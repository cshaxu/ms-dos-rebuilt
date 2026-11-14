sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 1c68h
boot_read_sector proc near
 ret
boot_read_sector endp
 org 1cf3h
boot_find_file proc near
 ret
boot_find_file endp
 org 1d5bh
; Determine the paragraphs needed to load the disk compression driver.
boot_compressed_reserve proc near
        mov     si,offset boot_compress_name
        call    boot_find_file
        jc      boot_try_drvspace
        test    byte ptr es:[di+0bh],18h
        jz      boot_find_compress_bin
boot_try_drvspace:
        mov     word ptr [si+1],5652h
        call    boot_find_file
        jnc     short boot_check_drvspace
        jmp     boot_compress_default
boot_check_drvspace:
        test    byte ptr es:[di+0bh],18h
        jz      boot_find_compress_bin
        jmp     boot_compress_default
boot_find_compress_bin:
        mov     word ptr [si+8],4942h
        mov     byte ptr [si+0ah],4eh
        call    boot_find_file
        jnc     short boot_check_compress_bin
        jmp     boot_compress_default
boot_check_compress_bin:
        test    byte ptr es:[di+0bh],18h
        jz      boot_check_compress_size
        jmp     boot_compress_default
boot_check_compress_size:
        cmp     word ptr es:[di+1eh],0
        jne     short boot_compress_sector
        cmp     word ptr es:[di+1ch],40h
        jb      boot_compress_default
boot_compress_sector:
        mov     cl,cs:[boot_copy_buffer+10h]
        xor     ch,ch
        mov     ax,word ptr cs:[boot_copy_buffer+16h]
        mul     cx
        add     ax,word ptr cs:[boot_copy_buffer+0eh]
        adc     dx,0
        mov     bx,word ptr cs:[boot_copy_buffer+11h]
        .386
        bsf     cx,word ptr cs:[boot_copy_buffer+0bh]
        .8086
        sub     cx,5
        shr     bx,cl
        add     ax,bx
        adc     dx,0
        mov     bx,word ptr es:[di+1ah]
        sub     bx,2
        jb      boot_compress_default
        mov     cl,cs:[boot_copy_buffer+0dh]
        xor     ch,ch
        .386
        bsf     si,cx
        .8086
        mov     cx,si
        xor     si,si
        .386
        shld    si,bx,cl
        .8086
        shl     bx,cl
        add     ax,bx
        add     dx,si
        call    boot_read_sector
        jc      boot_compress_default
        mov     ax,1000h
        cmp     word ptr es:[bx],5a4dh
        jne     boot_compress_return
        cmp     word ptr es:[bx+18h],40h
        jb      boot_compress_return
        cmp     word ptr es:[bx+28h],7365h
        jne     boot_compress_return
        mov     dx,word ptr es:[bx+2ah]
        cmp     dx,3000h
        ja      boot_compress_return
        mov     ax,dx
boot_compress_return:
        ret
boot_compress_default:
        xor     ax,ax
        test    byte ptr cs:[boot_copy_buffer+24h],80h
        jnz     boot_compress_return
        mov     ax,1000h
        jmp     short boot_compress_return
boot_compressed_reserve endp
boot_compress_name db 'DBLSPACEINI'

 org 42e0h
boot_copy_buffer db 48h dup(0)
sysinitseg ends
end
