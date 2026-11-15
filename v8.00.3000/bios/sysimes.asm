;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160

MULTI_CONFIG equ 1

	include	version.inc	; set build flags
	include biosseg.inc	; establish bios segment structure

	extrn ConfigRecordCount:word

SysInitSeg segment
	.386
	assume cs:SysInitSeg
	db 0

; Format a long value in decimal or hexadecimal in the caller's buffer.
	public SysInitFormatLong
SysInitFormatLong proc far
	enter	16h,0
	push	di
	push	si
	push	ds
	mov	ax,seg ConfigRecordCount
	mov	ds,ax
	mov	si,[bp+12h]
	mov	byte ptr [bp-16h],30h
	mov	byte ptr [bp-15h],31h
	mov	byte ptr [bp-14h],32h
	mov	byte ptr [bp-13h],33h
	mov	byte ptr [bp-12h],34h
	mov	byte ptr [bp-11h],35h
	mov	byte ptr [bp-10h],36h
	mov	byte ptr [bp-0fh],37h
	mov	byte ptr [bp-0eh],38h
	mov	byte ptr [bp-0dh],39h
	mov	byte ptr [bp-0ch],41h
	mov	byte ptr [bp-0bh],42h
	mov	byte ptr [bp-0ah],43h
	mov	byte ptr [bp-9],44h
	mov	byte ptr [bp-8],45h
	mov	byte ptr [bp-7],46h
	cmp	word ptr [bp+0ah],1
	sbb	di,di
	and	di,-6
	add	di,10h
	mov	eax,[bp+6]
	mov	[bp-4],eax
	les	bx,dword ptr [bp+0eh]
	mov	byte ptr es:[bx+si],0
	mov	[bp-6],di
sfl_next:
	cmp	dword ptr [bp+6],0
	jnz	short sfl_digit
	cmp	dword ptr [bp-4],0
	jnz	short sfl_finish
	mov	dword ptr [bp-4],1
sfl_digit:
	mov	ax,di
	cwd
	push	dx
	push	di
	mov	eax,[bp+6]
	pop	ecx
	xor	edx,edx
	div	ecx
	mov	eax,edx
	shr	edx,10h
	mov	bx,ax
	lea	ax,[bp-16h]
	add	bx,ax
	mov	al,ss:[bx]
	les	bx,dword ptr [bp+0eh]
	dec	si
	mov	es:[bx+si],al
	cmp	si,0
	jz	short sfl_finish
	mov	ax,di
	cwd
	push	dx
	push	di
	mov	eax,[bp+6]
	pop	ecx
	xor	edx,edx
	div	ecx
	mov	[bp+6],eax
	jmp	short sfl_next
sfl_finish:
	cmp	byte ptr [bp+0ch],0
	jnz	short sfl_pad
	mov	di,[bp+0eh]
	mov	ax,di
	mov	dx,[bp+10h]
	add	ax,si
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
sfl_pad:
	mov	di,[bp+0eh]
	or	si,si
	jz	short sfl_return
	mov	es,word ptr [bp+10h]
sfl_pad_next:
	mov	bx,di
	dec	si
	mov	al,[bp+0ch]
	mov	es:[bx+si],al
	or	si,si
	jnz	short sfl_pad_next
sfl_return:
	mov	ax,di
	mov	dx,[bp+10h]
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
SysInitFormatLong endp
	.8086

; Indexed SYSINIT message resource header, offsets and text.
;
sysinit_resource label byte
	dw	(sysinit_msg_base - sysinit_msg_table)/2 - 1
	dw	offset sysinit_msg_base
	dw	100h
	dw	sysinit_msg_end - sysinit_msg_base
	include ..\lang\usa\messages\sysimsg.inc

; The loader locates the message resource from its trailing signature.
	db	'IOSYSMSG'
	dw	sysinit_msg_end - sysinit_resource
	db	1419 dup ('MPAD')
	db	3 dup (0)

SysInitSeg	ends
	end
