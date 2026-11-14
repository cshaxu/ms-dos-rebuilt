sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 336fh
boot_config_flags db 0
boot_runtime_flags db 0
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

 org 589dh
; Set default directory names and remove a trailing backslash.
; The later BIOS path propagation is not yet connected.
boot_prepare_paths proc near
        mov     di,offset boot_windows_dir
        cmp     byte ptr [di],0
        jne     boot_windows_length
        or      byte ptr [boot_config_flags],20h
        mov     ah,19h
        int     21h
        add     al,'A'
        mov     [di],al
        cmp     al,'C'
        jae     boot_windows_length
        mov     byte ptr [di+3],0
        or      byte ptr [boot_runtime_flags],1
boot_windows_length:
        xor     al,al
        mov     cx,64
        repne   scasb
        not     cx
        add     cx,64
        mov     [boot_windows_dir_len],cx
        cmp     byte ptr [di-2],'\'
        jne     boot_winboot_default
        mov     byte ptr [di-2],0
        dec     cx
        mov     [boot_windows_dir_len],cx
boot_winboot_default:
        mov     di,offset boot_winboot_dir
        cmp     byte ptr [di],0
        jne     boot_winboot_length
        push    di
        mov     si,offset boot_windows_dir
        inc     cx
        rep     movsb
        pop     di
boot_winboot_length:
        xor     al,al
        mov     cx,64
        repne   scasb
        not     cx
        add     cx,64
        mov     [boot_winboot_dir_len],cx
        cmp     byte ptr [di-2],'\'
        jne     boot_drive_default
        mov     byte ptr [di-2],0
        dec     word ptr [boot_winboot_dir_len]
boot_drive_default:
        mov     di,offset boot_winboot_dir
        mov     al,[di]
        mov     bx,offset boot_host_drive
        cmp     byte ptr [bx],0
        jne     boot_paths_done
        mov     [bx],al
boot_paths_done:
        ret
boot_prepare_paths endp
sysinitseg ends
end
