sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
DOS7_CONFIG equ 1
 org 9d72h
IFDEF DOS7_CONFIG
; Notify the boot log of device loading and its result.
config_loading  db      'Loading Device = '
config_failed   db      'LoadFailed     = '
config_success  db      'LoadSuccess    = '
config_log_buf  db      279 dup (0)
config_log_len  dw      0

        .286
config_log_device proc near
        push    ds
        push    es
        pusha
        push    cs
        pop     ds
        mov     dx,offset config_loading
        call    config_log_send
        popa
        pop     es
        pop     ds
        ret
config_log_device endp

config_log_send proc near
        or      si,si
        jz      config_log_prefix
        push    es
        pop     ds
        push    cs
        pop     es
        mov     di,offset config_log_buf+17
config_log_copy:
        lodsb
        or      al,al
        jz      config_log_end
        stosb
        jmp     short config_log_copy
config_log_end:
        mov     ax,0a0dh
        stosw
        mov     cx,di
        sub     cx,offset config_log_buf
        mov     cs:[config_log_len],cx
config_log_prefix:
        mov     si,dx
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     cx,17
        mov     di,offset config_log_buf
        mov     dx,di
        rep     movsb
        mov     ax,4a17h
        mov     cx,cs:[config_log_len]
        int     2fh
        ret
config_log_send endp

log_device_result proc near
        push    ds
        push    es
        pusha
        push    cs
        pop     ds
        xor     si,si
        mov     dx,offset config_success
        or      al,al
        jz      config_log_result
        mov     dx,offset config_failed
config_log_result:
        call    config_log_send
        popa
        pop     es
        pop     ds
        ret
log_device_result endp
        .8086
ENDIF

sysinitseg ends
end
