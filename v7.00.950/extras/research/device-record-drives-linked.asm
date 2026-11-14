sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 sysi_numio equ 20h
 sysi_cds equ 16h
 dpb_driver_addr equ 13h
 org 0eebh
dosinfo dd 0
 org 6778h
config_cds_drivers dd 26 dup (-1)
 org 682dh
config_cds_changed dd 0
 org 8845h
        .386
config_record_drives proc near
        db      66h                     ; 32-bit operand
        mov     word ptr cs:[config_cds_changed],0
        dw      0                       ; upper immediate word
        push    ds
        push    si
        push    cx
        lds     bx,cs:[dosinfo]
        xor     ch,ch
        mov     cl,[bx].sysi_numio
        jcxz    config_drives_done
        xor     dx,dx
        mov     si,offset config_cds_drivers
        lds     bx,[bx].sysi_cds
config_drive_loop:
        push    ds
        push    bx
        test    word ptr [bx+43h],4000h
        jz      short config_drive_next
        lds     bx,[bx+45h]
        mov     ax,cs:[si]
        cmp     [bx].dpb_driver_addr,ax
        jne     short config_drive_changed
        mov     ax,cs:[si+2]
        cmp     word ptr [bx].dpb_driver_addr+2,ax
        je      short config_drive_next
config_drive_changed:
        inc     ax
        jz      short config_drive_save
        push    edx
        movzx   edx,dx
        db      66h                     ; 32-bit operand
        bts     word ptr cs:[config_cds_changed],dx
        pop     edx
config_drive_save:
        mov     ax,word ptr [bx].dpb_driver_addr
        mov     cs:[si],ax
        mov     ax,word ptr [bx].dpb_driver_addr+2
        mov     cs:[si+2],ax
config_drive_next:
        add     si,4
        inc     dx
        pop     bx
        pop     ds
        add     bx,58h
        loop    config_drive_loop
config_drives_done:
        pop     cx
        pop     si
        pop     ds
        db      66h                     ; 32-bit operand
        cmp     word ptr cs:[config_cds_changed],0
        jz      short config_drives_exit
        inc     cx
        mov     al,7
        stosb
        mov     ax,word ptr cs:[config_cds_changed]
        stosw
        mov     ax,word ptr cs:[config_cds_changed+2]
        stosw
config_drives_exit:
        ret
config_record_drives endp
        .8086

sysinitseg ends
end
