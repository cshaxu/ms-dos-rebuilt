;**	MSCTRLC.ASM - ^C and error handler for MSDOS
;
;
;
	.xlist
	.xcref
	include version.inc
	include mssw.asm
	.cref
	.list

	TITLE	Control C detection, Hard error and EXIT routines
	NAME	IBMCTRLC

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	Low level routines for detecting special characters on CON input,
;	the ^C exit/int code, the Hard error INT 24 code, the
;	process termination code, and the INT 0 divide overflow handler.
;
;	FATAL
;	FATAL1
;	reset_environment
;	DSKSTATCHK
;	SPOOLINT
;	STATCHK
;	CNTCHAND
;	DIVOV
;	CHARHARD
;	HardErr
;
;	Revision history:
;
;	    AN000	version 4.0   Jan 1988
;	    A002	PTM    -- dir >lpt3 hangs
;	    A003	PTM 3957- fake version for IBMCAHE.COM
;
; 	M011: NEC's 8086 clone chip uses Intel's undocumented bit number in
;	      flags register. In order to return to user normally DOS used to
;	      move F202 into flags, which sets bit number 1 in flags uncondit-
;	      ionally. Now it is modified to maintain the state of bit 1.
;
; 	M024: suppressed fail and ignore options if not in the middle of int 
;	      24 and if Ctrl P or ctrl printscrn is pressed in routine 
;	      charhard.
;


	.xlist
	include dosseg.inc
	.xcref
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include mult.inc
	include pdb.inc
	include dpb.inc
	include exe.inc
	include sf.inc
	include vector.inc
	include filemode.inc
	include mi.inc
	include syscall.inc
	include bugtyp.inc
	.cref
	.list

	I_need	SFN,WORD
	I_NEED	pJFN,DWORD
	i_need	DevIOBuf,BYTE
	i_need	DidCTRLC,BYTE
	i_need	INDOS,BYTE
	i_need	DosCallDepth,BYTE
	i_need	DOS_FLAG,BYTE
	i_need	BiosErrorVector,DWORD
	i_need	DSKSTCOM,BYTE
	i_need	DSKSTCALL,BYTE
	i_need	DSKSTST,WORD
	i_need	BCON,DWORD
	i_need	DSKCHRET,BYTE
	i_need	DSKSTCNT,WORD
	i_need	IDLEINT,BYTE
	i_need	CONSWAP,BYTE
	i_need	user_SS,WORD
	i_need	user_SP,WORD
	i_need	User_In_AX,WORD
	i_need	ERRORMODE,BYTE
	i_need	ConC_spsave,WORD
	i_need	Exit_type,BYTE
	i_need	PFLAG,BYTE
	i_need	ExitHold,DWORD
	i_need	WPErr,BYTE
	i_need	ReadOp,BYTE
	i_need	CONTSTK,WORD
	i_need	Exit_Code,WORD
	i_need	CurrentPDB,WORD
	i_need	ALLOWED,BYTE
	i_need	FAILERR,BYTE
	i_need	EXTERR,WORD
	i_need	ERR_TABLE_24,BYTE
	I_need	ErrMap24,BYTE
	I_need	ErrMap24End,BYTE
	I_need	fAborting,BYTE
	I_need	AUXStack,BYTE
	I_need	SCAN_FLAG,BYTE
	I_need	EXTOPEN_ON,BYTE 	      ;AN000; DOS 4.0
	I_need	InterCon,BYTE		      ;AN000; DOS 4.0
	I_need	DOS34_FLAG,WORD 	      ;AN000; DOS 4.0
	I_need	Special_Version,WORD	      ;AN007; DOS 4.0

	I_need	TEMPSEG, WORD
	I_need	DosHasHMA,byte			; M021



ifndef ROMDOS

DOSDATA	SEGMENT
	extrn	LowInt23:near
	extrn	LowInt24:near
	extrn	LowInt28:near
DOSDATA	ENDS

endif ; ROMDOS


DOSCODE SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE


	allow_getdseg

ifndef ROMDOS

		public	LowInt23Addr		
LowInt23Addr	LABEL	DWORD
	DW	offset DOSDATA:LowInt23, 0

		public	LowInt24Addr
LowInt24Addr	LABEL	DWORD
	DW	offset DOSDATA:LowInt24, 0

		public	LowInt28Addr
LowInt28Addr	LABEL	DWORD
	DW	offset DOSDATA:LowInt28, 0

endif ; ROMDOS


Break	<Checks for ^C in CON I/O>

;---------------------------------------------------------------------------
;
; Procedure Name : DSKSTATCHK
;
; Check for ^C if only one level in
;
;---------------------------------------------------------------------------

        PUBLIC ConsoleStatePtr
ConsoleStatePtr DD 0
SpoolRestore:
        pop ax
        pop bx
procedure   SPOOLINT,NEAR
	PUSHF
	cmp	IdleInt,0		; SS override for IdleInt & ErrorMode
	je	POPFRet
	cmp	ErrorMode,0
	jnz	POPFRet
	
	;
	; Note that we are going to allow an external program to issue system 
	; calls at this time.  We MUST preserve IdleInt across this.
	;

	PUSH	WORD PTR IdleInt

ifndef ROMDOS 
	cmp	[DosHasHMA], 0		; Q: is dos running in HMA (M021)
	jne	do_low_int28		; Y: the int must be done from low mem
	INT	int_spooler		; N: Execute user int 28 handler
	jmp	short spool_ret_addr

do_low_int28:
	call	dword ptr LowInt28Addr

spool_ret_addr:
else
	INT	int_spooler		; if in ROM just do int 
endif ; ROMDOS

	POP	WORD PTR IdleInt
POPFRET:
	POPF
	return
EndProc SPOOLINT

procedure DSKSTATCHK,NEAR
        ASSUME DS:NOTHING,SS:DOSDATA
        cmp InDos,1
        jne POPFRET+1
        push cx
        push es
        push bx
        push ds
        push si
        lds si,CS:ConsoleStatePtr
        push WORD PTR [si]
        push ax
        mov ax,ss
        mov ds,ax
        mov es,ax
        ASSUME DS:DOSDATA,ES:NOTHING
        mov bx,OFFSET DOSDATA:DskStCall
        mov DskStCom,DEVRDND
        mov DskStCall,DRDNDHL
        mov DskStSt,0
        lds si,BCon
        ASSUME DS:NOTHING
        invoke DEVIOCALL2
        pop ax
        test al,al
        pop ax
        jnz status_keep
        lds si,CS:ConsoleStatePtr
        mov [si],ax
status_keep:
        push ss
        pop ds
        ASSUME DS:DOSDATA
        TESTB DskStSt,STBUI
        jz GotCh
        xor al,al
RET36:
        pop si
        pop ds
        pop bx
        pop es
        pop cx
        ret
GotCh:
        mov al,DskChRet
        cmp al,3
        jnz RET36
        mov DskStCom,DEVRD
        mov DskStCall,DRDWRHL
        mov DskChRet,cl
        mov DskStSt,0
        mov DskStCnt,1
        lds si,BCon
        ASSUME DS:NOTHING
        invoke DEVIOCALL2
        pop si
        pop ds
        pop bx
        pop es
        pop cx
        jmp CNTCHAND
EndProc DSKSTATCHK

procedure STATCHK,NEAR
        ASSUME DS:NOTHING,SS:DOSDATA
        push bx
        push ax
        cmp al,2
        je status_read
        invoke DSKSTATCHK
status_read:
        xor bx,bx
        invoke GET_IO_SFT
        jc status_failed
        mov ah,1
        invoke IOFUNC
        jnz status_character
        jmp SpoolRestore
status_character:
        pop bx
        cmp bl,2
        pop bx
        je status_peek
        cmp al,13h
        jne NOSTOP
        cmp Scan_Flag,0
        jne status_done
        xor ah,ah
        invoke IOFUNC
        jmp short PAUSOSTRT
NOSTOP:
        cmp al,10h
        jne check_next
        cmp Scan_Flag,0
        je INCHK
        ret
check_next:
        cmp al,3
        je INCHK
status_done:
        clc
        ret
status_peek:
        or ah,0ffh
        ret
status_failed:
        pop ax
        pop bx
StatusError:
        xor al,al
        ret
PAUSOLP:
        call SPOOLINT
PAUSOSTRT:
        mov ah,1
        invoke IOFUNC
        jz PAUSOLP
INCHK:
        push bx
        xor bx,bx
        invoke GET_IO_SFT
        pop bx
        jc StatusError
        xor ah,ah
        invoke IOFUNC
        cmp al,10h
        je PRINTON
        cmp al,3
        je CNTCHAND
        stc
        ret
PRINTOFF:
PRINTON:

	NOT	BYTE PTR PFlag		; SS override
	PUSH	BX
	MOV	BX,4
	invoke	GET_IO_SFT
	POP	BX
	jc	StatusError
	PUSH	ES
	PUSH	DI
	PUSH	DS
	POP	ES
	MOV	DI,SI			; ES:DI -> SFT
	TESTB	ES:[DI].SF_FLAGS,sf_net_spool
	JZ	NORM_PR 		; Not redirected, echo is OK
	Callinstall NetSpoolEchoCheck,MultNet,38,<AX>,<AX> ; See if allowed
	JNC	NORM_PR 		; Echo is OK

					; SS override
	MOV	BYTE PTR PFlag,0	; If not allowed, disable echo
	Callinstall NetSpoolClose,MultNet,36,<AX>,<AX> ; and close
	JMP	SHORT RETP6

NORM_PR:
	CMP	BYTE PTR PFlag,0	; SS override
	JNZ	PRNOPN
	invoke	DEV_CLOSE_SFT
	JMP	SHORT RETP6

PRNOPN:
	invoke	DEV_OPEN_SFT
RETP6:
	POP	DI
	POP	ES
	xor	al,al
	return
EndProc STATCHK

;	!! NOTE: FALL THROUGH !!

;---------------------------------------------------------------------------
;
; Procedure Name : CNTHAND ( CTRLC_C HANDLER )
;
; "^C" and CR/LF is printed.  Then the user registers are restored and the
; user CTRL-C handler is executed.  At this point the top of the stack has 1)
; the interrupt return address should the user CTRL-C handler wish to allow
; processing to continue; 2) the original interrupt return address to the code
; that performed the function call in the first place.	If the user CTRL-C
; handler wishes to continue, it must leave all registers unchanged and RET
; (not IRET) with carry CLEAR.	If carry is SET then an terminate system call
; is simulated.
;
;---------------------------------------------------------------------------

procedure   CNTCHAND,NEAR
	AND	DOS_FLAG,0EFh

					; SS override
					; AN002; from RAWOUT
	TESTB	Dos34_Flag,CTRL_BREAK_FLAG  
	JNZ	around_deadlock 	; AN002;
	MOV	AL,3			; Display "^C"
	invoke	BUFOUT
	invoke	CRLF
around_deadlock:			;AN002;
	Context DS			; SS is DOSDATA
	CMP	BYTE PTR ConSwap,0
	JZ	NOSWAP
	invoke	SWAPBACK
NOSWAP:
	CLI				; Prepare to play with stack
	MOV	SS,User_SS		; User stack now restored
ASSUME	SS:NOTHING
	MOV	SP,User_SP

					; use macro for restore_world
	restore_world			; User registers now restored

	;
	; CS was used to address these variables. We have to use DOSDATA 
	;
	push	ds
	getdseg	<ds>			; ds -> dosdata

	MOV	BYTE PTR InDos,0	; Go to known state
	MOV	DosCallDepth,0
	MOV	BYTE PTR ErrorMode,0
	MOV	ConC_Spsave,SP		; save his SP


	; User SP has changed because of push. Adjust for it

	add	ConC_Spsave,2		

ifndef ROMDOS
	cmp	[DosHasHMA], 0		; Q: is dos running in HMA (M021)
 	pop	ds	;restore ds
	assume	ds:NOTHING

	jne	do_low_int23		; Y: the int must be done from low mem
	CLC				
	INT	int_ctrl_c		; N: Execute user Ctrl-C handler
	jmp	short ctrlc_ret_addr

do_low_int23:
	clc
	call	dword ptr LowInt23Addr

ctrlc_ret_addr:
else
 	pop	ds	;restore ds
	assume	ds:NOTHING

	CLC
	INT	int_ctrl_c		; Execute user Ctrl-C handler

endif ; ROMDOS


;
; The user has returned to us.	The circumstances we allow are:
;
;   IRET	We retry the operation by redispatching the system call
;   CLC/RETF	POP the stack and retry
;   ... 	Exit the current process with ^C exit
;
; User's may RETURN to us and leave interrupts on.  Turn 'em off just to be
; sure
;
	CLI

	;
	; We have to use DOSDATA for these variables. Previously CS was used 
	;

	push	ax
	mov	ax, ds
	getdseg	<ds>			; ds -> dosdata

	mov	TempSeg, ax
	pop	ax

	MOV	User_In_AX,ax		; save the AX
	PUSHF				; and the flags (maybe new call)
	POP	AX

	;
	; See if the input stack is identical to the output stack
	;

	CMP	SP,ConC_Spsave
	JNZ	ctrlc_try_new		; current SP not the same as saved SP

	;
	; Repeat the operation by redispatching the system call.
	;

ctrlc_repeat:
	MOV	AX,User_In_AX		; ds still points to dosdata 

					
	mov	ds, TempSeg		; restore ds and original sp 
	assume	ds:NOTHING

	transfer    COMMAND

	;
	; The current SP is NOT the same as the input SP.  Presume that he 
	; RETF'd leaving some flags on the stack and examine the input
	;

ctrlc_try_new:
	ADD	SP,2			; pop those flags
	TESTB	AX,f_carry		; did he return with carry?
	JZ	Ctrlc_Repeat		; no carry set, just retry

					
	assume	ds:DOSDATA		;restore ds 
	mov	ds, TempSeg
	assume	ds:NOTHING

	;
	; Well...  time to abort the user.  Signal a ^C exit and use the EXIT 
	; system call..
	;

ctrlc_abort:
	MOV	AX,(EXIT SHL 8) + 0

	push	ds
	getdseg	<ds>			; ds -> dosdata
	
	MOV	DidCTRLC,-1

	pop	ds
	assume	ds:NOTHING

	transfer    COMMAND		; give up by faking $EXIT

EndProc CNTCHAND

Break	<DIVISION OVERFLOW INTERRUPT>
;----------------------------------------------------------------------------
;
; Procedure Name : DIVOV
;
; Default handler for division overflow trap
;
;----------------------------------------------------------------------------

procedure   DIVOV,NEAR
	ASSUME	SS:NOTHING

	getdseg	<ds>
	MOV	AX,1
	CALL	DWORD PTR BiosErrorVector
	JMP	ctrlc_abort		; Use Ctrl-C abort on divide overflow
EndProc DIVOV

;---------------------------------------------------------------------------
;
; Procedure Name : OutMes
;
;
; OutMes: perform message output
; Inputs:   SS:SI points to message
;	    BX has message length
; Outputs:  message to BCON
;
;Actually, cs:si points to the message now. The segment address is filled in
;at init. time ([dskchret+2]). This will be temporarily changed to DOSCODE. 
;NB. This procedure is called only from DIVOV. -SR
;
;---------------------------------------------------------------------------

procedure   OutMes,NEAR

	Context ES			; get ES addressability
	Context DS			; get DS addressability

	MOV	BYTE PTR DskStCom,DevWrt
	MOV	BYTE PTR DskStCall,DRdWrHL
	MOV	DskStSt,0
	MOV	DskStCnt,BX

					; DSKSTCALL is in DOSDATA
	MOV	BX,OFFSET DOSDATA:DskStCall
	MOV	WORD PTR [DskChRet+1],SI; transfer address (need an EQU)


					; CS is used for string, fill in 
					; segment address 
	MOV	WORD PTR [DskChRet+3],CS

	LDS	SI,BCon

ASSUME	DS:NOTHING
	invoke	DEVIOCALL2
					; ES still points to DOSDATA. ES is
					; not destroyed by deviocall2. So use
					; ES override.

					; DEVIOBUF is in DOSDATA
	MOV	WORD PTR ES:[DskChRet+1],OFFSET DOSDATA:DevIOBuf
	MOV	ES:[DskStCnt],1
	return
EndProc OutMes

Break	<CHARHRD,HARDERR,ERROR -- HANDLE DISK ERRORS AND RETURN TO USER>
;---------------------------------------------------------------------------
;
; Procedure Name : CHARHARD
;
;
; Character device error handler
; Same function as HARDERR
;
;---------------------------------------------------------------------------

procedure   CHARHARD,NEAR
	ASSUME	SS:DOSDATA

		   			; M024 - start
	cmp	byte ptr [ErrorMode], 0	; Q: are we in the middle of int 24
	jne	@f			; Y: allow fail

	OR	AH, allowed_RETRY	; assume ctrl p

	test	byte ptr [PFLAG], -1	; Q: has ctrl p been pressed
	jnz	ctrlp			; Y: 
@@:					; M024 - end

	OR	AH,allowed_FAIL + allowed_IGNORE + allowed_RETRY

ctrlp:					; M024

					; SS override for Allowed and EXITHOLD
	MOV	Allowed,AH
	MOV	WORD PTR EXITHOLD+2,ES
	MOV	WORD PTR EXITHOLD,BP
	PUSH	SI
	AND	DI,STECODE
	MOV	BP,DS			; Device pointer is BP:SI
	CALL	FATALC
	POP	SI
	return
EndProc CHARHARD

;---------------------------------------------------------------------------
;
; Procedure Name : HardErr
;
; Hard disk error handler. Entry conditions:
;	DS:BX = Original disk transfer address
;	DX = Original logical sector number
;	CX = Number of sectors to go (first one gave the error)
;	AX = Hardware error code
;	DI = Original sector transfer count	
;	ES:BP = Base of drive parameters
;	[READOP] = 0 for read, 1 for write
;	Allowed Set with allowed responses to this error (other bits MUST BE 0)
; Output:
;	[FAILERR] will be set if user responded FAIL
;
;--------------------------------------------------------------------------

procedure   HardErr,NEAR

	XCHG	AX,DI			; Error code in DI, count in AX
	AND	DI,STECODE		; And off status bits
	CMP	DI,error_I24_write_protect ; Write Protect Error?
	JNZ	NOSETWRPERR
	PUSH	AX
	MOV	AL,ES:[BP.dpb_drive]

					; SS override
	MOV	BYTE PTR WPERR,AL	; Flag drive with WP error
	POP	AX
NOSETWRPERR:
	SUB	AX,CX			; Number of sectors successfully transferred
	ADD	DX,AX			; First sector number to retry
	PUSH	DX
	MUL	ES:[BP.dpb_sector_size] ; Number of bytes transferred
	POP	DX
	ADD	BX,AX			; First address for retry
	XOR	AH,AH			; Flag disk section in error
	CMP	DX,ES:[BP.dpb_first_FAT]; In reserved area?
	JB	ERRINT
	INC	AH			; Flag for FAT
					; In FAT?
	CMP	DX,ES:[BP.dpb_dir_sector]   
	JAE	TESTDIR 		; No
	MOV	ES:[BP.dpb_free_cnt],-1 ; Err in FAT must force recomp of freespace
	JMP	SHORT ERRINT

TESTDIR:
	INC	AH
					; In directory?
	CMP	DX,ES:[BP.dpb_first_sector] 
	JB	ERRINT
	INC	AH			; Must be in data area
ERRINT:
	SHL	AH,1			; Make room for read/write bit

					; SS override
	OR	AH,BYTE PTR READOP	; Set bit 0

	;
	; If we have a write protect error when writing on a critical area on ,
	; disk, do not allow a retry as this may write out garbage on any 
	; subsequent disk.
	;
	;test	ah,1
	;jz	Not_Crit
	;cmp	ah,5
	;ja	Not_Crit
	;and	Allowed,NOT Allowed_RETRY

Not_Crit:

					; SS override for allowed and EXITHOLD
	OR	AH,Allowed		; Set the allowed_ bits
	entry	FATAL
	MOV	AL,ES:[BP.dpb_drive]	; Get drive number
	entry	FATAL1
	MOV	WORD PTR EXITHOLD+2,ES
	MOV	WORD PTR EXITHOLD,BP	; The only things we preserve
	LES	SI,ES:[BP.dpb_driver_addr]
	MOV	BP,ES			; BP:SI points to the device involved

	;
	; DI has the INT-24-style extended error.  We now map the error code 
	; for this into the normalized get extended error set by using the 
	; ErrMap24 table as a translate table.  Note that we translate ONLY 
	; the device returned codes and leave all others beyond the look up 
	; table alone.
	;

FATALC:
	call	SET_I24_EXTENDED_ERROR
	CMP	DI,error_I24_gen_failure
	JBE	GOT_RIGHT_CODE		; Error codes above gen_failure get
	MOV	DI,error_I24_gen_failure; mapped to gen_failure. Real codes
					;  Only come via GetExtendedError
;**
;
; Entry point used by REDIRector on Network I 24 errors.
;
;	ASSUME	DS:NOTHING,ES:NOTHING,SS:DOSDATA
;
; ALL I 24 regs set up. ALL Extended error info SET. ALLOWED Set.
;     EXITHOLD set for restore of ES:BP.
;

	entry	NET_I24_ENTRY

GOT_RIGHT_CODE:

					; SS override
	CMP	BYTE PTR ErrorMode,0	; No INT 24s if already INT 24
	JZ	NoSetFail
	MOV	AL,3
IF	DEBUG
	JMP	FailRet
ELSE
	JMP	short FailRet
ENDIF
NoSetFail:

					; SS override
	MOV	CONTSTK,SP
	Context ES
	fmt TypINT24,LevLog,<"INT 24: AX = $x DI = $x\n">,<AX,DI>

	;
	; Wango!!!  We may need to free some user state info...  In 
	; particular, we may have locked down a JFN for a user and he may 
	; NEVER return to us. Thus,we need to free it here and then 
	; reallocate it when we come back.
	;

					; SS override for SFN and pJFN
	CMP	SFN,-1
	JZ	NoFree
	SAVE	<DS,SI>
	LDS	SI,pJFN
	MOV	BYTE PTR [SI],0FFH
	RESTORE <SI,DS>
NoFree:
	CLI				; Prepare to play with stack

					; SS override for ERRORMODE, INDOS, 
					; DOS34_FLAG, EXTOPEN_ON
	INC	BYTE PTR ErrorMode	; Flag INT 24 in progress
	DEC	BYTE PTR InDos		; INT 24 handler might not return
	DEC	DosCallDepth

	;; Extended Open hooks

					; AN000;IFS.I24 error disabled	      ;AN000;
	TESTB	EXTOPEN_ON,EXT_OPEN_I24_OFF 
	JZ	i24yes			; AN000;IFS.no			      ;AN000;
faili24:				; AN000;
	MOV	AL,3			; AN000;IFS.fake fail		      ;AN000;
	JMP	short passi24 		; AN000;IFS.exit			      ;AN000;
i24yes: 				; AN000;

	;; Extended Open hooks

	MOV	SS,User_SS
ASSUME	SS:NOTHING
	MOV	SP,ES:User_SP		; User stack pointer restored

ifndef ROMDOS
	cmp	[DosHasHMA], 0		; Q: is dos running in HMA (M021)
	jne	do_low_int24		; Y: the int must be done from low mem
	INT	int_fatal_abort 	; Fatal error interrupt vector, 
					; must preserve ES
	jmp	short criterr_ret_addr

do_low_int24:
	call	dword ptr LowInt24Addr

criterr_ret_addr:
else

	INT	int_fatal_abort 	; Fatal error interrupt vector, must preserve ES

endif ; ROMDOS
	MOV	ES:User_SP,SP		; restore our stack
	MOV	ES:User_SS,SS
	MOV	BP,ES
	MOV	SS,BP
ASSUME	SS:DOSDATA
passi24:				; AN000;

					; SS override for nect 3 instructions.
	MOV	SP,CONTSTK
	INC	BYTE PTR InDos		; Back in the DOS
	INC	DosCallDepth
	MOV	BYTE PTR ErrorMode,0	; Back from INT 24
	STI
;;	MOV	ACT_PAGE,-1		; LB. invalidate DOS active page 	;AN000;
;;	invoke	SAVE_MAP		; LB. save user's EMS map                ;AN000;
	fmt TypINT24,LevLog,<"INT 24: User reply = $x\n">,<AX>
FAILRET:

					
	LES	BP,EXITHOLD		; SS override
ASSUME	ES:NOTHING

	;
	; Triage the user's reply.
	;

	CMP	AL,1
	JB	CheckIgnore		; 0 => ignore
	JZ	CheckRetry		; 1 => retry
	CMP	AL,3			; 3 => fail
	JNZ	DoAbort 		; 2, invalid => abort

	;
	; The reply was fail.  See if we are allowed to fail.
	;

					; SS override for ALLOWED, EXTOPEN_ON, 
					; ALLOWED, FAILERR, WpErr, SFN, pJFN
	TESTB	Allowed,allowed_FAIL	; Can we?
	JZ	DoAbort 		; No, do abort
DoFail:
	MOV	AL,3			; just in case...
					; AN000;EO. I24 error disabled
	TESTB	EXTOPEN_ON,EXT_OPEN_I24_OFF 
	JNZ	cleanup 		; AN000;EO. no
	INC	FAILERR			; Tell everybody
CleanUp:
	MOV	WpErr,-1
	CMP	SFN,-1
	retz
	SAVE	<DS,SI,AX>
	MOV	AX,SFN
	LDS	SI,pJFN
	MOV	[SI],AL
	RESTORE <AX,SI,DS>
	return

	;
	; The reply was IGNORE.  See if we are allowed to ignore.
	;

CheckIgnore:
	TESTB	Allowed,allowed_IGNORE 	; Can we?
	JZ	DoFail			; No, do fail
	JMP	CleanUp

	;	
	; The reply was RETRY.	See if we are allowed to retry.
	;

CheckRetry:
	TESTB	Allowed,allowed_RETRY 	; Can we?
	JZ	DoFail			; No, do fail
	JMP	CleanUp

	;
	; The reply was ABORT.
	;

DoAbort:
	Context DS
	CMP	BYTE PTR ConSwap,0
	JZ	NOSWAP2
	invoke	SWAPBACK
NOSWAP2:

	;	
	; See if we are to truly abort.  If we are in the process of aborting, 
	; turn this abort into a fail.
	;

	cmp	fAborting,0
	JNZ	DoFail

	;
	; Set return code
	;

	MOV	BYTE PTR [exit_Type],Exit_hard_error
	XOR	AL,AL

	;
	; we are truly aborting the process.  Go restore information from 
	; the PDB as necessary.
	;

	Transfer    exit_inner
;**
;
; reset_environment checks the DS value against the CurrentPDB.  If they are
; different, then an old-style return is performed.  If they are the same,
; then we release jfns and restore to parent.  We still use the PDB at DS:0 as
; the source of the terminate addresses.
;
; Some subtlety:  We are about to issue a bunch of calls that *may* generate
; INT 24s.  We *cannot* allow the user to restart the abort process; we may
; end up aborting the wrong process or turn a terminate/stay/resident into a
; normal abort and leave interrupt handlers around.  What we do is to set a
; flag that will indicate that if any abort code is seen, we just continue the
; operation.  In essence, we dis-allow the abort response.
;
; output:   none.
;
	entry	reset_environment
	ASSUME	DS:NOTHING,ES:NOTHING

;***	invoke	Reset_Version		; AN007;MS. reset version number
	PUSH	DS			; save PDB of process

	;
	; There are no critical sections in force.  Although we may enter 
	; here with critical sections locked down, they are no longer 
	; relevant. We may safely free all allocated resources.
	;

	invoke	LcritAll

					; SS override
	MOV	fAborting,-1		; signal abort in progress

					; DOS 4.00 doesn't need it
	CallInstall NetResetEnvironment, multNet, 34  
					; Allow REDIR to clear some stuff
					; On process exit.
	MOV	AL,int_Terminate
	invoke	$Get_interrupt_vector	; and who to go to

	POP	CX			; get ThisPDB
	SAVE	<ES,BX> 		; save return address

	MOV	BX,[CurrentPDB] 	; get currentPDB
	MOV	DS,BX
	MOV	AX,DS:[PDB_Parent_PID]	; get parentPDB

	;
	; AX = parentPDB, BX = CurrentPDB, CX = ThisPDB
	; Only free handles if AX <> BX and BX = CX and [exit_code].upper 
	; is not Exit_keep_process
	;
	
	CMP	AX,BX
	JZ	reset_return		; parentPDB = CurrentPDB
	CMP	BX,CX
	JNZ	reset_return		; CurrentPDB <> ThisPDB
	PUSH	AX			; save parent

					; SS override
	CMP	BYTE PTR [exit_type],Exit_keep_process
	JZ	reset_to_parent 	; keeping this process

	;
	; We are truly removing a process.  Free all allocation blocks 
	; belonging to this PDB
	;

	invoke	arena_free_process

	;
	; Kill off remainder of this process.  Close file handles and signal 
	; to relevant network folks that this process is dead.  Remember that 
	; CurrentPDB is STILL the current process!
	;

	invoke	DOS_ABORT

reset_to_parent:
					; SS override
	POP	[CurrentPDB]		; set up process as parent

reset_return:				; come here for normal return

	Context	DS			; DS is used to refer to DOSDATA  

	MOV	AL,-1

	;
	; make sure that everything is clean In this case ignore any errors, 
	; we cannot "FAIL" the abort, the program being aborted is dead.
	;

	EnterCrit   critDisk
	CALL	DeferredFlush
	LeaveCrit   critDisk

	;
	; Decrement open ref. count if we had done a virtual open earlier.
	;

	invoke	CHECK_VIRT_OPEN
	CLI
	MOV	BYTE PTR InDos,0	; Go to known state
	MOV	DosCallDepth,0
	MOV	BYTE PTR [WPERR],-1	; Forget about WP error
	MOV	fAborting,0		; let aborts occur
	POP	WORD PTR ExitHold
	POP	WORD PTR ExitHold+2

	;
	; Snake into multitasking... Get stack from CurrentPDB person
	;

	MOV	DS,[CurrentPDB]
	ASSUME	DS:NOTHING
	MOV	SS,WORD PTR DS:[PDB_user_stack+2]
	MOV	SP,WORD PTR DS:[PDB_user_stack]

	ASSUME	SS:NOTHING
	restore_world			; use macro

	ASSUME	ES:NOTHING


	push	ax			; set up ds, but save ds in TEMPSEG 
	mov	ax, ds			; and not on stack.
	getdseg <ds>			; ds ->dosdata
	mov	TempSeg, ax
	pop	ax
					; set up ds to DOSDATA
	MOV	User_SP,AX

	POP	AX			; suck off CS:IP of interrupt...
	POP	AX
	POP	AX

; M011 : BEGIN

;	MOV	AX,0F202h		; STI

	LAHF
	XCHG	AH, AL
	AND	AL, 02
	MOV	AH, 0F2h

; M011 : END

	PUSH	AX

 
	PUSH	WORD PTR [EXITHOLD+2]
	PUSH	WORD PTR [EXITHOLD]

	MOV	AX,User_SP

	mov	ds,TempSeg		; restore ds
	assume	ds:NOTHING

	IRET				; Long return back to user terminate address
EndProc HardErr,NoCheck

;---------------------------------------------------------------------------
;
; Procedure Name : SET_I24_EXTENDED_ERROR
;
; This routine handles extended error codes.
; Input : DI = error code from device
; Output: All EXTERR fields are set
;
;--------------------------------------------------------------------------

Procedure SET_I24_EXTENDED_ERROR,NEAR
	PUSH	AX

					; ErrMap24End is in DOSDATA
	MOV	AX,OFFSET DOSDATA:ErrMap24End
	SUB	AX,OFFSET DOSDATA:ErrMap24

					; Change to dosdata to access 
					; ErrMap24 and EXTERR -SR
	push	ds
	getdseg <ds>			; ds ->dosdata

	;
	; AX is the index of the first unavailable error.  Do not translate 
	; if greater or equal to AX.
	;

	CMP	DI,AX
	MOV	AX,DI
	JAE	NoTrans

	MOV	AL,ErrMap24[DI]
	XOR	AH,AH
NoTrans:

	MOV	[EXTERR],AX
	pop	ds
	assume	ds:nothing
	POP	AX

	;
	; Now Extended error is set correctly.	Translate it to get correct 
	; error locus class and recommended action.
	;

	PUSH	SI

					; ERR_TABLE_24 is in DOSCODE 
	MOV	SI,OFFSET DOSDATA:ERR_TABLE_24
	invoke	CAL_LK			; Set other extended error fields
	POP	SI
	ret
EndProc SET_I24_EXTENDED_ERROR

        PUBLIC  CL0FATENTRY
CL0FATENTRY dw 0
        PUBLIC  FIRST_BUFF_ADDR
FIRST_BUFF_ADDR dw 0

; DS addresses DOSDATA; defer writes when the target flag requests it.
        i_need  DeferredFlushFlags,BYTE
procedure DeferredFlush,near
        ASSUME  DS:DOSDATA
        test    DeferredFlushFlags,1
        jnz     deferred_flush_done
        transfer FLUSHBUF
deferred_flush_done:
        ret
EndProc DeferredFlush


;--------------------------------------------------------------------------
;
; Proc. name : dos_high
;
; ENTRY: CS = current doscode segment
; 
; EXIT: if CS >=F000 (DOS is in HMA)
;	   CY stc
;	else	     (DOS is LOW)
;	   NC clc	
;
; USED: nothing
;
;-------------------------------------------------------------------------
;
;public	dos_high
;dos_high	proc	near
;
;	push	ax
;	mov	ax, cs
;	cmp	ax, 0f000h		; Q: is current cs >= f000
;	pop	ax
;	cmc				; clc if dos is low
;					; stc if dos is high 
;	ret
;
;dos_high	endp
;

DOSCODE	ENDS
    END
