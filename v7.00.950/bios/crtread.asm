;** CRTREAD.ASM - DOS C runtime text and binary input
;
; C entry: file handle, far buffer, byte count.
; Returns byte count or -1 through the shared DOS error handler.
_DATA segment word public 'DATA'
        extrn __nfile:word,__osfile:byte
        extrn ___aDBswpflg:word,___aDBswpchk:word
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        extrn __dosretax:near
        public __read
__read proc far
        push bp
        mov bp,sp
        sub sp,02h
        mov bx,[bp+06h]
        cmp bx,__nfile
        jc short read_015
        stc
        mov ax,0900h
        jmp short read_088
read_015:
        xor ax,ax
        mov cx,[bp+0Ch]
        jcxz short read_088
        test byte ptr __osfile[bx],02h
        jnz short read_088
        cmp word ptr ___aDBswpflg,0D6D6h
        jnz short read_02F
        call word ptr ___aDBswpchk
read_02F:
        mov cx,[bp+0Ch]
        push ds
        lds dx,[bp+08h]
        mov ah,03Fh
        int 021h
        pop ds
        jnc short read_041
        mov ah,09h
        jmp short read_088
read_041:
        test byte ptr __osfile[bx],080h
        jz short read_088
        and byte ptr __osfile[bx],0FBh
        push si
        push di
        push ds
        pop es
        assume es:DGROUP
        mov ds,word ptr [bp+0Ah]
        cld
        mov si,dx
        mov di,dx
        mov cx,ax
        jcxz short read_084
        mov ah,0Dh
        cmp byte ptr [si],0Ah
        jnz short read_06A
        or byte ptr es:__osfile[bx],04h
read_06A:
        lodsb
        db 038h,0E0h            ; cmp al,ah; compiler r/m8,r8 form
        jz short read_08B
        cmp al,01Ah
        jnz short read_07B
        or byte ptr es:__osfile[bx],02h
        jmp short read_080
read_07B:
        mov [di],al
        inc di
read_07E:
        loop read_06A
read_080:
        mov ax,di
        sub ax,dx
read_084:
        push es
        pop ds
read_086:
        pop di
        pop si
read_088:
        jmp __dosretax
read_08B:
        cmp cx,01h
        jz short read_097
        cmp byte ptr [si],0Ah
        jz short read_07E
        jmp short read_07B
read_097:
        push es
        pop ds
        test byte ptr __osfile[bx],040h
        jz short read_0BC
        mov ax,04400h
        int 021h
        test dx,020h
        jnz short read_0B8
        push ds
        push ss
        pop ds
        lea dx,[bp-01h]
        mov ah,03Fh
        int 021h
        pop ds
        jc short read_086
read_0B8:
        mov al,0Ah
        jmp short read_0EC
read_0BC:
        push ds
        push ss
        pop ds
        mov byte ptr [bp-01h],00h
        lea dx,[bp-01h]
        mov ah,03Fh
        int 021h
        pop ds
        jc short read_086
        or ax,ax
        jz short read_0EA
        cmp word ptr [bp+0Ch],01h
        jz short read_0F6
read_0D7:
        mov cx,0FFFFh
        mov dx,cx
        mov ax,04201h
        int 021h
        mov cx,01h
        cmp byte ptr [bp-01h],0Ah
        jz short read_0F1
read_0EA:
        mov al,0Dh
read_0EC:
        lds dx,[bp+08h]
        jmp short read_07B
read_0F1:
        lds dx,[bp+08h]
        jmp short read_07E
read_0F6:
        cmp byte ptr [bp-01h],0Ah
        jnz short read_0D7
        jmp short read_0B8
__read endp
_TEXT ends
        end
