DOS7_CONFIG equ 1
CR equ 13
LF equ 10
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 27ddh
copy_envvar proc near
        push    cx              ;
        push    si              ;
        push    ds              ;
        push    es              ;
        push    es              ;
        mov     es,[config_wrkseg]; ES:DI to point to next available byte
        pop     ds                ; DS:SI to point to envvar
        assume  ds:nothing      ;
;
;   Have to calculate the length of the variable name (and if we hit
;   the end of the line before we hit '=', then it's curtains for this
;   config.sys line)
;
;   The check for NULL is important because copy_envvar is also used to copy
;   the initial CONFIG= setting, which will have been zapped by a NULL if no
;   menu block existed (in order to prevent the creation of an environment)
;
        sub     cx,cx           ;
copy_varlen:                    ;
        lodsb                   ;
        or      al,al           ; NULL?
        stc                     ;
IFDEF DOS7_CONFIG
        jnz     copy_notnull
        jmp     near ptr copy_envexit
copy_notnull:
ELSE
        jz      copy_envexit    ; yes, abort
ENDIF
        cmp     al,CR           ;
        stc                     ;
        je      copy_envexit    ;
        cmp     al,LF           ;
        stc                     ;
        je      copy_envexit    ;
        inc     cx              ;
        cmp     al,'='          ;
        jne     copy_varlen     ;
        mov     al,0            ;
        mov     ah,[si]         ; save char after '='
        sub     si,cx           ; back up to given varname
        dec     cx              ; CX == # of bytes in varname
        sub     di,di           ; start looking for DS:SI at ES:0
copy_varsrch:
        cmp     byte ptr es:[di],al
        je      copy_envprep    ; search failed, just copy var
        mov     bx,di           ; ES:BX -> start of this varname
        push    cx              ;
        push    si              ;
        repe    cmpsb           ;
        pop     si              ;
        pop     cx              ;
        jne     copy_varnext    ; no match, skip to next varname
        cmp     byte ptr es:[di],'='
        jne     copy_varnext    ; no match, there's more characters
IFDEF DOS7_CONFIG
        test    dx,dx           ; zero requests the value without changing it
        jnz     copy_vardestroy
        lea     dx,[di+1]
        jmp     short copy_envexit
copy_vardestroy:
ENDIF
;
;   Previous occurrence of variable has been found;  determine the
;   entire length and then destroy it
;
        mov     cx,-1           ;
        repne   scasb           ; guaranteed to get null (since we put it there)
        push    si              ;
        mov     si,di           ;
        mov     di,bx           ;
        mov     cx,cs:[config_envlen]
        sub     cx,si           ; destroy variable now
IFDEF DOS7_CONFIG
        rep     movs byte ptr es:[di],byte ptr es:[si]
ELSE
        rep movs byte ptr es:[di],byte ptr es:[si]
ENDIF
        pop     si              ;
copy_envprep:
IFDEF DOS7_CONFIG
        test    dx,dx
        jz      copy_envexit
        test    ah,ah
        jz      copy_envdel
ENDIF
        cmp     ah,CR           ; if there is nothing after the '='
        je      copy_envdel     ; then just exit with variable deleted
        cmp     ah,LF           ;
        je      copy_envdel     ;
        jmp     short copy_envloop

copy_varnext:                   ;
        push    cx              ;
        mov     cx,-1           ;
        repne   scasb           ;
        pop     cx              ;
        jmp     short copy_varsrch    ;

copy_envloop:                   ;
        lodsb                   ;
IFDEF DOS7_CONFIG
        test    al,al
        jz      copy_envdone
ENDIF
        cmp     al,CR           ;
        je      copy_envdone    ;
        cmp     al,LF           ;
        je      copy_envdone    ;
        stosb                   ;
        jmp     copy_envloop    ;

copy_envdone:                   ;
        sub     al,al           ; do SUB to clear carry as well
        stosb                   ; always null-terminate these puppies
copy_envdel:                    ;
        mov     es:[di],al      ; and stick another null to terminate the env.
        mov     cs:[config_envlen],di

copy_envexit:                   ;
        pop     es              ;
        pop     ds              ;
        assume  ds:sysinitseg   ;
        pop     si              ;
        pop     cx              ;
        ret                     ;
copy_envvar endp
 org 5aceh
config_envlen dw 0
config_wrkseg dw 0
sysinitseg ends
end
