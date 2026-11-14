Bios_Data segment at 70h
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0eefh
dos_temp_location dd 0
 org 1209h
        mov     bx,Bios_Data
        mov     ax,0505h
        call    cs:[dos_temp_location]
        mov     word ptr cs:[config_access_table],bx
        mov     word ptr cs:[config_access_table+2],es
 org 5acah
config_access_table dd 0
config_envlen dw 0
config_wrkseg dw 0
sysinitseg ends
end
