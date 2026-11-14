CONFIG_LASTDRIVEHIGH equ 'l'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 6572h
p_ldrv_high db 0
 org 72b7h
lastdrive_value:
 ret
 org 72e7h
; Return a numeric LASTDRIVE value in AX, or carry if not valid.
lastdrive_number proc near
        push    si
        sub     dx,dx
lastdrive_digit:
        mov     al,es:[si]
        inc     si
        cmp     al,' '
        jbe     lastdrive_done
        sub     al,'0'
        jc      lastdrive_bad
        cmp     al,9
        ja      lastdrive_bad
        push    ax
        mov     ax,10
        mul     dx
        xchg    ax,dx
        pop     ax
        cbw
        add     dx,ax
        jmp     short lastdrive_digit
lastdrive_bad:
        sub     dx,dx
lastdrive_done:
        pop     si
        xchg    ax,dx
        cmp     ax,21h
        cmc
        jc      lastdrive_return
        test    ax,ax
        jnz     lastdrive_return
        stc
lastdrive_return:
        ret
lastdrive_number endp

try_lastdrivehigh:
        cmp     ah,CONFIG_LASTDRIVEHIGH
        jne     tryp
        call    query_user
        jc      tryp
        mov     byte ptr cs:[p_ldrv_high],1
        jmp     short lastdrive_value
tryp:
 ret
sysinitseg ends
end
