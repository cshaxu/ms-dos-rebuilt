	page ,132
;	SCCSID = @(#)tenv.asm	4.2 85/08/16
;	SCCSID = @(#)tenv.asm	4.2 85/08/16
TITLE	Part6 COMMAND Transient routines.
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;	Environment utilities and misc. routines
;
;	Revision History
;	================
;
;	M024	SR	9/5/90	Zero out comspec_flag to fix bug
;				#710 about comspec getting trashed.
;



	INCLUDE comsw.asm

.xlist
.xcref
	include dossym.inc
	include syscall.inc
	include arena.inc
	include comseg.asm
	include comequ.asm
	include doscntry.inc		;an000;
	include	resmsg.equ
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	comdrv:byte
	EXTRN	comspec_end:word
	EXTRN	ComSpecName:word
	EXTRN	dbcs_vector_addr:dword	;AN000;
	EXTRN	ENVIRSEG:WORD
	EXTRN	fucase_addr:word	;AC000;
	EXTRN	PutBackDrv:byte
	EXTRN	PutBackComSpec:byte
	EXTRN	RESTDIR:BYTE
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg_buf_ptr:word
	EXTRN	comspec:byte
	EXTRN	comspec_flag:byte
	EXTRN	comspecstr:byte
	EXTRN	ENVERR_PTR:WORD
	EXTRN	CmdLineName:BYTE
	EXTRN	FilePrefix:BYTE
	EXTRN	PATH_TEXT:byte
	EXTRN	PROMPT_TEXT:byte
	EXTRN	SYNTMES_PTR:WORD
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	EnvCaseMode:BYTE
	EXTRN	PathChdirFunction:WORD
	EXTRN	CmdBufferLength:WORD
	EXTRN	Arg_Buf:BYTE
	EXTRN	SRCXNAME:BYTE
	EXTRN	arg:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	USERDIR1:BYTE
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC byte

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	cerror:near
	EXTRN	PathFromSet:near

	PUBLIC	add_name_to_environment
	PUBLIC	add_prompt
	PUBLIC	delete_path
	PUBLIC	find_name_in_environment
	PUBLIC	getarg
	PUBLIC	find_path
	PUBLIC	find_prompt
	PUBLIC	move_name
	PUBLIC	restudir
	PUBLIC	restudir1
	PUBLIC	scan_double_null
	PUBLIC	scasb2
	PUBLIC	Testkanj		;AN000;  3/3/KK
	PUBLIC	upconv

BREAK	<Environment utilities>
ASSUME DS:TRANGROUP

	break	Prompt command
assume	ds:trangroup,es:trangroup

ADD_PROMPT:
	CALL	GETARG
	JZ	SHORT PromptDelete
	MOV	DI,SI
	MOV	AL,0DH
	CALL	SCASBX
	SUB	DI,SI				; Length of the value
	MOV	DX,SI
	MOV	SI,OFFSET TRANGROUP:PROMPT_TEXT-1
	LODSB					; Length of PROMPT=
	XOR	AH,AH
	ADD	AX,DI
	MOV	BX,1
	CALL	SetEnvironmentValue
PromptDone:
	RET
PromptDelete:
	CALL	DELETE_PROMPT
	JMP	SHORT PromptDone

assume	ds:trangroup,es:trangroup



; Preserve a long command line in the environment for a child COMMAND.
; DS and ES address TRANGROUP on entry.

	PUBLIC	PrepareLongCommand
PrepareLongCommand PROC NEAR
	CMP	[CmdBufferLength],80H
	JBE	SHORT LongCommandDone
	PUSH	ES
	PUSH	CX
	PUSH	SI
	PUSH	DI
	MOV	SI,OFFSET TRANGROUP:arg
	MOV	SI,[SI].arg_ocomptr
	INVOKE	SCANOFF
	MOV	DI,SI
	MOV	AL,0DH
	CALL	SCASBX
	MOV	AX,DI
	SUB	AX,SI
	MOV	DX,OFFSET TRANGROUP:CmdLineName
	XCHG	SI,DX
	ADD	AL,[SI]
	ADC	AH,0
	INC	SI
	ADD	AL,[FilePrefix]
	ADC	AH,0
	XOR	BX,BX
	CALL	SetEnvironmentValue
	POP	DI
	POP	SI
	POP	CX
	POP	ES
LongCommandDone:
	RET
PrepareLongCommand ENDP

DISP_ENVj:
	jmp	DISP_ENV


	break	The SET command
;
; Input: DS and ES address the transient segment; argv holds the command.
; Output: environment displayed or changed; errors reported by CERROR.
;
ADD_NAME_TO_ENVIRONMENT:
	CALL	GETARG
	JZ	DISP_ENVj
;
; check if line contains exactly one equals sign
;
	XOR	BX,BX				;= COUNT IS 0
	XOR	CX,CX				; Count the command text
	PUSH	SI				;SAVE POINTER TO BEGINNING OF LINE

EQLP:
	LODSB					;GET A CHAR
	INC	CX
	CMP	AL,13				;IF CR WE'RE ALL DONE
	JZ	QUEQ
	CMP	AL,'='                          ;LOOK FOR = SIGN
	JNZ	EQLP				;NOT THERE, GET NEXT CHAR
	MOV	DX,SI				; Save the value address
	INC	BL				;OTHERWISE INCREMENT EQ COUNT
	CMP	BYTE PTR [SI],13		;LOOK FOR CR FOLLOWING = SIGN
	JNZ	EQLP
	INC	BH				;SET BH=1 MEANS NO PARAMETERS

QUEQ:
	POP	SI				;RESTORE BEGINNING OF LINE
	DEC	BL				;ZERO FLAG MEANS ONLY ONE EQ
	JZ	ONEQ				;GOOD LINE
	MOV	DX,OFFSET TRANGROUP:SYNTMES_ptr
	JMP	CERROR

ONEQ:
	MOV	DI,SI
	MOV	AL,0DH
	CALL	SCASBX				; Find the end of the value
	MOV	AX,DI
	SUB	AX,SI				; Size including the terminator
	MOV	BL,1				; Reserve long command space
	PUSH	SI
	PUSH	AX
	CLD
	LODSW
	AND	AX,0DFDFH
	CMP	AX,4150H				; "PA"
	JNE	SHORT EnvNotPath
	LODSW
	AND	AX,0DFDFH
	CMP	AX,4854H				; "TH"
	JNE	SHORT EnvNotPath
	CMP	BYTE PTR [SI],'='
	JNE	SHORT EnvNotPath
	POP	AX
	POP	SI
	MOV	SI,DX
	MOV	DI,OFFSET TRANGROUP:SRCXNAME
	XOR	BL,BL
	XOR	CX,CX
	PUSH	CS
	POP	ES
	JMP	PathFromSet
EnvNotPath:
	POP	AX
	POP	SI
	PUBLIC	SetEnvironmentValue
SetEnvironmentValue:
	PUSH	BX
	CMP	BH,1
	JNE	SHORT EnvSetPrepare
	XOR	AX,AX				; An empty value deletes the name
EnvSetPrepare:
	CALL	PrepareEnvironmentChange
	POP	BX
	DEC	BH
	retz

	CALL	SCAN_DOUBLE_NULL
	mov	bx,di				; Save ptr to beginning of env var name
	CALL	MOVE_NAME
	xchg	si,dx				; Point to the value
	push	si
	xchg	bx,di				; Switch ptrs to beginning and end of
						;  env var name
;
; We want to special-case COMSPEC.  This is to reduce the amount of code
; necessary in the resident for re-reading the transient.  Let's look for
; COMSPEC=
;
	mov	comspec_flag,0			; clear flag ; M024
	mov	si,offset trangroup:comspecstr	; Load ptr to string "COMSPEC"
	mov	cx,4				; If the new env var is comspec, set
	repz	cmpsw				;  the comspec_flag
;
; Zero set => exact match
;
	jnz	not_comspec
	inc	comspec_flag			; comspec is changing ; M024

not_comspec:
	mov	di,bx				; Load ptr to end of env var name

ADD_NAME:					; Add the value of the new env var
	pop	si				;  to the environment.
	push	si

add_name1:
	LODSB
	CMP	AL,13
	jz	add_name_ret
	STOSB
	JMP	ADD_NAME1

add_name_ret:
	xor	ax,ax
	stosw					; End with a double null
	pop	si
	cmp	comspec_flag,0			; If the new env var is comspec,
	retz					;  copy the value into the
;
; We have changed the COMSPEC variable.  We need to update the resident
; pieces necessary to reread in the info.  First, skip all delimiters
;
	invoke	ScanOff
	mov	es,[resseg]			;  comspec var in the resident
	assume	es:resgroup
;
; Make sure that the printer knows where the beginning of the string is
;
	mov	di,offset resgroup:comspec
	mov	bx,di
;
; Generate drive letter for display
;
	xor	ax,ax				;g assume no drive first
	mov	comdrv,al			;g
	push	ax				;AN000;  3/3/KK
	mov	al,[si] 			;AN000;  3/3/KK
	call	testkanj			;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	jnz	GotDrive
	cmp	byte ptr [si+1],':'             ; drive specified?
	jnz	GotDrive
	mov	al,[si] 			; get his specified drive
	call	UpConv				; convert to uppercase
	sub	al,'A'                          ; convert to 0-based
	add	di,2
	inc	al				; convert to 1-based number
	mov	comdrv,al
;
; Stick the drive letter in the prompt message.  Nothing special needs to be
; done here..
;

	add	al,'A'-1

GotDrive:					;g
	mov	PutBackComSpec.SubstPtr,di	;g point to beginning of name after drive
	mov	es:PutBackDrv,al
;
; Copy chars until delim
;

	mov	di,bx
	mov	es:ComSpecName,di		; default filename position

copy_comspec:
	lodsb
	invoke	Delim
	jz	CopyDone
	cmp	al,13
	jz	CopyDone
	cmp	al,'\'
	jnz	short StoreComSpecChar
	mov	es:ComSpecName,di
	inc	word ptr es:ComSpecName
StoreComSpecChar:
	stosb
	jmp	short copy_comspec

CopyDone:
	xor	al,al				; Null terminate the string and quit
	stosb
	mov	comspec_flag,0
	dec	di
	mov	comspec_end,di

	ret

DISP_ENV:
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	DS,[ENVIRSEG]
ASSUME	DS:NOTHING
	XOR	SI,SI

PENVLP:
	CMP	BYTE PTR [SI],0
	retz
	mov	di,offset trangroup:arg_buf

PENVLP2:
	LODSB
	stosb
	OR	AL,AL
	JNZ	PENVLP2
	mov	dx,offset trangroup:arg_buf_ptr
	push	ds
	push	es
	pop	ds
	invoke	printf_crlf
	pop	ds
	JMP	PENVLP

ASSUME	DS:TRANGROUP

; Prepare space for a replacement environment string.
; DS:SI points to the name, AX is the requested size, and BL indicates
; whether space must also be reserved for the long command line.

	PUBLIC	PrepareEnvironmentChange
PrepareEnvironmentChange PROC NEAR
	PUSH	DX
	PUSH	AX
	PUSH	ES
	PUSH	DS
	PUSH	SI
	PUSH	AX
	MOV	[EnvCaseMode],0
	CALL	FIND
	MOV	CX,0
	JC	SHORT EnvChangeOldSize
	MOV	SI,DI
	CALL	SCASB2
	MOV	CX,DI
	SUB	CX,SI
EnvChangeOldSize:
	POP	AX
	CMP	AX,CX
	JBE	SHORT EnvChangeReady
	SUB	AX,CX
	OR	BL,BL
	JZ	SHORT EnvChangeSpace
	CMP	[CmdBufferLength],80H
	JBE	SHORT EnvChangeSpace
	PUSH	AX
	MOV	SI,OFFSET TRANGROUP:CmdLineName+1
	MOV	[EnvCaseMode],0
	CALL	FIND
	MOV	SI,DI
	MOV	DI,0
	JC	SHORT EnvChangeCmdSize
	MOV	DI,SI
	CALL	SCASB2
	SUB	DI,SI
EnvChangeCmdSize:
	POP	AX
	SUB	AX,DI
	ADD	AX,[CmdBufferLength]
	ADD	AL,BYTE PTR [CmdLineName]
	ADC	AH,0
	INC	AX
	ADD	AX,8
EnvChangeSpace:
	PUSH	AX
	PUSH	CX
	CALL	SCAN_DOUBLE_NULL
	POP	CX
	POP	AX
	ADD	AX,DI
	INC	AX
	PUSH	CX
	CALL	GETENVSIZ
	MOV	BX,CX
	POP	CX
	CMP	AX,BX
	JB	SHORT EnvChangeReady
	MOV	BX,AX
	ADD	BX,1FH
	PUSH	CX
	CALL	ResizeEnvironment
	POP	CX
EnvChangeReady:
	POP	SI
	POP	DS
	JCXZ	EnvChangeDone
	CALL	DELETE_NAME_IN_ENVIRONMENT
EnvChangeDone:
	POP	ES
	POP	AX
	POP	DX
	RET
PrepareEnvironmentChange ENDP

DELETE_PATH:
	MOV	SI,OFFSET TRANGROUP:PATH_TEXT
	JMP	SHORT DELETE_NAME_IN_environment

DELETE_PROMPT:
	MOV	SI,OFFSET TRANGROUP:PROMPT_TEXT

DELETE_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: carry flag is set if name not found
;	  otherwise name is deleted
;
	PUSH	SI
	PUSH	DS
	PUBLIC	DeleteEnvironmentLookup
DeleteEnvironmentLookup:
	MOV	[EnvCaseMode],0
	CALL	FIND				; ES:DI POINTS TO NAME
	JC	DEL1
	MOV	SI,DI				; SAVE IT
	CALL	SCASB2				; SCAN FOR THE NUL
	XCHG	SI,DI
;SR;
; If we have only one env string, then the double null is lost when the last
;string is deleted and we have an invalid empty environment with only a 
;single null. To avoid this, we will look for the double null case and then
;move an extra null char.
; Bugbug: The only possible problem is that the last pathstring 
;will be followed by a triple null. Is this really a problem?
;
	cmp	byte ptr es:[si],0			;null char?
	jnz	not_dnull			;no, we are at a double null
	dec	si				;point at the double null
not_dnull:

	CALL	GETENVSIZ
	SUB	CX,SI
	PUSH	ES
	POP	DS				; ES:DI POINTS TO NAME, DS:SI POINTS TO NEXT NAME
	REP	MOVSB				; DELETE THE NAME

DEL1:
	POP	DS
	POP	SI
	return

FIND_PATH:
	MOV	SI,OFFSET TRANGROUP:PATH_TEXT
	MOV	[EnvCaseMode],0
	JMP	SHORT FIND_NAME_IN_environment

FIND_PROMPT:
	MOV	SI,OFFSET TRANGROUP:PROMPT_TEXT
	MOV	[EnvCaseMode],0

FIND_NAME_IN_environment:
;
; Input: DS:SI points to a "=" terminated string
; Output: ES:DI points to the arguments in the environment
;	  zero is set if name not found
;	  carry flag is set if name not valid format
;
	CALL	FIND				; FIND THE NAME
	retc					; CARRY MEANS NOT FOUND
	JMP	SCASB1				; SCAN FOR = SIGN
;
; On return of FIND1, ES:DI points to beginning of name
;
	PUBLIC	FIND
FIND:
	CLD
	CALL	COUNT0				; CX = LENGTH OF NAME
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	ES,[ENVIRSEG]
ASSUME	ES:NOTHING
	XOR	DI,DI

FIND1:
	PUSH	CX
	PUSH	SI
	PUSH	DI

FIND11:
	LODSB
	CALL	TESTKANJ
	JZ	NOTKANJ3
	DEC	SI
	LODSW
	INC	DI
	INC	DI
	CMP	AX,ES:[DI-2]
	JNZ	FIND12
	DEC	CX
	LOOP	FIND11
	JMP	SHORT FIND12

NOTKANJ3:
	CALL	UPCONV
	INC	DI
	PUBLIC	CompareEnvironmentChar
CompareEnvironmentChar:
	CMP	[EnvCaseMode],0
	JZ	SHORT CompareEnvironmentExact
	PUSH	BX
	MOV	BL,AL
	MOV	AL,ES:[DI-1]
	CALL	UPCONV
	CMP	AL,BL
	POP	BX
	JMP	SHORT EnvironmentCharCompared
CompareEnvironmentExact:
	CMP	AL,ES:[DI-1]
EnvironmentCharCompared:
	JNZ	FIND12
	LOOP	FIND11

FIND12:
	POP	DI
	POP	SI
	POP	CX
	retz
	PUSH	CX
	CALL	SCASB2				; SCAN FOR A NUL
	POP	CX
	CMP	BYTE PTR ES:[DI],0
	JNZ	FIND1
	STC					; INDICATE NOT FOUND
	return

COUNT0:
	PUSH	DS
	POP	ES
	MOV	DI,SI

COUNT1:
	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL "="
	CALL	SCASB1
	JMP	SHORT COUNTX

COUNT2:
	PUSH	DI				; COUNT NUMBER OF CHARS UNTIL NUL
	CALL	SCASB2

COUNTX:
	POP	CX
	SUB	DI,CX
	XCHG	DI,CX
	return

MOVE_NAME:
	CMP	BYTE PTR DS:[SI],13
	retz
	LODSB

;;;;	IFDEF	DBCS			3/3/KK
	CALL	TESTKANJ
	JZ	NOTKANJ1
	STOSB
	LODSB
	STOSB
	JMP	SHORT MOVE_NAME

NOTKANJ1:
;;;;	ENDIF				3/3/KK

	CALL	UPCONV
	STOSB
	CMP	AL,'='
	JNZ	MOVE_NAME
	return

GETARG:
	MOV	SI,SIZE argv_ele
	ADD	SI,OFFSET TRANGROUP:arg
	MOV	SI,[SI].arg_ocomptr		; Original argument text
	MOV	AX,arg.argvcnt
	DEC	AX				; Exclude the command name
	OR	AL,AL
	retz
	invoke	SCANOFF
	CMP	AL,13
	return

;
; Point ES:DI to the final NULL string.  Note that in an empty environment,
; there is NO double NULL, merely a string that is empty.
;
SCAN_DOUBLE_NULL:
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP
	MOV	ES,[ENVIRSEG]
ASSUME	ES:NOTHING
	XOR	DI,DI
;
; Top cycle-point.  If the string here is empty, then we are done
;
SDN1:
	cmp	byte ptr es:[di],0		; nul string?
	retz					; yep, all done
	CALL	SCASB2
	JMP	SDN1

SCASB1:
	MOV	AL,'='                          ; SCAN FOR AN =
	JMP	SHORT SCASBX
SCASB2:
	XOR	AL,AL				; SCAN FOR A NUL
SCASBX:
	MOV	CX,414H				; Maximum environment string length
	REPNZ	SCASB
	return
;Bugbug: This is Kanji stuff - put it in conditionals

TESTKANJ:
	push	ds				;AN000;  3/3/KK
	push	si				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	mov	ds,cs:[resseg]			;AN000;  Get resident segment
	assume	ds:resgroup			;AN000;
	lds	si,dbcs_vector_addr		;AN000;  get DBCS vector
ktlop:						;AN000;  3/3/KK
	cmp	word ptr ds:[si],0		;AN000;  end of Table	3/3/KK
	je	notlead 			;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	push	ax				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jb	notlead 			;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	cmp	al, byte ptr ds:[si]		;AN000;  3/3/KK
	jbe	islead				;AN000;  3/3/KK
	inc	si				;AN000;  3/3/KK
	jmp	short ktlop			;AN000;  try another range ; 3/3/KK
Notlead:					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  set zero 3/3/KK
	jmp	short ktret			;AN000;  3/3/KK
Islead: 					;AN000;  3/3/KK
	xor	ax,ax				;AN000;  reset zero  3/3/KK
	inc	ax				;AN000;  3/3/KK
ktret:						;AN000;  3/3/KK
	pop	ax				;AN000;  3/3/KK
	pop	si				;AN000;  3/3/KK
	pop	ds				;AN000;  3/3/KK
	return					;AN000;  3/3/KK
;-------------------------------------		;3/3/KK


; ****************************************************************
; *
; * ROUTINE:	 UPCONV     (ADDED BY EMG 4.00)
; *
; * FUNCTION:	 This routine returns the upper case equivalent of
; *		 the character in AL from the file upper case table
; *		 in DOS if character if above  ascii 128, else
; *		 subtracts 20H if between "a" and "z".
; *
; * INPUT:	 AL	      char to be upper cased
; *		 FUCASE_ADDR  set to the file upper case table
; *
; * OUTPUT:	 AL	      upper cased character
; *
; ****************************************************************

assume	ds:trangroup				;AN000;

upconv	proc	near				;AN000;

	cmp	al,80h				;AN000;  see if char is > ascii 128
	jb	oth_fucase			;AN000;  no - upper case math
	sub	al,80h				;AN000;  only upper 128 chars in table
	push	ds				;AN000;
	push	bx				;AN000;
	mov	ds,[resseg]			;AN000;  get resident data segment
assume	ds:resgroup				;AN000;
	lds	bx,dword ptr fucase_addr+1	;AN000;  get table address
	add	bx,2				;AN000;  skip over first word
	xlat	ds:byte ptr [bx]		;AN000;  convert to upper case
	pop	bx				;AN000;
	pop	ds				;AN000;
assume	ds:trangroup				;AN000;
	jmp	short upconv_end		;AN000;  we finished - exit

oth_fucase:					;AN000;
	cmp	al,small_a			;AC000; if between "a" and "z",
	jb	upconv_end			;AC000;     subtract 20h to get
	cmp	al,small_z			;AC000;    upper case equivalent.
	ja	upconv_end			;AC000;
	sub	al,20h				;AC000; Change lower-case to upper

upconv_end:					;AN000;
	ret

upconv	endp					;AN000;


; Expand the environment to the requested size in BX.
; ES addresses the environment.  Errors are reported by CERROR.

	PUBLIC	ResizeEnvironment
ResizeEnvironment PROC NEAR
	PUSH	AX
	PUSH	CX
	PUSH	ES
	PUSH	BX
	invoke	FREE_TPA
	POP	BX
	PUSH	BX
	ADD	BX,2				; Include the final double null
	CMP	BX, 8000H			; Don't let environment grow > 32K
	JB	SHORT ResizeEnvCheck
ResizeEnvFail:
	STC
	JMP	SHORT ResizeEnvRestore
ResizeEnvCheck:
	MOV	CL,4
	SHR	BX,CL				; Convert back to paragraphs
	MOV	AX,CS
	MOV	CX,ES
	CMP	CX,AX
	JA	SHORT ResizeEnvSet
	ADD	CX,BX
	ADD	CX,20H				; Leave room for the TPA
	CMP	CX,AX
	JNB	SHORT ResizeEnvFail
ResizeEnvSet:
	MOV	AH,SETBLOCK
	INT	21h
ResizeEnvRestore:
	PUSHF
	PUSH	ES
	MOV	ES,[RESSEG]
	invoke	ALLOC_TPA
	POP	ES
	POPF
	JNC	SHORT ResizeEnvDone
	PUSH	DS
	POP	ES
	MOV	DX,OFFSET TRANGROUP:ENVERR_PTR
	JMP	CERROR
ResizeEnvDone:
	POP	BX
	POP	ES
	POP	CX
	POP	AX
	RET
ResizeEnvironment ENDP

GETENVSIZ:
;Get size of environment in bytes, rounded up to paragraph boundry
;ES has environment segment
;Size returned in CX, all other registers preserved

	PUSH	ES
	PUSH	AX
	MOV	AX,ES
	DEC	AX				;Point at arena
	MOV	ES,AX
	MOV	AX,ES:[arena_size]
	MOV	CL,4
	SHL	AX,CL				;Convert to bytes
	MOV	CX,AX
	POP	AX
	POP	ES
	return


ASSUME	DS:TRANGROUP


RESTUDIR1:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	CMP	[RESTDIR],0
	POP	DS
ASSUME	DS:TRANGROUP
	retz

RESTUDIR:
	MOV	DX,OFFSET TRANGROUP:USERDIR1
	MOV	AX,PathChdirFunction
	INT	21h			; Restore users DIR
	XOR	AL,AL
	invoke	SETREST
RET56:
	return

trancode    ends
	    end
