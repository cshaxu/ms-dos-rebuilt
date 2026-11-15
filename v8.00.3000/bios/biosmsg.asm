Bios_Code	segment word public 'Bios_Code'
	assume	cs:Bios_Code
	public	BCode_end,bios_msg_descriptor

; Message resource status returned by the BIOS multiplex handler.
bios_msg_descriptor dw	4 dup (0),-1,0
BCode_end:
	include	..\lang\usa\messages\biosmsg.inc

; BIOS message resource trailer and reserved message area.
bios_msg_end	label byte
bios_msg_trailer label byte
	db	'IOSYSMSG'
	dw	bios_msg_trailer - bios_msg_count
	rept	144
	db	'MPAD'
	endm

Bios_Code	ends
	end
