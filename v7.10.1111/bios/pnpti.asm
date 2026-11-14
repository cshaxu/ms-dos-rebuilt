;** PNPTI.ASM - No arguments. Return firmware capability probe status.
;
; FAR C entry: No arguments. Return firmware capability probe status.
; Preserve firmware signatures, service selectors, ports and return codes.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
; No registry state dependencies.
_DATA ends
DGROUP group _DATA
PNPTI segment word public 'CODE'
        assume cs:PNPTI,ds:DGROUP
        public ConfigProbeTI

ConfigProbeTI proc far
        push bp
        mov bp,sp
        sub sp,02h
        push di
        push si
        mov ax,0F963h
        mov bx,04954h
        push ds
        push si
        push di
        int 015h
        pop di
        pop si
        pop ds
        cmp bx,05449h
        jz short ti_loc_026
        mov ax,07FFFh
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
ti_loc_026:
        mov ax,0F95Fh
        int 015h
        or ah,ah
        jnz short ti_loc_04D
        cmp word ptr es:[bx],0Ch
        jl short ti_loc_04D
        test word ptr es:[bx+0Ah],080h
        jnz short ti_loc_056
        test word ptr es:[bx+018h],08h
        jnz short ti_loc_056
        test word ptr es:[bx+0Ah],0200h
        jnz short ti_loc_056
ti_loc_04D:
        xor ax,ax
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
ti_loc_056:
        mov ax,0FB00h
        int 015h
        cmp ah,086h
        jz short ti_loc_078
        mov cx,02h
        test al,02h
        jnz short ti_loc_06C
        inc cx
        test al,01h
        jz short ti_loc_078
ti_loc_06C:
        mov [bp-02h],cx
        mov ax,[bp-02h]
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ti_loc_078:
        mov ax,01h
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigProbeTI endp
        even
PNPTI ends
        end
