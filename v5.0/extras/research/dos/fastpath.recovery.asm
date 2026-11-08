; Retained OpenNT FastOpen lookup/insert code, target-layout candidate.
; Physical path recovery experiment; not production-linked.
	TITLE	DIR2 - Directory and path cracking
	NAME	Dir2

;**	Main Path cracking routines, low level search routines and device
;	  name detection routines
;
;	GETPATH
;	GetPathNoSet
;	CHKDEV
;	ROOTPATH
;	FINDPATH
;	StartSrch
;	MatchAttributes
;	DEVNAME
;	Build_device_ent
;	Validate_CDS
;	CheckThisDevice
;
;	Revision history:
;
;		A000  version 4.00  Jan. 1988
;		A001  PTM 3564 -- search using fastopen
;
; 		M026 - set Attrib before invoking devname. 9/17/90

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	include dossym.inc
	include devsym.inc
	include fastopen.inc
	include curdir.inc
	include dpb.inc
	include dossvc.inc
	.cref
	.list


	i_need	NoSetDir,BYTE
	i_need	EntFree,WORD
	i_need	DirStart,WORD
	i_need	LastEnt,WORD
	i_need	WFP_START,WORD
	i_need	CURR_DIR_END,WORD
	i_need	CurBuf,DWORD
	i_need	THISCDS,DWORD
	i_need	Attrib,BYTE
	i_need	SAttrib,BYTE
	i_need	VolID,BYTE
	i_need	Name1,BYTE
	i_need	ThisDPB,DWORD
	i_need	EntLast,WORD
	i_need	Creating,BYTE
	i_need	NULDEV,DWORD
	i_need	DEVPT,DWORD
	i_need	DEVFCB,BYTE
	i_need	ALLOWED,BYTE
	i_need	EXTERR_LOCUS,BYTE
	I_need	FastOpenFlg,BYTE	  ;DOS 3.3
	I_need	FastOpenTable,BYTE	  ;DOS 3.3
	I_need	Dir_Info_Buff,BYTE	  ;DOS 3.3
	I_need	FastOpen_Ext_Info,BYTE	  ;DOS 3.3
	I_need	CLUSNUM,WORD		  ;DOS 3.3
	I_need	Next_Element_Start,WORD   ;DOS 3.3
	I_need	HIGH_SECTOR,WORD	  ;AN000;>32mb
	I_need	DOS34_FLAG,WORD 	  ;AN000;>32mb
	I_need	CURDRV, BYTE


DOSCODE	Segment
	ASSUME	SS:DOSDATA,CS:DOSCODE

EXTRN MatchAttributes:NEAR
procedure LookupPath,NEAR

;	PUSH	AX

;hkn; SS override
	TEST	[FastOpenFlg],FastOpen_Set	    ; flg is set in DOSPEN
	JNZ	FASTINST			    ; and this routine is
NOLOOK:
	JMP	NOLOOKUP			    ; executed once
FASTINST:

;hkn; SS override
	TEST	[FastOpenFlg],No_Lookup 	    ; no more lookup?
	JNZ	NOLOOK				    ; yes

	MOV	BX,OFFSET DOSDATA:FastOpenTable    ; get fastopen related tab

;hkn; SS override
	MOV	SI,[Wfp_Start]			    ; si points to path name
	MOV	DI,OFFSET DOSDATA:Dir_Info_Buff
	MOV	CX,OFFSET DOSDATA:FastOpen_Ext_Info
	MOV	AL,FONC_look_up 		    ; al = 1
	PUSH	DS
	POP	ES

;hkn; SS override
	CALL	DWORD PTR [BX.FASTOPEN_NAME_CACHING] ;call fastopen
	JC	NOTFOUND			    ; fastopen not in memory

	LEA	BX,[SI-2]

;hkn; SS override
	CMP	BX,[Wfp_Start]			    ; path found ?
	JZ	NOTFOUND			    ; no
						    ; fully or partially found
	CMP	BYTE PTR [SI],0 		    ;AN000;FO.
	JNZ	parfnd				    ;AN000;FO.; partiallyfound
	PUSH	CX				    ;AN000;FO.; is attribute matched ?

;hkn; SS override for attrib/sattrib
	MOV	CL,Attrib			    ;AN000;FO.;
	MOV	CH,Sattrib			    ;AN000;FO.; attrib=sattrib
	MOV	Attrib,CH			    ;AN000;FO.;
	MOV	CH,ES:[DI.dir_attr]		    ;AN000;FO.;
	invoke	Matchattributes 		    ;AN000;FO.;
;;;	MOV	Attrib,CL			    ;AN001;FO.; retore attrib
	POP	CX				    ;AN000;FO.;
	JNZ	NOLOOKUP			    ;AN000;FO.; not matched
parfnd:

;hkn; SS override
	MOV	[Next_Element_Start],SI 		   ; save si
	MOV	BX,CX
	MOV	AX,[BX.FEI_lastent]		    ;AN000;;FO. restore lastentry

;hkn; SS override for LASTENT, DIRSTART, CLUSNUM
	MOV	[LASTENT],AX			    ;AN000;;FO.
	MOV	AX,[BX.FEI_dirstart]		    ;AN001;;FO. restore dirstart
	MOV	[DIRSTART],AX			    ;AN001;;FO.
	MOV	AX,[BX.FEI_clusnum]		    ; restore next cluster num
	MOV	[CLUSNUM],AX			    ;

	PUSH	ES				    ; save ES

;hkn; SS override
	LES	BX,[THISDPB]			    ; put drive id
	MOV	AH,ES:[BX.dpb_drive]		    ; in AH for DOOPEN
	POP	ES				    ; pop ES
;SR;
; We cannot have a root dir if we have come here. So, we zero out CurBuf to
;indicate it is not a root dir
;
	mov	word ptr CurBuf,0			;indicate not root dir

	MOV	WORD PTR [CURBUF+2],ES		    ; [curbuf+2].bx points to
	MOV	BX,DI				    ; start of entry
	LEA	SI,[DI.dir_first]		    ; [curbuf+2]:si points to
						    ; dir_first field in the
						    ; dir entry

;hkn; SS override for FastOpenFlg
	OR	[FastOpenFlg],Lookup_Success + set_for_search
;	POP	AX
	RET
NOTFOUND:
	CMP	AX,-1				    ; not in memory ?
	JNZ	Partial_Success 		    ; yes, in memory
	MOV	[FastOpenFlg],0 		    ; no more fastopen
Partial_Success:
	AND	[FastOpenFlg],Special_Fill_Reset
NOLOOKUP:
;	POP	AX
	STC
	RET
EndProc LookupPath

BREAK <InsertPath - call fastopen to insert dir entry info>
;-----------------------------------------------------------------------------
;
; Procedure Name : InsertPath
; Input:  FastOpen_Set flag set when from DOSOPEN otherwise 0
;	  Lookup_Success flag set when got dir entry info from FASTOPEN
;	  DS = DOSDATA
; Output: FastOPen_Ext_Info is set and path dir info is inserted
;
;-----------------------------------------------------------------------------
procedure InsertPath,NEAR

	PUSHF

;hkn; SS override for FastOpenFlag
	TEST   [FastOpenFlg],FastOpen_Set     ;only DOSOPEN can take advantage of
	JZ     GET_NEXT_ELEMENT 	      ; the FastOpen
	TEST   [FastOpenFlg],Lookup_Success   ; Lookup just happened
	JZ     INSERT_DIR_INFO		      ; no
	AND    [FastOpenFlg],Lookup_Reset     ; we got dir info from fastopen so
	MOV    DI,[Next_Element_Start]	      ; no need to insert it again
	JMP    short GET_NEXT2
INSERT_DIR_INFO:			      ; save registers
	PUSH   DS
	PUSH   ES
	PUSH   BX
	PUSH   SI
	PUSH   DI
	PUSH   CX
	PUSH   AX

;hkn; SS override
	LDS    DI,[CURBUF]		; DS:DI -> buffer header
ASSUME DS:NOTHING
	MOV    SI,OFFSET DOSDATA:FastOpen_Ext_Info
	MOV    AX,WORD PTR [DI.buf_sector]  ; get directory sector
	MOV    WORD PTR SS:[SI.FEI_dirsec],AX ;AN000; >32mb save dir sector
	MOV    AX,WORD PTR [DI.buf_sector+2]  ;AN000; >32mb

;hkn; SS is DOSDATA
	context DS
	MOV    WORD PTR [SI.FEI_dirsec+2],AX  ;AN000;>32mb save high dir sector
	MOV    AX,[CLUSNUM]		; save next cluster number
	MOV    [SI.FEI_clusnum],AX
	MOV    AX,[LASTENT]		;AN000;FO. save lastentry for search first
	MOV    [SI.FEI_lastent],AX	;AN000;FO.
	MOV    AX,[DIRSTART]		;AN001;FO. save  for search first
	MOV    [SI.FEI_dirstart],AX	;AN001;FO.

	MOV    AX,BX
	ADD    DI,BUFINSIZ		; DS:DI -> start of data in buffer
	SUB    AX,DI			; AX=BX relative to start of sector
	MOV    CL,SIZE dir_entry
;invoke debug_DOS
	DIV    CL
	MOV    [SI.FEI_dirpos],AL	; save directory entry # in buffer

	PUSH   DS
	POP    ES

	MOV    DS,WORD PTR [CURBUF+2]
	MOV    DI,BX			; DS:DI -> dir entry info
ASSUME DS:NOTHING
	CMP    DS:[DI.dir_first],0	; never insert info when file is empty
	JZ     SKIP_INSERT		; e.g. newly created file

	PUSH   SI			; ES:BX -> extended info
	POP    BX

	MOV    AL,FONC_insert		; call fastopen insert operation
	MOV    SI,OFFSET DOSDATA:FastOpenTable
	CALL   DWORD PTR ES:[SI.FASTOPEN_NAME_CACHING]

	CLC
SKIP_INSERT:
	POP    AX
	POP    CX			; restore registers
	POP    DI
	POP    SI
	POP    BX
	POP    ES
	POP    DS
GET_NEXT2:
	OR     [FastOpenFlg],No_Lookup	      ; we got dir info from fastopen so
GET_NEXT_ELEMENT:
	POPF
	RET
EndProc InsertPath
DOSCODE ENDS
END
