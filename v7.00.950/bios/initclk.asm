;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160
	title	initclk for BIOS

BYTE_SYSINIT equ 1
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
	extrn	outchr:near

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


;cmos clock setting support routines used by msclock.
;
; warning!!! this code will be dynamically relocated by msinit.



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
	public	read_real_date,read_real_time

IFNDEF	POWER				; M083
	align	2			; cas -- trash aligns!

; the k09 requires the routines for reading the clock because of the suspend/
; resume facility. the system clock needs to be reset after resume.

	assume	es:nothing

; the following routine is executed at resume time when the system
; powered on after suspension. it reads the real time clock and
; resets the system time and date, and then irets.

; warning!!! this code will be dynamically relocated by msinit.



;************************************************************************
;
;   read_real_date reads real-time clock for date and returns the number
;   of days elapsed since 1-1-80 in daycnt2
;
read_real_date proc near
	assume	ds:datagrp,es:nothing

	assume	ds:Bios_Code
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	push	cs
	pop	ds
	push	es
	mov	es,Bios_Data_Word

	xor	ah,ah			; throw away clock roll over
	int	1ah


	mov	es:daycnt2,1	; real time clock error flag (+1 day)
	mov	ah,4		; read date function code
	int	1ah		; read real-time clock
	jnc	read_ok 	; jmp success
	jmp	r_d_ret 	; jmp error

read_ok:			; ******* get bcd values in binary *****
	mov	byte ptr bin_date_time+0,ch  ; store as hex value
	mov	byte ptr bin_date_time+1,cl  ; ...
	mov	byte ptr bin_date_time+2,dh  ; ...
	mov	byte ptr bin_date_time+3,dl  ; ...

	mov	es:daycnt2,2	; read of r-t clock successful
	call	bcd_verify	; verify bcd values in range
	jc	r_d_ret 	; jmp some value out of range
	mov	es:daycnt2,3	; read of r-t clock successful
	call	date_verify	; verify date values in range
	jc	r_d_ret 	; jmp some value out of range
	mov	es:daycnt2,0	; verify successful
	call	in_bin		; convert date to binary
				; ******* years since 1-1-80 *********
	mov	al,byte ptr bin_date_time+1  ; get years into century
	cbw				     ;
	cmp	byte ptr bin_date_time+0,20  ; 20th century?
	jnz	century_19		     ; jmp no
	add	ax,100		; add in a century
century_19:			;
	sub	ax,80		; subtract off 1-1-80
	mov	cl,4		; leap year every 4
	div	cl		; al= # leap year blocks, ah= remainder
	mov	bl,ah		; save odd years
	cbw			; zero ah
	mov	cx,366+3*365	; # of days in leap year blocks
	mul	cx		; dx:ax is result
	mov	es:daycnt2,ax	; save count of days
	mov	al,bl		; get odd years count
	cbw			;
	or	ax,ax		; is ax= 0?
	jz	leap_year	; jmp if none
	mov	cx,365		; days in year
	mul	cx		; dx:ax is result
	add	es:daycnt2,ax	; add on days in odd years
	jmp	short leap_adjustment ; account for leap year
leap_year:			; possibly account for a leap day
	cmp	byte ptr bin_date_time+2,2 ; is month february
	jbe	no_leap_adjustment ; jan or feb. no leap day yet.
leap_adjustment:		; account for leap day
	inc	es:daycnt2
no_leap_adjustment:		; ******* get days of month *******
	mov	cl,byte ptr bin_date_time+3
	xor	ch,ch
	dec	cx		; because of offset from day 1, not day 0
	add	es:daycnt2,cx	 ; ******* get days in months preceeing *****
	mov	cl,byte ptr bin_date_time+2   ; get month
	xor	ch,ch
	dec	cx		; january starts at offset 0
	shl	cx,1		; word offset
	mov	bx,offset month_table
	add	bx,cx
	mov	ax,word ptr [bx]
	add	es:daycnt2,ax
r_d_ret:
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret


read_real_date endp

;--------------------------------------------------------------------

; read_real_time reads the time from the rtc. on exit, it has the number of
; ticks (at 18.2 ticks per sec.) in cx:dx.

read_real_time proc near
	assume	ds:datagrp,es:nothing	; cas -- is this correct????

	assume	ds:Bios_Code
	push	ds
	push	cs
	pop	ds
	mov	ah,2
	int	1ah
	jc	r_t_retj

oktime:
	mov	byte ptr bin_date_time,ch	; hours
	mov	byte ptr bin_date_time+1,cl	; minutes
	mov	byte ptr bin_date_time+2,dh	; seconds
	mov	byte ptr bin_date_time+3,0	; unused for time

	call	bcd_verify
	jc	r_t_retj
	call	time_verify
	jc	r_t_retj

	call	in_bin
	mov	ch,byte ptr bin_date_time
	mov	cl,byte ptr bin_date_time+1
	mov	dh,byte ptr bin_date_time+2
	mov	dl,byte ptr bin_date_time+3

; get time in ticks in cx:dx

	call	time_to_ticks
	jmp	short r_t_ret
r_t_retj:
	xor	cx,cx
	xor	dx,dx
r_t_ret:
	pop	ds
	ret

read_real_time endp

;--------------------------------------------------------------------

;   in_bin converts bin_date_time values from bcd to bin

in_bin	proc	near
	assume	ds:datagrp,es:nothing
	assume	ds:Bios_Code

	mov	al,byte ptr bin_date_time+0  ; century or hours
	call	bcd_to_bin
	mov	byte ptr bin_date_time+0,al

	mov	al,byte ptr bin_date_time+1  ; years or minutes
	call	bcd_to_bin
	mov	byte ptr bin_date_time+1,al

	mov	al,byte ptr bin_date_time+2  ; months or seconds
	call	bcd_to_bin
	mov	byte ptr bin_date_time+2,al

	mov	al,byte ptr bin_date_time+3  ; days (not used for time)
	call	bcd_to_bin
	mov	byte ptr bin_date_time+3,al

	ret

in_bin	endp

;--------------------------------------------------------------------

;   bcd_to_bin converts two bcd nibbles in al (value <= 99.) to
;   a binary representation in al
;   ah is destroyed


;--------------------------------------------------------------------

;   date_verify loosely checks bcd date values to be in range in bin_date_time

date_verify proc near
	assume	ds:datagrp,es:nothing
	assume	ds:Bios_Code

	cmp	byte ptr bin_date_time+0,20h  ; century check
	ja	date_error		      ;	error
	jz	century_20		      ; jmp in 20th century

	cmp	byte ptr bin_date_time+0,19h  ; century check
	jb	date_error		      ;  error
	cmp	byte ptr bin_date_time+1,80h  ; year check
	jb	date_error		      ;  error

century_20:
	cmp	byte ptr bin_date_time+1,99h  ; year check
	ja	date_error		      ;  error
	cmp	byte ptr bin_date_time+2,12h  ; month check
	ja	date_error		      ;  error
	cmp	byte ptr bin_date_time+2,00h  ; month check
	jbe	date_error		      ;  error
	cmp	byte ptr bin_date_time+3,31h  ; day check
	ja	date_error		      ;  error
	cmp	byte ptr bin_date_time+3,00h  ; day check
	jbe	date_error		      ;  error
	clc				      ; set success flag
	ret
date_error:
	stc				      ; set error flag
	ret

date_verify endp

;--------------------------------------------------------------------

; time_verify very loosely checks bcd date values to be in range in bin_date_time

time_verify proc near
	assume	ds:datagrp,es:nothing
	assume	ds:Bios_Code

	cmp	byte ptr bin_date_time+0,24h
	ja	time_error
	cmp	byte ptr bin_date_time+1,59h
	ja	time_error
	cmp	byte ptr bin_date_time+2,59h
	ja	time_error

	clc
	ret

time_error:
	stc
	ret

time_verify endp

;--------------------------------------------------------------------

;   bcd_verify checks values in bin_date_time to be valid
;   bcd numerals.  carry set if any nibble out of range

bcd_verify proc near
	assume	ds:datagrp,es:nothing
	assume	ds:Bios_Code

	mov	cx,4		; 4 bytes to check
	mov	bx,offset bin_date_time
bv_loop:
	mov	al,[bx] 	; get a bcd number (0..99)
	mov	ah,al
	and	ax,0f00fh	; 10's place in high ah, 1's in al
	cmp	al,10		; is 1's place in range?
	ja	bv_error	; jmp out of range

	shr	ah,1		; swap nibbles
	shr	ah,1
	shr	ah,1
	shr	ah,1
	and	ah,0fh		; get rid of any erroneous bits
	cmp	ah,10		; is 10's place in range
	ja	bv_error	; jmp out of range

	inc	bx		; next byte
	dec	cx
	jnz	bv_loop

	clc			; set success flag
	ret

bv_error:
	stc			; set error flag
	ret

bcd_verify endp

;--------------------------------------------------------------------

;  the real time clock structures were moved to msbio2.asm

endk09	label	byte

ENDIF ; NOT POWER		; M083

	public	daycnt_to_day,daycnt_to_day_near ; for real time clock support
daycnt_to_day_near label near
daycnt_to_day	proc	near	; for real time clock support
	assume	ds:datagrp,es:nothing

;entry: [daycnt] = number of days since 1-1-80
;
;return: ch - centry in bcd
;	 cl - year in bcd
;	 dh - month in bcd
;	 dl - day in bcd

	push	[daycnt]		;save daycnt
	cmp	daycnt,(365*20+(20/4))	;# of days from 1-1-1980 to 1-1-2000
	jae	century20

	mov	cs:base_century,19
	mov	cs:base_year,80
	jmp	short years

century20:				;20th century
	mov	cs:base_century,20
	mov	cs:base_year,0
	sub	daycnt,(365*20+(20/4))	;adjust daycnt
years:
	xor	dx,dx
	mov	ax,daycnt
	mov	bx,(366+365*3)		;# of days in a leap year block
	div	bx			;ax = # of leap block, dx = daycnt
	mov	daycnt,dx		;save daycnt left

	mov	bl,4
	mul	bl			;ax = # of years. less than 100 years!
	add	cs:base_year,al		;so, ah = 0. adjust year accordingly.
	inc	daycnt			;set daycnt to 1 base
	cmp	daycnt,366		;the daycnt here is the remainder of the leap year block.
	jbe	leapyear		;so, it should within 366+355+355+355 days.
	inc	cs:base_year		;first if daycnt <= 366, then leap year
	sub	daycnt,366		;else daycnt--, cs:base_year++;
					;and the next three years are regular years.
	mov	cx,3
regularyear:
	cmp	daycnt,365		;for(i=1; i>3 or daycnt <=365;i++)
	jbe	yeardone		;{if (daycnt > 365)
	inc	cs:base_year		;  { daycnt -= 365
	sub	daycnt,365		;  }
	loop	regularyear		;}

;	should never fall through loop

leapyear:
	mov	byte ptr cs:month_tab+1,29 ;leap year. change the month table.
yeardone:
	xor	bx,bx
	xor	dx,dx
	mov	ax,daycnt
	mov	si,offset cs:month_tab
	mov	cx,12
months:
	inc	bl
	mov	dl,byte ptr cs:[si]	;compare daycnt for each month until fits
	cmp	ax,dx			;dh=0.
	jbe	month_done

	inc	si			;next month
	sub	ax,dx			;adjust daycnt
	loop	months

;	should never fall through loop

month_done:
	mov	byte ptr cs:month_tab+1,28 ;restore month table value
	mov	dl,bl
	mov	dh,cs:base_year
	mov	cl,cs:base_century 	;now, al=day, dl=month,dh=year,cl=century
	call	bin_to_bcd		;oh my!!! to save 15 bytes, bin_to_bcd proc
					;was relocated seperately from daycnt_to_day proc.
	xchg	dl,al			;dl = bcd day, al = month
	call	bin_to_bcd

	xchg	dh,al			;dh = bcd month, al = year
	call	bin_to_bcd

	xchg	cl,al			;cl = bcd year, al = century
	call	bin_to_bcd

	mov	ch,al			;ch = bcd century
	pop	[daycnt]		;restore original value
	ret
daycnt_to_day	endp

enddaycnttoday label	byte

	public	bin_to_bcd,bin_to_bcd_near
bin_to_bcd_near label near
bin_to_bcd	proc	near		;for real time clock support

;convert a binary input in al (less than 63h or 99 decimal)
;into a bcd value in al.  ah destroyed.

	push	cx

	aam				; M048
	mov	cl, 4			; M048
	shl	ah, cl			; M048
	or	al, ah			; M048

;M048	xor	ah,ah
;M048	mov	cl,10
;M048	div	cl		;al - high digit for bcd, ah - low digit for bcd
;M048	mov	cl,4
;M048	shl	al,cl		;mov the high digit to high nibble
;M048	or	al,ah

	pop	cx
	ret
bin_to_bcd	endp

endcmosclockset label byte		; end of cmos clock support routines

bcd_to_bin proc	near
	assume	ds:nothing,es:nothing

	mov	ah, al		; M048
	and	al, 0fh		; M048
	mov	cl, 4		; M048
	shr	ah, cl		; M048
	aad			; M048
	ret

;	  subtract hi nibble * 6

;M048	mov	ah,al
;M048	and	ah,0f0h 	; isolate the high nibble
;M048	shr	ah,1		; get ah=hi nibble*8
;M048	shr	ah,1		; get ah=hi nibble*4
;M048	sub	al,ah		; subtract hi nibble * 4
;M048	shr	ah,1		; get ah=hi nibble*2
;M048	sub	al,ah		; subtract hi nibble * 2
;M048	ret

bcd_to_bin endp

Bios_Code ends
end
