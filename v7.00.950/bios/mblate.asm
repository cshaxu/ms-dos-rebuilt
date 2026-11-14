	include	version.inc
	include	biosseg.inc
	include	msequ.inc
	include	bpb.inc
	include	bootform.inc
	include	msbds.inc
Bios_Data	segment
	extrn	config_flags:byte,config_count:word,config_value:word,config_xms:dword
Bios_Data	ends
Bios_Code	segment
	extrn	exec_bios_word:word
Bios_Code	ends
sysinitseg	segment
	assume	cs:sysinitseg

	extrn	alloclim:word
	extrn	bios_data_segment:word
	extrn	exec_windows_path:byte,exec_boot_state:byte
	public	exec_data,exec_mode,exec_option,exec_value
exec_data	db	3 dup (0)
exec_mode	db	0
exec_option	db	0
exec_value	dw	30h
		db	0
	public	config_buffer_segment,config_buffer_paragraphs,config_buffer_count
config_buffer_segment	dw	0
config_buffer_paragraphs	dw	0
config_buffer_count	dw	0
	public	saved_mcb_size
saved_mcb_size	dw	0		; original memory block size

; Binary command tail passed to the system file.  The segment words are
; replaced by SYSINIT before the EXEC call.
	public	system_exec_tail,system_io_path,system_winboot_path
	public	system_exec_records
system_exec_tail	label	byte
	db	system_exec_tail_end - system_exec_payload
system_exec_payload	label	byte
	db	0ffh,(system_exec_tail_end - system_exec_records)/6
system_exec_records	label	word
	dw	40h,offset exec_windows_path,0f000h
	dw	2,offset Bios_Code:exec_bios_word,0f000h
	dw	3,offset exec_data,0f000h
	dw	1,offset exec_mode,0f000h
	dw	1,offset exec_boot_state,0f000h
	dw	1,offset exec_option,0f000h
	dw	2,offset exec_value,0f000h
system_exec_tail_end db 13,0
system_io_path db	'C:\IO.SYS',0
system_winboot_path db 'C:\WINBOOT.SYS',0

; Empty environment and EXEC parameter block for the system file.
	public	system_exec_environment,system_exec_env_end,system_exec_block
system_exec_environment db 14 dup (0)
system_exec_env_end dw	0
system_exec_block	label	word
	dw	0,offset system_exec_tail,0
	dd	0,0

	.286
	public	config_init_entry
;
; Reserve paragraphs below alloclim for the CONFIG$ buffer.
; CX = requested bytes, ES:DI -> allocation result.
;
config_init_entry	proc	far
	push	ds
	push	cs
	pop	ds
	assume	ds:sysinitseg
	add	cx,15
	shr	cx,4
	mov	ax,alloclim
	sub	ax,cx
	dec	ax
	xor	dx,dx
	mov	es:[di],dx
	mov	es:[di+2],ax
	mov	config_buffer_segment,ax
	mov	config_buffer_paragraphs,cx
	mov	alloclim,ax
	pop	ds
	assume	ds:nothing
	retf
config_init_entry	endp

	.386
	public	config_xms_init
config_xms_init	proc	near
	push	ds
	push	es
	cmp	cs:config_buffer_paragraphs,0
	jz	config_xms_done
	mov	ax,4300h
	int	2fh
	cmp	al,80h
	jne	config_xms_fail
	mov	ax,4310h
	int	2fh
	mov	ax,cs:bios_data_segment
	mov	ds,ax
	assume	ds:Bios_Data
	mov	word ptr config_xms,bx
	mov	ax,es
	mov	word ptr config_xms+2,ax
	mov	ax,cs:config_buffer_paragraphs
	add	ax,0ffh
	mov	cl,6
	shr	ax,cl
	and	ax,0fffch
	mov	dx,ax
	mov	ah,9
	call	dword ptr config_xms
	cmp	ax,1
	jne	short config_xms_fail
	mov	config_value,dx
	mov	ah,0ch
	call	dword ptr config_xms
	mov	ax,cs:config_buffer_segment
	push	ds
	mov	ds,ax
	assume	ds:nothing
	xor	si,si
	mov	[si+0ch],bx
	mov	[si+0eh],dx
	pop	ds
	assume	ds:Bios_Data
	push	bp
	mov	bp,sp
	xor	ax,ax
	push	ax
	push	ax
	push	config_value
	push	cs:config_buffer_segment
	push	ax
	push	ax
	push	ax
	mov	ax,cs:config_buffer_paragraphs
	shl	ax,4
	push	ax
	mov	si,sp
	push	ds
	push	dword ptr config_xms
	push	ss
	pop	ds
	assume	ds:nothing
	mov	ah,0bh
	mov	bx,sp
	call	dword ptr [bx]
	add	sp,4
	pop	ds
	assume	ds:Bios_Data
	mov	sp,bp
	pop	bp
	cmp	ax,1
	jne	short config_xms_fail
	or	config_flags,3
config_xms_done:
	pop	es
	pop	ds
	assume	ds:nothing
	ret
config_xms_fail:
	assume	ds:Bios_Data
	mov	config_flags,0
	mov	cs:config_buffer_paragraphs,0
	jmp	short config_xms_done
config_xms_init	endp

	public	config_copy
config_copy	proc	near
	cmp	cs:config_buffer_paragraphs,0
	jz	short config_copy_done
	push	cx
	add	di,15
	mov	cx,4
	shr	di,cl
	shl	di,cl
	push	es
	push	di
	mov	ax,di
	shr	ax,cl
	mov	cx,es
	add	ax,cx
	push	ds
	push	si
	push	ax
	mov	cx,cs:config_buffer_paragraphs
	shl	cx,1
	shl	cx,1
	push	cx
	mov	ax,cs:config_buffer_segment
	mov	ds,ax
	assume	ds:nothing
	xor	si,si
	cld
	rep	movsd
	pop	cx
	pop	ax
	mov	ds,cs:bios_data_segment
	assume	ds:Bios_Data
	mov	config_value,ax
	or	config_flags,1
	pop	si
	pop	ds
	assume	ds:nothing
	shl	cx,1
	shl	cx,1
	pop	di
	pop	es
	add	di,cx
	pop	cx
config_copy_done:
	ret
config_copy	endp

	public	config_restore
;
; Check the saved CONFIG$ buffer header and record its location.
; An invalid header clears the saved buffer address and length.
;
config_restore	proc	near
	push	ds
	pusha
	mov	ax,cs:config_buffer_segment
	mov	cx,cs:config_buffer_paragraphs
	or	ax,ax
	jz	short config_restore_bad
	mov	ds,ax
	assume	ds:nothing
	xor	si,si
	shl	cx,4
	cmp	dword ptr [si],4d435744h
	jne	short config_restore_bad
	cmp	[si+8],cx
	jne	short config_restore_bad
	mov	bx,[si+4]
	xchg	bx,cx
	mov	ax,0f0h
	dec	cx
	mul	cx
	add	ax,022ch
	add	ax,15
	and	ax,0fff0h
	cmp	ax,bx
	jne	short config_restore_bad
	inc	cx
	mov	cs:config_buffer_count,cx
	mov	ds,cs:bios_data_segment
	assume	ds:Bios_Data
	mov	config_count,cx
	or	config_flags,1
	mov	ax,cs:config_buffer_segment
	mov	config_value,ax
config_restore_done:
	popa
	pop	ds
	assume	ds:nothing
	ret
config_restore_bad:
	xor	ax,ax
	mov	cs:config_buffer_paragraphs,ax
	mov	cs:config_buffer_segment,ax
	jmp	short config_restore_done
config_restore	endp
	.8086

;----------------------------------------------------------------------------
; procedure : boot_exec_system
;
; Check whether the system file may run and temporarily reduce the last
; memory block.  The original size is restored after the file returns.
;----------------------------------------------------------------------------
;
	.386
	assume	ds:sysinitseg,es:nothing
	extrn	boot_config_flags:byte,bCRTPage:byte
	extrn	memhi:word
	public	boot_exec_system
boot_exec_system	proc	near
	test	boot_config_flags,1
	jnz	short system_mcb_checked
	test	bCRTPage,2
	jnz	short system_mcb_checked
	mov	ax,memhi
	dec	ax
	mov	es,ax
	db	67h,26h,80h,3dh	; cmp byte ptr es:[00000000h],'Z'
	dd	0
	db	'Z'
system_mcb_checked:
	jnz	boot_exec_return
	db	67h,26h,0a1h	; mov ax,es:[00000003h]
	dd	3
	mov	saved_mcb_size,ax
	mov	ax,alloclim
	sub	ax,memhi
	sub	ax,101h
	db	67h,26h,0a3h	; mov es:[00000003h],ax
	dd	3
	.8086
	assume	ds:nothing,es:nothing

;----------------------------------------------------------------------------
; boot_system_exec_block
;
; Set the environment and command-tail segment words for the system file.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg,es:nothing
	extrn	BCodeSeg:word
boot_system_exec_block	label	near
	mov	bx,offset system_exec_block
	push	cs
	pop	es
	assume	es:sysinitseg
	mov	cx,4
	mov	ax,offset system_exec_env_end
	shr	ax,cl
	mov	cx,es
	add	ax,cx
	mov	es:[bx],ax
	mov	es:[bx+4],cx
	mov	system_exec_records+4,cx
	mov	ax,BCodeSeg
	mov	system_exec_records+10,ax
	mov	system_exec_records+28,cx
	mov	system_exec_records+16,cx
	mov	system_exec_records+22,cx
	mov	system_exec_records+34,cx
	mov	system_exec_records+40,cx
	assume	ds:nothing,es:nothing

;----------------------------------------------------------------------------
; boot_system_drive
;
; Resolve the boot drive through the compression mapping and put its letter
; into the two system file names.  Preserve the EXEC parameter pointer.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg,es:sysinitseg
	extrn	default_drive:byte,MagicMoveInfo:dword
boot_system_drive	label	near
	mov	dl,default_drive
	dec	dx
	push	bx
	mov	ax,4a11h
	mov	bx,1
	int	2fh
	test	ax,ax
	jz	short system_drive_mapped
	lds	bx,MagicMoveInfo
	assume	ds:nothing
	cmp	bx,-1
	je	short system_drive_done
	mov	dh,0
	add	bx,dx
	add	bx,dx
	mov	bx,[bx]
	test	bl,80h
	jz	short system_drive_done
system_drive_mapped:
	mov	dl,bl
	and	dl,7fh
system_drive_done:
	pop	bx
	add	dl,'A'
	mov	es:system_io_path,dl
	mov	es:system_winboot_path,dl
	assume	ds:nothing,es:nothing

;----------------------------------------------------------------------------
; boot_prepare_system_file
;
; Check the Windows path and save the path and mode bytes for restoration
; after the system file returns.
;----------------------------------------------------------------------------
;
	extrn	boot_check_windows_path:near
	extrn	query_mode_flags:byte,config_cmd:byte
boot_prepare_system_file	label	near
	push	cs
	pop	ds
	assume	ds:sysinitseg
	call	boot_check_windows_path
	mov	al,0
	xchg	al,exec_windows_path
	mov	ah,exec_mode
	push	ax
	and	query_mode_flags,0bfh
	mov	config_cmd,1
	assume	ds:nothing

;----------------------------------------------------------------------------
; boot_run_system_file
;
; Query before executing WINBOOT.SYS or IO.SYS and save the return code.
; ES:BX points to the EXEC parameter block.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg,es:sysinitseg
	extrn	query_check_skip:near,boot_previous_status:byte
	extrn	sysinit_msg_base:byte,sysinit_msg_table:word
boot_run_system_file	label	near
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+68]
	push	bx
	call	query_check_skip
	pop	bx
	jnc	short exec_winboot
	sub	al,al
	jmp	short exec_save_status
exec_winboot:
	mov	dx,offset system_winboot_path
	mov	ax,4b00h
	int	21h
	jnc	short exec_get_status
	mov	dx,offset system_io_path
	mov	ax,4b00h
	int	21h
	jc	short exec_run_done
exec_get_status:
	mov	ah,4dh
	int	21h
	test	ah,ah
	jnz	short exec_run_done
exec_save_status:
	mov	boot_previous_status,al
exec_run_done:
	assume	ds:nothing,es:nothing

;----------------------------------------------------------------------------
; boot_exec_restore_mcb
;
; Restore the size and last-block marker changed before system file EXEC.
; The following memory references use the 32-bit absolute address form.
;----------------------------------------------------------------------------
;
boot_exec_restore_mcb	label	near
	mov	ax,cs:memhi
	dec	ax
	mov	es,ax
	mov	cx,cs:saved_mcb_size
	db	67h,26h,89h,0dh	; mov es:[00000003h],cx
	dd	3
	db	67h,26h,0c6h,05h	; mov byte ptr es:[00000000h],'Z'
	dd	0
	db	'Z'

;----------------------------------------------------------------------------
; boot_exec_complete
;
; Restore the startup paths and process the system file return status.
; The saved mode and path byte are on the stack.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg,es:sysinitseg
	extrn	boot_winboot_dir:byte
	extrn	boot_prepare_paths:near
	extrn	print:near
boot_exec_complete	label	near
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	pop	ax
	or	exec_mode,ah
	xchg	al,exec_windows_path
	test	al,al
	jz	short exec_check_status
	mov	exec_windows_path,al
	test	boot_config_flags,20h
	jz	short exec_prepare_paths
	mov	boot_winboot_dir,0
exec_prepare_paths:
	call	boot_prepare_paths
exec_check_status:
	cmp	boot_previous_status,0ffh
	jnz	short exec_complete_done
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+86]
	call	print
exec_complete_done:
	assume	ds:nothing,es:nothing

;----------------------------------------------------------------------------
; boot_exec_options
;
; Apply the drive count and query option returned by the system file.
;----------------------------------------------------------------------------
;
	assume	ds:sysinitseg,es:sysinitseg
	extrn	lastdrive_number:near
	extrn	num_cds:byte,default_num_cds:byte,bQueryOpt:byte
boot_exec_options	label	near
	mov	si,offset exec_data
	call	lastdrive_number
	jnc	short exec_drive_store
	mov	al,[si]
	and	al,0dfh
	sub	al,40h
	jbe	short exec_drive_done
	cmp	al,1ah
	ja	short exec_drive_done
exec_drive_store:
	mov	num_cds,al
	mov	default_num_cds,al
exec_drive_done:
	cmp	exec_option,0
	jz	short exec_options_done
	or	bQueryOpt,1
exec_options_done:
	call	config_restore
boot_exec_return:
	ret
boot_exec_system	endp
	assume	ds:nothing,es:nothing

sysinitseg	ends
	end
