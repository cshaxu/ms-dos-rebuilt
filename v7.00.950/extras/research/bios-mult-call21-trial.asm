; INT 2Fh multiplex log notification, isolated layout experiment.
Bios_Code segment word public 'Bios_Code'
        assume  cs:Bios_Code,ds:nothing
        org     2B6Fh
log_flags       dw      2041h
        org     2B78h
log_device      dw      0
log_message     db      'MDF??'
        org     2CC8h
mult_call21 proc near
        push    bx
        push    cx
        push    dx
        test    cs:log_flags,4000h
        jz      notify_exit
        mov     bx,cs:log_device
        or      bx,bx
        jz      notify_exit
        push    cs
        pop     ds
        assume  ds:Bios_Code
        mov     word ptr log_message+3,3F3Fh
        mov     dx,offset log_message
        mov     ax,4404h
        mov     cx,5
        int     21h
notify_exit:
        pop     dx
        pop     cx
        pop     bx
        ret
mult_call21 endp
Bios_Code ends
        end     mult_call21
