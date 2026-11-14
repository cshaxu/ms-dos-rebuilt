sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 0f0ch
dos_umb_flag db 1
 org 0f21h
confbot dw 0
 org 0f2dh
linecount dw 0
 org 0f52h
multi_pass_id db 0
 org 0fdah
count dw 0
 org 0fdeh
chrptr dw 0
 org 336fh
boot_config_flags db 0
 org 3374h
bQueryOpt db 0
query_mode_flags db 0
 org 40d8h
boot_winboot_command db 3 dup(0)
boot_winboot_dir db 64 dup(0)
 org 4129h
boot_winboot_dir_len dw 0
 org 42b9h
boot_driver_table dw 0,0
boot_himem_record_length db 17h,81h
 org 42dfh
boot_driver_depth db 0ffh
 org 4b01h
boot_check_umb_stack proc near
 ret
boot_check_umb_stack endp
 org 4b9fh
boot_check_umb_rom proc near
 ret
boot_check_umb_rom endp
 org 4each
; Process the startup driver records and apply stack compatibility checks.
        public  boot_process_drivers
boot_process_drivers proc near
        cld
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     bx,offset boot_driver_table
        test    byte ptr [query_mode_flags],1
        jnz     boot_driver_next
        mov     byte ptr [boot_himem_record_length],0bh
boot_driver_next:
        call    boot_process_driver_record
        jc      boot_driver_all_done
        add     bx,6
        jmp     short boot_driver_next
boot_driver_all_done:
        call    boot_check_umb_stack
        call    boot_check_umb_rom
        ret
boot_process_drivers endp
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
boot_execute_config_line proc near
        push    bx
        mov     [si],al
        mov     word ptr [si+1],0
        push    word ptr [confbot]
        push    word ptr [chrptr]
        push    word ptr [count]
        push    word ptr [linecount]
        push    word ptr [config_multi]
        mov     word ptr [config_multi],1
        mov     [confbot],es
        mov     [chrptr],si
        mov     [count],cx
        xchg    dh,[bQueryOpt]
        mov     dl,[multi_pass_id]
        push    dx
        mov     byte ptr [multi_pass_id],2
        push    ds
        push    es
        call    multi_pass_config_line
        pop     es
        pop     ds
        pop     dx
        mov     [multi_pass_id],dl
        mov     [bQueryOpt],dh
        pop     word ptr [config_multi]
        pop     word ptr [linecount]
        pop     word ptr [count]
        pop     word ptr [chrptr]
        pop     word ptr [confbot]
        pop     bx
        ret
boot_execute_config_line endp
 org 5ad3h
config_multi db 0,0
 org 6942h
multi_pass_config_line proc near
 ret
multi_pass_config_line endp
sysinitseg ends
end
