sysinitseg segment para public 'code'
 assume cs:sysinitseg
sysinit$ label byte
 org 11d7h
        cli
        mov     ax,cs
        mov     ss,ax
locstack =      (offset $ - offset sysinit$ + 5) and 0fffeh
        mov     sp,locstack
        nop
        sti
sysinitseg ends
end
