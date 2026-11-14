 	page ,132
	title	COMMAND Initialization
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;	M002	SR	07/15/90	Resize right at the start because
;				Carousel depends on it.
;
;	M004	SR	07/17/90	Initialization reworked so that 
;				transient is now moved at EndInit.
;				The old approach assumed that the
;				biggest block is the one currently 
;				loaded in, an assumption not true
;				for UMBs.
;
;	M005	SR	07/20/90	Numerous hacks for Carousel
;				1. Set CurrentPDB to ours at start
;				2. Normalize cs:ip of int 2fh hook
;				so that cs is different.
;
;	M013	SR	08/06/90	Fixed Setup_res_end & Move_res_code
;				to use new GetVersion call that
;				returns info about whether DOS is in
;				HMA or not.
;
;	M015	SR	08/09/90	Increased default environment size to
;				256 bytes from 160 bytes
;
;	M026	SR	9/12/90	Fixed environment trashing on second
;				Command if new comspec is given.
;
;	M030	SR	10/3/90	Before calling int 2fh 4a02h, set di
;				to 0ffffh so that we are ok if no one
;				answers this int 2fh.
;
;	M042	SR	12/13/90	Bug #4660. Changed setup_res_end to
;				take care of the dummy segment that
;				adds a para to the resident size.
;

.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include pdb.inc
	include mult.inc
	include syscall.inc
	include doscntry.inc
	include comseg.asm
	include comequ.asm
	include resmsg.equ

	include envdata.asm
	include xmm.inc
.list
.cref



ENVBIG			equ	32768
ENVSML			equ	256		;Increased to 256 ; M015
KOREA_COUNTRY_CODE	equ	82


CODERES segment public byte

	extrn	ContC		:near
	extrn	DskErr		:near
	extrn	Int_2e		:near
	extrn	LodCom		:near
	extrn	MsgInt2fHandler	:far
	extrn	ChkSum		:near
	extrn	CrLf		:near
	extrn	LoadCom	:near
	extrn	RPrint		:near

	extrn	EndCode	:byte
	extrn	EndTopCode:byte
	extrn	ExecTopRet:near
	extrn	ExecTopPath:dword
	extrn	StartCode	:byte
	extrn	ResidentChecksum:dword

	ifdef	DBCS
	extrn	ItestKanj	:near
	endif

	extrn	BadMemErr	:near

CODERES ends

DATARES segment public byte
	extrn	ResMsg127Ptr:word
	extrn	Append_State	:word	
	extrn	Batch		:word
	extrn	Com_Fcb1	:dword
	extrn	Com_Fcb2	:dword
	extrn	Com_Ptr		:dword
	extrn	ComDrv		:byte
	extrn	ComSpec		:byte
	extrn	ComSpec_End	:word
	extrn	ComSpecName	:word
	extrn	YSwitchFlags :byte	; /Y switch state
	extrn	Crit_Msg_Off	:word	
	extrn	Crit_Msg_Seg	:word	
	extrn	DataResEnd	:byte 	
	extrn	Dbcs_Vector_Addr:word	
	extrn	EchoFlag	:byte
	extrn	EnvirSeg	:word
	extrn	ExtMsgEnd	:byte	
	extrn	fFail		:byte
	extrn	FUCase_addr	:word	
	extrn	InitFlag	:byte
	extrn	Int2fHandler	:dword
	extrn	Int2eHandler	:dword
	extrn	ResidentDataSeg:word
	extrn	OriginalDataSeg:word
	extrn	LFNForFlag:byte
	extrn	DosCommandState:dword
	extrn	OriginalComSpec:byte
	extrn	Io_Save		:word
	extrn	LTpa		:word	
	extrn	MemSiz		:word
	extrn	MySeg		:word	
	extrn	MySeg1		:word
	extrn	MySeg2		:word
	extrn	MySeg3		:word
	extrn	Nest		:word
	extrn	OldTerm	:dword
	extrn	Parent		:word
	extrn	ParseMes_Ptr	:word	
	extrn	ParsMsgPtrs	:word
        extrn   PermCom         :byte
        extrn   SemiPermCom     :byte
	extrn	PutBackDrv	:byte
	extrn	PutBackComSpec	:byte
	extrn	RDirChar	:byte
	extrn	Res_Tpa	:word
	extrn	ResMsgEnd	:word	    
	extrn	RSwitChar	:byte
	extrn	SingleCom	:word
	extrn	CmdBufSize	:word
	extrn	InputBufSize	:word
	extrn	Sum		:word
	extrn	SumHigh	:word
	extrn	TrnSeg		:word
	extrn	TrnMvFlg	:byte

	extrn	ResSize	:word
	extrn	RStack		:word

	extrn	ComInHMA	:byte	;flag set if in HMA
	extrn	XMMCallAddr	:dword	;far call address to XMM

;;ifdef	ROMDOS
;;;	If LoadFromROM is in DATARES..
;;	extrn	LoadFromROM_seg	:word
;;endif

;
;All far pointers to resident routines that are to be patched
;
	extrn	Int2f_Entry	:dword
	extrn	Int2e_Entry	:dword
	extrn	Ctrlc_Entry	:dword
	extrn	CritErr_Entry	:dword

	extrn	Int2f_Trap	:near
	extrn	Int2e_Trap	:near
	extrn	Ctrlc_Trap	:near
	extrn	CritErr_Trap	:near
	extrn	LodCom_Trap	:near

	extrn	EndInit	:near

	extrn	Carousel_i2f_Hook	:byte	; M005

ifdef	BETA3WARN
	%out	Take this out before we ship
	extrn	Beta3Warned:byte
endif


DATARES ends


TAIL	segment public para

	extrn	TranStart	:word

TAIL	ends


TRANCODE	segment public byte


TRANCODE	ends

TRANDATA	segment

	extrn	TranDataEnd	:byte
	extrn	CmdLineName	:byte

TRANDATA	ends

TRANSPACE	segment public byte

	extrn	TranSpaceEnd	:byte

TRANSPACE	ends




ifdef ROMDOS

;----------------------------------------------------------------------------
; Image of part of the BIOS data segment, named Bdata.
; Defines the following label:
;
;	BootFlags =	Boot options from CMOS RAM

include	msbdata.inc

; BootFlags bit we're concerned with:

BF_NoConfig	=	00000001b	; No config.sys processing

endif ; ROMDOS




; *******************************************************************
; START OF INIT PORTION
; This code is deallocated after initialization.

INIT	SEGMENT PUBLIC PARA
	extrn	ReadMessageClass:near, FixInitMessages:near

	extrn	AutoBat	:byte
	extrn	Badcspfl	:byte
        extrn   AllocedEnv      :byte
	extrn	Command_?_syn	:byte	
	extrn	Command_c_syn	:byte	
        extrn   Command_k_syn   :byte
	extrn	Command_d_syn	:byte	
	extrn	Command_e_syn	:byte	
	extrn	Command_f_syn	:byte	
	extrn	Command_m_syn	:byte	
	extrn	Command_p_syn	:byte	
	extrn	Command_y_syn	:byte	
	extrn	Comnd1_syn	:word 	
	extrn	Comnd1_addr	:dword	
	extrn	ComSpect	:byte
	extrn	Dswitch	:byte	
	extrn	EnvMax		:word
	extrn	EnvSiz		:word
	extrn	EqualSign	:byte
	extrn	Eswitch	:byte	
	extrn	Ext_msg	:byte	
	extrn	HelpMsgs:word
	extrn	InitMsgBuffer:byte
	extrn	InitMsgCount:byte
	extrn	InitMsgTable:word
	extrn	ResMsgCount:byte,ResMsgTable:word
	extrn	ResidentMsgBuffer:byte,ResidentMsgFileOffset:dword
	extrn	ResMsg101Ptr:word
	extrn	ResMsg102Ptr:word
	extrn	ResMsg103Ptr:word
	extrn	ResMsg104Ptr:word
	extrn	ResMsg105Ptr:word
	extrn	ResMsg106Ptr:word
	extrn	MsgEnvPath:dword
	extrn	MsgEnvName:byte
	extrn	MsgReadHeader:byte
	extrn	MsgReadSegment:word,MsgReadOffset:word,MsgReadLimit:word
	extrn	MsgReadClass:word,MsgReadHandle:word
	extrn	MsgFileOffset:dword,MsgFallbackPath:dword
	extrn	ParseInitCommand:word
	extrn	InitAdd	:dword
	extrn	InitEnd	:word
	extrn	Init_Parse	:dword	
	extrn	Internat_Info	:byte	
	extrn	KautoBat	:byte	
	extrn	Lcasea		:byte
	extrn	Lcasez		:byte
	extrn	Num_positionals	:word	
	extrn	OldEnv		:word
	extrn	Old_parse_ptr	:word	
	extrn	Parse_command	:byte	
	extrn	PrdAttm	:byte
	extrn	ResetEnv	:word	
	extrn	Scswitch	:byte
        extrn   Skswitch        :byte
	extrn	Space		:byte
	extrn	Triage_Add	:dword	
	extrn	TrnSize	:word
	extrn	Ucasea		:byte
	extrn	UsedEnv	:word

	extrn	PathString	:byte
        extrn   PathStrLen      :abs
        extrn   DefPathString   :byte
        extrn   DefPathStrLen   :abs
        extrn   PrmptString     :byte
        extrn   PrmptStrLen     :abs
        extrn   PrmptStrLen2    :abs
        extrn   ComspOffset     :word
	extrn	ComspString	:byte
        extrn   ComspStrLen     :abs
        extrn   ComspStrLen2    :abs
	extrn	Reloc_Table	:word
	extrn	FirstCom	:byte
	extrn	ResJmpTable	:dword

	extrn	TriageError	:near

	extrn	NUM_RELOC_ENTRIES	:abs

	extrn	DevFlag	:byte
	extrn	PathFlag	:byte
	extrn	ResidentCodeOffset:word
	extrn	LoadLow:byte
	extrn	RequestedCmdSize:word, RequestedInputSize:word
	extrn	Lswitch:byte, Uswitch:byte
	extrn	COMMAND_L_SYN:byte, COMMAND_U_SYN:byte
	extrn	COMMAND_LOW_SYN:byte, COMMAND_Z_SYN:byte, COMMAND_T_SYN:byte

	PUBLIC	ConProc
	PUBLIC	Init_ContC_SpecialCase

	assume	cs:ResGroup,ds:ResGroup,es:ResGroup,ss:ResGroup

	org	0
ZERO	=	$


ConProc:
	mov	sp,offset ResGroup:RStack	; must be first instruction
;
; We need to set the PSP to us right at start because Carousel needs
; to be lied to and it does not set PSP when it transfers control to
; us after loading us as an overlay. By setting PSP, we ensure that
; command.com is also not lied to.
;
        mov     ah,SET_CURRENT_PDB
        mov     bx,es
        int     21h

        mov     cx,800h
        mov     ax,5
        lea     di,InitMsgBuffer
        push    ds
        pop     es
        call    ReadMessageClass
        call    FixInitMessages
        mov     cx,1200h
        mov     ax,6
        lea     di,ResidentMsgBuffer
        push    ds
        pop     es
        call    ReadMessageClass
        mov     word ptr ResidentMsgFileOffset,dx
        mov     word ptr ResidentMsgFileOffset+2,cx
        call    FixResidentMessages

        public  CheckDosVersion
CheckDosVersion:
        mov     ah,GET_VERSION
	int	21h
	cmp	ax,EXPECTED_VERSION
	je	OkDos				; DOS version is ok

	mov	dx,word ptr InitMsgTable+2	; resolved bad-version message
	call	RPrint
	mov	ax,es
	cmp	es:PDB_Parent_Pid,ax		; if COMMAND is own parent,
Here:	jz	Here				;  loop forever
	
	int	20h				; otherwise, exit
okdos:
;
; Preserve the executable pathname from the environment trailer.
;
	public	SaveOriginalPath, SaveOriginalPathEnd
SaveOriginalPath:
	push	es
	mov	ah,GET_CURRENT_PDB
	int	21h
	mov	es,bx
	mov	es,es:PDB_Environ
	xor	ax,ax
	mov	di,ax
	dec	di
sopFindEnd:
	inc	di
	cmp	es:[di],ax
	jne	sopFindEnd
	inc	di
	inc	di
	cmp	word ptr es:[di],1
	jne	sopDone
	inc	di
	cmp	es:[di],al
	jne	sopDone
	inc	di
	mov	si,di
	mov	di,offset DATARES:OriginalComSpec
	push	ds
	mov	ax,es
	push	ds
	pop	es
	mov	ds,ax
sopCopy:
	lodsb
	stosb
	or	al,al
	jne	sopCopy
sopDone:
	pop	ds
	pop	es
SaveOriginalPathEnd label byte

;
;  Calculate and save the end of the INIT segment (which is also
;  the beginning of TRANGROUP).
;

        public  ComputeInitEnd,CheckHelp,Patch_segs
ComputeInitEnd:
        mov     dx,offset resgroup:TranStart    ; get end of init code
        mov     cl,4                            ; change to paragraphs
        shr     dx,cl                           ;
        mov     ax,cs                           ; get current segment
        add     ax,dx                           ; calculate segment of end of init
        mov     InitEnd,ax                      ; save this

;
;  Check for /? on the command line.  If found, display help text
;  and exit.
;
;  NOTE:  this routine may terminate the program, never returning.
;
	call	CheckHelp

;
; We have to patch the segment values for the various interrupt entry points.
; This is because we need to have the default addresses of the handlers in our
; stub before the relocation is done. These values will then be changed once
; the resident is relocated
;
	call	patch_segs

;
;  Turn APPEND off during initialization processing
;
        mov     ax,APPENDINSTALL                ; see if append installed
	int	2fh				;
	cmp	al,0				; append installed?
	je	set_msg_addr			; no - continue
	mov	ax,APPENDDOS			; see if append DOS version right
	int	2fh				;
	cmp	ax,-1				; append version correct?
	jne	set_msg_addr			; no - continue
        mov     ax,APPENDGETSTATE               ; Get the state of Append
	int	2fh				;
        mov     Append_State,bx                 ; save append state
        xor     bx,bx                           ; clear out state
        mov     ax,APPENDSETSTATE               ; Set the state of Append
	int	2fh				; set everything off

        public  set_msg_addr,InitInstanceSelect,init_cntry,get_XMMAddr
set_msg_addr:
	mov	di,offset resgroup:DataresEnd 	; get address of resident end
	mov	ResMsgEnd,di			; save it


        call    get_XMMAddr                     ; get XMM call address
	public	InitializeCommandState
InitializeCommandState:
	call	GetCommandState
        public  SetInitialEnvSize
SetInitialEnvSize:
	mov	EnvSiz,18h
;
; Check if this is the first instance of command.com. If not, we just exit
; this routine without moving any code.
; After the int 2fh, ds:si points at the resident jump table in the previous
; stub. We just have to copy this over
;
	
InitInstanceSelect:
ifndef ROMDOS
	mov	ax,GET_COMMAND_STATE	
else
	mov	ax,GET_ROMCOMMAND_STATE	
endif ; ROMDOS

	int	2fh
	assume	ds:nothing

	or	ax,ax
	jnz	first_com			;this is the first instance

ifdef	BETA3WARN
	%out	Take this out before we ship
	mov	es:Beta3Warned, 0ffh
endif

	mov	word ptr es:ResJmpTable,si		;save old stub jump table
	mov	word ptr es:ResJmpTable+2,ds
	assume	ds:RESGROUP
	public	InheritLFNFor
InheritLFNFor:
	mov	al,LFNForFlag
	mov	es:LFNForFlag,al
        public  InheritBufferSizes
InheritBufferSizes:
	mov	ax,InputBufSize
	mov	es:InputBufSize,ax
	mov	ax,CmdBufSize
	mov	es:CmdBufSize,ax
        public  AdjustInheritedEnv
AdjustInheritedEnv:
	mov	bx,EnvSiz
	cmp	ax,80h
	je	short aieStore
	add	ax,1bh
	mov	cl,4
	shr	ax,cl
	sub	bx,ax
aieStore:
	mov	es:EnvSiz,bx
	assume	ds:nothing
        public  FinishInstanceSelect
FinishInstanceSelect:
	jmp	short init_cntry

first_com:
	mov	es:FirstCom,1			;indicate first command.com

init_cntry:
	push	es
	pop	ds
	assume	ds:RESGROUP


	mov	ah,GETEXTCNTRY			; get extended country info
	mov	al,4				; get file ucase table
	mov	dx,-1				;
	mov	bx,-1				;
	mov	cx,5				; number of bytes we want
	mov	di,offset resgroup:Fucase_addr	; buffer for address
	int	21h				;

;	Bugbug:	conditionalize dbcs_vector stuff?
	push	ds				;
	mov	ax, (ECS_CALL shl 8) or GETLEADBTBL ;
	int	21h				;
	mov	bx,ds				; get segment to bx
	pop	ds				;
	mov	Dbcs_vector_addr,si			; save address of
	mov	Dbcs_vector_addr+2,bx			; dbcs vector


        public  SetParentFlags
SetParentFlags:
	mov	ax,word ptr ds:PDB_Parent_Pid 	; save parent process
	mov	Parent,ax
	or	ax,ax
	jz	short spfPermanent
	push	ds
	mov	ds,ax
	cmp	word ptr ds:PDB_Parent_Pid,0
	pop	ds
	jnz	short spfDone
spfPermanent:
	or	word ptr YSwitchFlags,24h
spfDone:
        public  InitializeTransientPlacement
InitializeTransientPlacement:
	mov	ax,word ptr ds:Pdb_Exit
	mov	word ptr OldTerm,ax
	mov	ax,word ptr ds:Pdb_Exit+2
	mov	word ptr Oldterm+2,ax


	mov	ax,offset ResGroup:EndTopCode + 15
	mov	cl,4				; ax = size of resident part of
	shr	ax,cl				;  command in paragraphs.  Add
	mov	cx,cs				;  this to CS and you get the
	add	ax,cx				;  segment of the TPA.

	mov	Res_tpa, ax			; Temporarily save the TPA segment
	and	ax, 0f000h
	add	ax, 01000h			; Round up to next 64K boundary
	jnc	TpaSet				; Memory wrap if carry set
	mov	ax, Res_tpa
TpaSet:
	mov	Ltpa,ax			; Good enough for the moment
	mov	ax,word ptr ds:PDB_Block_Len	; ax = # of paras given to command

	mov	Myseg1,ds			; These 3 variables are used as part of
	mov	Myseg2,ds			;  3 long ptrs that the transient will
	mov	Myseg,ds			;  use to call resident routines.
	mov	Myseg3,ds			; segment of msg retriever routine

	mov	Memsiz,ax			; Needed for execing other programs

;
; First reallocate the COMMAND size to its memory image
;
	public	ResizeCommand
ResizeCommand:
	push	ax
	mov	bx,400h
	add	bx,bx
	add	bx,bx
	add	bx,400h
	add	bx,0FFh
	add	bx,offset TRANGROUP:TranSpaceEnd
	jnc	rcSizeReady
	int	3
rcSizeReady:
	add	bx,15
	mov	cl,4
	shr	bx,cl
	push	bx
	mov	ax,offset RESGROUP:TranStart
	shr	ax,cl
	add	bx,ax
	mov	ah,SETBLOCK
	int	21h
	pop	dx
	pop	ax

;
; Compute maximum size of environment
;
        public  SetInitialEnvironment
SetInitialEnvironment:
        mov     EnvMax,(SIZE Environment + 15) / 16 + (EnvMaximum-zero + 15)/16 - 1
        mov     Trnsize,dx                      ; save size of transient in paragraphs

	sub	ax,dx				; max seg addr - # para's needed for transient
	mov	Trnseg,ax			;  = seg addr to load the transient at.
	mov	ax,ds:PDB_Environ			; ax = environment segment
        mov     EnvirSeg,ax                     ;
        or      ax,ax                           ; if there is no environment segment,
        jz      buildenv                        ; make one

        cmp     FirstCom,0                      ; if this is the first command.com,
        je      environpassed                   ; do a merge job (make sure COMSPEC exists)
;
; We allocate a buffer here just large enough to hold the 'PATH=' and
; the COMSPEC. After parsing, we will allocate an environment of the right
; size and free this buffer. We need this buffer because we no longer have an
; ENVIRONMENT segment but need a place to store the COMSPEC which can be
; given on the command line before we know the environment size. This routine
; will not return in case of an allocation error. It will either exit or hang
; depending on whether or not this is the first COMMAND.COM or not.
;
buildenv:
        call    alloc_env                       ; try to allocate buffer

environpassed:
	public	ReadInitialCommand
ReadInitialCommand:
	call	ExtractCmdLine
	push	cs
	pop	ds
        mov     es,ax                           ; and it load into es.
	assume	es:nothing

gottheenvir:
;
; Initialize the command drive
;
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
	inc	al
	mov	Comdrv,al

        mov     al,byte ptr ds:Fcb              ; al = default drive number for command
	or	al,al
	jz	nocomdrv			; no drive specified

	mov	ah,':'
	mov	Comdrv,al
	add	al,40h				; convert number to uppercase character

ifndef	ROMDOS

;	(Don't add drive specifier to ROM COMMAND COMSPEC.)

	std
        cmp     AllocedEnv,0                    ; if a new environment is being built,
        je      notwidenv                       ;  move the default comspec string in it

        mov     di,ComspOffset
        cmp     byte ptr es:[di+1],':'          ; drive specifier already exist?
        je      notwidenv                       ; yes, must have been inherited that way
	push	ds				;  2 bytes to make room for a drivespec.
	push	es				;  the drivespec is in ax and is copied
	pop	ds				;  on to the front of the string.

        lea     si,[di+MAX_COMSPEC-3]
        lea     di,[di+MAX_COMSPEC-1]
        mov     cx,MAX_COMSPEC - 2
	rep	movsb
	pop	ds
        mov     word ptr es:[di-1],ax

endif	;ROMDOS

notwidenv:
	cld					; add the drivespec to the string
        mov     word ptr AutoBat,ax             ; used to reference autoexec.bat
        mov     word ptr KautoBat,ax            ; used to reference kautoexe.bat 3/3/kk

nocomdrv:
        public  CheckWindowsStartup
CheckWindowsStartup:
        cmp     FirstCom,0
        je      short SelectInitialCommand
        mov     ax,1611h
        int     2fh
        or      ax,ax
        jnz     short SelectInitialCommand
        test    bl,20h
        jz      short cwsSaveTail
        and     byte ptr ss:YSwitchFlags,NOT 4
cwsSaveTail:
        lea     ax,[si+80h]
        mov     word ptr ss:ExecTopPath,ax
        mov     word ptr ss:ExecTopPath+2,ds
        and     bl,40h
        shl     bl,1
        or      byte ptr ss:YSwitchFlags,bl
        call    ParseWindowsSwitches

;*********************************
; parsing starts here
;*********************************

	public	SelectInitialCommand
SelectInitialCommand:
	push	cs
	push	cs
	pop	ds
	pop	es
	assume	ds:RESGROUP,es:RESGROUP
	cmp	byte ptr ds:PDB_Tail,7Fh
	jne	ShortInitialCommand
	mov	ax,word ptr ds:PDB_Environ
	or	ax,ax
	je	NoInitialArgs
	call	ParseInitialCommand
	jnc	InitialArgsReady
NoInitialArgs:
	jmp	ArgsDone
ShortInitialCommand:
	mov	si,80h
	lodsb
	mov	di,si
	xor	ah,ah
	add	di,ax
	mov	byte ptr [di],0Dh
InitialArgsReady:
	xor	cx,cx
	mov	Num_positionals,cx
	public	Parse_command_line
Parse_command_line:
	mov	di,offset RESGROUP:Parse_Command
	push	cs
	pop	es
	mov	cx,Num_positionals
	xor	dx,dx
	mov	Old_parse_ptr,si
	call	Init_Parse
	mov	Num_positionals,cx
	cmp	ax,END_OF_LINE
	je	NoInitialArgs
	cmp	ax,RESULT_NO_ERROR
	jne	parse_line_error
	jmp	parse_cont

	public	parse_line_error
parse_line_error:
	push	si				; save line position
	push	ax				; save error number
	cmp	ax,BADSWT_PTR			; Was error invalid switch?
        jnz     parse_line_error_disp           ; No - just issue message
	mov	di,si				; Get terminating pointer in DI
        mov     si,Old_parse_ptr                ; Get starting pointer in SI

init_chk_delim:
	cmp	si,di				; at end of parsed parameter?
        jz      parse_line_error_disp           ; Yes - just display message
	lodsb					;
	cmp	al,Space			; Skip blank spaces
	jz	init_chk_delim			;
	cmp	al,TAB_CHR			; Skip tab characters
	jz	init_chk_delim			;

	cmp	al,Rswitchar			; Switch?
        jnz     parse_line_error_disp           ; No - just issue message
	lodsb					; Get the char after the switch

	ifdef	DBCS
	call	ItestKanj			; Is it DBCS?
        jnz     parse_line_error_disp           ; Yes - can't be /C or /K
	endif

	call	iupconv 			; upper case it
	cmp	al,Scswitch			; it is /C?
        jnz     check_k_too                     ;
	pop	dx				; even up stack
	pop	dx				; even up stack
	jmp	setSSwitch			; Yes - go set COMMAND /C

check_k_too:
        cmp     al,Skswitch                     ; it is /K?
        jnz     parse_line_error_disp           ;
	pop	dx				; even up stack
	pop	dx				; even up stack
        jmp     setKSwitch                      ; Yes - go set COMMAND /K

parse_line_error_disp:
	pop	ax				; restore error number
	pop	si				; restore line position
	mov	dx,ax				; get message number
	call	PrintResidentMessage
	call	CrLf
        jmp     short Parse_command_line        ; continue parsing

	public	InitSwitchHandlers
InitSwitchHandlers:
SetYSwitch:
	or	YSwitchFlags,10h		; indicate /Y entered
	jmp	short Parse_command_line
SetZSwitch:
	or	YSwitchFlags,1
	jmp	short Parse_command_line
SetFSwitch:
	cmp	fFail,-1
	jne	setfailok
	mov	ax,Moreargs_ptr
	jmp	short parse_line_error
setfailok:
	mov	fFail,-1			; fail all INT 24s.
	jmp	Parse_command_line
SetDSwitch:
;
; Flag no date/time prompting.
;
	cmp	Dswitch,0			; has /D switch been set?
	je	setdateok
	mov	ax,Moreargs_ptr
	jmp	short parse_line_error
setdateok:
	and	YSwitchFlags,NOT 4
	inc	Dswitch
	mov	PrdAttm,1
	jmp	Parse_command_line

	public	SetSSwitch,SetKSwitch
	public	ParseSwitches
ParseSwitches:
parse_cont:
	mov	ax,Comnd1_Syn
	cmp	ax,offset RESGROUP:Command_f_syn
	je	SetFSwitch
	cmp	ax,offset RESGROUP:Command_p_syn
	je	SetPSwitch
	cmp	ax,offset RESGROUP:Command_d_syn
	je	SetDSwitch
	cmp	ax,offset RESGROUP:Command_c_syn
	je	SetSSwitch
	cmp	ax,offset RESGROUP:Command_k_syn
	je	SetKSwitch
	cmp	ax,offset RESGROUP:Command_y_syn
	je	SetYSwitch
	cmp	ax,offset RESGROUP:Command_z_syn
	je	SetZSwitch
	cmp	ax,offset RESGROUP:Command_e_syn
	je	SetESwitch
	cmp	ax,offset RESGROUP:Command_m_syn
	je	SetMSwitch
	jmp	short CheckBufferSwitches

SetPSwitch:
;
; We have a permanent COMMAND switch /P.  Flag this and stash the
; termination address.
;
	cmp	PermCom,0			; has /p switch been set?
	jne	MoreInitArgs
permcomok:
	inc	PermCom
	mov	word ptr OldTerm,offset DATARES:LodCom_Trap
	mov	word ptr OldTerm+2,ds
;
; make sure that we display the date and time.	if the flag was not
; initialized, set it to indicate yes, do prompt.
;
	cmp	byte ptr PrdAttm,-1
	jnz	Parse_command_line_jmp		; keep parsing
        mov     byte ptr PrdAttm,0              ; if not set explicit, set to prompt

Parse_command_line_jmp: 			;
        jmp     parse_command_line              ; keep parsing

SetKSwitch:
	or	SemiPermCom,1
	jmp	short SetSorKSwitch
SetSSwitch:
	mov	PermCom,0
	and	YSwitchFlags,NOT 4
	cmp	FirstCom,0
	je	SetSorKSwitch
	or	SemiPermCom,2
SetSorKSwitch:
	public	SaveSingleCommand
SaveSingleCommand:
	mov	SingleCom,si			; point to the rest of the command line
	mov	word ptr SingleCom+2,ds
        mov     byte ptr PrdAttm,1              ; no date or time either, explicit
	jmp	ArgsDone
;
; Look for environment-size setting switch
;
; The environment size is represented in decimal bytes and is
; converted into pargraphs (rounded up to the next paragraph).
;

SetESwitch:
	mov	di,offset RESGROUP:Eswitch
	call	CheckSizeSwitch
	jc	MoreInitArgs
	add	bx,15
	mov	cl,4
	shr	bx,cl
	mov	EnvSiz,bx
	jmp	Parse_command_line
SetMSwitch:
	cmp	Ext_msg,SET_EXTENDED_MSG
	jne	setMswitchok
MoreInitArgs:
	mov	ax,Moreargs_ptr
	jmp	parse_line_error
setMswitchok:
	mov	Ext_msg,SET_EXTENDED_MSG
	jmp	Parse_command_line
CheckBufferSwitches:
	cmp	ax,offset RESGROUP:COMMAND_L_SYN
	je	SetLSwitch
	cmp	ax,offset RESGROUP:COMMAND_U_SYN
	je	SetUSwitch
	jmp	short CheckLowSwitch
SetLSwitch:
	mov	di,offset RESGROUP:Lswitch
	call	CheckSizeSwitch
	jc	MoreInitArgs
	mov	RequestedCmdSize,bx
	jmp	Parse_command_line
SetUSwitch:
	mov	di,offset RESGROUP:Uswitch
	call	CheckSizeSwitch
	jc	MoreInitArgs
	mov	RequestedInputSize,bx
	jmp	Parse_command_line
ArgsDoneJ:
	jmp  ArgsDone

SetLowSwitch:
	cmp	LoadLow,0
	jne	MoreInitArgs
	mov	LoadLow,1
	jmp	Parse_command_line
SetTSwitch:
	test	byte ptr YSwitchFlags+1,2
	jnz	MoreInitArgs
	or	byte ptr YSwitchFlags+1,2
	jmp	Parse_command_line
CheckLowSwitch:
	cmp	ax,offset RESGROUP:COMMAND_LOW_SYN
	je	SetLowSwitch
	cmp	ax,offset RESGROUP:COMMAND_T_SYN
	je	SetTSwitch


;
; We have a non-switch character here.
;
	public	ChkOtherArgs
ChkOtherArgs:
	push	ds				;
	push	si				; save place in command line
	lds	si,Comnd1_Addr			; get address of filespec
	assume	ds:nothing			;

	mov	dx,si				; put in dx also
        mov     ax,(OPEN shl 8) or 22h          ; Read/write, deny writes
	int	21h
	jnc	short OpenDeviceOk
	jmp	short ChkSrchSpec		; Wasn't a file
OpenDeviceOk:
	mov	bx,ax
	mov	ax,IOCTL shl 8
	int	21h
	test	dl,80h
	jnz	IsaDevice

BadSetCon:					;
	mov	ah,CLOSE			; Close initial handle, wasn't a device
	int	21h
	jmp	short ChkSrchSpec

IsaDevice:
	xor	dh,dh
	or	dl,3				; Make sure has CON attributes
	mov	ax,(IOCTL shl 8) or 1
	int	21h
	jc	BadSetCon			; Can't set attributes - quit
	mov	dx,bx				; Save new handle

	cmp	es:DevFlag,1
	jz	DevErr

	push	cx
	mov	cx,3
	xor	bx,bx

rcclloop:					; Close 0,1 and 2
	mov	ah,CLOSE
	int	21h
	inc	bx
	loop	rcclloop

	mov	bx,dx				; New device handle
	mov	ah,XDUP
	int	21h				; Dup to 0
	mov	ah,XDUP
	int	21h				; Dup to 1
	mov	ah,XDUP
	int	21h				; Dup to 2
	mov	ah,CLOSE
	int	21h				; Close initial handle
	pop	cx
	pop	si				; restore position of command line
	pop	ds				;
;
; Register the fact that we already have redirected the output and cannot do
; it again
;
	inc	es:DevFlag			;
        jmp     Parse_command_line              ; continue parsing

DevErr:
	pop	si
	pop	ds
	mov	dx,1
        call    PrintResidentMessage            ; "Too many parameters"
        call    CrLf
	jmp	Parse_command_line

        public  ChkSrchSpec,DevErr
ChkSrchSpec:					; Not a device, so must be directory spec

        cmp     es:PathFlag,1                   ; already set COMSPEC?
        jz      DevErr                          ; yes, error

        inc     es:PathFlag                     ; mark that we have a path
;
; We have to override the passed environment. Allocate a buffer for use now.
; This buffer will later be replaced by a proper environment
;
        call    alloc_env                       ; environment buffer
	mov	es,ax
	assume	es:nothing
	push	si				; remember location of file
	xor	cx,cx				; clear cx for counting

countloop:
	lodsb					; get a character
	inc	cx				; increment counter
        cmp     al,END_OF_LINE_OUT              ; are we at end of line?
	jnz	countloop			; no - keep counting

	mov	al,Space
	dec	si				; move back one
        mov     byte ptr [si],al                ; put a space at end of line
;
; We now know how long the new pathspec for command.com is.  Time to
; figure out how long the current COMSPEC setting is, and then to move
; all the environment data up, throwing that COMSPEC setting away, and
; preparing to append the new COMSPEC.  ComspOffset (the offset of
; where the filespec exists in the environment) is updated as well.
;
        push    cx                              ;
        mov     cx,ENVBIG                       ;
        mov     di,ComspOffset                  ; get location of COMSPEC
        mov     al,0                            ;
        repne   scasb                           ; find the end of COMSPEC
        mov     si,di                           ;
comp_endenv:                                    ;
        scasb                                   ; end of env?
        je      got_endenv                      ; yes
        repne   scasb                           ;
        jmp     comp_endenv                     ;
got_endenv:                                     ;
        mov     cx,di                           ;
        sub     cx,si                           ;
        mov     di,ComspOffset                  ;
        sub     di,ComspStrLen                  ;
        push    ds                              ;
        push    es                              ;
        pop     ds                              ;
        rep     movsb                           ;
        dec     di                              ; copy in new COMSPEC=
        push    cs                              ;
        pop     ds                              ;
        assume  ds:ResGroup                     ;
        mov     si,offset RESGROUP:ComspString  ;
        mov     cx,ComspStrLen                  ;
        rep     movsb                           ;
        mov     ComspOffset,di                  ;
        pop     ds                              ;
        assume  ds:nothing                      ;
        pop     cx                              ;

        pop     si                              ; get new comspec location back

ComtrLoop:
	lodsb
	dec	cx
	cmp	al,Space
	jz	SetComsr
	stosb

	ifdef	DBCS
	xor	ah,ah
	endif

	jcxz	setcomsr

	ifdef	DBCS

	push	ds				; Make sure we have
	push	cs				;  local DS for
	pop	ds				;  ItestKanj
	call	ItestKanj
	pop	ds				; restore parser ds
	jz	ComtrLoop
	dec	cx
	movsb
	inc	ah
	jcxz	setcomsr

	endif

	jmp	short comtrloop

        public  SetComsr,SetComsrRet,SetComsrBad
setcomsr:
	push	cx

	push	cs				; Get local segment
	pop	ds				;
	assume	ds:ResGroup			;

	push	ds
	mov	si,offset ResGroup:ComSpect
	mov	cx,14

	mov	al,es:[di-1]

	ifdef	DBCS
	or	ah,ah
	jnz	iNotRoot			; Last char was KANJI second byte, might be '\'
	endif

	cmp	al,RDirChar
	jnz	iNotRoot
	inc	si				; Don't make a double /
	dec	cx

iNotRoot:
	rep	movsb

        mov     dx,ComspOffset                  ; Now lets make sure its good!
	push	es
	pop	ds

	mov	ax,(OPEN shl 8) or 40h
	int	21h				; Open COMMAND.COM
	pop	ds
	jc	SetComsrBad			; No COMMAND.COM here
	mov	bx,ax				; Handle
	mov	ah,CLOSE
	int	21h				; Close COMMAND.COM

SetComsrRet:
	pop	cx
	pop	si
	pop	ds				;
	assume	ds:ResGroup			;

	push	cs				; Make sure local ES is
	pop	es				;  restored
	jmp	Parse_command_line			; continue parsing command line

SetComsrBad:
	mov	dx,word ptr InitMsgTable+14	; unable to load COMMAND

;	Note:  we're about to make a near call to TriageError, which
;	lives in a different segment and group.  Some linkers will
;	generate a warning like "Possible fix-up overflow".  We're
;	ok, though, because we all fit in 64 KB and, at init time,
;	we're still all together.

	call	triageError
	cmp	ax, 65
	jnz	doprt
	mov	dx,word ptr InitMsgTable+18	; access denied
DoPrt:
	call	RPrint
	mov	si,offset ResGroup:ComSpect
        mov     di,ComspOffset
	mov	cx,14
	rep	movsb				; get my default back

	jmp	short SetComsrRet

;*********************************
; Parsing Ends Here
;*********************************

ArgsDone:
	public	ApplyInitialBufferSizes
ApplyInitialBufferSizes:
	mov	es,EnvirSeg
	cmp	FirstCom,0
	je	aibsDone
	cmp	RequestedInputSize,0
	je	aibsCommand
	mov	ax,RequestedInputSize
	mov	InputBufSize,ax
aibsCommand:
	cmp	RequestedCmdSize,0
	je	aibsDone
	mov	ax,RequestedCmdSize
	mov	CmdBufSize,ax
	add	ax,ax
	add	ax,ax
	mov	dx,CmdBufSize
	add	ax,dx
	cmp	dx,0FFh
	jbe	aibsSize
	mov	dx,0FFh
aibsSize:
	add	ax,dx
	add	ax,8
	add	ax,offset TRANGROUP:TranSpaceEnd+15
	mov	cl,4
	shr	ax,cl
	sub	ax,TrnSize
	add	TrnSize,ax
	sub	TrnSeg,ax
aibsDone:
	assume	es:nothing			;

; Set the original PSP before resident data may be relocated.
        public  PrepareOriginalPSP
PrepareOriginalPSP:
        cmp     PermCom,0
        jz      short ComReturns
        push    es
        mov     ah,SET_CURRENT_PDB
        mov     bx,ds
        mov     es,bx
        int     21h
	mov	di,PDB_EXIT			; Diddle the addresses in my header
	mov	ax,offset DATARES:LodCom_Trap
	stosw
	mov	ax,ds
	stosw
	mov	ax,offset DATARES:Ctrlc_Trap
	stosw
	mov	ax,ds
	stosw
	mov	ax,offset DATARES:CritErr_Trap
	stosw
	mov	ax,ds
	stosw
	mov	word ptr ds:PDB_Parent_Pid,ds 	; Parent is me forever
        pop     es

        public  ComReturns
ComReturns:
	mov	ax,word ptr ds:PDB_Parent_Pid
	mov	Parent,ax			; Save parent
	mov	word ptr ds:PDB_Parent_Pid,ds 	; Parent is me
	mov	ax,word ptr ds:PDB_Jfn_Table
	mov	Io_save,ax			; Get the default stdin and out
	mov	word ptr Com_ptr+2,ds		 	; set all these to resident
	mov	word ptr Com_fcb1+2,ds
	mov	word ptr Com_fcb2+2,ds
	mov	di,offset ResGroup:ComSpec

        mov     si,ComspOffset
        cmp     AllocedEnv,0

	mov	ax,ds				; Xchg es,ds
	push	es
	pop	ds
	mov	es,ax

        jne     CopyComsp                       ; All set up for copy

	push	cs
	pop	ds

	mov	si,offset ResGroup:ComspString
	push	es
	push	di
	call	IfindE
	mov	si,di
	push	es
	pop	ds
	pop	di
	pop	es
	jnc	CopyComsp

ComSpecNofnd:
        mov     si,offset ResGroup:ComspString
        add     si,ComspStrLen
	push	cs
	pop	ds

	assume	es:ResGroup

CopyComsp:
	mov	es:ComSpecName,di
	mov	es:PutBackComSpec.SubstPtr,di	; Save ptr to beginning of comspec path
	cmp	byte ptr [si+1],':'             ; Is there a drive specifier in comspec
	jnz	CopyComspLoop			; If not, do not skip over first 2 bytes
	add	es:PutBackComSpec.SubstPtr,2

CopyComspLoop:
	lodsb
	stosb
	cmp	al,'\'
	jne	short CopyComspTest
	mov	es:ComSpecName,di
CopyComspTest:
	or	al,al
	jnz	CopyComspLoop
	mov	es:Comspec_end,di			; Save ptr to end of comspec path
	dec	es:Comspec_end
	mov	ah,es:comdrv
	add	ah,'A'-1
	mov	es:PutBackDrv,ah			; save drive letter


;
; The routine below sets up the exact resident size of COMMAND. If this is not
; the first COMMAND, then the resident code is not duplicated and the resident
; size is just the data. If we are the first COMMAND, it checks if we are to
; be loaded into HIMEM. If not, then the resident size includes the code and
; the data otherwise it is just the data.
; 
        public  ConfigureResidentMessages
ConfigureResidentMessages:
	call	SelectResidentMessages		; choose retained messages
	call	Setup_res_end			;put resident size in ResSize

	push	cs
	pop	ds
	assume	ds:RESGROUP


Public EnvMaximum
EnvMaximum:

;
; Compute checksum right now before we can get corrupted and save it
;

	push	ds
	mov	si,offset RESGROUP:TranStart
	mov	cl,4
	shr	si,cl
	mov	dx,ds
	add	dx,si
	mov	ds,dx
	mov	si,100h
	mov	cx,offset TRANGROUP:TranDataEnd - 100H

	cld
	shr	cx,1
	xor	dx,dx
Ichksum:
	lodsw
	add	dx,ax
	adc	dx,0
	loop	Ichksum

	pop	ds
        mov     Sum,dx                          ; store checksum
	mov	SumHigh,0

        cmp     byte ptr PrdAttm,0              ;
        jnz     NoBatchSeg                      ; don't do autoexec or date time
;
; Allocate batch segment for d:/autoexec.bat + no arguments
;
	mov	bx,((SIZE BatchSegment) + 15 + 1 + 0fh)/16 ;eg
        mov     ah,ALLOC                        ;
        int     21h                             ;
        jc      NoBatchSeg                      ; didn't allocate - pretend no batch
        mov     Batch,ax                        ; save batch segment

	public	nobatchseg
nobatchseg:
        mov     bx,EnvirSeg                     ; get old environment segment
        mov     OldEnv,bx                       ; save it

        mov     UsedEnv,0                       ; initialize env size counter
	mov	ds,bx
	assume	ds:nothing

	xor	si,si
	mov	di,si
;
; This is the maximum allowed size for the environment
;
	mov	bx,4096 - 1 			; max. allowed env. size
	mov	EnvMax,bx
				 
	shl	bx,1
	shl	bx,1
	shl	bx,1
	shl	bx,1
	mov	EnvMax, bx			; convert envmax to bytes
	dec	bx				; dec by one to leave room for double 0
	xor	dx,dx				; use dx to indicate that there was
						; no environment size error.
public NxtStr
NxtStr:
	call	GetStrLen			; get the size of the current env string

;Bugbug: Can use ss here to address UsedEnv

        push    ds                              ; get addressability to environment
        push    cs                              ;                       counter
        pop     ds                              ;
        assume  ds:ResGroup
        add     UsedEnv,cx                      ; add the string length to env size
        pop     ds                              ;
	assume	ds:nothing
	cmp	cx,1				; end of environment was encountered.
	jz	EnvExit
	sub	bx,cx
	jae	OkCpyStr			; can't fit in all of enviroment.
	inc	dx				; out of env space msg must be displayed
	jmp	short EnvExit
OkCpyStr:
	jmp	NxtStr
EnvExit:

	push	cs
	pop	ds
	assume	ds:ResGroup
	or	dx,dx				; dx will be non-zero if error
	jz	EnvNoErr
	mov	dx,word ptr InitMsgTable+6	; out of environment space
	call 	RPrint

	public	EnvNoErr
EnvNoErr:
	mov	ax,EnvSiz
	mov	cl,4
	shl	ax,cl
	cmp	ax,UsedEnv
	ja	envBufferSpace
	mov	ax,UsedEnv
envBufferSpace:
	cmp	CmdBufSize,80h
	je	st_envsize
	add	ax,CmdBufSize
	add	ax,12
st_envsize:
	add	ax,15
	shr	ax,cl
	mov	EnvSiz,ax

	cmp	Batch,0			;eg did we set up a batch segment?
	jnz	DoDate				;eg yes - go initialize it
	jmp	NoDttm				; don't do autoexec or date time
;
; allocate batch segment for d:/autoexec.bat + no arguments
;
DoDate:
	mov	ax,Batch			;eg get batch segment
	mov	EchoFlag,3			; set batch echo
	mov	Nest,1				; g set nest flag to 1 batch
	mov	es,ax
;
; initialize the segment
;
	xor	di,di
	mov	al,BATCHTYPE
	stosb
	mov	al,1				; g initialize echo for batch exit
	stosb					; g
;
; Hosebag! This guy does not use the struct fields to init the BatchSegment
;
	xor	ax,ax				; initialize to zero
	stosb					; clear out BatchEOF

	stosw					; g batch segment of last job - batlast
	stosw					; g segment for for
	stosb					; g for flag
	stosw					; position in file - batseek
	stosw
;
; clean out the parameters
;
	mov	ax,-1				; initialize to no parameters
	mov	cx,10
	rep	stosw
;
; decide whether we should grab the default drive
;
	cmp	byte ptr AutoBat,0
	jnz	NoAutSet
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
	add	al,Ucasea

	mov	AutoBat,al
	mov	KautoBat,al			; 3/3/kk

NoAutSet:
;
; copy in the batch file name (including nul)
;
	mov	si,offset ResGroup:AutoBat
	mov	cx,8
	rep	movsw
	movsb					; move in carriage return to terminate string

ifdef ROMDOS

; Check to see if the Boot Options indicate that startup processing
; should be omitted.  If so, skip the open, and pretend that there is
; no autoexec.bat.

	push	es			; save current ES
	mov	ax,BDATA
	mov	es,ax
	assume	es:BDATA
	mov	ax,es:BootFlags		; get boot options from BIOS
	pop	es			; restore previous ES
	assume	es:RESGROUP
	test	al,BF_NoConfig		; flag set to supress processing?
	jnz	NOABAT			; if so, skip autoexec processing

endif ; ROMDOS

        public  OpenAutoexec,NoAbat,NoKabat,AccDenErr,OpenErr,Drv0
OpenAutoexec:
        mov     dx,offset ResGroup:AutoBat
        mov     ax,(OPEN shl 8) or 40h
        int     21h
        jc      NoAbat
        mov     bx,ax
        mov     ax,FILE_TIMES shl 8
        int     21h
        push    es
        push    bx
        les     bx,DosCommandState
        mov     es:[bx+6],cx
        mov     es:[bx+8],dx
        pop     bx
        pop     es
        mov     ah,CLOSE
        int     21h
        jmp     short Drv0
NoAbat:
        push    ax
        call    Setup_Seg
        mov     word ptr Triage_Add+2,ax
        pop     ax
        call    Triage_Add
        cmp     ax,65
        jz      AccDenErr
        mov     dx,offset ResGroup:Internat_Info
        mov     ax,INTERNATIONAL shl 8
        int     21h
        jc      NoKabat
        cmp     bx,KOREA_COUNTRY_CODE
        jnz     OpenErr
        mov     di,BatFile
        mov     si,offset ResGroup:KautoBat
        mov     cx,8
        rep     movsw
        movsb
        mov     dx,offset ResGroup:KautoBat
        mov     ax,(OPEN shl 8) or 40h
        int     21h
        jc      NoKabat
        mov     bx,ax
        mov     ah,CLOSE
        int     21h
        jmp     short Drv0
NoKabat:
        call    Triage_Add
        cmp     ax,65
        jnz     OpenErr
AccDenErr:
        mov     dx,ResMsg127Ptr
        call    RPrint
OpenErr:
	mov	es,Batch			; not found--turn off batch job
	mov	ah,DEALLOC
	int	21h
	mov	Batch,0			; after dealloc in case of ^c
	mov	EchoFlag,1
	mov	Nest,0				;g indicate no batch in progress

        public  NoDttm
NoDttm:

Copyright:
	public	Copyright
;	Bugbug:	remove Copyright label.

	cmp	SingleCom,0
	jnz	Drv0				; do not print header for /C
	mov	dx,word ptr InitMsgTable+10	; copyright message
	call	RPrint

Drv0:						; Reset APPEND state
	push	ds				; save data segment
	push	cs				; Get local segment into DS
	pop	ds				;
	mov	ax,APPENDSETSTATE			; Set the state of Append
	mov	bx,Append_State 			;  back to the original state
	int	2fh				;
	pop	ds				; get data segment back
;
;Check FirstCom set previously to see if this is the first instance of
;command.com. If not, we do not move command.com. Instead, we copy over the
;jump table from the previous stub to the current stub.
;
	cmp	FirstCom,1			;first command.com?
	jz	move_code			;yes, move it

	push	es
	push	ds

	push	ds
	pop	es
	mov	di,offset DATARES:Int2f_Entry

	mov	ds,word ptr es:ResJmpTable+2	;get segment address
	mov	si,word ptr es:ResJmpTable		;get offset address

	mov 	cx,NUM_RELOC_ENTRIES 			;number of dword ptrs
	shl	cx,1
	shl	cx,1				;size of table in bytes

	cld
	rep	movsb				;copy the jump table
;
;Check if the resident code is in HMA. We assume that it is in HMA if its 
;code segment > 0f000h. If in HMA, we set the ComInHMA flag
;
	cmp	es:[di-2],0f000h			;is resident code in HMA?
	jb	res_low			;no, dont set flag

	mov	es:ComInHMA,1			;indicate code in HMA

res_low:
	pop	ds
	pop	es
	jmp	short finish_init
;
;Now, we can move the resident code to its final location, either to HIMEM
;or to overlay the messages in the data segment if the user has not used the
;/msg switch.
;
        public  move_code
move_code:
	call	Move_res_code			;move the code

finish_init:
        public  FinishResidentMove
FinishResidentMove:
        mov     al,FirstCom
        push    ax
        call    Move_res_data
        mov     ax,ResidentDataSeg
        mov     ds,ax
        call    InstallInitVectors
        pop     ax
        call    setup_for_messages
        mov     ax,168FH
        mov     bx,ds
        mov     dh,4
        int     2fh
        mov     ah,SET_CURRENT_PDB
        mov     bx,ds
        mov     es,bx
        int     21h
        public  FinishResidentPSP
FinishResidentPSP:
        cmp     PermCom,0
        je      short frpVector
        mov     di,PDB_EXIT
        mov     ax,offset DATARES:LodCom_Trap
        stosw
        mov     ax,ds
        stosw
        mov     ax,offset DATARES:Ctrlc_Trap
        stosw
        mov     ax,ds
        stosw
        mov     ax,offset DATARES:CritErr_Trap
        stosw
        mov     ax,ds
        stosw
        mov     word ptr ds:PDB_Parent_Pid,ds
        mov     Parent,ds
frpVector:
        mov     al,FirstCom
        or      al,PermCom
        jz      short frpPointers
        push    es
        mov     ax,(GET_INTERRUPT_VECTOR shl 8) or 2eh
        int     21h
        mov     word ptr Int2eHandler,bx
        mov     word ptr Int2eHandler+2,es
        pop     es
        mov     dx,offset DATARES:Int2e_Trap
        mov     ax,(SET_INTERRUPT_VECTOR shl 8) or 2eh
        int     21h
frpPointers:
        mov     word ptr ds:PDB_Parent_Pid,ds
        mov     word ptr Com_ptr+2,ds
        mov     word ptr Com_fcb1+2,ds
        mov     word ptr Com_fcb2+2,ds
        push    ds
        mov     ax,offset DATARES:EndInit
        push    ax
        cmp     SingleCom,0
        jz      short frpTransfer
        call    CopySingleCommand
frpTransfer:
        retf

;*** CopySingleCommand -- Preserve the single command in transient storage.
;
;	ENTRY:	SingleCom = far pointer to a CR-terminated command
;	EXIT:	Command and word length copied to the dynamic command buffer
;	USED:	ax, cx, si, di, ds, es, flags
;
	public	CopySingleCommand
CopySingleCommand	proc	near
	assume	ds:RESGROUP,es:nothing
	lds	si,dword ptr SingleCom
	mov	ax,ds
	mov	di,offset RESGROUP:TranStart
	mov	cl,4
	shr	di,cl
	add	ax,di
	mov	es,ax
	mov	di,offset TRANGROUP:TranSpaceEnd+2
	add	di,CmdBufSize
	add	di,InputBufSize
	add	di,7
	push	di
	push	es
	push	ds
	pop	es
	mov	di,si
	mov	al,0Dh
	mov	cx,0FFFFh
	repne	scasb
	pop	es
	not	cx
	pop	di
	dec	cx
	mov	es:[di-2],cx
	inc	cx
	cld
	rep	movsb
	ret
CopySingleCommand	endp

;
;	Get length of string pointed to by DS:SI.  Length includes NULL.
;	Length is returned in CX
;
	public	GetStrLen
GetStrLen:
	xor	cx,cx
NxtChar:
	lodsb
	inc	cx
	or	al,al
	jnz	NxtChar
	ret
;
; If the transient has been loaded in TranSeg, then we need to use that
; segment for calls to routines in the transient area. Otherwise, the current
; code segment is used
; Segment returned in AX.
;
        public  Setup_Seg
Setup_Seg:
	mov	ax,TrnSeg
	cmp	TrnMvFlg, 1			; Has transient portion been moved
	jz	setup_end
	push	bx
	mov	bx,cs
	mov	ax,offset ResGroup:TranStart
	shr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	add	ax,bx
	pop	bx
setup_end:
	ret


;***	RPrintParse - display parse error message
;
;	ENTRY	DX = parse error #
;
;	EXIT	nothing
;
;	USED	flags
;
;	EFFECTS
;	  Message is displayed on stdout.

RPrintParse	proc
	public	PrintResidentMessage
PrintResidentMessage label near

	assume	ds:ResGroup,ss:ResGroup

	push	dx				; preserve DX
	xchg	bx,dx				; bx = parse error #
						; dx = saved BX
	dec	bx				; bx = parse error index, from 0
	shl	bx,1				; bx = offset in word table
	mov	bx,ParsMsgPtrs[bx]			; bx = address of message pointer
	mov	bx,[bx]				; bx = ptr to error msg
	xchg	bx,dx				; dx = ptr to error msg
						; bx = restored
	call	RPrint				; print the message
	pop	dx				; restore DX
	ret

RPrintParse	endp



        public  IfindE,ifind,Icount0,Iscasb1,Iscasb2,IupConv
IfindE:
	call	ifind				; find the name
	jc	ifind2				; carry means not found
	jmp	short Iscasb1 			; scan for = sign
;
; on return of find1, es:di points to beginning of name
;
ifind:
	cld
	call	Icount0 			; cx = length of name
	mov	es,EnvirSeg
	xor	di,di

ifind1:
	push	cx
	push	si
	push	di

Ifind11:
	lodsb

	ifdef	DBCS

	call	ItestKanj
	jz	NotKanj4
	dec	si
	lodsw
	inc	di
	inc	di
	cmp	ax,es:[di-2]
	jnz	Ifind12
	dec	cx
	loop	Ifind11
	jmp	short Ifind12
NotKanj4:

	endif

	call	IupConv
	inc	di
	cmp	al,es:[di-1]
	jnz	Ifind12
	loop	Ifind11

Ifind12:
	pop	di
	pop	si
	pop	cx
	jz	Ifind2
	push	cx
	call	Iscasb2 			; scan for a nul
	pop	cx
	cmp	byte ptr es:[di],0
	jnz	Ifind1
	stc					; indicate not found

Ifind2:
	ret

Icount0:
	push	ds
	pop	es
	mov	di,si

	push	di				; count number of chars until "="
	call	Iscasb1
	jmp	short Icountx
	push	di				; count number of chars until nul
	call	Iscasb2

Icountx:
	pop	cx
	sub	di,cx
	xchg	di,cx
	ret

Iscasb1:
	mov	al,Equalsign			; scan for an =
	jmp	short Iscasbx

Iscasb2:
	xor	al,al				; scan for a nul

Iscasbx:
	mov	cx,100h
	repnz	scasb
	ret


; ****************************************************************
; *
; * ROUTINE:	 IUPCONV    (ADDED BY EMG 4.00)
; *
; * FUNCTION:	 This routine returns the upper case equivalent of
; *		 the character in AL from the file upper case table
; *		 in DOS if character if above  ascii 128, else
; *		 subtracts 20H if between "a" and "z".
; *
; * INPUT:	 DS	      set to resident
; *		 AL	      char to be upper cased
; *		 FUCASE_ADDR  set to the file upper case table
; *
; * OUTPUT:	 AL	      upper cased character
; *
; ****************************************************************


IupConv proc	near				
	assume	ds:ResGroup			;

	cmp	al,80h				; see if char is > ascii 128
	jb	other_fucase			; no - upper case math
	sub	al,80h				; only upper 128 chars in table
	push	ds				;
	push	bx				;
	lds	bx,dword ptr fucase_addr+1		; get table address
	add	bx,2				; skip over first word
	xlat	ds:byte ptr [bx]			; convert to upper case
	pop	bx				;
	pop	ds				;
	jmp	short iupconv_end			; we finished - exit

other_fucase:					;
	cmp	al,Lcasea			; if between "a" and "z",
	jb	iupconv_end			;     subtract 20h to get
	cmp	al,Lcasez			; upper case equivalent.
	ja	iupconv_end			;
	sub	al,20h				; Change lower-case to upper

iupconv_end:					;
	ret

IupConv endp					;


init_contc_specialcase:
						; This routine is called if control-C
	add	sp,6				;  is type during the date/time prompt
	push	si				;  at initialization time.  The desired
	mov	si,dx				;  response is to make it look like the
	mov	word ptr [si+1],0d00h			;  user typed <CR> by "popping" the
	pop	si				;  INT 21h stuff off the stack, putting
	iret					;  a <CR> in the user's buffer, and
						;  returning directly to the user.
						; In this case the user is TCODE.


;*** SelectResidentMessages -- Choose the retained resident message extent.
        public  SelectResidentMessages
SelectResidentMessages proc near
        push    bx
        push    ds
        push    es
        push    ax
        push    dx
        push    di
        mov     ax,cs
        mov     ds,ax
        mov     es,ax
        cmp     PermCom,0
        jne     short srmRetain
        cmp     FirstCom,0
        je      short srmCheckMsg
srmRetain:
        mov     di,offset RESGROUP:ExtMsgEnd
        mov     ResMsgEnd,di
        jmp     short srmDone
srmCheckMsg:
        cmp     Ext_msg,1
        jne     short srmDone
        mov     dx,2
        call    PrintResidentMessage
srmDone:
        pop     di
        pop     dx
        pop     ax
        pop     es
        pop     ds
        pop     bx
        ret
SelectResidentMessages endp

;*** setup_for_messages -- Save and install the message service vector.
;
        public  setup_for_messages
setup_for_messages	proc	near
;
;	ENTRY:	ds = resident data segment
;		al = first COMMAND flag saved before moving data
;	USED:	ax, bx, dx, flags
;
	cmp	PermCom,0
	jne	smSaveVector
	cmp	FirstCom,0
	je	smDone
smSaveVector:
	push	ax
	push	es
	mov	ax,(GET_INTERRUPT_VECTOR shl 8) or 2Fh
	int	21h
	mov	word ptr Int2fHandler,bx
	mov	word ptr Int2fHandler+2,es
	pop	es
	pop	ax
	or	al,al
	je	smDone
;
; M005; !!!SLIMIEST CAROUSEL HACK OFF ALL!!!
; M005; Carousel plays around with the interrupt vector tables. He saves it
; M005; before loading a new command.com. Then, it takes hold of the current
; M005; command.com's PSP and then looks at all interrupt vectors whose
; M005; segment matches the command.com PSP and then updates these segments
; M005; to the new command.com's PSP in his saved vector table. Whenever we
; M005; we pop into his menu, he puts this saved table into the vector table.
; M005; If we now quit, Carousel just wipes out command.com's arena and then
; M005; issues a terminate. Unfortunately, the int 2fh vector is pointing at
; M005; the command.com that was wiped out and so the next int 2fh call will
; M005; bomb. To prevent Carousel from doing this clever(1**$$#) patching, we
; M005; renormalize our int 2fh pointer so that its cs is not the same as the
; M005; command.com PSP. Now, he does no such patching and our int 2fh vector
; M005; remains nice and happy. The renormalized pointer points at a far 
; M005; jump to the actual int 2fh entry point.
;
	push	ds				; M005
	mov	dx,offset DATARES:Carousel_i2f_Hook ; M005
	sub	dx,10h				; renormalize offset; M005
	mov	ax,ds				; M005
	inc	ax				; Relocated cs ; M005
	mov	ds,ax				; M005
	mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 2Fh
	int	21h
	pop	ds				; M005
	mov	word ptr Carousel_i2f_Hook+3,ds	; M005
						; patch in the cs for jump
smDone:
	ret
setup_for_messages	endp


;*** InstallInitVectors -- Install termination, control-C and error vectors.
;   ENTRY: DS = resident data segment
;   USED:  AX, DX, flags
        public  InstallInitVectors
InstallInitVectors proc near
        mov     dx,offset DATARES:LodCom_Trap
        mov     ax,(SET_INTERRUPT_VECTOR shl 8) or 22h
        mov     word ptr ds:PDB_EXIT,dx
        mov     word ptr ds:PDB_EXIT+2,ds
        int     21h
        mov     dx,offset DATARES:Ctrlc_Trap
        inc     al
        int     21h
        mov     dx,offset DATARES:CritErr_Trap
        inc     al
        int     21h
        ret
InstallInitVectors endp





;***	CheckHelp - print help text and exit if /? is on command line
;
;	ENTRY	command-line tail at 81h
;
;	EXIT	return if /? not found
;		terminate if /? found
;
;	USED	AX,BX,CX,DX,SI,DI
;
;	EFFECTS	Help text displayed if /? found on command line

CheckHelp	proc

	assume	cs:RESGROUP,ds:RESGROUP,es:RESGROUP,ss:RESGROUP

	mov	si,81h			; DS:SI = ptr to command-line tail
	mov	di,offset RESGROUP:Parse_Command
					; ES:DI = ptr to primary parse block
	xor	cx,cx			; CX = # positional param's found
	xor	dx,dx			; DX will be ptr to result buffer

chParse:
	call	Init_Parse		; call system parser

	cmp	ax,END_OF_LINE
	je	chRet			; end of command line, no /? found
	cmp	ax,RESULT_NO_ERROR
	je	chWhich			; valid syntax element found
	jmp	chParse			; go parse more

chWhich:
	cmp	Comnd1_Syn,offset RESGROUP:Command_?_Syn
	je	chHelp			; /? found - display help & exit
	cmp	Comnd1_Syn,offset RESGROUP:Command_C_Syn
	je	chRet			; /c found - ignore rest of line
        cmp     Comnd1_Syn,offset RESGROUP:Command_K_Syn
        je      chRet                   ; /k found - ignore rest of line
	jmp	chParse			; anything else - ignore, keep looking

chHelp:
	lea	bx,HelpMsgs			; message number/pointer records
	mov	cx,16				; number of help messages
	add	bx,2				; first text pointer
chHelpNext:
	mov	dx,[bx]
	call	RPrint				; display msg
	add	bx,4				; next text pointer
	dec	cx
	jnz	chHelpNext
chHelpDone:
	int	20h				; terminate program

chRet:	ret

CheckHelp	endp




;*** Setup_res_end -- Determine the resident size of COMMAND.
;
;	ENTRY:	ResMsgEnd = end of retained resident data
;	EXIT:	ResSize = resident size in paragraphs
;	USED:	ax, cx, dx, flags
;
GET_HMA_ADDR		equ	4a02h

	public	Setup_res_end
Setup_res_end	proc	near
	push	ds
	mov	ax,cs
	mov	ds,ax
	assume	ds:RESGROUP
	call	GetResidentDataSize
	xor	ax,ax
	cmp	FirstCom,1
	jne	not_first
	push	bx
	push	cx
	mov	ax,(SET_CTRL_C_TRAPPING shl 8) or 06h
	int	21h
	pop	cx
	xor	ax,ax
	and	dh,10h
	pop	bx
	jne	not_first
	mov	ax,offset CODERES:EndCode
not_first:
	add	cx,ax
	add	cx,15
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cx,1
	mov	ResSize,cx
	pop	ds
	assume	ds:nothing
	ret
Setup_res_end	endp

ifndef	ROMDOS

;*** Move_res_code -- Move or reuse the resident code.
;
;	ENTRY:	ResMsgEnd = end of resident data
;
;	EXIT:	ResidentCodeOffset = offset of resident code
;		Resident entry stubs patched for the final location.
;
;	USED:	ax, bx, cx, dx, bp, si, di, flags
;
	public	Move_res_code
	.386
Move_res_code	proc	near
	push	ds
	push	es
	mov	ax,cs
	mov	ds,ax
	assume	ds:RESGROUP
	mov	ResidentCodeOffset,offset RESGROUP:StartCode
	mov	ax,(SET_CTRL_C_TRAPPING shl 8) or 06h
	int	21h
	and	dh,10h
	jnz	short	move_high
	jmp	load_low
move_high:
	mov	bx,offset CODERES:EndCode
	test	word ptr YSwitchFlags,4
	jnz	short	hma_failed
	mov	si,offset RESGROUP:StartCode
	mov	cx,bx
	shr	cx,2
	xor	edx,edx
	cld
checksum_loop:
	lodsd
	xor	edx,eax
	loop	checksum_loop
	mov	ResidentChecksum,edx
	mov	ax,4A04h
	int	2Fh
	xor	ax,ax
	mov	edx,dword ptr StartCode
	mov	bp,0
	cmp	es:[di+4],ax
	je	short	hma_failed
find_resident:
	cmp	es:[di+2],ax
	je	short	next_resident
	lea	si,[di+10h]
	cmp	es:[bp+si],edx
	je	short	check_resident
next_resident:
	mov	di,es:[di+6]
	test	di,di
	jnz	short	find_resident
	jmp	short alloc_hma
check_resident:
	mov	edx,ResidentChecksum
	mov	bp,4
	cmp	es:[bp+si],edx
	jne	short	hma_failed
	mov	di,si
	mov	ComInHMA,1
	jmp	short save_code_offset
alloc_hma:
	mov	di,0FFFFh
	mov	ax,GET_HMA_ADDR
	int	2Fh
	cmp	di,0FFFFh
	mov	ComInHMA,1
	jne	short	setup_move
hma_failed:
	mov	ComInHMA,0
	call	GetResidentDataSize
	mov	ax,offset CODERES:EndCode
	add	cx,ax
	add	cx,15
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cx,1
	mov	ResSize,cx
load_low:
	push	ds
	pop	es
	mov	di,ResMsgEnd
	mov	bx,offset RESGROUP:ExtMsgEnd
	cmp	di,bx
	jne	short	setup_move
	mov	cl,4
	add	di,0Fh
	and	di,0FFF0h
	jmp	short patch_up
setup_move:
	mov	si,offset RESGROUP:StartCode
	mov	cx,offset CODERES:EndCode
	cld
	push	di
	rep	movsb
	pop	di
save_code_offset:
	mov	ResidentCodeOffset,di
patch_up:
	mov	bx,ds
	call	Patch_stub
	pop	es
	pop	ds
	assume	ds:nothing
	ret
Move_res_code	endp
	.8086

else	;ROMDOS

;***	Move_res_code - ROMDOS version - locate ROM resident

Move_res_code	proc

	push	es

	invoke	FindROMRes		; ES:DI = ptr to ROM resident code
	mov	bx,ds			;resident data segment
	call	patch_stub

	pop	es
	ret

Move_res_code	endp

	assume	ds:NOTHING		; to match ending assume above

endif	;ROMDOS


;*** Alloc_env -- This routine allocates the temporary environment for the
; Init code to initialize the COMSPEC. This is not a complete environment. 
; Later on, at EndInit time, a proper sized environment is allocated and
; the contents of this temporary environment are copied to it. This routine
; will not be called in case a valid environment is passed to command.com
;
;       ENTRY:  FirstCom and initial EnvirSeg set
;
;       EXIT:   ax = EnvirSeg = segment of newly allocated environment segment
;
;       REGISTERS AFFECTED: ax,bx,cx,dx
;

	public	Alloc_env
Alloc_env	proc	near
        assume  ds:nothing
	
        push    ds
	push	es
	push	si
	push	di

        push    ss
        pop     ds
        assume  ds:RESGROUP

        mov     ax,EnvirSeg

        cmp     AllocedEnv,0
        je      alloc_cont
        jmp     alloc_done

alloc_cont:
        sub     di,di                           ; default start
        mov     bx,SIZE Environment             ; default size needed

        cmp     FirstCom,0                      ; first COMMAND.COM?
        je      alloc_seg                       ; no
;
;   Check EnvirSeg;  if non-zero, then scan it for PATH and COMSPEC;
;   Record their respective locations and do not add the default vars.
;
        or      ax,ax
        jz      alloc_new                       ; no previous environment

        mov     es,ax
        assume  es:nothing

find_path:
        mov     al,0
        sub     di,di
comp_path:
        scasb                                   ; end of env?
        je      find_prompt                     ; yes
        dec     di
        mov     cx,PathStrLen
        mov     si,offset RESGROUP:PathString
        repe    cmpsb
        je      got_path
        mov     cx,256
        repne   scasb                           ; find next NULL
        jmp     comp_path

got_path:
        mov     PathString,al                    ; don't add it

find_prompt:
        sub     di,di
comp_prompt:
        scasb                                   ; end of env?
        je      find_comspec                    ; yes
        dec     di
        mov     cx,PrmptStrLen2
        mov     si,offset RESGROUP:PrmptString
        repe    cmpsb
        je      got_prompt
        mov     cx,256
        repne   scasb                           ; find next NULL
        jmp     comp_prompt

got_prompt:
        mov     PrmptString,al                   ; don't add it

find_comspec:
	call	FindComspec
	jc	got_envend

        mov     ComspOffset,di

find_envend:
        sub     di,di
        mov     cx,ENVBIG                       ; max env size
comp_envend:
        dec     cx                              ;
        scasb                                   ; end of env?
        je      got_envend                      ; yes
        repne   scasb
        jmp     comp_envend

got_envend:
        dec     di
        lea     bx,[di+SIZE Environment]        ; add room for the basics
;
;   We want to fall through to alloc_new and set up default
;   path and prompt ONLY IF this is the first process;  in all other
;   cases, we assume it is a bad idea to try editing the user's environment
;
        push    ds
        mov     ds,ds:[PDB_Parent_Pid]
        cmp     ds:[PDB_Parent_Pid],0           ; is parent's parent pid field 0?
        pop     ds
        jne     alloc_seg                       ; no, we're not the first process
                                                ; so don't muck with the env.
alloc_new:
        inc     AllocedEnv                      ; note we have virgin env.

alloc_seg:
;
; Allocate default environment size
;
        mov     cx,bx                           ; save byte-granular size in CX
        add     bx,15
        shr     bx,1
        shr     bx,1
        shr     bx,1
        shr     bx,1                            ; BX = # paras
	mov	ah,ALLOC
	int	21h
        jnc     init_ok
        jmp     init_nomem                      ; insufficient memory, error
;
; If a previous environment existed (ie, DI != 0), then copy it into
; the new buffer
;
init_ok:
	mov	es,ax
        assume  es:nothing                      ; es = temp env segment

        or      di,di
        jz      copy_path

        push    cx
        push    ds
        mov     ds,EnvirSeg
        assume  ds:nothing
        sub     si,si
        mov     cx,di
        sub     di,di
        rep     movsb
        pop     ds
        assume  ds:RESGROUP
        pop     cx
        sub     cx,di

copy_path:
;
; First clear out (the rest of) the buffer
;
        push    di
        sub     ax,ax
        rep     stosb
        pop     di
;
; Initialize the path string (PATH=) first
;
        mov     si,offset RESGROUP:PathString   ; DS:SI -> "PATH=\0"
        cmp     byte ptr [si],al                ; add it?
        je      init_prompt                     ; no
        mov     cx,PathStrLen+1                 ;
        rep     movsb                           ;
        cmp     AllocedEnv,al                   ; virgin env?
        je      init_prompt                     ; no
;
; Establish a more reasonable default for the PATH
;
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
        add     al,'A'                          ; convert to letter
        mov     [DefPathString],al              ;

        mov     dl,0                            ; get dir for default drive
        push    ds                              ;
        push    es                              ;
        pop     ds                              ;
        mov     byte ptr [di],'\'               ;
        lea     si,[di+1]                       ; set DS:SI -> available space
        mov     ah,Current_Dir                  ;
        int     21h                             ;
        pop     ds                              ;

        mov     cx,DefPathStrLen+1              ;
        mov     dx,offset RESGROUP:DefPathString
        mov     si,dx                           ;
        mov     ah,CHDir                        ;
        int     21h                             ;
        jc      init_prompt                    ; default path does not exist

init_setpath:
        mov     dx,di                           ; success
        push    ds                              ; so restore prev dir
        push    es                              ;
        pop     ds                              ; DS:DX -> prev dir
        mov     ah,CHDir                        ;
        int     21h                             ;
        pop     ds                              ;

        dec     di                              ; then copy in DefPathString
        rep     movsb                           ; DS:SI -> default command path
;
; Initialize the default prompt
;
init_prompt:
        push    di                              ;
        sub     ax,ax                           ;
        mov     cx,64                           ; insure any data read in
        rep     stosb                           ; from Current_Dir is zapped
        pop     di                              ;

        cmp     AllocedEnv,al                   ; virgin env?
        je      init_comspec                    ; no
        mov     si,offset RESGROUP:PrmptString  ; DS:SI -> "PROMPT=$P$G\0"
        cmp     byte ptr [si],al                ; add it?
        je      init_comspec                    ; no
        mov     cx,PrmptStrLen+1                ;
        rep     movsb                           ;
;
; Initialize the Comspec string
;
init_comspec:
        cmp     ComspOffset,ax                  ; add it?
        jne     init_done                       ; no
        lea     ax,[di+ComspStrLen]             ;
        mov     ComspOffset,ax                  ;
        mov     si,offset RESGROUP:ComspString  ; DS:SI -> "COMSPEC=\\COMMAND.COM\0"
        mov     cx,ComspStrLen2+1               ;
        rep     movsb                           ;

init_done:
        mov     ax,es                           ; return env seg in ax
        mov     EnvirSeg,ax                     ; save env seg
        inc     AllocedEnv                      ; remember that *we* alloced it

alloc_done:
	pop	di
	pop	si
	pop	es
        pop     ds
        assume  ds:nothing
	ret

init_nomem:
;
;We call the error routine from here. This routine never returns. It either
;terminates COMMAND with error( if it is not the first invocation ) or hangs
;the system ( if it is the first COMMAND.COM ).
;
	call	alloc_error

Alloc_env	endp


;*** Alloc_error: This routine just jumps to the actual label where we 
; check if this is a permanent or secondary command.com and take the 
; appropriate action.
;
;	ENTRY:	ds = RESGROUP = DATARES
;
;	EXIT:	None - does not return
;
;	REGISTERS AFFECTED: Does not matter
;

public Alloc_error
Alloc_error	proc	near

	jmp	RESGROUP:BadMemErr

Alloc_error	endp

;*** ExtractCmdLine -- Save and remove CMDLINE from the environment.
;
;	ENTRY:	ax = environment segment
;	EXIT:	ax preserved; InitCmdLine contains a CR-terminated string
;	USED:	bx, cx, si, di, ds, es, flags
;
	public	ExtractCmdLine
ExtractCmdLine	proc	near
	push	ax
	mov	es,ax
	xor	di,di
	push	cs
	pop	ds
	assume	ds:RESGROUP,es:nothing
	mov	si,offset TRANGROUP:CmdLineName
	add	si,offset RESGROUP:TranStart
	xor	bx,bx
	lodsb
	mov	bl,al
	mov	ax,di
eclFind:
	cmp	es:[di],al
	je	eclCopy
	push	si
	mov	cx,bx
	repe	cmpsb
	pop	si
	je	eclCopy
	dec	di
	mov	cx,4096
	repne	scasb
	jmp	short eclFind
eclCopy:
	xchg	si,di
	push	si
	push	ds
	push	es
	pop	ds
	pop	es
	assume	ds:nothing,es:RESGROUP
	mov	di,offset RESGROUP:InitCmdLine
eclCopyChar:
	lodsb
	stosb
	or	al,al
	jnz	eclCopyChar
	mov	byte ptr es:[di-1],0Dh
	pop	di
	push	ds
	pop	es
	assume	es:nothing
	cmp	byte ptr [di],0
	je	eclDone
	sub	di,bx
eclNext:
	cmp	byte ptr [si],0
	je	eclFixComspec
eclMove:
	lodsb
	stosb
	or	al,al
	jnz	eclMove
	jmp	short eclNext
eclFixComspec:
	push	ds
	push	di
	push	ss
	pop	ds
	call	FindComspec
	jc	eclTerm
	mov	ss:ComspOffset,di
eclTerm:
	pop	di
	pop	ds
	xor	al,al
	stosb
eclDone:
	pop	ax
	ret
ExtractCmdLine	endp

;*** FindComspec -- Find COMSPEC in the supplied environment.
;
;	ENTRY:	DS = resident data, ES = environment, AL = 0
;	EXIT:	Carry clear and DI points past COMSPEC= if found
;	USED:	cx, si, di, flags
;
	public	FindComspec
FindComspec	proc	near
	assume	ds:RESGROUP,es:nothing
	sub	di,di
fcNext:
	scasb
	je	fcNotFound
	dec	di
	mov	cx,ComspStrLen
	mov	si,offset RESGROUP:ComspString
	repe	cmpsb
	je	fcFound
	mov	cx,256
	repne	scasb
	jmp	short fcNext
fcFound:
	clc
	ret
fcNotFound:
	stc
	ret
FindComspec	endp


;*** ParseInitialCommand -- Skip the program name in an extended command.
;
;	ENTRY:	InitCmdLine contains the saved CMDLINE value
;	EXIT:	Carry clear and SI points to the command arguments on success
;	USED:	ax, cx, dx, si, di, es, flags
;
	public	ParseInitialCommand
ParseInitialCommand	proc	near
	push	ds
	pop	es
	mov	si,offset RESGROUP:InitCmdLine+1
	cmp	byte ptr [si],0
	je	piFailed
	mov	di,offset RESGROUP:ParseInitCommand
	xor	cx,cx
	xor	dx,dx
	call	Init_Parse
	cmp	ax,END_OF_LINE
	je	piFailed
	cmp	ax,RESULT_NO_ERROR
	jne	piFailed
	ret
piFailed:
	stc
	ret
ParseInitialCommand	endp

;*** Patch_stub -- This routine patches in the segment and offset values in
; the stub table of the various entry points in the resident code segment.
; Some of them are interrupt entry points and some of them are entries from
; the transient to the resident code segment.
;
;	ENTRY:	ds = RESGROUP
;		es:di = segment:offset of final location of resident code
;		bx = resident data segment
;
;	EXIT:	All segments and offsets patched into the stub table
;
;	REGISTERS AFFECTED: ax, bx, cx, dx, si, di
; 
;
Patch_stub	proc	near

	assume	ds:RESGROUP
	
	push	es

	push	es
	push	bx
	pop	es				;es = resident data segment
	pop	bx				;bx = resident code segment
	mov	dx,di
	mov	di,offset DATARES:Int2f_Entry
	mov	si,offset RESGROUP:Reloc_Table
;
;bx:dx = segment:offset of resident code segment
;es:di = entry point table in resident data stub
;ds:si = offset table in INIT segment -- offsets of code entry points now
;
	mov	cx,NUM_RELOC_ENTRIES		;number of entry points
patchlp:
	lodsw				;get current offset
	add	ax,dx			;offset it by code seg location 
	stosw				;store offset
	mov	ax,bx			
	stosw				;store segment 
	loop	patchlp

	pop	es
	ret

Patch_stub	endp

;*** Patch_segs -- This routine patches the segment values in the dword 
; pointers that the stub uses to jump to the actual handler. These values 
; are temporarily needed to handle these interrupts if they occur before
; the resident is relocated to its final position and all the addresses of
; the handlers have been updated.
;
;	ENTRY:	es = PSP segment = code segment
;
;	EXIT:	Current segment values patched into the jump table in the
;		stub.
;
;	REGISTERS AFFECTED: ax, cx, di
;

Patch_segs	proc	near

	mov	di,offset RESGROUP:Int2f_Entry
	mov	cx,4			;we have to patch 4 handlers
	add	di,2
	mov	ax,es

pseglp:
	stosw				;store the segment value
	add	di,2			;skip the next offset value
	loop	pseglp

	ret

Patch_segs	endp


;*** get_XMMAddr -- This routine gets the call address for the XMM driver
; by issuing the appropriate int 2fh. This is stored in a stub variable 
; and is used by the stub when we have to jump to the resident in HMA
;
;	ENTRY:	ds = RESGROUP
;
;	EXIT:	XMMCallAddr = XMM driver far call address
;
;	REGISTERS AFFECTED:
;

get_XMMAddr	proc	near
	assume	ds:RESGROUP

	push	es

	mov	ax,XMM_MULTIPLEX SHL 8 + XMM_INSTALL_CHECK
	int	2Fh
	cmp	al,80h			; Q: installed
	jne	short cXMMexit	;   N: set error, quit
;
; get the XMM control functions entry point, save it, we
; need to call it later.
;
	mov	ax,XMM_MULTIPLEX SHL 8 + XMM_FUNCTION_ADDR
	int	2Fh

	mov	word ptr [XMMCallAddr], bx
	mov	word ptr [XMMCallAddr+2],es

cXMMexit:
	pop	es
	ret				; done

get_XMMAddr	endp

;*** GetCommandState -- Get the DOS command state pointer.
;
;	ENTRY	DS = resident segment
;	EXIT	DosCommandState initialized; ES preserved
;
	public	GetCommandState
GetCommandState proc near
	push	es
	mov	ah,GET_IN_VARS
	int	21h
	les	bx,es:[bx+12h]
	mov	bx,es:[bx+13h]
	mov	bx,es:[bx+4]
	add	bx,20h
	les	bx,es:[bx]
	mov	word ptr DosCommandState,bx
	mov	word ptr DosCommandState+2,es
	pop	es
	ret
GetCommandState endp



;*** CheckProtman -- Test for an installed protocol manager.
;
;	EXIT:	Carry set if the device cannot be opened.
;	USED:	ax, bx, dx, flags
;
ProtmanName	db	"PROTMAN$",0
	public	CheckProtman, Move_res_data
CheckProtman	proc	near
	mov	dx,offset RESGROUP:ProtmanName
	mov	ax,OPEN shl 8
	int	21h
	jc	cpDone
	mov	bx,ax
	mov	ah,CLOSE
	int	21h
cpDone:
	ret
CheckProtman	endp

;*** Move_res_data -- Allocate and move resident data.
;
;	ENTRY:	ds = original resident data segment
;		ResidentCodeOffset = source of resident code
;
;	EXIT:	ResidentDataSeg = final resident data segment
;		OriginalDataSeg = original allocation
;		SS addresses the final resident data segment if moved.
;
;	USED:	ax, bx, cx, dx, flags
;
Move_res_data	proc	near
	assume	ds:RESGROUP
	mov	ResidentDataSeg,ds
	mov	OriginalDataSeg,ds
	cmp	LoadLow,1
	jne	mdCheckTop
	jmp	mdDone
mdCheckTop:
	test	byte ptr YSwitchFlags+1,2
	jnz	mdCheckNetwork
	test	word ptr YSwitchFlags,4
	jz	mdUpper
	test	word ptr YSwitchFlags,80h
	jnz	mdUpper
	mov	ax,160Ah
	int	2Fh
	test	ax,ax
	jz	mdUpper
mdCheckNetwork:
	call	CheckProtman
	jnc	mdUpper
	mov	ah,ALLOC
	or	bx,-1
	int	21h
	mov	ax,4
	add	ax,ResSize
	mov	cx,offset CODERES:EndTopCode+15
	sub	cx,offset CODERES:EndCode
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cx,1
	add	ax,cx
	add	ax,EnvSiz
	add	ax,40h
	add	ax,3
	sub	bx,ax
	jbe	mdUpper
	mov	ah,ALLOC
	int	21h
	jc	mdUpper
	push	ax
	mov	ah,ALLOC
	mov	bx,ResSize
	add	bx,cx
	int	21h
	pop	bx
	pushf
	push	ax
	push	es
	mov	es,bx
	mov	ah,DEALLOC
	int	21h
	pop	es
	pop	ax
	popf
	jc	mdUpper
	or	PermCom,2
	cmp	ComInHMA,0
	jne	mdAllocated
	or	PermCom,4
	mov	bx,offset CODERES:ExecTopRet
	mov	Reloc_Table+8,bx
	jmp	short mdAllocated
mdUpper:
	mov	ax,(ALLOCOPER shl 8) or 3
	mov	bx,1
	int	21h
	jnc	mdStrategy
	jmp	mdDone
mdStrategy:
	mov	ah,ALLOCOPER
	mov	al,1
	mov	bx,41h
	int	21h
	jc	mdFailed
	mov	ah,ALLOC
	mov	bx,ResSize
	int	21h
mdAllocated:
	mov	bx,ds
	jnc	mdCopy
mdFailed:
	jmp	mdRestoreStrategy
mdCopy:
	mov	ResidentDataSeg,ax
	push	es
	push	di
	push	si
	mov	cx,ResMsgEnd
	xor	si,si
	mov	di,si
	mov	es,ax
	cld
	rep	movsb
	mov	bx,ResidentDataSeg
	push	di
	push	es
	push	ds
	mov	ax,bx
	dec	ax
	mov	es,ax
	mov	es:[1],bx
	mov	ax,ds
	dec	ax
	mov	ds,ax
	mov	si,8			; arena name
	mov	di,si
	mov	cx,si
	rep	movsb
	pop	ds
	pop	es
	pop	di
	mov	ax,es
	add	ax,ResSize
	mov	word ptr es:PDB_Block_Len,ax
	cmp	ComInHMA,0
	jne	mdPointers
	cmp	FirstCom,1
	jne	mdPointers
	push	di
	push	es
	mov	si,ResidentCodeOffset
	mov	cx,offset CODERES:EndCode
	test	PermCom,2
	jz	mdCopyCode
	mov	cx,offset CODERES:EndTopCode
mdCopyCode:
	rep	movsb
	pop	es
	pop	di
	push	bx
	mov	bx,es
	call	Patch_stub
	pop	bx
mdPointers:
	mov	word ptr es:PDB_JFN_Pointer+2,bx
	mov	es:MySeg,bx
	mov	es:MySeg1,bx
	mov	es:MySeg2,bx
	mov	es:MySeg3,bx
	cmp	PermCom,0
	je	mdStack
	mov	word ptr es:OldTerm+2,bx
mdStack:
	pop	si
	pop	di
	pop	es
	mov	ss,bx
mdRestoreStrategy:
	mov	ah,ALLOCOPER
	mov	al,1
	mov	bx,0
	int	21h
mdDone:
	ret
Move_res_data	endp

;*** ParseWindowsSwitches -- Read /E, /L and /U from the Windows tail.
;   ENTRY: DS:SI = Windows command tail, SS = resident data segment
;   EXIT:  numeric requests saved for normal initialization
        public  ParseWindowsSwitches
ParseWindowsSwitches proc near
        cld
        lodsb
        xor     cx,cx
        mov     ss:Num_positionals,cx
pwsNext:
        mov     di,offset RESGROUP:Parse_Command
        push    cs
        pop     es
        mov     cx,ss:Num_positionals
        xor     dx,dx
        call    dword ptr ss:Init_Parse
        mov     ss:Num_positionals,cx
        cmp     ax,END_OF_LINE
        je      short pwsDone
        cmp     ax,RESULT_NO_ERROR
        jne     short pwsNext
        mov     ax,ss:Comnd1_Syn
        cmp     ax,offset RESGROUP:Command_c_syn
        je      short pwsDone
        cmp     ax,offset RESGROUP:Command_k_syn
        je      short pwsDone
        cmp     ax,offset RESGROUP:Command_e_syn
        je      short pwsEnvironment
        cmp     ax,offset RESGROUP:Command_l_syn
        je      short pwsCommand
        cmp     ax,offset RESGROUP:Command_u_syn
        jne     short pwsNext
        mov     di,offset RESGROUP:Uswitch
        call    CheckSizeSwitch
        jc      short pwsNext
        mov     ss:RequestedInputSize,bx
        jmp     short pwsNext
pwsEnvironment:
        mov     di,offset RESGROUP:Eswitch
        call    CheckSizeSwitch
        jc      short pwsNext
        add     bx,15
        mov     cl,4
        shr     bx,cl
        mov     ss:EnvSiz,bx
        jmp     short pwsNext
pwsCommand:
        mov     di,offset RESGROUP:Lswitch
        call    CheckSizeSwitch
        jc      short pwsNext
        mov     ss:RequestedCmdSize,bx
        jmp     short pwsNext
pwsDone:
        xor     al,al
        mov     ss:Uswitch,al
        mov     ss:Lswitch,al
        mov     ss:Eswitch,al
        ret
ParseWindowsSwitches endp

;*** CheckSizeSwitch -- Reject a repeated numeric switch.
;
;	ENTRY:	ES:DI = switch flag
;	EXIT:	Carry clear and BX = parsed value if first occurrence
;	USED:	bx, di, flags
;
	public	CheckSizeSwitch
CheckSizeSwitch	proc	near
	cmp	byte ptr es:[di],0
	jne	cssRepeated
	inc	byte ptr es:[di]
	mov	di,offset RESGROUP:Comnd1_Addr
	mov	bx,es:[di]
	clc
	ret
cssRepeated:
	stc
	ret
CheckSizeSwitch	endp

;*** GetResidentDataSize -- Return the retained data size in bytes.
;
;	EXIT:	cx = size, rounded if resident messages are retained
;	USED:	cx, flags
;
	public	GetResidentDataSize
GetResidentDataSize	proc	near
	mov	cx,ss:ResMsgEnd
	cmp	cx,offset RESGROUP:ExtMsgEnd
	jne	grdsDone
	add	cx,15
	and	cx,0FFF0h
grdsDone:
	ret
GetResidentDataSize	endp

;*** FixResidentMessages - resolve resident messages and input characters
;
;   Entry: DS and SS address resident data; class pointers are relative.
;   Uses:  BX, CX, flags.  Call once after loading the resident class.
;
        public  FixResidentMessages
FixResidentMessages proc near
	mov	bx,offset RESGROUP:ResMsgTable
	xor	cx,cx
	mov	cl,ss:ResMsgCount
FixResidentNext:
	add	[bx+2],bx
	add	bx,4
	loop	FixResidentNext
	inc	ss:ResMsg101Ptr
	inc	ss:ResMsg102Ptr
	inc	ss:ResMsg103Ptr
	inc	ss:ResMsg104Ptr
	inc	ss:ResMsg105Ptr
	inc	ss:ResMsg106Ptr
	ret
FixResidentMessages endp


	public	InitCmdLine
InitCmdLine	db	400h+2 dup (0)	; equals sign, command and terminator

INIT	ENDS

	END
