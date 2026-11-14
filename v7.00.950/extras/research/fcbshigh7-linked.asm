CONFIG_FCBSHIGH equ 'x'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 655ch
p_fcbs_high db 0
 org 748ch
parse_fcbs:
 ret
 org 74c2h
try_fcbshigh:
        cmp     ah,CONFIG_FCBSHIGH
        jne     try1
        call    query_user
        jc      try1
        mov     byte ptr cs:[p_fcbs_high],1
        jmp     short parse_fcbs
try1:
 ret
sysinitseg ends
end
