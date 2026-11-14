DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 2733h
        push    es              ; then copy the configuration name
IFNDEF DOS7_CONFIG
        mov     cx,128-7        ; put an upper limit on the name, to be safe
ENDIF
        mov     si,cs:[offDefBlock]; ES:SI -> default block name
        or      si,si           ; valid?
        jnz     l1_check        ; yes
        push    cs              ;
        pop     es              ;
        mov     si,offset szCommon
IFDEF DOS7_CONFIG
        jmp     short l1
l1_check:
        mov     bx,offset boot_config_name
        cmp     byte ptr cs:[bx],0
        je      l1
        push    si
        mov     cx,32
boot_name_loop:
        mov     al,cs:[bx]
        test    al,al
        jz      boot_name_done
        call    boot_toupper
        mov     ah,al
        mov     al,es:[si]
        call    boot_toupper
        cmp     al,ah
        jne     boot_name_changed
        inc     bx
        inc     si
        loop    boot_name_loop
        jmp     short boot_name_done
boot_name_changed:
        or      byte ptr cs:[boot_runtime_flags],20h
boot_name_done:
        pop     si
ELSE
l1_check:
ENDIF
l1:
IFDEF DOS7_CONFIG
        mov     cx,128-7
ENDIF
        mov     al,es:[si]      ;
 org 3370h
boot_runtime_flags db 0
 org 3379h
offDefBlock dw 0
 org 33bdh
szCommon db 'COMMON',0
 org 4068h
boot_config_name db 32 dup(0)
 org 5abfh
boot_toupper proc near
        cmp     al,'a'
        jb      boot_upper_done
        cmp     al,'z'
        ja      boot_upper_done
        sub     al,20h
boot_upper_done:
        ret
boot_toupper endp
sysinitseg ends
end
