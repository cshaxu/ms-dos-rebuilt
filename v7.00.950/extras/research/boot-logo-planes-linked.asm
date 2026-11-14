sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 8efch
boot_logo_checksum dw 0
 org 91e9h
; Restore VGA memory mapping for the saved text display.
; SS:DI addresses the saved video state; SI returns the text segment.
boot_logo_text_mapping proc near
        mov     dx,3c4h
        mov     al,2
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0f3h
        or      al,3
        out     dx,al
        dec     dx
        mov     al,4
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0fbh
        out     dx,al
        mov     dl,0ceh
        mov     ax,4
        out     dx,ax
        mov     al,5
        out     dx,al
        inc     dx
        in      al,dx
        or      al,10h
        out     dx,al
        dec     dx
        mov     al,6
        out     dx,al
        inc     dx
        in      al,dx
        or      al,0eh
        mov     si,0b800h
        cmp     byte ptr ss:[di+1],7
        jne     boot_logo_text_color
        and     al,0fbh
        mov     si,0b000h
boot_logo_text_color:
        out     dx,al
        ret
boot_logo_text_mapping endp

; Copy a 320-byte image row into four VGA planes and accumulate its sum.
; DS:BX points to the row and ES:DI to the display destination.
        .386
boot_logo_copy_row proc near
        push    bp
        cld
        mov     dx,3c4h
        mov     cx,320
        shr     cx,2
        mov     bp,cx
        mov     ax,0102h
        out     dx,ax
        mov     si,bx
        push    di
boot_logo_plane1:
        lodsd
        stosb
        mov     ah,0
        add     cs:[boot_logo_checksum],ax
        loop    boot_logo_plane1
        pop     di
        mov     ax,0202h
        out     dx,ax
        lea     si,[bx+1]
        mov     cx,bp
        push    di
boot_logo_plane2:
        lodsd
        stosb
        mov     ah,0
        add     cs:[boot_logo_checksum],ax
        loop    boot_logo_plane2
        pop     di
        mov     ax,0402h
        out     dx,ax
        lea     si,[bx+2]
        mov     cx,bp
        push    di
boot_logo_plane3:
        lodsd
        stosb
        mov     ah,0
        add     cs:[boot_logo_checksum],ax
        loop    boot_logo_plane3
        pop     di
        mov     ax,0802h
        out     dx,ax
        lea     si,[bx+3]
        mov     cx,bp
        push    di
boot_logo_plane4:
        lodsd
        stosb
        mov     ah,0
        add     cs:[boot_logo_checksum],ax
        loop    boot_logo_plane4
        pop     di
        pop     bp
        ret
boot_logo_copy_row endp
        .8086
sysinitseg ends
end
