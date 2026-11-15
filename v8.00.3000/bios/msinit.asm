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
	extrn	call_orig13:far
	extrn	int16_entry:far,int16_old:dword
;
; Indexes in the SYSINIT message offset table.
;
sysinit_cpu_msg	equ	0*2
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
	extrn	device_list:dword
	extrn	memory_size:word
	extrn	default_drive:byte
	extrn	bdss:byte		;for mini disk
	extrn	dskdrvs:word
	extrn	boot_data_high:word,boot_data_low:word
	extrn	no_floppy_report:byte
	extrn	sys_model_byte:byte,sys_scnd_model_byte:byte
	extrn	rpl_memory_size:word,boot_copy_buffer:byte
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



;	M015 -- begin additions

;	compaq fixed up rom



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
	extrn	eot:byte
	extrn	bin_date_time:byte,month_table:word
	extrn	Bios_Data_Word:word
	extrn	time_to_ticks:near
Bios_Code ends


SysInitMsg segment para public 'system_init'
	extrn	sysinit_msg_base:byte,sysinit_msg_table:word
SysInitMsg ends

Bios_Data_Init segment
	assume	cs:datagrp


Bios_Data_Init ends
Bios_Code segment
	assume	cs:Bios_Code
	extrn read_real_date:near,read_real_time:near,daycnt_to_day:near,daycnt_to_day_near:near,bin_to_bcd:near,bin_to_bcd_near:near
Bios_Code ends
Bios_Data_Init segment
	assume	cs:datagrp

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
init_fat32	db	0		; partition uses a 32 bit fat
init_boot_retry db	0		; backup boot sector tried
dsktnum	db	1		; number of diskette drives

; the following two bytes are used to save the info returned by int 13, ah = 8
; call to determine drive parameters.

num_heads db	2			; number of heads returned by rom
sec_trk   db	9			; sec/trk returned by rom
num_cyln  dw	40			; number of cylinders returned by rom

fakefloppydrv db      0 		; if 1, then no diskette drives in the system.

bootbias  =	200h
boot_addr =	7c00h

; Each entry contains a sector limit, cluster shift and size, root entries
; and fat flags.  The sector limit is a double word.

fat32_flag equ	20h

disktable2  dd	32680			; for compatibility
	    dw	0803h, 512, 0
	    dd	40000h			; covers upto 134 mb media
	    dw	0402h, 512, fbig
	    dd	80000h			; upto 268 mb
	    dw	0803h, 512, fbig
	    dd	100000h			; upto 536 mb
	    dw	1004h, 512, fbig
	    dd	200000h			; upto 1072 mb
	    dw	2005h, 512, fbig
	    dd	400000h			; upto 2144 mb
	    dw	4006h, 512, fbig
	    dd	800000h			; upto 4288 mb
	    dw	8007h, 512, fbig

disktable32 dd	82000h
	    dw	0100h, 0, fbig or fat32_flag
	    dd	1000000h
	    dw	0803h, 0, fbig or fat32_flag
	    dd	2000000h
	    dw	1004h, 0, fbig or fat32_flag
	    dd	4000000h
	    dw	2005h, 0, fbig or fat32_flag
	    dd	0ffffffffh
	    dw	4006h, 0, fbig or fat32_flag

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



bios_date db	'01/10/84',0

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
	dd	0		; extended sectors per fat
	dw	0		; extended flags
	dw	0		; file system version
	dd	0		; root directory cluster
	dw	0		; file system information sector
	dw	0		; backup boot sector
	db	12 dup (0)	; reserved
bpbx	ends


	nop				; align in Bios_Data

bpb48t	bpbx	<,2,,,112,2*9*40,0fdh,2,9>	; 48 tpi diskettes
	db	0			; align in Bios_Data
bpb96t	bpbx	<,1,,,224,2*15*80,0f9h,7,15>	; 96 tpi diskettes
	db	0			; align in Bios_Data
bpb35	bpbx	<,2,,,70h,2*9*80,0f9h,3,9>	; 3.5" diskettes
	db	0			; align in Bios_Data
bpb288	bpbx	<,2,,,240,2*36*80,0f0h,9,36>	; 2.88MB diskettes	; m037
	db	0			; align in Bios_Data
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

call_bios_code proc near
	assume	ds:nothing, es:nothing

	pop	cs:bios_call_return
	push	cs
	push	cs:bios_call_return
	.286
	push	offset bc_retf
	push	Bios_Code
	.8086
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
	mov	cs:saved_boot_bp,bp
	mov	cs:saved_boot_ss,ss
	mov	ss,si
	mov	sp,700h
	mov	cs:drvfat,dx
	mov	cs:boot_drive_copy,dx
	mov	ds,cs:init_sysinit_seg
	assume	ds:sysinitseg
	mov	boot_data_high,ax
	mov	boot_data_low,bx
	mov	ds,si
	assume	ds:nothing

; Save the original vectors and controller masks for the system loader.

	mov	ah,0fh
	int	10h
	mov	ax,50h
	mov	es,ax
	mov	di,3ch
	mov	ax,ds:[413h]		; conventional memory size
	stosw
	mov	ax,ds:[40eh]		; extended BIOS data segment
	stosw
	.386
	mov	cx,20h
	rep	movsd
	mov	dword ptr es:[0a4h],0
	mov	si,100h
	mov	cx,4
	rep	movsd
	add	si,8
	movsd
	add	si,10h
	movsd
	add	si,0ch
	movsd
	mov	si,1c0h
	mov	cx,8
	rep	movsd
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
	shl	ax,2
	mov	di,ax
	xchg	si,di
	movsd
	xchg	si,di
	loop	init_next_vector
	mov	eax,dword ptr es:Old13
	mov	dword ptr es:Orig13,eax
	mov	bx,cs
	mov	word ptr ds:[13h*4],offset block13
	mov	ds:[13h*4+2],bx
	mov	word ptr ds:[15h*4],offset Int15
	mov	ds:[15h*4+2],bx
	mov	ax,offset int16_entry
	xchg	ax,ds:[16h*4]
	mov	word ptr es:int16_old,ax
	mov	ax,bx
	xchg	ax,ds:[16h*4+2]
	mov	word ptr es:int16_old+2,ax
	mov	word ptr ds:[19h*4],offset int19
	mov	ds:[19h*4+2],bx
	sub	ax,ax
	mov	ds:[500h],ax
	mov	ds:[lstdrv],ax
	push	ds
	pop	es
	mov	di,530h
	stosd
	stosd
	.8086
	mov	word ptr ds:[1bh*4],offset cbreak
	mov	ds:[1bh*4+2],bx
	mov	word ptr ds:[29h*4],offset outchr
	mov	ds:[29h*4+2],bx
	mov	di,4
	mov	ax,offset intret
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
	stosw
	xchg	ax,bx
	stosw
	add	di,4
	xchg	ax,bx
	stosw
	xchg	ax,bx
	stosw
	xchg	ax,bx
init_debug_vectors:
	mov	di,10h
	stosw
	xchg	ax,bx
	stosw

	sti

	.386

;	Determine the number of physical floppy drives. Some BIOSes only
;	report the number of drives in their equipment word.
;
	xor	cl,cl
	mov	ah,8
	mov	dl,0
	int	13h
	jnc	short init_floppy_count
	int	11h
	test	ax,1
	jnz	short init_floppy_equipment
	xor	dl,dl
	jmp	short init_floppy_count
init_floppy_equipment:
	shr	al,6
	mov	dl,al
	inc	dl
init_floppy_count:
	mov	cs:rom_floppy_drives,dl
	movzx	ax,cs:rom_floppy_drives
	or	ax,ax
	jnz	short init_have_floppy
	inc	ax
	mov	cs:fakefloppydrv,al
	mov	es,cs:init_sysinit_seg
	assume	es:sysinitseg
	mov	es:no_floppy_report,al
	jmp	short settwodrive
init_have_floppy:
	dec	ax
	and	ax,3
	jnz	short notsingle
	inc	ax
settwodrive:
	inc	cs:flp_drvs
notsingle:
	inc	ax
	mov	cs:drvmax,al
	test	byte ptr cs:drvfat,80h
	jnz	short gothrd
	xor	ax,ax
gothrd:
	mov	byte ptr cs:drvfat,al

;	Read the system configuration when the BIOS supplies it.
;
	mov	ah,0c0h
	int	15h
	jc	short init_mem_size
	assume	es:nothing
	mov	al,es:[bx.bios_sd_modelbyte]
	mov	cs:model_byte,al
	mov	al,es:[bx.bios_sd_scnd_modelbyte]
	mov	cs:secondary_model_byte,al

;	Reserve the boot and disk-sector buffers below conventional memory
;	or below the area occupied by an installed RPL loader.
;
init_mem_size:
	int	12h
	shl	ax,6
	mov	dx,ax
	push	ax
	lds	bx,ds:dword ptr [2fh*4]
	assume	ds:nothing
	cmp	word ptr [bx+3],'PR'
	jnz	short SkipRPL
	cmp	byte ptr [bx+5],'L'
	jnz	short SkipRPL
	mov	cx,ax
	mov	ax,(multMULT shl 8)+multMULTRPLTOM
	int	2fh
	mov	ax,dx
	cmp	ax,cx
	jnz	short init_memory_set
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
	mov	cx,31h
	rep	movsw
	pop	ds
	stosw

	push	cs
	pop	ds
	push	cs
	pop	es
	assume	ds:datagrp,es:datagrp
	mov	cl,ss:[496h]
	test	cl,10h
	jz	short org_key
	mov	keyrd_func,10h
	mov	keysts_func,11h
org_key:
	or	bios_flags,20h
	mov	bp,offset read_real_date
	call	call_bios_code
	mov	hdrv_pat,offset harddrv
	mov	al,drvmax
	mov	dsktnum,al
	xor	ax,ax
	mov	hnum,al
	mov	dl,80h
	mov	ah,8
	int	13h
	jnc	short init_count_disks
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
	push	es
	pusha
	push	dx
	xor	bx,bx
	mov	ah,8
	int	13h
	pop	ax
	jc	noparmsfromrom
	cmp	bl,10h
	jne	standard_floppy_parms
	call	ext_floppy_parms
	jc	standard_floppy_parms
	mov	num_cyln,cx
	mov	num_heads,dh
	mov	sec_trk,al
	mov	es,word ptr [cdev+2]
	assume	es:Bios_Code
	cmp	al,es:eot
	jbe	ext_eot_ok
	mov	es:eot,al
ext_eot_ok:
	test	bl,fchangeline
	popa
	pop	es
	pop	ds
	assume	es:nothing
	jz	gotother
	or	cl,fchangeline
	or	bios_flags,2
	jmp	short gotother
standard_floppy_parms:
	inc	dh
	mov	num_heads,dh
	push	cx
	and	cl,3fh
	mov	sec_trk,cl
	pop	cx
	xchg	ch,cl
	shr	ch,6
	inc	cx
	mov	num_cyln,cx
	mov	cl,sec_trk
	mov	es,word ptr [cdev+2]
	assume	es:Bios_Code
	cmp	cl,es:eot
	jbe	eot_ok
	mov	es:eot,cl
eot_ok:
	popa
	pop	es
	assume	es:nothing
	pop	ds
	mov	ah,15h
	int	13h
	jc	changeline_done
	cmp	ah,2
	jne	changeline_done
	or	cl,fchangeline
	or	bios_flags,2
changeline_done:
	cmp	num_cyln,40
	jnz	try_80
	cmp	sec_trk,9
	jbe	nextdrive
gotother:
	mov	dh,ffother
	jmp	short nextdrive
try_80:
	cmp	num_cyln,80
	jnz	gotother
	mov	dh,ff288
	cmp	sec_trk,36
	je	nextdrive
	cmp	sec_trk,15
	jz	got96
	cmp	sec_trk,9
	jnz	gotother
	mov	dh,ffsmall
	jmp	short nextdrive
got96:
	mov	dh,ff96tpi
	jmp	short nextdrive
noparmsfromrom:
	popa
	pop	es
	pop	ds
	mov	ah,15h
	int	13h
	jc	nextdrive
	cmp	ah,2
	jnz	nextdrive
	or	cl,fchangeline
	or	bios_flags,2
	mov	num_cyln,80
	mov	dh,ff96tpi
	mov	al,15
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
	mov	bx,num_cyln
	mov	es:[di].bds_ccyln,bx
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

; The transient disk tables follow the low initialization code.
init_cpu_ecx:
	mov	di,offset datagrp:BiosInitEnd
	push	cs
	pop	es
	assume	es:datagrp

configdone:				;di is final ending address of msbio.

	add	di,15
	shr	di,4
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
	push	si
	mov	si,3			; retry a failed read three times
	mov	es,cs:init_bootseg
	sub	bx,bx
getboot_read:
	mov	ax,0201h
	xor	dh,dh
	mov	cx,0001h
	int	13h
	push	es
	pop	ds
	assume	ds:nothing
	jc	erret
	cmp	word ptr ds:[bx+1feh],0aa55h
	clc				; zero flag reports the signature
norm_ret:
	pop	si
	pop	es
	pop	dx
	ret
erret:
	dec	si
	stc
	jz	norm_ret
	xor	ax,ax
	int	13h
	jmp	short getboot_read
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
	jnc	sethard_partition
	or	dh,dh
	stc
	jnz	setret
	push	es
	push	ds
	pop	es
	mov	ax,0201h
	mov	dh,1
	mov	cx,1
	int	13h
	pop	es
	jc	setret
	cmp	word ptr ds:[bx+1feh],0aa55h
	je	sethard_boot
sethard_badboot:
	stc
	jmp	setret
sethard_boot:
	cmp	byte ptr ds:[bx],0e9h
	je	sethard_bpb
	cmp	byte ptr ds:[bx],0ebh
	jne	sethard_badboot
	cmp	byte ptr ds:[bx+2],90h
	jne	sethard_badboot
sethard_bpb:
	mov	cs:init_fat32,0
	cmp	[bx].EXT_BOOT_BPB.BPB_SECTORSPERFAT,0
	jne	sethard_fat16
	cmp	byte ptr ds:[bx+42h],ext_boot_signature
	jne	sethard_badboot
	cmp	[bx].EXT_BOOT_BPB.BPB_BIGSECTORSPERFAT,0
	je	sethard_badboot
	cmp	[bx].EXT_BOOT_BPB.BPB_ROOTCLUS,2
	jb	sethard_badboot
	cmp	[bx].EXT_BOOT_BPB.BPB_FSVER,0
	ja	sethard_badboot
	inc	cs:init_fat32
	or	cs:fbigfat,fat32_flag
	jmp	short sethard_check_bpb
sethard_fat16:
	cmp	[bx].EXT_BOOT_SIG,ext_boot_signature
	jne	sethard_badboot
sethard_check_bpb:
	cmp	[bx].EXT_BOOT_BPB.BPB_NUMBEROFFATS,0
	je	sethard_badboot
	mov	al,[bx].EXT_BOOT_BPB.BPB_MEDIADESCRIPTOR
	and	al,0f0h
	cmp	al,0f0h
	jne	sethard_badboot
	cmp	[bx].EXT_BOOT_BPB.BPB_BYTESPERSECTOR,512
	jne	sethard_badboot
	mov	al,[bx].EXT_BOOT_BPB.BPB_SECTORSPERCLUSTER
	or	al,al
	jz	sethard_badboot
sethard_cluster:
	shr	al,1
	jnc	sethard_cluster
	jnz	sethard_badboot
	mov	ax,[bx].EXT_BOOT_BPB.BPB_BYTESPERSECTOR
	mov	es:[di].BDS_BPB.BPB_BYTESPERSECTOR,ax
	mov	ax,[bx].EXT_BOOT_BPB.BPB_TOTALSECTORS
	mov	es:[di].BDS_BPB.BPB_TOTALSECTORS,ax
	mov	al,[bx].EXT_BOOT_BPB.BPB_MEDIADESCRIPTOR
	mov	es:[di].BDS_BPB.BPB_MEDIADESCRIPTOR,al
	mov	ax,[bx].EXT_BOOT_BPB.BPB_HIDDENSECTORS
	mov	es:[di].BDS_BPB.BPB_HIDDENSECTORS,ax
	mov	ax,[bx].EXT_BOOT_BPB.BPB_HIDDENSECTORS+2
	mov	es:[di].BDS_BPB.BPB_HIDDENSECTORS+2,ax
	jmp	copybpb_fat
sethard_partition:
	jne	sethard_badboot
	mov	bx,1c2h			; first partition type


;	M018 -- begin changed section

;	The first 'active' partition is 00, the second is 01....
;	  then the remainder of the 'primary' but non-active partitions

act_part:
	mov	cs:init_fat32,0
	test	BYTE PTR ds:[bx - 4],80h  ;AN016;is the partition active?
	jz	not_act
	cmp	byte ptr ds:[bx],1	; reject if partitiontype != 1, 4, 6 or 0eh
	jz	got_good_act
	cmp	byte ptr ds:[bx],4
	jz	got_good_act
	cmp	byte ptr ds:[bx],6
	jz	got_good_act
	cmp	byte ptr ds:[bx],0bh
	jz	got_good_act
	cmp	byte ptr ds:[bx],0eh
	jz	got_good_act
	cmp	byte ptr ds:[bx],0ch
	jnz	not_act			; reject!
got_good_act:
	or	dh,dh			; is this our target partition #?
	jz	set2			; WE GOT THE ONE WANTED!!
	dec	dh			; count down
not_act:
	add	bx,16			;AN016;next entry
	cmp	bx,1feh	;AN016;last entry done?
	jb	act_part		;AN016;no,process next entry

;	Now scan the non-active partitions

	mov	bx,1c2h	;AN016;restore original value of bx

get_primary:
	mov	cs:init_fat32,0
	test	byte ptr ds:[bx - 4],80h ; we've already scanned
	jnz	not_prim		; the ACTIVE ones
	cmp	byte ptr ds:[bx],1	; see if partitiontype == 1, 4, 6 or 0eh
	jz	got_prim
	cmp	byte ptr ds:[bx],4
	jz	got_prim
	cmp	byte ptr ds:[bx],6
	jz	got_prim
	cmp	byte ptr ds:[bx],0bh
	jz	got_prim
	cmp	byte ptr ds:[bx],0eh
	jz	got_prim
	cmp	byte ptr ds:[bx],0ch
	jnz	not_prim

got_prim:
	or	dh,dh			; is this our target partition?
	jz	set2
	dec	dh

not_prim:
	add	bx,16
	cmp	bx,1feh
	jb	get_primary		; loop till we've gone through table

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
	cmp	byte ptr ds:[bx],0bh
	jne	set2_extended
	inc	cs:init_fat32
set2_extended:
	cmp	byte ptr ds:[bx],0eh
	je	set2_lba
	cmp	byte ptr ds:[bx],0ch
	jne	set2_chs
	inc	cs:init_fat32
set2_lba:
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
	mov	es:[di].BDS_BPB.BPB_TOTALSECTORS,0
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2,dx
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS,ax ;   bpb->maxsec = p->partitionlength;
	cmp	dx,0
	ja	okdrive_cont

	cmp	ax,64			;   if (p->partitionlength < 64)
	jb	setret			;	return -1;

okdrive_cont:
	mov	cs:init_boot_retry,0
	mov	dx,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS	; boot sector number - for mini disk,;j.k.
set2_read:
	test	word ptr es:[di].bds_flags,0400h
	jz	set2_chs_read
	mov	ch,cs:rom_drv_num
	mov	cl,1
	lds	bx,cs:disksector_ptr
	call	init_ext_read
	jmp	short set2_read_done
set2_chs_read:
	movzx	ebx,byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK
	movzx	eax,ax
	shl	edx,16
	or	eax,edx
	xor	edx,edx
	div	ebx
	mov	cl,dl
	inc	cl
	movzx	ebx,byte ptr es:[di].BDS_BPB.BPB_HEADS
	xor	edx,edx
	div	ebx
	cmp	eax,1024
	ja	setret			; exceeds the limit of int 13h

; dl is head.
; ax is cylinder
; cl is sector number (assume less than 2**6 = 64 for int 13h)

;*** for mini disks ***
	cmp	es:[di].bdsm_ismini,1 		;check for mini disk
	jnz	oknotmini		;not mini disk.
	add	ax,es:[di].bdsm_hidden_trks	;set the physical track number
oknotmini:
;*** end of added logic for mini disk

	ror	ah,2			; move high two bits of cyl to high
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
	jnc	set2_check_boot
	cmp	cs:init_fat32,0
	stc
	jz	setret
	cmp	cs:init_boot_retry,0
	stc
	jnz	setret
set2_backup:
	mov	cs:init_boot_retry,1
	mov	dx,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2
	mov	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS
	add	ax,6
	adc	dx,0
	jmp	set2_read
set2_check_boot:

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
	lea	bx,[bx].EXT_BOOT_BPB
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
	cmp	cs:init_fat32,0
	jz	unknown_boot
	cmp	cs:init_boot_retry,0
	jnz	unknown_boot
	jmp	short set2_backup

valid_boot_record:			; for valid boot record
	pop	ax			; restore registers
	pop	bx			;

; signature found.  Now check version.

	cmp	word ptr ds:[bx+8],"." shl 8 + "2"
	jnz	try5
	cmp	byte ptr ds:[bx+10],"0"
	jnz	try5

	jmp	short copybpb

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
unknown_boot:
	jmp	unknown

; no os2 signature, this is to check for real dos versions

no_os2:
	cmp	word ptr ds:[bx+8],"." shl 8 + "3"
	jb	unknown3_0		; must be 2.1 boot record. do not trust it, but still legal.
	jnz	copybpb 		; honor os2 boot record, or dos 4.0 version
	cmp	byte ptr ds:[bx+10],"1"	;do not trust 3.0 boot record. but still legal
	jb	unknown3_0		; if version >= 3.1, then o.k.

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

	cmp	[bx].EXT_BOOT_BPB.BPB_SECTORSPERFAT,0
	jne	copybpb_fat16
	cmp	byte ptr ds:[bx+42h],ext_boot_signature
	jne	copybpb_nonfat
	cmp	[bx].EXT_BOOT_BPB.BPB_NUMBEROFFATS,0
	je	copybpb_nonfat
	cmp	[bx].EXT_BOOT_BPB.BPB_ROOTCLUS,2
	jb	copybpb_nonfat
	cmp	[bx].EXT_BOOT_BPB.BPB_BIGSECTORSPERFAT,0
	je	copybpb_nonfat
	cmp	[bx].EXT_BOOT_BPB.BPB_FSVER,0
	ja	copybpb_nonfat
	cmp	cs:init_fat32,0
	jz	near ptr toobig_ret
copybpb_fat32:
	or	cs:fbigfat,fat32_flag
	jmp	short copybpb_fat
copybpb_fat16:
	cmp	[bx].EXT_BOOT_SIG,ext_boot_signature
	jne	copybpb_fat		; conventional fat system
	cmp	[bx].EXT_BOOT_BPB.BPB_NUMBEROFFATS,0
	jne	copybpb_fat		;   a fat system.

; non fat based media.
copybpb_nonfat:
	or	es:[di].bds_flags,unformatted_media
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

	mov	cx,size A_BPB

	rep	movsb

	pop	di
	mov	bp,offset mov_media_ids
	call	call_bios_code
	jmp	goodret

copybpb_fat:				; fat system
	lea	si,[bx].EXT_BOOT_BPB
	movzx	eax,word ptr ds:[si].BPB_TOTALSECTORS
	or	ax,ax
	jnz	copy_totsec
	mov	eax,dword ptr ds:[si].BPB_BIGTOTALSECTORS
	or	eax,eax
	jz	totsec_already_set
copy_totsec:
	mov	dword ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS,eax
totsec_already_set:
	mov	eax,dword ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS

fat_big_small:			; determine fat entry size
	push	bx
	mov	bl,ds:[si].BPB_NUMBEROFFATS
	mov	es:[di].BDS_BPB.BPB_NUMBEROFFATS,bl
	movzx	ebx,ds:[si].BPB_RESERVEDSECTORS
	mov	es:[di].BDS_BPB.BPB_RESERVEDSECTORS,bx
	sub	eax,ebx
	mov	bx,ds:[si].BPB_SECTORSPERFAT
	mov	es:[di].BDS_BPB.BPB_SECTORSPERFAT,bx
	or	bx,bx
	jnz	fat_count
	push	si
	push	di
	lea	si,[si].BPB_BIGSECTORSPERFAT
	lea	di,[di].BDS_BPB.BPB_BIGSECTORSPERFAT
	mov	cx,14
	cld
	rep	movsw
	pop	di
	pop	si
	mov	ebx,ds:[si].BPB_BIGSECTORSPERFAT
fat_count:
	mov	edx,ebx
	movzx	cx,ds:[si].BPB_NUMBEROFFATS
	jcxz	fat_sectors
	dec	cx
	jz	fat_sectors
fat_add:
	add	ebx,edx
	loop	fat_add
fat_sectors:
	sub	eax,ebx
	movzx	ebx,ds:[si].BPB_ROOTENTRIES
	mov	es:[di].BDS_BPB.BPB_ROOTENTRIES,bx
	cmp	ds:[si].BPB_SECTORSPERFAT,0
	jz	fat_clusters
	add	ebx,15
	shr	ebx,4
	sub	eax,ebx
fat_clusters:
	pop	bx
	movzx	ecx,ds:[si].BPB_SECTORSPERCLUSTER
	mov	es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER,cl
	xor	edx,edx
	div	ecx
	cmp	eax,4096-10
	jb	copymediaid
	cmp	eax,65536-10
	jb	fat_word_entries
	test	cs:fbigfat,fat32_flag
	jnz	copymediaid
toobig_ret:
	or	cs:fbigfat,ftoobig
	jmp	goodret
fat_word_entries:
	or	cs:fbigfat,fbig
copymediaid:
	mov	bp,offset mov_media_ids
	call	call_bios_code
	jmp	massage_bpb

unknown:
	or	es:[di].bds_flags, unformatted_media ; M042
					; Set unformatted media flag.

;  the boot signature may not be recognizable,
;     but we should try and read it anyway.

unknown3_0:				;skip setting unformatted_media bit
	mov	eax,dword ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	mov	si,offset datagrp:disktable2
	cmp	cs:init_fat32,0
	jz	scan
	mov	si,offset datagrp:disktable32
scan:

	cmp	eax,dword ptr cs:[si]
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

	mov	eax,dword ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER,ch ;save sectors per cluster
	test	cs:fbigfat,fbig or fat32_flag
	jnz	dobig			;	goto dobig;

;   we don't need to change "small fat" logic since it is gauranteed
;   that double word total sector will not use 12 bit fat (unless
;   it's sectors/cluster >= 16 which will never be in this case.)
;   so in this case the total sector count fits in ax.

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
; Calculate the fat size from data sectors and the selected cluster size.

	test	cs:fbigfat,fat32_flag
	jz	fat_root_size
	mov	es:[di].BDS_BPB.BPB_NUMBEROFFATS,2
	mov	es:[di].BDS_BPB.BPB_RESERVEDSECTORS,20h
fat_root_size:
	test	cs:fbigfat,fat32_flag
	jnz	fat_reserved
	movzx	edx,es:[di].BDS_BPB.BPB_ROOTENTRIES
	add	edx,15
	shr	edx,4
	sub	eax,edx
fat_reserved:
	movzx	edx,es:[di].BDS_BPB.BPB_RESERVEDSECTORS
	sub	eax,edx
	movzx	ebx,es:[di].BDS_BPB.BPB_NUMBEROFFATS
	mov	bh,es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER
	test	cs:fbigfat,fat32_flag
	jz	fat_divisor
	shr	ebx,1
fat_divisor:
	add	eax,ebx
	dec	eax
	xor	edx,edx
	div	ebx
	xor	ecx,ecx
	test	cs:fbigfat,fat32_flag
	jz	fat_store_size
	xchg	eax,ecx
fat_store_size:
	mov	es:[di].BDS_BPB.BPB_SECTORSPERFAT,ax
	mov	es:[di].BDS_BPB.BPB_BIGSECTORSPERFAT,ecx

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
	cmp	[bx].EXT_BOOT_BPB.BPB_SECTORSPERFAT,0
	je	cfb_retit
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

	movzx	eax,es:[di].BDS_BPB.BPB_TOTALSECTORS
	or	ax,ax
	jnz	get_ccyl
	mov	eax,dword ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
get_ccyl:
	push	eax
	mov	ax,es:[di].BDS_BPB.BPB_HEADS
	mul	es:[di].BDS_BPB.BPB_SECTORSPERTRACK
	movzx	ecx,ax
	pop	eax
	xor	edx,edx
	div	ecx
	or	dx,dx
	jz	no_cyl_rnd		; came out even
	inc	ax			; round up
no_cyl_rnd:
	mov	es:[di].bds_ccyln,ax
	push	es
	pop	ds
	lea	si,[di].BDS_BPB.BPB_BYTESPERSECTOR	; ds:si -> bpb for hard file
	jmp	set_recbpb

nothardff:

; we don't use the extended bpb for a floppy.


;	if fake floppy drive variable is set then we don't have to handle this
;	bds.  we can just go and deal with the next bds at label go_to_next_bds.

	cmp	fakefloppydrv,1
	jz	go_to_next_bds

	cmp	bl,ffother		; special case "other" type of medium
	jnz	not_process_other

process_other:
	movzx	eax,es:[di].BDS_RBPB.BPB_HEADS
	movzx	ecx,es:[di].BDS_RBPB.BPB_SECTORSPERTRACK
	mul	ecx
	movzx	ecx,es:[di].bds_ccyln
	mul	ecx
	mov	dword ptr es:[di].BDS_RBPB.BPB_BIGTOTALSECTORS,eax
	test	eax,0ffff0000h
	jz	other_small
	mov	es:[di].BDS_RBPB.BPB_TOTALSECTORS,0
	mov	si,offset datagrp:disktable2
	cmp	eax,100000h
	jb	other_scan
	mov	es:[di].BDS_RBPB.BPB_RESERVEDSECTORS,20h
	mov	si,offset datagrp:disktable32
other_scan:
	cmp	eax,dword ptr cs:[si]
	jbe	other_gotparm
	add	si,5 * 2
	jmp	short other_scan
other_gotparm:
	mov	bl,byte ptr cs:[si+8]
	mov	cx,word ptr cs:[si+4]
	movzx	edx,word ptr cs:[si+6]
	mov	es:[di].BDS_RBPB.BPB_ROOTENTRIES,dx
	mov	es:[di].BDS_RBPB.BPB_SECTORSPERCLUSTER,ch
	shr	edx,4
	sub	eax,edx
	movzx	edx,es:[di].BDS_RBPB.BPB_RESERVEDSECTORS
	sub	eax,edx
	movzx	ecx,es:[di].BDS_RBPB.BPB_NUMBEROFFATS
	mov	ch,es:[di].BDS_RBPB.BPB_SECTORSPERCLUSTER
	test	bl,fat32_flag
	jz	other_divisor
	shr	ecx,1
other_divisor:
	add	eax,ecx
	dec	eax
	xor	edx,edx
	div	ecx
	test	bl,fat32_flag
	jz	no_round_up
	mov	es:[di].BDS_RBPB.BPB_BIGSECTORSPERFAT,eax
	xor	ax,ax
	jmp	short no_round_up
other_small:
	mov	es:[di].BDS_RBPB.BPB_TOTALSECTORS,ax
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
	jnz	domininext		; invalid boot signature
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

	push	bx
	lea	bx,[bx+1c2h]		; first partition type
	mov	cs:ext_partition_lba,0
fmpnext:
	cmp	byte ptr [bx],5
	jz	fmpgot
	cmp	byte ptr [bx],0fh
	jz	fmp_lba
	add	bx,16
	cmp	bx,1feh
	jb	fmpnext
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
	jnc	fmpret
	mov	di,cs:end_of_bdss
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
	jb	near ptr fmpret
fmpgot_cont:
	cmp	cs:ext_partition_lba,0
	jz	fmp_chs
	or	word ptr es:[di].bds_flags,0400h
	mov	ax,[bx+4]
	add	ax,cs:ext_partition_next
	mov	dx,[bx+6]
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
	pop	bx
	push	bx
	call	init_ext_read
	jmp	short fmp_read_done
fmp_chs:
	mov	dh,[bx-2]
	and	dh,0c0h
	rol	dh,2
	mov	dl,[bx-1]
	mov	es:[di].bdsm_hidden_trks,dx
	mov	cx,[bx-2]
	mov	dh,[bx-3]
	mov	dl,cs:rom_minidisk_num
	mov	ax,201h
	pop	bx
	push	bx
	push	es
	push	ds
	pop	es
	int	13h
	pop	es
fmp_read_done:
	jc	fmpret
	lea	bx,[bx+1c2h]
	push	es
	call	setmini
	pop	es
	jc	fmpnext
	call	xinstall_bds
fmpnextchain:
	jmp	fmpnext
fmpret:
	pop	bx
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
	mov	ax,4200h
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
	mov	cs:init_fat32,0
	cmp	byte ptr ds:[bx],0bh
	jnz	setmini_extended
	inc	cs:init_fat32
	jmp	short setmini_2
setmini_extended:
	cmp	byte ptr ds:[bx],0eh
	jz	setmini_lba
	cmp	byte ptr ds:[bx],0ch
	jnz	setmini_legacy
	inc	cs:init_fat32
setmini_lba:
	or	word ptr es:[di].bds_flags,0400h
	jmp	short setmini_2
setmini_legacy:
	cmp	byte ptr ds:[bx],1
	jz	setmini_2

	cmp	byte ptr ds:[bx],4
	jz	setmini_2

	cmp	byte ptr ds:[bx],6
	jz	setmini_2

	add	bx,16
	cmp	bx,1feh
	jb	setmini_1

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

; Get extended diskette geometry.  AL is the physical drive number.
; Return CX cylinders, DH heads, AL sectors and BL change-line flags.
; Carry is set if the ROM does not support extended parameters.

ext_floppy_parms proc near
	assume	ds:nothing,es:nothing
	push	ds
	push	si
	sub	sp,1ah
	mov	si,sp
	mov	dl,al
	mov	ax,ss
	mov	ds,ax
	mov	word ptr [si],1ah
	mov	ah,48h
	int	13h
	jc	ext_floppy_done
	xor	bl,bl
	mov	dh,[si+8]
	mov	al,[si+0ch]
	mov	cx,[si+4]
	test	word ptr [si+2],10h
	jz	ext_floppy_done
	or	bl,fchangeline
ext_floppy_done:
	lahf
	add	sp,1ah
	sahf
	pop	si
	pop	ds
	ret
ext_floppy_parms endp



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


	.8086
Bios_Data_Init	ends

Filler	segment
BiosInitEnd label byte
	db	8000 dup (?)	; transient space following BIOS initialization
Filler	ends
	end
