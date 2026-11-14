CONFIG_REM equ 30h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1e3bh
query_yes db 0
query_yes_lower db 0
query_no db 0
query_no_lower db 0
query_all_char db 0
query_all_lower db 0
 org 2c46h
disp_input proc near
 ret
disp_input endp
 org 2dbah
query_user proc near
input_loop:
        mov     ax,0c08h                ; flush input and read a character
        int     21h
        test    al,al                   ; extended key?
        jnz     not_func
        test    byte ptr [boot_runtime_flags],8
        jnz     input_loop
        mov     ah,8
        int     21h
        mov     ah,1
        cmp     al,'?'
        je      set_query_mode
        cmp     al,'X'
        je      set_skip_mode
        cmp     al,'@'
        jne     input_loop
        or      ah,4
        jmp     short set_query_mode
set_skip_mode:
        or      ah,2
set_query_mode:
        or      [query_mode_flags],ah
answer_no:
        mov     al,[query_no]
        jmp     short legal_char
not_func:
        cmp     al,0dh
        je      answer_yes
        cmp     al,1bh
        je      answer_no
        cmp     al,[query_no]
        je      answer_no
        cmp     al,[query_yes]
        je      answer_yes
        cmp     al,[query_no_lower]
        je      answer_no
        cmp     al,[query_yes_lower]
        je      answer_yes
        cmp     al,9
        jne     check_all_char
        or      byte ptr [query_mode_flags],40h
        jmp     short answer_yes
check_all_char:
        test    byte ptr [config_cmd],7fh
        jz      input_loop
        cmp     al,[query_all_char]
        je      answer_all
        cmp     al,[query_all_lower]
        jne     input_loop
answer_all:
        or      byte ptr [query_mode_flags],10h
answer_yes:
        mov     byte ptr [query_result],1
        mov     al,[query_yes]
legal_char:
        test    byte ptr [query_display_flags],1
        jnz     query_no_echo
        call    disp_input
query_no_echo:
        and     byte ptr [query_display_flags],0feh
        pop     si
        cmp     al,[query_no]
        je      skip_cmd
        cmp     al,[query_no_lower]
        je      skip_cmd
do_cmd:
        pop     ax
        clc
        ret
skip_cmd:
        pop     ax
skip_all:
        mov     ah,CONFIG_REM
        stc
        ret
query_user endp
 org 3370h
boot_runtime_flags db 0
 org 3375h
query_mode_flags db 0
query_display_flags db 0
 org 33afh
query_result db 0
 org 5ad2h
config_cmd db 0
sysinitseg ends
end query_user
