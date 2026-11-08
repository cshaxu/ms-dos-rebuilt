; Bounded physical directory read from comparative DOS 6, target-audited.
	TITLE	DISK - Disk utility routines
	NAME	Disk

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	Low level Read and write routines for local SFT I/O on files and devs
;
;	SWAPCON
;	SWAPBACK
;	DOS_READ
;	DOS_WRITE
;	get_io_sft
;	DirRead
;	FIRSTCLUSTER
;	SET_BUF_AS_DIR
;	FATSecRd
;	DREAD
;	CHECK_WRITE_LOCK
;	CHECK_READ_LOCK
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
	I_Need	CONSft,DWORD		; SFT for swapped console In/Out
	i_need	CONSWAP,BYTE
	i_need	IDLEINT,BYTE
	i_need	THISSFT,DWORD
	i_need	DMAADD,DWORD
	i_need	DEVCALL,BYTE
	i_need	CALLSCNT,WORD
	i_need	CALLXAD,DWORD
	i_need	CONTPOS,WORD
	i_need	NEXTADD,WORD
	i_need	CONBUF,BYTE
	i_need	ClusFac,BYTE
	i_need	SecClusPos,BYTE
	i_need	DirSec,DWORD
	i_need	ClusNum,WORD
	i_need	NxtClusNum,WORD
	i_need	ReadOp,BYTE
	i_need	CURBUF,DWORD
	i_need	ALLOWED,BYTE
	i_need	EXTERR_LOCUS,BYTE


	i_need	HIGH_SECTOR,WORD
	I_need	JShare,DWORD
	i_need	DOS34_FLAG,WORD
;
;Flag to indicate WIN386 presence
;
	I_need	IsWin386,BYTE


DOSCODE	Segment
	ASSUME	SS:DOSDATA,CS:DOSCODE

	EXTRN	CharHard:near
	EXTRN	DevIoCall:near
	EXTRN	DevIoCall2:near
	EXTRN	Outt:near
	EXTRN	Setup:near


; Shared preceding get_io_sft return, as used by target retc macros.
return
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
	retc
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
	retc

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
	return
EndProc DirRead
DOSCODE ENDS
END
