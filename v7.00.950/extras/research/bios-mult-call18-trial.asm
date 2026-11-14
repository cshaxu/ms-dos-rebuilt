; INT 2Fh multiplex close service, isolated layout experiment.
Bios_Code segment word public 'Bios_Code'
        assume  cs:Bios_Code
        org     2B71h
log_handle      dw      -1
log_open_count  dw      0
        org     2CA6h
mult_call18 proc near
        mov     ax,cs:log_open_count
        dec     ax
        js      close_exit
        mov     cs:log_open_count,ax
        jnz     close_exit
        mov     bx,cs:log_handle
        mov     ah,3Eh
        int     21h
        mov     cs:log_handle,-1
        jc      close_exit
        xor     ax,ax
close_exit:
        ret
mult_call18 endp
Bios_Code ends
        end     mult_call18
