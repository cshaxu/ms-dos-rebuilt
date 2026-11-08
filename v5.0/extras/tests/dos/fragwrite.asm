; Write across a fragmented cluster boundary, close, reopen and verify.
bits 16
org 100h
        push    cs
        pop     ds
        mov     dx,file_name
        mov     ax,3d02h
        int     21h
        jc      fail
        mov     bx,ax
        call    seek_boundary
        jc      fail
        mov     dx,pattern
        mov     cx,6
        mov     ah,40h
        int     21h
        jc      fail
        cmp     ax,6
        jne     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail
        mov     bx,ax
        call    seek_boundary
        jc      fail
        mov     dx,buffer
        mov     cx,6
        mov     ah,3fh
        int     21h
        jc      fail
        cmp     ax,6
        jne     fail
        cmp     word [buffer],05aa5h
        jne     fail
        cmp     word [buffer+2],0c33ch
        jne     fail
        cmp     word [buffer+4],06996h
        jne     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,ok
        mov     ah,09h
        int     21h
        mov     ax,4c00h
        int     21h
seek_boundary:
        mov     ax,4200h
        xor     cx,cx
        mov     dx,510
        int     21h
        ret
fail:   mov     dx,bad
        mov     ah,09h
        int     21h
        mov     ax,4c01h
        int     21h
file_name db 'A:\FATDATA.BIN',0
pattern db 0a5h,05ah,03ch,0c3h,096h,069h
ok      db 'FRAGWRITE-PASS',13,10,'$'
bad     db 'FRAGWRITE-FAIL',13,10,'$'
buffer  times 6 db 0
