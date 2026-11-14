Bios_Data segment at 70h
 org 0f8h
start_bds dd 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 35eh
fdrive1 db 0
 org 0each
bds_count dw 0
 org 0f0ch
dos_umb_flag db 0
 org 0f3eh
bios_data_segment dw 70h
 org 3664h
; Move the BDS array and repair links that point into the old array.
        mov     ax,[bds_count]
        mov     bl,100
        mul     bl
        push    ax
        call    pararound
        mov     bh,'G'
        mov     bl,[dos_umb_flag]
        call    alloc_marked_block
        mov     es,cx
        pop     cx
        mov     si,offset fdrive1-6
        sub     di,di
        rep     movsb
        mov     bx,di
        sub     di,di
        mov     ax,cs
bds_relocate_link:
        cmp     word ptr es:[di],-1
        je      bds_next_link
        cmp     word ptr es:[di+2],ax
        jne     bds_next_link
        sub     word ptr es:[di],offset fdrive1-6
        mov     word ptr es:[di+2],es
bds_next_link:
        add     di,100
        cmp     di,bx
        jb      bds_relocate_link
        push    ds
        mov     ds,[bios_data_segment]
        assume  ds:Bios_Data
        mov     word ptr [start_bds],0
        mov     word ptr [start_bds+2],es
        pop     ds
        assume  ds:sysinitseg
 org 3b88h
pararound proc near
 ret
pararound endp
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
