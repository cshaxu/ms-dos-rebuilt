devmark_cds equ 'L'
sysi_ncds equ 21h
sysi_cds equ 16h
sysi_dpb equ 0
curdir_list struc
 db 58h dup(?)
curdir_list ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0eebh
dosinfo dd 0
 org 0f20h
num_cds db 5
 org 35c4h
fooset proc near
 ret
fooset endp
 org 38c9h
        push    cs
        pop     ds
        assume  ds:sysinitseg
        call    relocate_disksector
        mov     al,[num_cds]
        push    ax
        mov     ah,size curdir_list
        mul     ah
        call    pararound
        mov     bh,devmark_cds
        mov     bl,[p_ldrv_high]
        call    alloc_marked_block
        les     si,[dosinfo]
        pop     ax
        mov     es:[si.sysi_ncds],al
        mov     word ptr es:[si.sysi_cds+2],cx
        xor     di,di
        mov     word ptr es:[si.sysi_cds],di
        lds     si,es:[si.sysi_dpb]
        assume  ds:nothing
        mov     es,cx
        mov     cl,al
        xor     ch,ch
        call    fooset
        push    cs
        pop     ds
        assume  ds:sysinitseg
 org 3b88h
pararound proc near
 ret
pararound endp
 org 3c1bh
relocate_disksector proc near
 ret
relocate_disksector endp
 org 6572h
p_ldrv_high db 0
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
