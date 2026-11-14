std_con_string_output equ 9
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1c14h
print_indexed proc near
	xchg	si,dx
	pop	si
	cld
	lods	word ptr cs:[si]
	push	si
	xchg	si,dx
	push	bx
	and	ax,7fffh
	mov	bx,ax
	shl	bx,1
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[bx+sysinit_msg_table]
	mov	ah,std_con_string_output
	int	21h
	pop	bx
	ret
print_indexed endp
 org 8c69h
start proc near
	jnc	no_driver_version_fail	; skip if not a version failure

;	In this case, we're going to display a message

	push	cs
	pop	ds
IFDEF DOS7_CONFIG
	call	print_indexed
	dw	8021h
ELSE
	mov	dx,offset baddblspace
	mov	ah,9
	int	21h			; display the message
ENDIF
	jmp	short fail_driver_load

no_driver_version_fail:
 or ax,ax
 jz fail_driver_load
fail_driver_load:
 ret
start endp
 org 0a568h
 include sysimsg.inc
sysinitseg ends
 end start
