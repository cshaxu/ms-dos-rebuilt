multMULT equ 4ah
multMULTALLOCHMA7 equ 3
devmark_buf equ 42h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f17h
buffers dw 0
 org 0f1bh
singlebuffersize dw 0
 org 3caeh
GetBufferAddr7 proc near
        push    bx
        mov     ax,cs:[singlebuffersize]
        mul     word ptr cs:[buffers]
        add     ax,15
        and     ax,not 15
        xchg    ax,bx
        mov     ax,(multMULT shl 8)+multMULTALLOCHMA7
        mov     dl,1
        mov     cx,-6
        int     2fh
        cmp     di,-1
        jne     short buffer7_done
        .286
        shr     bx,4
        .8086
        push    ds
        push    cs
        pop     ds
        assume  ds:sysinitseg
        mov     ax,bx
        mov     bh,devmark_buf
        mov     bl,[p_buffers_high]
        call    alloc_marked_block
        mov     es,cx
        xor     di,di
        pop     ds
        assume  ds:nothing
buffer7_done:
        pop     bx
        ret
GetBufferAddr7 endp
 org 648eh
p_buffers_high db 0
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
