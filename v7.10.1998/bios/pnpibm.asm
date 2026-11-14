;** PNPIBM.ASM - Query IBM firmware capabilities.
;
; FAR C entry; no arguments. Select the BIOS service or adapter probe
; for the model and submodel. Return the probe result in AX, or 7FFFh
; when the model is not recognized.
;
_DATA segment word public 'DATA'
_DATA ends
DGROUP group _DATA
PNPIBM segment word public 'CODE'
        assume cs:PNPIBM,ds:DGROUP
        public ConfigProbeIBM

ConfigProbeIBM proc far
        push bp
        mov bp,sp
        sub sp,06h
        mov ah,0C0h
        int 015h
        jc short ibm_unknown_model
        or ah,ah
        jnz short ibm_unknown_model
        mov ax,es:[bx+02h]
        mov [bp-04h],al
        mov [bp-06h],ah
        cmp byte ptr [bp-04h],0F8h
        jz short ibm_check_submodel
ibm_unknown_model:
        mov ax,07FFFh
        mov sp,bp
        pop bp
        ret
        nop
ibm_check_submodel:
        mov al,[bp-06h]
        sub ah,ah
        sub ax,05Dh
        jl short ibm_unknown_model
        jo short ibm_unknown_model
        dec ax
        jng short ibm_query_capabilities
        dec ax
        dec ax
        jl short ibm_unknown_model
        sub ax,04h
        jg short ibm_unknown_model
ibm_query_capabilities:
        cmp byte ptr [bp-06h],060h
        ja short ibm_probe_adapter
        mov ax,05101h
        int 015h
        jc short ibm_default_result
        or ah,ah
        jnz short ibm_default_result
        or al,al
        jz short ibm_default_result
        add ax,01h
        mov [bp-02h],ax
ibm_return_result:
        mov ax,[bp-02h]
        mov sp,bp
        pop bp
        ret
ibm_probe_adapter:
        cli
        pushf
        cld
        mov al,0FDh
        out 094h,al
        mov cx,0100h
ibm_delay_select:
        nop
        loop ibm_delay_select
        mov dx,0100h
        in al,dx
        mov cx,0100h
ibm_delay_read:
        nop
        loop ibm_delay_read
        mov bl,al
        mov al,0FFh
        out 094h,al
        popf
        sti
        cmp bl,0FFh
        jz short ibm_default_result
        xor bh,bh
        add bx,02h
        mov [bp-02h],bx
        jmp short ibm_return_result
ibm_default_result:
        mov ax,01h
        mov sp,bp
        pop bp
        ret
ConfigProbeIBM endp
        even
PNPIBM ends
        end
