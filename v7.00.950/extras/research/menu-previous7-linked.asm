DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 25f8h
menu_valid:
        sub     bx,bx           ;
        mov     [bMaxBlock],dl  ; first, record how many blocks we found
IFDEF DOS7_CONFIG
        xchg    bl,[menu_previous_allowed]
        or      bl,bl
        jz      menu_no_previous
        mov     ax,[config_buffer_segment]
        or      ax,ax
        jz      menu_no_previous
menu_previous_loop:
        push    bx
        add     bx,bx
        mov     si,aoffBlockDesc[bx]
        mov     cx,128
        push    ds
        mov     ds,[config_buffer_segment]
        assume  ds:nothing
        mov     di,1ch
menu_previous_cmp:
        call    get_char
        jc      menu_previous_done
        cmp     al,'$'
        je      menu_previous_char
        cmp     al,1fh
        ja      menu_previous_char
        sub     al,al
menu_previous_char:
        mov     ah,[di]
        je      menu_previous_end
        inc     di
        and     ax,0dfdfh
        cmp     al,ah
        je      menu_previous_cmp
        mov     ah,1
menu_previous_end:
        or      ah,ah
menu_previous_done:
        pop     ds
        assume  ds:sysinitseg
        pop     bx
        je      menu_previous_found
        inc     bx
        cmp     bl,[bMaxBlock]
        jbe     menu_previous_loop
menu_no_previous:
        sub     bx,bx
        jmp     short menu_finddefault
menu_previous_found:
        test    byte ptr [query_mode_flags],8
        jnz     menu_setdefault
        jmp     short menu_autoselect
menu_finddefault:
ENDIF
        mov     di,[offDefBlock];
        or      di,di           ; does a default block exist?
        jz      menu_nodefault  ; no
        inc     bx              ; yes, walk name table, looking for default
menu_chkdefault:
        push    bx              ;
        add     bx,bx           ;
        mov     si,aoffBlockName[bx]
        mov     cx,128          ; arbitrary maximum length of a name
        push    ds              ;
        push    es              ;
        pop     ds              ;
        call    comp_names      ; is this block the same as the default?
        pop     ds              ;
        pop     bx              ;
        je      menu_setdefault ; yes
        inc     bx              ;
        cmp     bl,[bMaxBlock]  ; all done searching?
        jbe     menu_chkdefault ; not yet
menu_nodefault:
        mov     bl,1            ; if no default, force default to #1
menu_setdefault:
        mov     [bDefBlock],bl  ; yes, this will be the initial current block
;
;   If the timeout was explicitly set to 0 (or technically, anything that
;   failed to resolve to a number, like "NONE" or "EAT POTATOES"), then we're
;   supposed to skip menu display and run with the specified default block;
;   however, if the user hit Enter prior to boot, thereby requesting fully
;   INTERACTIVE boot, then we shall display the menu block anyway (though still
;   with no timeout)
;
        cmp     [secTimeOut],0  ; is timeout zero? (ie, assume default)
        jne     menu_display    ; no
IFDEF DOS7_CONFIG
        test    byte ptr [query_mode_flags],8
ELSE
        test    byte ptr [bQueryOpt],1  ; yes, but was INTERACTIVE requested?
ENDIF
        jnz     menu_display    ; yes, so *don't* assume default after all
IFDEF DOS7_CONFIG
        jmp     short not_topmenu
ELSE
        jmp     not_topmenu     ;
ENDIF
;
;   Reset the mode, so that we know screen is clean and cursor is home
;
menu_display:
 ret
 org 2699h
menu_autoselect:
 ret
 org 26b1h
not_topmenu:
 ret
 org 294ch
comp_names proc near
 ret
comp_names endp
 org 2d11h
get_char proc near
 ret
get_char endp
 org 3327h
menu_previous_allowed db 0
 org 3375h
query_mode_flags db 0
 org 3377h
bDefBlock db 0
bMaxBlock db 0
offDefBlock dw 0
secTimeOut db 0
 org 3387h
aoffBlockName dw 10 dup(0)
aoffBlockDesc dw 10 dup(0)
 org 0a0a0h
config_buffer_segment dw 0
sysinitseg ends
end
