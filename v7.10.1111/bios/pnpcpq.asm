;** PNPCPQ.ASM - No arguments. Return firmware capability probe status.
;
; FAR C entry: No arguments. Return firmware capability probe status.
; Preserve firmware signatures, service selectors, ports and return codes.
; Local instruction flow follows the target; final layout is linked.
;
        extrn _strncmp:far
_DATA segment word public 'DATA'
        extrn PnPCompaqName:byte
_DATA ends
DGROUP group _DATA
PNPCPQ segment word public 'CODE'
        assume cs:PNPCPQ,ds:DGROUP
        public ConfigProbeCompaq

ConfigProbeCompaq proc far
        push bp
        mov bp,sp
        sub sp,02h
        mov ax,06h
        push ax
        mov ax,offset DGROUP:PnPCompaqName
        push ds
        push ax
        mov ax,0FFEAh
        mov dx,0F000h
        push dx
        push ax
        call _strncmp
        add sp,0Ah
        or ax,ax
        jz short cpq_loc_02A
        mov ax,07FFFh
        mov sp,bp
        pop bp
        ret
cpq_loc_02A:
        mov ax,0E800h
        int 015h
        mov [bp-02h],bx
        jnc short cpq_loc_03A
cpq_loc_034:
        xor ax,ax
        mov sp,bp
        pop bp
        ret
cpq_loc_03A:
        mov ax,[bp-02h]
        cmp ax,0DCh
        jz short cpq_loc_071
        ja short cpq_loc_05E
        cmp ax,0D8h
        jz short cpq_loc_071
        ja short cpq_loc_034
        sub al,054h
        jc short cpq_loc_034
        sub al,01h
        jna short cpq_loc_071
        sub al,07Bh
        jc short cpq_loc_034
        sub al,01h
        jna short cpq_loc_071
        jmp short cpq_loc_034
        nop
cpq_loc_05E:
        cmp ax,0FCh
        jz short cpq_loc_071
        ja short cpq_loc_034
        sub al,0E8h
        jc short cpq_loc_034
        sub al,02h
        jna short cpq_loc_071
        sub al,02h
        jnz short cpq_loc_034
cpq_loc_071:
        mov dx,01C65h
        in al,dx
        test al,020h
        jz short cpq_loc_080
        mov ax,01h
        mov sp,bp
        pop bp
        ret
cpq_loc_080:
        mov ax,02h
        mov sp,bp
        pop bp
        ret
ConfigProbeCompaq endp
        even
PNPCPQ ends
        end
