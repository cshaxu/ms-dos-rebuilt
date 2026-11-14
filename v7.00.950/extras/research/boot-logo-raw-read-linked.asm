sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 9316h
; Read an uncompressed startup image block from BX into DS:DX.
boot_logo_read_file proc near
        mov     cx,8000h
        mov     ah,3fh
        stc
        int     21h
        ret
boot_logo_read_file endp
sysinitseg ends
end
