;** CFGMEM.ASM - Configuration program DOS memory services
;
; FAR C entries; arguments follow the saved return address at BP+6.
; ConfigAlloc takes a DWORD byte count and returns a paragraph-aligned
; pointer in DX:AX, or zero on failure. ConfigFree takes a FAR pointer.
; ConfigRealloc takes a FAR pointer, DWORD new size and DWORD copy size.
;

REGIO	segment	word public 'CODE'
	.386
	assume	cs:REGIO
	public	ConfigAlloc,ConfigFree,ConfigRealloc

ConfigAlloc	proc	far
ca_alloc	label	near
	enter	0,0
	mov	ax,[bp+10]
	mov	dx,[bp+6]
	mov	ax,[bp+8]
	add	dx,15
	db	083h,0D0h,0           ; ADC AX,0 (signed immediate)
	shr	ax,1
	rcr	dx,1
	shr	ax,1
	rcr	dx,1
	shr	ax,1
	rcr	dx,1
	shr	ax,1
	rcr	dx,1
	mov	ah,48h
	mov	bx,dx
	xor	dx,dx
	push	bx
	int	21h
	pop	cx
	jc	short ca_fail
	push	es
	push	di
	mov	es,ax
	mov	di,0
	shl	cx,4
	cld
	mov	ax,0
	rep	stosb
	mov	dx,es
	pop	di
	pop	es
	jmp	short ca_exit
ca_fail:
	xor	ax,ax
	mov	dx,ax
ca_exit:
	leave
	ret
ConfigAlloc	endp

ConfigFree	proc	far
	enter	0,0
	push	bx
	push	es
	mov	dx,[bp+6]
	or	dx,dx
	jnz	short cf_exit
	mov	es,word ptr [bp+8]
	mov	ax,4900h
	int	21h
cf_exit:
	pop	es
	pop	bx
	leave
	ret
ConfigFree	endp

; Try to resize in place. On failure allocate, copy across segment
; boundaries and release the original allocation only after success.
;
ConfigRealloc	proc	far
	enter	4,0
	push	bx
	push	es
	les	bx,[bp+6]
	mov	ebx,[bp+10]
	add	ebx,15
	shr	ebx,4
	mov	ax,4A00h
	int	21h
	pop	es
	jnc	short cr_same
	xor	eax,eax
	push	eax
	mov	eax,[bp+10]
	push	eax
	push	cs
	call	ca_alloc
	add	sp,8
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	ax,ax
	jnz	short cr_copy
	or	dx,dx
	jz	short cr_exit
cr_copy:
	push	es
	push	ds
	push	ecx
	push	si
	push	di
	mov	ecx,[bp+14]
	or	ecx,ecx
	jz	short cr_copied
	les	di,[bp-4]
	lds	si,[bp+6]
cr_byte:
	mov	al,[si]
	mov	es:[di],al
	inc	si
	jz	short cr_source
cr_dest:
	inc	di
	jz	short cr_segment
cr_count:
	dec	ecx
	jnz	short cr_byte
	jmp	short cr_copied
cr_source:
	mov	ax,ds
	add	ax,1000h
	mov	ds,ax
	jmp	short cr_dest
cr_segment:
	mov	ax,es
	add	ax,1000h
	mov	es,ax
	jmp	short cr_count
cr_copied:
	pop	di
	pop	si
	pop	ecx
	pop	ds
	pop	es
	mov	ax,[bp+8]
	push	es
	mov	es,ax
	mov	ax,4900h
	int	21h
	pop	es
	mov	ax,[bp-4]
	mov	dx,[bp-2]
cr_exit:
	pop	bx
	leave
	ret
cr_same:
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	jmp	short cr_exit
ConfigRealloc	endp

REGIO	ends
	end
