	page ,132
;	SCCSID = @(#)uinit.asm	4.5 85/12/04
;	SCCSID = @(#)uinit.asm	4.5 85/12/04
TITLE	COMMAND Initialization messages
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;	M003	SR	07/16/90	Added Lh_OffUnlink to the offset
;				patch table (Reloc_Table) for UMB
;				support
;

.XCREF
.XLIST
include comsw.asm
include dossym.inc
include pdb.inc
include comseg.asm
include ifequ.asm
.LIST
.CREF

addr macro sym,name
     public name
     ifidn <name>,<>

	    dw offset resgroup:sym
     else

name	    dw	offset resgroup:sym
     endif
     endm

CODERES	segment

	extrn	ContC		:near
	extrn	DskErr		:near
	extrn	Int_2e		:near
	extrn	MsgInt2fHandler	:near
	extrn	Exec_Ret	:near
	extrn	TRemCheck	:far
	extrn	TrnLodCom1	:near
	extrn	MsgRetriever	:near
	extrn	LodCom		:near
	extrn	THeadFix	:far
	extrn	Lh_OffUnlink	:far	; M003
	extrn	BadMemEntry	:near
	extrn	ReleaseInit	:far

CODERES	ends


;;ENVIRONMENT	SEGMENT PUBLIC PARA		;AC000;
;;	EXTRN	ECOMSPEC:BYTE
;;ENVIRONMENT ENDS

TRANCODE	SEGMENT PUBLIC BYTE		;AC000;
	extrn	Printf_init:FAR
	extrn	Triage_Init:FAR
	extrn	append_parse:FAR		;AN054;
TranCode    ENDS

INIT		SEGMENT PUBLIC PARA		;AC000;


	public	icondev
	public	BADCSPFL
	public	COMSPECT
	public	AUTOBAT
	public	space
	public	PRDATTM
	public	INITADD
	public	print_add
        public  AllocedEnv
	public	scswitch
        public  skswitch
	public	ucasea
;;	public	ECOMLOC
	public	equalsign
	public	lcasea
	public	lcasez
        public  ComspOffset
        public  ComspString
        public  ComspStrLen
        public  ComspStrLen2
	public	EnvMax
	public	initend
	public	trnsize
	public	resetenv			;AC000;
	public	ext_msg 			;AC000;
	public	num_positionals
	public	internat_info
	public	parsemes_ptr

	PUBLIC	triage_add
	PUBLIC	oldenv
	PUBLIC	usedenv
	PUBLIC	KAUTOBAT			;AN000;  3/3/KK
	public	eswitch 			;AN018;
	public	dswitch 			;AN018;
	public	init_parse			;AN054;
	public	old_parse_ptr			;AN057;
	PUBLIC	pars_msg_off			;AN060;
	PUBLIC	pars_msg_seg			;AN060;

	public	PathString
        public  PathStrLen
        public  DefPathString
        public  DefPathStrLen
        public  PrmptString
        public  PrmptStrLen
        public  PrmptStrLen2
	public	Reloc_Table
	public	ResJmpTable
	public	FirstCom

	public	DevFlag
	public	PathFlag


include resmsg.equ				;AC000;



ICONDEV LABEL BYTE
		DB	"/DEV/"
		DB	"CON",0,0,0,0,0,0               ; Room for 8 char device
BADCSPFL	DB	0
COMSPECT	DB	"\COMMAND.COM",0,0
AUTOBAT 	DB	0,":\AUTOEXEC.BAT",0,0DH        ;AC027;
KAUTOBAT	DB	0,":\KAUTOEXE.BAT",0,0DH        ;AC027;  3/3/KK

PRDATTM 	DB	-1				;Init not to prompt for date time
INITADD 	DD	?
print_add	LABEL	DWORD
		DW	OFFSET TranGroup:Printf_INIT
		DW	0
triage_add	LABEL	DWORD
		DW	OFFSET TranGroup:Triage_Init
		DW	0

AllocedEnv      DB      0

PathString	db	"PATH=",0
PathStrLen      equ     $-PathString-1
DefPathString   db      "C:\WINDOWS\COMMAND",0
DefPathStrLen   equ     $-DefPathString-1
PrmptString     db      "PROMPT=$P$G",0
PrmptStrLen     equ     $-PrmptString-1
PrmptStrLen2    equ     7                               ; length of PROMPT=
ComspOffset     dw      0
ifndef		ROMDOS
ComspString	db	"COMSPEC=\COMMAND.COM",0
else
ComspString	db	"COMSPEC=COMMAND",0
endif
ComspStrLen     equ     8                               ; length of COMSPEC=
ComspStrLen2    equ     $-ComspString-1                 ; length of full COMSPEC

;;COMSPSTRING	DB	"COMSPEC="

equalsign	db	"="
lcasea		db	"a"
lcasez		db	"z"
space		db	" "
scswitch	db	"C"                             ; Single command
skswitch        db      "K"
ucasea		db	"A"

EnvMax		DW	0				; maximum size allowed.
oldenv		DW	0				; envirseg at initialization
usedenv 	DW	0				; amount of envirseg used
PARS_MSG_OFF	DW	0				;AN060;  SAVED PARSE ERROR MESSAGE OFFSET
PARS_MSG_SEG	DW	0				;AN060;  SAVED PARSE ERROR MESSAGE SEGMENT

;Do not separate the following two words.  Used to call transient PARSE routine

init_parse	label	dword				;AN054;
init_p		DW	TRANGROUP:APPEND_PARSE		;AN054;
initend 	DW	0				;eg segment address of end of init

;End of data that shouldn't be separated.

trnsize 	DW	0				;eg size of transient in paragraphs
	public	RequestedCmdSize, RequestedInputSize
RequestedCmdSize dw	0
RequestedInputSize dw	0
resetenv	DB	0				;eg set if we need to setblck env at endinit
ext_msg 	DB	0				;AN000; set if /MSG switch entered
eswitch 	db	0				;AN018; set if /e was entered
dswitch 	db	0				;AN018; set if /d was entered
	public	Lswitch, Uswitch
Lswitch	db	0
Uswitch	db	0
LoadLow	db	0		; retain resident data in low memory
parsemes_ptr	dw	0			;AN000; word to store parse error number

;
; PARSE BLOCK FOR COMMAND
;
PUBLIC	PARSE_COMMAND				;AN000;
PUBLIC	COMND1_OUTPUT				;AN000;
PUBLIC	COMND1_TYPE				;AN000;
PUBLIC	COMND1_CODE				;AN000;
PUBLIC	COMND1_SYN				;AN000;
PUBLIC	COMND1_ADDR				;AN000;
PUBLIC	COMMAND_F_SYN				;AN000;
PUBLIC	COMMAND_P_SYN				;AN000;
PUBLIC	COMMAND_C_SYN				;AN000;
PUBLIC  COMMAND_K_SYN                           ;AN000;
PUBLIC	COMMAND_D_SYN				;AN000;
PUBLIC	COMMAND_E_SYN				;AN000;
PUBLIC	COMMAND_M_SYN				;AN000;
PUBLIC	COMMAND_Y_SYN				; /Y switch
PUBLIC	COMMAND_?_SYN

;
;  The following parse control block is used for COMMAND.  This block is
;  used for parsing during initialization.  The sytax for COMMAND is:
;  COMMAND [/?] [d:][path][/P][/F][/D][/E:xxxxx][/MSG][/C executable]
;
;  Anything on the command line after the /C switch will be passed to the
;  executable command, so if /C is used, it must be specified last. The
;  /MSG switch can only be specified if the /P switch is specified.
;
;  The /? switch causes help text to be displayed.  Any other options
;  on the command line are ignored.  Command.com will not load if /?
;  is specified.
;

ENVBIG	EQU	32768				;AN000; maximum environment size
ENVSML	EQU	256				;AN000; minimum environment size

INTERNAT_INFO	LABEL	BYTE			;AN000; used for country info after parsing is completed
PARSE_COMMAND	LABEL	BYTE			;AN000;
		DW	RESGROUP:COMMAND_PARMS	;AN000;
		DB	0			;AN000; no extra delimiter

COMMAND_PARMS	LABEL	BYTE			;AN000;
		DB	0,2			;AN000; 1 positional parm
		DW	RESGROUP:COMMAND_FILE	;AN000;
		dw	RESGROUP:Command_File
                DB      14                       ; 14 switches
		DW	RESGROUP:COMMAND_SWITCH1 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH2 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH3 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH4 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH5 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH6 ;AN000;
		DW	RESGROUP:COMMAND_SWITCH7
                DW      RESGROUP:COMMAND_SWITCH8
                DW      RESGROUP:COMMAND_SWITCH9
		DW	RESGROUP:COMMAND_SWITCH10
		DW	RESGROUP:COMMAND_SWITCH11
		DW	RESGROUP:COMMAND_SWITCH12
		DW	RESGROUP:COMMAND_SWITCH13
		DW	RESGROUP:COMMAND_SWITCH14
		DB	0			;AN000; no keywords

COMMAND_FILE	LABEL	BYTE			;AN000;
		DW	0201H			;AN000; filespec - optional
		DW	1			;AN000; capitalize - file table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	0			;AN000; no keywords

COMMAND_SWITCH1 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_P_SYN	DB	"/P",0                  ;AN000; /P switch

COMMAND_SWITCH2 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_F_SYN	DB	"/F",0                  ;AN000; /F switch

COMMAND_SWITCH3 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_D_SYN	DB	"/D",0                  ;AN000; /D switch

COMMAND_SWITCH4 LABEL	BYTE			;AN000;
		DW	8000H			;AN000; numeric value - required
		DW	0			;AN000; no function flags
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:COMMAND_E_VAL	;AN000; pointer to value list
		DB	1			;AN000; 1 keyword
COMMAND_E_SYN	DB	"/E",0                  ;AN000; /E switch

COMMAND_E_VAL	LABEL	BYTE			;AN000;
		DB	1			;AN000;
		DB	1			;AN000; 1 range
		DB	1			;AN000; returned if result
		DD	ENVSML,ENVBIG		;AN000; minimum & maximum value
		DB	0			;AN000; no numeric values
		DB	0			;AN000; no string values

COMMAND_SWITCH5 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_C_SYN	DB	"/C",0                  ;AN000; /C switch

COMMAND_SWITCH6 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_M_SYN	DB	"/MSG",0                ;AN000; /MSG switch

COMMAND_SWITCH7 LABEL	BYTE			;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_?_SYN	DB	"/?",0                  ;AN000; /? switch

COMMAND_SWITCH8 LABEL   BYTE                    ;AN000;
		DW	0			;AN000; no match flags
		DW	2			;AN000; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	;AN000; result buffer
		DW	RESGROUP:NO_VAL 	;AN000;
		DB	1			;AN000; 1 keyword
COMMAND_K_SYN   DB      "/K",0                  ;AN000; /K switch

COMMAND_SWITCH9 LABEL	BYTE			; /Y switch
		DW	0			; no match flags
		DW	2			; capitalize by char table
		DW	RESGROUP:COMND1_OUTPUT	; result buffer
		DW	RESGROUP:NO_VAL		; no values
		DB	1			; 1 keyword
COMMAND_Y_SYN	DB	"/Y",0			; /Y switch

	public	COMMAND_Z_SYN
COMMAND_SWITCH10 LABEL BYTE
		DW	0
		DW	2
		DW	RESGROUP:COMND1_OUTPUT
		DW	RESGROUP:NO_VAL
		DB	1
COMMAND_Z_SYN DB "/Z",0

	public	COMMAND_L_SYN
COMMAND_SWITCH11 LABEL BYTE
		DW	8000h
		DW	0
		DW	RESGROUP:COMND1_OUTPUT
		DW	RESGROUP:COMMAND_L_VAL
		DB	1
COMMAND_L_SYN DB "/L",0
COMMAND_L_VAL LABEL BYTE
		DB	1,1,1
		DD	128,1024
		DB	0,0

	public	COMMAND_LOW_SYN
COMMAND_SWITCH12 LABEL BYTE
		DW	0
		DW	2
		DW	RESGROUP:COMND1_OUTPUT
		DW	RESGROUP:NO_VAL
		DB	1
COMMAND_LOW_SYN DB "/LOW",0

	public	COMMAND_U_SYN
COMMAND_SWITCH13 LABEL BYTE
		DW	8000h
		DW	0
		DW	RESGROUP:COMND1_OUTPUT
		DW	RESGROUP:COMMAND_U_VAL
		DB	1
COMMAND_U_SYN DB "/U",0
COMMAND_U_VAL LABEL BYTE
		DB	1,1,1
		DD	128,255
		DB	0,0

	public	COMMAND_T_SYN
COMMAND_SWITCH14 LABEL BYTE
		DW	0
		DW	2
		DW	RESGROUP:COMND1_OUTPUT
		DW	RESGROUP:NO_VAL
		DB	1
COMMAND_T_SYN DB "/T",0

COMND1_OUTPUT	LABEL	BYTE
COMND1_TYPE	DB	0
COMND1_CODE	DB	0
COMND1_SYN	DW	0
COMND1_ADDR	DD	0

	public	NO_VAL
NO_VAL		DB	0
num_positionals DW	0
old_parse_ptr	DW	0

;   Initial CMDLINE program name.
;
	public	ParseInitCommand, InitCommandParms, InitCommandFile
ParseInitCommand	dw	RESGROUP:InitCommandParms
		db	0
InitCommandParms db	0,1
		dw	RESGROUP:InitCommandFile
		db	0,0
InitCommandFile	dw	0200h
		dw	1
		dw	RESGROUP:COMND1_OUTPUT
		dw	RESGROUP:NO_VAL
		db	0

;   Resource-file environment search state.
;
MsgReadHeader	db	26 dup (0)
MsgEnvPath	dd	0
MsgEnvName	db	"COMSPEC="
MsgReadSegment	dw	0
MsgReadOffset	dw	0
MsgReadLimit	dw	0
MsgReadClass	dw	0
MsgReadHandle	dw	0
MsgFileOffset	dd	0
MsgReadReserved dw	0
MsgFallbackPath dd	0
	public	MsgReadHeader,MsgEnvPath,MsgEnvName
	public	MsgReadSegment,MsgReadOffset,MsgReadLimit,MsgReadClass
	public	MsgReadHandle,MsgFileOffset,MsgFallbackPath

; Resident identification and initialization resource loading.
	include copyrigh.inc
	assume cs:RESGROUP,ds:RESGROUP,es:RESGROUP,ss:RESGROUP

;*** ReadMessageClass - read a message resource from the command file
;
;   Entry: AX = class, CX = buffer capacity, ES:DI = destination.
;          DS addresses RESGROUP.
;   Exit:  Carry reports failure; CX:DX identifies the resource data.
;   Uses:  CX, DX, flags; AX, BX, ES and DI are preserved.
;
        public  ReadMessageClass,ReadMessageHeader,ScanMessageClass,FindMessageFile
ReadMessageClass proc near
	push	ax
	push	bx
	push	es
	push	di
	mov	word ptr [MsgReadSegment],es
	mov	[MsgReadOffset],di
	mov	[MsgReadLimit],cx
	mov	[MsgReadClass],ax
	mov	ah,051h
	int	byte ptr 021h
	xor	di,di
	mov	es,bx
	cmp	word ptr [MsgFallbackPath+2],di
	jnz	rmEnvironment
	mov	ax,es:[030h]
	mov	word ptr [MsgFallbackPath+2],ax
	mov	ax,es:[032h]
	mov	word ptr [MsgFallbackPath],ax
rmEnvironment:
	mov	es,word ptr es:[PDB_Environ]
	call	FindMessageFile
	jc	rmReturn
	push	ds
	push	es
	pop	ds
	mov	dx,di
	mov	ax,03d00h
	int	byte ptr 021h
	pop	ds
	jc	rmFallback
	mov	[MsgReadHandle],ax
	xchg	ax,bx
	call	ReadMessageHeader
	jnc	rmClose
	mov	ah,03eh
	mov	bx,[MsgReadHandle]
	int	byte ptr 021h
rmFallback:
	push	ds
	lds	dx,dword ptr [MsgFallbackPath]
	mov	ax,03d00h
	int	byte ptr 021h
	pop	ds
	jc	rmReturn
	mov	[MsgReadHandle],ax
	xchg	ax,bx
	call	ReadMessageHeader
rmClose:
	pushf
	mov	ah,03eh
	mov	bx,[MsgReadHandle]
	int	byte ptr 021h
	popf
	mov	dx,word ptr [MsgFileOffset]
	mov	cx,word ptr [MsgFileOffset+2]
rmReturn:
	pop	di
	pop	es
	pop	bx
	pop	ax
	ret
ReadMessageClass endp

ReadMessageHeader proc near
	push	es
	mov	cx,01ah
	mov	ax,03f00h
	lea	dx,[MsgReadHeader]
	int	byte ptr 021h
	jnc	rhSignature
rhBadRead:
	jmp	short rhError
rhSignature:
	mov	ax,word ptr [MsgReadHeader]
	cmp	ax,05a4dh
	jz	rhExe
	xor	cx,cx
	xor	dx,dx
	sub	dx,07h
	sbb	cx,00h
	mov	ax,04202h
	int	byte ptr 021h
	mov	cx,07h
	mov	ax,03f00h
	lea	dx,[MsgReadHeader]
	int	byte ptr 021h
	jc	rhBadRead
	cmp	word ptr [MsgReadHeader+3],0534eh
	jnz	rhBadRead
	mov	ax,word ptr [MsgReadHeader+5]
	jmp	short rhScan
rhExe:
	mov	ax,word ptr [MsgReadHeader+6]
	shl	ax,1
	shl	ax,1
	add	ax,word ptr [MsgReadHeader+24]
	cmp	ax,03fh
	jna	rhMinimum
	add	ax,0fh
	mov	cx,04h
	shr	ax,cl
	shl	ax,cl
	jmp	short rhScan
rhMinimum:
	mov	ax,040h
rhScan:
	mov	word ptr [MsgFileOffset],ax
	mov	word ptr [MsgFileOffset+2],00h
	call	ScanMessageClass
	jc	rhError
	pop	es
	ret
rhError:
	stc
	pop	es
	ret
ReadMessageHeader endp

ScanMessageClass proc near
	xor	cx,cx
	mov	dx,ax
smNext:
	push	cx
	push	dx
	mov	ax,04200h
	int	byte ptr 021h
	mov	cx,010h
	mov	ah,03fh
	lea	dx,[MsgReadHeader]
	int	byte ptr 021h
	jc	smError
	cmp	ax,cx
	jnz	smError
	mov	ax,word ptr [MsgReadHeader+11]
	cmp	ax,0534eh
	jnz	smError
	mov	cl,[MsgReadHeader+15]
	mov	ax,[MsgReadClass]
	cmp	ax,cx
	jz	smFound
	pop	dx
	pop	cx
	add	dx,word ptr [MsgReadHeader]
	adc	cx,00h
	add	dx,0fh
	adc	cx,00h
	and	dl,0f0h
	jmp	short smNext
smError:
	pop	dx
	pop	cx
	stc
	jmp	short smReturn
smFound:
	pop	dx
	pop	cx
	add	dx,014h
	adc	cx,00h
	mov	word ptr [MsgFileOffset],dx
	mov	word ptr [MsgFileOffset+2],cx
	push	bx
	mov	bx,word ptr [MsgReadHeader+2]
	sub	bx,010h
	mov	ax,[MsgReadLimit]
	sub	ax,bx
	pop	bx
	js	smFailure
	mov	cx,word ptr [MsgReadHeader]
	sub	cx,010h
	push	ds
	mov	ax,[MsgReadSegment]
	mov	es,ax
	mov	dx,[MsgReadOffset]
	mov	ah,03fh
	int	byte ptr 021h
	pop	ds
	jc	smFailure
smReturn:
	ret
smFailure:
	stc
	ret
ScanMessageClass endp

;*** FindMessageFile - find the executable path in the environment
;
;   Entry: ES:DI addresses the environment block, DS addresses RESGROUP.
;   Exit:  Carry clear, ES:DI addresses the path; carry set, no path.
;          A COMSPEC match is also saved in MsgEnvPath.
;   Uses:  AX, BX, CX, DI, flags.  SI is preserved.
;
FindMessageFile proc near
	push	si
	xor	ax,ax
	cmp	es:[di],ax
	je	short fmEmpty
	push	di
fmScan:
	inc	di
	cmp	es:[di],al
	jne	fmScan
	inc	di
	cmp	es:[di],al
	jne	fmScan
	inc	di
	cmp	byte ptr es:[di],1
	jne	short fmComspec
	inc	di
	cmp	es:[di],al
	jne	short fmComspec
	inc	di
	pop	si
	jmp	short fmReturn
fmComspec:
	pop	di
	lea	si,MsgEnvName
	mov	bx,8
fmNext:
	mov	cx,bx
	push	si
	repe	cmpsb
	pop	si
	je	short fmFound
	mov	cx,0ffffh
	repne	scasb
	cmp	es:[di],al
	je	short fmTrailer
	jmp	short fmNext
fmFound:
	lea	si,MsgEnvPath
	mov	[si],di
	add	si,2
	mov	ax,es
	mov	[si],ax
	xor	ax,ax
	jmp	short fmReturn
fmEmpty:
	inc	di
fmTrailer:
	inc	di
	cmp	byte ptr es:[di],1
	jne	short fmError
	inc	di
	cmp	es:[di],al
	jne	short fmError
	inc	di
	jmp	short fmReturn
fmError:
	stc
fmReturn:
	pop	si
	ret
FindMessageFile endp

;*** FixInitMessages - resolve initialization message text pointers
;
;   Entry: DS addresses RESGROUP.  The message class contains relative
;          offsets and must be fixed once before any initialization message.
;   Uses:  BX, CX, flags.
;
        public  FixInitMessages
FixInitMessages proc near
	mov	bx,offset RESGROUP:InitMsgTable
	xor	cx,cx
	mov	cl,InitMsgCount
FixInitMsgNext:
	add	[bx+2],bx
	add	bx,4
	loop	FixInitMsgNext
	ret
FixInitMessages endp


;***	INITIALIZATION MESSAGES

        public  InitMsgBuffer
InitMsgBuffer   db      3 dup (0) ; resource class header
INIT_MSG_BUFFER equ 1
	include	comimsg.inc		;M00


;SR;
; This table of offsets is used by the init code to calculate the new offsets
;for these labels after the resident code has been relocated
;

Reloc_Table	dw	offset CODERES:MsgInt2fHandler
		dw	offset CODERES:Int_2e
		dw	offset CODERES:ContC
		dw	offset CODERES:DskErr
		dw	offset CODERES:Exec_Ret
		dw	offset CODERES:TRemCheck
		dw	offset CODERES:TrnLodCom1
		dw	offset CODERES:LodCom
		dw	offset CODERES:MsgRetriever
		dw	offset CODERES:THeadFix
		dw	offset CODERES:Lh_OffUnlink	; M003
		dw	offset CODERES:BadMemEntry
		dw	offset CODERES:ReleaseInit

NUM_RELOC_ENTRIES	equ  ($ - Reloc_Table) / 2
public	NUM_RELOC_ENTRIES

ResJmpTable	dd	?		;stores prev stub jump table addr
FirstCom		db	0		;flag set if first command.com

DevFlag		db	0
PathFlag		db	0

	public	ResidentCodeOffset, LoadLow
ResidentCodeOffset dw	0		; source of resident code

INIT	ends

	end

