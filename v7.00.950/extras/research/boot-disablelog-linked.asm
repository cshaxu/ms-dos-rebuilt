Bios_Code segment at 1d5h
 org 2b76h
exec_bios_word dw ?
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f40h
BCodeSeg dw 1d5h
 org 5839h
; Store the DISABLELOG option in the BIOS startup state.
boot_option_disablelog proc near
        lodsb
        cmp     al,'='
        jne     boot_option_error
        call    boot_option_number
        jc      boot_option_error
        push    ds
        mov     ds,[BCodeSeg]
        assume  ds:Bios_Code
        mov     byte ptr [exec_bios_word-1],al
        pop     ds
        assume  ds:sysinitseg
        ret
boot_option_disablelog endp
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
