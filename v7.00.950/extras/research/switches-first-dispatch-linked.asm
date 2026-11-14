CONFIG_DEVICE equ 'D'
CONFIG_DEVICEHIGH equ 'U'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f52h
multi_pass_id db 0
 org 69b9h
tryi:
	cmp	multi_pass_id,0		; the initial pass for DOS=HI
	jne	not_init_pass

        cmp     ah,CONFIG_DEVICE
        je      short scan_qemm_device
        cmp     ah,CONFIG_DEVICEHIGH
        je      short scan_qemm_device
        jmp     multi_try_doshi
scan_qemm_device:
        call    config_check_qemm
        jmp     multi_pass_coff

not_init_pass: ret
 org 6a82h
multi_pass_coff: ret
 org 6bddh
multi_try_doshi: ret
 org 8a30h
config_check_qemm proc near
 ret
config_check_qemm endp
sysinitseg ends
end
