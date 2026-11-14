sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 4088h
boot_windows_dir db 64 dup (0)
 org 40dbh
boot_winboot_dir db 64 dup (0)
 org 412bh
boot_host_drive db 2 dup (0)
 org 57f0h
; Parse the Windows directory, boot directory, and host drive options.
boot_option_windir proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        mov     cx,64
        mov     di,offset boot_windows_dir
boot_option_windir endp

boot_option_copy proc near
boot_copy_next:
        lodsb
        stosb
        cmp     al,0dh
        loopne  boot_copy_next
        mov     byte ptr [di-1],0
        ret
boot_option_copy endp
boot_option_winbootdir proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        mov     cx,64
        mov     di,offset boot_winboot_dir
        jmp     boot_option_copy
boot_option_winbootdir endp

boot_option_hostdrive proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        mov     cx,2
        mov     di,offset boot_host_drive
        jmp     boot_option_copy
boot_option_hostdrive endp
 org 5870h
boot_option_error proc near
 ret
boot_option_error endp
sysinitseg ends
end
