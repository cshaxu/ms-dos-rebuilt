sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 913ah
; Set the VGA display mode used by the startup logo.
; CX nonzero also clears the upper display memory.
boot_logo_video_mode proc near
        mov     ax,93h
        int     10h
        mov     dx,3dah
        in      al,dx
        mov     dl,0c0h
        xor     al,al
        out     dx,al
        mov     dl,0c4h
        mov     ax,0f02h
        out     dx,ax
        mov     al,4
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0f7h
        or      al,4
        out     dx,al
        mov     dl,0ceh
        mov     al,5
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0efh
        out     dx,al
        dec     dx
        mov     al,6
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0fdh
        out     dx,al
        jcxz    boot_logo_no_clear
        mov     ax,0a000h
        mov     es,ax
        xor     ax,ax
        mov     di,8000h
        cld
        rep     stosb
boot_logo_no_clear:
        mov     dl,0d4h
        mov     ax,800ch
        out     dx,ax
        mov     al,9
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0e0h
        out     dx,al
        dec     dx
        mov     al,14h
        out     dx,al
        inc     dx
        in      al,dx
        and     al,0bfh
        out     dx,al
        dec     dx
        mov     al,17h
        out     dx,al
        inc     dx
        in      al,dx
        or      al,40h
        out     dx,al
        ret
boot_logo_video_mode endp
sysinitseg ends
end
