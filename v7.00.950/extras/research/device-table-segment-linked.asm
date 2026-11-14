sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0eebh
dosinfo dd 0
 org 0ff1h
config_device_table_ptr dd 0
 org 36cbh
        mov     ax,word ptr [dosinfo+2]
        mov     word ptr [config_device_table_ptr+2],ax
sysinitseg ends
end
