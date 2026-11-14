;** CFGIOCTL.ASM - Configuration device control services
;
; FAR C arguments: device handle, FAR buffer, byte count.
; Return zero on success and one on DOS carry-set failure.
CFGIOCTL segment word public 'CODE'
        assume cs:CFGIOCTL
        public ConfigIOWrite,ConfigIORead
ConfigIOWrite proc far
        push bp
        mov bp,sp
        push ds
        mov ax,04403h
        mov cx,[bp+12]
        mov bx,[bp+6]
        lds dx,[bp+8]
        int 21h
        mov ax,0
        jnc short ConfigIOWrite_done
        inc ax
ConfigIOWrite_done:
        pop ds
        pop bp
        ret
ConfigIOWrite endp

ConfigIORead proc far
        push bp
        mov bp,sp
        push ds
        mov ax,04402h
        mov cx,[bp+12]
        mov bx,[bp+6]
        lds dx,[bp+8]
        int 21h
        mov ax,0
        jnc short ConfigIORead_done
        inc ax
ConfigIORead_done:
        pop ds
        pop bp
        ret
ConfigIORead endp

CFGIOCTL ends
        end
