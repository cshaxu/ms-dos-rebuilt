;	Check compressed-drive host mappings during initialization.
;
	.8086
sysinitseg	segment	word public 'system_init'
	assume	cs:sysinitseg
	assume	ds:sysinitseg
	public	boot_check_redirected_drive
;	AL = drive letter; AX = host drive letter, or zero if not redirected.
;
boot_check_redirected_drive	proc	near
	push	es
	push	ds
	and	al,5fh
	mov	[boot_checked_drive],al
	xor	ax,ax
	mov	es,ax
	call	boot_drive_info
	or	ax,ax
	jz	short drive_check_none
	call	boot_drive_host
	cmp	ax,-1
	je	short drive_check_none
	cmp	al,[boot_checked_drive]
	je	short drive_check_none
	xor	ah,ah
	jmp	short drive_check_exit
drive_check_none:
	xor	ax,ax
drive_check_exit:
	pop	ds
	pop	es
	ret
boot_check_redirected_drive	endp	

boot_drive_info	proc	near
	mov	al,13h
	mov	bl,[boot_checked_drive]
	xor	bh,bh
	call	boot_drive_ioctl
	test	ah,80h
	jz	short drive_info_version
	cmp	word ptr [boot_ioctl_packet],0aa55h
	je	short drive_info_none
	cmp	byte ptr [boot_ioctl_version],1
	jne	short drive_info_none
	mov	ax,13h
	jmp	short drive_info_exit
drive_info_none:
	xor	ax,ax
	jmp	short drive_info_exit
drive_info_version:
	mov	al,[boot_ioctl_major]
	mov	cl,4
	shl	al,cl
	or	al,[boot_ioctl_minor]
	xor	ah,ah
drive_info_exit:
	ret
boot_drive_info	endp	

boot_drive_host	proc	near
	mov	al,8
	mov	bl,[boot_checked_drive]
	xor	bh,bh
	call	boot_drive_ioctl
	test	ah,80h
	jz	short drive_host_value
	mov	ax,0ffffh
	jmp	short drive_host_exit
drive_host_value:
	mov	al,[boot_ioctl_result]
	xor	ah,ah
	add	ax,41h
drive_host_exit:
	ret
boot_drive_host	endp	

boot_drive_ioctl	proc	near
	mov	word ptr [boot_ioctl_packet],0aa55h
	mov	byte ptr [boot_ioctl_version],1
	mov	[boot_ioctl_command],al
	mov	ax,4405h
	sub	bl,40h
	mov	cx,0dh
	mov	dx,offset boot_ioctl_packet
	int	21h
	jnc	short drive_ioctl_ok
	or	ah,80h
	jmp	short drive_ioctl_exit
drive_ioctl_ok:
	mov	ax,[boot_ioctl_packet]
drive_ioctl_exit:
	ret
boot_drive_ioctl	endp	

boot_checked_drive db	0
boot_ioctl_packet  dw	0
boot_ioctl_version db	0
boot_ioctl_command db	0
boot_ioctl_result  db	0
		db	3 dup (0)
boot_ioctl_minor   db	0
boot_ioctl_major   db	0
		db	3 dup (0)
	assume	ds:nothing

;----------------------------------------------------------------------------
; procedure : boot_check_drive_map
;
; Check the drive mapping returned by the absolute disk read and IOCTL paths.
; AL contains the one-based drive number.  AX contains the result.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg
	public	boot_check_drive_map
boot_check_drive_map	proc	near
	dec	ax
	mov	byte ptr [boot_map_drive],al
	push	ds
	push	es
	push	cs
	pop	es
	sub	sp,400h
	mov	bx,sp
	push	ds
	push	bx
	mov	ax,0cdcdh
	mov	cx,1
	xor	dx,dx
	mov	[bx],dx
	mov	bp,bx
	int	25h
	pop	cx			; discard flags from INT 25h
	pop	bx
	pop	ds
	xor	ax,ax
	cmp	word ptr [bx],0cdcdh
	jne	short map_done
	cmp	word ptr [bx+2],1
	jne	short map_done
	les	di,[bx+4]
	cmp	word ptr es:[di],0a55ah
	jne	short map_done
	mov	bx,es:[di+2]
	cmp	bx,0c8h
	jb	short map_done
	cmp	word ptr es:[di+52h],5753h
	jne	short map_done
	cmp	word ptr es:[di+54h],5041h
	jne	short map_done
	mov	al,byte ptr [boot_map_drive]
	mov	ah,al
	mov	dx,ds
	lea	bx,[di+56h]
	xlat	es:[bx]
	db	38h,0e0h		; cmp al,ah
	jne	short map_other_drive
	mov	ax,4408h
	mov	bx,[boot_map_drive]
	inc	bx
	mov	byte ptr es:[di+3eh],0ffh
	int	21h
	xor	ax,ax
	mov	al,es:[di+3eh]
	cmp	al,0ffh
	je	short map_no_result
	mov	di,es:[di+4]
	add	ax,ax
	add	di,ax
	mov	di,es:[di]
	mov	al,es:[di+41h]
	jmp	short map_done
map_no_result:
	xor	ax,ax
	jmp	short map_done
map_other_drive:
	inc	ax
	or	al,40h
map_done:
	add	sp,400h
	pop	es
	pop	ds
	ret
boot_check_drive_map	endp	

boot_map_drive	dw	0
	assume	ds:nothing
	.8086
sysinitseg	ends	
	end
