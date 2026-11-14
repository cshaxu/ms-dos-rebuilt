Bios_Data segment at 70h
 org 8
bios_flags dw ?
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
CONFIG_BEGIN equ '['
CONFIG_NUMLOCK equ 'N'
CONFIG_SWITCHES equ '1'
CONFIG_REM equ '0'
LF equ 10
 org 0f3eh
bios_data_segment dw 0
 org 242bh
set_numlock proc near
 ret
set_numlock endp
 org 2452h
menu_check proc near
        mov     byte ptr [shell_opt_flags],0
        push    cx
        push    si
        sub     bx,bx
swchk7_loop:
        call    get_char
        jc      swchk7_end
        cmp     al,CONFIG_BEGIN
        jne     swchk7_next1
        inc     bx
        push    ds
        mov     ds,[bios_data_segment]
        assume  ds:Bios_Data
        test    byte ptr [bios_flags+1],20h
        pop     ds
        assume  ds:sysinitseg
        jnz     swchk7_nextline
        mov     word ptr [boot_delay],0
        jmp     short swchk7_nextline
swchk7_next1:
        cmp     al,CONFIG_NUMLOCK
        jne     swchk7_next2
        or      bx,bx
        jnz     swchk7_nextline
        call    set_numlock
        mov     byte ptr es:[si-1],CONFIG_REM
        jmp     short swchk7_nextline
swchk7_next2:
        cmp     al,CONFIG_SWITCHES
        jne     swchk7_nextline
swchk7_scan:
        call    get_char
swchk7_scan1:
        cmp     al,LF
        je      swchk7_nextline
        cmp     al,'/'
        jne     swchk7_scan
        call    get_char
        and     al,not 20h
        cmp     al,byte ptr swit_n+1
        jne     swchk7_scan2
        or      byte ptr [boot_runtime_flags],8
        jmp     swchk7_scan
swchk7_scan2:
        cmp     al,byte ptr swit_f+1
        jne     swchk7_scan1
        mov     word ptr [boot_delay],0
        jmp     swchk7_scan
swchk7_nextline:
        call    skip_opt_line
        jmp     swchk7_loop
swchk7_end:
        pop     si
        pop     cx
        test    byte ptr [boot_runtime_flags],8
        jz      swchk7_query
        and     byte ptr [query_mode_flags],0f6h
swchk7_query:
        test    byte ptr [query_mode_flags],1
        jz      menu_search
        jmp     menu_abort
menu_search:
 ret
menu_check endp
 org 269eh
menu_abort proc near
 ret
menu_abort endp
 org 2ccfh
skip_opt_line proc near
 ret
skip_opt_line endp
 org 2d11h
get_char proc near
 ret
get_char endp
 org 3368h
shell_opt_flags db 0
 org 3370h
boot_runtime_flags db 0
 org 3375h
query_mode_flags db 0
 org 4060h
boot_delay dw 2
 org 6614h
swit_n db '/N',0
 org 6620h
swit_f db '/F',0
sysinitseg ends
end
