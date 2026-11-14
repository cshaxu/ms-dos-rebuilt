;** PNPCAPS.ASM - Query firmware configuration capabilities.
;
; FAR C entry: two FAR output pointers, initially cleared to zero.
; Query PnP BIOS service 5; if no PnP BIOS is found, try each entry
; in PnPProbeTable until a probe supplies a result or the table ends.
;
        extrn ConfigProbeCompaq:far,ConfigProbeToshiba:far,ConfigProbeLF:far,ConfigProbeTI:far,ConfigProbeIBM:far
_DATA segment word public 'DATA'
        extrn PnPProbeTable:dword
_DATA ends
DGROUP group _DATA
CFGPNP segment word public 'CODE'
        assume cs:CFGPNP,ds:DGROUP
        extrn ConfigFindPnPBIOS:far
        public ConfigGetCapabilities

ConfigGetCapabilities proc far
        push bp
        mov bp,sp
        sub sp,0Eh
        push di
        push si
        mov si,[bp+0Ah]
        les bx,[bp+06h]
        sub ax,ax
        mov es:[bx+02h],ax
        mov es:[bx],ax
        mov es,word ptr [bp+0Ch]
        mov es:[si+02h],ax
        mov es:[si],ax
        push cs
        call near ptr ConfigFindPnPBIOS
        mov di,ax
        mov [bp-02h],dx
        or dx,ax
        jz short caps_probe_firmware
        mov es,word ptr [bp-02h]
        push word ptr es:[di+01Bh]
        lea ax,[bp-0Eh]
        push ss
        push ax
        mov ax,05h
        push ax
        call dword ptr es:[di+0Dh]
        add sp,08h
        cmp ax,089h
        jz short caps_copy_info
        jna short caps_check_status
        jmp caps_exit
caps_check_status:
        or al,al
        jz short caps_copy_info
        sub al,087h
        jz short caps_no_info
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
caps_copy_info:
        mov ax,[bp-0Ch]
        or ax,[bp-0Eh]
        jnz short caps_store_info
        mov word ptr [bp-0Eh],0FFF0h
        mov word ptr [bp-0Ch],0FFFFh
caps_store_info:
        mov ax,[bp-0Eh]
        mov dx,[bp-0Ch]
        les bx,[bp+06h]
        mov es:[bx],ax
        mov es:[bx+02h],dx
        mov ax,[bp-0Ah]
        mov dx,[bp-08h]
        mov es,word ptr [bp+0Ch]
        mov es:[si],ax
        mov es:[si+02h],dx
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
caps_no_info:
        mov es,word ptr [bp+0Ch]
        mov word ptr es:[si],01h
        mov word ptr es:[si+02h],00h
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
caps_probe_firmware:
        mov bx,offset DGROUP:PnPProbeTable
        mov di,bx
        mov word ptr [bp-02h],ds
        mov ax,[bx+02h]
        or ax,[bx]
        jz short caps_exit
caps_probe_next:
        mov es,word ptr [bp-02h]
        call dword ptr es:[di]
        mov si,ax
        cmp si,07FFFh
        jz short caps_advance_probe
        or si,ax
        jz short caps_exit
        cmp si,01h
        jz short caps_set_default
        cmp si,02h
        jc short caps_advance_probe
        cmp si,07FFEh
        jna short caps_set_result
caps_advance_probe:
        add di,04h
        mov es,word ptr [bp-02h]
        mov ax,es:[di+02h]
        or ax,es:[di]
        jnz short caps_probe_next
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
caps_set_default:
        les bx,[bp+0Ah]
        mov word ptr es:[bx],01h
        jmp short caps_clear_high
caps_set_result:
        les bx,[bp+0Ah]
        mov es:[bx],si
caps_clear_high:
        mov word ptr es:[bx+02h],00h
caps_exit:
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigGetCapabilities endp
CFGPNP ends
        end
