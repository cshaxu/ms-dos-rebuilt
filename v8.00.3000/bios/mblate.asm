	include	version.inc
	include	biosseg.inc
	include	msequ.inc

	extrn	BootConfig:far
Bios_Data segment
	extrn	boot_dos_codepage:word,boot_oem_country:word
	extrn	boot_keyboard_type:word,boot_keyboard_layout:word,boot_language_id:word
	extrn	boot_country_file:byte,boot_codepage_file:byte,boot_keyboard_file:byte
Bios_Data ends
Bios_Code segment
	extrn	exec_bios_word:word,Allow_Fat32_Bpb:byte
Bios_Code ends

sysinitseg segment
	assume	cs:sysinitseg,ds:sysinitseg
	extrn	BCodeSeg:word,bios_data_segment:word
	extrn	exec_windows_path:byte,exec_boot_state:byte
	extrn	exec_mode:byte,exec_option:byte,exec_value:word
	extrn	boot_config_flags:byte,boot_system_flags:byte
	extrn	boot_winboot_dir:byte,boot_previous_status:byte
	extrn	query_mode_flags:byte,config_cmd:byte
	extrn	sysinit_msg_base:byte,sysinit_msg_table:word
	extrn	print:near,query_check_skip:near
	extrn	boot_check_windows_path:near,boot_prepare_paths:near
	extrn	lastdrive_number:near
	extrn	num_cds:byte,default_num_cds:byte,bQueryOpt:byte

	public	system_exec_environment,config_environment
system_exec_environment db 200h dup (0)
config_environment dw offset system_exec_environment,0
	public	exec_data
exec_data db 3 dup (0)
	db	6 dup (0)
exec_allow_fat32 dd 1

; Configuration records address SYSINIT, BIOS code and BIOS data.
	public	system_exec_tail,system_exec_records
system_exec_tail label byte
	db	system_exec_tail_end-system_exec_payload
system_exec_payload label byte
	db	0FFh,(system_exec_tail_end-system_exec_records)/6
system_exec_records label word
	dw	40h,offset exec_windows_path,0F000h
	dw	2,offset Bios_Code:exec_bios_word,0F000h
	dw	3,offset exec_data,0F000h
	dw	1,offset exec_mode,0F000h
	dw	1,offset exec_boot_state,0F000h
	dw	1,offset exec_option,0F000h
	dw	2,offset exec_value,0F000h
	dw	4,offset exec_allow_fat32,0F000h
	dw	2,offset Bios_Data:boot_dos_codepage,0F000h
	dw	2,offset Bios_Data:boot_oem_country,0F000h
	dw	2,offset Bios_Data:boot_keyboard_type,0F000h
	dw	2,offset Bios_Data:boot_keyboard_layout,0F000h
	dw	2,offset Bios_Data:boot_language_id,0F000h
	dw	13,offset Bios_Data:boot_country_file,0F000h
	dw	13,offset Bios_Data:boot_codepage_file,0F000h
	dw	13,offset Bios_Data:boot_keyboard_file,0F000h
	dw	200h,0FFFFh,0FFFFh
system_exec_tail_end db 13,0

; Process the system registry and apply the boot configuration.
	.386
	public	boot_exec_system
boot_exec_system proc near
	test	boot_system_flags,1
	jnz	boot_exec_return
	test	boot_config_flags,2
	jnz	boot_exec_return
	mov	cx,ds
	mov	system_exec_records+4,cx
	mov	ax,BCodeSeg
	mov	dx,bios_data_segment
	mov	system_exec_records+10,ax
	mov	system_exec_records+46,cx
	mov	system_exec_records+28,cx
	mov	system_exec_records+16,cx
	mov	system_exec_records+22,cx
	mov	system_exec_records+34,cx
	mov	system_exec_records+40,cx
	mov	system_exec_records+52,dx
	mov	system_exec_records+58,dx
	mov	system_exec_records+64,dx
	mov	system_exec_records+70,dx
	mov	system_exec_records+76,dx
	mov	system_exec_records+82,dx
	mov	system_exec_records+88,dx
	mov	system_exec_records+94,dx
	mov	ax,config_environment
	mov	system_exec_records+98,ax
	mov	ax,config_environment+2
	mov	system_exec_records+100,ax

	call	boot_check_windows_path
	mov	al,exec_windows_path
	or	al,80h
	xchg	al,exec_windows_path
	mov	ah,exec_mode
	push	ax
	and	query_mode_flags,0BFh
	mov	config_cmd,1
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+84]
	push	bx
	call	query_check_skip
	pop	bx
	jnc	short exec_registry
	sub	al,al
	jmp	short exec_save_status
exec_registry:
	push	cs
	push	offset system_exec_tail
	call	BootConfig
	add	sp,4
exec_save_status:
	mov	boot_previous_status,al
	mov	ax,BCodeSeg
	mov	es,ax
	assume	es:Bios_Code
	xor	al,al
	cmp	exec_allow_fat32,0
	jz	short exec_fat32_ready
	inc	al
exec_fat32_ready:
	mov	es:Allow_Fat32_Bpb,al
	mov	ax,cs
	mov	es,ax
	assume	es:sysinitseg
	pop	ax
	or	exec_mode,ah
	xchg	al,exec_windows_path
	test	al,80h
	jnz	short exec_check_status
	mov	exec_windows_path,al
	test	boot_system_flags,20h
	jz	short exec_prepare_paths
	mov	boot_winboot_dir,0
exec_prepare_paths:
	call	boot_prepare_paths
exec_check_status:
	cmp	boot_previous_status,0FFh
	jnz	short exec_drive
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+106]
	call	print
exec_drive:
	mov	si,offset exec_data
	call	lastdrive_number
	jnc	short exec_drive_store
	mov	al,[si]
	and	al,0DFh
	sub	al,40h
	jbe	short exec_drive_done
	cmp	al,1Ah
	ja	short exec_drive_done
exec_drive_store:
	mov	num_cds,al
	mov	default_num_cds,al
exec_drive_done:
	cmp	exec_option,0
	jz	short boot_exec_return
	or	bQueryOpt,1
boot_exec_return:
	ret
boot_exec_system endp
	.8086

sysinitseg ends
	end
