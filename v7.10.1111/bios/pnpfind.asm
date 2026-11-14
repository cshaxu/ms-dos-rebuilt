;** PNPFIND.ASM - Find a usable PnP BIOS installation header.
;
; FAR C entry; no arguments. Scan paragraph boundaries in the ROM,
; check the signature and checksum, then reject incompatible entries.
; Return the header address in DX:AX, or zero if none; DS is restored from SS.
;
_DATA segment word public 'DATA'
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
find_scan:
        les di,[bp-06h]
        cmp word ptr es:[di],05024h
        jnz short find_next_signature
        cmp word ptr es:[di+02h],0506Eh
        jz short find_checksum
find_next_signature:
        push ss
        pop ds
        jmp short find_advance
find_checksum:
        xor al,al
        mov [bp-07h],al
        mov cx,es
        mov si,di
        mov ds,cx
        cmp [di+05h],al
        jz short find_checksum_done
        mov al,es:[di+05h]
        mov [bp-01h],al
        mov word ptr [bp-0Ah],es
find_checksum_byte:
        mov bx,si
        inc si
        mov al,[bx]
        add [bp-07h],al
        dec byte ptr [bp-01h]
        jnz short find_checksum_byte
find_checksum_done:
        push ss
        pop ds
        cmp byte ptr [bp-07h],00h
        jnz short find_advance
        mov word ptr [bp-0Ah],es
        push es
        push di
        push cs
        call near ptr ConfigRejectPnPEntry
        add sp,04h
        or ax,ax
        jz short find_found
find_advance:
        add word ptr [bp-06h],010h
        adc word ptr [bp-04h],00h
        cmp word ptr [bp-04h],0F001h
        jc short find_scan
        jmp short find_not_found
find_found:
        mov ax,di
        mov dx,[bp-0Ah]
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
find_not_found:
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
