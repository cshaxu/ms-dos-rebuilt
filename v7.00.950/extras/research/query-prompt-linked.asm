CONFIG_OPTION_QUERY equ 80h
CONFIG_SET equ 'V'
Std_Con_Output equ 2
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 2d5bh
query_prompt proc near
        push    si                      ; save pointer to rest of CONFIG.SYS line
IFDEF DOS7_CONFIG
; The caller supplies the generic prompt in DS:DX.
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,1
        jbe     generic_prompt
ELSE
        mov     dx,offset $AutoPrmpt    ;
        and     al,NOT CONFIG_OPTION_QUERY
        jz      generic_prompt          ; config_cmd must have been 0
ENDIF

        mov     dh,al                   ; save config_cmd in DH
        sub     bx,bx                   ;
        mov     di,offset comtab        ;
find_match:                             ;
        mov     bl,[di]                 ; get size of current keyword
        or      bl,bl                   ;
        jz      line_print              ; end of table
        inc     di                      ;
        cmp     al,[di+bx]              ; match?
        je      cmd_match               ; yes
        lea     di,[di+bx+1]            ; otherwise, skip this command code
        jmp     find_match              ; loop
cmd_match:                              ;
        mov     cl,[di-1]               ;
        mov     ch,0                    ;
        mov     ah,Std_Con_Output
cmd_print:                              ;
        mov     al,[di]                 ;
        inc     di                      ;
        mov     dl,al                   ;
        int     21h                     ;
        loop    cmd_print               ;
        mov     dl,'='                  ;
        cmp     dh,CONFIG_SET           ; for SET commands, don't display a '='
        jne     cmd_notset              ;
        mov     dl,' '                  ;
cmd_notset:
        int     21h                     ; '=' looks funny on SET commands
line_print:                             ;
        lods    byte ptr es:[si]        ;
        or      al,al                   ;
        jnz     non_null                ;
        mov     al,' '                  ;
non_null:                               ;
        cmp     al,' '                  ; control code?
        jb      prompt_user             ; yes, assume end of line
        jne     non_space               ;
        cmp     byte ptr es:[si],' '    ;
        jb      prompt_user             ;
non_space:                              ;
        mov     dl,al                   ;
        mov     ah,Std_Con_Output       ;
        int     21h                     ;
        jmp     line_print              ;
prompt_user:                            ;
IFDEF DOS7_CONFIG
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_prompt_index]
ELSE
        mov     dx,offset $InterPrmpt   ;
ENDIF

generic_prompt:
        call    print                   ;
 ret
query_prompt endp
 org 321ch
print proc near
 mov ah,9
 int 21h
 ret
print endp
 org 33c4h
comtab db 0
 org 0a568h
 include sysimsg.inc
sysinitseg ends
 end query_prompt
