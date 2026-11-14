;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160
	title	msdisk - bios
;
;----------------------------------------------------------------------------
;
; M033 : BIOS was setting the EOT in DPT to its desired value and then
;	 wrongly resetting it to 9 after it job. Now it saves the EOT
;	 before setting & resets it to the old value.
;
; M039 : Do not count error 6 in retry count while reading from floppy.
;
; M052 : Resolved the confusion of media byte F9. BIOS used to default to 1.2M
;	 drive if formfactor was != ffsmall & mediabyte = f9.
;
; M00x : Setting 'lstdrv' properly at Setown ioctl call. Earlier it used
;		to set lstdrv to -1 on a setown call which got qbasic confused
;		Now the lstdrv update is done inside checksingle
;
; M059 : Bug #5002. Treat rollover byte as a count instead of a flag, if
;			t_switch is not set.
;
;----------------------------------------------------------------------------
;
	BYTE_SYSINIT equ 1

	include version.inc	; set build flags
	include biosseg.inc	; define bios segment structure
	
	include msequ.inc
	include msdskpr.inc
	include	bpb.inc
	include	bootform.inc
	include	msbds.inc

	include msgroup.inc	; define Bios_Data segment

	include dossym.inc

;	Most of the disk routines keep es:[di] set up pointing to the
;	  currently selected bds.  This is often assumed to be the standard
;	  operating environment and in some cases may not be mentioned in
;	  the subroutine headers where it will be assumed.


;data

	extrn	ptrsav:dword
	extrn	bios_flags:word
	extrn	daycnt:word
	extrn	auxnum:word
	extrn	disksector_ptr:dword
	extrn	start_bds:dword
	extrn	prevoper:word
	extrn	orig13:dword
	extrn	number_of_sec:byte
	extrn	model_byte:byte
	extrn	secondary_model_byte:byte

;	the following is in msdioctl.asm

	extrn	media_set_for_format:byte


	extrn	ec35_flag:byte
	extrn	xfer_seg:word

;-----------------------------------------------------------------
;	disk interface routines
;
; device attribute bits:
;	bit 6 - get/set map for logical drives and generic ioctl.
;

maxerr		=	5
MAX_HD_FMT_ERR	=	2

lstdrv	=	504h

; some floppies do not have changeline.  as a result, media-check would
; normally return i-don't-know, the dos would continually reread the fat, and
; discard cached data.	we optimize this by implementing a logical door-
; latch:  it is physically impossible to change a disk in under 2 seconds.  we
; retain the time of the last successful disk operation and compare it with
; the current time during media-check.	if < 2 seconds and at least 1 timer
; tick has passed, the we say no change.  if > 2 seconds then we say i-
; don't-know.  finally, since we cannot trust the timer to be always
; available, we record the number of media checks that have occurred when no
; apparent time has elapsed.  while this number is < a given threshold, we say
; no change.  when it exceeds that threshold, we say i-don't-know and reset
; the counter to 0.  when we store the time of last successful access, if we
; see that time has passed too, we reset the counter.
;
accessmax	=	5
;
; due to various bogosities, we need to continually adjust what the head
; settle time is.  the following algorithm is used:
;
;   get the current head settle value.
;   if it is 0, then
;	set slow = 15
;   else
;	set slow = value
;   ...
;*********************************************
;************ old algorithm ******************
;*   if we are seeking and writing then
;*	 use slow
;*   else
;*	 use fast
;*********************************************
;*********** ibm's requested logic ***********
;   if we are seeking and writing and not on an at then
;	use slow
;   else
;	use fast
;   ...
;   restore current head settle value
;
;
;---------------------------------------
multrk_on	equ	10000000b	;user spcified mutitrack=on, or system turns
					; it on after handling config.sys file as a
					; default value, if multrk_flag = multrk_off1.
multrk_off1	equ	00000000b	;initial value. no "multitrack=" command entered.
multrk_off2	equ	00000001b	;user specified multitrack=off.


; close data segment, open Bios_Code segment

	extrn	drvmax:byte
	extrn	dskdrvs:word

	tocode

	public	step_drv,accesscount,tim_drv,medbyt,wrtverify,rflag,seccnt
	public	motorstartup,settlecurrent,settleslow,save_head_sttl,save_eot,eot,dpt
	public	cursec,curhd,curtrk,spsav,temp_h,start_sec_h,saved_word
	public	vretry_cnt,soft_ecc_cnt,set_id_flag,fat_12_id,fat_16_id,vol_no_name,sm92
	public	errin
	public	lsterr
step_drv	db	-2
accesscount	db	0
tim_drv		db	-1
medbyt		db	?
wrtverify	label	word
rflag		db	romread 	;2 for read, 3 for write
verify		db	0
seccnt		dw	0
motorstartup	db	?
settlecurrent	db	?
settleslow	db	?
save_head_sttl	db	?
save_eot	db	?
eot		db	9
dpt		dd	?
cursec		db	0
curhd		db	0
curtrk		dw	0
spsav		dw	0
temp_h		dw	0
start_sec_h	dw	0
saved_word	dw	0
vretry_cnt	dw	0
soft_ecc_cnt	dw	0
set_id_flag	db	0
fat_12_id	db	"FAT12   ",0
fat_16_id	db	"FAT16   ",0
vol_no_name	db	"NO NAME    ",0
sm92		db	3,9,70h
		dw	2*9*80
		db	2,2
errin	db	0cch			; write fault error
	db	80h			;no response
	db	40h			;seek failure
	db	10h			;bad crc
	db	8			;dma overrun
	db	6			; media change
	db	4			;sector not found
	db	3			;write attempt to write-protect disk
lsterr	db	0			;all other errors

;	returned error codes corresponding to above

	public errout
errout	db	10			; write fault error
	db	2			;no response
	db	6			;seek failure
	db	4			;bad crc
	db	4			;dma overrun
	db	15			; invalid media change
	db	8			;sector not found
	db	0			;write attempt on write-protect disk
	db	12			;general error
	public numerr
numerr	=	errout-errin

;--------------------------------------------------------------
;
;	command jump table
;
	extrn	bc_cmderr:near
	extrn	bc_err_cnt:near

	extrn	Bios_Data_Word:word

	extrn	config_init_segment:word
	extrn	do_generic_ioctl:near
	extrn	ioctl_getown:near
	extrn	ioctl_setown:near

	extrn	mediacheck:near
	extrn	haschange:near
	extrn	media_set_vid:near
	extrn	hidensity:near
	extrn	checklatchio:near
	extrn	checkio:near
	extrn	set_volume_id:near
	extrn	swpdsk:near
	extrn	resetchanged:near
	extrn	resetdisk:near
	extrn	ioctl_support_query:near
	extrn	GetTickCnt:near		; M059

	PUBLIC	Has1,Has720K		; M052

	public	dsktbl
dsktbl	label	byte
	db	((dtbl_siz-1)/2)	; this is the size of the table
	dw	dsk_init
	dw	media_chk
	dw	get_bpb
	dw	bc_cmderr
	dw	dsk_read
	dw	x_bus_exit
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	dsk_writ
	dw	dsk_writv
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	bc_cmderr

	dw	dsk_open
	dw	dsk_close
	dw	dsk_rem
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	do_generic_ioctl
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	ret_carry_clear
	dw	ioctl_getown
	dw	ioctl_setown
	dw	ioctl_support_query
dtbl_siz	=	(offset $)-(offset dsktbl)


	public	dsk_init
dsk_init proc	near
	assume	ds:Bios_Data,es:nothing

	mov	ah,byte ptr drvmax
	mov	es,cs:config_init_segment
	mov	di,offset SysInitSeg:dskdrvs
	jmp	setptrsav
dsk_init endp

; ==========================================================================
; setdrive scans through the data structure of bdss, and returns a pointer to
; the one that belongs to the drive specified. carry is set if none eists for
; the drive.  Pointer is returned in es:[di]
;
;  AL contains the logical drive number.
;
; ==========================================================================

	PUBLIC	SetDrive
SetDrive PROC NEAR
	ASSUME	DS:Bios_Data, ES:NOTHING

	les	di,[start_bds]		; Point es:di to first bds

X_Scan_Loop:
	cmp	es:[di].bds_drivelet,al
	je	X_SetDrv

	les	DI,ES:[DI].bds_link	; Go to next bds
	cmp	DI,-1
	jnz	X_Scan_Loop

	stc

X_SetDrv:
	ret

SetDrive endp


; ==========================================================================
; if id is f9, have a 96tpi disk else
; if bit 2 is 0 then media is not removable and could not have changed
;  otherwise if within 2 secs of last disk operation media could not
;    have changed, otherwise dont know if media has changed
;
; ==========================================================================

Media_Chk PROC	NEAR
	ASSUME	DS:Bios_Data

	call	SetDrive

		; For non-removable disks only return changed if changed by
		; format, otherwise return 'not changed'.

	mov	SI,1					; assume no change
	TESTB	ES:[DI].BDS_Flags,fCHANGED_BY_FORMAT
	jz	WeAreNotFakingIt

	and	ES:[DI].BDS_Flags,NOT fCHANGED_BY_FORMAT ; reset flag

		; If media has been changed by format, we must ask the ROM.
		; Cannot rely on the 2 second time check.

	mov	cs:[Tim_Drv],-1		; Ensure that we ask the rom if media
					; has changed
	TESTB	ES:[DI].BDS_Flags,fNON_REMOVABLE
	jz	WeHaveaFloppy

	mov	SI,-1			; Indicate media changed
	jmp	SHORT Media_Done

		; We need to return 'not changed' if we have a hard file.

WeAreNotFakingIt:
	TESTB	ES:[DI].BDS_Flags,fNON_REMOVABLE
	jnz	Media_Done

wehaveafloppy:
	xor	SI,SI			; Presume "I don't know"

		; If we have a floppy with changeline support, we ask the ROM
		; to determine if media has changed. We do not perform the
		; 2 second check for these drives.

	test	byte ptr bios_flags,2
	jz	mChk_NoChangeLine	; Brif not

	call	MediaCheck		; Call into removable routine
	jc	Err_Exitj		;

	call	HasChange		;
	jnz	Media_Done		;

mChk_NoChangeLine:

		; If we come here, we have a floppy with no changeline support

	mov	SI,1			; Presume no change
	mov	AL,cs:[Tim_Drv]		; Last drive accessed
	cmp	AL,ES:[DI].BDS_DriveNum ; Is drive of last access the same?
	jnz	Media_Unk		; No, then "i don't know"

		; Check to see if this drv has been accessed in last 2 seconds.

	call	Check_Time_Of_Access	; Sets si correctly
	jmp	SHORT Media_Done

Media_Unk:
	dec	SI			; Return "I don't know"

		; SI now contains the correct value for media change.
		; Clean up the left overs

Media_Done:
	push	ES			; Save bds
	les	BX,[PtrSav]		; Get original packet

	ASSUME	ES:NOTHING

	mov	WORD PTR ES:[BX].Trans,SI
	pop	ES			; Restore bds
	or	SI,SI
	jns	VolIdOk

	test	byte ptr bios_flags,2
	jz	mChk1_NoChangeLine	; Brif no changeline support

	call	Media_Set_vId		; We no longer care about bds pointer

mChk1_NoChangeLine:
	mov	cs:[tim_drv],-1		; Make sure we ask rom for media check

volidok:
ret_carry_clear:
	clc
	ret

err_exitj:
	call	maperror		; guaranteed to set carry
ret81:
	mov	ah,81h			; return error status
	ret				; return with carry set
media_chk	endp


; ==========================================================================
; perform a check on the time passed since the last access for this physicel
; drive.
; we are accessing the same drive.  if the time of last successful access was
; less than 2 seconds ago, then we may presume that the disk was not changed.
; returns in si:
;	0 - if time of last access was >= 2 seconds
;	1 - if time was < 2 seconds (i.e no media change assumed)
; registers affected ax,cx,dx, flags.
;
;	assume es:di -> bds, ds->Bios_Data
; ==========================================================================

	PUBLIC	Check_Time_Of_Access
Check_Time_Of_Access PROC NEAR
	ASSUME	DS:Bios_Data, ES:NOTHING

	mov	si,1			; presume no change.

	call	GetTickCnt		; M059 does INT 1A ah=0 & updates daycnt

					; compute elapsed time
	mov	ax,es:[di].bds_tim_lo	; get stored time
	sub	dx,ax
	mov	ax,es:[di].bds_tim_hi
	sbb	cx,ax
					; cx:dx is the elapsed time
	jnz	timecheck_unk		; cx <> 0 => > 1 hour
	or	dx,dx			; time must pass
	jnz	timepassed		; yes, examine max value

		; no noticeable time has passed. we cannot trust the counter
		; to be always available as there are bogus programs that go
		; and reprogram the thing. we keep a count of the number of
		; media checks that we've seen that do not have any time passing
		; if we exceed a give threshold, we give up on the timer.

	inc	byte ptr cs:accesscount
	cmp	byte ptr cs:accesscount,accessmax
	jb	timecheck_ret		; if count is less than threshold, ok

	dec	byte ptr cs:accesscount	; don't let the count wrap
	jmp	short timecheck_unk	; "i don't know" if media changed

timepassed:				; 18.2 tics per second.
	cmp	dx,18 * 2		; min elapsed time?
	jbe	timecheck_ret		; yes, presume no change

		; everything indicates that we do not know what has happened.

timecheck_unk:
	dec	si			 ; presume i don't know

timecheck_ret:
	ret

Check_Time_Of_Access ENDP

; ==========================================================================

Err_Exitj2:
	jmp Err_Exitj

; ==========================================================================
;
; Build a valid bpb for the disk in the drive.
;
; ==========================================================================

Get_Bpb PROC	NEAR
	ASSUME	DS:Bios_Data, ES:NOTHING


	mov	ah,byte ptr es:[di]	;get fat id byte read by dos
	call	setdrive		; get the correct bds for the drive
	TESTB	es:[di].bds_flags,fnon_removable
	jnz	already_gotbpb		; no need to build for fixed disks

		; let's set the default value for volid,vol_serial,
		; filesys_id in bds table

	call	clear_ids
	mov	cs:[set_id_flag],1		; indicate to set system id in bds
	call	getbp			; build a bpb if necessary.
	jc	ret81			; return ah=81, carry set if error

	cmp	cs:[set_id_flag],2		; already, volume_label set from boot
	mov	cs:[set_id_flag],0		;  record to bds table?
	je	already_gotbpb		;   do not set it again from root dir.
					; otherwise, conventional boot record.
	test	byte ptr bios_flags,2
	jz	already_gotbpb		; brif not

	call	set_volume_id

already_gotbpb:
	add	di,BDS_BPB		; return the bpb from the current bds

get_bpb	endp				; fall into setptrsav, es:di -> result


; ==========================================================================
;SR;
; Setptrsav is also jumped to from dsk_init. In both cases, the
;pointer to be returned is in es:di. We were incorrectly returning ds:di.
;Note that this works in most cases because most pointers are in Bios_Data.
;It fails, for instance, when we install an external drive using driver.sys
;because then the BDS segment is no longer Bios_Data. 
;NB: It is fine to corrupt cx because this is not a return value and anyway
;this returns to Chardev_entry (msbio1.asm) where all registers are 
;restored before returning to the caller.
;
; ==========================================================================

	PUBLIC	SetPtrSav
SetPtrSav	proc	near		; return point for dsk_init
	ASSUME	DS:Bios_Data

	mov	cx,es			;save es
	les	bx,[ptrsav]
	assume	es:nothing
	mov	es:[bx].media,ah
	mov	es:[bx].count,di
	mov	es:[bx].count+2,cx
	clc
	ret

setptrsav endp

; ==========================================================================
; clear ids in bds table. only applied for floppies.
;input:  es:di -> bds table
;	assumes ds: -> Bios_Data
;output: volid set to "NO NAME    "
;	 vol_serial set to 0.
;	 filesys_id set to "FAT12   " or "FAT16   "
;	   depending on the flag fatsize in bds.
;
;	trashes si, cx
; ==========================================================================

	public	clear_ids
clear_ids	proc near
	assume	ds:Bios_Data,es:nothing
	push	di

	xor	cx,cx				; no serial number
	mov	word ptr es:[di].bds_vol_serial,cx
	mov	word ptr es:[di].bds_vol_serial+2,cx

		; BUGBUG - there's a lot in common here and with
		; mov_media_ids.. see if we can save some space by
		; merging them... jgl

	mov	cx,size EXT_BOOT_VOL_LABEL	; =11
	mov	si,offset vol_no_name
	add	di,bds_volid			; points to volid field
	rep	movsb

	TESTB	es:[di].bds_fatsiz,fbig
	mov	si,offset fat_16_id		; big fat
	jnz	ci_bigfat			; small fat
	mov	si,offset fat_12_id

ci_bigfat:
	mov	cx,size EXT_SYSTEM_ID		; =8
	add	di,bds_filesys_id-bds_volid-size EXT_BOOT_VOL_LABEL ; filesys_id field
	rep	movsb
	pop	di				; restore bds pointer
	ret

clear_ids	endp


; ==========================================================================
;	getbp - return bpb from the drive specified by the bds.
;	    if the return_fake_bpb flag is set, then it does nothing.
;	    note that we never come here for fixed disks.
;	    for all other cases,
;	      - it reads boot sector to pull out the bpb
;	      - if no valid bpb is found, it then reads the fat sector,
;		to get the fat id byte to build the bpb from there.
;
;   inputs:	es:di point to correct bds.
;
;   outputs:	fills in bpb in current bds if valid bpb or fat id on disk.
;		carry set, and al=7 if invalid disk.
;		carry set and error code in al if other error.
;		if failed to recognize the boot record, then will set the
;		set_id_flag to 0.
;		this routine will only work for a floppy diskette.
;		     for a fixed disk, it will just return.
;
;	****** Note:  getbp is a clone of getbp which uses the newer
;	  segment definitions.  It should be migrated towards.
;	   now es:di has the bds, ds: has Bios_Data
; ==========================================================================

	PUBLIC GetBP
GetBp	PROC	NEAR
	ASSUME	DS:Bios_Data, ES:NOTHING

		; if returning fake bpb then return bpb as is.

	TESTB	es:[di].bds_flags,<return_fake_bpb or fnon_removable>
	jz	getbp1
	jmp	getret_exit

getbp1:
	push	cx
	push	dx
	push	bx

		;
		; attempt to read in boot sector and determine bpb.
		; we assume that the 2.x and greater dos disks all have a valid boot sector.

	call	readbootsec
	jc	getbp_err_ret_brdg	; carry set if there was error.

	or	cx,cx			; cx is 0 if boot sector is valid.
	jnz	dofatbpb

	call	movbpb			; move bpb into registers.
	jmp	short has1

getbp_err_ret_brdg:
	jmp getbp_err_ret

		; we have a 1.x diskette. In this case read in the fat ID byte
		; and fill in bpb from there.

dofatbpb:
	call	readfat 		; puts media descriptor byte in ah
	jc	getbp_err_ret_brdg

	test	byte ptr bios_flags,2
	jz	bpb_nochangeline	; brif not

	call	hidensity		; may not return!  May add sp,2 and
					; jump to has1!!!!!! or has720K
bpb_nochangeline:
					; test for a valid 3.5" medium
	cmp	es:[di].bds_formfactor,ffsmall
	jnz	is_floppy
	cmp	ah,0f9h 		; is it a valid fat id byte for 3.5" ?
	jnz	got_unknown_medium
Has720K:				; M052
	mov	bx,offset sm92		; pointer to correct bpb

		; es points to segment of bds. the following should be modified
		; to get spf,csec,spau,spt correctly. it had been wrong if
		; driver.sys is loaded since the bds is inside the driver.sys.

	mov	al,cs:[bx.spf]
	mov	cx,cs:[bx.csec]
	mov	dx,word ptr cs:[bx.spau]
	mov	bx,word ptr cs:[bx.spt]
	jmp	short has1

is_floppy:				; must be a 5.25" floppy if we come here
	cmp	ah,0f8h			; valid media??  (0f8h-0ffh)
	jb	got_unknown_medium

	mov	al,1			;set number of fat sectors
	mov	bx,64*256+8		;set dir entries and sector max
	mov	cx,40*8 		;set size of drive
	mov	dx,01*256+1		;set head limit and sec/all unit
	test	ah,00000010b		;test for 8 or 9 sector
	jnz	has8			;nz = has 8 sectors

	inc	al			;inc number of fat sectors
	inc	bl			;inc sector max
	add	cx,40			;increase size

has8:
	test	ah,00000001b		;test for 1 or 2 heads
	jz	has1			;z = 1 head

	add	cx,cx			;double size of disk
	mov	bh,112			;increase number of directory entries
	inc	dh			;inc sec/all unit
	inc	dl			;inc head limit

Has1	LABEL	NEAR
	ASSUME	DS:Bios_Data, ES:NOTHING

	mov	es:[di].BDS_BPB.BPB_SECTORSPERCLUSTER,dh
	mov	byte ptr es:[di].BDS_BPB.BPB_ROOTENTRIES,bh
	mov	es:[di].BDS_BPB.BPB_TOTALSECTORS,cx
	mov	es:[di].BDS_BPB.BPB_MEDIADESCRIPTOR,ah
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERFAT,al
	mov	byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK,bl
	mov	byte ptr es:[di].BDS_BPB.BPB_HEADS,dl

		; the BDS_BPB.BPB_HIDDENSECTORS+2 field and the
		; BDS_BPB.BPB_BIGTOTALSECTORS field need to be set
		; to 0 since this code is for floppies

	mov	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2,0
	mov	word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS,0
	mov	word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2,0

getret:
	pop	bx
	pop	dx
	pop	cx

getret_exit:
	ret

getbp_err_ret:
		; before doing anything else, set set_id_flag to 0.
	mov	cs:set_id_flag,0
	call	maperror
	jmp	short getret

		; we have a 3.5" diskette for which we cannot build a bpb.
		; we do not assume any type of bpb for this medium.

got_unknown_medium:
	mov	cs:set_id_flag,0
	mov	al,error_unknown_media
	stc
	jmp	short getret

getbp	endp

; ==========================================================================

bpbtype struc
spf	db	?
spt	db	?
cdire	db	?
csec	dw	?
spau	db	?
chead	db	?
bpbtype ends


; ==========================================================================
; read in the boot sector. set carry if error in reading sector.
; cx is set to 1 if the boot sector is invalid, otherwise it is 0.
;
;	assumes es:di -> bds, ds-> Bios_Data
; ==========================================================================

readbootsec proc near
	assume	ds:Bios_Data,es:nothing
	push	ds
	mov	dh,0
	mov	cx,0001
	call	read_sector
	jc	boot_read_done
	sub	cx,cx			; assume valid boot sector
	cmp	byte ptr [bx],069h
	je	boot_check_media
	cmp	byte ptr [bx],0e9h
	je	boot_check_media
	cmp	byte ptr [bx],0ebh
	jne	boot_invalid
	cmp	byte ptr [bx+2],090h
	jne	boot_invalid
boot_check_media:
	mov	al,[bx].EXT_BOOT_BPB.BPB_MEDIADESCRIPTOR
	and	al,0f0h
	cmp	al,0f0h
	jnz	boot_invalid
	and	byte ptr es:[di].bds_flags+1,0f7h
	cmp	word ptr [bx+3],534dh
	jne	boot_check_sides
	cmp	word ptr [bx+5],4d44h
	jne	boot_check_sides
	cmp	word ptr [bx+7],3346h
	jne	boot_check_sides
	or	byte ptr es:[di].bds_flags+1,08h
boot_check_sides:
	mov	al,[bx].EXT_BOOT_BPB.BPB_MEDIADESCRIPTOR
	cmp	al,0f0h
	je	boot_valid
	test	al,1
	jnz	boot_valid
	cmp	word ptr [bx+8],'.' shl 8 + '3'
	jnz	boot_earlier
	cmp	byte ptr [bx+10],'2'
	jae	boot_valid
boot_earlier:
	mov	[bx].EXT_BOOT_BPB.BPB_SECTORSPERCLUSTER,1
	jmp	short boot_valid
boot_invalid:
	inc	cx			; indicate invalid boot sector
boot_valid:
	clc
boot_read_done:
	pop	ds
	ret
readbootsec endp

; moves the bpb read from the boot sector into registers for use by
; getbp routine at has1
;
; if the set_id_flag is 1, and if an extended boot record, then set volume
; serial number, volume label, file system id in bds according to
; the boot record.  after that, this routine will set the set_id_flag to 2
; to signal that volume label is set already from the extended boot record
; (so, don't set it again by calling "set_volume_id" routine which uses
; the volume label in the root directory.)

movbpb	proc	near
	assume	ds:Bios_Data,es:nothing
	push	si
	push	ds
	lds	si,disksector_ptr
	assume	ds:nothing
	mov	dh,byte ptr [si].EXT_BOOT_BPB.BPB_SECTORSPERCLUSTER
	mov	bh,byte ptr [si].EXT_BOOT_BPB.BPB_ROOTENTRIES
	mov	cx,word ptr [si].EXT_BOOT_BPB.BPB_TOTALSECTORS
	mov	ah,byte ptr [si].EXT_BOOT_BPB.BPB_MEDIADESCRIPTOR
	mov	al,byte ptr [si].EXT_BOOT_BPB.BPB_SECTORSPERFAT
	mov	bl,byte ptr [si].EXT_BOOT_BPB.BPB_SECTORSPERTRACK
	mov	dl,byte ptr [si].EXT_BOOT_BPB.BPB_HEADS
	cmp	cs:[set_id_flag],1
	jne	mbpb_done
	xchg	bx,si
	call	mov_media_ids
	xchg	bx,si
	jc	mbpb_conventional
	mov	cs:[set_id_flag],2
mbpb_conventional:
	pop	ds
	push	ds
	assume	ds:Bios_Data
	test	byte ptr bios_flags,2
	jz	mbpb_done
	call	resetchanged
mbpb_done:
	pop	ds
	pop	si
	clc
	ret
movbpb	endp


; copy the serial number, volume label and file system id from the
; extended boot record at ds:bx to the bds at es:di.
;
; carry is set if this is not an extended boot record.
; all registers are preserved.

	public	mov_media_ids
mov_media_ids	proc	near
	assume	ds:nothing,es:nothing
	cmp	[bx].EXT_BOOT_SIG,ext_boot_signature
	jne	mmi7_not_ext
	push	cx
	mov	cx,word ptr [bx].EXT_BOOT_SERIAL
	mov	word ptr es:[di].bds_vol_serial,cx
	mov	cx,word ptr [bx].EXT_BOOT_SERIAL+2
	mov	word ptr es:[di].bds_vol_serial+2,cx
	push	di
	push	si
	mov	cx,size EXT_BOOT_VOL_LABEL
	lea	si,[bx].EXT_BOOT_VOL_LABEL
	add	di,bds_volid
	rep	movsb
	mov	cx,size EXT_SYSTEM_ID
	lea	si,[bx].EXT_SYSTEM_ID
	add	di,bds_filesys_id-bds_volid-size EXT_BOOT_VOL_LABEL
	rep	movsb
	pop	si
	pop	di
	pop	cx
	clc
	ret
mmi7_not_ext:
	stc
	ret
mov_media_ids	endp


; read in the fat sector and get the media byte from it.
; input : es:di -> bds
; output:
;	  carry set if an error occurs, ax contains error code.
;	  otherwise, ah contains media byte on exit

readfat proc	near
	assume	ds:Bios_Data,es:nothing
	push	ds
	mov	dh,0			; head 0
	mov	cx,0002 		; cylinder 0, sector 2
	call	read_sector		; ds:bx points to fat sector
	jc	bad_fat_ret
	mov	ah,[bx]			; media byte
bad_fat_ret:
	pop	ds
	ret
readfat endp

; read a single sector into the temp buffer.
; perform three retries in case of error.
;   inputs:	es:[di].bds_drivenum has physical drive to use
;		cx has sector and cylinder
;		dh has head
;		es:di has bds
;		ds has Bios_Data
;
;   outputs:	carry clear
;		    ds:bx points to the buffer addressed by disksector_ptr
;
;		carry set
;		    ax has rom error code
;
; register bp is preserved.

	public read_sector
read_sector proc near
	assume	ds:Bios_Data,es:nothing

	push	bp
	mov	bp,3			; make 3 attempts
	mov	dl,es:[di].bds_drivenum
	lds	bx,disksector_ptr	; ds:bx points to buffer
rd_ret:
	push	es
	push	ds
	pop	es			; dma address = sector buffer
	mov	ax,201h 		; number of sectors to 1 (al=1)
	int	13h			; call rom-bios disk routines
	pop	es			; restore bds pointer
	jnc	okret2

rd_rty:
	call	again			; reset disk, decrement bp, preserve ax
	jz	err_rd_ret

	TESTB	es:[di].bds_flags,fnon_removable
	jnz	rd_ret

	cmp	cs:[media_set_for_format],0
	jne	rd_skip1_dpt

	push	ax
	push	ds		; for retry, set the head settle time to 0fh

	lds	si,cs:dpt
	assume	ds:nothing
	mov	al,ds:[si].disk_head_sttl
	mov	byte ptr ds:[si].disk_head_sttl,normsettle
	pop	ds
	assume	ds:Bios_Data
	mov	cs:[save_head_sttl],al
	pop	ax
rd_skip1_dpt:
					; set cmd to read (ah=2) and
	push	es
	push	ds			; dma = sector buffer
	pop	es
	mov	ax,201h 		; num of sectors to 1 (al=1)
	int	13h			; call rom-bios disk routines
	pop	es

	pushf
	cmp	cs:[media_set_for_format],0
	jne	rd_skip2_dpt

	push	ax
	mov	al,cs:[save_head_sttl]
	push	ds
	lds	si,cs:dpt
	assume	ds:nothing
	mov	byte ptr ds:[si].disk_head_sttl,al
	pop	ds
	assume	ds:Bios_Data
	pop	ax

rd_skip2_dpt:
	popf
	jnc	okret2
	jmp	rd_rty

err_rd_ret:
	mov	dl,-1		; make sure we ask rom if media has changed
	stc			; return error

; update information pertaining to last drive accessed, time of access, last
; track accessed in that drive.

okret2:
	mov	cs:[step_drv],dl	; set up for head settle logic in disk.
	mov	cs:[tim_drv],dl 	;save drive last accessed
	mov	es:[di].bds_track,ch ; save last track accessed on this drive
	pushf			; preserve flags in case error occurred
	call	set_tim
	popf			; restore flags
	pop	bp
	ret
read_sector endp

;--------------------------------------------------------------------

;	disk open/close routines

	public	dsk_open
dsk_open proc	near
	assume	ds:Bios_Data,es:nothing

	test	byte ptr bios_flags,2
	jz	dsk_open_exit		; done if no changeline support

; al is logical drive

	call	setdrive		;get bds for drive
	inc	es:[di].bds_opcnt
dsk_open_exit:
	clc
	ret

dsk_open	endp

;--------------------------------------------------------------------


	public	dsk_close
dsk_close proc	near
	assume	ds:Bios_Data,es:nothing

	test	byte ptr bios_flags,2
	jz	exitjx

; al is logical drive

	call	setdrive		;get bds for drive
	cmp	es:[di].bds_opcnt,0
	jz	exitjx			; watch out for wrap
	dec	es:[di].bds_opcnt
exitjx:
	clc
	ret

dsk_close endp

;-----------------------------------------------------------
;
;		disk removable routine
;

dsk_rem proc	near
	assume	ds:Bios_Data,es:nothing

; al is unit #

	call	setdrive		; get bds for this drive
	TESTB	es:[di].bds_flags,fnon_removable
	jnz	non_rem
	clc
	ret

non_rem:
x_bus_exit:
	mov	ah,3			; return busy status
	stc
dsk_ret:
	ret
dsk_rem endp

;-----------------------------------------------------------
;
;		disk i/o routines
;

dsk_writv proc	near
	assume	ds:Bios_Data,es:nothing

	mov	cs:[wrtverify],103h
	jmp	short dsk_cl

dsk_writ:
	assume	ds:Bios_Data,es:nothing

	mov	cs:[wrtverify],romwrite

dsk_cl:
	call	diskio
dsk_io:
	jnc	dsk_ret			; normal completion, no carry!
	jmp	bc_err_cnt
dsk_writv endp

dsk_read proc	near
	assume	ds:Bios_Data,es:nothing

	call	diskrd
	jmp	dsk_io
dsk_read endp

; miscellaneous odd jump routines.  moved out of mainline for speed.

; if we have a system where we have virtual drives, we need to prompt the
; user to place the correct disk in the drive.
;
;	assume es:di -> bds, ds:->Bios_Data

checksingle proc near

	public checksingle
	assume	ds:Bios_Data,es:nothing

	push	ax
	push	bx
	mov	bx,es:[di].bds_flags

; if hard drive, cannot change disk.
; if current owner of physical drive, no need to change diskette.

	test	bl,fnon_removable or fi_own_physical
	jnz	singleret
	test	bl,fi_am_mult		 ; is there a drive sharing this
					 ;   physical drive?
	jz	singleret

; look for the previous owner of this physical drive and reset its ownership
; flag.

	mov	al,es:[di].bds_drivenum	; get physical drive number
	push	es			; preserve pointer to current bds
	push	di

	les	di,[start_bds]		; get first bds
scan_list:
	cmp	es:[di].bds_drivenum,al
	jnz	scan_skip		; nope.  Not our drive.  Try next bds.

	mov	bl,fi_own_physical	; test ownership flag
	test	bl,byte ptr es:[di].bds_flags
	jz	scan_skip		; he doesn't own it either.  continue

check_own:
	xor	byte ptr es:[di].bds_flags,bl ; reset ownership flag

	pop	di			; restore pointer to current bds
	pop	es

	or	byte ptr es:[di].bds_flags,bl	; set ownership flag

; we examine the set-owner bit in bios_flags. if set, we are using the code in
; checksingle to just set the owner of a drive. we must not issue the prompt
; in this case.

	test	byte ptr bios_flags,08h
	jz	not_fsetowner

	cmp	es:[di].bds_drivenum, 0		; are we handling drive
						;  number 0 ?
	jne	singleret

	mov	al, es:[di].bds_drivelet	; get the DOs drive letter
	push	ES
	sub	bx,bx
	mov	es,bx
	mov	BYTE PTR ES:[lstdrv],al 	; & set up sdsb
	pop	ES				; restore bds pointer
	jmp	short singleret
;
; M00x - END
;

; to support "backward" compatibility with ibm's "single drive status byte"
; we now check to see if we are in a single drive system and the application
; has "cleverly" diddled the sdsb
not_fsetowner:
	test	byte ptr bios_flags,04h	; single drive system?
	jz	ignore_sdsb

	push	ax
	mov	al,es:[di].bds_drivelet	    ;	  if (curr_drv == req_drv)
	mov	ah,al
	push	es
	sub	bx,bx
	mov	es,bx
	xchg	al,es:byte ptr lstdrv	    ;	     then swap(curr_drv,req_drv)
	pop	es
	db 38h,0c4h	; cmp ah,al (r/m8,r8); else
	pop	ax			    ;		  swap(curr_drv,req_drv)
	je	singleret		    ;		  issue swap_dsk_msg

ignore_sdsb:


	call	swpdsk			    ;  ask user for correct disk
	jmp	short singleret

scan_skip:
	les	di,es:[di].bds_link 		; go to next bds
	cmp	di,-1			; end of list?
	jnz	scan_list		; continue until hit end of list

single_err_ret:
	stc
	pop	di			    ; restore current bds
	pop	es
singleret:
	pop	bx
	pop	ax
	ret

checksingle endp

baddrive:
	mov	al,8			;sector not found
	jmp	short baddrive_ret

unformatteddrive:
	mov	al,7			;unknown media
baddrive_ret:
	stc
ioret:
	ret

;------------------------------------------------------------
;
;	disk i/o handler
;
;	al = drive number (0-6)
;	ah = media descriptor
;	cx = sector count
;	dx = first sector (low)
;	[start_sec_h] = first sector (high)  32 bit calculation.
;	ds = cs
;	es:di = transfer address
;	[rflag]=operation (2=read, 3=write)
;	[verify]=1 for verify after write
;
;	if successful carry flag = 0
;	  else cf=1 and al contains error code


;--------------------------------------------------------------

	public	diskrd
diskrd	proc	near
	assume	ds:Bios_Data,es:nothing


	mov	cs:[rflag],romread

diskrd	endp				; fall into diskio

;--------------------------------------------------------------

	public	diskio
diskio	proc	near
	assume	ds:Bios_Data,es:nothing

	mov	bx,di			; es:bx = transfer address
	mov	cs:xfer_seg,es		; save transfer segment
	call	setdrive		; map logical and physical
	mov	al,es:[di].BDS_BPB.BPB_MEDIADESCRIPTOR
	mov	cs:medbyt,al		; preserve media byte for drive for use
					; in determining media change.
	jcxz	ioret
	test	byte ptr es:[di].bds_flags+1,08h
	jz	diskio_allow
	cmp	es:[di].BDS_BPB.BPB_TOTALSECTORS,0
	jne	diskio_check_start
	cmp	cs:[start_sec_h],0
	jne	diskio_check_write
diskio_check_start:
	or	dx,dx
	jne	diskio_check_write
	cmp	cx,1
	je	diskio_allow
diskio_check_write:
	mov	al,0
	cmp	cs:[rflag],romwrite
	je	baddrive_ret
diskio_allow:

;	see if the media is formatted or not by checking the flags field in
;	in the bds.  if it is unformatted we cannot allow i/o, so we should
;	go to the error exit at label unformatteddrive.

	TESTB	es:[di].bds_flags,unformatted_media
	jnz	unformatteddrive

	mov	cs:[seccnt],cx		;save sector count
	mov	cs:[spsav],sp		; save sp

; ensure that we are trying to access valid sectors on the drive

	mov	ax,dx			; save dx to ax
	xor	si,si
	add	dx,cx
	adc	si,0
	cmp	es:[di].BDS_BPB.BPB_TOTALSECTORS,0 ; > 32 bit sector ?
	je	sanity32

	cmp	si,0
	jne	baddrive
	cmp	dx,es:[di].BDS_BPB.BPB_TOTALSECTORS
	ja	baddrive
	jmp	short sanityok

sanity32:
	add	si,cs:[start_sec_h]
	cmp	si,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS+2
	jb	sanityok
	jbe	@f
	jmp	baddrive
@@:
	cmp	dx,word ptr es:[di].BDS_BPB.BPB_BIGTOTALSECTORS
	jbe	@f
	jmp	baddrive
@@:

sanityok:
	mov	dx,cs:[start_sec_h]
	add	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS
	adc	dx,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2

; now dx;ax have the physical first sector.
;since the following procedures is going to destroy ax, let's
;save it temporarily to saved_word.

	mov	cs:[saved_word],ax		; save the sector number (low)

; set up pointer to disk base table in [dpt]. we cannot assume that iosetup
; will do it because we will skip the set up stuff with hard disks.

	push	es
	sub	ax,ax
	mov	es,ax
	les	si,dword ptr es:[dskadr]; current disk parm table
	mov	word ptr cs:dpt,si
	mov	word ptr cs:dpt+2,es
	pop	es			; restore bds

	TESTB	es:[di].bds_flags,fnon_removable
	jnz	skip_setup

	call	checksingle

; check to see if we have previously noted a change line.  the routine
; returns if everything is ok.	otherwise, it pops off the stack and returns
; the proper error code.

	test	byte ptr bios_flags,2
	jz	diskio_nochangeline	; brif not
	call	checklatchio		; will do a sneaky pop stack return
;					;  if a disk error occurs
diskio_nochangeline:
	call	iosetup		; set up tables and variables for i/o


; now the settle values are correct for the following code

skip_setup:
	call	ext_disk_dispatch

; 32 bit sector calculation.
; dx;[saved_word] = starting sector number.

	mov	ax,dx
	xor	dx,dx
	div	es:[di].BDS_BPB.BPB_SECTORSPERTRACK	;divide by sec per track
	mov	cs:[temp_h],ax
	mov	ax,cs:[saved_word]		; restore the lower word
	div	es:[di].BDS_BPB.BPB_SECTORSPERTRACK

;now, [temp_h],ax = track #, dx = sector

	inc	dl			;sector number is 1 based.
	mov	cs:[cursec],dl		;save current sector
	mov	cx,es:[di].BDS_BPB.BPB_HEADS ;get number of heads

	push	ax
	xor	dx,dx			;divide tracks by heads per cylinder
	mov	ax,cs:[temp_h]
	div	cx
	mov	cs:[temp_h],ax
	pop	ax
	div	cx

;now, [temp_h],ax = cyliner #, dx = head

	cmp	cs:[temp_h],0
	ja	baddrive_brdg
	cmp	ax,1024 		; 2**10 currently maxium for track #.
	jae	baddrive_brdg

	mov	cs:[curhd],dl		;save current head
	mov	cs:[curtrk],ax		;save current track

; we are now set up for the i/o.  normally, we consider the dma boundary
; violations here.  not true.  we perform the operation as if everything is
; symmetric; let the int 13 handler worry about the dma violations.

	mov	ax,cs:[seccnt]
	call	block
	call	done			; cas - call/ret
	ret

baddrive_brdg: jmp baddrive

diskio	endp

;--------------------------------------------------------------

; set the drive-last-accessed flag for diskette only.  we know that the hard
; disk will not be removed.
; es:di -> current bds.
; ds -> Bios_Data
; ax,cx,si are destroyed.

	public	iosetup
iosetup proc	near
	assume	ds:Bios_Data,es:nothing
	mov	al,es:[di].bds_drivenum
	mov	cs:[tim_drv],al
	cmp	cs:[media_set_for_format],0
	jne	iosetup7_done
	mov	al,cs:[eot]
	push	ds
	lds	si,cs:[dpt]
	assume	ds:nothing
	xchg	al,[si].disk_eot
	mov	ah,[si].disk_motor_strt
	mov	cs:save_eot,al
	mov	cs:motorstartup,ah
	cmp	es:[di].bds_formfactor,ffsmall
	jnz	iosetup7_motor_ok
	mov	[si].disk_motor_strt,4
iosetup7_motor_ok:
	mov	al,1
	xchg	al,[si].disk_head_sttl
	pop	ds
	assume	ds:Bios_Data
	mov	cs:settlecurrent,al
	mov	al,normsettle
	mov	cs:settleslow,al
iosetup7_done:
	ret
iosetup	endp

; set time of last access, and reset default values in the dpt.
;
;	  note:  trashes (at least) si

	public	done
done	proc	near
	assume	ds:Bios_Data,es:nothing
	TESTB	es:[di].bds_flags,fnon_removable
	jnz	ddbx			; do not set for non-removable media

	call	set_tim 		; set time of last access for drive
	FALLTHRU DiddleBack

done	endp

; restore head settle and eot values
;
;	note: trashes (at least) si

diddleback proc	near
	assume	ds:Bios_Data,es:nothing	; es:di -> bds
	pushf					;save flag
	cmp	cs:[media_set_for_format],0
	jnz	nodiddleback

	push	ax
	push	es			; save bds pointer
	les	si,cs:dpt

	mov	al, cs:save_eot		; M033
	mov	es:[si].disk_eot, al	; M033

	mov	al,cs:settlecurrent
	mov	ah,cs:motorstartup
	mov	es:[si].disk_head_sttl,al
	mov	es:[si].disk_sector_siz,2
	mov	es:[si].disk_motor_strt,ah
	pop	es			; restore bds pointer
	pop	ax
nodiddleback:
	popf				;restore flag
ddbx:	ret
diddleback endp


;read the number of sectors specified in ax, handling track boundaries
;es:di -> bds for this drive

block	proc	near
	assume	ds:Bios_Data,es:nothing
	or	ax,ax			;see if any sectors to read
	jz	ddbx

;fixed disk will not be restricted to the track-by-track basis.

	TESTB	es:[di].bds_flags,fnon_removable  ;fixed disk?
	jz	block7_floppy_setup

;	check to see if multi track operation is allowed.  if not
;	we have to go to the block_floppy below to break up the operation.

	test	byte ptr bios_flags+1,2
	jz	block_floppy

	call	disk
	xor	ax,ax
	ret

block7_floppy_setup:
	push	ds
	push	si
	lds	si,cs:[dpt]
	assume	ds:nothing
	mov	cl,cs:[cursec]
	add	cl,al
	dec	cx
	cmp	[si].disk_eot,cl
	ja	block7_eot_ok
	mov	[si].disk_eot,cl
block7_eot_ok:
	pop	si
	pop	ds
	assume	ds:Bios_Data
block_floppy:

; read at most 1 track worth.  perform minimization at sector / track

	mov	cl,byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK
	inc	cl
	sub	cl,cs:cursec
	xor	ch,ch
	cmp	ax,cx
	jae	gotmin
	mov	cx,ax
gotmin:
	test	es:[di].bds_flags,0800h
	jz	block7_transfer
	push	ax
	mov	al,cs:[cursec]
	cmp	al,18
	ja	block7_limit_done
	add	al,cl
	cmp	al,19
	jbe	block7_limit_done
	mov	cx,19
	sub	cl,cs:[cursec]
block7_limit_done:
	pop	ax
block7_transfer:

; ax is the requested number of sectors to read
; cx is the number that we can do on this track

	push	ax
	push	cx
	mov	ax,cx			; al is number of sectors to read
	call	disk
	pop	cx
	pop	ax

; cx is the number of sectors just transferred

	sub	ax,cx			; reduce sectors-remaining by last i/o
	shl	cl,1
	add	bh,cl			; adjust transfer address
	jmp	block
block	endp

dskerr_brdg: jmp dskerr


;perform disk i/o with retries
; al = number of sectors (1-8, all on one track)
; es:di point to drive parameters
; xfer_seg:bx = transfer address (must not cross a 64k physical boundary)
; [rflag] = 2 if read, 3 if write
; [verify] = 0 for normal, 1 for verify after write

	public	disk
disk	proc	near
	assume	ds:Bios_Data,es:nothing

					; Check for hard disk format and
					; if TRUE then set max error count
					; to 2

	mov	bp,maxerr		; set up retry count
	mov	ah,cs:rflag
	TESTB	es:[di].bds_flags,fnon_removable ; Is this a fixed disk?
	jz	GetRdWrInd
	cmp	ah,romverify		; Is this a track verify?
	jnz	GetRdWrInd
	mov	BP,MAX_HD_FMT_ERR 	; This is verify so only 1 retry

GetRdWrInd:
	mov	cs:vretry_cnt,bp		;verify op. retry cnt for write-verify.
	mov	cs:soft_ecc_cnt,bp		;soft ecc error retry count.

retry:
	push	ax

	mov	dx,cs:[curtrk]		;load current cylinder

	TESTB	es:[di].bds_flags,fnon_removable ;fixed disk?
	jz	disk_not_mini		;no, skip this.

	cmp	es:[di].bdsm_ismini,1	;is this a mini disk?
	jnz	disk_not_mini		;no. continue to next.
	add	dx,es:[di].bdsm_hidden_trks ;else add hidden trks.
disk_not_mini:
	ror	dh,1
	ror	dh,1

	or	dh,cs:[cursec]
	mov	cx,dx
	xchg	ch,cl			; cl = sector, ch = cylinder
	mov	dh,byte ptr cs:[curhd]	; load current head number and
	mov	dl,es:[di].bds_drivenum	; physical drive number
	cmp	es:[di].bds_formfactor,ffhardfile
	jz	do_fast 		; hard files use fast speed

; if we have [step_drv] set to -1, we use the slow settle time.
; this helps when we have just done a resed disk operation and the head has
; been moved to another cylinder - the problem crops up with 3.5" drives.

	cmp	cs:[step_drv],-1
	jz	do_writej
	cmp	ah,romread
	je	do_fast
	cmp	ah,romverify
	je	do_fast
do_writej:

; reads always fast, unless we have just done a disk reset operation

	jmp	short do_write		; reads always fast

do_fast:
	call	fastspeed		; change settle mode
testerr:
	jc	dskerr_brdg
	cmp	bp,maxerr
	jne	disk7_save_track
	cmp	ah,0bbh
	je	dskerr_brdg

; set drive and track of last access

disk7_save_track:
	mov	cs:[step_drv],dl		;  set drive
	mov	es:[di].bds_track,ch		;  save track
no_set:
	cmp	cs:wrtverify,103h		; check for write and verify
	jz	doverify
noverify:
	pop	ax

;	check the flags word in the bds to see if the drive is non removable
;	if not we needn't do anything special
;	if it is a hard disk then check to see if multi-track operation
;	is specified.  if specified we don't have to calculate for the next
;	track since we are already done.  so we can go to the exit of this
;	routine.

	TESTB	es:[di].bds_flags,fnon_removable
	jz	its_removable

	test	byte ptr bios_flags+1,2
	jnz	disk_ret

its_removable:
	and	cl,03fh 		; eliminate cylinder bits from sector
	xor	ah,ah
	sub	cs:[seccnt],ax		; reduce count of sectors to go
	add	cl,al			; next sector
	mov	cs:[cursec],cl
	cmp	cl,byte ptr es:[di].BDS_BPB.BPB_SECTORSPERTRACK ; see if sector/track limit reached
	jbe	disk_ret
nexttrack:
	mov	cs:[cursec],1		; start with first sector of next track
	mov	dh,cs:[curhd]
	inc	dh
	cmp	dh,byte ptr es:[di].BDS_BPB.BPB_HEADS
	jb	noxor
	xor	dh,dh
	inc	cs:[curtrk]		;next track
noxor:
	mov	cs:[curhd],dh
disk_ret:
	clc
	ret
disk	endp

; the request is for write.  determine if we are talking about the same
; track and drive.  if so, use the fast speed.

do_write proc	near
	assume	ds:Bios_Data,es:nothing
	cmp	dl,cs:[step_drv]
	jnz	do_norm 		;  we have changed drives

	cmp	ch,es:[di].bds_track
	jz	do_fast 		; we are still on the same track

do_norm:
	call	normspeed
	jmp	short testerr		; test for error
do_write endp

; we have a verify request also.  get state info and go verify

doverify proc	near
	assume	ds:Bios_Data,es:nothing
	pop	ax			; restore sector count
	push	ax
	mov	ah,romverify		; request verify
	call	fastspeed		; change settle mode
	jnc	noverify

;	check the error returned in ah to see if it is a soft ecc error.
;	if it is not we needn't do anything special.  if it is a soft
;	ecc error then decrement the soft_ecc_cnt error retry count. if
;	this retry count becomes 0 then we just  ignore the error and go to
;	no_verify but if we can still try then we call the routine to reset
;	the disk and go to dskerr1 to retry the operation.

	cmp	ah,11h			;soft ecc error ?
	jnz	not_softecc_err
	dec	cs:soft_ecc_cnt
	jz	noverify		;no more retry

	call	resetdisk		;reset disk
	jmp	short dskerr1		;retry


not_softecc_err:			;other error.
	call	resetdisk
	dec	cs:vretry_cnt
	jmp	short dskerr0
doverify endp

; need to special case the change-line error ah=06h.  if we get this, we
; need to return it.

dskerr	proc	near
	assume	ds:Bios_Data,es:nothing
	test	byte ptr bios_flags,2
	jz	dskerr_nochangeline	; brif not
	call	checkio 		;|
dskerr_nochangeline:

	test	bios_flags,0800h
	jz	dochkagain

	mov	bp,1			;no more retry.
	and	bios_flags,NOT 0800h

dochkagain:
	call	again
dskerr0:
	jz	harderr

	TESTB	es:[di].bds_flags,fnon_removable
	jnz	skip_timeout_chk

	cmp	ah,80h			;timeout?
	jz	harderr

skip_timeout_chk:
	cmp	ah,0cch 		;write fault error?
	jz	write_fault_err 	; then, don't retry.

	mov	cs:soft_ecc_cnt,maxerr
dskerr1:
	pop	ax			;restore sector count
	jmp	retry

write_fault_err:
	mov	bp,1			;just retry only once for write fault error.
	jmp	dskerr1

dskerr	endp			; fall into harderr

;--------------------------------------------------------------------

	public	harderr
harderr	proc	near
	assume	ds:Bios_Data,es:nothing

	call	maperror

harderr	endp				; fall into harderr2

;--------------------------------------------------------------------

;	entry point for routines that call maperror themselves

	public	harderr2
harderr2 proc	near
	assume	ds:Bios_Data,es:nothing

	mov	cs:[tim_drv],-1 		;force a media check through rom
	mov	cx,cs:seccnt		;get count of sectors to go
	mov	sp,cs:[spsav]		;recover entry stack pointer

; since we are performing a non-local goto, restore the disk parameters

	jmp	diddleback

harderr2 endp

;--------------------------------------------------------------------

; change settle value from settlecurrent to whatever is appropriate
; note that this routine is never called for a fixed disk.

normspeed proc	near
	assume	ds:Bios_Data,es:nothing

	cmp	cs:[media_set_for_format],0
	jne	fastspeed

	push	es
	push	ax
	mov	al,cs:settleslow
	les	si,cs:dpt			; current disk parm table
	mov	es:[si].disk_head_sttl,al
	pop	ax
	pop	es

	call	fastspeed

	push	es
	les	si,cs:dpt
	mov	es:[si].disk_head_sttl,1	; 1 is fast settle value
	pop	es
	ret
normspeed endp

fastspeed proc	near
	assume	ds:Bios_Data,es:nothing

; if the drive has been marked as too big (i.e. starting sector of the
; partition is > 16 bits, then always return drive not ready.

	TESTB	es:[di].bds_fatsiz,ftoobig
	jnz	notready

	push	es
	mov	es,cs:xfer_seg
	int	13h
	mov	cs:xfer_seg,es
	pop	es
	ret

notready:
	stc
	mov	ah,80h
	ret
fastspeed endp


; map error returned by rom in ah into corresponding code to be returned to
; dos in al.  trashes di.  guaranteed to set carry.


maperror proc	near
	public	maperror
	assume	ds:Bios_Data,es:nothing

	push	cx			; save cx
	push	es			; preserve es
	push	cs			; set es=Bios_Code
	pop	es

	mov	al,ah			;put error code in al
	mov	es:[lsterr],al		;terminate list with error code
	mov	cx,numerr		;number of possible error conditions
	mov	di,offset errin 	;point to error conditions
	repne	scasb
	mov	al,es:[di + numerr - 1] ;get translation

	pop	es			; restore caller's es
	pop	cx			; restore cx
	stc				;flag error condition
	ret
maperror endp

; set the time of last access for this drive. this is done only for removable
; media.  es:di -> bds

set_tim proc	near
	assume	ds:Bios_Data,es:nothing

	push	ax

	call	GetTickCnt		; M059 Does INT 1A ah=0 & updates daycnt

; we have the new time. if we see that the time has passed, then we reset
; the threshold counter...

	cmp	dx,es:[di].bds_tim_lo
	jnz	setaccess
	cmp	cx,es:[di].bds_tim_hi
	jz	done_set

setaccess:
	mov	byte ptr cs:[accesscount],0
	mov	es:[di].bds_tim_lo,dx 	    	;save it
	mov	es:[di].bds_tim_hi,cx
done_set:
	clc
	pop	ax
	ret
set_tim endp

; this routine is called if an error occurs while formatting or verifying.
; it resets the drive,and decrements the retry count.
; on entry - ds:di - points to bds for the drive
;	     bp    - contains retry count
; on exit    flags indicate result of decrementing retry count

again	proc	near
	call	resetdisk
	cmp	ah, 6			; M039
	je	dont_dec_retry_count	; If it is a media change error M039
					;  do not decrement retry count
	dec	bp			; decrement retry count
	ret
dont_dec_retry_count:			;		M039
	or	ah, ah			; return NZ	M039
	ret				;		M039
again	endp

; Extended disk address packet used by INT 13h.
ext_packet		db	10h,0
ext_packet_count	dw	0
ext_packet_buffer	dw	0,0
ext_packet_sector	dw	0,0,0,0

;--------------------------------------------------------------------
; dispatch extended disk requests for drives marked in the bds.
;
; es:di -> bds, ds -> Bios_Data
; dx:saved_word = starting sector, xfer_seg:bx = transfer buffer
; returns to diskio for other drives. for an extended request, removes
; the dispatch return address and returns directly to the diskio caller.
;
ext_disk_dispatch proc near
	test	es:[di].bds_flags,0400h
	jnz	ext_disk_selected
	ret
ext_disk_selected:
	add	sp,2
	mov	ax,cs:[seccnt]
	call	ext_disk_io
	xor	ax,ax
	ret
ext_disk_dispatch endp

; perform extended disk i/o with the same retry limits as disk.
;
; ax = sector count, dx:saved_word = starting sector
; es:di -> bds, xfer_seg:bx = transfer buffer
; rflag selects the operation; wrtverify selects write with verify.
; unrecoverable errors return through harderr.
;
ext_disk_io proc near
	mov	cs:ext_packet_count,ax
	mov	ax,cs:[saved_word]
	cmp	es:[di].bdsm_ismini,1
	jne	ext_sector_ready
	cmp	es:[di].bdsm_hidden_trks,0
	je	ext_sector_ready
	add	ax,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS
	adc	dx,word ptr es:[di].BDS_BPB.BPB_HIDDENSECTORS+2
ext_sector_ready:
	mov	cs:ext_packet_sector,ax
	mov	cs:ext_packet_sector+2,dx
	mov	cs:ext_packet_buffer,bx
	mov	ax,cs:xfer_seg
	mov	cs:ext_packet_buffer+2,ax
	mov	bp,maxerr
	mov	cs:vretry_cnt,bp
	mov	cs:soft_ecc_cnt,bp
	mov	ah,cs:rflag
ext_disk_retry:
	push	ax
	mov	dl,es:[di].bds_drivenum
	add	ah,40h
	xor	al,al
	push	ds
	push	cs
	pop	ds
	mov	si,offset Bios_Code:ext_packet
	int	13h
	pop	ds
	jc	ext_disk_error
	cmp	cs:wrtverify,103h
	jne	ext_disk_done
	pop	ax
	push	ax
	mov	ah,44h
	push	ds
	push	cs
	pop	ds
	int	13h
	pop	ds
	jc	ext_verify_error
ext_disk_done:
	pop	ax
	clc
	ret
ext_disk_error:
	jmp	short ext_retry_check
ext_verify_error:
	cmp	ah,11h
	jne	ext_verify_other
	dec	cs:soft_ecc_cnt
	jz	ext_disk_done
	call	resetdisk
	jmp	short ext_retry
ext_verify_other:
	call	resetdisk
	dec	cs:vretry_cnt
	jmp	short ext_retry_result
ext_retry_check:
	call	ext_again
ext_retry_result:
	jz	ext_hard_error
	cmp	ah,0cch
	je	ext_write_fault
	mov	cs:soft_ecc_cnt,maxerr
ext_retry:
	pop	ax
	jmp	short ext_disk_retry
ext_write_fault:
	mov	bp,1
	jmp	short ext_retry
ext_hard_error:
	jmp	harderr
ext_disk_io endp

; reset the drive and decrement bp, except for a media change error.
; flags indicate whether retries remain.
;
ext_again proc near
	call	resetdisk
	cmp	ah,6
	je	ext_no_decrement
	dec	bp
	ret
ext_no_decrement:
	or	ah,ah
	ret
ext_again endp


Bios_Code ends
	end
