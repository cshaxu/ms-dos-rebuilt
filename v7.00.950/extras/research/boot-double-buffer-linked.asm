sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 3375h
query_mode_flags db 0
 org 42c9h
boot_driver_entry1 db 11h
 org 42ddh
boot_driver_entry2 db 11h
 org 4bd6h
; Check the double-buffer provider and select the driver record types.
boot_double_provider proc near
        push    bx
        push    di
        push    es
        mov     ax,4a10h
        mov     bx,5
        int     2fh
        pop     es
        pop     di
        pop     bx
        cmp     ax,0babeh
        je      boot_double_done
        test    byte ptr [query_mode_flags],1
        je      boot_double_mode
        mov     byte ptr [boot_driver_entry1],11h
        mov     byte ptr [boot_driver_entry2],11h
        ret
boot_double_mode:
        cmp     byte ptr [exec_mode],0
boot_double_done:
        ret
boot_double_provider endp
 org 0a09bh
exec_mode db 0
sysinitseg ends
end
