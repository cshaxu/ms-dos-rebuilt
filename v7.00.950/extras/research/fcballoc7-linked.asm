devmark_fcbs equ 'X'
sflink equ 0
sfcount equ 4
sf_ref_count equ 0
sf_position equ 15h
sysi_fcb equ 1ah
sysi_keep equ 1eh
sf_entry struc
 db 3bh dup(?)
sf_entry ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 0eebh
dosinfo dd 0
 org 0f1eh
fcbs db 4
 org 37bbh
        push cs
        pop ds
        assume  ds:sysinitseg
        mov     al,[fcbs]
        xor     ah,ah
        push    ax
        mov     bl,size sf_entry
        mul     bl
        add     ax,6
        call    pararound
        mov     bh,devmark_fcbs
        mov     bl,[p_fcbs_high]
        call    alloc_marked_block
        mov     es,cx
        xor     di,di
        mov     word ptr es:[di+sflink],-1
        pop     cx
        mov     es:[di+sfcount],cx
        mov     al,'A'
        add     di,6
fcb7_fillloop:
        push    cx
        mov     cx,size sf_entry
        cld
        rep     stosb
        mov     word ptr es:[di-(size sf_entry)+sf_ref_count],0
        mov     word ptr es:[di-(size sf_entry)+sf_position],0
        mov     word ptr es:[di-(size sf_entry)+sf_position+2],0
        pop     cx
        loop    fcb7_fillloop
        lds     di,[dosinfo]
        assume  ds:nothing
        xor     ax,ax
        mov     word ptr [di+sysi_fcb],ax
        mov     word ptr [di+sysi_fcb+2],es
        mov     [di+sysi_keep],ax
        push    cs
        pop     ds
        assume  ds:sysinitseg
 org 3b88h
pararound proc near
 ret
pararound endp
 org 655ch
p_fcbs_high db 0
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
