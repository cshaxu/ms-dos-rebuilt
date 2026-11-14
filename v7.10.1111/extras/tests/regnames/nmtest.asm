        .386
TESTDATA segment word public use16 'DATA'
empty   db 0
mixed   db 'aZz',0
highbit db 7Fh,80h,0FFh,'a',0
longer  db 1000 dup ('z'),0
many    db 255 dup (80h),0
single  db 0,0
embedded db 'a',0,'b'
resulta dw 0
resultd dw 0
savedsp dw 0
TESTDATA ends
TESTSTACK segment para stack use16 'STACK'
        db 1024 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
        assume cs:_TEXT,ds:TESTDATA,ss:TESTSTACK
        extrn RegNameChecksum:near,RegOldNameSum:far
CheckName macro name,count,expectedlo,expectedhi
        mov savedsp,sp
        push ds
        mov ax,offset name
        push ax
        call RegOldNameSum
        add sp,4
        mov resulta,ax
        mov resultd,dx
        push ds
        mov ax,offset name
        push ax
        push count
        call RegNameChecksum
        cmp sp,savedsp
        jne test_failed
        cmp ax,resulta
        jne test_failed
        cmp dx,resultd
        jne test_failed
        cmp ax,expectedlo
        jne test_failed
        cmp dx,expectedhi
        jne test_failed
endm
start:
        mov ax,TESTDATA
        mov ds,ax
        CheckName empty,0,0,0
        CheckName mixed,3,245,0
        CheckName highbit,4,192,0
        CheckName longer,1000,5F90h,1
        CheckName many,255,0,0
        push ds
        mov ax,offset embedded
        push ax
        push 3
        call RegNameChecksum
        cmp ax,131
        jne test_failed
        or dx,dx
        jne test_failed
        mov cx,255
test_bytes:
        mov single,cl
        push cx
        push ds
        mov ax,offset single
        push ax
        call RegOldNameSum
        add sp,4
        mov resulta,ax
        mov resultd,dx
        push ds
        mov ax,offset single
        push ax
        push 1
        mov si,0BEEFh
        call RegNameChecksum
        cmp si,0BEEFh
        jne test_failed
        cmp ax,resulta
        jne test_failed
        cmp dx,resultd
        jne test_failed
        pop cx
        loop test_bytes
        mov ax,4C00h
        int 21h
test_failed:
        mov ax,4C01h
        int 21h
_TEXT ends
        end start
