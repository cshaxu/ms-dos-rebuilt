sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 5ad7h
config_ebda_limit dw 400h
 org 8a25h
qemm_device_name db     'QEMM386.SYS'

config_check_qemm proc near
        push    ds
        push    es
        push    si
        push    di
        push    cx
        push    ax
        push    es
        pop     ds
        push    cs
        pop     es
        cld
        mov     di,offset qemm_device_name
        mov     ah,es:[di]
config_qemm_scan:
        lodsb
        cmp     al,0ah
        je      short config_qemm_done
        cmp     al,ah
        jne     config_qemm_scan
        push    si
        push    di
        dec     si
        mov     cx,11
        repe    cmpsb
        pop     di
        pop     si
        jne     config_qemm_scan
        mov     word ptr cs:[config_ebda_limit],-1
config_qemm_done:
        pop     ax
        pop     cx
        pop     di
        pop     si
        pop     es
        pop     ds
        ret
config_check_qemm endp

sysinitseg ends
end
