sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 sysi_numio equ 20h
 sysi_cds equ 16h
 dpb_driver_addr equ 13h
 org 0eebh
dosinfo dd 0
 org 6778h
config_cds_drivers dd 26 dup (-1)
 org 8941h
config_snapshot_drives proc near
        push    ds
        push    es
        push    ax
        push    bx
        push    cx
        push    di
        push    cs
        pop     es
        mov     di,offset config_cds_drivers
        xor     ch,ch
        lds     bx,cs:[dosinfo]
        mov     cl,[bx].sysi_numio
        jcxz    config_snapshot_done
        lds     bx,[bx].sysi_cds
config_snapshot_loop:
        push    ds
        push    bx
        test    word ptr [bx+43h],4000h
        jz      short config_snapshot_next
        lds     bx,[bx+45h]
        mov     ax,word ptr [bx].dpb_driver_addr
        mov     es:[di],ax
        mov     ax,word ptr [bx].dpb_driver_addr+2
        mov     es:[di+2],ax
config_snapshot_next:
        pop     bx
        pop     ds
        add     bx,58h
        add     di,4
        loop    config_snapshot_loop
config_snapshot_done:
        pop     di
        pop     cx
        pop     bx
        pop     ax
        pop     es
        pop     ds
        ret
config_snapshot_drives endp

sysinitseg ends
end
