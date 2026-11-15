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
	include	msbds.inc
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


HimemInitSeg segment para public 'HIMEM_INIT'
	extrn	InitMemory:far,InitInterrupt:far,HimemMessage:dword
HimemInitSeg ends

	extrn	BootResume:far,ConfigPathBuffer:byte

Bios_Code	segment
	extrn   eot:byte,ec35_flag:byte
	extrn	Bios_Data_Word:word,win386_instance:word
	extrn   bootlog_device:word
	extrn	win386_stack_seg:word,win386_stack_size:word
	extrn	win386_nextstack:word
	extrn	win386_info_flags:byte,exec_bios_word:byte,win386_callback_table:dword
	extrn	bc_retf:far
	extrn	hma_initial_size:word,hma_free_head:word
	extrn	sysinit_seg:word
	extrn	win386_stack_code_seg:word,win386_stack_code_size:word
	irp	aa,<08,09,0a,0b,0c,0d,0e,70,72,73,74,76,77>
	extrn	int19old&aa:dword
	endm
	extrn	DosInit:far
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

	extrn	bios_flags:word,int16_count:word,keyboard_status:byte
	extrn	disksector_ptr:dword
	extrn	boot_minute:byte,boot_seconds:word
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

; Move SYSINIT and its messages below the top of conventional memory.
; Keep the decompressed resident BIOS and DOS at their linked addresses.
;
SYSINIT_IMAGE_BYTES equ 0c9d0h
SYSINIT_STACK_BYTES equ 2200h

	public	SI_start,move_myself
SI_start label far
move_myself:
	.386
	cld
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	bx,[memory_size]
	mov	[sysinit_memory_size],bx
	dec	bx
	cmp	[RPLMemTop],0
	je	short dos7_memory_ready
	mov	bx,[RPLMemTop]
	dec	bx
dos7_memory_ready:
	mov	edx,SYSINIT_IMAGE_BYTES+SYSINIT_STACK_BYTES
	mov	ax,dx
	shr	dx,4
	sub	bx,dx
	mov	es,bx
	mov	ss,bx
	mov	sp,ax
	xor	si,si
	mov	di,si
	mov	es,bx
	mov	cx,SYSINIT_IMAGE_BYTES
	shr	cx,2
	rep	movsd
	push	bx
	push	offset sysin
	retf
	.8086

	assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

	extrn	sysinit_msg_base:byte
	extrn	sysinit_msg_table:word
	public	print_indexed
	extrn   query_keyboard_service:near,query_check_skip:near,query_result:byte
	extrn	default_switch_char:byte,command_line2:byte,command_line3:byte
	extrn	boot_option_open:near,boot_performance:byte
	extrn	query_check_done:near
	extrn	xms_driver_index:word
	extrn	xms_memory_index:word
	extrn	xms_hma_index:word
	extrn	resume_cr_index:word
	extrn	resume_error_index:word
	extrn	resume_return_index:word
	extrn	resume_progress_index:word
	extrn	resume_prompt_index:word
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
	extrn	query_bios_call:near
	extrn	config_buffer_paragraphs:word
	extrn	boot_runtime_flags:byte
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
	extrn	int24:near,boot_old_int24:dword
	extrn	boot_buffer_segment:word,exec_windows_path:byte
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
	extrn	int08:far,int09:far,int70:far
	extrn	old08:dword,old09:dword,old70:dword
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
have_install_cmd equ 00000001b
has_installed equ 00000010b

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
	extrn	boot_io_file:byte,boot_system_flags:byte
	extrn   config_device_table_ptr:dword
	extrn   new_psp_segment:word
	extrn   compressed_dest_segment:word,compressed_reserved_paras:word
	extrn   compressed_reserve:word ; paragraphs reserved for compression


	ifdef	dblspace_hooks
	endif


;
; Relocated SYSINIT entry: prepare disk descriptors and initialize DOS.
;

public sysin
sysin:
	assume	ds:nothing,es:nothing,ss:nothing
	.386
	push	di
	mov	ds,bx
	assume	ds:sysinitseg
	mov	bx,offset dskdrvs
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
	sub     ax,size bds_struc
	jbe     bds_prepare_link
	add     dx,ax
	push    di
	add     di,size bds_struc
	mov     cx,offset dskdrvs
	sub	cx,si
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	di
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
	mov	eax,dword ptr [BiosOld4F]
	mov	dword ptr [int4f_old],eax
	mov     si,offset int4f_entry
	or	eax,eax
	jnz	short int4f_vector_ready
	mov     si,offset intret
int4f_vector_ready:
	xor     ax,ax
	mov     es,ax
	cli
	mov     word ptr es:[4fh*4],si
	mov     word ptr es:[4fh*4+2],ds
	sti
	assume  ds:nothing



;	Prepare the low DOS initialization workspace, then call the linked
;	resident kernel. The device list and memory size come from MSINIT.
;
	mov	ds,cs:[BCodeSeg]
	assume	ds:Bios_Code
	mov	word ptr [sysinit_seg],cs
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	or	byte ptr [bios_flags+1],80h

	sub	eax,eax
	mov	es,ax
	mov	di,600h
	mov	cx,40h
	rep	stosd
	mov	di,600h
	mov	cx,5
	mov	eax,204e4f43h		; 'CON '
dosinit_con_entry:
	stosd
	add	di,37h
	loop	dosinit_con_entry

	lds	si,cs:[device_list]
	mov	dx,cs:[memory_size]
	mov	bx,Bios_Data
	mov	ax,0448h
	call	DosInit
	mov	cs:[def_php],ds		; PSP supplied by DOS
	push	cs
	pop	ds
	assume	ds:sysinitseg
	mov	word ptr [config_access_table],bx
	mov	word ptr [config_access_table+2],es
	mov	[hi_doscod_size],ax
	mov	[lo_doscod_size],cx
	mov	eax,es:[di.sysi_initvars]
	mov	dosinfo,eax
	mov	eax,es:[di.sysi_country_tab]
	mov	sysi_country,eax
	add	bx,20h
	mov	word ptr [config_device_table_ptr],bx
	.8086

; Initialize the localized responses used by SYSINIT and DOS.
	mov     ah,GET_IN_VARS
	int     21h
	les     bx,es:[bx+12h]
	mov     bx,es:[bx+13h]
	push    bx
	mov     bx,es:[bx+6]
	mov     si,offset sysinit_msg_base
	add     si,[sysinit_msg_table+50]
	mov     al,[si]
	mov     [query_yes],al
	mov     es:[bx],al
	mov     al,[si+3]
	mov     [query_yes_lower],al
	mov     es:[bx+2],al
	mov     al,[si+1]
	mov     [query_no],al
	mov     es:[bx+1],al
	mov     al,[si+4]
	mov     [query_no_lower],al
	mov     es:[bx+3],al
	mov     al,[si+2]
	mov     [query_all_char],al
	mov     al,[si+5]
	mov     [query_all_lower],al
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
	.386
	mov	dword ptr es:[arena_name], 'LPR'
	mov	dword ptr es:[arena_name+4], 0
	.8086

        pop     es                      ; get back ptr to first block
        mov     ah, Dealloc             ; and free it
	int	21h
NoRPLArena:
;
;M056 - END
;
	les	di,dosinfo		; es:di -> DOS initialization variables
	assume	ds:sysinitseg
	mov	ax,es:[di.sysi_maxsec]	; get the sector size
	add	ax,bufinsiz		; size of buffer header
	mov	[singlebuffersize],ax	; total size for a buffer

	mov	al,default_drive	; get the 1 based boot drive number set by msinit
	mov	es:[di.sysi_boot_drive],al ; set sysi_boot_drive
	push	ds
	mov	cx,Bios_Data
	mov	ds,cx
	assume	ds:Bios_Data
	mov	[keyboard_status],al
	pop	ds
	assume	ds:sysinitseg

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
	.386
	mov	dword ptr [si.buf_sector],0
	.8086
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
	.386
	mov	cx,40h
	rep	movsd
	.8086

	mov	word ptr es:[pdb_jfn_pointer + 2],es ; relocate
	mov	es:[PDB_Parent_PID],0
	mov	es:[PDB_environ],0
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


;	Save the boot error vector, install SYSINIT's handler and set up
;	the relocated PSP return vectors.
;
	mov	ax,(get_interrupt_vector shl 8) or 24h
	int	21h
	mov	word ptr [boot_old_int24],bx
	mov	word ptr [boot_old_int24+2],es
	mov	dx,offset int24
	mov	ax,(set_interrupt_vector shl 8) or 24h
	int	21h
	mov	es,[new_psp_segment]
	mov	word ptr es:[PDB_Fatal_abort],bx
	mov	bx,word ptr [boot_old_int24+2]
	mov	word ptr es:[PDB_Fatal_abort+2],bx
	mov	ax,(get_interrupt_vector shl 8) or 23h
	int	21h
	mov	ax,es
	mov	es,[new_psp_segment]
	mov	word ptr es:[PDB_Ctrl_C],bx
	mov	word ptr es:[PDB_Ctrl_C+2],ax
	mov	word ptr es:[PDB_Exit],0
	mov	word ptr es:[PDB_Exit+2],es

        cmp     byte ptr [TooManyDrivesFlag],0  ;Q: >24 partitions? M029
        je      no_err                          ;  N: continue      M029
	call    print_indexed
	dw      8014h
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
	.286
	mov	ah,get_date
	int	21h
	xchg	ax,cx
	sub	ax,1980
	shl	ax,9
	or	al,dl
	shr	dx,3
	and	dl,0e0h
	or	ax,dx
	.8086

; The loader supplies the warning and expiration dates in DOS format.
	mov	cx,[boot_data_low]
	test	cx,cx
	jnz	short boot_date_present
	jmp	near ptr boot_save_time
boot_date_present:
	cmp	cx,-1
	jne	short boot_date_check
	jmp	near ptr boot_date_disabled
boot_date_check:
	cmp	cx,ax
	jb	short boot_date_expired
	mov	cx,[boot_data_high]
	test	cx,cx
	jnz	short boot_date_warn_check
	jmp	near ptr boot_save_time
boot_date_warn_check:
	cmp	cx,ax
	jbe	short boot_date_warn
	jmp	near ptr boot_save_time
boot_date_warn:
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+92]
	call	print
	.286
	mov	ax,[boot_data_low]
	shr	ax,5
	and	ax,0fh
	cmp	al,12
	jbe	short boot_date_month
	mov	al,12
boot_date_month:
	dec	ax
	add	ax,ax
	add	ax,ax
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+98]
	add	dx,ax
	call	print
	mov	dl,' '
	mov	ah,std_con_output
	int	21h
	mov	ax,[boot_data_low]
	and	ax,1fh
	call	show_line_number
	mov	dl,','
	mov	ah,std_con_output
	int	21h
	mov	dl,' '
	mov	ah,std_con_output
	int	21h
	mov	ax,[boot_data_low]
	shr	ax,9
	add	ax,1980
	.8086
	call	show_line_number
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+94]
	call	print
	jmp	short boot_date_prompt

; Save the expired state in the date word at the end of the loader.
boot_date_expired:
	mov	ax,(chmod shl 8) or 1
	sub	cx,cx
	mov	dx,offset boot_io_file
	int	21h
	jc	short boot_date_disabled
	mov	ax,(open shl 8) or 2
	int	21h
	jc	short boot_date_attributes
	xchg	ax,bx
	mov	dx,05fch
	sub	cx,cx
	mov	ax,lseek shl 8
	int	21h
	jc	short boot_date_close
	mov	[boot_data_low],-1
	mov	dx,offset boot_data_low
	mov	cx,2
	mov	ah,write
	int	21h
boot_date_close:
	mov	ah,close
	int	21h
boot_date_attributes:
	mov	ax,(chmod shl 8) or 1
	mov	cx,7
	mov	dx,offset boot_io_file
	int	21h
boot_date_disabled:
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+100]
	call	print
	mov	es,[BCodeSeg]
	assume	es:Bios_Code
	mov	byte ptr es:[win386_instance],0
	assume	es:nothing
	or	byte ptr [boot_system_flags],1
boot_date_prompt:
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+96]
	call	print
	mov	ax,(std_con_input_flush shl 8) or 8
	int	21h
boot_save_time:
	sub	dx,dx
	call	boot_option_open
	push	ds
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	mov	ah,get_time
	int	21h
	cmp	byte ptr cs:[boot_performance],0
	jz	short boot_store_time
	mov	cx,0100h		; use 01:00:00 for boot timing
	xor	dx,dx
boot_store_time:
	mov	boot_minute,cl
	mov	boot_seconds,dx
	cmp	byte ptr cs:[boot_performance],0
	jz	short boot_time_done
	mov	ah,set_time
	int	21h
boot_time_done:
	pop	ds
	assume	ds:sysinitseg

;
; Install the SYSINIT message entry before initializing the XMS handles.
;
	push	ds
	mov	ax,HimemInitSeg
	mov	ds,ax
	assume	ds:HimemInitSeg
	mov	word ptr [HimemMessage],offset DispHimemMsg
	mov	word ptr [HimemMessage+2],cs
	pop	ds
	assume	ds:sysinitseg
	push	word ptr [dos_segreinit+2]
	call	InitMemory
	call	AllocFreeMem
	.286
;
; Leave the high initialization work area free while resuming Windows.
;
	mov	es,[area]
	mov	bx,[alloclim]
	sub	bx,[area]
	sub	bx,2
	mov	ah,setblock
	int	21h
	mov	bx,-1
	mov	ah,alloc
	int	21h
	mov	ah,alloc
	int	21h
	mov	[boot_buffer_segment],ax
	mov	bx,548h
	add	bx,31
	shr	bx,4
	add	bx,(seg ConfigPathBuffer)+4Ch
	sub	bx,[area]
	mov	ah,setblock
	int	21h
	push	cs
	push	offset DispHimemMsg
	push	cs
	push	offset exec_windows_path
	call	BootResume
	add	sp,8
	.8086
	call	MovDOSHi

; Reinstall the critical-error handler after the HMA transition.
	push	es
	mov	ax,(get_interrupt_vector shl 8) or 24h
	int	21h
	mov	word ptr [boot_old_int24+2],es
	pop	es
	mov	dx,offset int24
	mov	ax,(set_interrupt_vector shl 8) or 24h
	int	21h
; Select the startup message and detect a restart into MS-DOS mode.
	test    byte ptr [boot_runtime_flags],10h
	jnz     boot_intro_done
boot_intro_retry:
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+8]
	mov     dx,offset boot_config_app
	mov     ax,4300h
	int     21h
	jnc     boot_intro_print
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+6]
	mov     dx,offset boot_config_wos
	mov     ax,4300h
	int     21h
	jnc     boot_intro_dos_mode
	mov     dx,offset boot_msdos_status
	mov     ax,4300h
	int     21h
	jnc     boot_intro_dos_mode
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+4]
	test    byte ptr [boot_runtime_flags],1
	jnz     boot_intro_print
	jmp	short boot_intro_done
boot_intro_dos_mode:
	mov     byte ptr [boot_mode],1
	or      byte ptr [boot_runtime_flags],1
boot_intro_print:
	mov     dx,bx
	call    print
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

	push    cs
	pop     ds
	assume  ds:sysinitseg
	call    boot_start_old_dos
	cmp     byte ptr [boot_mode],2
	jne     short sysinit_previous_done
	mov     word ptr [boot_old_image_seg],0
	mov     bx,offset sysinit_msg_base
	add     bx,word ptr [sysinit_msg_table+88]
	mov     byte ptr [bx],'$'
	mov     bx,offset boot_windows_file_table
	call    boot_old_file_table
sysinit_previous_done:

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
	mov	ah,Dealloc
	mov	es,[area]
	int	21h

; Restore the DOS startup flag when a system file did not handle it,
; then select the previous startup menu if appropriate.
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
	add     dx,word ptr [sysinit_msg_table+74]
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

; The combined resident image was moved into the HMA before CONFIG.SYS.

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

	call    boot_record_compressed_boot

	mov     ax,4a16h
	int     2fh
	test	byte ptr [query_mode_flags],1
	jnz	short skip_ebda_recovery
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


	call	endfile			; setup fcbs, files, buffers etc
	call    boot_prepare_shell
	call    boot_prepare_environment

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


;----------------------------------------------------------------------------
;
; MovDOSHi - Move the combined BIOS and DOS code into the HMA.
; Initialize its free block, retarget the low BIOS entries, and hook XMS.
;
;----------------------------------------------------------------------------

MovDOSHi proc near
	.386
	assume	ds:sysinitseg
	push	ds
	push	es
	mov	bx,[hi_doscod_size]
	add	bx,0fh
	and	bx,not 0fh
	mov	ds,[BCodeSeg]
	assume	ds:Bios_Code
	mov	ax,0ffffh
	mov	es,ax
	mov	word ptr es:[bx],534dh	; HMA arena signature
	mov	word ptr es:[bx+6],0	; last arena
	mov	ax,bx
	neg	ax
	sub	ax,10h
	mov	es:[bx+4],ax		; free bytes
	mov	word ptr es:[bx+2],0	; free owner
	mov	[hma_free_head],bx
	db	81h,0ebh		; sub bx,40h
	dw	40h
	mov	[hma_initial_size],bx
	mov	si,offset BCode_start
	mov	di,si
	lea	cx,[bx+10h]
	shr	cx,2
	rep	movsd
	mov	ax,es
	call	reinit_bios_code
	call	cs:dword ptr [dos_segreinit]

;	Copy the CP/M call at 0000:00C0 into the HMA.
;
	mov	cx,0ffffh
	mov	es,cx
	xor	cx,cx
	mov	ds,cx
	assume	ds:nothing
	mov	si,0c0h
	mov	di,0d0h
	mov	cx,5
	cld
	rep	movsb
	call	InitInterrupt
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	or	byte ptr [bios_flags],1
	pop	es
	pop	ds
	ret
	assume	ds:sysinitseg,es:nothing
	.8086
MovDOSHi endp

	public	FatalErr
FatalErr:
	call    query_keyboard_service
	push    cs
	pop     ds
	call    print_indexed
	dw      803eh
	public  stall
stall label near
fatal_halt:
	hlt
	jmp     short fatal_halt


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


;
; DispHimemMsg - print a diagnostic or prompt during early initialization.
; The caller supplies the message number on the stack.
;
DispHimemMsg proc far
	.386
	push	bp
	mov	bp,sp
	pusha
	push	ds
	push	es
	push	cs
	pop	ds
	push	cs
	pop	es
	assume	ds:sysinitseg,es:sysinitseg
	mov	ax,[bp+6]
	cmp	ax,14h
	ja	near ptr dhm_done
	jnz	short dhm_test_driver
	mov	dx,offset sysinit_msg_base
	add	dx,[xms_hma_index]
	jmp	short dhm_first_print
dhm_test_driver:
	cmp	ax,0ch
	ja	near ptr dhm_done
	jnz	short dhm_test_memory
	mov	dx,offset sysinit_msg_base
	add	dx,[xms_driver_index]
	jmp	short dhm_first_print
dhm_test_memory:
	cmp	ax,9
	ja	near ptr dhm_done
	jnz	short dhm_test_cr
	mov	dx,offset sysinit_msg_base
	add	dx,[xms_memory_index]
	jmp	short dhm_first_print
dhm_test_cr:
	cmp	ax,5
	ja	short dhm_done
	jnz	short dhm_test_error
	mov	dx,offset sysinit_msg_base
	add	dx,[resume_cr_index]
	jmp	short dhm_first_print
dhm_test_error:
	cmp	ax,4
	ja	short dhm_done
	jnz	short dhm_test_progress
	mov	dx,offset sysinit_msg_base
	add	dx,[resume_error_index]
dhm_first_print:
	jmp	short dhm_print
dhm_test_progress:
	cmp	ax,3
	ja	short dhm_done
	jnz	short dhm_test_prompt
	mov	dx,offset sysinit_msg_base
	add	dx,[resume_progress_index]
	call	print
	jmp	short dhm_done
dhm_test_prompt:
	cmp	ax,2
	ja	short dhm_done
	jnz	short dhm_test_return
	xor	al,al
	mov	ah,[boot_runtime_flags]
	or	ah,8
	xchg	al,[query_mode_flags]
	xchg	ah,[boot_runtime_flags]
	push	ax
	mov	byte ptr [config_cmd],81h
	mov	word ptr [bp-2],'Y'
	mov	dx,offset sysinit_msg_base
	add	dx,[resume_prompt_index]
	call	query_check_done
	pop	ax
	mov	[query_mode_flags],al
	mov	[boot_runtime_flags],ah
	jnc	short dhm_done
	mov	word ptr [bp-2],'N'
	jmp	short dhm_done
dhm_test_return:
	cmp	ax,1
	ja	short dhm_done
	jc	short dhm_done
	mov	dx,offset sysinit_msg_base
	add	dx,[resume_return_index]
dhm_print:
	call	print
dhm_done:
	pop	es
	pop	ds
	popa
	pop	bp
	ret
	.8086
DispHimemMsg endp

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
	extrn	vlim:word,rlim:word,alim:byte,bpb_count:byte
	extrn	fat16_sizes:byte,fat32_sizes:byte,cluster_limits:dword
switchnum equ 11111111000b
flagec35 equ 00000100b
flagdrive equ 00001000b
flagcyln equ 00010000b
flagseclim equ 00100000b
flagheads equ 01000000b
flagff equ 10000000b
flagreserved equ 100000000b
flagroot equ 1000000000b
flagcluster equ 10000000000b

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
	mov	word ptr deviceparameters.DP32_TRACKTABLEENTRIES,0
	mov	dx,offset deviceparameters
	mov	ah,ioctl
	mov	al,generic_ioctl
	mov	ch,rawio32
	mov	cl,set_device_parameters
	int	21h
	jnc	short setparms_done
	cmp	word ptr deviceparameters.DP32_BPB.BPB_SECTORSPERFAT,0
	stc
	jz	short setparms_return
	mov	word ptr deviceparameters.DP_TRACKTABLEENTRIES,0
	mov	ah,ioctl
	mov	al,generic_ioctl
	mov	ch,rawio
	int	21h
	jc	short setparms_return

setparms_done:
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
	clc

setparms_return:
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
	mov	byte ptr deviceparameters.dp_specialfunctions,0
	mov	byte ptr deviceparameters.dp_mediatype,0
	mov	word ptr switches,0	    ; zero all switches
	mov	word ptr hlim,2
	mov	word ptr slim,9
	mov	word ptr vlim,1
	mov	word ptr rlim,224
	mov	byte ptr alim,1
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
	jc	err_swtch

done_swtch:
	clc
	jmp	short check_switch_done

err_swtch:
	xor	bx,cx			; remove this switch from the records
err_check:
	stc
check_switch_done:
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

	or	ah,ah
	jnz	num_error
	cmp	al,bpb_count
	jae	num_error
	mov	byte ptr deviceparameters.dp_devicetype,al
	jmp	short done_ret

try_t:
	test	cx,flagcyln
	jz	try_s
	cmp	ax,1024
	ja	num_error
	mov	word ptr deviceparameters.dp_cylinders,ax
	jmp	short done_ret

try_s:
	or	ax,ax
	jz	done_ret		; if number entered was 0, assume default value
	test	cx,flagseclim
	jz	try_h
	test	ax,0ffc0h
	jnz	num_error
	mov	word ptr slim,ax
	jmp	short done_ret

; Check heads, reserved sectors, root entries and allocation unit.

try_h:
	test	cx,flagheads
	jz	try_v
	or	ah,ah
	jnz	num_error
	mov	word ptr hlim,ax
	jmp	short done_ret
try_v:
	test	cx,flagreserved
	jz	try_r
	mov	word ptr vlim,ax
	jmp	short done_ret
try_r:
	test	cx,flagroot
	jz	try_a
	test	ax,0fh
	jnz	num_error
	mov	word ptr rlim,ax
	jmp	short done_ret
try_a:
	or	ah,ah
	jnz	num_error
	mov	byte ptr alim,al
	or	al,al
	jz	done_ret
	cmp	al,80h
	jae	bad_cluster
check_cluster:
	shr	al,1
	jnc	check_cluster
	jz	done_ret
bad_cluster:
	mov	byte ptr alim,1
	jmp	short num_error

done_ret:
	clc
num_return:
	ret
num_error:
	stc
	jmp	short num_return

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
	test	word ptr switches,flagcyln
	jz	check_cylinders
	cmp	word ptr deviceparameters.dp_cylinders,0
	jne	got_80
	mov	word ptr deviceparameters.dp_cylinders,80
check_cylinders:
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
	.386
	test	word ptr switches,flagreserved+flagroot+flagcluster
	jz	standard_media
	cmp	byte ptr deviceparameters.dp_devicetype,5
	je	bpb_error
	test	word ptr switches,flagreserved
	jz	set_root_entries
	mov	ax,vlim
	or	ax,ax
	jnz	reserved_ready
	inc	ax
reserved_ready:
	mov	deviceparameters.dp_bpb.bpb_reservedsectors,ax
set_root_entries:
	test	word ptr switches,flagroot
	jz	set_cluster_size
	mov	ax,rlim
	or	ax,ax
	jnz	root_ready
	mov	ax,240
root_ready:
	mov	deviceparameters.dp_bpb.bpb_rootentries,ax
set_cluster_size:
	test	word ptr switches,flagcluster
	jz	calculate_capacity
	mov	al,alim
	or	al,al
	jnz	cluster_ready
	inc	al
cluster_ready:
	mov	deviceparameters.dp_bpb.bpb_sectorspercluster,al

; Calculate total sectors and select the FAT and allocation unit sizes.
calculate_capacity:
	mov	ax,deviceparameters.dp_bpb.bpb_heads
	mul	word ptr deviceparameters.dp_bpb.bpb_sectorspertrack
	cli
	movzx	eax,ax
	movzx	ebx,word ptr deviceparameters.dp_cylinders
	mul	ebx
	mov	dword ptr deviceparameters.dp_bpb.bpb_bigtotalsectors,eax
	mov	bx,ax
	test	eax,0ffff0000h
	jz	total_ready
	xor	bx,bx
total_ready:
	mov	deviceparameters.dp_bpb.bpb_totalsectors,bx
	test	word ptr switches,flagcluster
	jz	select_cluster
	cmp	byte ptr alim,0
	jne	explicit_cluster
select_cluster:
	or	bx,bx
	jnz	small_volume
	mov	bx,offset fat16_sizes
	cmp	eax,100000h
	jb	find_capacity
	mov	bx,offset fat32_sizes
	test	word ptr switches,flagreserved
	jz	default_reserved
	cmp	word ptr vlim,0
	jne	find_capacity
default_reserved:
	mov	word ptr deviceparameters.dp_bpb.bpb_reservedsectors,32
find_capacity:
	cmp	eax,dword ptr [bx]
	jbe	capacity_found
	add	bx,10
	jmp	short find_capacity
capacity_found:
	mov	ch,[bx+5]
	mov	cl,[bx+8]
	and	cl,20h
	movzx	edx,word ptr [bx+6]
	or	cl,cl
	jnz	capacity_root_ready
	test	word ptr switches,flagroot
	jz	capacity_root_ready
	cmp	word ptr rlim,0
	je	capacity_root_ready
	movzx	edx,word ptr deviceparameters.dp_bpb.bpb_rootentries
capacity_root_ready:
	mov	deviceparameters.dp_bpb.bpb_rootentries,dx
	mov	deviceparameters.dp_bpb.bpb_sectorspercluster,ch
calculate_fat:
	movzx	edx,word ptr deviceparameters.dp_bpb.bpb_rootentries
	add	edx,15
	shr	edx,4
	sub	eax,edx
	movzx	edx,word ptr deviceparameters.dp_bpb.bpb_reservedsectors
	sub	eax,edx
	movzx	ebx,byte ptr deviceparameters.dp_bpb.bpb_numberoffats
	mov	bh,ch
	or	cl,cl
	jz	fat_divisor_ready
	shr	ebx,1
fat_divisor_ready:
	add	eax,ebx
	dec	eax
	xor	edx,edx
	div	ebx
	or	cl,cl
	jz	store_fat_size
	mov	dword ptr deviceparameters.dp_bpb.bpb_bigsectorsperfat,eax
	xor	ax,ax
store_fat_size:
	mov	deviceparameters.dp_bpb.bpb_sectorsperfat,ax
	sti
	jmp	bpb_done
small_volume:
	sti
	test	word ptr switches,flagroot
	jz	default_root
	cmp	word ptr rlim,0
	jne	small_data_area
default_root:
	mov	dx,224
	cmp	ax,1000h
	jbe	store_small_root
	mov	dx,512
	cmp	ax,4000h
	jb	small_data_area
store_small_root:
	mov	deviceparameters.dp_bpb.bpb_rootentries,dx
small_data_area:
	mov	dx,deviceparameters.dp_bpb.bpb_reservedsectors
	sub	ax,dx
	mov	dx,deviceparameters.dp_bpb.bpb_rootentries
	add	dx,15
	shr	dx,4
	sub	ax,dx
	mov	dl,1
small_cluster:
	cmp	ax,0ff6h
	jb	small_cluster_ready
	shr	ax,1
	shl	dl,1
	jmp	short small_cluster
small_cluster_ready:
	mov	deviceparameters.dp_bpb.bpb_sectorspercluster,dl
fat12_size:
	sti
	mov	dx,ax
	shl	ax,1
	add	ax,dx
	shr	ax,1
	add	ax,511
	shr	ax,9
	jmp	short store_fat_size
explicit_cluster:
	mov	ch,deviceparameters.dp_bpb.bpb_sectorspercluster
	mov	cl,ch
	xor	bx,bx
cluster_limit_index:
	shr	cl,1
	jc	cluster_limit_ready
	add	bx,8
	jmp	short cluster_limit_index
cluster_limit_ready:
	add	bx,offset cluster_limits
	cmp	eax,dword ptr [bx]
	jbe	explicit_fat12
	mov	cl,0
	cmp	eax,dword ptr [bx+4]
	jbe	explicit_fat_ready
	inc	cl
	mov	word ptr deviceparameters.dp_bpb.bpb_rootentries,0
	test	word ptr switches,flagreserved
	jz	explicit_reserved
	cmp	word ptr vlim,0
	jne	explicit_fat_ready
explicit_reserved:
	mov	word ptr deviceparameters.dp_bpb.bpb_reservedsectors,32
explicit_fat_ready:
	jmp	calculate_fat
explicit_fat12:
	movzx	edx,word ptr deviceparameters.dp_bpb.bpb_rootentries
	add	edx,15
	shr	edx,4
	sub	ax,dx
	sub	ax,deviceparameters.dp_bpb.bpb_reservedsectors
	xor	cl,cl
	xchg	cl,ch
	xor	dx,dx
	div	cx
	jmp	short fat12_size

standard_media:


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

bpb_done:
	clc
bpb_return:
	sti
	ret
bpb_error:
	stc
	jmp	short bpb_return
	.8086

setdeviceparameters	endp
	



sysinitseg ends
	end
