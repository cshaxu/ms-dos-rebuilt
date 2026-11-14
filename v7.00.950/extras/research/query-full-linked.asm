DOS7_CONFIG equ 1
CONFIG_REM equ 30h
CONFIG_OPTION_QUERY equ 80h
CONFIG_SET equ 'V'
Std_Con_Output equ 2
std_con_string_output equ 9
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f40h
BCodeSeg dw 1d5h
 org 1c14h
print_indexed proc near
	xchg	si,dx
	pop	si
	cld
	lods	word ptr cs:[si]
	push	si
	xchg	si,dx
	push	bx
	and	ax,7fffh
	mov	bx,ax
	shl	bx,1
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[bx+sysinit_msg_table]
	mov	ah,std_con_string_output
	int	21h
	pop	bx
	ret
print_indexed endp
 org 1e3bh
query_yes db 0
query_yes_lower db 0
query_no db 0
query_no_lower db 0
query_all_char db 0
query_all_lower db 0
 org 2c46h
disp_input  proc near
        push    ax
        cmp     al,' '
        jae     disp_ok
        mov     al,' '
disp_ok:
        mov     dl,al
        mov     ah,Std_Con_Output
        int     21h
IFDEF DOS7_CONFIG
        call    print_indexed
        dw      8005h
ELSE
        mov     dx,offset crlfm
        call    print
ENDIF
        pop     ax
        ret
disp_input  endp
 org 2d1eh
nearby_ret: ret
query_user  proc near
IFDEF DOS7_CONFIG
        mov     byte ptr [query_result],0
        test    byte ptr [query_mode_flags],1
        jz      query_check_skip
        test    byte ptr [bQueryOpt],1
        jnz     query_check_skip
        jmp     skip_all
query_check_skip:
        test    byte ptr [query_mode_flags],2
        jz      query_check_done
        jmp     skip_all
query_check_done:
        test    byte ptr [query_mode_flags],50h
        jnz     nearby_ret
        push    ax
        mov     al,[config_cmd]
        test    byte ptr [query_mode_flags],8
        jnz     query_prepare
        test    al,CONFIG_OPTION_QUERY
        jnz     query_prepare
        jmp     do_cmd
query_prepare:
        call    query_keyboard_service
ELSE
        test    byte ptr [bQueryOpt],4  ; answer no to everything?
        jz      @F                      ;
        jmp     skip_all                ;
@@:     test    byte ptr [bQueryOpt],2  ; answer yes to everything?
        jnz     nearby_ret              ; yes (and return carry clear!)
        push    ax                      ;
        mov     al,[config_cmd]         ;
        test    byte ptr [bQueryOpt],1  ; query every command?
        jnz     query_all               ; yes
        test    al,CONFIG_OPTION_QUERY  ;
        jnz     query_all               ;
        jmp     do_cmd                  ;
ENDIF
query_all:
;
;   Search for the command code (AL) in "comtab", and then print
;   out the corresponding keyword, followed by the rest of the actual
;   line pointed to by ES:SI
;
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
IFDEF DOS7_CONFIG
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
ELSE
input_loop:                             ;
        mov     ah,0                    ; read a key
        int     16h                     ;
        or      al,al                   ; is it a function key?
        jnz     not_func                ; no
        cmp     ah,3Fh                  ; F5 function key?
        jne     input_loop              ; no
        mov     al,$NO                  ;
        or      byte ptr [bQueryOpt],4  ; no more queries
        jmp     short legal_char        ;
not_func:
        and     al,not 20h              ; converting to upper case
        cmp     al,$NO                  ; verify character is legal
        je      legal_char              ;
        cmp     al,$YES                 ;
        je      legal_char              ;
        cmp     [config_cmd],0          ;
        je      input_loop              ; don't allow Esc on this query
        cmp     al,1Bh                  ; Esc?
        jne     input_loop              ;
        or      byte ptr [bQueryOpt],2  ; no more interactive boot prompts
        mov     al,$YES
legal_char:                             ;
        call    disp_input              ;
        pop     si                      ; restore pointer to rest of CONFIG.SYS line

        cmp     al,$NO                  ; process line?
        je      skip_cmd                ; no
do_cmd:
        pop     ax                      ;
        clc                             ; just do the command
        ret

skip_cmd:
        pop     ax                      ;
skip_all:
        mov     ah,CONFIG_REM           ; fake out the rest of sysinit's processing
        stc
        ret
ENDIF
query_user  endp
 org 321ch
print proc near
 mov ah,9
 int 21h
 ret
print endp
 org 3370h
boot_runtime_flags db 0
 org 3374h
bQueryOpt db 0
query_mode_flags db 0
query_display_flags db 0
 org 33afh
query_result db 0
 org 33c4h
comtab db 0
 org 5ad2h
config_cmd db 0
 org 928eh
query_bios_return dw 0
query_bios_call proc near
        pop     cs:query_bios_return
        push    cs
        push    cs:query_bios_return
        .286
        push    0c0h
        .8086
        push    cs:BCodeSeg
        push    bp
        retf
query_bios_call endp

query_keyboard_service proc near
        push    bp
        mov     bp,1e2h
        call    query_bios_call
        pop     bp
        ret
query_keyboard_service endp
 org 0a568h
 include sysimsg.inc
sysinitseg ends
end query_user
