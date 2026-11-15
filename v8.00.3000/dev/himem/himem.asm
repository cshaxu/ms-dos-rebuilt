;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1988-1992
; *                      All Rights Reserved.
; */
;
; Resident High Memory Manager.
;
	page	,160
	title	Extended Memory Manager

	include	bioscode.inc

Bios_Code	segment byte public 'CODE'
	.386
	assume	cs:Bios_Code,ds:nothing,es:nothing

	extrn	HandleInfo:byte
	extrn	Version:near,aQueryExtMemory:near,aAllocExtMemory:near
	extrn	aFreeExtMemory:near,LockExtMemory:near,UnlockExtMemory:near
	extrn	aGetExtMemoryInfo:near,aReallocExtMemory:near,Movext386:near

ERR_NOTIMPLEMENTED equ	80h
ERR_A20		equ	82h
ERR_HMAINUSE	equ	91h

	db	4 dup (0)
	public	PrevInt15,PrevInt2f
PrevInt15	dd	0	; Original INT 15 vector
PrevInt2f	dd	0	; Original INT 2F vector
EnableCount	dw	1	; A20 Enable/Disable counter
GlobalA20	dw	0	; Global A20 request state

;*----------------------------------------------------------------------*
;* Int2fHandler - Extended Memory Manager installation and entry query.  *
;* ARGS: AH = 43h, AL = subfunction                                    *
;* RETS: AL = 80h if installed, or ES:BX = requested address.          *
;*----------------------------------------------------------------------*

	public	Int2fHandler
Int2fHandler proc far
	cmp	ah,43h
	je	short I2fXms
I2fNextInt:
	jmp	cs:[PrevInt2f]
I2fXms:
	or	al,al
	jne	short I2fNextSub
	mov	al,80h
	iret
I2fNextSub:
	cmp	al,10h
	jne	short tryHandleInfo
	push	cs
	pop	es
	mov	bx,offset XMMControl
	iret

tryHandleInfo:
	cmp	al,09h
	jne	short I2fNextInt
	mov	al,ah
	push	cs
	pop	es
	mov	bx,offset HandleInfo
	iret
Int2fHandler endp

ControlJumpTable label word
	dw	Version
	dw	RequestHMA
	dw	RequestHMA
	dw	GlobalEnableA20
	dw	GlobalDisableA20
	dw	LocalEnableA20
	dw	LocalDisableA20
	dw	IsA20On
	dw	aQueryExtMemory
	dw	aAllocExtMemory
	dw	aFreeExtMemory
	dw	Movext386
	dw	LockExtMemory
	dw	UnlockExtMemory
	dw	aGetExtMemoryInfo
	dw	aReallocExtMemory
NumFns	=	((offset $) - (offset ControlJumpTable)) / 2
SuperFunctions	dw	0c300h
	dw	offset EnableCount
	dw	1
	db	'MS'

;*----------------------------------------------------------------------*
;* XMMControl - Main Entry point for the Extended Memory Manager.      *
;* ARGS: AH = Function, AL = optional parameter                        *
;* RETS: AX = success code, BL = optional error code                   *
;*----------------------------------------------------------------------*

	public	XMMControl
XMMControl proc far
	jmp	short XCControlEntry
	nop			; Leave room for a far jump to hook this entry.
	nop
	nop
XCControlEntry:
	push	si
	push	di
	push	cx
	push	ds
	push	es
	pushf
	cld
	push	ds
	pop	es
	push	cs
	pop	ds
	assume	ds:Bios_Code
	movzx	di,ah
	and	di,7fh
	db	81h,0ffh		; cmp di,NumFns (word immediate)
	dw	NumFns
	jae	short XCUnsupported
	test	ah,ah
	jns	short XCCallFunc
	bt	SuperFunctions,di
	jnc	short XCUnsupported
XCCallFunc:
	shl	di,1
	call	ControlJumpTable[di]
XCExit:
	popf
	pop	es
	pop	ds
	assume	ds:nothing
	pop	cx
	pop	di
	pop	si
	ret
XCUnsupported:
	xor	ax,ax
	mov	bl,ERR_NOTIMPLEMENTED
	jmp	short XCExit
XMMControl endp

; Hide extended memory from clients using the original BIOS interfaces.
	public	Int15Handler
Int15Handler proc far
	cmp	ah,88h
	je	short I15NoMemory
	cmp	ax,0e801h
	je	short I15NoExtMemory
	cmp	ah,87h
	je	short I15Move
	jmp	cs:[PrevInt15]
I15NoExtMemory:
	xor	bx,bx
I15NoMemory:
	xor	ax,ax
	iret
I15Move:
	cli
	hlt
	jmp	short I15Move
Int15Handler endp

	assume	ds:Bios_Code
RequestHMA proc near
	mov	bl,ERR_HMAINUSE
	xor	ax,ax
	ret
RequestHMA endp

GlobalEnableA20 proc near
	cli
	cmp	GlobalA20,1
	je	short GEnableDone
	call	LocalEnableA20
	or	ax,ax
	jz	short GEnableError
	mov	GlobalA20,1
GEnableDone:
	mov	ax,1
	xor	bl,bl
	ret
GEnableError:
	mov	bl,ERR_A20
	xor	ax,ax
	ret
GlobalEnableA20 endp

GlobalDisableA20 proc near
	cli
	cmp	GlobalA20,0
	je	short GDisableDone
	call	LocalDisableA20
	or	ax,ax
	jz	short GDisableError
	mov	GlobalA20,0
GDisableDone:
	mov	ax,1
	xor	bl,bl
	ret
GDisableError:
	mov	bl,ERR_A20
	xor	ax,ax
	ret
GlobalDisableA20 endp

LocalEnableA20 proc near
	cli
	inc	EnableCount
	mov	ax,1
	xor	bl,bl
	ret
LocalEnableA20 endp

LocalDisableA20 proc near
	cli
	cmp	EnableCount,0
	je	short LDisableError
	dec	EnableCount
	mov	ax,1
	xor	bl,bl
LDisableDone:
	ret
LDisableError:
	mov	bl,ERR_A20
	xor	ax,ax
	jmp	short LDisableDone
LocalDisableA20 endp

IsA20On proc near
	mov	ax,1
	xor	bl,bl
	ret
IsA20On endp

Bios_Code	ends
	end
