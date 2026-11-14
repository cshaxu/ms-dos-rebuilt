; BIOS message resource.
; All offsets are relative to bios_msg_base.

	public	bios_msg_base,bios_swap_msg_first,bios_swap_msg_second
	public	bios_msg_1,bios_msg_2,bios_msg_3

bios_msg_count		dw	5
bios_msg_header_size	dw	14h
bios_msg_version	dw	100h
bios_msg_resource_size	dw	1a2h
bios_swap_msg_first	dw	0
bios_swap_msg_second	dw	1dh
bios_msg_1		dw	3fh
bios_msg_2		dw	0a8h
bios_msg_3		dw	141h
bios_msg_resource_end	dw	18eh

bios_msg_base	label	byte
	db	13,10,"Insert diskette for drive ",0
	db	" and press any key when ready",13,10,13,10,0
	db	13,10,"Your program caused a divide overflow error.",13,10
	db	"If the problem persists, contact your program vendor.",13,10,"$",0
	db	"Windows has disabled direct disk access to protect your long filenames.",13,10
	db	"To override this protection, see the LOCK /? command for more information.",13,10,13,10,"$",0
	db	"The system has been halted.  Press Ctrl+Alt+Del to restart your computer.",13,10,"$",0
