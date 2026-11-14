sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0ef3h
device_list dd 0
 org 0f48h
memory_size dw 0
 org 11e1h
; Prepare the DOS initialization workspace below the boot sector.
        sub     ax,ax
        mov     es,ax
        mov     di,600h
        push    di
        mov     cx,80h
        rep     stosw
        pop     di
        mov     cx,5
dosinit_con_entry:
        mov     ax,4f43h
        stosw
        mov     ax,204eh
        stosw
        add     di,37h
        loop    dosinit_con_entry
        lds     si,cs:[device_list]
        mov     dx,cs:[memory_size]
sysinitseg ends
end
