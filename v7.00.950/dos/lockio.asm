	TITLE	LOCK ROUTINES - Routines for file locking
	NAME	LOCKIO

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	LOCK.ASM - File Locking Routines
;
;	LOCK_CHECK
;	LOCK_VIOLATION
;	$LockOper
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
	i_need	RetryCount,WORD
	I_need	fShare,BYTE
	I_Need	EXTERR_LOCUS,BYTE	; Extended Error Locus
	i_need	JShare,DWORD
	i_need	Lock_Buffer,DWORD	; DOS 4.00
	i_need	Temp_Var,WORD		; DOS 4.00


DOSCODE SEGMENT

	allow_getdseg

	ASSUME	SS:DOSDATA,CS:DOSCODE

; Inputs:
;	Outputs of SETUP
;	[USER_ID] Set
;	[PROC_ID] Set
; Function:
;	Check for lock violations on local I/O
;	Retries are attempted with sleeps in between
; Outputs:
;    Carry clear
;	Operation is OK
;    Carry set
;	A lock violation detected
; Outputs of SETUP preserved

procedure   LOCK_CHECK,NEAR
	DOSAssume   <DS>,"Lock_Check"

	MOV	BX,RetryCount		; Number retries
LockRetry:
	SAVE	<BX,AX> 		; save regs
if installed
	call	JShare + 8 * 4
else
	Call	chk_block					;PBUGBUG
endif
	RESTORE <AX,BX> 	; restrore regs
	jnc	ret_label	; There are no locks (retnc)
	Invoke	Idle		; wait a while
	DEC	BX		; remember a retry
	JNZ	LockRetry	; more retries left...
	STC

ret_label:
	return
EndProc LOCK_CHECK

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
	MOV	DX,ES:[BP.dpb_first_sector]
	invoke	HARDERR
	POP	CX
	POP	DI
	POP	ES
	POP	DS
	CMP	AL,1
	retz			; 1 = retry, carry clear
	STC
	return

EndProc LOCK_VIOLATION

DOSCODE	ENDS
	END
