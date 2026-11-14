sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 6844h
config_file_time dw 0
config_file_date dw 0
 org 6908h
        push    ax
        push    cx
        push    dx
        mov     ax,5700h                ; get CONFIG.SYS date and time
        int     21h
        mov     [config_file_time],cx
        mov     [config_file_date],dx
        pop     dx
        pop     cx
        mov     ah,3eh
        int     21h
        pop     ax
        popf
 org 878fh
        mov     bx,cs:[config_file_time]
        mov     dx,cs:[config_file_date]
sysinitseg ends
end
