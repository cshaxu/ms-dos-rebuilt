	TITLE	DEV - Device call routines
	NAME	Dev

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	Misc Routines to do 1-12 low level I/O and call devices
;
;	IOFUNC
;	DEVIOCALL
;	SETREAD
;	SETWRITE
;	DEVIOCALL2
;	DEV_OPEN_SFT
;	DEV_CLOSE_SFT
;	RW_SC
;	IN_SC
;	INVALIDATE_SC
;	VIRREAD
;	SC2BUF
;
;	Revision history:
;
;		A000  version 4.00     Jan. 1988
;		A010  disable change line for SHARE /NC

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include dpb.inc
	include sf.inc
	.cref
	.list

	i_need	IOXAD,DWORD
	i_need	IOSCNT,WORD
	i_need	DEVIOBUF,4
	i_need	IOCALL,BYTE
	i_need	IOMED,BYTE
	i_need	IORCHR,BYTE
	i_need	CALLSCNT,WORD
	i_need	DMAAdd,DWORD
	i_need	CallDevAd,DWORD
	i_need	CallXAD,DWORD
	i_need	DPBHead,DWORD
	i_need	ThisSFT,DWORD
	i_need	ThisDPB,DWORD
	i_need	DevCall,DWORD
	i_need	VerFlg,BYTE
	i_need	HIGH_SECTOR,WORD	       ;AN000;
	i_need	CALLSSEC,WORD		       ;AN000;
	i_need	CALLNEWSC,DWORD 	       ;AN000;
	i_need	SC_CACHE_COUNT,WORD	       ;AN000;
	i_need	SC_CACHE_PTR,DWORD	       ;AN000;
	i_need	CURSC_SECTOR,WORD	       ;AN000;
	i_need	SEQ_SECTOR,DWORD	       ;AN000;
	i_need	SC_SECTOR_SIZE,WORD	       ;AN000;
	i_need	CURSC_DRIVE,BYTE	       ;AN000;
	i_need	SC_DRIVE,BYTE		       ;AN000;
	i_need	SC_STATUS,WORD		       ;AN000;
	i_need	SC_FLAG,BYTE		       ;AN000;
	i_need	TEMP_VAR,WORD		       ;AN000;
	i_need	TEMP_VAR2,WORD		       ;AN000;
	i_need	InterChar,BYTE	;AN000; interim character flag 2/13/KK
	i_need	InterCon,BYTE	;AN000; Console mode flag(1:interim mode) 2/13/KK
	i_need	SaveCurFlg,BYTE ;AN000; Console out mode(1:print & don't adv cursor) 2 /13/KK
	i_need	DDMOVE,BYTE	;AN000; flag for DWORD move
	i_need	DOS34_FLAG,WORD ;AN000;
	i_need	fshare,BYTE	;AN010; share flag

	i_need 	IoStatFail,BYTE	;SR; set if user failed on I24 in IOFUNC


DOSCODE	Segment

	ASSUME	CS:DOSCODE

ASSUME SS:DOSDATA,DS:NOTHING,ES:NOTHING
;**	Dev_Open_SFT - Open the Device for an SFT
;
;	Dev_Open_SFT issues an open call to the device associated with
;	the SFT.
;
;	ENTRY	(ES:DI) = SFT
;	EXIT	none
;	USES	all

procedure   DEV_OPEN_SFT,NEAR

	Assert	ISSFT,<ES,DI>,"Dev_Open_SFT"

	Save_World			; use macro
	MOV	AL,DEVOPN
	JMP	SHORT DO_OPCLS

EndProc DEV_OPEN_SFT

;---------------------------------------------------------------------------
;
; Procedure Name : DEV_CLOSE_SFT
;
; Inputs:
;	ES:DI Points to SFT
; Function:
;	Issue a CLOSE call to the correct device
; Outputs:
;	None
; ALL preserved
;
;---------------------------------------------------------------------------

procedure   DEV_CLOSE_SFT,NEAR

	Assert	ISSFT,<ES,DI>,"Dev_Close_SFT"

	Save_World			; use macro

	MOV	AL,DEVCLS

	;
	; Main entry for device open and close.  AL contains the function 
	; requested. Subtlety:  if Sharing is NOT loaded then we do NOT issue 
	; open/close to block devices.  This allows networks to function but 
	; does NOT hang up with bogus change-line code.
	;

	entry	DO_OPCLS

	; Is the SFT for the net?  If so, no action necessary.

	TESTB	es:[di].sf_Flags, SF_ISNET
	JNZ	OPCLS_DONE		; NOP on net SFTs
	XOR	AH,AH			; Unit
	TESTB	ES:[DI].SF_FLAGS,devid_device
	LES	DI,ES:[DI.sf_devptr]	; Get DPB or device
	JNZ	Got_Dev_Addr

	; We are about to call device open/close on a block driver.  If no 
	; sharing then just short circuit to done.

;;;;;	invoke	CheckShare

					; SS override
	CMP	fshare,1		;AN010; /NC or no SHARE
	JBE	opCLs_Done		;AN010; yes
	MOV	AH,ES:[DI.dpb_UNIT]	; (ah) = unit
	MOV	CL,ES:[DI.dpb_drive]	; (cl) = drive
	LES	DI,ES:[DI.dpb_driver_addr]  ; Get device
GOT_DEV_ADDR:				; ES:DI -> device
	TESTB	ES:[DI.SDEVATT],DEVOPCL
	JZ	OPCLS_DONE		; Device can't
	PUSH	ES
	POP	DS
	MOV	SI,DI			; DS:SI -> device
OPCLS_RETRY:
	Context ES

					; DEVCALL is in DOSDATA
	MOV	DI,OFFSET DOSDATA:DEVCALL

	MOV	BX,DI
	PUSH	AX
	MOV	AL,DOPCLHL
	STOSB				; Length
	POP	AX
	XCHG	AH,AL
	STOSB				; Unit
	XCHG	AH,AL
	STOSB				; Command
	MOV	WORD PTR ES:[DI],0	; Status
	PUSH	AX			; Save Unit,Command
	invoke	DEVIOCALL2
	MOV	DI,ES:[BX.REQSTAT]
	.errnz	STERR-8000h
	and	di,di
	Jns	OPCLS_DONEP		; No error
	TESTB	[SI.SDEVATT],DEVTYP
	JZ	BLKDEV
	MOV	AH,86H			; Read error in data, Char dev
	JMP	SHORT HRDERR

BLKDEV:
	MOV	AL,CL			; Drive # in AL
	MOV	AH,6			; Read error in data, Blk dev
HRDERR:
	invoke	CHARHARD
	CMP	AL,1
	JNZ	OPCLS_DONEP		; IGNORE or FAIL
					;  Note that FAIL is essentually IGNORED
	POP	AX			; Get back Unit, Command
	JMP	OPCLS_RETRY

OPCLS_DONEP:
	POP	AX			; Clean stack
OPCLS_DONE:

	Restore_World			;hkn; use macro
	return

EndProc DEV_CLOSE_SFT


DOSCODE ENDS
END
