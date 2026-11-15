	include	bioscode.inc

;
; SYSINIT state, boot image storage and configuration workspace.
;

.8086
include oemconf.inc
break	macro	arg
	endm
	include	exe.inc
Bios_Data	segment byte public 'bios_data'
Bios_Data	ends
Bios_Code	segment byte public 'CODE'
	extrn	seg_reinit:far
Bios_Code	ends
sysinitseg segment byte public 'system_init'
CR equ 13
LF equ 10
stacksw equ 1
	public  dosinfo
	public  device_list
	public  sysi_country
	public  dos_segreinit
	public  lo_doscod_size
	public  hi_doscod_size
	public  def_php
	public  disksector_pending_size
	public  temp_bcode_seg
	public  no_floppy_report
	public  fake_floppy_drv
	public  dos_umb_flag
	public  exec_boot_state
	public  sysinit_memory_size
	public  rpl_memory_size
	public  RPLMemTop
	public  default_drive
	public  buffers
	public  h_buffers
	public  singlebuffersize
	public  files
	public  fcbs
	public  keep
	public  num_cds
	public  confbot
	public  alloclim
	public  top_of_cdss
	public  DirStrng
	public  zero
	public  sepchr
	public  linecount
	public  showcount
	public  buffer_linenum
	public  buf_prev_off
	public  default_num_cds
ifdef COPYCDS
	public oldnum_cdss,newnum_cdss
endif
dosinfo	dd	0		; address of the DOS Sysini Variables

device_list dd	0

sysi_country dd	0			; pointer to country table in dos

dos_segreinit	dw	offset Bios_Code:seg_reinit,Bios_Code

lo_doscod_size	dw	0		; dos code size when in low mem
hi_doscod_size	dw	0		; dos code size when in HMA

def_php		dw	0


disksector_pending_size dw 200h         ; temporary disk buffer size
temp_bcode_seg dw 0                    ; relocated BIOS code segment
no_floppy_report label byte
fake_floppy_drv db 0			;set to 1 if this machine
					;does not have any floppies!!!

dos_umb_flag    db      1               ; DOS=UMB enabled
exec_boot_state db      0

; CDS counts for device initialization.

ifdef		COPYCDS
oldnum_cdss	dw	?		; number of DPB/CDSs built so far
newnum_cdss	dw	?		; number of CDSs to be built for the
					;  newly initialized device
endif ; COPYCDS

	if	stacksw
	endif

; various default values

sysinit_memory_size dw 1               ; memory available to SYSINIT
rpl_memory_size label word
RPLMemTop	dw	0
default_drive	db	0		;initialized by ibminit.
buffers         dw      -1
h_buffers	dw	0		; # of the heuristic buffers. initially 0.
singlebuffersize dw	?		; maximum sector size + buffer header

files	db	30		; enough files for pipe
fcbs	db	4		; performance for recycling
keep	db	0			; keep original set
num_cds db	26		; 5 net drives
confbot dw	?
alloclim dw	?
	public	boot_buffer_segment
boot_buffer_segment dw 0		; segment of the temporary boot buffer
top_of_cdss	dw	?
DirStrng db	"A:\",0                 ; string for the root directory of a drive
zero	db	0
sepchr	db	0
linecount dw    0                       ; line count in config.sys
showcount db    '     ',cr,lf,'$'       ; used to convert linecount to ascii.
buffer_linenum dw 0			; line count for "buffers=" command if entered.


buf_prev_off dw 0
default_num_cds db 26                   ; default drive count for DOS=UMB

;	Boot image segments and temporary buffer storage.
;
	public	bios_data_segment,BCodeSeg
	public	memory_size,temp_buffer_segment,temp_buffer_size
	public	boot_data_high,boot_data_low

bios_data_segment dw	Bios_Data
BCodeSeg	dw	Bios_Code
memory_size	dw	1
temp_buffer_segment dw	0		; temporary DOS buffer segment
temp_buffer_size dw	4018h		; bytes reserved for temporary buffers
boot_data_high	dw	0		; boot loader data, high word
boot_data_low	dw	0		; boot loader data, low word
;	INSTALL and configuration-command state.
;
	public  multi_pass_id
	public  install_flag
	public  config_size
	public  sysinit_base_ptr
	public  sysinit_ptr
	public  ldexec_fcb
	public  ldexec_line
	public  ldexec_start
	public  ldexec_parm
	public  instexe
	public  com_level
	public  cmmt
	public  cmmt1
	public  cmmt2
	public  cmd_indicator
	public  donotshownum
	public  count
	public  org_count
	public  chrptr
	public  cntryfilehandle
	public  old_area
	public  impossible_owner_size
install_flag	db	0
multi_pass_id	db	0		; parameter passed to multi_pass
					;  indicating the pass number
					; 0 - do scan for DOS=HIGH/LOW
					; 1 - process configuration options
					; 2 - load device drivers
					; 3 - process INSTALL and access dates

have_install_cmd equ	00000001b	; config.sys has install= commands
has_installed	equ	00000010b	; sysinit_base installed.

config_size	dw	0		; size of config.sys file. set by sysconf.asm
sysinit_base_ptr dd	0		; pointer to sysinit_base
sysinit_ptr	dd	0		; returning addr. from sysinit_base

ldexec_fcb	db	20 dup (' ')	;big enough
ldexec_line	db	0		;# of parm characters
ldexec_start	db	' '
ldexec_parm	db	80 dup (0)

instexe exec0	<0,ldexec_line,ldexec_fcb,ldexec_fcb>

;------------------------------------------------------------------
;variables for comment=

com_level	db	0		;level of " " in command line
cmmt		db	0		;length of comment string token
cmmt1		db	0		;token
cmmt2		db	0		;token
cmd_indicator	db	?
donotshownum	db	0

;------------------------------------------------------------------
count		dw	0
org_count	dw	0
chrptr		dw	0
cntryfilehandle dw	0
old_area	dw	0
impossible_owner_size dw 0		; paragraph

;	Memory allocation state.  Keep the aliased fields in this order.
;
	public	area,bucketptr,bufptr,memlo,prmblk,memhi,ldoff
	public	drivenumber,boot_mode
area	dw	0
bucketptr label dword
bufptr	label	dword			;leave this stuff in order!
memlo	dw	0
prmblk	label	word
memhi	dw	0
ldoff	dw	0
drivenumber	db	0
boot_mode db 0                         ; startup mode selected from files
;	Device table, relocated PSP and message resource sizes.
;
	public  toomanydrivesflag
	public  config_device_table_ptr
	public  new_psp_segment
toomanydrivesflag db    0               ;>24 fixed disk partitions flag   ; M029 
config_device_table_ptr dd 0           ; DOS initialization table entry
new_psp_segment dw 0                   ; relocated default PSP

sysinitseg ends
end
