	.8086
	include	biosseg.inc
	include	syscall.inc
	include	sysvar.inc
Bios_Data segment
	extrn	bios_flags:word,palette_index:byte,palette_count:byte,palette_config:word,int16_limit:word,int16_limit2:word
Bios_Data	ends
Bios_Code segment
	extrn	int15_esc:far,hma_init_ptr:dword,bc_retf:far,keyboard_service:near
Bios_Code	ends
sysinitseg	segment	public
	assume	cs:sysinitseg,ds:nothing,es:nothing
	extrn	BCodeSeg:word,boot_runtime_flags:byte,boot_config_flags:byte,boot_mode:byte,query_mode_flags:byte
	extrn	boot_load_segment:word,boot_reloc_segment:word,bios_data_segment:word,memhi:word
boot_logo_name	db	'\LOGO.SYS',0
boot_logo_checksum	dw	0                ; sum of displayed image bytes

; Display the startup bitmap from a file or the saved boot image.
; DX selects a startup mode or supplies the caller's file name.
	.386
	public	boot_logo_display
boot_logo_display	proc	near
	pusha
	push	ds
	push	es
	mov	ds,cs:[BCodeSeg]
	cmp	byte ptr ds:[int15_esc-1],0
	jne	short boot_logo_suppressed
	test	byte ptr cs:[boot_runtime_flags],1
	jnz	short boot_logo_suppressed
	test	byte ptr cs:[query_mode_flags],0ah
boot_logo_suppressed:
	jnz	short boot_logo_exit_jump
	cmp	dx,1
	jne	short boot_logo_check_video
	sub	dx,dx
	cmp	cs:[boot_logo_name],dl
	jne	short boot_logo_check_video
	cmp	cs:[boot_load_segment],dx
	jne	boot_logo_use_saved
	push	ss
	pop	es
	sub	sp,26h
	mov	di,sp
	mov	bp,35fh
	call	boot_video_call
	sub	cx,cx
	call	boot_logo_video_mode
	mov	ax,0a000h
	mov	ds,ax
	mov	si,0fd00h
	sub	di,di
	mov	cx,100h
	call	boot_logo_palette_write
	mov	di,sp
	call	boot_logo_text_mapping
	push	ss
	pop	es
	mov	bp,57fh
	call	boot_video_call
	add	sp,26h
	call	boot_logo_display_enable
	mov	ds,cs:[bios_data_segment]
	or	byte ptr ds:[bios_flags+1],20h
	mov	bp,299h
	call	boot_video_call
boot_logo_check_video:
	cmp	byte ptr cs:[boot_logo_name],0
	je	short boot_logo_exit_jump
	mov	ax,1a00h
	push	dx
	int	10h
	pop	dx
	cmp	al,1ah
	jne	short boot_logo_exit_jump
	or	bl,bl
	jnz	short boot_logo_video_known
	mov	bl,bh
boot_logo_video_known:
	cmp	bl,7
	je	short boot_logo_open
	cmp	bl,8
	je	short boot_logo_open
boot_logo_exit_jump:
	jmp	boot_logo_exit
boot_logo_open:
	or	dx,dx
	jnz	short boot_logo_open_path
	push	cs
	pop	ds
	mov	dx,offset boot_logo_name
	sub	bx,bx
boot_logo_open_path:
	mov	ax,3d00h
	int	21h
	jc	short boot_logo_open_failed
	mov	word ptr cs:[boot_load_segment],0
	jmp	short boot_logo_opened
boot_logo_open_failed:
	test	bx,bx
	jnz	short boot_logo_exit_jump
	cmp	word ptr cs:[boot_load_segment],0
	je	short boot_logo_exit_jump
boot_logo_use_saved:
	db	83h,0c8h,0ffh          ; or ax,-1
boot_logo_opened:
	mov	ds,cs:[memhi]
	mov	word ptr ds:[0],ax
	xchg	ax,bx
	mov	dx,2
	call	boot_logo_read_file
	jc	boot_logo_close
	mov	si,dx
	cmp	word ptr [si],4d42h
	jne	boot_logo_close
	add	si,0eh
	cmp	word ptr [si],28h
	jne	boot_logo_close
	cmp	word ptr [si+0ch],1
	jne	boot_logo_close
	cmp	word ptr [si+0eh],8
	jne	boot_logo_close
	cmp	word ptr [si+4],140h
	jne	boot_logo_close
	cmp	word ptr [si+8],190h
	jne	boot_logo_close
	cmp	word ptr [si+10h],0
	jne	boot_logo_close
	mov	ax,[si+24h]
	push	ds
	mov	ds,cs:[bios_data_segment]
	mov	ds:[palette_index],al
	neg	al
	add	al,0ffh
	mov	ds:[palette_count],al
	test	ah,ah
	jz	short boot_logo_palette_ready
	mov	ds:[palette_config],ax
	mov	ds:[palette_config+2],ax
boot_logo_palette_ready:
	pop	ds
	mov	byte ptr cs:[boot_logo_name],0
	push	ss
	pop	es
	sub	sp,26h
	mov	di,sp
	mov	bp,35fh
	call	boot_video_call
	mov	cx,8000h
	call	boot_logo_video_mode
	mov	word ptr cs:[boot_logo_checksum],0
	mov	ax,0a000h
	mov	es,ax
	mov	di,0fd00h
	mov	ds,cs:[memhi]
	mov	si,38h
	mov	cx,100h
	call	boot_logo_palette_convert
	mov	si,7bcah
boot_logo_next_buffer:
	mov	bx,438h
	mov	ax,si
	xor	dx,dx
	mov	cx,140h
	div	cx
	xchg	ax,cx
	mov	dx,si
	cmp	cx,word ptr ds:[18h]
	jbe	short boot_logo_have_rows
	mov	cx,word ptr ds:[18h]
boot_logo_have_rows:
	push	cx
	push	dx
boot_logo_next_row:
	sub	di,50h
	push	cx
	call	boot_logo_copy_row
	pop	cx
	add	bx,140h
	loop	boot_logo_next_row
	pop	cx
	pop	ax
	sub	word ptr ds:[18h],ax
	jbe	short boot_logo_image_done
	mov	si,bx
	mov	bx,140h
	mul	bx
	sub	cx,ax
	push	di
	push	cx
	push	es
	mov	es,cs:[memhi]
	mov	di,438h
	cld
	rep	movsb
	pop	es
	mov	dx,di
	call	boot_logo_read_file
	pop	si
	pop	di
	jc	short boot_logo_image_done
	add	si,8000h
	jmp	short boot_logo_next_buffer
boot_logo_image_done:
	mov	di,sp
	call	boot_logo_text_mapping
	push	ss
	pop	es
	mov	bp,57fh
	call	boot_video_call
	add	sp,26h
	call	boot_logo_display_enable
	mov	ds,cs:[BCodeSeg]
	mov	ax,cs:[boot_logo_checksum]
	mov	word ptr ds:[hma_init_ptr-2],ax
	mov	ds,cs:[bios_data_segment]
	mov	ax,es:[46ch]
boot_logo_wait_tick:
	mov	dx,es:[46ch]
	cmp	dx,ax
	je	short boot_logo_wait_tick
	sub	cx,cx
boot_logo_calibrate:
	mov	ah,1
	int	16h
	inc	cx
	cmp	dx,es:[46ch]
	je	short boot_logo_calibrate
	xchg	ax,cx
	sub	dx,dx
	mov	cx,20
	div	cx
	test	ax,ax
	jz	short boot_logo_calibrated
	mov	ds:[int16_limit],ax
	mov	ds:[int16_limit2],ax
boot_logo_calibrated:
	or	byte ptr ds:[bios_flags+1],20h
	mov	bp,299h
	call	boot_video_call
	mov	ds,cs:[memhi]
	mov	bx,word ptr ds:[0]
boot_logo_close:
	test	bx,bx
	js	short boot_logo_exit
	mov	ah,3eh
	int	21h
boot_logo_exit:
	pop	es
	pop	ds
	popa
	ret
boot_logo_display	endp
	.8086

; Set the VGA display mode used by the startup logo.
; CX nonzero also clears the upper display memory.
boot_logo_video_mode	proc	near
	mov	ax,93h
	int	10h
	mov	dx,3dah
	in	al,dx
	mov	dl,0c0h
	xor	al,al
	out	dx,al
	mov	dl,0c4h
	mov	ax,0f02h
	out	dx,ax
	mov	al,4
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0f7h
	or	al,4
	out	dx,al
	mov	dl,0ceh
	mov	al,5
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0efh
	out	dx,al
	dec	dx
	mov	al,6
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0fdh
	out	dx,al
	jcxz	boot_logo_no_clear
	mov	ax,0a000h
	mov	es,ax
	xor	ax,ax
	mov	di,8000h
	cld
	rep	stosb
boot_logo_no_clear:
	mov	dl,0d4h
	mov	ax,800ch
	out	dx,ax
	mov	al,9
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0e0h
	out	dx,al
	dec	dx
	mov	al,14h
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0bfh
	out	dx,al
	dec	dx
	mov	al,17h
	out	dx,al
	inc	dx
	in	al,dx
	or	al,40h
	out	dx,al
	ret
boot_logo_video_mode	endp

; Convert four-byte palette entries to VGA component triples.
; DS:SI addresses the input and CX contains the entry count.
boot_logo_palette_convert	proc	near
	push	di
	push	es
	push	si
	push	cx
	mov	di,si
	push	ds
	pop	es
	cld
boot_palette_convert_next:
	lodsw
	mov	dx,ax
	lodsw
	.286
	shr	al,2
	shr	dl,2
	shr	dh,2
	.8086
	stosb
	xchg	dl,dh
	mov	ax,dx
	stosw
	loop	boot_palette_convert_next
	pop	cx
	pop	si
	pop	es
	pop	di
boot_logo_palette_convert	endp

; Write CX palette triples from DS:SI; ES:DI receives a copy if DI is nonzero.
boot_logo_palette_write	proc	near
	push	di
	xor	ax,ax
	mov	dx,3c8h
	out	dx,al
	mov	dx,3c9h
	mov	bx,cx
	add	cx,cx
	add	cx,bx
boot_palette_next:
	push	cx
	mov	cx,20
boot_palette_wait:
	loop	boot_palette_wait
	pop	cx
	lodsb
	out	dx,al
	or	di,di
	jz	boot_palette_nocopy
	stosb
boot_palette_nocopy:
	loop	boot_palette_next
	pop	di
	ret
boot_logo_palette_write	endp

; Enable the VGA display after loading the palette.
boot_logo_display_enable	proc	near
	mov	dx,3dah
	in	al,dx
	mov	dl,0c0h
	mov	al,20h
	out	dx,al
	ret
boot_logo_display_enable	endp

; Restore VGA memory mapping for the saved text display.
; SS:DI addresses the saved video state; SI returns the text segment.
boot_logo_text_mapping	proc	near
	mov	dx,3c4h
	mov	al,2
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0f3h
	or	al,3
	out	dx,al
	dec	dx
	mov	al,4
	out	dx,al
	inc	dx
	in	al,dx
	and	al,0fbh
	out	dx,al
	mov	dl,0ceh
	mov	ax,4
	out	dx,ax
	mov	al,5
	out	dx,al
	inc	dx
	in	al,dx
	or	al,10h
	out	dx,al
	dec	dx
	mov	al,6
	out	dx,al
	inc	dx
	in	al,dx
	or	al,0eh
	mov	si,0b800h
	cmp	byte ptr ss:[di+1],7
	jne	boot_logo_text_color
	and	al,0fbh
	mov	si,0b000h
boot_logo_text_color:
	out	dx,al
	ret
boot_logo_text_mapping	endp

; Copy a 320-byte image row into four VGA planes and accumulate its sum.
; DS:BX points to the row and ES:DI to the display destination.
	.386
boot_logo_copy_row	proc	near
	push	bp
	cld
	mov	dx,3c4h
	mov	cx,320
	shr	cx,2
	mov	bp,cx
	mov	ax,0102h
	out	dx,ax
	mov	si,bx
	push	di
boot_logo_plane1:
	lodsd
	stosb
	mov	ah,0
	add	cs:[boot_logo_checksum],ax
	loop	boot_logo_plane1
	pop	di
	mov	ax,0202h
	out	dx,ax
	lea	si,[bx+1]
	mov	cx,bp
	push	di
boot_logo_plane2:
	lodsd
	stosb
	mov	ah,0
	add	cs:[boot_logo_checksum],ax
	loop	boot_logo_plane2
	pop	di
	mov	ax,0402h
	out	dx,ax
	lea	si,[bx+2]
	mov	cx,bp
	push	di
boot_logo_plane3:
	lodsd
	stosb
	mov	ah,0
	add	cs:[boot_logo_checksum],ax
	loop	boot_logo_plane3
	pop	di
	mov	ax,0802h
	out	dx,ax
	lea	si,[bx+3]
	mov	cx,bp
	push	di
boot_logo_plane4:
	lodsd
	stosb
	mov	ah,0
	add	cs:[boot_logo_checksum],ax
	loop	boot_logo_plane4
	pop	di
	pop	bp
	ret
boot_logo_copy_row	endp
	.8086

; Call the BIOS video routine selected by BP, returning through bc_retf.
	.386
boot_video_return	dw	0
	public	query_bios_call
query_bios_call	label	near
boot_video_call	proc	near
	pop	word ptr cs:[boot_video_return]
	push	cs
	push	word ptr cs:[boot_video_return]
	push	offset Bios_Code:bc_retf
	public	boot_bios_far_call
boot_bios_far_call	label	near
	push	word ptr cs:[BCodeSeg]
	push	bp
	retf
boot_video_call	endp

; Invoke the BIOS keyboard service while preserving BP.
	public	query_keyboard_service
query_keyboard_service	label	near
boot_video_console	proc	near
	push	bp
	mov	bp,offset Bios_Code:keyboard_service
	call	boot_video_call
	pop	bp
	ret
boot_video_console	endp

; Read a startup image block into DS:DX.  A negative handle selects the
; four-chunk image already held at boot_reloc_segment:boot_reloc_offset.
	.386
boot_logo_read_file	proc	near
	mov	bx,word ptr ds:[0]
	test	bx,bx
	jns	short boot_logo_read_raw
	push	dx
	push	si
	push	di
	push	ds
	push	es
	push	ds
	pop	es
	mov	di,dx
	lds	si,dword ptr cs:[boot_reloc_segment-2]
	sub	bx,bx
	mov	cx,4
boot_logo_read_chunk:
	lodsw
	test	ax,ax
	js	short boot_logo_read_compressed
	jz	short boot_logo_read_end
	push	cx
	mov	cx,ax
	shr	cx,1
	cld
	rep	movsw
	pop	cx
	jmp	short boot_logo_read_count
boot_logo_read_compressed:
	and	ah,7fh
	xchg	ax,dx
	lodsw
	call	decode_entry
	jc	short boot_logo_read_error
	add	si,dx
	add	di,ax
boot_logo_read_count:
	add	bx,ax
	loop	boot_logo_read_chunk
	jmp	short boot_logo_read_save
boot_logo_read_error:
	dec	si
	dec	si
boot_logo_read_end:
	dec	si
	dec	si
boot_logo_read_save:
	pushf
	mov	ax,si
	shr	ax,4
	mov	dx,ds
	add	dx,ax
	and	si,0fh
	mov	word ptr cs:[boot_reloc_segment-2],si
	mov	cs:[boot_reloc_segment],dx
	popf
	xchg	ax,bx
	mov	cx,8000h
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	dx
	jmp	short boot_logo_read_return
boot_logo_read_raw:
	mov	cx,8000h
	mov	ah,3fh
	stc
	int	21h
boot_logo_read_return:
	ret
boot_logo_read_file	endp

; Decode compressed startup image blocks.
	db	0                       ; padding before decoder workspace
	.386
	include	mrcf.inc
	.8086

sysinitseg	ends
	end
