sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 3370h
boot_runtime_flags db 0
 org 3377h
bDefBlock db 0
bMaxBlock db 0
 org 337bh
secTimeOut db 0,0
 org 339bh
aoffBlockDesc dw 10 dup (0)
 org 4062h
boot_menu db 0
boot_menu_default db 1
boot_menu_delay dw 30
 org 412dh
boot_previous_menu db 3
 org 5397h
; Build the Windows startup menu descriptions and default selection.
boot_build_menu proc near
        mov     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+88]
        mov     [bx+aoffBlockDesc],dx
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+90]
        mov     [bx+aoffBlockDesc],dx
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+92]
        mov     [bx+aoffBlockDesc],dx
        cmp     byte ptr [exec_value],'0'
        je      boot_menu_nonetwork
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+94]
        mov     [bx+aoffBlockDesc],dx
boot_menu_nonetwork:
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+96]
        mov     [bx+aoffBlockDesc],dx
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+98]
        mov     [bx+aoffBlockDesc],dx
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+100]
        mov     [bx+aoffBlockDesc],dx
        test    byte ptr [boot_runtime_flags],80h
        jnz     boot_menu_no_old_dos
        add     bx,2
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+102]
        mov     [bx+aoffBlockDesc],dx
boot_menu_no_old_dos:
        shr     bx,1
        mov     [bMaxBlock],bl
        mov     al,[boot_menu_default]
        cmp     al,bl
        jbe     boot_menu_default_ok
        mov     al,bl
boot_menu_default_ok:
        mov     [bDefBlock],al
        mov     ax,[boot_menu_delay]
        test    di,di
        jnz     boot_menu_previous
        cmp     byte ptr [boot_menu],0
        jne     boot_menu_set_time
        mov     ax,0ffh
        jmp     short boot_menu_set_time
boot_menu_previous:
        mov     dl,[boot_previous_menu]
        mov     [bDefBlock],dl
        cmp     dl,3
        jne     boot_menu_set_time
        cmp     byte ptr [exec_option],0
        je      boot_menu_set_time
        cmp     byte ptr [exec_value],'0'
        je      boot_menu_set_time
        mov     byte ptr [bDefBlock],4
boot_menu_set_time:
        mov     word ptr [secTimeOut],ax
        ret                             ; selection handling remains to be restored
boot_build_menu endp
 org 0a09ch
exec_option db 0
exec_value dw 30h
 org 0a568h
sysinit_msg_table dw 65 dup (0)
sysinit_msg_base db 0
sysinitseg ends
end
