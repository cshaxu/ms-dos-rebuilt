	TITLE	SHARING ROUTINES - Routines for file Sharing
	NAME	SHARE

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	Share.asm - File Sharing Routines
;
;

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include dpb.inc
	.cref
	.list

AsmVars <IBM, Installed>

Installed = True

	i_need  THISDPB,DWORD
	i_need  EXTERR,WORD
	i_need  ReadOp,BYTE
	i_need  ThisSFT,DWORD
	i_need  ALLOWED,BYTE
	i_need  HIGH_SECTOR,WORD

DOSCODE SEGMENT
	ASSUME  SS:DOSDATA,CS:DOSCODE

; Inputs:
;       [THISDPB] Set
;       AX has error code
; Function:
;       Handle Sharing errors
; Outputs:
;       Carry set if user says FAIL, causes error_sharing_violation
;       Carry clear if user wants a retry
;
; DS, ES, DI preserved, others destroyed

	ASSUME  ES:NOTHING
procedure   SHARE_VIOLATION,NEAR
	DOSAssume   <DS>,"Share_Viol"

	PUSH    DS
	PUSH    ES
	PUSH    DI
	MOV     [READOP],0                      ; All share errors are reading
        LES     DI,ThisSFT
        TEST    ES:[DI].sf_flags,DEVID_ISDEV ; Character device?
        JZ      share_disk_error
        OR      AH,80h                  ; Mark a character-device error
        LDS     SI,ES:[DI].sf_devptr
        MOV     DI,AX
        invoke  CHARHARD
        JMP     SHORT share_error_done
share_disk_error:
	MOV     [ALLOWED],allowed_FAIL + allowed_RETRY
	LES     BP,[THISDPB]
	MOV     DI,1                            ; Fake some registers
	MOV     CX,DI
	CMP     ES:[BP.dpb_fat_size],0
	JZ      share_fat32_error
	MOV     [HIGH_SECTOR],0
	MOV     DX,ES:[BP.dpb_dir_sector]
	JMP     SHORT share_hard_error
share_fat32_error:
	MOV     DX,WORD PTR ES:[BP.dpb_first_sector32+2]
	MOV     [HIGH_SECTOR],DX
	MOV     DX,WORD PTR ES:[BP.dpb_first_sector32]
share_hard_error:
	invoke  HARDERR
share_error_done:
	POP     DI
	POP     ES
	POP     DS
	CMP     AL,1
	JNZ     SHORT ShareFail
	return                  ; 1 = retry, carry clear
ShareFail:
	STC
	return

EndProc SHARE_VIOLATION

DOSCODE    ENDS
    END
