sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1a65h
; Return Z if an XMS manager is installed.
boot_check_xms proc near
        mov     ax,4300h
        int     2fh
        cmp     al,80h
        ret
boot_check_xms endp
 org 4240h
aspi2dos_loaded db 0
aspi2hlp_loaded db 0
 org 4299h
boot_ifshlp_name db 'IFS$HLP$',0
boot_setver_name db 'SETVERXX',0
 org 4c01h
; Return the combined ASPI driver state in the condition codes.
boot_check_aspi proc near
        cmp     byte ptr [aspi2dos_loaded],0
        je      boot_aspi_done
        cmp     byte ptr [aspi2hlp_loaded],1
boot_aspi_done:
        ret
boot_check_aspi endp

; Check whether the named startup device is present.
boot_check_ifshlp proc near
        mov     dx,offset boot_ifshlp_name
        jmp     short boot_check_device
boot_check_ifshlp endp

boot_check_setver proc near
        mov     dx,offset boot_setver_name
boot_check_setver endp

boot_check_device proc near
        push    bx
        push    dx
        mov     dl,1
        mov     ax,3307h
        int     21h
        pop     dx
        mov     ax,3d00h
        int     21h
        jc      boot_check_device_done
        xchg    ax,bx
        mov     ah,3eh
        int     21h
boot_check_device_done:
        sbb     ax,ax
        pop     bx
        ret
boot_check_device endp
sysinitseg ends
end
