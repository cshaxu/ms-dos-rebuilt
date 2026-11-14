sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 0ef1h
current_dos_location dw 0
 org 0efbh
dos_segreinit dw 0,0
 org 0ff1h
config_device_table_ptr dd 0
 org 1250h
        mov     ax,cs:[current_dos_location]
        mov     cs:[dos_segreinit+2],ax
        add     bx,20h
        mov     word ptr cs:[config_device_table_ptr],bx
sysinitseg ends
end
