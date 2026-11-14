;** PNPIBM.ASM - No arguments. Return firmware capability probe status.
;
; FAR C entry: No arguments. Return firmware capability probe status.
; Preserve firmware signatures, service selectors, ports and return codes.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
; No registry state dependencies.
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
        jc short ibm_loc_020
        or ah,ah
        jnz short ibm_loc_020
        mov ax,es:[bx+02h]
        mov [bp-04h],al
        mov [bp-06h],ah
        cmp byte ptr [bp-04h],0F8h
        jz short ibm_loc_028
ibm_loc_020:
        mov ax,07FFFh
        mov sp,bp
        pop bp
        ret
        nop
ibm_loc_028:
        mov al,[bp-06h]
        sub ah,ah
        sub ax,05Dh
        jl short ibm_loc_020
        jo short ibm_loc_020
        dec ax
        jng short ibm_loc_040
        dec ax
        dec ax
        jl short ibm_loc_020
        sub ax,04h
        jg short ibm_loc_020
ibm_loc_040:
        cmp byte ptr [bp-06h],060h
        ja short ibm_loc_062
        mov ax,05101h
        int 015h
        jc short ibm_loc_090
        or ah,ah
        jnz short ibm_loc_090
        or al,al
        jz short ibm_loc_090
        add ax,01h
        mov [bp-02h],ax
ibm_loc_05B:
        mov ax,[bp-02h]
        mov sp,bp
        pop bp
        ret
ibm_loc_062:
        cli
        pushf
        cld
        mov al,0FDh
        out 094h,al
        mov cx,0100h
ibm_loc_06C:
        nop
        loop ibm_loc_06C
        mov dx,0100h
        in al,dx
        mov cx,0100h
ibm_loc_076:
        nop
        loop ibm_loc_076
        mov bl,al
        mov al,0FFh
        out 094h,al
        popf
        sti
        cmp bl,0FFh
        jz short ibm_loc_090
        xor bh,bh
        add bx,02h
        mov [bp-02h],bx
        jmp short ibm_loc_05B
ibm_loc_090:
        mov ax,01h
        mov sp,bp
        pop bp
        ret
ConfigProbeIBM endp
        even
PNPIBM ends
        end
