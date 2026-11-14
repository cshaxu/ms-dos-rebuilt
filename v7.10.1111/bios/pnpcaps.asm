;** PNPCAPS.ASM - FAR output pointers. Query PnP BIOS or fallback firmware probes.
;
; FAR C entry: FAR output pointers. Query PnP BIOS or fallback firmware probes.
; PnP service five, then ordered firmware probes with zero terminator.
; Local instruction flow follows the target; final layout is linked.
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
        jz short caps_loc_0AA
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
        jz short caps_loc_05E
        jna short caps_loc_04F
        jmp caps_loc_106
caps_loc_04F:
        or al,al
        jz short caps_loc_05E
        sub al,087h
        jz short caps_loc_096
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
caps_loc_05E:
        mov ax,[bp-0Ch]
        or ax,[bp-0Eh]
        jnz short caps_loc_070
        mov word ptr [bp-0Eh],0FFF0h
        mov word ptr [bp-0Ch],0FFFFh
caps_loc_070:
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
caps_loc_096:
        mov es,word ptr [bp+0Ch]
        mov word ptr es:[si],01h
        mov word ptr es:[si+02h],00h
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
caps_loc_0AA:
        mov bx,offset DGROUP:PnPProbeTable
        mov di,bx
        mov word ptr [bp-02h],ds
        mov ax,[bx+02h]
        or ax,[bx]
        jz short caps_loc_106
caps_loc_0B9:
        mov es,word ptr [bp-02h]
        call dword ptr es:[di]
        mov si,ax
        cmp si,07FFFh
        jz short caps_loc_0DB
        or si,ax
        jz short caps_loc_106
        cmp si,01h
        jz short caps_loc_0F0
        cmp si,02h
        jc short caps_loc_0DB
        cmp si,07FFEh
        jna short caps_loc_0FA
caps_loc_0DB:
        add di,04h
        mov es,word ptr [bp-02h]
        mov ax,es:[di+02h]
        or ax,es:[di]
        jnz short caps_loc_0B9
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
caps_loc_0F0:
        les bx,[bp+0Ah]
        mov word ptr es:[bx],01h
        jmp short caps_loc_100
caps_loc_0FA:
        les bx,[bp+0Ah]
        mov es:[bx],si
caps_loc_100:
        mov word ptr es:[bx+02h],00h
caps_loc_106:
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigGetCapabilities endp
CFGPNP ends
        end
