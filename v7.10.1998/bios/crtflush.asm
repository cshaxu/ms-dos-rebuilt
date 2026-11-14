;** CRTFLUSH.ASM - DOS runtime output and termination
;
; Part of the output/error/termination dependency cycle.
; C entries preserve original near/far and caller-cleanup conventions.
        .286
        extrn __commit:far
        extrn __write:far
_DATA segment word public 'DATA'
        extrn __iob:byte
        extrn __iob2:byte
        extrn __lastiob:dword
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP

        public _fflush
_fflush proc far
        push bp
        mov bp,sp
        push si
        mov ax,[bp+08h]
        or ax,[bp+06h]
        jnz short LA170
        db 06Ah,0             ; push imm8; MASM otherwise emits imm16
        call near ptr CRTFlushAll
        jmp short LA1AE
        nop
LA170:
        push word ptr [bp+08h]
        push word ptr [bp+06h]
        call near ptr __flush
        add sp,04h
        or ax,ax
        jz short LA186
        mov ax,0FFFFh
        jmp short LA1AE
        nop
LA186:
        mov si,[bp+06h]
        sub si,offset DGROUP:__iob
        add si,offset DGROUP:__iob2
        test byte ptr [si],040h
        jz short LA1AE
        les bx,[bp+06h]
        sub ah,ah
        mov al,es:[bx+0Bh]
        push ax
        call far ptr __commit
        add sp,02h
        cmp ax,01h
        cmc
        sbb ax,ax
LA1AE:
        pop si
        leave
        retf
        nop
_fflush endp

        public __flush
__flush proc far
        enter 02h,00h
        push di
        push si
        xor di,di
        mov ax,[bp+04h]
        mov bx,ax
        mov si,ax
        mov cl,[bx+0Ah]
        mov dx,cx
        and cl,03h
        cmp cl,02h
        jnz short LA217
        test dl,08h
        jnz short LA1DE
        sub bx,offset DGROUP:__iob
        test byte ptr [bx+__iob2],01h
        jz short LA217
LA1DE:
        mov ax,[si]
        sub ax,[si+06h]
        mov [bp-02h],ax
        or ax,ax
        jng short LA217
        push ax
        push word ptr [si+08h]
        push word ptr [si+06h]
        mov al,[si+0Bh]
        sub ah,ah
        push ax
        call far ptr __write
        add sp,08h
        cmp ax,[bp-02h]
        jnz short LA210
        test byte ptr [si+0Ah],080h
        jz short LA217
        and byte ptr [si+0Ah],0FDh
        jmp short LA217
LA210:
        or byte ptr [si+0Ah],020h
        mov di,0FFFFh
LA217:
        mov ax,[si+06h]
        mov dx,[si+08h]
        mov [si],ax
        mov [si+02h],dx
        mov word ptr [si+04h],00h
        mov ax,di
        pop si
        pop di
        leave
        retn
        nop
__flush endp

        public __flushall
__flushall proc far
        db 06Ah,1             ; push imm8; MASM otherwise emits imm16
        call near ptr CRTFlushAll
        retf
__flushall endp

        public CRTFlushAll
CRTFlushAll proc far
        enter 02h,00h
        push di
        push si
        mov si,offset DGROUP:__iob
        xor di,di
        mov [bp-02h],di
        jmp short LA265
LA244:
        cmp word ptr [bp+04h],00h
        jnz short LA262
        test byte ptr [si+0Ah],02h
        jz short LA262
        push ds
        push si
        call far ptr _fflush
        add sp,04h
        inc ax
        jnz short LA262
        mov word ptr [bp-02h],0FFFFh
LA262:
        add si,0Ch
LA265:
        cmp word ptr __lastiob,si
        jc short LA288
        cmp word ptr [bp+04h],01h
        jnz short LA244
        test byte ptr [si+0Ah],083h
        jz short LA244
        push ds
        push si
        call far ptr _fflush
        add sp,04h
        inc ax
        jz short LA262
        inc di
        jmp short LA262
        nop
LA288:
        cmp word ptr [bp+04h],01h
        jnz short LA292
        mov ax,di
        jmp short LA295
LA292:
        mov ax,[bp-02h]
LA295:
        pop si
        pop di
        leave
        retn 02h
        nop
CRTFlushAll endp
_TEXT ends
        end
