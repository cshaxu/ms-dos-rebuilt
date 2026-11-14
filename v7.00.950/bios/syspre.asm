	page	,160
	title	syspre.asm - pre-load and final placement of dblspace.bin
;/*
; *			 Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1981-1992
; *			 All Rights Reserved.
; */

;	History:
;
;	    09-Jul-1992 chuckst    Initial version
;	    26-Jul-1992 chuckst    substantial changes for final placement
;				   of device driver
;
;	Exported Routines:
;
;	public	MagicPreload	; loads the MagicDrv driver and initializes it
;	public	MagicPostLoad	; does final default placement of Magicdrv.bin
;	public	MagicSetCdss	; let's us disable extra DblSpace drives
;
;	Design Notes:
;
;	    This code was basically stripped out of SYSCONF.ASM, in
;	    the function multi_pass, just after the label tryd:.
;	    The original implementation was to make a special
;	    call to multi_pass with a phoney 'organized' CONFIG.SYS,
;	    but the code is not in the greatest shape, so it was
;	    not really suitable.
;
;	    In this version of the code, I've added better
;	    comments on what the subroutines are expected
;	    to accomplish, and also optimized it a bit since
;	    we don't have to deal with as many special cases
;	    as the main DD loading code.


break	macro	; dummy empty macro for include files
	endm


	.xlist
	include biosseg.inc
	include version.inc
	include sysvar.inc
	include dpb.inc
	include syscall.inc
	include devsym.inc
	include devmark.inc
	include ds_vers.inc
	include curdir.inc
	include magicdrv.inc
	.list

	ifdef	dblspace_hooks

	public	MagicPreload	; loads the MagicDrv driver and initializes it
	public	MagicPostLoad	; does final default placement of Magicdrv.bin
	public	MagicSetCdss	; let's us disable extra DblSpace drives

SYSPRE_BADFILE_ERROR	=	40h	; problem loading dblspace.bin
SYSPRE_EXEC_FAIL_ERROR	=	41h
SYSPRE_MEMORY_ERROR	=	42h
SYSPRE_NO_UNITS_ERROR	=	43h
SYSPRE_TOO_MANY_UNITS_ERROR =	44h
SYSPRE_BAD_SECTOR_SIZE_ERROR =	45h
SYSPRE_NOT_MAGIC	=	46h
SYSPRE_DRIVER_FAILED	=	47h

	extrn	NullBackdoor:near
	extrn	packet:byte
	extrn	MagicBackdoor:dword

	if	ibmjapver
noexec	equ	   true
	else
noexec	equ	   false
	endif



	ifdef	TAIWAN
	extrn	cdosinit:near
	endif

;---------------------------------------



sysinitseg segment
	extrn	print_indexed:near
	extrn	query_check_done:near
	extrn	query_mode_flags:byte,config_cmd:byte
	extrn	sysinit_msg_table:word,sysinit_msg_base:byte
	assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing
	extrn	alloclim:word


	extrn	ExecDev:near
	extrn	DevBreak:near
	extrn	tempcds:near
	extrn	SizeDevice:near
	extrn	RoundBreakAddr:near
	extrn	DevSetBreak:near
	extrn	InitDevLoad:near
	extrn	CheckDeviceSectorSize:near

	extrn	unitcount:byte
	extrn	ConvLoad:byte
	extrn	DeviceHi:byte
	extrn	drivenumber:byte
	extrn	devdrivenum:byte

	extrn	break_addr:dword
	extrn	dosinfo:dword
	extrn	DevEntry:dword
	extrn	bpb_addr:dword
	extrn	DevBrkAddr:dword
	extrn	DevCmdLine:dword

	extrn	DevSize:word
	extrn	DevLoadAddr:word
	extrn	DevLoadEnd:word
	extrn	DevSizeOption:word
        extrn   boot_runtime_flags:byte

	ifdef	COPYCDS
	extrn	newnum_cdss:word
	endif


DrvDDName       db      '\DRVSPACE.BIN',0
DrvIniName	db	'C:\DRVSPACE.INI',0
MagicDDName	db	'C:\DBLSPACE.BIN',0
StackerDDName   db      '\STACKER.BIN',0
MagicRevision	dw	DS_INTERNAL_REVISION
        public  compressed_reserve
compressed_reserve label word           ; paragraphs reserved for compression
NoDDName	dw	0
MagicInitRevision dw	DS_INTERNAL_REVISION
	public	compression_skip,compressed_dest_segment,compressed_reserved_paras
compression_skip db	0
	db	0
compressed_dest_segment dw 0		; reserved image destination
compressed_reserved_paras dw 0		; usable reserved paragraphs
	public	MagicMoveInfo
MagicMoveInfo	dw	-1,-1

;***	MagicPreload - pre-load dblspace.bin
;
;	EXIT	ax = error code, 00 means none.
;		ZF = true if ax == 0
;

MagicCmpRev10 macro
	db	83h,0f8h,0ah	; cmp ax,0ah
	endm

MagicAdd15 macro
	db	83h,0c0h,0fh	; add ax,15
	endm

MagicCmpBlDl macro
	db	38h,0d3h		; cmp bl,dl
	endm

MagicPreload	proc	near

        mov     byte ptr cs:[DeviceHi],0
        mov     word ptr cs:[DevSizeOption],0
	push	cs
	pop	ds
        assume  ds:sysinitseg

        test    byte ptr [boot_runtime_flags],40h
        jz      short pre_keep_reserve
        mov     word ptr [compressed_dest_segment],0
        mov     word ptr [compressed_reserved_paras],0
pre_keep_reserve:

        test    byte ptr [boot_runtime_flags],4
        jnz     short pre7_disabled
	mov	dx,offset DrvIniName+2
	mov	ax,OPEN SHL 8
	int	21h
        jc      short pre7_drvspace
        xchg    ax,bx
        sub     cx,cx
        sub     dx,dx
        mov     ax,(LSEEK SHL 8) OR 2
	int	21h
        add     dx,-1
        sbb     dx,dx
        or      dx,ax
	mov	ah,CLOSE
	int	21h
        test    dx,dx
        jz      short pre7_disabled
pre7_drvspace:
        sbb     bx,bx
        mov     dx,offset DrvDDName
        mov     ax,CHMOD SHL 8
	int	21h
        jc      short pre7_dblspace
        test    bx,bx
        js      short pre7_drv_ini
        mov     si,dx
	jmp	short pre_name_found
pre7_drv_ini:
	mov	dx,offset DrvIniName
        mov     ax,CHMOD SHL 8
	int	21h
        jc      short pre7_dblspace
        mov     si,offset DrvDDName
	jmp	short pre_name_found
pre7_dblspace:
        test    byte ptr [boot_runtime_flags],2
        jnz     short pre7_badfile
	mov	dx,offset MagicDDName+2
        mov     ax,CHMOD SHL 8
	int	21h
        jnc     short pre7_dbl_relative
	mov	dx,offset MagicDDName
        mov     ax,CHMOD SHL 8
	int	21h
        jc      short pre7_stacker
        mov     si,dx
	jmp	short pre_name_found
pre7_stacker:
        mov     si,offset StackerDDName
	jmp	short pre_name_found
pre7_badfile:
	mov	ax,SYSPRE_BADFILE_ERROR
        jmp     short pre_exit1
pre7_disabled:
        test    byte ptr [boot_runtime_flags],2
        jnz     short pre7_badfile
pre7_dbl_relative:
	mov	si,offset MagicDDName+2
pre_name_found:

;	MagicDrv won't actually look at the <null> command tail.

	mov	word ptr [bpb_addr],si	; pass the command line to the device
	mov	word ptr [bpb_addr+2],cs

	mov	word ptr DevCmdLine, si ; save it for error reporting
	mov	word ptr DevCmdLine+2, cs


	push	cs
	pop	es			; get filename pointer to es:si
	call	SizeDevice		; get size of device file into DevSize
	mov	ax,SYSPRE_BADFILE_ERROR
	jc	pre_exit1

	mov	ConvLoad, 1		; Doesn't matter if DeviceHi==0

	call	InitDevLoad		; set up sub-arena, DevLoadAddr,
;					;  DevLoadEnd, and DevEntry
;					;  gets arena name from bpb_addr

;	check to make sure device driver fits our available space.

	mov	ax, cs:DevLoadAddr
	add	ax, cs:DevSize		; calculate seg after DD load
	jc	pre_exit_memory_err1	; choke if overflows address space
	cmp	cs:DevLoadEnd, ax		; does it overflow available space?
	jae	loaddev 		; we're golden if not

pre_exit_memory_err1:
	mov	ax,SYSPRE_MEMORY_ERROR
pre_exit1:
	jmp	pre_exit


loaddev:
	lds	dx,cs:DevCmdLine		; get the load file name
	assume	ds:nothing

	if	noexec
	les	bx,dword ptr cs:[memlo]
	call	ldfil			;load in the device driver

	else

	push	dx
	call	ExecDev 		; load device driver using exec call
	pop	dx

	endif

	mov	ax,SYSPRE_EXEC_FAIL_ERROR
	jc	pre_exit1

	mov	word ptr break_addr, 0	; pass the limit to the DD
	mov	ax, DevLoadEnd
	mov	word ptr break_addr+2, ax


	les	bx,DevEntry		; point to the Magic DD header
	cmp	es:[bx].12h,'.,'	; is it our stamp?
	mov	ax,SYSPRE_NOT_MAGIC
	jz	short pre_magic_header_ok
	jmp	pre_exit_3		; abort if not MagicDrv!!!
pre_magic_header_ok:
	push	cs
	pop	ds
	assume	ds:sysinitseg
	test	byte ptr [compression_skip],1
	jnz	short pre_query_done
	and	byte ptr [query_mode_flags],0bfh
	mov	byte ptr [config_cmd],1
	xchg	ax,dx
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+62]
	cmp	ax,offset DrvDDName
	jnz	short pre_query_driver
	mov	dx,offset sysinit_msg_base
	add	dx,word ptr [sysinit_msg_table+64]
pre_query_driver:
	call	query_check_done
	jnc	short pre_query_done
	or	byte ptr [compression_skip],1
pre_query_done:

;	Now save the backdoor entry.

	mov	bx,14h
	mov	word ptr MagicBackdoor,bx
	mov	word ptr MagicBackdoor+2,es

	mov	al,drivenumber	; pass drive number to DBLSPACE as if
	mov	devdrivenum,al	;  it is a normal block device driver
	cmp	byte ptr es:[bx],0e9h
	jnz	short pre_revision_done
	add	bx,es:[bx+1]
	add	bx,3
	cmp	byte ptr es:[bx],2eh
	jnz	short pre_revision_done
	cmp	word ptr es:[bx+1],063bh
	jnz	short pre_revision_done
	mov	si,es:[bx+3]
	mov	ax,es:[si]
	cmp	ax,MagicRevision
	ja	short pre_revision_done
	mov	MagicRevision,ax
	MagicCmpRev10
	jnz	short pre_revision_done
	add	bx,296h
	cmp	byte ptr es:[bx],2eh
	jz	short pre_revision_patch
	add	bx,1ah
	cmp	byte ptr es:[bx],2eh
	jnz	short pre_revision_done
pre_revision_patch:
	cmp	word ptr es:[bx+1],06f7h
	jnz	short pre_revision_done
	mov	ax,0c3f8h
	test	byte ptr [compression_skip],1
	jz	short pre_revision_store
	mov	ax,0c3f9h
pre_revision_store:
	mov	es:[bx-9],ax
pre_revision_done:
	push	cs
	pop	es			; calldev needs packet segment in es
	mov	bx,offset packet
	mov	si,offset MagicInitRevision
	mov	ax,DS_INTERNAL_REVISION ; tell it what revision we expect
	call	MagicBackdoor	; first time call is init entry point
;					;  with a standard device driver
;					;  init packet at es:bx
	jnc	no_driver_version_fail	; skip if not a version failure

;	In this case, we're going to display a message

	push	cs
	pop	ds
	call	print_indexed
	dw	8021h
	jmp	short fail_driver_load

no_driver_version_fail:
	or	ax,ax			; error code returned?????
	jz	magic_is_resident	; skip if no error

;	point backdoor call back to safe far return

fail_driver_load:
	mov	cs:word ptr MagicMoveInfo,-1
	mov	cs:word ptr MagicBackdoor,offset NullBackdoor
	mov	cs:word ptr MagicBackdoor+2,cs
	mov	ax,SYSPRE_DRIVER_FAILED ; error code
pre_exit_3:
	jmp	near ptr pre_exit_2

;	Normalize the break_addr into ENDSEG:0 form.

magic_is_resident:
	mov	ax,word ptr cs:break_addr
	MagicAdd15
	rcr	ax,1
	.286
	shr	ax,3			; convert to paragraphs
	.8086
	add	ax,word ptr cs:break_addr+2 ; add to terminate segment
	mov	word ptr cs:DevBrkAddr+2,ax
	mov	word ptr cs:DevBrkAddr,0	; store normalized end here

;	see if we can move the bulk of the driver up out of the
;	way for now.

	mov	bx,4			; inquire how many paragraphs it wants
	call	cs:MagicBackdoor

	mov	bx,cs:[alloclim]	; get top of free memory
	sub	bx,ax			; see how much we'll lower it
	cmp	bx,word ptr cs:[DevBrkAddr+2] ; is there that much room free?
	jb	cant_move_driver	; if not, just leave it low

;	BUGBUG -- 29 Jul 92 -- chuckst -- If we are in a very low memory
;					situation, and there isn't enough
;					space free to copy the driver up,
;					we'll just leave it sitting where
;					it is.	The big disadvantage of
;					this is that it can't be placed
;					in a UMB, and the init-resident
;					code will stay resident.

	sub	cs:[alloclim],ax	; allocate space!
	mov	es,cs:[alloclim]
	cmp	word ptr cs:[MagicMoveInfo],-1
	jnz	short pre_move_driver
	cmp	word ptr cs:[MagicRevision],0ah
	jnz	short pre_move_driver
	mov	word ptr cs:[MagicMoveInfo],4149h
pre_move_driver:
	mov	word ptr cs:[MagicMoveInfo+2],es
	mov	bx,6			; tell the driver to move itself
	call	cs:MagicBackdoor

	mov	word ptr cs:[DevBrkAddr+2],ax ; save end of low stub

cant_move_driver:
	mov	ax,word ptr cs:[DevBrkAddr+2] ; get terminate segment
	cmp	ax,cs:DevLoadEnd		; terminate size TOO big?
	mov	ax,SYSPRE_MEMORY_ERROR
	ja	pre_exit2		;  error out if so

	lds	si,cs:DevEntry		;set ds:si to header
	assume	ds:nothing
	les	di,cs:[dosinfo] 	;es:di point to dos info

	jmp	short isblock

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; central error exit

pre_exit_memory_err:
	mov	ax,SYSPRE_MEMORY_ERROR
pre_exit_2:
	jmp	near ptr pre_exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;------ deal with block device drivers
;
isblock:
	mov	al,cs:[unitcount]	;if no units found, erase the device
	or	al,al
	jz	pre_exit_no_units_err

	mov	[si.sdevname],al	; number of units in name field
;					;  device drivers are *supposed*
;					;  to do this for themselves.

	xor	ah,ah
	mov	cx,ax
	mov	dh,ah
	mov	dl,es:[di.sysi_numio]	;get number of devices into dx

	mov	ah,dl
	add	ah,al			; check for too many devices
	cmp	ah,26			; 'A' - 'Z' is 26 devices

	ja	pre_exit_too_many_units_err

	call	DevSetBreak		; alloc the device
	jc	pre_exit_memory_err

	add	es:[di.sysi_numio],al	; update the amount

	ifdef	COPYCDS
	xor	ah,ah
	mov	newnum_cdss, ax 	; save number of new CDSs to be built
endif ; COPYCDS

;	Note:  We won't add in the DblSpace drive count to [drivenumber],
;	which is used to inform future loadable devices of their base address.
;	Instead, we'll leave this alone, and after they load, call
;	back to DBLSPACE to shuffle the drives around.
;
;	add	cs:drivenumber,al	; remember amount for next device

	lds	bx,cs:[bpb_addr]	; point to bpb array

perunit:
	les	bp,cs:[dosinfo]
	les	bp,dword ptr es:[bp.sysi_dpb]	;get first dpb

scandpb:
	cmp	word ptr es:[bp.dpb_next_dpb],-1
	jz	foundpb
	les	bp,es:[bp.dpb_next_dpb]
	jmp	scandpb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Here are some centrally located error exits

pre_exit_too_many_units_err:
	mov	ax,SYSPRE_TOO_MANY_UNITS_ERROR
	jmp	short pre_exit2

pre_exit_no_units_err:
	mov	ax,SYSPRE_NO_UNITS_ERROR
pre_exit2:
	jmp	pre_exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	We've found the end of the DPB chain.  Now extend it.

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

	or	si,-1			; report errors to the preload caller
	call	CheckDeviceSectorSize
	mov	ax,SYSPRE_BAD_SECTOR_SIZE_ERROR
	jc	pre_exit

	inc	dx			; increment drive number
	inc	dh			; increment unit number
	loop	perunit

	push	cs			; restore addressability
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

	mov	word ptr ds:[si],cx		;link in the driver
	mov	word ptr ds:[si+2],dx

;	For the magicdrv load case, assume only one device driver
;	per file.

	call	DevBreak		; mark successful install

	mov	cx, word ptr cs:[DevBrkAddr+2]	; pass it a work buffer
	mov	dx, cs:[alloclim]		;   address in cx (segment)
	sub	dx, cx				;   for len dx (paragraphs)

	mov	ax,5500h		; we're shuffle aware, but don't move
;					;  any drives at this point.
	mov	bx,2			; switch what we can now
	call	cs:MagicBackdoor

	xor	ax,ax			; no errors!!!!

pre_exit:
        test    ax,ax
	ret

MagicPreload	endp


;***	MagicPostload -- called to clean up and make sure Magic is final placed
;

; Final placement of the compression driver, using its reserved image area.
MagicPostload	proc	near
	mov	ax,multMagicdrv
	mov	bx,MD_VERSION
	int	2fh
        or      ax,ax
        jz      short magic7_present
        jmp     near ptr magic7_done
magic7_present:
        test    dx,8000h
        jnz     short magic7_temporary
        jmp     near ptr magic7_done
magic7_temporary:
        mov     bx,-1
	mov	ax,multMagicdrv
	int	2fh
        cmp     ax,cs:[compressed_reserved_paras]
        ja      magic7_alloc
	mov	cx,ax
        mov     es,cs:[compressed_dest_segment]
	mov	ax,multMagicdrv
        mov     bx,-3
	int	2fh
        or      ax,ax
        jz      magic7_done
        xchg    ax,cx
magic7_alloc:
	add	ax,((offset tiny_stub_end - offset tiny_stub_start)+15)/16
        mov     cs:[DevSize],ax
        mov     byte ptr cs:[DeviceHi],0
        mov     word ptr cs:[DevSizeOption],0
        mov     byte ptr cs:[ConvLoad],1
	push	cs
	pop	ds
        mov     word ptr cs:[bpb_addr],offset MagicDDName+2
        mov     word ptr cs:[bpb_addr+2],cs
        call    InitDevLoad
        mov     ax,cs:[DevLoadAddr]
        add     ax,cs:[DevSize]
        mov     word ptr cs:[DevBrkAddr+2],ax
        mov     word ptr cs:[DevBrkAddr],0
        mov     es,cs:[DevLoadAddr]
	mov	si,offset tiny_stub_start
	xor	di,di
        mov     cx,offset tiny_stub_end - offset tiny_stub_start
        rep     movsb
        mov     ax,es
	add	ax,((offset tiny_stub_end - offset tiny_stub_start)+15)/16
	mov	es,ax
	mov	ax,multMagicdrv
        mov     bx,-2
	int	2fh
        call    DevSetBreak
	call	DevBreak
magic7_done:
	ret
MagicPostload	endp

;***	MagicSetCdss -- disable CDSs for still unmounted DblSpace drives
;
;	entry:
;	   CDSs are now persistent and in their final place

MagicSetCdss	proc	near

	mov	ax,multMagicdrv
	mov	bx,MD_VERSION	; get version
	int	2fh
	or	ax,ax		; is it there?
	jnz	magic_set_exit	; done if not

;	version call returned cl=first DblSpace drive in ASCII
;			      ch=number of DblSpace drive letters

	mov	al,cl		; get first DblSpace drive letter
	sub	al,'A'		; make it zero based.
	mov	dl,al		; and save for drive testing loop

	les	si,[dosinfo]	; point to DOS data area
	les	si,es:[si].sysi_cds ; fetch CDSs
	mov	ah,curdirLen
	mul	ah		; find first DblSpace CDS
	add	si,ax

	mov	cl,ch		; get DblSpace drive count into cx
	xor	ch,ch

;	We know cx > 0, or else the driver wouldn't have stayed resident

magic_set_cdss_1:

	push	si		; save cds pointer
	push	es
	push	cx		; save loop count
	push	dx		; and drive letter

	mov	ax,multMagicdrv
	mov	bx,MD_DRIVE_MAP ; inquire drive map
	int	2fh		; see if this is an unused DblSpace drive

	pop	dx
	pop	cx
	pop	es
	pop	si

	MagicCmpBlDl		; if mapped to itself, it is vacant
	jnz	magic_set_cdss_2 ; skip if used

	and	es:[si].CURDIR_FLAGS,not CURDIR_inuse ; reset the bit in flags

magic_set_cdss_2:
	add	si,curdirLen
	inc	dl		; next drive
	loop	magic_set_cdss_1

magic_set_exit:
	ret

MagicSetCdss	endp


tiny_stub_start:
	dw	-1,-1		; phony device driver link
	dw	8000h		; mark as character device for MEM display
	dw	0,0		; strat and irpt
	db	'DBLSBIN$'	; magic default load
tiny_stub_end:


sysinitseg ends
	endif			; ifdef dblspace_hooks

	end
