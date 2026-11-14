; CONFIG$ dispatch, isolated placement experiment.
include biosseg.inc
Bios_Data segment
        extrn config_flags:byte,config_value:word,bios_flags:word
Bios_Data ends
SysInitSeg segment
        extrn config_init_entry:far
SysInitSeg ends
Bios_Code segment word public 'Bios_Code'
        assume cs:Bios_Code,ds:Bios_Data
        extrn bc_cmderr:near,sysinit_seg:word
        public config_table
config_alloc_mask equ 8000h
config_table label byte
	db	13
	dw	config_done,config_done,config_done,config_read
	dw	bc_cmderr,bc_cmderr,config_done,config_done
	dw	bc_cmderr,bc_cmderr,bc_cmderr,bc_cmderr
	dw	config_init

;
; Read the CONFIG$ status into the caller's buffer.
; CX = buffer length, ES:DI -> buffer.
;
config_read proc near
	jcxz	config_done
	cmp	cx,5
	jb	config_done
	push	es
	push	di
	xor	ax,ax
	cld
	stosw
	test	config_flags,1
	jz	config_store
	mov	ax,config_value
config_store:
	stosw
	mov	al,config_flags
	stosb
	pop	di
	pop	es
config_read endp

config_done proc near
	clc
	ret
config_done endp

	.286
config_init proc near
	test	bios_flags,config_alloc_mask
	jz	config_init_done
	push	cs
	push	offset config_init_done
	jmp	short config_init_call
config_init_done:
	clc
	ret
config_init_call:
	push	cs:sysinit_seg
	push	offset config_init_entry
	retf
config_init endp
Bios_Code ends
        end
