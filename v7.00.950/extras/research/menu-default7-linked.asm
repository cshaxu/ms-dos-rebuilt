DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 2527h
menu_found:
        mov     byte ptr [bDefBlock],1
        mov     word ptr [offDefBlock],0
        mov     byte ptr [secTimeOut],-1
IFDEF DOS7_CONFIG
        test    byte ptr [query_mode_flags],10h
        jz      menu_query_ready
        and     byte ptr [query_mode_flags],0e7h
menu_query_ready:
ELSE
        and     byte ptr [bQueryOpt],not 2
ENDIF

 org 257dh
menu_default:
        mov     [offDefBlock],si; save address of default block name
        cmp     byte ptr [secElapsed],0
        jne     timeout_skip    ; secElapsed is only zero for the FIRST menu,
        call    skip_token      ; and for subsequent menus IF nothing was typed;
        jc      menu_nextitem   ; secElapsed becomes -1 forever as soon as
        call    skip_delim      ; something is typed
        jc      menu_nextitem   ;
        mov     si,bx           ;
        call    get_number      ; get number (of seconds for timeout)
IFDEF DOS7_CONFIG
        test    bx,bx           ; negative timeout disables previous selection
        jns     timeout_limit
        mov     byte ptr [menu_previous_allowed],0
        cmp     bx,-1           ; -1 means no timeout
        je      timeout_ok
        neg     bx
timeout_limit:
        cmp     bx,90
ELSE
        cmp     bl,90           ; limit it to a reasonable number
ENDIF
        jb      timeout_ok      ; (besides, 99 is the largest # my simple
        mov     bl,90           ;  display function can handle)
timeout_ok:                     ;
        mov     [secTimeOut],bl ;
timeout_skip:
        jmp     short menu_nextitem
 org 25e9h
menu_nextitem:
 ret
 org 2ca9h
skip_token proc near
 ret
skip_token endp
 org 2cc0h
skip_delim proc near
 ret
skip_delim endp
 org 2cddh
get_number proc near
 ret
get_number endp
 org 3327h
menu_previous_allowed db 0
 org 3375h
query_mode_flags db 0
 org 3377h
bDefBlock db 0
 org 3379h
offDefBlock dw 0
secTimeOut db 0
secElapsed db 0
sysinitseg ends
end
