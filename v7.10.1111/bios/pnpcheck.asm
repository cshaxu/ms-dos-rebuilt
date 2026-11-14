;** PNPCHECK.ASM - Reject incompatible PnP BIOS entry points.
;
; FAR C entry: FAR pointer to the PnP BIOS installation header.
; Compare the entry code with the two known incompatible signatures.
; Return AX = 1 to reject the entry, AX = 0 otherwise; restore DS from SS.
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
        jc short check_reject
        mov ds,dx
        mov bx,ax
        cmp byte ptr [bx],0E9h
        jnz short check_first_signature
        mov ax,[bx+01h]
        add ax,03h
        add [bp-04h],ax
check_first_signature:
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
        jnz short check_second_signature
        sub cx,ax
        repe cmpsb
check_second_signature:
        jz short check_reject
        mov ax,[bp-04h]
        mov dx,ss
        mov cx,08h
        mov di,offset DGROUP:PnPBadEntry2
        mov si,ax
        mov es,dx
        xor ax,ax
        repe cmpsb
        jz short check_compare_result
        sbb ax,ax
        sbb ax,0FFFFh
check_compare_result:
        or ax,ax
        jz short check_reject
        xor ax,ax
        jmp short check_return
        nop
check_reject:
        mov ax,01h
check_return:
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
