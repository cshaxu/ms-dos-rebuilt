	TITLE	DISKIO - Directory and FAT reads
	NAME	DiskIO

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	DISKIO.ASM - Directory and FAT reads
;
;	DirFromSFT
;	DirRead
;	FIRSTCLUSTER
;	SET_BUF_AS_DIR
;	FATSecRd
;	DREAD
;
;	Revision history:
;
;		A000   version 4.00  Jan. 1988
;
;----------------------------------------------------------------------------
;
; M065 : B#5276. On raw read/write of a block of characters if a critical
;		error happens, DOS retries the entire block assuming that
;		zero characters were transferred. Modified the code to take
;		into account the number of characters transfered before
;		retrying the operation.
;
;----------------------------------------------------------------------------
;
	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	include fastxxxx.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include dpb.inc
	include mult.inc
	include filemode.inc
	.cref
	.list

Installed = TRUE

	I_need	DirStart,WORD
	i_need	SecClusPos,BYTE
	i_need	DirSec,DWORD
	i_need	ClusNum,WORD
	i_need	NxtClusNum,WORD
	i_need	ReadOp,BYTE
	i_need	CURBUF,DWORD
	i_need	ALLOWED,BYTE
	i_need	EXTERR_LOCUS,BYTE


	i_need	HIGH_SECTOR,WORD


DOSCODE	Segment
	ASSUME	SS:DOSDATA,CS:DOSCODE



;----------------------------------------------------------------------------
;
; Procedure Name : DirFromSFT
;
;   DirFromSFT - locate a directory entry given an SFT.
;
;   Inputs:	ES:DI point to SFT
;		DS = DOSDATA
;   Outputs:
;		EXTERR_LOCUS = errLOC_Disk
;		CurBuf points to buffer
;		Carry Clear -> operation OK
;		    ES:DI point to entry
;		    ES:BX point to buffer
;		    DS:SI point to SFT
;		Carry SET   -> operation failed
;		    registers trashified
;   Registers modified: ALL
;----------------------------------------------------------------------------

Procedure   DirFromSFT,NEAR
	DOSAssume   <DS>,"DOS_Close"

	; BUGBUG - assert SFT
	MOV	[EXTERR_LOCUS],errLOC_Disk
	SAVE	<ES,DI>
	MOV	DX,WORD PTR ES:[DI.sf_dirsec+2]  ;F.C. >32mb
	MOV	[HIGH_SECTOR],DX		 ;F.C. >32mb
	MOV	DX,WORD PTR ES:[DI.sf_dirsec]

	PUSH	[HIGH_SECTOR]			 ;F.C. >32mb
	PUSH	DX
	invoke	FATREAD_SFT		; ES:BP points to DPB, [THISDRV] set
					; [THISDPB] set
	POP	DX
	POP	[HIGH_SECTOR]			 ;F.C. >32mb
	JC	PopDone
	XOR	AL,AL			; Pre read
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	invoke	GETBUFFR
	JC	PopDone
	RESTORE <SI,DS>		; Get back SFT pointer
	ASSUME	DS:NOTHING

;hkn; SS override
	LES	DI,Curbuf
	OR	ES:[DI.buf_flags],buf_isDIR
	MOV	BX,DI			; ES:BX point to buffer header
	LEA	DI,[DI].BUFINSIZ	; Point to buffer
	MOV	AL,SIZE dir_entry
	MUL	[SI].sf_DirPos
	ADD	DI,AX			; Point at the entry

	return				; carry is clear
PopDone:
	RESTORE <DI,ES>
	return
EndProc DirFromSFT,NoCheck

Break	<DIRREAD -- READ A DIRECTORY SECTOR>
;---------------------------------------------------------------------------
;
; Procedure Name : DIRREAD
;
; Inputs:
;	AX = Directory block number (relative to first block of directory)
;	ES:BP = Base of drive parameters
;	[DIRSEC] = First sector of first cluster of directory
;	[CLUSNUM] = Next cluster
;	[CLUSFAC] = Sectors/Cluster
; Function:
;	Read the directory block into [CURBUF].
; Outputs:
;	[NXTCLUSNUM] = Next cluster (after the one skipped to)
;	[SECCLUSPOS] Set
;	ES:BP unchanged
;	[CURBUF] Points to Buffer with dir sector
;	Carry set if error (user said FAIL to I 24)
; DS preserved, all other registers destroyed.
;---------------------------------------------------------------------------

;hkn; called from dir.asm. DS already set up to DOSDATA.

procedure   DirRead,NEAR

	DOSAssume   <DS>,"DirRead"
	Assert	    ISDPB,<ES,BP>,"DirRead"

; Note that ClusFac is is the sectors per cluster.  This is NOT necessarily
; the same as what is in the DPB!  In the case of the root directory, we have
; ClusFac = # sectors in the root directory.  The root directory is detected
; by DIRStart = 0.

	XOR	DX,DX
	CMP	DirStart,0
	jnz	SubDir
	XCHG	AX,DX
	JMP	short DoRead

; Convert the sector number in AX into cluster and sector-within-cluster pair

SubDir:
	MOV	DL,AL
	AND	DL,ES:[BP.dpb_cluster_mask]

;	(DX) = sector-in-cluster

	MOV	CL,ES:[BP.dpb_cluster_shift]
	SHR	AX,CL

;	(DX) = position in cluster
;	(AX) = number of clusters to skip

DoRead:
	MOV	[SECCLUSPOS],DL
	MOV	CX,AX
	MOV	AH,DL

;	(CX) = number of clusters to skip.
;	(AH) = remainder

	MOV	DX,WORD PTR [DIRSEC+2]	     ;>32mb
	MOV	[HIGH_SECTOR],DX	     ;>32mb
	MOV	DX,WORD PTR [DIRSEC]
	ADD	DL,AH
	ADC	DH,0
	ADC	[HIGH_SECTOR],0 	     ;>32mb

	MOV	BX,[CLUSNUM]
	MOV	[NXTCLUSNUM],BX
	JCXZ	FIRSTCLUSTER
SKPCLLP:
	invoke	UNPACK
	jc	DirReadDone
	XCHG	BX,DI
	invoke	IsEOF			; test for eof based on fat size
	JAE	HAVESKIPPED
	LOOP	SKPCLLP
HAVESKIPPED:
	MOV	[NXTCLUSNUM],BX
	MOV	DX,DI
	MOV	BL,AH
	invoke	FIGREC

	entry	FIRSTCLUSTER

	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	XOR	AL,AL		; Indicate pre-read
	invoke	GETBUFFR
	jc	DirReadDone

entry	SET_BUF_AS_DIR
	DOSAssume   <DS>,"SET_BUF_AS_DIR"
	ASSUME	ES:NOTHING

;	Set the type of CURBUF to be a directory sector.
;	Only flags are modified.

	PUSH	DS
	PUSH	SI
	LDS	SI,[CURBUF]
	Assert	ISBUF,<DS,SI>,"SetBufAsDir"
	OR	[SI.buf_flags],buf_isDIR	; Clears carry
	POP	SI
	POP	DS
DirReadDone:
	return
EndProc DirRead

Break	<FATSECRD -- READ A FAT SECTOR>
;----------------------------------------------------------------------------
;
; Procedure Name : FATSECRD
; Inputs:
;	Same as DREAD
;	DS:BX = Transfer address
;	CX = Number of sectors
;	DX = Absolute record number
;	ES:BP = Base of drive parameters
; Function:
;	Calls BIOS to perform FAT read.
; Outputs:
;	Same as DREAD
;---------------------------------------------------------------------------

procedure   FATSecRd,NEAR

	Assert	    ISDPB,<ES,BP>,"FATSecRd"

;hkn; SS override
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	MOV	DI,CX
	MOV	CL,ES:[BP.dpb_FAT_count]
	MOV	AX,ES:[BP.dpb_FAT_size] 	;>32mb
;	XOR	AH,AH
	XOR	CH,CH				;>32mb
	PUSH	DX
NXTFAT:

;hkn; SS override
	MOV	[HIGH_SECTOR],0       ;>32mb FAT sectors cannot exceed
	PUSH	CX		      ;>32mb
	PUSH	AX
	MOV	CX,DI
	invoke	DSKREAD
	POP	AX
	POP	CX
	JZ	RET41P		; Carry clear
	ADD	DX,AX
	LOOP	NXTFAT
	POP	DX
	MOV	CX,DI

; NOTE FALL THROUGH

Break	<DREAD -- DO A DISK READ>
;---------------------------------------------------------------------------
;
; Procedure Name : DREAD
;
; Inputs:
;	DS:BX = Transfer address
;	CX = Number of sectors
;	DX = Absolute record number	      (LOW)
;	[HIGH_SECTOR]= Absolute record number (HIGH)
;	ES:BP = Base of drive parameters
;	[ALLOWED] must be set in case call to HARDERR needed
; Function:
;	Calls BIOS to perform disk read. If BIOS reports
;	errors, will call HARDERRRW for further action.
; Outputs:
;	Carry set if error (currently user FAILED to INT 24)
; DS,ES:BP preserved. All other registers destroyed.
;---------------------------------------------------------------------------

	entry	DREAD
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DREAD"
	invoke	DSKREAD
	retz			; Carry clear

;hkn; SS override
	MOV	BYTE PTR [READOP],0
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DREAD
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	NO_CAR		; Ignore
	STC
NO_CAR:
	return

RET41P: POP	DX
	return
EndProc FATSecRd

DOSCODE	ENDS
	END
