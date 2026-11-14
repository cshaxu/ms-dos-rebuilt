;** PNPLF.ASM - No arguments. Return firmware capability probe status.
;
; FAR C entry: No arguments. Return firmware capability probe status.
; Preserve firmware signatures, service selectors, ports and return codes.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
; No registry state dependencies.
_DATA ends
DGROUP group _DATA
PNPLF segment word public 'CODE'
        assume cs:PNPLF,ds:DGROUP
        public ConfigProbeLF

ConfigProbeLF proc far
        push bp
        mov bp,sp
        sub sp,04h
        push si
        mov word ptr [bp-04h],0FF92h
        mov word ptr [bp-02h],0F000h
        mov ax,0F000h
        mov es,ax
        mov si,0FF90h
        cmp word ptr es:[si],04C46h
        jnz short lf_loc_03E
        mov ax,0200h
        call dword ptr [bp-04h]
        jc short lf_loc_046
        cmp ah,08h
        jc short lf_loc_046
        cmp al,014h
        jc short lf_loc_046
        mov ax,0800h
        call dword ptr [bp-04h]
        or ax,ax
        jnz short lf_loc_046
        jmp short lf_loc_04E
        nop
lf_loc_03E:
        mov ax,07FFFh
        pop si
        mov sp,bp
        pop bp
        ret
lf_loc_046:
        xor ax,ax
        pop si
        mov sp,bp
        pop bp
        ret
        nop
lf_loc_04E:
        mov ax,0314h
        call dword ptr [bp-04h]
        or ax,ax
        jnz short lf_loc_046
        cmp bh,01h
        jnz short lf_loc_046
        cmp bl,01h
        jz short lf_loc_06A
        mov ax,01h
        pop si
        mov sp,bp
        pop bp
        ret
lf_loc_06A:
        mov ax,02h
        pop si
        mov sp,bp
        pop bp
        ret
ConfigProbeLF endp
PNPLF ends
        end
