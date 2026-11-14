	TITLE MISC2 - Miscellanious routines for MS-DOS
	NAME  IDLE

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	MISC2.ASM - Miscellaneous useful routines
;
;	StrCpy
;	StrCmp
;	StrLen
;	DStrLen
;	Idle
;	TableDispatch
;	FastInit			  ; DOS 4.0
;	FastRet			  ; DOS 4.0
;	NLS_OPEN			  ; DOS 4.0
;	NLS_LSEEK			  ; DOS 4.0
;	Fake_User_Stack		  ; DOS 4.0
;	GetDevList			  ; DOS 4.0
;	NLS_IOCTL			  ; DOS 4.0
;	NLS_GETEXT			  ; DOS 4.0
;	MSG_RETRIEVAL		  ; DOS 4.0
;	Fake_Version		  ; DOS 4.0
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
	include sysvar.inc
	include sf.inc
	include curdir.inc
	include fastxxxx.inc
	include bugtyp.inc
	.cref
	.list

	i_need	THISCDS,DWORD
	I_Need	RetryLoop,WORD
	I_need	fSharing,BYTE		; TRUE => server-issued call
	I_need	FastTable,BYTE		;AN000;
	I_need	FastFlg,BYTE		;AN000;
	I_need	User_SP_2F,WORD 	;AN000;
	I_need	User_SP,WORD		;AN000;
	I_need	User_SS,WORD		;AN000;
	I_need	SysInitTable,BYTE	;AN000;
	I_need	EXTERR,WORD		;AN000;
	I_need	fshare,byte		;AN001;
	I_need	Special_version,WORD	;AN006;

	i_need	NlsBuffer,BYTE

DOSCODE	SEGMENT

	allow_getdseg

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
