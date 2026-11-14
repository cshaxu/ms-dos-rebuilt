Bios_Code segment at 1d5h
 org 1fd6h
win386_info_buffer db 78 dup (?)
win386_info_table db 128 dup (?)
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 0f40h
BCodeSeg dw 1d5h
 org 336fh
boot_config_flags db 0
boot_runtime_flags db 0
 org 3375h
query_mode_flags db 0
 org 40dbh
boot_winboot_dir db 64 dup (0)
 org 4129h
boot_winboot_dir_len dw 0
 org 41f6h
boot_netstart_cmd db ' /K NETSTART',0
boot_autoexec_cmd db ' /D /K AUTOEXEC',0
 org 42abh
boot_autoexec_name db '\AUTOEXEC.BAT',0
 org 448dh
newcmd db 0
 org 4490h
commnd db 78 dup (0)
command_line db 128 dup (0)
commnd2 db 78 dup (0)
command_line2 db 128 dup (0)
 org 46fah
commnd4 db 81 dup (0)
boot_autoexec_exists db 0
 org 4f9ah
; Prepare the Windows and command interpreter paths and startup arguments.
        public  boot_prepare_shell
boot_prepare_shell proc near
        cld
        push    cs
        pop     ds
        push    cs
        pop     es
        test    byte ptr [boot_config_flags],20h
        jz      boot_shell_paths
        jmp     near ptr boot_shell_done
boot_shell_paths:
        mov     si,offset boot_winboot_dir
        mov     cx,[boot_winboot_dir_len]
        mov     di,offset commnd4
        mov     dx,78
        call    boot_insert_path
        mov     di,offset commnd
        mov     bx,offset command_line+1
        cmp     byte ptr [newcmd],0
        je      boot_shell_insert
        mov     di,offset commnd2
        mov     bx,offset command_line2+1
boot_shell_insert:
        call    boot_insert_path
        mov     dx,126
        mov     di,bx
        call    boot_insert_path
        jc      boot_shell_arguments
        add     [di-1],cl
boot_shell_arguments:
        sub     ax,ax
        mov     bx,offset command_line+1
        mov     di,bx
        test    byte ptr [query_mode_flags],4
        jz      boot_shell_autoexec
        cmp     [exec_option],al
        jne     boot_shell_autoexec
        cmp     byte ptr [exec_value+2],al
        jne     boot_shell_autoexec
        push    di
        mov     al,[di-1]
        add     di,ax
        mov     cx,12
        add     ax,cx
        cmp     ax,127
        jae     boot_shell_net_done
        add     [bx-1],cl
        inc     cx
        mov     si,offset boot_netstart_cmd
        rep     movsb
        pop     di
        jmp     short boot_shell_copy_bios
boot_shell_net_done:
        pop     di
boot_shell_autoexec:
        test    byte ptr [boot_runtime_flags],20h
        jz      boot_shell_copy_bios
        test    byte ptr [query_mode_flags],1
        jnz     boot_shell_copy_bios
        mov     cx,15
        mov     si,offset boot_autoexec_cmd
        mov     ax,3d00h
        mov     dx,offset boot_autoexec_name
        int     21h
        jnc     boot_shell_append_autoexec
        mov     cx,3
        mov     byte ptr [si+3],0
boot_shell_append_autoexec:
        sub     ax,ax
        mov     al,[di-1]
        add     di,ax
        add     ax,cx
        cmp     ax,127
        jae     boot_shell_copy_bios
        add     [bx-1],cl
        inc     cx
        rep     movsb
boot_shell_copy_bios:
        mov     es,[BCodeSeg]
        assume  es:Bios_Code
        mov     si,offset commnd
        mov     di,offset Bios_Code:win386_info_buffer
        mov     cx,78
        rep     movsb
        mov     si,offset command_line
        mov     di,offset Bios_Code:win386_info_table
        mov     cx,128
        rep     movsb
        mov     al,6
        cmp     byte ptr [exec_option],0
        jne     boot_shell_test_mode
        cmp     byte ptr [exec_value+2],0
        je      boot_shell_test_mode
        and     al,0fbh
boot_shell_test_mode:
        test    [query_mode_flags],al
        jnz     boot_shell_done
        test    byte ptr [query_mode_flags],1
        jnz     boot_shell_rotate
        mov     ax,3d00h
        mov     dx,offset boot_autoexec_name
        int     21h
        jc      boot_shell_rotate
        xchg    ax,bx
        sub     cx,cx
        sub     dx,dx
        mov     ax,4202h
        int     21h
        or      ax,dx
        xchg    ax,cx
        mov     ah,3eh
        int     21h
        jcxz    boot_shell_rotate
        inc     byte ptr [boot_autoexec_exists]
        jmp     short boot_shell_done
boot_shell_rotate:
        call    rotate_shell_records
boot_shell_done:
        ret
boot_prepare_shell endp

 org 50ach
rotate_shell_records proc near
 ret
rotate_shell_records endp
 org 52c9h
boot_insert_path proc near
 ret
boot_insert_path endp
 org 0a09ch
exec_option db 0
exec_value dw 30h
 db 0
sysinitseg ends
end
