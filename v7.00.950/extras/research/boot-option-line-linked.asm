sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 5522h
boot_option_handle dw  0               ; startup option file handle
boot_option_buffer db  128 dup (0)     ; file read buffer
boot_option_line db    128 dup (0)     ; current option line
boot_option_count dw   0               ; bytes in read buffer
boot_option_index dw   0               ; next byte in read buffer
 org 597eh
; Read the next nonblank startup option line into boot_option_line.
; Spaces and tabs are discarded; a semicolon begins a comment.
boot_option_getline proc near
        mov     si,offset boot_option_line
boot_line_first:
        call    boot_option_getchar
        jc      boot_line_return
        cmp     al,0e9h
        stc
        je      boot_line_return
        cmp     al,0ebh
        stc
        je      boot_line_return
boot_line_char:
        cmp     al,9
        je      boot_line_next
        cmp     al,' '
        je      boot_line_next
        cmp     al,';'
        je      boot_line_comment
        cmp     al,0dh
        je      boot_line_end
        call    boot_toupper
        mov     [si],al
        inc     si
        cmp     si,offset boot_option_line+127
        je      boot_line_comment
boot_line_next:
        call    boot_option_getchar
        jmp     short boot_line_char
boot_line_comment:
        call    boot_option_getchar
        cmp     al,0dh
        jne     boot_line_comment
boot_line_end:
        mov     byte ptr [si],0dh
        mov     si,offset boot_option_line
        cmp     byte ptr [si],0dh
        je      boot_line_first
        clc
boot_line_return:
        ret
boot_option_getline endp

; Return the next character from the startup option file in AL.
; Carry indicates an error or end of file; AL then contains CR.
boot_option_getchar proc near
        mov     bx,[boot_option_index]
        cmp     bx,[boot_option_count]
        jb      boot_char_buffered
        mov     bx,[boot_option_handle]
        mov     dx,offset boot_option_buffer
        mov     cx,80h
        mov     ah,3fh
        int     21h
        jc      boot_char_eof
        test    ax,ax
        jz      boot_char_eof
        mov     [boot_option_count],ax
        sub     bx,bx
boot_char_buffered:
        mov     al,[bx+boot_option_buffer]
        inc     bx
        mov     [boot_option_index],bx
        cmp     al,1ah
        je      boot_char_cr
        cmp     al,0ah
        jne     boot_char_done
boot_char_cr:
        mov     al,0dh
boot_char_done:
        clc
        ret
boot_char_eof:
        mov     al,0dh
        stc
        ret
boot_option_getchar endp
 org 5abfh
boot_toupper proc near
        cmp     al,'a'
        jb      boot_upper_done
        cmp     al,'z'
        ja      boot_upper_done
        sub     al,20h
boot_upper_done:
        ret
boot_toupper endp
sysinitseg ends
end
