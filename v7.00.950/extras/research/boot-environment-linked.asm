sysinitseg segment para public 'code'
assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
org 0ff5h
def_php dw 0
org 27ddh
copy_envvar proc near
 ret
copy_envvar endp
org 336fh
boot_config_flags db 0
org 4088h
boot_windows_dir db 78 dup (0)
boot_windows_dir_len dw 0
org 40dbh
boot_winboot_dir db 78 dup (0)
boot_winboot_dir_len dw 0
org 412eh
boot_command_dir db 8 dup (0)
org 413eh
boot_device_scratch db 78 dup (0)
org 41cch
boot_env_tmp db 4 dup (0)
boot_env_temp db 5 dup (0)
boot_temp_dir db 5 dup (0)
boot_env_prompt db 12 dup (0)
boot_env_winboot db 11 dup (0)
boot_env_path db 5 dup (0)
org 4213h
boot_env_comspec db 8 dup (0)
org 455eh
commnd2 db 78 dup (0)
org 474ah
winboot_shell_pending db 0
org 50f4h
boot_prepare_environment proc near
        cld
        push    ds
        pop     es
        test    byte ptr [boot_config_flags],20h
        jz      short boot_env_check_shell
        jmp     near ptr boot_env_done
boot_env_check_shell:
        cmp     byte ptr [exec_option],0
        je      short boot_env_check_tmp
        jmp     near ptr boot_env_done
boot_env_check_tmp:
        sub     dx,dx
        mov     si,offset boot_env_tmp
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_existing_tmp
        push    ds
        mov     ds,[def_php]
        mov     dx,80h
        mov     ah,1ah
        int     21h
        pop     ds
        mov     di,offset boot_device_scratch+1
        mov     cx,4
        rep     movsb
        mov     dx,di
        mov     si,offset boot_windows_dir
        mov     cx,[boot_windows_dir_len]
        rep     movsb
        mov     bx,di
        mov     si,offset boot_temp_dir
        mov     cx,5
        rep     movsb
        mov     ax,4e00h
        stosb
        dec     di
        mov     cx,10h
        int     21h
        jc      short boot_env_make_temp
        push    ds
        mov     ds,[def_php]
        test    byte ptr ds:[95h],10h
        pop     ds
        jz      short boot_env_temp_parent
        jmp     short boot_env_set_tmp
boot_env_make_temp:
        mov     ah,39h
        int     21h
        jnc      short boot_env_set_tmp
boot_env_temp_parent:
        mov     di,bx
        cmp     word ptr [boot_windows_dir_len],2
        ja      short boot_env_temp_end
        mov     al,5ch
        stosb
boot_env_temp_end:
        sub     al,al
        stosb
boot_env_set_tmp:
        mov     dx,1
        mov     si,offset boot_device_scratch+1
        call    copy_envvar
        jmp     short boot_env_check_temp
boot_env_existing_tmp:
        push    ds
        mov     ds,[config_wrkseg]
        mov     si,dx
        mov     di,offset boot_device_scratch+5
        mov     cx,64
        rep     movsb
        pop     ds
boot_env_check_temp:
        sub     dx,dx
        mov     si,offset boot_env_temp
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_check_prompt
        mov     di,offset boot_device_scratch
        mov     cx,5
        rep     movsb
        mov     dx,1
        mov     si,offset boot_device_scratch
        call    copy_envvar
boot_env_check_prompt:
        sub     dx,dx
        mov     si,offset boot_env_prompt
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_check_winboot
        inc     dx
        call    copy_envvar
boot_env_check_winboot:
        sub     dx,dx
        mov     si,offset boot_env_winboot
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_check_path
        mov     di,offset boot_device_scratch
        mov     cx,11
        rep     movsb
        mov     si,offset boot_winboot_dir
        mov     cx,[boot_winboot_dir_len]
        rep     movsb
        mov     al,0
        stosb
        inc     dx
        mov     si,offset boot_device_scratch
        call    copy_envvar
boot_env_check_path:
        sub     dx,dx
        mov     si,offset boot_env_path
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_check_comspec
        mov     di,offset boot_device_scratch
        mov     cx,5
        rep     movsb
        mov     al,[boot_windows_dir]
        cmp     al,[boot_winboot_dir]
        je      short boot_env_path_windows
        cmp     byte ptr [boot_winboot_dir],'C'
        jb      short boot_env_path_windows
        mov     si,offset boot_winboot_dir
        mov     cx,[boot_winboot_dir_len]
        cmp     cx,2
        rep     movsb
        ja      short boot_env_path_separator
        mov     al,5ch
        stosb
boot_env_path_separator:
        mov     al,';'
        stosb
boot_env_path_windows:
        mov     si,offset boot_windows_dir
        mov     cx,[boot_windows_dir_len]
        cmp     cx,2
        rep     movsb
        ja      short boot_env_path_command
        mov     al,5ch
        stosb
        jmp     short boot_env_path_end
boot_env_path_command:
        mov     al,';'
        stosb
        mov     si,offset boot_windows_dir
        mov     cx,[boot_windows_dir_len]
        rep     movsb
        mov     si,offset boot_command_dir
        mov     cx,8
        rep     movsb
boot_env_path_end:
        sub     al,al
        stosb
        mov     dx,1
        mov     si,offset boot_device_scratch
        call    copy_envvar
boot_env_check_comspec:
        cmp     byte ptr [winboot_shell_pending],0
        je      short boot_env_done
        sub     dx,dx
        mov     si,offset boot_env_comspec
        call    copy_envvar
        test    dx,dx
        jnz      short boot_env_done
        mov     di,offset boot_device_scratch
        mov     cx,8
        rep     movsb
        mov     si,offset commnd2
boot_env_comspec_copy:
        lodsb
        stosb
        or      al,al
        jnz      short boot_env_comspec_copy
        mov     dx,1
        mov     si,offset boot_device_scratch
        call    copy_envvar
boot_env_done:
        ret
boot_prepare_environment endp
org 5ad0h
config_wrkseg dw 0
org 0a09ch
exec_option db 0
sysinitseg ends
end
