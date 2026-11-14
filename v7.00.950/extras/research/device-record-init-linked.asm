sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
  org 0f16h
default_drive db 0
 org 0f1bh
singlebuffersize dw 0
 org 0feeh
drivenumber db 0
 org 1338h
        push    cs
        pop     ds
        mov     ax,es:[di+10h]
        add     ax,14h
        mov     [singlebuffersize],ax
        mov     al,[default_drive]
        mov     es:[di+43h],al
        mov     ax,cs
        sub     ax,11h
        sub     ax,111h
        mov     word ptr [config_record_ptr+2],ax
        push    ax
        mov     al,es:[di+20h]
        mov     [drivenumber],al
        pop     ax
 org 6732h
config_record_ptr dd 0
sysinitseg ends
end
