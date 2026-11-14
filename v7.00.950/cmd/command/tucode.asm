	page ,132
;	SCCSID = @(#)tucode.asm 4.2 85/05/31
;	SCCSID = @(#)tucode.asm 4.2 85/05/31
Title	COMMAND Language midifiable Code Transient
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */


.xlist
.xcref
	include dossym.inc
	include syscall.inc
	include comsw.asm
	include comseg.asm
	include comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ECHOFLAG:BYTE,LFNForFlag:BYTE
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	OnOffControl:BYTE,OnOffWords:BYTE
	EXTRN	EchoOnOffControl:BYTE
	EXTRN	BAD_ON_OFF_ptr:word
	EXTRN	ctrlcmes_ptr:word
	EXTRN	DEL_Y_N_PTR:WORD
	EXTRN	ECHOMES_ptr:word
	EXTRN	extend_buf_ptr:word	;AC000;
	EXTRN	offmes_ptr:word
	EXTRN	onmes_ptr:word
	EXTRN	promptdat_moday:word	;AC000;
	EXTRN	promptdat_ptr:word	;AC000;
	EXTRN	promptdat_yr:word	;AC000;
	EXTRN	string_buf_ptr:word
	EXTRN	SUREMES_ptr:word
	EXTRN	LFNForMes_ptr:WORD
	EXTRN	VERIMES_ptr:BYTE
	EXTRN	WeekTab:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg_buf:byte
	EXTRN	COMSW:WORD,PathFindMode:BYTE
	EXTRN	DirSearchPos:WORD,DirSearchPath:BYTE,DirEntryPath:BYTE
	EXTRN	DirBuf:BYTE,DeleteCount:WORD,DeleteError:WORD
	EXTRN	BWDBUF:BYTE
	EXTRN	DEST:BYTE
	EXTRN	destdir:byte
	EXTRN	dirchar:byte
	EXTRN	PARSE1_CODE:BYTE	;AN000;
	EXTRN	RESSEG:WORD
	EXTRN	arg:BYTE,ParseArgIndex:WORD
	EXTRN	msg_disp_class:BYTE
	EXTRN	string_ptr_2:word

TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

	EXTRN	ParseArgument:NEAR,CheckParsedArgs:NEAR
	EXTRN	CERROR:NEAR
	EXTRN	PathFindFirst:NEAR,PathFindNext:NEAR
	EXTRN	DirAppendEntryName:NEAR
	EXTRN	Set_ext_error_from_ax:NEAR
	EXTRN	CRLF2:NEAR
	EXTRN	extend_setup:near	;AN022;

	PUBLIC	CNTRLC
	PUBLIC	ECHO
	PUBLIC	GetDate
	PUBLIC	NOTEST2
	PUBLIC	PRINT_DATE
	PUBLIC	VERIFY

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

; ****************************************************************
; *
; * ROUTINE:	 NOTEST2 - execution of DEL/ERASE command
; *
; * FUNCTION:	 Delete files based on user parsed input.  Prompt
; *		 user for Y/N if necessary.  If an error occurs,
; *		 set up an error message and go to CERROR.
; *
; * INPUT:	 FCB at 5ch set up with filename(s) entered
; *		 Current directory set to entered directory
; *
; * OUTPUT:	 none
; *
; ****************************************************************
;
; ARE YOU SURE prompt when deleting *.*

NOTEST2:
        CALL    EraseConfirmAll
        JNC     SHORT EraseStart
        RET
EraseStart:
        CMP     BYTE PTR [COMSW],0
        JNZ     SHORT EraseFind
        CMP     PathFindMode,0
        JZ      SHORT EraseFind
        MOV     DX,OFFSET TRANGROUP:DirSearchPath
        MOV     AX,7141H
        XOR     CX,CX
        MOV     SI,1
        INT     21H
        JC      SHORT EraseError
        JMP     SHORT EraseDone
EraseFind:
        MOV     DeleteCount,0
        MOV     DX,OFFSET TRANGROUP:DirSearchPath
        MOV     CX,21H
        MOV     DI,OFFSET TRANGROUP:DirBuf
        CALL    PathFindFirst
        JNC     SHORT EraseNextFile
        JMP     SHORT EraseError
EraseNextFile:
        PUSH    DS
        PUSH    DX
        PUSH    ES
        POP     DS
        CALL    DirAppendEntryName
        CALL    EraseConfirmFile
        JC      SHORT EraseSkipped
        MOV     DX,OFFSET TRANGROUP:DirEntryPath
        MOV     AH,41H
        CMP     PathFindMode,0
        JZ      SHORT EraseDoDelete
        MOV     AX,7141H
EraseDoDelete:
        XOR     SI,SI
        INT     21H
EraseSkipped:
        POP     DX
        POP     DS
        JNC     SHORT EraseCount
        INVOKE  Get_ext_error_number
        MOV     DeleteError,AX
        JMP     SHORT EraseContinue
EraseCount:
        INC     DeleteCount
EraseContinue:
        MOV     DI,OFFSET TRANGROUP:DirBuf
        CALL    PathFindNext
        JNC     EraseNextFile
        CMP     DeleteCount,0
        JNZ     SHORT EraseAny
        MOV     AX,DeleteError
        JMP     SHORT EraseErrorNumber
EraseAny:
        CMP     BYTE PTR [COMSW],0
        JZ      SHORT EraseDone
        INVOKE  CRLF2
EraseDone:
        INVOKE  RESTUDIR
        RET
EraseError:
        INVOKE  Get_ext_error_number
EraseErrorNumber:
        CALL    Set_ext_error_from_ax
        PUSH    DX
        INVOKE  RESTUDIR
        POP     DX
        CMP     Extend_Buf_Ptr,error_no_more_files
        JNZ     SHORT EraseReport
        MOV     Extend_Buf_Ptr,error_file_not_found
EraseReport:
        JMP     CERROR


;************************************************
; ECHO, BREAK, and VERIFY commands. Check for "ON" and "OFF"

	break	Echo

assume	ds:trangroup,es:trangroup

ECHO:
	MOV	DI,OFFSET TRANGROUP:EchoOnOffControl
	CALL	OnOffParse
	JC	DOEMES
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	JNZ	ECH_OFF
	OR	[ECHOFLAG],1
	RET
ECH_OFF:
	AND	[ECHOFLAG],NOT 1
	RET


CERRORJ:
	JMP	CERROR

;
; There was no discrenable ON or OFF after the ECHO.  If there is nothing but
; delimiters on the command line, we issue the ECHO is ON/OFF message.
;

ASSUME	DS:TRANGROUP

DOEMES:
	cmp	cl,0				;AC000; was anything on the line?
	jz	PEcho				; just display current state.
	MOV	DX,SI				; Point to the command text
	invoke	CRPRINT
	JMP	CRLF2

PECHO:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	BL,[ECHOFLAG]
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	AND	BL,1
	MOV	DX,OFFSET TRANGROUP:ECHOMES_ptr
	JMP	SHORT PYN

	break	Break
assume	ds:trangroup,es:trangroup

CNTRLC:
	CALL	ON_OFF
	MOV	AX,(SET_CTRL_C_TRAPPING SHL 8) OR 1
	JC	PCNTRLC
	JNZ	CNTRLC_OFF
	MOV	DL,1
	INT	21H				; Set ^C
	RET

CNTRLC_OFF:
	XOR	DL,DL
	INT	21H				; Turn off ^C check
	RET

PCNTRLC:
	CMP	CL,0				;AC000; rest of line blank?
	JNZ	CERRORJ 			; no, oops!

pccont:
	XOR	AL,AL
	INT	21H
	MOV	BL,DL
	MOV	DX,OFFSET TRANGROUP:CTRLCMES_ptr

        PUBLIC  PYN
PYN:
	mov	si,offset trangroup:onmes_ptr	;AC000; get ON pointer
	OR	BL,BL
	JNZ	PRINTVAL
	mov	si,offset trangroup:offmes_ptr	;AC000; get OFF pointer

PRINTVAL:
	push	dx				;AN000; save offset of message block
	mov	bx,dx				;AN000; save offset value
	lodsw					;AN000; get message number of on or off
	mov	dh,util_msg_class		;AN000; this is a utility message
	invoke	Tsysgetmsg			;AN000; get the address of the message
	add	bx,ptr_off_pos			;AN000; point to offset of ON/OFF
	mov	word ptr [bx],si		;AN000; put the offset in the message block
	pop	dx				;AN000; get message back
	invoke	std_printf			;AC000; go print message
	mov	word ptr [bx],0 		;AN000; zero out message pointer

	ret					;AN000; exit

	break	Verify
assume	ds:trangroup,es:trangroup

VERIFY:
	CALL	ON_OFF
	MOV	AX,(SET_VERIFY_ON_WRITE SHL 8) OR 1
	JC	PVERIFY
	JNZ	VER_OFF
	INT	21H				; Set verify
	RET

VER_OFF:
	DEC	AL
	INT	21H				; Turn off verify after write
	RET

PVERIFY:
	CMP	CL,0				;AC000; is rest of line blank?
	JZ	SHORT VerifyStatus
	JMP	CERROR
VerifyStatus:
	MOV	AH,GET_VERIFY_ON_WRITE
	INT	21H
	MOV	BL,AL
	MOV	DX,OFFSET TRANGROUP:VERIMES_ptr
	JMP	PYN

; LFNFOR controls long filename expansion in FOR commands.
        PUBLIC  LFNFOR
LFNFOR:
        CALL    ON_OFF
        JC      SHORT LFNForQuery
        PUSH    DS
        MOV     DS,[RESSEG]
        ASSUME  DS:RESGROUP
        MOV     DL,0
        JNZ     SHORT LFNForSet
        MOV     DL,1
LFNForSet:
        MOV     LFNForFlag,DL
        POP     DS
        ASSUME  DS:TRANGROUP
        RET
LFNForQuery:
        CMP     CL,0
        JE      SHORT LFNForShow
        JMP     CERROR
LFNForShow:
        PUSH    DS
        MOV     DS,ES:[RESSEG]
        ASSUME  DS:RESGROUP
        MOV     BL,LFNForFlag
        POP     DS
        ASSUME  DS:TRANGROUP
        MOV     DX,OFFSET TRANGROUP:LFNForMes_ptr
        JMP     PYN

; ****************************************************************
; *
; * ROUTINE:	 ON_OFF
; *
; * FUNCTION:	 Parse the command line for an optional ON or
; *		 OFF string for the BREAK, VERIFY, and ECHO
; *		 routines.
; *
; * INPUT:	 command line at offset 81H
; *		 PARSE_BREAK control block
; *
; * OUTPUT:	 If carry is clear
; *		    If ON is found
; *		       Zero flag set
; *		    If OFF is found
; *		       Zero flag clear
; *		 If carry set
; *		    If nothing on command line
; *		       CL set to zero
; *		    If error
; *		       CL contains error value from parse
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

        PUBLIC  ON_OFF,OnOffChar,OnOffSpace
ON_OFF:
        MOV     DI,OFFSET TRANGROUP:OnOffControl
OnOffParse:
        MOV     ParseArgIndex,1
        CALL    ParseArgument
        JC      OnOffNoMatch
        MOV     DI,OFFSET TRANGROUP:OnOffWords
        MOV     AX,0
        XOR     CH,CH
        MOV     BX,[BX].arglen
OnOffCompare:
        MOV     CL,[DI]
        JCXZ    OnOffNoMatch
        INC     DI
        CMP     CL,BL
        JNE     SHORT OnOffNext
        PUSH    CX
        PUSH    SI
        PUSH    DI
        REPE    CMPSB
        POP     DI
        POP     SI
        POP     CX
        JE      SHORT OnOffMatched
OnOffNext:
        ADD     DI,CX
        INC     AX
        JMP     SHORT OnOffCompare
OnOffMatched:
        OR      AX,AX
        PUSHF
        CALL    CheckParsedArgs
        JNC     SHORT OnOffExtra
        POPF
        CLC
        JMP     SHORT OnOffReturn
OnOffNoMatch:
        MOV     SI,OFFSET TRANGROUP:arg
        MOV     SI,[SI].arg_ocomptr
        XOR     CL,CL
        CLD
OnOffSkip:
        LODSB
        CALL    OnOffSpace
        JE      SHORT OnOffSkip
        DEC     SI
OnOffScan:
        LODSB
        CMP     AL,0DH
        JE      SHORT OnOffBad
        CALL    OnOffSpace
        JE      SHORT OnOffTrailing
        CALL    OnOffChar
        JNE     SHORT OnOffScan
        MOV     CL,1
        JMP     SHORT OnOffBad
OnOffTrailing:
        PUSH    SI
OnOffTrailingScan:
        LODSB
        CMP     AL,0DH
        JE      SHORT OnOffTrailingEnd
        CALL    OnOffSpace
        JE      SHORT OnOffTrailingScan
OnOffTrailingEnd:
        POP     SI
        JE      SHORT OnOffBad
        MOV     CL,1
        JMP     SHORT OnOffBad
OnOffExtra:
        POPF
        MOV     CX,AX
OnOffBad:
        MOV     msg_disp_class,3
        MOV     DX,OFFSET TRANGROUP:BAD_ON_OFF_ptr
        STC
OnOffReturn:
        RET

; Return zero for characters that delimit an ON/OFF token.
OnOffChar:
        CMP     AL,' '
        JB      SHORT OnOffControlChar
        CMP     AL,'/'
        JE      SHORT OnOffCharReturn
        CMP     AL,'"'
        JE      SHORT OnOffCharReturn
        CMP     AL,5CH
        JE      SHORT OnOffCharReturn
        CMP     AL,':'
        JE      SHORT OnOffCharReturn
        CMP     AL,'.'
        JE      SHORT OnOffCharReturn
        CMP     AL,'['
        JE      SHORT OnOffCharReturn
        CMP     AL,']'
        JE      SHORT OnOffCharReturn
        CMP     AL,'+'
        JE      SHORT OnOffCharReturn
        CMP     AL,','
        JE      SHORT OnOffCharReturn
        CMP     AL,';'
        JE      SHORT OnOffCharReturn
        CMP     AL,'='
OnOffCharReturn:
        RET
OnOffControlChar:
        CMP     AL,AL
        RET
OnOffSpace:
        CMP     AL,' '
        JE      SHORT OnOffSpaceReturn
        CMP     AL,9
OnOffSpaceReturn:
        RET


;*************************************************************************
; print date

PRINT_DATE:
	PUSH	ES
	PUSH	DI
	PUSH	CS
	POP	ES
	CALL	GetDate 			; get date
	xchg	dh,dl				;AN000; switch month & day
	mov	promptDat_yr,cx 		;AC000; put year into message control block
	mov	promptDat_moday,dx		;AC000; put month and day into message control block
	mov	dx,offset trangroup:promptDat_ptr ;AC000; set up message for output
	invoke	std_printf
;AD061; mov	promptDat_yr,0			;AC000; reset year, month and day
;AD061; mov	promptDat_moday,0		;AC000;     pointers in control block
	POP	DI				;AC000; restore di,es
	POP	ES				;AC000;
	return
;
; Do GET DATE system call and set up 3 character day of week in ARG_BUF
; for output.  Date will be returned in CX,DX.
;

GetDate:
	mov	di,offset trangroup:arg_buf	;AC000; target for day of week
	MOV	AH,GET_DATE			;AC000; get current date
	INT	21h			;AC000; Get date in CX:DX
	CBW					;AC000;

	push	cx				;AN000; save date returned in
	push	dx				;AN000;      CX:DX
	MOV	SI,AX
IFNDEF DBCS
	SHL	SI,1
	ADD	SI,AX				; SI=AX*3
  ELSE
    ifdef JAPAN					; MSKK01 07/14/89
	shl	si,1
	shl	si,1				; SI=AX*4
    endif
    IFDEF TAIWAN
	SHL	SI,1
	ADD	SI,AX
	SHL	SI,1				; SI=AX*6
    ENDIF
    ifdef KOREA
        shl     si,1
    endif
ENDIF
	mov	cx,si				;AN000; save si
	mov	ax,weektab			;AN000; get message number of weektab
	mov	dh,util_msg_class		;AN000; this is a utility message
	push	di				;AN000; save argument buffer
	invoke	Tsysgetmsg			;AN000; get the address of the message
	pop	di				;AN000; retrieve argument buffer
	add	si,cx				;AC000; get day of week
IFNDEF DBCS
	MOV	CX,3
  ELSE
    ifdef JAPAN					; MSKK01 07/14/89
	mov	cx,4
    endif
    IFDEF TAIWAN
	MOV	CX,6
    ENDIF
    ifdef KOREA
        mov     cx,2                            ; MSCH 90/9/6
    endif
ENDIF
	REP	MOVSB
	mov	al,end_of_line_out		;AC000; terminate the string
	stosb
	pop	dx				;AN000; get back date
	pop	cx				;AN000;

	return
;g
;g   This routine determines whether the character in AL is a
;g   Yes or No character.  On return, if AL=0, the character is
;g   No, if AL=1, the character is Yes.
;g

assume	ds:trangroup

	PUBLIC	char_in_xlat
char_in_xlat	proc	near

	mov	dl,al				;AC000; get character into DX
	xor	dh,dh				;AC000;
	mov	ax,(getextcntry SHL 8) + 35	;AC000; Yes/No char call
	int	21h			;AC000;

	ret

char_in_xlat	endp

; Confirm deletion of all files unless /P asks for each file.
EraseConfirmAll:
        CMP     BYTE PTR [COMSW],0
        JNZ     SHORT EraseConfirmYes
        MOV     SI,DirSearchPos
        LODSW
        CMP     AX,'.*'
        JZ      SHORT EraseCheckAllExt
        CMP     PathFindMode,0
        JZ      SHORT EraseConfirmYes
        JMP     SHORT EraseCheckAllStar
EraseCheckAllExt:
        LODSW
EraseCheckAllStar:
        CMP     AX,'*'
        JNZ     SHORT EraseConfirmYes
EraseAskAll:
        MOV     DX,OFFSET TRANGROUP:SureMes_Ptr
        INVOKE  STD_PRINTF
        MOV     SI,80H
        MOV     DX,SI
        MOV     WORD PTR [SI],120
        MOV     AX,0C0AH
        INT     21H
        LODSW
        OR      AH,AH
        JZ      EraseAskAll
        INVOKE  SCANOFF
        CALL    char_in_xlat
        JC      SHORT EraseConfirmNo
        CMP     AL,0
        JZ      SHORT EraseConfirmNo
        CMP     AL,1
        PUSHF
        INVOKE  CRLF2
        POPF
        JNZ     EraseAskAll
EraseConfirmYes:
        CLC
        RET
EraseConfirmNo:
        STC
        RET

; Confirm an individual filename for DEL /P.
EraseConfirmFile:
        CMP     BYTE PTR [COMSW],0
        JZ      SHORT EraseFileYes
EraseAskFile:
        INVOKE  CRLF2
        MOV     DX,OFFSET TRANGROUP:DirEntryPath
        MOV     string_ptr_2,DX
        MOV     DX,OFFSET TRANGROUP:string_buf_ptr
        INVOKE  STD_PRINTF
        MOV     DX,OFFSET TRANGROUP:Del_Y_N_Ptr
        INVOKE  STD_PRINTF
        MOV     AX,0C01H
        INT     21H
        CALL    char_in_xlat
        JC      SHORT EraseFileNo
        CMP     AL,0
        JZ      SHORT EraseFileNo
        CMP     AL,1
        JNZ     EraseAskFile
EraseFileYes:
        CLC
        RET
EraseFileNo:
        STC
        RET

TRANCODE	ENDS
	END
