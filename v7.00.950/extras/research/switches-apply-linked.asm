Bios_Data segment at 70h
 org 8
bios_flags dw 0
 org 69h
keyrd_func db 0
 org 0b2h
keysts_func db 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 663bh
p_swit_k db 0
p_swit_t db 0
p_swit_w db 0
p_swit_c db 0
 org 74dbh
apply_switches:
        cmp     byte ptr cs:[p_swit_k],1
        push    ds
        mov     ax,Bios_Data
        mov     ds,ax
        assume  ds:Bios_Data
        jne     short apply_switch_t
        mov     keyrd_func,0
        mov     keysts_func,1
apply_switch_t:
        mov     al,cs:[p_swit_t]
        or      byte ptr [bios_flags],al
        push    es
        push    bx
        mov     ah,52h
        int     21h
        cmp     byte ptr cs:[p_swit_w],0
        je      short apply_switch_c
        or      byte ptr es:[bx+60h],2
apply_switch_c:
        cmp     byte ptr cs:[p_swit_c],0
        je      short apply_switch_done
        or      byte ptr es:[bx+60h],8
apply_switch_done:
        pop     bx
        pop     es
        pop     ds
        assume  ds:sysinitseg
sysinitseg ends
end
