DOS7_CONFIG equ 1
MULTI_CONFIG equ 1
lf equ 10
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f21h
confbot dw 0
 org 0f2dh
linecount dw 0
 org 0f52h
multi_pass_id db 0
 org 0fdah
count dw 0
org_count dw 0
chrptr dw 0
 org 2034h
organize proc near
 ret
organize endp
 org 5ad2h
config_cmd db 0
 org 5ad5h
multdeviceflag db 0
 org 692ch
endconv:
 ret
multi_pass:
	push	cs
	pop	ds

	cmp	multi_pass_id,10
jae_endconv:
	jae	endconv 		; do nothing. just return.

IFDEF DOS7_CONFIG
        mov     ax,[org_count]
        mov     [count],ax
        mov     word ptr [chrptr],0
        push    [confbot]
        pop     es
        mov     word ptr [linecount],0
ELSE
	push	confbot
	pop	es			; es -> confbot

	mov	si,org_count
	mov	count,si		; set count
	xor	si,si
        mov     chrptr,si               ; reset chrptr
        mov     linecount,si            ; reset linecount
ENDIF

	call	getchr
	jmp	short conflp

getcom:
        call    organize                ; organize the file
	call	getchr

conflp: jc	endconv

        inc     linecount               ; increase linecount

	mov	multdeviceflag,0	; reset multdeviceflag.
IFNDEF DOS7_CONFIG
	mov	setdevmarkflag,0	; reset setdevmarkflag.
ENDIF
	cmp	al,lf			; linefeed?
	je	blank_line		;  then ignore this line.

ifdef   MULTI_CONFIG
;
;   If this is a genuine CONFIG.SYS command, then there should be a line
;   number immediately following it....
;
        mov     [config_cmd],al
endif
 org 69b2h
blank_line:
 ret
 org 75ech
getchr proc near
 ret
getchr endp
sysinitseg ends
end
