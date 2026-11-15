;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160
	title	mschar - character and clock devices
;
;----------------------------------------------------------------------------
;
; M013 : printer driver recognizes a special return value from MODE's
;	 INT 17 handler and does not do a retry operation. This is used
;	 to break out of tight loops in case mode was installed with the
;	 'R' option. This involves change in MODE also (Tag # M001)
;
; M026 : Putting back the buggy 4.01 code in auxin. (Time out bug)
;
; M044 : Isolating NOPRINTER bits from error before cmp it with NOPRINTER
;
; M059 : Bug #5002. Treat rollover byte as a count instead of a flag, if
;			t_switch is not set.
;
;----------------------------------------------------------------------------
;

	BYTE_SYSINIT equ 1

	.xlist

	include version.inc	; set build flags
	include biosseg.inc	; establish bios segment structure

	include msequ.inc
	include	devsym.inc
	include	bpb.inc
	include	ioctl.inc

break	macro
	endm

	include error.inc
	.list

	include msgroup.inc	; define Bios_Data segment


	extrn	ptrsav:dword

	extrn	bios_flags:word
	extrn	altah:byte
	extrn	keyrd_func:byte
	extrn	keysts_func:byte



; daycnt is the number of days since 1-1-80.
; each time the clock is read it is necessary to check if another day has
; passed.  the rom only returns the day rollover once so if it is missed
; the time will be off by a day.

	extrn	daycnt:word
	extrn	int16_count:word



; close Bios_Data and open Bios_Code segment

	tocode

	extrn	bc_cmderr:near
	extrn	Bios_Data_Word:word
	extrn	bin_to_bcd_near:near,daycnt_to_day_near:near

MODE_CTRLBRK	equ	0ffh		; M013

;************************************************************************
;*									*
;*	device driver dispatch tables					*
;*									*
;*	each table starts with a byte which lists the number of		*
;*	legal functions, followed by that number of words.  Each	*
;*	word represents an offset of a routine in Bios_Code which	*
;*	handles the function.  The functions are terminated with	*
;*	a near return.  If carry is reset, a 'done' code is returned	*
;*	to the caller.  If carry is set, the ah/al registers are	*
;*	returned as abnormal completion status.  Notice that ds		*
;*	is assumed to point to the Bios_Data segment throughout.	*
;*									*
;************************************************************************

	public	con_table
con_table:
	db	(((offset con_table_end) - (offset con_table) - 1)/2)
	dw	bc_exvec	; 00 init
	dw	bc_exvec	; 01
	dw	bc_exvec	; 02
	dw	bc_cmderr	; 03
	dw	con_read	; 04
	dw	con_rdnd	; 05
	dw	bc_exvec	; 06
	dw	con_flush	; 07
	dw	con_writ	; 08
	dw	con_writ	; 09
	dw	bc_exvec	; 0a
con_table_end:

	public	prn_table
prn_table	label	byte
	db	1
	dw	bc_exvec	; 00 init



	public	aux_table
aux_table	label	byte
	db	1
	dw	bc_exvec	; 00 init


	public	tim_table
tim_table	label	byte
	db	(((offset tim_table_end) - (offset tim_table) -1)/2)
	dw	bc_exvec	; 00
	dw	bc_exvec	; 01
	dw	bc_exvec	; 02
	dw	bc_cmderr	; 03
	dw	tim_read	; 04
	dw	z_bus_exit	; 05
	dw	bc_exvec	; 06
	dw	bc_exvec	; 07
	dw	tim_writ	; 08
	dw	tim_writ	; 09
tim_table_end:

	public	xms_table
xms_table:
	db	1
	dw	bc_exvec	; 00 init

;************************************************************************
;*									*
;*	con_read - read cx bytes from keyboard into buffer at es:di	*
;*									*
;************************************************************************

con_read proc	near
	assume	ds:Bios_Data,es:nothing

	jcxz	con_exit

con_loop:
	call	chrin		;get char in al
	stosb			;store char at es:di
	loop	con_loop

con_exit:
	clc
	ret
con_read endp

;************************************************************************
;*									*
;*	chrin - input single char from keyboard into al			*
;*									*
;*	  we are going to issue extended keyboard function, if		*
;*	  supported.  the returning value of the extended keystroke	*
;*	  of the extended keyboard function uses 0e0h in al		*
;*	  instead of 00 as in the conventional keyboard function.	*
;*	  this creates a conflict when the user entered real		*
;*	  greek alpha charater (= 0e0h) to  distinguish the extended	*
;*	  keystroke and the greek alpha.  this case will be handled	*
;*	  in the following manner:					*
;*									*
;*	      ah = 16h							*
;*	      int 16h							*
;*	      if al == 0, then extended code (in ah)			*
;*	      else if al == 0e0h, then					*
;*	      if ah <> 0, then extended code (in ah)			*
;*		else greek_alpha character.				*
;*									*
;*	also, for compatibility reason, if an extended code is		*
;*	  detected, then we are going to change the value in al		*
;*	  from 0e0h to 00h.						*
;*									*
;************************************************************************


chrin	proc	near
	assume	ds:Bios_Data,es:nothing

	mov	ah,keyrd_func		; set by msinit. 0 or 10h
	xor	al,al
	xchg	al,altah		;get character & zero altah

	or	al,al
	jnz	keyret

	int	16h			; do rom bios keyrd function

alt10:
	or	ax,ax			;check for non-key after break
	jz	chrin

	cmp	ax,7200h		;check for ctrl-prtsc
	jnz	alt_ext_chk

	mov	al,16
	jmp	short keyret

alt_ext_chk:

;**************************************************************
;  if operation was extended function (i.e. keyrd_func != 0) then
;    if character read was 0e0h then
;      if extended byte was zero (i.e. ah == 0) then
;	 goto keyret
;      else
;	 set al to zero
;	 goto alt_save
;      endif
;    endif
;  endif

	cmp	byte ptr keyrd_func,0
	jz	not_ext
	cmp	al,0e0h
	jnz	not_ext

	or	ah,ah
	jz	keyret
ifdef	DBCS
ifdef   KOREA                           ; Keyl  1990/11/5
        cmp     ah, 0f0h                ; If hangeul code range then
        jb      EngCodeRange1           ; do not modify any value.
        cmp     ah, 0f2h
        jbe     not_ext
EngCodeRange1:
endif	; KOREA
endif	; DBCS
	xor	al,al
	jmp	short alt_save

not_ext:

	or	al,al			;special case?
	jnz	keyret

alt_save:
	mov	altah,ah		;store special key
keyret:
	ret
chrin	endp

;************************************************************************
;*									*
;*	con_rdnd - keyboard non destructive read, no wait		*
;*									*
;*	pc-convertible-type machine: if bit 10 is set by the dos	*
;*	in the status word of the request packet, and there is no	*
;*	character in the input buffer, the driver issues a system	*
;*	wait request to the rom. on return from the rom, it returns	*
;*	a 'char-not-found' to the dos.					*
;*									*
;************************************************************************

con_rdnd proc	near
	assume	ds:Bios_Data,es:nothing

	mov	al,[altah]
	or	al,al
	jnz	rdexit

	mov	ah,keysts_func		; keyboard i/o interrupt - get
	int	16h			;  keystroke status (keysts_func)
	jnz	gotchr

z_bus_exit:
	stc
	mov	ah,3			; indicate busy status
	ret

gotchr:
	or	ax,ax
	jnz	notbrk			;check for null after break

	mov	ah,keyrd_func		; issue keyboard read function
	int	16h
	jmp	con_rdnd		;and get a real status

notbrk:
	cmp	ax,7200h		;check for ctrl-prtsc
	jnz	rd_ext_chk

	mov	al,'P' and 1fh		; return control p
	jmp	short rdexit

rd_ext_chk:
	cmp	keyrd_func,0		; extended keyboard function?
	jz	rdexit			; no. normal exit.

	cmp	al,0e0h 		; extended key value or greek alpha?
	jne	rdexit

ifdef	DBCS
ifdef   KOREA
        cmp     ah, 0f0h                ; If hangeul code range then
        jb      EngCodeRange            ; do not modify any value.
        cmp     ah, 0f2h
        jbe     rdexit                  ; Keyl 90/11/5
EngCodeRange:
endif	; KOREA
endif	; DBCS

	cmp	ah,0			; scan code exist?
	jz	rdexit			; yes. greek alpha char.
	mov	al,0			; no. extended key stroke.
					;  change it for compatibility

rdexit:
	les	bx,[ptrsav]
	assume	es:nothing
	mov	es:[bx].media,al	; *** return keyboard character here

bc_exvec:
	clc				; indicate normal termination
	ret

con_rdnd endp

;************************************************************************
;*									*
;*	con_write - console write routine				*
;*									*
;*	entry:	es:di -> buffer						*
;*		cx    =  count						*
;*									*
;************************************************************************

con_writ proc	near
	assume	ds:Bios_Data,es:nothing

	jcxz	bc_exvec

con_lp:
	mov	al,es:[di]		;get char
	inc	di
	int	chrout			;output char
	loop	con_lp			;repeat until all through

cc_ret:
	clc
	ret
con_writ	endp

;************************************************************************
;*									*
;*	con_flush - flush out keyboard queue				*
;*									*
;************************************************************************

	public	con_flush	; called from msbio2.asm for floppy swapping
con_flush proc	near
	assume	ds:Bios_Data,es:nothing


	mov	[altah],0		;clear out holding buffer

;	while (charavail()) charread();

flloop:
	mov	ah,1			; command code for check status
	int	16h			; call rom-bios keyboard routine
	jz	cc_ret			; return carry clear if none

	xor	ah,ah			; if zf is nof set, get character
	int	16h			; call rom-bios to get character
	jmp	flloop

con_flush endp

;----------------------------------------------------------------
;								:
;		    clock device driver 			:
;								:
;								:
;   this file contains the clock device driver. 		:
;								:
;   the routines in this files are:				:
;								:
;	routine 		function			:
;	------- 		--------			:
;	tim_writ		set the current time		:
;	tim_read		read the current time		:
;	time_to_ticks		convert time to corresponding	:
;				  number of clock ticks 	:
;								:
; the clock ticks at the rate of:				:
;								:
;	1193180/65536 ticks/second (about 18.2 ticks per second):
; see each routine for information on the use.			:
;								:
;----------------------------------------------------------------





;--------------------------------------------------------------------
;
; tim_writ sets the current time
;
; on entry es:[di] has the current time:
;
;	number of days since 1-1-80	(word)
;	minutes (0-59)			(byte)
;	hours (0-23)			(byte)
;	hundredths of seconds (0-99)	(byte)
;	seconds (0-59)			(byte)
;
; each number has been checked for the correct range.
;

IFDEF	POWER		; Power management driver has it's own version of
			; this routine. ;M074

	extrn	tim_writ:near

ELSE

;	NOTE:  Any changes in this routine probably require corresponding
;	changes in the version that is built with the power manager driver.
;	See ptime.asm.

tim_writ proc	near
	assume	ds:Bios_Data
	mov	ax,word ptr es:[di]
	push	ax			; save day count
	cmp	cx,6
	jb	tw_bad_time
	mov	al,es:[di+3]
	cmp	al,24
	jae	tw_bad_time
	call	bin_to_bcd_near
	mov	ch,al
	mov	al,es:[di+2]
	cmp	al,60
	jae	tw_bad_time
	call	bin_to_bcd_near
	mov	cl,al
	mov	al,es:[di+5]
	cmp	al,60
	jae	tw_bad_time
	call	bin_to_bcd_near
	mov	dh,al
	mov	dl,0
	cli
	mov	ah,03h
	int	1ah
	sti
	mov	cx,word ptr es:[di+2]
	mov	dx,word ptr es:[di+4]
	call	time_to_ticks
	cli
	mov	ah,1
	int	1ah
	pop	[daycnt]
	sti
	call	daycnt_to_day_near
	cli
	mov	ah,05h
	int	1ah
	sti
	jmp	short tw_done
tw_bad_time:
	pop	ax
tw_done:
	clc
	ret
tim_writ endp

; convert time to ticks
; input : time in cx and dx
; ticks returned in cx:dx

	public	time_to_ticks
time_to_ticks proc near

; first convert from hour,min,sec,hund. to
; total number of 100th of seconds

	mov	al,60
	mul	ch		;hours to minutes
	mov	ch,0
	add	ax,cx		;total minutes
	mov	cx,6000 	;60*100
	mov	bx,dx		;get out of the way of the multiply
	mul	cx		;convert to 1/100 sec
	mov	cx,ax
	mov	al,100
	mul	bh		;convert seconds to 1/100 sec
	add	cx,ax		;combine seconds with hours and min.
	adc	dx,0		;ripple carry
	mov	bh,0
	add	cx,bx		;combine 1/100 sec
	adc	dx,0

;	dx:cx is time in 1/100 sec

	xchg	ax,dx
	xchg	ax,cx		;now time is in cx:ax
	mov	bx,59659
	mul	bx		;multiply low half
	xchg	dx,cx
	xchg	ax,dx		;cx->ax, ax->dx, dx->cx
	mul	bx		;multiply high half
	add	ax,cx		;combine overlapping products
	adc	dx,0
	xchg	ax,dx		;ax:dx=time*59659
	mov	bx,5
	div	bl		;divide high half by 5
	mov	cl,al
	mov	ch,0
	mov	al,ah		;remainder of divide-by-5
	cbw
	xchg	ax,dx		;use it to extend low half
	div	bx		;divde low half by 5
	mov	dx,ax
				; cx:dx is now number of ticks in time
	ret
time_to_ticks endp

ENDIF	; POWER

;
; gettime reads date and time
; and returns the following information:

;	es:[di]  =count of days since 1-1-80
;	es:[di+2]=hours
;	es:[di+3]=minutes
;	es:[di+4]=seconds
;	es:[di+5]=hundredths of seconds

IFDEF	POWER		; Power management driver has it's own version of
			; this routine. ;M074

	extrn	tim_read:near

ELSE

;	NOTE:  Any changes in this routine probably require corresponding
;	changes in the version that is built with the power manager driver.
;	See ptime.asm.

	extrn	bcd_to_bin:near
rtc_sync_reads	db	0ffh
rtc_sync:
	call	int6c_update	; refresh the BIOS ticks from the RTC
	dec	cs:rtc_sync_reads
	jmp	short tim_read_ticks
tim_read proc	near
	inc	int16_count
	cmp	cs:rtc_sync_reads,0
	jnz	rtc_sync
tim_read_ticks:
	call	GetTickCnt	; M059 does INT 1A with ah=0 & updates daycnt

; we now need to convert the time in tick to the time in 100th of
; seconds.  the relation between tick and seconds is:
;
;		 65536 seconds
;	       ----------------
;		1,193,180 tick
;
; to get to 100th of second we need to multiply by 100. the equation is:
;
;	ticks from clock  * 65536 * 100
;      ---------------------------------  = time in 100th of seconds
;		1,193,180
;
; fortunately this fromula simplifies to:
;
;	ticks from clock * 5 * 65,536
;      --------------------------------- = time in 100th of seconds
;		59,659
;
; the calculation is done by first multipling tick by 5. next we divide by
; 59,659.  in this division we multiply by 65,536 by shifting the dividend
; my 16 bits to the left.
;
; start with ticks in cx:dx
; multiply by 5

	mov	ax,cx
	mov	bx,dx
	shl	dx,1
	rcl	cx,1		;times 2
	shl	dx,1
	rcl	cx,1		;times 4
	add	dx,bx
	adc	ax,cx		;times 5
	xchg	ax,dx		
	

; now have ticks * 5 in dx:ax
; we now need to multiply by 65,536 and divide by 59659 d.

	mov	cx,59659	; get divisor
	div	cx
				; dx now has remainder
				; ax has high word of final quotient
	mov	bx,ax		; put high work if safe place
	xor	ax,ax		; this is the multiply by 65536
	div	cx		; bx:ax now has time in 100th of seconds


;rounding based on the remainder may be added here
;the result in bx:ax is time in 1/100 second.

	mov	dx,bx
	mov	cx,200		;extract 1/100's

;division by 200 is necessary to ensure no overflow--max result
;is number of seconds in a day/2 = 43200.

	div	cx
	cmp	dl,100		;remainder over 100?
	jb	noadj
	sub	dl,100		;keep 1/100's less than 100
noadj:
	cmc			;if we subtracted 100, carry is now set
	mov	bl,dl		;save 1/100's

;to compensate for dividing by 200 instead of 100, we now multiply
;by two, shifting a one in if the remainder had exceeded 100.

	rcl	ax,1
	mov	dl,0
	rcl	dx,1
	mov	cx,60		;divide out seconds
	div	cx
	mov	bh,dl		;save the seconds
	div	cl		;break into hours and minutes
	xchg	al,ah

;time is now in ax:bx (hours, minutes, seconds, 1/100 sec)

	push	ax
	mov	ax,[daycnt]	; daycnt
	stosw
	pop	ax
	stosw
	mov	ax,bx
	stosw
	clc
	ret

tim_read endp

ENDIF	; POWER

; M059 - BEGIN
;
;----------------------------------------------------------------------------
;
; procedure : GetTickCnt
;
;		Returns the tick count in CX:DX. Takes care of DayCnt in case
;		of rollover.
;		Uses the following logic for updating Daycnt
;
;		if ( rollover ) {
;			if ( bios_flags & 80h )
;				daycnt++ ;
;			else
;				daycnt += rollover ;
;		}
;
;		For a rollover flag, refresh from the real-time clock.
;
; USES : AX
;
; RETURNS : CX:DX - tick count
; MODIFIES : daycnt
;
;----------------------------------------------------------------------------
;
	public	GetTickCnt

GetTickCnt	proc
	push	ds
	mov	ds,cs:Bios_Data_Word
	sub	ah,ah
	int	1ah
	test	byte ptr bios_flags,80h
	jnz	clock_flag_rollover
	xor	ah,ah
	add	daycnt,ax
	jmp	short clock_rollover_done
clock_flag_rollover:
	or	al,al
	jz	clock_rollover_done
	inc	daycnt
	call	int6c_update
clock_rollover_done:
	pop	ds
	ret
GetTickCnt	endp

; M059 - END

;	Refresh the BIOS tick count from the real-time clock.
;
	extrn	int6c_update:near


Bios_Code	ends
	end



