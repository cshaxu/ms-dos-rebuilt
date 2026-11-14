; Format a double word as eight hexadecimal digits.
        .386
Bios_Code segment word public use16 'Bios_Code'
        assume  cs:Bios_Code,es:nothing
        org     2D16h
hex_digits      db      '0123456789ABCDEF'
hex_dword proc near
        push    bx
        cld
        mov     bx,offset hex_digits
        mov     ah,0Fh
        mov     cx,8
hex_next:
        rol     edx,4
        mov     al,dl
        and     al,ah
        xlat    cs:hex_digits
        stosb
        loop    hex_next
        pop     bx
        ret
hex_dword endp
Bios_Code ends
        end     hex_dword
