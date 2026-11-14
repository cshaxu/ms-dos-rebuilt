;** REGVM - Windows registry service detection
;
; FAR C entry takes a FAR path at BP+6. Return -1 when the running
; Windows instance owns that path; otherwise return zero.
;
_DATA segment word public 'DATA'
_DATA ends
c_common segment word public 'BSS'
        extrn RegVMEntry:dword
c_common ends
DGROUP group _DATA,c_common
REGIO segment word public 'CODE'
        .386
        assume cs:REGIO,ds:DGROUP
        public RegIsWindowsPath,RegGetVMEntry
RegIsWindowsPath proc far
        enter 64h,0
        push ds
        push es
        push di
        push si
        push bx
        push ss
        pop es
        lea di,[bp-64h]
        mov cx,64h
        mov ax,1613h
        int 2fh
        or eax,eax
        jnz short rvm_not_found
        push di
        mov cx,64h
        cld
        repne scasb
        pop di
        jnz short rvm_not_found
        neg cx
        add cx,64h
        push ds
        lds si,[bp+6]
        repe cmpsb
        pop ds
        jnz short rvm_not_found
        mov ax,1600h
        int 2fh
        test al,7fh
        jz short rvm_not_found
        cmp al,1
        jz short rvm_not_found
        cmp al,0ffh
        jz short rvm_not_found
        cmp al,4
        jc short rvm_not_found
        mov ax,0ffffh
        jmp short rvm_exit
rvm_not_found:
        xor ax,ax
rvm_exit:
        mov dx,ax
        pop bx
        pop si
        pop di
        pop es
        pop ds
        leave
        ret
RegIsWindowsPath endp

; Obtain the VMM service entry. The caller decides whether to use it.
RegGetVMEntry proc far
        push es
        push bx
        push di
        xor di,di
        mov es,di
        mov ax,1684h
        mov bx,1
        int 2fh
        mov dx,es
        mov ax,di
        mov word ptr RegVMEntry,ax
        mov word ptr RegVMEntry+2,dx
        pop di
        pop bx
        pop es
        ret
RegGetVMEntry endp
REGIO ends
        end
