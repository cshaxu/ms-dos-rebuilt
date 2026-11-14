;** PNPLF.ASM - Query the LF firmware interface.
;
; FAR C entry; no arguments. Check the ROM signature and interface
; version before querying configuration. Return the probe result in AX:
; 7FFFh if absent, 0 if unsupported, otherwise 1 or 2.
;
_DATA segment word public 'DATA'
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
        jnz short lf_not_found
        mov ax,0200h
        call dword ptr [bp-04h]
        jc short lf_unsupported
        cmp ah,08h
        jc short lf_unsupported
        cmp al,014h
        jc short lf_unsupported
        mov ax,0800h
        call dword ptr [bp-04h]
        or ax,ax
        jnz short lf_unsupported
        jmp short lf_query_configuration
        nop
lf_not_found:
        mov ax,07FFFh
        pop si
        mov sp,bp
        pop bp
        ret
lf_unsupported:
        xor ax,ax
        pop si
        mov sp,bp
        pop bp
        ret
        nop
lf_query_configuration:
        mov ax,0314h
        call dword ptr [bp-04h]
        or ax,ax
        jnz short lf_unsupported
        cmp bh,01h
        jnz short lf_unsupported
        cmp bl,01h
        jz short lf_result_two
        mov ax,01h
        pop si
        mov sp,bp
        pop bp
        ret
lf_result_two:
        mov ax,02h
        pop si
        mov sp,bp
        pop bp
        ret
ConfigProbeLF endp
PNPLF ends
        end
