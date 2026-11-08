; Check duplicated file handles share a position and survive close operations.
bits 16
org 100h
        push    cs
        pop     ds
        mov     dx,file_name
        mov     ax,3d00h
        int     21h
        jc      fail
        mov     [original],ax
        mov     bx,ax
        mov     ah,45h
        int     21h
        jc      fail
        mov     [duplicate],ax
        mov     bx,[original]
        call    read_pair
        jc      fail
        cmp     word [buffer],0100h
        jne     fail
        mov     bx,[duplicate]
        call    read_pair
        jc      fail
        cmp     word [buffer],0302h
        jne     fail
        mov     bx,[original]
        mov     ah,3eh
        int     21h
        jc      fail
        mov     bx,[duplicate]
        call    read_pair
        jc      fail
        cmp     word [buffer],0504h
        jne     fail
        mov     bx,[duplicate]
        mov     cx,18                  ; valid slot in the default JFT
        mov     ah,46h
        int     21h
        jc      fail
        mov     bx,[duplicate]
        mov     ah,3eh
        int     21h
        jc      fail
        mov     bx,18
        call    read_pair
        jc      fail
        cmp     word [buffer],0706h
        jne     fail
        mov     ah,3eh
        int     21h
        jc      fail
        mov     dx,ok
        mov     ah,09h
        int     21h
        mov     ax,4c00h
        int     21h
read_pair:
        mov     dx,buffer
        mov     cx,2
        mov     ah,3fh
        int     21h
        jc      read_done
        cmp     ax,2
        je      read_done
        stc
read_done:
        ret
fail:   mov     dx,bad
        mov     ah,09h
        int     21h
        mov     ax,4c01h
        int     21h
original dw 0
duplicate dw 0
file_name db 'A:\FATDATA.BIN',0
ok      db 'SFTHANDLES-PASS',13,10,'$'
bad     db 'SFTHANDLES-FAIL',13,10,'$'
buffer  dw 0
