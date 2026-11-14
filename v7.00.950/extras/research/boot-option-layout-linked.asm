sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 4088h
; Windows directories and host drive from the startup options file.
boot_windows_dir db 0,':\WINDOWS',0,53 dup (0)
        db      14 dup (0)             ; adjacent path workspace
boot_windows_dir_len dw 0
        db      3 dup (0)
boot_winboot_dir db 0,':\WINDOWS',0,53 dup (0)
        db      14 dup (0)             ; adjacent path workspace
boot_winboot_dir_len dw 0
boot_host_drive db 2 dup (0)
 org 5820h
; Accept UNINSTALLDIR, which has no startup action.
boot_option_uninstall proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        ret
boot_option_uninstall endp
 org 5870h
boot_option_error proc near
 ret
boot_option_error endp
sysinitseg ends
end
