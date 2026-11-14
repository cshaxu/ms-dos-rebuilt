sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 0f40h
BCodeSeg dw 0
 org 0fe6h
area dw 0
 org 175dh
IFDEF DOS7_CONFIG
; Recover unused space following a relocated extended BIOS data area.
        .286
recover_ebda proc near
        push    cs
        pop     ds
        cmp     [config_ebda_limit],-1
        je      short ebda_abort
        mov     ax,40h
        mov     es,ax
        mov     cx,es:[0eh]
        stc
        jcxz    ebda_abort
        cmp     ch,98h
        jae     short ebda_check_bios
ebda_abort:
        jmp     ebda_done
ebda_check_bios:
        mov     ah,0c1h
        stc
        int     15h
        jc      short ebda_check_memory
        mov     ax,es
        cmp     ax,cx
        jne     ebda_abort
ebda_check_memory:
        int     12h
        shl     ax,6
        cmp     ax,cx
        jne     ebda_abort
        mov     dx,0a000h
        sub     dx,cx
        shl     dx,4
        cmp     dx,400h
        ja      ebda_abort
        jne     short ebda_use_all
        mov     bx,cs:[config_ebda_limit]
        cmp     bx,dx
        jae     short ebda_use_all
        mov     es,cx
        mov     di,bx
        mov     cx,dx
        sub     cx,di
        cld
        xor     al,al
        repe    scasb
        je      short ebda_allocate
ebda_use_all:
        mov     bx,dx
ebda_allocate:
        push    bx
        push    dx
        shr     bx,4
        mov     ax,bx
        mov     bx,5200h
        call    alloc_marked_block
        pop     dx
        pop     bx
        cli
        push    ds
        mov     ax,40h
        mov     ds,ax
        mov     es,cx
        xchg    cx,word ptr ds:[0eh]
        mov     ds,cx
        mov     cx,bx
        xor     si,si
        xor     di,di
        cld
        rep     movsb
        mov     cx,ds
        pop     ds
        sti
        mov     bx,es
        xor     di,di
        mov     es,di
        dec     di
        dec     di
ebda_vector_next:
        add     di,4
        cmp     di,200h
        ja      short ebda_find_arena
        cmp     es:[di],cx
        jne     ebda_vector_next
        cmp     di,0c2h
        je      ebda_vector_next
        cmp     di,0c6h
        je      ebda_vector_next
        mov     es:[di],bx
        jmp     short ebda_vector_next
ebda_find_arena:
        mov     ax,cs:[area]
        dec     ax
ebda_arena_next:
        mov     es,ax
        inc     ax
        add     ax,es:[3]
        cmp     byte ptr es:[0],5ah
        jne     ebda_arena_next
        cmp     ax,cx
        jne     short ebda_done
        shr     dx,4
        add     es:[3],dx
        shr     dx,6
        mov     ax,40h
        mov     es,ax
        add     es:[13h],dx
        mov     es,cs:[BCodeSeg]
        mov     es:[5f8h],dx
ebda_done:
        ret
recover_ebda endp
        .8086
ENDIF

 org 5ad7h
config_ebda_limit dw 400h
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
