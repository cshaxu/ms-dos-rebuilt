; Check SETDPB with 720 KB FAT12 and a 32-bit-sector-count FAT16 BPB.
bits 16
org 100h
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     si,bpb720
        mov     bp,dpb
        mov     ah,53h
        int     21h
        push    cs
        pop     ds
        cmp     byte [dpb+4],1
        jne     fail
        cmp     byte [dpb+5],1
        jne     fail
        cmp     word [dpb+9],112
        jne     fail
        cmp     word [dpb+11],14
        jne     fail
        cmp     word [dpb+13],714
        jne     fail
        cmp     word [dpb+15],3
        jne     fail
        cmp     word [dpb+17],7
        jne     fail
        cmp     byte [dpb+23],0f9h
        jne     fail
        push    cs
        pop     es
        mov     si,bpb16
        mov     bp,dpb
        mov     ah,53h
        int     21h
        push    cs
        pop     ds
        cmp     byte [dpb+4],3
        jne     fail
        cmp     byte [dpb+5],2
        jne     fail
        cmp     word [dpb+9],512
        jne     fail
        cmp     word [dpb+11],289
        jne     fail
        cmp     word [dpb+13],32696
        jne     fail
        cmp     word [dpb+15],128
        jne     fail
        cmp     word [dpb+17],257
        jne     fail
        cmp     byte [dpb+23],0f8h
        jne     fail
        mov     dx,ok
        mov     ah,09h
        int     21h
        mov     ax,4c00h
        int     21h
fail:   push    cs
        pop     ds
        mov     dx,bad
        mov     ah,09h
        int     21h
        mov     ax,4c01h
        int     21h
bpb720: dw 512
        db 2
        dw 1
        db 2
        dw 112,1440
        db 0f9h
        dw 3,9,2
        dd 0,0
bpb16:  dw 512
        db 4
        dw 1
        db 2
        dw 512,0
        db 0f8h
        dw 128,32,64
        dd 0,131072
dpb:    times 34 db 0
ok      db 'SETDPBGEOM-PASS',13,10,'$'
bad     db 'SETDPBGEOM-FAIL',13,10,'$'
