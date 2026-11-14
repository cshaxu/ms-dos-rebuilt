	page ,132
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;
;M031	SR 10/11/90    Bug #3069. Use deny write sharing mode to open files
;		      	instead of compatibility mode. This gives lesser
;			sharing violations when files are opened for read on
;			a copy operation.
;
;




	.xlist
	.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include sf.inc
	include comseg.asm
	include comequ.asm
	.list
	.cref


TRANDATA	segment public byte
	extrn	FulDir_Ptr:word 	;AN052;
TRANDATA ends

TRANSPACE	segment public byte
	extrn	Ascii:byte
	extrn	Binary:byte
	extrn	Concat:byte
	extrn	DestBuf:byte
	extrn	DestFcb:byte
	extrn	DestInfo:byte
	extrn	DestIsDir:byte
	extrn	DestTail:word
	extrn	DestVars:byte
	extrn	CopySourceOpenFunction:word,CopyDestOpenFunction:word
	extrn	CopyDestMode:byte,PathAttribFunction:word
	extrn	CopyPatternExt:word,CopySourceExt:word,DirBasePath:byte
	extrn	DirBuf:byte
	extrn	DirChar:byte
	extrn	FirstDest:byte
	extrn	Inexact:byte
	extrn	MelCopy:byte
	extrn	NxtAdd:word
	extrn	Plus:byte
	extrn	SDirBuf:byte
	extrn	SrcInfo:byte
	extrn	SrcXName:byte
	extrn	Tpa:word
	extrn	TrgXName:byte
	extrn	UserDir1:byte
TRANSPACE	ends

TRANCODE	segment public byte

	extrn	BadPath_Err:near	;AN022;
	extrn	CopErr:near		;AN052;
	extrn	Extend_Setup:near	;AN022;
	extrn	CopySelectPathCalls:near,CopyReturnedName:near

	public	BuildPath
	public	SetStars
	public	SetAsc

ASSUME	cs:TRANGROUP,ds:TRANGROUP,es:TRANGROUP,ss:NOTHING




;***	SetAsc - set Ascii, Binary, Inexact flags based on switches
;
;	Given switch vector in AX,
;	  Set Ascii flag if /a is set
;	  Clear Ascii flag if /b is set
;	  Binary set if /b specified
;	  Leave Ascii unchanged if neither or both are set
; 	Also sets Inexact if Ascii is ever set. 
;	AL = Ascii on exit, flags set
;

SetAsc:

	and	al,SWITCHA+SWITCHB	; AL = /a, /b flags
	jpe	LoadSw			; even parity - both or neither
	push	ax
	and	al,SWITCHB
	mov	Binary,al
	pop	ax
	and	al,SWITCHA
	mov	Ascii,al
	or	Inexact,al

LoadSw:
	mov	al,Ascii
	or	al,al
	return




;***	BuildDest

	public BuildDest

BuildDest:
	cmp	DestIsDir,-1
	jne	KnowAboutDest			; figuring already done
	mov	di,offset TRANGROUP:UserDir1
	mov	bp,offset TRANGROUP:DestVars
	mov	al,CopyDestMode
	call	CopySelectPathCalls
	call	BuildPath
	invoke	RestUDir1
KnowAboutDest:
	xor	al,al
	xchg	al,FirstDest
	or	al,al
	jnz	FirstDst
	jmp	NotFirstDest
FirstDst:
	mov	si,DestTail			
	mov	di,offset TRANGROUP:DirBasePath
bdSavePattern:
	lodsb
	stosb
	or	al,al
	jnz	bdSavePattern
	mov	ax,word ptr DestBuf		; AX = possible "d:"
	cmp	ah,':'
	je	short bdHaveDrive
	mov	al,'@'
bdHaveDrive:
	mov	cl,Ascii		; CL = saved Ascii flag
	or	al,20h
	sub	al,60h
	mov	DestFcb,al		; store drive # in FCB
	mov	al,DestInfo		; AL = destination CParse flags
	mov	ah,SrcInfo		; AH = source CParse flags
	and	ax,0202h		; AH,AL = source,dest wildcard flags
	or	al,al
	jz	NotMelCopy		; no destination wildcard
	cmp	al,ah
	jne	NotMelCopy		; no source wildcard
	cmp	Plus,0
	je	NotMelCopy		; no +'s in source
	inc	MelCopy			; 'Mel copy' = true
	xor	al,al
	jmp	short SetConc
NotMelCopy:
	xor	al,2		; AL=0 -> ambiguous destination, 2 otherwise
	and	al,ah
	shr	al,1		; AL=1 -> ambiguous source, unambiguous dest
				;   (implies concatenation)
SetConc:
	or	al,Plus		; "+" always infers concatenation
	mov	Concat,al
	shl	al,1
	shl	al,1
	mov	Inexact,al		; concatenation -> inexact copy
	cmp	Binary,0
	jne	NotFirstDest
	or	cl,cl
	jnz	NotFirstDest		; Ascii flag set before, data read correctly
	mov	Ascii,al
	or	al,al
	jz	NotFirstDest		; Ascii flag did not change state
	mov	cx,NxtAdd
	jcxz	NotFirstDest		; no data, everything ok
	mov	al,1Ah
	push	es
	xor	di,di
	mov	es,Tpa
	repne	scasb			; scan for EOF
	pop	es
	jne	NotFirstDest
	dec	di
	mov	NxtAdd,di		; new buffer length
NOTFIRSTDEST:
	invoke	CopyReturnedName
	mov	bx,si
	cmp	CONCAT,0
	jz	short bdNameSource
	mov	bx,offset TRANGROUP:SDirBuf
bdNameSource:
	mov	si,offset TRANGROUP:DirBasePath
	mov	di,DESTTAIL			; Where to put result
	public	CopyMakeTargetName
CopyMakeTargetName:
	call	CopySplitExtensions
	call	BuildName
	mov	si,CopyPatternExt
	or	si,si
	jz	short bdNameDone
	mov	al,'.'
	mov	[si-1],al
	stosb
	mov	bx,CopySourceExt
	call	BuildName
bdNameDone:
	xor	al,al
	stosb
	mov	bx,CopySourceExt
	or	bx,bx
	jz	short bdReturn
	mov	byte ptr [bx-1],'.'
bdReturn:
	return

; Substitute source characters into one part of the destination pattern.
public buildname
BUILDNAME:
bnNext:
	lodsb
	or	al,al
	jz	bnReturn
	cmp	al,'*'
	jz	short bnStar
	cmp	al,'?'
	jz	short bnQuestion
	stosb
	or	bx,bx
	jz	bnNext
	cmp	byte ptr [bx],0
	jz	bnNext
	inc	bx
	jmp	short bnNext
bnQuestion:
	or	bx,bx
	jz	bnNext
	cmp	byte ptr [bx],0
	jz	bnNext
	mov	al,[bx]
	stosb
	inc	bx
	jmp	short bnNext
bnStar:
	or	bx,bx
	jz	bnReturn
	mov	si,bx
	jmp	short bnNext
bnReturn:
	return

; Temporarily separate the final extensions of the pattern and source.
CopySplitExtensions:
	push	si
	push	dx
	call	CopySplitExtension
	mov	CopyPatternExt,dx
	mov	si,bx
	call	CopySplitExtension
	mov	CopySourceExt,dx
	pop	dx
	pop	si
	return
CopySplitExtension:
	xor	dx,dx
cseNext:
	lodsb
	or	al,al
	jz	cseFound
	cmp	al,'.'
	jnz	cseNext
	mov	dx,si
	jmp	short cseNext
cseFound:
	mov	si,dx
	or	si,si
	jz	cseReturn
	mov	byte ptr [si-1],0
cseReturn:
	return


BUILDPATH:
	test	[BP.INFO],2
	jnz	NOTPFILE			; If ambig don't bother with open
	mov	dx,bp
	add	dx,BUF
	push	di				;AN000;
	mov	ax,CopySourceOpenFunction
	cmp	bp,offset TRANGROUP:DestVars
	jnz	short bpOpen
	mov	ax,CopyDestOpenFunction
bpOpen:
	mov	bx,DENY_NONE or READ_OPEN_MODE	; open mode for COPY ;M046
	xor	cx,cx				;AN000; no special files
	mov	si,dx
	mov	dx,read_open_flag		;AN000; set up open flags
	int	21h
	pop	di				;AN000;
	jnc	pure_file			;AN022; is pure file
	invoke	get_ext_error_number
	cmp	ax,error_file_not_found 	;AN022; if file not found - okay
	jz	NOTPFILE
	cmp	ax,error_path_not_found
	jz	NOTPFILE
	cmp	ax,error_access_denied
	jz	NOTPFILE
	jmp	Extend_Setup

pure_file:
	mov	bx,ax				; Is pure file
	mov	ax,IOCTL SHL 8
	int	21h
	mov	ah,CLOSE
	int	21h
	test	dl,devid_ISDEV
	jnz	ISADEV				; If device, done
	test	[BP.INFO],4
	jz	ISSIMPFILE			; If no path seps, done

NOTPFILE:
	mov	dx,bp
	add	dx,BUF
	mov	bh,[BP.INFO]
	and	bh,6
	cmp	bh,6				; Ambig and path ?
	jnz	CHECKAMB			; jmp if no
	mov	si,[BP.TTAIL]
	mov	bl,':'
	cmp	byte ptr [si-2],bl
	jnz	KNOWNOTSPEC
	mov	[BP.ISDIR],2
	jmp	short DOPCDJ
KNOWNOTSPEC:
	mov	[BP.ISDIR],1
	dec	si
DOPCDJ:
	jmp	DOPCD				;AC022; need long jump

CHECKAMB:
	cmp	bh,2
	jnz	CHECKCD
ISSIMPFILE:
ISADEV:
	mov	[BP.ISDIR],0
	return

CHECKCD:
	mov	ax,PathAttribFunction
	xor	bl,bl
	int	21h
	jc	NOTPDIR
	test	cl,18h
	jz	notpdir_try			;AN022;
	mov	di,dx
	xor	ax,ax
	mov	cx,ax
	dec	cx
Kloop:						;AN000;  3/3/KK
	MOV	AL,ES:[DI]			;AN000;  3/3/KK
	inc	di
	or	al,al
	JZ	Done				;AN000;  3/3/KK
	xor	ah,ah				;AN000;  3/3/KK
	invoke	Testkanj
	JZ	Kloop				;AN000;  3/3/KK
	inc	di
	inc	ah
	jmp	Kloop				;AN000;  3/3/KK
Done:						;AN000;  3/3/KK
	dec	di
	mov	al,DIRCHAR
	mov	[bp.ISDIR],2
	OR	AH, AH				;AN000; 3/3/KK
	JNZ	Store_pchar			;AN000; 3/3/KK	 this is the trailing byte of ECS code
	cmp	al,[di-1]
	jz	GOTSRCSLSH
Store_pchar:					;AN000; 3/3/KK
	stosb
	mov	[bp.ISDIR],1
GOTSRCSLSH:
	or	[bp.INFO],6
	call	SETSTARS
bpReturn:
	return

NOTPDIR:
	invoke	get_ext_error_number
	cmp	ax,error_file_not_found 	;AN022; if file not found - okay
	jz	notpdir_try			;AN022;
	cmp	ax,error_path_not_found
	jz	notpdir_try			;AN022;
	cmp	ax,error_access_denied
	jnz	extend_setupj			;AN022; otherwise - exit error
notpdir_try:					;AN022;
	mov	[bp.ISDIR],0
	mov	bh,[bp.INFO]
	test	bh,4
	jz	bpReturn
	mov	[bp.ISDIR],2
	mov	si,[bp.TTAIL]
	cmp	byte ptr [si],0
	jz	BADCDERRJ2
	mov	bl,dot_chr
	cmp	byte ptr [si],bl
	jz	BADCDERRJ2
	mov	bl,':'
	cmp	byte ptr [si-2],bl
	jz	DOPCD				; Know d:/file
	mov	[bp.ISDIR],1
	dec	si
DOPCD:
	xor	bl,bl
	xchg	bl,[si]
	CMP	DX,SI				;AN000;  3/3/KK
	JAE	LookBack			;AN000;  3/3/KK
	PUSH	SI				;AN000;  3/3/KK
	PUSH	CX				;AN000;  3/3/KK
	MOV	CX,SI				;AN000;  3/3/KK
	mov	si,dx
Kloop2: 					;AN000;  3/3/KK
	lodsb
	invoke	TestKanj
	jz	NotKanj4			;AN000;  3/3/KK
	lodsb
	cmp	si,cx
	jb	Kloop2
	pop	cx
	pop	si
	JMP	SHORT DoCdr			;AN000;  3/3/KK  Last char is ECS code, don't check for
						;		 trailing path sep
NotKanj4:					;AN000;  3/3/KK
	cmp	si,cx
	jb	Kloop2
	pop	cx
	pop	si
LookBack:					;AN000;  3/3/KK
	CMP	BL,[SI-1]			; if double slash, then complain.
	jz	BADCDERRJ2
DoCdr:						;AN000;  3/3/KK
	xchg	bl,[si]
DonePath:
	return
EXTEND_SETUPJ:					;AN022;
	jmp	Extend_Setup
BADCDERRJ2:
	jmp	badpath_err			;AC022; go issue path not found message

SETSTARS:
	mov	[bp.TTAIL],DI
	add	[bp.SIZ],4
	mov	ax,2E2Ah
	stosw
	mov	ax,002Ah
	stosw
	return

PUBLIC CompName
COMPNAME:
	mov	si,offset trangroup:DESTBUF	;g do name translate of target
	mov	di,offset TRANGROUP:TrgXName
	mov	al,CopyDestMode
	invoke	CanonicalizePath
	jnc	short cnCompare
	or	ah,1
	jmp	short cnDone
cnCompare:
	MOV	si,offset trangroup:SRCXNAME	;g get name translate of source
	mov	di,offset TRANGROUP:TrgXName
	invoke	STRCOMP
cnDone:
	return

;*** CanonicalizePath -- Convert a pathname using the selected interface.
;
;	ENTRY	DS:SI = source, ES:DI = destination
;		AL = zero for DOS pathname conversion, nonzero for long names
;	EXIT	Carry and AX returned by DOS
;
	PUBLIC	CanonicalizePath
CanonicalizePath PROC NEAR
	MOV	AH,60H
	OR	AL,AL
	JZ	SHORT CanonicalizeCall
	MOV	AX,7160H
	MOV	CX,1
CanonicalizeCall:
	INT	21H
	RET
CanonicalizePath ENDP


TRANCODE ENDS
	 END
