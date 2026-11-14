        .386
TESTDATA segment word public use16 'DATA'
same1   db 'aBc'
same2   db 'AbC'
onea    db 'a'
oneb    db 'b'
lastz   db 'z'
firsta  db 'a'
lowbit  db 7Fh
highbit db 80h
savedsp dw ?
TESTDATA ends
TESTSTACK segment para stack use16 'STACK'
        db 1024 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
        assume cs:_TEXT,ds:TESTDATA,ss:TESTSTACK
        extrn RegCompareName:near
CheckCompare macro left,right,count,expected
        mov savedsp,sp
        push ds
        mov ax,offset right
        push ax
        push ds
        mov ax,offset left
        push ax
        push count
        mov si,0BEEFh
        mov di,0CAFEh
        call RegCompareName
        cmp sp,savedsp
        jne test_failed
        cmp si,0BEEFh
        jne test_failed
        cmp di,0CAFEh
        jne test_failed
        cmp ax,expected
        jne test_failed
endm
start:
        mov ax,TESTDATA
        mov ds,ax
        CheckCompare same1,same2,3,0
        CheckCompare onea,oneb,1,1
        CheckCompare lastz,firsta,1,0FFE7h
        CheckCompare highbit,lowbit,1,255
        CheckCompare lowbit,highbit,1,0FF01h
        CheckCompare onea,oneb,0,0
        mov ax,4C00h
        int 21h
test_failed:
        mov ax,4C01h
        int 21h
_TEXT ends
        end start
