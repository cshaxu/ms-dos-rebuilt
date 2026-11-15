;**	msinit.asm -- ms-dos initialization code
;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;
;
;	an000 version 4.0 jan. 1988
;	an007 ptm 3957 - fake version for ibmcache.com
;	an008 ptm 4070 - fake version for ms windows
;
;
;
;
;
;	Revision History
;	================
;
;	M019	SR	08/30/90	Changed number of instance items for
;				Win 3.1 UMB support.
;
; 	M020 : Fix for Rational bug for details see exepatch.asm
;
;	M023	SR	09/7/90	Initialize exepatch & Rational patch
;				ptrs here. Previous init in lmstub.asm
;				causes extrn problems when msdata is
;				linked in by other utilities e.g.Share
;
;	M068 - support for copy protected apps.
;
;	M079 - skip block device drivers which return 0 units
;

	.xlist
	.xcref
	include version.inc
	include dossym.inc
	include mssw.asm
	include dosseg.inc
	include sf.inc
	include curdir.inc
	include dpb.inc
	include arena.inc
	include vector.inc
	include devsym.inc
	include pdb.inc
	include find.inc
	include mi.inc
	include xmm.inc
	installed = true


	include sysvar.inc
	include doscntry.inc
	include fastopen.inc
	include bugtyp.inc
	include	cputype.inc			; M020

	include win386.inc	;Win386 constants

	.cref
	.list




Bios_Data	segment word public 'Bios_Data'

	extrn	DosDataSg:word		; using this to access the data seg

ifdef ROMDOS
	extrn	DOS_Res:word
endif

Bios_Data	ends

;
; This macro gets the DOS data segment value and puts it in the specified
; segment register.  This is the init segment version of GetDseg in dosmac
;

InitGetdseg	macro 	r

ifdef ROMDOS
	mov	r, cs:[InitBioDataSeg]
	assume	r:Bios_Data
	mov	r, r:[DosDataSg]
else
	mov	r, cs:[DosDseg]
endif
	assume	r:dosdata
endm




DOSDATA SEGMENT

	extrn	dmaadd:dword		; current dma address
	extrn	DPBHead:dword		; long pointer to dpb chain
	extrn	sft_addr:dword		; pointer to open file list
	extrn	NlsBuffer:byte
	extrn	numio:byte		; number of physical drives
	extrn	buffhead:dword		; pointer to buffer chain
	extrn	endmem:word		; first unavailable address in memory
	extrn	currentpdb:word 	; current process id
	extrn	createpdb:byte		; true => create a new pdb
	extrn	arena_head:word 	; paragraph address of head of arena
	extrn	sftabl:byte		; internal file table
	extrn	sysinitvar:byte 	; label for internal structures
	extrn	nuldev:dword		; long pointer to device chain
	extrn	bcon:dword		; pointer to console device
	extrn	bclock:dword		; pointer to clock device
	extrn	callunit:byte		; unit field in dd packet
	extrn	callbpb:dword		; returned bpb from dd
	extrn	maxsec:word
	extrn	dskchret:byte
	extrn	devcall:byte
	extrn	jshare:dword
	extrn	country_cdpg:byte	 ; country info table, dos 3.3
	extrn	sysinittable:byte	 ; sys init table for sysinit
	extrn	special_entries:word	 ; address of special entries ;an007;
	extrn	hashinitvar:word	 ; hash table variables       ;an000;
	extrn	packet_temp:word	 ; used for initial hash table;an000;


	extrn	user_ss:word
	extrn	user_sp:word

	extrn	msdat001e:byte		; end of dosdata segment
	extrn	msct001s:byte		; start of dosdata segment	


	extrn	dskstack:byte
	extrn	temp_dosloc:word	; stores the temp. location of DOS seg

;SR;
; WIN386 instance table variables
;
	extrn	Win386_Info:byte, Instance_Table:word, Instance_Table2:word

;
;Win386 2.xx instance table
;


	extrn	fixexepatch:word
	extrn	ChkCopyProt:word	; M068

IFDEF	ROMDOS
	extrn	I20To28Count:word
ENDIF

DOSDATA ENDS


DOSCODE	SEGMENT

	extrn	irett:near
	extrn	HardErrDefault:near
	extrn	int2f:near
	extrn	call_entry:near
	extrn	quit:near
	extrn	command:near
	extrn	absdrd:near
	extrn	absdwrt:near
	extrn	DivOvEntry:near
	extrn	stay_resident:near


	extrn	$startcode:word
	extrn	header:byte


	extrn	exepatch:near		; Routine in exepatch.asm
	extrn	exepatch_start:byte	; in exepatch.asm
	extrn	RetExePatch:near	; M023

ifndef	ROMDOS
	extrn	ConsoleStatePtr:dword

	extrn	dosdseg:word		; used by InitGetDseg macro
endif

;
; When using ROMDOS, init code is not in the DOSCODE segment.  Therefore,
; we need some entry points in DOSCODE to allow far calls to be made to
; certain routines in the DOS.  These just do a near call to the appropriate
; routine, and then do a far return back to the init code.
;
ifdef	ROMDOS

$setdpb_far	proc	far
	invoke	$setdpb
	ret
$setdpb_far	endp

setmem_far	proc	far
	invoke	setmem
	ret
setmem_far	endp

deviocall2_far	proc	far
	invoke	deviocall2
	ret
deviocall2_far	endp

endif ; ROMDOS

	public	sysbuf

sysbuf	label	word

	ASSUME	cs:doscode,ds:nothing,es:nothing,ss:nothing


; ROMDOS Note:  For RomDos, all the initialization stuff goes into
; the segment DOSINITSEG instead of DOSCODE.  The entry point from
; the BIOS will actually be right here.

ifdef ROMDOS

DOSCODE		ENDS

DOSINITSEG	segment

	assume	cs:dosinitseg

	jmp	SHORT DosInit		; jump down to the starting point

; We need to make some far calls from here to the DOS code, but we're not
; sure where it will be.  There are some special far entry points into
; the DOS (see above), so we need to set up some far pointer to them so
; that we can make the calls.  The segment parts of these pointers will
; be patched in at runtime (below).

$setdpb_ptr	dd	offset doscode:$setdpb_far
setmem_ptr	dd	offset doscode:setmem_far
deviocall2_ptr	dd	offset doscode:deviocall2_far


endif ; ROMDOS


; pointer to the BIOS data segment that will be available just to the
; initialization code

IFDEF ROMDOS
InitBioDataSeg	dw	70H
ENDIF


;
; MAIN ENTRY FOR DOS INITIALIZATION
;

	ENTRY	DosInit

	cli
	cld

	push	ds			; save BIOS device chain
	push	si
	mov	WORD PTR CS:ConsoleStatePtr,ax
	mov	WORD PTR CS:ConsoleStatePtr+2,bx

; Move DOSDATA to its low-memory location.
	mov	ax,SEG COUNTRY_CDPG
	mov	ds,ax
	mov	ax,70h			; BIOS data segment
	mov	es,ax
	assume	es:Bios_Data
	mov	es,es:[DosDataSg]
	assume	es:nothing
	xor	si,si
	xor	di,di
	mov	cx,offset MSDAT001e
	.386
	shr	cx,2
	rep	movsd
	push	es
	pop	ds
	assume	ds:dosdata

	mov	si,offset dosdata:country_cdpg
	mov	word ptr [si.ccucase_ptr + 2],ds
	mov	word ptr [si.ccfileucase_ptr + 2],ds
	mov	word ptr [si.ccfilechar_ptr + 2],ds
	mov	word ptr [si.cccollate_ptr + 2],ds
	mov	word ptr [si.ccmono_ptr + 2],ds
	mov	word ptr [si.ccdbcs_ptr + 2],ds

	pop	dword ptr [nuldev]
	.8086
	mov	[endmem],dx
	mov	cs:[dosdseg],es
	mov	ax,cs
	call	InitLowVectors

	mov	[user_sp],sp
	mov	[user_ss],ss

	mov	ax,ds			; set up ss:sp to dosdata:dskstack
	mov	ss,ax
	assume	ss:dosdata

	mov	sp,offset dosdata:dskstack

;M023
; Init patch ptrs to default values
;
	mov	FixExePatch, offset DOSCODE:RetExePatch		; M023
	mov	[ChkCopyProt], offset DOSCODE:RetExePatch	; M068


	PUBLIC Init_Instance_Tables
Init_Instance_Tables:
	mov	word ptr [Win386_Info + SIS_Instance_Data_Ptr + 2],ds
	mov	word ptr [Win386_Info + SIS_Instance_Data_Ptr + 6],ds
	mov	si,offset dosdata:Instance_Table+2
Instance_init_loop:
	cmp	word ptr [si],0
	je	Instance_next_table
	mov	word ptr [si],ds
	add	si,size Win386_IIS
	jmp	short Instance_init_loop
Instance_next_table:
	cmp	si,offset dosdata:Instance_Table2+2
	jae	Instance_init_done
	mov	si,offset dosdata:Instance_Table2+2
	jmp	short Instance_init_loop
Instance_init_done:
	lds	si,nuldev
	assume ds:nothing

	mov	ax,0
	call	charinit  		; initialize console driver
	push	si			; save pointer to header

	push	ss			; move pointer to dos data...
	pop	es			; ...into ES
	assume	es:dosdata

	;initialize sft for file 0 (CON)

	mov	di,offset dosdata:sftabl + sftable   
	mov	ax,3
	stosw				; refcount
	dec	al
	.errnz	sf_mode-(sf_ref_count+2)
	stosw				; access rd/wr, compatibility
	xor	al,al
	.errnz	sf_attr-(sf_mode+2)
	stosb				; attribute
	mov	al,devid_device_eof or devid_device or iscin or iscout
	.errnz	sf_flags-(sf_attr+1)
	stosw				; flags
	mov	ax,si
	.errnz	sf_devptr-(sf_flags+2)
	stosw				; device pointer in devptr
	mov	ax,ds
	stosw
	.386
	xor	eax,eax
	mov	DWORD PTR es:[di+sf_firclus32-sf_firclus],eax
	.errnz	sf_firclus-(sf_devptr+4)
	stosd				; first cluster and time
	stosw				; date
	dec	ax
	stosd				; size
	inc	ax
	stosd				; position
	add	di,sf_name - sf_cluspos
	add	si,sdevname
	mov	cx,2
	rep	movsd			; name
	.8086
	mov	cl,3
	mov	al," "
	rep	stosb			; extension
	pop	si			; get back pointer to header

					; mark device as CON I/O
	or	byte ptr [si.sdevatt],iscin or iscout
	mov	word ptr [bcon],si
	mov	word ptr [bcon+2],ds

	; initialize each device until the clock device is found

char_init_loop:
	lds	si,dword ptr [si]	; aux device
	mov	ax,0
	call	charinit
	test	byte ptr [si.sdevatt],isclock
	jz	char_init_loop
	
	mov	word ptr [bclock],si	; bclock -> clock device
	mov	word ptr [bclock+2],ds

					; bp = pointer to free mem
	mov	bp,offset MSDAT001e	; es:bp points to dpb area

	mov	word ptr [DPBHead], bp	; set offset of pointer to DPB's
	mov	word ptr [DPBHead+2], es; set segment of pointer to DPB's

	; build dpb for each unit in each block device

perdrv:
	lds	si,SDEVNEXT [si]	; next device
	cmp	si,-1			; Q: any more devices
	.386
	JE	NEAR PTR continit
	.8086
	mov	ax,0
	call	charinit		;  Y: initialize the device
	test	[si.sdevatt],devtyp	; Q: is it a block device
	jnz	perdrv			; skip any other character devs
	mov	cl,[callunit]
	xor	ch,ch
IFDEF	ROMDOS
	jcxz	perdrv			; skip to next dev if 0 units	; M079
ENDIF ; ROMDOS
	mov	[si.sdevname],cl	; number of units in name field
	mov	bl,numio		; BL is drive number, DH is unit
	mov	bh,0
	mov	dh,0
	add	numio,cl
perunit:
	mov	dl,0
	test	byte ptr [si.sdevatt+1],8
	jz	InitUnitBPB
	mov	al,0fh			; removable-media request
	mov	ah,dh
	call	charinit
	test	ah,2
	jz	InitUnitBPB
	or	dl,6
InitUnitBPB:
	push	ds
	push	si
	lds	si,callbpb
	mov	si,[si]
	add	word ptr callbpb,2
	mov	es:[bp].DPB_DRIVE,bl
	mov	es:[bp].DPB_UNIT,dh
	or	byte ptr [bx+NlsBuffer+20],dl
	push	bx			; save regs of interest while building
	push	cx
	push	dx
	mov	cx,4558h		; extended BPB signature
	mov	dx,4152h
ifndef ROMDOS
	invoke	$setdpb			; build DPB!
else
	call	dword ptr [$setdpb_ptr]	; call $setdpb in DOSCODE
endif ; ROMDOS
	mov	ax,es:[bp].DPB_SECTOR_SIZE
	cmp	ax,maxsec		; Q:is this the largest sector so far
	jbe	notmax			; N:
	mov	maxsec,ax		; Y: save it in maxsec
notmax:

					; set the next dpb field in the 
					; currently built bpb and mark as 
					; never accessed

	mov	ax, bp			; get pointer to DPB
	db	083h,0c0h,DPBSIZ	; ADD AX,DPBSIZ (signed immediate)
					; set seg & offset of next DPB
	mov	word ptr es:[bp].DPB_NEXT_DPB, ax
	mov	word ptr es:[bp].DPB_NEXT_DPB+2, es
					; mark as never accessed
	mov	es:[bp].DPB_FIRST_ACCESS, 80h

	pop	dx			; restore regs
	pop	cx
	pop	bx
	pop	si			
	pop	ds			; ds:si -> device header
					; store it in the corresponding dpb
	mov	word ptr es:[bp].DPB_DRIVER_ADDR,si
	mov	word ptr es:[bp].DPB_DRIVER_ADDR+2,ds
	
	inc	dh			; next unit
	inc	bx			; next drive
	add	bp,DPBSIZ
	loop	perunit
	jmp	perdrv

continit:
					; set link in last DPB to -1
	sub	bp,DPBSIZ		; back up to last dpb
					; set last link offset & segment
	mov	word ptr [bp].DPB_NEXT_DPB,-1
	mov	word ptr [bp].DPB_NEXT_DPB+2,-1
	add	BP, DPBSIZ		; advance to free memory again
					; the DPB chain is done.  

;M060;	; let's compute the length of the version_fake_table
;M060;
;M060;	mov	si,offset version_fake_table	
;M060;	mov	dx,si		     	; dx = start of version table
;M060;	xor	ah,ah		     
;M060;	
;M060;	push	cs
;M060;	pop	ds			; ds:si -> version_fake_table
;M060;
;M060;nxtentry:
;M060;	lodsb			     	; get name length
;M060;	or	al,al		     	; Q: end of list
;M060;	jz	endlist 	     	;  Y:
;M060;	add	si,ax		     	;  N:position to
;M060;
;M060;	add	SI,2			; SI -> next entry
;M060;;***	add	si,3		;    next entry
;M060;
;M060;	jmp	nxtentry
;M060;endlist:			     
;M060;	sub	si,dx		     
;M060;
;M060;	
;M060;	; set up the following:
;M060;	; ds:si -> version_fake_table (in doscode, or dosinitseg if romdos)
;M060;	; es:di -> dosdata:free mem (bp)
;M060;	; cx = length of version_fake_table
;M060;	
;M060;	mov	cx, si
;M060;	mov	si, offset version_fake_table
;M060;	mov	di, bp
;M060;	push	ss
;M060;	pop	es			; es -> dosdata
;M060;	push	cs
;M060;	pop	ds			; ds -> doscode (dosinitseg if romdos)
;M060;
;M060;	rep	movsb			; copy the version_fake_table at the
;M060;					; end of the dpbs
	push	ss
	pop	ds

	assume	ds:dosdata

;M060;	mov	[special_entries], bp	; store start fake version table
;M060;	mov	bp,di

	mov	ax,bp
	.386
	add	ax,15			; round up to a paragraph
	shr	ax,4
	.8086

	mov	dx,ds			; dx = dosdata segment
	add	dx,ax			; dx = ds+ax first free segment


					; set seg inpacketto dosdata					
	mov	word ptr [dskchret+3],ds


; Set the interrupt offsets in the resident code.
	xor	ax,ax
	mov	ds,ax
	mov	es,ax
assume	ds:nothing,es:nothing

	; set default divide trap offset

	mov	word ptr ds:[0],offset doscode:DivOvEntry
	; set vectors 20-28 and 2a-3f to point to iret.

	mov	di,intbase
	mov	ax,offset doscode:irett

IFDEF	ROMDOS
	mov	cx,dosdata:i20To28Count	; set 9 offsets (skip 2 between each)
					; or 8 offsets depending on POWER
					; being included in BIOS or not
					;   sets offsets for ints 20h-28h/27h
					; ALSO LOOK AT inc\LMSTUB.ASM
ELSE
	mov	cx,9			; set 9 offsets (skip 2 between each)
					;   sets offsets for ints 20h-28h
ENDIF

iset1:
	stosw
	add	di,2
	loop	iset1

IFDEF ROMDOS
	mov	di,intbase
	add	di,10 * 4
	
ELSE
	add	di,4			; skip vector 29h
ENDIF

	mov	cx,6			; set 6 offsets (skip 2 between each)
					;   sets offsets for ints 2ah-2fh
iset2:
	stosw
	add	di,2
	loop	iset2

; 30h & 31H is the CPM call entry point whose segment address is set up by
; patch_vec_segments above. So skip it.

	add	di,8			; skip vector 30h & 31h 


	mov	cx,14			; set 14 offsets (skip 2 between each)
					;   sets offsets for ints 32h-3fh
iset3:
	stosw
	add	di,2
	loop	iset3


	; set up entry point call at vectors 30-31h. Note the segment of the 
	; long jump will be patched in by  seg_reinit

	mov	byte ptr ds:[entrypoint],mi_long_jmp
	mov	word ptr ds:[entrypoint+1],offset doscode:call_entry


	mov	word ptr ds:[addr_int_abort],offset doscode:quit
	mov	word ptr ds:[addr_int_fatal_abort],offset doscode:HardErrDefault
	mov	word ptr ds:[addr_int_command],offset doscode:command
	mov	word ptr ds:[addr_int_disk_read],offset doscode:absdrd
	mov	word ptr ds:[addr_int_disk_write],offset doscode:absdwrt
	mov	word ptr ds:[addr_int_keep_process],offset doscode:stay_resident
	mov	word ptr ds:[addr_int_terminate],100h
	mov	word ptr ds:[addr_int_terminate+2],dx

	push	ss
	pop	es
	mov	word ptr ds:[02fh * 4],offset doscode:int2f
	push	ss
	pop	ds
assume	ds:dosdata,es:dosdata

	push	dx			; remember address of arena

	inc	dx			; leave room for arena header
        mov     [currentpdb], dx	; set current pdb

	xor	di, di			; point es:di at end of memory
	mov	es, dx			; ...where psp will be
	assume	es:nothing
	.386
	xor	eax,eax
	mov	cx,40h			; PSP is 64 doublewords
	rep	stosd
	.8086
        mov     ax,[endmem]

ifndef ROMDOS	
        invoke  setmem         	 	; build psp at dx; ax is memory size
else
	call	dword ptr [setmem_ptr]	; call setmem in DOSCODE
endif ;ROMDOS

	; ds, es now point to PSP

	assume	ds:nothing,es:nothing

	push	ss
	pop	ds
	assume	ds:dosdata

	mov	di,pdb_jfn_table	; es:di -> pdb_jfn_table in psp
	xor	ax,ax
	stosw
	stosb				; 0,1 and 2 are con device
	mov	al,0ffh
	mov	cx,filperproc - 3
	rep	stosb			; rest are unused

	push	ss
	pop	es
	assume	es:dosdata
					; must be set to print messages
	mov	word ptr [sft_addr+2],ds     
	mov	word ptr [sftabl+SFLink+2],ds

; after this point the char device functions for con will work for
; printing messages

	if	(ibm EQ FALSE) or (debug)
	mov	si,offset doscode:header
outmes:
	lods	cs:byte ptr [si]
	cmp	al,"$"
	jz	outdone
	invoke	outt
	jmp	short outmes
outdone:
	push	ss			; out stomps on segments
	pop	ds
	push	ss
	pop	es
	endif

if	DEBUG
	mov	ax,11100011b
	sub	dx,dx
	int	14h			; init serial port, 9600 baud
endif
	fmt TypSysCall,LevLog,<"Start Boot - CS=$x\n">,<CS>

	; at this point es is dosdata

	; Fill in the segment addresses of sysinitvar and country_cdpg 
	; in sysinittable (ms_data.asm)

	mov	si,offset dosdata:sysinittable
	mov	word ptr es:[si.sysi_country_tab + 2],es
	mov	word ptr es:[si.sysi_initvars + 2],es

	; buffhead -> dosdata:hashinitvar 

	mov	word ptr es:[buffhead+2],es	; BUGBUG - unused, remove this
	mov	si,offset dosdata:hashinitvar	; and all other references
	mov	word ptr es:[buffhead],si

        pop     dx                      ; restore address of arena

        mov     word ptr [dmaadd+2],dx

        mov     es:[arena_head],dx
        mov     ds, dx
	assume	ds:nothing

        mov     ds:[arena_signature],arena_signature_end
        mov     ds:[arena_owner],arena_owner_system
        mov     ax, [endmem]
	sub	ax, dx
        dec     ax
        mov     ds:[arena_size],ax

	; point to sft 0

        mov     di,offset dosdata:sftabl + sftable   
        mov     ax,3
        stosw           		; adjust refcount

	; es:di is shared data area i.e., es:di -> dosdata:sysinttable

        mov     di,offset dosdata:sysinittable	

	inc	dx			; advance dx from arena to psp
	mov	ds, dx			; point ds to psp

        if      installed EQ FALSE
        invoke  netwinit
        endif

	; Restore the BIOS stack before returning initialization results.

	mov	ax,[user_sp]
	mov	ss,[user_ss]
	assume	ss:nothing
	mov	sp,ax
	mov	cx,offset doscode:exepatch_start
	mov	ax,offset doscode:DosInit
	mov	bx,offset dosdata:NlsBuffer+20

        retf

;
; END OF DOSINIT
;
;--------------------------------------------------------------------------



	assume	ds:nothing,es:nothing,ss:dosdata
charinit:
	; DS:SI -> device header; AL = function, AH = unit.
	; Return the device request status in AX.
	mov	[devcall.reqlen],19h	; DOS 7 initialization request length
	mov	[devcall.requnit],ah
	mov	[devcall.reqfunc],al
	mov	[devcall.reqstat],0
	push	es
	push	bx
	mov	bx,offset dosdata:devcall
	push	ss
	pop	es
	invoke	deviocall2
	mov	ax,[devcall.reqstat]
	pop	bx
	pop	es
	ret



; ES points to the final resident code segment.
	PUBLIC seg_reinit
seg_reinit	proc	far
	mov	ax,es
	call	InitLowVectors
	push	ds
	InitGetdseg <ds>
	mov	[fixexepatch],offset DOSCODE:exepatch
	pop	ds
	ret
seg_reinit	endp

; Initialize segment values for the resident interrupt vectors.
InitLowVectors	proc	near

	push	es

	xor	cx,cx
	mov	es,cx
assume	es:nothing

	mov	es:[2],ax		; segment of default divide trap handler

	mov	di,intbase+2		; di -> segment of int 20 vector

					; set vectors 20 & 21

	mov	cx, 2
ps_set1:
	stosw
	add	di, 2
	loop	ps_set1

	add	di, 4			; skip	int 22h vector

	stosw				; set int 23h
	add	di, 2

					; set vectors 25-28 and 2a-3f 

	mov	cx, 5			; set vectors 24h through 28h
ps_set2:
	stosw				
	add	di, 2
	loop	ps_set2

	add	di,4			; skip int 29h vector (fast con) as it may
					;   already be set.


	mov	cx,6			; set 6 segs (skip 2 between each)
					;   set segs for ints 2ah-2fh
ps_set3:
	stosw
	add	di,2
	loop	ps_set3

; 30h & 31H is the CPM call entry point whose segment address is set up by
; below. So skip it.

	mov	word ptr es:[entrypoint+3],ax

	add	di,8			; skip vector 30h & 31h 


	mov	cx,14			; set 14 segs (skip 2 between each)
					;   sets segs for ints 32h-3fh
ps_set4:
	stosw
	add	di,2
	loop	ps_set4



; Install the code segment in the sharer table.
	mov	cx,SEG JShare
	mov	es,cx
	mov	di,OFFSET DOSDATA:JShare
	mov	cx,15
ps_share:
	add	di,2
	stosw
	loop	ps_share
	pop	es
	ret

InitLowVectors	endp

	public	memstrt

memstrt	label 	word

msini002e label byte


; if not ROMDOS, then we close the dos code segment, otherwise we close
; the dos initialization segment

ifndef ROMDOS

doscode	ends

else

dosinitseg ends

endif ; ROMDOS



 DPUBLIC <char_init_loop,charinit,continit,iset1,iset2,iset3>
 DPUBLIC <notmax,perdrv,perunit,ps_set1,ps_set2,ps_set3,ps_set4>

	end




