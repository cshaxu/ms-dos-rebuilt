	TITLE IDLE - Sharing retry delay
	NAME  IDLE

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	IDLE.ASM - Sharing retry delay
;
;	Idle
;
;	Revision history:
;
;	   Created: ARR 30 March 1983
;
;	   A000   version 4.0	Jan. 1988
;	   A001   DCR 486 - Share installation for >32mb drives
;	   A006   DCR 503 - fake version number for IBMCACHE
;	   DOS 5.00 Moved fake version to caller's PSP
	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	include dossym.inc
	.cref
	.list

	I_Need	RetryLoop,WORD
	I_need	fSharing,BYTE		; TRUE => server-issued call


DOSCODE	SEGMENT


	ASSUME	SS:DOSDATA,CS:DOSCODE



Break	<Idle - wait for a specified amount of time>
;----------------------------------------------------------------------------
;
;   Idle - when retrying an operation due to a lock/sharing violation, we spin
;   until RetryLoop is exhausted.
;
;   Inputs:	RetryLoop is the number of times we spin
;   Outputs:	Wait
;   Registers modified: none
;----------------------------------------------------------------------------
Procedure   Idle,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA

;hkn; SS override
	cmp	fSharing,0
	JNZ	IdleDone
	SAVE	<CX>

;hkn; SS override
	MOV	CX,RetryLoop
	JCXZ	Idle3
Idle1:	PUSH	CX
	XOR	CX,CX
Idle2:	LOOP	Idle2
	POP	CX
	LOOP	Idle1
Idle3:	RESTORE <CX>
IdleDone:
	return
EndProc Idle

DOSCODE	ENDS
	END
