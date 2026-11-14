	page ,132
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */
;	SCCSID = @(#)cparse.asm 1.1 85/05/14
;	SCCSID = @(#)cparse.asm 1.1 85/05/14
	INCLUDE comsw.asm

.xlist
.xcref
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	INCLUDE comseg.asm
	INCLUDE comequ.asm
.list
.cref


TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BADCD_PTR:WORD		;AC022;
	EXTRN	BADCPMES_ptr:word	;AC000;
	EXTRN	CParseSwitchList:BYTE
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	comma:byte
	EXTRN	cpyflag:byte
	EXTRN	CURDRV:BYTE
	EXTRN	ELCNT:BYTE
	EXTRN	ELPOS:BYTE
	EXTRN	EXPAND_STAR:BYTE
	EXTRN	SKPDEL:BYTE
	EXTRN	STARTEL:WORD
	EXTRN	SWITCHAR:BYTE
	EXTRN	switch_list:byte
	EXTRN	TPA:WORD
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:TRANGROUP,ES:TRANGROUP,SS:NOTHING

	EXTRN	CERROR:NEAR

	PUBLIC	BADCDERR		;AC022;
	PUBLIC	CPARSE

SWCOUNT EQU	8			; Must agree with length of switch_list

;-----------------------------------------------------------------------;
; ENTRY:								;
;	DS:SI	Points input buffer					;
;	ES:DI	Points to the token buffer				;
;	BL	Special delimiter for this call 			;
;		    Always checked last 				;
;		    set it to space if there is no special delimiter	;
; EXIT: 								;
;	DS:SI	Points to next char in the input buffer 		;
;	ES:DI	Points to the token buffer				;
;	[STARTEL] Points to start of last element of path in token	;
;		points to a NUL for no element strings 'd:' 'd:/'       ;
;	CX	Character count 					;
;	BH	Condition Code						;
;			Bit 1H of BH set if switch character		;
;				Token buffer contains the complete	;
;				switch, including the switch character	;
;				BP has switch bits set (ORing only)	;
;			Bit 2H of BH set if ? or * in token		;
;				* expanded only when EXPAND_STAR is set	;
;			Bit 4H of BH set if path sep in token		;
;			Bit 20H of BH set inside quotes			;
;			Bit 40H of BH set for a wildcard suffix		;
;			Bit 80H of BH set if the special delimiter	;
;			   was skipped at the start of this token	;
;		Rooted paths receive d: except for UNC names		;
;	CARRY SET							;
;	    if CR or NUL on input, or a malformed switch token		;
;		token buffer not altered on CR or NUL				;
;									;
;	DOES NOT RETURN ON BAD PATH				;
; MODIFIES:								;
;	CX, SI, AX, BH, DX and the Carry Flag				;	;
;									;
; -----------------------------------------------------------------------;
;---------------
; Modifications to cparse:  recognition of right and left parentheses
; as integral tokens, and removal of automatic upper-case conversion code.
;
; Both modifications were installed in the course of adding a coherent
; command-line parser to COMMAND.COM which builds a UNIX-style argv[]/argc
; structure for command-line arguments.  This parser relies on cparse to
; recognize individual tokens.
;
; To process for-loops correctly, parentheses must therefore be
; recognized as tokens.  The upper-case conversion code was removed so
; that commands (such as for and echo) would be able to use the "original"
; text of the command line.
;
; Note also the modification to prevent the automatic conversion of colons
; into spaces WITHIN THE SOURCE TEXT!
;
; Also note that BP is also clobbered if cparse recognizes any switches
; on the command line.
;
; Alan L, OS/MSDOS				    14 August 1983
;---------------

CPARSE:
ASSUME	DS:TRANGROUP,ES:TRANGROUP

	xor	ax,ax
	mov	[STARTEL],DI			; No path element (Is DI correct?)
	mov	[ELPOS],al			; Start in 8 char prefix
	mov	[SKPDEL],al			; No skip delimiter yet
	mov	bh,al				; Init nothing
	pushf					; save flags
	push	di				; save the token buffer addrss
	xor	cx,cx				; no chars in token buffer
	mov	comma,cl			;g reset comma flag
moredelim:
	LODSB
	INVOKE	DELIM
	JNZ	SCANCDONE
	CMP	AL,' '
	JZ	moredelim
	CMP	AL,9
	JZ	moredelim
	xchg	al,[SKPDEL]
	or	al,al
	jz	moredelim			; One non space/tab delimiter allowed
	test	bh,080h 			;g  has a special char been found?
	jz	no_comma			;g  no - just exit
	mov	comma,1 			;g  set comma flag
no_comma:
	JMP	x_done				; Nul argument

SCANCDONE:

;;;;	IFNDEF	DBCS	3/3/KK
;---------------
; Mod to avoid upper-case conversion.
;	cmp	cpyflag,1		3/3/KK
;	jnz	cpcont1 		3/3/KK
;	invoke	UPCONV			3/3/KK
cpcont1:
;---------------
;;;;	ENDIF			3/3/KK

	cmp	al,bl				; Special delimiter?
	jnz	nospec
	or	bh,80H
	jmp	short moredelim

nospec:
	cmp	al,0DH				; a CR?
	jne	cpCheckNul
cpEndOfLine:
	jmp	cperror
cpCheckNul:
	or	al,al				; ASCIIZ input ended?
	jz	cpEndOfLine

ncperror:
	cmp	al,[SWITCHAR]			; is the char the switch char?
	jne	na_switch			; yes, process...
	jmp	a_switch

na_switch:
	cmp	al,'"'				; quoted argument?
	jne	short cpDrive
	xor	bh,20h
	lodsb
	jmp	short nospec
cpDrive:
	mov	dl,':'
	cmp	byte ptr [si],dl
	jne	anum_chard			; Drive not specified

	call	move_char
	lodsb					; Get the ':'
	call	move_char
	mov	[STARTEL],di
	mov	[ELCNT],0
	jmp	anum_test

anum_chard:
	mov	[STARTEL],di
	mov	[ELCNT],0			; Store of this char sets it to one
	cmp	cpyflag,1			; Was CPARSE called from COPY?
	jnz	anum_char			; No, don't add drive spec.
	invoke	PATHCHRCMP			; Starts with a pathchar?
	jnz	anum_char			; no
	push	ax
	mov	al,[si]
	invoke	PATHCHRCMP			; UNC path?
	pop	ax
	jz	anum_char			; do not add a drive
	push	ax
	mov	al,[CURDRV]			; Insert drive spec
	add	al,capital_A
	call	move_char
	mov	al,':'
	call	move_char
	pop	ax
	mov	[STARTEL],di
	mov	[ELCNT],0

anum_char:

;;;;	IFDEF	DBCS		3/3/KK
	invoke	TESTKANJ
	jz	NOTKANJ 			;AC048;
	call	move_char
	lodsb
	jmp	short notspecial
	nop

NOTKANJ:					;AN048; If not kanji
	cmp	al,'"'
	jne	short TESTDOT
	xor	bh,20h
	jmp	short anum_char
TESTDOT:
;;;;	ENDIF			3/3/KK

	cmp	al,dot_chr
	jnz	testquest
	inc	[ELPOS] 			; flag in extension
	mov	[ELCNT],0FFH			; Store of the '.' resets it to 0

testquest:
	cmp	al,'?'
	jnz	testsplat
	or	bh,2

testsplat:
	cmp	al,star
	jnz	testpath
	or	bh,2
	cmp	byte ptr [expand_star],0
	jnz	expand_filename
	call	CParseStarSuffix
	jmp	SHORT testpath

badperr2j:
	jmp	badperr2

expand_filename:
	mov	ah,7
	cmp	[ELPOS],0
	jz	gotelcnt
	mov	ah,2

gotelcnt:
	mov	al,'?'
	sub	ah,[ELCNT]
	jc	badperr2j
	xchg	ah,cl
	jcxz	testpathx

qmove:
	xchg	ah,cl
	call	move_char
	xchg	ah,cl
	loop	qmove

testpathx:
	xchg	ah,cl

testpath:
	invoke	PATHCHRCMP
	jnz	notspecial
	or	bh,4
	cmp	byte ptr [expand_star],0
	jz	no_err_check
	test	bh,2				; If just hit a '/', cannot have ? or * yet
	jnz	badperr

no_err_check:
	mov	[STARTEL],di			; New element
	INC	[STARTEL]			; Point to char after /
	mov	[ELCNT],0FFH			; Store of '/' sets it to 0
	mov	[ELPOS],0

notspecial:
	call	move_char			; just an alphanum string
anum_test:
	lodsb
	cmp	al,'"'				; quote toggles delimiter handling
	jne	short cpDelimiter
	xor	bh,20h
	jmp	short anum_test
cpDelimiter:
	call	QuoteDelim
	je	x_done
	test	bh,20h
	jnz	short cpQuoted
	cmp	al,[SWITCHAR]
	je	x_done
	cmp	al,bl
	je	x_done
cpQuoted:
	cmp	al,':'
	je	short cpColon
	cmp	al,0DH
	je	x_done
	or	al,al
	je	x_done
	jmp	anum_char
cpColon:
	test	cpyflag,2
	jz	short cpColonCheck
cpKeepColon:
	call	move_char
	jmp	short anum_test
cpColonCheck:
	test	bh,10h
	jnz	cpKeepColon
	inc	si
	jmp	short x_done

anum_charj:
	jmp	anum_char

badperr2:
	mov	dx,offset trangroup:BADCPMES_ptr
	jmp	CERROR

badperr:
BADCDERR:					;AC022; Issue "Invalid Directory"
	MOV	DX,OFFSET TRANGROUP:BADCD_ptr	;AC022;     message
	JMP	CERROR				;AC022;

a_switch:
	OR	BH,1				; Indicate switch
	OR	BP,fSwitch
	call	CParseSwitch
	jnc	cp_finish

cperror:
	dec	si				; adjust the pointer
	pop	di				; restore token buffer address
	popf					; restore flags
	stc					; set the carry bit
	return

x_done:
	mov	al,0
	stosb					; null at the end
	dec	si				; adjust for next round
cp_finish:
	pop	di			; restore token buffer pointer
	popf
	clc				; clear carry flag
	return

; Alternate token exits present after the normal parser return.
cpStoreChar:
	jmp	short notspecial
cpQuoteChar:
	lodsb
	xor	bh,20h
	jmp	short notspecial
cpEndSpecial:
	or	bh,8
	jmp	short x_done

move_char:
	stosb				; store char in token buffer
	inc	cx			; increment char count
	inc	[ELCNT] 		; increment element count for * substi
	return


; Copy and classify a complete switch token.
; DS:SI follows the switch character; ES:DI is the token buffer.
	PUBLIC	CParseSwitch
CParseSwitch PROC NEAR
	push	bx
	push	si
	INVOKE	SCANOFF
	mov	bx,si
	pop	si
	cmp	bx,si
	pop	bx
	push	ds
	push	es
	push	di
	pushf
	xor	cx,cx
	mov	al,[SWITCHAR]
	call	move_char
	popf
	jnz	short cpsBad
	cmp	al,0DH
	jz	short cpsBad
	cmp	al,bl
	jz	short cpsBad
	or	al,al
	jz	short cpsBad
cpsNext:
	lodsb
	INVOKE	TESTKANJ
	jz	short cpsSingle
	call	move_char
	lodsb
	call	move_char
	jmp	short cpsNext
cpsSingle:
	INVOKE	DELIM
	jz	short cpsDone
	cmp	al,0DH
	jz	short cpsDone
	cmp	al,[SWITCHAR]
	jz	short cpsDone
	or	al,al
	jz	short cpsDone
	cmp	al,bl
	jz	short cpsDone
	INVOKE	UPCONV
	call	move_char
	jmp	short cpsNext
cpsDone:
	dec	si
	mov	byte ptr es:[di],0
	sub	di,cx
	push	si
	push	cx
	push	es
	pop	ds
	mov	si,di
	inc	si
	push	cs
	pop	es
	mov	di,offset TRANGROUP:CParseSwitchList
	mov	cx,11
	call	CParseMatchSwitch
	or	ax,ax
	jz	short cpsNotRecognized
	or	bp,ax
	and	bp,not fBadSwitch
cpsUnknown:
	pop	cx
	pop	si
cpsReturn:
	pop	di
	pop	es
	pop	ds
	ret
cpsBad:
	mov	byte ptr es:[di],0
	stc
	or	bp,fBadSwitch
	jmp	short cpsReturn
cpsNotRecognized:
	jmp	short cpsUnknown
CParseSwitch ENDP

;*** QuoteDelim -- Test a delimiter outside a quoted argument.
;
;	ENTRY	AL = character, BH bit 5 = quote state
;	EXIT	Zero set for a delimiter outside quotes
;
	PUBLIC	QuoteDelim
QuoteDelim PROC NEAR
	TEST	BH,20H
	JNZ	SHORT QuoteDelimDone
	INVOKE	DELIM
QuoteDelimDone:
	RET
QuoteDelim ENDP

; Match an ASCIIZ switch against the counted switch definitions.
; DS:SI addresses the switch, ES:DI addresses CX definitions.
	PUBLIC	CParseMatchSwitch
CParseMatchSwitch PROC NEAR
	push	cx
cpmsNext:
	push	cx
	push	si
	mov	cl,es:[di]
	inc	di
	xor	ch,ch
	repe	cmpsb
	jz	short cpmsEqual
	cmp	byte ptr es:[di-1],'*'
	jz	short cpmsFound
cpmsSkip:
	add	di,cx
	pop	si
	pop	cx
	loop	cpmsNext
	xor	ax,ax
	pop	cx
	ret
cpmsEqual:
	cmp	byte ptr [si],0
	jnz	short cpmsSkip
cpmsFound:
	pop	si
	pop	cx
	mov	ax,cx
	pop	cx
	sub	cx,ax
	mov	ax,1
	shl	ax,cl
	ret
CParseMatchSwitch ENDP

; Record a character following a wildcard within the same name.
	PUBLIC	CParseStarSuffix
CParseStarSuffix PROC NEAR
	push	ax
	mov	al,[si]
	INVOKE	DELIM
	jz	short cpssDone
	INVOKE	PATHCHRCMP
	jz	short cpssDone
	cmp	al,'.'
	jz	short cpssDone
	cmp	al,0DH
	jz	short cpssDone
	cmp	al,[SWITCHAR]
	jz	short cpssDone
	cmp	al,bl
	jz	short cpssDone
	cmp	al,'"'
	jz	short cpssDone
	or	bh,40h
cpssDone:
	pop	ax
	ret
CParseStarSuffix ENDP

TRANCODE	ENDS
	END
