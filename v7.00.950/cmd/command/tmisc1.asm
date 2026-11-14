	page ,132
;	SCCSID = @(#)tmisc1.asm 4.1 85/09/22
;	SCCSID = @(#)tmisc1.asm 4.1 85/09/22
TITLE	Part7 COMMAND Transient Routines
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;	M003	SR	07/16/90	Made Execute public to jump to it for
;				LoadHigh support
;
;	M025	SR	9/12/90	Removed calls to SetStdInOn,SetStdInOff
;				SetStdOutOn & SetStdOutOff.
;


;	More misc routines

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
;;	EXTRN	RSTACK:BYTE
CodeRes 	ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	CALL_FLAG:BYTE
	EXTRN	EchoFlag:BYTE
	EXTRN	EXEC_BLOCK:BYTE
	EXTRN	EXTCOM:BYTE
	EXTRN	LenMsgOrPathBuf:ABS
	EXTRN	PIPEFLAG:BYTE
	EXTRN	PIPEPTR:WORD
	EXTRN	RESTDIR:BYTE
	EXTRN	RetCode:WORD
	EXTRN	YSwitchFlags:WORD
	EXTRN	RE_OUT_APP:BYTE
	EXTRN	RE_OUTSTR:BYTE
	EXTRN	SAFEPATHBUFFER:BYTE

	extrn	RStack:word

ifdef	BETA3WARN
        %out    BETA WARNING: Take this out before we ship retail product
	EXTRN	Beta3Warned:byte
	EXTRN	TrnSeg:word
endif


DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADDRV_PTR:WORD
	EXTRN	PipeMemErr_Ptr:WORD
	EXTRN	BADNAM_PTR:WORD
	EXTRN	NoWin_Ptr:WORD
	EXTRN	COMTAB:BYTE		;AC000;
	EXTRN	CommandNames:BYTE
	EXTRN	extend_buf_ptr:word	;AN000;
	EXTRN	msg_disp_class:byte	;AN000;

ifdef	BETA3WARN
        %out    BETA WARNING: Take this out before we ship retail product
	EXTRN	Beta3WarnMsg:byte
endif

TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE
	EXTRN	PathFindMode:BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
	EXTRN	ALLSWITCH:WORD
	EXTRN	APPEND_EXEC:BYTE	;AN041;
	EXTRN	CHKDRV:BYTE
	EXTRN	ComBufPtr:WORD
	EXTRN	COMSW:WORD
	EXTRN	ExecState:BYTE
	EXTRN	EXECPATH:BYTE
	EXTRN	EXEC_ADDR:DWORD
	EXTRN	FILTYP:BYTE
	EXTRN	fTest:WORD
	EXTRN	IDLEN:BYTE
	EXTRN	KPARSE:BYTE		;AC000;
	EXTRN	PARM1:BYTE
	EXTRN	PARM2:BYTE
	EXTRN	PathPos:word
	EXTRN	RESSEG:WORD
	EXTRN	RE_INSTR:BYTE
	EXTRN	SPECDRV:BYTE
	EXTRN	SWITCHAR:BYTE
	EXTRN	switch_list:byte
	EXTRN	TRAN_TPA:WORD

IFDEF ROMEXEC
	EXTRN	ExecFromROM:byte
	EXTRN	fbuf:byte
ENDIF

	IF  IBM_ROM_FIND
	EXTRN	ROM_CALL:BYTE
	EXTRN	ROM_CS:WORD
	EXTRN	ROM_IP:WORD
	ENDIF

TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC byte

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	APPEND_PARSE:NEAR	;AN010;
	EXTRN	BATCOM:NEAR
	EXTRN	DOCOM1:NEAR
	EXTRN	PIPEERRSYN:NEAR
	EXTRN	PrepareLongCommand:NEAR
	EXTRN	CanonicalizePath:NEAR
	EXTRN	cmd_copy:NEAR
	EXTRN	QuoteDelim:NEAR
	EXTRN	TCOMMAND:NEAR

	IF	IBM_ROM_FIND
	EXTRN	ROM_EXEC:NEAR
	EXTRN	ROM_SCAN:NEAR
	ENDIF

	PUBLIC	CERROR
	PUBLIC	DRVBAD
	PUBLIC	EXTERNAL
	PUBLIC	FNDCOM
	PUBLIC	PRESCAN
	PUBLIC	SWITCH

	public	Lh_Execute			; M051


ASSUME	DS:TRANGROUP

;---------------------------
; We can get rid of this switch processing code if we can take
; care of the remaining two calls to switch, later in the file.
; However, I have not checked whether or not any other files use
; switch -- after all, it IS public!
;---------------------------

SWCOUNT EQU	8				; Length of switch_list

RETSW:
	XCHG	AX,BX				; Put switches in AX
	return

SWITCH:
	XOR	BX,BX				; Initialize - no switches set
SWLOOP:
	INVOKE	SCANOFF 			; Skip any delimiters
	CMP	AL,[SWITCHAR]			; Is it a switch specifier?
	JNZ	RETSW				; No -- we're finished
	OR	BX,fSwitch			; Indicate there is a switch specified
	INC	SI				; Skip over the switch character
	INVOKE	SCANOFF
	CMP	AL,0DH
	JZ	RETSW				; Oops
	INC	SI
; Convert lower case input to upper case
	INVOKE	UPCONV
	MOV	DI,OFFSET TRANGROUP:switch_list
	MOV	CX,SWCOUNT
	REPNE	SCASB				; Look for matching switch
	JNZ	BADSW
	SUB	CX,SWCOUNT
	NEG	CX
	DEC	CX
	MOV	AX,1
	SHL	AX,CL				; Set a bit for the switch
	OR	BX,AX
	JMP	SHORT SWLOOP

BADSW:
	JMP	SHORT SWLOOP

DRVBAD:
	MOV	DX,OFFSET TRANGROUP:BADDRV_ptr
	JMP	CERROR

externalj:
	jmp	EXTERNAL

fndcom: 					; search the internal command table
    OR	    AL,AL				; Get real length of first arg
    jz	    externalj				; If 0, it must begin with "\" so has
						;  to be external.
; barryf code starts here

	IF	IBM
	call	test_append			; see if APPEND installed
	je	contcom 			; not loaded

append_internal:
	mov	cl,TRANGROUP:IDLEN
	mov	ch,0
	mov	pathpos,cx
	inc	append_exec			;AN041; set APPEND to ON

	invoke	ioset				; re-direct the o'l io

	mov	SI, offset TRANGROUP:IDLEN	; address command name, DS already set
	mov	DX,-1				; set invoke function
	mov	di,offset TRANGROUP:APPEND_PARSE;AN010; Get the entry point for PARSE for APPEND
	mov	AX,0AE01H
	int	2FH				; execute command
	cmp	TRANGROUP:IDLEN,0		; execute requested
;;	je	Cmd_done
	jne	contcom
	jmp	Cmd_done

contcom:					; continue with internal scan
	ENDIF

; barryf code ends here

    mov     DI, OFFSET TRANGROUP:CommandNames
    XOR     CX,CX
    XOR     BX,BX
findcom:
    mov     SI, offset TRANGROUP:IDLEN+1
    mov     CL, [DI]
    inc     DI
    jcxz    externalj
    cmp     CL, IDLEN
    jnz     nextcom
    mov     PathPos,CX
    repz    cmpsb
    jz      foundcom
nextcom:
    add     DI,CX
    inc     BX
    jmp     findcom
foundcom:
    mov     AX,5
    mul     BL
    mov     DI,OFFSET TRANGROUP:COMTAB
    add     DI,AX
    mov     AL,[DI]
    mov     [CHKDRV],AL
    inc     DI
    mov     BX,WORD PTR [DI]
    inc     DI
    inc     DI
    mov     DX,WORD PTR [DI]
;
; All messages get redirected.
;
    cmp     append_exec,0			;AN041; APPEND just executed?
    jnz     dont_set_io 			;AN041; Yes - this junk is already set
    invoke  ioset				; re-direct the ol' i/o

dont_set_io:					;AN041;
;
; Check for /?.  Certain commands, flagged fLimitHelp,
; respond to /? only if it is the only command-line argument.
;
    mov     ax,[COMSW]				; AX = switches after command
    or      ax,[ALLSWITCH]			; AX = all switches
    and     ax,SwitchQues
    jz      drive_check				; /? not in command line

    test    [CHKDRV],fLimitHelp
    jz      do_help				; /? allowed in combination
;
; Make sure /? is the only argument on the command line.
;
    cmp     [arg.argvcnt],2
    jne     drive_check				; /? not only arg - ignore
;
; Note:  this is all the check we need, even against things like /??.
; Our argv parser breaks /?? into two args, /? and ?.
;

do_help:

; DX = ptr to word list of msg #s, terminated by zero word

    mov     si,dx				; SI = ptr to list of msg #s
    mov     ax,NO_SUBST				; AL = no subst's code
    push    ax					; build subst block on stack

next_help_msg:
    lodsw					; AX = help msg # or zero
    or      ax,ax
    jz      help_done
    push    ax					; SS:SP = ptr to subst block
						;  (msg # and no_subst byte)
; We assume DS = SS.

    mov     dx,sp				; DS:DX = ptr to subst block
    invoke  Std_PrintF				; display help message
    pop     ax					; remove msg # from stack
    jmp     next_help_msg

help_done:
    pop     ax					; clean up stack
    jmp     TCommand

drive_check:
    test    [CHKDRV], fCheckDrive		; did we wanna check those drives?
    jz	    nocheck
    mov     AL, [PARM1] 			; parse_file_descriptor results tell
    or	    AL, [PARM2] 			; us whether those drives were OK
    cmp     AL, -1
    jnz     nocheck
    jmp     drvbad


;
; The user may have omitted the space between the command and its arguments.
; We need to copy the remainder of the user's command line into the buffer.
; Note that thisdoes not screw up the arg structure; it points into COMBUF not
; into the command line at 80.
;
nocheck:
    call    cmd_copy

switcheck:
    test    [CHKDRV], fSwitchAllowed		; Does the command take switches
    jnz     realwork				; Yes, process the command
    call    noswit				; No, check to see if any switches
    jz      realwork				; None, process the command
    mov     msg_disp_class,parse_msg_class	;AN000; set up parse error msg class
    MOV     DX,OFFSET TranGroup:Extend_Buf_ptr	;AC000; get extended message pointer
    mov     Extend_Buf_ptr,BadSwt_ptr		;AN000; get "Invalid switch" message number
    jmp     CERROR				; Print error and chill out...
realwork:
    push    PathPos
    call    BX					; do some real work, at last
    push    cs
    pop     ds
    pop     PathPos

; See if we're in a batch CALL command. If we are, reprocess the command line,
; otherwise, go get another command.

Cmd_done:
    push    cs					; g  restore data segment
    pop     ds					; g
    push    ds					; g  save data segment
    mov     ds,[resseg] 			; g  get segment containing call flag
    ASSUME  ds:resgroup
    cmp     call_flag, call_in_progress 	; G  Is a call in progress?
    mov     call_flag, 0			; G  Either way, reset flag
    pop     ds					; g  get data segment back
    jz	    incall				; G
    jmp     tcommand				; chill out...

incall:
    JMP     DOCOM1

noswit:
    push    ax
    mov     ax,cs:[arg.argswinfo]       ; switches recorded by argument parser
    or      ax,ax
    pop     ax
    ret

EXTERNAL:

IF IBM
	call	test_append			; check to see if append installed
	je	not_barryf			; no - truly external command
	jmp	append_internal 		; yes - go to Barryf code

not_barryf:

ENDIF

	MOV	CS:[FILTYP],0
	MOV	DL,CS:[SPECDRV]
	MOV	CS:[IDLEN],DL

IFDEF ROMEXEC

;*	Check for ROM executable.

	mov	ExecFromROM,0		; ExecFromROM = no
	push	ax
	push	dx

	mov	dx, offset TRANGROUP:fbuf	; set up DTA before
	mov	ah, SET_DMA			;  doing a find first
	int	21h

	mov	dx,arg.argv[0].argpointer	; DX = ptr to command
	mov	ah,ROM_FIND_FIRST		; AH = "Find First ROM File"
	stc
	int	21h				; call DOS
	jc	NotInROM
	inc	ExecFromROM		; ExecFromROM = yes
NotInROM:
	pop	dx
	pop	ax

ENDIF ; ROMEXEC

IF IBM_ROM_FIND
	MOV	[ROM_CALL],0
	PUSH	DX
	MOV	DX,OFFSET TRANGROUP:IDLEN
	CALL	ROM_SCAN
	POP	DX
	JNC	DO_SCAN
	INC	[ROM_CALL]
	JMP	short PostSave
DO_SCAN:
PostSave:
ENDIF

IFDEF ROMEXEC

;*	No additional searching needed for ROM file.  Just execute
;	with int 21h Exec function.

	cmp	ExecFromROM,0
	je	NonROMFile
	push	si
	push	di
	push	cx
	mov	si,arg.argv[0].argpointer
	mov	di,offset TRANGROUP:ExecPath
	mov	cx,arg.argv[0].arglen
	cld
	rep	movsb			; copy command to ExecPath
	mov	word ptr es:[di],0	; and terminate with null
	pop	cx
	pop	di
	pop	si
	jmp	NeoExecute		; go do Exec

NonROMFile:

ENDIF ; ROMEXEC

	MOV	DI,OFFSET TRANGROUP:EXECPATH
	MOV	BYTE PTR [DI],0 		; Initialize to current directory

IF IBM_ROM_FIND
	CMP	[ROM_CALL],0
	JNZ	NeoExecute
ENDIF

RESEARCH:
	invoke	path_search			; find the mother (result in execpath)
	or	AX, AX				; did we find anything?
	je	badcomj45			; null means no (sob)
	cmp	AX, 04H 			; 04H and 08H are .exe and .com
						; fuckin' sixteen-bit machine ought
	jnl	execute 			; to be able to handle a SIXTEEN-BIT
						; DISPLACEMENT!!
	jmp	batcom				; 02H is .bat
BADCOMJ45:
ifdef	BETA3WARN
	JMP	BADCOM
else
	JMP	BADCOM
endif

ASSUME	DS:TRANGROUP,ES:TRANGROUP

	PUBLIC	Lh_Entry
Lh_Entry:
	JMP	SHORT Lh_Execute

EXECUTE:
NeoExecute:
	invoke	IOSET
	mov	ExecState,0
;M051
; Previously LoadHigh was jumping to the execute label above. This was wrong
;because IOSET was getting invoked twice resulting in 2 sets of redirections.
;After a close, this would still leave one open active resulting in sharing
;errors on subsequent opens of the redirected file.
;
Lh_Execute:				;M051

        CALL    BuildExternalTail
        MOV     ES,[RESSEG]
ASSUME  ES:RESGROUP
        MOV     BYTE PTR ES:[RetCode+2],1
	MOV	ES,[TRAN_TPA]
	MOV	AH,DEALLOC
	INT	21h			; Now running in "free" space
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	INC	[EXTCOM]		; Indicate external command
	MOV	[RESTDIR],0		; Since USERDIR1 is in transient, insure
					;  this flag value for re-entry to COMMAND
	MOV	SI,OFFSET TRANGROUP:EXECPATH
	MOV	DI,OFFSET RESGROUP:SAFEPATHBUFFER
	CALL	CopyCanonicalPath		; copy program pathname to resident

	MOV	DI,FCB
	MOV	SI,DI
	MOV	CX,052H 		; moving (100h-5Ch)/2 = 80h-2Eh
	REP	MOVSW			; Transfer parameters to resident header
	MOV	DX,OFFSET RESGROUP:SAFEPATHBUFFER
	PUSH	ES
	POP	DS
	ASSUME	DS:RESGROUP
	TEST	BYTE PTR [YSwitchFlags],4
	JZ	SHORT ExecNoNotify
	MOV	AX,4A16H
	INT	2FH
	MOV	AL,0
	MOV	DI,DX
	MOV	CX,104H
	REPNZ	SCASB
	NOT	CX
	ADD	CX,104H
	MOV	AX,4A17H
	INT	2FH
	PUSH	DX
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	DX,OFFSET TRANGROUP:ExecStarting
	MOV	CX,11
	NOP
	MOV	AX,4A17H
	INT	2FH
	POP	DS
	POP	DX
	MOV	AX,4A18H
	INT	2FH
ExecNoNotify:
	MOV	BX,OFFSET RESGROUP:EXEC_BLOCK
	MOV	AX,EXEC SHL 8
IF IBM_ROM_FIND
	TEST	[ROM_CALL],-1
	JZ	OK_EXEC
	JMP	ROM_EXEC
OK_EXEC:
ENDIF
;
; we are now running in free space.  anything we do from here on may get
; trashed.  Move the stack (also in free space) to allocated space because
; since EXEC restores the stack, somebody may trash what is on the stack.
;
	MOV	CX,ES
	CLI
	MOV	SS,CX
	MOV	SP,OFFSET DATARES:RStack
	STI

ifdef	BETA3WARN
        %out    BETA WARNING: Take this out before we ship retail product

	cmp	Beta3Warned, 0
	jne	NoWarning
	mov	Beta3Warned, 0ffh
	push	ax
	push	cx
	push	dx
	push	ds

	mov	ah, 2ah				; get date
	int	21h
        cmp     cx, yearBETA3WARN
	jb	nwx
	ja	bwarn

        cmp     dh, monthBETA3WARN
	jb	nwx
bwarn:
	mov	ds, trnseg
	assume	ds:trangroup
	mov	dx, offset trangroup:Beta3WarnMsg
	mov	ah, 9
	int	21h

;	wait till a key is hit

@@:
	mov	ah, 6				; console I/O
	mov	dl, 0ffh			; Read
	int	21h
	jz	@b
nwx:
	pop	ds
	assume	ds:resgroup
	pop	dx
	pop	cx
	pop	ax
NoWarning:
endif ; BETA3WARN
	JMP	[EXEC_ADDR]			; Jmp to the EXEC in the resident

ExecStarting DB ' starting',13,10

	ASSUME	DS:TRANGROUP
BADCOM:
	PUSH	CS
	POP	DS
        TEST    BYTE PTR [fTest],8      ; Was WIN requested?
        JZ      SHORT BadCommandName
        AND     BYTE PTR [fTest],NOT 8
        MOV     AX,3305H                ; Get boot drive
        INT     21H
        CMP     DL,3
        JB      SHORT BadCommandDone
        MOV     DX,OFFSET TRANGROUP:NoWin_Ptr
        JMP     SHORT CERROR
BadCommandName:
	MOV	DX,OFFSET TRANGROUP:BADNAM_ptr

CERROR:
	INVOKE	std_eprintf
BadCommandDone:
	JMP	TCOMMAND

;
; Prescan converts the input buffer into a canonicalized form.	All
; redirections and pipes are removed.
;
PRESCAN:					; Cook the input buffer

ASSUME	DS:TRANGROUP,ES:TRANGROUP

	XOR	CX,CX
	XOR	DL,DL
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	SI,[ComBufPtr]
	MOV	DI,SI

CountQuotes:
	LODSB					; get a byte
	CMP	AL,22h				; is it a quote?
	JNZ	CountEnd			; no, try for end of road
	INC	DL				; bump count
	JMP	CountQuotes			; go get next char

CountEnd:
	CMP	AL,13				; end of road?
	JNZ	CountQuotes			; no, go back for next char

;;;;	IFDEF	DBCS		3/3/KK
	PUSH	DX				; save count
	MOV	SI,DI				; get back beginning of buffer

KanjiScan:
	LODSB					; get a byte
	INVOKE	TestKanj			; is it a leadin byte
	JZ	KanjiQuote			; no, check for quotes
	MOV	AH,AL				; save leadin
	LODSB					; get trailing byte
	CMP	AX,DB_SPACE			; is it Kanji space
	JNZ	KanjiScan			; no, go get next
	MOV	[SI-2],2020h			; replace with spaces
	JMP	KanjiScan			; go get next char

KanjiQuote:
	CMP	AL,22h				; beginning of quoted string
	JNZ	KanjiEnd			; no, check for end
	DEC	DL				; drop count
	JZ	KanjiScan			; if count is zero, no quoting

KanjiQuoteLoop:
	LODSB					; get next byte
	CMP	AL,22h				; is it another quote
	JNZ	KanjiQuoteLoop			; no, get another
	DEC	DL				; yes, drop count
	JMP	KanjiScan			; go get next char

KanjiEnd:
	CMP	AL,13				; end of line character?
	JNZ	KanjiScan			; go back to beginning
	POP	DX				; get back original count
;;;;	ENDIF		3/3/KK

	MOV	SI,DI				; restore pointer to begining

PRESCANLP:
	LODSB

;;;;	IFDEF	DBCS		3/3/KK
	INVOKE	TESTKANJ
	JZ	NOTKANJ6
	MOV	[DI],AL
	INC	DI				; fake STOSB into DS
	LODSB					; grab second byte
	MOV	[DI],AL 			; fake stosb into DS
	INC	DI
	INC	CX
	INC	CX
	JMP	PRESCANLP

NOTKANJ6:
;;;;	ENDIF			3/3/KK

	CMP	AL,'"'                          ; " character
	JNZ	TRYGREATER
	DEC	DL
	JZ	TRYGREATER

QLOOP:
	MOV	[DI],AL
	INC	DI
	INC	CX
	LODSB
	CMP	AL,'"'                          ; " character
	JNZ	QLOOP
	DEC	DL

TRYGREATER:
	CMP	AL,rabracket
	JNZ	NOOUT
;
; We have found a ">" char.  We need to see if there is another ">"
; following it.
;
	CMP	BYTE PTR [SI],al
	JNZ	NOAPPND
	LODSB
	INC	[RE_OUT_APP]			; Flag >>

NOAPPND:
;
; Now we attempt to find the file name.  First, scan off all whitespace
;
	INVOKE	SCANOFF
	CMP	AL,labracket			;AN040; was there no filename?
	JZ	REOUT_ERRSET			;AN040; yes - set up error
	CMP	AL,0DH
	JNZ	GOTREOFIL
;
; There was no file present.  Set us up at end-of-line.
;
REOUT_ERRSET:					;AN040; set up for an error
	mov	byte ptr [di], 0dh		; Clobber first ">"
	MOV	WORD PTR [RE_OUTSTR],09H	; Cause an error later
	JMP	PRESCANEND

GOTREOFIL:
	PUSH	DI
	MOV	DI,OFFSET RESGROUP:RE_OUTSTR
	MOV	BX,DI
	XOR	DL,DL				; Not in a quoted name
	PUSH	ES

SETREOUTSTR:					; Get the redirection name
	PUSH	CX
	MOV	CX,260				; Maximum pathname length

SETREOUTSTR_LOOP:
	LODSB
	CMP	AL,0DH
	JZ	GOTRESTR_J
	CMP	AL,'"'
	JNZ	SHORT RedirNotQuote
	XOR	DL,1				; Toggle quoted-name state
	JMP	SHORT SETREOUTSTR_LOOP
RedirNotQuote:
	OR	DL,DL
	JNZ	SHORT NO_ABRACKET
	INVOKE	DELIM
	JZ	GOTRESTR_J
	CMP	AL,[SWITCHAR]
	JZ	GOTRESTR_J
	CMP	AL,labracket
	JZ	ABRACKET_TERM
	CMP	AL,rabracket
	JNZ	NO_ABRACKET

ABRACKET_TERM:
	DEC	SI				; Leave the redirection character
	MOV	AL,BLANK
GOTRESTR_J:
	POP	CX
	JMP	SHORT GOTRESTR

NO_ABRACKET:
	STOSB
	LOOP	SETREOUTSTR_LOOP
	JMP	SHORT GOTRESTR_J

PIPEERRSYNJ5_J:
	POP	CX
	JMP	SHORT PIPEERRSYNJ5

NOOUT:
	CMP	AL,labracket
	JNZ	CHKPIPE
	mov	bx,si				; Save loc of "<"
	INVOKE	SCANOFF
	CMP	AL,rabracket			;AN040; was there no filename?
	JZ	REIN_ERRSET			;AN040; yes - set up error
	CMP	AL,0DH
	JNZ	GOTREIFIL

REIN_ERRSET:					;AN040; set up for error
	mov	byte ptr [di],0dh		; Clobber "<"
	MOV	WORD PTR [RE_INSTR],09H 	; Cause an error later
	JMP	SHORT PRESCANEND

GOTREIFIL:
	PUSH	DI
	MOV	DI,OFFSET TranGROUP:RE_INSTR
	MOV	BX,DI
	PUSH	ES
	PUSH	CS
	POP	ES				; store in TRANGROUP
	XOR	DL,DL				; Not in a quoted name
	JMP	SHORT SETREOUTSTR		; Get the input redirection name

CHKPIPE:
	MOV	AH,AL
	CMP	AH,vbar
	JNZ	CONTPRESCAN

IsPipe3:
;
; Only push the echo flag if we are entering the pipe for the first time.
;
	CMP	PipeFlag,0
	JNZ	NoEchoPush
	SHL	EchoFlag,1			; push echo state and turn it off
NoEchoPush:
	INC	[PIPEFLAG]
	INVOKE	SCANOFF
	CMP	AL,0DH
	JZ	PIPEERRSYNJ5
	CMP	AL,vbar 			; Double '|'?
	JNZ	CONTPRESCAN

PIPEERRSYNJ5:
	PUSH	ES
	POP	DS				; DS->RESGROUP
	JMP	PIPEERRSYN

;
; Trailing :s are allowed on devices.  Check to be sure that there is more
; than just a :  in the redir string.
;
GOTRESTR:
	XCHG	AH,AL
	mov	al,':'
	SUB	BX,DI				; compute negatinve of number of chars
	CMP	BX,-1				; is there just a :?
	JZ	NotTrailCol			; yep, don't change
	CMP	BYTE PTR ES:[DI-1],al		; Trailing ':' OK on devices
	JNZ	NOTTRAILCOL
	DEC	DI				; Back up over trailing ':'

NOTTRAILCOL:
	XOR	AL,AL
	STOSB					; NUL terminate the string
	POP	ES
	POP	DI				; Remember the start

CONTPRESCAN:
	MOV	[DI],AH 			; "delete" the redirection string
	INC	DI
	CMP	AH,0DH
	JZ	PRESCANEND
	INC	CX
	JMP	PRESCANLP

PRESCANEND:
	CMP	[PIPEFLAG],0
	JZ	ISNOPIPE
	MOV	AH,ALLOC
	MOV	BX,41h
	INT	21h
	JC	PipeNoMemory
	MOV	ES,AX
	XOR	DI,DI
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP,ES:NOTHING
	MOV	[PIPEPTR],DI
	MOV	WORD PTR [PIPEPTR+2],AX
	POP	DS
ASSUME	DS:TRANGROUP,ES:NOTHING
	MOV	SI,[ComBufPtr]
	INVOKE	SCANOFF

PIPESETLP:					; Transfer the pipe into the resident
	LODSB					; pipe buffer
	STOSB
	CMP	AL,0DH
	JNZ	PIPESETLP

ISNOPIPE:
	PUSH	SI
	MOV	SI,[ComBufPtr]
	MOV	[SI-2],CX
	POP	SI
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	CMP	[PIPEFLAG],0
	PUSH	CS
	POP	ES
	return

PipeNoMemory:
	MOV	DX,OFFSET TRANGROUP:PipeMemErr_Ptr
	JMP	CERROR

        PUBLIC  BuildExternalTail
BuildExternalTail proc near
        MOV     DI,81H
        MOV     SI,[ComBufPtr]
        MOV     AX,[SI-2]
        MOV     SI,OFFSET TRANGROUP:arg
        MOV     SI,[SI].arg_ocomptr
        ADD     AX,SI
        PUSH    AX
        INVOKE  Scanoff
        POP     AX
        CALL    CountCommandName
        ADD     SI,CX
        SUB     AX,SI
        MOV     CX,AX
        CALL    PrepareLongCommand
        CMP     CX,7FH
        JB      SHORT CopyTail
        MOV     CX,7EH
        REP     MOVSB
        MOV     AL,0DH
        STOSB
        INC     DI
        JMP     SHORT CopyDone
CopyTail:
        LODSB
        STOSB
        CMP     AL,0DH
        JZ      SHORT CopyDone
        JMP     SHORT CopyTail
CopyDone:
        MOV     CX,DI
        SUB     CX,82H
        MOV     ES:[80H],CL
        RET
BuildExternalTail endp

test_append	proc near

	mov	BX,ComBufPtr			; command buffer address
	mov	SI, offset TRANGROUP:IDLEN	; address command name, DS already set
	mov	DX,-1				; set install check function
	mov	AX,0AE00H
	int	2FH				; see if loaded
	cmp	AL,00H

	ret

test_append	endp

;*** CopyCanonicalPath -- Copy a pathname to resident storage.
;
;       ENTRY   DS:SI = source, ES:DI = destination
;               DS = TRANGROUP, PathFindMode selects pathname conversion
;       EXIT    SI and DI preserved; AX, CX and flags changed
;
        PUBLIC  CopyCanonicalPath
assume  ds:trangroup
CopyCanonicalPath PROC NEAR
        MOV     AL,PathFindMode
        OR      AL,AL
        JZ      SHORT CopyPathBuffer
        PUSH    SI
        PUSH    DI
        CALL    CanonicalizePath
        POP     DI
        POP     SI
        JNC     SHORT CopyCanonicalDone
CopyPathBuffer:
        MOV     CX,104H
        CLD
        PUSH    SI
        PUSH    DI
        REP     MOVSB
        POP     DI
        POP     SI
CopyCanonicalDone:
        RET
CopyCanonicalPath ENDP

; Count the command name, allowing delimiters inside quotation marks.
        PUBLIC  CountCommandName
CountCommandName PROC NEAR
        PUSH    AX
        PUSH    SI
        XOR     CX,CX
        XOR     BX,BX
CountNameChar:
        LODSB
        CALL    QuoteDelim
        JZ      SHORT CountNameDone
        CMP     AL,0DH
        JZ      SHORT CountNameDone
        TEST    BH,20H
        JNZ     SHORT CountNameNext
        CMP     AL,[SWITCHAR]
        JZ      SHORT CountNameDone
CountNameNext:
        INC     CX
        CMP     AL,'"'
        JNZ     SHORT CountNameChar
        XOR     BH,20H
        JMP     SHORT CountNameChar
CountNameDone:
        POP     SI
        POP     AX
        RET
CountCommandName ENDP




TRANCODE    ENDS
	    END

