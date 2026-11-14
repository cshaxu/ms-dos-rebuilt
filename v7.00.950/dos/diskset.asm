	TITLE	DISKSET - Disk request setup
	NAME	DiskSet

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	DISKSET.ASM - Disk request setup and error mapping
;
;	HarderrRW
;	SETUP
;
;	Revision history:
;
;		AN000 version 4.00 Jan. 1988
;		M039 DB 10/17/90 - Disk read/write optimization


	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include dpb.inc
	include filemode.inc
        include dosmac.inc              ;M039
	.cref
	.list

Installed = TRUE

	i_need	DMAADD,DWORD
	i_need	NEXTADD,WORD
	i_need	ThisDrv,BYTE
	i_need	SecClusPos,BYTE
	i_need	ClusNum,WORD
	i_need	Trans,BYTE
	i_need	BytPos,4
	i_need	SecPos,DWORD		 ; DOS 4.00 >32mb			;AN000;
	i_need	BytSecPos,WORD
	i_need	ThisDPB,DWORD
	i_need	EXTERRPT,DWORD
	i_need	CALLVIDRW,DWORD

;**RMFHFE**	i_need	DISK_FULL,BYTE		  ; disk full flag for ran blk wrt



DOSCODE	Segment
	ASSUME	SS:DOSDATA, CS:DOSCODE


	ASSUME	DS:NOTHING,ES:NOTHING
Break	<HardErrRW - map extended errors and call harderr>
;---------------------------------------------------------------------------
;
; Procedure Name : HardErrRW
;
; Inputs:
;	AX is error code from read or write
;	Other registers set as per HARDERR
; Function:
;	Checks the error code for special extended
;	errors and maps them if needed. Then invokes
;	Harderr
; Outputs:
;	Of HARDERR
; AX may be modified prior to call to HARDERR.
; No other registers altered.
;
;---------------------------------------------------------------------------

procedure   HARDERRRW,near

	CMP	AL,error_I24_wrong_disk
	JNZ	DO_ERR				; Nothing to do

	push	ax
	mov	ax, word ptr callvidrw		; get ptr lo	;smr;SS Override
	mov	word ptr exterrpt, ax		; set ext err ptr lo
	mov	ax, word ptr callvidrw+2	; get ptr hi from dev
	mov	word ptr exterrpt+2, ax		; set ext err ptr hi
	pop	ax

;	PUSH	DS
;	PUSH	SI

;hkn; SS override for CALLVIDRW & EXTERRPT
;	LDS	SI,[CALLVIDRW]			; Get pointer from dev
;	MOV	WORD PTR [EXTERRPT+2],DS	; Set ext err pointer
;	MOV	WORD PTR [EXTERRPT],SI
;	POP	SI
;	POP	DS
DO_ERR:
	invoke	HARDERR
	return

EndProc HARDERRRW

Break	<SETUP -- SETUP A DISK READ OR WRITE FROM USER>
;----------------------------------------------------------------------------
;
; Procedure Name : SETUP
;
; Inputs:
;	ES:DI point to SFT (value also in THISSFT)
;	DMAAdd contains transfer address
;	CX = Byte count
;	DS = DOSDATA
;   WARNING Stack must be clean, two ret addrs on stack, 1st of caller,
;		2nd of caller of caller.
; Outputs:
;	    CX = byte count
;	    [THISDPB] = Base of drive parameters if file
;		      = Pointer to device header if device or NET
;	    ES:DI Points to SFT
;	    [NEXTADD] = Displacement of disk transfer within segment
;	    [TRANS] = 0 (No transfers yet)
;	    BytPos = Byte position in file
;
;	The following fields are relevant to local files (not devices) only:
;
;	    SecPos = Position of first sector (local files only)
;	    [BYTSECPOS] = Byte position in first sector (local files only)
;	    [CLUSNUM] = First cluster (local files only)
;	    [SECCLUSPOS] = Sector within first cluster (local files only)
;	    [THISDRV] = Physical unit number (local files only)
;
;      RETURNS ONE LEVEL UP WITH:
;	   CX = 0
;	   CARRY = Clear
;	IF AN ERROR IS DETECTED
; All other registers destroyed
;----------------------------------------------------------------------------

;hkn; called from disk.asm. DS has been set up to DOSDATA.

procedure   SETUP,NEAR
	DOSAssume   <DS>,"SetUp"

	Assert	    ISSFT,<ES,DI>,"SetUp"
	LDS	SI,ES:[DI.sf_devptr]
ASSUME	DS:NOTHING

;hkn; SS override
	MOV	WORD PTR [THISDPB+2],DS

;hkn; SS is DOSDATA
	context DS

	MOV	WORD PTR [THISDPB],SI
	MOV	BX,WORD PTR DMAAdd
	MOV	[NEXTADD],BX		;Set NEXTADD to start of Xaddr
	MOV	BYTE PTR [TRANS],0	;No transferes
	MOV	AX,WORD PTR ES:[DI.sf_Position]
	MOV	DX,WORD PTR ES:[DI.sf_Position+2]
	MOV	WORD PTR [BYTPOS+2],DX	;Set it
	MOV	WORD PTR BytPos,AX
	TESTB	ES:[DI].SF_FLAGS,<sf_isnet + devid_device>
	JNZ	NOSETSTUFF		;Following not done on devs or NET
	PUSH	ES
	LES	BP,[THISDPB]		;Point at the DPB
	Assert	ISDPB,<ES,BP>,"Setup"
	MOV	BL,ES:[BP.dpb_drive]
	MOV	[THISDRV],BL		;Set THISDRV
	MOV	BX,ES:[BP.dpb_sector_size]

;M039: Optimized this section.
        PUSH    CX                            ;SHR32 and DIV32 use CX.
	invoke	DIV32			      ;DX:AX/BX = CX:AX + DX (rem)
	MOV	[BYTSECPOS],DX
	MOV	WORD PTR SecPos,AX
	MOV	WORD PTR SecPos+2,CX
	MOV	DX,CX

	MOV	BX,AX
	AND	BL,ES:[BP.dpb_cluster_mask]
	MOV	[SECCLUSPOS],BL

	invoke	SHR32			     ;(DX:AX SHR dpb_cluster_shift)
	POP	CX			     ;CX = byte count.
	JNZ	EOFERR			     ;cluster number above 64k
	CMP	AX,ES:[BP.dpb_max_cluster]   ;>32mb    if > disk size ;AN000;	;AN000;
	JA	EOFERR			     ;>32mb    then EOF     ;AN000;	;AN000;

	MOV	[CLUSNUM],AX
	POP	ES			     ; ES:DI point to SFT
;M039

NOSETSTUFF:
	MOV	AX,CX		; AX = Byte count.
	ADD	AX,WORD PTR DMAAdd	 ; See if it will fit in one segment
	JNC	OK		; Must be less than 64K
	MOV	AX,WORD PTR DMAAdd
	NEG	AX		; Amount of room left in segment (know
				;    less than 64K since max value of CX
				;    is FFFF).
	JNZ	NoDec
	DEC	AX
NoDec:
	MOV	CX,AX		; Can do this much
	JCXZ	NOROOM		; Silly user gave Xaddr of FFFF in segment
OK:
	return

EOFERR:
	POP	ES		; ES:DI point to SFT
	XOR	CX,CX		; No bytes read
;;;;;;;;;;; 7/18/86
;	MOV	BYTE PTR [DISK_FULL],1	    ; set disk full flag
;;;;;;;;;;;
NOROOM:
	POP	BX		; Kill return address
	CLC
	return			; RETURN TO CALLER OF CALLER
EndProc SETUP

DOSCODE	ENDS
	END
