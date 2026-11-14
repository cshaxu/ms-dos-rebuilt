CONFIG_DEVICE equ 'D'
CONFIG_DEVICEHIGH equ 'U'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 6a0ah
multi_pass_device:
        cmp     ah,CONFIG_DEVICE
        jne     multi_pass_devicehigh
        jmp     near ptr tryd
multi_pass_devicehigh:
        cmp     ah,CONFIG_DEVICEHIGH
        jne     multi_pass_filter
        jmp     near ptr tryu
 org 6a6bh
multi_pass_filter:
 ret
 org 6ca8h
tryu:
 ret
 org 6d32h
tryd:
 ret
sysinitseg ends
end
