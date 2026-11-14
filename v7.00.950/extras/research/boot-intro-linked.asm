sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0fefh
boot_mode db 0
 org 1453h
; Select the startup message and detect a restart into MS-DOS mode.
        test    byte ptr [boot_runtime_flags],10h
        jnz     boot_intro_done
boot_intro_retry:
        mov     bx,offset sysinit_msg_base
        add     bx,word ptr [sysinit_msg_table+4]
        mov     dx,offset boot_config_app
        mov     ax,4300h
        int     21h
        jnc     boot_intro_print
        mov     bx,offset sysinit_msg_base
        add     bx,word ptr [sysinit_msg_table+2]
        mov     dx,offset boot_config_wos
        mov     ax,4300h
        int     21h
        jnc     boot_intro_dos_mode
        mov     dx,offset boot_msdos_status
        mov     ax,4300h
        int     21h
        jnc     boot_intro_dos_mode
        mov     bx,offset sysinit_msg_base
        add     bx,word ptr [sysinit_msg_table]
        test    byte ptr [boot_runtime_flags],1
        jnz     boot_intro_print
        cmp     word ptr [boot_delay],0
        je      boot_intro_done
        jmp     short boot_intro_print
boot_intro_dos_mode:
        mov     byte ptr [boot_mode],1
        or      byte ptr [boot_runtime_flags],1
boot_intro_print:
        mov     dx,bx
        call    print
        cmp     byte ptr [boot_mode],1
        jne     boot_intro_done
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+6]
        call    print
        shl     word ptr [boot_delay],1
boot_intro_done:
 org 321ch
print proc near
 ret
print endp
 org 3370h
boot_runtime_flags db 0
 org 4060h
boot_delay dw 0
 org 43a2h
; Files used to identify a restart into MS-DOS mode.
boot_config_app db 'CONFIG.APP',0
boot_config_wos db 'CONFIG.WOS',0
boot_msdos_status db 'C:\MSDOSSYS.STS',0
 org 0a568h
sysinit_msg_table dw 65 dup (0)
sysinit_msg_base db 0
sysinitseg ends
end
