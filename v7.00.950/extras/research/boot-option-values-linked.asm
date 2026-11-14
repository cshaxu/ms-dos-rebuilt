sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 4060h
boot_delay dw 0
 org 4068h
boot_config_name db 32 dup (0)
 org 57fbh
; Copy an option value through CR, terminating the result with zero.
; DS:SI addresses the value, ES:DI the destination, CX its capacity.
boot_option_copy proc near
boot_copy_next:
        lodsb
        stosb
        cmp     al,0dh
        loopne  boot_copy_next
        mov     byte ptr [di-1],0
        ret
boot_option_copy endp
 org 5826h
; Store BOOTDELAY if it is no greater than 3600 seconds.
boot_option_delay proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        call    boot_option_number
        jc      boot_option_error
        cmp     ax,3600
        ja      boot_option_error
        mov     word ptr ds:[boot_delay],ax
        ret
boot_option_delay endp
 org 584dh
; Store the selected BOOTCONFIG name.
boot_option_config proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        mov     cx,32
        mov     di,offset boot_config_name
        jmp     boot_option_copy
boot_option_config endp
 org 5870h
boot_option_error proc near
 ret
boot_option_error endp
 org 5a80h
boot_option_number proc near
 ret
boot_option_number endp
sysinitseg ends
end
