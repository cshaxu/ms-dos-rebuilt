; Read a prearranged fragmented FAT12 file and verify data and seek behavior.
bits 16
org 100h
        push    cs
        pop     ds
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail
        mov     bx,ax
        mov     dx,buffer
        mov     cx,2048
        mov     ah,3fh
        int     21h
        jc      fail
        cmp     ax,2048
        jne     fail
        mov     si,buffer
        mov     cx,2048
        xor     dl,dl
check:  lodsb
        cmp     al,dl
        jne     fail
        inc     dl
        loop    check
        mov     ax,4200h
        xor     cx,cx
        mov     dx,510
        int     21h
        jc      fail
        mov     dx,buffer
        mov     cx,6
        mov     ah,3fh
        int     21h
        jc      fail
        cmp     ax,6
        jne     fail
        cmp     word [buffer],0fffeh
        jne     fail
        cmp     word [buffer+2],0100h
        jne     fail
        cmp     word [buffer+4],0302h
        jne     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,ok
        mov     ah,09h
        int     21h
        mov     ax,4c00h
        int     21h
fail:   mov     dx,bad
        mov     ah,09h
        int     21h
        mov     ax,4c01h
        int     21h
file_name db 'A:\FATDATA.BIN',0
ok      db 'FRAG-PASS',13,10,'$'
bad     db 'FRAG-FAIL',13,10,'$'
buffer  times 2048 db 0
