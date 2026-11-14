;** CRTWRITE.ASM - DOS runtime output and termination
;
; Part of the output/error/termination dependency cycle.
; C entries preserve original near/far and caller-cleanup conventions.
        .286
_DATA segment word public 'DATA'
        extrn __aexit_rtn:word
        extrn __aintdiv:dword
        extrn __nfile:word
        extrn __osfile:byte
        extrn __exitflag:byte
        extrn __iob:byte
        extrn __iob2:byte
        extrn __lastiob:dword
        extrn __aaltstkovr:dword
        extrn _STKHQQ:word
        extrn CRTTempPrefix:byte
        extrn CRTPathSep:byte
        extrn ___aDBswpflg:word
        extrn ___aDBswpchk:word
        extrn ___aDBrterr:word
        extrn ___aDBexit:word
        extrn CRTFloatCallback:dword
        extrn CRTPreTerm:byte
        extrn CRTPostTerm:byte
        extrn CRTExitEmpty:byte
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        extrn __amsg_exit:near
        extrn __dosretax:near

        public __chkstk
__chkstk proc far
        pop cx
        pop dx
        mov bx,sp
        sub bx,ax
        jc short LA135
        cmp bx,_STKHQQ
        jc short LA135
        mov sp,bx
        push dx
        push cx
        retf
LA135:
        push dx
        push cx
        mov ax,word ptr __aaltstkovr
        inc ax
        jnz short LA142
        xor ax,ax
        jmp near ptr __amsg_exit
LA142:
        jmp dword ptr __aaltstkovr
__chkstk endp

        public __write
__write proc far
        push bp
        mov bp,sp
        sub sp,08h
        mov bx,[bp+06h]
        cmp bx,__nfile
        jc short LA334
        mov ax,0900h
        stc
LA331:
        jmp near ptr __dosretax
LA334:
        cmp word ptr ___aDBswpflg,0D6D6h
        jnz short LA340
        call word ptr ___aDBswpchk
LA340:
        test byte ptr [bx+__osfile],020h
        jz short LA352
        mov ax,04202h
        xor cx,cx
        mov dx,cx
        int 021h
        jc short LA331
LA352:
        test byte ptr [bx+__osfile],080h
        jz short LA3D5
        mov word ptr [bp-06h],ds
        mov es,word ptr [bp+0Ah]
        lds dx,[bp+08h]
        xor ax,ax
        mov [bp-02h],ax
        mov [bp-04h],ax
        cld
        push di
        push si
        mov di,dx
        mov si,dx
        mov [bp-08h],sp
        mov cx,[bp+0Ch]
        jcxz short LA3B8
        mov al,0Ah
        repne scasb
        jnz short LA3D0
        push ds
        mov ds,word ptr [bp-06h]
        call far ptr __stackavail
        cmp ax,0A8h
        jna short LA3D7
        pop ds
        sub sp,02h
        mov bx,sp
        mov dx,0200h
        cmp ax,0228h
        jnc short LA39E
        mov dx,080h
LA39E:
        sub sp,dx
        mov dx,sp
        mov di,dx
        push ss
        pop es
        mov cx,[bp+0Ch]
LA3A9:
        lodsb
        cmp al,0Ah
        jz short LA3BA
LA3AE:
        cmp di,bx
        jz short LA3CB
LA3B2:
        stosb
        loop LA3A9
        call near ptr CRTWriteBuffer
LA3B8:
        jmp short LA433
LA3BA:
        mov al,0Dh
        cmp di,bx
        jnz short LA3C3
        call near ptr CRTWriteBuffer
LA3C3:
        stosb
        mov al,0Ah
        inc word ptr [bp-04h]
        jmp short LA3AE
LA3CB:
        call near ptr CRTWriteBuffer
        jmp short LA3B2
LA3D0:
        pop si
        pop di
        mov ds,word ptr [bp-06h]
LA3D5:
        jmp short LA444
LA3D7:
        mov ax,0FFFCh
        push cs
        call near ptr __chkstk
        public CRTWriteBuffer
CRTWriteBuffer label far
        push ax
        push bx
        push cx
        push ds
        push es
        pop ds
        mov cx,di
        sub cx,dx
        jcxz short LA3FC
        push cx
        mov bx,[bp+06h]
        mov ah,040h
        int 021h
        pop cx
        jc short LA403
        add [bp-02h],ax
        cmp cx,ax
        ja short LA403
LA3FC:
        pop ds
        pop cx
        pop bx
        pop ax
        mov di,dx
        retn
LA403:
        lahf
        pop ds
        add sp,08h
        cmp word ptr [bp-02h],00h
        jnz short LA433
        sahf
        jnc short LA415
        mov ah,09h
        jmp short LA439
LA415:
        mov ds,word ptr [bp-06h]
        test byte ptr [bx+__osfile],040h
        jz short LA42D
        mov ds,word ptr [bp+0Ah]
        mov bx,[bp+08h]
        cmp byte ptr [bx],01Ah
        jnz short LA42D
        clc
        jmp short LA439
LA42D:
        stc
        mov ax,01C00h
        jmp short LA439
LA433:
        mov ax,[bp-02h]
        sub ax,[bp-04h]
LA439:
        mov sp,[bp-08h]
        pop si
        pop di
        mov ds,word ptr [bp-06h]
LA441:
        jmp near ptr __dosretax
LA444:
        mov cx,[bp+0Ch]
        or cx,cx
        jnz short LA450
        mov ax,cx
        jmp near ptr __dosretax
LA450:
        push ds
        lds dx,[bp+08h]
        mov ah,040h
        int 021h
        push ds
        pop es
        pop ds
        jnc short LA461
        mov ah,09h
        jmp short LA441
LA461:
        or ax,ax
        jnz short LA441
        test byte ptr [bx+__osfile],040h
        jz short LA477
        mov bx,dx
        cmp byte ptr es:[bx],01Ah
        jnz short LA477
        clc
        jmp short LA441
LA477:
        stc
        mov ax,01C00h
        jmp short LA441
__write endp

        public __stackavail
__stackavail proc far
        pop cx
        pop dx
        mov ax,_STKHQQ
        cmp ax,sp
        jnc short LA48E
        sub ax,sp
        neg ax
LA48B:
        push dx
        push cx
        retf
LA48E:
        xor ax,ax
        jmp short LA48B
__stackavail endp
_TEXT ends
        end
