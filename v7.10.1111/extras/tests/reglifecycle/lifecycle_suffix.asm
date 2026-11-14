RegReleaseFileBuffers proc far
        jmp failed
RegReleaseFileBuffers endp
RegReleaseMounts proc far
        inc MountCalls
        ret
RegReleaseMounts endp
RegIsWindowsPath proc far
        jmp failed
RegIsWindowsPath endp
RegGetVMEntry proc far
        jmp failed
RegGetVMEntry endp
RegFileCreate proc far
        jmp failed
RegFileCreate endp
RegRecoverFile proc far
        jmp failed
RegRecoverFile endp
RegReadFile proc far
        jmp failed
RegReadFile endp
ConfigGetAttr proc far
        jmp failed
ConfigGetAttr endp
ConfigDelete proc far
        jmp failed
ConfigDelete endp
RegCreateEmptyFile proc far
        jmp failed
RegCreateEmptyFile endp
RegInitUserRoot proc far
        jmp failed
RegInitUserRoot endp
RegInitClassesRoot proc far
        jmp failed
RegInitClassesRoot endp
ConfigFree proc far
        jmp failed
ConfigFree endp
RegFileUnlink proc far
        jmp failed
RegFileUnlink endp
start:
        mov ax,TESTDATA
        mov ds,ax
        mov SavedSP,sp
        push 0
        push 0
        push 0
        push 0
        mov ax,TESTSTACK
        mov ds,ax
        call RegInitialize
        push ax
        mov ax,ds
        mov bx,TESTSTACK
        cmp ax,bx
        jne failed
        mov ax,TESTDATA
        mov ds,ax
        pop ax
        add sp,8
        cmp sp,SavedSP
        jne failed
        cmp ax,57h
        jne failed
        or dx,dx
        jnz failed
        mov word ptr RegVMEntry,1
        push ds
        push offset RegRootTable
        push 0
        push 0
        mov ax,TESTSTACK
        mov ds,ax
        call RegInitialize
        push ax
        mov ax,ds
        mov bx,TESTSTACK
        cmp ax,bx
        jne failed
        mov ax,TESTDATA
        mov ds,ax
        pop ax
        add sp,8
        cmp sp,SavedSP
        jne failed
        or ax,dx
        jnz failed
        mov word ptr RegVMEntry,0
        mov ax,TESTSTACK
        mov ds,ax
        call RegTerminate
        mov ax,ds
        mov bx,TESTSTACK
        cmp ax,bx
        jne failed
        mov ax,TESTDATA
        mov ds,ax
        cmp sp,SavedSP
        jne failed
        cmp MountCalls,2
        jne failed
        cmp word ptr RegReserveSize,0
        jne failed
        cmp word ptr RegReserveSize+2,0
        jne failed
        mov ax,4C00h
        int 21h
failed:
        mov ax,4C01h
        int 21h
REGSTART ends
        end start
