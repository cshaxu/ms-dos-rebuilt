	TITLE	LOCKIO - Lock checks for local I/O
	NAME	LOCKIO

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	LOCKIO.ASM - Local I/O Lock Checks
;
;	LOCK_VIOLATION
;
;	Revision history:
;	  A000	 version 4.00	Jan. 1988

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include lock.inc
	include mult.inc
	include dpb.inc
	include sf.inc
	.cref
	.list

AsmVars <IBM, Installed>

Installed = TRUE

	i_need	THISSFT,DWORD
	i_need	THISDPB,DWORD
	i_need	EXTERR,WORD
	i_need	ALLOWED,BYTE
	I_need	fShare,BYTE
	I_Need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	HIGH_SECTOR,WORD
	i_need	Lock_Buffer,DWORD	; DOS 4.00
	i_need	Temp_Var,WORD		; DOS 4.00


DOSCODE SEGMENT

	allow_getdseg

	ASSUME	SS:DOSDATA,CS:DOSCODE

; Inputs:
;	[THISDPB] set
;	[READOP] indicates whether error on read or write
; Function:
;	Handle Lock violation on compatibility (FCB) mode SFTs
; Outputs:
;	Carry set if user says FAIL, causes error_lock_violation
;	Carry clear if user wants a retry
;
; DS, ES, DI, CX preserved, others destroyed

procedure   LOCK_VIOLATION,NEAR
	DOSAssume   <DS>,"Lock_Violation"

	PUSH	DS
	PUSH	ES
	PUSH	DI
	PUSH	CX
	MOV	AX,error_lock_violation
	MOV	[ALLOWED],allowed_FAIL + allowed_RETRY
	LES	BP,[THISDPB]
	MOV	DI,1				; Fake some registers
	MOV	CX,DI
	CMP	ES:[BP.dpb_fat_size],0
	JZ	LockSector32
	MOV	[HIGH_SECTOR],0
	MOV	DX,ES:[BP.dpb_first_sector]
	JMP	SHORT LockHardErr
LockSector32:
	MOV	DX,WORD PTR ES:[BP.dpb_first_sector32+2]
	MOV	[HIGH_SECTOR],DX
	MOV	DX,WORD PTR ES:[BP.dpb_first_sector32]
LockHardErr:
	invoke	HARDERR
	POP	CX
	POP	DI
	POP	ES
	POP	DS
	CMP	AL,1
	JNZ	SHORT LockFail
	return			; 1 = retry, carry clear
LockFail:
	STC
	return

EndProc LOCK_VIOLATION

DOSCODE	ENDS
	END
