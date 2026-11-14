	page	,132
	title	Calculate Compression Ratio Routines
;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1992
; *                      All Rights Reserved.
; */


;***	SYMBOLS & MACROS

	.xlist
	.xcref

	include version.inc

ifdef dblspace_hooks
	include dossym.inc	; get DOS basic symbol set
	include syscall.inc	; get DOS call names
	include	comseg.asm	; define segment order
	include comequ.asm	; get equates for COMMAND routines
	include magicdrv.inc	; for MagivDrv (compression ratio) support

	.list
	.cref

TRANSPACE segment public byte
	extrn	csecPerCluster:byte	; sectors/cluster for ratio calculation
        extrn   DirCompressionMask:dword
        extrn   DirCompressionShift:byte
TRANSPACE ends

TRANCODE segment public byte
	assume	cs:TRANGROUP,ds:TRANGROUP,es:nothing,ss:TRANGROUP

;***	ComputeRatio - calculate ratio of compressed sectors used to
;		       (would be) DOS sectors used
;
;	Entry
;		AX = DOS clusters used, cx:bx = compressed sectors used
;	Exit
;		AX = packed ratio (whole number shifted left 4 bits, low nibble = tenths)
;
;	Used	BX, CX, DX
;
	public	ComputeRatio

ComputeRatio	proc

	push	si
	push	di

	mov	si, bx
	mov	di, cx			; save cx:bx in di:si

	mov	bl, csecPerCluster
	xor	bh, bh
	mul	bx			; dx:ax = # DOS sectors used
	mov	bx, si			; restore bx

	call	Div32			; dx:ax = quotient, cx:bx = remainder

	push	ax			; save quotient

	mov	ax, bx			; if no remainder, tenths will be 0
	or	ax, cx			;   which is in AX so skip following
	jz	cr_got_tenths		;   (happens frequently)

	; Multiply the reminder by 10, add half the divisor so result is
	; rounded up, and divide again to get tenths digit

	mov	ax, cx
	xor	dx, dx
	mov	cx, bx
	mov	bx, 10
	mul	bx
	xchg	ax, cx
	mul	bx
	add	dx, cx			; dx:ax = remainder * 10

	mov	cx, di
	mov	bx, si
	shr	cx, 1
	rcr	bx, 1			; cx:bx = 1/2 divisor
	add	ax, bx
	adc	dx, cx			; dx:ax = remainder * 10 + 1/2 divisor

	mov	cx, di
	mov	bx, si

	call	Div32

cr_got_tenths:
	pop	bx			; original quotient
	cmp	ax,10
	jb	short cr_pack
	inc	bx
	xor	ax,ax
cr_pack:
	mov	cl,4
	shl	bx,cl
	or	ax,bx

cr_exit:
	pop	di
	pop	si

	ret

ComputeRatio	endp



;***	Div32 - 32 bit divide for computing ratios
;
;	Entry	DX:AX = dividend, CX:BX = divisor
;
;	Exit	DX:AX = quotient, CX:BX = reminder

Div32	proc

	jcxz	d32_16bit		; differently if 16bit divisor
	.386
	shl	eax,16
	shrd	eax,edx,16
	shl	ebx,16
	shrd	ebx,ecx,16
	sub	edx,edx
	div	ebx
	mov	bx,dx
	shld	ecx,edx,16
	shld	edx,eax,16
	ret
d32_16bit:
	div	bx			; divide dx:ax by bx

	mov	bx, dx			; remainder to cx:bx
	xor	dx, dx			; quotient to dx:ax
	mov	cx, dx
	ret

Div32	endp


; Round logical bytes to the selected compression cluster count.
	public	DirRoundCompressionClusters
DirRoundCompressionClusters proc near
	push	bx
	add	ax,word ptr DirCompressionMask
	adc	dx,word ptr DirCompressionMask+2
	mov	cl,DirCompressionShift
	cmp	cl,16
	jb	short drccShift
	mov	ax,dx
	xor	dx,dx
	and	cl,0Fh
drccShift:
	mov	bx,dx
	shr	ax,cl
	shr	dx,cl
	add	cl,0F0h
	neg	cl
	shl	bx,cl
	or	ax,bx
	pop	bx
	ret
DirRoundCompressionClusters endp

TRANCODE ends

endif           ;dblspace_hooks
	end
