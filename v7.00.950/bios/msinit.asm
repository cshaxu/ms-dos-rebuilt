;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160
	title	msinit for BIOS
;
;----------------------------------------------------------------------------
;
; M010 : IFDEFd the usage of Extended Keynboard read functions (10h &11h)
;        To support LOTUS Metro.
;
; M021 : Fix for AT&T 6300 WGS ROM BIOS bug
;
; M036 : Added VDISK header clearing code at INT 19 & CTRL ALT DEL
;
; M043 SR 10/17/90	Added special code which checks for IBM machines and
;			boots only on them. Code is activated only if the
;			flag IBM_VERSION is defined at assembly time.
;
; M048 : bin_to_bcd & bcd_to_bin using aam & aad
;
; M068 : B#6271. Added missed out RPL support.
;
; M083 : Take out bios' INT 6C hook if POWER is built into BIOS.
;
;----------------------------------------------------------------------------
;

	BYTE_SYSINIT equ 1
	BYTE_BIOS_INIT equ 1

EXTENDEDKEY	equ	1	; use extended keyboard functions

	include version.inc	; set build flags
	include biosseg.inc	; establish bios segment structure

	include	msequ.inc
	include	msdskpr.inc
	include dossym.inc
	include	bpb.inc
	include	bootform.inc
	include	dosmac.inc
	include biostruc.inc
	include	msbds.inc

	include	mult.inc	; M068


;	the following segment follows sysinit.  It is used to define
;	  the location to load MSDOS.SYS into.

dos_load_seg	segment	para public 'dos_load_seg'
dos_load_seg	ends


	include msgroup.inc	; establish Bios_Data segment


;	Note:  Most of the disk routines keep a pointer to the current bds
;	   in es:[di] or ds:[di].  The newer routines (in the resident code)
;	   use es:[di] consistently, because they assume that ds: points to
;	   Bios_Data.  The macros "mapnew" and "unmapnew" are used for
;	   switching back and forth when calling subroutines with the new
;	   mapping.

mapnew	macro
	push	es		; save whatever's in es
	push	ds		; copy bds to es:di
	pop	es
	push	cs		; copy Bios_Data to ds
	pop	ds
	endm

unmapnew	macro
	push	es		; copy bds back to ds:di
	pop	ds
	pop	es		; pop whatever was in es
	endm

;=======================================================
;=======================================================
;M011 -- eliminated hardnum,hdsktab,bdsh,bdsx,endtwohard,endonehard
;M011 -- changed bdsms -> bdss
	extrn	hdrv_pat:word
	extrn	orig13:dword
	extrn	RomVectors:dword
	extrn	NUMROMVECTORS:abs
	extrn	harddrv:byte
	extrn	drvmax:byte
	extrn	daycnt:word
	extrn	res_dev_list:word
	extrn	start_bds:dword
	extrn	old13:dword
	extrn	temp_h:word		; for 32 bit calculation. msdisk
	extrn	start_sec_h:word
	extrn	keyrd_func:byte 	; for mscon. defined in msdata.
	extrn	keysts_func:byte	; for mscon. defined in msdata.
	extrn	fat_12_id:byte
	extrn	fat_16_id:byte
	extrn	vol_no_name:byte
	extrn	model_byte:byte
	extrn	secondary_model_byte:byte


	extrn	daycnt2:word
	extrn	bios_flags:word
k09_mask equ	10h
	extrn	int6c_entry:far,call_orig13:far
	extrn	int16_entry:far,int16_old:dword
	extrn	a20_message_ptr:word
	extrn	sysinit_msg_base:byte,sysinit_msg_table:word
;
; Indexes in the SYSINIT message offset table.
;
sysinit_cpu_msg	equ	61*2
sysinit_a20_msg	equ	62*2
	extrn	disksector_ptr:dword

	extrn	dosdatasg:word

ifdef ROMDOS
	extrn	BIOS_Res:word		; seg addr of bios code ROM
	extrn	BootFlags:word		; boot options
endif

	extrn	errout:near
	extrn	block13:far
	extrn	Int15:far		; M036
	extrn	int19:far
	extrn	intret:near
	extrn	cbreak:near
	extrn	outchr:near
	extrn	errin:near

sysinitseg segment 
	assume	cs:sysinitseg
	extrn	current_dos_location:word
	extrn	device_list:dword
	extrn	memory_size:word
	extrn	default_drive:byte
	extrn	bdss:byte		;for mini disk
	extrn	dskdrvs:word
	extrn	boot_load_segment:word,boot_data_high:word,boot_data_low:word
	extrn	no_floppy_report:byte
	extrn	sys_model_byte:byte,sys_scnd_model_byte:byte
	extrn	rpl_memory_size:word,boot_copy_buffer:byte
	extrn	sysinit_bios_start:word,sysinit_bios_paras:word
	extrn	sysinit_reserve_count:word,sysinit_reserve_size:byte
	extrn	boot_reloc_segment:word
	extrn	buffers:word
	extrn	SI_start:far
	extrn	temp_bcode_seg:word
        extrn   toomanydrivesflag:byte          ; M029
        extrn   StartMsg:byte
sysinitseg ends

	assume	cs:datagrp

;	end of disk modules for configuration

	extrn	end96tpi:byte
	extrn	endfloppy:byte

;	ibm fixed up at rom

	extrn	ibm_disk_io:far
	extrn	endatrom:byte

;	M015 -- begin additions

;	compaq fixed up rom

	extrn	compaq_disk_io:far
	extrn	end_compaq_i13hook:byte

;	M015 -- end additions

;	equates for cmos.
									  
;----------------------------------------				  
;	cmos equates for this system	:				  
;------------------------------------------------------------------------------- 
cmos_port	equ	070h		; i/o address of cmos address port	 
cmos_data	equ	071h		; i/o address of cmos data port 	 
nmi		equ	10000000b	; disable nmi interrupts mask - 	 
					;  high bit of cmos location address	 
										 
;---------- cmos table location address's ## ----------------------------------- 
cmos_reg_a	equ	00ah		; status register a   '----------------- 
cmos_reg_b	equ	00bh		; status register b  alarm		 
cmos_shut_down	equ	00fh		; shutdown status command byte		 



; close data, open Bios_Code segment

	tocode

	extrn	bc_retf:near		; actually should be declared in
					;   Bios_Code segment
	extrn	setdrive:near
	extrn	diskrd:near
	extrn	getbp:near
	extrn	mov_media_ids:near
	extrn	clear_ids:near
	extrn	base_century:byte,base_year:byte,month_tab:byte
	extrn	eot:byte,motorstartup:byte
	extrn	bin_date_time:byte,month_table:word
	extrn	Bios_Data_Word:word
	extrn	time_to_ticks:near
Bios_Code ends


Bios_Data_Init segment
	assume	cs:datagrp


Bios_Data_Init ends
Bios_Code segment
	assume	cs:Bios_Code
	extrn read_real_date:near,read_real_time:near,daycnt_to_day:near,daycnt_to_day_near:near,bin_to_bcd:near,bin_to_bcd_near:near
Bios_Code ends
Bios_Data_Init segment
	assume	cs:datagrp

;*********************************************************
;	CMOS clock initialization
;*********************************************************

IFNDEF	POWER		; CMOS clock is initialized by power management
			; device driver, if present.  ;M074

cmos_clock_read proc	near
	assume	ds:datagrp,es:datagrp

; in order to determine if there is a clock present in the system, the following
; needs to be done.

	push	ax
	push	cx
	push	dx
	push	bp

	xor	bp,bp
loop_clock:
	xor	cx,cx
	xor	dx,dx
	mov	ah,2			;read real time clock
	int	1ah			;call rom-bios routine
	or	cx,cx			; cas - arrrrgh!
	jnz	clock_present

	or	dx,dx
	jnz	clock_present

	or	bp,bp			; read again after a slight delay, in case clock
	jnz	no_readdate		; was at zero setting.

	inc	bp			; only perform delay once.
	mov	cx,4000h
delay:
	loop	delay
	jmp	loop_clock

clock_present:
	or	bios_flags,020h	; cmos clock is present
	call	cmosck			; reset cmos clock rate that may be
					;possibly destroyed by cp dos and post routine did not
					;restore that.


no_readdate:
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	ret

cmos_clock_read endp

; the following code is written by jack gulley in engineering group.
; cp dos is changing cmos clock rate for its own purposes and if the
; use cold boot the system to use pc dos while running cp dos, the cmos
; clock rate are still slow which slow down disk operations of pc dos
; which uses cmos clock.  pc dos is put this code in msinit to fix this
; problem at the request of cp dos.
;
; the program is modified to be run on msinit. equates are defined in cmosequ.inc.
; this program will be called by cmos_clock_read procedure.
;
;  the following code cmosck is used to insure that the cmos has not
;	had its rate controls left in an invalid state on older at's.
;
;	it checks for an at model byte "fc" with a submodel type of
;	00, 01, 02, 03 or 06 and resets the periodic interrupt rate
;	bits in case post has not done it.  this initilization routine
;	is only needed once when dos loads.  it should be run as soon
;	as possible to prevent slow diskette access.
;
;	this code exposes one to dos clearing cmos setup done by a
;	resident program that hides and re-boots the system.

cmosck	proc	near			; check and reset rtc rate bits
	assume	ds:datagrp,es:nothing

;model byte and submodel byte were already determined in msinit.

	push	ax
	cmp	ds:model_byte,0fch	;check for pc-at model byte
					; exit if not "fc" for a pc-at
	jne	cmosck9 		; exit if not an at model

	cmp	ds:secondary_model_byte,06h  ; is it 06 for the industral at
	je	cmosck4 		; go reset cmos periodic rate if 06
	cmp	ds:secondary_model_byte,04h  ; is it 00, 01, 02, or 03
	jnb	cmosck9 		; exit if problem fixed by post
					; also,secondary_model_byte = 0 when ah=0c0h, int 15h failed.
cmosck4:				;	reset the cmos periodic rate
					;  model=fc submodel=00,01,02,03 or 06

	mov	al,cmos_reg_a or nmi	;nmi disabled on return
	mov	ah,00100110b		;set divider & rate selection
	call	cmos_write

					; clear set,pie,aie,uie and sqwe
	mov	al,cmos_reg_b or nmi	;nmi disabled on return
	call	cmos_read
	and	al,00000111b		;clear set,pie,aie,uie,sqwe
	mov	ah,al
	mov	al,cmos_reg_b		;nmi enabled on return
	call	cmos_write


cmosck9:				; exit routine
	pop	ax
	ret				; return to caller
					;  flags modifyied
cmosck	endp


;--- cmos_read -----------------------------------------------------------------
;		read byte from cmos system clock configuration table	       :
;									       :
; input: (al)=	cmos table address to be read				       :
;		bit    7 = 0 for nmi enabled and 1 for nmi disabled on exit    :
;		bits 6-0 = address of table location to read		       :
;									       :
; output: (al)	value at location (al) moved into (al).  if bit 7 of (al) was  :
;		on then nmi left disabled.  during the cmos read both nmi and  :
;		normal interrupts are disabled to protect cmos data integrity. :
;		the cmos address register is pointed to a default value and    :
;		the interrupt flag restored to the entry state on return.      :
;		only the (al) register and the nmi state is changed.	       :
;-------------------------------------------------------------------------------

cmos_read	proc	near		; read location (al) into (al)
	assume	es:nothing,ds:nothing

	pushf				; save interrupt enable status and flags
	cli
	push	bx
	push	ax			;save user nmi state
	or	al,nmi			;disable nmi for us
	out	cmos_port,al
	nop				;undocumented delay needed
	in	al,cmos_data		;get data value

;	set nmi state to user specified

	mov	bx,ax			;save data value
	pop	ax			;get user nmi
	and	al,nmi
	or	al,cmos_shut_down
	out	cmos_port,al
	nop
	in	al,cmos_data

	mov	ax,bx			;data value
	pop	bx

	push	cs			; *place datagrp segment in stack and
	call	cmos_popf		; *handle popf for b- level 80286
	ret				; return with flags restored

cmos_read	endp

cmos_popf	proc	near		; popf for level b- parts
	iret				; return far and restore flags

cmos_popf	endp

;--- cmos_write ----------------------------------------------------------------
;		write byte to cmos system clock configuration table	       :
;									       :
; input: (al)=	cmos table address to be written to			       :
;		bit    7 = 0 for nmi enabled and 1 for nmi disabled on exit    :
;		bits 6-0 = address of table location to write		       :
;	 (ah)=	new value to be placed in the addressed table location	       :
;									       :
; output:	value in (ah) placed in location (al) with nmi left disabled   :
;		if bit 7 of (al) is on.  during the cmos update both nmi and   :
;		normal interrupts are disabled to protect cmos data integrity. :
;		the cmos address register is pointed to a default value and    :
;		the interrupt flag restored to the entry state on return.      :
;		only the cmos location and the nmi state is changed.	       :
;-------------------------------------------------------------------------------

cmos_write	proc	near		; write (ah) to location (al)
	assume	es:nothing,ds:nothing
	pushf				; save interrupt enable status and flags
	push	ax			; save work register values

	cli
	push	ax			; save user nmi state
	or	al,nmi			; disable nmi for us
	out	cmos_port,al
	nop
	mov	al,ah
	out	cmos_data,al		; write data

;   set nmi state to user specified

	pop	ax			; get user nmi
	and	al,nmi
	or	al,cmos_shut_down
	out	cmos_port,al
	nop
	in	al,cmos_data

	pop	ax			; restore work registers
	push	cs			; *place datagrp segment in stack and
	call	cmos_popf		; *handle popf for b- level 80286
	ret

cmos_write	endp

ENDIF	; NOT POWER

drvfat	dw	0000			;drive and fat id of dos
bios_l	label	word
boot_drive_copy dw	0
bios_h	label	word
saved_boot_bp	dw	0
doscnt	label	word
saved_boot_ss	dw	0
fbigfat db	0			; flags for drive

init_bootseg	dw	?		; segment for the boot record buffer
rom_drv_num	db	80h
init_temp_h	dw	0		; high word of intermediate division
dsktnum	db	1		; number of diskette drives

; the following two bytes are used to save the info returned by int 13, ah = 8
; call to determine drive parameters.

num_heads db	2			; number of heads returned by rom
sec_trk   db	9			; sec/trk returned by rom
num_cyln  db	40			; number of cylinders returned by rom

fakefloppydrv db      0 		; if 1, then no diskette drives in the system.

bootbias  =	200h
boot_addr =	7c00h

	db	90h			; align in Bios_Data
disktable dw	512,  0100h,  64,0
	dw	2048, 0201h, 112,0
	dw	8192, 0402h, 256,0
	dw	32680,0803h, 512,0	;warning !!! old values
	dw	65535,1004h,1024,0



; default disktable under the assumption of total fat size <= 128 kb, and
;	the maxium size of fat entry = 16 bit.

disktable2  dw	 0, 32680, 0803h, 512, 0	;for compatibility.
	    dw	4h, 0000h, 0402h, 512, fbig	;covers upto 134 mb media.
	    dw	8h, 0000h, 0803h, 512, fbig	;	upto 268 mb
	    dw 10h, 0000h, 1004h, 512, fbig	;	upto 536 mb
	    dw 20h, 0000h, 2005h, 512, fbig	;	upto 1072 mb
	    dw 40h, 0000h, 4006h, 512, fbig	;	upto 2144 mb
	    dw 80h, 0000h, 8007h, 512, fbig	;	upto 4288 mb...

;******************************************************
;variables for mini disk initialization
;******************************************************

;M011 -- begin changed section

init_sysinit_seg dw	sysinitseg
rom_minidisk_num db	0		; temp variable for phys unit
hnum		db	0		; real number of hardfiles
end_of_bdss	dw	bdss		;offset value of the ending address
					;of bds table. needed to figure out
					;the dosdatasg address.
mini_hdlim	dw	0
mini_seclim	dw	0

;M011 -- end changed section

;end of mini disk init variables *********************


bios_date db	'01/10/84',0		;used for checking at rom bios date.
bdate_l	=	(offset $)-(offset bios_date)

; the following are the recommended bpbs for the media that we know of so
; far.

bpbx	struc
	dw	512
	db	?
	dw	1
	db	2
	dw	?
	dw	?
	db	?
	dw	?
	dw	?
	dw	2
	dw	0
	dw	0		; hidden sector high
	dd	0		; extended total sectors
bpbx	ends


	db	90h			; align in Bios_Data

bpb48t	bpbx	<,2,,,112,2*9*40,0fdh,2,9>	; 48 tpi diskettes
	db	90h			; align in Bios_Data
bpb96t	bpbx	<,1,,,224,2*15*80,0f9h,7,15>	; 96 tpi diskettes
	db	90h			; align in Bios_Data
bpb35	bpbx	<,2,,,70h,2*9*80,0f9h,3,9>	; 3.5" diskettes
	db	90h			; align in Bios_Data
bpb288	bpbx	<,2,,,240,2*36*80,0f0h,9,36>	; 2.88MB diskettes	; m037
	db	90h			; align in Bios_Data
bpbtable dw	offset datagrp:bpb48t	; 48tpi drives
	dw	offset datagrp:bpb96t;	; 96tpi drives
	dw	offset datagrp:bpb35	; 3.5" drives
	dw	offset datagrp:bpb35	; unused 8" diskette	DUMMY m037
	dw	offset datagrp:bpb35	; unused 8" diskette 	DUMMY m037
	dw	offset datagrp:bpb35	; used for hard disk	DUMMY m037
	dw	offset datagrp:bpb35	; used for tape drive	DUMMY m037
	dw	offset datagrp:bpb35	; FFOTHER		DUMMY m037
	dw	offset datagrp:bpb35	; ERIMO			DUMMY m037
	dw	offset datagrp:bpb288	; 2.88MB drive		      m037

;	entry point to call utility functions in Bios_Code.  At this time,
;	  we aren't doing any A20 switching.  During MSINIT time Bios_Code
;	  will not yet be moved to its final resting place, so we know
;	  it'll be low.
;
;	load bp with the offset of the function to call in Bios_Code.
;	  call_bios_code saves the near return address.  This routine will
;	  push the address of a retf in Bios_Code onto the stack which
;	  will get executed when the utility function finishes.  It will
;	  then transfer control to Bios_Code:bp using a couple of pushes
;	  and a retf

	extrn	cdev:dword

flp_drvs	db	0
rom_floppy_drives db	0
bios_call_return	dw	0
addr_of_bcretf	dw	bc_retf
bios_call_segment	dw	Bios_Code

call_bios_code proc near
	assume	ds:nothing, es:nothing

	pop	cs:bios_call_return
	push	cs
	push	cs:bios_call_return
	push	cs:addr_of_bcretf
	push	cs:bios_call_segment
	push	bp
	retf

call_bios_code endp




;===========================================================================
;
; entry from boot sector.  the register contents are:
;
;   dl = int 13 drive number we booted from
;   bx = first data sector on disk.
;   ax = first data sector (high)
;   di = boot load segment
;   ss:bp = saved boot record
;
	public	init
init	proc	near
	assume	ds:nothing,es:nothing

;
;M043; Begin changes
; This code has been added for IBM. It checks for IBM hardware and refuses
;to boot if the machine is not a true-blue IBM.
;

IF	0
ifdef 	IBM_VERSION

COPYR_LEN	equ	31

	push	ax
	push	bx
	push	cx
	push	di

	mov	ax,0fac0h
	mov	es,ax			; es = ROM Copyright segment
	mov	di,09bh		; es:di points at copyright
	push	cs
	pop	ds
	mov	si,offset datagrp:CopyrightIBM	; ds:si = copyright string
	mov	cx,COPYR_LEN		; length of string
	cld
	repz	cmpsb
	jz	isIBM			; copyright compared, IBM

;
;Check for IBM Basic Lite
;
 	mov	ah,22h
	int	15h
	jc	NotIBM			; not an IBM machine

	or	ah,ah
	jz	isIBM			; is an IBM Basic Lite

NotIBM:
	mov	si,offset datagrp:IBMBootFailMsg	;
	mov	bx,7			; setup display page
shIBMmsg:
	lodsb
	or	al,al
	jz	IBMstall		; done with message, stall

	mov	ah,14
	int	10h			; write teletype
	jmp	short shIBMmsg

IBMstall:
	jmp	short IBMstall		;hang 

CopyrightIBM	db	'The IBM Personal Computer Basic'

	include msbio.cl8		; the boot fail message

isIBM:					; IBM machine, continue init
	pop	di
	pop	cx
	pop	bx
	pop	ax

endif
ENDIF

;
;M043; End changes
;

	cli
	cld
	sub	si,si
	mov	ds,si
	mov	cs:saved_boot_bp,bp
	mov	cs:saved_boot_ss,ss
	mov	ss,si
	mov	sp,700h
	mov	cs:drvfat,dx
	mov	cs:boot_drive_copy,dx
	push	ds
	mov	ds,cs:init_sysinit_seg
	assume	ds:sysinitseg
	mov	boot_load_segment,di
	mov	boot_data_high,ax
	mov	boot_data_low,bx
	push	cs
	pop	ds
	assume	ds:datagrp
	mov	bios_flags,1000h
	jmp	short init_cpu_check

; Display a zero- or dollar-terminated initialization message.
init_message:
	lodsb
	test	al,al
	jz	init_message_done
	cmp	al,'$'
	jz	init_message_done
	mov	ah,0eh
	mov	bx,7
	int	10h
	jmp	short init_message
init_message_done:
	ret

; Determine the processor class from the writable FLAGS bits.
init_cpu_check:
	pushf
	push	bx
	xor	bx,bx
	xor	ax,ax
	push	ax
	popf
	pushf
	pop	ax
	and	ax,0f000h
	cmp	ax,0f000h
	jz	init_cpu_done
	mov	ax,0f000h
	push	ax
	popf
	pushf
	pop	ax
	and	ax,0f000h
	jz	init_cpu_286
	inc	bx
init_cpu_286:
	inc	bx
init_cpu_done:
	mov	ax,bx
	pop	bx
	popf
	cmp	ax,2
	jae	init_cpu_ok
	mov	si,offset sysinit_msg_base
	add	si,sysinit_msg_table+sysinit_cpu_msg
	call	init_message
init_cpu_halt:
	hlt
	jmp	short init_cpu_halt
init_cpu_ok:
	pop	ds

; Save the original vectors and controller masks for the system loader.

	mov	ah,0fh
	int	10h
	sub	si,si
	mov	ax,50h
	mov	es,ax
	mov	di,3ch
	mov	ax,ds:[413h]		; conventional memory size
	stosw
	mov	ax,ds:[40eh]		; extended BIOS data segment
	stosw
	mov	cx,40h
	rep	movsw
	xor	ax,ax
	mov	es:[0a4h],ax
	mov	es:[0a6h],ax
	mov	si,100h
	mov	cx,8
	rep	movsw
	add	si,8
	movsw
	movsw
	add	si,10h
	movsw
	movsw
	add	si,0ch
	movsw
	movsw
	mov	si,1c0h
	mov	cx,10h
	rep	movsw
	in	al,0a1h
	mov	ah,al
	in	al,21h
	stosw
	mov	cx,di
	mov	di,3ch
	sub	cx,di
	shr	cx,1
	sub	ax,ax
init_vector_sum:
	add	ax,es:[di]
	add	di,2
	loop	init_vector_sum
	stosw

; with the following information from msload, we don't need the
;     boot sector any more.-> this will solve the problem of 29 kb size
;     limitation of msbio.com file.
;
;

; Save ROM vectors and install the BIOS interrupt handlers.

	push	cs
	pop	es
	mov	cx,NUMROMVECTORS
	mov	si,offset RomVectors
init_next_vector:
	lods	byte ptr es:[si]
	cbw
	.286
	shl	ax,2
	.8086
	mov	di,ax
	xchg	si,di
	lodsw
	stosw
	lodsw
	stosw
	xchg	si,di
	loop	init_next_vector
	mov	ax,word ptr es:Old13
	mov	word ptr es:Orig13,ax
	mov	ax,word ptr es:Old13+2
	mov	word ptr es:Orig13+2,ax
	mov	word ptr ds:[13h*4],offset block13
	mov	ds:[13h*4+2],cs
	mov	word ptr ds:[15h*4],offset Int15
	mov	ds:[15h*4+2],cs
	mov	ax,offset int16_entry
	xchg	ax,ds:[16h*4]
	mov	word ptr es:int16_old,ax
	mov	ax,cs
	xchg	ax,ds:[16h*4+2]
	mov	word ptr es:int16_old+2,ax
	mov	word ptr ds:[19h*4],offset int19
	mov	ds:[19h*4+2],cs
	sub	ax,ax
	mov	ds:[500h],ax
	mov	ds:[lstdrv],ax
	push	ds
	pop	es
	mov	di,530h
	stosw
	stosw
	stosw
	stosw
	mov	ax,cs
	mov	word ptr ds:[1bh*4],offset cbreak
	mov	ds:[1bh*4+2],ax
	mov	word ptr ds:[29h*4],offset outchr
	mov	ds:[29h*4+2],ax
	mov	di,4
	mov	bx,offset intret
	push	es
	push	di
	les	di,es:[di]
	cmp	di,2
	jb	init_debug_check
	cmp	word ptr es:[di-2],'PJ'
init_debug_check:
	pop	di
	pop	es
	jz	init_debug_vectors
	xchg	ax,bx
	stosw
	xchg	ax,bx
	stosw
	add	di,4
	xchg	ax,bx
	stosw
	xchg	ax,bx
	stosw
init_debug_vectors:
	mov	di,10h
	xchg	ax,bx
	stosw
	xchg	ax,bx
	stosw

	sti
	int	11h			;get equipment status

; we have to support a system that does not have any diskette
;drives but only hardfiles.  this system will ipl from the hardfile.
;if the equipment flag bit 0 is 1, then the system has diskette drive(s).
;otherwise, the system has only hardfiles.
;
;important thing is that still, for compatibility reason, the drive letter
;for the hardfiles start from "c".  so, we still need to allocate dummy bds
;drive a and drive b.	at sysinit time, we are going to set cds table entry
;of dpb pointer for these drives to 0, so any user attempt to access this
;drives will get "invalid drive letter ..." message.  we are going to
;establish "fakefloppydrv" flag.  ***sysinit module should call int 11h to
;determine whether there are any diskette drivers in the system or not.!!!***

;	check the register returned by the equipment determination interrupt
;	we have to handle the case of no diskettes in the system by faking
;	two dummy drives.
;
;	if the register indicates that we do have floppy drives we don't need
;	to do anything special.
;
;	if the register indicates that we don't have any floppy drives then
;	what we need to do is set the fakefloppydrv variable, change the
;	register to say that we do have floppy drives and then go to execute
;	the code which starts at notsingle.  this is because we can skip the
;	code given below which tries to find if there are one or two drives
;	since we already know about this.


	if	ibmcopyright

;************************************************************************
; p????
;
; the following fix for lloyds of london does work correctly but it
; causes a regression in the ripl machine. machines with no ipl
; diskette will have ax bit 0 = 0. the cds structure is stomped on
; later to insure that a: is a invalid drive. this is where ripl fails.
; it wants the a: drive to be valid because it intercepts requests
; to the drive and returns info from it's memory image. but, if ibmbio
; finds no ipl drive, it tells ibmdos never to request anything from
; that drive.
;
; for the meantime, we will take out the support for lloyds of london
; by setting up a false condition. (ie. ax=1).
; (they have a special build, dos 3.31 to use). architecture needs to
; get the ripl machine to set bit 0 to say that there is in fact an
; virtual ipl diskette.
;
; the next 4 lines of code should be removed when the ripl people have
; gotten their act together. the unique identifier is used in case in
; the future, we want to dynamically patch ibmbio to work on the lloyds
; machine. the program could be written to scan for:
;
;	ebh,03h,52h,50h,53h,0dh,01h
;	 "jmp"	"R" "P" "S"  or  1
;
; and dynamically change the 0dh,01h to 90h,90h. note: that this string
; must be changed twice in ibmbio.com.
;************************************************************************

	jmp    short set_bit		; jmup over db
	db     "RPS"			; unique identifier

set_bit:
	or     ax,1			; turn on the ipl bit
;************************************************************************

	endif


	test	ax,1
	jnz	normalfloppydrv
	push	ax
	xor	cl,cl
	mov	ah,8
	mov	dl,0
	int	13h
	jc	init_floppy_result
	mov	cs:rom_floppy_drives,dl
init_floppy_result:
	test	cl,cl
	jz	init_floppy_probe_done
	test	dl,dl
	jnz	init_floppy_probe_done
	mov	es,cs:init_sysinit_seg
	assume	es:sysinitseg
	mov	es:no_floppy_report,1
init_floppy_probe_done:
	pop	ax
	jc	normalfloppydrv
	cmp	cs:rom_floppy_drives,0
	jz	init_no_floppy
	mov	al,cs:rom_floppy_drives
	dec	ax
	jmp	short got_num_flp_drvs
init_no_floppy:
	mov	ax,1
	mov	cs:fakefloppydrv,al
	jmp	short settwodrive
normalfloppydrv:
	rol	al,1
	rol	al,1
got_num_flp_drvs:
	and	ax,3
	jnz	notsingle
	inc	ax
settwodrive:
	inc	cs:flp_drvs
notsingle:
	inc	ax
	mov	cs:drvmax,al
	test	byte ptr cs:drvfat,80h
	jnz	gothrd
	xor	ax,ax
gothrd:
	mov	byte ptr cs:drvfat,al

; let model_byte, secondary_model_byte be set here!!!

	mov	ah,0c0h 		; return system environment
	int	15h			; call rom-bios routine

	jc	no_rom_system_conf	; just use model_byte
	or	ah,ah			; double check
	jne	no_rom_system_conf

	mov	al,es:[bx.bios_sd_modelbyte] ;get the model byte
	mov	cs:[model_byte],al
	mov	al,es:[bx.bios_sd_scnd_modelbyte] ;secondary model byte
	mov	cs:[secondary_model_byte],al
	jmp	short turn_timer_on

no_rom_system_conf:
	mov	si,0ffffh
	mov	es,si
	mov	al,es:[0eh]		; get model byte
	mov	cs:model_byte,al		; save model byte

turn_timer_on:
	mov	al,eoi
	out	akport,al		;turn on the timer

;	some olivetti m24 machines have an 8530 serial communications
;	  chip installed at io address 50h and 52h.  if we're running
;	  on one of those, we must inhibit the normal aux port initialization

	cmp	cs:model_byte,0		; next to last byte in rom bios
	jnz	not_olivetti_m24	; skip for all other machines

;	now we know we're on an m24.  read the configuration switch to
;	  see if we think we have an 8530 chip.

	in	al,66h
	test	al,20h			; is 8530 installed?
	jz	not_olivetti_m24	;  we're done if not

;	now double check to make sure the device is really there

	mov	al,0fh
	out	50h,al
	in	al,50h
	test	al,1			; this test was copied from olivetti
	jz	skip_aux_port_init	; take this branch if 8530 installed

not_olivetti_m24:

	mov	al,3		; init com4
	call	aux_init
	mov	al,2		; init com3
	call	aux_init
	mov	al,1		; init com2
	call	aux_init
	xor	al,al		; init com1
	call	aux_init

skip_aux_port_init:
	mov	al,2		; init lpt3
	call	print_init
	mov	al,1		; init lpt2
	call	print_init
	xor	al,al		; init lpt1
	call	print_init


;	we need to initalize the motorstartup variable in Bios_Code from the disk
;	parameter table at sec9.  the offsets in this table are defined in
;	the disk_parms struc in msdskprm.inc.  2 locs

	mov	es,word ptr cs:[cdev+2]	; BIOS code segment
	assume	es:nothing
	mov	al,ds:sec9 + disk_motor_strt
	mov	es:motorstartup,al
	cmp	cs:model_byte,0fdh
	jb	no_diddle
	mov	word ptr ds:(sec9 + disk_head_sttl),0200h+normsettle
	mov	ds:(sec9 + disk_specify_1),0dfh
no_diddle:
	int	12h
	mov	cl,6
	shl	ax,cl
	mov	dx,ax
	push	ax
	lds	bx,ds:dword ptr [2fh*4]
	assume	ds:nothing
	cmp	word ptr ds:[bx+3],'PR'
	jne	SkipRPL
	cmp	byte ptr ds:[bx+5],'L'
	jne	SkipRPL
	mov	cx,ax
	mov	ax,(multMULT shl 8) + multMULTRPLTOM
	int	2fh
	mov	ax,dx
	cmp	ax,cx
	jne	init_memory_set
SkipRPL:
	sub	dx,dx
init_memory_set:
	sub	ax,32
	mov	word ptr cs:disksector_ptr+2,ax
	sub	ax,64
	mov	cs:init_bootseg,ax
	pop	ax

	mov	ds,cs:init_sysinit_seg
	assume	ds:sysinitseg
	mov	word ptr device_list,offset res_dev_list
	mov	word ptr device_list+2,cs
	mov	memory_size,ax
	mov	rpl_memory_size,dx
	mov	al,cs:model_byte
	mov	sys_model_byte,al
	mov	al,cs:secondary_model_byte
	mov	sys_scnd_model_byte,al
	mov	ax,cs:drvfat
	inc	ax
	mov	default_drive,al
	mov	ax,cs:boot_drive_copy
	push	ds
	push	ds
	pop	es
	mov	di,offset boot_copy_buffer
	lds	si,cs:dword ptr saved_boot_bp
	assume	ds:nothing
	mov	cx,23h
	rep	movsw
	pop	ds
	assume	ds:sysinitseg
	stosw
	mov	ax,cs:dosdatasg
	mov	sysinit_bios_start,ax
	add	ax,15
	.286
	shr	ax,4
	.8086
	mov	sysinit_bios_paras,ax
	mov	cx,offset sysinit_reserve_size
	mov	sysinit_reserve_count,cx
	add	boot_load_segment,70h
	sub	boot_load_segment,cx
	sub	boot_load_segment,ax
	add	ax,sysinit_reserve_count
	mov	es,ax
	sub	cx,cx
	cmp	es:[0],cx
	xchg	cx,boot_load_segment
	jcxz	init_load_ready
	jz	init_load_ready
	mov	boot_load_segment,cx
	mov	boot_reloc_segment,ax
init_load_ready:

; Protect against spurious interrupt 0Fh from old printer adapters.

	assume	ss:nothing
	mov	ax,word ptr ss:[0fh*4+2]
	cmp	ax,memory_size
	jb	resetintf
	cmp	ax,0f000h
	jne	keepintf
resetintf:
	mov	word ptr ss:[0fh*4],offset intret
	mov	word ptr ss:[0fh*4+2],cs
keepintf:
	push	cs
	pop	ds
	push	cs
	pop	es
	assume	ds:datagrp,es:datagrp
	mov	cl,ss:[496h]
	test	cl,10h
	jz	org_key
	mov	keyrd_func,10h
	mov	keysts_func,11h
org_key:
	call	cmos_clock_read
	mov	bp,offset read_real_date
	call	call_bios_code
	mov	hdrv_pat,offset harddrv
	mov	al,drvmax
	mov	dsktnum,al
	xor	ax,ax
	mov	hnum,al

;  The following code is to support dual hard disk controllers on
;  Compaq systems ('mode 2').
;
;  Here we attempt to setup INT 13h, mode 2
;  We must execute this code before any INT 13h to fixed disks

	push	ds
	mov	ax,0f000h
	mov	ds,ax
	assume	ds:nothing
	cmp	word ptr ds:[0ffeah],'OC'
	jnz	init_not_compaq
	cmp	word ptr ds:[0ffech],'PM'
	jnz	init_not_compaq
	cmp	word ptr ds:[0ffeeh],'QA'
	jnz	init_not_compaq
	jmp	short init_compaq
init_not_compaq:
	pop	ds
	jmp	short skip_mode2
init_compaq:
	pop	ds
	assume	ds:datagrp
	mov	ax,0e400h
	int	15h
	jc	skip_mode2
	test	bx,40h
	jnz	skip_mode2
	mov	dl,80h
	mov	ah,8
	int	13h
	jc	init_cmos_disks
	mov	hnum,dl
init_cmos_disks:
	cli
	mov	al,19h
	out	70h,al
	in	al,71h
	sti
	xor	ah,ah
	test	al,0ffh
	jz	init_cmos_disk2
	inc	ah
init_cmos_disk2:
	cli
	mov	al,1ah
	out	70h,al
	in	al,71h
	sti
	test	al,0ffh
	jz	init_cmos_count
	inc	ah
init_cmos_count:
	mov	al,hnum
	sub	al,ah
	mov	hnum,al
	push	ds
	push	dx
	mov	dx,40h
	mov	ds,dx
	mov	ds:[75h],ah
	pop	dx
	pop	ds
	or	bx,40h
	mov	ax,0e480h
	int	15h
skip_mode2:
	mov	dl,80h
	mov	ah,8
	int	13h
	jnc	init_count_disks
	mov	dl,0
init_count_disks:
	add	dl,hnum
	mov	hnum,dl
	mov	byte ptr hdrv_pat+2,dl
	push	ds
	mov	ax,40h
	mov	ds,ax
	mov	ds:[75h],dl
	pop	ds

; scan the list of drives to determine their type.  we have three flavors of
; diskette drives:
;
;   48tpi drives    we do nothing special for them
;   96tpi drives    mark the fact that they have changeline support.
;   3.5"  drives    mark changeline support and small.
;
; the following code uses registers for certain values:
;
;   dl - physical drive
;   ds:di - points to current bds
;   cx - flag bits for bds
;   dh - form factor for the drive (1 - 48tpi, 2 - 96tpi, 3 - 3.5" medium)

	xor	dl,dl
	mov	di,offset start_bds

; check if the system has no physical diskette drives.
; if it is, then we don't have to set bds tables.  but since we
; pretend that we have 2 floppies, we are going to reserve two
; bds tables for the fake drive a, and b. and set the end of link
; pointer.

;*********************************************************
;	check to see if we are faking floppy drives.  if not we don't
;	do anything special.  if we are faking floppy drives we need
;	to set aside two bdss for the two fake floppy drives.  we
;	don't need to initalise any fields though. so starting at start_bds
;	use the link field in the bds structure to go to the second bds
;	in the list and initalise it's link field to -1 to set the end of
;	the list.  then jump to the routine at dohard to allocate/initialise
;	the bds for harddrives.

	cmp	fakefloppydrv,1
	jnz	loop_drive
	les	di,es:[di].bds_link
	les	di,es:[di].bds_link
	mov	word ptr es:[di].bds_link,-1
	jmp	dohard
loop_drive:
	cmp	dl,drvmax
	jb	got_more
	jmp	done_drives
got_more:
	xor	cx,cx			; zero all flags
	les	di,es:[di].bds_link	; get next bds
	mov	dh,ff48tpi		; set form factor to 48 tpi
	mov	num_cyln,40		; 40 tracks per side

	push	ds
	push	di
	push	dx
	push	cx
	push	es

	mov	ah,8			;get drive parameters
	int	13h			;call rom-bios
	jc	noparmsfromrom		; got an old rom

; if cmos is bad, it gives es,ax,bx,cx,dh,di=0. cy=0.
;in this case, we are going to put bogus informations to bds table.
;we are going to set ch=39,cl=9,dh=1 to avoid divide overflow when
;they are calculated at the later time.  this is just for the diagnostic
;diskette which need msbio,msdos to boot up before it sets cmos.
;this should only happen with drive b.

	cmp	ch,0			; if ch=0, then cl,dh=0 too.
	jne	pfr_ok

	mov	ch,39			; rom gave wrong info.
	mov	cl,9			; let's default to 360k.
	mov	dh,1

pfr_ok:
	inc	dh			; make number of heads 1-based
	inc	ch			; make number of cylinders 1-based
	mov	num_heads,dh		; save parms returned by rom
	and	cl,00111111b		; extract sectors/track
	mov	sec_trk,cl
	mov	num_cyln,ch		; assume less than 256 cylinders!!

; make sure that eot contains the max number of sec/trk in system of floppies

	mov	es,word ptr [cdev+2]
	assume	es:Bios_Code
	cmp	cl,es:eot		; may set carry
	jbe	eot_ok
	mov	es:eot,cl
eot_ok:
	pop	es
	assume	es:nothing
	pop	cx
	pop	dx
	pop	di
	pop	ds

; check for changeline support on drive

	mov	ah,15h 		; set command to get dasd type
	int	13h			; call rom-bios
	jc	changeline_done

	cmp	ah,02			; check for presence of changeline
	jne	changeline_done

; we have a drive with change line support.

	or	cl,fchangeline		; signal type
	or	bios_flags,2		; remember that we have 96tpi disks

; we now try to set up the form factor for the types of media that we know
; and can recognise. for the rest, we set the form factor as "other".

changeline_done:

; 40 cylinders and 9 or less sec/trk, treat as 48 tpi medium.

	cmp	num_cyln,40
	jnz	try_80

	cmp	sec_trk,9
	jbe	nextdrive

gotother:
	mov	dh,ffother		; we have a "strange" medium
	jmp	short nextdrive

; 80 cylinders and 9 sectors/track => 720 kb device
; 80 cylinders and 15 sec/trk => 96 tpi medium

try_80:
	cmp	num_cyln,80
	jnz	gotother

	mov	dh, ff288		; assume 2.88 MB drive	m037
	cmp	sec_trk, 36		; is it ?		m037
	je	nextdrive		; yeah, go update	m037
	
	cmp	sec_trk,15
	jz	got96

	cmp	sec_trk,9
	jnz	gotother

	mov	dh,ffsmall
	jmp	short nextdrive

got96:
	mov	dh,ff96tpi
	jmp	short nextdrive

; we have an old rom, so we either have a 48tpi or 96tpi drive. if the drive
; has changeline, we assume it is a 96tpi, otherwise we treat it as a 48tpi.

noparmsfromrom:
	pop	es
	pop	cx
	pop	dx
	pop	di
	pop	ds

	mov	ah,15h			; set command to get dasd type
	int	13h			; call rom-bios

	jc	nextdrive
	cmp	ah,2			; is there changeline?
	jnz	nextdrive

	or	cl,fchangeline
	or	bios_flags,2		; remember that we have 96tpi drives
	mov	num_cyln,80
	mov	dh,ff96tpi
	mov	al,15			; set eot if necessary
	push	es
	mov	es,word ptr [cdev+2]
	assume	es:Bios_Code
	cmp	al,es:eot
	jbe	eot_ok2
	mov	es:eot,al
eot_ok2:
	pop	es
	assume	es:nothing

nextdrive:
	or	cl,fi_own_physical
	mov	bh,dl
	cmp	flp_drvs,1
	jbe	not_special
	dec	bh
	xor	cl,fi_own_physical
not_special:
	xor	ax,ax
	mov	al,num_heads
	mov	es:[di].BDS_RBPB.BPB_HEADS,ax
	mov	al,sec_trk
	mov	es:[di].BDS_RBPB.BPB_SECTORSPERTRACK,ax
	mov	es:[di].bds_flags,cx
	mov	es:[di].bds_formfactor,dh
	mov	es:[di].bds_drivelet,dl
	mov	es:[di].bds_drivenum,bh
	mov	bl,num_cyln
	mov	byte ptr es:[di].bds_ccyln,bl
	cmp	flp_drvs,1
	jnz	no_single
	inc	flp_drvs
	or	bios_flags,4
	or	cx,fi_am_mult
	or	es:[di].bds_flags,cx
	les	di,es:[di].bds_link
	inc	dl
	jmp	short nextdrive
no_single:
	inc	dl
	jmp	loop_drive

done_drives:
	mov	word ptr es:[di].bds_link,-1

; set up all the hard drives in the system

dohard:
	.386
	or	ecx,-1
	.8086
	mov	dh,hnum
	or	dh,dh
	jz	init_cpu_ecx
	mov	dl,80h
dohard1:
	push	dx
	mov	di,end_of_bdss
	mov	bl,drvmax
	mov	bh,0
	call	sethard
	jc	hardfile_err
	call	dmax_check
	jnc	hardfile_err
	call	xinstall_bds
hardfile_err:
	pop	dx
	inc	dl
	dec	dh
	jnz	dohard1
	call	domini
	mov	dh,hnum
	mov	dl,80h
dohardx1:
	mov	bh,1
dohardx2:
	push	dx
	push	bx
	mov	di,end_of_bdss
	mov	bl,drvmax
	call	sethard
	jc	dohardx4
	call	dmax_check
	jnc	dohardx4
	call	xinstall_bds
	pop	bx
	pop	dx
	inc	bh
	jmp	short dohardx2
dohardx4:
	pop	bx
	pop	dx
	inc	dl
	dec	dh
	jnz	dohardx1
	cmp	dsktnum,2
	jbe	init_cpu_ecx
	call	remap
no_remap:

	assume	es:nothing

; end of drive initialization.

; we now decide, based on the configurations available so far, what
;code or data we need to keep as a stay resident code.	the following table
;shows the configurations under consideration.	they are listed in the order
;of their current position memory.
;
;configuration will be done in two ways:
;
;first, we are going to set "static configuration".  static configuration will
;consider from basic configuration to endof96tpi configuration.  the result
;of static configuration will be the address the dynamic configuration will
;use to start with.
;
;secondly, "dynamic cofiguration" will be performed.  dynamic configuration
;involves possible relocation of code or data.	dynamic configuration routine
;will take care of bdsm tables and at rom fix module thru k09 suspend/resume
;code individually.  after these operation, [dosdatasg] will be set.
;this will be the place sysinit routine will relocate msdos module for good.

;M011 -- begin changed section

;
;   1.	 basic configuration for msbio (endfloppy)
;   2.   end96tpi	; a system that supports "change line error"
;   3.	 end of bdss	; end of bdss for hard disks
;   4.	 endatrom	;some of at rom fix module.
;   5.	 endcmosclockset;supporting program for cmos clock write.
;   6.	 endk09 	;k09 cmos clock module to handle suspend/resume operation.
;


init_cpu_ecx:
; Install the ECX save and restore sequence when the processor supports it.

push_ecx_word	equ	5166h
pop_cx_byte	equ	59h
push_cx_byte	equ	51h
pop_ecx_word	equ	5966h

	.386
	push	ecx
	xor	ecx,ecx
	pop	cx
	pop	cx
	inc	cx
	jz	short static_configure
	mov	word ptr call_orig13+4,push_ecx_word
	mov	byte ptr call_orig13+6,pop_cx_byte
	mov	byte ptr call_orig13+1ah,push_cx_byte
	mov	word ptr call_orig13+1bh,pop_ecx_word
	.8086

static_configure:
	mov	di,offset datagrp:ibm_disk_io

;M011 -- end changed section

	cmp	model_byte,0fch		;at ?
	jnz	checkcompaqbug		; M015
	cmp	hnum,0			;no hard file?
	jz	checkcompaqbug		; M015

	xchg	ax,di			; save allocation pointer in ax
	mov	si,0f000h
	mov	es,si			;es -> bios segment
	assume	es:nothing

	mov	si,offset datagrp:bios_date ; only patch rom with this date
	mov	di,0fff5h		;  rom bios string is at f000:fff5
	mov	cx,bdate_l
	repz	cmpsb			; check for date + zero on end
	xchg	ax,di			; restore allocation pointer

;	M015 -- begin changes

	jnz	checkcompaqbug

;	install at rom fix

	mov	cx,offset datagrp:endatrom
	mov	si,offset datagrp:ibm_disk_io
	jmp	short install_int13_patch

;	M065 -- begin changes
;
;	On certain systems with Western Digital disk controllers, the
;	following detection scheme caused an unpredictable and serious
;	failure.  In particular, they've implemented a nonstandard
;	Int13(ah=16h) which reconfigures the hard drive, depending on
;	what happens to be at es:[bx] and other memory locations indexed
;	off of it.
;
;	Compaq was unable to tell us exactly which kind of systems have
;	the bug, except that they guarantee that the bug was fixed in
;	ROM BIOSs dated 08/04/86 and later.  We'll check for the COMPAQ
;	string, and then look for date codes before 08/04/86 to decide
;	when to install the hook.

checkcompaqbug:
	mov	ax,0f000h		; point to ROM BIOS
	mov	es,ax

	cmp	es:word ptr [0ffeah],'OC'	; look for COMPAQ
	jnz	not_compaq_patch
	cmp	es:word ptr [0ffech],'PM'
	jnz	not_compaq_patch
	cmp	es:word ptr [0ffeeh],'QA'
	jnz	not_compaq_patch

;	We're running on a COMPAQ.  Now look at the date code.

	mov	ax,es:word ptr [0fffbh]	; get year
	xchg	ah,al
	cmp	ax,'86'			; is it 86?
	ja	not_compaq_patch
	jb	do_compaq_patch

	mov	ax,es:word ptr [0fff5h]	; get month
	xchg	ah,al
	cmp	ax,'08'			; is it 08?
	ja	not_compaq_patch
	jb	do_compaq_patch

	mov	ax,es:word ptr [0fff8h]	; get day
	xchg	ah,al
	cmp	ax,'04'			; is it 04?
	jae	not_compaq_patch	; 08/04/86 or later needs no patch

do_compaq_patch:

;	M065 -- end additions

;M065	
;M065	;	on some Compaq '286 systems there's a ROM BIOS bug.  When an
;M065	;	  int13 is executed with ah>15h and dl>=80h, the byte at
;M065	;	  DS:74h is trashed.  If we detect that bug in the ROM, insert
;M065	;	  an int13 hook which always points ds->ROM DATA AREA on those
;M065	;	  calls.
;M065	
;M065	checkcompaqbug:
;M065	
;M065		push	ds
;M065		mov	ds,init_bootseg		; point to our scratch buffer
;M065		assume	ds:nothing
;M065	
;M065		mov	ds:byte ptr 74h,0ffh	; stick a known value at 74h
;M065		mov	ah,16h			; check disk change
;M065		mov	dl,80h			; on any hard disk
;M065	
;M065	;	we can't just do a straight int 13 here or the damn bug will
;M065	;	 trash something in our Bios Data, since our int13 hook
;M065	;	 has ds->bios_data when it calls the ROM.
;M065	
;M065		xor	si, si			; AT&T 6300 WGS goofs it up
;M065						;  if si != 0			M021
;M065	
;M065		pushf				; simulate int 13
;M065		call	orig13			; call directly into the ROM
;M065	
;M065		cmp	ds:byte ptr 74h,0ffh	; if it changed in error, COMPAQ bug
;M065		pop	ds
;M065		assume	ds:datagrp
;M065		jz	checkcmosclock		; brif no ROM BIOS bug
;M065	

;	insert patch for COMPAQ rom

	mov	cx,offset datagrp:end_compaq_i13hook
	mov	si,offset datagrp:compaq_disk_io

install_int13_patch:
	push	cs
	pop	es			;set es to datagrp seg

	mov	word ptr orig13,di
	mov	word ptr orig13+2,cs	;set new rom bios int 13 vector
	sub	cx,si			;size of rom fix module
	rep	movsb			;relocate it

;	M015 -- end changes

not_compaq_patch:			; M065
	push	cs
	pop	es
	assume	es:datagrp
	mov	ax,4101h		; wait for bh=es:[di]
	mov	bl,1			; wait for one clock tick
	mov	bh,byte ptr es:[di]
	stc
	int	15h
	jc	configdone

	or	bios_flags,k09_mask
	mov	word ptr ss:[4 * 6ch],offset int6c_entry
	mov	word ptr ss:[4 * 6ch + 2],cs

configdone:				;di is final ending address of msbio.

; Copy the A20 error message into the resident BIOS data area.

	mov	si,offset sysinit_msg_base
	add	si,sysinit_msg_table+sysinit_a20_msg
	mov	a20_message_ptr,di
a20_msg_copy:
	lodsb
	stosb
	cmp	al,'$'
	jnz	a20_msg_copy

	add	di,15
	.286
	shr	di,4
	.8086
	add	di,datagrp
	mov	[dosdatasg],di
	mov	ax,drvfat
	mov	bp,offset setdrive
	call	call_bios_code
	mov	bp,offset getbp
	call	call_bios_code
	call	setdrvparms
	jmp	SI_start

init	endp

;==========================================================================
;
; Following are subroutines to support resident device driver initialization
;
;M011 -- note:  deleted setup_bdsms and reset_bdsms here

;

;	M035 -- begin changed section

;******************************************************************************
; module name: remap
;
; descriptive name: all the code for himem that could be separated from msbio
;
; function:  remap the bds chain to adjusted logical drive numbers (drive
;	     letters if more than two diskette drives on the system.
;
;     scheme:  if more than 2 disktte drives, first map the bds structure
;	       as usual and then rescan the bds chain to adjust the  drive
;	       letters.  to do this, scan for disk drives and assign logica
;	       drive number starting from 2 and then rescan diskette drives
;	       and assign next to the last logical drive number of last disk
;	       drive to the 3rd and 4th diskette drives.

; input:       none
; exit:	drive letters have been remapped in bds chain
; exit error:	none
; called from: msinit
;
; notes:  this function  will be called only if more than 2 diskettes are
;	  found in the system
;	  this function assumes that there are no more than 26 drives assigned
;	    this is guaranteed by the code that creates bdss for partitions
;	  this function assumes that the first entries in the chain are
;	   floppy drives, and all the rest are hard drives
;	  will alter the boot drive if necessary to reflect remapping
;
;******************************************************************************

remap	proc	near

	assume	ds:datagrp

	les	di,start_bds

; search for 1st fixed disk physical drive num

drive_loop:
	cmp	es:[di].bds_drivenum,80h ; first hard disk??
	je	fdrv_found		 ; yes - continue

	les	di,es:[di].bds_link
	cmp	di,-1			; last bds?
	jnz	drive_loop		; loop if not

	jmp	short rmap_exit		; yes- no hard drive on system

;------------------------------------------------------------------------------
;first disk drive bds, now change the logical drive num to 2 and the subsequent
;logical drive nums to 3, 4, 5 etc.
;------------------------------------------------------------------------------

fdrv_found:
	mov	al,2			; start with logical drv num=2
fdrv_loop:
	mov	es:[di].bds_drivelet,al ; found ??
	les	di,es:[di].bds_link
	inc	al			; set num for next drive

	cmp	di,-1			; last hard drive ??
	jne	fdrv_loop		; no - assign more disk drives

;------------------------------------------------------------------------------
; now, rescan and find bds of 3rd floppy drive and assign next drive letter
; in al to 3rd. if the current drive letter is past z, then do not allocate
; any more.
;------------------------------------------------------------------------------


	les	di,start_bds
	les	di,es:[di].bds_link
	mov   ah,dsktnum		   ; get number of floppies to remap
	sub   ah,2			   ; adjust for a: & b:

remap_loop1:
	les	di,es:[di].bds_link
	mov   es:[di].bds_drivelet,al      ; set new num to next floppy

	inc   al			; new number for next floppy
	dec   ah			; count down extra floppies
	jnz   remap_loop1		; and loop until we got 'em all

;	now we've got to adjust the boot drive if we reassigned it

	mov	al,byte ptr drvfat
	cmp	al,2			; is it a: or b:
	jb	rmap_exit

	sub	al,dsktnum		; is it one of the other floppies?
	jb	remap_boot_flop		;  brif so

;	we've got to remap the boot hard drive
;	  subtract the number of EXTRA floppies from it

	add	al,2			; bootdrv -= (dsktnum-2)
	jmp	short remap_change_boot_drv

;	we've got to remap the boot floppy.
;	  add the number of hard drive partitions to it

remap_boot_flop:
	add	al,drvmax		; bootdrv += (drvmax-dsktnum)

remap_change_boot_drv:
	mov	byte ptr drvfat,al	; alter msdos.sys load drive
	inc	al

	mov	es,ds:init_sysinit_seg
	assume	es:sysinitseg
	mov	es:default_drive,al
	assume	es:nothing

rmap_exit:
	ret

remap	endp

;	M035 -- end changes


;**************************
;
; getboot - get the boot sector for a hard disk
;
; Reads the boot sector from a specified drive into a buffer at the top
; of memory.
;
; dl = int13 drive number to read boot sector for

getboot proc	near
	push	dx
	push	es
	mov	es,cs:init_bootseg
	sub	bx,bx
	mov	ax,0201h		; command to read & num sec. to 1
	xor	dh,dh			; head number zero
	mov	cx,0001h		; cylinder zero and sector one
	int	13h			; call rom bios
	push	es
	pop	ds
	assume	ds:nothing
	jc	erret

	cmp	word ptr ds:[1feh],0aa55h
	jz	norm_ret
erret:
	stc
norm_ret:
	pop	es
	pop	dx
	ret
getboot endp


;***************************************************************************
;   sethard - generate bpb for a variable sized hard file.  ibm has a
;   partitioned hard file; we must read physical sector 0 to determine where
;   our own logical sectors start.  we also read in our boot sector to
;   determine version number
;
;   inputs:	dl is rom drive number (80...)  M018
;		bh is partition number (0....)  M018
;		ds:di points to bds
;   outputs:	carry clear -> bpb is filled in
;		carry set   -> bpb is left uninitialized due to error
;	trashes (at least) si, cx
;	MUST PRESERVE ES:!!!!		; M011
;***************************************************************************


sethard proc	near
	assume	ds:datagrp,es:nothing

	push	di
	push	bx
	push	ds
	push	es		; M011
	mov	es:[di].bds_drivelet,bl
	mov	es:[di].bds_drivenum,dl
	or	es:byte ptr [di].bds_flags,fnon_removable
	mov	es:[di].bds_formfactor,ffhardfile
	mov	fbigfat,0		; assume 12 bit fat
	mov	dh,bh			; M018 - partition number
	push	dx
	mov	ah,8			; set command to get drive parameters
	int	13h			; call rom-bios disk routine

; dh is number of heads-1
; dl is number of hard disks attached
; low 6 bits of cl is sectors/track
; high 2 bits of cl with ch are max # of cylinders

	inc	dh			; get number of heads
	mov	byte ptr es:[di].BDS_BPB.BPB_HEADS,dh
	pop	dx

	jc	setret			; error if no hard disk

	and	cl,3fh			; extract number of sectors/track
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK,cl
	call	getboot
	assume	ds:nothing
	jc	setret			;	return -1;
	mov	bx,1c2h	;   p = &boot[0x1c2];

;	M018 -- begin changed section

;	The first 'active' partition is 00, the second is 01....
;	  then the remainder of the 'primary' but non-active partitions

act_part:
	test	BYTE PTR ds:[bx - 4],80h  ;AN016;is the partition active?
	jz	not_act
	cmp	byte ptr ds:[bx],1	; reject if partitiontype != 1, 4, 6 or 0eh
	jz	got_good_act
	cmp	byte ptr ds:[bx],4
	jz	got_good_act
	cmp	byte ptr ds:[bx],6
	jz	got_good_act
	cmp	byte ptr ds:[bx],0eh
	jnz	not_act			; reject!
got_good_act:
	or	dh,dh			; is this our target partition #?
	jz	set2			; WE GOT THE ONE WANTED!!
	dec	dh			; count down
not_act:
	add	bx,16			;AN016;next entry
	cmp	bx,202h	;AN016;last entry done?
	jnz	act_part		;AN016;no,process next entry

;	Now scan the non-active partitions

	mov	bx,1c2h	;AN016;restore original value of bx

get_primary:
	test	byte ptr ds:[bx - 4],80h ; we've already scanned
	jnz	not_prim		; the ACTIVE ones
	cmp	byte ptr ds:[bx],1	; see if partitiontype == 1, 4, 6 or 0eh
	jz	got_prim
	cmp	byte ptr ds:[bx],4
	jz	got_prim
	cmp	byte ptr ds:[bx],6
	jz	got_prim
	cmp	byte ptr ds:[bx],0eh
	jnz	not_prim

got_prim:
	or	dh,dh			; is this our target partition?
	jz	set2
	dec	dh

not_prim:
	add	bx,16
	cmp	bx,202h
	jnz	get_primary		; loop till we've gone through table

setret:
	stc				; error return
	jmp	ret_hard

;	M018 -- this concludes the changes.

;  until we get the real logical boot record and get the bpb,
;  BDS_BPB.BPB_BIGTOTALSECTORS will be used instead of BDS_BPB.BPB_TOTALSECTORS for the
;  convenience of the computation.
;
;  at the end of this procedure, if a bpb information is gotten from
;  the valid boot record, then we are going to use those bpb information
;  without change.
;
;  otherwise, if (hidden sectors + total sectors) <= a word, then
;  we will move BDS_BPB.BPB_BIGTOTALSECTORS (low) to BDS_BPB.BPB_TOTALSECTORS and zero out
;  BDS_BPB.BPB_BIGTOTALSECTORS entry to make
;  it a conventional bpb format.

set2:
	cmp	byte ptr ds:[bx],0eh
	jne	set2_chs
	or	word ptr es:[di].bds_flags,0400h
set2_chs:
	mov	cs:rom_drv_num, dl	; save the rom bios drive number we are handling now.

	mov	ax,word ptr ds:[bx+4]	;hidden sectors
	mov	dx,word ptr ds:[bx+6]

;  decrement the sector count by 1 to make it zero based. exactly 64k
;   sectors should be allowed

	sub	ax,1
	sbb	dx,0

	add	ax,word ptr ds:[bx+8]	;sectors in partition
	adc	dx,word ptr ds:[bx+10]
	jnc	okdrive
	or	cs:fbigfat,ftoobig
okdrive:
	mov	ax,word ptr ds:[bx+4]

	add	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS,ax	;   BPB_HIDDENSECTORS = p->partitionbegin;
	mov	ax,word ptr ds:[bx+6]
	adc	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2,ax

	mov	dx,word ptr ds:[bx+10]	; # of sectors (high)
	mov	ax,word ptr ds:[bx+8]	;# of sectors (low)
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2,dx
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS,ax ;   bpb->maxsec = p->partitionlength;
	cmp	dx,0
	ja	okdrive_cont

	cmp	ax,64			;   if (p->partitionlength < 64)
	jb	setret			;	return -1;

okdrive_cont:
	mov	dx,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS	; boot sector number - for mini disk,;j.k.
	test	word ptr es:[di].bds_flags,0400h
	jz	set2_chs_read
	mov	ch,cs:rom_drv_num
	mov	cl,1
	lds	bx,cs:disksector_ptr
	call	init_ext_read
	jmp	short set2_read_done
set2_chs_read:
	xor	bx,bx			;usually equal to the # of sec/trk.  ;j.k.
	mov	bl,byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK
	push	ax
	mov	ax,dx
	xor	dx,dx
	div	bx
	mov	cs:[init_temp_h],ax
	pop	ax
	div	bx			;(sectors)dx;ax / (BDS_BPB.BPB_SECTORSPERTRACK)bx =(track) temp_h;ax + (sector)dx
	mov	cl,dl			; cl is sector number;j.k.assume sector number < 255.
	inc	cl			; sectors are 1 based

	xor	bx,bx
	mov	bl,byte ptr es:[di].BDS_BPB.BPB_HEADS
	push	ax
	xor	dx,dx
	mov	ax,cs:[init_temp_h]
	div	bx
	mov	cs:[init_temp_h],ax
	pop	ax
	div	bx			; dl is head, ax is cylinder
	cmp	cs:[init_temp_h],0
	ja	setret_brdg		; exceeds the limit of int 13h
	cmp	ax,1024
	ja	setret_brdg		; exceeds the limit of int 13h

; dl is head.
; ax is cylinder
; cl is sector number (assume less than 2**6 = 64 for int 13h)

;*** for mini disks ***
	cmp	es:[di].bdsm_ismini,1 		;check for mini disk
	jnz	oknotmini		;not mini disk.
	add	ax,es:[di].bdsm_hidden_trks	;set the physical track number
oknotmini:
;*** end of added logic for mini disk

	ror	ah,1			; move high two bits of cyl to high
	ror	ah,1			; two bits of upper byte
	and	ah,0c0h 		; turn off remainder of bits
	or	cl,ah			; move two bits to correct spot
	mov	ch,al			; ch is cylinder

; cl is sector + 2 high bits of cylinder
; ch is low 8 bits of cylinder
; dl is head
; rom_drv_num is drive

	mov	dh,dl			; dh is head
	mov	dl,cs:rom_drv_num	; set the drive number

; cl is sector + 2 high bits of cylinder
; ch is low 8 bits of cylinder
; dh is head
; dl is drive

; read the logical boot sector into the buffer addressed by
; cs:disksector_ptr, using the bios disk interrupt.

	push	es
	les	bx,cs:disksector_ptr
	mov	ax,201h		; read, one sector
	int	13h
	push	es
	pop	ds
	pop	es
set2_read_done:

; ds:bx points to the boot sector.	in theory, (ha ha) the bpb in this thing
; is correct.  we can, therefore, suck out all the relevant statistics on the
; media if we recognize the version number.


	push	bx			; save changed regs
	push	ax

	cmp	byte ptr ds:[bx],0e9h	; is it a near jump?
	je	check_1_ok		; no,
	cmp	byte ptr ds:[bx],0ebh	;   is it a short jump?
	jne	invalid_boot_record	;   no, invalid boot record
	cmp	byte ptr ds:[bx+2],090h ;   yes, is the next one a nop?
	jne	invalid_boot_record	;     no, invalid boot record

check_1_ok:				; yes, jmup instruction ok.
					; now check some fields in
					;  the boot record bpb
	add	bx,EXT_BOOT_BPB
					;  in the boot record

					; get the mediadescriptor byte
	mov	al,byte ptr ds:[bx].bpb_mediadescriptor

	and	al,0f0h 		; mask off low nibble
	cmp	al,0f0h 		; is high nibble = 0fh?
	jne	invalid_boot_record	;   no, invalid boot record

	cmp	ds:[bx].bpb_bytespersector,512	; M042
	jnz	invalid_boot_record	; M042 invalidate non 512 byte sectors

check_2_ok:				; yes, mediadescriptor ok.
					; now make sure that
					;     the sectorspercluster
					;	is a power of 2

					; get the sectorspercluster

	mov	al,byte ptr ds:[bx].bpb_sectorspercluster

	or	al,al			; is it zero?
	jz	invalid_boot_record	;   yes, invalid boot record

;	M032 begin

ck_power_of_two:
	shr	al,1			; shift until first bit emerges
	jnc	ck_power_of_two

	jz	valid_boot_record	; if no bits left, then proceed ok

;	M032 end

invalid_boot_record:			; for invalid boot record
	pop	ax			; restore registers
	pop	bx			;
	jmp	unknown 		; jump to invalid boot record
					; unformatted or illegal media.

valid_boot_record:			; for valid boot record
	pop	ax			; restore registers
	pop	bx			;

; signature found.  Now check version.

	cmp	word ptr ds:[bx+8],"." shl 8 + "2"
	jnz	try5
	cmp	byte ptr ds:[bx+10],"0"
	jnz	try5

	jmp	short copybpb

setret_brdg:
	jmp	setret

;M042 unknownj:
;M042	jmp	unknown 		;unformatted or illegal media.

unknown3_0_j:				;legally formatted media,
	jmp	unknown3_0		; although, content might be bad.

try5:
	call	cover_fdisk_bug

; see if it is an os2 signature

	cmp	word ptr ds:[bx+8],'.' shl 8 + '0'	; M053
	jne	no_os2					; M053
	mov	al,byte ptr ds:[bx+7]			; M053
	sub	al,'1'					; M053
	and	al,0feh					; M053
	jz	copybpb		; accept either '1' or '2' ; M053

; M053	cmp	word ptr ds:[bx+7],"0" shl 8 + "1"
; M053	jne	no_os2
; M053	cmp	byte ptr ds:[bx+9],"."
; M053	je	copybpb
	jmp	unknown

; no os2 signature, this is to check for real dos versions

no_os2:
	cmp	word ptr ds:[bx+8],"." shl 8 + "3"
	jb	unknown3_0_j		; must be 2.1 boot record. do not trust it, but still legal.
	jnz	copybpb 		; honor os2 boot record, or dos 4.0 version
	cmp	byte ptr ds:[bx+10],"1"	;do not trust 3.0 boot record. but still legal
	jb	unknown3_0_j		; if version >= 3.1, then o.k.

copybpb:

;	we have a valid boot sector. use the bpb in it to build the
;	bpb in bios. it is assumed that only
;		BDS_BPB.BPB_SECTORSPERCLUSTER
;		BDS_BPB.BPB_ROOTENTRIES, and
;		BDS_BPB.BPB_SECTORSPERFAT
;	need to be set (all other values in already). fbigfat
;	is also set.

;if it is non fat based system, then just copy the bpb from the boot sector
;into the bpb in bds table, and also set the boot serial number, volume id,
;and system id according to the boot record.
;for the non_fat system, don't need to set the other value. so just
;do goodret.

	cmp	[bx].EXT_BOOT_SIG,ext_boot_signature
	jne	copybpb_fat		; conventional fat system
	cmp	[bx].EXT_BOOT_BPB.BPB_NUMBEROFFATS,0
	jne	copybpb_fat		;   a fat system.

; non fat based media.

	push	di			; sav reg.
	lea	si,[bx].EXT_BOOT_BPB
	add	di,BDS_BPB.BPB_BYTESPERSECTOR	; es:di -> bpb in bds

;	M034 -- begin additions

;       just for completeness, we'll make sure that total_sectors and
;         big_total_sectors aren't both zero.  I've seen examples of
;         this on DOS 3.30 boot records.  I don't know exactly how it
;         got that way.  If it occurs, then use the values from the
;         partition table.

        cmp     ds:[si].BPB_TOTALSECTORS,0      ; is total_sectors nonzero?
        jnz     already_nonz                    ; done if so, use it
        cmp     ds:[si].BPB_BIGTOTALSECTORS,0   ; how 'bout big_total?
        jnz     already_nonz                    ; we're okay if any are != 0
        cmp     ds:[si].BPB_BIGTOTALSECTORS+2,0
        jnz     already_nonz

;       now let's copy the values from the partition table (now in the BDS)
;         into the BPB in the boot sector buffer, before they get copied
;         back.

        mov     ax,es:[di.BPB_TOTALSECTORS]     ; get value from part table
        mov     ds:[si].BPB_TOTALSECTORS,ax     ; store it into bpb buffer
        mov     ax,es:[di.BPB_BIGTOTALSECTORS]  ; get value from part table
        mov     ds:[si].BPB_BIGTOTALSECTORS,ax  ; store it into bpb buffer
        mov     ax,es:[di.BPB_BIGTOTALSECTORS+2] ; get value from part table
        mov     ds:[si].BPB_BIGTOTALSECTORS+2,ax ; store it into bpb buffer

already_nonz:

;	end M034 additions

	mov	cx,size A_BPB - 6	; ****** Use SMALL version!

	rep	movsb

	pop	di
	mov	bp,offset mov_media_ids
	call	call_bios_code
	jmp	goodret

copybpb_fat:				;  fat system

;	M034 -- begin changes


;       ****** cas ---
;          IBM DOS 3.30 doesn't seem to mind that the TOTAL_SECTORS and
;          BIG_TOTAL_SECTORS field in the boot sector are 0000.  This
;          happens with some frequency -- perhaps through some OS/2 setup
;          program.  We haven't actually been COPYING the TOTAL_SECTORS
;          from the boot sector into the DPB anyway, we've just been using
;          it for calculating the fat size.  Pretty scary, huh?  For now,
;          we'll go ahead and copy it into the DPB, except in the case
;          that it equals zero, in which case we just use the values in
;          the DPB from the partition table.

	lea	si,[bx].EXT_BOOT_BPB
	xor	dx,dx
        mov     ax,ds:[si.BPB_TOTALSECTORS]     ; get totsec from boot sec
        or      ax,ax
        jnz     copy_totsec                     ; if non zero, use that

        mov     ax,ds:[si.BPB_BIGTOTALSECTORS]  ; get the big version
        mov     dx,ds:[si.BPB_BIGTOTALSECTORS+2]
        mov     cx,dx
        or      cx,ax                           ; see if it is a big zero
        jz      totsec_already_set              ; screw it.  it was bogus.

copy_totsec:
	mov	es:[di.BDS_BPB.BPB_BIGTOTALSECTORS],ax   ; M040 make DPB match
	mov	es:[di.BDS_BPB.BPB_BIGTOTALSECTORS+2],dx ; M040 boot sec

totsec_already_set:

;	M034 -- end changes

;M034	xor	dx,dx
;M040	mov	si,offset disksector.EXT_BOOT_BPB ;  cs:bx -> bpb in boot
;M034	mov	ax,cs:[si.BPB_TOTALSECTORS]	;  total sectors
;M034	or	ax,ax			; double word sector number?
;M034	jnz	fat_big_small		;  no. conventional bpb.

;M034	mov	ax,word ptr cs:[si.BPB_BIGTOTALSECTORS] ; use double word
;M034	mov	dx,word ptr cs:[si.BPB_BIGTOTALSECTORS+2]
	mov	ax,word ptr es:[di.BDS_BPB.BPB_BIGTOTALSECTORS]
	mov	dx,word ptr es:[di.BDS_BPB.BPB_BIGTOTALSECTORS+2]


fat_big_small:				 ; determine fat entry size.

;at this moment dx;ax = total sector number

;
;Do not assume 1 reserved sector. Update the reserved sector field in BDS 
;from the BPB on the disk
;
	push	bx
	mov	bx,ds:[SI.BPB_RESERVEDSECTORS]		;AN017;get #reserved_sectors from BPB
	mov	es:[di].BDS_BPB.BPB_RESERVEDSECTORS,bx	;AN017;update BDS field
	sub	ax,bx					;AN017;
	sbb	dx,0					;AN017;update the count

;	sub	ax,1					;AN017; subtrack # reserved (always 1)
;	sbb	dx,0					;AN017;

	mov	bx,ds:[si.BPB_SECTORSPERFAT]	;  bx = sectors/fat
	mov	es:[di].BDS_BPB.BPB_SECTORSPERFAT,bx 	;  set in bds bpb
	shl	bx,1			; always 2 fats
	sub	ax,bx			; sub # fat sectors
	sbb	dx,0
	mov	bx,ds:[si.BPB_ROOTENTRIES]	;  # root entries
	mov	es:[di].BDS_BPB.BPB_ROOTENTRIES,bx		;  set in bds bpb

	mov	cl,4
	shr	bx,cl			;  div by 16 ents/sector
	sub	ax,bx			;  sub # dir sectors
	sbb	dx,0
					; dx;ax now contains the # of data sectors
	pop	bx
	xor	cx,cx
	mov	cl,ds:[si.BPB_SECTORSPERCLUSTER]	; sectors per cluster
	mov	es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER,cl	; set in bios bpb
	push	ax
	mov	ax,dx
	xor	dx,dx
	div	cx			; cx = sectors per cluster
	mov	cs:[init_temp_h],ax
	pop	ax
	div	cx			;  [init_temp_h];ax now contains the # clusters.
	cmp	cs:[init_temp_h],0
	ja	toobig_ret		;  too big cluster number

	cmp	ax,4096-10		; is this 16-bit fat?
	jb	copymediaid		; no, small fat
	or	cs:fbigfat,fbig		; 16 bit fat

copymediaid:
	mov	bp,offset mov_media_ids	; copy filesys_id, volume label,
	call	call_bios_code
					;and volume serial to bds table, if extended
					;boot record.
	jmp	massage_bpb		; now final check for bpb info. and return.

toobig_ret:
	or	cs:fbigfat,ftoobig
	jmp	goodret 		; still drive letter is assigned
					; but useless. to big for
					; current pc dos fat file system
unknown:
	or	es:[di].bds_flags, unformatted_media ; M042
					; Set unformatted media flag.

;  the boot signature may not be recognizable,
;     but we should try and read it anyway.

unknown3_0:				;skip setting unformatted_media bit
	mov	dx,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	mov	si,offset datagrp:disktable2
scan:

	cmp	dx,word ptr cs:[si]
	jb	gotparm
	ja	scan_next
	cmp	ax,word ptr cs:[si+2]
	jbe	gotparm
scan_next:
	add	si,5 * 2
	jmp	scan			;  covers upto 512 mb media
gotparm:
	mov	cl,byte ptr cs:[si+8]	;  fat size for fbigfat flag
	or	cs:fbigfat,cl
	mov	cx,word ptr cs:[si+4]
	mov	dx,word ptr cs:[si+6]

;	dx = number of dir entries,
;	ch = number of sectors per cluster
;	cl = log base 2 of ch

;	now calculate size of fat table


	mov	es:[di].BDS_BPB.BPB_ROOTENTRIES,dx	;save number of dir entries

;now, cx = BDS_BPB.BPB_SECTORSPERCLUSTER|clusshift
;    es:[di].BDS_BPB.BPB_ROOTENTRIES = number of directory entries.

	mov	dx,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER,ch ;save sectors per cluster
	test	cs:fbigfat,fbig		;   if (fbigfat)
	jnz	dobig			;	goto dobig;

;   we don't need to change "small fat" logic since it is gauranteed
;   that double word total sector will not use 12 bit fat (unless
;   it's sectors/cluster >= 16 which will never be in this case.)
;   so in this case we assume dx = 0 !!!.

	xor	bx,bx
	mov	bl,ch
	dec	bx
	add	bx,ax			; dx=0
	shr	bx,cl			; bx = 1+(bpb->maxsec+BDS_BPB.BPB_SECTORSPERCLUSTER-1)/
	inc	bx			; BDS_BPB.BPB_SECTORSPERCLUSTER
	and	bl,11111110b		; bx &= ~1; (=number of clusters)
	mov	si,bx
	shr	bx,1
	add	bx,si
	add	bx,511			; bx += 511 + bx/2
	shr	bh,1			; bh >>= 1; (=bx/512)
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERFAT,bh ;save number of fat sectors
	jmp	short massage_bpb

dobig:
; for bigfat we do need to extend this logic to 32 bit sector calculation.

	mov	cl,4			; 16 (2^4) directory entries per sector
	push	dx			; save total sectors (high)
	mov	dx,es:[di].BDS_BPB.BPB_ROOTENTRIES
	shr	dx,cl			; cseBDS_BPB.BPB_ROOTENTRIES = BDS_BPB.BPB_ROOTENTRIES / 16;
	sub	ax,dx			; dx;ax -= cseBDS_BPB.BPB_ROOTENTRIES; dx;ax -= csecreserved;
	pop	dx
	sbb	dx,0
	sub	ax,1			; dx;ax = t - r - d
	sbb	dx,0			;
	mov	bl,2
	mov	bh,es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER	; bx = 256 * BDS_BPB.BPB_SECTORSPERCLUSTER + 2

;	i don't understand why to add bx here!!!

	add	ax,bx			; ax = t-r-d+256*spc+2
	adc	dx,0
	sub	ax,1			; ax = t-r-d+256*spc+1
	sbb	dx,0

;     assuming dx in the table will never be bigger than bx.

	div	bx			; BDS_BPB.BPB_SECTORSPERFAT = ceil((total-dir-res)/
					;		 (256*BDS_BPB.BPB_SECTORSPERCLUSTER+2));
	mov	es:[di].BDS_BPB.BPB_SECTORSPERFAT,ax ; number of fat sectors

; now, set the default filesys_id, volume label, serial number

	mov	bl,cs:fbigfat
	mov	es:[di].bds_fatsiz,bl		; set size of fat on media

	mov	bp,offset clear_ids
	call	call_bios_code

;   at this point, in bpb of bds table, BDS_BPB.BPB_BIGTOTALSECTORS which is
;   set according to the partition information. we are going to
;   see if (hidden sectors + total sectors) > a word.  if it is true,
;   then no change.  otherwise, BDS_BPB.BPB_BIGTOTALSECTORS will be moved
;   to BDS_BPB.BPB_TOTALSECTORS and BDS_BPB.BPB_BIGTOTALSECTORS will be set to 0.
;   we don't do this for the bpb information from the boot record. we
;   are not going to change the bpb information from the boot record

massage_bpb:
	mov	dx,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS

	cmp	dx,0			; double word total sector?
	ja	goodret 		; don't have to change it.
	cmp	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2,0
	ja	goodret 		; don't have to change it.
	add	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS
	jc	goodret 		; bigger than a word boundary

	mov	ax,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	mov	es:[di].BDS_BPB.BPB_TOTALSECTORS,ax
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS,0

goodret:
	mov	bl,cs:fbigfat
	mov	es:[di].bds_fatsiz,bl		; set size of fat on media
	clc
ret_hard:
	pop	es				; M011
	pop	ds
	pop	bx
	pop	di
	ret

sethard endp

cover_fdisk_bug 	proc

;fdisk of pc dos 3.3 and below, os2 1.0 has a bug.  the maximum number of
;sector that can be handled by pc dos 3.3 ibmbio should be 0ffffh.
;instead, sometimes fdisk use 10000h to calculate the maximum number.
;so, we are going to check that if BPB_TOTALSECTORS + hidden sector = 10000h
;then subtract 1 from BPB_TOTALSECTORS.

	push	ax
	push	dx
	push	si
	cmp	[bx].EXT_BOOT_SIG,ext_boot_signature
	je	cfb_retit		;if extended bpb, then >= pc dos 4.00

	cmp	word ptr ds:[bx+7],"0" shl 8 + "1" ; os2 1.0 ? = ibm 10.0
	jne	cfb_chk_BPB_TOTALSECTORS
	cmp	byte ptr ds:[bx+10],"0"
	jne	cfb_retit

cfb_chk_BPB_TOTALSECTORS:
	lea	si,[bx].EXT_BOOT_BPB
	cmp	ds:[si.BPB_TOTALSECTORS],0	;just to make sure.
	je	cfb_retit

	mov	ax,ds:[si.BPB_TOTALSECTORS]
	add	ax,word ptr ds:[si.BPB_HIDDENSECTORS]
	jnc	cfb_retit

;M031	xor	ax,ax			;if carry set and ax=0?
	jnz	cfb_retit		; M031 -- zero reflects ax from add

;	M031 -- result of add was 10000h

	dec	ds:[si.BPB_TOTALSECTORS]		; then decrease BPB_TOTALSECTORS by 1.
;M034	dec	word ptr ds:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	sub	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS,1	; M034
	sbb	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2,0 ; M034


cfb_retit:
	pop	si
	pop	dx
	pop	ax
	ret

cover_fdisk_bug endp


;****************************
;
; setdrvparms sets up the recommended bpb in each bds in the system based on
; the form factor. it is assumed that the bpbs for the various form factors
; are present in the bpbtable. for hard files, the recommended bpb is the same
; as the bpb on the drive.

; no attempt is made to preserve registers since we are going to jump to
; sysinit straight after this routine.

word2	dw	2		; word constants for mul/div
word3	dw	3
word512	dw	512

setdrvparms proc near
	assume	ds:datagrp
	xor	bx,bx
	les	di,[start_bds] 		; get first bds in list

next_bds:
	push	es
	push	di			; preserve pointer to bds
	mov	bl,es:[di].bds_formfactor
	cmp	bl,ffhardfile
	jnz	nothardff

	xor	dx,dx
	mov	ax,es:[di].BDS_BPB.BPB_TOTALSECTORS
	or	ax,ax
	jnz	get_ccyl

	mov	dx,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2	; use double word sector number
	mov	ax,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
get_ccyl:
	push	dx
	push	ax
	mov	ax,word ptr es:[di].BDS_BPB.BPB_HEADS
	mul	word ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK ;assume sectorsp per cyl. < 64k.
	mov	cx,ax			; cx has # sectors per cylinder
	pop	ax
	pop	dx			; restore BDS_BPB.BPB_TOTALSECTORS.

	push	ax
	mov	ax,dx
	xor	dx,dx
	div	cx
	mov	[init_temp_h],ax		; ax be 0 here.
	pop	ax

	div	cx			; div #sec by sec/cyl to get # cyl.
	or	dx,dx
	jz	no_cyl_rnd		; came out even
	inc	ax			; round up
no_cyl_rnd:
	mov	es:[di].bds_ccyln,ax
	push	es
	pop	ds
	lea	si,[di].BDS_BPB.BPB_BYTESPERSECTOR	; ds:si -> bpb for hard file
	jmp	short set_recbpb

nothardff:

; we don't use the extended bpb for a floppy.


;	if fake floppy drive variable is set then we don't have to handle this
;	bds.  we can just go and deal with the next bds at label go_to_next_bds.

	cmp	fakefloppydrv,1
	jz	go_to_next_bds

	cmp	bl,ffother		; special case "other" type of medium
	jnz	not_process_other

process_other:
	xor	dx,dx
	mov	ax,es:[di].bds_ccyln
	mul	es:[di].BDS_RBPB.BPB_HEADS
	mul	es:[di].BDS_RBPB.BPB_SECTORSPERTRACK
	mov	es:[di].BDS_RBPB.BPB_TOTALSECTORS,ax 	; have the total number of sectors
	dec	ax

	mov	dl, 1
again:
	cmp	ax, 4096-10
	jb	@f
	shr	ax, 1
	shl	dl, 1
	jmp	again
@@:
	cmp	dl, 1				; is it a small disk
	je	@f				; yes, 224 root entries is enuf
	mov	es:[di].BDS_RBPB.BPB_ROOTENTRIES, 240
@@:
	mov	es:[di].BDS_RBPB.BPB_SECTORSPERCLUSTER, dl

;	logic to get the sectors/fat area.
;	fat entry is assumed to be 1.5 bytes!!!

	mul	word3
	div	word2
	xor	dx,dx
	div	word512
	inc	ax

no_round_up:
	mov	es:[di].BDS_RBPB.BPB_SECTORSPERFAT,ax
	jmp	short go_to_next_bds

not_process_other:
	shl	bx,1			; bx is word index into table of bpbs
	mov	si,offset datagrp:bpbtable
	mov	si,word ptr [si+bx]	; get address of bpb

set_recbpb:
	lea	di,es:[di].BDS_RBPB	; es:di -> recbpb
	mov	cx,size bpbx
	rep	movsb			; move (size bpbx) bytes
	push	cs
	pop	ds
	assume	ds:datagrp

go_to_next_bds:
	pop	di
	pop	es			; restore pointer to bds
	les	di,es:[di].bds_link
	cmp	di,-1
	jz	got_end_of_bds_chain
	jmp	next_bds
got_end_of_bds_chain:
	ret


setdrvparms endp


;--------------------------------------------------------------------

; al = device number


;--------------------------------------------------------------------

; domini **********************************************************************
;
;mini disk initialization routine. called right after dohard
;modified for >2 hardfile support
;
; **cs=ds=es=datagrp
;
; **domini will search for every extended partition in the system, and
;   initialize it.
;
; **bdsm stands for bds table for mini disk and located right after the label
;   end96tpi.  end_of_bdsm will have the offset value of the ending
;   address of bdsm table.
;
; **bdsm is the same as usual bds structure except that tim_lo, tim_hi entries
;   are overlapped and used to identify mini disk and the number of hidden_trks.
;   right now, they are called as ismini, hidden_trks respectively.
;
; **domini will use the same routine in sethard routine after label set2 to
;   save coding.
;
; **drvmax determined in dohard routine will be used for the next
;   available logical mini disk drive number.
;
;M011 -- begin changed section
;
; input: drvmax, dskdrvs
;
; output: minidisk installed. bdsm table established and installed to bds.
;	  end_of_bdsm - ending offset address of bdsm.
;
;
; called modules:
;		  getboot
;		  find_mini_partition (new), xinstall_bds (new), M038

;		  setmini (new, it will use set2 routine)
;
; variables used: end_of_bdsm
;		  rom_minidisk_num
;		  mini_hdlim, mini_seclim
;		  BDS_STRUC, start_bds
;
;******************************************************************************

domini	proc	near
	assume	ds:datagrp,es:datagrp

	mov	dh,hnum			; get number of hardfiles
	cmp	dh,0
	jz	dominiret		;no hard file? then exit.

	mov	dl,80h			; start with hardfile 80h

domini_loop:
	push	dx			; save hard drive number, count
	mov	rom_minidisk_num,dl

	mov	ah,8h			;get drive parameters
	int	13h			;call rom-bios
	inc	dh			;get # of heads (convert it to 1 based)
	xor	ax,ax
	mov	al,dh
	mov	mini_hdlim,ax		;save it.
	and	cl,3fh			;get # of sectors/track
	mov	al,cl
	mov	mini_seclim,ax		;and save it.

	mov	dl,rom_minidisk_num
	push	ds
	call	getboot 		; read master boot record into init_bootseg
	assume	es:nothing
	jc	domininext
	call	find_mini_partition
domininext:
	pop	ds
	assume	ds:datagrp

	pop	dx
	inc	dl			; next hard file
	dec	dh
	jnz	domini_loop

dominiret:
	ret

domini	endp

; Extended partition base and relative sector addresses.
ext_partition_base	dw	0,0
ext_partition_next	dw	0,0
ext_partition_lba	db	0

;--------------------------------------------------------------------

;find_mini_partition tries to find every extended partition on a disk.
;at entry:	di -> bdsm entry
;		ds:bx -> master boot record
;		rom_minidisk_num  - rom drive number
;		drvmax - logical drive number
;		mini_hdlim, mini_seclim
;
;called routine: setmini which uses set2 (in sethard routine)
;variables & equates used from original bios - flags, fnon_removable, fbigfat

find_mini_partition proc near
	assume	ds:nothing,es:nothing

	add	bx,1c2h		; first partition type
	mov	cs:ext_partition_lba,0
fmpnext:
	cmp	byte ptr [bx],5
	jz	fmpgot
	cmp	byte ptr [bx],0fh
	jz	fmp_lba
	add	bx,16
	cmp	bx,202h
	jnz	fmpnext
fmp_exitj:
	jmp	fmpret

fmp_lba:
	mov	cs:ext_partition_lba,1
	mov	ax,[bx+4]
	mov	cs:ext_partition_base,ax
	mov	ax,[bx+6]
	mov	cs:ext_partition_base+2,ax
	mov	cs:ext_partition_next,0
	mov	cs:ext_partition_next+2,0
fmpgot:
	call	dmax_check
	jnc	fmp_exitj
	mov	di,cs:end_of_bdss
	mov	es:[di].bdsm_ismini,1
	or	es:[di].bds_flags,fnon_removable
	mov	es:[di].bds_formfactor,ffhardfile
	mov	cs:fbigfat,0
	mov	ax,cs:mini_hdlim
	mov	es:[di].BDS_BPB.BPB_HEADS,ax
	mov	ax,cs:mini_seclim
	mov	es:[di].BDS_BPB.BPB_SECTORSPERTRACK,ax
	mov	al,cs:rom_minidisk_num
	mov	es:[di].bds_drivenum,al
	mov	al,cs:drvmax
	mov	es:[di].bds_drivelet,al
	cmp	word ptr [bx+10],0
	ja	fmpgot_cont
	cmp	word ptr [bx+8],64
	jae	fmpgot_cont
	jmp	fmpret
fmpgot_cont:
	sub	bx,4
	cmp	cs:ext_partition_lba,0
	jz	fmp_chs
	or	word ptr es:[di].bds_flags,0400h
	mov	ax,[bx+8]
	add	ax,cs:ext_partition_next
	mov	dx,[bx+10]
	adc	dx,cs:ext_partition_next+2
	push	ax
	mov	ax,cs:ext_partition_base
	mov	cs:ext_partition_next,ax
	mov	ax,cs:ext_partition_base+2
	mov	cs:ext_partition_next+2,ax
	pop	ax
	mov	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS,ax
	mov	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2,dx
	mov	ch,cs:rom_minidisk_num
	mov	cl,1
	sub	bx,bx
	call	init_ext_read
	jmp	short fmp_read_done
fmp_chs:
	mov	dh,[bx+2]
	and	dh,0c0h
	rol	dh,1
	rol	dh,1
	mov	dl,[bx+3]
	mov	es:[di].bdsm_hidden_trks,dx
	mov	cx,[bx+2]
	mov	dh,[bx+1]
	mov	dl,cs:rom_minidisk_num
	mov	ax,201h
	sub	bx,bx
	push	es
	push	ds
	pop	es
	int	13h
	pop	es
fmp_read_done:
	jc	fmpret
	mov	bx,1c2h
	push	es
	call	setmini
	pop	es
	jc	fmpnextchain
	call	xinstall_bds
fmpnextchain:
	jmp	fmpnext
fmpret:
	ret
find_mini_partition endp

;--------------------------------------------------------------------

; Packet for the extended INT 13h read used during disk initialization.

init_ext_packet		db	10h,0
init_ext_count		dw	1
init_ext_buffer		dw	0,0
init_ext_sector		dw	0,0,0,0

; read sectors through the extended INT 13h interface.
;
; input:  CH = drive, CL = count, DX:AX = sector, DS:BX = buffer.
; output: carry and AH are returned by the BIOS. DS is preserved.

init_ext_read proc near
	mov	cs:init_ext_buffer,bx
	mov	cs:init_ext_buffer+2,ds
	mov	cs:init_ext_sector,ax
	mov	cs:init_ext_sector+2,dx
	mov	dl,ch
	xor	ch,ch
	mov	cs:init_ext_count,cx
	push	ds
	push	cs
	pop	ds
	mov	si,offset datagrp:init_ext_packet
	mov	ah,42h
	int	13h
	pop	ds
	ret
init_ext_read endp

setmini	proc	near
	assume	ds:datagrp,es:nothing

	push	di
	push	bx
	push	ds
	push	es			; M011 - match stack for standard exit

;	M019 -- begin changes

setmini_1:
	cmp	byte ptr ds:[bx],1
	jz	setmini_2

	cmp	byte ptr ds:[bx],4
	jz	setmini_2

	cmp	byte ptr ds:[bx],6
	jz	setmini_2

	add	bx,16
	cmp	bx,202h
	jnz	setmini_1

	stc
	pop	es
	pop	ds
	pop	bx
	pop	di	
	ret

setmini_2:
	jmp	set2_chs			; branch into middle of sethard

;	M019 -- end changes

setmini	endp

;M011 -- end changed section

;M029 -- begin additions
;
;	dmax_check --- call this when we want to install a new drive.
;			it checks for drvmax < 26 to see if there is
;			a drive letter left.
;
;		drvmax < 26 : carry SET!
;		drvmax >=26 : carry RESET!, error flag set for message later
;				trash ax
;
dmax_check	proc	near
	cmp	cs:drvmax,26
	jc	dmax_ok			; return with carry if okay

	push	es
	mov	es,cs:init_sysinit_seg
	mov	byte ptr es:[toomanydrivesflag],1 ; set message flag
	pop	es

;	note:  carry still clear!!!

dmax_ok:
	ret

dmax_check	endp

;	M029 -- end additions

;	M038 -- begin additions

;--------------------------------------------------------------------
;	link next bds (at es:di) into the chain within es.
;	  also update drvmax and end_of_bdss.


xinstall_bds proc near
	assume	ds:nothing,es:nothing

	push	si
	mov	si,word ptr cs:[start_bds]
xinstall_bds_1:
	cmp	word ptr es:[si].bds_link,-1
	jz	xinstall_bds_2
	mov	si,word ptr es:[si].bds_link
	jmp	short xinstall_bds_1
xinstall_bds_2:
	mov	word ptr es:[si].bds_link,di
	mov	word ptr es:[si].bds_link+2,es
	mov	word ptr es:[di].bds_link,-1
	mov	word ptr es:[di].bds_link+2,es
	inc	cs:drvmax
	add	cs:end_of_bdss,size BDS_STRUC
	pop	si
	ret
xinstall_bds endp

print_init proc	near
	assume	ds:nothing,es:nothing

	cbw
	mov	dx,ax			; get printer port number into dx
	mov	ah,1			;initalize printer port
	int	17h			;call rom-bios routine
	ret

print_init endp

;--------------------------------------------------------------------

aux_init proc	near
	assume	ds:nothing,es:nothing

	cbw
	mov	dx,ax
	mov	al,rsinit		;2400,n,1,8 (msequ.inc)
	mov	ah,0			;initalize aux port
	int	14h			;call rom-bios routine
	ret

aux_init endp

;	M038 -- end additions

;--------------------------------------------------------------------

;**end of mini disk initialization**

;--------------------------------------------------------------------



;==========================================================================
;
; DOS loading is handled by SYSINIT.
;

ifndef ROMDOS
endif	; end of non-ROMDOS-only code


Bios_Data_Init	ends
	end
