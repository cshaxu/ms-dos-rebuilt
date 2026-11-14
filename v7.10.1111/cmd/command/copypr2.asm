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
	jne	KnowAboutDest
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
	mov	ax,word ptr DestBuf
	cmp	ah,':'
	je	short bdHaveDrive
	mov	al,'@'
bdHaveDrive:
	mov	cl,Ascii
	or	al,20h
	sub	al,60h
	mov	DestFcb,al
	mov	al,DestInfo
	mov	ah,SrcInfo
	and	ax,0202h
	or	al,al
	jz	NotMelCopy
	cmp	al,ah
	jne	NotMelCopy
	cmp	Plus,0
	je	NotMelCopy
	inc	MelCopy
	xor	al,al
	jmp	short SetConc
NotMelCopy:
	xor	al,2
	and	al,ah
	shr	al,1
SetConc:
	or	al,Plus
	mov	Concat,al
	shl	al,1
	shl	al,1
	mov	Inexact,al
	cmp	Binary,0
	jne	NotFirstDest
	or	cl,cl
	jnz	NotFirstDest
	mov	Ascii,al
	or	al,al
	jz	NotFirstDest
	mov	cx,NxtAdd
	jcxz	NotFirstDest
	mov	al,1Ah
	push	es
	xor	di,di
	mov	es,Tpa
	repne	scasb
	pop	es
	jne	NotFirstDest
	dec	di
	mov	NxtAdd,di
NotFirstDest:
	invoke	CopyReturnedName
	mov	bx,si
	cmp	Concat,0
	jz	short bdNameSource
	mov	bx,offset TRANGROUP:SDirBuf
bdNameSource:
	mov	si,offset TRANGROUP:DirBasePath
	mov	di,DestTail
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
	public	BuildName
BuildName:
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
	jnz	NOTPFILE
	mov	dx,bp
	add	dx,BUF
	mov	bx,1000h or DENY_NONE or READ_OPEN_MODE
	mov	si,dx
bpRetryOpen:
	push	di
	mov	ax,CopySourceOpenFunction
	cmp	bp,offset TRANGROUP:DestVars
	jnz	short bpOpen
	mov	ax,CopyDestOpenFunction
bpOpen:
	xor	cx,cx
	mov	dx,READ_OPEN_FLAG
	int	21h
	pop	di
	jnc	pure_file
	test	bx,1000h
	jz	short bpOpenError
	cmp	ax,ERROR_INVALID_FUNCTION
	jnz	short bpOpenError
	mov	bx,DENY_NONE or READ_OPEN_MODE
	jmp	short bpRetryOpen
bpOpenError:
	invoke	get_ext_error_number
	cmp	ax,error_file_not_found
	jz	NOTPFILE
	cmp	ax,error_path_not_found
	jz	NOTPFILE
	cmp	ax,error_access_denied
	jz	NOTPFILE
	jmp	Extend_Setup

pure_file:
	mov	bx,ax
	mov	ax,IOCTL shl 8
	int	21h
	mov	ah,CLOSE
	int	21h
	test	dl,devid_ISDEV
	jnz	ISADEV
	test	[BP.INFO],4
	jz	ISSIMPFILE

NOTPFILE:
	mov	dx,bp
	add	dx,BUF
	mov	bh,[BP.INFO]
	and	bh,6
	cmp	bh,6
	jnz	CHECKAMB
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
	jmp	DOPCD

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
	jz	notpdir_try
	mov	di,dx
	xor	ax,ax
	mov	cx,ax
	dec	cx
Kloop:
	mov	al,es:[di]
	inc	di
	or	al,al
	jz	Done
	xor	ah,ah
	invoke	Testkanj
	jz	Kloop
	inc	di
	inc	ah
	jmp	Kloop
Done:
	dec	di
	mov	al,DirChar
	mov	[bp.ISDIR],2
	or	ah,ah
	jnz	Store_pchar
	cmp	al,[di-1]
	jz	GOTSRCSLSH
Store_pchar:
	stosb
	mov	[bp.ISDIR],1
GOTSRCSLSH:
	or	[bp.INFO],6
	call	SETSTARS
bpReturn:
	return

NOTPDIR:
	invoke	get_ext_error_number
	cmp	ax,error_file_not_found
	jz	notpdir_try
	cmp	ax,error_path_not_found
	jz	notpdir_try
	cmp	ax,error_access_denied
	jnz	EXTEND_SETUPJ
notpdir_try:
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
	jz	DOPCD
	mov	[bp.ISDIR],1
	dec	si
DOPCD:
	xor	bl,bl
	xchg	bl,[si]
	cmp	dx,si
	jae	LookBack
	push	si
	push	cx
	mov	cx,si
	mov	si,dx
Kloop2:
	lodsb
	invoke	TestKanj
	jz	NotKanj4
	lodsb
	cmp	si,cx
	jb	Kloop2
	pop	cx
	pop	si
	jmp	short DoCdr
NotKanj4:
	cmp	si,cx
	jb	Kloop2
	pop	cx
	pop	si
LookBack:
	cmp	bl,[si-1]
	jz	BADCDERRJ2
DoCdr:
	xchg	bl,[si]
DonePath:
	return
EXTEND_SETUPJ:
	jmp	Extend_Setup
BADCDERRJ2:
	jmp	BadPath_Err

SETSTARS:
	mov	[bp.TTAIL],di
	add	[bp.SIZ],4
	mov	ax,2E2Ah
	stosw
	mov	ax,002Ah
	stosw
	return

PUBLIC CompName
COMPNAME:
	mov	si,offset TRANGROUP:DestBuf
	mov	di,offset TRANGROUP:TrgXName
	mov	al,CopyDestMode
	invoke	CanonicalizePath
	jnc	short cnCompare
	or	ah,1
	jmp	short cnDone
cnCompare:
	mov	si,offset TRANGROUP:SrcXName
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