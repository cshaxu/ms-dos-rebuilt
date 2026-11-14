	page ,132
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
;	SCCSID = @(#)tcode.asm	1.1 85/05/14
TITLE	Part1 COMMAND Transient Routines
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;
;	M025	SR	9/12/90	Removed calls to SetStdInOn,SetStdInOff
;				SetStdOutOn & SetStdOutOff.
;


.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include comseg.asm
	include comequ.asm
.list
.cref


CODERES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	EXEC_WAIT:NEAR
	EXTRN	ExecTopRet:NEAR, Ext_Exec:NEAR
CODERES ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BATCH:WORD
	EXTRN	CALL_BATCH_FLAG:byte
	EXTRN	CALL_FLAG:BYTE
	EXTRN	CopyNonInteractive:WORD
	EXTRN	DosCommandState:DWORD
	EXTRN	ECHOFLAG:BYTE
	EXTRN	envirseg:word
	EXTRN	EXTCOM:BYTE
	EXTRN	Exec_Entry:DWORD
	EXTRN	FORFLAG:BYTE
	EXTRN	IFFLAG:BYTE
	EXTRN	next_batch:word
	EXTRN	nullflag:byte
	EXTRN	PermCom:BYTE
	EXTRN	PIPEFILES:BYTE
	EXTRN	PIPEFLAG:BYTE
	EXTRN	RE_OUT_APP:BYTE
	EXTRN	RE_OUTSTR:BYTE
	EXTRN	RESTDIR:BYTE
	EXTRN	RetCode:WORD
        EXTRN   SINGLECOM:WORD
        EXTRN   SEMIPERMCOM:BYTE
	EXTRN	VERVAL:WORD
	EXTRN	YSwitchFlags:WORD
	EXTRN	CmdBufSize:WORD, InputBufSize:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BadNam_Ptr:word 	;AC000;
	EXTRN	ForCommandName:BYTE
	EXTRN	WinCommand:BYTE
	EXTRN	BatchStep_Ptr:word	; batch execution prompt
	EXTRN	TraceReturn_Ptr:WORD, TraceReload_Ptr:WORD
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	DirOutputActive:BYTE
	EXTRN	APPEND_EXEC:BYTE	;AN041;
	EXTRN	ARG1S:WORD
	EXTRN	ARG2S:WORD
	EXTRN	ARGTS:WORD
	EXTRN	BYTCNT:WORD
	EXTRN	comptr:WORD
	EXTRN	expand_star:BYTE, cpyflag:BYTE
	EXTRN	ForTokenFound:BYTE, ForVariable:BYTE
	EXTRN	COMSW:WORD
	EXTRN	CURDRV:BYTE
	EXTRN	fTest:WORD, TracePrinted:BYTE
	EXTRN	HEADCALL:DWORD
	EXTRN	IDLEN:BYTE
	EXTRN	INTERNATVARS:BYTE
	EXTRN	PARM1:BYTE
	EXTRN	PARM2:BYTE
	EXTRN	RE_INSTR:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	TranSpaceEnd:BYTE
	EXTRN	CmdBufferLength:WORD, InputBufferLength:WORD, ComBufPtr:WORD
	EXTRN	SPECDRV:BYTE
	EXTRN	SavedBatchPosition:DWORD
	EXTRN	STACK:WORD
	EXTRN	SWITCHAR:BYTE
	EXTRN	TPA:WORD
	EXTRN	USERDIR1:BYTE
	IF  IBM_ROM_FIND
	EXTRN	ROM_CALL:BYTE
	EXTRN	ROM_CS:WORD
	EXTRN	ROM_IP:WORD
	ENDIF

TRANSPACE	ENDS

; ********************************************************************
; START OF TRANSIENT PORTION
; This code is loaded at the end of memory and may be overwritten by
; memory-intensive user programs.

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	$EXIT:NEAR
	EXTRN	DRVBAD:NEAR
	EXTRN	EXTERNAL:NEAR
	EXTRN	FNDCOM:NEAR
	EXTRN	ClosePathFind:NEAR
	EXTRN	ExpandCommandLine:NEAR
	EXTRN	FORPROC:NEAR
	EXTRN	PIPEPROC:NEAR
	EXTRN	PIPEPROCSTRT:NEAR
	EXTRN	TSYSGETMSG:NEAR

	PUBLIC	COMMAND
	PUBLIC	DOCOM
	PUBLIC	DOCOM1
	PUBLIC	NOPIPEPROC
	PUBLIC	TCOMMAND

	IF  IBM_ROM_FIND
	PUBLIC	ROM_EXEC
	PUBLIC	ROM_SCAN
	ENDIF

	ORG	0
ZERO	=	$

	ORG	100H				; Allow for 100H parameter area

SETDRV:
	MOV	AH,SET_DEFAULT_DRIVE
	INT	21h
;
; TCOMMAND is the recycle point in COMMAND.  Nothing is known here.
; No registers (CS:IP) no flags, nothing.
;

TCOMMAND:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	AX,-1
	XCHG	AX,[VERVAL]
	CMP	AX,-1
	JZ	NOSETVER2
	MOV	AH,SET_VERIFY_ON_WRITE		; AL has correct value
	INT	21h

NOSETVER2:
	CALL	CS:[HEADCALL]		; Make sure header fixed
	INVOKE	ClosePathFind		; close any outstanding search
	XOR	BP,BP				; Flag transient not read
	CMP	[SINGLECOM],-1
	JNZ	COMMAND

$EXITPREP:
	PUSH	CS
	POP	DS
	JMP	$EXIT				; Have finished the single command
ASSUME	DS:NOTHING
;
; Main entry point from resident portion.
;
;   If BP <> 0, then we have just loaded transient portion otherwise we are
;   just beginning the processing of another command.
;

COMMAND:

;
; We are not always sure of the state of the world at this time.  We presume
; worst case and initialize the relevant registers: segments and stack.
;
	ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING
	CLD
	MOV	AX,CS
	CLI
	MOV	SS,AX
ASSUME	SS:TRANGROUP
	MOV	SP,OFFSET TRANGROUP:STACK
	STI
	MOV	ES,AX
	MOV	DS,AX				;AN000; set DS to transient
ASSUME	ES:TRANGROUP,DS:TRANGROUP		;AC000;
	invoke	TSYSLOADMSG			;AN000; preload messages
	mov	append_exec,0			;AN041; set internal append state off
	mov	DirOutputActive,0		; disable DIR output buffering

	PUBLIC	InitializeCommandBuffers
InitializeCommandBuffers:
	CALL	InitCommandBuffers
ASSUME	DS:RESGROUP
;
; If we have just loaded the transient, then we do NOT need to initialize the
; command buffer.  ????  DO WE NEED TO RESTORE THE USERS DIRECTORY ????  I
; guess not:  the only circumstances in which we reload the command processor
; is after a transient program execution.  In this case, we let the current
; directory lie where it may.
;
	OR	BP,BP				; See if just read
	JZ	TESTRDIR			; Not read, check user directory
	MOV	WORD PTR ES:[SI+1],0D01H	; Reset raw input buffer
	JMP	SHORT NOSETBUF

TESTRDIR:
	CMP	[RESTDIR],0
	JZ	NOSETBUF			; User directory OK
	PUSH	DS
;
; We have an unusual situation to handle.  The user *may* have changed his
; directory as a result of an internal command that got aborted.  Restoring it
; twice may not help us:  the problem may never go away.  We just attempt it
; once and give up.
;
	MOV	[RESTDIR],0			; Flag users dirs OK
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	DX,OFFSET TRANGROUP:USERDIR1
	MOV	AH,CHDIR
	INT	21h			; Restore users directory
	POP	DS
ASSUME	DS:RESGROUP

NOSETBUF:
	CMP	[PIPEFILES],0
	JZ	NOPCLOSE			; Don't bother if they don't exist
	CMP	[PIPEFLAG],0
	JNZ	NOPCLOSE			; Don't del if still piping
	INVOKE	PIPEDEL

NOPCLOSE:
	MOV	[EXTCOM],0			; Flag internal command
	MOV	AX,CS				; Get segment we're in
	MOV	DS,AX
ASSUME	DS:TRANGROUP

	PUSH	AX
	MOV	DX,OFFSET TRANGROUP:INTERNATVARS
	MOV	AX,INTERNATIONAL SHL 8
	INT	21H
	POP	AX
	SUB	AX,[TPA]			; AX=size of TPA in paragraphs
	PUSH	BX
	MOV	BX,16
	MUL	BX				; DX:AX=size of TPA in bytes
	POP	BX
	OR	DX,DX				; See if over 64K
	JZ	SAVSIZ				; OK if not
	MOV	AX,-1				; If so, limit to 65535 bytes

SAVSIZ:
;
; AX is the number of bytes free in the buffer between the resident and the
; transient with a maximum of 64K-1.  We round this down to a multiple of 512.
;
	CMP	AX,512
	JBE	GotSize
	AND	AX,0FE00h			; NOT 511 = NOT 1FF

GotSize:
	MOV	[BYTCNT],AX			; Max no. of bytes that can be buffered

	PUBLIC	ShowTraceMessages
ShowTraceMessages:
	TEST	BYTE PTR [fTest],1
	JZ	TraceDone
	CMP	[TracePrinted],0FFh
	JZ	TraceReload
	MOV	DX,OFFSET TRANGROUP:TraceReturn_Ptr
	INVOKE	std_printf
	MOV	[TracePrinted],0FFh
TraceReload:
	TEST	BYTE PTR [fTest],2
	JZ	TraceDone
	MOV	DX,OFFSET TRANGROUP:TraceReload_Ptr
	INVOKE	std_printf
	AND	BYTE PTR [fTest],NOT 2
TraceDone:
        PUBLIC  InitializeInputState
InitializeInputState:
	MOV	DS,[RESSEG]			; All batch work must use resident seg.
ASSUME	DS:RESGROUP
	MOV	BYTE PTR [RetCode+1],-1
	AND	BYTE PTR [YSwitchFlags],NOT 2

	TEST	[ECHOFLAG],1
	JZ	GETCOM				; Don't do the CRLF
	INVOKE	SINGLETEST
	JB	GETCOM
	TEST	[PIPEFLAG],-1
	JNZ	GETCOM
	TEST	[FORFLAG],-1			; G  Don't print prompt in FOR
	JNZ	GETCOM				; G
	TEST	[BATCH], -1			; G  Don't print prompt if in batch
	JNZ	GETCOM				; G
	INVOKE	CRLF2

	PUBLIC	GETCOM
GETCOM:
	AND	BYTE PTR SS:[fTest],NOT 8
	CMP	[SINGLECOM],0
	JNZ	@F
	TEST	[BATCH],-1
	JNZ	@F
	PUBLIC	RestoreExecEntry
RestoreExecEntry:
	TEST	[PermCom],4
	JZ	SHORT CheckWinCommand
	MOV	BX,WORD PTR [Exec_Entry]
	SUB	BX,OFFSET CODERES:ExecTopRet
	ADD	BX,OFFSET CODERES:Ext_Exec
	MOV	WORD PTR [Exec_Entry],BX
	AND	[PermCom],NOT 4
	PUBLIC	CheckWinCommand
CheckWinCommand:
	TEST	BYTE PTR [YSwitchFlags],4
	JZ	SHORT ClearInputFlags
	AND	BYTE PTR [YSwitchFlags],NOT 24H
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	SI,OFFSET TRANGROUP:WinCommand
	MOV	DI,[ComBufPtr]
	LODSB
	CBW
	MOV	[DI-2],AX
	INC	AX
	XCHG	AX,CX
	REP	MOVSB
	OR	BYTE PTR [fTest],8
	MOV	AH,GET_DEFAULT_DRIVE
	INT	21H
	MOV	[CURDRV],AL
	JMP	DOCOM1
ClearInputFlags:
ASSUME	DS:RESGROUP
	AND	[YSwitchFlags],NOT 110H
@@:
	PUBLIC	BeginCommandInput
BeginCommandInput:
	CALL	SetCommandInputState
	MOV	CALL_FLAG,0			; G Reset call flags
	MOV	CALL_BATCH_FLAG,0		; G
	MOV	AH,GET_DEFAULT_DRIVE
	INT	21h
	MOV	[CURDRV],AL
	TEST	[PIPEFLAG],-1			; Pipe has highest presedence
	JZ	NOPIPE
	JMP	PIPEPROC			; Continue the pipeline

NOPIPE:
	TEST	[ECHOFLAG],1
	JZ	NOPDRV				; No prompt if echo off
	INVOKE	SINGLETEST
	JB	NOPDRV
	TEST	[FORFLAG],-1			; G  Don't print prompt in FOR
	JNZ	NOPDRV				; G
	TEST	[BATCH], -1			; G  Don't print prompt if in batch
	JNZ	TESTFORBAT			; G
	PUBLIC	CheckPromptState
CheckPromptState:
	CALL	QueryCommandState
	JZ	NOPDRV
	INVOKE	PRINT_PROMPT			; Prompt the user

NOPDRV:
	TEST	[FORFLAG],-1			; FOR has next highest precedence
	JZ	TESTFORbat
	JMP	FORPROC 			; Continue the FOR

TESTFORBAT:
	MOV	[RE_INSTR],0			; Turn redirection back off
	MOV	[RE_OUTSTR],0
	MOV	[RE_OUT_APP],0
	MOV	IFFlag,0			; no more ifs...
	TEST	[BATCH],-1			; Batch has lowest precedence
	JZ	ISNOBAT

;	Bugbug:	MULT_SHELL_GET no longer used?
	push	es				;AN000; save ES
	push	ds				;AN000; save DS
	mov	ax,mult_shell_get		;AN000; check to see if SHELL has command
	mov	es,[batch]			;AN000; get batch segment
	mov	di,batfile			;AN000; get batch file name
	push	cs				;AN000; get local segment to DS
	pop	ds				;AN000;
	PUBLIC	GetShellCommandBuffer
GetShellCommandBuffer:
	MOV	DX,SS:[ComBufPtr]
	SUB	DX,4
	int	2fh				;AN000; call the shell
	cmp	al,shell_action 		;AN000; does shell have a commmand?
	pop	ds				;AN000; restore DS
	pop	es				;AN000; restore ES
	jz	jdocom1 			;AN000; yes - go process command

	PUSH	DS				;G
	PUBLIC	SaveBatchPosition
SaveBatchPosition:
	PUSH	DS
	MOV	DS,[BATCH]
ASSUME	DS:NOTHING
	TEST	WORD PTR DS:[Batlast],-1
	JNZ	SHORT BatchPositionSaved
	MOV	AX,WORD PTR DS:[BatSeek]
	MOV	WORD PTR SS:[SavedBatchPosition],AX
	MOV	AX,WORD PTR DS:[BatSeek+2]
	MOV	WORD PTR SS:[SavedBatchPosition+2],AX
BatchPositionSaved:
	POP	DS
ASSUME	DS:RESGROUP
	INVOKE	READBAT 			; Continue BATCH
	POP	DS				;G
	mov	nullflag,0			;G reset no command flag
	TEST	[BATCH],-1			;G
	JNZ	JDOCOM1 			;G if batch still in progress continue
	MOV	BX,NEXT_BATCH			;G
	CMP	BX,0				;G see if there is a new batch file
	JZ	JDOCOM1 			;G no - go do command
	MOV	BATCH,BX			;G get segment of next batch file
	MOV	NEXT_BATCH,0			;G reset next batch
JDOCOM1:
	PUSH	CS				;G
	POP	DS				;G
	JMP	DoCom1			; echoing already done

ISNOBAT:
	CMP	[SINGLECOM],0
	JZ	REGCOM
	PUBLIC	ConsumeSingleCommand
ConsumeSingleCommand:
	OR	SI,-1
	MOV	AL,[SEMIPERMCOM]
	AND	[SEMIPERMCOM],NOT 1
	SHR	AL,1
	ADC	SI,0
	XCHG	SI,[SINGLECOM]
	CMP	SI,100H
	JA	JDOCOM1
	PUBLIC	CopyTransientCommand
CopyTransientCommand:
	MOV	DI,SS:[ComBufPtr]
	XOR	CX,CX

SINGLELOOP:
	LODSB
	STOSB
	INC	CX
	CMP	AL,0DH
	JNZ	SINGLELOOP
	DEC	CX
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	PUSH	SI
	MOV	SI,[ComBufPtr]
	MOV	[SI-2],CX
	POP	SI
;
; do NOT issue a trailing CRLF...
;
	JMP	SHORT DOCOM1

;
; We have a normal command.  
; Printers are a bizarre quantity.  Sometimes they are a stream and
; sometimes they aren't.  At this point, we automatically close all spool
; files and turn on truncation mode.
;

REGCOM:
	MOV	AX,(ServerCall SHL 8) + 9
	INT	21h
	MOV	AX,(ServerCall SHL 8) + 8
	MOV	DL,1
	INT	21h

	PUSH	CS
	POP	DS				; Need local segment to point to buffer
	PUBLIC	ReadInteractiveCommand
ReadInteractiveCommand:
	MOV	DX,OFFSET TRANGROUP:TranSpaceEnd+2
	ADD	DX,[CmdBufferLength]
	PUSH	DX

;	Try to read interactive command line via DOSKey.
;	If that fails, use DOS Buffered Keyboard Input.

	mov	ax,4810h		; AX = DOSKey Read Line function
	int	2fh
	or	ax,ax
	jz	GotCom			; DOSKey gave us a command line

	mov	ah,STD_CON_STRING_INPUT	; AH = DOS Buffered Keyboard Input
	int	21h			; call DOS

GotCom:
	PUBLIC	CheckInteractiveCommand
CheckInteractiveCommand:
	CALL	QueryCommandState
	JNZ	CopyInputCommand
	JMP	EXITJ
	PUBLIC	CopyInputCommand
CopyInputCommand:
	CALL	ClearCommandState
	PUBLIC	CopyInputBuffer
CopyInputBuffer:
	POP	SI
	MOV	CL,[SI+1]
	XOR	CH,CH
	MOV	DI,[ComBufPtr]
	MOV	[DI-2],CX
	INC	CX
	ADD	SI,2
	REP	MOVSB
	INVOKE	CRLF2
	XOR	AX,AX				; interactive command
	JMP	SHORT SetCopyMode

;---------------

transpace   segment
    extrn   arg:byte				; the arg structure!
transpace   ends
;---------------


DOCOM:
	INVOKE	CRLF2

DOCOM1:
	MOV	AX,1				; batch or single command
	PUBLIC	SetCopyMode
SetCopyMode:
	MOV	BX,-1
	OR	DX,BX
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	[CopyNonInteractive],AX
	TEST	[BATCH],-1
	JZ	SHORT CommandStateSet
	PUSHF
	TEST	[YSwitchFlags],100H
	JZ	SHORT SetBatchPosition
	MOV	BX,WORD PTR SS:[SavedBatchPosition]
	MOV	DX,WORD PTR SS:[SavedBatchPosition+2]
SetBatchPosition:
	CALL	PublishBatchPosition
	POPF
CommandStateSet:
	POP	DS
ASSUME	DS:TRANGROUP
	PUBLIC	PrepareInteractiveCommand
PrepareInteractiveCommand:
	JNZ	SHORT ReadCommandLength
	MOV	[ForTokenFound],0
	CALL	CheckForCommand
	CALL	ExpandCommandLine
	PUBLIC	ReadCommandLength
ReadCommandLength:
	MOV	SI,[ComBufPtr]
	MOV	CX,[SI-2]
	CALL	BatchStep
	JNC	@F
	JMP	nullcom
@@:
	PUBLIC	CheckPipelineIf
CheckPipelineIf:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	TEST	[PIPEFLAG],-1
	JZ	SHORT ScanCommandInput
	TEST	[IFFLAG],-1
	JZ	SHORT ScanCommandInput
	POP	DS
	JMP	SHORT NOPIPEPROC
ScanCommandInput:
	POP	DS
ASSUME	DS:TRANGROUP
	INVOKE	PRESCAN 			; Cook the input buffer
	JZ	NOPIPEPROC
	JMP	PIPEPROCSTRT			; Fire up the pipe

nullcomj:
	jmp	nullcom

NOPIPEPROC:
	invoke	parseline
	jnc	OkParse 			; user error?  or maybe we goofed?

	PUBLIC	BadParse
BadParse:
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET TRANGROUP:BADNAM_ptr
	INVOKE	std_eprintf
	JMP	TCOMMAND

OkParse:
	cmp	arg.argvcnt, 0			; there WAS a command, wasn't there?
	jz	nullcomj
	cmp	arg.argv[0].arglen, 0		; probably an unnecessary check...
	jz	nullcomj			; guarantees argv[0] at least x<NULL>

	PUBLIC	ParseCommandName
ParseCommandName:
	MOV	SI,[ComBufPtr]
	MOV	DI,OFFSET TRANGROUP:IDLEN
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H ; Make FCB with blank scan-off
	INT	21h
	CMP	AL,1
	JZ	BadParse			; ambiguous commands not allowed
	mov	BX, arg.argv[0].argpointer
	cmp	BYTE PTR [BX+1],':'             ; was a drive specified?
	jne	short drvgd			; no, use default of zero...

	mov	DL, BYTE PTR [BX]		; pick-up drive letter
	and	DL, NOT 20H			; uppercase the sucker
	sub	DL, capital_A			; convert it to a drive number, A=0

	CMP	AL,-1				; See what PARSE said about our drive letter.
	JZ	drvbadj2			; It was invalid.

	mov	DI, arg.argv[0].argstartel
	cmp	BYTE PTR [DI], 0		; is there actually a command there?
	jnz	drvgd				; if not, we have:  "d:", "d:\", "d:/"
	jmp	setdrv				; and set drive to new drive spec

drvbadj2:
	jmp	drvbad

DRVGD:
	MOV	AL,[DI]
	MOV	[SPECDRV],AL
	MOV	AL,' '
	MOV	CX,9
	INC	DI
	REPNE	SCASB				; Count no. of letters in command name
	MOV	AL,8
	SUB	AL,CL
	MOV	[IDLEN],AL			; IDLEN is truly the length
	PUBLIC	ParseCommandArguments
ParseCommandArguments:
	MOV	DI,arg.argv[0].argsw_word
	MOV	[COMSW],DI
	CALL	ParseCommandFCBs

	mov	DI, arg.argv[2*SIZE argv_ele].argsw_word
	mov	[ARG2S], DI
	mov	DI, arg.argv[0].argsw_word
	not	DI				; ARGTS doesn't include the flags
	and	DI, arg.argswinfo		; from COMSW...
	mov	[ARGTS], DI

	MOV	AL,[IDLEN]
	MOV	DL,[SPECDRV]
	or	DL, DL				; if a drive was specified...
	jnz	externalj1			; it MUST be external, by this time
	dec	al				; (I don't know why -- old code did it)
	jmp	fndcom				; otherwise, check internal com table

externalj1:
	jmp	external

nullcom:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	TEST	[BATCH], -1			;G Are we in a batch file?
	JZ	nosetflag			;G only set flag if in batch
	mov	nullflag,nullcommand		;G set flag to indicate no command

nosetflag:
	CMP	[SINGLECOM],-1
	JZ	EXITJ
	JMP	GETCOM

	PUBLIC	EXITJ
EXITJ:
	JMP	$EXITPREP

;*** InitCommandBuffers -- Set up the dynamic input and command buffers.
;
;	ENTRY:	ES = transient data segment
;	EXIT:	DS = resident data segment, SI = raw input buffer
;		ComBufPtr = command text offset in transient data
;	USED:	ax, si, ds, flags
;
	PUBLIC	InitCommandBuffers
InitCommandBuffers PROC NEAR
	ASSUME	DS:RESGROUP,ES:TRANGROUP
	MOV	DS,ES:[RESSEG]
	MOV	SI,OFFSET TRANGROUP:TranSpaceEnd+2
	ADD	SI,CmdBufSize
	MOV	AX,CmdBufSize
	MOV	ES:CmdBufferLength,AX
	MOV	AX,InputBufSize
	MOV	ES:InputBufferLength,AX
	MOV	AX,ES:InputBufferLength
	MOV	ES:[SI],AL
	PUSH	SI
	ADD	SI,AX
	ADD	SI,3
	MOV	AX,CmdBufSize
	MOV	ES:[SI],AX
	ADD	SI,4
	MOV	ES:ComBufPtr,SI
	POP	SI
	RET
InitCommandBuffers ENDP

;*** ParseCommandFCBs -- Parse the first two command arguments.
;
;	ENTRY	DS = transient segment, argv contains parsed arguments
;	EXIT	Default FCBs, PARM1, PARM2 and ARG1S set
;
	PUBLIC	ParseCommandFCBs
ParseCommandFCBs PROC NEAR
ASSUME	DS:TRANGROUP
	MOV	SI,arg.argv[1*SIZE argv_ele].argpointer
	OR	SI,SI
	JNZ	SHORT DoParse
	MOV	SI,[comptr]
DoParse:
	MOV	DI,FCB
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
	INT	21H
	MOV	[PARM1],AL
	MOV	DI,arg.argv[1*SIZE argv_ele].argsw_word
	MOV	[ARG1S],DI
	MOV	SI,arg.argv[2*SIZE argv_ele].argpointer
	OR	SI,SI
	JNZ	SHORT DoParse2
	MOV	SI,[comptr]
DoParse2:
	MOV	DI,FCB+10H
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
	INT	21H
	MOV	[PARM2],AL
	RET
ParseCommandFCBs ENDP

;*** CheckForCommand -- Recognize the FOR variable in a command line.
;
;	ENTRY	DS = transient segment
;	EXIT	ForTokenFound set when a FOR variable is recognized
;
	PUBLIC	CheckForCommand
CheckForCommand PROC NEAR
ASSUME	DS:TRANGROUP
	PUSH	ES
	PUSH	BP
	MOV	SI,[ComBufPtr]
	MOV	DI,FCB+10H
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 01H
	INT	21H
	INC	DI
	PUSH	DS
	POP	ES
	PUSH	SI
	MOV	SI,OFFSET TRANGROUP:ForCommandName
	LODSB
	MOV	CL,AL
	XOR	CH,CH
	CLD
	REPE	CMPSB
	POP	SI
	JNZ	SHORT ForCheckDone
	CMP	BYTE PTR ES:[DI],' '
	JNZ	SHORT ForCheckDone
	MOV	DI,OFFSET TRANGROUP:TranSpaceEnd+2
	MOV	BL,' '
	XOR	BP,BP
	MOV	[expand_star],0
	MOV	[cpyflag],0
	INVOKE	SCANOFF
	INVOKE	CPARSE
	JC	SHORT ForCheckDone
	TEST	BH,1
	JNZ	SHORT ForCheckDone
	CMP	BYTE PTR ES:[DI],'%'
	JNZ	SHORT ForCheckDone
	MOV	BX,OFFSET TRANGROUP:ForVariable
	MOV	CH,2
	MOV	AL,ES:[DI+1]
	INVOKE	TESTKANJ
	JZ	SHORT ForCheckLength
	INC	CH
	MOV	[BX],AL
	INC	BX
	MOV	AL,ES:[DI+2]
ForCheckLength:
	CMP	CH,CL
	JNZ	SHORT ForCheckDone
	MOV	[BX],AL
	MOV	[ForTokenFound],1
ForCheckDone:
	POP	BP
	POP	ES
	RET
CheckForCommand ENDP

;***	BatchStep - confirm execution of a batch command
;
;	ENTRY	DS:SI = command text, CX = length
;
;	EXIT	carry set if command is not to be executed
;
;	USED	AX,BX,CX,DX,SI,flags

BatchStep	PROC	NEAR
ASSUME	DS:TRANGROUP
	CLC
	JCXZ	bsContinue
	CMP	BYTE PTR [SI],20H
	CMC
	JNC	bsContinue
	PUSH	ES
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	AL,BYTE PTR ES:[YSwitchFlags]
	TEST	AL,10H
	JZ	bsPopContinue
	CMP	ES:[CALL_BATCH_FLAG],1
	JZ	bsPopContinue
	TEST	AL,40H
	JZ	bsPrompt
bsStop:
	TEST	ES:[BATCH],-1
	JZ	bsNoBatch
	MOV	ES,ES:[BATCH]
	MOV	ES:[BatchEOF],1
bsNoBatch:
	STC
bsPopContinue:
	POP	ES
bsContinue:
	RET
bsPrompt:
	MOV	DX,SI
	MOV	BX,2
	MOV	AH,40H
	INT	21H
	MOV	DX,OFFSET TRANGROUP:BatchStep_Ptr
	INVOKE	STD_EPRINTF
	PUSH	DS
	MOV	AX,043BH
	MOV	DH,util_msg_class
	CALL	TSYSGETMSG
	MOV	BL,'A'			; default all character
	MOV	CX,4E59H			; default Y/N characters
	JC	bsGetChar
	MOV	CX,[SI]
	MOV	BL,[SI+2]
bsGetChar:
	POP	DS
bsReadChar:
	MOV	AH,08H
	INT	21H
	TEST	AL,AL
	JNZ	bsCheckChar
	MOV	AH,08H
	INT	21H
	CMP	AL,3FH
	JZ	bsStopKey
	CMP	AL,58H
	JNZ	bsReadChar
bsStopKey:
	OR	BYTE PTR ES:[YSwitchFlags],40H
	JMP	SHORT bsStop
bsCheckChar:
	CMP	AL,1BH
	JZ	bsEscape
	CMP	AL,0DH
	JZ	bsReturn
	AND	AL,0DFH
	CMP	AL,BL
	JNZ	bsCheckNo
	AND	BYTE PTR ES:[YSwitchFlags],NOT 10H
	JMP	SHORT bsNewLine
bsCheckNo:
	CMP	AL,CH
	JNZ	bsCheckYes
	STC
	JMP	SHORT bsEcho
bsReturn:
	MOV	AL,CL
	JMP	SHORT bsEcho
bsEscape:
	MOV	AL,CH
	STC
	JMP	SHORT bsEcho
bsCheckYes:
	CMP	AL,CL
	JNZ	bsReadChar
bsEcho:
	PUSHF
	MOV	DL,AL
	MOV	AH,02H
	INT	21H
	POPF
bsNewLine:
	PUSHF
	INVOKE	CRLF2
	POPF
	POP	ES
	RET
BatchStep	ENDP
ASSUME	ES:NOTHING

;*** PublishBatchPosition -- Set the batch position in DOS command state.
;
;	ENTRY	DS = resident segment, DX:BX = batch file position
;	EXIT	DS and SI preserved
;
	PUBLIC	PublishBatchPosition
PublishBatchPosition PROC NEAR
ASSUME	DS:RESGROUP
	PUSH	DS
	PUSH	SI
	LDS	SI,[DosCommandState]
	MOV	[SI+0AH],BX
	MOV	[SI+0CH],DX
	POP	SI
	POP	DS
	RET
PublishBatchPosition ENDP

;*** SetCommandInputState -- Select the command input state.
;
;	ENTRY	DS = resident segment
;	EXIT	DX = input state; AX preserved
;
	PUBLIC	SetCommandInputState
SetCommandInputState PROC NEAR
ASSUME	DS:RESGROUP
	XOR	DX,DX
	CMP	[BATCH],DX
	JNZ	SHORT NotifyCommandState
	CMP	[PermCom],DL
	JZ	SHORT InputStateReady
	CMP	[SINGLECOM],-1
	JNZ	SHORT NotifyCommandState
InputStateReady:
	INC	DX
SetCommandInputState ENDP

;*** NotifyCommandState -- Issue the command state multiplex call.
;
;	ENTRY	DX = state request
;	EXIT	flags reflect the multiplex result; AX preserved
;
	PUBLIC	NotifyCommandState, ClearCommandState, QueryCommandState
NotifyCommandState PROC NEAR
	PUSH	AX
	MOV	AX,168FH
	INT	2FH
	TEST	AX,AX
	POP	AX
	RET
NotifyCommandState ENDP

ClearCommandState PROC NEAR
	PUSH	DX
	XOR	DX,DX
CommandStateCall:
	CALL	NotifyCommandState
	POP	DX
	RET
ClearCommandState ENDP

QueryCommandState PROC NEAR
	PUSH	DX
	MOV	DX,100H
	JMP	SHORT CommandStateCall
QueryCommandState ENDP

IF IBM_ROM_FIND
	include vector.inc
	include pdb.inc
	include arena.inc
	include mshalo.asm
ENDIF

TRANCODE	ENDS
	END

