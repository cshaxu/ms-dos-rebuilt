Bios_Data segment at 70h
 org 140h
cdev dd 0
 org 16ch
bios_hook_1 dd 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f40h
BCodeSeg dw 0
 org 1bedh
; Update the BIOS data entry vectors after moving BIOS code.
; AX is the new BIOS code segment.
reinit_bios_code proc near
        push    di
        push    es
        mov     cs:[BCodeSeg],ax
        mov     cx,Bios_Data
        mov     es,cx
        mov     di,offset cdev
        mov     cx,offset bios_hook_1
        sub     cx,di
        .286
        shr     cx,2
        .8086
        cmp     byte ptr cs:[config_hook_active],0
        je      short reinit_bios_next
        dec     cx
reinit_bios_next:
        inc     di
        inc     di
        stosw
        loop    reinit_bios_next
        pop     es
        pop     di
        ret
reinit_bios_code endp

 org 6841h
config_hook_active db 0
sysinitseg ends
end
