;** PNPCHECK.ASM - FAR PnP BIOS header. Check known incompatible entry signatures.
;
; FAR C entry: FAR PnP BIOS header. Check known incompatible entry signatures.
; Original ROM scan, signature checks and DS restoration are preserved.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
        extrn PnPBadEntry1:byte
        extrn PnPBadEntry2:byte
_DATA ends
DGROUP group _DATA
CFGPNP segment word public 'CODE'
        assume cs:CFGPNP,ds:DGROUP
        public ConfigRejectPnPEntry

ConfigRejectPnPEntry proc far
        push bp
        mov bp,sp
        sub sp,04h
        push di
        push si
        lds si,[bp+06h]
        mov ax,[si+013h]
        mov dx,[si+015h]
        shr dx,1
        rcr ax,1
        rcr dx,1
        rcr ax,1
        rcr dx,1
        rcr ax,1
        rcr dx,1
        rcr ax,1
        rcr dx,1
        xchg ax,dx
        and ax,0F000h
        add ax,[si+011h]
        adc dx,00h
        mov [bp-04h],ax
        cmp byte ptr [si+05h],021h
        jc short check_loc_08A
        mov ds,dx
        mov bx,ax
        cmp byte ptr [bx],0E9h
        jnz short check_loc_048
        mov ax,[bx+01h]
        add ax,03h
        add [bp-04h],ax
check_loc_048:
        mov ax,[bp-04h]
        mov dx,ss
        mov cx,0Ch
        mov di,offset DGROUP:PnPBadEntry1
        mov si,ax
        mov es,dx
        shr cx,1
        sbb ax,ax
        cmp cx,cx
        repe cmpsw
        jnz short check_loc_065
        sub cx,ax
        repe cmpsb
check_loc_065:
        jz short check_loc_08A
        mov ax,[bp-04h]
        mov dx,ss
        mov cx,08h
        mov di,offset DGROUP:PnPBadEntry2
        mov si,ax
        mov es,dx
        xor ax,ax
        repe cmpsb
        jz short check_loc_081
        sbb ax,ax
        sbb ax,0FFFFh
check_loc_081:
        or ax,ax
        jz short check_loc_08A
        xor ax,ax
        jmp short check_loc_08D
        nop
check_loc_08A:
        mov ax,01h
check_loc_08D:
        push ss
        pop ds
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigRejectPnPEntry endp
        even
CFGPNP ends
        end
