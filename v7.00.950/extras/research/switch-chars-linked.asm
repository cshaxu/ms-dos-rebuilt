char_oper equ 37h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 1439h
        mov     ax,(char_oper shl 8)
        int     21h
        mov     [default_switch_char],dl
        mov     [command_line+2],dl
        mov     [command_line2+2],dl
        mov     [command_line3+2],dl
 org 448ch
default_switch_char db 0
 org 44deh
command_line db 3,' /P'
 org 45ach
command_line2 db 3,' /P'
 org 467ah
command_line3 db 3,' /P'
sysinitseg ends
end
