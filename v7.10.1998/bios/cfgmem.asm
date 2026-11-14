;** CFGMEM.ASM - Configuration program DOS memory services
;
; FAR C entries; arguments follow the saved return address at BP+6.
; ConfigAlloc takes a DWORD byte count and returns a paragraph-aligned
; pointer in DX:AX, or zero on failure. ConfigFree takes a FAR pointer.
;

REGIO	segment	byte public 'CODE'
	.386
	assume	cs:REGIO
	public	ConfigAlloc,ConfigFree

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
REGIO	ends
	end
