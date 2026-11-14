DOS7_CONFIG equ 1
CRT_Cols equ 4ah
CRT_Rows equ 84h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1c14h
print_indexed proc near
 ret
print_indexed endp
 org 297bh
IFDEF DOS7_CONFIG
; Display the menu and return the selected block in BX.
display_menu proc near
        mov     ah,0fh
        int     10h
        mov     ah,0
        int     10h
        push    es
        mov     ax,40h
        mov     es,ax
        mov     ax,es:[4eh]
        mov     [wCRTStart],ax
        mov     al,es:[62h]
        mov     [bCRTPage7],al
        mov     ax,word ptr [bMenuPage]
        int     10h
        mov     ax,0600h
        mov     bh,[bMenuColor]
        sub     cx,cx
        mov     dl,byte ptr es:[CRT_Cols]
        dec     dl
        mov     dh,byte ptr es:[CRT_Rows]
        or      dh,dh
        jnz     short display_menu_clear
        mov     dh,[bLastRow]
display_menu_clear:
        int     10h
        pop     es
        mov     [bLastRow],dh
        call    print_indexed
        dw      8013h
        test    byte ptr [boot_runtime_flags],8
        jnz     short display_menu_items
        mov     bh,[bMenuPage]
        mov     dh,[bLastRow]
        mov     dl,0
        mov     ah,2
        int     10h
        call    print_indexed
        dw      8015h
        mov     ah,3
        int     10h
        sub     dl,2
        mov     [bLastCol],dl
display_menu_items:
        mov     bx,1
display_menu_loop:
        call    print_item
        inc     bx
        cmp     bl,[bMaxBlock]
        jbe     display_menu_loop
        mov     dl,0
        mov     dh,bl
        add     dh,6
        mov     bh,[bMenuPage]
        mov     ah,2
        int     10h
        test    di,di
        jz      short display_menu_prompt
        mov     dx,di
        call    print
display_menu_prompt:
        mov     dl,0
        mov     dh,bl
        add     dh,4
        mov     bh,[bMenuPage]
        mov     ah,2
        int     10h
        call    print_indexed
        dw      8014h
        call    select_item
        mov     cx,1
        test    di,di
        jz      short display_menu_crlf
        mov     cx,4
display_menu_crlf:
        call    print_indexed
        dw      8005h
        loop    display_menu_crlf
        push    word ptr [boot_runtime_flags]
        or      byte ptr [boot_runtime_flags],8
        call    show_status
        pop     word ptr [boot_runtime_flags]
        ret
display_menu endp
ENDIF

 org 2a48h
print_item proc near
 ret
print_item endp
 org 2ad8h
select_item proc near
 ret
select_item endp
 org 2c6ah
show_status proc near
 ret
show_status endp
 org 321ch
print proc near
 ret
print endp
 org 3369h
bMenuColor db 7
bMenuPage db 0
 db 5
bLastCol db 0
bLastRow db 24
bCRTPage7 label byte
bDisableUI db 0
boot_config_flags db 1
boot_runtime_flags db 80h
bCRTPage db 0
wCRTStart dw 0
 org 3378h
bMaxBlock db 0
sysinitseg ends
end
