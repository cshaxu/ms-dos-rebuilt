bufinsiz equ 14h
cache_ptr equ 6
cache_count equ 0ah
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f19h
h_buffers dw 0
singlebuffersize dw 0
 org 3893h
        call    set_buffer
        cmp     [h_buffers],0
        jz      xif16
        push    ds
        push    bx
        mov     ax,cs:[singlebuffersize]
        sub     ax,bufinsiz
        mul     word ptr cs:[h_buffers]
        call    pararound
        push    cs
        pop     ds
        assume  ds:sysinitseg
        mov     bx,4200h
        call    alloc_marked_block
        pop     bx
        pop     ds
        assume  ds:nothing
        mov     word ptr ds:[bx.cache_ptr+2],cx
        mov     word ptr ds:[bx.cache_ptr],0
        mov     cx,cs:[h_buffers]
        mov     ds:[bx.cache_count],cx
xif16:
 ret
 org 3b88h
pararound proc near
 ret
pararound endp
 org 3c4fh
set_buffer proc near
 ret
set_buffer endp
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
