	page	,160
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	title	bios	system initialization
;
;----------------------------------------------------------------------------
;
; M012 : Changed sysinit so that sysinit does not alloc mem for DOS from DOS
;        Instead it goes ahead and manipulates arena head and makes arena
;        head point to memory immediately above DOS
;
; M022 : Improved method for calling seg_reinit.  Uses a dword pointer 
;	 instead of a bunch of confusing pushes, calls, and patched code.
;
; M024 : Have LoadDOSHiOrLow call TryToMovDOSHi instead of doing all 
;	 the work itself.
;
; M025 : Restructuring to facilitate ROMDOS (and also make the code a 
;	 little smaller): call dos_segreinit before calling AllocFreeMem.
;
; M056 : Added RPL support, so that RPL's fake INT 13 code can be safe from
;		SYSINIT & transient portion of COMMAND.COM
;
; M067 : Set up the environment ptr to point to NULL when calling exec for
;	 install= command.
;
; M069 : Close NMI window.
;
; I070 : Bypass INT 15h block move in ClrVDISKHeader() for Tortugas & 30-286
;
; M072 : Call Power_Init after DOS HIGH stubs are loaded to enable POWER to
;		hook Int 2f properly
;----------------------------------------------------------------------------
;

MULTI_CONFIG equ 1

break	macro	; dummy empty macro
	endm

	.xlist
	include version.inc
	include biosseg.inc
	include	bpb.inc
	include sysvar.inc
	include dpb.inc
	include curdir.inc
	include pdb.inc
	include exe.inc
	include sf.inc
	include arena.inc
	include syscall.inc
	include devsym.inc
	include ioctl.inc
	include biostruc.inc
	include dossym.inc
	include	dosmac.inc
	include	mult.inc
	include	oemconf.inc
	.list

Bios_Code	segment
	extrn	eot:byte,ec35_flag:byte
	extrn	bootlog_device:word
	extrn	win386_stack_seg:word,win386_stack_size:word
	extrn	win386_nextstack:word
	extrn	win386_info_flags:byte,exec_bios_word:byte,win386_callback_table:dword
	extrn	hma_init_ptr:dword,bc_retf:far
	extrn	hma_initial_size:word,hma_allocate:near
	extrn	sysinit_seg:word
	extrn	win386_stack_code_seg:word,win386_stack_code_size:word
	irp	aa,<02,08,09,0a,0b,0c,0d,0e,70,72,73,74,76,77>
	extrn	int19old&aa:dword
	endm
	extrn	BCode_start:near
	extrn	BCode_end:near

Bios_Code	ends

	.xlist
	include devmark.inc
	include cputype.inc
	.list


true	equ	0ffffh
false	equ	0
cr	equ	13
lf	equ	10
tab	equ	9

;multMULT		equ	4ah
multMULTGETHMAPTR	equ	1
multMULTALLOCHMA	equ	2
multMULTALLOCHMA7 equ 3


; Boot options flags for ROMDOS

ifdef ROMDOS

BF_NoConfig	=	00000001b	; No config.sys processing
BF_DefaultMask	=	00000110b	; Bits to indicate default drive:
BF_DefFloppy	=	00000000b	; 	First floppy drive (00)
BF_DefHard	=	00000010b 	;	First hard drive   (80)
BF_DefROM	=	00000100b	;	ROM drive          (7F)

endif

stacksw equ	true			;include switchable hardware stacks
mycds_size equ	88			; size of curdir_list. if it is not
					;the same, then will generate compile error.

if DEBUG				; BUGBUG - Jeez, remove this!
  dossize equ	0b200h
else
  dossize equ	0a000h
endif

	if	ibmjapver
NOEXEC  equ     TRUE
	else
NOEXEC  equ     FALSE
	endif

;     if mycds_size <> curdirlen,then force a compilatiaon error.

	if	mycds_size ne curdirlen
	%out	!!! sysinit1 compilation failed. different cds size !!!
	.erre	ycds_size eq curdirlen
	endif


	ifdef	TAIWAN
	extrn	cdosinit:near
	endif

;---------------------------------------

Bios_Data	segment 
	extrn	bios_error_entry:far

;equates for main stack and stack initialization program

	if	stacksw


entrysize   equ     8

mincount    equ     8
defaultcount equ    9
maxcount    equ     64

minsize     equ     32
defaultsize equ     128
maxsize     equ     512

allocbyte   equ     0
intlevel    equ     1
savedsp     equ     2
savedss     equ     4
newsp	    equ     6

free	    equ     0
allocated   equ     1
overflowed  equ     2
clobbered   equ     3


;	 external variables in ibmbio for int19h handling rouitne.

	extrn	bios_flags:word,int16_count:word
	extrn	disksector_ptr:dword
	extrn	start_bds:dword
	extrn	cdev:dword,bios_hook_1:dword
	extrn	BiosOld4F:dword,int4f_old:dword
	extrn	int4f_entry:far,intret:byte
	endif


;---------------------------------------
; external variable defined in ibmbio module for multi-track
multrk_on equ	10000000b		;user spcified mutitrack=on,or system turns
					; it on after handling config.sys file as a
					; default value,if multrk_flag = multrk_off1.
multrk_off1 equ 00000000b		;initial value. no "multitrack=" command entered.
multrk_off2 equ 00000001b		;user specified multitrack=off.

;
;SR; Win386 present flag
;
;
;SR; Added for SetFocus routine for WIN386 support
;

	extrn	xms:dword		; entry point for xms driver

ifdef ROMDOS
	extrn	DOS_Res:word		; seg addr of dos code ROM
	extrn	BootFlags:word		; boot options
endif

Bios_Data	ends


sysinitseg segment 
	assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

	extrn	sysinit_msg_base:byte
	extrn	sysinit_msg_table:word
	extrn	print_indexed:near
	extrn	query_keyboard_service:near,query_check_skip:near,query_result:byte
	extrn	default_switch_char:byte,command_line2:byte,command_line3:byte
	extrn	boot_option_open:near
	extrn	boot_process_drivers:near
	extrn	boot_dos_file_table:word,boot_old_file_table:near
	extrn	boot_load_old_dos:near,boot_logo_display:near
	extrn	boot_start_old_dos:near,boot_old_image_seg:word,boot_exec_system:near,boot_previous_menu_check:near
	extrn	boot_windows_file_table:word
	extrn	check_low_memory:near
	extrn	boot_config_flags:byte,kbd_read:near
	extrn	boot_prepare_shell:near
	extrn	boot_prepare_environment:near
	extrn	boot_shell_main:near
	extrn	query_bios_call:near,config_xms_init:near,config_copy:near
	extrn	config_buffer_paragraphs:word
	extrn	boot_runtime_flags:byte,boot_delay:word
	extrn	config_record_ptr:dword,config_record_count:word
	extrn	config_hook_active:byte
	extrn	config_access_table:dword
	extrn	config_ebda_limit:word,query_mode_flags:byte
	extrn	config_record_interrupts:near,config_record_boot_int13:near
	extrn	config_record_device:near
	extrn	sysinit_stack_msg_index:word
	extrn	stack_high:byte,alloc_marked_block:near
	extrn	p_buffers_high:byte
	extrn	bds_count:word,fdrive1:byte,dskdrvs:word
	extrn	p_files_high:byte,p_fcbs_high:byte,p_ldrv_high:byte

ifdef   MULTI_CONFIG
	extrn	config_cmd:byte
	extrn	config_envlen:word
	extrn	config_wrkseg:word
endif

	extrn	DevEntry:dword

	ifdef	dblspace_hooks
	extrn	MagicPreload:near
	extrn	MagicPostload:near
	extrn	MagicSetCdss:near
	endif

	extrn	crlfm:byte
	extrn	SI_end:byte
	extrn	condev:byte
	extrn	auxdev:byte
	extrn	prndev:byte
	extrn	commnd:byte, command_line:byte
	extrn	deviceparameters:byte
IFDEF	CONFIGPROC
	extrn	pathstring:byte			; this is not being referenced
ENDIF ; CONFIGPROC
	extrn	print:near,badmem:byte,badfil:near,showlinenum:near
	extrn	int24:near
	if	noexec
	extrn	mem_err:near
	endif

IFDEF	CONFIGPROC
	extrn	doconf:near
	extrn	multi_pass:near 
	extrn	badload:near 
	extrn	error_line:near

	extrn	ShrinkUMB:near
	extrn	UnlinkUMB:near					;M002
ENDIF ; CONFIGPROC

	extrn	toomanydrivesmsg:byte				; M029

IFDEF	POWER
	extrn	Power_Init:near				; M072
ENDIF

	ifdef	dblspace_hooks
	endif


	if	stacksw 		; internal stack information
	endif

IFDEF	CONFIGPROC
	public	do_install_exec
ENDIF ; CONFIGPROC




	extrn	stackcount:word,stacksize:word,stackat:word,stacks:dword
	extrn	firstentry:word,lastentry:word,nextentry:word
	extrn	stack_count:word,stack_size:word,stack_addr:dword
	extrn	endstackcode:byte
	extrn	int02:far,int08:far,int09:far,int70:far
	extrn	old02:dword,old08:dword,old09:dword,old70:dword
	irp	a,<0a,0b,0c,0d,0e,72,73,74,76,77>
	extrn	int&a:far,old&a:dword,firstflag&a:byte
	endm


;
;----------------------------------------------------------------------------
;
DDHighInfo	struc
 ddhigh_CSegPtr	dd	?		; pointer to code segment to be relocated
 ddhigh_CSegLen	dw	?		; length of code segment to be relocated
 ddhigh_CallBak	dd	?		; pointer to the call back routine
DDHighInfo	ends



	extrn	dosinfo:dword
	extrn	dos_temp_location:dword
	extrn	dosinit:word
	extrn	sysinit_reserve_count:word
	extrn	current_dos_location:word
	extrn	device_list:dword
	extrn	sysi_country:dword
	extrn	dos_segreinit:word
	extrn	lo_doscod_size:word
	extrn	hi_doscod_size:word
	extrn	def_php:word
	extrn	disksector_pending_size:word
	extrn	temp_bcode_seg:word
	extrn	no_floppy_report:byte
	extrn	fake_floppy_drv:byte
	extrn	runhigh:byte
	extrn	dos_low_message:byte
	extrn	dos_umb_flag:byte
	extrn	exec_boot_state:byte
	extrn	sysinit_bios_start:word
	extrn	dos_image_size:word
	extrn	sysinit_bios_paras:word
	extrn	dos_image_paras:word
	extrn	sysinit_memory_size:word
	extrn	rpl_memory_size:word
	extrn	RPLMemTop:word
	extrn	default_drive:byte
	extrn	buffers:word
	extrn	h_buffers:word
	extrn	singlebuffersize:word
	extrn	files:byte
	extrn	fcbs:byte
	extrn	keep:byte
	extrn	num_cds:byte
	extrn	confbot:word
	extrn	alloclim:word
	extrn	top_of_cdss:word
	extrn	DirStrng:byte
	extrn	zero:byte
	extrn	sepchr:byte
	extrn	linecount:word
	extrn	showcount:byte
	extrn	buffer_linenum:word
	extrn	sys_model_byte:byte
	extrn	sys_scnd_model_byte:byte
	extrn	buf_prev_off:word
	extrn	default_num_cds:byte
ifdef COPYCDS
	extrn oldnum_cdss:word,newnum_cdss:word
endif

	extrn	bios_data_segment:word
	extrn	BCodeSeg:word
	extrn	boot_load_segment:word
	extrn	boot_reloc_offset:word
	extrn	boot_reloc_segment:word
	extrn	memory_size:word
	extrn	temp_buffer_segment:word
	extrn	temp_buffer_size:word
	extrn	boot_data_high:word
	extrn	boot_data_low:word

	extrn	boot_copy_buffer:byte  ; saved boot parameters and drive

	if	not NOEXEC
	extrn	comexe:byte
	endif

;------------------------------------------------------------------
;	variables for install= command.

	extrn	multi_pass_id:byte
	extrn	install_flag:byte
	extrn	config_size:word
	extrn	sysinit_base_ptr:dword
	extrn	sysinit_ptr:dword
	extrn	checksum:word
	extrn	ldexec_fcb:byte
	extrn	ldexec_line:byte
	extrn	ldexec_start:byte
	extrn	ldexec_parm:byte
	extrn	instexe:byte
	extrn	com_level:byte
	extrn	cmmt:byte
	extrn	cmmt1:byte
	extrn	cmmt2:byte
	extrn	cmd_indicator:byte
	extrn	donotshownum:byte
	extrn	count:word
	extrn	org_count:word
	extrn	chrptr:word
	extrn	cntryfilehandle:word
	extrn	old_area:word
	extrn	impossible_owner_size:word
have_install_cmd equ 00000001b
has_installed equ 00000010b

;------------------------------------------------------------------

	extrn	area:word
	extrn	bucketptr:dword
	extrn	bufptr:dword
	extrn	memlo:word
	extrn	prmblk:word
	extrn	memhi:word
	extrn	ldoff:word
	extrn	drivenumber:byte
	extrn	boot_mode:byte


	extrn	toomanydrivesflag:byte
	extrn	boot_config_app:byte,boot_config_wos:byte,boot_msdos_status:byte
	extrn	config_device_table_ptr:dword
	extrn	new_psp_segment:word
	extrn	compressed_dest_segment:word,compressed_reserved_paras:word
	extrn	compressed_reserve:word ; paragraphs reserved for compression
	extrn	bios_extra_bytes:word
	extrn	sysinit_extra_bytes:word


	ifdef	dblspace_hooks
	extrn	MagicBackdoor:dword,NullBackdoor:far
	endif








extrn move_myself:near,sysinit_exec_start:byte
;**	TempCDS - Create (Temporary?) CDS
;
;	ENTRY	?? BUGBUG
;		(DS) = SysInitSeg
;	EXIT	?? BUGBUG
;	USES	?? BUGBUG

	public	tempcds
Procedure TempCDS

    assume ds:sysinitseg

ifdef	COPYCDS
	push	ax			; save build from scratch flag
endif ; COPYCDS

	les	di,dosinfo
	mov	cl,byte ptr es:[di.sysi_numio]
	xor	ch,ch			; (cx) = # of block devices

	mov	es:[di.sysi_ncds],cl	; one CDS per device
	mov	al,cl
	mov	ah,size curdir_list
	mul	ah			; (ax) = byte size for those CDSs
	call	pararound		; (ax) = paragraph size for CDSs
	mov	si,[top_of_cdss]

;	BUGBUG - we don't update confbot - won't someone else use it?
;	chuckst -- answer: no.  Confbot is used to access the CDSs,
;	25 jul 92  which are stored BELOW it.  Alloclim is the
;		   variable which has the top of free memory for
;		   device driver loads, etc.

	sub	si,ax

;	chuckst, 25 Jul 92 -- note:  I'm removing the code here
;		that automatically updates alloclim every time we
;		set up some new CDSs.  Instead, I've added code
;		which pre-allocates space for 26 CDSs.  This
;	        way we've got room for worst case CDSs before
;		we place MagicDrv.sys
;
;	mov	[alloclim],si		; can't alloc past here!

	mov	word ptr es:[di.sysi_cds + 2],si
	mov	ax,si
	mov	word ptr es:[di.sysi_cds],0	; set address of CDS list
	lds	si,es:[di.sysi_dpb]	; (ds:si) = address of first DPB
	assume	ds:nothing
	mov	es,ax
	xor	di,di			; (es:di) = address of 1st CDS


ifdef	COPYCDS
	pop	ax			; get back build from scratch flag
	or	al, al			; build from scratch ?
	jz	@f
	mov	byte ptr DirStrng,"A"	; if from scratch, start with A
	mov	oldnum_cdss, cx
	jmp	short fooset		; yes!
@@:
	call	SlideCDSs		; Do not build from scratch, instead
					;  slide the old CDSs down and build
					;  the new ones

endif ; COPYCDS


;*	Initialize our temporary CDSs.	We'll init each CDS with the
;	info from the corresponding DPB.
;
;	(cx) = count of CDSs left to process
;	(es:di) = address of next CDS

	public	fooset
fooset:
	mov	ax,word ptr DirStrng


	.errnz	CURDIR_TEXT		; setup the root as the curdir
	stosw
	call	get_dpb_for_drive_al	; get dpb for drive in dpb
;	(ds:si) = address of DPB
;		    (si) = -1 if no drive

	mov	ax,word ptr DirStrng+2
	stosw
	inc	byte ptr DirStrng
	xor	ax,ax
	push	cx
	.errnz	CURDIR_FLAGS - CURDIR_TEXT - size CURDIR_TEXT
	mov	cx,curdir_flags - 4
	rep	stosb			; zero out rest of CURDIR_TEXTs

;	should handle the system that does not have any floppies.
;	in this case,we are going to pretended there are two dummy floppies
;	in the system. still they have dpb and cds,but we are going to
;	0 out curdir_flags,curdir_devptr of cds so ibmdos can issue
;	"invalid drive specification" message when the user try to
;	access them.
;
;	(ax) = 0
;	(es:di) = CURDIR_FLAGS in the CDS records
;	(ds:si) = Next DPB (-1 if none)

	cmp	si,-1
	je	fooset_zero		;don't have any physical drive.

;	check to see if we are faking floppy drives.  if not go to normcds.
;	if we are faking floppy drives then see if this cds being initialised
;	is for drive a: or b: by checking the appropriate field in the dpb
;	pointed to by ds:si.  if not for a: or b: then go to normcds.  if
;	for a: or b: then execute the code given below starting at fooset_zero.
;	for dpb offsets look at inc\dpb.inc.

	cmp	cs:[fake_floppy_drv],1
	jne	normcds 		; machine has floppy drives
	cmp	ds:[si.dpb_drive],1	;if dpb_drive = 0 (a) or 1 (b).
	INTTEST
	ja	normcds
	mov	cl,3			;  the next dbp pointer
	INTTEST 			; AX should be zero here
	rep	stosw
	pop	cx
	jmp	short get_next_dpb

;	(ax) = 0

fooset_zero:
	mov	cl,3
	rep	stosw
	pop	cx
	jmp	short fincds


;*	We have a "normal" DPB and thus a normal CDS.
;
;	(ax) = 0
;	(es:di) = CURDIR_FLAGS in the CDS records
;	(ds:si) = Next DPB (-1 if none)

normcds:pop	cx

;	if a non-fat based media is detected (by dpb.numberoffat == 0),then
;	set curdir_flags to 0.	this is for signaling ibmdos and ifsfunc that
;	this media is a non-fat based one.

	cmp	[si.dpb_fat_count],0	; non fat system?
	je	setnormcds		; yes. set curdir_flags to 0. ax = 0 now.
	mov	ax,curdir_inuse 	;  else,fat system. set the flag to curdir_inuse.
setnormcds:
	FOLLOWS	CURDIR_FLAGS,CURDIR_TEXT,2
	stosw				; curdir_flags
	mov	ax,si
	FOLLOWS CURDIR_DEVPTR,CURDIR_FLAGS,4
	stosw				; curdir_devptr
	mov	ax,ds
	stosw

get_next_dpb:				; entry point for fake_fooset_zero

fincds:
	mov	ax,-1
	FOLLOWS CURDIR_ID,CURDIR_DEVPTR,4
	stosw				; curdir_id
	stosw				; curdir_id
	FOLLOWS CURDIR_USER_WORD,CURDIR_ID,2
	stosw				; curdir_user_word
	mov	ax,2
	FOLLOWS CURDIR_END,CURDIR_USER_WORD,2
	stosw				; curdir_end
	mov	al,0			;clear out 7 bytes (curdir_type,
	FOLLOWS CURDIR_TYPE,CURDIR_END,1
	stosb
	FOLLOWS CURDIR_IFS_HDR,CURDIR_TYPE,4
	stosw				;  curdir_ifs_hdr,curdir_fsda)
	stosw
	FOLLOWS CURDIR_FSDA,CURDIR_IFS_HDR,2
	stosw
	LAST	CURDIR_FSDA,CURDIR_LIST
	loop	fooset

ifndef	COPYCDS
	mov	byte ptr DirStrng,"A"
endif ; COPYCDS

	ret

EndProc TempCDS

ifndef	COPYCDS

;***	get_dpb_for_drive_al -- lookup the DPB for drive in al
;
;	entry:
;	   al == ASCII CAPS drive letter
;
;	exit:
;	   ds:si -> DPB, or si = -1 if not found

get_dpb_for_drive_al	proc	near
	assume	ds:nothing

	lds	si,[dosinfo]		; point to first DPB
	lds	si,ds:[si.sysi_dpb]	; (ds:si) = address of first DPB
	sub	al,'A'

get_dpb_for_drive_1:
	cmp	al,ds:[si].DPB_DRIVE	; match?
	jz	got_dpb_for_drive	;  done if so

	lds	si,ds:[si].DPB_NEXT_DPB
	cmp	si,-1
	jnz	get_dpb_for_drive_1	; loop until hit end of DPBs

got_dpb_for_drive:
	ret

get_dpb_for_drive_al	endp

endif ; COPYCDS

ifdef	COPYCDS
;
;----------------------------------------------------------------------------
;
; SlideCDSs : Slide the old CDSs down and build the new CDSs above the
;		old ones.
;
;	INPUT :
;	DS:SI = pointer to first DPB
;	ES:DI = pointer to the start of new CDS table
;	oldnum_cdss = number of CDSs built so far
;	newnum_cdss = number of CDSs to be added
;
;	OUTPUT : (regs are set up for FOOSET)
;	DS:SI = pointer to first new DPB for which CDS is to be built
;	ES:DI = pointer to memory where the new CDSs can be built
;	CX    = number of new CDSs to be built
;	oldnum_cdss is updated to take the newly built CDSs into account
;
;----------------------------------------------------------------------------
;
SlideCDSs	proc

	mov	cx, oldnum_cdss		; CX = number of CDSs already
					;	present
	jcxz	sc90			; if zero CDSs no need to slide
	push	cx			; save old number of CDSs
sc10:
	lds	si, [si].dpb_next_dpb	; skip the old DPBs for which CDSs
	loop	sc10			;  have been already built
	pop	cx

	push	ds
	push	si			; save pointer to first new DPB

	mov	al, SIZE curdir_list
	mul	cl
	push	ax
	call	pararound		; AX = size of old CDS table in paras
	mov	si, [top_of_cdss]
	sub	si, ax
	mov	ds, si
	xor	si, si			; DS:SI = pointer to the current CDS
					;	   table
	pop	cx			; CX = size of the CDS table
					;	(note push AX above)
	cld
	rep	movsb

	pop	si			; get back pointer to first new DPB
	pop	ds

sc90:
	mov	cx, newnum_cdss		; set CX = number new CDSs to be built
	add	oldnum_cdss, cx		; update oldnumCDSs to reflect the new
					;  addition
	ret

SlideCDSs	endp

endif ; COPYCDS

;**	EndFile - Build DOS structures
;
; This procedure is called after the config.sys has been processed and
; installable device drivers have been loaded (but before "install="
; programs are loaded) to create the dos structures such as SFTs, buffers,
; FCBs, CDSs, etc.  It also loads the sysinit_base module in low memory
; to allow for the safe EXECing of "install=" programs.  All memory
; above these structures is deallocated back to DOS.
;
;	ENTRY	?? BUGBUG
;	EXIT	?? BUGBUG
;	USES	?? BUGBUG


;------------------------------------------------------------------------------
; allocate files
;------------------------------------------------------------------------------

	public	endfile
endfile:

; we are now setting up final cdss,buffers,files,fcss strings etc.  we no
; longer need the space taken by the temp stuff below confbot,so set alloclim
; to confbot.

;	if this procedure has been called to take care of install= command,
;	    then we have to save es,si registers.

	push	ds
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data

	test	byte ptr bios_flags+1,04h
	jnz	multrk_flag_done
	or	byte ptr bios_flags+1,02h
multrk_flag_done:

	pop	ds
	assume	ds:nothing

	mov	ax,[confbot]
	mov	[alloclim],ax

	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	ax,[singlebuffersize]
	mov	[disksector_pending_size],ax
	call	relocate_disksector
; Move the BDS array and repair links that point into the old array.
	mov	ax,[bds_count]
	mov	bl,100
	mul	bl
	push	ax
	call	pararound
	mov	bh,'G'
	mov	bl,[dos_umb_flag]
	call	alloc_marked_block
	mov	es,cx
	pop	cx
	mov	si,offset fdrive1-6
	sub	di,di
	rep	movsb
	mov	bx,di
	sub	di,di
	mov	ax,cs
bds_relocate_link:
	cmp	word ptr es:[di],-1
	je	bds_next_link
	cmp	word ptr es:[di+2],ax
	jne	bds_next_link
	sub	word ptr es:[di],offset fdrive1-6
	mov	word ptr es:[di+2],es
bds_next_link:
	add	di,100
	cmp	di,bx
	jb	bds_relocate_link
	push	ds
	mov	ds,[bios_data_segment]
	assume	ds:Bios_Data
	mov	word ptr [start_bds],0
	mov	word ptr [start_bds+2],es
	pop	ds
	assume	ds:sysinitseg
	call	relocate_disksector
	les	di,[dosinfo]
	mov	al,es:[di.sysi_numio]
	cmp	al,[num_cds]
	jae	short cds_count_ready
	mov	al,[num_cds]
cds_count_ready:
	mov	[num_cds],al
	mov	ax,word ptr [dosinfo+2]
	mov	word ptr [config_device_table_ptr+2],ax

; Build the device information table and append the recorded device data.
	mov	al,[num_cds]
	shl	al,1
	shl	al,1
	mov	ah,0
	add	ax,141h
	push	ax
	add	ax,word ptr [config_record_ptr]
	add	ax,15h
	and	ax,0fff0h
	mov	bx,ax
	mov	ax,(multMULT shl 8)+multMULTALLOCHMA7
	mov	dl,0
	mov	cx,0fffbh
	int	2fh
	cmp	di,-1
	jne	short config_table_allocated
	.286
	shr	bx,4
	.8086
	push	ds
	push	cs
	pop	ds
	mov	ax,bx
	mov	bx,5901h
	call	alloc_marked_block
	mov	es,cx
	xor	di,di
	pop	ds
config_table_allocated:
	lds	bx,cs:[config_device_table_ptr]
	assume	ds:nothing
	mov	[bx],di
	mov	[bx+2],es
	pop	ax
	mov	cx,ax
	push	ax
	push	di
	xor	ax,ax
	rep	stosb
	pop	di
	mov	al,cs:[num_cds]
	mov	es:[di+140h],al
	mov	ax,di
	add	ax,0eh
	mov	es:[di+4],ax
	pop	ax
	add	di,ax
	push	es
	push	di
	mov	byte ptr es:[di],7
	mov	word ptr es:[di+1],0
	mov	word ptr es:[di+3],0
	mov	ax,cs:[config_record_count]
	mov	es:[di+5],al
	add	di,6
	lds	si,cs:[config_record_ptr]
	mov	cx,si
	xor	si,si
	cld
	rep	movsb
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	mov	ds,word ptr [cdev+2]
	assume	ds:Bios_Code
	pop	word ptr [win386_callback_table]
	pop	word ptr [win386_callback_table+2]
	push	cs
	pop	ds
	assume	ds:sysinitseg
	call	relocate_disksector

	mov	al,[files]
	sub	al,5
	jbe	dofcbs

	assume	ds:sysinitseg
	xor	ah,ah
	push	ax
	mov	bl,size sf_entry
	mul	bl
	add	ax,6
	call	pararound
	mov	bh,devmark_files
	mov	bl,[p_files_high]
	call	alloc_marked_block
	mov	es,cx
	xor	di,di
	mov	cx,ax
	.286
	shl	cx,4
	.8086
	mov	word ptr es:[di+sflink],-1
	pop	ax
	mov	es:[di+sfcount],ax
	xor	ax,ax
	add	di,6
	sub	cx,6
	cld
	rep	stosb
	lds	di,[dosinfo]
	assume	ds:nothing
	lds	di,[di+sysi_sft]
	mov	word ptr [di+sflink],ax
	mov	word ptr [di+sflink+2],es

;------------------------------------------------------------------------------
; allocate fcbs
;------------------------------------------------------------------------------

dofcbs:
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	al,[fcbs]
	xor	ah,ah
	push	ax
	mov	bl,size sf_entry
	mul	bl
	add	ax,6
	call	pararound
	mov	bh,devmark_fcbs
	mov	bl,[p_fcbs_high]
	call	alloc_marked_block
	mov	es,cx
	xor	di,di
	mov	word ptr es:[di+sflink],-1
	pop	cx
	mov	es:[di+sfcount],cx
	mov	al,'A'
	add	di,6
fcb7_fillloop:
	push	cx
	mov	cx,size sf_entry
	cld
	rep	stosb
	mov	word ptr es:[di-(size sf_entry)+sf_ref_count],0
	mov	word ptr es:[di-(size sf_entry)+sf_position],0
	mov	word ptr es:[di-(size sf_entry)+sf_position+2],0
	pop	cx
	loop	fcb7_fillloop
	lds	di,[dosinfo]
	assume	ds:nothing
	xor	ax,ax
	mov	word ptr [di+sysi_fcb],ax
	mov	word ptr [di+sysi_fcb+2],es
	mov	[di+sysi_keep],ax
	push	cs
	pop	ds
	assume	ds:sysinitseg

;------------------------------------------------------------------------------
; allocate buffers
;------------------------------------------------------------------------------

; Determine the default buffer count and limit it to the available HMA.
	mov	cx,[buffers]
	cmp	cx,-1
	je	buffer_default
	mov	ax,cx
	mul	[singlebuffersize]
	test	dx,dx
	jz	buffer_check_size
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+104]
	call	print
buffer_default:
	mov	cx,30
	mov	[h_buffers],0
	cmp	byte ptr [dos_umb_flag],0
	je	buffer_save_count
	mov	ax,(multMULT shl 8)+multMULTGETHMAPTR
	int	2fh
	xchg	ax,bx
	or	ax,ax
	jz	buffer_save_count
	sub	ax,0c00h
	jbe	buffer_save_count
	sub	dx,dx
	div	[singlebuffersize]
	inc	cx
	cmp	ax,cx
	jae	buffer_save_count
	xchg	ax,cx
	shr	ax,1
	cmp	cx,ax
	jae	buffer_save_count
	add	ax,ax
	xchg	ax,cx
buffer_save_count:
	mov	[buffers],cx
buffer_check_size:
	mov	ax,[singlebuffersize]
	mul	cx
	or	dx,dx
	jz	buffer_count_done
	mov	dx,1
	xor	ax,ax
	div	[singlebuffersize]
	mov	[buffers],ax
	xchg	ax,cx
buffer_count_done:
dobuff:
	lds	bx,cs:dosinfo	; ds:bx -> sysinitvar

	mov	word ptr ds:[bx.sysi_buffers],cx
	mov	ax,cs:[h_buffers]
	mov	word ptr ds:[bx.sysi_buffers+2],ax
	lds	bx,ds:[bx.sysi_buf]	; now,ds:bx -> buffinfo

	call	set_buffer
	cmp	word ptr cs:[h_buffers],0
	jz	xif16
	push	ds
	push	bx
	mov	ax,cs:[singlebuffersize]
	sub	ax,bufinsiz
	mul	word ptr cs:[h_buffers]
	call	pararound
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	bx,4200h
	call	alloc_marked_block
	pop	bx
	pop	ds
	assume	ds:nothing
	mov	word ptr ds:[bx.cache_ptr+2],cx
	mov	word ptr ds:[bx.cache_ptr],0
	mov	cx,cs:[h_buffers]
	mov	ds:[bx.cache_count],cx
xif16:

;------------------------------------------------------------------------------
; allocate cdss
;------------------------------------------------------------------------------
buf1:
	push	cs
	pop	ds
	assume	ds:sysinitseg
	call	relocate_disksector
	mov	al,[num_cds]
	push	ax
	mov	ah,size curdir_list
	mul	ah
	call	pararound
	mov	bh,devmark_cds
	mov	bl,[p_ldrv_high]
	call	alloc_marked_block
	les	si,[dosinfo]
	pop	ax
	mov	es:[si.sysi_ncds],al
	mov	word ptr es:[si.sysi_cds+2],cx
	xor	di,di
	mov	word ptr es:[si.sysi_cds],di
	lds	si,es:[si.sysi_dpb]
	assume	ds:nothing
	mov	es,cx
	mov	cl,al
	xor	ch,ch
	call	fooset
	push	cs
	pop	ds
	assume	ds:sysinitseg
	cld
	mov	ax,0
	test	ax,ax
	jz	stack_message_done
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_stack_msg_index]
stack_message_next:
	lodsb
	test	al,al
stack_message_end:
	jz	stack_message_end
	mov	dl,al
	mov	ah,2
	int	21h
	jmp	short stack_message_next
stack_message_done:

;------------------------------------------------------------------------------
; allocate space for internal stack
;------------------------------------------------------------------------------

	if	stacksw

	assume	ds:sysinitseg

;	if the user did not entered stacks= command, as a default, do not install
;	sytem stacks for pc1,pc xt,pc portable cases.
;	otherwise,install it to the user specified value or to the default
;	value of 9,128 for other systems.

	cmp	word ptr [stack_addr],-1 ;has the user entered "stacks=" command?
	je	doinstallstack		;then install as specified by the user
	cmp	[sys_scnd_model_byte],0 ;pc1,xt has the secondary model byte = 0
	jne	doinstallstack		;other models use the default stack settings
	cmp	[sys_model_byte],0feh	;pc1, pc/xt or pc portable ?
	jb	short doinstallstack
	jmp	skipstack
doinstallstack:
	mov	ax,[stack_count]	; stack_count = 0?
	or	ax,ax			;then,stack size must be 0 too.
	jnz	short stack_enabled
	jmp	skipstack
stack_enabled:

; Allocate the interrupt code, message and hardware stack area.

	mov	ax,entrysize
	add	ax,[stack_size]
	mul	[stack_count]
	push	ax
	call	pararound
	mov	bx,ax

	mov	cx,offset endstackcode
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_stack_msg_index]
stack_msg_size:
	lodsb
	inc	cx
	or	al,al
	jnz	stack_msg_size
	mov	ax,cx
	call	pararound
	push	ax
	add	ax,bx
	mov	bh,devmark_stk
	mov	bl,[stack_high]
	call	alloc_marked_block
	pop	ax
	add	ax,cx
	mov	word ptr [stack_addr],0
	mov	word ptr [stack_addr+2],ax
	mov	es,cx

; Relocate the interrupt code and append its stack failure message.

	mov	cx,offset endstackcode
	xor	si,si
	xor	di,di
	cld
	rep	movsb
	push	ax
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_stack_msg_index]
stack_msg_copy:
	lodsb
	stosb
	or	al,al
	jnz	stack_msg_copy
	pop	ax
	pop	cx

; Fill the Windows instance entries for the stacks and interrupt code.

	push	ds
	mov	ds,BCodeSeg
	assume	ds:Bios_Code
	mov	win386_stack_seg,ax
	mov	win386_stack_size,cx
	add	cx,offset endstackcode
	mov	win386_stack_code_seg,es
	mov	win386_stack_code_size,cx
	mov	bx,offset nextentry
	mov	win386_nextstack,bx
	mov	word ptr [win386_nextstack+2],es
	mov	word ptr [win386_nextstack+4],2
	pop	ds
	assume	ds:sysinitseg
	call	stackinit

	endif

	push	cs
	pop	ds
	assume	ds:sysinitseg
skipstack:
	call	relocate_disksector
	call	finish_disksector

	mov	al,[files]
	xor	ah,ah		; do not use cbw instruction!!!!!
				;  it does sign extend.
	mov	cx,ax
	xor	bx,bx		;close standard input
	mov	ah,close
	int	21h
	mov	bx,2
rcclloop:			;close everybody but standard output
	mov	ah,close	; need output so we can print message
	int	21h		; in case we can't get new one open.
	inc	bx
	loop	rcclloop

	mov	dx,offset condev
	mov	al,2
	mov	ah,open 	;open con for read/write
	stc			; set for possible int 24
	int	21h
	jnc	goaux
	call	badfil
	jmp	short goaux2

goaux:	push	ax
	mov	bx,1		;close standard output
	mov	ah,close
	int	21h
	pop	ax

	mov	bx,ax		;new device handle
	mov	ah,xdup
	int	21h		;dup to 1,stdout
	mov	ah,xdup
	int	21h		;dup to 2,stderr

goaux2: mov	dx,offset auxdev
	mov	al,2		;read/write access
	extrn	open_dev:near
	call	open_dev

	mov	dx,offset prndev
	mov	al,1		;write only
	call	open_dev

;global rearm command for shared interrupt devices attached in the system;
;shared interrupt attachment has some problem when it issues interrupt
;during a warm reboot.	once the interrupt is presented by the attachment,
;no further interrupts on that level will be presented until a global rearm
;is issued.  by the request of the system architecture group, msbio will
;issue a global rearm after every device driver is loaded.
;to issue a global rearm:	;for pc1,xt,palace
;
;			  out 02f2h,xx  ; interrupt level 2
;			  out 02f3h,xx  ; interrupt level 3
;			  out 02f4h,xx  ; interrupt level 4
;			  out 02f5h,xx  ; interrupt level 5
;			  out 02f6h,xx  ; interrupt level 6
;			  out 02f7h,xx  ; interrupt level 7
;
;	for pc at,in addition to the above commands,
;	need to handle the secondary interrupt handler
;
;			  out 06f2h,xx  ; interrupt level 10
;			  out 06f3h,xx  ; interrupt level 11
;			  out 06f4h,xx  ; interrupt level 12
;			  out 06f6h,xx  ; interrupt level 14
;			  out 06f7h,xx  ; interrupt level 15
;
;	for round-up machine
;
;			  none.

; where xx stands for any value.
;
; for your information,after naples level machine,the system service bios
; call (int 15h),function ah=0c0h returns the system configuration parameters
;

	push	ax
	push	bx
	push	dx
	push	es

	mov	al,0ffh 		;reset h/w by writing to port
	mov	dx,2f2h 		;get starting address
	out	dx,al			; out 02f2h,0ffh
	inc	dx
	out	dx,al			; out 02f3h,0ffh
	inc	dx
	out	dx,al			; out 02f4h,0ffh
	inc	dx
	out	dx,al			; out 02f5h,0ffh
	inc	dx
	out	dx,al			; out 02f6h,0ffh
	inc	dx
	out	dx,al			; out 02f7h,0ffh

;sb secondary global rearm

	mov	ax,0f000h		;get machine type
	mov	es,ax
	cmp	byte ptr es:[0fffeh],0fch ;q:is it a at type machine
	je	startrearm		; *if at no need to check

	mov	ah,0c0h 		;get system configuration
	int	15h			; *
	jc	finishrearm		; *jmp if old rom

; test feature byte for secondary interrupt controller

	test	es:[bx.bios_sd_featurebyte1],scndintcontroller
	je	finishrearm		;jmp if it is there

startrearm:
	mov	al,0ffh 		;write any pattern to port
	mov	dx,6f2h 		;get starting address
	out	dx,al			;out 06f2h,0ffh
	inc	dx			;bump address
	out	dx,al			;out 06f3h,0ffh
	inc	dx			;bump address
	out	dx,al			;out 06f4h,0ffh
	inc	dx			;bump address
	inc	dx			;bump address
	out	dx,al			;out 06f6h,0ffh
	inc	dx			;bump address
	out	dx,al			;out 06f7h,0ffh

finishrearm:
	pop	es
	pop	dx
	pop	bx
	pop	ax

;    global rearm end *******************

;------------------------------------------------------------------------------
; allocate sysinit_base for install= command
;------------------------------------------------------------------------------
; sysinit_base allocation.
;   check if endfile has been called to handle install= command.

set_sysinit_base:
IFDEF	CONFIGPROC
;--------------------------------------------------------------------------
;sysinit_base will be established in the secure area of
;lower memory when it handles the first install= command.
;sysinit_base is the place where the actual exec function will be called and
;will check sysinit module in high memory if it is damaged by the application
;program.  if sysinit module has been broken,then "memory error..." message
;is displayed by sysinit_base.
;--------------------------------------------------------------------------

	mov	ax,[memhi]
	sub	ax,[area]
	mov	[impossible_owner_size],ax

; Reserve space for the relocated code and its error message.

	mov	cx,(offset end_sysinit_base) - (offset sysinit_base)
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_msg_table+106]
install_msg_size:
	lodsb
	inc	cx
	cmp	al,'$'
	jne	install_msg_size
	mov	ax,cx
	call	pararound
	mov	bx,devmark_inst * 100h
	call	alloc_marked_block
	mov	word ptr [sysinit_base_ptr+2],cx
	mov	es,cx
	assume	es:nothing
	xor	di,di
	mov	word ptr [sysinit_base_ptr],di
	mov	cx,(offset end_sysinit_base) - (offset sysinit_base)
	mov	si,offset sysinit_base
	cld
	rep	movsb
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_msg_table+106]
install_msg_copy:
	lodsb
	stosb
	cmp	al,'$'
	jne	install_msg_copy

	mov	word ptr [sysinit_ptr],offset sysinitptr ; returing address from
	mov	word ptr [sysinit_ptr+2],cs ;	sysinit_base back to sysinit.
	or	[install_flag],has_installed ; set the flag.
ENDIF ; CONFPROC

;------------------------------------------------------------------------------
; free the rest of the memory from memhi to confbot.  still from confbot to
; the top of the memory will be allocated for sysinit and config.sys if
; have_install_cmd.
;------------------------------------------------------------------------------

	mov	bx,[memhi]
	mov	ax,[area]
	mov	[old_area],ax		; save [area]
	mov	es,ax			;calc what we needed
	sub	bx,ax
	mov	ah,setblock
	int	21h			;give the rest back

	push	es
	mov	ax,es
	dec	ax
	mov	es,ax			;point to arena
	mov	es:[arena_owner],8	;set impossible owner
	mov	word ptr es:[arena_name], 'DS'	; System Data
	pop	es

	mov	bx,0ffffh
	mov	ah,alloc
	int	21h
	mov	ah,alloc
	int	21h			; allocate the rest of the memory

	mov	[memhi],ax		; start of the allocated memory

;;;; at this moment,memory from [memhi]:0 to top-of-the memory is
;;;; allocated.
;;;; to protect sysinit,confbot module (from confbot (or =alloclim at
;;;; this time) to the top-of-the memory),here we are going to
;;;; 1). "setblock" from memhi to confbot.
;;;; 2). "alloc" from confbot to the top of the memory.
;;;; 3). "free alloc memory" from memhi to confbot.

;memory allocation for sysinit,confbot module.

	mov	es,ax
	mov	bx,[confbot]
	sub	bx,ax			; confbot - memhi
	dec	bx			; make a room for the memory block id.
	dec	bx			; make sure!!!.
	mov	ah,setblock
	int	21h			; this will free (confbot to top of memory)
	mov	bx,0ffffh
	mov	ah,alloc
	int	21h
	mov	ah,alloc
	int	21h			; allocate (confbot to top of memory)
	mov	[area],ax		; save allocated memory segment.
					; need this to free this area for command.com.
	mov	es,[memhi]
	mov	ah,49h			; free allocated memory.
	int	21h			; free (memhi to confbot(=area))

endfile_ret:
	ret

; End of "EndFile" DOS structure configuration.

IFDEF	CONFIGPROC
;-------------------------------------------------------------------------
; Do_Install_Exec
;
; This procedure is used to EXEC a program being loaded via the 
; "install=" mechanism in config.sys.  It does this by setting up
; the parameters, and then jumping to sysinit_base, which has been
; setup in low memory.  When complete, sysinit_base will jump back
; up to this procedure (if sysinit remains uncorrupted by the installed
; program).

do_install_exec proc near		; now,handles install= command.

	push	si			; save si for config.sys again.

; we are going to call load/exec function.
; set es:bx to the parameter block here;;;;;;;
; set ds:dx to the asciiz string. remember that we already has 0
; after the filename. so parameter starts after that. if next
; character is a line feed (i.e. 10),then assume that the 0
; we already encountered used to be a carrage return. in this
; case,let's set the length to 0 which will be followed by
; carridge return.

; es:si -> command line in config.sys. points to the first non blank
;character after =.

	push	es
	push	ds
	pop	es
	pop	ds			; es->sysinitseg,ds->confbot seg
	assume	ds:nothing
	mov	dx,si			; ds:dx->file name,0 in config.sys image.

	xor	cx,cx
	cld
	mov	cs:ldexec_start,' '	; clear out the parm area
	mov	di,offset ldexec_parm
installfilename:			;  skip the file name
	lodsb				;  al = ds:si; si++
	or	al,al
	jnz	installfilename
got_installparm:			;  copy the parameters to ldexec_parm
	lodsb
	stosb
	cmp	al,lf			;  line feed?
	je	done_installparm
	inc	cl			;  # of char. in the parm.
	jmp	got_installparm
done_installparm:
	mov	byte ptr cs:[ldexec_line],cl ;	length of the parm.
	or	cl,cl			;if no parm,then
	jne	install_seg_set 	; let the parm area
	mov	byte ptr cs:[ldexec_start],cr ;	starts with cr.
install_seg_set:
	mov	word ptr cs:0,0		; make a null environment segment
	mov	ax,cs			; by overlap jmp instruction of sysinitseg.

;---------------------------------------------------M067---------------
;
; 	the environment pointer is made 0. so the current environment ptr.
; 	will be the same as pdb_environ which after dosinit is 0.
;
; 	mov	word ptr cs:[instexe+0],0 ; set the environment seg.
;
;
; 	instexe.exec0_environ need not be initialized to 0 above. It was
; 	done as a fix for bug #529. The actual bug was in NLSFUNC and
; 	was fixed. 
;
;--------------------------------------------------------------------------
ifdef   MULTI_CONFIG
;
;   If there's any environment data in "config_wrkseg", pass to app
;
	mov	cx,ax
	cmp	cs:[config_envlen],0
	je	no_envdata2
	mov	cx,cs:[config_wrkseg]
no_envdata2:
endif  ;MULTI_CONFIG

	mov	word ptr cs:[instexe+0],cx ; set the environment seg.

	mov	word ptr cs:[instexe+4],ax ; set the seg.
	mov	word ptr cs:[instexe+8],ax
	mov	word ptr cs:[instexe+12],ax
	call	sum_up
	mov	es:checksum,ax		; save the value of the sum
	xor	ax,ax
	mov	ah,exec			; load/exec
	mov	bx,offset instexe	; es:bx -> parm block.
	push	es			; save es,ds for load/exec
	push	ds			; these registers will be restored in sysinit_base.
	jmp	cs:dword ptr sysinit_base_ptr ; jmp to sysinit_base to execute
					; load/exec function and check sum.

;j.k. this is the returning address from sysinit_base.

	public	sysinitptr
sysinitptr:				; returning far address from sysinit_base
	pop	si			; restore si for config.sys file.
	push	es
	push	ds
	pop	es
	pop	ds			; now ds - sysinitseg,es - confbot
	jnc	install_exit_ret

	push	si			; error in loading the file for install=.
	call	badload 		; es:si-> path,filename,0.
	pop	si

install_exit_ret:
	ret

do_install_exec endp

ENDIF ; CONFIGPROC


;**	ParaRound - Round Up length to paragraph multiple
;
;	ParaRound rounds a byte count up to a multiple of 16, then divides
;	by 16 yielding a "length in paragraphs" value.
;
;	ENTRY	(ax) = byte length
;	EXIT	(ax) = rounded up length in paragraphs
;	USES	ax, flags

Procedure ParaRound

	add	ax,15
	rcr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	ret

EndProc   ParaRound


;------------------------------------------------------------------------------
; sysinit_base module.
;
; This module is relocated by the routine EndFile to a location in low
; memory.  It is then called by SYSINIT to perform the EXEC of programs
; that are being loaded by the "install=" command.  After the EXEC call
; completes, this module performs a checksum on the SYSINIT code (at the
; top of memory) to be sure that the EXECed program did not damage it.
; If it did, then this module will print an error message and stop the
; system.  Otherwise, it returns control to SYSINIT.
;
;
;in: after relocation,
;    ax = 4b00h - load and execute the program dos function.
;    ds = confbot. segment of config.sys file image
;    es = sysinitseg. segment of sysinit module itself.
;    ds:dx = pointer to asciiz string of the path,filename to be executed.
;    es:bx = pointer to a parameter block for load.
;    SI_end (byte) - offset vaule of end of sysinit module label
;    bigsize (word) - # of word from confbot to SI_end.
;    chksum (word) - sum of every byte from confbot to SI_end in a
;			word boundary moduler form.
;    sysinit_ptr (dword ptr) - return address to sysinit module.
;
;note: sysinit should save necessary registers and when the control is back

	public	sysinit_base
sysinit_base:
	mov	word ptr cs:sysinit_base_ss,ss	; save stack
	mov	word ptr cs:sysinit_base_sp,sp
	int	21h				; load/exec dos call.
	mov	ss,word ptr cs:sysinit_base_ss	; restore stack
	mov	sp,word ptr cs:sysinit_base_sp
	pop	ds				; restore confbot seg
	pop	es				; restore sysinitseg
	jc	sysinit_base_end		; load/exec function failed.
						; at this time,i don't have to worry about
						; that sysinit module has been broken or not.
	call	sum_up				; otherwise,check if it is good.
	cmp	es:checksum,ax
	je	sysinit_base_end

;	memory broken. show "memory allocation error" message and stall.

	mov	ax,160eh
	mov	bl,3
	int	2fh
	mov	ah,9
	push	cs
	pop	ds
	mov	dx,offset end_sysinit_base - sysinit_base
	int	21h

local_stall: hlt                        ;use HLT to minimize energy consumption
	jmp	local_stall

sysinit_base_end: jmp es:sysinit_ptr	;return back to sysinit module

sum_up:

;in:   es - sysinitseg.
;out:  ax - result
;
;remark: since this routine will only check starting from "sysinit_exec_start" to the end of
;	 sysinit segment,the data area, and the current stack area are not
;	 coverd.  in this sense,this check sum routine only gives a minimal
;	 gaurantee to be safe.
;
;first sum up confbot seg.

	push	ds
	mov	ax,es:confbot
	mov	ds,ax
	xor	si,si
	xor	ax,ax
	mov	cx,es:config_size	; if config_size has been broken,then this
					;whole test better fail.
	shr	cx,1			; make it a word count
	jz	sum_sys_code		; when config.sys file not exist.
sum1:
	add	ax,ds:word ptr [si]
	inc	si
	inc	si
	loop	sum1
;now,sum up sysinit module.
sum_sys_code:
	mov	si,offset sysinit_exec_start
					;  this does not cover the possible stack code!!!
	mov	cx,offset SI_end+200h ; include the temporary disk buffer
	add	cx,es:sysinit_extra_bytes
	sub	cx,si			;  from after_checksum to SI_end
	shr	cx,1
sum2:
	add	ax,es:word ptr [si]
	inc	si
	inc	si
	loop	sum2
	pop	ds
	ret

sysinit_base_ss equ $-sysinit_base
	dw	?
sysinit_base_sp equ $-sysinit_base
	dw	?
end_sysinit_base label byte

; Reserve the remainder of the current 64K area if the sector buffer
; could not be placed in any of the preceding marked blocks.
	public	finish_disksector,relocate_disksector
finish_disksector:
	assume	ds:sysinitseg
	mov	ax,[disksector_pending_size]
	test	ax,ax
	jz	disksector_done
	mov	ax,[memhi]
	not	ax
	and	ax,0fffh
	mov	bx,4800h
	call	alloc_marked_block

; Move the disk sector buffer when the next marked block permits it.
; Entry: DS = SYSINITSEG; disksector_pending_size is the byte count.
;
relocate_disksector proc near
	assume	ds:sysinitseg
	mov	ax,[disksector_pending_size]
	test	ax,ax
	jz	disksector_done
	mov	bx,[memhi]
	inc	bx
	.286
	shl	bx,4
	.8086
	add	bx,ax
	jnc	short disksector_alloc
	jnz	disksector_done
disksector_alloc:
	call	pararound
	mov	bx,4800h
	call	alloc_marked_block
	sub	ax,ax
	mov	[disksector_pending_size],ax
	push	ds
	mov	ds,[bios_data_segment]
	assume	ds:Bios_Data
	mov	word ptr [disksector_ptr],bufinsiz
	mov	word ptr [disksector_ptr+2],cx
	pop	ds
	assume	ds:sysinitseg
disksector_done:
	ret
relocate_disksector endp

;-------------------------------------------------------------------------
; Set_Buffer - Allocate and initialize the buffer queue
;
; Entry: DS:BX -> buffer information, singlebuffersize = header + sector.
; Exit:  Circular buffer queue and HMA/scratch-buffer fields established.
;
	public	set_buffer,GetBufferAddr7,set_buffer_info
set_buffer proc near

	assume	ds:nothing
	call	GetBufferAddr7
	mov	word ptr ds:[bx].Buff_Queue,di	; head of Buff Q
	mov	word ptr ds:[bx].Buff_Queue[2],es
	mov	word ptr ds:[bx.Dirty_Buff_Count],0 ;set dirty_count to 0.

	mov	ax, di
	mov	cx, [buffers]
	push	di				; remember first buffer

;	for each buffer

nxt_buff:
	call	set_buffer_info 		;set buf_link,buf_id...
	mov	di, ax
	loop	nxt_buff

	sub	di, [singlebuffersize]		; point to last buffer

	pop	cx				; get first buffer
	mov	word ptr es:[di].buf_next, cx	; last->next = first
	xchg	cx, di
	mov	word ptr es:[di].buf_prev, cx	; first->prev = last

	mov	ax,es
	cmp	ax,word ptr ds:[bx+1fh] ; DOS 7 buffer HMA segment threshold
	jb	buffer7_exit
	mov	byte ptr ds:[bx].Buff_In_HMA,1
	mov	ax,cs:[singlebuffersize]
	sub	ax,bufinsiz
	push	ds
	push	bx
	call	pararound
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	bh,devmark_buf
	mov	bl,[dos_umb_flag]
	cmp	bl,1
	jne	short buffer7_scratch
	mov	bl,0
buffer7_scratch:
	call	alloc_marked_block
	pop	bx
	pop	ds
	assume	ds:nothing
	mov	word ptr ds:[bx].Lo_Mem_Buff,0
	mov	word ptr ds:[bx].Lo_Mem_Buff[2],cx
buffer7_exit:
	ret
set_buffer endp

;;---------------------------------------------------------------------------
;
; procedure : GetBufferAddr7
;
;		Gets the buffer address either in HMA or in Lo Mem
;
; returns in es:di the buffer adress
;
;;---------------------------------------------------------------------------

GetBufferAddr7 proc near
	push	bx
	mov	ax,cs:[singlebuffersize]
	mul	word ptr cs:[buffers]
	add	ax,15
	and	ax,not 15
	xchg	ax,bx
	mov	ax,(multMULT shl 8)+multMULTALLOCHMA7
	mov	dl,1
	mov	cx,-6
	int	2fh
	cmp	di,-1
	jne	short buffer7_done
	.286
	shr	bx,4
	.8086
	push	ds
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	ax,bx
	mov	bh,devmark_buf
	mov	bl,[p_buffers_high]
	call	alloc_marked_block
	mov	es,cx
	xor	di,di
	pop	ds
	assume	ds:nothing
buffer7_done:
	pop	bx
	ret
GetBufferAddr7 endp



set_buffer_info proc

;function: set buf_link,buf_id,buf_sector
;
;in: es:di -> buffer header to be set.
;    ax = di
;
;out:
;    above entries set.

	push	[buf_prev_off]
	pop	es:[di.buf_prev]
	mov	buf_prev_off,ax
	add	ax,[singlebuffersize]		;adjust ax
	mov	word ptr es:[di.buf_next],ax
	mov	word ptr es:[di.buf_id],00ffh	;new buffer free
	mov	word ptr es:[di.buf_sector],0	;to compensate the masm 3 bug
	mov	word ptr es:[di.buf_sector+2],0 ;to compensate the masm 3 bug
	ret
set_buffer_info endp


;------------------------------------------------------------------------------
; ibmstack initialization routine.
	if	stacksw
.sall
;
;	to follow the standard interrupt sharing scheme, msstack.asm
;	has been modified.  this initialization routine also has to
;	be modified because for the interrupt level 7 and 15, firstflag
;	should be set to signal that this interrupt handler is the
;	first handler hooked to this interrupt vector.
;	we determine this by looking at the instruction pointed by
;	this vector.  if it is iret, then this handler should be the
;	first one.  in our case, only the interrupt vector 77h is the
;	interrupt level 15. (we don't hook interrupt level 7.)
;
;	the followings are mainly due to m.r.t; ptm fix of p886 12/3/86
;	some design changes are needed to the above interrupt sharing
;	method.  the above sharing scheme assumes that 1). interrupt
;	sharing is never done on levels that have bios support. 2). "phantom"
;	interrupts would only be generated on levels 7 and 15.
;	these assumptions are not true any more. we have to use the firstflag
;	for every level of interrupt.  we will set the firstflag on the following
;	conditions:
;
;	 a.	 if the cs portion of the vector is 0000, then "first"
;	 b. else if cs:ip points to valid shared header, then not "first"
;	 c. else if cs:ip points to an iret, then "first"
;	 d. else if cs:ip points to dummy, then "first"
;
;	where dummy is - the cs portion must be f000, and the ip portion must
;	be equal to the value at f000:ff01. this location is the initial value
;	from vector_table for interrupt 7, one of the preserved addresses in all
;	the bioses for all of the machines.
;
;	system design group requests bios to handle the phantom interrupts.
;
;	the "phantom" interrupt is an illegal interrupt such as an interrupt
;	produced by the bogus adapter card even without interrupt request is
;	set.  more specifically, 1). the 8259 has a feature when running in
;	edge triggered mode to latch a pulse and present the interrupt when
;	the processor indicates interrupt acknowledge (inta).  the interrupt
;	pulse was exist at the time of inta to get a "phantom" interrupt.
;	2). or, this is caused by adapter cards placing a glitch on the
;	interrupt line.
;
;	to handle those "phantom" interrupts, the main stack code will check
;	the own firstflag, and if it is not "first" (which means the forward
;	pointer points to the legal shared interrupt handler), then pass the
;	control.  if it is the first, then the following action should be
;	taken.	we don't have to implement skack logic in this case.
;
;	to implement this logic, we rather choose a simple method.
;	if ont of the above "firstflag" conditions is met, we are not
;	going to hook this interrupt vector.  the reason is if the original
;	vector points to "iret" and do nothing, we don't need
;	to implement the stack logic for it.  this will simplify implementation
;	while maintaining compatibility with the old version of dos.
;	this implies that in the main stack code, there might be a stack code
;	that will never be used, a dead code.
;
;in - cs, ds -> sysinitseg, es -> relocated stack code & data.

	page
	assume	ds:sysinitseg
stackinit	proc near

; Initialize the stack table and clear the stack area.
	push	cs
	pop	ds
	mov	bp,word ptr [stack_addr]
	mov	es:firstentry,bp
	mov	ax,entrysize
	mov	cx,[stack_count]
	mul	cx
	add	ax,bp
	mov	es:stackat,ax
	mov	bx,ax
	sub	bx,2
	mov	di,es:stackat
	mov	ax,[stack_size]
	mul	cx
	mov	cx,ax
	xor	ax,ax
	push	es
	pop	ds
	assume	ds:sysinitseg
	mov	es,word ptr [stacks+2]
	cld
	rep	stosb
	mov	cx,stackcount
buildloop7:
	mov	es:byte ptr allocbyte[bp],al
	mov	es:byte ptr intlevel[bp],al
	mov	es:word ptr savedsp[bp],ax
	mov	es:word ptr savedss[bp],ax
	add	bx,stacksize
	mov	es:word ptr newsp[bp],bx
	mov	es:[bx],bp
	add	bp,entrysize
	loop	buildloop7
	sub	bp,entrysize
	mov	lastentry,bp
	mov	nextentry,bp
	xor	ax,ax
	mov	es,ax
	cli

	irp	aa,<02,08,09,70>

	mov	si,aa&h*4		;pass where vector is to be adjusted
	mov	di, offset int19old&aa	;we have to set old&aa for int19 handler too.
	mov	bx,offset old&aa	;pass where to save original owner pointer
	mov	dx,offset int&aa	;pass where new handler is
	call	new_init_loop		;adjust the vector to new handler,
					;  saving pointer to original owner
	endm

	irp	aa,<0a,0b,0c,0d,0e,72,73,74,76,77>	;shared interrupts

	mov	si,aa&h*4		;pass where vector is to be adjusted
	push	ds			;save relocated stack code segment
	lds	bx, es:[si]		;ds:bx -> original interrupt handler
	push	ds
	pop	dx			;dx = segment value

	cmp	dx,0
	jz	int&aa&_first

	cmp	byte ptr ds:[bx],0cfh	;does vector point to an iret?
	jz	int&aa&_first

	cmp	word ptr ds:[bx.6],424bh ;magic offset (see int&aa, msstack.inc)
	jz	int&aa&_not_first

	cmp	dx,0f000h		;rom bios segment
	jnz	int&aa&_not_first

	push	es
	push	dx
	mov	dx,0f000h
	mov	es,dx
	cmp	bx,word ptr es:0ff01h
       	pop	dx
	pop	es
	jz	int&aa&_first

int&aa&_not_first:			;not the first. we are going to hook vector.
	pop	ds
	mov	di, offset int19old&aa	;we have to set old&aa for int19 handler too.
	mov	bx, offset old&aa	;pass where to save original owner pointer
	mov	dx, offset int&aa	;pass where new handler is
	call	new_init_loop		;adjust the vector to new handler, saving
					;pointer to original owner.
	jmp	short int&aa&_end
int&aa&_first:				 ;the first. don't have to hook stack code.
	pop	ds
int&aa&_end:

	endm

	sti
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	or	byte ptr [bios_flags+1],1
	ret
stackinit	endp

new_init_loop proc near

;input: si=ofset into vector table of the particular int vector being adjusted
;	bx=ds:offset of oldxx, where will be saved the pointer to original owner
;	dx=ds:offset of intxx, the new interrupt handler
;	di=offset value of int19old&aa variable in bios.
;	es=zero, segid of vector table
;	ds=relocated stack code segment

	mov	ax,es:[si]
	mov	word ptr ds:[bx],ax
	mov	cx,es:[si+2]
	mov	word ptr ds:[bx+2],cx
	push	ds
	mov	ds,cs:BCodeSeg
	mov	word ptr ds:[di],ax
	mov	word ptr ds:[di+2],cx
	pop	ds
	mov	word ptr es:[si],dx
	mov	word ptr es:[si+2],ds
	ret
new_init_loop endp


.xall
	endif

;------------------------------------------------------------------------------





	ifdef	TAIWAN

;---------------------
; entry : none
; exit : ax = 0  --> oem local driver not found
;	    = 1  --> oem local driver found
; destore : ds,es,bx,cx,dx,si,di
; description :
;  search config.sys to find oem local driver.
;  oem local driver should in \csi\driver\ directory .
;  if (found oem local driver in config.sys)
;	ax=1;
;  else
;	ax=0;
;  return;
;  ps. please see state diagram for state description.
;---------------------

chkoemlocaldrv proc near
	push	es
	push	ds
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	call	chkconfig
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	pop	es
	ret
chkoemlocaldrv endp

config_sys db	"\CONFIG.SYS",0
sizeofconfig dw 0
filehandle dw	0
workingmemptr dw 0
deviceid db	"DEVICE"
csidrvid db	"CSI\DRIVER\"
localdrvname dw 0
chkconfig proc	near
	call	preprocess
	jnc	initstate
	jmp	notfoundret

;
; processing config.sys
;
; state 0
; ds:si --> current line ( end of line is oah or 0dh )

initstate:
	mov	si,dx
state_0:
	push	cs
	pop	es
	mov	di,offset deviceid
	mov	cx,3
	repz	cmpsw
	jz	state_1
	mov	ax,0ffffh
	jmp	state_10
state_1:
	lodsb
	cmp	al,' '
	jz	state_1
	cmp	al,'='
	jz	state_2
state_10a:
	jmp	state_10
state_2:
	lodsb
	cmp	al,' '
	jz	state_2
	cmp	al,'\'
	jz	state_5
	cmp	al,'A'
	jb	state_10a
	cmp	al,'z'
	ja	state_10a
state_3:
	dec	si
	mov	cs:[localdrvname],si
	inc	si
state_4:
	lodsb
	cmp	al,':'
	jz	state_6
	jmp	state_10
state_5:
	dec	si
	mov	cs:[localdrvname],si
	inc	si
	jmp	state_7
state_6:
	lodsb
	cmp	al,'\'
	jz	state_7
	cmp	al,'c'
	jne	state_10a
	inc	si
state_7:
	mov	di,offset csidrvid
	mov	cx,11
	repz	cmpsb
	jnz	state_10a
state_8:
	lodsb
	cmp	al,'1'
	jb	state_10
	cmp	al,'z'
	ja	state_10
state_9:
tryopenlocaldrv:
	mov	dx,cs:[localdrvname]
	mov	si,dx
chknextbyte:
	lodsb
	cmp	al,0h
	jz	openfile
	cmp	al,' '
	jne	chknextbyte
	dec	si
	mov	byte ptr ds:[si],0
openfile:
	mov	ax,3d00h		; open config.sys
	stc
	int	21h
	jc	notfoundret
	mov	bx,ax			; bx = file handle
	mov	ah,3eh
	int	21h			; close local driver
	jc	notfoundret
	jmp	foundret

state_10:
	cmp	al,1ah			; look current char. == eof ?
	jz	notfoundret
	lodsb
	cmp	al,0
	jz	newlinestate
	cmp	al,1ah
	jz	notfoundret
	jmp	state_10
newlinestate:
	lodsb
	cmp	al,1ah
	jz	notfoundret
	cmp	al,0
	jz	newlinestate
	dec	si
	jmp	state_0
notfoundret:
	mov	ax,0
	jmp	freemem
foundret:
	mov	ax,1
freemem:
	push	ax
	call	freememory
	pop	ax
	ret

chkconfig endp

preprocess proc near
	push	cs
	pop	ds
	mov	dx,offset config_sys
	mov	ax,3d00h		; open config.sys
	stc
	int	21h
	jc	errorfile

; get size of config.sys

	mov	bx,ax			; bx = file handle
	mov	cs:[filehandle],bx
	xor	cx,cx
	xor	dx,dx
	mov	ax,4202h		; move file ptr
	int	21h
	mov	cs:[sizeofconfig],ax	; ax == size of config.sys
	xor	dx,dx			; ignore more than 64k of config
	mov	ax,4200h		; mov file ptr to beginning of file
	int	21h

; allocate for config.sys

	mov	ax,cs:[sizeofconfig]
	add	ax,15			; change to para
	rcr	ax,1
	shr	ax,1
	shr	ax,1
	shr	ax,1
	add	ax,20h
	mov	bx,ax			; size of memory in para
	mov	ah,48h
	int	21h
	jc	memerr
					; ax --> free memory
	mov	cs:[workingmemptr],ax

; read config.sys

	mov	bx,cs:[filehandle]	; file handle
	mov	cx,cs:[sizeofconfig]	; byte count of reading
	xor	dx,dx
	mov	ds,ax			; ds:dx --> buffer
	mov	ah,3fh
	int	21h
	jc	errorfile

; translate to upper case

	call	transtoupper
	clc
	ret
errorfile:
memerr:
	stc
	ret
preprocess endp

; entry : ds:dx --> buffer
; exit : none
; description : translate all letter in buffer to upper type
;	ps ,don't change ds:dx

transtoupper proc near
	cld
	mov	cx,cs:[sizeofconfig]
	mov	si,dx
transnext:
	lodsb
	cmp	al,'A'
	jb	chklfcr
	cmp	al,'z'
	ja	chkcounter
	sub	al,'a'-'A'
	mov	ds:[si-1],al
	jmp	chkcounter
chklfcr:
	cmp	al,0dh
	jz	setzero
	cmp	al,0ah
	jz	setzero
	jmp	chkcounter
setzero:
	mov	al,0
	mov	ds:[si-1],al
chkcounter:
	loop	transnext
	ret
transtoupper endp

;entry : none ( free memory block ptr in [workingmem] )
;exit : none

freememory proc near
	mov	ax,cs:[workingmemptr]
	mov	es,ax
	mov	ah,49h
	int	21h
	ret
freememory endp


; name : maketempvector
; entry : es:bx -->
;		dd	original int 9 vector	  ( offfset ,segment )
;		dd	original int 10h vector   ( offfset ,segment )
;		dd	original int 16h vector   ( offfset ,segment )
;
; exit : none
; description : 1. save local driver table in static area
;		2. make temp. vector for int9 ,10h ,16h
;
oemdriverinst dw 0
orgvectblptr dd 0

	db	0eah
dummyint9 dd	0
	db	0eah
dummyint10h dd	0
	db	0eah
dummyint16h dd	0

csiint9 dd	0
csiint10h dd	0
csiint16h dd	0

maketempvector proc near
	push	ds
	push	ax
	push	di
	push	si
	push	cx

; save table ptr

	mov	word ptr cs:[orgvectblptr],bx
	mov	word ptr cs:[orgvectblptr+2],es
	cmp	cs:oemdriverinst,0
	jnz	ignoreint9

; make temp. vector for int 9 ,

	mov	bx,9			; int #
	push	cs
	pop	es
	mov	di,offset csiint9	; es:di --> store area for csi vector
	push	cs
	pop	ds
	mov	si,offset dummyint9	; ds:si --> dummy int service
	call	dummyvector

ignoreint9:

; make temp. vector for int 10h

	mov	bx,10h			; int #
	push	cs
	pop	es
	mov	di,offset csiint10h	; es:di --> store area for csi vector
	push	cs
	pop	ds
	mov	si,offset dummyint10h	; ds:si --> dummy int service
	call	dummyvector

; make temp. vector for  int 16h

	mov	bx,16h			; int #
	push	cs
	pop	es
	mov	di,offset csiint16h	; es:di --> store area for csi vector
	push	cs
	pop	ds
	mov	si,offset dummyint16h	; ds:si --> dummy int service
	call	dummyvector
	pop	cx
	pop	si
	pop	di
	pop	ax
	pop	ds
	ret


maketempvector endp

;name	: dummyvector
; entey : ds:si --> dummy int sevice routine
;	  es:di --> point to  csi vector store area
;	  bx  == int number
; exit : none
; description :
;		setting dummy vector of int 9 ,10h,16h
;		for recover csi vector
;		/* phase 1*/
;		[ds:si]=[0:bx*4]
;		[ds:si+2]=[0:bx*4+2]
;		/* phase 2*/
;		[es:di]=[0:bx*4]
;		[es:di+2]=[0:bx*4+2]
;		/* phase 2*/
;		[0:bx*4]=si-1;
;		[0:bx*4+2]=ds;

dummyvector proc near
	shl	bx,1			; bx <- bx*4
	shl	bx,1			; ie ,get offset of vector

; phase 1
; es --> 0
; es:bx --> cpu int vector table

	xor	ax,ax
	push	es
	mov	es,ax
	mov	ax,es:[bx]		; get offset  ds-->0
	mov	ds:[si],ax		; store  offset
	mov	ax,es:[bx+2]		; get offset  ds-->0
	mov	ds:[si+2],ax		; store segment
	pop	es

; phase 2
; ds --> 0
; ds:bx --> cpu int vector table

	xor	ax,ax
	push	ds
	mov	ds,ax
	mov	ax,ds:[bx]		; get offset
	mov	es:[di],ax		; store  offset
	mov	ax,ds:[bx+2]		; get offset
	mov	es:[di+2],ax		; store segment
	pop	ds

; phase 3
; es --> 0
; es:bx --> cpu int vector table

	xor	ax,ax
	push	es
	mov	es,ax
	dec	si
	mov	es:[bx],si
	mov	ax,ds
	mov	es:[bx+2],ax
	pop	es
	ret
dummyvector endp

; name : recovercsiint
; entry : none
; exit :none
; description :
;	recover int 9 ,10h,16h ,for csi vector

recovercsiint proc near
	push	es
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	di

;recover int 9

	cmp	cs:oemdriverinst,0
	jnz	ignoreint9recover

	push	cs
	pop	ds
	mov	si,offset dummyint9
	push	cs
	pop	es

	mov	di,offset csiint9
	mov	bx,9
	mov	ax,0
	call	recoverint
ignoreint9recover:

; recover int 10h

	push	cs
	pop	ds
	mov	si,offset dummyint10h
	push	cs
	pop	es
	mov	di,offset csiint10h
	mov	bx,10h
	mov	ax,0+4
	call	recoverint

;recover int 16h

	push	cs
	pop	ds
	mov	si,offset dummyint16h
	push	cs
	pop	es
	mov	di,offset csiint16h
	mov	bx,16h
	mov	ax,0+4+4
	call	recoverint
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	pop	es
	ret
recovercsiint endp

; name : recoverint
; entey : ds:si --> dummy int sevice routine
;	  es:di --> point to  csi vector store area
;	  bx  == int number
;	  ax  == 0	; int 9
;		 4	; int 10h
;		 4+4	; int 16h
; exit : none
; description :
;	  1. if( [0:bx*4] == si-1  .and.  [es:bx*4+2] == ds )
;	     {
;		 [0:bx*4]   = [es:di];
;		 [0:bx*4+2] = [es:di+2];
;	     }
;	     else
;	     {
;		 /* phase 1 */
;		 [ds:si]  = [(*orgvectblptr)+ax]
;		 [ds:si+2]= [(*orgvectblptr)+ax+2];
;		 /* phase 2 */
;		 [orgvectblptr+ax) ]=[0:bx*4] ;
;		 [orgvectblptr+ax+2 ]=[0:bx*4+2] ;
;		 /* phase 3 */
;		 [0:bx*4]   = [es:di];
;		 [0:bx*4+2] = [es:di+2];
;
;
;	     }

;

recoverint proc near
;chek vector change ?
; es --> 0

	push	es
	mov	cx,ax
	xor	ax,ax
	mov	es,ax
	shl	bx,1
	shl	bx,1			; es:bx --> cpu int vector
	mov	ax,si
	dec	ax
	cmp	es:[bx],ax		; offset same ?
	jne	vectorbechanged

	mov	ax,ds
	cmp	es:[bx+2],ax		; segmnet same ?
	jne	vectorbechanged
	pop	es

; vector not be changed
; ds --> 0

	xor	ax,ax
	mov	ds,ax			; ds:bx --> cpu int vector
	mov	ax,es:[di]
	mov	ds:[bx],ax
	mov	ax,es:[di+2]
	mov	ds:[bx+2],ax
	ret

vectorbechanged:

;phase 1
; di:es --> addres of local driver

	pop	es
	push	di
	push	es
	mov	di,word ptr cs:[orgvectblptr]
	mov	es,word ptr cs:[orgvectblptr+2]
	add	di,cx
	mov	ax,es:[di]
	mov	ds:[si],ax
	mov	ax,es:[di+2]
	mov	ds:[si+2],ax

;phase2
; di:es --> addres of local driver
; ds --> 0

	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,ds:[bx]		; ds:bx --> cpu int vector
	mov	es:[di],ax
	mov	ax,ds:[bx+2]
	mov	es:[di+2],ax
	pop	ds
	pop	es
	pop	di

;phase3
; ds --> 0

	xor	ax,ax
	push	ds
	mov	ds,ax
	mov	cx,es:[di]
	mov	ds:[bx],cx		; ds:bx --> cpu int vector
	mov	cx,es:[di+2]
	mov	ds:[bx+2],cx
	pop	ds
	ret

recoverint endp

;name : chklocalexist
;entry : none
;exit :none
; descriptin : check local driver exist ?
;		if not exist system halt !
;		otherwise null return

chklocalexist proc near
	push	ax
	push	cx
	push	dx
	mov	ah,0dbh
	mov	al,80h			; module_extsysutil
	mov	cx,01			; syscmd_extquerysysmode
	int	16h
	test	ax,8000h		; bit 15 on
	jnz	csisystemerror		; no,system halt
					; yes ,dx == country id
	push	dx			; save current id
	mov	dx,58h
	mov	ah,0dbh
	mov	al,80h			; module_extsysutil
	mov	cx,02			; syscmd_extsetsysmode
	int	16h
	test	ax,8000h		; bit 15 on
	jnz	localdrvnotfound	; no ,local driver error

	pop	cx
	cmp	cx,dx			; current id == previous id ?
	jnz	localdrvnotfound	; no ,local driver error

	pop	dx
	pop	cx
	pop	ax
	ret

localdrvnotfound:
csisystemerror:
	push	cs
	pop	ds
	mov	dx,offset bootfailmsg
	mov	ah,9
	int	21h
	cli
	hlt
	ret

	include	msbio.cl7		; bootfailmsg
chklocalexist endp
	endif


sysinitseg ends
end
