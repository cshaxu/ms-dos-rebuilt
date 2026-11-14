sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f2dh
linecount dw 0
 org 6732h
config_record_ptr dd 0
config_record_count dw 0
config_record_name db 'IO      SYS'
config_record_flags dw 0
 db 0
config_record_vectors db 50 dup (0)
 org 6844h
config_device_vector dd 0
 org 86f8h
config_record_device proc near
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        push    ds
        cld
        les     di,cs:[config_record_ptr]
        mov     si,offset config_record_name
        mov     cx,11
        push    si
        push    di
        rep     movs byte ptr es:[di],byte ptr cs:[si]
        pop     di
        pop     si
        mov     es:[di+0dh],al
        xor     ax,ax
        xchg    ax,cs:[config_record_flags]
        mov     es:[di+0bh],ax
        lea     di,[di+0fh]
        xor     cx,cx
        mov     al,1
        mov     dx,ds
        call    config_record_item
        call    config_scsi_entry
        jc      short config_record_bios
        mov     al,6
        call    config_record_item
config_record_bios:
        mov     ax,70h
        mov     ds,ax
        mov     bx,word ptr ds:[0b4h]
        mov     dx,word ptr ds:[0b6h]
        mov     al,3
        call    config_record_item
        xor     ax,ax
        mov     ds,ax
        mov     bx,word ptr ds:[4ch]
        mov     dx,word ptr ds:[4eh]
        mov     al,2
        call    config_record_item
        mov     bx,word ptr ds:[12ch]
        mov     dx,word ptr ds:[12eh]
        mov     al,4
        call    config_record_item
        mov     bx,word ptr ds:[13ch]
        mov     dx,word ptr ds:[13eh]
        mov     al,5
        call    config_record_item
        call    config_record_drives
        mov     bx,cs:[linecount]
        or      bx,bx
        jnz     short config_record_line
        mov     word ptr cs:[config_record_vectors+36],-1
config_record_line:
        xor     dx,dx
        mov     al,8
        call    config_record_item
        mov     bx,cs:word ptr [config_device_vector]
        mov     dx,cs:word ptr [config_device_vector+2]
        mov     ax,bx
        or      ax,dx
        jz      short config_record_ints
        mov     al,9
        call    config_record_item
config_record_ints:
        xor     ax,ax
        mov     word ptr cs:[config_record_vectors+46],ax
        mov     word ptr cs:[config_record_vectors+48],ax
        call    config_record_interrupts
        mov     al,10
        call    config_record_item
        jcxz    config_record_exit
        push    di
        les     di,cs:[config_record_ptr]
        mov     es:[di+0eh],cl
        pop     word ptr cs:[config_record_ptr]
        inc     word ptr cs:[config_record_count]
config_record_exit:
        pop     ds
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
config_record_device endp

 org 87d5h
config_record_item proc near
 ret
config_record_item endp
 org 87feh
config_scsi_entry proc near
 ret
config_scsi_entry endp
 org 8845h
config_record_drives proc near
 ret
config_record_drives endp
 org 8985h
config_record_interrupts proc near
 ret
config_record_interrupts endp
sysinitseg ends
end
