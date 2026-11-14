Bios_Data segment at 70h
 org 0fch
disksector_ptr dd 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f3eh
bios_data_segment dw 70h
 org 1c68h
; Read one logical boot-volume sector into the temporary sector buffer.
; DX:AX is the sector number; ES:BX receives the buffer address.
boot_read_sector proc near
        cmp     word ptr cs:[boot_copy_buffer+0bh],200h
        ja      boot_read_error
        cmp     word ptr cs:[boot_copy_buffer+13h],0
        jne     boot_read_small
        cmp     word ptr cs:[boot_copy_buffer+22h],dx
        ja      boot_read_offset
        jb      boot_read_error
        cmp     word ptr cs:[boot_copy_buffer+20h],ax
        jbe     boot_read_error
boot_read_offset:
        add     ax,word ptr cs:[boot_copy_buffer+1ch]
        adc     dx,word ptr cs:[boot_copy_buffer+1eh]
        mov     si,word ptr cs:[boot_copy_buffer+18h]
        or      si,si
        jz      boot_read_error
        push    ax
        mov     ax,dx
        xor     dx,dx
        div     si
        mov     cx,ax
        pop     ax
        push    cx
        div     si
        inc     dx
        mov     bx,dx
        pop     dx
        mov     si,word ptr cs:[boot_copy_buffer+1ah]
        or      si,si
        jz      boot_read_error
        push    ax
        mov     ax,dx
        xor     dx,dx
        div     si
        or      ax,ax
        pop     ax
        jnz     boot_read_error
        div     si
        mov     dh,dl
        mov     dl,cs:[boot_copy_buffer+24h]
        mov     cx,ax
        xchg    cl,ch
        ror     cl,1
        ror     cl,1
        or      cl,bl
        mov     ax,0201h
        mov     es,cs:[bios_data_segment]
        assume  es:Bios_Data
        les     bx,es:[disksector_ptr]
        assume  es:nothing
        int     13h
boot_read_return:
        ret
boot_read_small:
        or      dx,dx
        jnz     boot_read_error
        cmp     word ptr cs:[boot_copy_buffer+13h],ax
        ja      boot_read_offset
boot_read_error:
        stc
        jmp     short boot_read_return
boot_read_sector endp

 org 42e0h
boot_copy_buffer db 48h dup(0)
sysinitseg ends
end
