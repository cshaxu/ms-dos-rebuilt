devmark_files equ 'F'
sflink equ 0
sfcount equ 4
sysi_sft equ 4
sf_entry struc
 db 3bh dup(?)
sf_entry ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 0eebh
dosinfo dd 0
 org 377bh
        assume  ds:sysinitseg
        xor     ah,ah
        push    ax
        mov     bl,size sf_entry
        mul     bl
        add     ax,6
        call    pararound
        mov     bh,devmark_files
        mov     bl,[p_files_high]
        call    alloc_marked_block
        mov     es,cx
        xor     di,di
        mov     cx,ax
        .286
        shl     cx,4
        .8086
        mov     word ptr es:[di+sflink],-1
        pop     ax
        mov     es:[di+sfcount],ax
        xor     ax,ax
        add     di,6
        sub     cx,6
        cld
        rep     stosb
        lds     di,[dosinfo]
        assume  ds:nothing
        lds     di,[di+sysi_sft]
        mov     [di+sflink],ax
        mov     [di+sflink+2],es
 org 3b88h
pararound proc near
 ret
pararound endp
 org 6524h
p_files_high db 0
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
