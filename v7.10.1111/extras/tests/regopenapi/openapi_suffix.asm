RegValidateKeyHandle proc far
        push bp
        mov bp,sp
        cmp Mode,1
        je short rv_fail
        les bx,[bp+0Ah]
        mov word ptr es:[bx],offset KeyHandle
        mov word ptr es:[bx+2],ds
        xor ax,ax
        xor dx,dx
        pop bp
        ret
rv_fail:
        mov ax,3F2h
        xor dx,dx
        pop bp
        ret
RegValidateKeyHandle endp
RegOpenPath proc far
        cmp Mode,2
        je short ro_fail
        xor ax,ax
        xor dx,dx
        ret
ro_fail:
        mov ax,3F3h
        xor dx,dx
        ret
RegOpenPath endp
RegFileAddRef proc far
        ret
RegFileAddRef endp
RegFileReleaseRef proc far
        ret
RegFileReleaseRef endp
RegFindOrCreate proc far
        cmp Mode,3
        je short rf_fail
        mov ax,offset NewHandle
        mov dx,ds
        ret
rf_fail:
        mov ax,-1
        cwd
        ret
RegFindOrCreate endp
RunOpen macro
        mov SavedSP,sp
        push ds
        push offset OutputHandle
        push ds
        push offset Path
        push 8000h
        push 0
        mov ax,TESTSTACK
        mov ds,ax
        call RegOpenKey
        push ax
        mov ax,ds
        mov bx,TESTSTACK
        cmp ax,bx
        jne failed
        mov ax,TESTDATA
        mov ds,ax
        pop ax
        add sp,12
        cmp sp,SavedSP
        jne failed
endm
start:
        mov ax,TESTDATA
        mov ds,ax
        mov word ptr KeyHandle+0Ch,offset FileObject
        mov word ptr KeyHandle+0Eh,ds
        mov Mode,1
        RunOpen
        cmp ax,3F2h
        jne failed
        or dx,dx
        jnz failed
        mov Mode,2
        RunOpen
        cmp ax,3F3h
        jne failed
        or dx,dx
        jnz failed
        mov Mode,3
        RunOpen
        cmp ax,0Eh
        jne failed
        or dx,dx
        jnz failed
        mov Mode,0
        RunOpen
        or ax,dx
        jnz failed
        cmp word ptr OutputHandle,offset NewHandle
        jne failed
        mov ax,ds
        cmp word ptr OutputHandle+2,ax
        jne failed
        cmp word ptr NewHandle+14h,1
        jne failed
        mov ax,4C00h
        int 21h
failed:
        mov ax,4C01h
        int 21h
REGAPI ends
        end start
