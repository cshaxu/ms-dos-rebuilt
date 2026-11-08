; Exercise SETDPB on private BPB/DPB buffers, including a short FAT.
bits 16
org 100h
        push    cs
        pop     ds
        push    cs
        pop     es
        mov     si,bpb
        mov     bp,dpb
        mov     ah,53h
        int     21h
        push    cs
        pop     ds
        cmp     byte [dpb],0a5h         ; drive/unit remain caller-owned
        jne     fail
        cmp     byte [dpb+1],05ah
        jne     fail
        cmp     word [dpb+2],512
        jne     fail
        cmp     word [dpb+6],1
        jne     fail
        cmp     byte [dpb+8],2
        jne     fail
        cmp     word [dpb+9],224
        jne     fail
        cmp     word [dpb+11],33
        jne     fail
        cmp     word [dpb+13],2848
        jne     fail
        cmp     word [dpb+15],9
        jne     fail
        cmp     word [dpb+17],19
        jne     fail
        cmp     byte [dpb+23],0f0h
        jne     fail
        cmp     word [dpb+29],0
        jne     fail
        cmp     word [dpb+31],0ffffh
        jne     fail
        mov     word [bpb+11],1         ; one 512-byte FAT sector
        push    cs
        pop     es
        mov     si,bpb
        mov     bp,dpb
        mov     ah,53h
        int     21h
        push    cs
        pop     ds
        cmp     word [dpb+11],17        ; 1 reserved + 2 FAT + 14 root
        jne     fail
        cmp     word [dpb+13],340       ; floor(512*2/3)-1
        jne     fail
        cmp     word [dpb+15],1
        jne     fail
        cmp     word [dpb+17],3
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
bpb:    dw 512
        db 1
        dw 1
        db 2
        dw 224,2880
        db 0f0h
        dw 9,18,2
        dd 0,0
dpb:    db 0a5h,05ah
        times 32 db 0cch
ok      db 'SETDPB-PASS',13,10,'$'
bad     db 'SETDPB-FAIL',13,10,'$'
