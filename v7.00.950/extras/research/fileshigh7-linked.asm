CONFIG_FILESHIGH equ 'f'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 6524h
p_files_high db 0
 org 7270h
parse_files:
 ret
 org 729bh
try_fileshigh:
        cmp     ah,CONFIG_FILESHIGH
        jne     tryl
        call    query_user
        jc      tryl
        mov     byte ptr cs:[p_files_high],1
        jmp     short parse_files
tryl:
 ret
sysinitseg ends
end
