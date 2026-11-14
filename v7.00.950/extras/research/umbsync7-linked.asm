Bios_Data segment at 70h
 org 8
bios_flags dw 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 0f0ch
dos_umb_flag db 1
 org 7682h
pd_umb_sync:
        push    ds
        mov     ax,Bios_Data
        mov     ds,ax
        assume  ds:Bios_Data
        and     byte ptr [bios_flags+1],not 10h
        cmp     byte ptr cs:[dos_umb_flag],0
        je      pd_umb_done
        or      byte ptr [bios_flags+1],10h
pd_umb_done:
        pop     ds
        assume  ds:nothing
        ret
sysinitseg ends
end
