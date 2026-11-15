	TITLE	FAT - FAT maintenance routines
	NAME	FAT

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	FAT.ASM
;
;	Low level local device routines for performing disk change sequence,
;	setting cluster validity, and manipulating the FAT
;
;	IsEof
;	UNPACK
;	PACK
;	MAPCLUSTER
;	FATREAD_SFT
;	FATREAD_CDS
;	FAT_operation
;
;	Revision history:
;
;	  AN000  version Jan. 1988
;	   A001  PTM	      -- disk changed for look ahead buffers
;
;	M014 - if a request for pack\unpack cluster 0 is made we write\read
;	       from CL0FATENTRY rather than disk.
;

	extrn	GetCurHead:near, ScanPlace:near

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include dpb.inc
	include curdir.inc
	.cref
	.list

FastDiv = TRUE

	i_need	CURBUF,DWORD
	i_need	CLUSSPLIT,BYTE
	i_need	CLUSSAVE,WORD
	i_need	CLUSSEC,DWORD		;F.C. >32mb  ;AN000;
	i_need	THISDRV,BYTE
	i_need	THISDPB,DWORD
	i_need	DEVCALL,BYTE
	i_need	CALLMED,BYTE
	i_need	CALLRBYT,BYTE
	i_need	CALLXAD,DWORD
	i_need	CALLBPB,DWORD
	i_need	CDSADDR,DWORD
	i_need	CDSCOUNT,BYTE
	i_need	EXTERR,WORD
	i_need	EXTERRPT,DWORD
	i_need	CALLVIDM,DWORD
	i_need	ReadOp,BYTE
	i_need	FAILERR,BYTE
	i_need	ALLOWED,BYTE
	i_need	VOLCHNG_FLAG,BYTE
	i_need	HIGH_SECTOR,WORD
	i_need	DirtyBufferCount,WORD
	i_need	BuffInHMA,BYTE
	i_need	LoMemBuff,DWORD
	i_need	SC_CACHE_COUNT,WORD	       ;AN001;


DOSCODE	SEGMENT
	EXTRN	DosDSeg:WORD
        EXTRN CURSC_DRIVE:BYTE
        EXTRN FIRST_BUFF_ADDR:WORD
        EXTRN   CL0FATENTRY:WORD
        I_need  FatClusterHigh,WORD
        I_need  FatEntryHigh,WORD
        I_need  FatNextHigh,WORD
	ASSUME	SS:DOSDATA,CS:DOSCODE


Break <IsEOF - check the quantity in BX for EOF>
;----------------------------------------------------------------------------
;
; Procedure Name : IsEOF
;
; IsEOF - check the fat value in BX for eof.
;
;   Inputs:	ES:BP point to DPB
;		BX has fat value
;   Outputs:	JAE eof
;   Registers modified: none
;
;---------------------------------------------------------------------------

Procedure IsEof,NEAR
	ASSUME	SS:DOSDATA,CS:DOSCODE

	Assert	    ISDPB,<ES,BP>,"IsEOF"
	CMP	ES:[BP.dpb_fat_size],0
	JE	EOF32
eof_legacy:
	CMP	ES:[BP.dpb_max_cluster],4096-10 ; is this 16 bit fat?
	JB	eof_check12
EOF16:
	CMP	BX,0FFF8h		; 16 bit compare
	RET
EOF32:
	.386
	CMP	ES:[BP.dpb_max_cluster32],65536-10
	.8086
	JB	eof_legacy
	CMP	FatClusterHigh,0fffh
	JNE	eof_return
	CMP	BX,0fff8h
eof_return:
	RET
eof_check12:
	CMP	ES:[BP.dpb_max_cluster],0FF0h
	JAE	EOF12
	CMP	BX,0FF0h
	return
EOF12:
	CMP	BX,0FF8h		; do the 12 bit compare
	return
EndProc IsEof

Break	<UNPACK -- UNPACK FAT ENTRIES>
;---------------------------------------------------------------------------
;
; Procedur Name : UNPACK
;
; Inputs:
;	BX = Cluster number (may be full 16-bit quantity)
;	ES:BP = Base of drive parameters
; Outputs:
;	DI = Contents of FAT for given cluster (may be full 16-bit quantity)
;	Zero set means DI=0 (free cluster)
;	Carry set means error (currently user FAILed to I 24)
; SI Destroyed, No other registers affected. Fatal error if cluster too big.
;
; NOTE: if BX = 0 then DI = contents of CL0FATENTRY
;
;----------------------------------------------------------------------------

procedure   UNPACK,NEAR
	DOSAssume   <DS>,"UnPack"
					; M014 - Start
	or	bx, bx			; Q: are we unpacking cluster 0
	jz	up_zero
up_cont:
	CMP	ES:[BP.dpb_fat_size],0
	JE	up_fat32
	CMP	BX,ES:[BP.dpb_max_cluster]
	JMP	SHORT up_check
up_zero:
	CMP	FatClusterHigh,BX
	JNZ	up_cont
	.386
	MOV	EDI,DWORD PTR CS:[CL0FATENTRY]
	ROR	EDI,16
	MOV	FatNextHigh,DI
	ROR	EDI,16
	OR	EDI,EDI
	RET
up_fat32:
	ROR	EBX,16
	MOV	BX,FatClusterHigh
	ROR	EBX,16
	CMP	EBX,ES:[BP.dpb_max_cluster32]
up_check:
	JA	HURTFAT
	MOV	FatNextHigh,0
	CALL	MAPCLUSTER
ASSUME	DS:NOTHING
	jc	DoContext
	JNZ	High12			; MZ if high 12 bits, go get 'em
	CMP	ES:[BP.dpb_fat_size],0
	JE	up_read32
up_read16:
	MOVZX	EDI,WORD PTR [DI]
	CMP	ES:[BP.dpb_max_cluster],4096-10
	JB	Unpack12		; MZ No, go 'AND' off bits
up_test:
	OR	EDI,EDI
	JMP	SHORT DoContext 	; MZ go do context
up_read32:
	CMP	ES:[BP.dpb_max_cluster32],65536-10
	JB	up_read16
	MOV	EDI,[DI]
	AND	EDI,0fffffffh
	ROR	EDI,16
	MOV	FatNextHigh,DI
	ROR	EDI,16
	JMP	SHORT up_test
High12:
	MOV	DI,[DI]
	SHR	DI,4
Unpack12:
	AND	DI,0FFFH		; Clears carry
DoContext:
	PUSH	SS
	POP	DS
	return

HURTFAT:
	CMP	ES:[BP.dpb_fat_size],0
	JE	hurt_fat32
	CMP	WORD PTR ES:[BP.dpb_free_cnt],-1
	JE	hurt_error
	MOV	WORD PTR ES:[BP.dpb_free_cnt],-1
	JMP	SHORT hurt_dirty
hurt_fat32:
	CMP	ES:[BP.dpb_free_cnt],-1
	JE	hurt_error
	MOV	ES:[BP.dpb_free_cnt],-1
hurt_dirty:
	OR	ES:[BP.dpb_first_access],1
hurt_error:
	.8086
	PUSH	AX
	MOV	AH,allowed_fail + 80h

;hkn; SS override
	MOV	Allowed,allowed_fail
;
; Signal Bad FAT to INT int_fatal_abort handler.  We have an invalid cluster.
;
	PUSH	FatClusterHigh
	PUSH	BX
	invoke	FATAL
	POP	BX
	POP	FatClusterHigh
	XOR	DI,DI
	DEC	DI
	MOV	FatNextHigh,DI
	CMP	AL,3
	CLC
	JNZ	OKU_RET 		; Try to ignore bad FAT
	STC				; User said FAIL
OKU_RET:
	POP	AX
	return
EndProc UNPACK

Break	<PACK -- PACK FAT ENTRIES>
;----------------------------------------------------------------------------
;
; Procedure Name : PACK
;
; Inputs:
;	BX = Cluster number
;	DX = Data
;	ES:BP = Pointer to drive DPB
; Outputs:
;	The data is stored in the FAT at the given cluster.
;	SI,DX,DI all destroyed
;	Carry set means error (currently user FAILed to I 24)
;	No other registers affected
;
; NOTE: if BX = 0 then data in DX is atored in CL0FATENTRY.
;
;---------------------------------------------------------------------------

procedure   PACK,NEAR
	DOSAssume   <DS>,"Pack"
	.386

	Assert	    ISDPB,<ES,BP>,"Pack"
					; M014 - start
	or	bx, bx			; Q: are we packing cluster 0
	jz	pack_zero
p_cont:					; M014 - end

	CALL	MAPCLUSTER
    ASSUME DS:NOTHING
	JC	DoContext
	JNZ	NEAR PTR pack_high12
ALIGNED:
	CMP	ES:[BP.dpb_fat_size],0
	JNE	pack_legacy
	CMP	ES:[BP.dpb_max_cluster32],65536-10
	JB	pack_legacy
	ROR	EDX,16
	MOV	DX,FatEntryHigh
	ROR	EDX,16
	XOR	EDX,[DI]
	AND	EDX,0fffffffh		; Preserve reserved high four bits
	XOR	[DI],EDX
	JMP	SHORT pack_dirty
pack_legacy:
	CMP	ES:[BP.dpb_max_cluster],4096-10 ; MZ 16 bit fats?
	JB	pack_low12
Pack16:
	MOV	SI,DX
PACKIN:
	MOV	[DI],SI
pack_dirty:
;hkn; SS override
	LDS	SI,[CURBUF]
	TESTB	[SI.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[SI.buf_flags],buf_dirty  ;LB.					;AN000;
yesdirty:				  ;LB.					;AN000;

;hkn; SS override
	CMP	BYTE PTR [CLUSSPLIT],0

;hkn; SS is DOSDATA
	Context DS
	JZ	pack_return
pack_split:
	PUSH	AX
	PUSH	FatClusterHigh
	PUSH	BX
	PUSH	CX
	MOV	AX,[CLUSSAVE]
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING
	ADD	SI,BUFINSIZ
	MOV	[SI],AH

;hkn; SS is DOSDATA
	Context DS
	PUSH	AX
	MOV	DX,WORD PTR [CLUSSEC+2] 	   ;F.C. >32mb		       ;AN000;
	MOV	WORD PTR [HIGH_SECTOR],DX	   ;F.C. >32mb		       ;AN000;

	MOV	DX,WORD PTR [CLUSSEC]
	MOV	SI,1
	XOR	AL,AL
	invoke	GETBUFFRB
	POP	AX
	JC	POPP_RET
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	TESTB	[DI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty2		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[DI.buf_flags],buf_dirty
yesdirty2:
	ADD	DI,BUFINSIZ
	DEC	DI
	ADD	DI,ES:[BP.dpb_sector_size]
	MOV	[DI],AL
	CLC
POPP_RET:
	PUSH	SS
	POP	DS
	ASSUME	DS:DOSDATA
	POP	CX
	POP	BX
	POP	FatClusterHigh
	POP	AX
pack_return:
	RET
pack_high12:
	MOV	SI,[DI]
	SHL	DX,4
	AND	SI,0fh
	JMP	SHORT pack_merge
pack_low12:
	MOV	SI,[DI]
	AND	SI,0f000h
	AND	DX,0fffh
pack_merge:
	OR	SI,DX
	JMP	PACKIN
pack_zero:
	CMP	SS:FatClusterHigh,BX
	JNZ	p_cont
	MOV	CS:[CL0FATENTRY],DX
	PUSH	DX
	MOV	DX,SS:FatEntryHigh
	MOV	CS:[CL0FATENTRY+2],DX
	POP	DX
	RET
	.8086

EndProc PACK

Break	<MAPCLUSTER - BUFFER A FAT SECTOR>
;---------------------------------------------------------------------------
;
; Procedure Name : MAPCLUSTER
;
; Inputs:
;	ES:BP Points to DPB
;	BX Is cluster number
; Function:
;	Get a pointer to the cluster
; Outputs:
;	DS:DI Points to contents of FAT for given cluster
;	DS:SI Points to start of buffer
;	Zero Not set if cluster data is in high 12 bits of word
;	Zero set if cluster data is in low 12 or 16 bits
;	Carry set if failed.
; SI is destroyed.
;
;---------------------------------------------------------------------------

procedure   MAPCLUSTER,NEAR
	DOSAssume   <DS>,"MapCluster"

	Assert	    ISDPB,<ES,BP>,"MapCluster"
	MOV	BYTE PTR [CLUSSPLIT],0
	SAVE	<AX,BX,CX,DX>
	.386
	XOR	EDX,EDX
	ROR	EBX,16
	MOV	BX,FatClusterHigh
	ROR	EBX,16
	MOV	EAX,EBX
	CMP	ES:[BP.dpb_fat_size],0
	JE	Map32
MapLegacy:
	CMP	ES:[BP.dpb_max_cluster],4096-10  ; MZ 16 bit fat?
	JB	Map12
Map16:					; MZ skip prev => AX=2*BX
	ADD	EAX,EBX			; FAT12/16 byte offset
	ADC	EDX,0
MapDivide:
	MOVZX	ECX,ES:[BP.dpb_sector_size]
	DIV	ECX
	MOVZX	EBX,ES:[BP.dpb_first_FAT]
	ADD	EAX,EBX
	DEC	CX			; CX is sector size - 1
	PUSH	EAX
	PUSH	DX
	PUSH	CX
	MOV	DX,AX
	SHR	EAX,16
	MOV	[HIGH_SECTOR],AX
	XOR	AL,AL
	MOV	SI,1
	invoke	GETBUFFRB
	POP	CX
	POP	AX			; Offset in sector
	POP	EDX			; Full FAT sector number
	JC	MAP_POP
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	LEA	DI,[SI.BufInSiz]
	ADD	DI,AX
	CMP	AX,CX
	JE	MapSplit
MAPRET:
MapRestore:
	RESTORE <DX,CX,BX>
	XOR	AL,AL
	CMP	ES:[BP.dpb_fat_size],0
	JE	MapFlags32
	CMP	ES:[BP.dpb_max_cluster],4096-10
	JB	MapOdd
MapSet:
	TEST	AL,1
	POP	AX
	RET
MapFlags32:
	CMP	ES:[BP.dpb_max_cluster32],4096-10
	JB	MapOdd
	JMP	SHORT MapSet
Map32:
	CMP	ES:[BP.dpb_max_cluster32],65536-10
	JB	MapLegacy
	SHL	EAX,1
	RCL	EDX,1
	SHL	EAX,1
	RCL	EDX,1
	JMP	SHORT MapDivide
Map12:
	SHR	EAX,1
	JMP	Map16
MapOdd:
	MOV	AL,BL
	JMP	SHORT MapSet
MAP_POP:
	RESTORE <DX,CX,BX,AX>
	RET
MapSplit:
	MOV	AL,[DI]
	Context DS		 	;hkn; SS is DOSDATA
	INC	BYTE PTR [CLUSSPLIT]
	MOV	BYTE PTR [CLUSSAVE],AL
	MOV	DWORD PTR [CLUSSEC],EDX
	INC	EDX
	MOV	EAX,EDX
	SHR	EAX,16
	MOV	[HIGH_SECTOR],AX
	XOR	AL,AL
	MOV	SI,1
	invoke	GETBUFFRB
	JC	MAP_POP
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	LEA	DI,[SI.BufInSiz]
	MOV	AL,[DI]
	Context DS			;hkn; SS is DOSDATA
	MOV	BYTE PTR [CLUSSAVE+1],AL

;hkn; CLUSSAVE is in DOSDATA
	MOV	DI,OFFSET DOSDATA:CLUSSAVE
	JMP	MapRestore
	.8086

EndProc MAPCLUSTER, NoCheck

Break	<FATREAD_SFT/FATREAD_CDS -- CHECK DRIVE GET FAT>
;----------------------------------------------------------------------------
;
; Procedure Name : FATREAD_SFT
;
; Inputs:
;	ES:DI points to an SFT for the drive of intrest (local only,
;		giving a NET SFT will produce system crashing results).
;	DS DOSDATA
; Function:
;	Can be used by an SFT routine (like CLOSE) to invalidate buffers
;	if disk changed.
;	In other respects, same as FATREAD_CDS.
;	(note ES:DI destroyed!)
; Outputs:
;	Carry set if error (currently user FAILed to I 24)
; NOTE: This routine may cause FATREAD_CDS to "miss" a disk change
;	as far as invalidating curdir_ID is concerned.
;	Since getting a true disk changed on this call is a screw up
;	anyway, that's the way it goes.
;
;---------------------------------------------------------------------------

procedure  FATREAD_SFT,NEAR
	DOSAssume   <DS>,"FATRead_SFT"

	LES	BP,ES:[DI.sf_devptr]
	Assert	ISDPB,<ES,BP>,"FatReadSFT"
	MOV	AL,ES:[BP.dpb_drive]
	MOV	[THISDRV],AL
	invoke	GOTDPB			;Set THISDPB
	CALL	FAT_GOT_DPB
	return

EndProc FATREAD_SFT

;----------------------------------------------------------------------------
;
; Procedure Name : FATREAD_CDS
;
; Inputs:
;	DS:DOSDATA
;	ES:DI points to an CDS for the drive of intrest (local only,
;		giving a NET or NUL CDS will produce system crashing results).
; Function:
;	If disk may have been changed, media is determined and buffers are
;	flagged invalid. If not, no action is taken.
; Outputs:
;	ES:BP = Drive parameter block
;	THISDPB = ES:BP
;	THISDRV set
;	Carry set if error (currently user FAILed to I 24)
; DS preserved , all other registers destroyed
;
;---------------------------------------------------------------------------

procedure   FATREAD_CDS,NEAR
	DOSAssume   <DS>,"FATRd_CDS"

	PUSH	ES
	PUSH	DI
	LES	BP,ES:[DI.curdir_devptr]
	Assert	ISDPB,<ES,BP>,"FatReadCDS"
	MOV	AL,ES:[BP.dpb_drive]
	MOV	[THISDRV],AL
	invoke	GOTDPB			;Set THISDPB
	CALL	FAT_GOT_DPB
	POP	DI			;Get back CDS pointer
	POP	ES
	retc
	JNZ	NO_CHANGE		;Media NOT changed

;	Media changed. We now need to find all CDS structures which use this
;	DPB and invalidate their ID pointers.

MED_CHANGE:
	XOR	AX,AX
	DEC	AX			;AX = -1
	PUSH	DS
	MOV	CL,[CDSCOUNT]
	XOR	CH,CH			; CX is number of structures
	LDS	SI,ES:[DI.curdir_devptr] ; Find all CDS with this devptr
ASSUME	DS:NOTHING

;hkn; SS override

;	Find all CDSs with this DevPtr
;
;	(ax) = -1
;	(ds:si) = DevPtr

	LES	DI,CDSADDR		; (es:di) = CDS pointer
frcd20: TESTB	ES:[DI.curdir_flags],curdir_isnet
	JNZ	frcd25			; Leave NET guys alone!!
	PUSH	DS
	MOV	DS,CS:[DosDSeg]
	invoke	CheckCDSDrive
	POP	DS
	JNZ	frcd25
	cmp	si,word ptr es:[di].curdir_devptr
	jne	frcd25			; no match
	mov	bx,ds
	cmp	bx,word ptr es:[di].curdir_devptr+2
	jne	frcd25			; CDS not for this drive
	.386
	TEST	DWORD PTR ES:[DI].curdir_ID,-1
	.8086
	JZ	frcd25			; If root (0), leave root
	MOV	ES:[DI].curdir_ID,AX	; else invalid
	MOV	WORD PTR ES:[DI.curdir_ID+2],AX
frcd25:	ADD	DI,SIZE curdir_list	; Point to next CDS
	LOOP	frcd20
	POP	DS
	DOSAssume   <DS>,"FrCd25"
NO_CHANGE:
	LES	BP,THISDPB
	CLC
	return

EndProc FATREAD_CDS

Break	<Fat_Operation - miscellaneous fat stuff>

	procedure   FAT_operation,NEAR
FATERR:
	DOSAssume   <DS>,"FATERR"
	CMP	ES:[BP.dpb_fat_size],0
	JE	faterr32
	CMP	WORD PTR ES:[BP.dpb_free_cnt],-1
	JE	faterr_report
	MOV	WORD PTR ES:[BP.dpb_free_cnt],-1 ; Err in FAT must force recomp of freespace
	JMP	SHORT faterr_dirty
faterr32:
	.386
	CMP	ES:[BP.dpb_free_cnt],-1
	JE	faterr_report
	MOV	ES:[BP.dpb_free_cnt],-1
	.8086
faterr_dirty:
	OR	ES:[BP.dpb_first_access],1
faterr_report:
	AND	DI,STECODE		; Put error code in DI
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	MOV	AH,2 + allowed_FAIL + allowed_RETRY ; While trying to read FAT
	MOV	AL,BYTE PTR [THISDRV]	 ; Tell which drive
	invoke	FATAL1
	LES	BP,THISDPB
	CMP	AL,3
	JNZ	FAT_GOT_DPB		; User said retry
fat_dpb_error:
	STC				; User said FAIL
	return

	public	fat_got_dpb

FAT_GOT_DPB:
	Context DS			;hkn; SS is DOSDATA
	MOV	AX,ES
	OR	AX,BP
	JZ	fat_dpb_error
	MOV	AL,DMEDHL
	MOV	AH,ES:[BP.dpb_UNIT]
	MOV	WORD PTR [DEVCALL],AX
	MOV	BYTE PTR [DEVCALL.REQFUNC],DEVMDCH
	MOV	[DEVCALL.REQSTAT],0
	MOV	AL,ES:[BP.dpb_media]
	MOV	BYTE PTR [CALLMED],AL
	PUSH	ES
	PUSH	DS

;hkn; DEVCALL is in DOSDATA
	MOV	BX,OFFSET DOSDATA:DEVCALL
	LDS	SI,ES:[BP.dpb_driver_addr]  ; DS:SI Points to device header
ASSUME	DS:NOTHING
	POP	ES			; ES:BX Points to call header
	invoke	DEVIOCALL2
	Context DS		 	;hkn; SS is DOSDATA
	POP	ES			; Restore ES:BP
	MOV	DI,[DEVCALL.REQSTAT]
	.errnz	STERR-8000h
	or	di,di
	.386
	JS	NEAR PTR FATERR		; have error
	.8086
	MOV	AH,ES:[BP.dpb_first_access]
	AND	AH,80h
	JZ	fat_first_access_done
	CMP	ES:[BP.dpb_first_access],-1
	JNE	fat_first_access_done
	MOV	ES:[BP.dpb_first_access],AH
fat_first_access_done:
	AND	ES:[BP.dpb_first_access],7fh
	MOV	AL,BYTE PTR [THISDRV]	; Use physical unit number
; See if we had changed volume id by creating one on the diskette
	cmp	[VOLCHNG_FLAG],AL
	jnz	CHECK_BYT
	mov	[VOLCHNG_FLAG],-1
	jmp	GOGETBPB		; Need to get device driver to read in
					; new volume label.
CHECK_BYT:
	OR	AH,BYTE PTR [CALLRBYT]
	JNS	CHECK_ZR		; ns = 0 or 1
	JMP	short NEWDSK

CHECK_ZR:
	JZ	CHKBUFFDIRT		; jump if I don't know
	CLC
	return				; If Media not changed (NZ)

DISK_CHNG_ERR:
ASSUME	DS:NOTHING
	PUSH	ES
	PUSH	BP
	LES	BP,ES:[BP.dpb_driver_addr]  ; Get device pointer
	TESTB	ES:[BP.SDEVATT],DEVOPCL ; Did it set vol id?
	POP	BP
	POP	ES
	JZ	FAIL_OPJ2		; Nope, FAIL
	PUSH	DS			; Save buffer pointer for ignore
	PUSH	DI
	Context DS			;hkn; SS is DOSDATA
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	PUSH	ES
	LES	DI,[CALLVIDM]		; Get volume ID pointer
	MOV	WORD PTR [EXTERRPT+2],ES
	POP	ES
	MOV	WORD PTR [EXTERRPT],DI
	MOV	AX,error_I24_wrong_disk
	MOV	[READOP],1		; Write
	invoke	HARDERR
	POP	DI			; Get back buffer for ignore
	POP	DS
ASSUME	DS:NOTHING
	CMP	AL,3
FAIL_OPJ2:
	JZ	FAIL_OP
	JMP	FAT_GOT_DPB		; Retry

CHKBUFFDIRT:
	DOSAssume   <DS>,"ChkBuffDirt"
	assume	DS:DOSDATA
	cmp	[DirtyBufferCount], 0		; any dirty buffers ? ;hkn;
	je	NEWDSK				; no, skip the check
	call	GetCurHead			; get pointer to first buffer
nbuffer:
	cmp	[di].buf_ID, al			; Unit OK ?
	jne	lfnxt				; no, go for next buffer
	TESTB	[di].buf_flags, buf_dirty	; is the buffer dirty ?
	jz	lfnxt				; no, go for next buffer
;	pop	di				; There is a dirty buffer
;	pop	ds				;  assume Media OK ( NZ )
	Context	DS
	clc
	ret

FAIL_OP:					; This label & code is here
	Context	DS				;  for reachability
	STC
	return

	assume	DS:NOTHING
lfnxt:
	mov	di, [di].buf_next		; get next buffer
	cmp	CS:[FIRST_BUFF_ADDR], di		; is this where we started ?;hkn;
	jne	nbuffer				; no, check this guy also

; If no dirty buffers, assume Media changed
NEWDSK:
	call	GetCurHead
nxbuffer:
	cmp	[di].buf_ID, al			; This drive ?
	jne	lfnxt2
	TESTB	[di].buf_flags, buf_dirty
	DLJNZ	DISK_CHNG_ERR
	mov	word ptr [di].buf_ID, (buf_visit SHL 8) OR 0FFh ; free up
	call	ScanPlace
	jmp	short skpbuff
lfnxt2:
	mov	di, [di].buf_next
skpbuff:
	cmp	di, CS:[FIRST_BUFF_ADDR]					;hkn;
	jne	nxbuffer

	CMP	[SC_CACHE_COUNT],0	;LB.  look ahead buffers ?		  ;AN001;
	JZ	GOGETBPB		;LB.  no				  ;AN001;
	CMP	AL,CS:[CURSC_DRIVE]	;LB.  same as changed drive		  ;AN001;
	JNZ	GOGETBPB		;LB.  no				  ;AN001;
	MOV	CS:[CURSC_DRIVE],-1	;LB.  invalidate look ahead buffers	  ;AN000;
GOGETBPB:
	LDS	DI,ES:[BP.dpb_driver_addr]
	TESTB	[DI.SDEVATT],ISFATBYDEV
	JNZ	GETFREEBUF
	context DS	    		;hkn; SS is DOSDATA
	MOV	ES:[BP.dpb_sector_size],512
	MOV	ES:[BP.dpb_first_FAT],1
	MOV	ES:[BP.dpb_FAT_count],1
	MOV	ES:[BP.dpb_max_cluster],3
	MOV	ES:[BP.dpb_FAT_size],1
	MOV	FatClusterHigh,0
	MOV	BX,2
	CALL	UNPACK			; Read the first FAT sector into CURBUF
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	.386
	JC	NEAR PTR FAIL_OP
	.8086
	JMP	SHORT GOTGETBUF

GETFREEBUF:
ASSUME	DS:NOTHING
	CMP	[BuffInHMA],0
	LDS	DI,[LoMemBuff]
	JNZ	SETBPBBUF
	PUSH	ES			; Get a free buffer for BIOS to use
	PUSH	BP
;	LDS	DI,[BUFFHEAD]
	XOR	DX,DX			     ;LB.  fake to get 1st		  ;AN000;

;hkn; SS override
	MOV	[HIGH_SECTOR],DX	     ;LB.  buffer addr			  ;AN000;
	invoke	GETCURHEAD		     ;LB.				  ;AN000;

	invoke	BUFWRITE
	POP	BP
	POP	ES
	.386
	JC	FAIL_OP
	.8086
GOTGETBUF:
	ADD	DI,BUFINSIZ
SETBPBBUF:

;hkn; SS override
	MOV	WORD PTR [CALLXAD+2],DS
	Context DS			;hkn; SS is DOSDATA
	MOV	WORD PTR [CALLXAD],DI
	MOV	AL,DBPBHL
	MOV	AH,BYTE PTR ES:[BP.dpb_UNIT]
	MOV	WORD PTR [DEVCALL],AX
	MOV	BYTE PTR [DEVCALL.REQFUNC],DEVBPB
	MOV	[DEVCALL.REQSTAT],0
	MOV	AL,BYTE PTR ES:[BP.dpb_media]
	MOV	[CALLMED],AL
	PUSH	ES
	PUSH	DS
	PUSH	WORD PTR ES:[BP.dpb_driver_addr+2]
	PUSH	WORD PTR ES:[BP.dpb_driver_addr]

;hkn; DEVCALL is in DOSDATA
	MOV	BX,OFFSET DOSDATA:DEVCALL
	POP	SI
	POP	DS			; DS:SI Points to device header
ASSUME	DS:NOTHING
	POP	ES			; ES:BX Points to call header
	invoke	DEVIOCALL2
	POP	ES			; Restore ES:BP
	Context DS		 	;hkn; SS is DOSDATA
	MOV	DI,[DEVCALL.REQSTAT]

	.errnz	STERR-8000h
	or	di,di
	.386
	JS	NEAR PTR FATERRJ	; have error
	.8086
	LDS	SI,[CALLBPB]
ASSUME	DS:NOTHING
	XOR	AX,AX
	MOV	CX,AX
	MOV	ES:[BP].DPB_next_free,AX ; recycle scanning pointer
	CMP	WORD PTR [SI+11],0	; FAT16 sectors per FAT in BPB
	JNE	fat_build_dpb
	MOV	WORD PTR ES:[BP.dpb_next_free32],AX
	MOV	WORD PTR ES:[BP.dpb_next_free32+2],AX
	.386
	MOV	ES:[BP.dpb_free_cnt],-1
	.8086
	MOV	CX,4558h		; Extended BPB signature
	MOV	DX,4152h
fat_build_dpb:
	invoke	$SETDPB

;hkn; SS override
	LDS	DI,[CALLXAD]		; Get back buffer pointer
	.386
	BTR	DWORD PTR ES:[BP.dpb_first_access],0
	JC	NEAR PTR fsinfo_buffer_done
	CMP	ES:[BP.dpb_fat_size],0
	JNE	NEAR PTR fsinfo_buffer_done
	MOV	DX,ES:[BP.dpb_fsinfo]
	INC	DX
	JZ	NEAR PTR fsinfo_buffer_done
	DEC	DX
	MOV	[HIGH_SECTOR],0
	MOV	BX,DI
	MOV	CX,1
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	CMP	[BuffInHMA],0
	JE	fsinfo_read_buffer
	PUSH	ES
	PUSH	DS
	LDS	BX,[LoMemBuff]
fsinfo_read_buffer:
	PUSH	DI
	PUSH	BX
	invoke	DREAD
	POP	BX
	POP	DI
	PUSHF
	CMP	[BuffInHMA],0
	JE	fsinfo_read_done
	MOV	CX,ES:[BP.dpb_sector_size]
	SHR	CX,1
	POPF
	MOV	SI,BX
	MOV	BX,DI
	POP	ES
	CLD
	REP	MOVSW
	PUSH	ES
	POP	DS
	MOV	DI,BX
	POP	ES
	PUSHF
fsinfo_read_done:
	POPF
	JC	fsinfo_done
	CMP	DWORD PTR [DI],41615252h
	JNE	fsinfo_done
	CMP	DWORD PTR [DI+1e4h],61417272h
	JNE	fsinfo_done
	MOV	EAX,[DI+1e8h]
	CMP	EAX,ES:[BP.dpb_max_cluster32]
	JAE	fsinfo_next_free
	MOV	ES:[BP.dpb_free_cnt],EAX
fsinfo_next_free:
	MOV	EAX,[DI+1ech]
	CMP	EAX,ES:[BP.dpb_max_cluster32]
	JAE	fsinfo_done
	MOV	ES:[BP.dpb_next_free32],EAX
	MOV	ES:[BP.dpb_next_free],AX
fsinfo_done:
	.8086
	CMP	[BuffInHMA],0
	JE	fsinfo_invalidate
	MOV	AX,DS
	CMP	AX,WORD PTR [LoMemBuff+2]
	JE	FATBPBDONE
fsinfo_invalidate:
	MOV	WORD PTR [DI.buf_ID-BUFINSIZ],00ffh
fsinfo_buffer_done:
	CMP	[BuffInHMA],0
	JZ	SETFATBUF
	MOV	AX,DS
	CMP	AX,WORD PTR [LoMemBuff+2]
	JZ	FATBPBDONE
SETFATBUF:
	CMP	ES:[BP.dpb_first_FAT],1
	JE	fat_buffer_layout
	MOV	WORD PTR [DI.buf_ID-BUFINSIZ],00ffh
fat_buffer_layout:
	MOV	AL,BYTE PTR ES:[BP.dpb_FAT_count]
	MOV	[DI.buf_wrtcnt-BUFINSIZ],AL   ;>32mb				;AN000;
	.386
	MOVZX	EAX,ES:[BP.dpb_FAT_size]
	OR	AX,AX
	JNZ	fat_buffer_size
	MOV	EAX,ES:[BP.dpb_FAT_size32]
fat_buffer_size:
	MOV	[DI.buf_wrtcntinc-BUFINSIZ],EAX
	.8086

FATBPBDONE:
	Context DS			;hkn; SS is DOSDATA
	XOR	AL,AL			;Media changed (Z), Carry clear
	return

FATERRJ:
	PUSH	DS
	PUSH	DI
	LDS	DI,[CALLXAD]
	MOV	WORD PTR [DI.buf_ID-BUFINSIZ],00ffh
	POP	DI
	POP	DS
	JMP	FATERR

EndProc FAT_operation

DOSCODE	ENDS
	END
