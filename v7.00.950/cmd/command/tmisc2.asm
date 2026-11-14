	page ,132
;	SCCSID = @(#)tmisc2.asm 4.3 85/06/25
;	SCCSID = @(#)tmisc2.asm 4.3 85/06/25
TITLE	Part7 COMMAND Transient Routines
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;	More misc routines


.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include pdb.inc
	include bpb.inc
	include sf.inc
	include comseg.asm
	include comequ.asm
	include ioctl.inc
.list
.cref


CODERES 	SEGMENT PUBLIC BYTE	;AC000;
CodeRes 	ENDS

DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	IFFlag:BYTE
	EXTRN	PIPEFLAG:BYTE
	EXTRN	RE_OUTSTR:BYTE
	EXTRN	RE_OUT_APP:BYTE
DATARES 	ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	AccDen_PTR:WORD
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	FULDIR_PTR:WORD
	EXTRN	msg_disp_class:byte	;AN000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	DirSearchPath:BYTE,DirEntryPath:BYTE
	EXTRN	DirSearchPos:WORD,DirEntryPos:WORD,DirSearchLength:WORD
	EXTRN	PathFindBuffer:BYTE,PathFindHandle:WORD,PathQueryRoot:BYTE
	EXTRN	DirBuf:BYTE,CopyFindDataOffset:WORD
	EXTRN	PathChdirFunction:WORD,PathGetdirFunction:WORD,PathAttribFunction:WORD
	EXTRN	PathFindMode:BYTE
	EXTRN	arg:BYTE
	EXTRN	DESTINFO:BYTE
	EXTRN	DESTISDIR:BYTE
	EXTRN	KPARSE:BYTE		;AC000;
	EXTRN	ONE_CHAR_VAL:BYTE	;AN011;
	EXTRN	PATHCNT:WORD
	EXTRN	PATHPOS:WORD
	EXTRN	PATHSW:WORD
	EXTRN	PathOpenFunction:WORD
	EXTRN	RE_INSTR:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	SRCBUF:BYTE
	EXTRN	SWITCHAR:BYTE

	IF  IBM_ROM_FIND
	EXTRN	ROM_CALL:BYTE
	EXTRN	ROM_CS:WORD
	EXTRN	ROM_IP:WORD
	ENDIF

TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC byte

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	CERROR:NEAR

	IF	IBM_ROM_FIND
	EXTRN	ROM_EXEC:NEAR
	EXTRN	ROM_SCAN:NEAR
	ENDIF

	PUBLIC	IOSET
	PUBLIC	MOVE_TO_SRCBUF		;AN000;
	PUBLIC	PGETARG
	PUBLIC	SETPATH
	PUBLIC	TESTDOREIN
	PUBLIC	TESTDOREOUT


ASSUME	DS:TRANGROUP

SETPATH:
;
; ENTRY PathPos = ptr to string
;       PathCnt = length of string
;
; EXIT  PathPos = ptr to string after pathname
;       PathCnt = length of rest of string
;       DX = ptr to pathname in string, made ASCIIZ
;       DestIsDir = 1 if pathname delimiters appeared in pathname, 0 otherwise
;       DestInfo = 2 if wildcards (?, *) appeared in pathname, 0 otherwise
;
;       A null character is dropped at the end of the pathname.  If the
;       character in that spot previously was CR, it is copied into the
;       following byte.  So there must be at least two two character 
;       positions in the buffer following the pathname.
;
        MOV     AX,[PATHCNT]            ;AC000; get length of string
        MOV     SI,[PATHPOS]            ;AC000; get start of source buffer

GETPATH:
	MOV	[DESTINFO],0
        MOV     [DESTISDIR],0
        MOV     SI,[PATHPOS]            ; SI = ptr to string
        MOV     CX,[PATHCNT]            ; CX = string length
        MOV     DX,SI                   ; DX = ptr to string
        JCXZ    PATHDONE                ; string length is zero, we're done
        PUSH    CX                      ; save string length
        PUSH    SI                      ; save ptr to string
        POP     BX                      ; BX = ptr to original string
        SUB     BX,SI                   ; BX = -(# chars scanned by Switch)
        POP     CX                      ; CX = string length
        ADD     CX,BX                   ; CX = string length from current SI
        MOV     DX,SI                   ; DX = ptr to current string

SKIPPATH:

;;;;	IFDEF	DBCS	3/3/KK
	MOV	[KPARSE],0

SKIPPATH2:
;;;;	ENDIF		3/3/KK

        JCXZ    PATHDONE                ; string length is zero, we're done
        DEC     CX                      ; CX = length left after next char
        LODSB                           ; AL = next char of string
                                        ; SI = ptr to char after this one

;;;;	IFDEF	DBCS	3/3/KK
	INVOKE	TESTKANJ
        JZ      TESTPPSEP               ; no Kanji, move along
	DEC	CX
	INC	SI
	INC	[KPARSE]
	JMP	SKIPPATH2

TESTPPSEP:
;;;;	ENDIF		3/3/KK

        INVOKE  PATHCHRCMP              ; compare AL to path delimiter char
        JNZ     TESTPMETA               ; it's not a path delim
        INC     [DESTISDIR]             ; DestIsDir = 1, signalling path char

TESTPMETA:
        CMP     AL,'?'
        JNZ     TESTPSTAR               ; char is not '?'
        OR      [DESTINFO],2            ; DestInfo = 2, signalling wildcard

TESTPSTAR:
        CMP     AL,star
        JNZ     TESTPDELIM              ; char is not '*'
        OR      [DESTINFO],2            ; DestInfo = 2, signalling wildcard

TESTPDELIM:
        CMP     AL,[SWITCHAR]
        JNZ     SKIPPATH                ; char isn't switch, go get next char

PATHDONEDEC:
        DEC     SI                      ; SI = ptr to char after pathname

PATHDONE:
        XOR     AL,AL                   ; AL = NULL
        XCHG    AL,[SI]                 ; place NULL after pathname
        INC     SI                      ; SI = ptr to byte after NULL
        CMP     AL,0DH                  ; were we at end of line?
        JNZ     NOPSTORE                ; not EOL, finish up
        MOV     [SI],AL                 ; save EOL after NULL

NOPSTORE:
        MOV     [PATHPOS],SI            ; PathPos = ptr to char after NULL
        MOV     [PATHCNT],CX            ; PathCnt = length of string left
        return

PGETARG:
        MOV     SI,OFFSET TRANGROUP:arg
        MOV     CX,[SI].arglen
        MOV     SI,[SI].arg_ocomptr
        CALL    PSCANOFF
        ADD     SI,CX
        CALL    PSCANOFF
        CMP     AL,13
        return

PSCANOFF:
	LODSB
	INVOKE	DELIM
	JNZ	PSCANOFFD
	CMP	AL,';'
	JNZ	PSCANOFF			; ';' is not a delimiter

PSCANOFFD:
	DEC	SI				; Point to first non-delimiter
	return

	PUBLIC	REDIRERR,NOREOUT
IOSET:
;
; ALL REGISTERS PRESERVED
;
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING

	PUSH	DS
	PUSH	DX
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	SI
	PUSH	DI
	MOV	DS,CS:[RESSEG]
ASSUME	DS:RESGROUP

	CMP	[PIPEFLAG],0
	JNZ	NOREDIR 			; Don't muck up the pipe
	TEST	IFFlag,-1
	JNZ	NoRedir
	CALL	TESTDOREIN
	CALL	TESTDOREOUT

NOREDIR:
	POP	DI
	POP	SI
	POP	CX
	POP	BX
	POP	AX
	POP	DX
	POP	DS
ASSUME	DS:NOTHING
	return

TESTDOREIN:

ASSUME	DS:RESGROUP

	CMP	[RE_INSTR],0
	retz
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	SI,OFFSET TRANGROUP:RE_INSTR
	CALL	SelectPathInterface
	MOV	AX,CS:PathOpenFunction
	MOV	BX,40H
	MOV	DX,1
	XOR	DI,DI
	INT	21h
	POP	DS
	JC	REDIRERR
	MOV	BX,AX
	MOV	AL,0FFH
;
; Mega sleaze!! We move the SFN from the new handle spot into the old stdin
; spot.  We invalidate the new JFN we got.
;
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table],AL

	return
;
; We had some kind of error on the redirection.  Figure out what the
; appropriate message should be; BX has the system call that failed
;
REDIRERR:
	PUSH	CS
	POP	DS
	Call	TriageError
;
; At this point, we have recognized the network-generated access denied error.
; The correct message is in DX
;
	CMP	AX,65
	JZ	CERRORJ 			;AC000; just issue message returned
	OR	DI,DI
	JZ	OpenError
;
; The error was for a create operation.  Report the error as a creation error.
;
	MOV	DX,OFFSET TranGroup:FULDIR_PTR

CERRORJ:
	JMP	CERROR
;
; The system call was an OPEN.	Report either file not found or path not found.
;

OpenError:
	mov	CS:msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AC000; get extended message pointer
	mov	CS:Extend_Buf_ptr,ax		;AN000; get message number in control block
	JMP	CERROR

TESTDOREOUT:

ASSUME	DS:RESGROUP

	CMP	[RE_OUTSTR],0
	JNZ	REOUTEXISTS			;AN017; need long jump
	JMP	NOREOUT 			;AN017;

REOUTEXISTS:
	MOV	SI,OFFSET RESGROUP:RE_OUTSTR
	CALL	SelectPathInterface
	CMP	[RE_OUT_APP],0
	JZ	REOUTCRT
;
; The output redirection was for append.  We open for write and seek to the
; end.
;
	MOV	AX,CS:PathOpenFunction
	MOV	BX,22H
	MOV	DX,1
	MOV	DI,1
	INT	21H
	JC	OpenWriteError

	MOV	BX,AX
	MOV	AX,IOCTL SHL 8			;AN035; Get attributes of handle
	INT	21h			;AN035;
	TEST	DL,devid_ISDEV			;AN035; Is it a device?
	JNZ	SET_REOUT			;AN035; Yes, don't read from it

	MOV	AX,(LSEEK SHL 8) OR 2
	MOV	CX,-1				;AC011; MOVE TO EOF -1
	MOV	DX,CX				;AC011;
	INT	21h
	PUSH	CS				;AN011; Get transient seg to DS
	POP	DS				;AN011;
	assume	DS:Trangroup			;AN011;
	MOV	AX,(READ SHL 8) 		;AN011; Read one byte from the
	MOV	CX,1				;AN011;   file into one_char_val
	MOV	DX,OFFSET Trangroup:ONE_CHAR_VAL;AN011;
	INT	21h			;AN011;
	JC	OpenWriteError			;AN011; If error, exit
	cmp	ax,cx				;AN017; Did we read 1 byte?
	jnz	reout_0_length			;AN017; No - file must be 0 length

	cmp	one_char_val,01ah		;AN011; Was char an eof mark?
	mov	DS,[resseg]			;AN011; Get resident segment back
	assume	DS:Resgroup			;AN011;
	JNZ	SET_REOUT			;AN011; No, just continue
	MOV	AX,(LSEEK SHL 8) OR 1		;AN011; EOF mark found
	MOV	CX,-1				;AN011; LSEEK back one byte
	MOV	DX,CX				;AN011;
	INT	21h			;AN011;
	JMP	SHORT SET_REOUT

reout_0_length: 				;AN017; We have a 0 length file
	mov	DS,CS:[resseg]			;AN017; Get resident segment back
	assume	DS:Resgroup			;AN017;
	MOV	AX,(LSEEK SHL 8)		;AN017; Move to beginning of file
	XOR	CX,CX				;AN017; Offset is 0
	MOV	DX,CX				;AN017;
	INT	21h			;AN017;
	JMP	SHORT SET_REOUT 		;AN017; now finish setting up redirection

OpenWriteError:
	CMP	AX,error_access_denied
	STC					; preserve error
	JNZ	REOUTCRT			;AN017; need long jump
	JMP	REDIRERR			;AN017;

REOUTCRT:
	MOV	SI,OFFSET RESGROUP:RE_OUTSTR
	XOR	CX,CX
	MOV	AX,CS:PathOpenFunction
	MOV	BX,22H
	MOV	DX,112H
	MOV	DI,1
	INT	21H
	JNC	NOREDIRERR			;AC011;
	JMP	REDIRERR			;AC011;

NOREDIRERR:					;AN011;
	MOV	BX,AX

SET_REOUT:
;
; Mega sleaze!! We move the SFN from the new handle spot into the old stdout
; spot.  We invalidate the new JFN we got.
;
	MOV	AL,0FFH
	XCHG	AL,[BX.PDB_JFN_Table]
	MOV	DS:[PDB_JFN_Table+1],AL

NOREOUT:
	return

;
; Compute length of string (including NUL) in DS:SI into CX.  Change no other
; registers
;
Procedure   DSTRLEN,NEAR

	SaveReg <AX>
	XOR	CX,CX
	CLD

DLoop:	LODSB
	INC	CX
	OR	AL,AL
	JNZ	DLoop
	SUB	SI,CX
	RestoreReg  <AX>
	return

EndProc DSTRLEN

Break	<Extended error support>

;
; TriageError will examine the return from a carry-set system call and
; return the correct error if applicable.
;
;   Inputs:	outputs from a carry-settable system call
;		No system calls may be done in the interrim
;   Outputs:	If carry was set on input
;		    carry set on output
;		    DX contains trangroup offset to printf message
;		else
;		    No registers changed
;

Procedure TriageError,NEAR

	retnc					; no carry => do nothing...
	PUSHF
	SaveReg <BX,CX,SI,DI,BP,ES,DS,AX,DX>
	MOV	AH,GetExtendedError
	INT	21h
	RestoreReg  <CX,BX>			; restore original AX
	MOV	DX,OFFSET TranGroup:AccDen_PTR
	CMP	AX,65				; network access denied?
	JZ	NoMove				; Yes, return it.
	MOV	AX,BX
	MOV	DX,CX

NoMove:
	RestoreReg  <DS,ES,BP,DI,SI,CX,BX>
	popf
	return

EndProc TriageError

PUBLIC Triage_Init
Triage_Init proc FAR
	call	TriageError
	ret
Triage_Init endp


; ****************************************************************
; *
; * ROUTINE:	 MOVE_TO_SRCBUF
; *
; * FUNCTION:	 Move ASCIIZ string from DS:SI to SRCBUF.  Change
; *		 terminating 0 to 0dH.	Set PATHCNT to length of
; *		 string.  Set PATHPOS to start of SRCBUF.
; *
; * INPUT:	 DS:SI points to ASCIIZ string
; *		 ES    points to TRANGROUP
; *
; * OUTPUT:	 SRCBUF filled in with string terminated by 0dH
; *		 PATHCNT set to length of string
; *		 PATHPOS set to start of SRCBUF
; *		 CX,AX	 changed
; *
; ****************************************************************

assume	es:trangroup,ds:nothing 		;AN000;

MOVE_TO_SRCBUF	PROC	NEAR			;AN000;

	push	si				;AN000;  save si,di
	push	di				;AN000;
	push	cx				;AN000;
	mov	di,offset TRANGROUP:srcbuf	;AN000;  set ES:DI to srcbuf
	xor	cx,cx				;AN000; clear cx for counint
	mov	ax,cx				;AN000; clear ax
	push	di				;AN000; save start of srcbuf
	lodsb					;AN000; get a character from DS:SI

mts_get_chars:					;AN000;
	cmp	al,0				;AN000; was it a null char?
	jz	mts_end_string			;AN000; yes - exit
	stosb					;AN000; no - store it in srcbuf
	inc	cx				;AN000; increment length count
	lodsb					;AN000; get a character from DS:SI
	jmp	short mts_get_chars		;AN000; go check it

mts_end_string: 				;AN000; we've reached the end of line
	mov	al,end_of_line_in		;AN000; store 0dH in srcbuf
	stosb					;AN000;
	pop	di				;AN000; restore start of srcbuf

	push	cs				;AN000; set DS to local segment
	pop	ds				;AN000;
assume	ds:trangroup				;AN000;
	mov	[pathcnt],cx			;AN000; set patchcnt to length count
	mov	[pathpos],di			;AN000; set pathpos to start of srcbuf
	pop	cx				;AN000; restore cx,di,si
	pop	di				;AN000;
	pop	si				;AN000;

	RET					;AN000; exit

MOVE_TO_SRCBUF	ENDP				;AN000;


	public	DirStoreArgument
DirStoreArgument proc
	push	si
	mov	di,offset TRANGROUP:DirSearchPath
	mov	cx,[bx].arglen
	mov	DirSearchLength,cx
	push	cx
	rep	movsb
	xor	al,al
	stosb
	pop	cx
	pop	si
	push	si
	mov	di,offset TRANGROUP:DirEntryPath
	rep	movsb
	stosb
	pop	si
	mov	ax,[bx].argstartel
	sub	ax,si
	mov	DirSearchPos,offset TRANGROUP:DirSearchPath
	mov	DirEntryPos,offset TRANGROUP:DirEntryPath
	add	DirSearchPos,ax
	add	DirEntryPos,ax
	ret
DirStoreArgument endp

	public	DirAppendWildcard
DirAppendWildcard proc near
	push	bx
	mov	bx,DirSearchLength
	cmp	byte ptr DirSearchPath[bx-1],'\'
	jz	short dawPosition
	cmp	byte ptr DirSearchPath[bx-1],':'
	jz	short dawPosition
	mov	byte ptr DirSearchPath[bx],'\'
	inc	bx
	add	DirSearchLength,1
dawPosition:
	mov	DirSearchPos,offset TRANGROUP:DirSearchPath
	add	DirSearchPos,bx
	cmp	PathFindMode,0
	jnz	short dawStar
	mov	word ptr DirSearchPath[bx],'.*'
	inc	bx
	inc	bx
	add	DirSearchLength,2
dawStar:
	mov	word ptr DirSearchPath[bx],'*'
	add	DirSearchLength,1
	pop	bx
	ret
DirAppendWildcard endp

	public	DirAppendEntryName
DirAppendEntryName proc near
	push	di
	mov	di,DirEntryPos
daenNext:
	lodsb
	stosb
	or	al,al
	jnz	daenNext
	pop	di
	ret
DirAppendEntryName endp

	public	DirAppendSearchName
DirAppendSearchName proc near
	push	di
	mov	di,DirSearchPos
	jmp	short daenNext
DirAppendSearchName endp

	public	DirSetEntryPosition
DirSetEntryPosition proc near
	push	bx
	mov	ax,DirSearchLength
	mov	bx,offset TRANGROUP:DirEntryPath
	add	bx,ax
	cmp	byte ptr [bx-1],'\'
	jz	short dsepReady
	mov	byte ptr [bx],'\'
	inc	bx
dsepReady:
	mov	DirEntryPos,bx
	pop	bx
	ret
DirSetEntryPosition endp

	public	DirNormalizePattern
DirNormalizePattern proc near
	push	si
	push	di
	push	cx
	push	dx
	push	bp
	mov	si,DirSearchPos
	push	si
	xor	bp,bp
dnpLength:
	lodsb
	or	al,al
	jz	short dnpLengthDone
	inc	bp
	jmp	short dnpLength
dnpLengthDone:
	pop	si
	xor	cx,cx
	mov	dx,cx
	push	si
dnpScan:
	lodsb
	cmp	al,'.'
	jnz	short dnpStar
	or	dx,1
dnpStar:
	cmp	al,'*'
	jnz	short dnpNext
	or	dx,2
dnpNext:
	or	al,al
	jz	short dnpScanned
	inc	cx
	jmp	short dnpScan
dnpScanned:
	pop	si
	jcxz	dnpEmpty
	test	dx,1
	jz	short dnpNoDot
	cmp	byte ptr [si],'.'
	jz	short dnpLeadingDot
dnpEmpty:
	cmp	DirSearchLength,2
	jnz	short dnpDone
	cmp	byte ptr DirSearchPath+1,':'
	jnz	short dnpDone
	call	DirAppendWildcard
dnpDone:
	pop	bp
	pop	dx
	pop	cx
	pop	di
	pop	si
	ret
dnpNoDot:
	cmp	DirSearchLength,2
	jnz	short dnpAddExt
	cmp	byte ptr [si+1],':'
	jnz	short dnpAddExt
	call	DirAppendWildcard
	jmp	short dnpDone
dnpAddExt:
	add	si,bp
	cmp	PathFindMode,0
	jz	short dnpAppendExt
	test	dx,2
	jnz	short dnpDone
dnpAppendExt:
	mov	word ptr [si],'*.'
	mov	byte ptr [si+2],0
	add	DirSearchLength,2
	jmp	short dnpDone
dnpLeadingDot:
	add	si,bp
	inc	cx
	mov	di,si
	inc	di
	std
	rep	movsb
	cld
	mov	si,DirSearchPos
	mov	byte ptr [si],'*'
	jmp	short dnpDone
DirNormalizePattern endp

;*** SelectPathInterface -- Select pathname calls for the file system.
;
;       ENTRY   DS:SI = pathname
;       EXIT    AL = nonzero for long filename calls, zero otherwise
;               AX and flags changed; other registers preserved
;
        PUBLIC  SelectPathInterface,SelectDriveInterface,IsNetworkPath
assume  ds:nothing,es:nothing
SelectDriveInterface PROC NEAR
        PUSH    DX
        PUSH    CX
        PUSH    BX
        OR      AL,AL
        JNZ     SHORT QueryDrivePath
        JMP     SHORT QueryCurrentDrive
SelectDriveInterface ENDP
SelectPathInterface PROC NEAR
        PUSH    DX
        PUSH    CX
        PUSH    BX
        CALL    IsNetworkPath
        OR      AL,AL
        JNZ     SHORT QueryNetworkPath
        CMP     BYTE PTR [SI+1],':'
        MOV     AL,[SI]
        JE      SHORT QueryDrivePath
QueryCurrentDrive:
        MOV     AH,19H
        INT     21H
        ADD     AL,'A'
QueryDrivePath:
        MOV     AH,':'
        MOV     WORD PTR CS:PathQueryRoot,AX
        MOV     WORD PTR CS:PathQueryRoot+2,005CH
        PUSH    SI
        PUSH    DS
        PUSH    CS
        POP     DS
        MOV     SI,OFFSET TRANGROUP:PathQueryRoot
        MOV     DX,SI
        XOR     BX,BX
        MOV     AX,71A0H
        XOR     CX,CX
        STC
        INT     21H
        POP     DS
        POP     SI
CheckPathInterface:
        JC      SHORT UseShortNames
        TEST    BX,4000H
        JZ      SHORT UseShortNames
        MOV     AL,1
        MOV     CS:PathChdirFunction,713BH
        MOV     CS:PathGetdirFunction,7147H
        MOV     CS:PathOpenFunction,716CH
        MOV     CS:PathAttribFunction,7143H
        JMP     SHORT PathInterfaceDone
QueryNetworkPath:
        PUSH    DI
        PUSH    ES
        PUSH    DS
        POP     ES
        LEA     DI,[SI+2]
        CMP     WORD PTR [SI],5C5CH
        JE      SHORT FindShareRoot
        INC     DI
        INC     DI
FindShareRoot:
        CLD
        XOR     AL,AL
        MOV     CX,0FFFFH
        REPNE   SCASB
        NOT     CX
        MOV     AL,5CH
        LEA     DI,[SI+2]
        REPNE   SCASB
        MOV     BX,0
        JNZ     SHORT NetworkQueryDone
        REPNE   SCASB
        DEC     DI
        XOR     AL,AL
        XCHG    AL,ES:[DI]
        PUSH    AX
        MOV     DX,SI
        XOR     BX,BX
        MOV     AX,71A0H
        XOR     CX,CX
        STC
        INT     21H
        POP     AX
        XCHG    AL,ES:[DI]
NetworkQueryDone:
        POP     ES
        POP     DI
        JMP     SHORT CheckPathInterface
UseShortNames:
        MOV     CS:PathChdirFunction,3B00H
        MOV     CS:PathGetdirFunction,4700H
        MOV     CS:PathOpenFunction,6C00H
        MOV     CS:PathAttribFunction,4300H
        XOR     AL,AL
PathInterfaceDone:
        POP     BX
        POP     CX
        POP     DX
        RET
SelectPathInterface ENDP

;*** PathFindFirst -- Find a pathname using the selected interface.
;
;       ENTRY   DS:DX = filespec, CX = attributes, ES:DI = search buffer
;               PathFindMode selects the DOS or long filename interface
;       EXIT    Carry and AX returned by DOS
;               SI = filename offset in the search buffer
;
PathFindFirst PROC NEAR
        MOV     AX,714EH
        CMP     CS:PathFindMode,0
        JNE     SHORT PathFindFirstCall
        CALL    SetPathDTA
        MOV     AX,4E00H
PathFindFirstCall:
        XOR     SI,SI
        INT     21H
        LEA     SI,[DI+1EH]
        PUSHF
        JC      SHORT PathFindFirstName
        MOV     CS:PathFindHandle,AX
PathFindFirstName:
        CMP     CS:PathFindMode,0
        JE      SHORT PathFindFirstDone
        LEA     SI,[DI+2CH]
PathFindFirstDone:
        POPF
        RET
PathFindFirst ENDP

;*** PathFindNext -- Continue a pathname search.
;
;       ENTRY   ES:DI = search buffer, saved mode and handle from first call
;       EXIT    Carry and AX returned by DOS
;               SI = filename offset; failed long filename search closed
;
PathFindNext PROC NEAR
        PUSH    BX
        MOV     AX,714FH
        MOV     BX,CS:PathFindHandle
        CMP     CS:PathFindMode,0
        JNE     SHORT PathFindNextCall
        CALL    SetPathDTA
        MOV     AX,4F00H
PathFindNextCall:
        XOR     SI,SI
        INT     21H
        PUSHF
        LEA     SI,[DI+1EH]
        CMP     CS:PathFindMode,0
        JE      SHORT PathFindNextName
        LEA     SI,[DI+2CH]
PathFindNextName:
        POPF
        PUSHF
        JNC     SHORT PathFindNextDone
        CMP     CS:PathFindMode,0
        JE      SHORT PathFindNextDone
        CALL    ClosePathFind
PathFindNextDone:
        POPF
        POP     BX
        RET
PathFindNext ENDP

;*** IsNetworkPath -- Check for a network pathname prefix.
;
;       ENTRY   DS:SI = pathname
;       EXIT    AL = 5CH for a network prefix, zero otherwise
;               AH and flags changed
;
IsNetworkPath PROC NEAR
        MOV     AX,5C5CH
        CMP     [SI],AX
        JE      SHORT NetworkPathDone
        CMP     BYTE PTR [SI+1],':'
        JNE     SHORT LocalPath
        CMP     [SI+2],AX
        JE      SHORT NetworkPathDone
LocalPath:
        XOR     AL,AL
NetworkPathDone:
        RET
IsNetworkPath ENDP

;*** SetPathDTA -- Set the DOS search buffer.
;
;       ENTRY   ES:DI = search buffer
;       EXIT    AX and flags changed
;
        PUBLIC  SetPathDTA,ClosePathFind,PathFindFirst,PathFindNext
SetPathDTA PROC NEAR
        PUSH    DX
        PUSH    DS
        PUSH    ES
        POP     DS
        MOV     DX,DI
        MOV     AH,1AH
        INT     21H
        POP     DS
        POP     DX
        RET
SetPathDTA ENDP

;*** ClosePathFind -- Release the saved long filename search handle.
;
;       EXIT    Saved handle cleared; AX and flags changed
;
ClosePathFind PROC NEAR
        PUSH    BX
        XOR     BX,BX
        XCHG    BX,CS:PathFindHandle
        OR      BX,BX
        JZ      SHORT ClosePathFindDone
        MOV     AX,71A1H
        INT     21H
ClosePathFindDone:
        POP     BX
        RET
ClosePathFind ENDP

;*** SelectReturnedName -- Use the long name if the short name is empty.
;
;       ENTRY   DS:SI = short filename field
;       EXIT    SI = nonempty filename field, flags changed
;
; Select the source name from COPY's search result.
        PUBLIC  CopyReturnedName
CopyReturnedName:
        MOV     SI,OFFSET TRANGROUP:DirBuf
        ADD     SI,CS:CopyFindDataOffset

        PUBLIC  SelectReturnedName
SelectReturnedName PROC NEAR
        CMP     BYTE PTR [SI],0
        JNE     SHORT ReturnedNameReady
        SUB     SI,104H
ReturnedNameReady:
        RET
SelectReturnedName ENDP


TRANCODE    ENDS
	    END
