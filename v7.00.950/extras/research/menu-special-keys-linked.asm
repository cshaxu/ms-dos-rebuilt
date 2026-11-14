DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 2b3ch
input_key: ret
 org 2bb7h
to_input_key: jmp short input_key
not_down:
IFDEF DOS7_CONFIG
        test    byte ptr [boot_runtime_flags],8
        jnz     to_input_key
        mov     ah,1
        test    byte ptr [boot_runtime_flags],80h
        jnz     short menu_key_62
        cmp     al,3eh
        jne     short menu_key_62
        or      byte ptr [boot_config_flags],10h
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_62:
        cmp     al,62h
        jne     short menu_key_5b
        or      byte ptr [compression_skip],1
        jmp     short menu_key_skip
menu_key_5b:
        cmp     al,5bh
        jne     short menu_key_3f
        xor     byte ptr [query_mode_flags],8
        call    show_status
        jmp     input_key
menu_key_3f:
        cmp     al,3fh
        jne     short menu_key_58
menu_key_set:
        or      [query_mode_flags],ah
menu_key_clean:
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_58:
        cmp     al,58h
        jne     short menu_key_6c
menu_key_skip:
        or      ah,2
        jmp     short menu_key_set
menu_key_6c:
        cmp     al,6ch
        jne     short menu_key_40
        or      byte ptr [boot_runtime_flags],21h
        jmp     short menu_key_clean
menu_key_40:
        cmp     al,40h
        jne     to_input_key
        or      ah,4
        jmp     short menu_key_set
ELSE
        test    byte ptr [bDisableUI],1
        jnz     to_input_key    ; don't allow F8 or F5
        cmp     al,42h          ; F8 function key?
        jne     not_f8          ; no
        xor     byte ptr [bQueryOpt],1
        call    show_status     ;
        jmp     input_key       ;
not_f8:
        cmp     al,3Fh          ; F5 function key?
        jne     to_input_key    ; no
        or      byte ptr [bQueryOpt],4
        mov     bx,-1           ; special return code (-1) indicating clean boot
        mov     al,' '          ; don't want to display anything really;
        jmp     short disp_input; just want to display the cr/lf sequence...
ENDIF

normal_key: ret
 org 2c46h
disp_input proc near
 ret
disp_input endp
 org 2c6ah
show_status proc near
 ret
show_status endp
 org 336fh
boot_config_flags db 1
boot_runtime_flags db 80h
 org 3375h
query_mode_flags db 0
 org 8aa5h
compression_skip db 0
sysinitseg ends
end
