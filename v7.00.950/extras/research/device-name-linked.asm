sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 4240h
; Names used to recognize the Adaptec real-mode drivers.
        public  aspi2dos_loaded,aspi2hlp_loaded
aspi2dos_loaded db      0
aspi2hlp_loaded db      0
aspi2dos_name   db      '\ASPI2DOS.SYS',0
aspi2hlp_name   db      '\ASPI2HLP.SYS',0


 org 6738h
config_record_name db 11 dup (0)
 org 88c8h
config_record_name_from_path proc near
        push    si
        push    cs
        pop     es
        mov     di,offset config_record_name
        mov     cx,11
        mov     al,' '
        cld
        rep     stosb
config_find_end:
        lodsb
        or      al,al
        jnz     config_find_end
config_find_start:
        dec     si
        cmp     dx,si
        ja      short config_name_start
        cmp     byte ptr [si],'\'
        je      short config_name_start
        cmp     byte ptr [si],':'
        jne     config_find_start
config_name_start:
        inc     si
        call    config_check_aspi
        mov     cx,8
        mov     di,offset config_record_name
        call    config_copy_name
config_find_extension:
        or      al,al
        jz      short config_name_done
        cmp     al,'.'
        je      short config_copy_extension
        lodsb
        jmp     short config_find_extension
config_copy_extension:
        mov     cx,3
        mov     di,offset config_record_name+8
        call    config_copy_name
config_name_done:
        pop     si
        ret
config_record_name_from_path endp

config_copy_name proc near
config_copy_name_loop:
        lodsb
        or      al,al
        jz      short config_copy_name_done
        cmp     al,'.'
        je      short config_copy_name_done
        stosb
        loop    config_copy_name_loop
config_copy_name_done:
        ret
config_copy_name endp

config_check_aspi proc near
        push    si
        mov     di,offset aspi2dos_name+1
        mov     cx,12
        repe    cmpsb
        jne     short config_check_aspi2
        mov     byte ptr cs:[aspi2dos_loaded],1
        jmp     short config_check_aspi_done
config_check_aspi2:
        pop     si
        push    si
        mov     di,offset aspi2hlp_name+1
        mov     cx,12
        repe    cmpsb
        jne     short config_check_aspi_done
        mov     byte ptr cs:[aspi2hlp_loaded],1
config_check_aspi_done:
        pop     si
        ret
config_check_aspi endp

sysinitseg ends
end
