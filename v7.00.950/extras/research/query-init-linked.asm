DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 1260h
IFDEF DOS7_CONFIG
; Initialize the localized responses used by SYSINIT and DOS.
        mov     ah,52h
        int     21h
        les     bx,es:[bx+12h]
        mov     bx,es:[bx+13h]
        push    bx
        mov     bx,es:[bx+6]
        mov     si,offset sysinit_msg_base
        add     si,cs:[sysinit_msg_table+46]
        mov     al,cs:[si]
        mov     cs:[query_yes],al
        mov     es:[bx],al
        mov     al,cs:[si+3]
        mov     cs:[query_yes_lower],al
        mov     es:[bx+2],al
        mov     al,cs:[si+1]
        mov     cs:[query_no],al
        mov     es:[bx+1],al
        mov     al,cs:[si+4]
        mov     cs:[query_no_lower],al
        mov     es:[bx+3],al
        mov     al,cs:[si+2]
        mov     cs:[query_all_char],al
        mov     al,cs:[si+5]
        mov     cs:[query_all_lower],al
        pop     bx
ENDIF
 org 1e3bh
query_yes db 0
query_yes_lower db 0
query_no db 0
query_no_lower db 0
query_all_char db 0
query_all_lower db 0
 org 0a568h
 include sysimsg.inc
sysinitseg ends
end
