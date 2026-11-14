sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 52c9h
; Insert CX bytes from DS:SI at ES:DI in a DX-byte string buffer.
; Carry is set if the existing string leaves insufficient room.
        .386
boot_insert_path proc near
        pusha
        mov     bx,cx
        xor     al,al
        mov     cx,dx
        repne   scasb
        cmp     cx,bx
        jb      boot_insert_done
        dec     di
        mov     si,di
        add     di,bx
        neg     cx
        add     cx,dx
        std
        rep     movsb
        cld
        pop     di
        pop     si
        push    si
        push    di
        mov     cx,bx
        rep     movsb
        clc
boot_insert_done:
        popa
        ret
boot_insert_path endp
        .8086
sysinitseg ends
end
