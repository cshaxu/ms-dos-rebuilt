; Extend an existing fragmented FAT12 file and check the appended data.
bits 16
org 100h
        push    cs
        pop     ds
        mov     dx,file_name
        mov     ax,3d02h
        int     21h
        jc      fail
        mov     bx,ax
        mov     ax,4202h
        xor     cx,cx
        xor     dx,dx
        int     21h
        jc      fail
        or      dx,dx
        jnz     fail
        cmp     ax,2048
        jne     fail
        mov     dx,pattern
        mov     cx,1024
        mov     ah,40h
        int     21h
        jc      fail
        cmp     ax,1024
        jne     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail
        mov     bx,ax
        mov     ax,4200h
        xor     cx,cx
        mov     dx,2048
        int     21h
        jc      fail
        mov     dx,buffer
        mov     cx,1024
        mov     ah,3fh
        int     21h
        jc      fail
        cmp     ax,1024
        jne     fail
        mov     si,buffer
        mov     cx,1024
check:  lodsb
        cmp     al,0a5h
        jne     fail
        loop    check
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
ok      db 'FRAGEXTEND-PASS',13,10,'$'
bad     db 'FRAGEXTEND-FAIL',13,10,'$'
pattern times 1024 db 0a5h
buffer  times 1024 db 0
