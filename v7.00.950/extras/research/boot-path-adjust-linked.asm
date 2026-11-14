Bios_Code segment at 1d5h
 org 1f16h
win386_text_length dw ?
win386_text_buffer db ?
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 0f40h
BCodeSeg dw 1d5h
 org 336fh
boot_config_flags db 0
boot_runtime_flags db 0
 org 4067h
boot_network db 0
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
 org 42c9h
boot_driver_entry1 db 11h
 org 42ddh
boot_driver_entry2 db 11h
 org 589dh
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
        test    byte ptr [boot_config_flags],8
        jnz     boot_paths_end
        or      byte ptr [boot_config_flags],8
        push    es
        mov     es,[BCodeSeg]
        assume  es:Bios_Code
        add     di,[boot_winboot_dir_len]
        push    di
        mov     cx,es:[win386_text_length]
        sub     cx,2
        mov     si,offset Bios_Code:win386_text_buffer+2
        mov     es:[si-2],al
boot_path_suffix:
        lods    byte ptr es:[si]
        mov     [di],al
        inc     di
        loop    boot_path_suffix
        sub     cx,cx
        mov     si,offset boot_winboot_dir
        mov     di,offset Bios_Code:win386_text_buffer
boot_path_to_bios:
        lodsb
        stosb
        inc     cx
        test    al,al
        jnz     boot_path_to_bios
        mov     es:[win386_text_length],cx
        pop     di
        pop     es
        assume  es:sysinitseg
        sub     al,al
        stosb
        cmp     byte ptr [boot_network],0
        je      boot_check_double_buffer
        mov     byte ptr [exec_value],'1'
boot_check_double_buffer:
        cmp     byte ptr [exec_mode],1
        ja      boot_paths_end
        mov     byte ptr [boot_driver_entry1],0dh
        mov     byte ptr [boot_driver_entry2],0dh
boot_paths_end:
        ret
boot_prepare_paths endp
 org 0a09bh
exec_mode db 0
 db 0
exec_value dw 30h
sysinitseg ends
end
