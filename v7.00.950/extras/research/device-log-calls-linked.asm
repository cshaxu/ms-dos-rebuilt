sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 5ad6h
driver_units db 0
 org 6d89h
 mov [driver_units],0
 call config_log_device
 org 6dd8h
 mov al,0ffh
 call log_device_result
 org 705eh
 xor al,al
 call log_device_result
 org 9ebeh
config_log_device proc near
 ret
config_log_device endp
 org 9f0ah
log_device_result proc near
 ret
log_device_result endp
sysinitseg ends
end
