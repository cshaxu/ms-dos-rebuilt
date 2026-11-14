REGOLD segment word public 'CODE'
        assume cs:REGOLD
        public RegOldNameSum
RegOldNameSum proc far
        push bp
        mov bp,sp
        sub sp,6
        sub ax,ax
        mov [bp-2],ax
        mov [bp-4],ax
        jmp short rns_test
rns_char:
        cmp al,80h
        jnc short rns_test
        cmp al,'a'
        jc short rns_plain
        cmp al,'z'
        ja short rns_plain
        sub ah,ah
        sub ax,20h
        cwd
        jmp short rns_add
rns_plain:
        mov al,[bp-6]
        sub ah,ah
        sub dx,dx
rns_add:
        add [bp-4],ax
        adc [bp-2],dx
rns_test:
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov al,es:[bx]
        mov [bp-6],al
        or al,al
        jnz short rns_char
        mov ax,[bp-4]
        mov dx,[bp-2]
        mov sp,bp
        pop bp
        ret
RegOldNameSum endp
REGOLD ends
        end
