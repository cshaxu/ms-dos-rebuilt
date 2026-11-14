DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1e3bh
query_yes db 0,0
query_no db 0
 org 2c6ah
show_status proc near
        push    bx              ; BL = video page #
        mov     bx,word ptr [bMenuColor]
        mov     ah,03h          ; get cursor position
        int     10h             ;
        push    dx              ; save it
        mov     ah,02h          ; set cursor position
        mov     dx,word ptr [bLastCol]   ; set correct row/col
IFDEF DOS7_CONFIG
        test    byte ptr [boot_runtime_flags],8
ELSE
        test    byte ptr [bDisableUI],1
ENDIF
        jz      show_onoff      ; just show on/off
        mov     dl,0            ;
        int     10h             ;
        mov     ax,0A20h        ; write multiple spaces
        mov     cx,80           ; 80 of them, to be exact
        int     10h             ; to obliterate the status line
        jmp     short show_done ;
show_onoff:                     ;
        int     10h             ;
IFDEF DOS7_CONFIG
        mov     al,[query_no]
        test    byte ptr [query_mode_flags],8
        jz      show_noton
        mov     al,[query_yes]
ELSE
        mov     al,$NO          ; assume OFF
        cmp     byte ptr [bQueryOpt],1  ; is interactive mode on?
        jne     show_noton      ; no
        mov     al,$YES         ; yes
ENDIF
show_noton:                     ;
        mov     ah,0Eh          ; write TTY
        int     10h             ;
show_done:                      ;
        pop     dx              ;
        mov     ah,02h          ;
        int     10h             ; restore original cursor position
        pop     bx              ;
        ret                     ;
show_status endp
 org 3369h
bMenuColor db 7,0,5
bLastCol db 0
bLastRow db 24
bDisableUI db 0
boot_config_flags db 1
boot_runtime_flags db 80h
 org 3375h
query_mode_flags db 0
sysinitseg ends
end
