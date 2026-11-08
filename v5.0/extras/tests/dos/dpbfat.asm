; Exercise DOS 5 Get-DPB and a multi-cluster FAT file on disposable media.
bits 16
org 100h
start:
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     ax,3200h
        mov     dl,1
        int     21h
        or      al,al
        jnz     fail_dpb
        cmp     byte [bx],0
        jne     fail_dpb
        cmp     word [bx+2],512
        jne     fail_dpb
        cmp     byte [bx+8],2
        jne     fail_dpb
        mov     [cs:saved_seg],ds
        mov     [cs:saved_off],bx
        mov     ax,3200h
        xor     dl,dl
        int     21h
        or      al,al
        jnz     fail_dpb
        mov     ax,ds
        cmp     ax,[cs:saved_seg]
        jne     fail_dpb
        cmp     bx,[cs:saved_off]
        jne     fail_dpb
        mov     ax,3200h
        mov     dl,27
        int     21h
        cmp     al,0ffh
        jne     fail_dpb
        push    cs
        pop     ds
        mov     dx,dpb_pass
        mov     ah,09h
        int     21h

        push    cs
        pop     es
        mov     di,write_buffer
        mov     cx,2048
        xor     al,al
fill:   stosb
        inc     al
        loop    fill
        mov     dx,file_name
        xor     cx,cx
        mov     ah,3ch
        int     21h
        jc      fail_fat
        mov     bx,ax
        mov     dx,write_buffer
        mov     cx,2048
        mov     ah,40h
        int     21h
        jc      fail_fat
        cmp     ax,2048
        jne     fail_fat
        mov     ah,3eh
        int     21h
        jc      fail_fat
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail_fat
        mov     bx,ax
        mov     dx,read_buffer
        mov     cx,2048
        mov     ah,3fh
        int     21h
        jc      fail_fat
        cmp     ax,2048
        jne     fail_fat
        mov     ah,3eh
        int     21h
        jc      fail_fat
        push    cs
        pop     es
        mov     si,write_buffer
        mov     di,read_buffer
        mov     cx,2048
        cld
        repe    cmpsb
        jne     fail_fat
        mov     dx,fat_pass
        mov     ah,09h
        int     21h
        mov     ax,4c00h
        int     21h
fail_dpb:
        push    cs
        pop     ds
        mov     dx,dpb_fail
        jmp     short fail
fail_fat:
        push    cs
        pop     ds
        mov     dx,fat_fail
fail:   mov     ah,09h
        int     21h
        mov     ax,4c01h
        int     21h
saved_seg dw 0
saved_off dw 0
file_name db 'A:\FATDATA.BIN',0
dpb_pass  db 'DPB-PASS',13,10,'$'
fat_pass  db 'FAT-PASS',13,10,'$'
dpb_fail  db 'DPB-FAIL',13,10,'$'
fat_fail  db 'FAT-FAIL',13,10,'$'
write_buffer times 2048 db 0
read_buffer  times 2048 db 0
