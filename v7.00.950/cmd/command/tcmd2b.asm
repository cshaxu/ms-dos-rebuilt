	page ,132
;	SCCSID = @(#)tcmd2b.asm 4.1 85/09/22
;	SCCSID = @(#)tcmd2b.asm 4.1 85/09/22
TITLE	PART5 COMMAND Transient routines.
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include pdb.inc
	include mult.inc
	include comseg.asm
	include comequ.asm
.list
.cref


;;CODERES 	SEGMENT PUBLIC BYTE	;AC000;
;;	EXTRN	LODCOM1:NEAR
;;CODERES ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	crit_msg_off:word	;AC000;
	EXTRN	crit_msg_seg:word	;AC000;
	EXTRN	IO_SAVE:WORD
	EXTRN	Int_2e_Ret:DWORD
	EXTRN	Int2eHandler:DWORD
	EXTRN	Int2fHandler:DWORD
	EXTRN	SemiPermCom:BYTE
	EXTRN	OldTerm:DWORD
	EXTRN	PARENT:WORD
;AD060; EXTRN	pars_msg_off:word	;AC000;
;AD060; EXTRN	pars_msg_seg:word	;AC000;
	EXTRN	PERMCOM:BYTE		;AN045;
	EXTRN	RetCode:WORD
	EXTRN	SingleCom:word

	extrn	TrnLodCom1_Trap:far
	extrn	LodCom_Trap:far
	extrn	Int2f_Trap:far

DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ACRLF_PTR:WORD		;AN007;
	EXTRN	LockErr_Ptr:WORD
	EXTRN	LockWarn_Ptr:WORD
	EXTRN	LockPrompt_Ptr:WORD
	EXTRN	baddev_ptr:word
	EXTRN	CP_active_Ptr:word
	EXTRN	CP_not_all_Ptr:word
	EXTRN	CP_not_set_Ptr:word
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	inv_code_page:word	;AC000;
	EXTRN	msg_disp_class:byte	;AN000;
	EXTRN	NLSFUNC_Ptr:word	;AC000;
	EXTRN	parse_chcp:byte 	;AC000;
	EXTRN	parse_chdir:byte	;AC000;
	EXTRN	parse_ctty:byte 	;AC000;
	EXTRN	string_buf_ptr:word	;AC000;

	extrn	NoCntry_Ptr:word	;M045

TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ComBufPtr:WORD
	EXTRN	ParseArgIndex:WORD
	EXTRN	ParseResultValue:DWORD
	EXTRN	parse_last:word 	;AN018;
	EXTRN	parse1_addr:dword	;AC000;
	EXTRN	parse1_type:byte	;AC000;
	EXTRN	RESSEG:WORD
	EXTRN	srcbuf:byte
	EXTRN	srcxname:byte		;AC000;
	EXTRN	string_ptr_2:word
	EXTRN	system_cpage:word
	EXTRN	TRAN_TPA:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
TRANSPACE	ENDS
;---------------

	EXTRN	cerror:near
	EXTRN	getarg:near
	EXTRN	char_in_xlat:near
	EXTRN	ParseArgument:near
	EXTRN	CheckParsedArgs:near
	EXTRN	GetParsedArg:near
	extrn	TCommand:near

	PUBLIC	$exit
	PUBLIC	LockDrive,UnlockDrive
	PUBLIC	chcp
	PUBLIC	ctty
	EXTRN	DirSetupParamError:near
	PUBLIC	setup_parse_error_msg	;AN018;
	PUBLIC	truename		;AN000;

	break	Ctty
assume	ds:trangroup,es:trangroup

; ****************************************************************
; *
; * ROUTINE:	 CTTY - Change console
; *
; * SYNTAX:	 CTTY device
; *
; * FUNCTION:	 If a valid console device is specified, CTTY will
; *		 duplicate the device handle to STDIN, STDOUT and
; *		 STDERR.  This routine returns to LODCOM1.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

CTTY:
        push    ds
        pop     es
        mov     di,offset TRANGROUP:parse_ctty
        mov     ParseArgIndex,1
        invoke  ParseArgument
        jc      short ctty_error
        push    si
        mov     di,offset TRANGROUP:srcbuf
ctty_move_filename:
        lodsb
        stosb
        cmp     al,end_of_line_out
        jnz     ctty_move_filename
        cmp     byte ptr [di-2],colon_char
        jnz     short ctty_name_done
        mov     byte ptr [di-2],0
ctty_name_done:
        pop     si
        invoke  CheckParsedArgs
        jc      short ctty_open
ctty_error:
        jmp     short ISBADDEV
ctty_open:
        mov     si,offset TRANGROUP:srcbuf
        mov     ax,6C00H
        mov     bx,42H
        xor     cx,cx
        mov     dx,0101H
        int     21h
	JC	ISBADDEV
	MOV	BX,AX
	MOV	AX,IOCTL SHL 8
	INT	21h
	TEST	DL,80H
	JNZ	DEVISOK

CLOSEDEV:					;AN007;
	MOV	AH,CLOSE			; Close initial handle
	INT	21h

ISBADDEV:
	MOV	DX,OFFSET TRANGROUP:BADDEV_ptr
	invoke	std_printf
	JMP	SHORT RESRET

DEVISOK:
	push	dx				;AN007; save device info
	mov	ax,acrlf_ptr			;AN021; get message number for 0d, 0a
	mov	dh,util_msg_class		;AN021; this is a utility message
	push	bx				;AN021; save handle
	invoke	Tsysgetmsg			;AN021; get the address of the message
	mov	dx,si				;AN021; get address into dx
	mov	ax,(write shl 8)		;AN007; write to device
	mov	cx,2				;AN007; write two bytes
	int	21h			;AN007;
	pop	bx				;AN021; get back handle
	pop	dx				;AN007; get back device info
	jc	closedev			;AN007; if error, quit
	XOR	DH,DH
	OR	DL,3				; Make sure has CON attributes
	MOV	AX,(IOCTL SHL 8) OR 1
	INT	21h
	PUSH	BX				; Save handle
	MOV	CX,3
	XOR	BX,BX

ICLLOOP:					; Close basic handles
	MOV	AH,CLOSE
	INT	21h
	INC	BX
	LOOP	ICLLOOP
	POP	BX				; Get handle
	MOV	AH,XDUP
	INT	21h			; Dup it to 0
	MOV	AH,XDUP
	INT	21h			; Dup to 1
	MOV	AH,XDUP
	INT	21h			; Dup to 2
	MOV	AH,CLOSE			; Close initial handle
	INT	21h

RESRET:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	PUSH	DS
	MOV	AX,WORD PTR DS:[PDB_JFN_Table]	; Get new 0 and 1
	MOV	[IO_SAVE],AX
	MOV	AX,OFFSET DATARES:TrnLodCom1_Trap
	PUSH	AX

ZMMMM	PROC FAR
	RET					; Force header to be checked
ZMMMM	ENDP

	break	Chcp

;****************************************************************
;*
;* ROUTINE:	CHCP - Change code page internal command
;*		(added DOS 3.30 07/21/86)
;*
;* SYNTAX:	CHCP [xxx]
;*		where xxx is a valid code page
;*
;* FUNCTION:	If xxx is specified, CHCP will use INT 21H function
;*		6402H to set the code page to xxxx. If no parameters
;*		are specified, CHCP will use INT 21H function 6401H
;*		to get global code page and display it to the user.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	none
;*
;****************************************************************

NLSFUNC_installed	equ    0ffh
set_global_cp		equ    2
get_global_cp		equ    1

assume	ds:trangroup,es:trangroup

CHCP:
        push    ds
        pop     es
        mov     ParseArgIndex,1
        mov     di,offset TRANGROUP:parse_chcp
        invoke  ParseArgument
        jnc     short setcp
        or      ax,ax
        jz      getcp
        jmp     short cp_error
setcp:
        mov     ax,word ptr ParseResultValue
        cmp     ax,100
        jb      chcp_invalid
        cmp     ax,999
        ja      chcp_invalid
        mov     system_cpage,ax
        invoke  CheckParsedArgs
        jnc     chcp_extra

okset:
	mov	ah,NLSFUNC			;AN000; see if NLSFUNC installed
	mov	al,0				;AN000;
	int	2fh				;AN000;
	cmp	al,NLSFUNC_installed		;AN000;
	jz	got_NLS 			;AN000; Yes - continue
	mov	dx,offset trangroup:NLSFUNC_ptr ;AN000; no - set up error message
	jmp	short cp_error			;AN000; error exit

got_NLS:
	mov	bx,system_cpage 		;AN000; get user input code page
	mov	ah,getsetcdpg			;get/set global code page function
	mov	al,set_global_cp		;minor - set
	int	21h
	jnc	chcp_return			;no error - exit
;
;added for p716
;
	cmp	ax,error_file_not_found 	;p716 was the error file not found?
	jnz	chcp_other_error		;no - country.sys was found

	mov	ah,GetExtendedError		;p850 see if error is invalid data
	xor	bx,bx				;  which is file was found but CP
	int	21h			;  information was not found.
	cmp	ax,error_invalid_data		;AC000; invalid code page
	jnz	no_countrysys			;no - use file not found
	mov	dx,offset trangroup:inv_code_page ;AN000; get message
	jmp	short cp_error			;AC000; error exit

no_countrysys:
;M045;	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
;M045;	mov	dx,offset TranGroup:Extend_Buf_ptr  ;AC000; get extended message pointer
;M045;	mov	Extend_Buf_ptr,error_file_not_found ;AN000; get message number in control block
	
	mov	dx,offset TRANGROUP:NoCntry_Ptr	;M045

	jmp	short cp_error			;AC000; error exit

chcp_other_error:
;
; end of p716
;
	mov	ah,GetExtendedError		;error - see what it is
	xor	bx,bx
	int	21h
	cmp	ax,65				;was it access denied?
	jnz	none_set			;no - assume all failed
	mov	dx,offset trangroup:cp_not_all_ptr ;set up message
	jmp	short cp_error			;AC000; error exit

chcp_invalid:
        mov     ax,6
        jmp     short chcp_setup_error
chcp_extra:
        invoke  GetParsedArg
        mov     ax,1
chcp_setup_error:
        invoke  DirSetupParamError
        jmp     short cp_error

none_set:
	mov	dx,offset trangroup:cp_not_set_ptr ;set up message
cp_error:					;AN000;
	jmp	cerror				;exit

getcp:
	mov	ah,getsetcdpg			;get/set global code page function
	mov	al,get_global_cp		;minor - get
	int	21h
	mov	system_cpage,bx 		;get active cp for output
	mov	dx,offset trangroup:cp_active_ptr
	invoke	std_printf			;print it out

chcp_return:

	RET

	break	TRUENAME			;AN000;


; ****************************************************************
; *
; * ROUTINE:	 TRUENAME
; *
; * FUNCTION:	 Entry point for the internal TRUENAME command.
; *		 Parses the command line. If a path is found, set
; *		 SRCXNAME to path.  If only a drive letter is
; *		 found, set SRCXNAME to the drive letter.  If
; *		 no path is found, set the path of SRCXNAME to
; *		 dot (.) for current directory.  Use the NAME
; *		 TRANSLATE system call to get the real name and
; *		 then display the real name.  If an error occurs
; *		 issue an error message and transfer control to
; *		 CERROR.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup		;AN000;

TRUENAME:
        push    ds
        pop     es
        mov     ParseArgIndex,1
        mov     di,offset TRANGROUP:parse_chdir
        invoke  ParseArgument
        jnc     short tn_argument
        or      ax,ax
        jz      short tn_eol
        jmp     short tn_parse_error
tn_eol:
        mov     di,offset TRANGROUP:srcxname
        mov     ah,end_of_line_out
        mov     al,dot_chr
        stosw
        jmp     short tn_doit
tn_argument:
        mov     di,offset TRANGROUP:srcxname
        cmp     [bx].arglen,2
        jnz     short tn_filespec
        cmp     byte ptr [si+1],colon_char
        jnz     short tn_filespec
        push    si
        lodsb
        stosb
        mov     ax,dot_colon
        stosw
        mov     al,end_of_line_out
        stosb
        pop     si
        jmp     short tn_check_eol
tn_filespec:
        push    si
tn_move_filename:
        lodsb
        stosb
        cmp     al,end_of_line_out
        jnz     tn_move_filename
        pop     si
tn_check_eol:
        invoke  CheckParsedArgs
        jc      short tn_doit
        invoke  GetParsedArg
        mov     ax,1
        invoke  DirSetupParamError
tn_parse_error:
        jmp     cerror

tn_doit:					;AN000;
	mov	si,offset trangroup:srcxname	;AN000; set up srcxname as source
	mov	di,[ComBufPtr]			;AN000; translation target buffer
	mov	ah,xnametrans			;AN000; do name translate call
	int	21h			;AN000;
	jnc	tn_print_xname			;AN000; If no error - print result

	invoke	Set_ext_error_msg		;AN000; get extended message
	mov	string_ptr_2,offset trangroup:srcxname ;AN000; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN000; put number of subst in control block
	jmp	cerror				;AN000; Go to error routine

tn_print_xname: 				;AN000;
	mov	dx,[ComBufPtr]			;AN000; translated name
	mov	string_ptr_2,dx
	mov	dx,offset trangroup:string_buf_ptr   ;AN000; Set up address of print control block
	invoke	crlf2				;AN000; print a crlf
	invoke	printf_crlf			;AN000; print it out

	ret					;AN000;

	break	$Exit

assume	ds:trangroup,es:trangroup

$EXIT:
        push    ds
        mov     ds,[resseg]
        ASSUME  DS:RESGROUP
        cmp     [permcom],0
        jnz     short ExitPermanent
        cmp     word ptr [Int_2e_Ret+2],0
        jz      short free_com
        push    ds
        mov     ax,offset RESGROUP:LodCom_Trap
        push    ax
        retf
ExitPermanent:
        cmp     word ptr [singlecom],-1
        jz      short no_reset
        jmp     TCommand
free_com:
        mov     ax,(multdos shl 8 or message_2f)
        mov     dl,set_critical_msg
        mov     di,crit_msg_off
        mov     es,crit_msg_seg
        int     2fh
no_reset:
        pop     ds
        ASSUME  DS:TRANGROUP
        invoke  RestUDir1
        mov     es,[RESSEG]
        ASSUME  ES:RESGROUP
        mov     ax,ES:[PARENT]
        mov     word ptr ES:[PDB_Parent_PID],ax
        mov     ax,word ptr ES:[OldTerm]
        mov     word ptr ES:[PDB_Exit],ax
        mov     ax,word ptr ES:[OldTerm+2]
        mov     word ptr ES:[PDB_Exit+2],ax
        mov     ax,ES:[RetCode]
        cmp     ah,0FFH
        jnz     short ExitSaveCode
        mov     al,0
ExitSaveCode:
        push    ax
        push    ds
        cmp     ES:[PermCom],0
        jnz     short ExitRestoreDone
        lds     dx,ES:[Int2eHandler]
        mov     ax,ds
        or      ax,dx
        jz      short ExitCheckInt2f
        mov     ax,252EH
        int     21h
ExitCheckInt2f:
        test    ES:[SemiPermCom],2
        jz      short ExitRestoreInt2f
        mov     dx,es
        mov     ax,352FH
        int     21h
        inc     bx
        cmp     word ptr ES:[bx],offset RESGROUP:Int2f_Trap
        jnz     short ExitKeepResident
        cmp     ES:[bx+2],dx
        jnz     short ExitKeepResident
        mov     es,dx
ExitRestoreInt2f:
        lds     dx,ES:[Int2fHandler]
        mov     ax,ds
        or      ax,dx
        jz      short ExitRestoreDone
        mov     ax,252FH
        int     21h
ExitRestoreDone:
        pop     ds
        push    es
        mov     es,[TRAN_TPA]
        mov     ah,DEALLOC
        int     21h
        pop     es
        pop     ax
        mov     ah,Exit
        int     21h
ExitKeepResident:
        mov     es,dx
        pop     ds
        push    es
        mov     es,[TRAN_TPA]
        mov     ah,DEALLOC
        int     21h
        dec     dx
        mov     es,dx
        mov     dx,ES:[3]
        pop     es
        pop     ax
        mov     ah,31h
        int     21h


; Set up a parser error for the parameter ending at DS:SI.
SETUP_PARSE_ERROR_MSG proc near
	mov	Msg_Disp_Class,PARSE_MSG_CLASS
	mov	dx,offset TRANGROUP:Extend_Buf_Ptr
	mov	byte ptr [si],0
	mov	Extend_Buf_Ptr,ax
	cmp	ax,2
	je	short ParseErrorDone
	mov	si,Parse_Last
	mov	String_Ptr_2,si
	mov	Extend_Buf_Sub,ONE_SUBST
ParseErrorDone:
	inc	si
	ret
SETUP_PARSE_ERROR_MSG endp

; LOCK and UNLOCK enable or disable direct access to a logical drive.
; A missing drive selects all drives; LOCK first asks for confirmation.
LockDrive:
        MOV     DX,OFFSET TRANGROUP:LockWarn_Ptr
        INVOKE  STD_PRINTF
LockQuestion:
        MOV     DX,OFFSET TRANGROUP:LockPrompt_Ptr
        INVOKE  STD_PRINTF
        MOV     SI,80H
        MOV     DX,SI
        MOV     WORD PTR [SI],78H
        MOV     AX,0C0AH
        INT     21H
        LODSW
        OR      AH,AH
        JZ      LockQuestion
        INVOKE  CRLF2
        INVOKE  SCANOFF
        CALL    char_in_xlat
        CMP     AL,0
        JZ      LockDone
        CMP     AL,1
        JNZ     LockQuestion
        MOV     CX,084AH
        JMP     SHORT LockOperation
UnlockDrive:
        MOV     CX,086AH
LockOperation:
        PUSH    CX
        CALL    GETARG
        POP     CX
        JNZ     SHORT LockSpecifiedDrive
        MOV     AL,1
        MOV     DX,011AH
        JMP     SHORT LockNextDrive
        NOP
LockSpecifiedDrive:
        CMP     BYTE PTR [SI+1],':'
        JNZ     SHORT LockError
        MOV     AL,[SI]
        PUSH    AX
        MOV     AX,1213H
        INT     2FH
        INC     SP
        INC     SP
        SUB     AL,40H
        JC      SHORT LockError
        CMP     AL,20H
        JA      SHORT LockError
        MOV     DX,1
LockNextDrive:
        PUSH    AX
        MOV     BL,AL
        MOV     BH,4
        MOV     AX,440DH
        INT     21H
        JNC     SHORT LockResult
        MOV     BH,0
        MOV     AX,440DH
        PUSH    DX
        XOR     DX,DX
        INT     21H
        POP     DX
LockResult:
        POP     AX
        JC      SHORT LockFailure
LockContinue:
        INC     AX
        DEC     DL
        JNZ     LockNextDrive
LockDone:
        RET
LockFailure:
        TEST    DH,DH
        JNZ     LockContinue
LockError:
        MOV     DX,OFFSET TRANGROUP:LockErr_Ptr
        JMP     CERROR
trancode    ends
	    end
