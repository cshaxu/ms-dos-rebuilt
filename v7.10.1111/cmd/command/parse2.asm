	page ,132
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */
;	SCCSID = @(#)parse.asm	1.1 85/05/14
;	SCCSID = @(#)parse.asm	1.1 85/05/14
.sall
.xlist
.xcref
    INCLUDE DOSSYM.INC
    INCLUDE DEVSYM.INC
    include comsw.asm
    include comseg.asm
    include comequ.asm
    include intnat.inc
.list
.cref


break <Parse.Asm>
;----------------------------------------------------------------------------
;    PARSE.ASM contains the routines to perform command line parsing.
;    Parse and Path share a buffer and argv[] definitions.
;   Invoking <Parseline> maps the unparsed command line in COMBUF into an
;   array of pointers to the parsed tokens.  The resulting array, argv[],
;   also contains extra information provided by cparse about each token
;   <Parseline> should be executed prior to <Path_Search>
;
; Alan L, OS/MSDOS				    August 15, 1983
;
;
; ENTRY:
;   <Parseline>:	    command line in COMTAB.
; EXIT:
;   <Parseline>:	    success flag, argcnt (number of args), argv[].
; NOTE(S):
;   *	<Argv_calc> handily turns an array index into an absolute pointer.
;	The computation depends on the size of an argv[] element (arg_ele).
;   *	<Parseline> calls <cparse> for chunks of the command line.  <Cparse>
;	does not function as specified; see <Parseline> for more details.
;   *	<Parseline> now knows about the flags the internals of COMMAND.COM
;	need to know about.  This extra information is stored in a switch_flag
;	word with each command-line argument; the switches themselves will not
;	appear in the resulting arg structure.
;   *	With the exception of CARRY, flags are generally preserved across calls.
;---------------
; CONSTANTS:
;---------------
    DEBUGx	equ	    FALSE	; prints out debug info
;---------------
; DATA:
;---------------

DATARES 	SEGMENT PUBLIC BYTE
	EXTRN	FORFLAG:BYTE
DATARES     ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	combuf:byte
	EXTRN	cpyflag:byte
	EXTRN	expand_star:byte
	EXTRN	RESSEG:word
	EXTRN	INTERNATVARS:BYTE
	EXTRN	DATE_YEAR:WORD,DATE_MONTH:BYTE,DATE_DAY:BYTE
	EXTRN	ParseDateParts:WORD
	EXTRN	STARTEL:word
	EXTRN	ParseArgIndex:WORD,ParseResultType:BYTE,ParseResultValue:DWORD
TRANSPACE   ENDS

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	DirSetupParamError:NEAR
	PUBLIC	argv_calc		; convert array index into address
	PUBLIC	parseline


assume cs:trangroup, ds:trangroup, es:trangroup, ss:nothing


break <Parseline:  Munch on the command line>
;----------------------------------------------------------------------------
;    PARSELINE takes an MSDOS command line and maps it into a UNIX-style
; argv[argvcnt] array.	The most important difference between this array and
; the tradition UNIX format is the extra cparse information included with
; each argument element.
;---------------
; ENTRY:
;	(BL	     special delimiter for cparse -- not implemented)
;---------------
; EXIT:
;	CF	    set if error
;	AL	    error code (carry set).  Note AH clobbered in any event.
;	argv[]	    array of cparse flags and pointers to arguments
;	argvcnt     argument count
;---------------
; NOTE(S):
;	*   BL (special delimiter) is ignored, for now (set to space).
;	*   Parseflags record contains cparse flags, as follows:
;		sw_flag 	--	was this arg a switch?
;		wildcard	--	whether or not it contained a * or ?
;		path_sep	--	maybe it was a pathname
;		unused		--	for future expansion
;		special_delim	--	was there an initial special delimiter?
;	*   argv[] and argvcnt are undefined if CF/AL indicates an error.
;	*   Relationship between input, cparse output, and comtail can be
;	    found in the following chart.  Despite the claim of the cparse
;	    documentation that, "Token buffer always starts d:  for non switch
;	    tokens", such is not the case (see column two, row two).
;	    Similarly, [STARTEL] is not null when the command line is one of
;	    the forms, "d:", "d:\", or "d:/".  In fact, *STARTEL (i.e., what
;	    STARTEL addresses) will be null.  This is clearly just a
;	    documentation error.
;	*   cparse also returns a switch code in BP for each switch it
;	    recognizes on the command line.
;	*   arglen for each token does NOT include the terminating null.
;	*   Finally, note that interesting constructions like 'foodir/*.exe'
;	    parse as three separate tokens, and the asterisk is NOT a wildcard.
;	    For example, 'for %i in (foodir/*.exe) do echo %i' will first
;	    echo 'foodir', then '*', then '.exe'.  Using cparse for command-
;	    line parsing may result in slightly different behavior than
;	    previously observed with the old COMMAND.COM command-line parser.
;
;	    Input		    Cparse		Command Line (80H)
;	\alan\foo.bat		c:\alan\foo.bat 	\alan\foo.bat
;	alan\foo.bat		alan\foo.bat		alan\foo.bat
;	foo.bat 		foo.bat 		foo.bat
;	c:\alan\foo.bat 	c:\alan\foo.bat 	c:\alan\foo.bat
;	c:alan\foo.bat		c:alan\foo.bat		c:alan\foo.bat
;	c:foo.bat		c:foo.bat		c:foo.bat
;---------------
; CONSTANTS:
;---------------
;---------------
; DATA:
;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte
	EXTRN	PathPos:word
	EXTRN	ComBufPtr:WORD,CmdBufferLength:WORD,ArgBufferEnd:WORD
	EXTRN	ParseSwitchFlag:BYTE,TranSpaceEnd:BYTE
	EXTRN	argbufptr:word
	EXTRN	comptr:word
	EXTRN	last_arg:word
TRANSPACE	ENDS

;---------------
parseline:
        PUSH    AX
        PUSH    BX
        MOV     AX,ComBufPtr
        MOV     BX,0
        CALL    ParseCommandLine
        POP     BX
        POP     AX
        RET

; Reparse the remainder when a command name shares its first argument.
        PUBLIC  cmd_copy
cmd_copy PROC NEAR
        PUSH    AX
        PUSH    BX
        PUSH    SI
        MOV     BX,PathPos
        CMP     BX,arg.argv[0].arglen
        JE      SHORT CmdCopyDone
        MOV     SI,ComBufPtr
        INVOKE  SCANOFF
        ADD     SI,BX
        MOV     arg.argv[0].arglen,BX
        XOR     AX,AX
        MOV     arg.argv[0].argsw_word,AX
        MOV     arg.argv[0].argstartel,AX
        MOV     arg.argv[0].argflags,AL
        PUSH    SI
        MOV     SI,ComBufPtr
        MOV     arg.argv[0].arg_ocomptr,SI
        MOV     SI,arg.argv[0].argpointer
        ADD     SI,BX
        MOV     BYTE PTR [SI],0
        INC     SI
        MOV     argbufptr,SI
        MOV     arg.argvcnt,1
        POP     SI
        MOV     AX,SI
        CALL    ParseCommandLine
CmdCopyDone:
        POP     SI
        POP     BX
        POP     AX
        RET
cmd_copy ENDP

; Parse a complete command, or continue after its first argument.
; AX is the command pointer; BX is zero for a complete command.
        PUBLIC  ParseCommandLine,newarg,Arg_Switch
ParseCommandLine PROC NEAR
        PUSH    CX
        PUSH    DX
        PUSH    DI
        PUSH    SI
        PUSHF
        OR      BX,BX
        JZ      SHORT ParseWholeLine
        MOV     LAST_ARG,0
        MOV     cpyflag,2
        MOV     SI,AX
        XOR     AX,AX
        MOV     BX,SIZE argv_ele
        JMP     SHORT ParseClearArgs
ParseWholeLine:
        MOV     LAST_ARG,-1
        XOR     AX,AX
        MOV     cpyflag,AL
        MOV     SI,ComBufPtr
ParseClearArgs:
        MOV     CX,ARGMAX * SIZE argv_ele
        SUB     CX,BX
        MOV     DI,OFFSET TRANGROUP:arg.argv
        ADD     DI,BX
        REP     STOSB
        MOV     arg.argswinfo,AX
        OR      BX,BX
        JNZ     SHORT ParseCopyLine
        MOV     arg.argvcnt,AX
        MOV     CX,CmdBufferLength
        ADD     CX,ComBufPtr
        INC     CX
        MOV     argbufptr,CX
        ADD     CX,CmdBufferLength
        ADD     CX,CmdBufferLength
        DEC     CX
        MOV     ArgBufferEnd,CX
ParseCopyLine:
        MOV     ParseSwitchFlag,AL
        PUSH    DS
        MOV     DS,RESSEG
        ASSUME  DS:RESGROUP
        CMP     FORFLAG,0
        POP     DS
        ASSUME  DS:TRANGROUP
        JNZ     SHORT pcont
        MOV     DI,ComBufPtr
        MOV     CX,CmdBufferLength
        ADD     CX,CX
        ADD     CX,CmdBufferLength
        INC     CX
        ADD     DI,CX
        PUSH    DI
        XOR     CH,CH
        PUSH    DI
        MOV     DI,ComBufPtr
        MOV     CX,[DI-2]
        POP     DI
        INC     CX
        REP     MOVSB
        POP     SI
pcont:
        MOV     DI,OFFSET TRANGROUP:TranSpaceEnd+2
        MOV     BL,' '
parseloop:
        MOV     comptr,SI
        XOR     BP,BP
        MOV     expand_star,0
        invoke  SCANOFF
        invoke  CPARSE
        JNC     SHORT More_prse
        OR      BP,BP
        JZ      SHORT parsedone
        CALL    newarg
        JMP     SHORT parsedone
More_prse:
        MOV     cpyflag,2
        CALL    newarg
        JNC     parseloop
        JMP     SHORT parse_error
parsedone:
        POPF
        CLC
        JMP     SHORT parse_exit
parse_error:
        POPF
        STC
parse_exit:
        MOV     comptr,SI
        POP     SI
        POP     DI
        POP     DX
        POP     CX
        RET
ParseCommandLine ENDP

break <NewArg>
;----------------------------------------------------------------------------
;   NEWARG adds the supplied argstring and cparse data to arg.argv[].
; ENTRY:
;   BH			argflags
;   CX			character count in argstring
;   DI			pointer to argstring
;   comptr		ptr to starting loc of current token in original command
;   [STARTEL]		cparse's answer to where the last element starts
; EXIT:
;   argbufptr		points to next free section of argbuffer
;   arg.argbuf		contains null-terminated argument strings
;   arg.argvcnt 	argument count
;   arg.argv[]		array of flags and pointers
;   arg.arg_ocomptr	ptr to starting loc of current token in original command
;   CF			set if error
;   AL			carry set:  error code; otherwise, zero
;---------------
newarg:
;---------------

	push	BX
	push	CX
	push	DX				; one never knows, do one?
	push	DI
	push	SI
	pushf
	call	arg_switch			; if it's a switch, record switch info
						; LEAVE SWITCH ON COMMAND LINE!!
;;;	jc	newarg_done			; previous arg's switches -- and leave

	cmp	arg.argvcnt, ARGMAX		; check to ensure we've not
	jge	too_many_args			; exceeded array limits
	mov	DH, BH				; save argflags
	mov	BX, arg.argvcnt 		; argv[argvcnt++] = arg data
	inc	arg.argvcnt
	mov	AX, OFFSET TRANGROUP:arg.argv
	call	argv_calc			; convert offset to pointer
	mov	[BX].argsw_word, 0		; no switch information, yet...
	TEST	DH,MASK sw_flag
	JZ	SHORT NewArgLength
	MOV	[BX].argsw_word,BP
NewArgLength:
	mov	[BX].arglen, CX 		; argv[argvcnt].arglen = arg length
	mov	[BX].argflags, DH		; argv[argvcnt].argflags = cparse flags
	mov	SI, argbufptr
	mov	[BX].argpointer, SI		; argv[argvcnt].argpointer = [argbufptr]
	add	SI, [STARTEL]			; save startel from new location
	sub	SI, DI				; form pointer into argbuf
	mov	[BX].argstartel, SI		; argv[argvcnt].argstartel = new [STARTEL]
	mov	si,[comptr]
	mov	[BX].arg_ocomptr,si		; arg_ocomptr=ptr into original com line

	mov	SI, DI				; now save argstring in argbuffer
	mov	DI, argbufptr			; load the argbuf pointer and make
	add	DI, CX				; sure we're not about to run off
	CMP	DI,ArgBufferEnd
	jge	buf_ovflow			; the end of the buffer (plus null byte)
	sub	DI, CX				; adjust the pointer
	cld
	rep	movsb				; and save the string in argbuffer
	mov	AL, ANULL			; tack a null byte on the end
	stosb
	mov	argbufptr, DI			; update argbufptr after copy

newarg_done:
	popf
	clc
	jmp	short newarg_exit

too_many_args:
	mov	AX, arg_cnt_error
	jmp	short newarg_error

buf_ovflow:
	mov	AX, arg_buf_ovflow

newarg_error:
	popf
	stc

newarg_exit:
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	ret

;---------------
; NewArg ends
;----------------------------------------------------------------------------


break <Arg_Switch>
;----------------------------------------------------------------------------
;   ARG_SWITCH decides if an argument might really be a switch.  In the
; event that it is, and we can recognize
; ENTRY:
;   As in <newarg>.
; EXIT:
;   CF	    --	    clear (wasn't a switch); set (was a switch)
; NOTE(S):
;   *	The mechanism mapping a switch into a bit-value depends entirely
;	on the order of definition in the <switch_list> variable and the
;	values chosen to define the bits in CMDT:COMEQU.ASM.  Change either
;	<switch_list> or the definitions in CMDT:COMEQU.ASM -- and rewrite
;	this mechanism.  This code taken from CMDT:TCODE.ASM.
;   *	The <switch_list> declared below is redundant to one declared in
;	TDATA.ASM, and used in TCODE.ASM.
;   *	An ugly routine.
;---------------
; CONSTANTS:
;---------------
;   Constants come from the definitions in CMDT:COMEQU.ASM.
;---------------
; DATA:
;---------------

TRANSPACE	SEGMENT PUBLIC BYTE		;AC000;
    extrn   switch_list:byte
    switch_count    EQU     $-switch_list
transpace   ends

;---------------
Arg_Switch:
;---------------

	push	AX
	push	BX
	push	CX
	push	DI
	pushf
	test	BH, MASK sw_flag		; is it a switch? (preserve flag word)
	jz	arg_no_switch0
	cmp	[LAST_ARG], -1			; have we encountered any REAL args yet?
	je	arg_no_switch1			; no, so leading switches don't matter
	mov	BX, [LAST_ARG]			; yes, add switch info to last REAL arg
	mov	AX, OFFSET TRANGROUP:arg.argv
	call	argv_calc
	or	[BX].argsw_word, BP
	or	arg.argswinfo, BP
	TEST	BP,8
	JZ	SHORT arg_yes_switch
	MOV	ParseSwitchFlag,1

arg_yes_switch: 				; ah, sweet success...
	popf
	stc
	jmp	short arg_switch_exit

arg_no_switch0:
	mov	AX, arg.argvcnt 		; future switches should then affect
	mov	[LAST_ARG], AX			; this argument

arg_no_switch1: 				; wasn't a switch, or we're pretending
	popf
	clc

arg_switch_exit:
	pop	DI
	pop	CX
	pop	BX
	pop	AX
	ret

;---------------
; Arg_Switch ends
;----------------------------------------------------------------------------


break <Argv_calc>
;----------------------------------------------------------------------------
;   ARGV_CALC maps an array index into a byte-offset from the base of
; the supplied array.  Method used for computing the address is:
;	Array Index * Array Elt Size + Base Addr = Elt Addr
; ENTRY:
;   AX	    --	    base of array
;   BX	    --	    array index
; EXIT:
;   BX	    --	    byte offset
;---------------

argv_calc:
	push	ax				; Save base
	mov	al,bl				; al = array index
	mov	bl,SIZE argv_ele		; bl = size of an argv element
	mul	bl				; ax = base offset
	pop	bx				; Get base
	add	ax,bx				; Add in base offset
	xchg	ax,bx				; Restore ax and put byte offset in bx
	ret

;---------------
; argv_calc ends
;----------------------------------------------------------------------------




; Parsed argument access used by command-specific parsers.
; DS = TRANGROUP.  ParseArgIndex identifies the next argv entry.

        PUBLIC  CheckParsedArgs,GetParsedArg,ReadDecimal
        PUBLIC  AdvanceParsedArgs,ParseNumberArg,UppercaseParsedArg

; Dispatch one argv entry according to the command parse control block.
        PUBLIC  ParseArgument
ParseArgument:
        MOV     BX,ParseArgIndex
        CMP     BX,arg.argvcnt
        JAE     ParseArgumentEnd
        MOV     AX,OFFSET TRANGROUP:arg
        CALL    argv_calc
        MOV     CL,[BX].argflags
        MOV     DX,[BX].argsw_word
        MOV     SI,[BX].argpointer
        TEST    CX,1
        JNZ     ParseArgumentSwitch
        TEST    BYTE PTR [DI],20H
        JZ      ParseArgumentDrive
        TEST    BYTE PTR [DI+1],1
        JZ      SHORT ParseArgumentString
        CALL    UppercaseParsedArg
ParseArgumentString:
        MOV     AL,2
        MOV     WORD PTR ParseResultValue,SI
        MOV     WORD PTR ParseResultValue+2,DS
ParseArgumentStore:
        MOV     ParseResultType,AL
        XOR     AX,AX
ParseArgumentReturn:
        INC     ParseArgIndex
        RET
ParseArgumentEnd:
        MOV     AX,0
        STC
        JMP     SHORT ParseArgumentReturn
ParseArgumentCarry:
        STC
        JMP     SHORT ParseArgumentReturn
ParseArgumentDrive:
        TEST    BYTE PTR [DI],10H
        JZ      SHORT ParseArgumentDate
        CMP     [BX].arglen,2
        JNZ     SHORT ParseArgumentBadDrive
        CMP     BYTE PTR [SI+1],':'
        JNZ     SHORT ParseArgumentBadDrive
        MOV     AL,[SI]
        invoke  UPCONV
        SUB     AL,'A'
        INC     AL
        CMP     AL,26
        JA      SHORT ParseArgumentBadDrive
        MOV     BYTE PTR ParseResultValue,AL
        MOV     AL,4
        JMP     SHORT ParseArgumentStore
ParseArgumentDate:
        TEST    BYTE PTR [DI],40H
        JZ      SHORT ParseArgumentNumber
        CALL    ParseDateArg
        JC      ParseArgumentCarry
ParseArgumentCheck:
        JC      SHORT ParseArgumentError
        JMP     SHORT ParseArgumentStore
ParseArgumentNumber:
        TEST    BYTE PTR [DI],80H
        JZ      SHORT ParseArgumentBadType
        CALL    ParseNumberArg
        JMP     SHORT ParseArgumentCheck
ParseArgumentSwitch:
        CMP     WORD PTR [DI+2],-1
        JE      SHORT ParseArgumentSwitchValid
        TEST    WORD PTR [DI+2],3FFFH
        JZ      SHORT ParseArgumentBadSwitch
        TEST    [DI+2],DX
        JZ      SHORT ParseArgumentBadSwitch
ParseArgumentSwitchValid:
        MOV     AL,1
        MOV     WORD PTR ParseResultValue,DX
        JMP     SHORT ParseArgumentStore
ParseArgumentBadType:
        MOV     AX,1
        JMP     SHORT ParseArgumentError
ParseArgumentBadSwitch:
        MOV     AX,3
ParseArgumentError:
        invoke  DirSetupParamError
        JMP     SHORT ParseArgumentCarry
ParseArgumentBadDrive:
        MOV     AX,10
        JMP     SHORT ParseArgumentError
CheckParsedArgs:
        MOV     AX,ParseArgIndex
        CMP     AX,arg.argvcnt
        JAE     ParsedArgsEnd
        CLC
ParsedArgsReturn:
        RET
ParsedArgsEnd:
        STC
        JMP     SHORT ParsedArgsReturn

GetParsedArg:
        PUSH    AX
        PUSH    BX
        MOV     BX,ParseArgIndex
        MOV     AX,OFFSET TRANGROUP:arg
        CALL    argv_calc
        MOV     SI,[BX].argpointer
        POP     BX
        POP     AX
        RET

; Parse a date argument using the current country date order.
; DS:BX addresses its argv entry; DI addresses the parse control block.
        PUBLIC  ParseDateArg
ParseDateArg:
        PUSH    DI
        MOV     SI,[BX].arg_ocomptr
        invoke  SCANOFF
        XOR     AX,AX
        MOV     ParseDateParts,AX
        MOV     ParseDateParts+2,AX
        MOV     ParseDateParts+4,AX
        MOV     ParseDateParts+6,AX
        TEST    BYTE PTR [DI],8
        JNZ     SHORT ParseDateSuccess
        CALL    ReadDecimal
        MOV     ParseDateParts,AX
        CALL    CheckDateSeparator
        JC      SHORT ParseDateError
        CALL    ReadDecimal
        MOV     ParseDateParts+2,AX
        CALL    CheckDateSeparator
        JC      SHORT ParseDateError
        CALL    ReadDecimal
        MOV     ParseDateParts+4,AX
        MOV     AL,[SI]
        CMP     AL,' '
        JE      SHORT ParseDateEndCheck
        CMP     AL,9
        JE      SHORT ParseDateEndCheck
        CMP     AL,0DH
        JE      SHORT ParseDateEndCheck
        CMP     AL,0AH
        JNE     SHORT ParseDateError
ParseDateEndCheck:
        MOV     AX,ParseDateParts
        CMP     WORD PTR INTERNATVARS.Date_tim_format,0
        JE      SHORT ParseDateMonth
        MOV     AX,ParseDateParts+2
ParseDateMonth:
        OR      AX,AX
        JZ      SHORT ParseDateError
        MOV     DATE_MONTH,AL
        MOV     AX,ParseDateParts+2
        CMP     WORD PTR INTERNATVARS.Date_tim_format,1
        JB      SHORT ParseDateDay
        MOV     AX,ParseDateParts
        JE      SHORT ParseDateDay
        MOV     AX,ParseDateParts+4
ParseDateDay:
        OR      AX,AX
        JZ      SHORT ParseDateError
        MOV     DATE_DAY,AL
        MOV     AX,ParseDateParts+4
        CMP     WORD PTR INTERNATVARS.Date_tim_format,2
        JB      SHORT ParseDateYear
        MOV     AX,ParseDateParts
ParseDateYear:
        OR      AX,AX
        JZ      SHORT ParseDateError
        CMP     AX,100
        JA      SHORT ParseDateStoreYear
        ADD     AX,1900
ParseDateStoreYear:
        MOV     DATE_YEAR,AX
        CALL    AdvanceParsedArgs
        MOV     AL,8
ParseDateSuccess:
        CLC
ParseDateReturn:
        POP     DI
        RET
ParseDateError:
        STC
        MOV     AX,-1
        JMP     SHORT ParseDateReturn

; Read decimal digits at DS:SI.  AX is the value, SI the first non-digit.
ReadDecimal:
        XOR     AX,AX
        PUSH    CX
        MOV     CX,10
ReadDecimalLoop:
        CMP     BYTE PTR [SI],'0'
        JB      ReadDecimalDone
        CMP     BYTE PTR [SI],'9'
        JA      ReadDecimalDone
        MUL     CL
        ADD     AL,[SI]
        ADC     AH,0
        SUB     AX,'0'
        INC     SI
        JMP     SHORT ReadDecimalLoop
ReadDecimalDone:
        POP     CX
        RET

; Check a date separator followed by a decimal digit.
        PUBLIC  CheckDateSeparator
CheckDateSeparator:
        LODSB
        CMP     AL,INTERNATVARS.Date_sep
        JE      SHORT DateSeparatorFound
        CMP     AL,'/'
        JE      SHORT DateSeparatorFound
        CMP     AL,'-'
        JE      SHORT DateSeparatorFound
        CMP     AL,'.'
        JE      SHORT DateSeparatorFound
DateSeparatorError:
        STC
DateSeparatorReturn:
        RET
DateSeparatorFound:
        CMP     BYTE PTR [SI],'0'
        JB      DateSeparatorError
        CMP     BYTE PTR [SI],'9'
        JA      DateSeparatorError
        CLC
        JMP     SHORT DateSeparatorReturn

; Advance the argument index to the original command position in SI.
AdvanceParsedArgs:
        PUSH    AX
        PUSH    BX
        MOV     BX,ParseArgIndex
        MOV     AX,OFFSET TRANGROUP:arg
AdvanceParsedLoop:
        CALL    argv_calc
        CMP     SI,[BX].arg_ocomptr
        JA      AdvanceParsedNext
AdvanceParsedDone:
        POP     BX
        POP     AX
        RET
AdvanceParsedNext:
        INC     ParseArgIndex
        MOV     BX,ParseArgIndex
        CMP     BX,arg.argvcnt
        JAE     AdvanceParsedDone
        JMP     SHORT AdvanceParsedLoop

; Convert the null-terminated decimal argument at DS:SI.
; Carry is set and AX = 9 for a non-digit; otherwise save the result.
ParseNumberArg:
        PUSH    SI
        PUSH    CX
        PUSH    DX
        XOR     DX,DX
        MOV     CX,10
ParseNumberLoop:
        LODSB
        OR      AL,AL
        JZ      ParseNumberDone
        SUB     AL,'0'
        CMP     AL,9
        JA      ParseNumberError
        CBW
        XCHG    AX,DX
        MUL     CL
        ADD     AX,DX
        MOV     DX,AX
        JMP     SHORT ParseNumberLoop
ParseNumberDone:
        MOV     WORD PTR ParseResultValue,DX
        MOV     ParseResultType,14H
        CLC
ParseNumberReturn:
        POP     DX
        POP     CX
        POP     SI
        RET
ParseNumberError:
        MOV     AX,9
        STC
        JMP     SHORT ParseNumberReturn

; Uppercase an argument in place, preserving double-byte characters.
UppercaseParsedArg:
        PUSH    SI
UppercaseArgLoop:
        MOV     AL,[SI]
        OR      AL,AL
        JZ      UppercaseArgDone
        invoke  TESTKANJ
        JZ      UppercaseArgSingle
        INC     SI
        INC     SI
        JMP     SHORT UppercaseArgLoop
UppercaseArgSingle:
        invoke  UPCONV
        MOV     [SI],AL
        INC     SI
        JMP     SHORT UppercaseArgLoop
UppercaseArgDone:
        POP     SI
        RET

trancode    ends
	    end
