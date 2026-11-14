bufinsiz equ 14h
Bios_Data segment at 70h
 org 0fch
disksector_ptr dd 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f05h
disksector_pending_size dw 200h
 org 0f3eh
bios_data_segment dw 70h
 org 0feah
memhi dw 0
 org 3b88h
pararound proc near
 ret
pararound endp
 org 3c1bh
relocate_disksector proc near
        assume  ds:sysinitseg
        mov     ax,[disksector_pending_size]
        test    ax,ax
        jz      disksector_done
        mov     bx,[memhi]
        inc     bx
        .286
        shl     bx,4
        .8086
        add     bx,ax
        jnc     short disksector_alloc
        jnz     disksector_done
disksector_alloc:
        call    pararound
        mov     bx,4800h
        call    alloc_marked_block
        sub     ax,ax
        mov     [disksector_pending_size],ax
        push    ds
        mov     ds,[bios_data_segment]
        assume  ds:Bios_Data
        mov     word ptr [disksector_ptr],bufinsiz
        mov     word ptr [disksector_ptr+2],cx
        pop     ds
        assume  ds:sysinitseg
disksector_done:
        ret
relocate_disksector endp
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
