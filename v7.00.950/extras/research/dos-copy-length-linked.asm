sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 0f0eh
dos_image_size dw 0c000h
dos_image_paras dw 0c00h
 org 1115h
        mov     cx,cs:[dos_image_size]
        shr     cx,1
        rep     movsw
        adc     cx,cx
        rep     movsb
sysinitseg ends
end
