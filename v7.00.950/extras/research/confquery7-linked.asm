DOS7_CONFIG equ 1
open equ 3dh
lseek equ 42h
close equ 3eh
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f23h
alloclim dw 0
 org 0f52h
multi_pass_id db 0
 org 0fdah
count dw 0
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 32ceh
config db 0
 org 3375h
query_mode_flags db 0
 org 5ad0h
config_wrkseg dw 0
config_cmd db 0
 org 6848h
doconf proc near
	push	cs
	pop	ds
	assume	ds:sysinitseg

IFNDEF DOS7_CONFIG
        mov     ax,(char_oper shl 8)    ; get switch character
	int	21h
	mov	[command_line+1],dl	; set in default command line

ifdef   MULTI_CONFIG
        mov     [command_line-1],dl     ; save default switchchar
endif  ;MULTI_CONFIG

ENDIF

	mov	dx,offset config	;now pointing to file description
	mov	ax,open shl 8		;open file "config.sys"
	stc				;in case of int 24
	int	21h			;function request
	jnc	noprob			; brif opened okay

IFDEF DOS7_CONFIG
config_missing:
        mov     ax,[alloclim]           ; reserve an environment workspace
        sub     ax,20h
        mov     [config_wrkseg],ax
        mov     es,ax
        mov     byte ptr es:[0],0
        mov     [alloclim],ax
ELSE
ifdef   MULTI_CONFIG
        extrn   kbd_read:near           ; we still want to give the guy
        call    kbd_read                ; a chance to select clean boot!
endif                                   ; (ie, no autoexec.bat processing)
ENDIF

	mov	multi_pass_id,11	; set it to unreasonable number
	ret
noprob: 				;get file size (note < 64k!!)
IFDEF DOS7_CONFIG
        xchg    ax,bx
ELSE
	mov	bx,ax
ENDIF
	xor	cx,cx
	xor	dx,dx
	mov	ax,(lseek shl 8) or 2
	int	21h
IFDEF DOS7_CONFIG
        test    dx,dx                   ; limit file size to 64K-1
        jz      config_size_ok
        or      ax,-1
config_size_ok:
        push    ax
        push    bx
        and     byte ptr [query_mode_flags],0bfh
        mov     byte ptr [config_cmd],1
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+72]
        call    query_user
        pop     bx
        pop     ax
        jnc     config_accepted
        mov     ah,close
        int     21h
        jmp     short config_missing
config_accepted:
ENDIF
	mov	[count],ax
doconf endp
 org 0a568h
sysinit_msg_table dw 65 dup(0)
sysinit_msg_base db 0
sysinitseg ends
end
