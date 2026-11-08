	TITLE	DELETE - Directory cache operations
	NAME	Delete

	include version.inc
	include dosseg.inc
	include dossym.inc
	include fastopen.inc
	include fastxxxx.inc

	i_need WFP_Start,WORD
	i_need REN_WFP,WORD
	i_need NAME1,BYTE
	i_need FastTable,BYTE

DOSCODE SEGMENT
	ASSUME SS:DOSDATA,CS:DOSCODE

Break	<FastOpen_Delete - delete dir info in fastopen>
;--------------------------------------------------------------------------
; Procedure Name : FastOpen_Delete
; Inputs:
;	None
; Function:
;	Call FastOpen to delete the dir info.
; Outputs:
;	None
;
;---------------------------------------------------------------------------

procedure  FastOpen_Delete,NEAR
	PUSHF			; save flag
	PUSH	SI		; save registers
	PUSH	BX
	PUSH	AX

;hkn; SS override
	MOV	SI,[WFP_Start]			       ; ds:si points to path name
	MOV	AL,FONC_delete			       ; al = 3
fastinvoke:

;hkn; FastTable is in DOSDATA
	MOV	BX,OFFSET DOSDATA:FastTable + 2
	CALL	DWORD PTR [BX]			       ; call fastopen

	POP	AX		; restore registers
	POP	BX
	POP	SI
	POPF			; restore flag
	return
EndProc FastOpen_Delete


Break	<FastOpen_Rename - Rename directory>	   ; PTR 5622

;------------------------------------------------------------------------------
;
; PROCEDURE Name : FastOpen_Rename
;
; Inputs:
;	 REN_WFP   = Path Name
;	 NAME1	   = New Name
; Function:
;	Call FastOpen to rename the dir entry in the cache
; Outputs:
;	None
;------------------------------------------------------------------------------

PROCEDURE FastOpen_Rename,NEAR

	PUSHF			;AN001 save flag
	PUSH	SI		;;AN001  save registers
	PUSH	DI		;AN001
	PUSH	BX		;AN001
	PUSH	AX		;AN001

;hkn; SS override
	MOV	SI,[REN_WFP]	;AN001		     ;;AN001  ds:si-->Path name addrs

;hkn; NAME1 is in DOSDATA
	MOV	DI,OFFSET DOSDATA:NAME1	     ;;AN001  ds:di-->New name addrs
;	MOV	AL,FONC_Rename			     ;;AN001  al = 3
	MOV	AL,6				     ;;AN001  al = 3

;hkn; FastTable is in DOSDATA
	MOV	BX,OFFSET DOSDATA:FastTable + 2
	CALL	DWORD PTR [BX]			     ;;AN001  call fastopen

	POP	AX		; restore registers  ;AN001
	POP	BX				     ;AN001
	POP	DI				     ;AN001
	POP	SI				     ;AN001
	POPF			; restore flag	     ;AN001
	return					     ;AN001
EndProc FastOpen_Rename


Break	<FastOpen_Update - update dir info in fastopen>
;-----------------------------------------------------------------------------
;
; Procedure Name : FastOpen_Update
;
; Inputs:
;	DL     drive number (A=0,B=1,,,)
;	CX     first cluster #
;	AH     0 updates dir entry
;	       1 updates CLUSNUM  , BP = new CLUSNUM
;	ES:DI  directory entry
; Function:
;	Call FastOpen to update the dir info.
; Outputs:
;	None
;
;----------------------------------------------------------------------------

procedure  FastOpen_Update,NEAR
	PUSHF			; save flag
	PUSH	SI
	PUSH	BX		; save regs
	PUSH	AX

	MOV	AL,FONC_update			       ; al = 4
	JMP	fastinvoke

EndProc FastOpen_Update




ASSUME	DS:NOTHING,ES:NOTHING							;AN000;


entry Fast_Dispatch			      ; future fastxxxx entry		;AN000;

;hkn; FastTable is in DOSDATA
	MOV	SI,OFFSET DOSDATA:FastTable + 2	; index to the		;AN000;


;hkn; use SS override
	CALL	DWORD PTR SS:[SI]			; RMFD call fastopen
	return

;
DOSCODE ENDS
	END
