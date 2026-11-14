sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 6732h
config_record_ptr dd 0
config_record_count dw 0
 org 6831h
config_mbr_record db 'MBRINT13SYS',0,0,0,1,2
 org 8678h
        public  config_record_boot_int13
config_record_boot_int13 proc near
        push    ds
        push    es
        mov     ax,70h
        mov     ds,ax
        mov     bx,word ptr ds:[106h]
        mov     dx,word ptr ds:[108h]
        cmp     dx,0a000h
        jae     short config_boot_done
        mov     ds,dx
        cmp     word ptr [bx],0e1eh
        jne     short config_boot_direct
        cmp     byte ptr [bx+2],1fh
        jne     short config_boot_record
        cmp     byte ptr [bx+3],0eah
        jne     short config_boot_indirect
        cmp     word ptr [bx+6],0a000h
        jae     short config_boot_done
        jmp     short config_boot_record
config_boot_indirect:
        cmp     word ptr [bx+3],2effh
        je      short config_boot_pointer
        cmp     word ptr [bx+3],1effh
        jne     short config_boot_record
config_boot_pointer:
        push    bx
        mov     bx,[bx+5]
        cmp     word ptr [bx+2],0a000h
        pop     bx
        jae     short config_boot_done
        jmp     short config_boot_record
config_boot_direct:
        cmp     byte ptr [bx],9ah
        je      short config_boot_segment
        cmp     byte ptr [bx],0eah
        jne     short config_boot_record
config_boot_segment:
        cmp     word ptr [bx+3],0a000h
        jae     short config_boot_done
config_boot_record:
        les     di,cs:[config_record_ptr]
        push    cs
        pop     ds
        mov     si,offset config_mbr_record
        mov     cx,16
        cld
        rep     movsb
        xchg    ax,bx
        stosw
        xchg    ax,dx
        stosw
        mov     cs:word ptr [config_record_ptr],di
        inc     word ptr cs:[config_record_count]
config_boot_done:
        pop     es
        pop     ds
        ret
config_record_boot_int13 endp

sysinitseg ends
end
