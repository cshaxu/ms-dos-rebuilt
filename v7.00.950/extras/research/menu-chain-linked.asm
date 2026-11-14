DOS7_CONFIG equ 1
CRT_Cols equ 4ah
CRT_Rows equ 84h
tab equ 9
Raw_Con_IO equ 6
Get_Time equ 2ch
Std_Con_Output equ 2
std_con_string_output equ 9
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
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
query_yes db 0,0
query_no db 0
 org 297bh
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
 org 2a48h
print_item  proc near           ; prints menu item #BL (1 to N)
IFDEF DOS7_CONFIG
        .286
        pusha
        .8086
ELSE
        push    ax              ;
        push    bx              ;
        push    cx              ;
        push    dx              ;
        push    si              ;
ENDIF
        mov     ah,03h          ; get cursor position
        mov     bh,[bMenuPage]  ; always page zero
        int     10h             ; DH/DL = row/column
        push    dx              ; save it
        mov     ah,02h          ; set cursor position
        mov     dh,bl           ;
        add     dh,3            ;
        mov     dl,5            ;
        int     10h             ; set cursor position for correct row/col
        mov     al,bl           ;
        add     al,'0'          ; convert menu item # to ASCII digit
        mov     ah,[bMenuColor] ; normal attribute
        cmp     bl,[bDefBlock]  ; are we printing the current block?
        jne     print_other     ; no
        or      ah,70h          ; yes, set bgnd color to white
        mov     ch,ah           ;
        mov     cl,4            ;
        rol     ch,cl           ;
        cmp     ch,ah           ; are fgnd/bgnd the same?
        jne     print_other     ; no
        xor     ah,08h          ; yes, so modify the fgnd intensity
print_other:                    ;
        mov     bh,0            ;
        add     bx,bx           ;
        mov     di,aoffBlockDesc[bx]
        mov     bl,ah           ; put the attribute in the correct register now
        mov     bh,[bMenuPage]  ; get correct video page #
        mov     ah,09h          ; write char/attr
        mov     cx,1            ;
        int     10h             ;
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        mov     ax,0900h+'.'    ;
        int     10h             ; display '.'
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        mov     ax,0900h+' '    ;
        int     10h             ; display ' '
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        push    es              ;
print_loop:                     ;
        mov     al,es:[di]      ; get a character of the description
        inc     di              ;
        cmp     al,TAB          ; substitute spaces for tabs
        jne     print_nontab    ;
        mov     al,' '          ;
print_nontab:                   ;
        cmp     al,' '          ;
        jb      print_done      ; stop at the 1st character < space
        cmp     al,'$'          ;
        je      print_done      ; also stop on $
        mov     ah,09h          ; display function #
        int     10h             ;
        inc     dl              ; increment column
        cmp     dl,78           ; far enough?
        jae     print_done      ; yes
        mov     ah,02h          ;
        int     10h             ;
        jmp     print_loop      ;
print_done:                     ;
        pop     es              ;
        pop     dx              ;
        mov     ah,02h          ;
        int     10h             ; restore previous row/col
IFDEF DOS7_CONFIG
        .286
        popa
        .8086
ELSE
        pop     si              ;
        pop     dx              ;
        pop     cx              ;
        pop     bx              ;
        pop     ax              ;
ENDIF
        ret                     ;
print_item  endp
 org 2ad8h
select_item proc near           ; returns digit value in BX (trashes AX/CX/DX)
        mov     bl,[bDefBlock]  ; BL will be the default block #
        mov     al,bl           ;
        call    disp_num        ;
        call    show_status     ; display current interactive status
        cmp     byte ptr [secTimeOut],-1
        je      input_key       ; no time-out, just go to input
        mov     ah,Get_Time     ;
        int     21h             ;
        mov     bh,dh           ; BH = initial # of seconds
check_time:
        mov     al,[secTimeOut] ;
        sub     al,[secElapsed] ;
        jae     show_time       ;
IFDEF DOS7_CONFIG
        or      byte ptr [query_mode_flags],10h ; accept remaining commands
ELSE
        or      byte ptr [bQueryOpt],2  ; disable all further prompting
ENDIF
        mov     byte ptr [secElapsed],0
        jmp     select_done     ; time's up!
show_time:
        push    bx              ;
        mov     bl,al           ; save # in BL
        mov     bh,[bMenuPage]  ;
        mov     ah,03h          ; get cursor position
        int     10h             ;
        push    dx              ;
	add	dl,8		; move cursor to the right
        mov     ah,02h          ; set cursor position
        int     10h             ;
IFDEF DOS7_CONFIG
        call    print_indexed
        dw      8018h
ELSE
        mov     dx,offset $TimeOut
        call    print           ; print the "Time remaining: " prompt
ENDIF
        mov     al,bl           ; recover # from BL
        cbw                     ; this works because AL is always <= 90
        mov     cl,10           ;
        div     cl              ; AL = tens digit, AH = ones digit
        mov     cl,ah           ;
        add     al,'0'          ;
        mov     ah,0Eh          ;
        int     10h             ; write TTY tens digit
        mov     al,cl           ;
        add     al,'0'          ;
        mov     ah,0Eh          ;
        int     10h             ; write TTY ones digit
        pop     dx
        mov     ah,02h          ; set cursor position back to where it was
        int     10h             ;
        pop     bx              ;
input_key:
        mov     ah,Raw_Con_IO   ;
        mov     dl,0FFh         ; input request
        int     21h             ;
        jnz     got_key         ;
        cmp     byte ptr [secTimeOut],-1; is there a time-out?
        je      input_key       ; no, just go back to input
        mov     ah,Get_Time     ;
        int     21h             ; DH = seconds
        mov     ah,dh           ;
        sub     dh,bh           ; should generally be zero or one
        mov     bh,ah           ;
        jnc     got_time        ;
        mov     dh,1            ; it wrapped back to zero, so assume one
got_time:
        or      dh,dh           ; any change?
        jz      input_key       ; no
        add     [secElapsed],dh ;
        jmp     check_time      ;
got_key:
        push    ax              ;
        mov     ax,-1           ; zap both secTimeOut and secElapsed
        xchg    word ptr [secTimeOut],ax
        cmp     al,-1           ; was time-out already disabled?
        je      timeout_disabled; yes
        push    bx              ; let's disable # seconds display
        mov     ax,0A20h        ; write multiple spaces
        mov     bx,word ptr [bMenuColor]
        mov     cx,80           ; 80 of them, to be safe
        int     10h             ; to completely obliterate # seconds display
        pop     bx              ;
timeout_disabled:
        pop     ax              ;
        or      al,al           ; extended key pressed?
IFDEF DOS7_CONFIG
        jz      short extended_key
        jmp     normal_key
extended_key:
ELSE
        jnz     normal_key      ; no
ENDIF
        int     21h             ; get the next part of the key then
        jz      input_key       ; hmmm, what happened to the second part?

        cmp     al,48h          ; up arrow?
        jne     not_up          ; no
        cmp     bl,1            ; are we as up as up can get?
        jbe     input_key       ; yes, ignore it
        dec     [bDefBlock]     ;
        call    print_item      ; re-print the current item
        dec     bl              ; and then print the new current item
        jmp     short print1
not_up:
        cmp     al,50h          ; down arrow?
        jne     not_down        ; no
        cmp     bl,[bMaxBlock]  ; are we as down as down can get?
        jae     to_input_key    ; yes, ignore it
        inc     [bDefBlock]     ;
        call    print_item      ; re-print the current item
        inc     bx              ; and then print the new current item
print1: mov     al,bl           ;
print2: call    print_item      ;
        call    disp_num        ;
to_input_key:
        jmp     input_key       ;
not_down:
IFDEF DOS7_CONFIG
        test    byte ptr [boot_runtime_flags],8
        jnz     to_input_key
        mov     ah,1
        test    byte ptr [boot_runtime_flags],80h
        jnz     short menu_key_62
        cmp     al,3eh
        jne     short menu_key_62
        or      byte ptr [boot_config_flags],10h
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_62:
        cmp     al,62h
        jne     short menu_key_5b
        or      byte ptr [compression_skip],1
        jmp     short menu_key_skip
menu_key_5b:
        cmp     al,5bh
        jne     short menu_key_3f
        xor     byte ptr [query_mode_flags],8
        call    show_status
        jmp     input_key
menu_key_3f:
        cmp     al,3fh
        jne     short menu_key_58
menu_key_set:
        or      [query_mode_flags],ah
menu_key_clean:
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_58:
        cmp     al,58h
        jne     short menu_key_6c
menu_key_skip:
        or      ah,2
        jmp     short menu_key_set
menu_key_6c:
        cmp     al,6ch
        jne     short menu_key_40
        or      byte ptr [boot_runtime_flags],21h
        jmp     short menu_key_clean
menu_key_40:
        cmp     al,40h
        jne     to_input_key
        or      ah,4
        jmp     short menu_key_set
ELSE
        test    byte ptr [bDisableUI],1
        jnz     to_input_key    ; don't allow F8 or F5
        cmp     al,42h          ; F8 function key?
        jne     not_f8          ; no
        xor     byte ptr [bQueryOpt],1
        call    show_status     ;
        jmp     input_key       ;
not_f8:
        cmp     al,3Fh          ; F5 function key?
        jne     to_input_key    ; no
        or      byte ptr [bQueryOpt],4
        mov     bx,-1           ; special return code (-1) indicating clean boot
        mov     al,' '          ; don't want to display anything really;
        jmp     short disp_input; just want to display the cr/lf sequence...
ENDIF

normal_key:
        cmp     al,0Dh          ; Enter?
        je      select_done     ; yes
        cmp     al,08h          ; backspace?
        jne     not_backspace   ; no
        mov     bx,-2           ; yes, special return code
        ret                     ;
not_backspace:
        sub     al,'0'          ; is greater than '0'?
        jbe     to_input_key    ; no
        cmp     al,[bMaxBlock]  ; is less than or equal to the maximum digit?
        ja      to_input_key    ; no
        mov     [bDefBlock],al  ;
        call    print_item      ; redisplay the current selection
        mov     bl,al           ; set new selection
        jmp     print2

select_done:
        mov     bh,0            ; return a full 16-bit value (for indexing)
        mov     al,bl           ;
        add     al,'0'          ; convert it into a digit, then display it
        if2
        .errnz  disp_input-$    ; fall into disp_input
        endif
select_item endp

;
;----------------------------------------------------------------------------
;
;   disp_input:  display a single character + cr/lf
;
;   INPUT
;       AL == character to display
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       None
;
;   NOTES
;       This function is used not only for the menu input selection but
;       also for the interactive line prompting (the y/n/a thing).
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  disp_input

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

disp_num    proc near
        push    bx
        add     al,'0'
        mov     ah,0Ah
        mov     bx,word ptr [bMenuColor]
        mov     cx,1
        int     10h
        pop     bx
        ret
disp_num    endp

;
;----------------------------------------------------------------------------
;
;   show_status:  display current interactive mode setting (on/off/none)
;
;   INPUT
;       None
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       None
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  show_status

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
 org 321ch
print proc near
 mov ah,9
 int 21h
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
bQueryOpt db 0
query_mode_flags db 0
 db 0
bDefBlock db 1
bMaxBlock db 0
 dw 0
secTimeOut db 0
secElapsed db 0
 org 339bh
aoffBlockDesc dw 10 dup (0)
 org 8aa5h
compression_skip db 0
 org 0a568h
 include sysimsg.inc
sysinitseg ends
end
