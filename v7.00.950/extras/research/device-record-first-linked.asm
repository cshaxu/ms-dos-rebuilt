sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0eebh
dosinfo dd 0
 org 0feeh
drivenumber db 0
 org 13cah
        call    config_record_interrupts
        call    config_record_boot_int13
        lds     bx,cs:[dosinfo]
        lds     bx,[bx]
        lds     bx,[bx+13h]
        mov     al,cs:[drivenumber]
        call    config_record_device
 org 8678h
config_record_boot_int13 proc near
 ret
config_record_boot_int13 endp
 org 86f8h
config_record_device proc near
 ret
config_record_device endp
 org 8985h
config_record_interrupts proc near
 ret
config_record_interrupts endp
sysinitseg ends
end
