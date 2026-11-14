; Rotate boot log, isolated target-layout experiment.
Bios_Code segment word public 'Bios_Code'
        assume  cs:Bios_Code,ds:Bios_Code
        org     2B50h
log_name        db      'C:\BOOTLOG.TXT',0
old_log_name    db      'C:\BOOTLOG.PRV',0
log_rotate      db      1
log_flags       dw      2041h
        org     2CF4h
rotate_bootlog proc near
        push    es
        mov     dx,offset old_log_name
        mov     ah,41h
        int     21h
        mov     dx,offset log_name
        mov     di,offset old_log_name
        push    cs
        pop     es
        mov     ah,56h
        int     21h
        jnc     rotate_exit
        cmp     al,2
        jnz     rotate_exit
        or      log_flags,4000h
rotate_exit:
        pop     es
        ret
rotate_bootlog endp
Bios_Code ends
        end     rotate_bootlog
