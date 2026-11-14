sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 0f12h
sysinit_memory_size dw 1
RPLMemTop dw 0
 org 0f48h
memory_size dw 1
 org 1005h
        mov     cx,cs:[memory_size]
        push    cs
        pop     ds
        assume  ds:sysinitseg
        mov     [sysinit_memory_size],cx
        dec     cx
        cmp     [RPLMemTop],0
        je      short dos7_memory_ready
        mov     cx,[RPLMemTop]
        dec     cx
dos7_memory_ready:
sysinitseg ends
end
