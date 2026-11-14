Bios_Code	segment para public 'Bios_Code'
	assume	cs:Bios_Code
	public	BCode_end
BCode_end:
	include	..\lang\usa\messages\biosmsg.inc

; BIOS message resource trailer and reserved message area.
bios_msg_trailer label byte
	db	'IOSYSMSG'
	dw	bios_msg_trailer - bios_msg_count
	rept	99
	db	'MPAD'
	endm

Bios_Code	ends
	end
