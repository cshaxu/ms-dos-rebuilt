sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f42h
boot_load_segment dw 0
 dw 0
boot_reloc_segment dw 0
 org 115eh
; Place the boot image in the reserved space following the BIOS.
        mov     ax,di
        call    pararound
        mov     di,es
        add     di,ax
        mov     cs:[compressed_dest_segment],di
        mov     cx,cs:[compressed_reserve]
        mov     cs:[compressed_reserved_paras],cx
        mov     cx,cs:[boot_load_segment]
        jcxz    boot_move_done
        cmp     cx,cs:[compressed_reserve]
        ja      boot_move_done
        sub     si,si
        mov     ds,cs:[boot_reloc_segment]
        mov     es,di
        sub     di,di
        mov     cs:[boot_reloc_segment],es
        mov     ax,cx
boot_move_block:
        mov     cx,1000h
        cmp     cx,ax
        jb      short boot_move_size_ready
        mov     cx,ax
boot_move_size_ready:
        sub     ax,cx
        .286
        shl     cx,3
        .8086
        rep     movsw
        mov     cx,ds
        add     cx,1000h
        mov     ds,cx
        mov     cx,es
        add     cx,1000h
        mov     es,cx
        test    ax,ax
        jnz     boot_move_block
boot_move_done:
 org 3b88h
pararound proc near
 ret
pararound endp
 org 8aa1h
compressed_reserve dw 0
 dd 0
compressed_dest_segment dw 0
compressed_reserved_paras dw 0
sysinitseg ends
end
