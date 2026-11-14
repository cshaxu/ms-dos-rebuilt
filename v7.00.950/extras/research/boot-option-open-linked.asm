Bios_Code segment at 1d5h
 org 20a4h
win386_options_path db 16 dup (?)
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
sysi_boot_drive equ 43h
 org 0eebh
dosinfo dd 0
 org 0f40h
BCodeSeg dw 1d5h
 org 336fh
boot_config_flags db 0
boot_runtime_flags db 0
 org 43d1h
boot_msdos_name db 'MSDOS.SYS',0
boot_msdos_root db 'C:\MSDOS.SYS',0
 org 445eh
 db 9
boot_msdos_w40 db 'MSDOS.W40',0
 db 11
boot_winboot_ini db 'WINBOOT.INI',0
 org 5522h
boot_option_handle dw 0
 org 575fh
; Open the requested or default startup options file.
; DS:DX is an optional filename; zero selects WINBOOT.INI.
        public  boot_option_open
boot_option_open proc near
        cld
        push    ds
        pop     es
        test    dx,dx
        jnz     boot_open_first
        mov     dx,offset boot_winboot_ini
boot_open_first:
        mov     ax,3d00h
        int     21h
        jc      boot_open_w40
        and     byte ptr [boot_runtime_flags],7fh
        jmp     short boot_open_found
boot_open_w40:
        mov     byte ptr [boot_winboot_ini-1],0
        mov     dx,offset boot_msdos_w40
        mov     ax,3d00h
        int     21h
        jnc     boot_open_found
        mov     byte ptr [boot_msdos_w40-1],0
        mov     dx,offset boot_msdos_name
        mov     ax,3d00h
        int     21h
        jnc     boot_open_found
        mov     dx,offset boot_msdos_root
        mov     ax,3d00h
        int     21h
        jnc     boot_open_root
        jmp     near ptr boot_option_no_file
boot_open_root:
        push    ds
        lds     si,[dosinfo]
        assume  ds:nothing
        mov     byte ptr [si].sysi_boot_drive,3
        pop     ds
        assume  ds:sysinitseg
        or      byte ptr [boot_config_flags],4
boot_open_found:
        mov     [boot_option_handle],ax
        push    es
        mov     si,dx
        cmp     si,offset boot_msdos_w40
        jne     boot_open_copy_name
        mov     si,offset boot_msdos_name
boot_open_copy_name:
        mov     di,offset Bios_Code:win386_options_path+3
        mov     es,[BCodeSeg]
        assume  es:Bios_Code
        mov     cx,13
        rep     movsb
        mov     ax,3305h
        int     21h
        add     dl,'@'
        mov     es:[win386_options_path],dl
        pop     es
        assume  es:sysinitseg
boot_option_open endp
 org 5899h
boot_option_no_file: ret
sysinitseg ends
end
