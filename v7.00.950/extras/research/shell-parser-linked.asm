MULTI_CONFIG equ 1
CONFIG_SHELL equ 'S'
lf equ 10
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0fdah
count dw 0
 org 0fdeh
chrptr dw 0
 org 2d1fh
query_user proc near
 ret
query_user endp
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
 org 6958h
conflp: ret
 org 741fh
trys:
        cmp     ah,CONFIG_SHELL
	jnz	tryx
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      tryx                    ; has the CONFIG_OPTION_QUERY bit set
        mov     [newcmd],1
endif
        mov     word ptr [command_line],0;zap length,first byte of command-line

        mov     di,offset commnd+1      ; we already have the first char
        mov     [di-1],al               ; of the new shell in AL, save it now

storeshell:
	call	getchr
        or      al,al                   ; this is the normal case: "organize"
        jz      getshparms              ; put a ZERO right after the filename

        cmp     al," "                  ; this may happen if there are no args
        jb      endofshell              ; I suppose...
	mov	[di],al
	inc	di
        cmp     di,offset commnd+63     ; this makes sure we don't overflow
        jb      storeshell              ; commnd (the filename)
        jmp     short endofshell

getshparms:
        mov     byte ptr [di],0         ; zero-terminate the filename
        mov     di,offset command_line+1; prepare to process the command-line

parmloop:
	call	getchr
	cmp	al," "
        jb      endofparms
	mov	[di],al
	inc	di
        cmp     di,offset command_line+126
        jb      parmloop

endofparms:
        mov     cx,di
        sub     cx,offset command_line+1
        mov     [command_line],cl

endofshell:
        mov     byte ptr [di],0         ; zero-terminate the filename (or
                                        ; the command-line as the case may be)
skipline:
        cmp     al,lf                   ; the safest way to eat the rest of
        je      endofline               ; the line:  watch for ever-present LF
	call	getchr
        jnc     skipline                ; keep it up as long as there are chars

endofline:
        jmp     conflp

tryx: ret
 org 75ech
getchr	proc	near
IFDEF DOS7_CONFIG
	assume	ds:nothing
ENDIF
	push	cx
	mov	cx,count
	jcxz	nochar

	mov	si,chrptr
	mov	al,es:[si]
	dec	count
	inc	chrptr
	clc
get_ret:
	pop	cx
	ret

nochar: stc
	jmp	short get_ret
getchr	endp
sysinitseg ends
 end trys
