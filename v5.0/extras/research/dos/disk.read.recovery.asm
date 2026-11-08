; DOS 5 disk recovery candidate, not yet production linked.
; Comparative source: DOS 6 disk.asm / disk2.asm, bounded procedures below.
include version.inc
include dosseg.inc
include dossym.inc
include devsym.inc
include dpb.inc
I_need ALLOWED,BYTE
I_need HIGH_SECTOR,WORD
I_need ReadOp,BYTE
DOSCODE SEGMENT
ASSUME SS:DOSDATA,CS:DOSCODE,DS:NOTHING,ES:NOTHING
; Prior DirRead return is shared by target DREAD's retz.
return
procedure   FATSecRd,NEAR

	Assert	    ISDPB,<ES,BP>,"FATSecRd"

;hkn; SS override
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL
	MOV	DI,CX
	MOV	CL,ES:[BP.dpb_FAT_count]
	MOV	AX,ES:[BP.dpb_FAT_size] 	;>32mb
;	XOR	AH,AH
	XOR	CH,CH				;>32mb
	PUSH	DX
NXTFAT:

;hkn; SS override
	MOV	[HIGH_SECTOR],0       ;>32mb FAT sectors cannot exceed
	PUSH	CX		      ;>32mb
	PUSH	AX
	MOV	CX,DI
	invoke	DSKREAD
	POP	AX
	POP	CX
	JZ	RET41P		; Carry clear
	ADD	DX,AX
	LOOP	NXTFAT
	POP	DX
	MOV	CX,DI

; NOTE FALL THROUGH

Break	<DREAD -- DO A DISK READ>
;---------------------------------------------------------------------------
;
; Procedure Name : DREAD
;
; Inputs:
;	DS:BX = Transfer address
;	CX = Number of sectors
;	DX = Absolute record number	      (LOW)
;	[HIGH_SECTOR]= Absolute record number (HIGH)
;	ES:BP = Base of drive parameters
;	[ALLOWED] must be set in case call to HARDERR needed
; Function:
;	Calls BIOS to perform disk read. If BIOS reports
;	errors, will call HARDERRRW for further action.
; Outputs:
;	Carry set if error (currently user FAILED to INT 24)
; DS,ES:BP preserved. All other registers destroyed.
;---------------------------------------------------------------------------

	entry	DREAD
ASSUME	DS:NOTHING,ES:NOTHING

	Assert	ISDPB,<ES,BP>,"DREAD"
	invoke	DSKREAD
	retz			; Carry clear

;hkn; SS override
	MOV	BYTE PTR [READOP],0
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DREAD
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	NO_CAR		; Ignore
	STC
NO_CAR:
	return

RET41P: POP	DX
	return
EndProc FATSecRd
DOSCODE ENDS
END
