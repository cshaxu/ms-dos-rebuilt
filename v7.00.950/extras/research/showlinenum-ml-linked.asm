.model small
std_con_string_output equ 9
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f2dh
linecount dw 0
showcount db 4 dup (0),0,'$'
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
 org 321ch
print proc near
 mov ah,9
 int 21h
 ret
print endp
 org 760ch
error_line	proc	near


	push	cs
	pop	ds
IFDEF DOS7_CONFIG
	cmp	linecount,0
	jz	error_line_done
	call	print_indexed
	dw	8011h
	call	showlinenum
error_line_done:
ELSE
	mov	dx,offset errorcmd
	call	print
	call	showlinenum
ENDIF
	ret

error_line	endp
showlinenum	proc	near


	push	es
	push	ds
	push	di

	push	cs
	pop	es		; es=cs

	push	cs
	pop	ds

	mov	di,offset showcount+4	; di -> the least significant decimal field.
	mov	cx,10			; decimal devide factor
IFDEF DOS7_CONFIG
	mov	ax,linecount
ELSE
	mov	ax,cs:linecount
ENDIF

sln_loop:
	cmp	ax,10			; < 10?
	jb	sln_last

	xor	dx,dx
	div	cx
	or	dl,30h			; add "0" (= 30h) to make it an ascii.
	mov	[di],dl
	dec	di
	jmp	sln_loop

sln_last:
	or	al,30h
	mov	[di],al
	mov	dx,di
	call	print			; show it.
	pop	di
	pop	ds
	pop	es
	ret
showlinenum	endp
 org 0a568h
 include sysimsg.inc
sysinitseg ends
 end error_line
