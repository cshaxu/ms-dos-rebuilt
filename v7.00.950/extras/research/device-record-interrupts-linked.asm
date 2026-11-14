sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 67e0h
config_int_vectors dd 16 dup (-1)
 org 8985h
        .386
config_record_interrupts proc near
        push    eax
        push    cx
        push    si
        push    di
        push    es
        xor     bx,bx
        mov     es,bx
        mov     di,1dch
        push    cs
        pop     ds
        mov     si,offset config_int_vectors+60
        std
        call    config_compare_interrupts
        mov     di,3ch
        call    config_compare_interrupts
        xor     dx,dx
        cld
        pop     es
        pop     di
        pop     si
        pop     cx
        pop     eax
        ret
config_record_interrupts endp

config_compare_interrupts proc near
        mov     cx,8
config_interrupt_loop:
        shl     bx,1
        cmpsd
        jz      short config_interrupt_next
        db      66h                     ; 32-bit operand
        mov     ax,word ptr es:[di+4]
        mov     [si+4],eax
        or      bx,1
config_interrupt_next:
        loop    config_interrupt_loop
        ret
config_compare_interrupts endp
        .8086

sysinitseg ends
end
