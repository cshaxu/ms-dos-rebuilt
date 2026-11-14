sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 336fh
boot_config_flags db 1
boot_runtime_flags db 80h
 org 448dh
; Command paths and command tails retained for startup fallback.

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
		db	0
 org 50ach
rotate_shell_records proc near
	assume	ds:sysinitseg
	test	byte ptr [boot_config_flags],20h
	jnz	rotate_shell_done
	test	byte ptr [boot_runtime_flags],20h
	jnz	rotate_shell_done
	test	byte ptr [boot_config_flags],4
	jz	rotate_shell_copy
	mov	ah,0eh
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
sysinitseg ends
 end rotate_shell_records
