sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 1c68h
boot_read_sector proc near
 ret
boot_read_sector endp
 org 1cf3h
; Find an 11-byte directory name in the boot volume root directory.
; DS:SI points to the name.  Return ES:DI at the entry, carry if absent.
boot_find_file proc near
        mov     cl,cs:[boot_copy_buffer+10h]
        xor     ch,ch
        mov     ax,word ptr cs:[boot_copy_buffer+16h]
        mul     cx
        add     ax,word ptr cs:[boot_copy_buffer+0eh]
        adc     dx,0
        mov     bx,word ptr cs:[boot_copy_buffer+11h]
        xor     cx,cx
        .386
        bsf     cx,word ptr cs:[boot_copy_buffer+0bh]
        .8086
        sub     cx,5
        jbe     boot_find_error
        shr     bx,cl
        jz      boot_find_error
boot_find_sector:
        dec     bx
        js      boot_find_error
        push    bx
        push    dx
        push    ax
        push    si
        call    boot_read_sector
        mov     di,bx
        pop     si
        pop     ax
        pop     dx
        pop     bx
        jc      boot_find_error
        add     ax,1
        adc     dx,0
        mov     cx,word ptr cs:[boot_copy_buffer+0bh]
        .286
        shr     cx,5
        .8086
boot_find_entry:
        cmp     byte ptr es:[di],0
        je      boot_find_error
        push    cx
        push    di
        push    si
        mov     cx,11
        cld
        repe    cmpsb
        pop     si
        pop     di
        pop     cx
        je      boot_find_return
        add     di,20h
        loop    boot_find_entry
        jmp     short boot_find_sector
boot_find_error:
        stc
boot_find_return:
        ret
boot_find_file endp

 org 42e0h
boot_copy_buffer db 48h dup(0)
sysinitseg ends
end
