sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 0f0ch
dos_umb_flag db 1
 org 336fh
boot_config_flags db 0
 org 40d8h
boot_winboot_command db 3 dup(0)
boot_winboot_dir db 64 dup(0)
 org 4129h
boot_winboot_dir_len dw 0
 org 42dfh
boot_driver_depth db 0ffh
 org 4ed1h
; Execute one startup driver record at DS:BX.
; Carry indicates the end of the record table or an unavailable path.
        .386
boot_process_driver_record proc near
        cld
        pusha
        push    es
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     cx,[bx]
        stc
        jcxz    boot_driver_return
        cmp     byte ptr [dos_umb_flag],0
        je      boot_driver_return
        test    byte ptr [boot_config_flags],20h
        jnz     boot_driver_return
        inc     byte ptr [boot_driver_depth]
        jnz     boot_driver_leave
        call    cx
        je      boot_driver_leave
        mov     di,offset boot_winboot_dir
        add     di,[boot_winboot_dir_len]
        push    di
        mov     si,[bx+2]
        mov     dx,[bx+4]
        movzx   cx,dl
        rep     movsb
        mov     cl,'U'
        test    dh,80h
        jz      boot_driver_install
        mov     cl,'D'
        and     dh,7fh
        mov     al,0ah
        stosb
        jmp     short boot_driver_command
boot_driver_install:
        mov     byte ptr [di-1],' '
        mov     ax,0a0dh
        stosw
boot_driver_command:
        xchg    ax,cx
        mov     si,offset boot_winboot_command
        mov     cx,di
        sub     cx,si
        call    boot_execute_config_line
        pop     di
        mov     al,0
        stosb
boot_driver_leave:
        dec     byte ptr [boot_driver_depth]
        clc
boot_driver_return:
        pop     es
        popa
        ret
boot_process_driver_record endp
        .8086
 org 4f38h
boot_execute_config_line proc near
 ret
boot_execute_config_line endp
sysinitseg ends
end
