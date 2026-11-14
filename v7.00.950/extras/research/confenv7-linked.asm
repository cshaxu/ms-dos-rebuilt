sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f23h
alloclim dw 0
 org 0f52h
multi_pass_id db 0
 org 5ad0h
config_wrkseg dw 0
 org 6855h
        mov     ax,[alloclim]
        sub     ax,20h
        mov     [config_wrkseg],ax
        mov     es,ax
        mov     byte ptr es:[0],0
        mov     [alloclim],ax
        mov     multi_pass_id,11
        ret
 org 68b9h
        sub     dx,ax
        sub     dx,20h
        mov     [config_wrkseg],dx
        mov     es,dx
        mov     byte ptr es:[0],0
        sub     dx,ax
sysinitseg ends
end
