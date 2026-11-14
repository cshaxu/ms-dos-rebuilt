;** PNPCPQ.ASM - Query Compaq firmware capabilities.
;
; FAR C entry; no arguments. Check the ROM name and supported models,
; then read the configuration port. Return the probe result in AX:
; 7FFFh if not Compaq, 0 if unsupported, otherwise 1 or 2.
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
        jz short cpq_query_model
        mov ax,07FFFh
        mov sp,bp
        pop bp
        ret
cpq_query_model:
        mov ax,0E800h
        int 015h
        mov [bp-02h],bx
        jnc short cpq_check_model
cpq_unsupported:
        xor ax,ax
        mov sp,bp
        pop bp
        ret
cpq_check_model:
        mov ax,[bp-02h]
        cmp ax,0DCh
        jz short cpq_read_configuration
        ja short cpq_newer_models
        cmp ax,0D8h
        jz short cpq_read_configuration
        ja short cpq_unsupported
        sub al,054h
        jc short cpq_unsupported
        sub al,01h
        jna short cpq_read_configuration
        sub al,07Bh
        jc short cpq_unsupported
        sub al,01h
        jna short cpq_read_configuration
        jmp short cpq_unsupported
        nop
cpq_newer_models:
        cmp ax,0FCh
        jz short cpq_read_configuration
        ja short cpq_unsupported
        sub al,0E8h
        jc short cpq_unsupported
        sub al,02h
        jna short cpq_read_configuration
        sub al,02h
        jnz short cpq_unsupported
cpq_read_configuration:
        mov dx,01C65h
        in al,dx
        test al,020h
        jz short cpq_result_two
        mov ax,01h
        mov sp,bp
        pop bp
        ret
cpq_result_two:
        mov ax,02h
        mov sp,bp
        pop bp
        ret
ConfigProbeCompaq endp
        even
PNPCPQ ends
        end
