sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 5a80h
; Convert a signed decimal boot option at DS:SI to AX.
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
sysinitseg ends
end
