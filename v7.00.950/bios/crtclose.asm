;** CRTCLOSE.ASM - DOS runtime output and termination
;
; Part of the output/error/termination dependency cycle.
; C entries preserve original near/far and caller-cleanup conventions.
        .286
        extrn __close:far
        extrn __itoa:far
        extrn __unlink:far
        extrn _strcat:far
        extrn _strcpy:far
_DATA segment word public 'DATA'
        extrn __iob:byte
        extrn __iob2:byte
        extrn __lastiob:dword
        extrn CRTTempPrefix:byte
        extrn CRTPathSep:byte
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        extrn __flush:near
        extrn __freebuf:near


        public _fclose
_fclose proc far
        enter 010h,00h
        push di
        push si
        mov di,0FFFFh
        mov ax,[bp+06h]
        mov si,ax
        mov bx,ax
        test byte ptr [bx+0Ah],040h
        jz short LA5DA
        mov byte ptr [bx+0Ah],00h
        jmp LA67C
        nop
LA5DA:
        test byte ptr [si+0Ah],083h
        jnz short LA5E3
        jmp LA678
LA5E3:
        push ds
        push si
        call near ptr __flush
        add sp,04h
        mov di,ax
        mov bx,si
        sub bx,offset DGROUP:__iob
        mov ax,word ptr [bx+__iob2+4]
        mov [bp-02h],ax
        push ds
        push si
        call near ptr __freebuf
        add sp,04h
        mov al,[si+0Bh]
        sub ah,ah
        push ax
        call far ptr __close
        add sp,02h
        or ax,ax
        jl short LA675
        cmp word ptr [bp-02h],00h
        jz short LA678
        push ds
        push offset DGROUP:CRTTempPrefix
        lea cx,[bp-0Ch]
        push ss
        push cx
        call far ptr _strcpy
        add sp,08h
        lea ax,[bp-0Ah]
        mov [bp-010h],ax
        mov word ptr [bp-0Eh],ss
        cmp byte ptr [bp-0Ch],05Ch
        jz short LA64E
        push ds
        push offset DGROUP:CRTPathSep
        lea ax,[bp-0Ch]
        push ss
        push ax
        call far ptr _strcat
        add sp,08h
        jmp short LA651
        nop
LA64E:
        dec word ptr [bp-010h]
LA651:
        db 06Ah,10             ; push imm8; MASM otherwise emits imm16
        push word ptr [bp-0Eh]
        push word ptr [bp-010h]
        push word ptr [bp-02h]
        call far ptr __itoa
        add sp,08h
        lea ax,[bp-0Ch]
        push ss
        push ax
        call far ptr __unlink
        add sp,04h
        or ax,ax
        jz short LA678
LA675:
        mov di,0FFFFh
LA678:
        mov byte ptr [si+0Ah],00h
LA67C:
        mov ax,di
        pop si
        pop di
        leave
        retf
_fclose endp
_TEXT ends
        end
