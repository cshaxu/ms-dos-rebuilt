sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 3370h
boot_runtime_flags dw 0
 org 5870h
boot_option_error proc near
 ret
boot_option_error endp
 org 5a01h
; Match a startup option against the table at DS:DI.
; DS:SI addresses the option line.  Entries end in a type byte and word.
boot_option_dispatch proc near
boot_match_entry:
        mov     bx,si
boot_match_current:
        cmp     byte ptr [di],0
        je      boot_match_direct
boot_match_char:
        mov     al,[di]
        inc     di
        cmp     al,1
        je      boot_match_number
        jb      boot_match_jump
        cmp     al,2
        je      boot_match_flag
        cmp     al,[si]
        jne     boot_match_skip
        inc     si
        jmp     short boot_match_char
boot_match_direct:
        inc     di
        jmp     word ptr [di]
boot_match_number:
        lodsb
        cmp     al,'='
        je      boot_number_value
        jmp     near ptr boot_option_error
boot_number_value:
        call    boot_option_number
        jnc     boot_number_limit
        jmp     near ptr boot_option_error
boot_number_limit:
        cmp     ax,90
        jbe     boot_number_store
        jmp     near ptr boot_option_error
boot_number_store:
        mov     di,[di]
        mov     [di],al
        ret
boot_match_flag:
        lodsb
        cmp     al,'='
        je      boot_flag_value
        jmp     near ptr boot_option_error
boot_flag_value:
        call    boot_option_number
        jnc     boot_flag_store
        jmp     near ptr boot_option_error
boot_flag_store:
        mov     cx,[di]
        or      word ptr [boot_runtime_flags],cx
        test    al,al
        je      boot_flags_sync
        not     cx
        and     word ptr [boot_runtime_flags],cx
boot_flags_sync:
        ret                             ; BIOS flag sync remains to be restored
 org 5a71h
boot_match_jump:
        jmp     word ptr [di]
boot_match_skip:
        mov     al,[di]
        inc     di
        cmp     al,2
        ja      boot_match_skip
        inc     di
        inc     di
        mov     si,bx
        jmp     boot_match_entry
boot_option_dispatch endp
 org 5a80h
boot_option_number proc near
 ret
boot_option_number endp
sysinitseg ends
end
