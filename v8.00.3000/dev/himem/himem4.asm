;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1988-1992
; *                      All Rights Reserved.
; */
	page	95,160
	title	himem4 - block allocation stuff (common to both 286&386)

	include	himem.inc

	include	bioscode.inc

Bios_Code	segment byte public 'CODE'
	.386
	assume	cs:Bios_Code,ds:Bios_Code

	public	HandleInfo,cHandles,KiddValley,KiddValleyTop
	public	Version,LockExtMemory,UnlockExtMemory,ValidateHandle

HandleTable	Handle	DEFHANDLES dup (<0,0,0,0>)

;-----------------------------------------------------------------
; Following entries must be kept together in the same order.

HandleInfo	label	byte
		db	1		; info structure version #
		db	SIZE Handle	; size of handle entries
cHandles	dw	DEFHANDLES	; number of handles
KiddValley	dw	offset HandleTable
segKiddValley	dw	0		; segment of handle table
KiddValleyTop	dw	0		; last handle

Version	proc	near
	mov	ax,0300h	; XMS version
	mov	bx,0363h	; driver version
	mov	dx,1		; HMA exists
	ret
Version	endp

;*----------------------------------------------------------------------*
;*									*
;*  LockExtMemory -					FUNCTION 0Ch    *
;*									*
;*	Locks a block of extended memory				*
;*									*
;*  ARGS:   DX = 16-bit handle to the extended memory block		*
;*  RETS:   AX = 1 of successful, 0 otherwise.	BL = Error code		*
;*	DX:BX = 32-bit linear address of the base of the memory block   *
;*  REGS:   AX, BX, DX and Flags clobbered				*
;*									*
;*  INTERNALLY NON-REENTRANT						*
;*									*
;*----------------------------------------------------------------------*

LockExtMemory proc near

	cli 				; This is a non-reentrant function

	call    ValidateHandle		; Is the handle valid?
	jnc     LEMBadh
	mov     bx,dx			; Move the handle into BX

;	Are we at some preposterously large limit?

	cmp	[bx].cLock,0FFh
	je	LEMOverflow

	inc	[bx].cLock		; lock the block

	mov	dx, word ptr [bx].Base+2	; return the 32-bit address of base
	mov	bx, word ptr [bx].Base

	mov	ax, bx			; save low 16 bits
	shl	dx, 10			; *1024 of hi 16 bits
	shl	bx, 10			; *1024 of low 16 bits
	shr	ax, 06			; take the overflow into account
	or	dx, ax

	mov	ax,1			; return success
	ret

LEMBadh:
	mov	bl,ERR_INVALIDHANDLE
	jmp	short LEMErrExit

LEMOverflow:
	mov	bl,ERR_LOCKOVERFLOW
LEMErrExit:
	xor     ax,ax			; Return failure
	mov	dx,ax
	ret

LockExtMemory endp


;*----------------------------------------------------------------------*
;*									*
;*  UnlockExtMemory -					FUNCTION 0Dh    *
;*									*
;*	Unlocks a block of extended memory				*
;*									*
;*  ARGS:   DX = 16-bit handle to the extended memory block		*
;*  RETS:   AX = 1 if successful, 0 otherwise.	BL = Error code		*
;*  REGS:   AX, BX and Flags clobbered					*
;*									*
;*  INTERNALLY NON-REENTRANT						*
;*									*
;*----------------------------------------------------------------------*

UnlockExtMemory proc near

	cli				; This is a non-reentrant function

	call    ValidateHandle		; Is the handle valid?
	jnc     UEMBadh
	mov	bx,dx			; Move the handle into BX

	cmp	[bx].cLock,0		; is handle locked?
	je	UEMUnlocked		; No, return error

	dec	[bx].cLock		; Unlock the block

	mov     ax,1			; Return success
	xor     bl,bl
	ret

UEMUnlocked:
	mov	bl,ERR_EMBUNLOCKED
	jmp	short UEMErrExit

UEMBadh:
	mov	bl,ERR_INVALIDHANDLE
UEMErrExit:
	xor	ax,ax
	ret

UnlockExtMemory endp

;*----------------------------------------------------------------------*
;*									*
;*  ValidateHandle -							*
;*									*
;*	Validates an extended memory block handle			*
;*									*
;*  ARGS:   DX = 16-bit handle to the extended memory block		*
;*  RETS:   Carry is set if the handle is valid				*
;*  REGS:   Preserved except the carry flag				*
;*									*
;*----------------------------------------------------------------------*

ValidateHandle proc near

	push	ax
	push	bx
	push	cx
	push	dx

	mov	bx,dx		; Move the handle into BX

;	The handle must be equal to or above "KiddValley".

	cmp	bx,cs:[KiddValley]
	jb	VH9f

;	The handle must not be above "KiddValleyTop".

	cmp	bx,cs:[KiddValleyTop]
	ja	VH9f

;	(The handle-"KiddValley") must be a multiple of a handle's size.

	sub	dx,cs:[KiddValley]
	mov	ax,dx
	xor	dx,dx
	mov	cx,SIZE Handle
	div	cx
	or	dx,dx		; Any remainder?
	jnz     VH9f 		; Yup, it's bad

;	Does the handle point to a currently USED block?

	cmp	[bx].Flags,USEDFLAG
	jne     VH9f 		; This handle is not being used.

;	The handle looks good to me...

	stc			; return success
VH9:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

VH9f:

;	It's really bad.
	clc 			; Return failure
	jmp	short vh9	; we can take a performance hit if it is
				;  a bad handle

ValidateHandle endp

Bios_Code	ends
	end
