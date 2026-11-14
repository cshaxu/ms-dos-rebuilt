attr_ignore EQU 061h
attr_volume_id EQU 08h
Dir_First EQU 01Ah
Dir_Attr EQU 0Bh
Dir_Name EQU 0
DPB_DRIVE EQU 0
DOSDATA SEGMENT
        ORG 0348h
LastEnt dw 0
        ORG 054Bh
Name1 db 0
        ORG 056Bh
Attrib db 0
        ORG 057Bh
VolID db 0
        ORG 057Eh
Creating db 0
DelAll db 0
        ORG 058Ah
ThisDPB dd 0
        ORG 05D8h
EntFree dw 0
EntLast dw 0
        ORG 05E2h
CurBuf dd 0
        ORG 0AACh
DirSave1 dw 7 dup (0)
DOSDATA ENDS
DOSCODE SEGMENT
ASSUME CS:DOSCODE,SS:DOSDATA,DS:DOSDATA
        ORG 079B5h
Search PROC NEAR
FindEntry:
        ASSUME DS:DOSDATA
        call STARTSRCH
	MOV	AL,Attrib
	AND	AL,NOT attr_ignore	; Ignore useless bits
	CMP	AL,attr_volume_id	; Looking for vol ID only ?
	JNZ	NOTVOLSRCH		; No
	CALL	SETROOTSRCH		; Yes force search of root
NOTVOLSRCH:
	CALL	GETENTRY
	JNC	Srch
	JMP	SETESRET
Srch:
	mov	[DirSave1],0
SrchItem:


	PUSH	DS
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING

;	(DS:bx) = directory entry address

	MOV	AH,DIR_NAME[BX]
	MOV	AL,DIR_ATTR[BX]
	CALL	CaptureDir
	JZ	LongNameNext
	OR	AH,AH			; End of directory?
	JZ	FREE

;hkn; SS override
	CMP	AH,DelAll		; Free entry?
	JZ	FREE
	TEST	BYTE PTR DIR_ATTR[BX],attr_volume_id	; Volume ID file?
	JZ	CHKFNAM 		; NO

;hkn; SS override
	INC	BYTE PTR [VOLID]
CHKFNAM:
;	Context ES

;hkn;	ASSUME	ES:DOSGroup
	ASSUME	ES:DOSDATA

	MOV	SI,SS
	MOV	ES,SI
	MOV	SI,BX

;hkn; NAME1 is in DOSDATA
	MOV	DI,OFFSET DOSDATA:NAME1
;;;;; 7/29/86

;hkn; SS override for NAME1
	CMP	BYTE PTR [NAME1],0E5H	 ; special char check
	JNZ	NO_E5
	MOV	BYTE PTR [NAME1],05H
NO_E5:
;;;;; 7/29/86
	CALL	MetaCompare
	JZ	FOUND
	POP	DS
NEXTENT:
        ASSUME DS:DOSDATA

	LES	BP,[THISDPB]
ASSUME	ES:NOTHING
	CALL	NEXTENTRY
	JNC	SRCH
	JMP	SHORT SETESRET

FREE:
	POP	DS
        ASSUME DS:DOSDATA
	MOV	CX,LASTENT
	CMP	CX,ENTFREE
	JAE	TSTALL
	MOV	ENTFREE,CX
TSTALL:
	CMP	AH,DelAll		; At end of directory?
NextEntJ:
	je	LongNameNextNoPop 		; No - continue search
	MOV	[ENTLAST],CX
	STC
	JMP	SHORT SETESRET

LongNameNext:
	POP	DS
LongNameNextNoPop:
	LES	BP,[THISDPB]
	CALL	NEXTENTRY
	JNC	SrchItem
	JMP	SHORT SETESRET

FOUND:
;
; We have a file with a matching name.	We must now consider the attributes:
; ATTRIB	Action
; ------	------
; Volume_ID	Is Volume_ID in test?
; Otherwise	If no create then Is ATTRIB+extra superset of test?
;		If create then Is ATTRIB equal to test?
;
	MOV	CH,[SI] 		; Attributes of file
	POP	DS
        ASSUME DS:DOSDATA
	MOV	AH,Attrib		; Attributes of search
	AND	AH,NOT attr_ignore
	LEA	SI,[SI+Dir_First-Dir_Attr]  ; point to firclus field
	TEST	CH,attr_volume_id	; Volume ID file?
	JZ	check_one_volume_id	; Nope check other attributes
	TEST	AH,attr_volume_id	; Can we find Volume ID?
	JZ	NEXTENT		; Nope, (not even $FCB_CREATE)
	XOR	AH,AH			; Set zero flag for $FCB_CREATE
	JMP	SHORT RETFF		; Found Volume ID
check_one_volume_id:
	CMP	AH,attr_volume_id	; Looking only for Volume ID?
	JZ	NEXTENT		; Yes, continue search
        call MatchAttributes
	JZ	RETFF
	TEST	BYTE PTR [CREATING],-1	; Pass back mismatch if creating
	JZ	NEXTENT		; Otherwise continue searching
RETFF:
	LES	BP,[THISDPB]
	MOV	AH,ES:[BP.dpb_drive]
SETESRET:
	PUSH	SS
	POP	ES
	PUSH	[ENTLAST]
	POP	[DirSave1+12]
	JNC	SearchDone
	MOV	[DirSave1],0
SearchDone:
        ret
Search ENDP
        ORG 07A8Eh
NextEntry: ret
        ORG 07AEAh
GetEntry: ret
        ORG 07B62h
SetRootSrch: ret
        ORG 07F4Eh
StartSrch: ret
        ORG 07F62h
MatchAttributes: ret
        ORG 0AA7Ch
CaptureDir: ret
        ORG 0B65Dh
MetaCompare: ret
DOSCODE ENDS
END
