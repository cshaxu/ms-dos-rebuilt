;** CPATH.ASM - Configuration path and fallback file preparation
;
; FAR C entry: caller supplies a FAR pointer to a 64-byte path buffer.
; Query INT 2Fh/1613h, check the returned path, and if needed copy the
; alternate file whose final character is '0'. Empty the path on failure.
;
	extrn	ConfigAlloc:far,ConfigFree:far
	extrn	ConfigCreate:far,ConfigOpen:far,ConfigRead:far
	extrn	ConfigWriteAll:far,ConfigClose:far
CONFIGPATH	segment	para public 'CODE'
	.386
	assume	cs:CONFIGPATH
	public	ConfigPreparePath

ConfigPreparePath	proc	far
	enter	0,0
	pushf
	push	ds
	push	es
	push	si
	push	di
	push	bx
	les	di,[bp+6]
	mov	cx,40h
	mov	ax,1613h
	int	2Fh
	or	ax,ax
	jnz	cp_fail
	push	ax
	mov	cx,7
	push	ds
	lds	dx,[bp+6]
	mov	ah,4Eh
	int	21h
	pop	ds
	pop	ax
	jnc	cp_exit
	or	al,al
	jnz	cp_fail
	les	di,[bp+6]
	xor	al,al
	cld
	mov	cx,40h
	repne	scasb
	jnz	cp_fail
	dec	di
	dec	di
	push	word ptr es:[di]
	mov	byte ptr es:[di],'0'
	push	ds
	push	di
	mov	cx,7
	lds	dx,[bp+6]
	mov	ah,4Eh
	int	21h
	pop	di
	pop	ds
	pop	ax
	jc	cp_fail
;
; Keep the alternate path on the stack and restore the requested name.
;
	push	ds
	push	si
	lds	si,[bp+6]
	sub	sp,40h
	mov	cx,di
	sub	cx,dx
	inc	cx
	inc	cx
	mov	di,sp
	push	ss
	pop	es
	cld
	rep	movsb
	dec	si
	dec	si
	mov	[si],al
	xor	ax,ax
	push	ax
	push	ax
	push	ax
	mov	ax,8000h
	push	ax
	call	ConfigAlloc
	add	sp,8
	mov	es,dx
	mov	bx,ax
	or	ax,dx
	jz	cp_fail
	xor	ax,ax
	push	ax
	push	ax
	lds	dx,[bp+6]
	push	ds
	push	dx
	call	ConfigCreate
	add	sp,8
	db	083h,0F8h,0FFh        ; CMP AX,-1 (signed immediate)
	jz	cp_fail
	mov	dx,sp
	push	ax
	xor	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	ss
	push	dx
	call	ConfigOpen
	add	sp,12
	db	083h,0F8h,0FFh        ; CMP AX,-1 (signed immediate)
	pop	di
	jz	short cp_close_dest
	mov	si,ax
cp_copy:
	xor	ax,ax
	push	ax
	push	ax
	push	ax
	mov	ax,8000h
	push	ax
	push	es
	push	bx
	push	si
	call	ConfigRead
	add	sp,14
	db	083h,0F8h,0FFh        ; CMP AX,-1 (signed immediate)
	jz	short cp_close_source
	or	ax,ax
	jz	short cp_close_source
	mov	dx,ax
	xor	ax,ax
	push	ax
	push	ax
	push	ax
	push	dx
	push	es
	push	bx
	push	di
	call	ConfigWriteAll
	add	sp,14
	db	083h,0F8h,0FFh        ; CMP AX,-1 (signed immediate)
	jnz	short cp_copy
cp_close_source:
	mov	dx,sp
	push	ax
	xor	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	si
	push	ss
	push	dx
	call	ConfigClose
	add	sp,14
cp_close_dest:
	mov	ax,-1
	push	ax
	push	ax
	inc	ax
	push	ax
	push	ax
	push	di
	lds	dx,[bp+6]
	push	ds
	push	dx
	call	ConfigClose
	add	sp,14
	push	es
	push	bx
	call	ConfigFree
	add	sp,4
	pop	ax
	add	sp,40h
	pop	si
	pop	ds
	or	ax,ax
	jz	short cp_exit
cp_fail:
	les	di,[bp+6]
	mov	byte ptr es:[di],0
cp_exit:
	pop	bx
	pop	di
	pop	si
	pop	es
	pop	ds
	popf
	leave
	ret
ConfigPreparePath	endp

CONFIGPATH	ends
	end
