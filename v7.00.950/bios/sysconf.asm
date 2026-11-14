	page	,160
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	title	bios system initialization
;
;----------------------------------------------------------------------------
;
; M002 : Change for leaving the UMBs in an unlinked state
;
; M003 : Fixed a parse in the DOS= command
;
; M004 : Fixed bug #2005. The file name copied into the device driver arena
;        contained the full pathname. modified it to copy only the file nmae
;        part
;
; M005 : Fixed a bug in the umb insert code. The prev arena ptr was not
;        being updated when traversing the arena chain.
;
;
; M007 : DeviceHi flag was not reset after a DEVICEHIGH. Which forced all
;        subsequent devices in config.sys to be loaded in UMB
;
; M009 : Case of multiple device drivers in a single file where the last
;        device driver fails was not being handled properly.
;
; M016 : Enabling the /X optionin buffers, so that DOS 5.0 does not crib
;	 about /X in old config.sys files. /X is totally ignored now.
;
; M017 : Ignoring the keep count in FCBS= command
;
; M020 : The PDB_Block_Len field is updated to alloclim before
;	 each device driver call. This fix is put specifically for loading
;	 periscope using sysload.sys
;
; M023 : Increased country='s buffer from 2K to 6K
;
; M027 : We will pass the memory limit of a device driver in the break addr
;	 field only for the 1st device driver in a file.
;
; M045 : Backing out OS/2 device driver check
;
; M049 : initialize device header of block device with unit count
;
; M050 : Changed parse limit of buffers from 10000 to 99
;
; M059 : Bug #5002. Treat rollover byte as a count instead of a flag, if
;			t_switch is not set.
;
; M063 : Bug #4984. Added SWITCHES=/W for suppressing mandatory loading of
;		WINA20.386
;
;----------------------------------------------------------------------------
;
;==============================================================================

MULTI_CONFIG equ 1

	.xlist
	include version.inc		; set version build flags
	include biosseg.inc		; establish bios segment structure
	include	magicdrv.inc		; get MagicDrv equates
	.list

lf	equ	10
cr	equ	13
tab	equ	 9

HIGH_FIRST            equ     080h      ; from ARENA.INC - modifier for
                                        ; allocation strategy call

have_install_cmd      equ     00000001b ; config.sys has install= commands
has_installed	      equ     00000010b ; sysinit_base installed.

default_filenum = 8

	break	macro	; dummy empty macro
	endm

	.xlist
	include sysvar.inc
	include dpb.inc
	include curdir.inc
	include	pdb.inc			; M020
	include syscall.inc
	include doscntry.inc
	include devsym.inc
	include devmark.inc
        include config.inc

	include	umb.inc
	.xlist			; *** umb.inc re-enables listing!
	include	dossym.inc
	.list

stacksw equ	true		;include switchable hardware stacks

	if	ibmjapver
noexec	equ	true
	else
noexec	equ	false
	endif




; external variable defined in ibmbio module for multi-track

multrk_on	equ	10000000b	;user spcified mutitrack=on,or system turns
					; it on after handling config.sys file as a
					; default value,if multrk_flag = multrk_off1.
multrk_off1	equ	00000000b	;initial value. no "multitrack=" command entered.
multrk_off2	equ	00000001b	;user specified multitrack=off.

Bios_Data segment 
	extrn   int16_entry:far,int4f_entry:far
	extrn   int16_old:dword,int4f_old:dword
	extrn   bios_flags:word
	extrn	keyrd_func:byte
	extrn	keysts_func:byte
Bios_Data ends

; end of multi-track definition.

Bios_Code segment
	extrn   keyboard_vector_install:near,keyboard_vector_setup:near
	extrn   i2f_handler:far
	extrn   win386_info_flags:byte
Bios_Code ends

sysinitseg	segment 

IFDEF	CONFIGPROC
assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

	extrn	area:word

	ifdef	dblspace_hooks
	extrn	MagicBackdoor:dword
	endif

	extrn   bios_data_segment:word,BCodeSeg:word
	extrn   query_mode_flags:byte,boot_runtime_flags:byte
	extrn   dos_umb_flag:byte
	extrn   sysinit_msg_base:byte,sysinit_msg_table:word
	extrn   boot_emm_name:byte
	extrn   boot_logo_display:near
	extrn   singlebuffersize:word,temp_buffer_segment:word,temp_buffer_size:word
	extrn	badopm:byte,crlfm:byte,badmem:byte
	extrn	badsiz_pre:byte,badld_pre:byte
	extrn	badstack:byte,badcountrycom:byte
        extrn   badcountry:byte,insufmemory:byte
	extrn	condev:byte,auxdev:byte,prndev:byte,commnd:byte,config:byte
	extrn	cntry_drv:byte,cntry_root:byte,cntry_path:byte
	extrn	deviceparameters:byte
	extrn	memory_size:word
	extrn	buffers:word
	extrn	files:byte,num_cds:byte
	extrn	dosinfo:dword
	extrn	fcbs:byte,keep:byte
	extrn	confbot:word,alloclim:word,command_line:byte
	extrn	zero:byte,sepchr:byte
	extrn	count:word,chrptr:word,cntryfilehandle:word
	extrn	memlo:word,memhi:word,prmblk:word,ldoff:word
	extrn	packet:byte,unitcount:byte,break_addr:dword
	extrn	bpb_addr:dword,drivenumber:byte,sysi_country:dword
	extrn	devdrivenum:byte
	extrn	config_size:word
	extrn	install_flag:byte
        extrn   errorcmd:byte
	extrn	linecount:word
	extrn	showcount:byte
	extrn	buffer_linenum:word
	extrn	h_buffers:word
	extrn	badparm:byte
	extrn	configmsgflag:word
	extrn	org_count:word
	extrn	multi_pass_id:byte

	if	noexec
	extrn	mem_err:near
	endif
	extrn	setdoscountryinfo:near
	extrn	pararound:near,tempcds:near
	extrn	set_country_path:near,move_asciiz:near,delim:near
	extrn	badfil:near
	extrn	do_install_exec:near

	extrn	print:near,organize:near,newline:near
	extrn	print_indexed:near,stall:near
	extrn	query_bios_call:near
	extrn	diddleback:near,parseline:near,setparms:near
	extrn	badload:near,calldev:near,prnerr:near

	extrn	runhigh:byte
	extrn	IsXMSLoaded:near
	extrn   boot_umb_driver_record:word,boot_process_driver_record:near

ifndef ROMDOS
	extrn	TryToMovDOSHi:near
endif

ifdef	COPYCDS
	extrn	newnum_cdss:word
endif ; COPYCDS

ifdef DBCS
	extrn	testkanj:near
endif

	if	stacksw

; internal stack parameters

entrysize	equ	8

mincount	equ	8
defaultcount	equ	9
maxcount	equ	64

minsize 	equ	32
defaultsize	equ	256
maxsize 	equ	512

DOS_FLAG_OFFSET	equ	86h

	extrn  stack_count:word
	extrn  stack_size:word
	extrn  stack_addr:dword

	endif

	public doconf
	public getchr
	public multi_pass

;	the syspre module needs hooks back into us, for routines and
;	variables.  Here they are made public.

	public	DevBrkAddr,DevCmdLine,DevSizeOption
	public	ExecDev,InitDevLoad,DevSetBreak
	public	DevLoadAddr,DevBreak,DevSize
	public	ConvLoad,RoundBreakAddr
	public	DeviceHi,SizeDevice,DevLoadEnd



ifdef   MULTI_CONFIG
;
;   config_envlen must immediately precede config_wrkseg, because they
;   may be loaded as a dword ptr
;
	public  config_access_table
config_access_table dd  0               ; per-drive access-date settings
        public  config_envlen           ; when config_wrkseg is being used as
config_envlen   dw  0                   ; a scratch env, this is its length

        public  config_wrkseg           ; config work area (above confbot)
config_wrkseg   dw  0                   ; segment of work area

        public  config_cmd              ; current config cmd
config_cmd      db  0                   ; (with CONFIG_OPTION_QUERY bit intact)

        public  config_multi            ;
config_multi    db  0                   ; non-zero if multi-config config.sys

        extrn   newcmd:byte
        extrn   set_numlock:near
        extrn   query_user:near
        extrn   copy_envvar:near

endif  ;MULTI_CONFIG


	public	setdevmarkflag
setdevmarkflag	    db	    0		;flag used for devmark

	public	multdeviceflag
multdeviceflag	db	0
ENDIF ; CONFIGPROC

driver_units	db	0		;total unitcount for driver
	public  config_ebda_limit
config_ebda_limit dw    400h            ; maximum EBDA area to examine

IFDEF	CONFIGPROC

IFDEF	DONT_LOAD_OS2_DD		; M045

Os2ChkBuf	DD	0		; Tmp read buffer

ENDIF					; M045

badparm_ptr	label	dword
badparm_off	dw	0
badparm_seg	dw	0

;******************************************************************************
;take care of config.sys file.
;system parser data and code.
;******************************************************************************

;*******************************************************************
; parser options set for msbio sysconf module
;*******************************************************************
;
;**** default assemble swiches definition **************************

	ifndef	farsw
farsw	equ	0	; near call expected
	endif

	ifndef	datesw
datesw	equ	0	; check date format
	endif

	ifndef	timesw
timesw	equ	0	; check time format
	endif

	ifndef	filesw
filesw	equ	1	; check file specification
	endif

	ifndef	capsw
capsw	equ	0	; perform caps if specified
	endif

	ifndef	cmpxsw
cmpxsw	equ	0	; check complex list
	endif

	ifndef	numsw
numsw	equ	1	; check numeric value
	endif

	ifndef	keysw
keysw	equ	0	; support keywords
	endif

	ifndef	swsw
swsw	equ	1	; support switches
	endif

	ifndef	val1sw
val1sw	equ	1	; support value definition 1
	endif

	ifndef	val2sw
val2sw	equ	0	; support value definition 2
	endif

	ifndef	val3sw
val3sw	equ	1	; support value definition 3
	endif

	ifndef	drvsw
drvsw	equ	1	; support drive only format
	endif

	ifndef	qussw
qussw	equ	0	; support quoted string format
	endif


PARSE_STRING_LENGTH equ 104h		; extended parser string buffer

$P_Compare_AL macro
	db	38h,0c0h		; cmp al,al
	endm

	.xlist
	include parse.asm		;together with psdata.inc
	.list


;control block definitions for parser.
;---------------------------------------------------
; buffer = [n | n,m] {/e}

p_parms struc
	dw	?
	db	1		; an extra delimiter list
	db	1		; length is 1
	db	';'		; delimiter
p_parms ends

p_pos	struc
	dw	?		; numeric value??
	dw	?		; function
	dw	?		; result value buffer

; note: by defining result_val before this structure, we could remove
;  the "result_val" from every structure invocation

	dw	?		; value list
	db	0		; no switches/keywords
p_pos	ends

p_range struc
	db	1		; range definition
	db	1		; 1 definition of range
	db	1		; item tag for this range
	dd	?		; numeric min
	dd	?		; numeric max
p_range ends

buf_parms p_parms <buf_parmsx>
buf_parmsx dw	201h,buf_pos1,buf_pos2	; min 1, max 2 positionals
	   db	1			; one switch
	   dw	sw_x_ctrl
	   db	0			; no keywords

buf_pos1    p_pos   <8000h,0,result_val,buf_range_1> ; numeric
buf_range_1 p_range <,,,1,99>			     ; M050
buf_pos2    p_pos   <8001h,0,result_val,buf_range_2> ; optional num.
buf_range_2 p_range <,,,0,8>

sw_x_ctrl p_pos <0,0,result_val,noval,1> ; followed by one switch
switch_x  db	'/X',0			; M016

p_buffers	dw	0	; local variables
p_h_buffers	dw	0
p_buffer_slash_x db	0
	public  p_buffers_high
p_buffers_high db 0                     ; request high-memory buffers

;common definitions ------------
noval	db	0

result_val	label	byte
	db	?		; type returned
	db	?		; item tag returned
	dw	?		; es:offset of the switch defined
rv_byte 	label	byte
rv_dword dd	?		; value if number,or seg:offset to string.
;-------------------------------

; break = [ on | off ]

brk_parms	p_parms  <brk_parmsx>

brk_parmsx dw	101h,brk_pos	; min,max = 1 positional
	   db	0		; no switches
	   db	0		; no keywords

brk_pos p_pos	<2000h,0,result_val,on_off_string> ; simple string

on_off_string	label	byte
	db	3		; signals that there is a string choice
	db	0		; no range definition
	db	0		; no numeric values choice
	db	2		; 2 strings for choice
	db	1		; the 1st string tag
	dw	on_string
	db	2		; the 2nd string tag
	dw	off_string

on_string	db	"ON",0
off_string	db	"OFF",0

swit_e_range p_range <,,2,30h,400h>
	db	0,0		; purpose not yet established

p_ctrl_break	db	0	; local variable

;--------------------------------

; country = n {m {path}}
; or
; country = n,,path

cntry_parms	p_parms <cntry_parmsx>

cntry_parmsx dw	301h,cntry_pos1,cntry_pos2,cntry_pos3 ; min 1, max 3 pos.
	     db	0		; no switches
	     db	0		; no keywords

cntry_pos1 p_pos <8000h,0,result_val,cc_range> ; numeric value
cc_range p_range <,,,1,999>
cntry_pos2 p_pos <8001h,0,result_val,cc_range> ; optional num.
cntry_pos3 p_pos <201h,0,result_val,noval>     ; optional filespec

p_cntry_code	dw	0	; local variable
p_code_page	dw	0	; local variable

;--------------------------------

; files = n

files_parms	p_parms <files_parmsx>

files_parmsx dw	101h,files_pos	; min,max 1 positional
	     db	0		; no switches
	     db	0		; no keywords

files_pos   p_pos   <8000h,0,result_val,files_range,0> ; numeric value
files_range p_range <,,,8,255>

p_files db	0		; local variable
	public  p_files_high
p_files_high db 0

;-------------------------------

; fcbs = n,m

fcbs_parms	p_parms <fcbs_parmsx>

fcbs_parmsx dw	201h,fcbs_pos_1,fcbs_pos_2 ; min,max = 2 positional
	    db	0		; no switches
	    db	0		; no keywords

fcbs_pos_1	p_pos	<8000h,0,result_val,fcbs_range> ; numeric value
fcbs_range	p_range	<,,,1,255>
fcbs_pos_2	p_pos	<8000h,0,result_val,fcbs_keep_range> ; numeric value
fcbs_keep_range p_range <,,,0,255>

p_fcbs	db	0		; local variable
p_keep	db	0		; local variable
	public  p_fcbs_high
p_fcbs_high db 0

;-------------------------------
; lastdrive = x

ldrv_parms	p_parms <ldrv_parmsx>

ldrv_parmsx dw	101h,ldrv_pos	; min,max = 1 positional
	    db	0		; no switches
	    db	0		; no keywords

ldrv_pos p_pos	<110h,10h,result_val,noval> ; drive only, ignore colon
					    ; remove colon at end
p_ldrv	db	0		; local variable
	public  p_ldrv_high
p_ldrv_high db 0

;-------------------------------

; stacks = n,m

stks_parms	p_parms <stks_parmsx>

stks_parmsx dw	202h,stks_pos_1,stks_pos_2 ; min,max = 2 positionals
	    db	0		; no switches
	    db	0		; no keywords

stks_pos_1     p_pos   <8000h,0,result_val,stks_range> ; numeric value
stks_range     p_range <,,,0,64>
stks_pos_2     p_pos   <8000h,0,result_val,stk_size_range> ; numeric value
stk_size_range p_range <,,,0,512>

p_stack_count	dw	0	; local variable
p_stack_size	dw	0	; local variable
	public	stack_high
stack_high	db	0

;-------------------------------

; multitrack = [ on | off ]

mtrk_parms	p_parms <mtrk_parmsx>

mtrk_parmsx dw	101h,mtrk_pos	; min,max = 1 positional
	    db	0		; no switches
	    db	0		; no keywords

mtrk_pos p_pos	<2000h,0,result_val,on_off_string> ; simple string

p_mtrk	db	0		; local variable

;-------------------------------
; switches=/k

swit_parms	p_parms <swit_parmsx>

swit_parmsx dw  0                       ; no positionals
	    db  8                       ; number of switches
	    dw  swit_k_ctrl,swit_t_ctrl,swit_w_ctrl,swit_c_ctrl
	    dw  swit_n_ctrl,swit_f_ctrl,swit_d_ctrl,swit_e_ctrl
	    db  0                       ; no keywords

	public  swit_n,swit_f
swit_k_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_k db	'/K',0
swit_t_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows	M059
swit_t db	'/T',0			   ;				M059
swit_w_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows	M063
swit_w db	'/W',0			   ;				M063
swit_c_ctrl p_pos <0,0,result_val,noval,1>
swit_c  db      '/C',0
swit_n_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_n db       '/N',0
swit_f_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_f db       '/F',0
swit_d_ctrl p_pos <0,0,result_val,noval,1>
swit_d  db      '/D',0
swit_e_ctrl p_pos <8001h,0,result_val,swit_e_range,1>
swit_e  db      '/E',0

;   There doesn't need to be p_swit_n or p_swit_f because /N and /F are
;   acted upon during MULTI_CONFIG processing;  we only needed entries
;   in the above table to prevent the parsing code from complaining about them

p_swit_k	db     0	; local variable
p_swit_t	db     0	; local variable			M059
p_swit_w	db     0	; local variable			M063
p_swit_c        db      0
p_dos_hi        db      0       ; local variable
dos_opt_count   db      0ffh    ; number of DOS= options processed

;-------------------------------

; DOS = [ high | low ]

dos_parms	p_parms  <dos_parmsx>

dos_parmsx db	1		; min parameters
	   db	4		; max parameters
	   dw	dos_pos		; 
	   dw	dos_pos		; 
	   dw	dos_pos		; 
	   db	0		; no switches
	   db	0		; no keywords

dos_pos p_pos	<2000h,0,result_val,dos_strings> ; simple string

dos_strings	label	byte
	db	3		; signals that there is a string choice
	db	0		; no range definition
	db	0		; no numeric values choice
	db	7		; 7 strings for choice
	db	1		; the 1st string tag
	dw	hi_string
	db	2		; the 2nd string tag
	dw	lo_string
	db	3
	dw	umb_string
	db	4
	dw	noumb_string
	db	5
	dw	auto_string
	db	6
	dw	noauto_string
	db	7
	dw	single_string

hi_string	db	"HIGH",0
lo_string	db	"LOW",0
umb_string	db	"UMB",0
noumb_string	db	"NOUMB",0
auto_string	db	"AUTO",0
noauto_string	db	"NOAUTO",0
single_string	db	"SINGLE",0


;****************************************************************** RICHID ****

include	highvar.inc		; devicehigh variables (used by loadhigh also)

;****************************************************************** RICHID ****

		public	DevEntry

DevSize		dw	?	; size of the device driver being loaded(paras)
DevLoadAddr	dw	?	; Mem addr where the device driver is 2 b loaded
DevLoadEnd	dw	?	; MaxAddr to which device can be loaded
DevEntry	dd	?	; Entry point to the device driver
DevBrkAddr	dd	?	; Break address of the device driver
ConvLoad	db	?	; Use conventional (dos 5 -style) InitDevLoad?
;
	public  DevUMB
DevUMB		db	0	; byte indicating whether to load DDs in UMBs
DevUMBActive	db	0	; UMB allocation is active
DevUMBAddr	dw	0	; cuurent UMB used fro loading devices (paras)
DevUMBSize	dw	0	; Size of the current UMB being used   (paras)
DevUMBFree	dw	0	; Start of free are in the current UMB (paras)
;
DevXMSAddr	dd	?
;
DevExecAddr	dw	?	; Device load address parameter to Exec call
DevExecReloc	dw	?	; Device load relocation factor
;
DeviceHi	db	0	; Flag indicating whther the current device
				;  is being loaded into UMB
DevSizeOption	dw	?	; SIZE= option
;
Int12Lied	db	0	; did we trap int 12 ?
OldInt12Mem	dw	?	; value in 40:13h (int 12 ram)
ThreeComName	db	'PROTMAN$'	; 3Com Device name
ATIVideoName	db	'ATiVideo'
QEMMName	db	'QEMM386$'
QLoaderName	db	'QLODR$10'
StacCDName	db	'?STAC-CD'
ProTName	db	'ProT',82h,67h,82h,57h
DevOriginalCmdLine dd	0
;
FirstUMBLinked	db	0
DevDOSData	dw	?	; segment of DOS Data
DevCmdLine	dd	?	; Current Command line
DevSavedDelim	db	?	; The delimiter which was replaced with null
				; to use the file name in the command line
;
	ifdef	dblspace_hooks
MagicHomeFlag	db	0	; set non-zero when MagicDrv is final placed
	endif

; State used while recording device and interrupt-vector changes.
	public  config_record_ptr
config_record_ptr       dd      0
	public  config_record_count
config_record_count     dw      0
config_record_name      db      'IO      SYS'
config_record_flags     dw      0
	                db      0
config_record_vectors   label   byte
	irp     aa,<1,2,3,4,5,6,7,8,9>
	db      aa
	dw      -1,-1
	endm
	db      10
	dw      0,0
config_cds_drivers      dd      26 dup (-1)
config_int_vectors      dd      16 dup (-1)

scsi_device_name        db      'SCSIMGR$',0
scsi_device_entry       dd      0
config_cds_changed      dd      0
config_mbr_record        db      'MBRINT13SYS',0,0,0,1,2

	public  config_hook_active
config_hook_active db      0
	public  config_device_segment
config_device_segment dw  0             ; segment supplied by device-load hook

config_file_time dw     0               ; CONFIG.SYS last write time
config_file_date dw     0               ; CONFIG.SYS last write date

;----------------------------------------------------------------------------
;
; procedure : doconf
;
;             Config file is parsed intitially with this routine. For the
;             Subsequent passes 'multi_pass' entry is used .
;
;----------------------------------------------------------------------------
;
doconf	proc	near
	push	cs
	pop	ds
	assume	ds:sysinitseg


	mov	dx,offset config	;now pointing to file description
	mov	ax,open shl 8		;open file "config.sys"
	stc				;in case of int 24
	int	21h			;function request
	jnc	noprob			; brif opened okay

config_missing:
	mov     ax,[alloclim]           ; reserve an environment workspace
	sub     ax,20h
	mov     [config_wrkseg],ax
	mov     es,ax
	mov     byte ptr es:[0],0
	mov     [alloclim],ax

	mov	multi_pass_id,11	; set it to unreasonable number
	ret
noprob: 				;get file size (note < 64k!!)
	xchg    ax,bx
	xor	cx,cx
	xor	dx,dx
	mov	ax,(lseek shl 8) or 2
	int	21h
	test    dx,dx                   ; limit file size to 64K-1
	jz      config_size_ok
	or      ax,-1
config_size_ok:
	push    ax
	push    bx
	and     byte ptr [query_mode_flags],0bfh
	mov     byte ptr [config_cmd],1
	mov     dx,offset sysinit_msg_base
	add     dx,word ptr [sysinit_msg_table+72]
	call    query_user
	pop     bx
	pop     ax
	jnc     config_accepted
	mov     ah,close
	int     21h
	jmp     short config_missing
config_accepted:
	mov	[count],ax

	xor	cx,cx
	xor	dx,dx
	mov	ax,lseek shl 8		;reset pointer to beginning of file
	int	21h

	mov	dx,[alloclim]		;use current alloclim value
	mov	ax,[count]
	mov	[config_size],ax	;save the size of config.sys file.
	call	pararound
	sub	dx,ax

ifdef   MULTI_CONFIG
;
;   Reserve the environment workspace in addition to the space needed
;   to rebuild the in-memory CONFIG.SYS image.
;
	sub     dx,20h                  ;reserve environment workspace
	mov     [config_wrkseg],dx
	mov     es,dx
	mov     byte ptr es:[0],0
	sub     dx,ax
endif  ;MULTI_CONFIG

	sub	dx,11h			;room for header
	mov	[alloclim],dx		; config starts here. new alloclim value.
	mov	[confbot],dx
	mov	ds,dx
	mov	es,dx

	assume	ds:nothing,es:nothing
	xor	dx,dx
	mov	cx,[count]
	mov	ah,read
	stc				;in case of int 24
	int	21h			;function request
	pushf

; find the eof mark in the file.  if present,then trim length.

	push	ax
	push	di
	push	cx
	mov	al,1ah			; eof mark
	mov	di,dx			; point ro buffer
	jcxz	puteol			; no chars
	repnz	scasb			; find end
	jnz	puteol			; none found and count exahusted

; we found a 1a.  back up

	dec	di			; backup past 1a

;  just for the halibut,stick in an extra eol

puteol:
	mov	al,cr
	stosb
	mov	al,lf
	stosb
	sub	di,dx			; difference moved
	mov	count,di		; new count

	pop	cx
	pop	di
	pop	ax

	push	cs
	pop	ds
	assume	ds:sysinitseg

	push	ax
	push    cx
	push    dx
	mov     ax,5700h                ; get CONFIG.SYS date and time
	int     21h
	mov     [config_file_time],cx
	mov     [config_file_date],dx
	pop     dx
	pop     cx
	mov	ah,close
	int	21h
	pop	ax
	popf
	jc	conferr 		;if not we've got a problem
	cmp	cx,ax
	jz	getcom			;couldn't read the file

conferr:
	mov	dx,offset config	;want to print config error
	call	badfil
endconv:
	ret

;
;----------------------------------------------------------------------------
;
; entry : multi_pass
;
;             called to execute device=,install= commands
;
;----------------------------------------------------------------------------
;

multi_pass:
	push	cs
	pop	ds

	cmp	multi_pass_id,10
jae_endconv:
	jae	endconv 		; do nothing. just return.

	mov     ax,[org_count]
	mov     [count],ax
	mov     word ptr [chrptr],0
	public  multi_pass_config_line
multi_pass_config_line:
	push    [confbot]
	pop     es
	mov     word ptr [linecount],0

	call	getchr
	jmp	short conflp

getcom:
        call    organize                ; organize the file
	call	getchr

conflp: jc	endconv

        inc     linecount               ; increase linecount

	mov	multdeviceflag,0	; reset multdeviceflag.
	cmp	al,lf			; linefeed?
	je	blank_line		;  then ignore this line.

ifdef   MULTI_CONFIG
;
;   If this is a genuine CONFIG.SYS command, then there should be a line
;   number immediately following it....
;
        mov     [config_cmd],al         ; save original command code
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     [config_multi],0        ; is this a multi-config config.sys?
        je      not_final               ; no, line number is not embedded

        push    ax                      ;
        call    getchr                  ; ignore end-of-image errors,
        mov     ah,al                   ; because if there's an error
        call    getchr                  ; fetching the line number that's
        xchg    al,ah                   ; supposed to be there, the next
        mov     [linecount],ax          ; getchr call will get the same error
	pop     ax
;
;   HACK: when 4DOS.COM is the shell and it doesn't have an environment from
;   which to obtain its original program name, it grovels through all of
;   memory to find the filename that was used to exec it;  it wants to find
;   the SHELL= line in the in-memory copy of CONFIG.SYS, and it knows that
;   sysinit converts the SHELL= keyword to an 'S', so it expects to find an 'S'
;   immediately before the filename, but since we are now storing line # info
;   in the config.sys memory image, 4DOS fails to find the 'S' in the right
;   spot.
;
;   So, on the final pass of CONFIG.SYS, copy the command code (eg, 'S')
;   over the line number info, since we no longer need that info anyway.  This
;   relies on the fact that getchr leaves ES:SI pointing to the last byte
;   retrieved.
;
        cmp     multi_pass_id,2         ; final pass?
        jb      not_final               ; no
        test    install_flag,have_install_cmd
        jz      final                   ; no install cmds, so yes it is
        cmp     multi_pass_id,3         ; final pass?
        jb      not_final               ; no
final:                                  ;
        mov     es:[si],al              ; save backward-compatible command code

not_final:                              ;
endif
	mov	ah,al
	call	getchr
	jnc	tryi

	cmp	multi_pass_id,2
        jae     jae_endconv             ; do not show badop again for multi_pass.
	jmp	badop

coff:	push	cs
	pop	ds
	call	newline
	jmp	conflp

blank_line:
	call	getchr
	jmp	conflp

coff_p:
	push	cs
	pop	ds


; Pass 0 handles DOS, SWITCHES and LOGO options.  Pass 1 handles the
; remaining options and records deferred commands.  Pass 2 loads devices;
; pass 3 handles INSTALL, INSTALLHIGH and access-date settings.

;------------------------------------------------------------------------------
;install command
;------------------------------------------------------------------------------
tryi:
	cmp	multi_pass_id,0		; the initial pass for DOS=HI
	jne	not_init_pass
	cmp     ah,CONFIG_DEVICE
	je      short scan_qemm_device
	cmp     ah,CONFIG_DEVICEHIGH
	je      short scan_qemm_device
	jmp     multi_try_doshi
scan_qemm_device:
	call    config_check_qemm
	jmp     multi_pass_coff
not_init_pass:

	cmp	multi_pass_id,2		; load device drivers on this pass
	je      multi_pass_device

	cmp	multi_pass_id,3		; the third pass for install= ?
	je	multi_try_i
        cmp     ah, CONFIG_DOS
	jne     short check_logo_pass
	jmp     multi_pass_coff
check_logo_pass:

;       make note of any INSTALL= or INSTALLHIGH= commands we find,
;       but don't process them now.        
        
	cmp     ah,'q'                  ; LOGO= handled on initial pass
	jne     short check_install_pass
	jmp     multi_pass_coff
check_install_pass:

	cmp     ah,CONFIG_ACCDATE
	je      mark_install_command
        cmp     ah,CONFIG_INSTALL               ; install= command?
	je      mark_install_command
	cmp     ah,CONFIG_INSTALLHIGH
	je      mark_install_command
	jmp     tryb
mark_install_command:
	or      install_flag,have_install_cmd
multi_pass_coff2:
	jmp     short coff

multi_pass_device:
	cmp     ah,CONFIG_DEVICE
	jne     multi_pass_devicehigh
	jmp     near ptr tryd
multi_pass_devicehigh:
	cmp     ah,CONFIG_DEVICEHIGH
	jne     multi_pass_filter
	jmp     near ptr tryu

multi_try_i:
        cmp     ah, CONFIG_INSTALL      ; install= command?
        jne     multi_try_n             ; no, check for installhigh
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      multi_pass_filter       ; has the CONFIG_OPTION_QUERY bit set
endif
	call	do_install_exec 	;install it.
	jmp	short coff			;to handle next install= command.

multi_try_n:
        cmp     ah,CONFIG_INSTALLHIGH   ; installhigh= command?
	jne     multi_try_accdate
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      multi_pass_filter       ; has the CONFIG_OPTION_QUERY bit set
endif

;       The memory environment is in its normal DOS state, so do
;       the standard calls to set the alloc strategy for loading high

	mov	ax,(ALLOCOPER shl 8) OR 0
	int	21h			;get alloc strategy
	mov	bx,ax
        push    bx                      ; save for the return

        or	bx,HIGH_FIRST		;set alloc to HighFirst
	mov	ax,(ALLOCOPER shl 8) OR 1
	int	21h			;set alloc strategy

	mov     ax,(ALLOCOPER shl 8) OR 2 
        int     21h                     ; get link state
        xor     ah,ah                   ; clear top byte
        push    ax                      ; save for return

        mov	ax,(ALLOCOPER shl 8) OR 3
	mov	bx,1
	int	21h			;link in UMBs

	call	do_install_exec 	;install it.

        mov     ax,(ALLOCOPER shl 8) OR 3
        pop     bx                      ; recover original link state
	int     21h
        pop     bx                      ; recover original alloc strategy
        mov     ax,(ALLOCOPER shl 8) OR 1
	int     21h

	jmp	coff			;to handle next install= command.

multi_try_accdate:
	cmp     ah,CONFIG_ACCDATE
	je      accdate_command
multi_pass_filter:
        cmp     ah, CONFIG_COMMENT      ; comment?
	je	multi_pass_adjust
        cmp     ah, CONFIG_UNKNOWN      ; bad command?
	je	multi_pass_adjust
        cmp     ah, CONFIG_REM          ; rem?
	jne	multi_pass_coff 	; ignore the rest of the commands.

multi_pass_adjust:			; these commands need to
	dec	chrptr			;  adjust chrptr,count
	inc	count			;  for newline proc.

multi_pass_coff:
	jmp	coff			; to handle next install= commands.

; Set or clear access-date recording for each named drive.
accdate_command:
	call    query_user
	jc      multi_pass_filter
	assume  ds:sysinitseg
	lds     di,[config_access_table]
	assume  ds:nothing
	jmp     short accdate_character
accdate_next:
	call    getchr
	jc      multi_pass_coff
accdate_character:
	cmp     al,' '
	je      accdate_next
	cmp     al,tab
	je      accdate_next
	cmp     al,cr
	je      accdate_next
	cmp     al,lf
	je      multi_pass_coff
	and     al,not 20h
	sub     al,'A'
	jb      accdate_invalid
	cmp     al,26
	jae     accdate_invalid
	cbw
	xchg    ax,bx
	call    getchr
	jc      accdate_invalid
	cmp     al,'+'
	jne     accdate_minus
	or      byte ptr [bx+di],6
	jmp     short accdate_next
accdate_minus:
	cmp     al,'-'
	jne     accdate_invalid
	and     byte ptr [bx+di],not 6
	jmp     short accdate_next
accdate_invalid:
	jmp     near ptr accdate_error

;------------------------------------------------------------------------------
; buffer command
;------------------------------------------------------------------------------
;*******************************************************************************
;									      *
; function: parse the parameters of buffers= command.			      *
;									      *
; input :								      *
;	es:si -> parameters in command line.				      *
; output:								      *
;	buffers set							      *
;	buffer_slash_x	flag set if /x option chosen.			      *
;	h_buffers set if secondary buffer cache specified.		      *
;									      *
; subroutines to be called:						      *
;	sysinit_parse							      *
; logic:								      *
; {									      *
;	set di points to buf_parms;  /*parse control definition*/	      *
;	set dx,cx to 0; 						      *
;	reset buffer_slash_x;						      *
;	while (end of command line)					      *
;	{ sysinit_parse;						      *
;	  if (no error) then						      *
;	       if (result_val.$p_synonym_ptr == slash_e) then /*not a switch  *
;		    buffer_slash_x = 1					      *
;	       else if	 (cx == 1) then 	    /* first positional */    *
;			  buffers = result_val.$p_picked_val;		      *
;		    else  h_buffers = result_val.$p_picked_val; 	      *
;	  else	{show error message;error exit} 			      *
;	};								      *
;	if (buffer_slash_x is off & buffers > 99) then show_error;	      *
; };									      *
;									      *
;*******************************************************************************

	assume  ds:sysinitseg
tryb:
        cmp     ah,CONFIG_BUFFERS
	jne     try_buffershigh
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
	jc      try_buffershigh
endif
parse_buffers:
	mov	p_buffer_slash_x,0
	mov	di,offset buf_parms
	xor	cx,cx
	mov	dx,cx

do7:
	call	sysinit_parse
	jnc	if7			; parse error,
	call	badparm_p		;   and show messages and end the search loop.
	jmp	short sr7

if7:
	cmp	ax,$p_rc_eol		; end of line?
	jz	en7			;  then jmp to $endloop for semantic check
	cmp	result_val.$p_synonym_ptr,offset switch_x
	jz	do7

;	mov	p_buffer_slash_x,1	; set the flag M016
	mov	ax,word ptr result_val.$p_picked_val
	cmp	cx,1
	jnz	if13

	mov	p_buffers,ax
	jmp	do7

if13:
	mov	p_h_buffers,ax
	jmp	do7

en7:
	cmp	p_buffers,99
	jbe	if18
;	cmp	p_buffer_slash_x,0	; M016
;	jnz	if18

	call	badparm_p
	mov	p_h_buffers,0
	jmp	short sr7

if18:
	mov	ax,p_buffers	; we don't have any problem.
	mov	buffers,ax	; now,let's set it really.

	mov	ax,p_h_buffers
	mov	h_buffers,ax

;	mov	al,p_buffer_slash_x	; M016
;	mov	buffer_slash_x,al

	mov	ax,linecount
	mov	buffer_linenum,ax ; save the line number for the future use.

sr7:
	jmp	coff

try_buffershigh:
	cmp     ah,CONFIG_BUFFERSHIGH
	jne     tryc
	call    query_user
	jc      tryc
	mov     byte ptr [p_buffers_high],1
	jmp     short parse_buffers

;------------------------------------------------------------------------------
; break command
;------------------------------------------------------------------------------
;****************************************************************************
;									    *
; function: parse the parameters of break = command.			    *
;									    *
; input :								    *
;	es:si -> parameters in command line.				    *
; output:								    *
;	turn the control-c check on or off.				    *
;									    *
; subroutines to be called:						    *
;	sysinit_parse							    *
; logic:								    *
; {									    *
;	set di to brk_parms;						    *
;	set dx,cx to 0; 						    *
;	while (end of command line)					    *
;	{ sysinit_parse;						    *
;	  if (no error) then						    *
;	       if (result_val.$p_item_tag == 1) then	  /*on		 */ *
;		   set p_ctrl_break,on;					    *
;	       else					  /*off 	 */ *
;		   set p_ctrl_break,off;				    *
;	  else {show message;error_exit};				    *
;	};								    *
;	if (no error) then						    *
;	   dos function call to set ctrl_break check according to	    *
; };									    *
;									    *
;****************************************************************************

tryc:
        cmp     ah,CONFIG_BREAK
	jnz	trym
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      trym                    ; has the CONFIG_OPTION_QUERY bit set
endif
	mov	di,offset brk_parms
	xor	cx,cx
	mov	dx,cx
do22:
	call	sysinit_parse
	jnc	if22			; parse error
	call	badparm_p		;  show message and end the serach loop.
	jmp	short sr22

if22:
	cmp	ax,$p_rc_eol		; end of line?
	jz	en22			; then end the $endloop
	cmp	result_val.$p_item_tag,1
	jnz	if26

	mov	p_ctrl_break,1		; turn it on
	jmp	short en26

if26:
	mov	p_ctrl_break,0		; turn it off
en26:
	jmp	short do22		; we actually set the ctrl break

en22:
	mov	ah,set_ctrl_c_trapping ; if we don't have any parse error.
	mov	al,1
	mov	dl,p_ctrl_break
	int	21h
sr22:
	jmp	coff

;------------------------------------------------------------------------------
; multitrack command
;------------------------------------------------------------------------------
;******************************************************************************
;									      *
; function: parse the parameters of multitrack= command.		      *
;									      *
; input :								      *
;	es:si -> parameters in command line.				      *
; output:								      *
;	turn multrk_flag on or off.					      *
;									      *
; subroutines to be called:						      *
;	sysinit_parse							      *
; logic:								      *
; {									      *
;	set di to brk_parms;						      *
;	set dx,cx to 0; 						      *
;	while (end of command line)					      *
;	{ sysinit_parse;						      *
;	  if (no error) then						      *
;	       if (result_val.$p_item_tag == 1) then	  /*on		 */   *
;		   set p_mtrk,on;					      *
;	       else					  /*off 	 */   *
;		   set p_mtrk,off;					      *
;	  else {show message;error_exit};				      *
;	};								      *
;	if (no error) then						      *
;	   dos function call to set multrk_flag according to p_mtrk.	      *
;									      *
; };									      *
;									      *
;******************************************************************************

trym:
        cmp     ah,CONFIG_MULTITRACK
	je      short multi_track_command
	jmp     tryu
multi_track_command:
ifdef   MULTI_CONFIG
	call    query_user      ; query the user if config_cmd
	jnc     config_query_ok
	jmp     tryu
config_query_ok:
endif
	mov	di,offset mtrk_parms
	xor	cx,cx
	mov	dx,cx
do31:
	call	sysinit_parse
	jnc	if31		; parse error
	call	badparm_p	;  show message and end the serach loop.
	jmp	short sr31
if31:
	cmp	ax,$p_rc_eol	; end of line?
	jz	en31		; then end the $endloop

	cmp	result_val.$p_item_tag,1
	jnz	if35

	mov	p_mtrk,1	; turn it on temporarily.
	jmp	short en35

if35:
	mov	p_mtrk,0	; turn it off temporarily.
en35:
	jmp	short do31	; we actually set the multrk_flag here

en31:
	push	ds
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data

	or	bios_flags,0400h
	cmp	p_mtrk,0
	jz	en39
	or	bios_flags,0200h
en39:
	pop	ds
	assume	ds:sysinitseg
sr31:
	jmp	coff

;----------------------------------------------------------------------------
; DOS=HIGH/LOW command
;----------------------------------------------------------------------------
;

multi_try_doshi:
        cmp     ah,CONFIG_DOS
	jne     parse_switches
it_is_h:				; M003 - removed initing DevUMB
					;	 & runhigh
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
	jc      parse_switches                 ; has the CONFIG_OPTION_QUERY bit set
endif
	mov	di,offset dos_parms
	xor	cx,cx
	mov	dx,cx
h_do_parse:
	call	sysinit_parse
	jnc	h_parse_ok		; parse error
h_badparm:
	call	badparm_p		;  show message and end the serach loop.
	jmp	short h_end

h_parse_ok:
	cmp	ax,$p_rc_eol		; end of line?
	jz	h_end			; then end the $endloop
	call	ProcDOS
	jmp	short h_do_parse
h_end:
	jmp	coff

;
; Parse SWITCHES once on the initial configuration pass.
;
parse_switches:
	cmp     ah,CONFIG_SWITCHES
	jne     firstpass_logo
ifdef   MULTI_CONFIG
	call    query_user      ; query the user if config_cmd
	jc      firstpass_logo        ; has the CONFIG_OPTION_QUERY bit set
endif
	mov	di,offset swit_parms
	xor	cx,cx
	mov	dx,cx

do110:
	call	sysinit_parse
	jnc	if110		; parse error
	call	badparm_p	;  and show messages and end the search loop.
	jmp     h_end

if110:
	cmp	ax,$p_rc_eol	; end of line?
	jz	h_end		; then jmp to $endloop for semantic check

	cmp     result_val.$p_synonym_ptr,offset swit_k
	jne     short parse_switch_t
	mov     p_swit_k,1
	jmp     short do110
parse_switch_t:
	cmp     result_val.$p_synonym_ptr,offset swit_t
	jne     short parse_switch_w
	mov     p_swit_t,80h
	jmp     short do110
parse_switch_w:
	cmp     result_val.$p_synonym_ptr,offset swit_w
	jne     short parse_switch_c
	mov     p_swit_w,1
	jmp     short do110
parse_switch_c:
	cmp     result_val.$p_synonym_ptr,offset swit_c
	jne     short parse_switch_e
	mov     p_swit_c,1
	jmp     short do110
parse_switch_e:
	cmp     result_val.$p_synonym_ptr,offset swit_e
	jne     do110
	mov     ax,0ffffh
	cmp     result_val.$p_item_tag,2
	jne     short set_ebda_limit
	mov     ax,word ptr result_val.$p_picked_val
	add     ax,0fh
	and     al,0f0h
set_ebda_limit:
	mov     config_ebda_limit,ax
	jmp     short do110


;
;-----------------------------------------------------------------------------
firstpass_logo:
	cmp     ah,'q'                  ; LOGO= command
	je      short logo_command
firstpass_logo_skip:
	jmp     multi_pass_filter
logo_command:
	call    query_user
	jc      firstpass_logo_skip
	push    es
	pop     ds
	sub     dx,dx
	mov     al,[si]
	cmp     al,' '
	jb      short logo_ready
	mov     dx,si
logo_name_loop:
	lodsb
	cmp     al,' '
	jae     logo_name_loop
	mov     byte ptr [si-1],0
logo_ready:
	call    boot_logo_display
	jmp     coff

DeviceLineLimit equ	6122h



; devicehigh command
;-----------------------------------------------------------------------------
;
	assume	ds:nothing
tryu:
	cmp     ah,CONFIG_DEVICEHIGH
	je      short devicehigh_command
	jmp     tryd
devicehigh_command:
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      tryd                    ; has the CONFIG_OPTION_QUERY bit set
endif
	mov     bx,offset boot_umb_driver_record
	call    boot_process_driver_record
	call	InitVar
	call	ParseSize		; process the size= option
	jnc	@f

	mov	badparm_off, si		; stash it there in case of an error
	mov	badparm_seg, es
	call	badparm_p
	jmp	coff

@@:	mov	ax, DevSizeOption
	or	ax, ax
	jnz	@f

	call	ParseVar
	jnc	@f

	mov	badparm_off, si		; If ParseVar up there failed, then
	mov	badparm_seg, es		; ES:SI points to its problem area...
	call	badparm_p		; so all we have to do is choke and
	jmp	coff			; die, rather verbosely.

@@:	push	si
	push	es

@@:	mov	al, es:[si]
	cmp	al, cr
	je	@f
	cmp	al, lf
	je	@f
	call	delim
	jz	@f
	inc	si
	jmp	@b

@@:	mov	DevSavedDelim, al	; Save the delimiter before replacing
					;  it with null
	mov	byte ptr es:[si], 0
	pop	es
	pop	si

;------------------------------------------------------------------------------
; BEGIN PATCH TO CHECK FOR NON-EXISTANT UMBs   -- t-richj 7-21-92
;------------------------------------------------------------------------------

	call	UmbTest			; See if UMBs are around...
	jnc	NrmTst			; ...yep.  So do that normal thang.

	mov	DeviceHi, 0		; ...nope... so load low.
	jmp short LoadDevice

;------------------------------------------------------------------------------
; END PATCH TO CHECK FOR NON-EXISTANT UMBs   -- t-richj 7-21-92
;------------------------------------------------------------------------------

NrmTst:	mov	DeviceHi, 0
	cmp	DevUMB, 0		; do we support UMBs
	je	LoadDevice		; no, we don't
	mov	DeviceHi, 1
	jmp	short LoadDevice
;
;------------------------------------------------------------------------------
; device command
;------------------------------------------------------------------------------

	assume	ds:nothing
tryd:
	cmp     ah,CONFIG_DEVICE
	jz	gotd
skip_it2:
	jmp	tryq
gotd:
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      skip_it2                ; has the CONFIG_OPTION_QUERY bit set
endif
	mov	DeviceHi, 0		; not to be loaded in UMB ;M007
	mov	DevSizeOption, 0
	mov	DevSavedDelim, ' '	; In case of DEVICE= the null has to
					;  be replaced with a ' '

LoadDevice:                             ; device= or devicehigh= command.
	push    cs
	pop     ds
	assume  ds:sysinitseg

; Keep an equivalent segment:offset form of the command line for drivers
; which need the original address after initialization.
	mov	cx,si
	mov	dx,es
	mov	ax,DeviceLineLimit
	sub	ax,si
	jc	short device_line_original
	and	ax,0fff0h
	add	cx,ax
	jc	short device_line_original
	.286
	shr	ax,4
	.8086
	sub	dx,ax
	jnc	short device_line_saved
device_line_original:
	mov	cx,si
	mov	dx,es
device_line_saved:
	mov	word ptr [DevOriginalCmdLine],cx
	mov	word ptr [DevOriginalCmdLine+2],dx

	mov	word ptr [bpb_addr],si	; pass the command line to the dvice
	mov	word ptr [bpb_addr+2],es

	mov	word ptr DevCmdLine, si	; save it for ourself
	mov	word ptr DevCmdLine+2, es

	mov	[driver_units], 0	; clear total block units for driver
	call    config_log_device

	call	SizeDevice
	jc	BadFile

;
; - Begin DeviceHigh primary logic changes ------------------------------------
;

	mov	ConvLoad, 1		; Doesn't matter if DeviceHi==0

	mov	al, DeviceHi		; If not using upper memory,
	or	DeviceHi, 0		; Skip all this and go on to
	jz	DevConvLoad		; the actual load.

	call	GetLoadUMB		; Returns first UMB spec'ed in AX
	cmp	al, -1			; If umb0 not specified, it's old style
	jz	DevConvLoad		; so load high even if SIZE= is smaller

	dec	ConvLoad		; They specified /L, so use new loader

	call	GetLoadSize		; Returns size of first UMB specified
	or	ax, ax
	jz	@f			; If size1 not specified, nada to do:

	cmp	ax, DevSize		; /L:...,Size < DevSize?
	jge	DevConvLoad

; These two lines commented out, to correct Astro bug #973
;
;	mov	ax, 0			; Yep... so crank load UMB to conv mem
;	call	StoLoadUMB		;
;

@@:	mov	ax, DevSize		; Size < DevSize, so write DevSize as
	call	StoLoadSize		; minsize for load UMB.

;
; - End DeviceHigh primary logic changes --------------------------------------
;

DevConvLoad:
	call	InitDevLoad

	mov	ax, DevLoadAddr
	add	ax, DevSize
	jc	NoMem
	cmp	DevLoadEnd, ax
	jae	LoadDev

NoMem:
	jmp	low_memory_error

BadFile:
	mov     al,0ffh
	call    log_device_result
	call	RetFromUM		; Does nothing if didn't call HideUMBs

        cmp     byte ptr es:[si], ' '
        jae     @f
	jmp	badop
@@:
	call	badload
	jmp	coff

LoadDev:
	push	es
	pop	ds
	assume	ds:nothing
	mov	dx,si			;ds:dx points to file name
	call    config_record_name_from_path
	call    config_snapshot_drives

	if	noexec
	les	bx,dword ptr cs:[memlo]
	call	ldfil			;load in the device driver

	else

	call	ExecDev			; load device driver using exec call

	endif

badldreset:
	push	ds
	pop	es			;es:si back to config.sys
	push	cs
	pop	ds			;ds back to sysinit
	jc	BadFile
goodld:
	push	es
	push	si
	call	RemoveNull
	push	es
	push	si

	push	cs
	pop	es

	push	ds
	push	si

	lds	si, DevEntry			; peeks the header attribute
	test	word ptr ds:[si.sdevatt],devtyp ;block device driver?
	jnz	got_device_com_cont		;no.

	lds	si,dosinfo			; ds:si -> sys_var
	cmp	ds:[si.sysi_numio],26		; no more than 26 drive number
	jb	got_device_com_cont

	pop	si
	pop	ds

	pop	si				;clear the stack
	pop	es

	call	RetFromUM			; Do this before we leave

	jmp	badnumblock

got_device_com_cont:
	pop	si
	pop	ds

	sub	ax,ax
	call	DeviceCompatCheck
	call	LieInt12Mem
	call	UpdatePDB		; update the PSP:2 value M020

	cmp	cs:multdeviceflag, 0	; Pass limit only for the 1st device
					;  driver in the file ; M027
	jne	skip_pass_limit		;		      ; M027

	mov	word ptr break_addr, 0	; pass the limit to the DD
	mov	bx, DevLoadEnd
	mov	word ptr break_addr+2, bx
skip_pass_limit:
	mov	byte ptr cs:[unitcount],0

;	Note:  sysi_numio (in DOS DATA) currently reflects the REAL
;	number of installed devices (including DblSpace drives) where
;	"drivenumber" is the number that the next block device will
;	be assigned to.  Because some naughty device drivers (like
;	interlnk) look at the internal DOS variable instead of the
;	value we pass it, we'll temporarily stick our value into
;	DOS DATA while we're initializing the device drivers.
;
;	Note that this will make it impossible for this device
;	driver to access the DblSpace drive letters, whether
;	they are swapped-hosts or unswapped compressed drives,
;	during its initialization phase.

	push	ds
	lds	si,cs:DevEntry
	test	word ptr ds:[si.sdevatt],devtyp
	lds	bx,cs:dosinfo		; ds:bx -> sys_var

	mov	al,cs:drivenumber	; temporarily use this next drv value
	mov	cs:devdrivenum, al	; pass drive number in packet to driver
	.errnz	sysi_ncds-sysi_numio-1	; handle adjacent bytes as a word
	mov	ax,ds:word ptr [bx.sysi_numio]
	jnz	short device_counts_saved
	mov	al,cs:drivenumber
	mov	ah,al
	xchg	ax,ds:word ptr [bx.sysi_numio]	; swap with existing values
device_counts_saved:
	pop	ds

	push	ax			; save real sysi_numio/ncds in ax
	call    config_hook_install

	mov	bx,sdevstrat
	call	calldev 		;   calldev (sdevstrat);
	mov	bx,sdevint
	call	calldev 		;   calldev (sdevint);
	call    config_hook_remove

	pop	ax			; get real sysi_numio value
	push	ds
	lds	bx,dosinfo		; ds:bx -> sys_var
	.errnz	sysi_ncds-sysi_numio-1	; handle adjacent bytes as a word
	mov	ds:word ptr [bx.sysi_numio],ax	; swap with existing values
	pop	ds

	call	TrueInt12Mem
	or	ax,-1
	call	DeviceCompatCheck

	mov	ax, word ptr break_addr	; move break addr from the req packet
	mov	word ptr DevBrkAddr, ax
	mov	ax, word ptr break_addr+2
	mov	word ptr DevBrkAddr+2, ax

	assume	ds:nothing

	call	RetFromUM		; There we go... all done.

	cmp	DevUMB, 0
	jz	@f
	call	AllocUMB
@@:

ifndef ROMDOS
;
;------ If we are waiting to be moved into hma lets try it now !!!
;
	call	TryToMovDOSHi		; move DOS into HMA if reqd
endif ; ROMDOS

	pop	si
	pop	ds
	mov	byte ptr [si],0 	;   *p = 0;

	push	cs
	pop	ds

	jmp	short was_device_com
;
;----------------------------------------------------------------------------
;
badnumblock:
	push	cs
	pop	ds
	call	print_indexed
	dw	800fh

;
;------ fall thru -----------------------------------------------------------
;
erase_dev_do:				; modified to show message "error in config.sys..."
	call	CheckDoubleSpace
	mov	al,0ffh
	call	log_device_result
	lds	bx,cs:DevEntry
	cmp	cs:config_device_segment,0
	jz	erase_dev_record
	mov	bx,cs:config_device_segment
	mov	ds,bx
	xor	bx,bx
erase_dev_record:
	xor	al,al
	call	config_record_device
	pop	si
	pop	es

	push	cs
	pop	ds

;	test	[setdevmarkflag],setbrkdone	;if already set_break is done,
;	jnz	skip1_resetmemhi		; then do not
;	dec	[memhi] 			;adjust memhi by a paragrah of devmark.

skip1_resetmemhi:
	cmp	configmsgflag,0
	je	no_error_line_msg

	call	error_line		; no "error in config.sys" msg for device driver. dcr d493
	mov	configmsgflag,0		;set the default value again.

no_error_line_msg:
	jmp	coff
;
;----------------------------------------------------------------------------
;
was_device_com:

	mov	ax,word ptr [DevBrkAddr+2]
	cmp	ax,DevLoadEnd
	jbe	breakok

	pop	si
	pop	es
	jmp	BadFile

breakok:
	lds	dx,DevEntry		;set ds:dx to header
	mov	si,dx
;
;M049	add	si,sdevatt		;ds:si points to attributes
;M049
;M049	ds:si -> hedaer
;
	les	di,cs:[dosinfo] 	;es:di point to dos info
;M049	mov	ax,ds:[si]		;get attributes
	mov	ax,ds:[si.sdevatt]	;M049: get attributes
	test	ax,devtyp		;test if block dev
	jz	isblock
;
;------ lets deal with character devices
;
	call	DevSetBreak		; go ahead and alloc mem for device
jc_edd:
	jc	erase_dev_do		;device driver's init routine failed.

	test	ax,iscin		;is it a console in?
	jz	tryclk

	mov	word ptr es:[di.sysi_con],dx
	mov	word ptr es:[di.sysi_con+2],ds

tryclk: test	ax,isclock		;is it a clock device?
	jz	golink

	mov	word ptr es:[di+sysi_clock],dx
	mov	word ptr es:[di+sysi_clock+2],ds
golink: jmp	linkit
;
;------ deal with block device drivers
;
isblock:
	mov	al,cs:[unitcount]	;if no units found,erase the device
	or	al,al
	jnz	isblock_has_units
	jmp	erase_dev_do
isblock_has_units:
	mov	[si.sdevname],al	; M049: number of units in name field
	add	cs:[driver_units], al	; keep total for all drivers in file

perdrv:
	cbw				; warning no device > 127 units
	mov	cx,ax
	mov	dh,ah
	mov	dl,es:[di.sysi_numio]	;get number of devices
	mov	ah,dl
	add	ah,al			; check for too many devices
	cmp	ah,26			; 'A' - 'Z' is 26 devices
	jbe	ok_block
	jmp	badnumblock

ok_block:
	call	DevSetBreak		; alloc the device
	jc	jc_edd
	add	es:[di.sysi_numio],al	; update the amount

ifdef	COPYCDS
	xor	ah, ah
	mov	newnum_cdss, ax		; save number of new CDSs to be built
endif ; COPYCDS

	add	cs:drivenumber,al	; remember amount for next device
	lds	bx,cs:[bpb_addr]	; point to bpb array

perunit:
	les	bp,cs:[dosinfo]
	les	bp,dword ptr es:[bp.sysi_dpb]	;get first dpb

scandpb:cmp	word ptr es:[bp.dpb_next_dpb],-1
	jz	foundpb
	les	bp,es:[bp.dpb_next_dpb]
	jmp	scandpb
foundpb:
	mov	ax,word ptr cs:[DevBrkAddr]
	mov	word ptr es:[bp.dpb_next_dpb],ax
	mov	ax, word ptr cs:[DevBrkAddr+2]
	mov	word ptr es:[bp.dpb_next_dpb+2],ax

	les	bp,dword ptr cs:[DevBrkAddr]
	add	word ptr cs:[DevBrkAddr],dpbsiz

	call	RoundBreakAddr

	mov	word ptr es:[bp.dpb_next_dpb],-1
	mov	byte ptr es:[bp.dpb_first_access],-1

	mov	si,[bx] 			;ds:si points to bpb
	inc	bx
	inc	bx				;point to next guy
	mov	word ptr es:[bp.dpb_drive],dx
	mov	ah,setdpb			;hidden system call
	int	21h

	mov	ax,word ptr cs:[DevEntry]
	mov	word ptr es:[bp.dpb_driver_addr],ax
	mov	ax,word ptr cs:[DevEntry+2]
	mov	word ptr es:[bp.dpb_driver_addr+2],ax

	sub	si,si			; report errors for this CONFIG.SYS device
	call	CheckDeviceSectorSize
	jc	bad_bpb_size_sector

	inc	dx
	inc	dh
	loop	perunit

	push	cs
	pop	ds

ifdef	COPYCDS
	xor	al, al			; build CDSs incrementally
endif ; COPYCDS

	call	tempcds 			; set cds for new drives

linkit:
	les	di,cs:[dosinfo] 		;es:di = dos table
	mov	cx,word ptr es:[di.sysi_dev]	;dx:cx = head of list
	mov	dx,word ptr es:[di.sysi_dev+2]

	lds	si,cs:[DevEntry]		;ds:si = device location
	mov	word ptr es:[di.sysi_dev],si	;set head of list in dos
	mov	word ptr es:[di.sysi_dev+2],ds
	mov	ax,ds:[si]			;get pointer to next device
	mov	word ptr cs:[DevEntry],ax	;and save it

	mov	word ptr ds:[si],cx		;link in the driver
	mov	word ptr ds:[si+2],dx

	push    ax                      ; save next device offset
	mov     al,[si.sdevname]        ; block device unit count
	test    word ptr [si.sdevatt],devtyp   ; character device?
	jz      short record_loaded_device
	xor     al,al
record_loaded_device:
	mov     bx,si
	call    config_record_device
	pop     ax

enddev:

	pop	si
	pop	es
	inc	ax			;ax = ffff (no more devs if yes)?
	jz	coffj3

	inc	cs:multdeviceflag	; possibly multiple device driver.
	call	DevBreak		; M009
ifdef BREAK_HARD_CARDS_WILDLY
;BUGBUG 16-Mar-1993 bens Need to fix this correctly in next release!!!
	call	CheckDoubleSpace
else
endif
	jmp	goodld			; otherwise pretend we loaded it in

bad_bpb_size_sector:
	pop	si
	pop	es
	jmp	coff

coffj3: mov	cs:multdeviceflag,0	; reset the flag
	call	DevBreak
	call	CheckProtmanArena	; adjust alloclim if Protman$ just
;					;  created a bogus arena to try
;					;  to protect some of its resident-
;					;  init code.

	call	CheckDoubleSpace
	xor     al,al
	call    log_device_result
	jmp	coff

CheckDoubleSpace:
	ifdef	dblspace_hooks

;	Now check for two special MagicDrv cases:
;
;       a) the last driver load was MagicDrv final placement:
;	   -> add number of MagicDrv reserved drives to drivenumber
;
;       b) MagicDrv is currently in temporary home:
;          -> call it to give it a chance to mount and shuffle drives

	cmp	cs:MagicHomeFlag,0	; already home?
	jnz	no_more_magic_calls	;  nothing more to do if so

;	Now inquire of driver whether it is present, and final located

	mov	ax,multMagicdrv
	mov	bx,MD_VERSION
	int	2fh			; ch = number of MagicDrv drive letters
	or	ax,ax			; is it there?
	jnz	no_more_magic_calls	; done if not

	test	dx,8000h		; is it final placed?
	jnz	magic_not_yet_home	;  skip if not

;	Okay, now the driver is final placed!  Set the flag so we
;	don't keep checking it, and add its number of drive letters
;	to drivenumber.

	mov	cs:MagicHomeFlag,0ffh	; set the flag!
	add	cs:drivenumber,ch	; add number of MagicDrv volumes to
;					;  the drive number we'll pass to the
;					;  next loadable block device.

	jmp	short no_more_magic_calls ; and finished.


magic_not_yet_home:
	push	es
	push	si

	mov	cx, cs:[memhi]		; pass it a work buffer
	mov	dx, cs:[alloclim]	;   address in cx (segment)
	sub	dx, cx			;   for len dx (paragraphs)

	mov	bx,2
	mov	al,cs:[driver_units]	; shuffle magicdrives and new drives
;					;   by this many units

;BUGBUG 29-Oct-1992 bens Take this 55h out after Beta 4
	mov	ah,55h			; backdoor won't shuffle unless it
;					;  sees this, to prevent bad things
;					;  from happening if people run the
;					;  new driver with an old BIOS
	call	cs:MagicBackdoor

	pop	si
	pop	es

no_more_magic_calls:

	endif
	ret

; Check the new DPB's sector size and enlarge the temporary buffer if needed.
; SI is zero for a CONFIG.SYS device and nonzero for the preload driver.
	public	CheckDeviceSectorSize
CheckDeviceSectorSize proc near
	mov	di,es:[bp.dpb_sector_size]
	les	bp,cs:[dosinfo]
	cmp	di,es:[bp.sysi_maxsec]
	jbe	short cdss_ok
	lea	ax,[di+14h]		; sector size plus buffer header
	cmp	ax,cs:[temp_buffer_size]
	ja	short cdss_too_large
	mov	cs:[singlebuffersize],ax
	mov	es:[bp.sysi_maxsec],di
	mov	ah,0dh			; reset disk system
	int	21h
	xor	ax,ax
	les	di,es:[bp.sysi_buf]
	mov	es:[di+4],ax
	mov	es:[di],ax
	mov	es,cs:[temp_buffer_segment]
	xchg	ax,di
	mov	es:[di],di
	mov	es:[di+2],di
	mov	word ptr es:[di+4],0ffh
	mov	es:[di+6],di
	mov	es:[di+8],di
cdss_ok:
	clc
	ret
cdss_too_large:
	or	si,si
	jnz	short cdss_failed
	pop	di
	pop	si
	pop	es
	push	es
	push	si
	push	di
	push	bx
	push	cx
	push	dx
	push	ds
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_msg_table+14]
	mov	bx,offset sysinit_msg_base
	add	bx,cs:[sysinit_msg_table+10]
	call	prnerr
	pop	ds
	pop	dx
	pop	cx
	pop	bx
cdss_failed:
	stc
	ret
CheckDeviceSectorSize endp



;------------------------------------------------------------------------------
; country command
;      the syntax is:
;	country=country id {,codepage {,path}}
;	country=country id {,,path}	:default codepage id in dos
;------------------------------------------------------------------------------

tryq:
        cmp     ah,CONFIG_COUNTRY
	jz	tryq_cont
skip_it3:
	jmp	tryf
tryq_cont:
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      skip_it3                ; has the CONFIG_OPTION_QUERY bit set
endif
	mov	cntry_drv,0		; reset the drive,path to default value.
	mov	p_code_page,0
	mov	di,offset cntry_parms
	xor	cx,cx
	mov	dx,cx
do52:
	call	sysinit_parse
	jnc	if52			; parse error,check error code and

	call	cntry_error		;  show message and end the search loop.
	mov	p_cntry_code,-1		; signals that parse error.
	jmp	short sr52

if52:
	cmp	ax,$p_rc_eol		; end of line?
	jz	sr52			; then end the search loop

	cmp	result_val.$p_type,$p_number	; numeric?
	jnz	if56

	mov	ax,word ptr result_val.$p_picked_val
	cmp	cx,1
	jnz	if57

	mov	p_cntry_code,ax
	jmp	short en57

if57:
	mov	p_code_page,ax
en57:
	jmp	short en56		; path entered

if56:
	push	ds
	push	es
	push	si
	push	di

	push	cs
	pop	es

	lds	si,rv_dword		; move the path to known place.
	mov	di,offset cntry_drv
	call	move_asciiz

	pop	di
	pop	si
	pop	es
	pop	ds

en56:
	jmp	do52

sr52:
	cmp	p_cntry_code,-1		; had a parse error?
	jne	tryq_open
	jmp	coff

tryqbad:				;"invalid country code or code page"
       stc
       mov     dx,offset sysinit_msg_base
       add     dx,cs:[sysinit_msg_table+22]
       jmp     tryqchkerr

tryq_open:
	cmp	cntry_drv,0
	je	tryq_def
	mov	dx,offset cntry_drv
	jmp	short tryq_openit

tryq_def:
	mov	dx,offset cntry_root
tryq_openit:
	mov	ax,3d00h		;open a file
	stc
	int	21h
	jc	tryqfilebad		;open failure

	mov	cs:cntryfilehandle,ax	;save file handle
	mov	bx,ax
	mov	ax,cs:p_cntry_code
	mov	dx,cs:p_code_page	; now,ax=country id,bx=filehandle
	mov	cx,cs:[memhi]
	add	cx,384			; need 6k buffer to handle country.sys
					; M023
	cmp	cx,cs:[alloclim]
	ja	tryqmemory		;cannot allocate the buffer for country.sys

	mov	si,offset cntry_drv	;ds:si -> cntry_drv
	cmp	byte ptr [si],0 	;default path?
	jne	tryq_set_for_dos

	inc	si
	inc	si			;ds:si -> cntry_root

tryq_set_for_dos:
	les	di,cs:sysi_country	;es:di -> country info tab in dos
	push	di			;save di
	add	di,ccpath_countrysys
	call	move_asciiz		;set the path to country.sys in dos.
	pop	di			;es:di -> country info tab again.

	mov	cx,cs:[memhi]
	mov	ds,cx
	xor	si,si			;ds:si -> 2k buffer to be used.
	call	setdoscountryinfo	;now do the job!!!
	jnc	tryqchkerr		;read error or could not find country,code page combination

	cmp	cx,-1			;could not find matching country_id,code page?
	je	tryqbad 		;then "invalid country code or code page"

tryqfilebad:
	push	cs
	pop	es
	cmp	cs:cntry_drv,0		;is the default file used?
	je	tryqdefbad

	mov	si,offset cntry_drv
	jmp	short tryqbadload

tryqdefbad:				;default file has been used.
	mov	si,offset cntry_root	;es:si -> \country.sys in sysinit_seg
tryqbadload:
	call	badload 		;ds will be restored to sysinit_seg
	mov	cx,cs:[confbot]
	mov	es,cx			;restore es -> confbot.
	jmp	short coffj4

tryqmemory:
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_msg_table+26]
tryqchkerr:
	mov	cx,cs:[confbot]
	mov	es,cx			;restore es -> confbot seg
	push	cs
	pop	ds			;retore ds to sysinit_seg
	jnc	coffj4			;if no error,then exit

	call	print			;else show error message
	call	error_line

coffj4:
	mov	bx,cntryfilehandle
	mov	ah,3eh
	int	21h			;close a file. don't care even if it fails.
	jmp	coff

	public	cntry_error
cntry_error	proc	near

;function: show "invalid country code or code page" messages,or
;		"error in country command" depending on the error code
;		in ax returned by sysparse;
;in:	ax - error code
;	ds - sysinitseg
;	es - confbot
;out:	show message.  dx destroyed.

	cmp	ax,$p_out_of_range
	jnz	if64
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_msg_table+22] ; invalid country code or code page
	jmp	short en64

if64:
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_msg_table+24] ; error in country command
en64:
	call	print
	call	error_line
	ret
cntry_error	endp

;------------------------------------------------------------------------------
; files command
;------------------------------------------------------------------------------
;*******************************************************************************
; function: parse the parameters of files= command.			       *
;									       *
; input :								       *
;	es:si -> parameters in command line.				       *
; output:								       *
;	variable files set.						       *
;									       *
; subroutines to be called:						       *
;	sysinit_parse							       *
; logic:								       *
; {									       *
;	set di points to files_parms;					       *
;	set dx,cx to 0; 						       *
;	while (end of command line)					       *
;	{ sysinit_parse;						       *
;	  if (no error) then						       *
;	     files = result_val.$p_picked_val				       *
;	  else								       *
;	     error exit;						       *
;	};								       *
; };									       *
;									       *
;*******************************************************************************
tryf:
        cmp     ah,CONFIG_FILES
	jne     try_fileshigh
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
	jc      try_fileshigh
endif
parse_files:
	mov	di,offset files_parms
	xor	cx,cx
	mov	dx,cx

do67:
	call	sysinit_parse
	jnc	if67			; parse error
	call	badparm_p		;   and show messages and end the search loop.
	jmp	short sr67

if67:
	cmp	ax,$p_rc_eol		; end of line?
	jz	en67			; then end the $endloop
	mov	al,byte ptr result_val.$p_picked_val
	mov	p_files,al		; save it temporarily
	jmp	short do67

en67:
	mov	al,p_files
	mov	files,al		; no error. really set the value now.

sr67:
	jmp	coff

try_fileshigh:
	cmp     ah,CONFIG_FILESHIGH
	jne     tryl
	call    query_user
	jc      tryl
	mov     byte ptr cs:[p_files_high],1
	jmp     short parse_files

;------------------------------------------------------------------------------
; lastdrive command
;------------------------------------------------------------------------------
;*******************************************************************************
; function: parse the parameters of lastdrive= command. 		       *
;									       *
; input :								       *
;	es:si -> parameters in command line.				       *
; output:								       *
;	set the variable num_cds.					       *
;									       *
; subroutines to be called:						       *
;	sysinit_parse							       *
; logic:								       *
; {									       *
;	set di points to ldrv_parms;					       *
;	set dx,cx to 0; 						       *
;	while (end of command line)					       *
;	{ sysinit_parse;						       *
;	  if (no error) then						       *
;	     set num_cds to the returned value; 			       *
;	  else	/*error exit*/						       *
;	     error exit;						       *
;	};								       *
; };									       *
;									       *
;*******************************************************************************

tryl:
        cmp     ah,CONFIG_LASTDRIVE
	jne     try_lastdrivehigh
ifdef   MULTI_CONFIG
	call    query_user      ; query the user if config_cmd
	jc      try_lastdrivehigh
endif
lastdrive_value:
	call    lastdrive_number
	jnc     lastdrive_store
	mov	di,offset ldrv_parms
	xor	cx,cx
	mov	dx,cx

do73:
	call	sysinit_parse
	jnc	if73		; parse error
	call	badparm_p	;   and show messages and end the search loop.
	jmp	short sr73

if73:
	cmp	ax,$p_rc_eol	; end of line?
	jz	en73		; then end the $endloop
	mov	al,rv_byte	; pick up the drive number
	mov	p_ldrv,al	; save it temporarily
	jmp	do73

en73:
	mov	al,p_ldrv
lastdrive_store:
	mov	num_cds,al	; no error. really set the value now.
sr73:
	jmp	coff

; Return a numeric LASTDRIVE value in AX, or carry if not valid.
	public  lastdrive_number
lastdrive_number proc near
	push    si
	sub     dx,dx
lastdrive_digit:
	mov     al,es:[si]
	inc     si
	cmp     al,' '
	jbe     lastdrive_done
	sub     al,'0'
	jc      lastdrive_bad
	cmp     al,9
	ja      lastdrive_bad
	push    ax
	mov     ax,10
	mul     dx
	xchg    ax,dx
	pop     ax
	cbw
	add     dx,ax
	jmp     short lastdrive_digit
lastdrive_bad:
	sub     dx,dx
lastdrive_done:
	pop     si
	xchg    ax,dx
	cmp     ax,21h
	cmc
	jc      lastdrive_return
	test    ax,ax
	jnz     lastdrive_return
	stc
lastdrive_return:
	ret
lastdrive_number endp

try_lastdrivehigh:
	cmp     ah,CONFIG_LASTDRIVEHIGH
	jne     tryp
	call    query_user
	jc      tryp
	mov     byte ptr cs:[p_ldrv_high],1
	jmp     short lastdrive_value


;--------------------------------------------------------------------------
; setting drive parameters
;--------------------------------------------------------------------------

tryp:
        cmp     ah,CONFIG_DRIVPARM
	jnz	tryk
ifdef   MULTI_CONFIG
	call    query_user      ; query the user if config_cmd
        jc      tryk            ; has the CONFIG_OPTION_QUERY bit set
endif
; Set the default device parameters before parsing DRIVPARM.
	mov     byte ptr cs:[deviceparameters],0
	mov     byte ptr cs:[deviceparameters+1],2
	mov     word ptr cs:[deviceparameters+2],0
	mov     word ptr cs:[deviceparameters+4],80
	call	parseline
	jc	trypbad
	call	setparms
	call	diddleback

; No error check here, because setparms and diddleback have no error 
; returns, and setparms as coded now can return with carry set. 
;       jc	trypbad

	jmp	coff
trypbad:jmp	badop
;--------------------------------------------------------------------------
; setting internal stack parameters
; stacks=m,n where
;	m is the number of stacks (range 8 to 64,default 9)
;	n is the stack size (range 32 to 512 bytes,default 128)
; j.k. 5/5/86: stacks=0,0 implies no stack installation.
;	any combinations that are not within the specified limits will
;	result in "unrecognized command" error.
;--------------------------------------------------------------------------

;****************************************************************************
;									    *
; function: parse the parameters of stacks= command.			    *
;	    the minimum value for "number of stacks" and "stack size" is    *
;	    8 and 32 each.  in the definition of sysparse value list,they   *
;	    are set to 0.  this is for accepting the exceptional case of    *
;	    stacks=0,0 case (,which means do not install the stack.)	    *
;	    so,after sysparse is done,we have to check if the entered	    *
;	    values (stack_count,stack_size) are within the actual range,    *
;	    (or if "0,0" pair has been entered.)			    *
; input :								    *
;	es:si -> parameters in command line.				    *
; output:								    *
;	set the variables stack_count,stack_size.			    *
;									    *
; subroutines to be called:						    *
;	sysinit_parse							    *
; logic:								    *
; {									    *
;	set di points to stks_parms;					    *
;	set dx,cx to 0; 						    *
;	while (end of command line)					    *
;	{ sysinit_parse;						    *
;	  if (no error) then						    *
;	     { if (cx == 1) then /* first positional = stack count */	    *
;		   p_stack_count = result_val.$p_picked_val;		    *
;	       if (cx == 2) then /* second positional = stack size */	    *
;		   p_stack_size = result_val.$p_picked_val;		    *
;	     }								    *
;	  else	/*error exit*/						    *
;	     error exit;						    *
;	};								    *
;	here check p_stack_count,p_stack_size if it meets the condition;    *
;	if o.k.,then set stack_count,stack_size;			    *
;	 else error_exit;						    *
; };									    *
;****************************************************************************

tryk:
        if      stacksw

        cmp     ah,CONFIG_STACKS
	je	do_tryk
	cmp	ah,CONFIG_STACKSHIGH
	je	do_tryk
skip_it4:
	jmp	try_stackshigh

do_tryk:
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      skip_it4                ; has the CONFIG_OPTION_QUERY bit set
endif
	cmp	ah,CONFIG_STACKSHIGH
	jne	stack_parse
	mov	stack_high,1
stack_parse:
	mov	di,offset stks_parms
	xor	cx,cx
	mov	dx,cx

do79:
	call	sysinit_parse
	jnc	if79			; parse error

	call	print_indexed		; invalid stack parameter
	dw	8010h
	jmp	short stack_error

if79:
	cmp	ax,$p_rc_eol		; end of line?
	jz	en79			; then end the $endloop

	mov	ax,word ptr result_val.$p_picked_val
	cmp	cx,1
	jnz	if83

	mov	p_stack_count,ax
	jmp	do79

if83:
	mov	p_stack_size,ax
	jmp	do79

en79:
	cmp	p_stack_count,0
	jz	if87

	cmp	p_stack_count,mincount
	jb	ll88
	cmp	p_stack_size,minsize
	jnb	if88

ll88:
	mov	p_stack_count,-1	; invalid
if88:
	jmp	short en87

if87:
	cmp	p_stack_size,0
	jz	en87
	mov	p_stack_count,-1	; invalid
en87:
	cmp	p_stack_count,-1	; invalid?
	jnz	if94

	mov	stack_count,defaultcount ;reset to default value.
	mov	stack_size,defaultsize
	mov	word ptr stack_addr,0

	call	print_indexed		; invalid stack parameter
	dw	8010h
stack_error:
	jmp	err

if94:
	mov	ax,p_stack_count
	mov	stack_count,ax
	mov	ax,p_stack_size
	mov	stack_size,ax
	mov	word ptr stack_addr,-1	; stacks= been accepted.
sr79:
	jmp	coff

	endif

try_stackshigh:
	cmp	ah,CONFIG_STACKSHIGH
	jne	trys
	jmp	do_tryk

;------------------------------------------------------------------------
; shell command
;------------------------------------------------------------------------

trys:
        cmp     ah,CONFIG_SHELL
	jnz	tryx
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
        jc      tryx                    ; has the CONFIG_OPTION_QUERY bit set
        mov     [newcmd],1
endif
        mov     word ptr [command_line],0;zap length,first byte of command-line

        mov     di,offset commnd+1      ; we already have the first char
        mov     [di-1],al               ; of the new shell in AL, save it now

storeshell:
	call	getchr
        or      al,al                   ; this is the normal case: "organize"
        jz      getshparms              ; put a ZERO right after the filename

        cmp     al," "                  ; this may happen if there are no args
        jb      endofshell              ; I suppose...
	mov	[di],al
	inc	di
        cmp     di,offset commnd+63     ; this makes sure we don't overflow
        jb      storeshell              ; commnd (the filename)
        jmp     short endofshell

getshparms:
        mov     byte ptr [di],0         ; zero-terminate the filename
        mov     di,offset command_line+1; prepare to process the command-line

parmloop:
	call	getchr
	cmp	al," "
        jb      endofparms
	mov	[di],al
	inc	di
        cmp     di,offset command_line+126
        jb      parmloop

endofparms:
        mov     cx,di
        sub     cx,offset command_line+1
        mov     [command_line],cl

endofshell:
        mov     byte ptr [di],0         ; zero-terminate the filename (or
                                        ; the command-line as the case may be)
skipline:
        cmp     al,lf                   ; the safest way to eat the rest of
        je      endofline               ; the line:  watch for ever-present LF
	call	getchr
        jnc     skipline                ; keep it up as long as there are chars

endofline:
        jmp     conflp

;------------------------------------------------------------------------
; fcbs command
;------------------------------------------------------------------------

;************************************************************************
; function: parse the parameters of fcbs= command.			*
;									*
; input :								*
;	es:si -> parameters in command line.				*
; output:								*
;	set the variables fcbs,keep.					*
;									*
; subroutines to be called:						*
;	sysinit_parse							*
; logic:								*
; {									*
;	set di points to fcbs_parms;					*
;	set dx,cx to 0; 						*
;	while (end of command line)					*
;	{ sysparse;							*
;	  if (no error) then						*
;	     { if (cx == 1) then /* first positional = fcbs */		*
;		   fcbs = result_val.$p_picked_val;			*
;	       if (cx == 2) then /* second positional = keep */ 	*
;		   keep = result_val.$p_picked_val;			*
;	     }								*
;	  else	/*error exit*/						*
;	     error exit;						*
;	};								*
; };									*
;************************************************************************

tryx:
        cmp     ah,CONFIG_FCBS
	jne     try_fcbshigh
ifdef   MULTI_CONFIG
	call    query_user      ; query the user if config_cmd
	jc      try_fcbshigh
endif
parse_fcbs:
	mov	di,offset fcbs_parms
	xor	cx,cx
	mov	dx,cx

do98:
	call	sysinit_parse
        jnc     if98            ; parse error
        call    badparm_p       ;  and show messages and end the search loop.
	jmp	short sr98

if98:
	cmp	ax,$p_rc_eol	; end of line?
	jz	en98		; then end the $endloop

	mov	al,byte ptr result_val.$p_picked_val
	cmp	cx,1		; the first positional?
	jnz	if102
	mov	p_fcbs,al
	jmp	short en102

if102:
	mov	p_keep,al
en102:
	jmp	do98

en98:
	mov	al,p_fcbs	; M017
	mov	fcbs,al		; M017
sr98:
	jmp	coff

try_fcbshigh:
	cmp     ah,CONFIG_FCBSHIGH
	jne     try1
	call    query_user
	jc      try1
	mov     byte ptr cs:[p_fcbs_high],1
	jmp     short parse_fcbs

;-----------------------------------------------------------------------
; switches command
;-----------------------------------------------------------------------
;
; Apply the switch values parsed on the initial pass.
;
try1:
	cmp     ah,CONFIG_SWITCHES
        je      do_try1         ; switches= command entered?
skip_it5:
        jmp     tryv
do_try1:
apply_switches:
	cmp     byte ptr cs:[p_swit_k],1
	push    ds
	mov     ax,Bios_Data
	mov     ds,ax
	assume  ds:Bios_Data
	jne     short apply_switch_t
	mov     keyrd_func,0
	mov     keysts_func,1
apply_switch_t:
	mov     al,cs:[p_swit_t]
	or      byte ptr [bios_flags],al
	push    es
	push    bx
	mov     ah,GET_IN_VARS
	int     21h
	cmp     byte ptr cs:[p_swit_w],0
	je      short apply_switch_c
	or      byte ptr es:[bx+60h],2
apply_switch_c:
	cmp     byte ptr cs:[p_swit_c],0
	je      short apply_switch_done
	or      byte ptr es:[bx+60h],8
apply_switch_done:
	pop     bx
	pop     es
	pop     ds
	assume  ds:sysinitseg
	jmp     coff

tryv:

ifdef   MULTI_CONFIG
;------------------------------------------------------------------------
; set command (as in "set var=value<cr/lf>")
;------------------------------------------------------------------------

        cmp     ah,CONFIG_SET
        jne     tryn
	call    query_user      ; query the user if config_cmd
        jc      tryn            ; has the CONFIG_OPTION_QUERY bit set
	mov     dx,1            ; update the environment
        call    copy_envvar     ; copy var at ES:SI to "config_wrkseg"
        jnc     sr110           ; no error
accdate_error:
err:    call    error_line      ; whoops, display error in line XXX
        jmp     short sr110     ; jump to coff (to skip to next line)

;------------------------------------------------------------------------
; numlock command (as in "numlock=on|off")
;------------------------------------------------------------------------
tryn:
        cmp     ah,CONFIG_NUMLOCK
        jne     tryy            ;
	call    query_user      ; query the user if config_cmd
        jc      tryy            ; has the CONFIG_OPTION_QUERY bit set
        call    set_numlock
        jc      err
        jmp     sr110           ; all done

endif  ;MULTI_CONFIG

;-------------------------------------------------------------------------
; comment= do nothing. just decrese chrptr,and increase count for correct
;		line number
;-------------------------------------------------------------------------

tryy:
        cmp     ah,CONFIG_COMMENT
	jne	try0

donothing:
	dec	chrptr
	inc	count
sr110:
	jmp	coff

;------------------------------------------------------------------------
; rem command
;------------------------------------------------------------------------

try0:				;do nothing with this line.
        cmp     ah,CONFIG_REM
	je	donothing

;------------------------------------------------------------------------
; bogus command
;------------------------------------------------------------------------

tryz:
        cmp     ah,0ffh         ;null command? (BUGBUG - who sets FFh anyway?)
        je      donothing

	dec	chrptr
	inc	count
	jmp	short badop

doconf	endp

;***	CheckProtmanArena -- special hack for adjusting alloclim with Protman$
;
;	adjusts alloclim if Protman$ reduced our arena through a manual hack.
;

CheckProtmanArena	proc	near

	push	es
	mov	ax,cs:area	; get our arena header
	dec	ax
	mov	es,ax
	add	ax,es:word ptr 3 ; find end of arena
	inc	ax
	cmp	ax,cs:alloclim	; is it less than alloclim?
	ja	CheckProtmanDone

	mov	cs:alloclim,ax	; reduce alloclim then

CheckProtmanDone:
	pop	es
	ret

CheckProtmanArena	endp

;------------------------------------------------------------------------------

sysinit_parse	proc
;set up registers for sysparse
;in)	es:si -> command line in  confbot
;	di -> offset of the parse control defintion.
;
;out)	calls sysparse.
;	carry will set if parse error.
;	*** the caller should check the eol condition by looking at ax
;	*** after each call.
;	*** if no parameters are found,then ax will contain a error code.
;	*** if the caller needs to look at the synomym@ of the result,
;	***  the caller should use cs:@ instead of es:@.
;	cx register should be set to 0 at the first time the caller calls this
;	 procedure.
;	ax - exit code
;	bl - terminated delimeter code
;	cx - new positional ordinal
;	si - set to pase scanned operand
;	dx - selected result buffer

	push	es			;save es,ds
	push	ds

	push	es
	pop	ds			;now ds:si -> command line

	push	cs
	pop	es			;now es:di -> control definition

	mov	cs:badparm_seg,ds	;save the pointer to the parm
	mov	cs:badparm_off,si	; we are about to parse for badparm msg.
	mov	dx,0
	call	sysparse
	cmp	ax,$p_no_error		;no error

;**cas note:  when zero true after cmp, carry clear

	jz	ll4
	cmp	ax,$p_rc_eol		;or the end of line?
	jnz	if4

ll4:
	clc
	jmp	short en4

if4:
	stc
en4:
	pop	ds
	pop	es
	ret
sysinit_parse	endp

;
;----------------------------------------------------------------------------
;
; procedure : badop_p
;
;             same thing as badop,but will make sure to set ds register back
;             to sysinitseg and return back to the caller.
;
;----------------------------------------------------------------------------
;
badop_p proc	near

	push	cs
	pop	ds			;set ds to configsys seg.
	call	print_indexed		; unrecognized command
	dw	8004h
	call	error_line
	ret

badop_p endp
;
;----------------------------------------------------------------------------
;
; label : badop
;
;----------------------------------------------------------------------------
;
badop:	call	print_indexed		; unrecognized command
	dw	8004h
	jmp	err			; show line number and continue


;
;----------------------------------------------------------------------------
;
; procedure : badparm_p
;
;             show "bad command or parameters - xxxxxx"
;             in badparm_seg,badparm_off -> xxxxx
;
;----------------------------------------------------------------------------
;
	public	badparm_p
badparm_p	proc	near


	push	ds
	push	dx
	push	si

	push	cs
	pop	ds

	call	print_indexed
	dw	8006h			; "bad command or parameters - "
	assume	ds:sysinitseg
	lds	si,badparm_ptr
	assume	ds:nothing

;	print "xxxx" until cr.

do1:
	mov	dl,byte ptr [si]	; get next character
	cmp	dl,cr			; is a carriage return?
	jz	en1			; exit loop if so

	mov	ah,std_con_output	; function 2
	int	21h			; display character
	inc	si			; next character
	jmp	do1
en1:
	push	cs
	pop	ds

	call	print_indexed
	dw	8005h
	call	error_line

	pop	si
	pop	dx
	pop	ds
badparmp_ret:
	ret
badparm_p	endp

;
;----------------------------------------------------------------------------
;
; procedure : getchr
;
;----------------------------------------------------------------------------
;
getchr	proc	near
	assume	ds:nothing
	push	cx
	mov	cx,count
	jcxz	nochar

	mov	si,chrptr
	mov	al,es:[si]
	dec	count
	inc	chrptr
	clc
get_ret:
	pop	cx
	ret

nochar: stc
	jmp	short get_ret
getchr	endp
	assume	ds:sysinitseg


;
;----------------------------------------------------------------------------
;
; procedure : error_line
;
;             show "error in config.sys ..." message.
;
;----------------------------------------------------------------------------
;
		public	error_line
error_line	proc	near


	push	cs
	pop	ds
	cmp	linecount,0
	jz	error_line_done
	call	print_indexed
	dw	8011h
	call	showlinenum
error_line_done:
	ret

error_line	endp

;
;----------------------------------------------------------------------------
;
; procedure : showlinenum
;
; convert the binary linecount to decimal ascii string in showcount
;and display showcount at the current curser position.
;in.) linecount
;
;out) the number is printed.
;
;----------------------------------------------------------------------------
;
		public	showlinenum
showlinenum	proc	near


	push	es
	push	ds
	push	di

	push	cs
	pop	es		; es=cs

	push	cs
	pop	ds

	mov	di,offset showcount+4	; di -> the least significant decimal field.
	mov	cx,10			; decimal devide factor
	mov	ax,linecount

sln_loop:
	cmp	ax,10			; < 10?
	jb	sln_last

	xor	dx,dx
	div	cx
	or	dl,30h			; add "0" (= 30h) to make it an ascii.
	mov	[di],dl
	dec	di
	jmp	sln_loop

sln_last:
	or	al,30h
	mov	[di],al
	mov	dx,di
	call	print			; show it.
	pop	di
	pop	ds
	pop	es
	ret
showlinenum	endp

comment ^
set_devmark	proc	near
;***************************************************************************
; function: set a paragraph of informations infront of a device file or    *
;	    an ifs file to be loaded for mem command.			   *
;	    the structure is:						   *
;	      devmark_id	byte "d" for device,"i" for ifs		   *
;	      devmark_size	size in para for the device loaded	   *
;	      devmark_filename	11 bytes. filename			   *
;									   *
; input :								   *
;	    [memhi] = address to set up devmark.			   *
;	    [memlo] = 0 						   *
;	    es:si -> pointer to [drive][path]filename,0 		   *
;	    [ifs_flag] = is_ifs bit set if ifs= command.		   *
;									   *
; output:   devmark_id,devmark_filename set				   *
;	    cs:[devmark_addr] set.					   *
;	    ax,cx register destroyed.					   *
;***************************************************************************

	push	ds
	push	si
	push	es
	push	di

	mov	di,cs:[memhi]
	mov	ds,di
	assume	ds:nothing
	mov	[devmark_addr],di	; save the devmark address for the future.
	mov	ds:[devmark_id],devmark_device	; 'd'
	inc	di
	mov	ds:[devmark_seg],di
	xor	al,al
	push	si
	pop	di			; now es:si = es:di = [path]filename,0
	mov	cx,128			; maximum 128 char
	repnz	scasb			; find 0
	dec	di			; now es:di-> 0
sdvmk_backward: 			; find the pointer to the start of the filename.
	mov	al,byte ptr es:[di]	; we do this by check es:di backward until
	cmp	al,'\' 		        ; di = si or di -> '\' or di -> ':'.
	je	sdvmk_gotfile
	cmp	al,':'
	je	sdvmk_gotfile
	cmp	di,si
	je	sdvmk_fileptr
	dec	di
	jmp	sdvmk_backward
sdvmk_gotfile:
	inc	di
sdvmk_fileptr:				; now es:di -> start of file name
	push	di			; cas - holy sh*t!!!  CODE!
	pop	si			; save di to si.

	push	ds			; switch es,ds
	push	es
	pop	ds
	pop	es			; now,ds:si -> start of filename

	mov	di,devmark_filename
	push	di
	mov	al,' '
	mov	cx,8
	rep	stosb			; clean up memory.
	pop	di
	mov	cx,8			; max 8 char. only
sdvmk_loop:
	lodsb
	cmp	al,'.'
	je	sdvmk_done
	cmp	al,0
	je	sdvmk_done
	stosb
	loop	sdvmk_loop

sdvmk_done:
	pop	di
	pop	es
	pop	si
	pop	ds
	ret
set_devmark	endp
^
; =========================================================================
;reset_dos_version	proc	near
;
;;function: issue ax=122fh,dx=0,int 2fh to restore the dos version.
;
;	push	ax
;	push	dx
;	mov	ax,122fh
;	mov	dx,0
;	int	2fh
;	pop	dx
;	pop	ax
;	ret
;reset_dos_version	endp
;
;
; =========================================================================

IFDEF	DONT_LOAD_OS2_DD		; M045

EXE_SIG		EQU	5a4dh		; .EXE file signature
OS2_SIG 	EQU	454eh		; OS2 .EXE file signature

SIGNATURE_LEN	EQU	2		; Lenght of .EXE signature in bytes
SIZE_DWORD	EQU	4

SEG_SIG_OFFSET	EQU	18h		; Offset of segmented .EXE signature
SEG_EXE_SIG	EQU	40h		; Signature of a segmented .EXE file
SEG_HEADER_PTR	EQU	3ch		; Offsets of ptr to segmented header

; =========================================================================
; CheckForOS2 PROC
;
; Examines an open file to see if it is really an OS2 executable file.
;
; REGISTERS:	AX	- Open file handle
; RETURNS:	Carry	- Carry set if file is an OS2 executable or error.
; DESTROYS:	NOTHING
;		NOTE:	The file ptr is assumed to be set to start of file
;			on entry and is not reset to begining of the file
;			on exit.
;
; Strategy:	If word value at 00h == 454eh file is OS2
;		else if word value at 00h == 5a4dh and
;		        (word value at 18h == 40h and the dword ptr at 3ch
;			 points to word value of 454eh) file is OS2.
;
; =========================================================================

CheckForOS2 PROC NEAR

	push	AX
	push	BX
	push	CX
	push	DX
	push	DS
	push	BP

	push	CS				; BUGBUG
	pop	DS				; NOT ROM DOS COMPATIBLE

	mov	BX,AX				; Put open file handle in BX
	mov	BP,offset DS:Os2ChkBuf		; Save buff offset for latter

		; First we need to read in the first 2 bytes of the file
		; to see if it's an OS2 .EXE file and if not see if 
		; it is a DOS .EXE file. 

	mov	AX,(read shl 8)			; AH = DOS read function
	mov	CX,SIGNATURE_LEN		; CX = size of word value
	mov	DX,BP				; DS:DX --> tmp buffer
	int	21h
	jc	OS2ChkExit			; Return carry on error

	dec	AX				; Check number of byte read
	dec	AX
	jnz	NotOs2				; Must be at end of file

	mov	AX, WORD PTR DS:Os2ChkBuf
	cmp	AX, OS2_SIG			; Check for 454eh
	je	IsOS2				; Return is OS2 if match
	cmp	AX, EXE_SIG			; Now see if it's a DOS .EXE
	jne	NotOS2				; If no match can't be OS2

		; Here we know the file has a valid DOS .EXE signature so
		; now we need to see if it's a segmented .EXE file by looking
		; for the segmented .EXE signature at file offset 18h

	mov	AX,(lseek shl 8)		; AX = Seek from begining
	xor	CX,CX
	mov	DX,SEG_SIG_OFFSET		; CX:DX = offset of segmented
	int	21h				; Seek to offset 18h
	jc	OS2ChkExit			; Return carry on error

	mov	AX,read shl 8			; AX = Read file
	mov	CX,SIGNATURE_LEN		; CX = size of word value
	mov	DX,BP				; Restore buffer offset
	int	21h 				; DS:DX -> buffer
	jc	OS2ChkExit			; Return carry on error

	dec	AX				; Check number of byte read
	dec	AX
	jnz	NotOs2				; Must be at end of file

	cmp	WORD PTR DS:Os2ChkBuf,SEG_EXE_SIG ; Chk for segmented .EXE file
	jne	NotOS2				; Can't be OS2 if no match

		; Here we know we have a segmented .EXE file so we have
		; to get the offset of the start of the segmented  header
		; from offset 3ch in the file.

	mov	AX,(lseek shl 8)		; AX = Seek from begining
	xor	CX,CX
	mov	DX,SEG_HEADER_PTR		; CX:DX = offset of head ptr
	int	21h				; Seek to offset 3ch
	jc	OS2ChkExit			; Return carry on error

	mov	AX,(read shl 8)			; AX = Read file
	mov	CX,SIZE_DWORD			; CX = size of dword (4 bytes)
	mov	DX,BP				; Restore buffer offset
	int	21h 				; Read in 4 byte offset
	jc	OS2ChkExit			; Return carry on error

	cmp	AX,SIZE_DWORD			; Check number of byte read
	jne	NotOs2				; Must be at end of file

		; At this point OS2ChkBuf has a 4 byte offset into the file
		; to the start of a segmented .EXE header so we need to read
		; the 2 bytes at this location to see if they are 454eh

	mov	DX,WORD PTR DS:Os2ChkBuf
	mov	CX,WORD PTR DS:Os2ChkBuf[2]	; CX:DX = offset of new header
	mov	AX,(lseek shl 8)		; AX = Seek from begining
	int	21h				; Seek to offset 3ch
	jc	OS2ChkExit			; Return carry on error

	mov	AX,(read shl 8)			; AX = Read file
	mov	CX,SIGNATURE_LEN		; CX = size of word (2 bytes)
	mov	DX,BP				; DS:DX --> Os2ChkBuf
	int	21h 				; Read in 4 byte offset
	jc	OS2ChkExit			; Return carry on error

	dec	AX				; Check number of byte read
	dec	AX
	jnz	NotOs2				; Must be at end of file

		; We have the segmented .EXE header in OS2ChkBuf so all
		; we have left to do is see if it's a .EXE signature.

	cmp	WORD PTR DS:OS2ChkBuf,OS2_SIG	; Check for 454eh
	jne	NotOs2				; Not OS2 if it doesn't match

IsOs2:
	stc					; Signal error or OS2 .EXE
	jmp	SHORT OS2ChkExit
NotOs2:
	clc					; Signal no err and not OS2

OS2ChkExit:
	pop	BP
	pop	DS
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	ret

CheckForOS2 ENDP

ENDIF						; M045

;
;----------------------------------------------------------------------------
;
; procedure : ProcDOS
;
;	Process the result of DOS= parsing
;
;	result_val.$p_item_tag	= 1 for DOS=HIGH
;				= 2 for DOS=LOW
;				= 3 for DOS=UMB
;				= 4 for DOS=NOUMB
;				= 5 for DOS=AUTO
;				= 6 for DOS=NOAUTO
;				= 7 for DOS=SINGLE
;----------------------------------------------------------------------------
;
ProcDOS	proc	near
	assume	ds:nothing, es:nothing
	xor	ax,ax
	cwd
	inc	cs:[dos_opt_count]
	jnz	short pd_option
	xchg	dl,cs:[runhigh]
pd_option:
	mov	al,cs:result_val.$p_item_tag
	dec	ax
	jz	short pd_hi
	dec	ax
	jz	short pd_lo
	dec	ax
	jz	short pd_umb
	dec	ax
	jz	short pd_noumb
	dec	ax
	jz	short pd_auto
	dec	ax
	jz	short pd_noauto
	dec	ax
	jz	short pd_single
pd_auto:
	mov	byte ptr cs:[dos_umb_flag],1
	jmp	short pd_auto_sync
pd_noauto:
	mov	byte ptr cs:[dos_umb_flag],0
pd_auto_sync:
	push	ds
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	and	byte ptr [bios_flags+1],not 10h
	cmp	byte ptr cs:[dos_umb_flag],0
	je	short pd_auto_done
	or	byte ptr [bios_flags+1],10h
pd_auto_done:
	pop	ds
	assume	ds:nothing
	ret
pd_single:
	dec	cs:[dos_opt_count]
	jge	short pd_single_flags
	mov	cs:[runhigh],dl
pd_single_flags:
	or	byte ptr cs:[query_mode_flags],80h
	or	byte ptr cs:[boot_runtime_flags],40h
	push	ds
	mov	ds,cs:[BCodeSeg]
	assume	ds:Bios_Code
	or	byte ptr [win386_info_flags],0c0h
	pop	ds
	assume	ds:nothing
	ret
pd_noumb:
	mov	cs:[DevUMB],0
	ret
pd_umb:
	mov	cs:[DevUMB],0ffh
	ret
pd_lo:
	mov	cs:[runhigh],0
	ret
pd_hi:
	mov	word ptr cs:[runhigh],0ffffh
	ret
ProcDOS	endp

;
;----------------------------------------------------------------------------
;
; procedure : LieInt12Mem
;
;	Input : DevEntry points to Device Start address (offset == 0)
;		alloclim set to the limit of low memory.
;
;	Output : none
;
;	Changes the ROM BIOS variable which stores the total low memory
;	If a 3com device driver (any character device with name 'PROTMAN$')
;	is being loaded alloclim is converted into Ks and stored in 40:13h
;	Else if a device driver being loaded into UMB the DevLoadEnd is
;	converted into Ks and stored in 40:13h
;
;----------------------------------------------------------------------------
;
LieInt12Mem	proc	near

		assume	ds:nothing, es:nothing
 
		mov	ax, alloclim		; lie INT 12 as alloclim
						; assuming that it is 3Com
		mov	di,offset ThreeComName
		mov	cx,1
		call	FindDeviceName		; Is it 3Com driver?
		je	lim_set			; yes, lie to him differently
		cmp	DeviceHi, 0		; Is the DD being loaded in UMB
		je	limx			; no, don't lie
		mov	ax, DevLoadEnd		; lie INT 12 as end of UMB
lim_set:
		call	SetInt12Mem
limx:
		ret
LieInt12Mem	endp

;
;----------------------------------------------------------------------------
;
; procedure : SetInt12Mem
;
;	Input : AX = Memory size to be set (in paras)
;	Output : none
;
;	Sets the variable 40:13 to the memory size passed in AX
;	It saves the old value in 40:13 in OldInt12Mem,
;	It also sets bit 0 of Int12Lied, which is checked before
;	restoring the value of 40:13
;
;----------------------------------------------------------------------------
;
SetInt12Mem	proc	near

		assume	ds:nothing, es:nothing
 
		push	ds
		mov	bx, 40h
		mov	ds, bx			; ROM BIOS Data Segment
		mov	bx, word ptr ds:[13h]	; INT 12 memory variable
		mov	OldInt12Mem, bx		; save it
		mov	cl, 6
		shr	ax, cl			; convert paras into Ks
		mov	word ptr ds:[13h], ax	; Lie
		or	byte ptr cs:[Int12Lied],1 ; mark that we are lying
		pop	ds
		ret
SetInt12Mem	endp

;
;----------------------------------------------------------------------------
;
; procedure : TrueInt12Mem
;
;	Input : Bit 0 of Int12Lied is set if we are lying
;		OldInt12Mem = Saved value of 40:13h
;
;	Output : none
;
;	Resets the INT 12 Memory variable if we were lying about int 12
;	and resets the flag which indicates that we were lying
;
;----------------------------------------------------------------------------
;
TrueInt12Mem	proc	near

		assume	ds:nothing, es:nothing
 
		test	byte ptr cs:[Int12Lied],1 ; were we lying so far?
		je	timx			; no, we weren't
		push	ds
		mov	ax, 40h
		mov	ds, ax
		mov	ax, OldInt12Mem
		mov	word ptr ds:[13h], ax	; restore INT 12 memory
		pop	ds
		and	byte ptr cs:[Int12Lied],0feh
timx:
		ret
TrueInt12Mem	endp



; Check for device drivers which need special initialization handling.
; AX is zero before initialization and nonzero afterward.

DeviceCompatCheck proc near
		test	ax,ax
		jz	short dcc_first
		jmp	near ptr DeviceCompatRestore
dcc_first:
		mov	di,offset ProTName
		mov	cx,1
		mov	bx,12h
		call	FindDeviceNameAt
		jz	short dcc_clear_buffers
		mov	di,offset ATIVideoName
		mov	cx,1
		call	FindDeviceName
		jnz	short dcc_stac
		jmp	near ptr DeviceCompatSwitch
dcc_stac:
		mov	di,offset StacCDName
		mov	cx,1
		call	FindDeviceName
		jz	short dcc_restore_line
		mov	di,offset QEMMName
		mov	cx,1
		call	FindDeviceName
		jnz	short dcc_qloader
		jmp	near ptr DeviceCompatSwitch
dcc_qloader:
		mov	di,offset QLoaderName
		mov	cx,1
		call	FindDeviceName
		jz	short DeviceCompatSwitch
		mov	di,offset boot_emm_name
		mov	cx,1
		call	FindDeviceName
		jz	short dcc_qemm_search
		jmp	near ptr dcv_done
dcc_qemm_search:
		mov	di,offset QEMMName
		mov	cx,80h
		call	FindDeviceName
		jz	short DeviceCompatSwitch
		jmp	near ptr dcv_done
dcc_clear_buffers:
		.286
		pusha
		push	es
		mov	ah,0dh
		int	21h
		mov	ah,GET_IN_VARS
		int	21h
		mov	cx,es:[bx+10h]
		shr	cx,1
		les	bx,dword ptr es:[bx+12h]
		les	bx,dword ptr es:[bx]
		mov	di,bx
		xor	ax,ax
		cld
dcc_buffer_loop:
		test	byte ptr es:[di+5],40h
		jnz	short dcc_buffer_next
		mov	word ptr es:[di+4],0ffh
		push	di
		push	cx
		add	di,14h
		rep	stosw
		pop	cx
		pop	di
dcc_buffer_next:
		mov	di,es:[di]
		cmp	di,bx
		jne	short dcc_buffer_loop
		pop	es
		popa
		.8086
		jmp	near ptr dcv_done
dcc_restore_line:
		mov	ax,word ptr cs:[DevOriginalCmdLine]
		mov	word ptr cs:[bpb_addr],ax
		mov	ax,word ptr cs:[DevOriginalCmdLine+2]
		mov	word ptr cs:[bpb_addr+2],ax
		jmp	near ptr dcv_done
DeviceCompatCheck endp

; Restore the keyboard vectors around selected device initializations.
; AX is zero before initialization and nonzero afterward.

DeviceCompatRestore proc near
		test	byte ptr cs:[Int12Lied],2
		jnz	short DeviceCompatSwitch
		jmp	near ptr dcv_done
DeviceCompatSwitch:
		mov	bp,offset Bios_Code:keyboard_vector_install
		and	byte ptr cs:[Int12Lied],0fdh
		test	ax,ax
		jnz	short dcv_call
		mov	bp,offset Bios_Code:keyboard_vector_setup
		or	byte ptr cs:[Int12Lied],2
dcv_call:
		call	query_bios_call
		push	ds
		push	es
		sub	cx,cx
		mov	ds,cx
		assume	ds:nothing,es:nothing
		mov	cx,70h
		test	ax,ax
		jnz	short dcv_install
		cmp	word ptr ds:[5ah],cx
		jnz	short dcv_save4f
		mov	es,cx
		les	di,es:int16_old
		cli
		mov	word ptr ds:[58h],di
		mov	word ptr ds:[5ah],es
		sti
		or	byte ptr cs:[Int12Lied],4
dcv_save4f:
		cmp	word ptr ds:[13eh],cx
		jnz	short dcv_pop
		mov	es,cx
		les	di,es:int4f_old
		cli
		mov	word ptr ds:[13ch],di
		mov	word ptr ds:[13eh],es
		sti
		or	byte ptr cs:[Int12Lied],8
		jmp	short dcv_pop
dcv_install:
		test	byte ptr cs:[Int12Lied],4
		jz	short dcv_install4f
		les	di,dword ptr ds:[58h]
		mov	ax,es
		mov	es,cx
		mov	word ptr es:int16_old,di
		mov	word ptr es:int16_old+2,ax
		cli
		mov	word ptr ds:[58h],offset Bios_Data:int16_entry
		mov	word ptr ds:[5ah],cx
		sti
		and	byte ptr cs:[Int12Lied],0fbh
dcv_install4f:
		test	byte ptr cs:[Int12Lied],8
		jz	short dcv_pop
		les	di,dword ptr ds:[13ch]
		mov	ax,es
		mov	es,cx
		mov	word ptr es:int4f_old,di
		mov	word ptr es:int4f_old+2,ax
		cli
		mov	word ptr ds:[13ch],offset Bios_Data:int4f_entry
		mov	word ptr ds:[13eh],cx
		sti
		and	byte ptr cs:[Int12Lied],0f7h
dcv_pop:
		pop	es
		pop	ds
dcv_done:
		ret
DeviceCompatRestore endp

; Compare device names against the name supplied in CS:DI.
; CX is the number of possible starting positions in the device header.
; Return ZF set on a match; FindDeviceNameAt accepts the starting offset in BX.

FindDeviceName	proc	near
		mov	bx,sdevname
FindDeviceNameAt:
		cld
		push	ds
		push	es
		push	si
		lds	si,cs:DevEntry
		add	si,bx
		push	cs
		pop	es
fdn_next:
		push	si
		push	di
		push	cx
		mov	cx,8
		repe	cmpsb
		pop	cx
		pop	di
		pop	si
		lea	si,[si+1]
		loopne	fdn_next
		pop	si
		pop	es
		pop	ds
		ret
FindDeviceName	endp

;M020 : BEGIN
;
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;
UpdatePDB	proc	near
		assume	ds:nothing
		push	ds
		mov	ah, 62h
		int	21h
		mov	ds, bx
		mov	bx, alloclim
		mov	ds:[PDB_Block_Len], bx
		pop	ds
		ret
UpdatePDB	endp
;
; M020 : END
;
;----------------------------------------------------------------------------
;
; procedure : InitDevLoad
;
;	Input : DeviceHi = 0 indicates load DD in low memory
;			 = 1 indicates load in UMB:
;		           ConvLoad = 0 indicates a new-style load (see below)
;		                    = 1 indicates a DOS 5-style load
;		DevSize  = Size of the device driver file in paras
;
;	Output : none
;
;	Initializes DevLoadAddr, DevLoadEnd & DevEntry.
;	Also sets up a header for the Device driver entry for mem utility
;
;----------------------------------------------------------------------------
; For a "new-style load", we break off the current DevEntry and link the umbs
; as we see fit, using HideUMBs (and UnHideUMBs at exit, though _it_ decides
; whether it's entitled to do anything).  HideUMBs uses the chart built by
; ParseVar to determine which UMBs to leave FREE, and which not.
;----------------------------------------------------------------------------
;

include	highload.inc	; Routines for devicehigh parsing, control of HIDDEN
include	highexit.inc	; umb's, etc

;
; ---------------------------------------------------------------------------
;

InitDevLoad	proc	near

		assume	ds:nothing, es:nothing

		cmp	DeviceHi, 0		; Are we loading in UMB
		je	InitForLo		; no, init for lo mem

		cmp	ConvLoad, 1		; Are we loading as per Dos 5?
		je	InitForConv

;
; There are two stages to preparing upper-memory; first, we mark as 8+HIDDEN
; any areas not specified on the /L:... chain.  Second, we mark as 8+FROZEN
; any areas left in upper-memory, except for elements in the load UMB...
; we then malloc space as per Dos-5 style, and mark as free any spaces which
; are 8+FROZEN (but leave 8+HIDDEN still hidden).  The load is performed,
; and UnHideUMBs later on marks all 8+HIDDEN as free.
;

		call	ShrinkUMB	; Stop using the old device arena

		call	HideUMBs	; Mark up the UM area as we see fit
		call	FreezeUM	; Hide everything BUT the load area
		call	GetUMBForDev	; And grab that load area as needed
		pushf
		call	UnFreeze	; Then unhide everything frozen
		popf

		jc	InitForLo	; (if carry, it's loading low)

		jmp short InitForHi

InitForConv:
		call	SpaceInUMB?		; Do we have space left in the
						;  current UMB ?
		jnc	InitForHi		; yes, we have
		call	ShrinkUMB		; shrink the current UMB in use
		call	GetUMBForDev		; else try to allocate new UMB
		jc	InitForLo		; we didn't succeed, so load
						;  in low memory
InitForHi:
		mov	ax, DevUMBFree		; get Para addr of free mem
		mov	dx, DevUMBAddr		; UMB start addr
		add	dx, DevUMBSize		; DX = UMB End addr
		jmp	short idl1

InitForLo:
		mov	DeviceHi, 0		; in case we failed to load
						;  into UMB indicate that we
						;  are loading low
		mov	ax, memhi		; AX = start of Low memory
		mov	dx, alloclim		; DX = End of Low memory

idl1:
		call	DevSetMark		; setup a sub-arena for DD
		mov	DevLoadAddr, ax		; init the Device load address

		mov	DevLoadEnd, dx		; init the limit of the block
		mov	word ptr DevEntry, 0	; init Entry point to DD
		mov	word ptr DevEntry+2, ax
		ret
InitDevLoad	endp

;
;----------------------------------------------------------------------------
;
; procedure : SpaceInUMB?
;
;	Input : DevUMBAddr, DevUMBSize, DevUMBFree & DevSize
;	Output : Carry set if no space in UMB
;		 Carry clear if Space is available for the device in
;		   current UMB
;
;----------------------------------------------------------------------------
;
	public  SpaceInUMB?
SpaceInUMB?	proc	near

		assume	ds:nothing, es:nothing

		mov	ax, DevUMBSize
		add	ax, DevUMBAddr		; End of UMB
		sub	ax, DevUMBFree		; - Free = Remaining space
		or	ax, ax			; Nospace ?
		jnz	@f
		stc
		ret
@@:
		dec	ax			; space for sub-arena
		cmp	ax, DevSize		; do we have space ?
		ret
SpaceInUMB?	endp

;
;----------------------------------------------------------------------------
;
; procedure : PrepareMark
;
;	Input : AX==Address of MCB (not addr of free space), BX==Size
;	Output : None; MCB marked appropriately and DevUMB* set as needed.
;
;----------------------------------------------------------------------------
;
PrepareMark	proc	near

		push	ds
		mov	ds, ax
		mov	word ptr ds:[arena_owner], 8
		mov	word ptr ds:[arena_name], 'DS'
		pop	ds

		inc	ax
		mov	DevUMBAddr, ax
		mov	DevUMBFree, ax
		mov	DevUMBSize, bx		; update the UMB Variables
		ret

PrepareMark	endp

;
;----------------------------------------------------------------------------
;
; procedure : GetUMBForDev
;
;	Input : DevSize
;	Output : Carry set if couldn't allocate a UMB to fit the
;		 the device.
;		 If success carry clear
;
;	Allocates the biggest UMB for loading devices and updates
;	DevUMBSize, DevUMBAddr & DevUMBFree if it succeeded in allocating
;	UMB.
;
;	This routine relies on the fact that all of the low memory
;	is allocated, and any DOS alloc calls should return memory
;	from the UMB pool.
;
;----------------------------------------------------------------------------
;
	public  GetUMBForDev
GetUMBForDev	proc	near

		assume	ds:nothing, es:nothing

		mov	bx, 0ffffh
		mov	ax, 4800h
		int	21h

		or	bx, bx
		jz	gufd_err

		dec	bx
		cmp	DevSize, bx
		ja	gufd_err
		inc	bx

		mov	ax, 4800h
		int	21h
		jc	gufd_err

		dec	ax
		call	PrepareMark

		clc				; mark no error
		ret
gufd_err:
		xor	ax, ax
		mov	DevUMBSize, ax		; erase the previous values
		mov	DevUMBAddr, ax
		mov	DevUMBFree, ax
		stc
		ret
GetUMBForDev	endp

;
;----------------------------------------------------------------------------
;
; procedure : DevSetMark
;
;	Input : AX - Free segment were device is going to be loaded
;	Output : AX - Segment at which device can be loaded (AX=AX+1)
;
;	Creates a sub-arena for the device driver
;	puts 'D' marker in the sub-arena
;	Put the owner of the sub-arena as (AX+1)
;	Copies the file name into sub-arena name field
;
;	Size field of the sub-arena will be set only at succesful
;	completion of Device load.
;
;----------------------------------------------------------------------------
;
DevSetMark	proc	near

		assume	ds:nothing, es:nothing

		push	es
		push	di
		push	ds
		push	si
		mov	es, ax
		mov	byte ptr es:[devmark_id], devmark_device	; 'D'
		inc	ax
		mov	word ptr es:[devmark_seg], ax
;
;-------------- Copy file name
;
		push	ax			; save load addr
		lds	si, bpb_addr		; command line is still there
;M004 - BEGIN
		mov	di, si
		cld
dsm_again:
		lodsb
		cmp	al, ':'
		jne	isit_slash
		mov	di, si
		jmp	dsm_again
isit_slash:
		cmp	al, '\'
		jne	isit_null
		mov	di, si
		jmp	dsm_again
isit_null:

ifdef DBCS
		call	testkanj
		jz	@f		; if this is not lead byte
		lodsb			; get tail byte
@@:
endif

		or	al, al
		jnz	dsm_again
		mov	si, di
;M004 - END
		mov	di, devmark_filename
		mov	cx, 8			; maximum 8 characters
dsm_next_char:
		lodsb
		or	al, al
		jz	blankout
		cmp	al, '.'
		jz	blankout
		stosb
		loop	dsm_next_char
blankout:
		jcxz	dsm_exit
		mov	al, ' '
		rep	stosb			; blank out the rest
dsm_exit:
		pop	ax			; restore load addr
		pop	si
		pop	ds
		pop	di
		pop	es
		ret
DevSetMark	endp

;
;----------------------------------------------------------------------------
;
; procedure : SizeDevice
;
;	Input : ES:SI - points to device file to be sized
;
;	Output : Carry set if file cannot be opened or if it is an OS2EXE file
;
;	Calculates the size of the device file in paras and stores it
;	in DevSize
;
;----------------------------------------------------------------------------
;

SizeDevice	proc	near

		assume	ds:nothing, es:nothing

                push    ds
		push	es
		pop	ds
		mov	dx, si			; ds:dx -> file name
		mov	ax, 3d00h		; open
		int	21h
		jc	sd_err			; open failed

IFDEF	DONT_LOAD_OS2_DD			; M045
		call	CheckForOS2		; is it a OS2 EXE file ?
		jc	sd_close		; yeah, we dont load them
ENDIF						; M045

		mov	bx, ax			; BX - file handle
		mov	ax, 4202h		; seek
		xor	cx, cx
		mov	dx, cx			; to end of file
		int	21h
		jc	sd_close		; did seek fail (impossible)
		add	ax, 15			; para convert
		adc	dx, 0
		test	dx, 0fff0h		; size > 0ffff paras ?
		jz	@f			; no
		mov	DevSize, 0ffffh		; invalid device size
						; assuming that we fail later
		jmp	short sd_close
@@:
		mov	cl, 4			; conver it to paras
		shr	ax, cl
		mov	cl, 12
		shl	dx, cl
		or	ax, dx			;
		mov	DevSize, ax		; save file size
		clc
sd_close:
		pushf				; let close not spoil our
						;  carry flag
		mov	ax, 3e00h		; close
		int	21h			; we are not checking for err
		popf
sd_err:
                pop     ds
		ret
SizeDevice	endp

;
;----------------------------------------------------------------------------
;
; procedure : ExecDev
;
;	Input : ds:dx -> device to be executed
;		DevLoadAddr - contains where device has to be loaded
;
;	Output : Carry if error
;		 Carry clear if no error
;
;	Loads a device driver using the 4b03h function call
;
;----------------------------------------------------------------------------
;
ExecDev		proc	near

		assume	ds:nothing, es:nothing

		mov	bx, DevLoadAddr
		mov	DevExecAddr, bx		; Load the parameter block
						;  block for exec with
						;  Load address
		mov	DevExecReloc, bx
		mov	bx,cs
		mov	es,bx
		mov	bx,offset DevExecAddr	;es:bx points to parameters
		mov	al,3
		mov	ah,exec
		int	21h			;load in the device driver
		ret
ExecDev		endp

;
;----------------------------------------------------------------------------
;
; procedure : RetFromUM
;
;	Input : None
;	Output : ConvLoad set if didn't previously call HideUMBs
;		 ConvLoad clear if did.
;
;	Prepares memory for more devices after returning from loading one
;	using the Dos 6 options (/L:... etc).
;
;----------------------------------------------------------------------------
;
RetFromUM	proc	near
	pushf
	mov	ConvLoad, 1
	call	UnHideUMBs
	jc	@f			; Skip this if didn't HideUMBs:
	mov	ConvLoad, 0
@@:	popf
	ret

RetFromUM	endp


;
;----------------------------------------------------------------------------
;
; procedure : RemoveNull
;
;	Input : ES:SI points to a null terminated string
;
;	Output : none
;
;	Replaces the null at the end of a string with blank
;
;----------------------------------------------------------------------------
;

RemoveNull	proc	near

		assume	ds:nothing, es:nothing

rn_next:
		mov	bl, es:[si]
		or	bl, bl			; null ?
		jz	rn_gotnull
		inc	si			; advance the pointer
		jmp	rn_next
rn_gotnull:
		mov	bl, DevSavedDelim
		mov	byte ptr es:[si], bl	; replace null with blank
		ret
RemoveNull	endp

; Check the conventional memory limit after allocation.

	public  check_low_memory
check_low_memory proc near
	push	ax
	mov	ax,cs:[memhi]
	cmp	cs:[alloclim],ax
	jbe	low_memory_error
	pop	ax
	ret
low_memory_error:
	push	cs
	pop	ds
	call	print_indexed
	dw	800eh
	jmp	stall
check_low_memory endp

;
;----------------------------------------------------------------------------
;
; procedure : RoundBreakAddr
;
;	Input : DevBrkAddr
;	Output : DevBrkAddr
;
;	Rounds DevBrkAddr to a para address so that it is of the form xxxx:0
;
;----------------------------------------------------------------------------
;

RoundBreakAddr	proc	near

		assume	ds:nothing, es:nothing

		mov	ax, word ptr DevBrkAddr
		call	pararound
		add	word ptr DevBrkAddr+2, ax
		mov	word ptr DevBrkAddr, 0
		mov	ax, DevLoadEnd
		cmp	word ptr DevBrkAddr+2, ax
		jbe	rba_ok
		jmp	low_memory_error
rba_ok:
		ret
RoundBreakAddr	endp

;
;----------------------------------------------------------------------------
;
; procedure : DevSetBreak
;
;	Input : DevBrkAddr
;	Output : Carry set if Device returned Init failed
;		 Else carry clear
;
;----------------------------------------------------------------------------
;
DevSetBreak	proc	near

		assume	ds:nothing, es:nothing

		push	ax

		mov	ax,word ptr [DevBrkAddr+2]  ;remove the init code
		cmp	multdeviceflag, 0
		jne	set_break_continue	    ;do not check it.
		cmp	ax, DevLoadAddr
		jne	set_break_continue	    ;if not same, then o.k.

		cmp	word ptr [DevBrkAddr],0
		je	break_failed		;[DevBrkAddr+2]=[memhi] & [DevBrkAddr]=0

set_break_continue:
		call	RoundBreakAddr
		pop	ax
		clc
		ret
break_failed:
		pop	ax
		stc
		ret
DevSetBreak	endp

;
;----------------------------------------------------------------------------
;
; procedure : DevBreak
;
;	Input : DevLoadAddr & DevBrkAddr
;	Output : none
;
;	Marks a succesful install of a device driver
;	Sets device size field in sub-arena &
;	Updates Free ptr in UMB or adjusts memhi
;
;----------------------------------------------------------------------------
;
DevBreak	proc	near

		assume	ds:nothing, es:nothing

		push	ds
		mov	ax, DevLoadAddr
		mov	bx, word ptr [DevBrkAddr+2]
		dec	ax			; seg of sub-arena
		mov	ds, ax
		inc	ax			; Back to Device segment
		sub	ax, bx
		neg	ax			; size of device in paras
		mov	ds:[devmark_size], ax	; store it in sub-arena
		cmp	DeviceHi, 0
		je	db_lo
		mov	DevUMBFree, bx		; update Free ptr in UMB
		jmp	short db_exit
db_lo:
		mov	memhi, bx
		call	check_low_memory
db_exit:
		pop	ds
		ret
DevBreak	endp
;
;----------------------------------------------------------------------------
;
; procedure : ParseSize
;
;	Parses the command line for SIZE= command
;
;	ES:SI = command line to parsed
;
;	returns ptr to command line after SIZE= option in ES:SI
;	updates the DevSizeOption variable with value supplied
;	in SIZE=option
;	Returns carry if the SIZE option was invalid
;
;----------------------------------------------------------------------------
;

co	macro	arg
	mov	dl, arg
	mov	ah, 2
	int	21h
	endm

ParseSize	proc	near

		assume	ds:nothing, es:nothing

		push	bx
		mov	bx, si

		mov	DevSizeOption, 0	; init the value
		mov	word ptr DevCmdLine, si
		mov	word ptr DevCmdLine+2, es
		call	SkipDelim
		cmp	word ptr es:[si], 'IS'
		jne	ps_no_size
		cmp	word ptr es:[si+2], 'EZ'
		jne	ps_no_size
		mov	al, es:[si+4]
		call	delim
		jne	ps_no_size
		add	si, 5
		call	GetHexNum
		jc	ps_err
		mov	DevSizeOption, ax
		call	SkipDelim
		mov	bx, si

ps_no_size:	mov	si, bx
		pop	bx
		clc
		ret
ps_err:
		pop	bx
		stc
		ret
ParseSize	endp
;
;----------------------------------------------------------------------------
;
; procedure : SkipDelim
;
;	Skips delimiters in the string pointed to by ES:SI
;	Returns ptr to first non-delimiter character in ES:SI
;
;----------------------------------------------------------------------------
;
SkipDelim	proc	near

		assume	ds:nothing, es:nothing

sd_next_char:
		mov	al, es:[si]
		call	delim
		jnz	sd_ret
		inc	si
		jmp	sd_next_char
sd_ret:
		ret
SkipDelim	endp
;
;----------------------------------------------------------------------------
;
; procedure : GetHexNum
;
;	Converts an ascii string terminated by a delimiter into binary.
;	Assumes that the ES:SI points to a Hexadecimal string
;
;	Returns in AX the number number of paras equivalent to the
;	hex number of bytes specified by the hexadecimal string.
;
;	Returns carry in case it encountered a non-hex character or
;	if it encountered crlf
;
;----------------------------------------------------------------------------
;

GetHexNum	proc	near

		assume	ds:nothing, es:nothing

		xor	ax, ax
		xor	dx, dx
ghn_next:
		mov	bl, es:[si]
		cmp	bl, cr
		je	ghn_err
		cmp	bl, lf
		je	ghn_err
		push	ax
		mov	al, bl
		call	Delim
		pop	ax
		jz	ghn_into_paras
		call	GetNibble
		jc	ghn_err
		mov	cx, 4
ghn_shift1:
		shl	ax, 1
		rcl	dx, 1
		loop	ghn_shift1
		or	al, bl
		inc	si
		jmp	ghn_next
ghn_into_paras:
		add	ax, 15
		adc	dx, 0
		test	dx, 0fff0h
		jnz	ghn_err
		mov	cx, 4
ghn_shift2:
		clc
		rcr	dx, 1
		rcr	ax, 1
		loop	ghn_shift2
		clc
		ret
ghn_err:
		stc
		ret
GetHexNum	endp
;
;----------------------------------------------------------------------------
;
; procedure : GetNibble
;
;	Convert one nibble (hex digit) in BL into binary
;
;	Retruns binary value in BL
;
;	Returns carry if BL contains non-hex digit
;
;----------------------------------------------------------------------------
;
GetNibble	proc	near
		cmp	bl, '0'
		jb	gnib_err
		cmp	bl, '9'
		ja	is_it_hex
		sub	bl, '0'			; clc
		ret
is_it_hex:
		cmp	bl, 'A'
		jb	gnib_err
		cmp	bl, 'F'
		ja	gnib_err
		sub	bl, 'A'- 10		; clc
		ret
gnib_err:
		stc
		ret
GetNibble	endp
;
;
;============================================================================
;============================================================================
;
;----------------------------------------------------------------------------
;
; procedure : AllocUMB
;
;	Allocate all UMBs and link it to DOS arena chain
;
;----------------------------------------------------------------------------
;
AllocUMB	proc	near
		call	InitAllocUMB		; link in the first UMB
		jc	au_exit			; quit on error
		mov	byte ptr cs:[DevUMBActive],0ffh
		or	word ptr cs:[config_record_flags],2
au_next:
		call	umb_allocate		; allocate
		jc	au_coalesce
		call	umb_insert		; & insert till no UMBs
		jmp	short au_next
au_coalesce:
		call	umb_coalesce		; coalesce all UMBs
au_exit:
		ret
AllocUMB	endp
;
;----------------------------------------------------------------------------
;
; procedure : InitAllocUMB
;
;----------------------------------------------------------------------------
;
InitAllocUMB	proc	near

		call	IsXMSLoaded
		jnz	iau_err			; quit on no XMS driver
		mov	ah, 52h
		int	21h			; get DOS DATA seg
		mov	DevDOSData, es		; & save it for later
		mov	ax, 4310h
		int	2fh
		mov	word ptr DevXMSAddr, bx	; get XMS driver address
		mov	word ptr DevXMSAddr+2, es
		cmp	FirstUMBLinked, 0	; have we already linked a UMB?
		jne	@f			; quit if we already did it
		call	LinkFirstUMB		; else link the first UMB
		jc	iau_err
		mov	FirstUMBLinked, 0ffh	; mark that 1st UMB linked
@@:
		clc
		ret
iau_err:
		stc
		ret
InitAllocUMB	endp

;-------------------------------------------------------------------------
;
; Procedure Name	: umb_allocate
;
; Inputs		: DS = data
;
; Outputs		: if UMB available
;				Allocates the largest available UMB and 
;			  	BX = segment of allocated block
;				DX = size of allocated block
;				NC
;			  else 
;				CY
;
; Uses			: BX, DX
;
;-------------------------------------------------------------------------


umb_allocate	proc	near

		push	ax
		mov	ah, XMM_REQUEST_UMB
		mov	dx, 0ffffh		; try to allocate largest
						;   possible
		call	dword ptr DevXMSAddr
						; dx now contains the size of
						; the largest UMB
		or	dx, dx
		jz	ua_err
	
		mov	ah, XMM_REQUEST_UMB
		call	dword ptr DevXMSAddr

		cmp	ax, 1			; Q: was the reqst successful
		jne	ua_err			; N: error

		clc

ua_done:
		pop	ax
		ret		

ua_err:
		stc
		jmp	short ua_done

umb_allocate	endp



;---------------------------------------------------------------------------
;
; Procedure Name	: umb_insert
;
; Inputs		: DOSDATA:UMB_HEAD = start of umb chain
;			: BX = seg address of UMB to be linked in
;			: DX = size of UMB to be linked in paras
;			; DS = data
;
; Outputs		: links the UMB into the arena chain
;
; Uses			: AX, CX, ES, DX, BX
;
;---------------------------------------------------------------------------


umb_insert	proc	near

		push	ds

		mov	ds, [DevDOSData]
		mov	ds, ds:[UMB_ARENA]	; es = UMB_HEAD
		mov	ax, ds
		mov	es, ax

ui_next:
		cmp	ax, bx			; Q: is current block above
						;    new block
		ja	ui_insert     		; Y: insert it
						; Q: is current block the
						;    last
		cmp	es:[arena_signature], arena_signature_end
		jz	ui_append		; Y: append new block to chain
						; N: get next block

		mov	ds, ax			; M005
		call	get_next		; ax = es = next block
		jmp	short ui_next

ui_insert:
	
		mov	cx, ds			; ds = previous arena
		inc	cx			; top of previous block

		sub	cx, bx
		neg	cx			; cx = size of used block
		mov	ds:[arena_signature], arena_signature_normal
		mov	ds:[arena_owner], 8	; mark as system owned
		mov	ds:[arena_size], cx	
		mov	word ptr ds:[arena_name], 'CS'

; prepare the arena at start of new block

		mov	es, bx
		mov	es:[arena_signature], arena_signature_normal
		mov	es:[arena_owner], arena_owner_system
						; mark as free
		sub	dx, 2			; make room for arena at
						; start & end of new block
		mov	es:[arena_size], dx	
		
; prepare arena at end of new block
	
		add	bx, dx
		inc	bx
		mov	es, bx			; es=arena at top of new block
		inc	bx			; bx=top of new block

						; ax contains arena just above
						; this block
		sub	ax, bx			; ax = size of used block
	
		mov	es:[arena_signature], arena_signature_normal
		mov	es:[arena_owner], 8	; mark as system owned
		mov	es:[arena_size], ax	
		mov	word ptr es:[arena_name], 'CS'

		jmp	short ui_done

ui_append:

						; es = arena of last block	

		add	ax, es:[arena_size]	; ax=top of last block-1 para
		sub	es:[arena_size], 1	; reflect the space we are
						; going to rsrv on top of this 
						; block for the next arena.
		mov	es:[arena_signature], arena_signature_normal

		mov	cx, ax			; cx=top of prev block-1
		inc	ax
		sub	ax, bx			; ax=top of prev block - 
						;    seg. address of new block

		neg	ax

		mov	es, cx			; ds = arena of unused block


		mov	es:[arena_signature], arena_signature_normal
		mov	es:[arena_owner], 8	; mark as system owned
		mov	es:[arena_size], ax	
		mov	word ptr es:[arena_name], 'CS'

; prepare the arena at start of new block

		mov	es, bx
		mov	es:[arena_signature], arena_signature_end
		mov	es:[arena_owner], arena_owner_system
						; mark as free
		dec	dx			; make room for arena
		mov	es:[arena_size], dx	

ui_done:
		pop	ds
		ret

umb_insert	endp


;
;----------------------------------------------------------------------------
;
;**	umb_coalesce - Combine free blocks ahead with current block
;
;	Coalesce adds the block following the argument to the argument block,
;	iff it's free.  Coalesce is usually used to join free blocks, but
;	some callers (such as $setblock) use it to join a free block to it's
;	preceeding allocated block.
;
;	EXIT	'C' clear if OK
;		  (ds) unchanged, this block updated
;		  (ax) = address of next block, IFF not at end
;		'C' set if arena trashed
;	USES	cx, di, ds, es
;
;----------------------------------------------------------------------------
;

umb_coalesce	proc	near



		xor	di, di

		mov	es, [DevDOSData]
		mov	es, es:[UMB_ARENA]	; es = UMB_HEAD

uc_nextfree:
		mov	ax, es
		mov	ds, ax
		cmp	es:[arena_owner], di	; Q: is current arena free
		jz	uc_again		; Y: try to coalesce with next block
						; N: get next arena
		call	get_next		; es, ax = next arena
		jc	uc_done
		jmp	short uc_nextfree
uc_again:
		call	get_next		; ES, AX <- next block
		jc	uc_done
uc_check:
		cmp     es:[arena_owner],di	; Q: is arena free
		jnz	uc_nextfree		; N: get next free arena
						; Y: coalesce
		mov     cx,es:[arena_size]      ; cx <- next block size
		inc     cx                      ; cx <- cx + 1 (for header size)
		add     ds:[arena_size],cx      ; current size <- current size + cx
		mov     cl,es:[di]              ; move up signature
		mov     ds:[di],cl
		jmp     short uc_again		; try again
uc_done:
		ret

umb_coalesce	endp

;
;----------------------------------------------------------------------------
;
;**	get_next - Find Next item in Arena
;
;	ENTRY	dS - pointer to block head
;	EXIT	AX,ES - pointers to next head
;		'C' set iff arena damaged
;
;----------------------------------------------------------------------------
;

get_next	proc	near

		cmp	byte ptr ds:[0], arena_signature_end
		je	gn_err

		mov     ax,ds                   ; ax=current block
		add     ax,ds:[arena_size]      ; ax=ax + current block length
		inc     ax                      ; remember that header!
		mov	es, ax
		clc
		ret
gn_err:
		stc
		ret

get_next	endp

;
;----------------------------------------------------------------------------
;
; procedure : LinkFirstUMB
;
;----------------------------------------------------------------------------
;
LinkFirstUMB	proc	near

		call	umb_allocate
		jc	lfu_err

; bx = segment of allocated UMB
; dx = size of UMB

		int	12h			; ax = size of memory
		mov	cl, 6
		shl	ax, cl			; ax = size in paragraphs

		mov	cx, ax			; cx = size in paras
		sub	ax, bx			; ax = - size of unused block

		neg	ax

		sub	cx, 1			; cx = first umb_arena
		mov	es, cx			; es = first umb_arena
	
		mov	es:[arena_signature], arena_signature_normal
		mov	es:[arena_owner], 8	; mark as system owned
					
		mov	es:[arena_size], ax	
		mov	word ptr es:[arena_name], 'CS'


; put in the arena for the first UMB

		mov	es, bx			; es has first free umb seg
		mov	es:[arena_signature], arena_signature_end
		mov	es:[arena_owner], arena_owner_system	
						; mark as free 
		dec	dx			; make room for arena
		mov	es:[arena_size], dx	


		mov	es, [DevDOSData]
		mov	di, UMB_ARENA
		mov	es:[di], cx		; initialize umb_head in DOS
						;  data segment with the arena
						;  just below Top of Mem

; we must now scan the arena chain and update the size of the last
; arena

		mov	di, DOS_ARENA
		mov	es, word ptr es:[di]	; es = start arena
		xor	di, di

	
scan_next:
		cmp	byte ptr es:[di], arena_signature_end
		jz	got_last
	
		mov	ax, es
		add	ax, es:[arena_size]
		inc	ax
		mov	es, ax
		jmp	short scan_next

got_last:
		sub	es:[arena_size], 1
		mov	es:[arena_signature], arena_signature_normal
		clc
		ret

lfu_err:
		stc
		ret
LinkFirstUMB	endp

;
;----------------------------------------------------------------------------
;
; procedure : ShrinkUMB
;
;	Shrinks the current UMB in use, so that the unused portions
;	of the UMB is given back to the DOS free mem pool
;
;----------------------------------------------------------------------------
;
		public	ShrinkUMB

ShrinkUMB	proc	near
		cmp	DevUMBAddr, 0
		je	su_exit
		push	es
		push	bx
		mov	bx, DevUMBFree
		sub	bx, DevUMBAddr
		mov	es, DevUMBAddr
		mov	ax, 4a00h
		int	21h
		mov	ax, es
		dec	ax
		mov	es, ax
		mov	word ptr es:[arena_owner], 8
		pop	bx
		pop	es
su_exit:
		ret
ShrinkUMB	endp


;M002 - BEGIN
;
;----------------------------------------------------------------------------
;
; procedure : UnlinkUMB
;
;	Unlinks the UMBs from the DOS arena chain
;
;----------------------------------------------------------------------------
;
		public	UnlinkUMB

UnlinkUMB	proc	near
		push	ds
		push	es
		cmp	FirstUMBLinked, 0
		je	ulu_x			; nothing to unlink
		mov	es, DevDOSData		; get DOS data seg
		mov	ds, es:[DOS_ARENA]
		mov	di, es:[UMB_ARENA]
ulu_next:
		call	get_next
		jc	ulu_x
		cmp	di, ax			; is the next one UMB ?
		je	ulu_found
		mov	ds, ax
		jmp	ulu_next
ulu_found:
                mov     ds:[arena_signature], arena_signature_end
ulu_x:
		pop	es
		pop	ds
		ret
UnlinkUMB	endp

;M002 - END

; Allocate a marked block in upper or conventional memory.
; AX = size in paragraphs, BH = marker id, BL = upper-memory flag.
; DS = SYSINITSEG; CX returns the first usable segment.

	public	alloc_marked_block
alloc_marked_block proc near
	push	ax
	or	bl,bl
	jz	alloc_marked_low
	mov	ds:[DevSize],ax
	call	SpaceInUMB?
	jnc	alloc_marked_high
	push	bx
	call	ShrinkUMB
	call	GetUMBForDev
	pop	bx
	jc	alloc_marked_low
alloc_marked_high:
	pop	dx
	mov	cx,ds:[DevUMBFree]
	call	setdevmark7
	mov	ax,dx
	add	dx,cx
	mov	ds:[DevUMBFree],dx
	jmp	short alloc_marked_done
alloc_marked_low:
	pop	dx
	mov	cx,ds:[memhi]
	call	setdevmark7
	add	ds:[memhi],dx
	inc	ds:[memhi]
	call	check_low_memory
	mov	ax,dx
alloc_marked_done:
	ret
alloc_marked_block endp

; Initialize the device marker for an allocated block.
; CX = marker segment, DX = size in paragraphs, BH = marker id.
; CX returns the segment following the marker; ES addresses the marker.

setdevmark7 proc near
	push	bx
	mov	bl,0
	cmp	bh,'R'
	je	mark_internal
	cmp	bh,'G'
	je	mark_internal
	cmp	bh,'Y'
	je	mark_internal
	cmp	bh,'H'
	jne	mark_write
mark_internal:
	mov	bl,bh
	mov	bh,'I'
mark_write:
	mov	es,cx
	mov	es:[devmark_id],bh
	mov	es:[devmark_dum+2],bl
	inc	cx
	mov	es:[devmark_seg],cx
	mov	es:[devmark_size],dx
	pop	bx
	ret
setdevmark7 endp

; Allocate space below the system data arena and write its device marker.
; AX is the number of paragraphs and BH is the marker id.
; DS = SYSINITSEG; CX returns the first paragraph following the marker.
; This allocator grows the system data arena downward.

alloc_system_data proc near
	assume  ds:sysinitseg
	push    dx
	push    si
	push    di
	cmp     ldoff,0
	jne     short alloc_system_have_arena
	mov     dx,area
	dec     dx
	push    ds
	mov     ds,dx
	assume  ds:nothing
	add     dx,word ptr ds:[arena_size]
	dec     word ptr ds:[arena_size]
	mov     es,dx
	xor     si,si
	xor     di,di
	mov     cx,8
	cld
	rep     movsw
	xor     si,si
	mov     byte ptr [si],arena_signature_normal
	mov     word ptr es:[si+arena_size],0
	mov     word ptr es:[si+arena_owner],8
	mov     word ptr es:[si+arena_name],'DS'
	pop     ds
	assume  ds:sysinitseg
	mov     ldoff,es
alloc_system_have_arena:
	mov     dx,area
	dec     dx
	mov     es,dx
	inc     ax
	sub     word ptr es:[arena_size],ax
	mov     dx,ldoff
	push    ds
	mov     ds,dx
	assume  ds:nothing
	sub     dx,ax
	mov     es,dx
	xor     si,si
	xor     di,di
	mov     cx,8
	cld
	rep     movsw
	pop     ds
	assume  ds:sysinitseg
	mov     ldoff,dx
	add     word ptr es:[arena_size],ax
	mov     cx,dx
	inc     cx
	dec     ax
	mov     dx,ax
	call    setdevmark7
	pop     di
	pop     si
	pop     dx
	ret
alloc_system_data endp


; =========================================================================
;
public config_record_name_from_path


	extrn   aspi2dos_loaded:byte,aspi2hlp_loaded:byte
	extrn   aspi2dos_name:byte,aspi2hlp_name:byte


	public  config_record_boot_int13
;
; Record the boot INT 13h handler if it resides below ROM.
; Append to config_record_ptr and update config_record_count.
;
config_record_boot_int13 proc near
	push    ds
	push    es
	mov     ax,70h
	mov     ds,ax
	mov     bx,word ptr ds:[106h]
	mov     dx,word ptr ds:[108h]
	cmp     dx,0a000h
	jae     short config_boot_done
	mov     ds,dx
	cmp     word ptr [bx],0e1eh
	jne     short config_boot_direct
	cmp     byte ptr [bx+2],1fh
	jne     short config_boot_record
	cmp     byte ptr [bx+3],0eah
	jne     short config_boot_indirect
	cmp     word ptr [bx+6],0a000h
	jae     short config_boot_done
	jmp     short config_boot_record
config_boot_indirect:
	cmp     word ptr [bx+3],2effh
	je      short config_boot_pointer
	cmp     word ptr [bx+3],1effh
	jne     short config_boot_record
config_boot_pointer:
	push    bx
	mov     bx,[bx+5]
	cmp     word ptr [bx+2],0a000h
	pop     bx
	jae     short config_boot_done
	jmp     short config_boot_record
config_boot_direct:
	cmp     byte ptr [bx],9ah
	je      short config_boot_segment
	cmp     byte ptr [bx],0eah
	jne     short config_boot_record
config_boot_segment:
	cmp     word ptr [bx+3],0a000h
	jae     short config_boot_done
config_boot_record:
	les     di,cs:[config_record_ptr]
	push    cs
	pop     ds
	mov     si,offset config_mbr_record
	mov     cx,16
	cld
	rep     movsb
	xchg    ax,bx
	stosw
	xchg    ax,dx
	stosw
	mov     cs:word ptr [config_record_ptr],di
	inc     word ptr cs:[config_record_count]
config_boot_done:
	pop     es
	pop     ds
	ret
config_record_boot_int13 endp

	public  config_record_device
;
; Record changes made while initializing a device.
; DS:BX = device header, AL = block device unit count (zero for character).
; Preserve general and segment registers; append changed entries only.
;
config_record_device proc near
	push    ax
	push    bx
	push    cx
	push    dx
	push    si
	push    di
	push    es
	push    ds
	cld
	les     di,cs:[config_record_ptr]
	mov     si,offset config_record_name
	mov     cx,11
	push    si
	push    di
	rep     movs byte ptr es:[di],byte ptr cs:[si]
	pop     di
	pop     si
	mov     es:[di+0dh],al
	xor     ax,ax
	xchg    ax,cs:[config_record_flags]
	mov     es:[di+0bh],ax
	lea     di,[di+0fh]
	xor     cx,cx
	mov     al,1
	mov     dx,ds
	call    config_record_item
	call    config_scsi_entry
	jc      short config_record_bios
	mov     al,6
	call    config_record_item
config_record_bios:
	mov     ax,70h
	mov     ds,ax
	mov     bx,word ptr ds:[0b4h]
	mov     dx,word ptr ds:[0b6h]
	mov     al,3
	call    config_record_item
	xor     ax,ax
	mov     ds,ax
	mov     bx,word ptr ds:[4ch]
	mov     dx,word ptr ds:[4eh]
	mov     al,2
	call    config_record_item
	mov     bx,word ptr ds:[12ch]
	mov     dx,word ptr ds:[12eh]
	mov     al,4
	call    config_record_item
	mov     bx,word ptr ds:[13ch]
	mov     dx,word ptr ds:[13eh]
	mov     al,5
	call    config_record_item
	call    config_record_drives
	mov     bx,cs:[linecount]
	or      bx,bx
	jnz     short config_record_line
	mov     word ptr cs:[config_record_vectors+36],-1
config_record_line:
	xor     dx,dx
	mov     al,8
	call    config_record_item
	mov     bx,cs:[config_file_time]
	mov     dx,cs:[config_file_date]
	mov     ax,bx
	or      ax,dx
	jz      short config_record_ints
	mov     al,9
	call    config_record_item
config_record_ints:
	xor     ax,ax
	mov     word ptr cs:[config_record_vectors+46],ax
	mov     word ptr cs:[config_record_vectors+48],ax
	call    config_record_interrupts
	mov     al,10
	call    config_record_item
	jcxz    config_record_exit
	push    di
	les     di,cs:[config_record_ptr]
	mov     es:[di+0eh],cl
	pop     word ptr cs:[config_record_ptr]
	inc     word ptr cs:[config_record_count]
config_record_exit:
	pop     ds
	pop     es
	pop     di
	pop     si
	pop     dx
	pop     cx
	pop     bx
	pop     ax
	ret
config_record_device endp

; Copy a changed vector into the current device record.
; AL = record id, DX:BX = vector, ES:DI = output, CS:SI = record name.
; Advance DI and increment CX only when the vector has changed.
config_record_item proc near
	push    si
	lea     si,[si+0eh]
	mov     ah,5
	dec     al
	mul     ah
	add     si,ax
	cmp     cs:[si+1],bx
	jne     config_record_changed
	cmp     cs:[si+3],dx
	je      config_record_done
config_record_changed:
	mov     cs:[si+1],bx
	mov     cs:[si+3],dx
	movs    byte ptr es:[di],byte ptr cs:[si]
	movs    word ptr es:[di],word ptr cs:[si]
	movs    word ptr es:[di],word ptr cs:[si]
	inc     cx
config_record_done:
	pop     si
	ret
config_record_item endp

;
; Get the SCSIMGR$ entry point for the device header at DS:BX.
; Return CF clear and DX:BX = entry point on success; CF set otherwise.
;
config_scsi_entry proc near
	push    si
	push    di
	push    ds
	push    es
	push    cx
	lea     si,[bx.sdevname]
	mov     di,offset scsi_device_name
	push    cs
	pop     es
	mov     cx,8
	repe    cmpsb
	jnz     config_scsi_fail
	push    cs
	pop     ds
	mov     dx,offset scsi_device_name
	mov     ax,open shl 8
	int     21h
	jc      config_scsi_fail
	push    ax
	mov     bx,ax
	mov     dx,offset scsi_device_entry
	mov     cx,4
	mov     ax,4402h
	int     21h
	pop     bx
	mov     ah,close
	int     21h
	mov     bx,cs:word ptr [scsi_device_entry]
	mov     dx,cs:word ptr [scsi_device_entry+2]
	clc
	jmp     short config_scsi_done
config_scsi_fail:
	stc
config_scsi_done:
	pop     cx
	pop     es
	pop     ds
	pop     di
	pop     si
	ret
config_scsi_entry endp

	.386
;
; Compare CDS driver pointers with the saved snapshot.
; Append a changed-drive bitmap at ES:DI and increment CX when needed.
;
config_record_drives proc near
	db      66h                     ; 32-bit operand
	mov     word ptr cs:[config_cds_changed],0
	dw      0                       ; upper immediate word
	push    ds
	push    si
	push    cx
	lds     bx,cs:[dosinfo]
	xor     ch,ch
	mov     cl,[bx].sysi_numio
	jcxz    config_drives_done
	xor     dx,dx
	mov     si,offset config_cds_drivers
	lds     bx,[bx].sysi_cds
config_drive_loop:
	push    ds
	push    bx
	test    word ptr [bx.curdir_flags],curdir_inuse
	jz      short config_drive_next
	lds     bx,[bx.curdir_devptr]
	mov     ax,cs:[si]
	cmp     word ptr [bx].dpb_driver_addr,ax
	jne     short config_drive_changed
	mov     ax,cs:[si+2]
	cmp     word ptr [bx].dpb_driver_addr+2,ax
	je      short config_drive_next
config_drive_changed:
	inc     ax
	jz      short config_drive_save
	push    edx
	movzx   edx,dx
	db      66h                     ; 32-bit operand
	bts     word ptr cs:[config_cds_changed],dx
	pop     edx
config_drive_save:
	mov     ax,word ptr [bx].dpb_driver_addr
	mov     cs:[si],ax
	mov     ax,word ptr [bx].dpb_driver_addr+2
	mov     cs:[si+2],ax
config_drive_next:
	add     si,4
	inc     dx
	pop     bx
	pop     ds
	add     bx,curdirlen
	loop    config_drive_loop
config_drives_done:
	pop     cx
	pop     si
	pop     ds
	db      66h                     ; 32-bit operand
	cmp     word ptr cs:[config_cds_changed],0
	jz      short config_drives_exit
	inc     cx
	mov     al,7
	stosb
	mov     ax,word ptr cs:[config_cds_changed]
	stosw
	mov     ax,word ptr cs:[config_cds_changed+2]
	stosw
config_drives_exit:
	ret
config_record_drives endp
	.8086

;
; Build the space-padded device name in config_record_name.
; DS:SI = pathname, DX = its starting offset.  Preserve SI.
;
config_record_name_from_path proc near
	push    si
	push    cs
	pop     es
	mov     di,offset config_record_name
	mov     cx,11
	mov     al,' '
	cld
	rep     stosb
config_find_end:
	lodsb
	or      al,al
	jnz     config_find_end
config_find_start:
	dec     si
	cmp     dx,si
	ja      short config_name_start
	cmp     byte ptr [si],'\'
	je      short config_name_start
	cmp     byte ptr [si],':'
	jne     config_find_start
config_name_start:
	inc     si
	call    config_check_aspi
	mov     cx,8
	mov     di,offset config_record_name
	call    config_copy_name
config_find_extension:
	or      al,al
	jz      short config_name_done
	cmp     al,'.'
	je      short config_copy_extension
	lodsb
	jmp     short config_find_extension
config_copy_extension:
	mov     cx,3
	mov     di,offset config_record_name+8
	call    config_copy_name
config_name_done:
	pop     si
	ret
config_record_name_from_path endp

;
; Copy up to CX name characters from DS:SI to ES:DI.
; Stop at a period or null; return the last character read in AL.
;
config_copy_name proc near
config_copy_name_loop:
	lodsb
	or      al,al
	jz      short config_copy_name_done
	cmp     al,'.'
	je      short config_copy_name_done
	stosb
	loop    config_copy_name_loop
config_copy_name_done:
	ret
config_copy_name endp

;
; Check the basename at DS:SI against ASPI driver names in ES.
; Set the corresponding loaded flag; preserve SI.
;
config_check_aspi proc near
	push    si
	mov     di,offset aspi2dos_name+1
	mov     cx,12
	repe    cmpsb
	jne     short config_check_aspi2
	mov     byte ptr cs:[aspi2dos_loaded],1
	jmp     short config_check_aspi_done
config_check_aspi2:
	pop     si
	push    si
	mov     di,offset aspi2hlp_name+1
	mov     cx,12
	repe    cmpsb
	jne     short config_check_aspi_done
	mov     byte ptr cs:[aspi2hlp_loaded],1
config_check_aspi_done:
	pop     si
	ret
config_check_aspi endp

;
; Save the current CDS driver pointers before device initialization.
; Preserve registers.
;
config_snapshot_drives proc near
	push    ds
	push    es
	push    ax
	push    bx
	push    cx
	push    di
	push    cs
	pop     es
	mov     di,offset config_cds_drivers
	xor     ch,ch
	lds     bx,cs:[dosinfo]
	mov     cl,[bx].sysi_numio
	jcxz    config_snapshot_done
	lds     bx,[bx].sysi_cds
config_snapshot_loop:
	push    ds
	push    bx
	test    word ptr [bx.curdir_flags],curdir_inuse
	jz      short config_snapshot_next
	lds     bx,[bx.curdir_devptr]
	mov     ax,word ptr [bx].dpb_driver_addr
	mov     es:[di],ax
	mov     ax,word ptr [bx].dpb_driver_addr+2
	mov     es:[di+2],ax
config_snapshot_next:
	pop     bx
	pop     ds
	add     bx,curdirlen
	add     di,4
	loop    config_snapshot_loop
config_snapshot_done:
	pop     di
	pop     cx
	pop     bx
	pop     ax
	pop     es
	pop     ds
	ret
config_snapshot_drives endp


	.386
	public  config_record_interrupts
;
; Compare hardware interrupt vectors with the saved snapshot.
; Return the change mask in BX, DX = 0, DS = CS and DF clear.
;
config_record_interrupts proc near
	push    eax
	push    cx
	push    si
	push    di
	push    es
	xor     bx,bx
	mov     es,bx
	mov     di,1dch
	push    cs
	pop     ds
	mov     si,offset config_int_vectors+60
	std
	call    config_compare_interrupts
	mov     di,3ch
	call    config_compare_interrupts
	xor     dx,dx
	cld
	pop     es
	pop     di
	pop     si
	pop     cx
	pop     eax
	ret
config_record_interrupts endp

;
; Compare eight dword vectors at DS:SI and ES:DI with DF set.
; Update the snapshot and shift change bits into BX.
;
config_compare_interrupts proc near
	mov     cx,8
config_interrupt_loop:
	shl     bx,1
	cmpsd
	jz      short config_interrupt_next
	db      66h                     ; 32-bit operand
	mov     ax,word ptr es:[di+4]
	mov     [si+4],eax
	or      bx,1
config_interrupt_next:
	loop    config_interrupt_loop
	ret
config_compare_interrupts endp
	.8086

extrn config_log_device:near,log_device_result:near

ENDIF ; CONFIGPROC
;	Track CONFIG$ device loads and the QEMM memory limit.
;
	assume	cs:sysinitseg,ds:nothing,es:nothing
	public	config_hook_install,config_hook_remove,config_check_qemm
config_hook_install	proc	near
	push	ds
	mov	ax,cs:[bios_data_segment]
	mov	ds,ax
	cli
	mov	ax,offset config_hook_int2f
	mov	word ptr ds:[168h],ax
	mov	ax,cs
	mov	word ptr ds:[16ah],ax
	sti
	mov	byte ptr cs:[config_hook_active],1
	mov	word ptr cs:[config_device_segment],0
	pop	ds
	ret
config_hook_install	endp

config_hook_remove	proc	near
	push	ds
	mov	ax,cs:[bios_data_segment]
	mov	ds,ax
	cli
	mov	ax,offset Bios_Code:i2f_handler
	mov	word ptr ds:[168h],ax
	mov	ax,cs:[BCodeSeg]
	mov	word ptr ds:[16ah],ax
	sti
	mov	byte ptr cs:[config_hook_active],0
	pop	ds
	ret
config_hook_remove	endp

	.286
config_hook_int2f	proc	far
	cmp	ax,4a30h
	je	short config_hook_device
	push	cs:[BCodeSeg]
	push	offset Bios_Code:i2f_handler
	retf
config_hook_device:
	pusha
	push	ds
	push	es
	mov	ax,es:[bx]
	mov	cs:[config_device_segment],ax
	mov	si,dx
	call	config_record_name_from_path
	pop	es
	pop	ds
	popa
	iret
config_hook_int2f	endp
	.8086

qemm_device_name	db	    'QEMM386.SYS'

;
; Scan the line at ES:SI for QEMM386.SYS, ending at LF.
; Set config_ebda_limit to -1 if found; preserve registers.
;
config_check_qemm	proc	near
	push	ds
	push	es
	push	si
	push	di
	push	cx
	push	ax
	push	es
	pop	ds
	push	cs
	pop	es
	cld
	mov	di,offset qemm_device_name
	mov	ah,es:[di]
config_qemm_scan:
	lodsb
	cmp	al,lf
	je	short config_qemm_done
	db	38h,0e0h               ; cmp al,ah
	jne	config_qemm_scan
	push	si
	push	di
	dec	si
	mov	cx,11
	repe	cmpsb
	pop	di
	pop	si
	jne	config_qemm_scan
	mov	word ptr cs:[config_ebda_limit],-1
config_qemm_done:
	pop	ax
	pop	cx
	pop	di
	pop	si
	pop	es
	pop	ds
	ret
config_check_qemm	endp
sysinitseg	ends
		end
