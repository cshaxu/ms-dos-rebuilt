sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 5ad7h
config_ebda_limit dw 400h
 org 6490h
result_val db 8 dup (0)
 org 6638h
swit_e db '/E',0
 org 6c16h
do110: ret
 org 6c61h
if_switch_e:
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
        jmp     do110
sysinitseg ends
end
