DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f0ch
dos_umb_flag db 1
 org 0f1dh
files db 8
fcbs db 4
 db 0
num_cds db 5
 org 0f3dh
default_num_cds db 26
 org 1639h
IFDEF DOS7_CONFIG
        push    cs
        pop     ds
        assume  ds:sysinitseg
        cmp     byte ptr [dos_umb_flag],0
        je      umb_defaults_done
        mov     al,1
        mov     [p_buffers_high],al
        mov     [p_ldrv_high],al
        mov     [p_fcbs_high],al
        mov     [p_files_high],al
        mov     [stack_high],al
        mov     byte ptr [files],30
        mov     word ptr [fcbs],4       ; also clears KEEP
        mov     al,[default_num_cds]
        mov     [num_cds],al
umb_defaults_done:
ENDIF
 ret
 org 648eh
p_buffers_high db 0
 org 6524h
p_files_high db 0
 org 655ch
p_fcbs_high db 0
 org 6572h
p_ldrv_high db 0
 org 65ach
stack_high db 0
sysinitseg ends
end
