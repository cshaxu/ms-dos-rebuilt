;** CRTEXIT.ASM - DOS runtime output and termination
;
; Part of the output/error/termination dependency cycle.
; C entries preserve original near/far and caller-cleanup conventions.
        .286
        extrn __fcloseall:far
        extrn __flushall:far
        extrn __nullcheck:far
_DATA segment word public 'DATA'
        extrn __nfile:word
        extrn __osfile:byte
        extrn __iob:byte
        extrn __iob2:byte
        extrn __lastiob:dword
        extrn ___aDBswpflg:word
        extrn ___aDBswpchk:word
        extrn ___aDBrterr:word
        extrn ___aDBexit:word
        public __aexit_rtn,__aintdiv,__exitflag,__aaltstkovr,_STKHQQ
        public CRTFloatCallback,CRTPreTerm,CRTPostTerm,CRTExitEmpty
        public CRTTempPrefix,CRTPathSep
__aexit_rtn dw offset __exit
__aintdiv dd 0
__exitflag db 0
__aaltstkovr dd -1
_STKHQQ dw offset DGROUP:__end+100h
CRTTempPrefix db '\',0
CRTPathSep db '\',0
CRTFloatCallback dd 0
CRTPreTerm dw offset __endstdio,seg __endstdio
CRTPostTerm label byte
CRTExitEmpty label byte
_DATA ends
_END segment word public 'BSS'
        public __end
__end label byte
_END ends
_DATA segment word public 'DATA'
_DATA ends
DGROUP group _DATA,_END
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        extrn __FF_MSGBANNER:near
        extrn __NMSG_WRITE:near

        public __cintDIV
__cintDIV proc far
        mov ax,cs:CRTDataSegment
        mov ds,ax
        mov ax,03h
        mov word ptr __aexit_rtn,offset _exit
__cintDIV endp

        public __amsg_exit
__amsg_exit proc far
        push ax
        mov bx,cs:CRTDataSegment
        mov ds,bx
        call far ptr __farstub
        push cs
        call near ptr __FF_MSGBANNER
        push cs
        call near ptr __NMSG_WRITE
        cmp word ptr ___aDBswpflg,0D6D6h
        jnz short L9285
        pop ax
        push ax
        call word ptr ___aDBrterr
L9285:
        mov ax,0FFh
        push ax
        push cs
        call word ptr __aexit_rtn
__amsg_exit endp

        public _exit
_exit proc far
        push bp
        mov bp,sp
        xor cx,cx
        jmp short L937A
        public __exit
__exit label far
        push bp
        mov bp,sp
        mov cx,01h
        jmp short L937A
        public __cexit
__cexit label far
        push bp
        mov bp,sp
        push si
        push di
        mov cx,0100h
        jmp short L937A
        public __c_exit
__c_exit label far
        push bp
        mov bp,sp
        push si
        push di
        mov cx,0101h
L937A:
        mov __exitflag,ch
        push cx
        or cl,cl
        jnz short L93A1
        mov si,offset CRTExitEmpty
        mov di,offset CRTExitEmpty
        call near ptr __ctermsub
        mov si,offset CRTPreTerm
        mov di,offset CRTPostTerm
        call near ptr __ctermsub
        cmp word ptr ___aDBswpflg,0D6D6h
        jnz short L93A1
        call word ptr ___aDBexit
L93A1:
        mov si,offset CRTPostTerm
        mov di,offset CRTPostTerm
        call near ptr __ctermsub
        mov si,offset CRTPostTerm
        mov di,offset CRTPostTerm
        call near ptr __ctermsub
        call far ptr __nullcheck
        or ax,ax
        jz short L93CD
        pop ax
        or ah,ah
        push ax
        jnz short L93CD
        cmp word ptr [bp+06h],00h
        jnz short L93CD
        mov word ptr [bp+06h],0FFh
L93CD:
        call near ptr CRTRestoreVectors
        pop ax
        or ah,ah
        jnz short L93DC
        mov ax,[bp+06h]
        mov ah,04Ch
        int 021h
L93DC:
        pop di
        pop si
        pop bp
        retf
_exit endp

        public CRTRestoreVectors
CRTRestoreVectors proc far
        mov cx,word ptr CRTFloatCallback+2
        jcxz short L93ED
        mov bx,02h
        call dword ptr CRTFloatCallback
L93ED:
        push ds
        lds dx,__aintdiv
        mov ax,02500h
        int 021h
        pop ds
        retn
CRTRestoreVectors endp

        public __ctermsub
__ctermsub proc far
        cmp si,di
        jnc short L940B
        sub di,04h
        mov ax,[di]
        or ax,[di+02h]
        jz short __ctermsub
        call dword ptr [di]
        jmp short __ctermsub
L940B:
        retn
__ctermsub endp

        public __fptrap
__fptrap proc far
        mov ax,02h
        jmp near ptr __amsg_exit
__fptrap endp

        public __farstub
__farstub proc far
        retf
__farstub endp

        public __endstdio
__endstdio proc far
        push bp
        mov bp,sp
        call far ptr __flushall
        mov al,__exitflag
        or al,al
        jz short LA15A
        call far ptr __fcloseall
LA15A:
        pop bp
        retf
__endstdio endp
        public CRTDataSegment
CRTDataSegment dw seg __aexit_rtn
_TEXT ends
        end
