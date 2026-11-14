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
BYTE_SYSINIT equ 1

break	macro	; dummy empty macro
	endm

	.xlist
	include version.inc
	include biosseg.inc
	include	bpb.inc
	include bootform.inc
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
	extrn   eot:byte,ec35_flag:byte
	extrn   bootlog_device:word
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
	.386
	assume	cs:sysinitseg,ds:nothing,es:nothing

;	Reserve DOS, BIOS and compressed-image space, then relocate SYSINIT.
;
	public	MagicBackdoor,NullBackdoor

MagicBackdoor	dd	0

NullBackdoor	proc	far

	ret				; prevent hang with bogus backdoor

NullBackdoor	endp

	public	move_myself
move_myself:
	cld			; set up move
	xor	si,si
	mov	di,si

	mov	cx,cs:[memory_size]
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	[sysinit_memory_size],cx
	dec	cx
	cmp	[RPLMemTop],0
	je	short dos7_memory_ready
	mov	cx,[RPLMemTop]
	dec	cx
dos7_memory_ready:
	mov	ax,word ptr [SI_end+6]
	add	ax,15
	and	ax,0fff0h
	mov	[sysinit_extra_bytes],ax
	add	ax,offset SI_end+200h  ; reserve an additional 200h bytes
	.286
	shr	ax,4
	.8086
	sub	cx,ax

; we need to leave room for the DOS and (if not ROMDOS) for the BIOS
; code above sysinit in memory
;
	assume	ds:sysinitseg
	mov	ax,[dos_image_paras]
	cmp	ax,0a00h
	ja	short dos_reserve_ready
	mov	ax,0a00h
	mov	[dos_image_paras],ax
dos_reserve_ready:
	sub	cx,ax
	assume	ds:nothing

ifndef ROMDOS
	assume	ds:sysinitseg
	mov	ax,Bios_Code
	mov	es,ax
	assume	es:Bios_Code
	mov	ax,word ptr es:[BCode_end+6]
	add	ax,1fh
	and	ax,0fff0h
	mov	[bios_extra_bytes],ax
	add	ax,offset BCode_end
	.286
	shr	ax,4
	.8086
	sub	cx,ax
	assume	ds:nothing,es:nothing
endif ; ROMDOS

	push	cx
	push	di
	push	si
	call	boot_compressed_reserve
	pop	si
	pop	di
	pop	cx
	assume	ds:sysinitseg
	mov	[compressed_reserve],ax
	sub	cx,ax
	sub	[sysinit_memory_size],ax
	assume	ds:nothing
	mov	es,cx			; offset where sysinit will be located

	mov	cx,offset SI_end
	assume	ds:sysinitseg
	add	cx,[sysinit_extra_bytes]
	assume	ds:nothing
	shr	cx,1			;divide by 2 to get words
	rep	movsw			;relocate sysinit

	push	es			; push relocated segment
	mov	ax,offset sysin
	push	ax			; push relocated entry point

	retf				; far jump to relocated sysinit

	assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

	extrn	sysinit_msg_base:byte
	extrn	sysinit_msg_table:word
	public	print_indexed
	extrn   query_keyboard_service:near,query_check_skip:near,query_result:byte
	extrn	default_switch_char:byte,command_line2:byte,command_line3:byte
	extrn	boot_option_open:near
	extrn	boot_process_drivers:near
	extrn   boot_dos_file_table:word,boot_old_file_table:near
	extrn   boot_load_old_dos:near,boot_logo_display:near
	extrn   boot_start_old_dos:near,boot_old_image_seg:word,boot_exec_system:near,boot_previous_menu_check:near
	extrn   boot_windows_file_table:word
	extrn   check_low_memory:near
	extrn   boot_config_flags:byte,kbd_read:near
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
        extrn   config_cmd:byte
        extrn   config_envlen:word
        extrn   config_wrkseg:word
endif

	extrn	DevEntry:dword

	ifdef	dblspace_hooks
	extrn	MagicPreload:near
	extrn	MagicPostload:near
	extrn	MagicSetCdss:near
	endif

        extrn   crlfm:byte
	extrn	SI_end:byte
	extrn	condev:byte
	extrn	auxdev:byte
	extrn	prndev:byte
        extrn   commnd:byte, command_line:byte
	extrn	deviceparameters:byte
IFDEF	CONFIGPROC
	extrn	pathstring:byte			; this is not being referenced
ENDIF ; CONFIGPROC
	extrn   print:near,badmem:byte,badfil:near,showlinenum:near
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

        extrn   toomanydrivesmsg:byte				; M029

IFDEF	POWER
	extrn	Power_Init:near				; M072
ENDIF

	ifdef	dblspace_hooks
	endif


	if	stacksw 		; internal stack information
	endif

IFDEF	CONFIGPROC
	extrn	do_install_exec:near
ENDIF ; CONFIGPROC



extrn pararound:near,tempcds:near,endfile:near
sysinit$:
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



	extrn   dosinfo:dword
	extrn   dos_temp_location:dword
	extrn   dosinit:word
	extrn   sysinit_reserve_count:word
	extrn   current_dos_location:word
	extrn   device_list:dword
	extrn   sysi_country:dword
	extrn   dos_segreinit:word
	extrn   lo_doscod_size:word
	extrn   hi_doscod_size:word
	extrn   def_php:word
	extrn   disksector_pending_size:word
	extrn   temp_bcode_seg:word
	extrn   no_floppy_report:byte
	extrn   fake_floppy_drv:byte
	extrn   runhigh:byte
	extrn   dos_low_message:byte
	extrn   dos_umb_flag:byte
	extrn   exec_boot_state:byte
	extrn   sysinit_bios_start:word
	extrn   dos_image_size:word
	extrn   sysinit_bios_paras:word
	extrn   dos_image_paras:word
	extrn   sysinit_memory_size:word
	extrn   rpl_memory_size:word
	extrn   RPLMemTop:word
	extrn   default_drive:byte
	extrn   buffers:word
	extrn   h_buffers:word
	extrn   singlebuffersize:word
	extrn   files:byte
	extrn   fcbs:byte
	extrn   keep:byte
	extrn   num_cds:byte
	extrn   confbot:word
	extrn   alloclim:word
	extrn   top_of_cdss:word
	extrn   DirStrng:byte
	extrn   zero:byte
	extrn   sepchr:byte
	extrn   linecount:word
	extrn   showcount:byte
	extrn   buffer_linenum:word
	extrn   sys_model_byte:byte
	extrn   sys_scnd_model_byte:byte
	extrn   buf_prev_off:word
	extrn   default_num_cds:byte
ifdef COPYCDS
	extrn oldnum_cdss:word,newnum_cdss:word
endif

	extrn   bios_data_segment:word
	extrn   BCodeSeg:word
	extrn   boot_load_segment:word
	extrn   boot_reloc_offset:word
	extrn   boot_reloc_segment:word
	extrn   memory_size:word
	extrn   temp_buffer_segment:word
	extrn   temp_buffer_size:word
	extrn   boot_data_high:word
	extrn   boot_data_low:word

	extrn   boot_copy_buffer:byte  ; saved boot parameters and drive

        if      not NOEXEC
	extrn   comexe:byte
	endif

;------------------------------------------------------------------
;	variables for install= command.

	extrn   multi_pass_id:byte
	extrn   install_flag:byte
	extrn   config_size:word
	extrn   sysinit_base_ptr:dword
	extrn   sysinit_ptr:dword
	extrn   checksum:word
	extrn   ldexec_fcb:byte
	extrn   ldexec_line:byte
	extrn   ldexec_start:byte
	extrn   ldexec_parm:byte
	extrn   instexe:byte
	extrn   com_level:byte
	extrn   cmmt:byte
	extrn   cmmt1:byte
	extrn   cmmt2:byte
	extrn   cmd_indicator:byte
	extrn   donotshownum:byte
	extrn   count:word
	extrn   org_count:word
	extrn   chrptr:word
	extrn   cntryfilehandle:word
	extrn   old_area:word
	extrn   impossible_owner_size:word
have_install_cmd equ	00000001b	; config.sys has install= commands
has_installed	equ	00000010b	; sysinit_base installed.

;------------------------------------------------------------------

	extrn   area:word
	extrn   bucketptr:dword
	extrn   bufptr:dword
	extrn   memlo:word
	extrn   prmblk:word
	extrn   memhi:word
	extrn   ldoff:word
	extrn   drivenumber:byte
	extrn   boot_mode:byte


	extrn   toomanydrivesflag:byte
	extrn   boot_config_app:byte,boot_config_wos:byte,boot_msdos_status:byte
	extrn   config_device_table_ptr:dword
	extrn   new_psp_segment:word
	extrn   compressed_dest_segment:word,compressed_reserved_paras:word
	extrn   compressed_reserve:word ; paragraphs reserved for compression
	extrn   bios_extra_bytes:word
	extrn   sysinit_extra_bytes:word


	ifdef	dblspace_hooks
	endif


;
; Relocated SYSINIT entry: prepare disk descriptors and initialize DOS.
;

public sysin
sysin:
	assume	ds:nothing,es:nothing,ss:nothing
	push    di
	push    cs
	pop     ds
	assume  ds:sysinitseg
	push    cs
	pop     es
	mov     bx,offset dskdrvs
	mov     di,offset fdrive1-6
	sub     dx,dx
bds_prepare_next:
	inc     [bds_count]
	mov     word ptr [di+2],cs
	lea     ax,[di+6]
	mov     [bx],ax
	add     bx,2
	mov     ax,[di]
	cmp     ax,-1
	je      bds_prepare_done
	sub     ax,dx
	mov     si,ax
	sub     ax,di
	sub     ax,100
	jbe     bds_prepare_link
	add     dx,ax
	push    di
	add     di,100
	mov     cx,offset dskdrvs
	sub     cx,si
	rep     movsb
	pop     di
bds_prepare_link:
	sub     [di],dx
	mov     di,[di]
	jmp     short bds_prepare_next
bds_prepare_done:
	mov     ds,[bios_data_segment]
	assume  ds:Bios_Data
	mov     word ptr [start_bds+2],cs
	pop     di
	mov     word ptr [disksector_ptr],di
	mov     word ptr [disksector_ptr+2],es
	mov     cx,word ptr [BiosOld4F]
	mov     ax,word ptr [BiosOld4F+2]
	mov     word ptr [int4f_old],cx
	mov     word ptr [int4f_old+2],ax
	mov     si,offset int4f_entry
	or      ax,cx
	jnz     short int4f_vector_ready
	mov     si,offset intret
int4f_vector_ready:
	xor     ax,ax
	mov     es,ax
	cli
	mov     word ptr es:[4fh*4],si
	mov     word ptr es:[4fh*4+2],ds
	sti
	assume  ds:nothing


; first move the MSDOS.SYS image up to a harmless place 
; on top of our new sysinitseg

	mov     ax,offset SI_end+200h  ; temporary disk sector buffer
	add     ax,cs:[sysinit_extra_bytes]
	.286
	shr     ax,4
	.8086
	mov	cx,cs			; pick a buffer for msdos above us
	add	ax,cx
	mov	es,ax
	xor	si,si
	mov	di,si

	mov	ds,[current_dos_location] ; where it is (set by msinit)

	assume	ds:nothing

	mov     cx,cs:[dos_image_size]
	shr     cx,1
	rep     movsw
	adc     cx,cx
	rep     movsb
	mov	[current_dos_location],es

; The DOS code is ORGed at a non-zero value to allow it to be located in
; HIMEM.  Thus, the DOS segment location must be adjusted accordingly.
; If this is ROMDOS, however, only the init code is loaded into RAM, so
; this ORG is not done.  The entry point is at offset zero in the segment.

ifndef ROMDOS

	mov	ax,ds:word ptr 3	; get offset of dos
	mov	[dosinit],ax		; that's the entry point offset
	.286
	shr     ax,4
	.8086
	sub	[current_dos_location],ax
else
	mov	[dosinit], 0		; entry to init is at zero

endif ; ROMDOS


; If this is not ROMDOS, then the BIOS code is moved to the top of memory
; until it is determined whether it will be running in HIMEM or not.

ifndef ROMDOS

; now put Bios_Code up on top of that.  Assume Bios_Code + dossize < 64k

	mov	ax,es
	add     ax,cs:[dos_image_paras]
	mov     es,ax
	mov     ds,cs:[BCodeSeg]
	assume  ds:nothing
	mov     si,offset BCode_start
	mov     di,si
	mov     cx,offset BCode_end
	add     cx,cs:[bios_extra_bytes]
	sub     cx,si
	shr     cx,1
	rep     movsw
	mov     cs:[temp_bcode_seg],ax
	call    reinit_bios_code
; Place the boot image in the reserved space following the BIOS.
	mov     ax,di
	call    pararound
	mov     di,es
	add     di,ax
	mov     cs:[compressed_dest_segment],di
	mov     cx,cs:[compressed_reserve]
	mov     cs:[compressed_reserved_paras],cx
	mov     cx,cs:[boot_load_segment]
	jcxz    boot_move_done
	cmp     cx,cs:[compressed_reserve]
	ja      boot_move_done
	sub     si,si
	mov     ds,cs:[boot_reloc_segment]
	mov     es,di
	sub     di,di
	mov     cs:[boot_reloc_segment],es
	mov     ax,cx
boot_move_block:
	mov     cx,1000h
	cmp     cx,ax
	jb      short boot_move_size_ready
	mov     cx,ax
boot_move_size_ready:
	sub     ax,cx
	.286
	shl     cx,3
	.8086
	rep     movsw
	mov     cx,ds
	add     cx,1000h
	mov     ds,cx
	mov     cx,es
	add     cx,1000h
	mov     es,cx
	test    ax,ax
	jnz     boot_move_block
boot_move_done:

endif	; not ROMDOS

	mov     ds,cs:[BCodeSeg]       ; install temporary HMA callback
	assume  ds:Bios_Code
	mov     word ptr [sysinit_seg],cs
	mov     word ptr [hma_init_ptr],offset FTryToMovDOSHi
	mov     word ptr [hma_init_ptr+2],cs
	mov     ax,Bios_Data
	mov     ds,ax
	assume  ds:Bios_Data
	or      byte ptr [bios_flags+1],80h ; config allocation active

;	now call dosinit while it's in its temporary home

	cli
	mov     ax,cs
	mov     ss,ax
	mov     sp,offset locstack
	nop
locstack label byte
	sti
; Prepare the DOS initialization workspace below the boot sector.
	sub     ax,ax
	mov     es,ax
	mov     di,600h
	push    di
	mov     cx,80h
	rep     stosw
	pop     di
	mov     cx,5
dosinit_con_entry:
	mov     ax,4f43h
	stosw
	mov     ax,204eh
	stosw
	add     di,37h
	loop    dosinit_con_entry
	lds     si,cs:[device_list]
	mov     dx,cs:[memory_size]


; This call to DOSINIT will relocate the DOS data from its present location
; at the top of memory, to its final location in low memory just above the
; BIOS data.  It will then build important DOS data structures in low 
; memory following the DOS data.  It returns (among many other things) the
; new starting address of free memory.

	mov     bx,Bios_Data
	mov     ax,0505h
	call	[dos_temp_location]	; call dosinit
	mov     word ptr cs:[config_access_table],bx
	mov     word ptr cs:[config_access_table+2],es
					;es:di -> sysinitvars_ext

	mov	[def_php],ds		; save pointer to PSP
	mov	[hi_doscod_size],ax	; size of doscode (including exepatch)
	mov	[lo_doscod_size],cx	; (not including exepatch)
	mov	[dos_segreinit],dx	; save offset of segreinit

	mov	ax,word ptr es:[di.sysi_initvars]
	mov	word ptr dosinfo,ax
	mov	ax,word ptr es:[di.sysi_initvars+2]
	mov	word ptr [dosinfo+2],ax ;set the sysvar pointer

	mov	ax,word ptr es:[di.sysi_country_tab]
	mov	word ptr [sysi_country],ax
	mov	ax,word ptr es:[di.sysi_country_tab+2]
	mov	word ptr [sysi_country+2],ax ;set the sysi_country pointer

	mov     ax,cs:[current_dos_location]
	mov     cs:[dos_segreinit+2],ax
	add     bx,20h
	mov     word ptr cs:[config_device_table_ptr],bx

; Initialize the localized responses used by SYSINIT and DOS.
	mov     ah,GET_IN_VARS
	int     21h
	les     bx,es:[bx+12h]
	mov     bx,es:[bx+13h]
	push    bx
	mov     bx,es:[bx+6]
	mov     si,offset sysinit_msg_base
	add     si,cs:[sysinit_msg_table+46]
	mov     al,cs:[si]
	mov     cs:[query_yes],al
	mov     es:[bx],al
	mov     al,cs:[si+3]
	mov     cs:[query_yes_lower],al
	mov     es:[bx+2],al
	mov     al,cs:[si+1]
	mov     cs:[query_no],al
	mov     es:[bx+1],al
	mov     al,cs:[si+4]
	mov     cs:[query_no_lower],al
	mov     es:[bx+3],al
	mov     al,cs:[si+2]
	mov     cs:[query_all_char],al
	mov     al,cs:[si+5]
	mov     cs:[query_all_lower],al
	pop     bx
	mov     bx,es:[bx+8]
	mov     word ptr es:[bx],offset Bios_Data:bios_error_entry
	mov     word ptr es:[bx+2],seg bios_error_entry
;
;M056 - BEGIN
;
;------ Cover up RPL code with an arena
;
	cmp	cs:RPLMemTop, 0
	je	NoRPLArena
;
;------ alloc all memory
;
	mov	bx, 0ffffh
	mov	ah, 48h
	int	21h
	mov	ah, 48h
	int	21h

	mov	es, ax				; get it into Es and save it
	push	es
;
;------ resize upto RPL mem
;
	sub	ax, cs:RPLMemTop
	neg	ax
	dec	ax
	mov	bx, ax
	mov	ah, 4ah
	int	21h
;
;------ allocate the free (RPL MEM)
;
	mov	bx, 0ffffh
	mov	ah, 48h
	int	21h
	mov	ah, 48h
	int	21h
;
;----- mark that it belongs to RPL
;
	dec	ax
	mov	es, ax
	mov	word ptr es:[arena_owner], 8
	mov	word ptr es:[arena_name], 'PR'
	mov	word ptr es:[arena_name+2], 'L'
	mov	word ptr es:[arena_name+4], 0
	mov	word ptr es:[arena_name+6], 0

        pop     es                      ; get back ptr to first block
        mov     ah, Dealloc             ; and free it
	int	21h
NoRPLArena:
;
;M056 - END
;
	les	di,dosinfo		;es:di -> dosinfo

	clc				;get the extended memory size

;	execute the get extended memory size subfunction in the bios int 15h
;	if the function reports an error do nothing else store the extended
;	memory size reported at the appropriate location in the dosinfo buffer
;	currently pointed to by es:di.	use the offsets specified in the
;	definition of the sysinitvars struct in inc\sysvar.inc


	mov	ah,88h
	int	15h			;check extended memory size
	jc	no_ext_memory
	mov	es:[di].sysi_ext_mem,ax ;save extended memory size
	or	ax, ax
	jz	no_ext_memory
	call	ClrVDISKHeader
no_ext_memory:
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	ax,es:[di.sysi_maxsec]	; get the sector size
	add	ax,bufinsiz		; size of buffer header
	mov	[singlebuffersize],ax	; total size for a buffer

	mov	al,default_drive	; get the 1 based boot drive number set by msinit
	mov	es:[di.sysi_boot_drive],al ; set sysi_boot_drive

; Reserve space for the PSP and device records below SYSINIT.

	mov     ax,cs
	sub     ax,11h                  ; room for PSP
	sub     ax,111h                 ; device record buffer
	mov     word ptr [config_record_ptr+2],ax
	push    ax
	mov     al,es:[di.sysi_numio]
	mov     drivenumber,al
	pop     ax
; Allocate and link the temporary DOS disk buffers.
	mov     cx,[temp_buffer_size]
	.286
	shr     cx,4
	.8086
	inc     cx
	sub     ax,cx
	mov     [top_of_cdss],ax
	push    es
	push    di
	mov     [temp_buffer_segment],ax
	mov     cx,ax
	sub     ax,((26 * (size curdir_list)) + 15)/16
	mov     [alloclim],ax
	mov     [confbot],ax
	lds     si,es:[di.sysi_buf]
	assume  ds:nothing
	mov     word ptr [si.Dirty_Buff_Count],0
	mov     word ptr [si.Buff_Queue],0
	mov     word ptr [si.Buff_Queue+2],cx
	mov     ds,cx
	xor     si,si
	mov     ax,cs:[temp_buffer_size]
	sub     dx,dx
	mov     bx,cs:[singlebuffersize]
	div     bx
	xchg    ax,cx
temp_buffer_loop:
	mov     [si.buf_next],bx
	mov     [si.buf_prev],dx
	mov     word ptr [si.buf_id],00ffh
	mov     word ptr [si.buf_sector],0
	mov     word ptr [si.buf_sector+2],0
	mov     dx,si
	mov     si,bx
	add     bx,cs:[singlebuffersize]
	loop    temp_buffer_loop
	mov     bx,dx
	mov     [bx.buf_next],cx
	mov     word ptr ds:[2],bx

	push	cs
	pop	ds

	assume	ds:sysinitseg

ifdef	COPYCDS
	mov	al, 1			; ask tempcds to build CDSs from
					;  scratch
endif ; COPYCDS

	call	tempcds 		; set up cdss so re_init and sysinit
					;   can make disk system calls

	call    config_record_interrupts
	call    config_record_boot_int13
	lds     bx,cs:[dosinfo]
	lds     bx,[bx].sysi_dpb
	lds     bx,[bx].dpb_driver_addr
	mov     al,cs:[drivenumber]
	call    config_record_device
	assume	ds:nothing		; tempcds trashes ds

	mov	ds,[def_php]		; retreive pointer to PSP returned by DOSINIT


	sti				; ints ok
	cld				; make sure

; dosinit has set up a default "process" (php) at ds:0. we will move it out
; of the way by putting it just below sysinit at end of memory.

	mov	bx,cs
	sub	bx,10h
	mov	es,bx
	xor	si,si
	mov	di,si
	mov	cx,80h
	rep	movsw

	mov	word ptr es:[pdb_jfn_pointer + 2],es ; relocate
	mov     cs:[new_psp_segment],bx
	mov     ah,set_current_pdb
	int     21h
	mov     ds,bx
	mov     dx,80h
	mov     ah,set_dma
	int     21h

	push	cs
	pop	ds			; point DS to sysinitseg

	assume	ds:sysinitseg

	; set up temp. critical error handler
	mov	dx,offset int24 	;set up int 24 handler
	mov	ax,(set_interrupt_vector shl 8) or 24h
	int	21h

        cmp     byte ptr [TooManyDrivesFlag],0  ;Q: >24 partitions? M029
        je      no_err                          ;  N: continue      M029
	call    print_indexed
	dw      8012h
no_err:						;		    M029

	assume  ds:sysinitseg

	mov	dl,[default_drive]
	or	dl,dl
	jz	nodrvset		; bios didn't say
	dec	dl			; a = 0
	mov	ah,set_default_drive
	int	21h			;select the disk

nodrvset:
	mov     ax,[def_php]
	mov     [memhi],ax
	mov     ax,(char_oper shl 8)
	int     21h
	mov     [default_switch_char],dl
	mov     [command_line+2],dl
	mov     [command_line2+2],dl
	mov     [command_line3+2],dl
	sub     dx,dx
	call    boot_option_open
; Select the startup message and detect a restart into MS-DOS mode.
	test    byte ptr [boot_runtime_flags],10h
	jnz     boot_intro_done
boot_intro_retry:
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+4]
	mov     dx,offset boot_config_app
	mov     ax,4300h
	int     21h
	jnc     boot_intro_print
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+2]
	mov     dx,offset boot_config_wos
	mov     ax,4300h
	int     21h
	jnc     boot_intro_dos_mode
	mov     dx,offset boot_msdos_status
	mov     ax,4300h
	int     21h
	jnc     boot_intro_dos_mode
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table]
	test    byte ptr [boot_runtime_flags],1
	jnz     boot_intro_print
	cmp     word ptr [boot_delay],0
	je      boot_intro_done
	jmp     short boot_intro_print
boot_intro_dos_mode:
	mov     byte ptr [boot_mode],1
	or      byte ptr [boot_runtime_flags],1
boot_intro_print:
	mov     dx,bx
	call    print
	cmp     byte ptr [boot_mode],1
	jne     boot_intro_done
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+6]
	call    print
	shl     word ptr [boot_delay],1
boot_intro_done:
	mov     bx,offset boot_dos_file_table
	call    boot_old_file_table
	call    kbd_read
	test    byte ptr [query_mode_flags],1
	jnz     short boot_show_startup_logo
	mov     al,[boot_runtime_flags]
	and     al,10h
	xor     [boot_config_flags],al
	test    byte ptr [boot_config_flags],10h
	jnz     short boot_load_previous_dos
	test    al,al
	jz      short boot_show_startup_logo
	and     byte ptr [boot_runtime_flags],0efh
	jmp     boot_intro_retry
boot_load_previous_dos:
	call    boot_load_old_dos
	jmp     short boot_startup_choice_done
boot_show_startup_logo:
	sub     dx,dx
	call    boot_logo_display
boot_startup_choice_done:

;
; Process the CONFIG.SYS file 
;
ifdef ROMDOS

	; see if we need to skip CONFIG.SYS processing

	push	ds			; preserve current DS
	mov	ax, Bios_Data		; get bios data segment
	mov	ds, ax			; point ds to bios data
	assume	ds:Bios_Data

	mov	ax, BootFlags		; get boot flags
	test	ax, BF_NoConfig		; is no config bit set?
	pop	ds			; restore former DS
	assume	ds:nothing
	jz	ProcessConfig		; no, process config.sys

	; Skip config.sys processing

;M072 BEGIN
ifdef POWER
; No Config.sys to be processed
; initialise POWER 

	call	Power_Init

endif
;M072 END

        mov     ax,(char_oper shl 8)    ; get switch character
	int	21h
	mov	[command_line+1],dl	; set in default command line

	call	AllocFreeMem		; allocate free memory
	call	endfile			; setup fcbs, files, buffers etc

	jmp	short ConfigDone

endif ; ROMDOS

	
ProcessConfig:
	mov     [boot_load_segment],0

	ifdef	dblspace_hooks
	mov     word ptr [MagicBackdoor],offset NullBackdoor
	mov     word ptr [MagicBackdoor+2],cs

	call	AllocFreeMem		; get the largest free block from DOS
	call	MagicPreload		; **** PRE-LOAD MAGICDRV!!! ****
	jnz	short PreloadFailed

	mov	es,cs:[area]
	mov	bx,cs:[memhi]
	sub	bx,cs:[area]		; get desired block size in paras
	mov	ah,setblock
	int	21h
	mov	ax,es
	dec	ax
	mov	es,ax			; point to arena
	mov	es:[arena_owner],8	;set impossible owner
	mov	word ptr es:[arena_name], 'DS'	; System Data

;	BUGBUG -- 3 Aug 92 -- chuckst -- Device drivers like PROTMAN$ (part
;					 of Microsoft's networking products)
;					 assume that their arena is the first
;					 one.  Therefore, we must remove
;					 MagicDrv from the arena list.  The
;					 problem with this is that MagicDrv's
;					 stub will not show up in a MEM
;					 listing.

	mov	ax,es			; get Magicdrv arena
	add	ax,es:word ptr [3]	; get MCB length
	inc	ax			; get addr of next MCB
	les	si,cs:dosinfo		; get to arena header
	mov	es:word ptr [si-2],ax	; store that
	inc	ax
	mov	cs:[memhi],ax
	call	check_low_memory
	test	byte ptr cs:[query_mode_flags],9
	jnz	short preload_no_logo
	sub	dx,dx
	call	boot_logo_display
preload_no_logo:
	mov	bx,offset boot_dos_file_table
	call	boot_old_file_table
	push	ds
	mov	ds,cs:[BCodeSeg]
	assume	ds:Bios_Code
	or	byte ptr [win386_info_flags],10h
	pop	ds
	assume	ds:sysinitseg

	jmp	short PreloadCommon

PreloadFailed:
	mov	ah,Dealloc		; free the block if no load
	mov	es,cs:[area]
	int	21h

PreloadCommon:
	endif

	push    cs
	pop     ds
	assume  ds:sysinitseg
	call    boot_start_old_dos
	cmp     byte ptr [boot_mode],2
	jne     short sysinit_previous_done
	mov     word ptr [boot_old_image_seg],0
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+84]
	mov     byte ptr [bx],'$'
	mov     bx,offset boot_windows_file_table
	call    boot_old_file_table
sysinit_previous_done:

; Use the initialization stack space already passed before running the
; optional system file.  Restore the DTA and startup display afterwards.
	mov     sp,offset sysinit_exec_start
	nop
	public	sysinit_exec_start
sysinit_exec_start:
	mov     al,[query_mode_flags]
	and     al,0dh
	cmp     al,1
	je      short sysinit_exec_done
	call    boot_exec_system
	mov     ds,cs:[new_psp_segment]
	assume  ds:nothing
	mov     dx,80h
	mov     ah,set_dma
	int     21h
	mov     ax,Bios_Data
	mov     ds,ax
	assume  ds:Bios_Data
	cmp     int16_count,-1
	je      short sysinit_exec_done
	test    byte ptr [bios_flags+1],20h
	jnz     short sysinit_exec_done
	mov     int16_count,0
	mov     dx,1
	call    boot_logo_display
sysinit_exec_done:
	push    cs
	pop     ds
	assume  ds:sysinitseg
sysinit_exec_ready:

; Restore the DOS startup flag when a system file did not handle it,
; then select the previous startup menu if appropriate.
	cmp     byte ptr [exec_boot_state],1
	je      short sysinit_check_menu
	test    byte ptr [query_mode_flags],1
	jnz     short sysinit_check_menu
	mov     ah,GET_IN_VARS
	int     21h
	and     byte ptr es:[bx+60h],0bfh
sysinit_check_menu:
	or      byte ptr [boot_runtime_flags],80h
	call    boot_previous_menu_check
sysinit_menu_checked:

; Ask before enabling the startup option when it is still undecided.
	push    ds
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	cmp     byte ptr [exec_bios_word-1],2
	pop     ds
	assume  ds:sysinitseg
	jne     short sysinit_config_prescan
	and     byte ptr [query_mode_flags],0bfh
	mov     byte ptr [config_cmd],1
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+70]
	xor     al,al
	call    query_check_skip
	adc     al,0
	sub     al,[query_result]
	jne     short sysinit_store_option
	push    ax
	mov     ax,3305h
	int     21h
	pop     ax
	cmp     dl,3
	jnc     short sysinit_store_option
	mov     al,1
sysinit_store_option:
	mov     ds,[BCodeSeg]
	assume  ds:Bios_Code
	mov     byte ptr [exec_bios_word-1],al
sysinit_config_prescan:
	assume  ds:nothing

ifndef	TAIWAN

IFDEF	CONFIGPROC
	call	doconf			;do pre-scan for dos=high/low
ELSE
	mov	ax,(char_oper shl 8)	;get switch character
	int	21h
	mov	[command_line+1],dl	; set in default command line

ENDIF ; CONFIGPROC

else	; taiwan

	call	chkoemlocaldrv
	mov	cs:oemdriverinst,ax
	call	cdosinit
	push	es
	push	bx

	pop	bx
	pop	es
	call	maketempvector		;make dummy int service routine

	call	doconf			;do pre-scan for dos=high/low

	call	chklocalexist		;check if local dev drv exist
					;if not found,system halt
	call	recovercsiint		;recover csi interrupt vector
endif	; taiwan

	public  sysinit_umb_defaults
sysinit_umb_defaults:
	push    cs
	pop     ds
	assume  ds:sysinitseg
	cmp     byte ptr [dos_umb_flag],0
	je      umb_defaults_done
	mov     al,1
	mov     [p_buffers_high],al
	mov     [p_ldrv_high],al
	mov     [p_fcbs_high],al
	mov     [p_files_high],al
	mov     [stack_high],al
	mov     byte ptr [files],30
	mov     word ptr [fcbs],4       ; also clears KEEP
	mov     al,[default_num_cds]
	mov     [num_cds],al
umb_defaults_done:

; Now, if this is not romdos, we decide what to do with the DOS code.
; It will either be relocated to low memory, above the DOS data structures,
; or else it will be located in HiMem, in which case a stub with the DOS
; code entry points will be located in low memory.  Dos_segreinit is used
; to tell the DOS data where the code has been placed, and to install the
; low memory stub if necessary.  If the DOS is going to go into HiMem, we
; must first initialize it in its present location and load the installable
; device drivers.  Then, if a HiMem driver has been located, we can actually
; relocate the DOS code into HiMem.
;
; For ROMDOS, if DOS=HIGH is indicated, then we need to call dos_segreinit
; to install the low memory stub  (this must be done before allowing any
; device drivers to hook interrupt vectors).  Otherwise, we don't need to 
; call dos_segreinit at all, since the interrupt vector table has already 
; been patched.

; M025 begin

	cmp	runhigh, 0		; Did user choose to run low ?
	je	dont_install_stub	; yes, don't install dos low mem stub
;
;------ user chose to load high
;

ifndef ROMDOS

	mov	es,[current_dos_location]	; give dos its temporary loc.

else

	mov	ax, Bios_Data		; get bios data segment
	mov	es, ax			; point es to bios data
	assume	es:Bios_Data
	mov	es, [DOS_Res]		; get DOS resident code segment
	assume	es:nothing

endif ; ROMDOS

	xor	ax,ax				; ax = 00 ---> install stub
	call	dword ptr [dos_segreinit]	; call dos segreinit
	jmp	short do_multi_pass
	
;
;------ User chose to load dos low
;
dont_install_stub:

ifndef ROMDOS
	xor	bx, bx			; M012
					;  don't use int 21 call to alloc mem

	call	MovDOSLo		; move it !


	mov	ax, 1			; dont install stub
	mov	es, cs:current_dos_location; set_dos_final_position set it up
	call	cs:dword ptr dos_segreinit	; inform dos about new seg

endif ; ROMDOS

do_multi_pass:

; M072 BEGIN
ifdef POWER
; If DOS=HIGH was specified, stubs for int 2f would have already been loaded
; by now and so it safe to initialise POWER.
; It is done here so that POWER hooks int 2f after DOS puts its int2f stub
; and before any other CONFIG.SYS device/tsr hooks int 2f.

	call	Power_Init

endif
; M072 END

	call	AllocFreeMem		; allocate all the free mem
					;  & update [memhi] & [area]
					; start of free memory.

	ifdef	dblspace_hooks
	mov	bx,0			; magic backdoor to place int hooks
	call	cs:MagicBackdoor
	endif

	call    boot_record_compressed_boot

	mov     ax,4a16h
	int     2fh
	test    byte ptr cs:[query_mode_flags],1
	jnz     short skip_ebda_recovery
	call    recover_ebda
skip_ebda_recovery:

; M025 end

IFDEF	CONFIGPROC
; Now, process config.sys some more.  
; Load the device drivers and install programs

	inc	cs:multi_pass_id	; multi_pass_id = 1
	call	multi_pass		; process configuration options
	inc	cs:multi_pass_id	; multi_pass_id = 2
	call    boot_process_drivers   ; built-in startup drivers
	mov     ax,4a18h
	int     2fh

ENDIF ; CONFIGPROC

	ifdef	dblspace_hooks
	call	MagicPostload		; make sure Magicdrv is final placed
	endif

	call	endfile			; setup fcbs, files, buffers etc
	call    boot_prepare_shell
	call    boot_prepare_environment

	ifdef	dblspace_hooks
	call	MagicSetCdss		; disable CDSs of reserved drives
	endif
IFDEF CONFIGPROC
	call    ShrinkUMB
	call    UnlinkUMB
ENDIF

;
; End configuration allocation and restore the resident HMA callback before
; running installed programs.
;
	mov     es,cs:[BCodeSeg]
	assume  es:Bios_Code
	mov     word ptr es:[hma_init_ptr],offset bc_retf
	mov     word ptr es:[hma_init_ptr+2],es
	mov     es,cs:[bios_data_segment]
	assume  es:Bios_Data
	and     byte ptr es:[bios_flags+1],7fh

IFDEF	CONFIGPROC
	test	cs:[install_flag],have_install_cmd ; are there install commands?
	jz	dolast			; no, no need for further processing
	inc	cs:multi_pass_id	; mult_pass_id = 3
	call	multi_pass		; execute install= commands
ENDIF ; CONFIGPROC

dolast:
	assume	es:nothing

; [area] has the segment address for the allocated memory of sysinit, confbot.
;  free the confbot area used for config.sys and sysinit itself.


; Now if DOS is supposed to run high, we actually move it into high memory 
; (if HiMem manager is available).  For ROMDOS, we don't actually move
; anything, but just set up the ROM area for suballocation (or print
; a message if HiMem is not available).
;
; There is also this little hack for CPM style DOS calls that needs to
; be done when A20 is set...

	call	LoadDOSHiOrLo

; We are now done with CONFIG.SYS processing

ConfigDone:

	mov	cs:[donotshownum],1	; done with config.sys. do not show line number message.
	mov	es,cs:[area]

	assume	es:nothing

        mov     ah,Dealloc              ; free allocated memory for command.com
	int	21h

	test	cs:[install_flag],has_installed ; sysinit_base installed?
	jz	skip_free_sysinitbase	; no.

;set block from the old_area with impossible_owner_size.
;this will free the unnecessary sysinit_base that had been put in memory to
;handle install= command.

	mov	es,cs:[old_area]
	mov	bx,cs:[impossible_owner_size]
	mov	ah,setblock
	int	21h
	mov	ax,es
	dec	ax
	mov	es,ax			;point to arena
	mov	es:[arena_owner],8	;set impossible owner
	mov	word ptr es:[arena_name], 'DS'	; System Data

skip_free_sysinitbase:

	cmp	cs:[runhigh], 0
	je	@f
	call	InstVDiskHeader		; Install VDISK header (allocates some mem from DOS)
@@:

	push	cs
	pop	ds
	assume	ds:sysinitseg
	jmp	boot_shell_main

; Display the line number saved in AX.
	public	show_line_number
show_line_number proc near
	mov	cs:[linecount],ax
	mov	al,'$'
	xchg	al,cs:[showcount+5]
	push	ax
	call	showlinenum
	pop	ax
	mov	cs:[showcount+5],al
	ret
show_line_number endp

; Recover unused space following a relocated extended BIOS data area.
	.286
	public  recover_ebda
recover_ebda proc near
	push    cs
	pop     ds
	cmp     [config_ebda_limit],-1
	je      short ebda_abort
	mov     ax,40h
	mov     es,ax
	mov     cx,es:[0eh]
	stc
	jcxz    ebda_abort
	cmp     ch,98h
	jae     short ebda_check_bios
ebda_abort:
	jmp     ebda_done
ebda_check_bios:
	mov     ah,0c1h
	stc
	int     15h
	jc      short ebda_check_memory
	mov     ax,es
	cmp     ax,cx
	jne     ebda_abort
ebda_check_memory:
	int     12h
	shl     ax,6
	cmp     ax,cx
	jne     ebda_abort
	mov     dx,0a000h
	sub     dx,cx
	shl     dx,4
	cmp     dx,400h
	ja      ebda_abort
	jne     short ebda_use_all
	mov     bx,cs:[config_ebda_limit]
	cmp     bx,dx
	jae     short ebda_use_all
	mov     es,cx
	mov     di,bx
	mov     cx,dx
	sub     cx,di
	cld
	xor     al,al
	repe    scasb
	je      short ebda_allocate
ebda_use_all:
	mov     bx,dx
ebda_allocate:
	push    bx
	push    dx
	shr     bx,4
	mov     ax,bx
	mov     bx,5200h
	call    alloc_marked_block
	pop     dx
	pop     bx
	cli
	push    ds
	mov     ax,40h
	mov     ds,ax
	mov     es,cx
	xchg    cx,word ptr ds:[0eh]
	mov     ds,cx
	mov     cx,bx
	xor     si,si
	xor     di,di
	cld
	rep     movsb
	mov     cx,ds
	pop     ds
	sti
	mov     bx,es
	xor     di,di
	mov     es,di
	dec     di
	dec     di
ebda_vector_next:
	add     di,4
	cmp     di,200h
	ja      short ebda_find_arena
	cmp     es:[di],cx
	jne     ebda_vector_next
	cmp     di,0c2h
	je      ebda_vector_next
	cmp     di,0c6h
	je      ebda_vector_next
	mov     es:[di],bx
	jmp     short ebda_vector_next
ebda_find_arena:
	mov     ax,cs:[area]
	dec     ax
ebda_arena_next:
	mov     es,ax
	inc     ax
	add     ax,es:[arena_size]
	cmp     byte ptr es:[arena_signature],arena_signature_end
	jne     ebda_arena_next
	cmp     ax,cx
	jne     short ebda_done
	shr     dx,4
	add     es:[arena_size],dx
	shr     dx,6
	mov     ax,40h
	mov     es,ax
	add     es:[13h],dx
	mov     es,cs:[BCodeSeg]
	mov     es:[5f8h],dx
ebda_done:
	ret
recover_ebda endp
	.8086

;----------------------------------------------------------------------------
; procedure : AllocFreeMem
;
; Allocate Max memory from DOS to find out where to load DOS.
; DOS is at temporary location when this call is being made
;
; Inputs : None
; Outputs: The biggest chunk of memory is allocated (all mem at init time)
;	   [area] & [memhi] set to the para value of the start of the
;	   free memory.
;
; Uses   : AX, BX
;
;----------------------------------------------------------------------------
;
	public	AllocFreeMem
AllocFreeMem	proc	near

	assume	es:nothing, ds:nothing
	mov	bx,0ffffh
	mov	ah,alloc
	int	21h			;first time fails
	mov	ah,alloc
	int	21h			;second time gets it
	jc      short alloc_free_done
	mov     cs:[area],ax
	mov     cs:[memhi],ax
	call    check_low_memory
alloc_free_done:
	ret
					; start of free memory
AllocFreeMem	endp


;
;----------------------------------------------------------------------------
;
; procedure : LoadDOSHiOrLo
;
;		Tries to move DOS into HMA. If it fails then loads
;		DOS into Low memory.  For ROMDOS, nothing is actually
;		moved; this just tries to allocate the HMA, and prints
;		a message if this is not possible.
;
;----------------------------------------------------------------------------
;

	public	LoadDOSHiOrLo
LoadDOSHiOrLo	proc	near
	cmp	cs:[runhigh],0ffh
	jne	short load_high_done
	call	TryToMovDOSHi			; Try moving it into HMA (M024)
	jc	LdngLo				; If that don't work...
load_high_done:
	ret
LdngLo:
	push	cs
	pop	ds
	cmp	cs:[dos_low_message],0
	je	short load_low_silent
	call	print_indexed
	dw	8036h
load_low_silent:

ifndef ROMDOS
	; actually move the dos, and reinitialize it.

	mov	bx, 1				; M012
						;  use int 21 alloc for mem
	call	MovDOSLo
	mov	es,cs:[current_dos_location]	; give dos its temporary loc.
	xor	ax,ax				; ax = 00 ---> install stub
	call	cs:dword ptr [dos_segreinit]	; call dos segreinit
endif ; ROMDOS

	mov	cs:[runhigh], 0			; mark that we are running lo
	ret
LoadDOSHiOrLo	endp


;
;----------------------------------------------------------------------------
;
; procedure : TryToMovDOSHi
;
;		This tries to move DOS into HMA.
;		Returns CY if it failed.
;		If it succeeds returns with carry cleared.
;
;		For ROMDOS, dos_segreinit must be called again to allow
;		the A20 switching code in the low mem stub to be installed.
; 
;----------------------------------------------------------------------------
;

		public	TryToMovDOSHi

TryToMovDOSHi	proc	near
	cmp	cs:[runhigh],1
	jbe	ttldhx
	call	MovDOSHi
	jc	ttldhx

ifndef ROMDOS

	mov	es,[current_dos_location]	; give dos its temporary loc.

else

	mov	ax, Bios_Data		; get bios data segment
	mov	es, ax			; point es to bios data
	assume	es:Bios_Data
	mov	es, [DOS_Res]		; get DOS resident code segment
	assume	es:nothing

endif ; ROMDOS

	xor	ax,ax				; ax = 00 ---> install stub
	call	cs:dword ptr [dos_segreinit]	; call dos segreinit

	mov	runhigh, 1
	call	CPMHack
	clc
ttldhx:
	ret
TryToMovDOSHi	endp


;
;----------------------------------------------------------------------------
; procedure : FTryToMovDOSHi
;
;		Called from HMA suballoc calls
;	
;----------------------------------------------------------------------------
;
;

		public	FTryToMovDOSHi
FTryToMovDOSHi	proc	far
	.286
	pusha
	push    ds
	push    es
	call    TryToMovDOSHi
	pop     es
	jc      short ftry_hma_done
	mov     ax,0ffffh
	mov     es,ax
ftry_hma_done:
	pop     ds
	popa
	ret
	.8086
FTryToMovDOSHi	endp

;----------------------------------------------------------------------------
;
; procedure : MovDOSHi
;
;		Tries to allocate HMA and Move DOS/BIOS code into HMA
;		For ROMDOS, the code is not actually moved, but the
;		HMA is allocated and prepared for sub-allocation.
;
;		Returns : CY if it failed
;
;----------------------------------------------------------------------------
;

MovDOSHi	proc	near
	call	AllocHMA
	jc	mdhx				; did we get HMA?
	mov	bx,offset BCode_End-10h
	add	bx,cs:[bios_extra_bytes]
	db	81h,0ebh,40h,0		; sub bx,40h
	mov	cx,0ffffh
	mov	dl,0
	mov	bp,offset Bios_Code:hma_allocate
	call	query_bios_call
	mov	ax, 0ffffh			; yes, HMA seg = 0ffffh
	mov	es, ax

ifndef ROMDOS
	; actually move the BIOS and DOS

	call	MovBIOS				; First move BIOS into HMA

	; ES:DI points to free HMA after BIOS

	mov	bx,cs:[hi_doscod_size]
	mov	cx,0fffdh
	mov	dl,0
	push	bx
	mov	bp,offset Bios_Code:hma_allocate
	call	query_bios_call
	pop	cx
	call	MovDOS
	mov	es:[di-0eh],bx
	call	config_xms_init

	; ES:DI points to free HMA after DOS
else
	; allocate space at beginning of HMA to allow for CPMHack

	mov	di, 0E0h			; room for 5 bytes at ffff:d0

endif ; ROMDOS

	clc
mdhx:
	ret
MovDOSHi	endp


;
;----------------------------------------------------------------------------
;
; procedure : MovDOSLo
;
;		Allocates memory from DOS and moves BIOS/DOS code into it
;
;----------------------------------------------------------------------------
;

ifndef ROMDOS

	public  MovDOSLo
MovDOSLo	proc	near
	call	AllocMemForDOS			; incestuosly!!!
	mov	es, ax				; pass the segment to MovBIOS
	call	MovBIOS
;
;------ ES:DI points memory immediately after BIOS
;
	mov	cx, lo_doscod_size		; DOS code size when loaded
						;  low
	push	cx
	call	MovDOS
	pop	cx
	add	di,cx
	call	config_copy
	ret
MovDOSLo	endp

endif ; ROMDOS

;
;----------------------------------------------------------------------------
;
; procedure : MovBIOS
;
;		Moves BIOS code into requested segment
;
;	In : ES - segment to which BIOS is to be moved
;		  ( it moves always into offset BCode_Start)
;
;	Out : ES:DI - pointer to memory immediately after BIOS
;
;----------------------------------------------------------------------------
;

ifndef ROMDOS

MovBIOS	proc	near
	mov	ds,cs:[BCodeSeg]
	mov	si,offset BCode_Start
	mov	di,si
	mov	cx,offset BCode_End
	add	cx,cs:[bios_extra_bytes]
	sub	cx,si
	shr	cx,1
	rep	movsw
	mov	ax,es
	call	reinit_bios_code
	ret
MovBIOS	endp

endif ; ROMDOS

;
;----------------------------------------------------------------------------
;
; procedure : MovDOS
;
;		Moves DOS code into requested area
;
;	In : ES:DI - pointer to memory where DOS is  to be moved
;	     CX    - size of DOS code to be moved
;
;	Out : ES:DI - starting address of the copied DOS code
;	      BX    - adjusted DOS segment (also saved in current_dos_location)
;
;----------------------------------------------------------------------------
;

ifndef ROMDOS

MovDOS	proc	near
	push	es
	push	di
	lds	si,cs:[dos_temp_location]	; current location of DOS
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	di
	mov	bx,di
	mov	ax, dosinit			; get the offset at which DOS
						;  wants to run
	sub	ax, bx
	test	al,0fh
	jz	short movdos_aligned
	jmp	near ptr FatalErr
movdos_aligned:
	.286
	shr	ax,4
	.8086
	pop	bx				; get the segment at which
						;  we moved DOS into
	sub	bx, ax				; Adjust segment
	mov	current_dos_location, bx	; and save it
	ret
MovDOS	endp

endif ;ROMDOS

;
;----------------------------------------------------------------------------
;
; procedure : AllocMemForDOS
;
;		Allocate memory for DOS/BIOS code from DOS !!!
;
;	Out : AX - seg of allocated memoryblock
;
;----------------------------------------------------------------------------
;

ifndef ROMDOS

	public  AllocMemForDOS,FatalErr
AllocMemForDOS	proc	near
	mov	ax, offset BCode_end
	add	ax,cs:[bios_extra_bytes]
	sub	ax, offset BCode_start		; BIOS code size
	add	ax, lo_doscod_size		; + DOS code size
	add	ax, 15
	.286
	shr	ax,4
	.8086
	add	ax,cs:[config_buffer_paragraphs]
	inc	ax
	or	bx, bx				; M012
						;  can we use int 21 for alloc
	mov	bx, ax
	jz	update_arena			; M012
	mov	ah, 48h				; request DOS
	int	21h
	jc	FatalErr			; IF ERR WE ARE HOSED
	sub	ax, 3				; Take care ORG 30h of
						;  BIOS code
	mov	es, ax
	mov	word ptr es:[20h+arena_owner], 08h	; mark it as system
	mov	word ptr es:[20h+arena_name], 'CS'	;  code area
	ret

;	BUGBUG -- 5 Aug 92 -- chuckst -- Allocating space for DOS
;		  using DOS itself causes an arena to be generated.
;		  Unfortunately, certain programs (like PROTMAN$)
;		  assume that the device drivers are loaded into
;		  the first arena.  For this reason, MagicDrv's
;		  main device driver header arena is manually
;		  truncated from the arena chain, and the space
;		  for DOS is allocated using the following
;		  simple code, which also assumes that the
;		  first arena is the free one where DOS's low
;		  stub will go.
;
; M012 : BEGIN
;
update_arena:
	push	ds
	push	di
	push	cx
	push	dx
	lds	di, dosinfo			; get ptr to DOS var
	dec	di
	dec	di				; Arena head is immediately
						;  before sysvar
	mov	es, ds:[di]			; es = arena head
	mov	cx, es:[arena_size]		; cx = total low mem size
	cmp	cx, bx				; is it sufficient ?
	jb	FatalErr			; no, fatal error

	mov	dl, es:[arena_signature]
	mov	ax, es
	add	ax, bx				; ax = new arena head
	mov	ds:[di], ax			; store it in DOS data area
	mov	ds, ax
	mov	byte ptr ds:[arena_signature], dl	; type of arena
	mov	word ptr ds:[arena_owner], 0		; free
	sub	cx, bx				; size of the new block
	mov	word ptr ds:[arena_size], cx	; store it in the arena
	mov	ax, es				; return seg to the caller
	sub	ax, 3				; Take care ORG 30h of
						;  BIOS code
	pop	dx
	pop	cx
	pop	di
	pop	ds
	ret
;
; M012 : END
;
FatalErr:
	call    query_keyboard_service
	push    cs
	pop     ds
	call    print_indexed
	dw      8037h
	public  stall
stall label near
fatal_halt:
	hlt
	jmp     short fatal_halt

AllocMemForDOS	endp

endif ;ROMDOS

;
;----------------------------------------------------------------------------
;
; procedure : AllocHMA
;
;	grab_the_hma tries to enable a20 and make sure there is memory
;	  up there.  If it gets any sort of error, it will return with
;	  carry set so that we can resort to running low.
;
;	On success, A20 is enabled and the BIOS HMA allocator is initialized.
;
;----------------------------------------------------------------------------
;

AllocHMA	proc near
	assume	ds:nothing,es:nothing
;
;	cas note:  The pre-286 check is no longer needed here since the
;		   presence of XMS is sufficient.  However, this code hasn't
;		   been deleted because it can be recycled for skipping the
;		   extra pass of CONFIG.SYS and assuming we're running low
;		   in the case of a pre-286.

;
;;	see if we're running on a pre-286.  If not, force low.
;
;	xor	ax,ax
;	pushf			; save flags (like int)
;	push	ax
;	popf
;	pushf
;	pop	ax
;	popf			; restore original flags (like int)
;	and	ax,0f000h
;	cmp	ax,0f000h	; 8088/8086?
;	jz	grab_hma_error
;
	push	ds
	mov	ax,Bios_Data
	mov	ds,ax
	assume 	ds:Bios_Data

	call	IsXMSLoaded
	jnz	grabhma_error

	mov	ax,4310h
	int	2fh		; get the vector into es:bx
	mov	word ptr xms,bx
	mov	word ptr xms+2,es

	mov	ah,1		; request HMA
	mov	dx,0ffffh
	call	xms
	dec	ax
	jz	@f		; error if not able to allocate HMA

;
;------ Himem may be lying because it has allocated mem for int 15
;
	mov	ah, 88h
	int	15h
	cmp	ax,64		; less than 64 K of hma ?
	jb	grabhma_error

@@:	mov	ah,5		; localenableA20
	call	xms
	dec	ax
	jnz	grabhma_error	; error if couldn't enable A20

	call	IsVDiskInstalled
	jz	grabhma_error	; yes, we cant use HMA

	mov	ax,0ffffh
	mov	ds,ax
	assume	ds:nothing
	mov	word ptr ds:[10h],1234h ; verify HMA memory
	cmp	word ptr ds:[10h],1234h
	jnz	grabhma_error
	mov	ds,cs:[BCodeSeg]
	assume	ds:Bios_Code
	mov	word ptr [hma_init_ptr],offset bc_retf
	mov	word ptr [hma_init_ptr+2],ds
	mov	word ptr [hma_initial_size],0ffc0h
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	or	byte ptr [bios_flags],1 ; A20 is enabled
	pop	ds
	ret

grabhma_error:
	stc
	pop	ds
	assume	ds:nothing
	ret

AllocHMA	endp

;
;----------------------------------------------------------------------------
;
; procedure : IsXMSLoaded
;
;             Checks whether a XMS driver is loaded
;
; Returns : Z flag set if XMS driver loaded
;           Z flag reset if no XMS drivers are present
;
;----------------------------------------------------------------------------
;
		public	IsXMSLoaded

IsXMSLoaded	proc	near
		mov	ax,4300h
		int	2fh
		cmp	al,80h		; XMS installed?
		ret
IsXMSLoaded	endp

;
;


;
;

;
;----------------------------------------------------------------------------
;
; following piece of code will be moved into a para boundary. And the para
; address posted in seg of int 19h vector. Offset of int 19h will point to
; VDint19. This is to protect HMA from apps which use VDISK header method
; to determine free extended memory.
;
; For more details read "power programming" column by Ray Duncan in the
; May 30 1989 issue of PC Magazine (pp 377-388) [USING EXTENDED MEMORY,PART 1]
;
;----------------------------------------------------------------------------
;
StartVDHead	label	byte
;
;-------------- what follows is a dummy device driver header (not used by DOS)
;
		dd	0		; link to next device driver
		dw	8000h		; device attribute
		dw	0		; strategy routine offset
		dw	0		; interrupt routine offset
		db	1		; number of units
		db	7 dup(0)	; reserved area
VDiskSig1	db	'VDISK'

VLEN1		equ	($-offset VDiskSig1)

		db	'  V3.3'	; vdisk label
		db	15 dup (0)	; pad
		dw	0		; bits 0-15 of free HMA
		db	11h		; bits 16-23 of free HMA (1M + 64K)

VDInt19:
		db	0eah		; jmp to old vector
OldVDInt19	dd	?		; Saved int 19 vector

EndVDHead	label	byte
;
;
VDiskHMAHead	db	0,0,0		; non-bootable disk
VDiskSig2	db	'VDISK'

VLEN2		equ	($-offset VDiskSig2)

		db	'3.3'		; OEM - signature
		dw	128		; number of bytes/sector
		db	1		; sectors/cluster
		dw	1		; reserved sectors
		db	1		; number of FAT copies
		dw	64		; number of root dir entries
		dw	512		; number of sectors
		db	0feh		; media descriptor
		dw	6		; number of sectors/FAT
		dw	8		; sectors per track
		dw	1		; number of heads
		dw	0		; number of hodden sectors
		dw	440h		; Start of free HMA in K (1M+64K)
EndVDiskHMAHead	label	byte
;
;
;----------------------------------------------------------------------------
;
; procedure : InstVDiskHeader
;
;             Installs the VDISK header to reserve the 64k of HMA
;	      It puts a 32 byte header at 10000:0 and
;	      another header at (seg of int19):0
;
; Inputs : None
;
; Outputs : None
;
; USES : DS,SI,AX,CX,DX
;
;----------------------------------------------------------------------------
;
		assume	ds:nothing

InstVDiskHeader	proc	near

		xor	ax, ax
		mov	ds, ax			; seg of int vect table
;
;-------------- save old int 19 vector
;
		mov	ax, word ptr ds:[19h*4]
		mov	word ptr OldVDint19, ax
		mov	ax, word ptr ds:[19h*4+2]
		mov	word ptr OldVDint19+2, ax
;
;-------------- calculate seg of new int 19 handler
;
		mov	ah, 48h			; allocate memory
		mov	bx, (offset EndVDHead - offset StartVDHead + 15) shr 4
		int	21h

;	if carry, fatal hanging error!!!!!

		dec	ax			; point to arena
		mov	es, ax
		mov	word ptr es:[arena_owner], 8	; owner = System
		mov	word ptr es:[arena_name], 'CS'	; System Code
		inc	ax
		mov	es, ax			; get back to allocated memory
;
;-------------- install new int 19 vector
;
		cli				; no reboots at this time
		mov	word ptr ds:[19h*4], (offset VDint19 - offset StartVDHead)
		mov	word ptr ds:[19h*4+2], ax
;
;-------------- move the code into proper place
;
		mov	cx, (offset EndVDHead - offset StartVDHead)
		mov	si, offset StartVDHead
		xor	di, di
		push	cs
		pop	ds
		cld
		rep	movsb
		sti				; BUGBUG is sti OK now?
;
;-------------- mov the HMA VDisk head into HMA
;
		push	di
		push	es

		mov	ax, 0ffffh
		mov	es, ax
		mov	di, 10h
		mov	cx, (offset EndVDiskHMAHead - offset VDiskHMAHead)
		mov	si, offset VDiskHMAHead
		rep	movsb			; ds already set to cs

		pop	di
		pop	es

		ret

InstVDiskHeader	endp

;
;----------------------------------------------------------------------------
; procedure : ClrVDISKHeader
;
;		Clears the first 32 bytes at 1MB boundary
;		So that DOS/HIMEM is not confused about the VDISK header
;		left by previous DOS=HIGH session
;
;----------------------------------------------------------------------------
;


desc		struc
 seg_lim	dw	0			; seg limit 64K 
 lo_word	dw	0			; 24 bit seg physical 
 hi_byte	db	0			; address
 acc_rights	db	0			; access rights ( CPL0 - R/W )
 reserved	dw	0			;
desc		ends

bmove		label byte

dummy		desc	<> 
gdt		desc	<>
src_desc	desc	<0ffffh,0,0,93h,0>
tgt_desc	desc	<0ffffh,0,10h,93h,0>	; 1MB
rombios_code	desc	<>
temp_stack	desc	<>


ClrdVDISKHead	db	32 dup (0)

		assume	ds:nothing

	public	ClrVDISKHeader
ClrVDISKHeader	proc	near

;-----------------------------------------------------------	      ;I070
; The following workaround get around a problem with the	      ;I070
; Tortugas and PS/2 30-286 BIOS when password server mode	      ;I070
; is set.  On those machines the INT 15h block move code	      ;I070
; goes through the 8042 to twiddle A20 instead of port 92h.	      ;I070
; In password server mode the 8042 is disabled so the block	      ;I070
; move crashes the system. We can do this because these		      ;I070
; systems clear all of memory on a cold boot.			      ;I070
								      ;I070
                in      al,64h         ; Test for password servr mode ;I070
                test    al,10h         ; Is keyboard inhibited?	      ;I070
                jnz     ClrVDISKok     ; No, go do block move.	      ;I070
                                       ; Check for Tortugas...	      ;I070
                cmp     word ptr cs:[sys_model_byte],19F8h	      ;I070
                je      ClrVDISKno				      ;I070
                                       ; Check for mod 30-286	      ;I070
                cmp     word ptr cs:[sys_model_byte],09FCh	      ;I070
	        je      ClrVDISKno
								      ;I070
ClrVDISKok:							      ;I070
;-----------------------------------------------------------	      ;I070

		push	es
		mov	ax, cs
		mov	dx, ax
		mov	cl, 12
		shr	dx, cl
		mov	cl, 4
		shl	ax, cl
		add	ax, offset ClrdVDISKHead
		adc	dl, 0
		mov	src_desc.lo_word, ax
		mov	src_desc.hi_byte, dl
		mov	cx, 16			; 16 words
		push	cs
		pop	es
		mov	si, offset bmove
		mov	ah, 87h
		int	15h
		pop	es
ClrVDISKno:
		ret
ClrVDISKHeader	endp

;
;
;----------------------------------------------------------------------------
;
; procedure : IsVDiskInstalled
;
;		Checks for the presence of VDISK header at 1MB boundary
;		& INT 19 vector
;
; Inputs  : A20 flag should be ON
; Outputs : Zero set if VDISK header found else Zero cleared
;
;----------------------------------------------------------------------------
;
IsVDiskInstalled proc	near
		xor	ax, ax
		mov	ds, ax
		mov	ds, word ptr ds:[19*4+2]
		mov	si, offset VDiskSig1 - offset StartVDHead
		mov	cx, VLEN1
		push	cs
		pop	es
		mov	di, offset VDiskSig1
		rep	cmpsb
		je	@f
		mov	ax, 0ffffh
		mov	ds, ax
		mov	si, 10h+(offset VDiskSig2 - offset VDiskHMAHead)
		mov	di, offset VDiskSig2
		mov	cx, VLEN2
		rep	cmpsb
@@: 
		ret			; returns the Zero flag
IsVDiskInstalled endp
;
;----------------------------------------------------------------------------
;
; procedure : CPMHack
;
;		Copies the code from 0:c0 into ffff:0d0h
;		for CPM comatibilty
;
;----------------------------------------------------------------------------
;
CPMHack		proc	near
		push	ds
		mov	cx, 0ffffH
		mov	es, cx		; ES = FFFF
		xor	cx, cx
		mov	ds, cx		; DS = 0
		mov	si, 0c0h
		mov	di, 0d0h
		mov	cx, 5
		cld
		rep	movsb		; move 5 bytes from 0:C0 to FFFF:D0
		pop	ds
		ret
CPMHack		endp

; Update the BIOS data entry vectors after moving BIOS code.
; AX is the new BIOS code segment; preserve DI and ES, use CX.
; Leave an installed configuration hook in place.
	public  reinit_bios_code
reinit_bios_code proc near
	push    di
	push    es
	mov     cs:[BCodeSeg],ax
	mov     cx,Bios_Data
	mov     es,cx
	mov     di,offset cdev
	mov     cx,offset bios_hook_1
	sub     cx,di
	.286
	shr     cx,2
	.8086
	cmp     byte ptr cs:[config_hook_active],0
	je      short reinit_bios_next
	dec     cx
reinit_bios_next:
	inc     di
	inc     di
	stosw
	loop    reinit_bios_next
	pop     es
	pop     di
	ret
reinit_bios_code endp

; Print the message whose word index follows the near CALL.
; The low 15 bits select sysinit_msg_table; skip the inline word on return.
; Preserve SI and BX; use AX and DX, return with DF clear.

print_indexed proc near
	xchg	si,dx
	pop	si
	cld
	lods	word ptr cs:[si]
	push	si
	xchg	si,dx
	push	bx
	and	ax,7fffh
	mov	bx,ax
	shl	bx,1
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[bx+sysinit_msg_table]
	mov	ah,std_con_string_output
	int	21h
	pop	bx
	ret
print_indexed endp

; Record the compressed boot drive for the BIOS startup state.
	public  boot_record_compressed_boot
boot_record_compressed_boot proc near
	mov     ax,4a11h
	xor     bx,bx
	int     2fh
	cmp     bx,444dh
	jne     short compressed_boot_done
	mov     ax,3305h
	int     21h
	dec     dl
	mov     ax,4a11h
	mov     bx,1
	int     2fh
	or      ax,ax
	jnz     short compressed_boot_done
	test    bl,80h
	jz      short compressed_boot_done
	push    ds
	mov     ds,cs:[BCodeSeg]
	assume  ds:Bios_Code
	inc     dl
	xor     dh,dh
	mov     [bootlog_device],dx
	pop     ds
	assume  ds:sysinitseg
compressed_boot_done:
	ret
boot_record_compressed_boot endp

; Read one logical boot-volume sector into the temporary sector buffer.
; DX:AX is the sector number; ES:BX receives the buffer address.
boot_read_sector proc near
	cmp     word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BYTESPERSECTOR],200h
	ja      boot_read_error
	cmp     word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_TOTALSECTORS],0
	jne     boot_read_small
	cmp     word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BIGTOTALSECTORS+2],dx
	ja      boot_read_offset
	jb      boot_read_error
	cmp     word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BIGTOTALSECTORS],ax
	jbe     boot_read_error
boot_read_offset:
	add     ax,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_HIDDENSECTOR]
	adc     dx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_HIDDENSECTOR+2]
	mov     si,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_SECTORSPERTRACK]
	or      si,si
	jz      boot_read_error
	push    ax
	mov     ax,dx
	xor     dx,dx
	div     si
	mov     cx,ax
	pop     ax
	push    cx
	div     si
	inc     dx
	mov     bx,dx
	pop     dx
	mov     si,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_HEADS]
	or      si,si
	jz      boot_read_error
	push    ax
	mov     ax,dx
	xor     dx,dx
	div     si
	or      ax,ax
	pop     ax
	jnz     boot_read_error
	div     si
	mov     dh,dl
	mov     dl,cs:[boot_copy_buffer+EXT_PHYDRV]
	mov     cx,ax
	xchg    cl,ch
	ror     cl,1
	ror     cl,1
	or      cl,bl
	mov     ax,0201h
	mov     es,cs:[bios_data_segment]
	assume  es:Bios_Data
	les     bx,es:[disksector_ptr]
	assume  es:nothing
	int     13h
boot_read_return:
	ret
boot_read_small:
	or      dx,dx
	jnz     boot_read_error
	cmp     word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_TOTALSECTORS],ax
	ja      boot_read_offset
boot_read_error:
	stc
	jmp     short boot_read_return
boot_read_sector endp

; Find an 11-byte directory name in the boot volume root directory.
; DS:SI points to the name.  Return ES:DI at the entry, carry if absent.
boot_find_file proc near
	mov     cl,cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_NUMBEROFFATS]
	xor     ch,ch
	mov     ax,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_SECTORSPERFAT]
	mul     cx
	add     ax,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_RESERVEDSECTORS]
	adc     dx,0
	mov     bx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_ROOTENTRIES]
	xor     cx,cx
	.386
	bsf     cx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BYTESPERSECTOR]
	.8086
	sub     cx,5
	jbe     boot_find_error
	shr     bx,cl
	jz      boot_find_error
boot_find_sector:
	dec     bx
	js      boot_find_error
	push    bx
	push    dx
	push    ax
	push    si
	call    boot_read_sector
	mov     di,bx
	pop     si
	pop     ax
	pop     dx
	pop     bx
	jc      boot_find_error
	add     ax,1
	adc     dx,0
	mov     cx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BYTESPERSECTOR]
	.286
	shr     cx,5
	.8086
boot_find_entry:
	cmp     byte ptr es:[di],0
	je      boot_find_error
	push    cx
	push    di
	push    si
	mov     cx,11
	cld
	repe    cmpsb
	pop     si
	pop     di
	pop     cx
	je      boot_find_return
	add     di,20h
	loop    boot_find_entry
	jmp     short boot_find_sector
boot_find_error:
	stc
boot_find_return:
	ret
boot_find_file endp

; Determine the paragraphs needed to load the disk compression driver.
; Return the reservation in AX, using the saved boot BPB in boot_copy_buffer.
public boot_compressed_reserve
boot_compressed_reserve proc near
	mov     si,offset boot_compress_name
	call    boot_find_file
	jc      boot_try_drvspace
	test    byte ptr es:[di+0bh],18h
	jz      boot_find_compress_bin
boot_try_drvspace:
	mov     word ptr [si+1],5652h
	call    boot_find_file
	jnc     short boot_check_drvspace
	jmp     boot_compress_default
boot_check_drvspace:
	test    byte ptr es:[di+0bh],18h
	jz      boot_find_compress_bin
	jmp     boot_compress_default
boot_find_compress_bin:
	mov     word ptr [si+8],4942h
	mov     byte ptr [si+0ah],4eh
	call    boot_find_file
	jnc     short boot_check_compress_bin
	jmp     boot_compress_default
boot_check_compress_bin:
	test    byte ptr es:[di+0bh],18h
	jz      boot_check_compress_size
	jmp     boot_compress_default
boot_check_compress_size:
	cmp     word ptr es:[di+1eh],0
	jne     short boot_compress_sector
	cmp     word ptr es:[di+1ch],40h
	jb      boot_compress_default
boot_compress_sector:
	mov     cl,cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_NUMBEROFFATS]
	xor     ch,ch
	mov     ax,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_SECTORSPERFAT]
	mul     cx
	add     ax,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_RESERVEDSECTORS]
	adc     dx,0
	mov     bx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_ROOTENTRIES]
	.386
	bsf     cx,word ptr cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_BYTESPERSECTOR]
	.8086
	sub     cx,5
	shr     bx,cl
	add     ax,bx
	adc     dx,0
	mov     bx,word ptr es:[di+1ah]
	sub     bx,2
	jb      boot_compress_default
	mov     cl,cs:[boot_copy_buffer+EXT_BOOT_BPB+EBPB_SECTORSPERCLUSTER]
	xor     ch,ch
	.386
	bsf     si,cx
	.8086
	mov     cx,si
	xor     si,si
	.386
	shld    si,bx,cl
	.8086
	shl     bx,cl
	add     ax,bx
	add     dx,si
	call    boot_read_sector
	jc      boot_compress_default
	mov     ax,1000h
	cmp     word ptr es:[bx],5a4dh
	jne     boot_compress_return
	cmp     word ptr es:[bx+18h],40h
	jb      boot_compress_return
	cmp     word ptr es:[bx+28h],7365h
	jne     boot_compress_return
	mov     dx,word ptr es:[bx+2ah]
	cmp     dx,3000h
	ja      boot_compress_return
	mov     ax,dx
boot_compress_return:
	ret
boot_compress_default:
	xor     ax,ax
	test    byte ptr cs:[boot_copy_buffer+EXT_PHYDRV],80h
	jnz     boot_compress_return
	mov     ax,1000h
	jmp     short boot_compress_return
boot_compressed_reserve endp
boot_compress_name db 'DBLSPACEINI',0

; Localized responses copied from the system message table at startup.
	public  query_yes, query_yes_lower, query_no, query_no_lower
	public  query_all_char, query_all_lower
	public  config_swap_active,OnOff,insert_blank
config_swap_active db   0
query_yes       db      0
query_yes_lower db      0
query_no        db      0
query_no_lower  db      0
query_all_char  db      0
query_all_lower db      0
OnOff	db	'ONOFF'
insert_blank db 0               ; terminator and inserted-blank flag

	public	setparms,parseline,diddleback
	extrn	getchr:near,getnum:near
	extrn	bpbtable:word
	extrn	drive:byte,switches:word,hlim:word,slim:word,switchlist:byte
switchnum equ 11111000b
flagec35 equ 00000100b
flagdrive equ 00001000b
flagcyln equ 00010000b
flagseclim equ 00100000b
flagheads equ 01000000b
flagff equ 10000000b

;
;----------------------------------------------------------------------------
;
; procedure : setparms
;
; the following set of routines is used to parse the drivparm = command in
; the config.sys file to change the default drive parameters.
;
;----------------------------------------------------------------------------
;
setparms	proc	near

	push	ds
	push	ax
	push	bx
	push	cx
	push	dx

	push	cs
	pop	ds
	assume	ds:sysinitseg

	xor	bx,bx
	mov	bl,byte ptr drive
	inc	bl			; get it correct for ioctl
					;  call (1=a,2=b...)
	mov	dx,offset deviceparameters
	mov	ah,ioctl
	mov	al,generic_ioctl
	mov	ch,rawio
	mov	cl,set_device_parameters
	int	21h

	mov	ds,[BCodeSeg]		; get relocated BIOS code segment
	assume	ds:Bios_Code

	test	cs:word ptr switches, flagec35
	jz	not_ec35

	mov	cl,cs:byte ptr drive	; which drive was this for?

	mov	al,1			; assume drive 0
	shl	al,cl			; set proper bit depending on drive
	or	ds:ec35_flag,al 	; set the bit in the permanent flags

not_ec35:

;	Now adjust the BIOS's EOT variable if our new drive has more
;	sectors per track than any old ones.

	mov	al,cs:byte ptr deviceparameters.DP_BPB.BPB_SECTORSPERTRACK
	cmp	al,eot
	jbe	eot_ok
	mov	eot,al
eot_ok:

	pop	dx			; fix up all the registers
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	assume	ds:nothing
	ret

setparms	endp

;
;----------------------------------------------------------------------------
;
; procedure : diddleback
;
; replace default values for further drivparm commands
;
;----------------------------------------------------------------------------
;

diddleback	proc	near

	push	ds
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	word ptr deviceparameters.dp_cylinders,80
	mov	byte ptr deviceparameters.dp_devicetype, dev_3inch720kb
	mov	word ptr deviceparameters.dp_deviceattributes,0
	mov	word ptr switches,0	    ; zero all switches
	pop	ds
	assume	ds:nothing
	ret

diddleback	endp

;
;----------------------------------------------------------------------------
;
; procedure : parseline
;
; entry point is parseline. al contains the first character in command line.
;
;----------------------------------------------------------------------------
;

parseline	proc	near
					; don't get character first time
	push	ds

	push	cs
	pop	ds
	assume	ds:sysinitseg

nextswtch:
	cmp	al,cr			; carriage return?
	jz	done_line
	cmp	al,lf			; linefeed?
	jz	put_back		; put it back and done

; anything less or equal to a space is ignored.

	cmp	al,' '                  ; space?
	jbe	get_next		; skip over space
	cmp	al,'/'
	jz	getparm
	stc				; mark error invalid-character-in-input
	jmp	short exitpl

getparm:
	call	check_switch
	mov	word ptr switches,bx	; save switches read so far
	jc	swterr

get_next:
	call	getchr
	jc	done_line
	jmp	nextswtch

swterr:
	jmp	short exitpl		; exit if error

done_line:
	test	word ptr switches,flagdrive  ; see if drive specified
	jnz	okay
	stc				; mark error no-drive-specified
	jmp	short exitpl

okay:
	mov	ax,word ptr switches
	and	ax,0003h	    ; get flag bits for changeline and non-rem
	mov	word ptr deviceparameters.dp_deviceattributes,ax
	mov	word ptr deviceparameters.dp_tracktableentries, 0
	clc			    ; everything is fine
	call	setdeviceparameters
exitpl:
	pop	ds
	ret

put_back:
	inc	count			; one more char to scan
	dec	chrptr			; back up over linefeed
	jmp	short done_line

parseline	endp

;
;----------------------------------------------------------------------------
;
; procedure : check_switch
;
; processes a switch in the input. it ensures that the switch is valid, and
; gets the number, if any required, following the switch. the switch and the
; number *must* be separated by a colon. carry is set if there is any kind of
; error.
;
;----------------------------------------------------------------------------
;

check_switch	proc	near

	call	getchr
	jc	err_check
	and     al,0dfh                 ; convert it to upper case
	cmp	al,'A'
	jb	err_check
	cmp	al,'Z'
	ja	err_check

	push	es

	push	cs
	pop	es

	mov	cl,byte ptr switchlist	; get number of valid switches
	mov	ch,0
	mov	di,1+offset switchlist	; point to string of valid switches
	repne	scasb

	pop	es
	jnz	err_check

	mov	ax,1
	shl	ax,cl			; set bit to indicate switch
	mov	bx,word ptr switches	; get switches so far
	or	bx,ax			; save this with other switches
	mov	cx,ax
	test	ax, switchnum		; test against switches that require number to follow
	jz	done_swtch

	call	getchr
	jc	err_swtch

	cmp	al,':'
	jnz	err_swtch

	call	getchr
	push	bx			; preserve switches
	mov	byte ptr cs:sepchr,' '	; allow space separators
	call	getnum
	mov	byte ptr cs:sepchr,0
	pop	bx			; restore switches

; because getnum does not consider carriage-return or line-feed as ok, we do
; not check for carry set here. if there is an error, it will be detected
; further on (hopefully).

	call	process_num

done_swtch:
	clc
	ret

err_swtch:
	xor	bx,cx			; remove this switch from the records
err_check:
	stc
	ret

check_switch	endp

;
;----------------------------------------------------------------------------
;
; procedure : process_num
;
; this routine takes the switch just input, and the number following (if any),
; and sets the value in the appropriate variable. if the number input is zero
; then it does nothing - it assumes the default value that is present in the
; variable at the beginning. zero is ok for form factor and drive, however.
;
;----------------------------------------------------------------------------
;

process_num	proc	near
	test	word ptr switches,cx	; if this switch has been done before,
	jnz	done_ret		; ignore this one.
	test	cx,flagdrive
	jz	try_f
	mov	byte ptr drive,al
	jmp	short done_ret

try_f:
	test	cx,flagff
	jz	try_t

; ensure that we do not get bogus form factors that are not supported

	mov	byte ptr deviceparameters.dp_devicetype,al
	jmp	short done_ret

try_t:
	or	ax,ax
	jz	done_ret		; if number entered was 0, assume default value
	test	cx,flagcyln
	jz	try_s

	mov	word ptr deviceparameters.dp_cylinders,ax
	jmp	short done_ret

try_s:
	test	cx,flagseclim
	jz	try_h
	mov	word ptr slim,ax
	jmp	short done_ret

; must be for number of heads

try_h:
	mov	word ptr hlim,ax

done_ret:
	clc
	ret

process_num	endp

;
;----------------------------------------------------------------------------
;
; procedure : setdeviceparameters
;
; setdeviceparameters sets up the recommended bpb in each bds in the
; system based on the form factor. it is assumed that the bpbs for the
; various form factors are present in the bpbtable. for hard files,
; the recommended bpb is the same as the bpb on the drive.
; no attempt is made to preserve registers since we are going to jump to
; sysinit straight after this routine.
;
;	if we return carry, the DRIVPARM will be aborted, but presently
;	  we always return no carry
;
;
;	note:  there is a routine by the same name in msdioctl.asm
;
;----------------------------------------------------------------------------
;

	public  setdeviceparameters
	assume	ds:sysinitseg
setdeviceparameters	proc	near

	push	es

	push	cs
	pop	es
	assume	es:sysinitseg

	xor	bx,bx
	mov	bl,byte ptr deviceparameters.dp_devicetype
	cmp	bl,dev_5inch
	jnz	got_80

	mov	word ptr deviceparameters.dp_cylinders,40 	; 48 tpi=40 cyl

got_80:
	shl	bx,1			; get index into bpb table
	mov	si,bpbtable[bx]		; get address of bpb

	mov	di,offset deviceparameters.dp_bpb ; es:di -> bpb
	mov	cx,size A_BPB
	cld
	repe	movsb

	pop	es
	assume es:nothing

	test	word ptr switches,flagseclim
	jz	see_heads

	mov	ax,word ptr slim
	mov	word ptr deviceparameters.dp_bpb.bpb_sectorspertrack,ax

see_heads:
	test	word ptr switches,flagheads
	jz	heads_not_altered

	mov	ax,word ptr hlim
	mov	word ptr deviceparameters.dp_bpb.bpb_heads,ax

heads_not_altered:


; set up correct media descriptor byte and sectors/cluster
;   sectors/cluster is always 2 except for any one sided disk or 1.44M

	mov	byte ptr deviceparameters.dp_bpb.bpb_sectorspercluster,2
	mov	bl,0f0h			; get default mediabyte

;	preload the mediadescriptor from the bpb into bh for convenient access

	mov	bh,byte ptr deviceparameters.dp_bpb.bpb_mediadescriptor

	cmp	word ptr deviceparameters.dp_bpb.bpb_heads,2	; >2 heads?
	ja	got_correct_mediad	; just use default if heads>2

	jnz	only_one_head		; one head, do one head stuff

;	two head drives will use the mediadescriptor from the bpb

	mov	bl,bh			; get mediadescriptor from bpb

;	two sided drives have two special cases to look for.  One is
;	   a 320K diskette (40 tracks, 8 secs per track).  It uses
;	   a mediaid of 0fch.  The other is 1.44M, which uses only
;	   one sector/cluster.

;	any drive with 18secs/trk, 2 heads, 80 tracks, will be assumed
;	   to be a 1.44M and use only 1 sector per cluster.  Any other
;	   type of 2 headed drive is all set.

	cmp	deviceparameters.dp_bpb.bpb_sectorspertrack,18
	jnz	not_144m
	cmp	deviceparameters.dp_cylinders,80
	jnz	not_144m

;	We've got cyl=80, heads=2, secpertrack=18.  Set cluster size to 1.

	jmp	short got_one_secperclus_drive


;	check for 320K

not_144m:
	cmp	deviceparameters.dp_cylinders,40
	jnz	got_correct_mediad
	cmp	deviceparameters.dp_bpb.bpb_sectorspertrack,8
	jnz	got_correct_mediad

	mov	bl,0fch
	jmp	short got_correct_mediad


only_one_head:

;	if we don't have a 360K drive, then just go use 0f0h as media descr.

	cmp	deviceparameters.dp_devicetype,dev_5inch
	jnz	got_one_secperclus_drive

;	single sided 360K drive uses either 0fch or 0feh, depending on
;	  whether sectorspertrack is 8 or 9.  For our purposes, anything
;	  besides 8 will be considered 0fch

	mov	bl,0fch			; single sided 9 sector media id
	cmp	word ptr deviceparameters.dp_bpb.bpb_sectorspertrack,8
	jnz	got_one_secperclus_drive ; okay if anything besides 8

	mov	bl,0feh			; 160K mediaid

;	we've either got a one sided drive, or a 1.44M drive
;	  either case we'll use 1 sector per cluster instead of 2

got_one_secperclus_drive:
	mov	byte ptr deviceparameters.dp_bpb.bpb_sectorspercluster,1

got_correct_mediad:
	mov	byte ptr deviceparameters.dp_bpb.bpb_mediadescriptor,bl


;	 Calculate the correct number of Total Sectors on medium
;
	mov	ax,deviceparameters.dp_cylinders
	mul	word ptr deviceparameters.dp_bpb.bpb_heads
	mul	word ptr deviceparameters.dp_bpb.bpb_sectorspertrack
	mov	word ptr deviceparameters.dp_bpb.bpb_totalsectors,ax
	clc				; we currently return no errors

	ret

setdeviceparameters	endp
	



sysinitseg ends
	end
