	TITLE	ROM - Low level disk routines
	NAME	Rom

;**	Physical sector calculation
;
;	FIGREC
;
	include	version.inc
	include	dosseg.inc
	include	dossym.inc
	include	devsym.inc
	include	dpb.inc
	I_need	HIGH_SECTOR,WORD
DOSCODE	SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE,DS:NOTHING,ES:NOTHING
Break   <RELEASE -- DEASSIGN DISK SPACE>
;---------------------------------------------------------------------------
;
; Procedure Name : RELEASE
;
; Inputs:
;       BX = Cluster in file
;       ES:BP = Base of drive parameters
; Function:
;       Frees cluster chain starting with [BX]
;       Carry set if error (currently user FAILed to I 24)
; AX,BX,DX,DI all destroyed. Other registers unchanged.
;
;-----------------------------------------------------------------------------

	return
procedure RELEASE,NEAR
	DOSAssume   <DS>,"Release"

        XOR     DX,DX
entry   RELBLKS
	DOSAssume   <DS>,"RelBlks"
        Assert      ISDPB,<ES,BP>,"RelBlks"

;   Enter here with DX=0FFFFH to put an end-of-file mark in the first cluster
;   and free the rest in the chain.

        invoke  UNPACK
	retc
	retz
        MOV     AX,DI
        PUSH    DX
        invoke  PACK
        POP     DX
	retc
        OR      DX,DX
        JNZ     NO_DEALLOC              ; Was putting EOF mark
        CMP     ES:[BP.dpb_free_cnt],-1 ; Free count valid?
        JZ      NO_DEALLOC              ; No
        INC     ES:[BP.dpb_free_cnt]    ; Increase free count by 1
NO_DEALLOC:
        MOV     BX,AX
        dec     ax              ; check for "1"
	retz	; is last cluster of incomplete chain
        Invoke  IsEOF
        JB      RELEASE         ; Carry clear if JMP not taken

RET12:
	return
EndProc RELEASE
Break   <GETEOF -- Find the end of a file>
;------------------------------------------------------------------------
;
; Procedure Name : GETEOF
;
; Inputs:
;       ES:BP Points to DPB
;       BX = Cluster in a file
;       DS = CS
; Outputs:
;       BX = Last cluster in the file
;       Carry set if error (currently user FAILed to I 24)
; DI destroyed. No other registers affected.
;
;--------------------------------------------------------------------------

procedure GETEOF,NEAR
	DOSAssume   <DS>,"GetEOF"

	Assert	ISDPB,<ES,BP>,"GetEof"
        invoke  UNPACK
        retc
        PUSH    BX
        MOV     BX,DI
        Invoke  IsEOF
        POP     BX
        JAE     RET12           ; Carry clear if jmp
        MOV     BX,DI
        JMP     GETEOF

EndProc GETEOF

DOSCODE ENDS
	END
