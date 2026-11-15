	.8086
	include	biosseg.inc
	include	syscall.inc
	include	sysvar.inc
Bios_Data segment
	extrn	bios_flags:word,palette_index:byte,palette_count:byte,palette_config:word,int16_limit:word,int16_limit2:word
	extrn	palette_cycles:byte
Bios_Data	ends
Bios_Code segment
	extrn	int15_esc:far,keyboard_info:word,bc_retf:far,keyboard_service:near
	extrn	video_state_save:far,video_state_restore:far
	extrn	keyboard_vector_install:near
Bios_Code	ends
	extrn	BootLogo:byte
sysinitseg	segment	public
	assume	cs:sysinitseg,ds:nothing,es:nothing
	extrn	BCodeSeg:word,boot_runtime_flags:byte,boot_config_flags:byte,boot_mode:byte,query_mode_flags:byte
	extrn	bios_data_segment:word
boot_logo_name	db	'\LOGO.SYS',0
boot_logo_handle dw 0
boot_logo_checksum dw 0

	.386
; Display the startup bitmap, using the built-in image when no file was opened.
	public	boot_logo_display
boot_logo_display proc near
	pusha
	push	ds
	push	es
	mov	ds,word ptr cs:[BCodeSeg]
	assume ds:Bios_Code
	cmp	byte ptr [int15_esc-1],0
	jnz	short boot_logo_suppressed
	test	byte ptr cs:[boot_runtime_flags],1
	jnz	short boot_logo_suppressed
	test	byte ptr cs:[query_mode_flags],0ah
boot_logo_suppressed:
	jnz	short boot_logo_exit_jump
	cmp	dx,1
	jnz	short boot_logo_check_video
	sub	dx,dx
	cmp	cs:[boot_logo_name],dl
	jnz	short boot_logo_check_video
	jmp	near ptr boot_logo_use_saved
	push	ss
	pop	es
	sub	sp,26h
	mov	di,sp
	mov	bp,offset Bios_Code:video_state_save
	call	boot_video_call
	sub	cx,cx
	call	boot_logo_video_mode
	mov	ax,0a000h
	mov	ds,ax
	assume ds:nothing
	mov	si,0fd00h
	sub	di,di
	mov	cx,100h
	call	boot_logo_palette_write
	mov	di,sp
	call	boot_logo_text_mapping
	push	ss
	pop	es
	mov	bp,offset Bios_Code:video_state_restore
	call	boot_video_call
	add	sp,26h
	call	boot_logo_display_enable
	mov	ds,word ptr cs:[bios_data_segment]
	assume ds:Bios_Data
	or	byte ptr [bios_flags+1],20h
	mov	bp,offset Bios_Code:keyboard_vector_install
	call	boot_video_call
boot_logo_check_video:
	cmp	byte ptr cs:[boot_logo_name],0
	jz	short boot_logo_exit_jump
	mov	ax,1a00h
	push	dx
	int	10h
	pop	dx
	cmp	al,1ah
	jnz	short boot_logo_exit_jump
	or	bl,bl
	jnz	short boot_logo_video_known
	mov	bl,bh
boot_logo_video_known:
	cmp	bl,7
	jz	short boot_logo_open
	cmp	bl,8
	jz	short boot_logo_open
boot_logo_exit_jump:
	jmp	near ptr boot_logo_exit
boot_logo_open:
	or	dx,dx
	jnz	short boot_logo_open_path
	push	cs
	pop	ds
	assume ds:nothing
	mov	dx,offset boot_logo_name
	sub	bx,bx
boot_logo_open_path:
	mov	ax,3d00h
	int	21h
	jnc	short boot_logo_opened
	test	bx,bx
	jnz	short boot_logo_exit_jump
boot_logo_use_saved:
	db 83h,0C8h,0FFh	; OR AX,-1
boot_logo_opened:
	mov	dx,seg BootLogo
	mov	ds,dx
	assume ds:nothing
	mov	cs:[boot_logo_handle],ax
	xchg	ax,bx
	mov	dx,0
	call	boot_logo_read_file
	jc	near ptr boot_logo_close
	mov	si,dx
	cmp	word ptr [si],4d42h
	jnz	near ptr boot_logo_close
	add	si,0eh
	cmp	word ptr [si],28h
	jnz	near ptr boot_logo_close
	cmp	word ptr [si+0ch],1
	jnz	near ptr boot_logo_close
	cmp	word ptr [si+0eh],8
	jnz	near ptr boot_logo_close
	cmp	word ptr [si+4],140h
	jnz	near ptr boot_logo_close
	cmp	word ptr [si+8],190h
	jnz	near ptr boot_logo_close
	cmp	word ptr [si+10h],0
	jnz	near ptr boot_logo_close
	mov	ax,[si+24h]
	push	ds
	mov	ds,word ptr cs:[bios_data_segment]
	assume ds:Bios_Data
	mov	[palette_index],al
	neg	al
	add	al,0ffh
	mov	[palette_count],al
	test	ah,ah
	jz	short boot_logo_palette_ready
	mov	[palette_config],ax
	mov	word ptr [palette_cycles],ax
boot_logo_palette_ready:
	pop	ds
	assume ds:nothing
	mov	byte ptr cs:[boot_logo_name],0
	push	ss
	pop	es
	sub	sp,26h
	mov	di,sp
	mov	bp,offset Bios_Code:video_state_save
	call	boot_video_call
	mov	cx,8000h
	call	boot_logo_video_mode
	mov	word ptr cs:[boot_logo_checksum],0
	mov	ax,0a000h
	mov	es,ax
	mov	di,0fd00h
	mov	cx,seg BootLogo
	mov	ds,cx
	assume ds:nothing
	mov	si,36h
	mov	cx,100h
	call	boot_logo_palette_convert
	mov	bx,436h
	mov	cx,word ptr [16h]
	push	ds
boot_logo_rows:
	sub	di,50h
	push	cx
	call	boot_logo_copy_row
	pop	cx
	add	bx,140h
	cmp	bx,8000h
	jc	short boot_logo_row_done
	sub	bx,8000h
	mov	dx,ds
	add	dx,800h
	mov	ds,dx
	assume ds:nothing
boot_logo_row_done:
	loop	boot_logo_rows
	pop	ds
	assume ds:nothing
	mov	di,sp
	call	boot_logo_text_mapping
	push	ss
	pop	es
	mov	bp,offset Bios_Code:video_state_restore
	call	boot_video_call
	add	sp,26h
	call	boot_logo_display_enable
	mov	ds,word ptr cs:[BCodeSeg]
	assume ds:Bios_Code
	mov	ax,cs:[boot_logo_checksum]
	mov	[keyboard_info],ax
	mov	ds,word ptr cs:[bios_data_segment]
	assume ds:Bios_Data
	mov	ax,es:[46ch]
boot_logo_ticks:
	mov	dx,es:[46ch]
	cmp	dx,ax
	jz	short boot_logo_ticks
	sub	cx,cx
boot_logo_keys:
	mov	ah,1
	int	16h
	inc	cx
	cmp	dx,es:[46ch]
	jz	short boot_logo_keys
	xchg	ax,cx
	sub	dx,dx
	mov	cx,14h
	div	cx
	test	ax,ax
	jz	short boot_logo_enable
	mov	[int16_limit],ax
	mov	[int16_limit2],ax
boot_logo_enable:
	or	byte ptr [bios_flags+1],20h
	mov	bp,offset Bios_Code:keyboard_vector_install
	call	boot_video_call
	mov	bx,cs:[boot_logo_handle]
boot_logo_close:
	test	bx,bx
	js	short boot_logo_exit
	mov	ah,3eh
	int	21h
boot_logo_exit:
	pop	es
	pop	ds
	assume ds:nothing
	popa
	ret
boot_logo_display endp

; Program the VGA display mode.
boot_logo_video_mode proc near
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
	jcxz	short boot_logo_set_registers
	mov	ax,0a000h
	mov	es,ax
	xor	ax,ax
	mov	di,8000h
	cld
	rep	stosb
boot_logo_set_registers:
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
boot_logo_video_mode endp

; Convert the bitmap palette to VGA components.
boot_logo_palette_convert proc near
	push	di
	push	es
	push	si
	push	cx
	mov	di,si
	push	ds
	pop	es
	cld
boot_logo_palette_next:
	lodsw
	mov	dx,ax
	lodsw
	shr	al,2
	shr	dl,2
	shr	dh,2
	stosb
	xchg	dl,dh
	mov	ax,dx
	stosw
	loop	boot_logo_palette_next
	pop	cx
	pop	si
	pop	es
	pop	di
boot_logo_palette_convert endp

; Write the VGA palette.
boot_logo_palette_write proc near
	push	di
	xor	ax,ax
	mov	dx,3c8h
	out	dx,al
	mov	dx,3c9h
	mov	bx,cx
	add	cx,cx
	add	cx,bx
boot_logo_palette_loop:
	push	cx
	mov	cx,14h
boot_logo_palette_wait:
	loop	boot_logo_palette_wait
	pop	cx
	lodsb
	out	dx,al
	or	di,di
	jz	short boot_logo_palette_end
	stosb
boot_logo_palette_end:
	loop	boot_logo_palette_loop
	pop	di
	ret
boot_logo_palette_write endp

; Enable VGA display output.
boot_logo_display_enable proc near
	mov	dx,3dah
	in	al,dx
	mov	dl,0c0h
	mov	al,20h
	out	dx,al
	ret
boot_logo_display_enable endp

; Set up the VGA text-mode mapping.
boot_logo_text_mapping proc near
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
	jnz	short boot_logo_text_done
	and	al,0fbh
	mov	si,0b000h
boot_logo_text_done:
	out	dx,al
	ret
boot_logo_text_mapping endp

; Copy one bitmap row to the four VGA planes.
boot_logo_copy_row proc near
	push	bp
	cld
	mov	dx,3c4h
	mov	cx,140h
	shr	cx,2
	mov	bp,cx
	mov	ax,102h
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
	mov	ax,202h
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
	mov	ax,402h
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
	mov	ax,802h
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
boot_logo_copy_row endp

; Invoke the BIOS keyboard service while preserving BP.
	public	query_keyboard_service
query_keyboard_service label near
boot_video_console proc near
	push	bp
	mov	bp,offset Bios_Code:keyboard_service
	call	boot_video_call
	pop	bp
	ret
boot_video_console endp

; Read an optional external bitmap into the built-in image buffer.
boot_logo_read_file proc near
	mov	bx,cs:[boot_logo_handle]
	test	bx,bx
	clc
	js	short boot_logo_read_return
	push	ds
	push	si
	mov	si,ds
	mov	cx,3
boot_logo_read_block:
	push	cx
	mov	cx,8000h
	mov	ah,3fh
	stc
	int	21h
	pop	cx
	jc	short boot_logo_read_last
	add	si,800h
	mov	ds,si
	assume ds:nothing
	loop	boot_logo_read_block
boot_logo_read_last:
	jc	short boot_logo_read_done
	mov	cx,7836h
	mov	ah,3fh
	stc
	int	21h
boot_logo_read_done:
	pop	si
	pop	ds
	assume ds:nothing
boot_logo_read_return:
	ret
boot_logo_read_file endp

; Call a BIOS code routine and return to SYSINIT.
boot_video_return dw 0
	public	query_bios_call
query_bios_call label near
boot_video_call proc near
	pop	word ptr cs:[boot_video_return]
	push	cs
	push	word ptr cs:[boot_video_return]
	push	offset Bios_Code:bc_retf
	public	boot_bios_far_call
boot_bios_far_call label near
	push	word ptr cs:[BCodeSeg]
	push	bp
	retf
boot_video_call endp

	.8086
sysinitseg ends
	end
