; DOS 5 bounded disk recovery, integrated in the kernel link.
; Comparative source: DOS 6 disk.asm / disk2.asm, bounded procedures below.
include version.inc
include dosseg.inc
include dossym.inc
include devsym.inc
include dpb.inc
I_need ReadOp,BYTE
I_need CALLSCNT,WORD
I_need DEVCALL,BYTE
I_need CALLVIDRW,DWORD
I_need EXTERRPT,DWORD
DOSCODE SEGMENT
ASSUME SS:DOSDATA,CS:DOSCODE,DS:NOTHING,ES:NOTHING
procedure   DskRead,NEAR

	Assert	ISDPB,<ES,BP>,"DskRead"
	PUSH	CX
	MOV	AH,ES:[BP.dpb_media]
	MOV	AL,ES:[BP.dpb_UNIT]
	PUSH	BX
	PUSH	ES
	invoke	SETREAD
	JMP	short DODSKOP

Break	<DWRITE -- SEE ABOUT WRITING>
;--------------------------------------------------------------------------
;
; Procedure Name : DWRITE
;
; Inputs:
;	DS:BX = Transfer address
;	CX = Number of sectors
;	[HIGH_SECTOR] = Absolute record number (HIGH)
;	DX = Absolute record number	       (LOW)
;	ES:BP = Base of drive parameters
;	[ALLOWED] must be set in case HARDERR called
; Function:
;	Calls BIOS to perform disk write. If BIOS reports
;	errors, will call HARDERRRW for further action.
; Output:
;	Carry set if error (currently, user FAILed to I 24)
; BP preserved. All other registers destroyed.
;----------------------------------------------------------------------------


	entry	DWRITE
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DWrite"
	CALL	DSKWRITE
	jz	ret_label	; Carry clear (retz)

;hkn; SS override
	MOV	BYTE PTR [READOP],1
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DWRITE
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	NO_CAR2 	; Ignore
	STC
NO_CAR2:

ret_label:
	return

Break	<DSKWRITE -- PHYSICAL DISK WRITE>
;---------------------------------------------------------------------------
;
; Procedure Name : DSKWRITE
;
; Inputs:
;	DS:BX = Transfer addr
;	CX = Number of sectors
;	DX = Absolute record number	       (LOW)
;	[HIGH_SECTOR] = Absolute record number (HIGH)
;	ES:BP = Base of drive parameters
; Function:
;	Call BIOS to perform disk read
; Outputs:
;	DI = CX on entry
;	CX = Number of sectors unsuccessfully transfered
;	AX = Status word as returned by BIOS (error code in AL if error)
;	Zero set if OK (from BIOS) (carry clear)
;	Zero clear if error (carry clear)
; SI Destroyed, others preserved
;
;----------------------------------------------------------------------------

	entry	DSKWRITE
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DskWrite"
	PUSH	CX
	MOV	AH,ES:[BP.dpb_media]
	MOV	AL,ES:[BP.dpb_UNIT]
	PUSH	BX
	PUSH	ES
	invoke	SETWRITE
DODSKOP:
	MOV	CX,DS		; Save DS
	POP	DS		; DS:BP points to DPB
	PUSH	DS
	LDS	SI,DS:[BP.dpb_driver_addr]
	invoke	DEVIOCALL2
	MOV	DS,CX		; Restore DS
	POP	ES		; Restore ES
	POP	BX

;hkn; SS override
	MOV	CX,[CALLSCNT]	; Number of sectors transferred
	POP	DI
	SUB	CX,DI
	NEG	CX		; Number of sectors not transferred

;hkn; SS override
	MOV	AX,[DEVCALL.REQSTAT]
	test	AX,STERR
	return
EndProc DskRead



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
DOSCODE ENDS
END
