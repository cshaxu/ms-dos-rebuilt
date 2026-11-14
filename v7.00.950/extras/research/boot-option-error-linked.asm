sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 55a4h
boot_option_line db 128 dup (0)
 org 5870h
; Display the invalid startup option and its diagnostic.
boot_option_error proc near
        mov     ah,9
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+120]
        int     21h
        mov     si,offset boot_option_line
boot_error_char:
        lodsb
        mov     dl,al
        mov     ah,2
        int     21h
        cmp     dl,0dh
        jne     boot_error_char
        mov     dl,0ah
        mov     ah,2
        int     21h
        ret
boot_option_error endp
 org 0a568h
sysinit_msg_table dw 65 dup (0)
sysinit_msg_base db 0
sysinitseg ends
end
