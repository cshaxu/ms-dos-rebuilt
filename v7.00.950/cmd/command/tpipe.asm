	page ,132
;	SCCSID = @(#)tpipe.asm	1.1 85/05/14
;	SCCSID = @(#)tpipe.asm	1.1 85/05/14
TITLE	PART8 COMMAND Transient routines.
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
	include pdb.inc
	include comseg.asm
	include comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ECHOFLAG:BYTE
	EXTRN	InitFlag:byte
	EXTRN	INPIPEPTR:WORD
	EXTRN	OUTPIPEPTR:WORD
	EXTRN	PIPE1:BYTE
;;;	EXTRN	PIPE1T:BYTE
	EXTRN	PIPE2:BYTE
;;;	EXTRN	PIPE2T:BYTE
	EXTRN	PIPEFILES:BYTE
	EXTRN	PIPEFLAG:BYTE
	EXTRN	PIPEPTR:WORD
	EXTRN	RESTDIR:BYTE
	EXTRN	SINGLECOM:WORD

DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADDAT_PTR:WORD
	EXTRN	BADTIM_PTR:WORD
	EXTRN	curdat_mo_day:word	;AN000;
	EXTRN	CURDAT_PTR:WORD
	EXTRN	curdat_yr:word		;AN000;
	EXTRN	curtim_hr_min:word	;AN000;
	EXTRN	CURTIM_PTR:WORD
	EXTRN	curtim_sec_hn:word	;AN000;
	EXTRN	eurdat_ptr:word
	EXTRN	japdat_ptr:word
	EXTRN	newdat_format:word	;AN000;
	EXTRN	NEWDAT_PTR:WORD
	EXTRN	NEWTIM_PTR:WORD
	EXTRN	parse_date:byte 	;AN000;
	EXTRN	parse_time:byte 	;AN000;
	EXTRN	PIPEEMES_PTR:WORD
	EXTRN	promtim_hr_min:word	;AN000;
	EXTRN	promtim_ptr:word	;AN000;
	EXTRN	promtim_sec_hn:word	;AN000;
	EXTRN	STRING_BUF_PTR:WORD	;AC000;
	EXTRN	SYNTMES_PTR:WORD
	EXTRN	usadat_ptr:word

	extrn	TempVarName:byte

TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	COMBUF:BYTE
	EXTRN	ComBufPtr:WORD
	EXTRN	TranSpaceEnd:BYTE
	EXTRN	ParseArgIndex:WORD
	EXTRN	date_day:byte		;AN000;
	EXTRN	date_month:byte 	;AN000;
	EXTRN	date_year:word		;AN000;
	EXTRN	INTERNATVARS:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	time_fraction:byte	;AN000;
	EXTRN	time_hour:byte		;AN000;
	EXTRN	time_minutes:byte	;AN000;
	EXTRN	time_seconds:byte	;AN000;
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE
ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	CERROR:NEAR
	EXTRN	NOPIPEPROC:NEAR
	EXTRN	parseline:NEAR
	EXTRN	GETARG:NEAR
	EXTRN	ParseArgument:NEAR,CheckParsedArgs:NEAR
	EXTRN	STD_PRINTF:NEAR
	EXTRN	TCOMMAND:NEAR
	EXTRN	TESTDOREIN:NEAR
	EXTRN	TESTDOREOUT:NEAR
	EXTRN	TESTKANJ:NEAR		;AN000;3/3/KK
	EXTRN	TSYSGETMSG:NEAR 	;AN000;

	extrn	Find_Name_In_Environment:near

	PUBLIC	CTIME
	PUBLIC	DATE
	PUBLIC	PIPEDEL
	PUBLIC	PIPEERRSYN
	PUBLIC	PIPEPROC
	PUBLIC	PIPEPROCSTRT
	PUBLIC	PRINT_TIME
	PUBLIC	SETREST
	PUBLIC	SETREST1
	PUBLIC	SINGLETEST

SINGLETEST:
	ASSUME	DS:NOTHING
	push	ds
	MOV	DS,ResSeg
	ASSUME	DS:ResGroup
	CMP	[SINGLECOM],0
	JZ	TestDone
	CMP	[SINGLECOM],0EFFFH
TestDone:
	pop	ds
	return


ASSUME	DS:TRANGROUP
SETREST1:
	MOV	AL,1
SETREST:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	[RESTDIR],AL
	POP	DS
ASSUME	DS:TRANGROUP
	return

ASSUME	DS:RESGROUP

;
; Note that we need to handle the same thing that RestDir handles:  the
; requirement that we try only once to restore the user's environment after
; and INT 24 or the like.  If the condition that causes the INT 24 does not
; disappear, we just give up.
;

PIPEDEL:
	assume	ds:nothing
	push	ds
	PUSH	DX
	mov	ds,ResSeg
	assume	ds:ResGroup
	mov	DX,OFFSET RESGROUP:PIPE1	; Clean up in case ^C
	MOV	AH,UNLINK
	INT	21h
	MOV	DX,OFFSET RESGROUP:PIPE2
	MOV	AH,UNLINK
	INT	21h
	POP	DX
	call	PipeOff
	mov	PipeFiles,0
	pop	ds
	return

PIPEERRSYN:
	MOV	DX,OFFSET TRANGROUP:SYNTMES_ptr
	CALL	PIPEDEL
	PUSH	CS
	POP	DS
	JMP	CERROR
PIPEERR:
	pushf
	invoke	triageError
	SaveReg    <AX,DX>			; Save results from TriageError
	MOV	DX,OFFSET TRANGROUP:PIPEEMES_ptr
	CALL	PIPEDEL
	PUSH	CS
	POP	DS
	invoke	std_eprintf
	RestoreReg <DX,AX>			; Restore results from TriageError
	popf
	cmp	ax, 65
	jnz	tcommandj
	JMP	CERROR
tcommandj:
	jmp	tcommand

PIPEPROCSTRT:
ASSUME	DS:TRANGROUP,ES:TRANGROUP
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	INC	[PIPEFILES]			; Flag that the pipe files exist

	push	es
	push	di
	push	ds
	push	si

	push	ds
	push	es
	pop	ds				;ds = TRANGROUP
	mov	si,offset TRANGROUP:TempVarName	;ds:si = "TEMP="
	mov	byte ptr es:[TranSpaceEnd-1],0
;
;Some hideous code in Find_Name_In_Environment. Expects ds = TRANGROUP and
;so the routine is not really general
;
	call	Find_Name_In_Environment		;es:di points at path
	pop	ds				;ds = DATARES again
	jc	no_temp_path

	push	ds
	push	es
	pop	ds
	pop	es				;swap ds and es
	mov	si,di				;ds:si points at path

	call	skip_white			;skip white space chars
;
;This copies the path into both buffers -- Pipe1 & Pipe2
;
	call	copy_pipe_path			;copy the pipe path


;
;Check if the TEMP path is valid
;
	push	es
	pop	ds				;ds = DATARES
	mov	dx,offset DATARES:Pipe1		;ds:dx = path to look for
	mov	ax, (CHMOD shl 8) or 0
	int	21h
	jc	no_temp_path

	test	cx,10h				;is it a directory?
	jnz	no_temp_path			;yes, continue (carry clear)

	stc					;no, indicate fail

no_temp_path:
	pop	si
	pop	ds
	pop	di
	pop	es
	jnc	crt_temp			;path found, create tempfiles
;;;;
;;;;Invalid or no TEMP path, default to root of current drive
;;;;

;;;	MOV	AH,Get_Default_Drive		; Get current drive
;;;	INT	21h
;;;	ADD	AL,capital_A
;;;	MOV	PIPE2,AL			; Make pipe files in root of def drv
;;;	MOV	Pipe1,AL
;;;	mov	al,':'
;;;	mov	ah,'\'
;;;	mov	word ptr Pipe1+1,ax
;;;	mov	word ptr Pipe2+1,ax			;store ':\'
;;;
;;;	xor	ah,ah				; nul terminate path names
;;;	mov	Pipe1+3,ah
;;;	mov	Pipe2+3,ah

;SR;
; We want to create temp files in the current directory rather than in the 
;root of the drive. This is because the number of files that can be present
;in the root directory is fixed, whereas it is not so in subdirectories.
;
	mov	ax,'.'
	mov	word ptr Pipe1,ax
	mov	word ptr Pipe2,ax			;create files in current dir

crt_temp:
	MOV	DX,offset DATARES:Pipe1
	XOR	CX,CX
	mov	ah,CreateTempFile		; the CreateTemp call
	INT	21h
	JnC	@f
	jmp	PIPEERR 			; Couldn't create
@@:
	MOV	BX,AX
	MOV	AH,CLOSE			; Don't proliferate handles
	INT	21h

	MOV	DX,OFFSET RESGROUP:PIPE2
	mov	ah,createTempFile		; the CreateTemp call
	INT	21h
	JnC	@f
	jmp	PIPEERR
@@:
	MOV	BX,AX
	MOV	AH,CLOSE
	INT	21h

	CALL	TESTDOREIN			; Set up a redirection if specified
	MOV	SI,[PIPEPTR]
	CMP	[SINGLECOM],-1
	JNZ	NOSINGP
	MOV	[SINGLECOM],0F000H		; Flag single command pipe
NOSINGP:
	JMP	SHORT FIRSTPIPE

PIPEPROC:
ASSUME	DS:RESGROUP
	AND	[ECHOFLAG],0FEh 		; force current echo to be off
	MOV	SI,[PIPEPTR]
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	LODSB
	POP	DS
	CMP	AL,AltPipeChr			; Alternate pipe char?
	JZ	IsPipe1 			; Yes
	CMP	AL,vbar
	jz	IsPipe1
	jmp	PIPEEND 			; Pipe done
IsPipe1:
	MOV	DX,[INPIPEPTR]			; Get the input file name
	MOV	AX,(OPEN SHL 8) or 20h
	INT	21h
PIPEERRJ:
	jnc	no_pipeerr
	JMP	PIPEERR 			; Lost the pipe file
no_pipeerr:
	MOV	BX,AX
	MOV	AL,0FFH
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table],AL		; Redirect

FIRSTPIPE:
	MOV	DI,ES:[ComBufPtr]			; Dynamic command buffer
	XOR	CX,CX
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	CMP	BYTE PTR [SI],0DH
	POP	DS		; '|<CR>'
	JNZ	PIPEOK1
PIPEERRSYNJ:
	JMP	PIPEERRSYN
PIPEOK1:
	mov	al,vbar
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	CMP	BYTE PTR [SI],al
	POP	DS		; '||'
	JZ	PIPEERRSYNJ
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	CMP	BYTE PTR [SI],AltPipeChr
	POP	DS	; '##' or '|#'?
	JZ	PipeErrSynJ			; Yes, Error
PIPECOMLP:
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	LODSB
	POP	DS
	STOSB

;;;;	IFDEF	DBCS		3/3/KK
	CALL	TESTKANJ
	JZ	NOTKANJ5
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	MOVSB
	POP	DS
;
;  Added following 2 commands to the fix pipe bug.
;
	inc	cx				;AN000;  3/3/KK
	inc	cx				;AN000;  3/3/KK
;
	JMP	PIPECOMLP

NOTKANJ5:
	CMP	AL,22h
	JNE	PipeQuoteDone
	INC	CX
PipeQuoteCopy:
	PUSH	DS
	MOV	DS,WORD PTR [PIPEPTR+2]
	LODSB
	POP	DS
	STOSB
	INC	CX
	CMP	AL,22h
	JNE	PipeQuoteCopy
	JMP	PIPECOMLP
PipeQuoteDone:
;;;;	ENDIF			; 3/3/KK

	CMP	AL,0DH
	JZ	LASTPIPE
	INC	CX
	CMP	AL,AltPipeChr
	JZ	IsPipe2
	CMP	AL,vbar
	JNZ	PIPECOMLP
IsPipe2:
	MOV	BYTE PTR ES:[DI-1],0DH
	DEC	CX
	PUSH	DI
	MOV	DI,ES:[ComBufPtr]
	MOV	ES:[DI-2],CX			; Save the word length
	POP	DI
	DEC	SI
	MOV	[PIPEPTR],SI			; On to next pipe element
	MOV	DX,[OUTPIPEPTR]
	PUSH	CX
	XOR	CX,CX
	MOV	AX,(CREAT SHL 8)
	INT	21h
	POP	CX
	JNC	PipeFileCreated
	JMP	PIPEERRJ			; Lost the file
PipeFileCreated:
	MOV	BX,AX
	MOV	AL,0FFH
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table+1],AL
	XCHG	DX,[INPIPEPTR]			; Swap for next element of pipe
	MOV	[OUTPIPEPTR],DX
	JMP	SHORT PIPECOM

LASTPIPE:
	PUSH	DI
	MOV	DI,ES:[ComBufPtr]
	MOV	ES:[DI-2],CX			; Save the word length
	POP	DI
	DEC	SI
	MOV	[PIPEPTR],SI			; Point at the CR (anything not '|' will do)
	CALL	TESTDOREOUT			; Set up the redirection if specified
PIPECOM:
	PUSH	CS
	POP	DS
	JMP	NOPIPEPROC			; Process the pipe element

PIPEEND:
	CALL	PIPEDEL
	CMP	[SINGLECOM],0F000H
	JNZ	NOSINGP2
	MOV	[SINGLECOM],-1			; Make it return
NOSINGP2:
	JMP	TCOMMAND

ASSUME	DS:TRANGROUP,ES:TRANGROUP



; DATE - Gets and sets the time


	break	Date


; ****************************************************************
; *
; * ROUTINE:	 DATE - Set system date
; *
; * FUNCTION:	 If a date is specified, set the system date,
; *		 otherwise display the current system date and
; *		 prompt the user for a new date.  If an invalid
; *		 date is specified, issue an error message and
; *		 prompt for a new date.  If the user enters
; *		 nothing when prompted for a date, terminate.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

DATE:
	mov	di,offset TRANGROUP:PARSE_DATE
	mov	ParseArgIndex,1
	call	ParseArgument
	jnc	COMDAT
	or	ax,ax
	jnz	DATERR
PRMTDAT:
	invoke	GetDate
	xchg	dh,dl
	mov	CurDat_yr,cx
	mov	CurDat_mo_day,dx
	mov	dx,offset TRANGROUP:CurDat_ptr
	invoke	std_printf
GET_NEW_DATE:
	call	GETDAT
	jnc	COMDAT
	or	ax,ax
	jz	date_end
	jmp	short DATERR
COMDAT:
	mov	cx,date_year
	mov	dh,date_month
	mov	dl,date_day
	push	cx
	push	dx
	call	CheckParsedArgs
	pop	dx
	pop	cx
	jnc	DATERR
	mov	ah,SET_DATE
	int	21H
	or	al,al
	jnz	DATERR
date_end:
	ret
DATERR:
	invoke	CRLF2
	mov	dx,offset TRANGROUP:BADDAT_ptr
	invoke	std_printf
	jmp	short GET_NEW_DATE

; TIME gets and sets the time

	break	Time

; ****************************************************************
; *
; * ROUTINE:	 TIME - Set system time
; *
; * FUNCTION:	 If a time is specified, set the system time,
; *		 otherwise display the current system time and
; *		 prompt the user for a new time.  If an invalid
; *		 time is specified, issue an error message and
; *		 prompt for a new time.  If the user enters
; *		 nothing when prompted for a time, terminate.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

CTIME:
	invoke	GETARG
	jz	PRMTTIM
	mov	di,offset trangroup:parse_time	;AN000; Get adderss of PARSE_time
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser
	cmp	ax,end_of_line			;AC000; are we at end of line?
	JZ	PRMTTIM 			;AC000; yes - prompt for time
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	timerr				;AN000; yes - go issue message
	JMP	short COMTIM			;AC000; we have a time

PRMTTIM:
	;Printf "Current time is ... "

	MOV	AH,GET_TIME			;AC000; get the current time
	INT	21h			;AC000;    Get time in CX:DX
	xchg	ch,cl				;AN000; switch hours & minutes
	xchg	dh,dl				;AN000; switch seconds & hundredths
	mov	CurTim_hr_min,cx		;AC000; put hours and minutes into message subst block
	mov	CurTim_sec_hn,dx		;AC000; put seconds and hundredths into message subst block
	mov	dx,offset trangroup:CurTim_ptr	;AC000; set up message for output
	invoke	std_printf
;AD061; mov	CurTim_hr_min,0 		;AC000; reset hour, minutes, seconds, and hundredths
;AD061; mov	CurTim_sec_hn,0 		;AC000;     pointers in control block

GET_NEW_TIME:
	call	gettim				;AC000;
	cmp	ax,end_of_line			;AC000; are we at end of line?
	jz	time_end			;AC000;
	cmp	ax,result_no_error		;AN000; did we have an error?
	jne	timerr				;AN000; yes - go issue message

COMTIM:
	mov	ch,time_hour			;AC000; get parts of time in
	mov	cl,time_minutes 		;AC000;    cx and dx for set
	mov	dh,time_seconds 		;AC000;    time function call
	mov	dl,time_fraction		;AC000;
	push	cx				;AC000; save time
	push	dx				;AC000;
	mov	cx,1				;AC000; set 1 positional parm entered
	xor	dx,dx				;AN029;
	invoke	cmd_parse			;AN029; call parser
	cmp	al,end_of_line			;AN029; Are we at end of line?
	pop	dx				;AC000; retieve time
	pop	cx				;AC000;
	jnz	timerr				;AC000; extra stuff on line - try again

SAVTIM:
	MOV	AH,SET_TIME
	INT	21h
	OR	AL,AL
	JNZ	TIMERR				;AC000; if an error occured, try again

TIME_END:

	ret

TIMERR:
	invoke	crlf2				;AN028; print out a blank line
	MOV	DX,OFFSET TRANGROUP:BADTIM_ptr
	invoke	std_printf			; Print error message
	JMP	GET_NEW_TIME			;AC000; Try again


;
; Set the special flag in the INIT flag to the value in CX.
;
SetInitFlag:
	mov	ds,[RESSEG]
assume ds:resgroup
	and	InitFlag,NOT initSpecial
	or	InitFlag,cL
	push	cs
	pop	ds
	return

Public	PipeOff
PipeOff:
	ASSUME	DS:NOTHING,ES:NOTHING
	SaveReg <DS,AX>
	MOV	DS,ResSeg
	ASSUME	DS:RESGroup
	XOR	AX,AX
	XCHG	AX,WORD PTR PipePtr+2
	OR	AX,AX
	JZ	PipeTextFreed
	PUSH	ES
	MOV	ES,AX
	MOV	AH,DEALLOC
	INT	21h
	POP	ES
PipeTextFreed:
	XOR	AL,AL
	XCHG	PipeFlag,AL
	OR	AL,AL
	JZ	PipeOffDone
	SHR	EchoFlag,1
PipeOffDone:
	RestoreReg  <AX,DS>
	return


PRINT_TIME:

	MOV	AH,GET_TIME
	INT	21h			; Get time in CX:DX

	PUSH	ES
	PUSH	CS
	POP	ES
	xchg	ch,cl				;AN000; switch hours & minutes
	xchg	dh,dl				;AN000; switch seconds & hundredths
	mov	promTim_hr_min,cx		;AC000; put hours and minutes into message subst block
	mov	promTim_sec_hn,dx		;AC000; put seconds and hundredths into message subst block
	mov	dx,offset trangroup:promTim_ptr ;AC000; set up message for output
	invoke	std_printf
;AD061; mov	promTim_hr_min,0		;AC000; reset hour, minutes, seconds, and hundredths
;AD061; mov	promTim_sec_hn,0		;AC000;     pointers in control block

	POP	ES
	return


; ****************************************************************
; *
; * ROUTINE:	 GETDAT - Prompt user for date
; *
; * FUNCTION:	 Gets the date format from the COUNTRY DEPENDENT
; *		 INFORMATION and issues the "Enter new date"
; *		 message with the proper date format.  COMBUF
; *		 is reset to get a date from the command line.
; *		 The PARSE_DATE blocks are then reset and the
; *		 PARSE function call is issued.
; *
; * INPUT:	 NONE
; *
; * OUTPUT:	 COMBUF
; *		 PARSER RETURN CODES
; *
; ****************************************************************


GETDAT	proc	near				;AC000;

	mov	ax,(International SHL 8)	; Determine what format the date
	mov	dx,5ch				;  should be entered in and
	int	21h			;  print a message describing it
	mov	si,dx
	lodsw
	mov	dx,usadat_ptr			;AC000; get mm-dd-yy
	dec	ax
	js	printformat
	mov	dx,eurdat_ptr			;AC000; get dd-mm-yy
	jz	printformat
	mov	dx,japdat_ptr			;AC000; get yy-mm-dd
printformat:
	mov	ax,dx				;AN000; get message number of format
	mov	dh,util_msg_class		;AN000; this is a utility message
	call	Tsysgetmsg			;AN000; get the address of the message
	mov	newdat_format,si		;AN000; put the address in subst block
	MOV	DX,OFFSET TRANGROUP:NEWDAT_ptr	;AC000; get address of message to print
	invoke	std_printf
	mov	newdat_format,no_subst		;AN000; reset subst block

	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,CS:[ComBufPtr]
	SUB	DX,2
	PUSH	SI
	MOV	SI,DX
	MOV	BYTE PTR [SI],COMBUFLEN
	MOV	WORD PTR [SI+1],0D00H
	POP	SI
	mov	cx,initSpecial			; Set bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for date.
	INT	21h			; Get input line
	PUSH	SI
	MOV	SI,CS:[ComBufPtr]
	SUB	SI,2
	MOV	CL,[SI+1]
	XOR	CH,CH
	MOV	[SI],CX
	POP	SI
	xor	cx,cx				; Reset bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for date.
	invoke	CRLF2
	CALL	parseline
	jc	short GetDateDone
	mov	di,offset TRANGROUP:PARSE_DATE
	mov	CS:ParseArgIndex,0
	call	ParseArgument
GetDateDone:

	ret

GETDAT	endp					;AC000;


; ****************************************************************
; *
; * ROUTINE:	 GETTIME - Prompt user for time
; *
; * FUNCTION:	 Gets the time format from the COUNTRY DEPENDENT
; *		 INFORMATION and issues the "Enter new time"
; *		 message. COMBUF is reset to get a time from the
; *		 command line.	The PARSE_TIME blocks are then
; *		 reset and the PARSE function call is issued.
; *
; * INPUT:	 NONE
; *
; * OUTPUT:	 COMBUF
; *		 PARSER RETURN CODES
; *
; ****************************************************************


GETTIM	proc	near				;AC000;

	XOR	CX,CX				; Initialize hours and minutes to zero
	MOV	DX,OFFSET TRANGROUP:NEWTIM_ptr
	invoke	std_printf
	MOV	AH,STD_CON_STRING_INPUT
	MOV	DX,OFFSET TRANGROUP:TranSpaceEnd
	MOV	SI,DX
	MOV	BYTE PTR [SI],COMBUFLEN
	MOV	WORD PTR [SI+1],0D00H
	mov	cx,initSpecial			; Set bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for time.
	INT	21h			; Get input line
	xor	cx,cx				; Reset bit in InitFlag that indicates
	call	SetInitFlag			;  prompting for time.
	invoke	CRLF2
	MOV	SI,OFFSET TRANGROUP:TranSpaceEnd+2
	mov	di,offset trangroup:parse_time	;AN000; Get adderss of PARSE_TIME
	xor	cx,cx				;AN000; clear counter for positionals
	xor	dx,dx				;AN000;
	invoke	cmd_parse			;AC000; call parser

	ret

GETTIM	endp					;AC000;

;
;Skip_white: Skips over the whitespace chars that could be present after
;the '=' sign in the environment variable before the actual path.
;
;	ENTRY:	ds:si = arguments of the environment variable
;
;	EXIT:	ds:si = start of the path
;
;	REGISTERS AFFECTED: ax
;

Skip_white	proc	near

	cld
skw_lp:
	lodsb
	cmp	al,' '				;blank char?
	jz	skw_lp				;yes, skip it
	cmp	al,09				;tab char?
	jz	skw_lp				;yes, skip it

	dec	si				;point at first non-white

	ret

Skip_white	endp

;
;Copy_pipe_path:	This routine copies the path from the TEMP environment
;variable into the path buffers Pipe1 & Pipe2.
;
;	ENTRY:	ds:si = path to be copied
;		es = RESGROUP
;
;	EXIT:	Path copied into Pipe1 and Pipe2.
;
;	REGISTERS AFFECTED: si, di, cx, ax
;

Copy_pipe_path	proc	near

	mov	cx,0ffffh
	xor	al,al

	mov	di,si
	push	es			;save es
	push	ds
	pop	es			;es:di = path to be copied
	
	cld
	push	di
	repnz	scasb			;look for the null char
	pop	di

	pop	es			;es = RESGROUP again

	not	cx			;length including the null

	mov	di,offset DATARES:Pipe1	
	push	di
	push	cx			
	rep	movsb			;copy path into Pipe1
	pop	cx
	pop	di

	push	ds
	push	es
	pop	ds			;ds:si = Pipe1
	mov	si,di
	mov	di,offset DATARES:Pipe2	;es:di = Pipe2
	rep	movsb			;copy path into Pipe2
	pop	ds

	ret				;

Copy_pipe_path	endp


TRANCODE    ENDS
	    END
