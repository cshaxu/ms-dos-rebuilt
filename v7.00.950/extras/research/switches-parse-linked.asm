sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 5ad7h
config_ebda_limit dw 400h
 org 6490h
result_val db 8 dup (0)
 org 65e4h
swit_k db '/K',0
 org 65f0h
swit_t db '/T',0
 org 65fch
swit_w db '/W',0
 org 6608h
swit_c db '/C',0
 org 6638h
swit_e db '/E',0
p_swit_k db 0
p_swit_t db 0
p_swit_w db 0
p_swit_c db 0
 org 6c16h
do110: ret
 org 6c25h
        cmp     word ptr [result_val+2],offset swit_k
        jne     short parse_switch_t
        mov     p_swit_k,1
        jmp     short do110
parse_switch_t:
        cmp     word ptr [result_val+2],offset swit_t
        jne     short parse_switch_w
        mov     p_swit_t,80h
        jmp     short do110
parse_switch_w:
        cmp     word ptr [result_val+2],offset swit_w
        jne     short parse_switch_c
        mov     p_swit_w,1
        jmp     short do110
parse_switch_c:
        cmp     word ptr [result_val+2],offset swit_c
        jne     short parse_switch_e
        mov     p_swit_c,1
        jmp     short do110
parse_switch_e:
        cmp     word ptr [result_val+2],offset swit_e
        jne     do110
        mov     ax,0ffffh
        cmp     byte ptr [result_val+1],2
        jne     short set_ebda_limit
        mov     ax,word ptr [result_val+4]
        add     ax,0fh
        and     al,0f0h
set_ebda_limit:
        mov     config_ebda_limit,ax
        jmp     short do110
sysinitseg ends
end
