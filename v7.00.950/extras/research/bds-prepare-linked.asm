Bios_Data segment at 70h
 org 0f8h
start_bds dd 0
disksector_ptr dd 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 35eh
fdrive1 db 0
 org 0each
bds_count dw 0
dskdrvs dw 26 dup (0)
 org 0f3eh
bios_data_segment dw 70h
 org 1080h
        push    di
        push    cs
        pop     ds
        assume  ds:sysinitseg
        push    cs
        pop     es
        mov     bx,offset dskdrvs
        mov     di,offset fdrive1-6
        sub     dx,dx
bds_prepare_next:
        inc     [bds_count]
        mov     word ptr [di+2],cs
        lea     ax,[di+6]
        mov     [bx],ax
        add     bx,2
        mov     ax,[di]
        cmp     ax,-1
        je      bds_prepare_done
        sub     ax,dx
        mov     si,ax
        sub     ax,di
        sub     ax,100
        jbe     bds_prepare_link
        add     dx,ax
        push    di
        add     di,100
        mov     cx,offset dskdrvs
        sub     cx,si
        rep     movsb
        pop     di
bds_prepare_link:
        sub     [di],dx
        mov     di,[di]
        jmp     short bds_prepare_next
bds_prepare_done:
        mov     ds,[bios_data_segment]
        assume  ds:Bios_Data
        mov     word ptr [start_bds+2],cs
        pop     di
        mov     word ptr [disksector_ptr],di
        mov     word ptr [disksector_ptr+2],es
        assume  ds:nothing
sysinitseg ends
end
