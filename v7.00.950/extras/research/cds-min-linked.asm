sysi_numio equ 20h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0eebh
dosinfo dd 0
 org 0f20h
num_cds db 0
 org 36b4h
        call    relocate_disksector
        les     di,[dosinfo]
        mov     al,es:[di.sysi_numio]
        cmp     al,[num_cds]
        jae     short cds_count_ready
        mov     al,[num_cds]
cds_count_ready:
        mov     [num_cds],al
 org 3c1bh
relocate_disksector proc near
 ret
relocate_disksector endp
sysinitseg ends
end
