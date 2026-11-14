sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f10h
dos_image_paras dw 0c00h
 org 1031h
        assume  ds:sysinitseg
        mov     ax,[dos_image_paras]
        cmp     ax,0a00h
        ja      short dos_reserve_ready
        mov     ax,0a00h
        mov     [dos_image_paras],ax
dos_reserve_ready:
        sub     cx,ax
        assume  ds:nothing
 org 1136h
 mov ax,es
 add ax,cs:[dos_image_paras]
sysinitseg ends
end
