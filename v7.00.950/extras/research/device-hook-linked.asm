Bios_Code segment at 1d5h
 org 20b4h
i2f_handler label far
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f3eh
bios_data_segment dw 70h
BCodeSeg dw 1d5h
 org 6841h
config_hook_active db 0
config_device_segment dw 0
 org 88c8h
config_record_name_from_path proc near
 ret
config_record_name_from_path endp
 org 89c3h
config_hook_install proc near
        push    ds
        mov     ax,cs:[bios_data_segment]
        mov     ds,ax
        cli
        mov     ax,offset config_hook_int2f
        mov     word ptr ds:[168h],ax
        mov     ax,cs
        mov     word ptr ds:[16ah],ax
        sti
        mov     byte ptr cs:[config_hook_active],1
        mov     word ptr cs:[config_device_segment],0
        pop     ds
        ret
config_hook_install endp

config_hook_remove proc near
        push    ds
        mov     ax,cs:[bios_data_segment]
        mov     ds,ax
        cli
        mov     ax,offset Bios_Code:i2f_handler
        mov     word ptr ds:[168h],ax
        mov     ax,cs:[BCodeSeg]
        mov     word ptr ds:[16ah],ax
        sti
        mov     byte ptr cs:[config_hook_active],0
        pop     ds
        ret
config_hook_remove endp

        .286
config_hook_int2f proc far
        cmp     ax,4a30h
        je      short config_hook_device
        push    cs:[BCodeSeg]
        push    offset Bios_Code:i2f_handler
        retf
config_hook_device:
        pusha
        push    ds
        push    es
        mov     ax,es:[bx]
        mov     cs:[config_device_segment],ax
        mov     si,dx
        call    config_record_name_from_path
        pop     es
        pop     ds
        popa
        iret
config_hook_int2f endp
        .8086

sysinitseg ends
end
