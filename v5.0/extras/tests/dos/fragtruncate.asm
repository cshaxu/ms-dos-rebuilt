; Truncate a fragmented file and check its remaining contents and EOF.
bits 16
org 100h
        push    cs
        pop     ds
        mov     dx,file_name
        mov     ax,3d02h
        int     21h
        jc      fail
        mov     bx,ax
        mov     ax,4200h
        xor     cx,cx
        mov     dx,600
        int     21h
        jc      fail
        xor     cx,cx
        mov     dx,buffer
        mov     ah,40h
        int     21h
        jc      fail
        or      ax,ax
        jnz     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail
        mov     bx,ax
        mov     dx,buffer
        mov     cx,601
        mov     ah,3fh
        int     21h
        jc      fail
        cmp     ax,600
        jne     fail
        mov     si,buffer
        mov     cx,600
        xor     dl,dl
check:  lodsb
        cmp     al,dl
        jne     fail
        inc     dl
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
ok      db 'FRAGTRUNCATE-PASS',13,10,'$'
bad     db 'FRAGTRUNCATE-FAIL',13,10,'$'
buffer  times 601 db 0
