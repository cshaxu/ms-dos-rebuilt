;** CRTMSG.ASM - Runtime message lookup, output and data check
;
; __NMSG_TEXT and __NMSG_WRITE take one message number and pop it.
; __FF_MSGBANNER invokes the optional far debug-message callback.
; __nullcheck checks the original 66-byte null-assignment guard.
_DATA segment word public 'DATA'
        extrn ___aDBswpflg:word,___aDBswpchk:word
        public __adbgmsg,CRTMessageHeader,CRTMessages
__adbgmsg dd 0
CRTMessageHeader db '<<NMSG>>'
CRTMessages label byte
        dw 0
        db 'R6000',13,10,'- stack overflow',13,10,0
        dw 3
        db 'R6003',13,10,'- integer divide by 0',13,10,0
        dw 9
        db 'R6009',13,10,'- not enough space for environment',13,10,0
        dw 252
        db 13,10,0
        dw 255
        db 'run-time error ',0
        dw 2
        db 'R6002',13,10,'- floating-point support not loaded',13,10,0
        dw 1
        db 'R6001',13,10,'- null pointer assignment',13,10,0
        dw 65535
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP

        public __NMSG_TEXT
__NMSG_TEXT proc far
        push bp
        mov bp,sp
        push si
        push di
        push ds
        pop es
        mov dx,[bp+06h]
        mov si,offset CRTMessages
__NMSG_TEXT_loc_0D:
        lodsw
        cmp ax,dx
        jz short __NMSG_TEXT_loc_22
        inc ax
        xchg ax,si
        jz short __NMSG_TEXT_loc_22
        xchg ax,di
        xor ax,ax
        mov cx,0FFFFh
        repne scasb
        mov si,di
        jmp short __NMSG_TEXT_loc_0D
__NMSG_TEXT_loc_22:
        xchg ax,si
        pop di
        pop si
        mov sp,bp
        pop bp
        ret 02h
__NMSG_TEXT endp

        public __NMSG_WRITE
__NMSG_WRITE proc far
        push bp
        mov bp,sp
        push di
        push word ptr [bp+06h]
        push cs
        call near ptr __NMSG_TEXT
        or ax,ax
        jz short __NMSG_WRITE_loc_2F
        xchg ax,dx
        mov di,dx
        xor ax,ax
        mov cx,0FFFFh
        repne scasb
        not cx
        dec cx
        mov bx,02h
        cmp word ptr ___aDBswpflg,0D6D6h
        jnz short __NMSG_WRITE_loc_2B
        call word ptr ___aDBswpchk
__NMSG_WRITE_loc_2B:
        mov ah,040h
        int 021h
__NMSG_WRITE_loc_2F:
        pop di
        mov sp,bp
        pop bp
        ret 02h
__NMSG_WRITE endp

        public __FF_MSGBANNER
__FF_MSGBANNER proc far
        push bp
        mov bp,sp
        mov ax,0FCh
        push ax
        push cs
        call near ptr __NMSG_WRITE
        cmp word ptr __adbgmsg+2,00h
        jz short __FF_MSGBANNER_loc_16
        call dword ptr __adbgmsg
__FF_MSGBANNER_loc_16:
        mov ax,0FFh
        push ax
        push cs
        call near ptr __NMSG_WRITE
        mov sp,bp
        pop bp
        ret
__FF_MSGBANNER endp

        public __nullcheck
__nullcheck proc far
        push si
        xor si,si
        mov cx,042h
        xor ah,ah
        cld
__nullcheck_loc_09:
        lodsb
        xor ah,al
        loop __nullcheck_loc_09
        xor ah,055h
        jz short __nullcheck_loc_22
        push cs
        call near ptr __FF_MSGBANNER
        mov ax,01h
        push ax
        push cs
        call near ptr __NMSG_WRITE
        mov ax,01h
__nullcheck_loc_22:
        pop si
        ret
__nullcheck endp
_TEXT ends
        end
