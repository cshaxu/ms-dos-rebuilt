sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f52h
multi_pass_id db 0
 org 16a7h
        inc     cs:multi_pass_id
        call    multi_pass
        inc     cs:multi_pass_id
        call    boot_process_drivers
 org 4each
boot_process_drivers proc near
 ret
boot_process_drivers endp
 org 692dh
multi_pass proc near
 ret
multi_pass endp
sysinitseg ends
end
