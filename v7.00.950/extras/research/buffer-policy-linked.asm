sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f0ch
dos_umb_flag db 0
 org 0f17h
buffers dw 0
h_buffers dw 0
singlebuffersize dw 0
 org 321ch
badfil proc near
 ret
badfil endp
 org 3816h
; Determine the default buffer count and limit it to the available HMA.
        mov     cx,[buffers]
        cmp     cx,-1
        je      buffer_default
        mov     ax,cx
        mul     [singlebuffersize]
        test    dx,dx
        jz      buffer_check_size
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+104]
        call    badfil
buffer_default:
        mov     cx,30
        mov     [h_buffers],0
        cmp     byte ptr [dos_umb_flag],0
        je      buffer_save_count
        mov     ax,4a01h
        int     2fh
        xchg    ax,bx
        or      ax,ax
        jz      buffer_save_count
        sub     ax,0c00h
        jbe     buffer_save_count
        sub     dx,dx
        div     [singlebuffersize]
        inc     cx
        cmp     ax,cx
        jae     buffer_save_count
        xchg    ax,cx
        shr     ax,1
        cmp     cx,ax
        jae     buffer_save_count
        add     ax,ax
        xchg    ax,cx
buffer_save_count:
        mov     [buffers],cx
buffer_check_size:
        mov     ax,[singlebuffersize]
        mul     cx
        or      dx,dx
        jz      buffer_count_done
        mov     dx,1
        xor     ax,ax
        div     [singlebuffersize]
        mov     [buffers],ax
        xchg    ax,cx
buffer_count_done:
 org 0a568h
sysinit_msg_table dw 65 dup (0)
sysinit_msg_base label byte
sysinitseg ends
end
