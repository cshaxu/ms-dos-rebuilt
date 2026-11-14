BYTE_SYSINIT equ 1
	page	,160
;
;       Microsoft Confidential
;       Copyright (C) Microsoft Corporation 1981-1991
;       All Rights Reserved.
;

	title   bios system initialization

;
; Startup options, default drivers and command interpreter selection.
;

MULTI_CONFIG equ 1
CONFIG_LOGO equ 'q'

break   macro
	endm

	.xlist
	include version.inc		; set version build flags
	include biosseg.inc		; establish bios segment structure
	.list

lf	equ	10
cr	equ	13
tab	equ	9

; the following depends on the positions of the various letters in switchlist

switchnum	equ 11111000b		; which switches require number

	.xlist
	include	bpb.inc
	include exe.inc
	include syscall.inc
	include sysvar.inc
	include doscntry.inc
	include devsym.inc
	include ioctl.inc
	include devmark.inc
	include config.inc
ifdef   MULTI_CONFIG
	include rombios.inc
endif
	.list

stacksw equ     true                    ; include switchable hardware stacks

	if	ibmjapver
noexec	equ	true
	else
noexec	equ	false
	endif


Bios_Data segment 
Bios_Data ends

Bios_Code segment
	extrn	int19_restore:far
	extrn	win386_info_flags:byte
	extrn	exec_bios_word:word
	extrn	win386_text_length:word,win386_text_buffer:byte
	extrn	win386_options_path:byte
	extrn	win386_info_buffer:byte,win386_info_table:byte
Bios_Code ends

sysinitseg segment public

	extrn	sysinit_msg_table:word,sysinit_msg_base:byte
	extrn	IsXMSLoaded:near
	extrn	print_indexed:near

assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

ifdef   MULTI_CONFIG

	MAX_MULTI_CONFIG equ 9          ; max # of multi-config menu items supported

	extrn	BCodeSeg:word
	extrn	MagicMoveInfo:dword
	extrn	boot_check_redirected_drive:near,boot_check_drive_map:near
	extrn	DevUMB:byte
	extrn	stack_high:byte
	extrn	multi_pass_id:byte,multi_pass_config_line:near
	extrn	dos_umb_flag:byte
	extrn	exec_mode:byte,exec_option:byte,exec_value:word
	extrn	config_envlen:word
	extrn	config_wrkseg:word
	extrn	new_psp_segment:word
	extrn	AllocFreeMem:near,boot_mode:byte
	extrn	config_cmd:byte
	extrn	config_multi:byte

	public  newcmd,tmplate,commnd2,commnd3,commnd4
endif

IFDEF	CONFIGPROC


	extrn	dosinfo:dword
	extrn	default_drive:byte,confbot:word
	extrn	zero:byte
	extrn	count:word,chrptr:word


ENDIF ; CONFIGPROC

	extrn	memhi:word,alloclim:word
	extrn	badmem:byte

	extrn	stall:near


public  commnd,command_line


IFDEF	CONFIGPROC


assume ds:nothing, es:nothing


extrn	badfil:near
extrn	copy_envvar:near,display_menu:near,print:near,query_check_skip:near,query_user:near
extrn	config:byte,boot_config_flags:byte,boot_runtime_flags:byte
extrn	bqueryopt:byte,query_mode_flags:byte,bdefblock:byte,bmaxblock:byte,sectimeout:byte
extrn	aoffblockdesc:word,linecount:word
public boot_safe,boot_menu,boot_config_name,boot_toupper
; the following depend on the positions of the various letters in switchlist

;switchnum	equ 11111000b		; which switches require number

flagec35	equ 00000100b		; electrically compatible 3.5 inch disk drive
flagdrive	equ 00001000b
flagcyln	equ 00010000b
flagseclim	equ 00100000b
flagheads	equ 01000000b
flagff		equ 10000000b
	public  boot_delay
boot_delay      dw      2               ; startup delay in seconds
boot_menu       db      0               ; show startup menu
boot_menu_default db    1               ; default startup menu selection
boot_menu_delay dw      30              ; startup menu timeout
boot_safe       db      0               ; safe startup requested
boot_network    db      0               ; network startup requested
boot_config_name db     32 dup (0)      ; BOOTCONFIG selection

; Windows directories and host drive from the startup options file.
	public  exec_windows_path
exec_windows_path label byte
boot_windows_dir db 0,':\WINDOWS',0,53 dup (0)
	db      14 dup (0)             ; adjacent path workspace
boot_windows_dir_len dw 0
	public  boot_winboot_command
boot_winboot_command label byte
	db      3 dup (0)
boot_winboot_dir db 0,':\WINDOWS',0,53 dup (0)
	db      14 dup (0)             ; adjacent path workspace
boot_winboot_dir_len dw 0
boot_host_drive db 2 dup (0)
boot_previous_menu db 3                ; previous startup menu choice
boot_command_dir db '\COMMAND'
	public  boot_previous_status,boot_winboot_dir
boot_previous_status db 0ffh,0ffh,'/D /Y '
	public  boot_device_scratch
boot_device_scratch db 78 dup (0)      ; temporary startup device path
boot_device_reserved db 64 dup (0)

; Default environment strings.  Several entries share their trailing data.
boot_env_tmp db 'TMP='
boot_env_temp db 'TEMP='
boot_temp_dir db '\TEMP'
boot_env_prompt db 'PROMPT=$p$g',0
boot_env_winboot db 'winbootdir='
boot_env_path db 'PATH='
boot_netstart_cmd db ' /K NETSTART',0
boot_autoexec_cmd db ' /D /K AUTOEXEC',0
boot_env_comspec db 'COMSPEC='
	public  boot_restart_status
boot_restart_status db '\WNBOOTNG.STS',0

; Built-in startup driver names and command tails.
boot_himem_name db '\HIMEM.SYS',0,'/TESTMEM:ON',0dh

; Names used to recognize the Adaptec real-mode drivers.
	public  aspi2dos_loaded,aspi2hlp_loaded
	public  aspi2dos_name,aspi2hlp_name
aspi2dos_loaded db      0
aspi2hlp_loaded db      0
aspi2dos_name   db      '\ASPI2DOS.SYS',0
aspi2hlp_name   db      '\ASPI2HLP.SYS',0

boot_dblbuff_name db '\DBLBUFF.SYS',0,'/D+',0dh
boot_ifshlp_driver db '\IFSHLP.SYS',0
boot_setver_driver db '\SETVER.EXE',0

	public  boot_emm_name,boot_qmm_name,boot_ifshlp_name,boot_setver_name
boot_emm_name db 'EMMXXXX0',0
boot_qmm_name db 'QMMXXXX0',0
boot_ifshlp_name db 'IFS$HLP$',0
boot_setver_name db 'SETVERXX',0

; Startup driver records: check procedure, name, length and flags.
boot_autoexec_name db '\AUTOEXEC.BAT',0
	public  boot_driver_table,boot_himem_record_length,boot_driver_depth
boot_driver_table label word
	dw      offset IsXMSLoaded,offset boot_himem_name
boot_himem_record_length db 17h,81h
	dw      offset boot_check_aspi,offset aspi2hlp_name
	db      0eh,0
	dw      offset boot_double_provider,offset boot_dblbuff_name
boot_driver_entry1 db 11h,81h
	dw      offset boot_check_ifshlp,offset boot_ifshlp_driver
	db      0ch,1
	dw      offset boot_check_setver,offset boot_setver_driver
	db      0ch,0
	dw      0
	public  boot_umb_driver_record
boot_umb_driver_record label word
	dw      offset boot_check_umb_manager,offset boot_dblbuff_name
boot_driver_entry2 db 11h,80h
boot_driver_depth db 0ffh

; Extended FCB used to locate earlier DOS system files.
	public  boot_copy_buffer
boot_copy_buffer label byte            ; saved boot parameters and drive
boot_old_sector db 62 dup (0)
boot_old_bx dw 0
boot_old_ax dw 0
boot_old_si dd 0
boot_old_dx dw 0
	public  boot_old_image_seg
boot_old_image_seg dw 0
boot_find_fcb db 0ffh,5 dup (0),7,0
boot_find_name db 'IO      DOS'
	db      25 dup (0)

; Names used for earlier versions of DOS.
boot_old_msdos_fcb db 'MSDOS   DOS'
boot_old_ibmbio_fcb db 'IBMBIO  COM'
boot_old_ibmdos_fcb db 'IBMDOS  COM'
boot_old_io_name db 'IO.DOS',0
boot_old_ibmbio_name db 'IBMBIO.COM',0

; Startup mode names and file names.
boot_old_w40 db 'W40'
boot_old_dos db 'DOS'
boot_old_wos db 'WOS'
boot_old_app db 'APP',12 dup (' '),0

; Files used to identify a restart into MS-DOS mode.
	public  boot_config_app,boot_config_wos
boot_config_app db 'CONFIG.APP',0
boot_config_wos db 'CONFIG.WOS',0
	public  boot_msdos_status
boot_msdos_status db 'C:\MSDOSSYS.STS',0

; Startup option file names, including length bytes used by startup.
boot_io_entry db 3
boot_io_file db 'IO.SYS',0
boot_msdos_entry db 6
boot_msdos_name db 'MSDOS.SYS',0
boot_msdos_root db 'C:\MSDOS.SYS',0
boot_command_entry db 8
boot_command_name db 'COMMAND.COM',0
boot_config_entry db 7
boot_config_file db 'CONFIG.SYS',0
boot_autoexec_entry db 9
boot_autoexec_file db 'AUTOEXEC.BAT',0
boot_dblspace_entry db 9
boot_dblspace_file db 'DBLSPACE.BIN',0
boot_drvspace_entry db 9
boot_drvspace_file db 'DRVSPACE.BIN',0

; Startup file name tables.
	public  boot_dos_file_table,boot_windows_file_table
boot_dos_file_table label word
	dw      offset boot_old_w40,offset boot_old_dos
	dw      offset boot_io_entry,offset boot_msdos_entry
	dw      offset boot_command_entry,offset boot_config_entry
	dw      offset boot_autoexec_entry,offset boot_dblspace_entry
	dw      offset boot_drvspace_entry,0
boot_windows_file_table label word
	dw      offset boot_old_wos,offset boot_old_app
	dw      offset boot_config_entry,offset boot_autoexec_entry,0

boot_io_w40_entry db 6
boot_io_w40 db 'IO.W40',0
boot_winboot_sys_entry db 11
boot_winboot_sys db 'WINBOOT.SYS',0
boot_msdos_w40_entry db 9
boot_msdos_w40 db 'MSDOS.W40',0
boot_winboot_ini_entry db 11
boot_winboot_ini db 'WINBOOT.INI',0

	if      not NOEXEC
	public  comexe
comexe  exec1   <0,command_line,default_drive,zero,0,0,0,0>
	endif

; Command paths and command tails retained for startup fallback.

	public  default_switch_char,command_line2,command_line3
default_switch_char db 0
newcmd		db	0
tmplate		db	78
		db	12
commnd		db	"\COMMAND.COM",0
		db	65 dup (0)
command_line	db	3," /P"
		db	124 dup (0)
commnd2		db	"\COMMAND.COM",0
		db	65 dup (0)
command_line2	db	3," /P"
		db	124 dup (0)
commnd3		db	"\COMMAND.COM",0
		db	65 dup (0)
command_line3	db	3," /P"
		db	124 dup (0)
commnd4		db	"\WIN.COM",0
		db	69 dup (0)
		db	0,0dh
		public	winboot_shell_pending
winboot_shell_pending db 0
boot_autoexec_exists db 0
	public  boot_safe_message
boot_safe_message db '(Safe boot)',13,10


	assume  ds:nothing

	assume  ds:sysinitseg


; Select and start the command interpreter.
; This code may be reused as a buffer after it has executed.

	public  boot_shell_main,boot_shell_scratch
boot_shell_main proc near
	assume  ds:sysinitseg,es:nothing
	call    boot_check_windows_path
	mov     es,[BCodeSeg]
	assume  es:Bios_Code
	mov     al,es:[win386_options_path]
	call    boot_resolve_mapped_drive
	jc      short shell_drive_done
	cmp     al,es:[win386_options_path]
	je      short shell_drive_done
	mov     es:[win386_options_path],al
	mov     es:[win386_info_flags-1],al
	mov     [boot_msdos_status],al
shell_drive_done:
	cmp     byte ptr [boot_mode],2
	jne     short shell_safe_check
	mov     dx,offset boot_msdos_status
	mov     ah,unlink
	int     21h
shell_safe_check:
	test    byte ptr [query_mode_flags],1
	jz      short shell_environment
	mov     ax,4a16h
	int     2fh
	mov     dx,offset boot_safe_message
	mov     ax,4a17h
	mov     cx,13
	int     2fh
	mov     ax,4a18h
	int     2fh
shell_environment:
	cld
	mov     es,[new_psp_segment]
	assume  es:nothing
	mov     es:[2ch],ds
	xor     bx,bx
	mov     [bx],bx
	cmp     byte ptr [boot_autoexec_exists],0
	je      short shell_windows_prompt
	and     byte ptr [query_mode_flags],0bfh
	mov     byte ptr [config_cmd],1
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+74]
	call    query_user
	jnc     short shell_flags
	or      byte ptr [query_mode_flags],20h
	call    rotate_shell_records
shell_windows_prompt:
	cmp     byte ptr [winboot_shell_pending],0
	je      short shell_flags
	and     byte ptr [query_mode_flags],0bfh
	mov     byte ptr [config_cmd],1
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+76]
	call    query_check_skip
	jnc     short shell_flags
	mov     byte ptr [commnd],0
	mov     byte ptr [newcmd],0
	mov     byte ptr [winboot_shell_pending],0
shell_flags:
	mov     es,[BCodeSeg]
	assume  es:Bios_Code
	mov     al,[query_mode_flags]
	test    al,10h
	jz      short shell_mask_flags
	and     al,0f7h
shell_mask_flags:
	and     al,8fh
	or      es:[win386_info_flags],al
	mov     al,[boot_config_flags]
	and     al,20h
boot_shell_scratch equ $+4
	or      es:[win386_info_flags],al
shell_retry:
	cmp     byte ptr [commnd],0
	je      shell_prompt
	mov     di,offset command_line
	call    disable_autoexec
	call    enable_autoexec_query
	lea     bx,[di+1]
	add     bl,[di]
	adc     bh,0
	mov     byte ptr [bx],0dh
	mov     dx,offset commnd
	call    boot_size_shell
	jc      short shell_failed
	call    boot_exec_shell
shell_failed:
	cmp     byte ptr [commnd3],0
	je      short shell_error
	cmp     byte ptr [newcmd],0
	je      short shell_prompt
shell_error:
	cmp     ax,1
	jne     short shell_error_name
	call    print_indexed
	dw      800eh
	jmp     short shell_prompt
shell_error_name:
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+18]
	cmp     byte ptr [winboot_shell_pending],0
	jne     short shell_show_error
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+20]
	cmp     byte ptr [command_line],0
	jne     short shell_show_error
	mov     dx,offset commnd
shell_show_error:
	call    badfil
shell_prompt:
	mov     ah,get_default_drive
	int     21h
	add     al,'A'
	mov     dl,al
	mov     si,offset commnd2
	cmp     byte ptr [si],0
	jne     short shell_use_fallback
	mov     si,offset commnd3
	cmp     byte ptr [si],0
	jne     short shell_use_fallback
	push    dx
	call    print_indexed
	dw      8019h
	pop     dx
shell_prompt_input:
	mov     ah,std_con_output
	int     21h
	push    dx
	mov     dl,'>'
	int     21h
	mov     bl,[commnd-1]
	mov     bh,0
	mov     byte ptr [commnd+bx],0dh
	mov     dx,offset commnd-2
	mov     ah,std_con_string_input
	int     21h
	call    print_indexed
	dw      8005h
	pop     dx
	mov     bl,[commnd-1]
	or      bl,bl
	jz      short shell_prompt_input
	mov     byte ptr [newcmd],1
	mov     byte ptr [commnd+bx],0
	mov     byte ptr [command_line],0
	jmp     short shell_retry_reset
shell_use_fallback:
	mov     bx,si
	push    ds
	pop     es
	mov     byte ptr [newcmd],0
	mov     di,offset commnd
shell_copy_name:
	lodsb
	mov     byte ptr [si-1],0
	stosb
	or      al,al
	jnz     short shell_copy_name
	mov     di,offset command_line
	lea     si,[bx+78]
shell_copy_tail:
	lodsb
	stosb
	or      al,al
	jnz     short shell_copy_tail
shell_retry_reset:
	mov     byte ptr [winboot_shell_pending],0
	jmp     shell_retry
boot_shell_main endp

;----------------------------------------------------------------------------
; procedure : boot_check_windows_path
;
; Check the Windows path on its mapped drive, the host drive, and then the
; remaining local drives.  Preserve the original drive letter on failure.
;----------------------------------------------------------------------------
;
	public  boot_check_windows_path
boot_check_windows_path proc near
	push    ds
	push    bx
	mov     al,[boot_winboot_dir]
	call    boot_resolve_mapped_drive
	jnc     short path_use_drive
	mov     al,[boot_host_drive]
path_use_drive:
	mov     ds,[BCodeSeg]
	assume  ds:nothing
	mov     bx,offset Bios_Code:win386_text_buffer
	xchg    al,[bx]
	mov     dx,bx
	push    ax
	mov     ax,chmod shl 8
	int     21h
	pop     ax
	jnc     short path_done
	push    es
	push    di
	push    ax
	mov     di,bx
	push    ds
	pop     es
	cld
	xor     al,al
	mov     cx,40h
	repne   scasb
	jnz     short path_restore
	dec     di
	dec     di
	push    word ptr [di]
	mov     byte ptr [di],'0'
	push    di
	mov     dx,bx
	mov     ax,chmod shl 8
	int     21h
	pop     di
	pop     ax
	mov     [di],al
	jnc     short path_restore
	mov     di,bx
	mov     dl,3
path_next_drive:
	mov     ah,get_dpb
	int     21h
	cmp     al,0ffh
	je      short path_advance
	push    es
	pop     ds
	mov     al,dl
	add     al,40h
	mov     [di],al
	push    dx
	mov     dx,di
	mov     ax,chmod shl 8
	int     21h
	pop     dx
	jnc     short path_restore
path_advance:
	inc     dx
	cmp     dl,1ah
	jbe     short path_next_drive
	pop     ax
	mov     [di],al
	push    ax
path_restore:
	pop     ax
	pop     di
	pop     es
path_done:
	pop     bx
	pop     ds
	ret
boot_check_windows_path endp
	assume  ds:sysinitseg

;----------------------------------------------------------------------------
; procedure : boot_resolve_mapped_drive
;
; Resolve a startup drive through IOCTL, drive mapping and compression.
; AL contains a drive letter and returns the resolved letter on success.
; Carry is set when no mapping is available.
;----------------------------------------------------------------------------
;
	public  boot_resolve_mapped_drive
boot_resolve_mapped_drive proc near
	push    ds
	sub     al,40h
	push    ax
	or      al,40h
	call    boot_check_redirected_drive
	or      ax,ax
	jnz     short resolve_drive_exit
	pop     ax
	push    ax
	call    boot_check_drive_map
	or      ax,ax
	jnz     short resolve_drive_exit
	pop     dx
	push    dx
	dec     dx
	mov     ax,4a11h
	mov     bx,1
	int     2fh
	test    ax,ax
	jz      short resolve_drive_number
	lds     bx,MagicMoveInfo
	cmp     bx,-1
	je      short resolve_drive_fail
	mov     dh,0
	add     bx,dx
	add     bx,dx
	mov     bx,[bx]
	test    bl,80h
	jz      short resolve_drive_fail
resolve_drive_number:
	mov     al,bl
	and     al,7fh
	add     al,41h
	jmp     short resolve_drive_exit
resolve_drive_fail:
	stc
resolve_drive_exit:
	pop     dx
	pop     ds
	ret
boot_resolve_mapped_drive endp

; Execute the selected command interpreter.
; DS:DX points to its name.  Return AX = 2 if EXEC returns.

	public	boot_exec_shell
boot_exec_shell proc near
	push	cs
	pop	es
	mov	bx,offset comexe
	mov	cx,[config_envlen]
	jcxz	short shell_env_ready
	mov	cx,[config_wrkseg]
shell_env_ready:
	mov	[bx.exec0_environ],cx
	mov	word ptr [bx.exec0_com_line+2],cs
	mov	word ptr [bx.exec0_5c_fcb+2],cs
	mov	word ptr [bx.exec0_6c_fcb+2],cs
	mov	ax,(exec shl 8)
	stc
	int	21h
	push	cs
	pop	ds
	mov	ax,2
	ret
boot_exec_shell endp

; Check the selected interpreter and available memory.
; DS:DX points to the file name.  Carry is set on failure.

	public  boot_size_shell
	.386
boot_size_shell proc near
	assume  ds:sysinitseg,es:nothing
	push    dx
	call    AllocFreeMem
	jc      short shell_size_memory_error
	mov     es,ax
	mov     ah,dealloc
	int     21h
	mov     bp,bx
	mov     ax,cs
	mov     bx,[config_envlen]
	test    bx,bx
	jz      short shell_size_env_ready
	mov     ax,[config_wrkseg]
shell_size_env_ready:
	mov     cx,es
	add     cx,bp
	cmp     cx,ax
	jbe     short shell_size_open
	mov     cx,es
	add     bx,15
	shr     bx,4
	add     cx,bx
	cmp     ax,cx
shell_size_memory_error:
	jae     short shell_size_open
	jmp     near ptr shell_size_no_memory
shell_size_open:
	mov     ax,open shl 8
	stc
	int     21h
	jnc     short shell_size_opened
	jmp     near ptr shell_size_bad_file
shell_size_opened:
	mov     bx,ax
	cmp     byte ptr [newcmd],0
	jne     short shell_size_seek_end
	mov     dx,offset boot_shell_scratch-1
	mov     cx,2
	mov     ah,read
	int     21h
	jc      short shell_size_close
	cmp     word ptr [boot_shell_scratch-1],5a4dh
	stc
	jne     short shell_size_close
	mov     dx,8
	xor     cx,cx
	mov     ax,lseek shl 8
	int     21h
	jc      short shell_size_close
	mov     dx,offset boot_shell_scratch-1
	mov     cx,2
	mov     ah,read
	int     21h
	jc      short shell_size_close
	cmp     ax,cx
	stc
	jne     short shell_size_close
	mov     dx,word ptr [boot_shell_scratch-1]
	mov     cl,4
	shl     dx,cl
	xor     cx,cx
	mov     ax,lseek shl 8
	int     21h
	jc      short shell_size_close
	mov     dx,offset boot_shell_scratch
	mov     cx,1
	mov     ah,read
	int     21h
	jc      short shell_size_close
	cmp     byte ptr [boot_shell_scratch],70h
	stc
	jne     short shell_size_close
shell_size_seek_end:
	xor     cx,cx
	xor     dx,dx
	mov     ax,(lseek shl 8) or 2
	stc
	int     21h
shell_size_close:
	pushf
	push    ax
	mov     ah,close
	int     21h
	pop     ax
	popf
	jc      short shell_size_bad_file
	add     ax,15
	adc     dx,0
	shr     ax,4
	mov     cl,12
	shl     dx,cl
	or      ax,dx
	add     ax,10h
	cmp     bp,ax
	jb      short shell_size_no_memory
shell_size_return:
	pop     dx
	ret
shell_size_bad_file:
	mov     ax,2
	stc
	jmp     short shell_size_return
shell_size_no_memory:
	mov     ax,1
	jmp     short shell_size_return
boot_size_shell endp
	.8086


; Check UMB support and installed expanded-memory managers.
	public  boot_check_umb_manager,boot_check_umb_stack,boot_check_umb_rom
	public  boot_double_provider,boot_check_aspi,boot_check_ifshlp,boot_check_setver
boot_check_umb_manager proc near
	cmp     byte ptr [DevUMB],0
	je      boot_umb_done
	push    ds
	xor     ax,ax
	mov     ds,ax
	assume  ds:nothing
	mov     ax,word ptr ds:[019eh]
	cmp     ax,1
	jb      boot_umb_restore_ds
	mov     ds,ax
	cmp     word ptr ds:[0bh],'MM'
	jne     boot_umb_restore_ds
	cmp     word ptr ds:[0eh],'XX'
boot_umb_restore_ds:
	pop     ds
	assume  ds:sysinitseg
	je      boot_umb_found
	mov     dx,offset boot_emm_name
	call    boot_check_device
	je      boot_umb_found
	mov     dx,offset boot_qmm_name
	call    boot_check_device
	je      boot_umb_found
	sub     ax,ax
	jmp     short boot_umb_done
boot_umb_found:
	call    boot_double_provider
boot_umb_done:
	ret
boot_check_umb_manager endp

; Check the expanded-memory manager version before placing stacks high.
boot_umb_ioctl dw 2
boot_check_umb_stack proc near
	cmp     byte ptr [DevUMB],0
	jne     boot_umb_stack_enabled
	jmp     near ptr boot_umb_stack_done
boot_umb_stack_enabled:
	cmp     byte ptr [stack_high],0
	je      boot_umb_stack_done
	push    ds
	xor     ax,ax
	mov     ds,ax
	assume  ds:nothing
	mov     ax,word ptr ds:[019eh]
	cmp     ax,1
	jb      boot_umb_stack_pop_ds
	mov     ds,ax
	mov     si,0ah
	cmp     word ptr [si+1],'MM'
	jne     boot_umb_stack_pop_ds
	cmp     word ptr [si+4],'XX'
	jne     boot_umb_stack_pop_ds
	cld
	mov     di,offset boot_device_scratch
	mov     dx,di
	mov     cx,8
	rep     movsb
	mov     al,0
	stosb
	pop     ds
	assume  ds:sysinitseg
	push    dx
	mov     dl,1
	mov     ax,3307h
	int     21h
	pop     dx
	mov     ax,open shl 8
	int     21h
	jc      boot_umb_stack_no_file
	xchg    ax,bx
	mov     ax,4400h
	int     21h
	jc      boot_umb_stack_close
	test    dx,80h
	jz      boot_umb_stack_close
	test    dx,4000h
	jz      boot_umb_stack_close
	mov     dx,offset boot_umb_ioctl
	mov     cx,2
	mov     ax,4402h
	int     21h
	jc      boot_umb_stack_close
	cmp     ax,cx
	jne     boot_umb_stack_close
	mov     si,dx
	mov     ax,[si]
	xchg    al,ah
	cmp     ax,043ch
	jae     boot_umb_stack_close
	mov     byte ptr [stack_high],0
boot_umb_stack_close:
	mov     ax,close shl 8
	int     21h
boot_umb_stack_no_file:
	jmp     short boot_umb_stack_done
boot_umb_stack_pop_ds:
	pop     ds
	assume  ds:sysinitseg
boot_umb_stack_done:
	ret
boot_check_umb_stack endp

boot_umb_rom_id db 'IBM ThinkPad 510'

; Disable high stacks for the affected system ROM.
boot_check_umb_rom proc near
	cmp     byte ptr [DevUMB],0
	je      boot_umb_rom_done
	cmp     byte ptr [stack_high],0
	je      boot_umb_rom_done
	cld
	push    es
	mov     di,0f000h
	mov     es,di
	mov     di,0b000h
	mov     al,[boot_umb_rom_id]
	mov     cx,1000h
boot_umb_rom_search:
	repne   scasb
	jcxz    boot_umb_rom_restore
	push    cx
	push    di
	mov     cx,15
	mov     si,offset boot_umb_rom_id+1
	repe    cmpsb
	pop     di
	pop     cx
	jne     boot_umb_rom_search
	mov     byte ptr [stack_high],0
boot_umb_rom_restore:
	pop     es
boot_umb_rom_done:
	ret
boot_check_umb_rom endp


; Check the double-buffer provider and select the driver record types.
boot_double_provider proc near
	push    bx
	push    di
	push    es
	mov     ax,4a10h
	mov     bx,5
	int     2fh
	pop     es
	pop     di
	pop     bx
	cmp     ax,0babeh
	je      boot_double_done
	test    byte ptr [query_mode_flags],1
	je      boot_double_mode
	mov     byte ptr [boot_driver_entry1],11h
	mov     byte ptr [boot_driver_entry2],11h
	ret
boot_double_mode:
	cmp     byte ptr [exec_mode],0
boot_double_done:
	ret
boot_double_provider endp

; Return the combined ASPI driver state in the condition codes.
boot_check_aspi proc near
	cmp     byte ptr [aspi2dos_loaded],0
	je      boot_aspi_done
	cmp     byte ptr [aspi2hlp_loaded],1
boot_aspi_done:
	ret
boot_check_aspi endp

; Check whether the named startup device is present.
boot_check_ifshlp proc near
	mov     dx,offset boot_ifshlp_name
	jmp     short boot_check_device
boot_check_ifshlp endp

boot_check_setver proc near
	mov     dx,offset boot_setver_name
boot_check_setver endp

boot_check_device proc near
	push    bx
	push    dx
	mov     dl,1
	mov     ax,3307h
	int     21h
	pop     dx
	mov     ax,open shl 8
	int     21h
	jc      boot_check_device_done
	xchg    ax,bx
	mov     ah,close
	int     21h
boot_check_device_done:
	sbb     ax,ax
	pop     bx
	ret
boot_check_device endp

; Find and load the previous DOS system files.
	.286
	public  boot_load_old_dos
boot_load_old_dos proc near
	push    ds
	mov     ah,get_dma
	int     21h
	push    es
	push    bx
	mov     ds,[memhi]
	sub     dx,dx
	mov     ah,set_dma
	int     21h
	push    ds
	pop     es
	push    cs
	pop     ds
	mov     di,offset boot_old_io_name
	mov     si,offset boot_find_name
	call    boot_find_old_file
	jz      short old_load_first_found
	mov     di,offset boot_old_ibmbio_name
	mov     si,offset boot_old_ibmbio_fcb
	call    boot_find_old_file
	jz      short old_load_first_found
	jmp     old_load_not_found
old_load_first_found:
	mov     bx,es:[22h]
	mov     si,offset boot_old_msdos_fcb
	call    boot_find_old_file
	jz      short old_load_second_found
	mov     si,offset boot_old_ibmdos_fcb
	call    boot_find_old_file
	jz      short old_load_second_found
	jmp     old_load_not_found
old_load_second_found:
	mov     cx,es:[22h]
	jcxz    old_load_bad_image
	sub     dx,dx
	mov     es,dx
	mov     es:[51ah],bx
	mov     es:[53ah],cx
	mov     dx,di
	mov     ax,open shl 8
	int     21h
	jc      short old_load_restore
	mov     bx,ax
	mov     ax,[alloclim]
	sub     ax,60h
	mov     ds,ax
	assume  ds:nothing
	sub     dx,dx
	mov     cx,600h
	mov     ah,read
	int     21h
	jc      short old_load_bad_image
	cmp     ax,cx
	jne     short old_load_bad_image
	cmp     byte ptr ds:[0],0e9h
	je      short old_load_version
	cmp     byte ptr ds:[0],0ebh
	jne     short old_load_bad_image
old_load_version:
	mov     ax,word ptr ds:[3]
	xchg    al,ah
	cmp     ax,500h
	jb      short old_load_bad_image
	cmp     ax,800h
	jae     short old_load_bad_image
	mov     word ptr cs:[boot_old_image_seg],ds
	mov     word ptr cs:[alloclim],ds
	or      byte ptr cs:[query_mode_flags],1
	push    bx
	mov     bx,offset boot_dos_file_table
	call    boot_old_file_table
	pop     bx
	jmp     short old_load_close
old_load_bad_image:
	push    cs
	pop     ds
	assume  ds:sysinitseg
	call    print_indexed
	dw      8039h
	call    print_indexed
	dw      803ah
old_load_close:
	mov     ah,close
	int     21h
	jmp     short old_load_restore
old_load_not_found:
	push    cs
	pop     ds
	call    print_indexed
	dw      8038h
	call    print_indexed
	dw      803ah
old_load_restore:
	pop     dx
	pop     ds
	assume  ds:nothing
	mov     ah,set_dma
	int     21h
	pop     ds
	ret
boot_load_old_dos endp
	assume  ds:sysinitseg,es:sysinitseg

; Rename the system files selected by the table at DS:BX.
;
	public  boot_old_file_table
boot_old_file_table proc near
	cld
	push    cs
	pop     ds
	push    cs
	pop     es
	test    byte ptr [boot_runtime_flags],80h
	jz      short old_table_start
	cmp     bx,offset boot_dos_file_table
	jne     short old_table_start
	ret
old_table_start:
	sub     sp,4
	mov     bp,sp
	mov     ax,[bx]
	mov     dx,[bx+2]
	add     bx,4
	mov     [bp],ax
	mov     [bp+2],dx
	cmp     word ptr [boot_old_image_seg],0
	je      short old_table_next
	mov     [bp],dx
	mov     [bp+2],ax
old_table_next:
	mov     si,[bx]
	or      si,si
	jnz     short old_table_name
	jmp     old_table_done
old_table_name:
	lodsb
	cbw
	xchg    ax,cx
	mov     di,offset boot_old_app+3
	mov     dx,di
	rep     movsb
	mov     si,[bp]
	mov     cl,3
	rep     movsb
	mov     al,0
	stosb
	push    dx
	push    di
	mov     di,dx
	call    boot_old_filename
	mov     dx,di
	mov     ax,chmod shl 8
	int     21h
	pop     di
	pop     dx
	jnc     short old_table_check
	jmp     old_table_advance
old_table_check:
	test    cl,2
	jz      short old_table_rename
	or      ax,-1
	cmp     word ptr [bx],offset boot_io_entry
	je      short old_table_rename
	cmp     word ptr [bx],offset boot_msdos_entry
	je      short old_table_rename
	call    boot_old_file_size
old_table_rename:
	push    ax
	push    cx
	push    dx
	push    di
	push    bx
	mov     dx,[bx]
	inc     dx
	mov     si,[bp+2]
	sub     di,4
	mov     cx,3
	rep     movsb
	mov     al,0
	stosb
	mov     di,offset boot_old_app+3
	call    boot_old_filename
	mov     ah,rename
	int     21h
	jnc     short old_table_restore
	cmp     ax,2
	jne     short old_table_error
	mov     dx,di
	mov     ax,chmod shl 8
	int     21h
	jnc     short old_table_restore
	mov     cx,2
	mov     ah,creat
	int     21h
	jc      short old_table_restore
	xchg    ax,bx
	mov     ah,close
	int     21h
	jmp     short old_table_restore
old_table_error:
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+84]
	call    print
	mov     bx,dx
	mov     byte ptr [bx],'$'
old_table_restore:
	pop     bx
	pop     di
	pop     dx
	mov     si,[bp]
	sub     di,4
	mov     cx,3
	rep     movsb
	mov     al,0
	stosb
	mov     di,offset boot_old_app+3
	call    boot_old_filename
	mov     dx,di
	pop     ax
	pop     cx
	test    al,2
	jz      short old_table_final_rename
	test    cx,cx
	jnz     short old_table_final_rename
	mov     ah,unlink
	int     21h
	jmp     short old_table_advance
old_table_final_rename:
	mov     di,[bx]
	inc     di
	mov     ah,rename
	int     21h
old_table_advance:
	inc     bx
	inc     bx
	jmp     old_table_next
old_table_done:
	add     sp,4
	ret
boot_old_file_table endp

; Return zero if the file named by DS:DX is empty.
boot_old_file_size proc near
	mov     ax,open shl 8
	int     21h
	jc      short boot_old_size_done
	push    bx
	push    cx
	push    dx
	xchg    ax,bx
	sub     cx,cx
	sub     dx,dx
	mov     ax,(lseek shl 8) or 2
	int     21h
	add     dx,-1
	sbb     dx,dx
	or      ax,dx
	xchg    ax,cx
	mov     ah,close
	int     21h
	xchg    ax,cx
	pop     dx
	pop     cx
	pop     bx
boot_old_size_done:
	ret
boot_old_file_size endp

; Use WINBOOT.SYS when the old system file is IO.W40.
boot_old_filename proc near
	mov     ch,0
	mov     ax,di
	mov     si,offset boot_io_w40_entry
	mov     cl,[si]
	inc     si
	repe    cmpsb
	jne     short boot_old_filename_done
	mov     ax,offset boot_winboot_sys
boot_old_filename_done:
	xchg    ax,di
	ret
boot_old_filename endp

; Start the earlier DOS image if one has been loaded.
	public  boot_start_old_dos
boot_start_old_dos proc near
	cmp     word ptr cs:[boot_old_image_seg],0
	je      short boot_old_start_done
	cli
	mov     bp,offset Bios_Code:int19_restore
	push    cs
	call    boot_bios_far_call
	mov     ds,word ptr cs:[boot_old_image_seg]
	sub     si,si
	mov     ax,70h
	mov     es,ax
	sub     di,di
	mov     cx,300h
	cld
	rep     movsw
	push    cs
	pop     ds
	mov     si,offset boot_old_sector
	mov     cx,23h
	sub     ax,ax
	mov     es,ax
	mov     di,7c00h
	rep     movsw
	mov     bx,[boot_old_bx]
	mov     ax,[boot_old_ax]
	mov     ch,byte ptr [boot_old_dx+1]
	mov     dl,byte ptr [boot_old_dx]
	lds     si,dword ptr [boot_old_si]
	db      0eah            ; jmp 0070h:0000h
	dw      0,70h
boot_old_start_done:
	ret
boot_start_old_dos endp

; Find the system file named by DS:SI using the extended FCB.
boot_find_old_file proc near
	push    es
	push    di
	push    ds
	pop     es
	mov     di,offset boot_find_name
	mov     cx,11
	rep     movsb
	pop     di
	pop     es
	mov     dx,offset boot_find_fcb
	mov     ah,dir_search_first
	int     21h
	test    al,al
	ret
boot_find_old_file endp

; Process the startup driver records and apply stack compatibility checks.
	public  boot_process_drivers
boot_process_drivers proc near
	cld
	push    cs
	pop     ds
	push    cs
	pop     es
	mov     bx,offset boot_driver_table
	test    byte ptr [query_mode_flags],1
	jnz     boot_driver_next
	mov     byte ptr [boot_himem_record_length],0bh
boot_driver_next:
	call    boot_process_driver_record
	jc      boot_driver_all_done
	add     bx,6
	jmp     short boot_driver_next
boot_driver_all_done:
	call    boot_check_umb_stack
	call    boot_check_umb_rom
	ret
boot_process_drivers endp

; Execute one startup driver record at DS:BX.
; Carry indicates the end of the record table or an unavailable path.
	.386
	public  boot_process_driver_record
boot_process_driver_record proc near
	cld
	pusha
	push    es
	push    cs
	pop     ds
	push    cs
	pop     es
	mov     cx,[bx]
	stc
	jcxz    boot_driver_return
	cmp     byte ptr [dos_umb_flag],0
	je      short boot_driver_return
	test    byte ptr [boot_config_flags],20h
	jnz     short boot_driver_return
	inc     byte ptr [boot_driver_depth]
	jnz     short boot_driver_leave
	call    cx
	je      short boot_driver_leave
	mov     di,offset boot_winboot_dir
	add     di,[boot_winboot_dir_len]
	push    di
	mov     si,[bx+2]
	mov     dx,[bx+4]
	movzx   cx,dl
	rep     movsb
	mov     cl,CONFIG_DEVICEHIGH
	test    dh,80h
	jz      short boot_driver_install
	mov     cl,CONFIG_DEVICE
	and     dh,7fh
	mov     al,0ah
	stosb
	jmp     short boot_driver_command
boot_driver_install:
	mov     byte ptr [di-1],' '
	mov     ax,0a0dh
	stosw
boot_driver_command:
	xchg    ax,cx
	mov     si,offset boot_winboot_command
	mov     cx,di
	sub     cx,si
	call    boot_execute_config_line
	pop     di
	mov     al,0
	stosb
boot_driver_leave:
	dec     byte ptr [boot_driver_depth]
	clc
boot_driver_return:
	pop     es
	popa
	ret
boot_process_driver_record endp
	.8086

; Execute one synthesized CONFIG.SYS command at ES:SI, length CX.
; AL is the command code and DH is the temporary query state.
boot_execute_config_line proc near
	push    bx
	mov     [si],al
	mov     word ptr [si+1],0
	push    word ptr [confbot]
	push    word ptr [chrptr]
	push    word ptr [count]
	push    word ptr [linecount]
	push    word ptr [config_multi]
	mov     word ptr [config_multi],1
	mov     [confbot],es
	mov     [chrptr],si
	mov     [count],cx
	xchg    dh,[bQueryOpt]
	mov     dl,[multi_pass_id]
	push    dx
	mov     byte ptr [multi_pass_id],2
	push    ds
	push    es
	call    multi_pass_config_line
	pop     es
	pop     ds
	pop     dx
	mov     [multi_pass_id],dl
	mov     [bQueryOpt],dh
	pop     word ptr [config_multi]
	pop     word ptr [linecount]
	pop     word ptr [count]
	pop     word ptr [chrptr]
	pop     word ptr [confbot]
	pop     bx
	ret
boot_execute_config_line endp

	assume  ds:sysinitseg,es:sysinitseg
; Prepare the Windows and command interpreter paths and startup arguments.
	public  boot_prepare_shell
boot_prepare_shell proc near
	cld
	push    cs
	pop     ds
	push    cs
	pop     es
	test    byte ptr [boot_config_flags],20h
	jz      boot_shell_paths
	jmp     near ptr boot_shell_done
boot_shell_paths:
	mov     si,offset boot_winboot_dir
	mov     cx,[boot_winboot_dir_len]
	mov     di,offset commnd4
	mov     dx,78
	call    boot_insert_path
	mov     di,offset commnd
	mov     bx,offset command_line+1
	cmp     byte ptr [newcmd],0
	je      boot_shell_insert
	mov     di,offset commnd2
	mov     bx,offset command_line2+1
boot_shell_insert:
	call    boot_insert_path
	mov     dx,126
	mov     di,bx
	call    boot_insert_path
	jc      boot_shell_arguments
	add     [di-1],cl
boot_shell_arguments:
	sub     ax,ax
	mov     bx,offset command_line+1
	mov     di,bx
	test    byte ptr [query_mode_flags],4
	jz      boot_shell_autoexec
	cmp     [exec_option],al
	jne     boot_shell_autoexec
	cmp     byte ptr [exec_value+2],al
	jne     boot_shell_autoexec
	push    di
	mov     al,[di-1]
	add     di,ax
	mov     cx,12
	add     ax,cx
	cmp     ax,127
	jae     boot_shell_net_done
	add     [bx-1],cl
	inc     cx
	mov     si,offset boot_netstart_cmd
	rep     movsb
	pop     di
	jmp     short boot_shell_copy_bios
boot_shell_net_done:
	pop     di
boot_shell_autoexec:
	test    byte ptr [boot_runtime_flags],20h
	jz      boot_shell_copy_bios
	test    byte ptr [query_mode_flags],1
	jnz     boot_shell_copy_bios
	mov     cx,15
	mov     si,offset boot_autoexec_cmd
	mov     ax,open shl 8
	mov     dx,offset boot_autoexec_name
	int     21h
	jnc     boot_shell_append_autoexec
	mov     cx,3
	mov     byte ptr [si+3],0
boot_shell_append_autoexec:
	sub     ax,ax
	mov     al,[di-1]
	add     di,ax
	add     ax,cx
	cmp     ax,127
	jae     boot_shell_copy_bios
	add     [bx-1],cl
	inc     cx
	rep     movsb
boot_shell_copy_bios:
	mov     es,[BCodeSeg]
	assume  es:Bios_Code
	mov     si,offset commnd
	mov     di,offset Bios_Code:win386_info_buffer
	mov     cx,78
	rep     movsb
	mov     si,offset command_line
	mov     di,offset Bios_Code:win386_info_table
	mov     cx,128
	rep     movsb
	mov     al,6
	cmp     byte ptr [exec_option],0
	jne     boot_shell_test_mode
	cmp     byte ptr [exec_value+2],0
	je      boot_shell_test_mode
	and     al,0fbh
boot_shell_test_mode:
	test    [query_mode_flags],al
	jnz     boot_shell_done
	test    byte ptr [query_mode_flags],1
	jnz     boot_shell_rotate
	mov     ax,open shl 8
	mov     dx,offset boot_autoexec_name
	int     21h
	jc      boot_shell_rotate
	xchg    ax,bx
	sub     cx,cx
	sub     dx,dx
	mov     ax,(lseek shl 8) or 2
	int     21h
	or      ax,dx
	xchg    ax,cx
	mov     ah,close
	int     21h
	jcxz    boot_shell_rotate
	inc     byte ptr [boot_autoexec_exists]
	jmp     short boot_shell_done
boot_shell_rotate:
	call    rotate_shell_records
boot_shell_done:
	ret
boot_prepare_shell endp
	assume  ds:nothing,es:nothing

; Rotate the command path and command-tail records for startup fallback.

	public	rotate_shell_records
rotate_shell_records proc near
	assume	ds:sysinitseg
	test	byte ptr [boot_config_flags],20h
	jnz	rotate_shell_done
	test	byte ptr [boot_runtime_flags],20h
	jnz	rotate_shell_done
	test	byte ptr [boot_config_flags],4
	jz	rotate_shell_copy
	mov	ah,set_default_drive
	mov	dl,2
	int	21h
rotate_shell_copy:
	cld
	push	cs
	pop	es
	mov	cx,206
	mov	si,offset commnd2
	mov	di,offset commnd3
	rep	movsb
	mov	cx,206
	mov	si,offset commnd
	mov	di,offset commnd2
	rep	movsb
	mov	cx,206
	mov	si,offset commnd4
	mov	di,offset commnd
	rep	movsb
	inc	byte ptr [newcmd]
	inc	byte ptr [winboot_shell_pending]
rotate_shell_done:
	ret
rotate_shell_records endp

	assume  ds:sysinitseg,es:sysinitseg
; Set the default environment for the command interpreter.
	public  boot_prepare_environment
boot_prepare_environment proc near
	cld
	push    ds
	pop     es
	test    byte ptr [boot_config_flags],20h
	jz      short boot_env_check_shell
	jmp     near ptr boot_env_done
boot_env_check_shell:
	cmp     byte ptr [exec_option],0
	je      short boot_env_check_tmp
	jmp     near ptr boot_env_done
boot_env_check_tmp:
	sub     dx,dx
	mov     si,offset boot_env_tmp
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_existing_tmp
	push    ds
	mov     ds,[new_psp_segment]
	mov     dx,80h
	mov     ah,set_dma
	int     21h
	pop     ds
	mov     di,offset boot_device_scratch+1
	mov     cx,4
	rep     movsb
	mov     dx,di
	mov     si,offset boot_windows_dir
	mov     cx,[boot_windows_dir_len]
	rep     movsb
	mov     bx,di
	mov     si,offset boot_temp_dir
	mov     cx,5
	rep     movsb
	mov     ax,find_first shl 8
	stosb
	dec     di
	mov     cx,10h
	int     21h
	jc      short boot_env_make_temp
	push    ds
	mov     ds,[new_psp_segment]
	test    byte ptr ds:[95h],10h
	pop     ds
	jz      short boot_env_temp_parent
	jmp     short boot_env_set_tmp
boot_env_make_temp:
	mov     ah,mkdir
	int     21h
	jnc      short boot_env_set_tmp
boot_env_temp_parent:
	mov     di,bx
	cmp     word ptr [boot_windows_dir_len],2
	ja      short boot_env_temp_end
	mov     al,5ch
	stosb
boot_env_temp_end:
	sub     al,al
	stosb
boot_env_set_tmp:
	mov     dx,1
	mov     si,offset boot_device_scratch+1
	call    copy_envvar
	jmp     short boot_env_check_temp
boot_env_existing_tmp:
	push    ds
	mov     ds,[config_wrkseg]
	mov     si,dx
	mov     di,offset boot_device_scratch+5
	mov     cx,64
	rep     movsb
	pop     ds
boot_env_check_temp:
	sub     dx,dx
	mov     si,offset boot_env_temp
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_check_prompt
	mov     di,offset boot_device_scratch
	mov     cx,5
	rep     movsb
	mov     dx,1
	mov     si,offset boot_device_scratch
	call    copy_envvar
boot_env_check_prompt:
	sub     dx,dx
	mov     si,offset boot_env_prompt
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_check_winboot
	inc     dx
	call    copy_envvar
boot_env_check_winboot:
	sub     dx,dx
	mov     si,offset boot_env_winboot
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_check_path
	mov     di,offset boot_device_scratch
	mov     cx,11
	rep     movsb
	mov     si,offset boot_winboot_dir
	mov     cx,[boot_winboot_dir_len]
	rep     movsb
	mov     al,0
	stosb
	inc     dx
	mov     si,offset boot_device_scratch
	call    copy_envvar
boot_env_check_path:
	sub     dx,dx
	mov     si,offset boot_env_path
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_check_comspec
	mov     di,offset boot_device_scratch
	mov     cx,5
	rep     movsb
	mov     al,[boot_windows_dir]
	cmp     al,[boot_winboot_dir]
	je      short boot_env_path_windows
	cmp     byte ptr [boot_winboot_dir],'C'
	jb      short boot_env_path_windows
	mov     si,offset boot_winboot_dir
	mov     cx,[boot_winboot_dir_len]
	cmp     cx,2
	rep     movsb
	ja      short boot_env_path_separator
	mov     al,5ch
	stosb
boot_env_path_separator:
	mov     al,';'
	stosb
boot_env_path_windows:
	mov     si,offset boot_windows_dir
	mov     cx,[boot_windows_dir_len]
	cmp     cx,2
	rep     movsb
	ja      short boot_env_path_command
	mov     al,5ch
	stosb
	jmp     short boot_env_path_end
boot_env_path_command:
	mov     al,';'
	stosb
	mov     si,offset boot_windows_dir
	mov     cx,[boot_windows_dir_len]
	rep     movsb
	mov     si,offset boot_command_dir
	mov     cx,8
	rep     movsb
boot_env_path_end:
	sub     al,al
	stosb
	mov     dx,1
	mov     si,offset boot_device_scratch
	call    copy_envvar
boot_env_check_comspec:
	cmp     byte ptr [winboot_shell_pending],0
	je      short boot_env_done
	sub     dx,dx
	mov     si,offset boot_env_comspec
	call    copy_envvar
	test    dx,dx
	jnz      short boot_env_done
	mov     di,offset boot_device_scratch
	mov     cx,8
	rep     movsb
	mov     si,offset commnd2
boot_env_comspec_copy:
	lodsb
	stosb
	or      al,al
	jnz      short boot_env_comspec_copy
	mov     dx,1
	mov     si,offset boot_device_scratch
	call    copy_envvar
boot_env_done:
	ret
boot_prepare_environment endp
	assume  ds:nothing,es:nothing

;
;   Add the appropriate startup switch to the shell command line.
;
	assume  ds:sysinitseg,es:sysinitseg
	public  disable_autoexec, enable_autoexec_query
disable_autoexec proc near
	cmp     byte ptr [winboot_shell_pending],0
	jne     short autoexec_exit
	test    byte ptr [query_mode_flags],4
	jnz     short autoexec_exit
	test    byte ptr [query_mode_flags],21h
	jz      short autoexec_exit
	mov     cx,3
	mov     si,offset boot_previous_status+2
autoexec_insert:
	mov     al,[default_switch_char]
	test    al,al
	jz      short autoexec_copy
	mov     [si],al
autoexec_copy:
	push    ds
	pop     es
	inc     di
	mov     dx,126
	call    boot_insert_path
	dec     di
	jc      short autoexec_exit
	add     [di],cl
autoexec_exit:
	ret
disable_autoexec endp

enable_autoexec_query proc near
	cmp     byte ptr [winboot_shell_pending],0
	jne     short autoexec_exit
	test    byte ptr [query_mode_flags],8
	jz      short autoexec_exit
	test    byte ptr [query_mode_flags],50h
	jnz     short autoexec_exit
	mov     cx,3
	mov     si,offset boot_previous_status+5
	jmp     short autoexec_insert
enable_autoexec_query endp

; Insert CX bytes from DS:SI at ES:DI in a DX-byte string buffer.
; Carry is set if the existing string leaves insufficient room.
; DS and ES both address SYSINITSEG; preserve general registers.
	.386
	public  boot_insert_path
boot_insert_path proc near
	pusha
	mov     bx,cx
	xor     al,al
	mov     cx,dx
	repne   scasb
	cmp     cx,bx
	jb      short boot_insert_done
	dec     di
	mov     si,di
	add     di,bx
	neg     cx
	add     cx,dx
	std
	rep     movsb
	cld
	pop     di
	pop     si
	push    si
	push    di
	mov     cx,bx
	rep     movsb
	clc
boot_insert_done:
	popa
	ret
boot_insert_path endp
	.8086


; Select the startup-menu title and handle a previous boot choice.
	assume  ds:sysinitseg,es:sysinitseg
	public  boot_previous_menu_check
boot_previous_menu_check proc near
	cld
	push    ds
	pop     es
	test    byte ptr [query_mode_flags],3
	jz      short boot_previous_check_runtime
	jmp     boot_previous_done
boot_previous_check_runtime:
	test    word ptr [boot_runtime_flags],120h
	jz      short boot_previous_select_title
	jmp     boot_previous_done
boot_previous_select_title:
	mov     di,offset sysinit_msg_base
	add     di,word ptr [sysinit_msg_table+78]
	cmp     byte ptr [boot_previous_status],0dh
	je      short boot_previous_show_menu
	cmp     byte ptr [boot_previous_status],1
	jne     short boot_previous_restart_file
	push    ds
	mov     dl,[boot_host_drive]
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	cmp     dl,ds:[win386_text_buffer]
	je      short boot_previous_check_windows_drive
	sub     dl,40h
	mov     ah,get_dpb
	int     21h
	pop     ds
	assume  ds:sysinitseg
	cmp     al,0ffh
	jne     short boot_previous_check_windows
	mov     byte ptr [boot_previous_menu],7
	cmp     byte ptr [exec_value],'0'
	jne     short boot_previous_old_title
	dec     byte ptr [boot_previous_menu]
boot_previous_old_title:
	mov     di,offset sysinit_msg_base
	add     di,word ptr [sysinit_msg_table+80]
	jmp     short boot_previous_show_menu
boot_previous_check_windows:
	push    ds
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
boot_previous_check_windows_drive:
	mov     dl,ds:[win386_text_buffer]
	sub     dl,40h
	mov     ah,get_dpb
	int     21h
	pop     ds
	assume  ds:sysinitseg
	cmp     al,0ffh
	jne     short boot_previous_show_menu
boot_previous_restart_file:
	mov     si,offset boot_restart_status
	mov     di,offset boot_device_scratch
	mov     cx,14
	rep     movsb
	mov     si,offset boot_windows_dir
	mov     cx,[boot_windows_dir_len]
	mov     di,offset boot_device_scratch
	push    di
	mov     dx,78
	call    boot_insert_path
	pop     dx
	mov     ax,chmod shl 8
	int     21h
	jc      short boot_previous_done
	mov     ah,unlink
	int     21h
	mov     di,offset sysinit_msg_base
	add     di,word ptr [sysinit_msg_table+82]
boot_previous_show_menu:
	call    boot_build_menu
boot_previous_done:
	ret
boot_previous_menu_check endp

; Build the Windows startup menu descriptions and default selection.
	public  boot_build_menu
boot_build_menu proc near
	mov     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+88]
	mov     [bx+aoffBlockDesc],dx
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+90]
	mov     [bx+aoffBlockDesc],dx
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+92]
	mov     [bx+aoffBlockDesc],dx
	cmp     byte ptr [exec_value],'0'
	je      short boot_menu_nonetwork
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+94]
	mov     [bx+aoffBlockDesc],dx
boot_menu_nonetwork:
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+96]
	mov     [bx+aoffBlockDesc],dx
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+98]
	mov     [bx+aoffBlockDesc],dx
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+100]
	mov     [bx+aoffBlockDesc],dx
	test    byte ptr [boot_runtime_flags],80h
	jnz     short boot_menu_no_old_dos
	add     bx,2
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+102]
	mov     [bx+aoffBlockDesc],dx
boot_menu_no_old_dos:
	shr     bx,1
	mov     [bMaxBlock],bl
	mov     al,[boot_menu_default]
	db      38h,0d8h               ; cmp al,bl
	jbe     short boot_menu_default_ok
	mov     al,bl
boot_menu_default_ok:
	mov     [bDefBlock],al
	mov     ax,[boot_menu_delay]
	test    di,di
	jnz     short boot_menu_previous
	cmp     byte ptr [boot_menu],0
	jne     short boot_menu_set_time
	mov     ax,0ffh
	jmp     short boot_menu_set_time
boot_menu_previous:
	mov     dl,[boot_previous_menu]
	mov     [bDefBlock],dl
	cmp     dl,3
	jne     short boot_menu_set_time
	cmp     byte ptr [exec_option],0
	je      short boot_menu_set_time
	cmp     byte ptr [exec_value],'0'
	je      short boot_menu_set_time
	mov     byte ptr [bDefBlock],4
boot_menu_set_time:
	mov     word ptr [secTimeOut],ax
	call    display_menu
	sub     cx,cx
	sub     dx,dx
	cmp     bx,-1
	je      short boot_menu_selection_flags
	cmp     bx,4
	jb      short boot_menu_selection_number
	cmp     byte ptr [exec_value],'0'
	jne     short boot_menu_selection_number
	inc     bx
boot_menu_selection_number:
	cmp     bx,1
	jne     short boot_menu_selection_log
	jmp     boot_menu_selection_message
boot_menu_selection_log:
	cmp     bx,2
	jne     short boot_menu_selection_safe
	push    ds
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	mov     byte ptr ds:[exec_bios_word-1],0ffh
	pop     ds
	assume  ds:sysinitseg
	jmp     short boot_menu_selection_message
boot_menu_selection_safe:
	cmp     bx,3
	jne     short boot_menu_selection_prompt
	or      byte ptr [query_mode_flags],1
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+54]
	jmp     short boot_menu_selection_message
boot_menu_selection_prompt:
	cmp     bx,4
	jne     short boot_menu_selection_step
	or      byte ptr [query_mode_flags],5
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+56]
	jmp     short boot_menu_selection_message
boot_menu_selection_step:
	cmp     bx,5
	jne     short boot_menu_selection_command
	or      byte ptr [query_mode_flags],8
	and     byte ptr [boot_runtime_flags],0efh
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+60]
	jmp     short boot_menu_selection_done
boot_menu_selection_command:
	cmp     bx,6
	jne     short boot_menu_selection_legacy
	or      byte ptr [boot_runtime_flags],61h
	jmp     short boot_menu_selection_done
boot_menu_selection_legacy:
	cmp     bx,7
	jne     short boot_menu_selection_other
	or      byte ptr [query_mode_flags],3
boot_menu_selection_flags:
	test    byte ptr [query_mode_flags],4
	jz      short boot_menu_selection_standard
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+56]
	jmp     short boot_menu_selection_message
boot_menu_selection_standard:
	test    byte ptr [boot_config_flags],10h
	jnz     short boot_menu_selection_old_message
	test    byte ptr [query_mode_flags],3
	jz      short boot_menu_selection_message
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+54]
boot_menu_selection_message:
	inc     cx
	jmp     short boot_menu_selection_done
boot_menu_selection_other:
	or      byte ptr [boot_config_flags],10h
boot_menu_selection_old_message:
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+118]
boot_menu_selection_done:
	jcxz    boot_menu_selection_return
	push    dx
	mov     dx,cx
	call    boot_logo_display
	pop     dx
boot_menu_selection_return:
	ret
boot_build_menu endp

boot_option_handle dw  0               ; startup option file handle
boot_option_buffer db  128 dup (0)     ; file read buffer
boot_option_line db    128 dup (0)     ; current option line
boot_option_count dw   0               ; bytes in read buffer
boot_option_index dw   0               ; next byte in read buffer


; Section and option tables for the startup options file.
boot_option_current dw offset boot_option_sections
boot_option_sections label byte
	db      '[PATHS]',0
	dw      offset boot_section_paths
	db      '[OPTIONS]',0
	dw      offset boot_section_options
	db      0
	dw      offset boot_option_error
boot_option_paths label byte
	db      'WINDIR',0
	dw      offset boot_option_windir
	db      'WINBOOTDIR',0
	dw      offset boot_option_winbootdir
	db      'HOSTWINBOOTDRV',0
	dw      offset boot_option_hostdrive
	db      'UNINSTALLDIR',0
	dw      offset boot_option_uninstall
	db      0
	dw      offset boot_section_restart
boot_option_options label byte
	db      'LOGO',2
	dw      1
	db      'DBLSPACE',2
	dw      2
	db      'DRVSPACE',2
	dw      4
	db      'BOOTKEYS',2
	dw      8
	db      'BOOTDELAY',0
	dw      offset boot_option_delay
	db      'BOOTWIN',2
	dw      10h
	db      'BOOTGUI',2
	dw      20h
	db      'BOOTWARN',2
	dw      100h
	db      'BOOTMULTI',2
	dw      80h
	db      'DOUBLEBUFFER',1
	dw      offset exec_mode
	db      'BOOTMENUDEFAULT',1
	dw      offset boot_menu_default
	db      'BOOTMENUDELAY',1
	dw      offset boot_menu_delay
	db      'BOOTMENU',1
	dw      offset boot_menu
	db      'BOOTSAFE',1
	dw      offset boot_safe
	db      'NETWORK',1
	dw      offset boot_network
	db      'LOADTOP',2
	dw      40h
	db      'BOOTCONFIG',0
	dw      offset boot_option_config
	db      'DISABLELOG',0
	dw      offset boot_option_disablelog
	db      'SYSTEMREG',2
	dw      200h
	db      0
	dw      offset boot_section_restart


assume  ds:sysinitseg,es:sysinitseg
; Open and process the requested or default startup options file.
; DS:DX is an optional filename; zero first selects WINBOOT.INI.
; Fall through to the read loop, then close the file and prepare paths.
	public  boot_option_open
boot_option_open proc near
	cld
	push    ds
	pop     es
	test    dx,dx
	jnz     boot_open_first
	mov     dx,offset boot_winboot_ini
boot_open_first:
	mov     ax,open shl 8
	int     21h
	jc      boot_open_w40
	and     byte ptr [boot_runtime_flags],7fh
	jmp     short boot_open_found
boot_open_w40:
	mov     byte ptr [boot_winboot_ini-1],0
	mov     dx,offset boot_msdos_w40
	mov     ax,open shl 8
	int     21h
	jnc     boot_open_found
	mov     byte ptr [boot_msdos_w40-1],0
	mov     dx,offset boot_msdos_name
	mov     ax,open shl 8
	int     21h
	jnc     boot_open_found
	mov     dx,offset boot_msdos_root
	mov     ax,open shl 8
	int     21h
	jnc     boot_open_root
	jmp     near ptr boot_option_no_file
boot_open_root:
	push    ds
	lds     si,[dosinfo]
	assume  ds:nothing
	mov     byte ptr [si].sysi_boot_drive,3
	pop     ds
	assume  ds:sysinitseg
	or      byte ptr [boot_config_flags],4
boot_open_found:
	mov     [boot_option_handle],ax
	push    es
	mov     si,dx
	cmp     si,offset boot_msdos_w40
	jne     boot_open_copy_name
	mov     si,offset boot_msdos_name
boot_open_copy_name:
	mov     di,offset Bios_Code:win386_options_path+3
	mov     es,[BCodeSeg]
	assume  es:Bios_Code
	mov     cx,13
	rep     movsb
	mov     ax,3305h
	int     21h
	add     dl,'@'
	mov     es:[win386_options_path],dl
	pop     es
	assume  es:sysinitseg
boot_option_open endp

; Read and dispatch lines from the open startup options file.
boot_option_readloop proc near
boot_option_next:
	call    boot_option_getline
	jnc     boot_option_line_ready
	jmp     near ptr boot_option_close
boot_option_line_ready:
	and     byte ptr [boot_config_flags],0feh
	mov     di,[boot_option_current]
boot_option_loop_dispatch:
	call    boot_option_dispatch
	jmp     short boot_option_next
boot_option_readloop endp

; Parse the Windows directory, boot directory, and host drive options.
boot_option_windir proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	mov     cx,64
	mov     di,offset boot_windows_dir
boot_option_windir endp

; Copy an option value through CR, terminating the result with zero.
; DS:SI addresses the value, ES:DI the destination, CX its capacity.
boot_option_copy proc near
boot_copy_next:
	lodsb
	stosb
	cmp     al,0dh
	loopne  boot_copy_next
	mov     byte ptr [di-1],0
	ret
boot_option_copy endp

boot_option_winbootdir proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	mov     cx,64
	mov     di,offset boot_winboot_dir
	jmp     boot_option_copy
boot_option_winbootdir endp

boot_option_hostdrive proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	mov     cx,2
	mov     di,offset boot_host_drive
	jmp     boot_option_copy
boot_option_hostdrive endp

; Accept UNINSTALLDIR, which has no startup action.
boot_option_uninstall proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	ret
boot_option_uninstall endp

; Store BOOTDELAY if it is no greater than 3600 seconds.
boot_option_delay proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	call    boot_option_number
	jc      boot_option_error
	cmp     ax,3600
	ja      boot_option_error
	mov     word ptr ds:[boot_delay],ax
	ret
boot_option_delay endp

	assume  ds:sysinitseg
; Store the DISABLELOG option in the BIOS startup state.
boot_option_disablelog proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	call    boot_option_number
	jc      boot_option_error
	push    ds
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	mov     byte ptr [exec_bios_word-1],al
	pop     ds
	assume  ds:sysinitseg
	ret
boot_option_disablelog endp
	assume  ds:nothing

; Store the selected BOOTCONFIG name.
boot_option_config proc near
	lodsb
	cmp     al,'='
	jne     boot_option_error
	mov     cx,32
	mov     di,offset boot_config_name
	jmp     boot_option_copy
boot_option_config endp

	assume  ds:sysinitseg
; Retry an unmatched line against the section names.
boot_section_restart proc near
	mov     di,offset boot_option_sections
	add     sp,2
	jmp     boot_option_loop_dispatch
boot_section_restart endp

boot_section_paths proc near
	mov     word ptr [boot_option_current],offset boot_option_paths
	ret
boot_section_paths endp

boot_section_options proc near
	mov     word ptr [boot_option_current],offset boot_option_options
	ret
boot_section_options endp

; Display the invalid startup option and its diagnostic.
boot_option_error proc near
	mov     ah,std_con_string_output
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+120]
	int     21h
	mov     si,offset boot_option_line
boot_error_char:
	lodsb
	mov     dl,al
	mov     ah,std_con_output
	int     21h
	cmp     dl,0dh
	jne     boot_error_char
	mov     dl,0ah
	mov     ah,std_con_output
	int     21h
	ret
boot_option_error endp

; Close the options file and finish preparing the startup paths.
boot_option_close proc near
	mov     ah,close
	mov     bx,[boot_option_handle]
	int     21h
boot_option_no_file:
	call    boot_prepare_paths
	ret
boot_option_close endp

	assume  ds:sysinitseg,es:sysinitseg
; Set default directory names and remove a trailing backslash.
; Propagate the boot path and apply startup driver options.
	public  boot_prepare_paths
boot_prepare_paths proc near
	mov     di,offset boot_windows_dir
	cmp     byte ptr [di],0
	jne     boot_windows_length
	or      byte ptr [boot_config_flags],20h
	mov     ah,get_default_drive
	int     21h
	add     al,'A'
	mov     [di],al
	cmp     al,'C'
	jae     boot_windows_length
	mov     byte ptr [di+3],0
	or      byte ptr [boot_runtime_flags],1
boot_windows_length:
	xor     al,al
	mov     cx,64
	repne   scasb
	not     cx
	add     cx,64
	mov     [boot_windows_dir_len],cx
	cmp     byte ptr [di-2],'\'
	jne     boot_winboot_default
	mov     byte ptr [di-2],0
	dec     cx
	mov     [boot_windows_dir_len],cx
boot_winboot_default:
	mov     di,offset boot_winboot_dir
	cmp     byte ptr [di],0
	jne     boot_winboot_length
	push    di
	mov     si,offset boot_windows_dir
	inc     cx
	rep     movsb
	pop     di
boot_winboot_length:
	xor     al,al
	mov     cx,64
	repne   scasb
	not     cx
	add     cx,64
	mov     [boot_winboot_dir_len],cx
	cmp     byte ptr [di-2],'\'
	jne     boot_drive_default
	mov     byte ptr [di-2],0
	dec     word ptr [boot_winboot_dir_len]
boot_drive_default:
	mov     di,offset boot_winboot_dir
	mov     al,[di]
	mov     bx,offset boot_host_drive
	cmp     byte ptr [bx],0
	jne     boot_paths_done
	mov     [bx],al
boot_paths_done:
	test    byte ptr [boot_config_flags],8
	jnz     boot_paths_end
	or      byte ptr [boot_config_flags],8
	push    es
	mov     es,[BCodeSeg]
	assume  es:Bios_Code
	add     di,[boot_winboot_dir_len]
	push    di
	mov     cx,es:[win386_text_length]
	sub     cx,2
	mov     si,offset Bios_Code:win386_text_buffer+2
	mov     es:[si-2],al
boot_path_suffix:
	lods    byte ptr es:[si]
	mov     [di],al
	inc     di
	loop    boot_path_suffix
	sub     cx,cx
	mov     si,offset boot_winboot_dir
	mov     di,offset Bios_Code:win386_text_buffer
boot_path_to_bios:
	lodsb
	stosb
	inc     cx
	test    al,al
	jnz     boot_path_to_bios
	mov     es:[win386_text_length],cx
	pop     di
	pop     es
	assume  es:sysinitseg
	sub     al,al
	stosb
	cmp     byte ptr [boot_network],0
	je      boot_check_double_buffer
	mov     byte ptr [exec_value],'1'
boot_check_double_buffer:
	cmp     byte ptr [exec_mode],1
	ja      boot_paths_end
	mov     byte ptr [boot_driver_entry1],0dh
	mov     byte ptr [boot_driver_entry2],0dh
boot_paths_end:
	ret
boot_prepare_paths endp
	assume  ds:nothing,es:nothing

; Read the next nonblank startup option line into boot_option_line.
; Spaces and tabs are discarded; a semicolon begins a comment.
; Return DS:SI at the CR-terminated uppercase line, CF clear.
; CF set indicates EOF, a read error, or an old binary DOS image.
	assume  ds:sysinitseg
boot_option_getline proc near
	mov     si,offset boot_option_line
boot_line_first:
	call    boot_option_getchar
	jc      boot_line_return
	cmp     al,0e9h
	stc
	je      boot_line_return
	cmp     al,0ebh
	stc
	je      boot_line_return
boot_line_char:
	cmp     al,9
	je      boot_line_next
	cmp     al,' '
	je      boot_line_next
	cmp     al,';'
	je      boot_line_comment
	cmp     al,0dh
	je      boot_line_end
	call    boot_toupper
	mov     [si],al
	inc     si
	cmp     si,offset boot_option_line+127
	je      boot_line_comment
boot_line_next:
	call    boot_option_getchar
	jmp     short boot_line_char
boot_line_comment:
	call    boot_option_getchar
	cmp     al,0dh
	jne     boot_line_comment
boot_line_end:
	mov     byte ptr [si],0dh
	mov     si,offset boot_option_line
	cmp     byte ptr [si],0dh
	je      boot_line_first
	clc
boot_line_return:
	ret
boot_option_getline endp

; Return the next character from the startup option file in AL.
; Carry indicates an error or end of file; AL then contains CR.
boot_option_getchar proc near
	mov     bx,[boot_option_index]
	cmp     bx,[boot_option_count]
	jb      boot_char_buffered
	mov     bx,[boot_option_handle]
	mov     dx,offset boot_option_buffer
	mov     cx,80h
	mov     ah,read
	int     21h
	jc      boot_char_eof
	test    ax,ax
	jz      boot_char_eof
	mov     [boot_option_count],ax
	sub     bx,bx
boot_char_buffered:
	mov     al,[bx+boot_option_buffer]
	inc     bx
	mov     [boot_option_index],bx
	cmp     al,1ah
	je      boot_char_cr
	cmp     al,0ah
	jne     boot_char_done
boot_char_cr:
	mov     al,0dh
boot_char_done:
	clc
	ret
boot_char_eof:
	mov     al,0dh
	stc
	ret
boot_option_getchar endp


assume  ds:sysinitseg
; Match a startup option against the table at DS:DI.
; DS:SI addresses the option line.  Entries end in a type byte and word.
boot_option_dispatch proc near
boot_match_entry:
	mov     bx,si
boot_match_current:
	cmp     byte ptr [di],0
	je      boot_match_direct
boot_match_char:
	mov     al,[di]
	inc     di
	cmp     al,1
	je      boot_match_number
	jb      boot_match_jump
	cmp     al,2
	je      boot_match_flag
	cmp     al,[si]
	jne     boot_match_skip
	inc     si
	jmp     short boot_match_char
boot_match_direct:
	inc     di
	jmp     word ptr [di]
boot_match_number:
	lodsb
	cmp     al,'='
	je      boot_number_value
	jmp     near ptr boot_option_error
boot_number_value:
	call    boot_option_number
	jnc     boot_number_limit
	jmp     near ptr boot_option_error
boot_number_limit:
	cmp     ax,90
	jbe     boot_number_store
	jmp     near ptr boot_option_error
boot_number_store:
	mov     di,[di]
	mov     [di],al
	ret
boot_match_flag:
	lodsb
	cmp     al,'='
	je      boot_flag_value
	jmp     near ptr boot_option_error
boot_flag_value:
	call    boot_option_number
	jnc     boot_flag_store
	jmp     near ptr boot_option_error
boot_flag_store:
	mov     cx,[di]
	or      word ptr [boot_runtime_flags],cx
	test    al,al
	je      boot_flags_sync
	not     cx
	and     word ptr [boot_runtime_flags],cx
boot_flags_sync:
	push    ds
	mov     al,[boot_runtime_flags]
	and     al,40h
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	and     byte ptr [win386_info_flags],0bfh
	or      [win386_info_flags],al
	pop     ds
	assume  ds:sysinitseg
	ret
boot_match_jump:
	jmp     word ptr [di]
boot_match_skip:
	mov     al,[di]
	inc     di
	cmp     al,2
	ja      boot_match_skip
	inc     di
	inc     di
	mov     si,bx
	jmp     boot_match_entry
boot_option_dispatch endp

; Convert a signed numeric boot option at DS:SI to AX.
; Carry is set if the first character is invalid or the value overflows.
boot_option_number proc near
	lodsb
	mov     cx,1
	cmp     al,'-'
	jne     boot_num_first
	neg     cx
	lodsb
boot_num_first:
	sub     al,'0'
	jc      boot_num_invalid
	cmp     al,0ah
	ja      boot_num_invalid
	cbw
	mov     bx,ax
boot_num_next:
	lodsb
	sub     al,'0'
	jc      boot_num_done
	cmp     al,0ah
	ja      boot_num_done
	cbw
	xchg    ax,bx
	mov     dx,10
	mul     dx
	or      dx,dx
	jnz     boot_num_overflow
	add     bx,ax
	jnc     boot_num_next
boot_num_overflow:
	mov     ax,0ffffh
	stc
	ret
boot_num_done:
	mov     ax,bx
	dec     si
	mul     cx
	clc
	ret
boot_num_invalid:
	xor     ax,ax
	dec     si
	stc
	ret
boot_option_number endp

; Convert ASCII lowercase AL to uppercase; leave other characters unchanged.
;
boot_toupper proc near
	cmp     al,'a'
	jb      boot_upper_done
	cmp     al,'z'
	ja      boot_upper_done
	sub     al,20h
boot_upper_done:
	ret
boot_toupper endp

	assume  ds:nothing

extrn	boot_logo_display:near,boot_bios_far_call:near


ENDIF ; CONFIGPROC
	if	noexec
	public	mem_err
mem_err:
	mov	dx,offset badmem
	push	cs
	pop	ds
	call	print
	jmp	stall
	endif

sysinitseg	ends
	end
