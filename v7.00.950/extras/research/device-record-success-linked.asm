sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
DOS7_CONFIG equ 1
 org 7027h
IFDEF DOS7_CONFIG
        push    ax                      ; save next device offset
        mov     al,[si+0ah]             ; block device unit count
        test    word ptr [si+4],8000h   ; character device?
        jz      short record_loaded_device
        xor     al,al
record_loaded_device:
        mov     bx,si
        call    config_record_device
        pop     ax
ENDIF

 org 86f8h
config_record_device proc near
 ret
config_record_device endp
sysinitseg ends
end
