sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 919bh
; Convert four-byte palette entries to VGA component triples.
; DS:SI addresses the input and CX contains the entry count.
boot_logo_palette_convert proc near
        push    di
        push    es
        push    si
        push    cx
        mov     di,si
        push    ds
        pop     es
        cld
boot_palette_convert_next:
        lodsw
        mov     dx,ax
        lodsw
        .286
        shr     al,2
        shr     dl,2
        shr     dh,2
        .8086
        stosb
        xchg    dl,dh
        mov     ax,dx
        stosw
        loop    boot_palette_convert_next
        pop     cx
        pop     si
        pop     es
        pop     di
boot_logo_palette_convert endp

; Write CX palette triples from DS:SI; ES:DI receives a copy if DI is nonzero.
boot_logo_palette_write proc near
        push    di
        xor     ax,ax
        mov     dx,3c8h
        out     dx,al
        mov     dx,3c9h
        mov     bx,cx
        add     cx,cx
        add     cx,bx
boot_palette_next:
        push    cx
        mov     cx,20
boot_palette_wait:
        loop    boot_palette_wait
        pop     cx
        lodsb
        out     dx,al
        or      di,di
        jz      boot_palette_nocopy
        stosb
boot_palette_nocopy:
        loop    boot_palette_next
        pop     di
        ret
boot_logo_palette_write endp

; Enable the VGA display after loading the palette.
boot_logo_display_enable proc near
        mov     dx,3dah
        in      al,dx
        mov     dl,0c0h
        mov     al,20h
        out     dx,al
        ret
boot_logo_display_enable endp
sysinitseg ends
end
