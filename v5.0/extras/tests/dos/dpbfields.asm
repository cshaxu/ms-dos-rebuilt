; Check Get-DPB against the 1.44 MB test floppy's BPB and derived geometry.
bits 16
org 100h
        mov     ax,3200h
        mov     dl,1
        int     21h
        or      al,al
        jnz     fail
        cmp     byte [bx],0             ; A:
        jne     fail
        cmp     byte [bx+1],0           ; device unit
        jne     fail
        cmp     word [bx+2],512         ; sector size
        jne     fail
        cmp     byte [bx+4],0           ; cluster mask
        jne     fail
        cmp     byte [bx+5],0           ; cluster shift
        jne     fail
        cmp     word [bx+6],1           ; first FAT sector
        jne     fail
        cmp     byte [bx+8],2           ; FAT copies
        jne     fail
        cmp     word [bx+9],224         ; root directory entries
        jne     fail
        cmp     word [bx+11],33         ; first data sector
        jne     fail
        cmp     word [bx+13],2848       ; maximum cluster
        jne     fail
        cmp     word [bx+15],9          ; sectors per FAT
        jne     fail
        cmp     word [bx+17],19         ; first root directory sector
        jne     fail
        cmp     byte [bx+23],0f0h       ; media descriptor
        jne     fail
        push    cs
        pop     ds
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
ok      db 'DPBFIELDS-PASS',13,10,'$'
bad     db 'DPBFIELDS-FAIL',13,10,'$'
