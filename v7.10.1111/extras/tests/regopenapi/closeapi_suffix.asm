RegValidateKeyHandle proc far
        push bp
        mov bp,sp
        cmp Mode,1
        je short rv_bad
        les bx,[bp+0Ah]
        mov word ptr es:[bx],offset KeyHandle
        mov word ptr es:[bx+2],ds
        xor ax,ax
        xor dx,dx
        pop bp
        ret
rv_bad:
        mov ax,3F2h
        xor dx,dx
        pop bp
        ret
RegValidateKeyHandle endp
RegFileReleaseRef proc far
        inc ReleaseCount
        ret
RegFileReleaseRef endp
RegSaveFile proc far
        inc SaveCount
        xor ax,ax
        xor dx,dx
        ret
RegSaveFile endp
RegKeyDestroy proc far
        inc DestroyCount
        ret 4
RegKeyDestroy endp
RunClose macro
        mov SavedSP,sp
        push 8000h
        push 0
        mov ax,TESTSTACK
        mov ds,ax
        call RegCloseKey
        push ax
        mov ax,ds
        mov bx,TESTSTACK
        cmp ax,bx
        jne failed
        mov ax,TESTDATA
        mov ds,ax
        pop ax
        add sp,4
        cmp sp,SavedSP
        jne failed
endm
start:
        mov ax,TESTDATA
        mov ds,ax
        mov word ptr KeyHandle+0Ch,offset FileObject
        mov word ptr KeyHandle+0Eh,ds
        mov Mode,1
        RunClose
        cmp ax,3F2h
        jne failed
        cmp ReleaseCount,0
        jne failed
        mov Mode,0
        mov byte ptr KeyHandle+19h,40h
        RunClose
        or ax,dx
        jnz failed
        cmp ReleaseCount,1
        jne failed
        cmp SaveCount,1
        jne failed
        cmp DestroyCount,0
        jne failed
        mov byte ptr KeyHandle+19h,0
        mov word ptr KeyHandle+14h,1
        RunClose
        or ax,dx
        jnz failed
        cmp ReleaseCount,2
        jne failed
        cmp DestroyCount,1
        jne failed
        mov ax,4C00h
        int 21h
failed:
        mov ax,4C01h
        int 21h
REGAPI ends
        end start
