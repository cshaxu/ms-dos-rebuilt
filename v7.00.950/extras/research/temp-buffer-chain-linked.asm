sysi_buf equ 12h
Dirty_Buff_Count equ 4
Buff_Queue equ 0
buf_next equ 0
buf_prev equ 2
buf_id equ 4
buf_sector equ 6
curdir_list struc
 db 58h dup(?)
curdir_list ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 0f1bh
singlebuffersize dw 0
 org 0f21h
confbot dw 0
alloclim dw 0
top_of_cdss dw 0
 org 0f4ah
temp_buffer_segment dw 0
temp_buffer_size dw 4014h
 org 135fh
; Allocate and link the temporary DOS disk buffers.
        mov     cx,[temp_buffer_size]
        .286
        shr     cx,4
        .8086
        inc     cx
        sub     ax,cx
        mov     [top_of_cdss],ax
        push    es
        push    di
        mov     [temp_buffer_segment],ax
        mov     cx,ax
        sub     ax,((26 * (size curdir_list)) + 15)/16
        mov     [alloclim],ax
        mov     [confbot],ax
        lds     si,es:[di.sysi_buf]
        assume  ds:nothing
        mov     word ptr [si.Dirty_Buff_Count],0
        mov     word ptr [si.Buff_Queue],0
        mov     word ptr [si.Buff_Queue+2],cx
        mov     ds,cx
        xor     si,si
        mov     ax,cs:[temp_buffer_size]
        sub     dx,dx
        mov     bx,cs:[singlebuffersize]
        div     bx
        xchg    ax,cx
temp_buffer_loop:
        mov     [si.buf_next],bx
        mov     [si.buf_prev],dx
        mov     word ptr [si.buf_id],00ffh
        mov     word ptr [si.buf_sector],0
        mov     word ptr [si.buf_sector+2],0
        mov     dx,si
        mov     si,bx
        add     bx,cs:[singlebuffersize]
        loop    temp_buffer_loop
        mov     bx,dx
        mov     [bx.buf_next],cx
        mov     word ptr ds:[2],bx
sysinitseg ends
end
