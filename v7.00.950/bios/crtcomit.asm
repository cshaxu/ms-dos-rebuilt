;** CRTCOMIT.ASM - Commit a DOS file handle
;
; FAR C entry: file handle. Return zero on success, -1 on failure.
; DOS versions before 3.30 need no explicit commit operation.
        .286
        extrn __dos_commit:far
_DATA segment word public 'DATA'
        extrn _errno:word,__doserrno:word,__nfile:word
        extrn __osminor:byte,__osmajor:byte,__osfile:byte
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        public __commit
__commit proc far
        push bp
        mov bp,sp
        push di
        push si
        mov si,[bp+06h]
        or si,si
        jl short commit_12
        cmp __nfile,si
        jg short commit_1E
commit_12:
        mov word ptr _errno,09h
        mov ax,0FFFFh
        jmp short commit_53
        nop
commit_1E:
        mov al,__osminor
        mov ah,__osmajor
        cmp ax,031Eh
        jnl short commit_2E
        xor ax,ax
        jmp short commit_53
commit_2E:
        test byte ptr __osfile[si],01h
        jz short commit_48
        push si
        call __dos_commit
        add sp,02h
        mov di,ax
        or di,ax
        jz short commit_51
        mov __doserrno,di
commit_48:
        mov word ptr _errno,09h
        mov di,0FFFFh
commit_51:
        mov ax,di
commit_53:
        pop si
        pop di
        leave
        ret
__commit endp
        even
_TEXT ends
        end
