	TITLE	DISK_INFO - Internal Get Disk Info
	NAME	DISK_INFO

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	Low level routine for returning disk drive information from a local
;	  or NET device
;
;	DISK_INFO
;
;	  Modification history:
;
;		Created: ARR 30 March 1983

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include mult.inc
	include dpb.inc
	include bugtyp.inc
	.cref
	.list

Installed = TRUE

	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	EXTERR_LOCUS,BYTE
	i_need	LoMemBuff,DWORD
	i_need	BuffInHMA,BYTE
	i_need	HIGH_SECTOR,WORD
	i_need	ALLOWED,BYTE
	i_need	ClusterWorkHigh,WORD
	i_need	ClusterCountHigh,WORD
	i_need	FatClusterHigh,WORD

DOSCODE	Segment
	ASSUME	SS:DOSDATA,CS:DOSCODE


	Break	<DISK_INFO -- Get Disk Drive Information>
;---------------------------------------------------------------------------
; 
; Procedure Name : DISK_INFO
;
; Inputs:
;	[THISCDS] Points to the Macro List Structure of interest
;		(It MAY NOT be NUL, error not detected)
; Function:
;	Get Interesting Drive Information
; Returns:
;	DX = Number of free allocation units
;	BX = Total Number of allocation units on disk
;	CX = Sector size
;	AL = Sectors per allocation unit
;	AH = FAT ID BYTE
;	Carry set if error (currently user FAILed to I 24)
; Segs except ES preserved, others destroyed
;----------------------------------------------------------------------------

;hkn; called from getset.asm and misc.asm. DS has already been set up to 
;hkn; DOSDATA. 

	procedure   DISK_INFO,NEAR
	DOSAssume   <DS>,"Disk_Info"
	ASSUME	ES:NOTHING

	XOR	AX,AX
	MOV	[ClusterWorkHigh],AX
	MOV	[ClusterCountHigh],AX
	Invoke	TestNet
	JNC	LOCAL_INFO
IF NOT Installed
	transfer NET_DISK_INFO
ELSE
	MOV	AX,(multNET SHL 8) OR 12
	INT	2FH
	return
ENDIF

LOCAL_INFO:
	MOV	[EXTERR_LOCUS],errLOC_Disk
	EnterCrit   critDisk
	invoke	FATREAD_CDS		; perform media check.
	.386
	JC	NEAR PTR CRIT_LEAVE
	.8086
	MOV	BX,2
	MOV	[FatClusterHigh],0
	invoke	UNPACK			; Get first FAT sector into CURBUF
	.386
	JC	NEAR PTR CRIT_LEAVE
	.8086
	LDS	SI,[CURBUF]
ASSUME	DS:NOTHING
	.386
	MOVZX	AX,BYTE PTR [SI].bufinsiz ; get FAT ID BYTE
	MOV	AH,AL
	.8086

;hkn; SS is DOSDATA
	context DS
	CMP	ES:[BP.dpb_fat_size],0
	JZ	INFO_FAT32
	MOV	CX,ES:[BP.dpb_max_cluster]
;
; Examine the current free count.  If it indicates that we have an invalid
; count, do the expensive calculation.
;
	MOV	DX,WORD PTR ES:[BP.dpb_free_cnt] ; get free count
	INC	DX			; is it valid?
	JZ	DoScan
	DEC	DX
;
; Check to see if it is in a reasonalbe range.	If so, trust it and return.
; Otherwise, we need to blast out an internal error message and then recompute
; the count.
;
	CMP	DX,CX			; is it in a reasonable range?
	.386
	JB	NEAR PTR GotVal		; yes, trust it.
	.8086
	JMP	SHORT DoScan
INFO_FAT32:
	.386
	MOV	CX,WORD PTR ES:[BP.dpb_max_cluster32+2]
	MOV	[ClusterCountHigh],CX
	SHL	ECX,16
	MOV	CX,WORD PTR ES:[BP.dpb_max_cluster32]
	MOV	DX,WORD PTR ES:[BP.dpb_free_cnt+2]
	MOV	[ClusterWorkHigh],DX
	SHL	EDX,16
	MOV	DX,WORD PTR ES:[BP.dpb_free_cnt]
	INC	EDX
	JZ	DoScan
	DEC	EDX
	CMP	EDX,ECX
	JB	GotVal
DoScan:
	OR	ES:[BP.dpb_first_access],1
	XOR	DX,DX
	MOV	[ClusterWorkHigh],DX
	SUB	CX,1
	SBB	[ClusterCountHigh],0
SCANFREE:
	invoke	UNPACK
	JC	Crit_Leave
	JNZ	NOTFREECLUS
	ADD	DX,1			; A free one
	ADC	[ClusterWorkHigh],0
NOTFREECLUS:
	ADD	BX,1			; Next cluster
	ADC	[FatClusterHigh],0
	ROR	ECX,16
	MOV	CX,[ClusterCountHigh]
	ROR	ECX,16
	DEC	ECX
	JZ	SCAN_DONE
	ROR	ECX,16
	MOV	[ClusterCountHigh],CX
	ROR	ECX,16
	JMP	SHORT SCANFREE
SCAN_DONE:
	MOV	CX,[FatClusterHigh]
	MOV	[ClusterCountHigh],CX
	SUB	BX,1
	SBB	[ClusterCountHigh],0
ReturnVals:
	SUB	BX,1			; count
	SBB	[ClusterCountHigh],0
	MOV	AL,ES:[BP.dpb_cluster_mask]
	INC	AL			; Sectors/cluster
	MOV	CX,ES:[BP.dpb_sector_size]  ; Bytes/sector
	CMP	ES:[BP.dpb_fat_size],0
	JZ	INFO_STORE32
	MOV	WORD PTR ES:[BP.dpb_free_cnt],DX
	JMP	SHORT INFO_WRITE
INFO_STORE32:
	MOV	WORD PTR ES:[BP.dpb_free_cnt],DX
	MOV	DX,[ClusterWorkHigh]
	MOV	WORD PTR ES:[BP.dpb_free_cnt+2],DX
	MOV	DX,WORD PTR ES:[BP.dpb_free_cnt]
INFO_WRITE:
	CALL	UpdateFSInfo
	CLC
CRIT_LEAVE:
	LeaveCrit   critDisk
	return
;
; We have correctly computed everything previously.  Load up registers for
; return.
;
GotVal:
	MOV	BX,CX			; get cluster count
	JMP	ReturnVals

EndProc DISK_INFO

; Write changed FAT32 allocation information and boot parameters.
; ES:BP points to the DPB. Registers and segments are preserved.
; Carry set on an I/O error.
	.386
procedure UpdateFSInfo,NEAR
	ASSUME	DS:NOTHING,ES:NOTHING,SS:DOSDATA
	TEST	ES:[BP.dpb_first_access],80h
	JNZ	NEAR PTR fsi_clear
	TEST	ES:[BP.dpb_first_access],0Bh
	JZ	NEAR PTR fsi_clear
	CMP	ES:[BP.dpb_fat_size],0
	JNZ	NEAR PTR fsi_clear
	CMP	ES:[BP.dpb_fsinfo],-1
	JZ	NEAR PTR fsi_clear
	PUSH	ES
	PUSH	DS
	PUSHAD
	LDS	DI,[LoMemBuff]
	CMP	[BuffInHMA],0
	JNZ	fsi_read
	PUSH	ES
	PUSH	BP
	invoke	GETCURHEAD
	invoke	BUFWRITE
	POP	BP
	POP	ES
	JC	NEAR PTR fsi_restore
	MOV	WORD PTR [DI.buf_ID],00FFh
	ADD	DI,BUFINSIZ
fsi_read:
	MOV	BX,DI
	MOV	DX,ES:[BP.dpb_fsinfo]
	MOV	[HIGH_SECTOR],0
	MOV	CX,1
	MOV	[ALLOWED],allowed_FAIL+allowed_RETRY
	PUSH	BX
	invoke	DREAD
	POP	BX
	JC	NEAR PTR fsi_restore
	CMP	DWORD PTR [BX],41615252h
	CLC
	JNZ	fsi_boot
	CMP	DWORD PTR [BX+484],61417272h
	CLC
	JNZ	fsi_boot
	TEST	ES:[BP.dpb_first_access],1
	JZ	fsi_boot
	MOV	EAX,ES:[BP.dpb_free_cnt]
	MOV	[BX+488],EAX
	MOV	EAX,ES:[BP.dpb_next_free32]
	MOV	[BX+492],EAX
	MOV	CX,1
	MOV	[HIGH_SECTOR],0
	MOV	DX,ES:[BP.dpb_fsinfo]
	PUSH	BX
	invoke	DWRITE
	POP	BX
	JC	NEAR PTR fsi_restore
	AND	ES:[BP.dpb_first_access],NOT 1
fsi_boot:
	TEST	ES:[BP.dpb_first_access],0Ah
	JZ	NEAR PTR fsi_restore
	XOR	DX,DX
	XOR	AX,AX
fsi_boot_read:
	MOV	CX,1
	MOV	[HIGH_SECTOR],0
	PUSH	AX
	PUSH	DX
	PUSH	BX
	invoke	DREAD
	POP	BX
	POP	DX
	POP	AX
	JNC	fsi_boot_check
	OR	AL,1
	JMP	SHORT fsi_boot_next
fsi_boot_check:
	CMP	WORD PTR [BX+508],0
	JNZ	fsi_boot_bad
	CMP	BYTE PTR [BX],0EBh
	JZ	fsi_boot_extended
	CMP	BYTE PTR [BX],0E9h
	JNZ	fsi_boot_bad
fsi_boot_extended:
	CMP	BYTE PTR [BX+66],29h
	JNZ	fsi_boot_bad
	CMP	WORD PTR [BX+22],0
	JNZ	fsi_boot_bad
	PUSH	AX
	TEST	ES:[BP.dpb_first_access],2
	JZ	fsi_boot_flags
	MOV	EAX,ES:[BP.dpb_rootclus]
	MOV	[BX+44],EAX
fsi_boot_flags:
	TEST	ES:[BP.dpb_first_access],8
	JZ	fsi_boot_write
	MOV	AX,ES:[BP.dpb_extflags]
	MOV	[BX+40],AX
fsi_boot_write:
	MOV	CX,1
	MOV	[HIGH_SECTOR],0
	PUSH	DX
	PUSH	BX
	invoke	DWRITE
	POP	BX
	POP	DX
	POP	AX
	JNC	fsi_boot_next
	OR	AL,1
	JMP	SHORT fsi_boot_next
fsi_boot_bad:
	OR	AL,2
fsi_boot_next:
	OR	DX,DX
	JZ	fsi_backup
	OR	AH,AH
	JZ	fsi_restore
fsi_boot_result:
	OR	AL,AL
	JZ	fsi_restore
	STC
	JMP	SHORT fsi_restore
fsi_backup:
	MOV	DX,ES:[BP.dpb_bkbootsec]
	INC	DX
	JZ	fsi_boot_result
	DEC	DX
	JZ	fsi_boot_result
	XCHG	AH,AL
	JMP	fsi_boot_read
fsi_restore:
	POPAD
	POP	DS
	POP	ES
	JC	fsi_done
fsi_clear:
	AND	ES:[BP.dpb_first_access],0F4h
fsi_done:
	return
EndProc UpdateFSInfo
	.8086

DOSCODE	ENDS
    END

