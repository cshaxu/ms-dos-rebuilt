std_con_output equ 2
std_con_string_output equ 9
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f2dh
linecount dw 0
 org 0fd9h
donotshownum db 0
 org 31d6h
badfil:
	push	cs
	pop	es

	mov	si,dx
badload:
IFDEF DOS7_CONFIG
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_badld_index]
	mov	bx,offset sysinit_msg_base
	add	bx,cs:[sysinit_crlf_index]
ELSE
	mov	dx,offset badld_pre	;want to print config error
	mov	bx, offset crlfm
ENDIF

prnerr:
	push	cs
	pop	ds
IFDEF DOS7_CONFIG
	assume	ds:sysinitseg
	cmp	bQueryOpt,0
	jne	short badfil_print
	cmp	linecount,0
	je	short prnexit
badfil_print:
ENDIF
	call	print

prn1:
	mov	dl,es:[si]
	or	dl,dl
	jz	prn2
	mov	ah,std_con_output
	int	21h
	inc	si
	jmp	prn1

prn2:
	mov	dx,bx
	call	print

IFDEF	CONFIGPROC
IFDEF DOS7_CONFIG
	cmp	cs:donotshownum,1
ELSE
	cmp	donotshownum,1		; suppress line number when handling command.com
ENDIF
	je	prnexit
	call	error_line
ENDIF ; CONFIGPROC

prnexit:
	ret
IFDEF DOS7_CONFIG
	assume	ds:nothing
ENDIF

print:
	mov	ah,std_con_string_output
	int	21h
	ret

 org 3374h
bQueryOpt db 0
 org 760ch
error_line proc near
 ret
error_line endp
 org 0a568h
 include sysimsg.inc
sysinitseg ends
 end badfil
