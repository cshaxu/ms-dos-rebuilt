sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
boot_option_windir equ 057f0h
boot_option_winbootdir equ 05806h
boot_option_hostdrive equ 05813h
boot_option_uninstall equ 05820h
boot_option_delay equ 05826h
boot_option_disablelog equ 05839h
boot_option_config equ 0584dh
boot_menu equ 04062h
boot_menu_default equ 04063h
boot_menu_delay equ 04064h
boot_safe equ 04066h
boot_network equ 04067h
exec_mode equ 0a09bh
 org 336fh
boot_config_flags db 0
 org 5522h
boot_option_handle dw 0
 org 5628h
; Section and option tables for the startup options file.
boot_option_current dw offset boot_option_sections
boot_option_sections label byte
        db      '[PATHS]',0
        dw      offset boot_section_paths
        db      '[OPTIONS]',0
        dw      offset boot_section_options
        db      0
        dw      offset boot_option_error
boot_option_paths label byte
        db      'WINDIR',0
        dw      offset boot_option_windir
        db      'WINBOOTDIR',0
        dw      offset boot_option_winbootdir
        db      'HOSTWINBOOTDRV',0
        dw      offset boot_option_hostdrive
        db      'UNINSTALLDIR',0
        dw      offset boot_option_uninstall
        db      0
        dw      offset boot_section_restart
boot_option_options label byte
        db      'LOGO',2
        dw      1
        db      'DBLSPACE',2
        dw      2
        db      'DRVSPACE',2
        dw      4
        db      'BOOTKEYS',2
        dw      8
        db      'BOOTDELAY',0
        dw      offset boot_option_delay
        db      'BOOTWIN',2
        dw      10h
        db      'BOOTGUI',2
        dw      20h
        db      'BOOTWARN',2
        dw      100h
        db      'BOOTMULTI',2
        dw      80h
        db      'DOUBLEBUFFER',1
        dw      offset exec_mode
        db      'BOOTMENUDEFAULT',1
        dw      offset boot_menu_default
        db      'BOOTMENUDELAY',1
        dw      offset boot_menu_delay
        db      'BOOTMENU',1
        dw      offset boot_menu
        db      'BOOTSAFE',1
        dw      offset boot_safe
        db      'NETWORK',1
        dw      offset boot_network
        db      'LOADTOP',2
        dw      40h
        db      'BOOTCONFIG',0
        dw      offset boot_option_config
        db      'DISABLELOG',0
        dw      offset boot_option_disablelog
        db      'SYSTEMREG',2
        dw      200h
        db      0
        dw      offset boot_section_restart
 org 57dah
; Read and dispatch lines from the open startup options file.
boot_option_readloop proc near
boot_option_next:
        call    boot_option_getline
        jnc     boot_option_line_ready
        jmp     near ptr boot_option_close
boot_option_line_ready:
        and     byte ptr [boot_config_flags],0feh
        mov     di,[boot_option_current]
boot_option_loop_dispatch:
        call    boot_option_dispatch
        jmp     short boot_option_next
boot_option_readloop endp
 org 585ah
; Retry an unmatched line against the section names.
boot_section_restart proc near
        mov     di,offset boot_option_sections
        add     sp,2
        jmp     boot_option_loop_dispatch
boot_section_restart endp

boot_section_paths proc near
        mov     word ptr [boot_option_current],offset boot_option_paths
        ret
boot_section_paths endp

boot_section_options proc near
        mov     word ptr [boot_option_current],offset boot_option_options
        ret
boot_section_options endp
 org 5870h
boot_option_error proc near
 ret
boot_option_error endp
 org 5891h
; Close the options file and finish preparing the startup paths.
boot_option_close proc near
        mov     ah,3eh
        mov     bx,[boot_option_handle]
        int     21h
        call    boot_prepare_paths
        ret
boot_option_close endp
 org 589dh
boot_prepare_paths proc near
 ret
boot_prepare_paths endp
 org 597eh
boot_option_getline proc near
 ret
boot_option_getline endp
 org 5a01h
boot_option_dispatch proc near
 ret
boot_option_dispatch endp
sysinitseg ends
end
