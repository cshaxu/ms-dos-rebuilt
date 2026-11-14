;** PNPTI.ASM - Query Texas Instruments firmware capabilities.
;
; FAR C entry; no arguments. Check the BIOS signature and capability
; flags, then query the current state. Return the probe result in AX:
; 7FFFh if absent, 0 if unsupported, otherwise 1, 2 or 3.
;
_DATA segment word public 'DATA'
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
        jz short ti_query_capabilities
        mov ax,07FFFh
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
ti_query_capabilities:
        mov ax,0F95Fh
        int 015h
        or ah,ah
        jnz short ti_unsupported
        cmp word ptr es:[bx],0Ch
        jl short ti_unsupported
        test word ptr es:[bx+0Ah],080h
        jnz short ti_query_state
        test word ptr es:[bx+018h],08h
        jnz short ti_query_state
        test word ptr es:[bx+0Ah],0200h
        jnz short ti_query_state
ti_unsupported:
        xor ax,ax
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
ti_query_state:
        mov ax,0FB00h
        int 015h
        cmp ah,086h
        jz short ti_default_result
        mov cx,02h
        test al,02h
        jnz short ti_return_result
        inc cx
        test al,01h
        jz short ti_default_result
ti_return_result:
        mov [bp-02h],cx
        mov ax,[bp-02h]
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ti_default_result:
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
