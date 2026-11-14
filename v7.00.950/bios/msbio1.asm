;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160
	title	msbio1.asm - Bios_Data definition and device driver entry/exit

;
;----------------------------------------------------------------------------
;
; Modification history
;
; M001 : BIOS used to local enable a20 before calling original int 13 fn
;        and local disable a20 after the int 13 call. This created some
;        problems with disk caching programs which do lazy reads (PC-Kwik)
;	 Now BIOS turns a20 on if it is off and leaves it on after the
;	 int 13 call
;
; M028 : Added INT 10 to the list of interrupt vectors to be restored
;	 at INT 19 time.
;
; M033 : BIOS was setting the EOT in DPT to its desired value and then
;	 wrongly resetting it to 9 after it job. Now it saves the EOT
;	 before setting & resets it to the old value.
;
; M036 : Added VDISK header clearing code at INT 19 & CTRL ALT DEL
;
; M041 : Saving & restoring A20 status for all transitions from HMA
;	 to Lomem & vice versa in INT 13 handler. For PCKWIK
;
; M058 : Bug #4925. Changed Orig13 offset to 70:b4 so that people like CMS,
;	ProComm who patch it directly will work.
;
; M059 : Bug #5002. Treat rollover byte as a count instead of a flag, if
;			t_switch is not set.
;
;
; M064 : Bug #5070. Ensure that A20 is enabled before entering Device driver
;		entry point in HMA. And do not try to preserve A20 status
;		across INT 13 calls (support norton cache).
;
;
; M073 : Add far code pointers in power.asm to seg_reinit list.
;
; M084 : Remove IOCTL support for built-in POWER$ 
;
; M097 : B#2958. Define endfloppy label after ROMDRIVE & POWER code, so that we
;	  do not overwrite ROMDRIVE and POWER on a harddiskless system
;
;----------------------------------------------------------------------------
;
	include version.inc	; set build flags
	include biosseg.inc	; define BIOS segments

	include	devsym.inc
	include	msequ.inc
	include	bpb.inc
	include	bootform.inc
	include	msbds.inc

;SR;
; Assembly conditional for stack switching
;
STACKSW		equ	1

Bios_Data	segment

	assume	cs:Bios_Data
	public	BData_start
BData_start:

	assume	ds:nothing,es:nothing

	public	hdrv_pat
hdrv_pat label	word			; patched by msinit
	assume	cs:Bios_Data

	extrn	init:near		; this is in msinit

	jmp	init			; go to initialization code

;	define some stuff that is also used by msdos.sys from an include file

In_Bios	=	0ffffh	; define flag for msbdata.inc
	include	oemconf.inc
	public	dosdatasg,bios_i2f,bios_flags,romstartaddr,altah
DosDataSg	dw	09e46h		; initial value, reset by init
bios_i2f proc far
	jmp	near ptr int_2f
bios_i2f endp
bios_flags dw 10dch
	public	a20_mask,changeline_mask,single_drive_mask,setowner_mask
	public	k09_mask,int19_init_mask,multrk_mask,format_multitrk_mask
	public	multrk_configured_mask
	public	cmos_clock_mask,rollover_flag_mask
	public	win386_mask,keyboard_hook_mask,config_alloc_mask
a20_mask	equ	01h
changeline_mask equ	02h
single_drive_mask equ	04h
setowner_mask	equ	08h
k09_mask	equ	10h
cmos_clock_mask equ	20h
win386_mask	equ	40h
rollover_flag_mask equ 80h
int19_init_mask equ	0100h
multrk_mask	equ	0200h
multrk_configured_mask equ 0400h
format_multitrk_mask equ 0800h
keyboard_hook_bit equ	13
keyboard_hook_mask equ	2000h
config_alloc_mask equ	8000h
IFDEF ROMEXEC
romstartaddr dw ROMEXEC_SEG
ELSE
romstartaddr dw 0
ENDIF
IFDEF ROMDOS
	public	BIOS_Res,DOS_Res,BootFlags
BIOS_Res dw ?
DOS_Res dw ?
BootFlags dw ?
ENDIF

	public	xms
	public	model_byte,secondary_model_byte
model_byte	db	0ffh		; model byte set at init time
secondary_model_byte db	0
xms	dd	0		; entry point to xms if above is true

	align	2
;M058;	public orig13
;M058;orig13	dd	?

	public	ptrsav
ptrsav	dd	0

	public	res_dev_list

res_dev_list	label	byte
	p_attr	=	chardev+outtilbusy+dev320+IOQUERY
; **	p_attr	=	chardev+outtilbusy+dev320

	sysdev <auxdev2,8013h,strategy,con_entry,'CON     '>
auxdev2 sysdev <prndev2,8000h,strategy,aux0_entry,'AUX     '>
prndev2 sysdev <timdev,p_attr,strategy,prn0_entry,'PRN     '>
timdev	sysdev <dskdev,8008h,strategy,tim_entry,'CLOCK$  '>
dskdev	dd	com1dev
	dw	842h + IOQUERY		; 00001001 01000010
; **	dw	842h			; 32 bit sector calculation
	dw	strategy,dsk_entry

	public	drvmax

drvmax		db	4
	public	keyrd_func
keyrd_func	db	0		; conventional keyboard read

com1dev sysdev <lpt1dev,8000h,strategy,aux0_entry,'COM1    '>
lpt1dev sysdev <lpt2dev,p_attr,strategy,prn1_entry,"LPT1    ">

IFDEF	ROMDOS
;
;ROM DOS BIOS has an additional six bytes of variables before this
;point, so Orig13 has been repositioned yet again.  -DBO
;
;M058; Start of changes
; Orig13 needs to be at offset 0b4h for the CMS floppy driver to work.
;These guys patch Orig13 with their own int 13h hook and so this offset
;cannot change for them to work. Even ProComm does this.
;
	db	15 dup (?)	; to make Orig13 offset 0B4h

	public orig13
orig13	dd	?

;
;M058; End of changes
;
ENDIF	;ROMDOS

lpt2dev sysdev <lpt3dev,p_attr,strategy,prn2_entry,"LPT2    ">

lpt3dev sysdev <configdev,p_attr,strategy,prn3_entry,"LPT3    ">
	public	keysts_func
keysts_func db	1		; conventional keyboard status
	db	0eah
	public	orig13
orig13	dd	?
com2dev sysdev <com3dev,8000h,strategy,aux1_entry,"COM2    ">
com3dev sysdev <com4dev,8000h,strategy,aux2_entry,"COM3    ">

;	define a label for the device (if any) which immediately
;	  follows com4

IFDEF	POWER
after_com4	equ	powerdev
ELSE
IFDEF	ROMDRIVE
	extrn	rdrive:near
after_com4	equ	rdrive
ELSE
after_com4	equ	0ffffh
ENDIF
ENDIF

com4dev dw	after_com4,Bios_Data,8000h,strategy,aux3_entry
	db	"COM4    "
tim_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	tim_table

tim_entry endp

;--------------------------------------------------------------------

	public	dsk_entry	; this entry point is called from msbio2

dsk_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	dsktbl

dsk_entry endp
	public	start_bds
start_bds dd bds1
	public	disksector_ptr
disksector_ptr dd 0		; address of disk sector buffer

IFDEF	POWER
powerdev	label	word

IFDEF	ROMDRIVE
	extrn	rdrive:near
	dw	rdrive
ELSE
	dw	0ffffh		; end of chain
ENDIF

		dw	Bios_Data, 8000h, strategy, power_entry		;M084
	db	"POWER$  "

ENDIF

		public	RomVectors
RomVectors	label	byte
	public	Old10, Old13, Old15, Old19, Old1B	; M028
	db	10h					; M028
Old10	dd	(?)					; M028
	db	13h
Old13	dd	(?)
	db	15h
Old15	dd	(?)
	db	19h
Old19	dd	(?)
	db	1bh
Old1B	dd	(?)
	public	BiosOld4F,BiosOld08,BiosOld0F,BiosOld16
	db	4fh
BiosOld4F	dd	0
	db	08h
BiosOld08	dd	0
	db	0fh
BiosOld0F	dd	0
	db	16h
BiosOld16	dd	0
EndRomVectors	equ	$
		public	NUMROMVECTORS
NUMROMVECTORS	equ	((EndRomVectors - RomVectors)/5)

configdev sysdev <com2dev,0c000h,strategy,config_entry,"CONFIG$ ">
	public	harddrv
harddrv db	80h		; physical drive number of first hardfile
	public	cdev
cdev	dd	chardev_entry
video_callback dd video_service
i13x	dd	i13z
int15_reset_ptr dd int15_reset
int15_esc_ptr dd int15_esc
int16_check_ptr dd int16_check
int19_code_ptr dd int19_restore
outchr_code_ptr dd outchr_code
int6c_code_ptr dd int6c_code
	public	bios_error_vector
bios_error_vector dd Bios_Code:bios_error_report
bcode_i2f dd	i2f_handler
;BEGIN M073
IFDEF	POWER
	extrn	Check_and_Init_APM:far
	public	Check_and_Init_APM_Ptr
Check_and_Init_APM_Ptr dd Bios_Code:Check_and_Init_APM
	extrn	P_UpdFromCMOS:far		;M074
	public	P_UpdFromCMOS_Ptr		;M074
P_UpdFromCMOS_Ptr dd Bios_Code:P_UpdFromCMOS	;M074
ENDIF	;POWER
;END M073
end_BC_entries:

	public	bios_hook_1,int10_old,int16_old,int4f_old
bios_hook_1	dd	0
int10_old	dd	0
int16_old	dd	0
int4f_old	dd	0
	public	a20_message_ptr
a20_message_ptr dw 0
max_sectors_curr_sup equ 63
	public	tracktable
tracktable	db	0,0,1,2
		db	0,0,2,2
		db	0,0,3,2
		db	0,0,4,2
		db	0,0,5,2
		db	0,0,6,2
		db	0,0,7,2
		db	0,0,8,2
		db	0,0,9,2
		db	0,0,10,2
		db	0,0,11,2
		db	0,0,12,2
		db	0,0,13,2
		db	0,0,14,2
		db	0,0,15,2
		db	0,0,16,2
		db	0,0,17,2
		db	0,0,18,2
		db	0,0,19,2
		db	0,0,20,2
		db	0,0,21,2
		db	0,0,22,2
		db	0,0,23,2
		db	0,0,24,2
		db	0,0,25,2
		db	0,0,26,2
		db	0,0,27,2
		db	0,0,28,2
		db	0,0,29,2
		db	0,0,30,2
		db	0,0,31,2
		db	0,0,32,2
		db	0,0,33,2
		db	0,0,34,2
		db	0,0,35,2
		db	0,0,36,2
		db	4*max_sectors_curr_sup - ($ - tracktable) dup (0)
	public	strategy
;************************************************************************
;*									*
;*	strategy - store es:bx (device driver request packet)		*
;*		     away at [ptrsav] for next driver function call	*
;*									*
;************************************************************************

strategy proc	far
	assume	ds:nothing,es:nothing

	mov	word ptr cs:[ptrsav],bx
	mov	word ptr cs:[ptrsav+2],es
	ret
strategy endp

;************************************************************************
;*									*
;*	device driver entry points.  these are the initial		*
;*	  'interrupt' hooks out of the device driver chain.		*
;*	  in the case of our resident drivers, they'll just		*
;*	  stick a fake return address on the stack which		*
;*	  points to dispatch tables and possibly some unit		*
;*	  numbers, and then call through a common entry point		*
;*	  which can take care of a20 switching				*
;*									*
;************************************************************************

con_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry	; call into code segment handler
	dw	con_table

con_entry endp

;--------------------------------------------------------------------

prn0_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	prn_table
	db	0,0		; device numbers

prn0_entry endp

;--------------------------------------------------------------------

prn1_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	prn_table
	db	0,1

prn1_entry endp

;--------------------------------------------------------------------

prn2_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	prn_table
	db	1,2

prn2_entry endp

;--------------------------------------------------------------------

prn3_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	prn_table
	db	2,3

prn3_entry endp

;--------------------------------------------------------------------

aux0_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	aux_table
	db	0

aux0_entry endp

;--------------------------------------------------------------------

aux1_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	aux_table
	db	1

aux1_entry endp

;--------------------------------------------------------------------

aux2_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	aux_table
	db	2

aux2_entry endp

;--------------------------------------------------------------------

aux3_entry proc	near
	assume	ds:nothing,es:nothing

	call	cdev_entry
	dw	aux_table
	db	3

aux3_entry endp

;--------------------------------------------------------------------

;--------------------------------------------------------------------

IFDEF	POWER

power_entry	proc	near
	assume	ds:nothing, es:nothing

	call	cdev_entry
	dw	power_table

power_entry	endp

ENDIF

;************************************************************************
;*									*
;*	Ensure A20 is enabled before jumping into code in HMA.		*
;*	This code assumes that if Segment of Device request packet is	*
;*	DOS DATA segment then the Device request came from DOS & that	*
;*	A20 is already on.						*
;*									*
;************************************************************************

config_entry proc near
	assume	ds:nothing,es:nothing
	call	cdev_entry
	dw	config_table
config_entry endp

cdev_entry proc	near
	assume	ds:nothing,es:nothing
;
; M064 - BEGIN
;
	push	ax
	mov	ax, DosDataSg
	cmp	word ptr [ptrsav+2], ax
	pop	ax
	je	short ce_enter_codeseg
	call	EnsureA20On
ce_enter_codeseg:
	jmp	cdev
cdev_entry endp
	public	int08_stub,int08_entry,int10_stub,int10_vector,int10_entry
	public	palette_index,palette_count,palette_config
	public	palette_cycles,palette_step
palette_index db 0
palette_count db 0
palette_config dw 100h
palette_cycles db 0
palette_step db 1
int08_stub db 0cfh
	dd	Bios_Data:int08_entry
	.386
int08_entry proc near
	push	eax
	push	ds
	sub	ax,ax
	mov	ds,ax
	assume	ds:nothing
	mov	ax,ds:[46ch]
	test	al,1
	jnz	int08_done
	sti
	push	bx
	push	cx
	push	dx
	mov	ax,70h
	mov	ds,ax
	assume	ds:Bios_Data
	mov	dl,palette_index
	test	dl,dl
	jz	short int08_restore
	push	dx
	mov	dx,3dah
	mov	bx,40h
	sub	cx,cx
int08_wait_first:
	in	al,dx
	test	al,8
int08_wait_first_branch:
	jz	short int08_wait_second_init
	loop	int08_wait_first
	dec	bx
	jnz	short int08_wait_first
	mov	byte ptr cs:int08_wait_first_branch,0ebh
int08_wait_second_init:
	mov	bx,40h
	sub	cx,cx
int08_wait_second:
	in	al,dx
	test	al,8
int08_wait_second_branch:
	jnz	short int08_wait_done
	loop	int08_wait_second
	dec	bx
	jnz	short int08_wait_second
	mov	byte ptr cs:int08_wait_second_branch,0ebh
int08_wait_done:
	pop	dx
	call	palette_read
	push	eax
	mov	cl,palette_count
	mov	bl,palette_step
int08_rotate:
	add	dl,bl
	call	palette_read
	sub	dl,bl
	call	palette_write
	add	dl,bl
	dec	cl
	jnz	short int08_rotate
	pop	eax
	call	palette_write
	cmp	palette_cycles,0
	jz	short int08_restore
	dec	palette_cycles
	jnz	short int08_restore
	neg	palette_step
	mov	al,palette_count
	mov	palette_cycles,al
	mul	bl
	add	palette_index,al
int08_restore:
	pop	dx
	pop	cx
	pop	bx
int08_done:
	pop	ds
	assume	ds:nothing
	pop	eax
	jmp	bios_hook_1
int08_entry endp

palette_read proc near
	mov	al,dl
	mov	dx,3c7h
	out	dx,al
	inc	dx
	inc	dx
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	in	al,dx
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	in	al,dx
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	in	al,dx
	ror	eax,8
	mov	dl,al
	ret
palette_read endp

palette_write proc near
	mov	al,dl
	mov	dx,3c8h
	out	dx,al
	inc	dx
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	out	dx,al
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	out	dx,al
	ror	eax,8
	jmp	short $+2
	jmp	short $+2
	jmp	short $+2
	out	dx,al
	ror	eax,8
	mov	dl,al
	ret
palette_write endp
	.8086
int10_stub db 0cfh
int10_vector dd Bios_Data:int10_entry
int10_entry proc far
	call	EnsureA20On
	call	video_callback
	jmp	int10_old
int10_entry endp

	public	block13
;************************************************************************
;*									*
;*	block13 - our int13 hooker					*
;*									*
;************************************************************************

block13	proc	far
	assume	ds:nothing,es:nothing

	call	EnsureA20On
	jmp	i13x
block13	endp

	public	Int15
Int15	proc	far
	assume	ds:nothing
	cmp	ah,4fh
	jne	short int15_chain
int15_jump:
	jmp	short int15_del
	cmp	al,1
	jne	short int15_del
	call	EnsureA20On
	jmp	int15_esc_ptr
int15_del:
	cmp	al,53h
	jne	short int15_setcarry
	push	ax
	push	ds
	sub	ax,ax
	mov	ds,ax
	mov	al,ds:[417h]
	and	al,0ch
	cmp	al,0ch
	jne	short int15_done
	call	EnsureA20On
	pushf
	call	int15_reset_ptr
int15_done:
	pop	ds
	pop	ax
int15_setcarry:
	stc
int15_chain:
	jmp	dword ptr Old15
Int15	endp

	public	int16_entry
int16_entry proc far
	assume	ds:nothing,es:nothing
	sti
	pushf
	test	byte ptr bios_flags+1,keyboard_hook_mask shr 8
	jnz	short int16_check_entry
int16_call:
	cli
	call	int16_old
	pushf
	dec	int16_active
	jnz	short int16_done
	nop
int16_done:
	popf
	ret	2
int16_check_entry:
	call	EnsureA20On
	call	int16_check_ptr
	jmp	short int16_call
int16_entry endp

	public	int19
;************************************************************************
;*									*
;*	int19 - bootstrap interrupt -- we must restore a bunch of the	*
;*	  interrupt vectors before resuming the original int19 code	*
;*									*
;************************************************************************

int19	proc	far
	assume	ds:nothing,es:nothing

	call	EnsureA20On
	call	int19_code_ptr
	int	19h
int19	endp

altah	db	0
	public	cbreak
;************************************************************************
;*									*
;*	cbreak - break key handling - simply set altah=3 and iret	*
;*									*
;************************************************************************

cbreak	proc	near
	assume	ds:nothing,es:nothing

	mov	altah,3		;indicate break key set

	public	intret		; general purpose iret in the Bios_Data seg
intret:
	iret
cbreak	endp

	public	outchr
;************************************************************************
;*									*
;*	outchr - this is our int 29h handler.  it writes the		*
;*	   character in al on the display using int 10h ttywrite	*
;*									*
;************************************************************************

outchr	proc	far
	assume	ds:nothing,es:nothing

	call	EnsureA20On
	jmp	outchr_code_ptr
outchr	endp

int_2f	proc	far
	assume	ds:nothing,es:nothing
	jmp	bcode_i2f
int_2f	endp

	public	i2f_dskentry
i2f_dskentry proc far
	jmp	dsk_entry
i2f_dskentry endp

	public	int6c_entry
int6c_entry proc far
	call	EnsureA20On
	jmp	int6c_code_ptr
int6c_entry endp

HiMem	label	dword
	dw	90h
	dw	0ffffh

LoMem	label	dword
	dw	80h
	dw	0h

;************************************************************************
;*									*
;*	EnsureA20On - ensure that a20 is enabled if we're running	*
;*	  in the HMA before interrupt entry points into Bios_Code	*
;*									*
;************************************************************************

EnsureA20On proc near
	assume	ds:nothing,es:nothing
	test	byte ptr bios_flags,a20_mask
	jz	short a20_return
	push	cx
	push	si
	push	di
	push	ds
	push	es
	lds	si,HiMem
	les	di,LoMem
	mov	cx,8
	cld
	repe	cmpsw
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	cx
	jz	short ea_enable
	clc
	ret
ea_enable:
EnableA20 label near
	push	ax
	mov	ah,5
a20_call:
	push	bx
	call	xms
	or	ax,ax
	jz	short a20_failure
	pop	bx
	pop	ax
	stc
a20_return:
	ret
EnsureA20On endp

DisableA20 proc near
	push	ax
	mov	ah,6
	jmp	short a20_call
DisableA20 endp

	public	bios_error_entry,bios_error_dispatch
bios_error_entry label far
a20_failure:
	or	ax,ax
	jnz	short bios_error_dispatch
	mov	ah,0fh
	int	10h
	cmp	al,7
	jz	short a20_screen
	xor	ah,ah
	mov	al,2
	int	10h
a20_screen:
	mov	ah,5
	xor	al,al
	int	10h
	mov	si,a20_message_ptr
	push	cs
	pop	ds
	cld
a20_message:
	lodsb
	cmp	al,'$'
	jz	short a20_halt
	mov	ah,0eh
	mov	bx,7
	int	10h
	jmp	short a20_message
a20_halt:
	sti
	jmp	short a20_halt
bios_error_dispatch label far
	call	EnsureA20On
	call	bios_error_vector
	retf

	public	int4f_entry
int4f_entry proc far
	jmp	int4f_old
int4f_entry endp

	public	daycnt,daycnt2
daycnt	label	word
daycnt2	dw	0		; count of days since 1-1-80

	public	int16_tick,int16_count,int16_active,int16_limit,int16_limit2
int16_tick	dw	0
int16_count	dw	0		; shared with clock read
int16_limit	dw	200
int16_limit2	dw	200
int16_active	dw	0

	db	0
	public	i13_ds
i13_ds	dw	?

	public	call_orig13
call_orig13 proc far
	assume	ds:Bios_Data
	mov	ds,i13_ds
	assume	ds:nothing
	lea	bp,[bp]
	pushf
	cli
	call	orig13
	mov	i13_ds,ds
	push	cs
	pop	ds
	assume	ds:Bios_Data
	pushf
	call	EnsureA20On
	popf
	lea	bp,[bp]
	ret
call_orig13 endp
	public	config_flags,config_count,config_value,config_xms
config_flags	db	0
config_count	dw	0
config_value	dw	0
config_xms	dd	0

;*********************************************************************
;	"bds" contains information for each drive in the system.
;	various values are patched whenever actions are performed.
;	sectors/alloc. unit in bpb initially set to -1 to signify that
;	the bpb has not been filled. link also set to -1 to signify end
;	of list. # of cylinders in maxparms initialized to -1 to indicate
;	that the parameters have not been set.
;
bds_str struc
	dw	?		; dword link to next structure
	dw	?
	db	0		; int 13 drive number
	db	0		; logical drive letter

xfdrv	dw	512		; physical sector size in bytes
	db	-1		; sectors/allocation unit
	dw	1		; reserved sectors for dos
	db	2		; no of allocation tables
	dw	64		; number of directory entries
	dw	9*40		; number sectors (at 512 bytes each)
	db	0		; media descriptor, initially 0
	dw	2		; number of fat sectors
	dw	9		; sector limit
	dw	1		; head limit
	dw	0		; hidden sector count (low word)
	dw	0		; hidden sector (high)
	dw	0		; number sectors (low)
	dw	0		; number sectors (high)
	db	0		;  true => large fats
	dw	0		; open ref. count
	db	3		; form factor
	dw	20h		; various flags
	dw	40		; number of cylinders

;	recommended bps for this drive

	dw	512		; bytes per sector
	db	1		; sectors/alloc unit
	dw	1		; reserved sectors for dos
	db	2		; number of allocation tables
	dw	0e0h		; number directory entries
	dw	9*40		; number 512 byte sectors
	db	0f0h		; media descriptor, initially 0f0h
	dw	2		; number of fat sectors
	dw	9		; sector limit
	dw	2		; head limit
	dw	0		; hidden sector count(low)
	dw	0		; hidden sector count(high)
	dw	0		; number sectors(low)
	dw	0		; number sectors(high)
	db	6 dup (?)

	db	-1		; last track accessed on this drive
	dw	-1		; keep these two contiguous (?)
	dw	-1
	db	"NO NAME    ",0	; volume id for this disk
	dd	0		; current volume serial from boot record
	db	"FAT12   ",0	; current file system id from boot record
bds_str ends

bpbtype struc
spf	db	?
spt	db	?
cdire	db	?
csec	dw	?
spau	db	?
chead	db	?
bpbtype ends

	public	max_sectors_curr_sup
DELKEY		equ	53h
ROMDATASEG	equ	40h
KBFLAG		equ	17h
CTRLSTATE	equ	04h
ALTSTATE	equ	08h

IFNDEF	ROMDOS						; M097

; this will be the end of the BIOS data if no hard disks are in system
; in DISK based DOS

	public	endfloppy
endfloppy label byte

ENDIF ; NOT ROMDOS					; M097

Bios_Data ends

;
; Possibly disposable BIOS data
; This data follows the regular BIOS data, and is part of the same group.
;

Bios_Data_Init	segment

; M097 : begin

IFDEF	ROMDOS

; this will be the end of the BIOS data if no hard disks are in system
; in ROMDOS

	public	endfloppy
endfloppy label byte

ENDIF ; ROMDOS

; M097 : end

;	M011 -- begin changed section

;	this stuff is only used for changeline support

	public	end96tpi
end96tpi label	byte

;*********************************************************************
;memory allocation for bdss
;*********************************************************************

;M011 -- end of changed section

Bios_Data_Init	ends

;	okay.  so much for Bios_Data.  Now let's put our device driver
;	  entry stuff up into Bios_Code.

Bios_Code	segment
	assume	cs:Bios_Code

; ORG a bit past zero to leave room for running in HMA...

	org	30h
	public	BCode_start
BCode_start:
	db	'MS'
	dw	0
	public	hma_initial_size
hma_initial_size dw 0

;	device driver entry point tables

	extrn	dsktbl:near
	extrn	con_table:near
	extrn	tim_table:near
	extrn	prn_table:near
	extrn	aux_table:near
	extrn	read_real_date:near,read_real_time:near
	extrn	start_sec_h:word
	; sysinit_seg is shared by the CONFIG$ and disk initialization code.
; exec_bios_word is part of the BIOS boot log state.

IFDEF POWER
	extrn	power_table:near
ENDIF

	extrn	i2f_handler:far
	extrn	time_to_ticks:far
	extrn	i13z:far

	org	40h

;************************************************************************
;*									*
;*	chardev_entry - main device driver dispatch routine		*
;*	   called with a dummy parameter block on the stack		*
;*	   dw dispatch_table, dw prn/aux numbers (optional)		*
;*									*
;*	will eventually take care of doing the transitions in		*
;*	   out of Bios_Code						*
;*									*
;************************************************************************

chardev_entry	proc	far
	assume	ds:nothing,es:nothing

	.286
	pusha
	push	ds
	push	es
	mov	bp,sp
	mov	ds,Bios_Data_Word
	assume	ds:Bios_Data
	mov	bx,20[bp]
	mov	si,[bx]
	cmp	si,offset con_table
	jz	short char_get_request
	mov	ax,2[bx]
	mov	byte ptr auxnum,al
	mov	byte ptr printdev,ah
char_get_request:
	les	bx,[ptrsav]
	mov	al,es:[bx].unit
	mov	ah,es:[bx].media
	mov	cx,es:[bx].count
	mov	dx,es:[bx].start
	cmp	si,offset dsktbl
	jnz	short char_sector_done
	mov	start_sec_h,0
	cmp	dx,-1
	jnz	short char_sector_done
	mov	dx,es:[bx].start_h
	mov	start_sec_h,dx
	mov	dx,es:[bx].start_l
char_sector_done:
	xchg	ax,di
	mov	al,es:[bx].cmd
	cmp	al,cs:[si]
	jae	command_error
	cbw
	add	ax,ax
	add	si,ax
	xchg	ax,di
	les	di,dword ptr es:[bx].trans
	cld
	push	ds
	call	cs:word ptr [si+1]
	pop	ds
	jc	short already_got_ah_status
	mov	ah,1
already_got_ah_status:
	lds	bx,[ptrsav]
	assume	ds:nothing
	mov	word ptr [bx].status,ax
	pop	es
	pop	ds
	popa
	add	sp,2
	.8086

chardev_entry endp		; fall through into bc_retf

	public	bc_retf
bc_retf	proc	far
	assume	ds:nothing,es:nothing

	ret

bc_retf	endp

	public	bc_cmderr
bc_cmderr:
	mov	al,3			;unknown command error

;	now zero the count field by subtracting its current value,
;	  which is still in cx, from itself.


;	subtract the number of i/o's NOT YET COMPLETED from total
;	  in order to return the number actually complete


	public	bc_err_cnt
bc_err_cnt:
	assume	ds:Bios_Data
	les	bx,[ptrsav]
	assume	es:nothing
	sub	es:word ptr [bx].count,cx;# of successful i/o's
	mov	ah,81h			;mark error return
	stc				; indicate abnormal end
	ret

;
;----------------------------------------------------------------------------
; The following piece of hack is for supporting CP/M compatibility
; Basically at offset 5 we have a far call into 0:c0. But this does not call
; 0:c0 directly instead it call f01d:fef0, because it needs to support 'lhld 6'
; The following hack has to reside at ffff:d0 (= f01d:fef0) if BIOS is loaded
; high.
;----------------------------------------------------------------------------
;
	db	?

	public	off_d0
off_d0	db	5 dup (?)	; 5 bytes from 0:c0 will be copied onto here
				;  which is the CP/M call 5 entry point

command_error:
	call	bc_cmderr
	jmp	short already_got_ah_status
	public	Bios_Data_Word
Bios_Data_Word	dw	Bios_Data

;	we assume the following remain contiguous and their order doesn't change

i19_lst:
	irp	aa,<02,08,09,0a,0b,0c,0d,0e,70,72,73,74,76,77>
	public	int19old&aa
		db	aa&h	; store the number as a byte
int19old&aa	dd	-1	;orignal hardware int. vectors for int 19h.
	endm
num_i19 =	((offset $) - (offset i19_lst))/5
	.386
	public	video_service
video_service proc far
	sti
	or	ah,ah
	jnz	short video_function
	cmp	al,7fh
	jz	short video_return
video_keyboard:
	call	keyboard_service
video_return:
	ret
video_function:
	cmp	ah,11h
	jz	short video_keyboard
	cmp	ah,0eh
	jnz	short video_return
	cmp	al,7
	jz	short video_return
	cmp	al,8
	jz	short video_return
	pusha
	push	ds
	push	es
	cmp	al,0dh
	jz	short video_restore
	sub	dx,dx
	mov	ds,dx
	assume	ds:nothing,es:nothing
	mov	dx,ds:[450h]
	cmp	dh,ds:[484h]
	jnz	short video_restore
	mov	ah,ds:[449h]
	cmp	ah,7
	jz	short video_mode_ok
	cmp	ah,2
	jb	short video_restore
	cmp	ah,3
	ja	short video_restore
video_mode_ok:
	cmp	word ptr ds:[44ah],50h
	jne	short video_restore
	cmp	byte ptr ds:[462h],0
	jne	short video_restore
	cmp	al,0ah
	jz	short video_scroll
	cmp	dl,4fh
	jne	short video_restore
video_scroll:
	mov	si,0b000h
	cmp	ah,7
	jz	short video_segment
	mov	si,0b800h
video_segment:
	mov	ds,si
	mov	es,si
	mov	si,0a0h
	sub	di,di
	movzx	cx,dh
	imul	cx,si
	mov	bx,cx
	shr	cx,2
	cmp	al,0ah
	jz	short video_copy
	add	dl,dl
	mov	dh,0
	add	bx,dx
	mov	[bx],al
	sub	bx,dx
	mov	ax,0e0dh
	int	10h
video_copy:
	cld
	rep	movsd
	mov	al,20h
	mov	ah,[bx+1]
	mov	cx,50h
	rep	stosw
	pop	es
	pop	ds
	popa
	add	sp,4
	iret
video_restore:
	pop	es
	pop	ds
	popa
	ret
video_service endp
	public	int15_reset
int15_reset proc far
	call	EraseVDiskHead
	iret
int15_reset endp
int15_esc_count db 0
	public	int15_esc
int15_esc proc far
	call	keyboard_service
	adc	int15_esc_count,0
	push	bp
	mov	bp,sp
	and	byte ptr [bp+6],0feh
	pop	bp
	iret
int15_esc endp
	public	keyboard_service
keyboard_service proc near
	push	ds
	mov	ds,Bios_Data_Word
	assume	ds:Bios_Data
	btr	word ptr bios_flags,keyboard_hook_bit
	pop	ds
	assume	ds:nothing,es:nothing
	jnc	keyboard_return
	inc	cs:keyboard_depth
	jnz	short keyboard_stack_ready
	mov	cs:keyboard_ss,ss
	mov	cs:keyboard_sp,sp
	push	cs
	pop	ss
	mov	sp,offset keyboard_sp
keyboard_stack_ready:
	call	keyboard_vector_setup
	pusha
	push	ds
	push	es
	push	ss
	pop	es
	sub	sp,26h
	mov	di,sp
	call	video_state_save
	cmp	byte ptr ds:[484h],2ah
	jne	short keyboard_mode
	mov	ax,1201h
	mov	bl,30h
	pushf
	cli
	call	dword ptr ds:[870h]
	mov	dx,ds:[488h]
keyboard_mode:
	mov	ah,0
	mov	al,ds:[449h]
	or	al,80h
	pushf
	cli
	call	dword ptr ds:[870h]
	call	video_state_restore
	add	sp,26h
	cmp	byte ptr es:[484h],2ah
	jb	short keyboard_cursor
	ja	short keyboard_font
	mov	es:[488h],dx
keyboard_font:
	mov	ax,1112h
	mov	bl,0
	pushf
	cli
	call	dword ptr es:[870h]
keyboard_cursor:
	movzx	bx,byte ptr es:[462h]
	mov	di,bx
	mov	dx,es:[bx+di+450h]
	mov	bh,bl
	mov	ah,2
	pushf
	cli
	call	dword ptr es:[870h]
	pop	es
	pop	ds
	popa
	dec	cs:keyboard_depth
	jns	short keyboard_carry
	mov	ss,cs:keyboard_ss
	mov	sp,cs:keyboard_sp
keyboard_carry:
	stc
keyboard_return:
	ret
keyboard_service endp
keyboard_vector_table label word
	dw	offset Bios_Data:int08_stub,20h,offset Bios_Data:bios_hook_1
	dw	offset Bios_Data:int10_stub,40h,offset Bios_Data:int10_old
	dw	0
	public	keyboard_vector_install
keyboard_vector_install proc near
	cli
	cld
	pusha
	push	ds
	push	es
	push	eax
	push	edx
	sub	ax,ax
	mov	es,ax
	mov	ax,70h
	mov	ds,ax
	assume	ds:Bios_Data,es:nothing
	test	byte ptr bios_flags+1,keyboard_hook_mask shr 8
	jz	short keyboard_install_exit
	rol	eax,16
	mov	si,offset keyboard_vector_table
keyboard_install_next:
	lods	word ptr cs:[si]
	or	ax,ax
	jz	short keyboard_install_done
	xchg	ax,bx
	cmp	byte ptr [bx],0cfh
	jz	short keyboard_install_hook
	cmp	word ptr [bx+3],70h
	jz	short keyboard_install_skip
	lea	ax,[bx+5]
	mov	[bx+1],eax
keyboard_install_skip:
	add	si,4
	jmp	short keyboard_install_next
keyboard_install_hook:
	mov	byte ptr [bx],0eah
	lods	word ptr cs:[si]
	xchg	ax,bx
	xchg	eax,es:[bx]
	mov	bx,cs:[si]
	add	si,2
	mov	[bx],eax
	mov	ax,ds
	rol	eax,16
	jmp	short keyboard_install_next
keyboard_install_done:
	mov	byte ptr [int15_jump],3ch
keyboard_install_exit:
	pop	edx
	pop	eax
	pop	es
	pop	ds
	assume	ds:nothing,es:nothing
	popa
	sti
	ret
keyboard_vector_install endp
	public	keyboard_vector_setup
keyboard_vector_setup proc near
	cli
	cld
	pusha
	push	ds
	push	es
	push	eax
	push	edx
	sub	ax,ax
	mov	es,ax
	mov	ax,70h
	mov	ds,ax
	assume	ds:Bios_Data,es:nothing
	rol	eax,16
	mov	si,offset keyboard_vector_table
keyboard_vector_next:
	lods	word ptr cs:[si]
	or	ax,ax
	jz	short keyboard_vector_done
	xchg	ax,bx
	cmp	byte ptr [bx],0cfh
	jz	short keyboard_vector_skip
	lods	word ptr cs:[si]
	xchg	ax,bx
	cmp	eax,es:[bx]
	jz	short keyboard_vector_restore
	xchg	ax,bx
	lods	word ptr cs:[si]
	xchg	ax,di
	mov	edx,[di]
	mov	[bx+1],edx
	jmp	short keyboard_vector_next
keyboard_vector_restore:
	xchg	ax,bx
	mov	byte ptr [bx],0cfh
	xchg	ax,bx
	lods	word ptr cs:[si]
	xchg	ax,di
	mov	edx,[di]
	mov	es:[bx],edx
	jmp	short keyboard_vector_next
keyboard_vector_skip:
	add	si,4
	jmp	short keyboard_vector_next
keyboard_vector_done:
	mov	byte ptr [int15_jump],0ebh
	pop	edx
	pop	eax
	pop	es
	pop	ds
	assume	ds:nothing,es:nothing
	popa
	sti
	ret
keyboard_vector_setup endp
	public	video_state_save
video_state_save proc near
	assume	ds:nothing,es:nothing
	push	di
	sub	cx,cx
	mov	ds,cx
	cld
	mov	si,410h
	movsb
	mov	si,449h
	mov	cl,1eh
	rep	movsb
	mov	si,484h
	mov	cl,7
	rep	movsb
	pop	di
	ret
video_state_save endp
	nop
keyboard_stack db 512 dup (0)
keyboard_sp dw 0
keyboard_ss dw 0
keyboard_depth db 0ffh
	public	video_state_restore
video_state_restore proc near
	assume	ds:nothing,es:nothing
	push	es
	pop	ds
	mov	si,di
	sub	cx,cx
	mov	es,cx
	cld
	mov	di,410h
	movsb
	mov	di,449h
	mov	cl,1eh
	rep	movsb
	mov	di,484h
	mov	cl,7
	rep	movsb
	ret
video_state_restore endp
	public	int16_check
int16_check proc far
	push	ax
	push	ds
	push	es
	mov	es,Bios_Data_Word
	assume	es:Bios_Data
	and	ah,0efh
	cmp	ah,1
	jb	short int16_check_call
	jz	short int16_check_ticks
	cmp	ah,2
	ja	short int16_check_done
int16_check_ticks:
	sub	ax,ax
	mov	ds,ax
	assume	ds:nothing
	mov	ax,ds:[46ch]
	cmp	ax,es:int16_tick
	jnz	short int16_check_new_tick
	inc	es:int16_count
	mov	ax,es:int16_limit
	cmp	es:int16_count,ax
	jb	short int16_check_done
	jmp	short int16_check_call
int16_check_new_tick:
	mov	es:int16_tick,ax
	mov	es:int16_count,0
	jmp	short int16_check_done
int16_check_call:
	call	keyboard_service
int16_check_done:
	pop	es
	pop	ds
	pop	ax
	ret
int16_check endp
	public	int19_restore
int19_restore proc far
	mov	ds,Bios_Data_Word
	assume	ds:Bios_Data
	cld
	sub	dx,dx
	mov	es,dx
	or	dx,es:[40eh]
	jz	short int19_vectors
	mov	ax,0
	sub	es:[413h],ax
	shl	ax,9
	jz	short int19_vectors
	mov	cx,es:[413h]
	shl	cx,6
	push	ds
	push	es
	mov	es,cx
	mov	ds,dx
	xchg	ax,cx
	sub	si,si
	sub	di,di
	rep	movsw
	pop	es
	pop	ds
	mov	es:[40eh],ax
int19_vectors:
	mov	cx,NUMROMVECTORS
	mov	si,offset RomVectors
int19_vector_loop:
	lodsb
	cbw
	shl	ax,2
	xchg	ax,di
	movsw
	movsw
	loop	int19_vector_loop
	test	byte ptr bios_flags+1,int19_init_mask shr 8
	jz	short int19_clear
	push	cs
	pop	ds
	assume	ds:Bios_Code
	mov	si,offset i19_lst
	mov	cx,num_i19
int19_hardware_loop:
	lodsb
	cbw
	xchg	ax,di
	lodsw
	xchg	ax,bx
	lodsw
	cmp	bx,-1
	jz	short int19_hardware_next
	shl	di,2
	xchg	ax,bx
	stosw
	xchg	ax,bx
	stosw
int19_hardware_next:
	loop	int19_hardware_loop
int19_clear:
	call	EraseVDiskHead
	ret
int19_restore endp
	public	outchr_code
outchr_code proc far
	assume	ds:nothing,es:nothing
	push	ax
	push	si
	push	di
	push	bp
	push	bx
	push	ds
	mov	ds,Bios_Data_Word
	assume	ds:Bios_Data
	mov	ds,DosDataSg
	assume	ds:nothing
	test	byte ptr ds:[86h],10h
	mov	ah,0eh
	mov	bx,7
	jz	short outchr_int10
	cmp	al,0dh
	jz	short outchr_int10
	xor	si,si
	mov	ds,si
	cmp	al,20h
	jb	short outchr_old10
	cmp	byte ptr ds:[449h],3
	jne	short outchr_old10
	cmp	word ptr ds:[44ah],50h
	jne	short outchr_old10
	cmp	byte ptr ds:[462h],0
	jne	short outchr_old10
	cmp	byte ptr ds:[450h],4fh
	jz	short outchr_old10
	push	dx
	mov	bl,al
	mov	di,ds:[44eh]
	mov	dx,ds:[450h]
	inc	byte ptr ds:[450h]
	mov	ax,0a0h
	mul	dh
	xor	dh,dh
	shl	dx,1
	add	ax,dx
	add	di,ax
	mov	ax,0b800h
	mov	ds,ax
	mov	[di],bl
	pop	dx
	jmp	short outchr_done
outchr_old10:
	pushf
	call	dword ptr ds:[40h]
	jmp	short outchr_done
outchr_int10:
	int	10h
outchr_done:
	pop	ds
	pop	bx
	pop	bp
	pop	di
	pop	si
	pop	ax
	iret
outchr_code endp
	public	EraseVDiskHead
EraseVDiskHead proc near
	push	ax
	push	cx
	push	di
	push	es
	mov	es,Bios_Data_Word
	assume	es:Bios_Data
	test	byte ptr es:bios_flags,a20_mask
	jz	short erase_vdisk_done
	mov	ax,0ffffh
	mov	es,ax
	assume	es:nothing
	mov	di,10h
	mov	cx,10h
	sub	ax,ax
	cld
	rep	stosw
erase_vdisk_done:
	pop	es
	pop	di
	pop	cx
	pop	ax
	ret
EraseVDiskHead endp
bios_error_report proc far
	push	si
	push	ds
	cld
	push	cs
	pop	ds
	assume	ds:Bios_Code
	dec	ax
	jnz	short bios_error_report_2
	mov	si,offset Bios_Code:bios_msg_base
	add	si,bios_msg_1
	jmp	short bios_error_report_print
bios_error_report_2:
	dec	ax
	jnz	short bios_error_report_3
	mov	si,offset Bios_Code:bios_msg_base
	add	si,bios_msg_2
	jmp	short bios_error_report_print
bios_error_report_3:
	dec	ax
	jnz	short bios_error_report_done
	mov	si,offset Bios_Code:bios_msg_base
	add	si,bios_msg_3
bios_error_report_print:
	lodsb
	cmp	al,'$'
	jz	short bios_error_report_done
	mov	ah,0eh
	mov	bx,7
	int	10h
	jmp	short bios_error_report_print
bios_error_report_done:
	pop	ds
	assume	ds:nothing
	pop	si
	retf
bios_error_report endp
	db	0			; align character data
	public	printdev,wait_count,auxnum,auxbuf
	public	base_century,base_year,month_tab,bin_date_time,month_table
printdev	dw	0
wait_count	dw	4 dup (50h)
auxnum		dw	0
auxbuf		db	4 dup (0)
base_century	db	19
base_year	db	80
month_tab	db	31,28,31,30,31,30,31,31,30,31,30,31
bin_date_time:
	db	0		; century (19 or 20) or hours (0-23)
	db	0		; year in century (0...99) or minutes (0-59)
	db	0		; month in year (1...12) or seconds (0-59)
	db	0		; day in month (1...31)

month_table:
	dw	0		; january
	dw	31		; february
	dw	59
	dw	90
	dw	120
	dw	151
	dw	181
	dw	212
	dw	243
	dw	273
	dw	304
	dw	334		; december
	.8086
	extrn	int6c_code:far,int6c_update:near

	extrn	config_table:byte,sysinit_seg:word,exec_bios_word:byte

	extrn	bios_msg_base:byte
	extrn	bios_msg_1:word,bios_msg_2:word,bios_msg_3:word

Bios_Code	ends

;	the last real segment is sysinitseg

sysinitseg	segment
	public	bds1
bds1	bds_str <bds2,seg sysinitseg>
bds2	bds_str <bds3,seg sysinitseg,0,1>
bds3	bds_str <bds4,seg sysinitseg>
bds4	bds_str <-1,-1>

	public	fdrive1
	public	fdrive2
	public	fdrive3
	public	fdrive4

fdrive1 equ	bds1.xfdrv
fdrive2 equ	bds2.xfdrv
fdrive3 equ	bds3.xfdrv
fdrive4 equ	bds4.xfdrv

	public	bdss
bdss	BDS_STRUC (2+max_mini_dsk_num) dup (<-1>)	;currently max. 25
	public	bds_count,dskdrvs
bds_count dw	0
dskdrvs dw	(4+2+max_mini_dsk_num) dup (0) ; pointers to drive BPBs

	even
	extrn	move_myself:near
	public	SI_start
SI_start:
	jmp	move_myself

	extrn	config_init_entry:far
sysinitseg	ends

	end
