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

Public DEV001S, DEV001E 		; Pathgen labels
DEV001s:
;		length of packets
LenTab	DB	DRDWRHL, DRDNDHL, DRDWRHL, DSTATHL, DFLSHL, DRDNDHL

;		Error	Function

CmdTab	DB	86h,	DEVRD		; 0 input
	DB	86h,	DEVRDND 	; 1 input status
	DB	87h,	DEVWRT		; 2 output
	DB	87h,	DEVOST		; 3 output status
	DB	86h,	DEVIFL		; 4 input flush
	DB	86H,	DEVRDND 	; 5 input status with system WAIT
DEV001E:

	ASSUME	CS:DOSCODE, SS:DOSDATA

Break	<IOFUNC -- DO FUNCTION 1-12 I/O>
;----------------------------------------------------------------------------
;
; Procedure Name : IOFUNC
;
; Inputs:
;	DS:SI Points to SFT
;	AH is function code
;		= 0 Input
;		= 1 Input Status
;		= 2 Output
;		= 3 Output Status
;		= 4 Flush
;		= 5 Input Status - System WAIT invoked for K09 if no char
;				   present.
;	AL = character if output
; Function:
;	Perform indicated I/O to device or file
; Outputs:
;	AL is character if input
;	If a status call
;		zero set if not ready
;		zero reset if ready (character in AL for input status)
; For regular files:
;	Input Status
;		Gets character but restores position
;		Zero set on EOF
;	Input
;		Gets character advances position
;		Returns ^Z on EOF
;	Output Status
;		Always ready
; AX altered, all other registers preserved
;----------------------------------------------------------------------------

procedure   IOFUNC,NEAR

	Assert	ISSFT,<DS,SI>,"IOFUNC"

					
	MOV	WORD PTR [IOXAD+2],SS	; SS override for IOXAD, IOSCNT, 
					; DEVIOBUF

					; DEVIOBUF is in DOSDATA
	MOV	WORD PTR [IOXAD],OFFSET DOSDATA:DEVIOBUF
	MOV	WORD PTR [IOSCNT],1
	MOV	WORD PTR [DEVIOBUF],AX
	TESTB	[SI].SF_FLAGS,sf_isnet
	JZ	IOTO22								;AN000;
	JMP	IOTOFILE							;AN000;
IOTO22:
	TESTB	[SI].SF_FLAGS,devid_device
	JNZ	IOTo33								;AN000;
	JMP	IOTOFILE							;AN000;
IOTO33:
	save_world
	MOV	DX,DS
	MOV	BX,SS
	MOV	DS,BX
	MOV	ES,BX

	ASSUME	DS:DOSDATA

	XOR	BX,BX
	cmp	ah,5		    ; system wait enabled?
	jnz	no_sys_wait
	or	bx,0400H	    ; Set bit 10 in status word for driver
				    ; It is up to device driver to carry out
				    ; appropriate action.
no_sys_wait:
	MOV	[IOCALL.REQSTAT],BX
	XOR	BX,BX
	MOV	BYTE PTR [IOMED],BL

; moved out side this DOSCODE segment.
; Table	Segment
; Public DEV001S, DEV001E 		; Pathgen labels
; DEV001s:
; ;		length of packets
; LenTab	DB	DRDWRHL, DRDNDHL, DRDWRHL, DSTATHL, DFLSHL, DRDNDHL
; 
; ;		Error	Function
; 
; CmdTab	DB	86h,	DEVRD		; 0 input
; 	DB	86h,	DEVRDND 	; 1 input status
; 	DB	87h,	DEVWRT		; 2 output
; 	DB	87h,	DEVOST		; 3 output status
; 	DB	86h,	DEVIFL		; 4 input flush
; 	DB	86H,	DEVRDND 	; 5 input status with system WAIT
; DEV001E:
; Table	ENDS

	MOV	BL,AH			; get function
	MOV	AH,LenTab[BX]
	SHL	BX,1
	MOV	CX,WORD PTR CmdTab[BX]
	MOV	BX,OFFSET DOSDATA:IOCALL; IOCALL is in DOSDATA
	MOV	[IOCALL.REQLEN],AH
	MOV	[IOCALL.REQFUNC],CH
 IFDEF  DBCS				;AN000;
;----------------------------- Start of DBCS 2/13/KK
	PUSH	CX			;AN000;
	MOV	CL, [InterCon]		;AN000;
	CMP	CH, DEVRD		;AN000; 0 input
	JZ	SETIN			;AN000;
	CMP	CH, DEVRDND		;AN000; 1(5) input status without(with) system WAIT
	JZ	SETIN			;AN000;
	MOV	CL, [SaveCurflg]	;AN000;
	CMP	CH, DEVWRT		;AN000; 2 output
	JZ	CHKERROUT		;AN000;
	XOR	CL,CL			;AN000; else, do normal
SETIN:					;AN000;
	MOV	BYTE PTR [IoMed], CL	;AN000; set interim I/O indication
	POP	CX			;AN000;
;----------------------------- End of DBCS 2/13/KK
 ENDIF					;AN000;
	MOV	DS,DX
ASSUME	DS:NOTHING
	invoke	DEVIOCALL
	MOV	DI,[IOCALL.REQSTAT]	; SS override
	.errnz	STERR-8000h
	and	di,di
	js	DevErr
OkDevIO:
	MOV	AX,SS
	MOV	DS,AX

	ASSUME	DS:DOSDATA

 IFDEF  DBCS			;AN000;
	MOV	[InterChar],0	;AN000; reset interim character flag  2/13/KK
	TEST	DI,Ddkey	;AN000; is this a dead key (interim char)? 2/13/KK
	JZ	NotInterim	;AN000; no, flag already reset...	   2/13/KK
	INC	[InterChar]	;AN000; yes, set flag for future	   2/13/KK
NotInterim:			;AN000; 				   2/13/KK
 ENDIF				;AN000;
	CMP	CH,DEVRDND
	JNZ	DNODRD
	MOV	AL,BYTE PTR [IORCHR]
	MOV	[DEVIOBUF],AL

DNODRD: MOV	AH,BYTE PTR [IOCALL.REQSTAT+1]
	NOT	AH			; Zero = busy, not zero = ready
	AND	AH,STBUI SHR 8

QuickReturn:				;AN000; 2/13/KK
	restore_world
ASSUME	DS:NOTHING

	; SR;
	; We return ax = -1 if the user failed on I24. This is the case if 
	; IoStatFail = -1 (set after return from the I24)
	;

	pushf
	mov	al,ss:IoStatFail	;assume fail error
	cbw				;sign extend to word
	cmp	ax,-1
	jne	not_fail_ret
	inc	ss:IoStatFail
	popf
	ret
not_fail_ret:

	MOV	AX,WORD PTR [DEVIOBUF]	;ss override
	popf
	return

;IOTOFILEJ:
;	JMP	SHORT IOTOFILE
 IFDEF  DBCS				;AN000;
;------------------------------ Start of DBCS 2/13/KK
CHKERROUT:				;AN000;
	MOV	DS, DX			;AN000;
	TESTB	[SI].SF_FLAGS, devid_device_con_out	;AN000; output to console ?
	JNZ	GOOD			;AN000; yes
	CMP	CL, 01			;AN000; write interim ?
	JNZ	GOOD			;AN000; no,
	POP	CX			;AN000;
	JMP	SHORT QuickReturn	;AN000; avoid writting interims to other than
					;AN000; console device
GOOD:					;AN000;
	PUSH	SS			;AN000;
	POP	DS			;AN000;
	JMP	SETIN			;AN000;
;------------------------------ End of DBCS 2/13/KK
 ENDIF					;AN000;
DevErr:
	MOV	AH,CL
	invoke	CHARHARD
	CMP	AL,1
	JNZ	NO_RETRY
	restore_world			;hkn; use macro
	JMP	IOFUNC

NO_RETRY:
	
	;
	; Know user must have wanted Ignore OR Fail.	Make sure device shows ready
	; ready so that DOS doesn't get caught in a status loop when user 
	; simply wants to ignore the error.
	;
	; SR; If fail wanted by user set ax to special value (ax = -1). This 
	; should be checked by the caller on return
	;

					; SS override
	AND	BYTE PTR [IOCALL.REQSTAT+1], NOT (STBUI SHR 8)

	; SR;
	; Check if user failed
	;

	cmp	al,3
	jnz	not_fail
	dec	IoStatFail		;set flag indicating fail on I24
not_fail:
	JMP	OKDevIO

IOTOFILE:
ASSUME	DS:NOTHING
	OR	AH,AH
	JZ	IOIN
	DEC	AH
	JZ	IOIST
	DEC	AH
	JZ	IOUT
	return				; NON ZERO FLAG FOR OUTPUT STATUS

IOIST:
	PUSH	WORD PTR [SI.sf_position]   ; Save position
	PUSH	WORD PTR [SI.sf_position+2]
	CALL	IOIN
	POP	WORD PTR [SI.sf_position+2] ; Restore position
	POP	WORD PTR [SI.sf_position]
	return

IOUT:
	CALL	SETXADDR
	invoke	DOS_WRITE
	CALL	RESTXADDR		; If you change this into a jmp don't
	return				; come crying to me when things don't
					; work ARR

IOIN:
	CALL	SETXADDR

					; SS override for DOS34_FLAG
	OR	[DOS34_FLAG],Disable_EOF_I24   ;AN000;
	invoke	DOS_READ
	AND	[DOS34_FLAG],NO_Disable_EOF_I24   ;AN000;
	OR	CX,CX			; Check EOF
	CALL	RESTXADDR

					; SS override
	MOV	AL,[DEVIOBUF]		; Get byte from trans addr
	retnz
	MOV	AL,1AH			; ^Z if no bytes
	return

SETXADDR:

					; SS override
	POP	WORD PTR [CALLSCNT]	; Return address

	save_world			;hkn; use macro

					; SS override for DMAADD and THISSFT
	PUSH	WORD PTR [DMAADD]	; Save Disk trans addr
	PUSH	WORD PTR [DMAADD+2]
	MOV	WORD PTR [THISSFT+2],DS

	Context DS
	MOV	WORD PTR [THISSFT],SI	; Finish setting SFT pointer
	MOV	CX,WORD PTR [IOXAD+2]
	MOV	WORD PTR [DMAADD+2],CX
	MOV	CX,WORD PTR [IOXAD]
	MOV	WORD PTR [DMAADD],CX	; Set byte trans addr
	MOV	CX,[IOSCNT]		; ioscnt specifies length of buffer
	JMP	SHORT RESTRET		; RETURN ADDRESS

RESTXADDR:
	DOSAssume   <DS>,"RestXAddr"
	POP	WORD PTR [CALLSCNT]	; Return address
	POP	WORD PTR [DMAADD+2]	; Restore Disk trans addr
	POP	WORD PTR [DMAADD]

	restore_world			; use macro

ASSUME	DS:NOTHING

					; SS override
RESTRET:JMP	WORD PTR [CALLSCNT]	; Return address
EndProc IOFUNC


DOSCODE ENDS
END
