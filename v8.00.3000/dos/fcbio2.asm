;	SCCSID = @(#)fcbio2.asm 1.2 85/07/23
	TITLE	FCBIO2 - FCB system calls
	NAME	FCBIO2

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	FCBIO2.ASM - Ancient 1.0 1.1 FCB system calls
;
;	GetExtended
;	$FCB_OPEN
;	$FCB_CREATE
;	$FCB_RANDOM_WRITE_BLOCK
;	$FCB_RANDOM_READ_BLOCK
;	$FCB_SEQ_READ
;	$FCB_SEQ_WRITE
;	$FCB_RANDOM_READ
;	$FCB_RANDOM_WRITE
;
;	Revision history:
;
;		Created: ARR 4 April 1983
;			 MZ  6 June  1983 completion of functions
;			 MZ 15 Dec   1983 Brain damaged programs close FCBs multiple
;				  times.  Change so successive closes work by
;				  always returning OK.	Also, detect I/O to
;				  already closed FCB and return EOF.
;		 MZ 16 Jan   1984 More braindamage.  Need to separate info
;				  out of sft into FCB for reconnection
;
;	    A000   version 4.00	Jan. 1988

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include dpb.inc
	include cpmfcb.inc
	include filemode.inc
	include bugtyp.inc
	.cref
	.list


	I_need	OpenBuf,128		; buffer for translating paths
	I_need	ThisSFT,DWORD		; SFT in use
	I_need	sftFCB,DWORD		; pointer to SFTs for FCB cache
	I_need	FCBLRU,WORD		; least recently used count

	I_need	LocalSFT,DWORD		;Cache for new FCB implementation


DOSCODE	SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE


	EXTRN	DOS_Open:NEAR, DOS_Create:NEAR


Break <GetExtended - find FCB in potential extended fcb>
;---------------------------------------------------------------------------
;
;   GetExtended - Make DS:SI point to FCB from DS:DX
;
;   Inputs:	DS:DX point to a possible extended FCB
;   Outputs:	DS:SI point to the FCB part
;		zeroflag set if not extended fcb
;   Registers modified: SI
;---------------------------------------------------------------------------

Procedure   GetExtended,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA
	MOV	SI,DX			; point to Something
	CMP	BYTE PTR DS:[SI],-1	; look for extention
	JNZ	GetBye			; not there
	ADD	SI,7			; point to FCB
GetBye:
	CMP	SI,DX			; set condition codes
	return
EndProc GetExtended

Break <$FCB_Open - open an old-style FCB>
;---------------------------------------------------------------------------
;
;   $FCB_Open - CPM compatability file open.  The user has formatted an FCB
;	for us and asked to have the rest filled in.
;
;   Inputs:	DS:DX point to an unopenned FCB
;   Outputs:	AL indicates status 0 is ok FF is error
;		FCB has the following fields filled in:
;		    Time/Date Extent/NR Size
;---------------------------------------------------------------------------

Procedure $FCB_Open,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA
	MOV	AX,sharing_Compat+Open_For_Both

;hkn; DOS_Open is in DOSCODE
	MOV	CX,OFFSET DOSCODE:DOS_Open
;
; The following is common code for Creation and openning of FCBs.  AX is
; either attributes (for create) or open mode (for open)...  DS:DX points to
; the FCB
;
DoAccess:
	SAVE	<DS,DX,CX,AX>		; save FCB pointer away

;hkn; 	OpenBuf is in DOSDATA
	MOV	DI,OFFSET DOSDATA:OpenBuf
	invoke	TransFCB		; crunch the fcb
	RESTORE <AX,CX,DX,DS>	; get fcb
	JNC	FindFCB 		; everything seems ok
FCBOpenErr:
;
; AL has error code
;
	transfer    FCB_Ret_Err
FindFCB:
	invoke	GetExtended		; DS:SI will point to FCB

	push	ax
	mov	al,1			;indicate Open/Create operation
	invoke	LRUFCB			; get a sft entry (no error)
	pop	ax

	JC	HardMessage
	ASSUME	ES:NOTHING

;	Message 1,"Entering "
;	MessageNum  ES
;	Message 1,":"
;	MessageNum  DI
;	Message 1,<13,10>

	MOV	ES:[DI].sf_mode,sf_ISFCB
	SAVE	<DS,SI,BX>		; save fcb pointer
	MOV	SI,CX

;hkn; SS is DOSDATA
	Context DS			; let DOS_Open see variables
	CALL	SI			; go open the file
	RESTORE <BX,SI,DS>		; get fcb
	ASSUME	DS:NOTHING

;hkn; SS override
	LES	DI,ThisSFT		; get sf pointer
	JNC	FCBOK			; operation succeeded
	Assert	ISSFT,<ES,DI>,"DeadFCB"
failopen:
	PUSH	AX
	MOV	AL,"R"                  ; clear out field (free sft)
	invoke	BlastSFT
	POP	AX
	DB	083h,0F8h,error_too_many_open_files ; CMP AX,imm8
	JZ	HardMessage
	DB	083h,0F8h,error_sharing_buffer_exceeded ; CMP AX,imm8
	jnz	DeadFCB
HardMessage:
	PUSH	AX
	invoke	FCBHardErr
	POP	AX
DeadFCB:
	transfer    FCB_Ret_Err
FCBOK:
	invoke	IsSFTNet		       ;AN007;F.C. >32mb  Non Fat file?
	JNZ	FCBOK2			       ;AN007;F.C. >32mb  yes
;SR;
; If we reach here, we know we have got a local SFT. Let's update the 
; LocalSFT variable to reflect this.
;
	mov	word ptr LocalSFT,di	;
	mov	word ptr LocalSFT+2,es; Store the SFT address
;
; Local FCB opens are limited to devices and volume labels.
;
	TESTB	ES:[DI].sf_flags,devid_device
	JNZ	FCBOK2
	TESTB	ES:[DI].sf_attr,attr_volume_id
	JNZ	FCBOK2
	MOV	AX,error_invalid_function
	JMP	failopen
;SR;
; The check below is not valid anymore since we regenerate for media > 32M.
;
;	CMP	WORD PTR ES:[DI].sf_dirsec+2,0 ;AN000;F.C. >32mb  if dirsec >32mb
;	JZ	FCBOK2			       ;AN000;F.C. >32mb    then error
;	MOV	AX,error_sys_comp_not_loaded   ;AN000;F.C. >32mb
;	JMP	failopen		       ;AN000;F.C. >32mb

FCBOK2:

	INC	ES:[DI].sf_ref_count	; increment reference count
	invoke	SaveDirSft
	invoke	SaveFCBInfo
	Assert	ISSFT,<ES,DI>,"FCBOK"

	TESTB	ES:[DI].sf_flags,devid_device
	JNZ	FCBNoDrive		; do not munge drive on devices
	MOV	AL,DS:[SI]		; get drive byte
	invoke	GetThisDrv		; convert
	INC	AL
	MOV	DS:[SI],AL		; stash in good drive letter
FCBNoDrive:
	MOV	[SI].FCB_RecSiz,80h	; stuff in default record size
	MOV	AX,ES:[DI].SF_Time	; set time
	MOV	[SI].FCB_FTime,AX
	MOV	AX,ES:[DI].SF_Date	; set date
	MOV	[SI].FCB_FDate,AX
	MOV	AX,WORD PTR ES:[DI].SF_Size ; set sizes
	MOV	[SI].FCB_FILSIZ,AX
	MOV	AX,WORD PTR ES:[DI].SF_Size+2
	MOV	[SI].FCB_FILSIZ+2,AX
	XOR	AX,AX			; convenient zero
	MOV	[SI].FCB_Extent,AX	; point to beginning of file
;
; We must scan the set of FCB SFTs for one that appears to match the current
; one.	We cheat and use CheckFCB to match the FCBs.
;

;hkn; 	SS override
	LES	DI,SFTFCB		; get the pointer to head of the list
	MOV	AH,BYTE PTR ES:[DI].sfCount ; get number of SFTs to scan
OpenScan:
	CMP	AL,[SI].fcb_sfn 	; don't compare ourselves
	JZ	SkipCheck
	SAVE	<AX>			; preserve count
	invoke	CheckFCB		; do they match
	RESTORE <AX>		; get count back
	JNC	OpenFound		; found a match!
SkipCheck:
	INC	AL			; advance to next FCB
	DB	038h,0E0h		; CMP AL,AH; table full?
	JNZ	OpenScan		; no, go for more
OpenDone:
	xor	al,al			; return success
	return
;
; The SFT at ES:DI is the one that is already in use for this FCB.  We set the
; FCB to use this one.	We increment its ref count.  We do NOT close it at all.
; Consider:
;
;   open (foo)	delete (foo) open (bar)
;
; This causes us to recycle (potentially) bar through the same local SFT as
; foo even though foo is no longer needed; this is due to the server closing
; foo for us when we delete it.  Unfortunately, we cannot see this closure.
; If we were to CLOSE bar, the server would then close the only reference to
; bar and subsequent I/O would be lost to the redirector.
;
; This gets solved by NOT closing the sft, but zeroing the ref count
; (effectively freeing the SFT) and informing the sharer (if relevant) that
; the SFT is no longer in use.	Note that the SHARER MUST keep its ref counts
; around.  This will allow us to access the same file through multiple network
; connections and NOT prematurely terminate when the ref count on one
; connection goes to zero.
;
OpenFound:
	MOV	[SI].fcb_SFN,AL 	; assign with this
	INC	ES:[DI].sf_ref_count	; remember this new invocation
	invoke	SaveDirSft
	MOV	AX,FCBLRU		; update LRU counts
	MOV	ES:[DI].sf_LRU,AX
;
; We have an FCB sft that is now of no use.  We release sharing info and then
; blast it to prevent other reuse.
;

;hkn; SS is DOSDATA
	context DS
	LES	DI,ThisSFT
	DEC	ES:[DI].sf_ref_count	; free the newly allocated SFT
	Assert	ISSFT,<ES,DI>,"Open blasting"
	MOV	AL,'C'
	invoke	BlastSFT
	JMP	OpenDone
EndProc $FCB_Open

BREAK	<$FCB_Create - create a new directory entry>
;----------------------------------------------------------------------------
;
;   $FCB_Create - CPM compatability file create.  The user has formatted an
;	FCB for us and asked to have the rest filled in.
;
;   Inputs:	DS:DX point to an unopenned FCB
;   Outputs:	AL indicates status 0 is ok FF is error
;		FCB has the following fields filled in:
;		    Time/Date Extent/NR Size
;----------------------------------------------------------------------------

Procedure $FCB_Create,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA

;hkn; DOS_Create is in DOSCODE
	MOV	CX,OFFSET DOSCODE:DOS_Create	; routine to call
	XOR	AX,AX			; attributes to create
	invoke	GetExtended		; get extended FCB
	.386
	JZ	DoAccess		; not an extended FCB
	.8086
	MOV	AL,[SI-1]		; get attributes
DoAccessJ:
	JMP	DoAccess		; do dirty work
EndProc $FCB_Create

BREAK <Unsupported FCB record transfers>

Procedure $FCB_Random_Write_Block,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA
	MOV	AL,error_invalid_function
	transfer    FCB_Ret_Err
EndProc $FCB_Random_Write_Block

Procedure $FCB_Random_Read_Block,NEAR
	JMP	SHORT $FCB_Random_Write_Block
EndProc $FCB_Random_Read_Block

Procedure $FCB_Seq_Read,NEAR
	JMP	SHORT $FCB_Random_Write_Block
EndProc $FCB_Seq_Read

Procedure $FCB_Seq_Write,NEAR
	JMP	SHORT $FCB_Random_Write_Block
EndProc $FCB_Seq_Write

Procedure $FCB_Random_Read,NEAR
	JMP	SHORT $FCB_Random_Write_Block
EndProc $FCB_Random_Read

Procedure $FCB_Random_Write,NEAR
	JMP	SHORT $FCB_Random_Write_Block
EndProc $FCB_Random_Write

DOSCODE ENDS
	END

