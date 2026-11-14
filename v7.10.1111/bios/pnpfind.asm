;** PNPFIND.ASM - No arguments. Scan ROM installation structures and validate checksums.
;
; FAR C entry: No arguments. Scan ROM installation structures and validate checksums.
; Original ROM scan, signature checks and DS restoration are preserved.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
; No registry state dependencies.
_DATA ends
DGROUP group _DATA
CFGPNP segment word public 'CODE'
        assume cs:CFGPNP,ds:DGROUP
        extrn ConfigRejectPnPEntry:far
        public ConfigFindPnPBIOS

ConfigFindPnPBIOS proc far
        push bp
        mov bp,sp
        sub sp,0Ch
        push di
        push si
        mov word ptr [bp-06h],00h
        mov word ptr [bp-04h],0F000h
find_loc_012:
        les di,[bp-06h]
        cmp word ptr es:[di],05024h
        jnz short find_loc_024
        cmp word ptr es:[di+02h],0506Eh
        jz short find_loc_028
find_loc_024:
        push ss
        pop ds
        jmp short find_loc_067
find_loc_028:
        xor al,al
        mov [bp-07h],al
        mov cx,es
        mov si,di
        mov ds,cx
        cmp [di+05h],al
        jz short find_loc_04F
        mov al,es:[di+05h]
        mov [bp-01h],al
        mov word ptr [bp-0Ah],es
find_loc_042:
        mov bx,si
        inc si
        mov al,[bx]
        add [bp-07h],al
        dec byte ptr [bp-01h]
        jnz short find_loc_042
find_loc_04F:
        push ss
        pop ds
        cmp byte ptr [bp-07h],00h
        jnz short find_loc_067
        mov word ptr [bp-0Ah],es
        push es
        push di
        push cs
        call near ptr ConfigRejectPnPEntry
        add sp,04h
        or ax,ax
        jz short find_loc_078
find_loc_067:
        add word ptr [bp-06h],010h
        adc word ptr [bp-04h],00h
        cmp word ptr [bp-04h],0F001h
        jc short find_loc_012
        jmp short find_loc_084
find_loc_078:
        mov ax,di
        mov dx,[bp-0Ah]
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
find_loc_084:
        xor ax,ax
        cwd
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigFindPnPBIOS endp
        even
CFGPNP ends
        end
