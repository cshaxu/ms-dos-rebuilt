; Retained OpenNT validation body; target-layout candidate only.
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

Procedure   ValidateCDS,NEAR
	ASSUME	CS:DOSCODE,SS:DOSDATA
; Restore retained OpenNT physical validation body (DOS 5 target).
Public DIR2001S,DIR2001E
DIR2001S:
	LocalVar    Temp,WORD
	LocalVar    SaveCDS,DWORD
DIR2001E:
	Enter
	MOV	Temp,DI

;hkn; SS override
	LDS	SI,ThisCDS
	MOV	SaveCDSL,SI
	MOV	SaveCDSH,DS
	Invoke EcritDisk
	TEST	[SI].curdir_flags,curdir_isnet	; Clears carry
	JZ	DoSplice
	JMP	FatFail
DoSplice:
	XOR	DL,DL
	XCHG	DL,NoSetDir

;hkn; SS is DOSDATA
	Context ES
	Invoke	FStrcpy
	MOV	SI,Temp

;hkn; SS is DOSDATA
	Context DS
	Invoke	Splice
	ASSUME	DS:NOTHING

 ;hkn; SS is DOSDATA
	Context DS			;   FatReadCDS (ThisCDS);
	MOV	NoSetDir,DL
	LES	DI,ThisCDS
	SAVE	<BP>
	Invoke	FatRead_CDS
	RESTORE <BP>
	JC	FatFail
	LDS	SI,ThisCDS		;   if (ThisCDS->ID == -1) {
	ASSUME	DS:NOTHING
	CMP	[SI].curdir_ID,-1
	JNZ	RestoreCDS

;hkn; SS is DOSDATA
	Context ES

;hkn; SS override
	SAVE	<wfp_Start>		;	t = wfp_Start;
	CMP	SI,SaveCDSL		; if not spliced
	JNZ	DoChdir
	MOV	DI,Temp

;hkn; SS override
	MOV	wfp_Start,DI		;	wfp_start = d;
	Invoke	FStrCpy 		;	strcpy (d, ThisCDS->Text);
DoChdir:

;hkn; SS is DOSDATA
	Context DS
	SAVE	<<WORD PTR SAttrib>,BP> ;	c = DOSChDir ();
	Invoke	DOS_ChDir
	RESTORE <BP,BX,wfp_start>	;	wfp_Start = t;
	MOV	SAttrib,BL
	LDS	SI,SaveCDS
	ASSUME	DS:NOTHING
	JNC	SetCluster		;	if (c == -1) {

;hkn; SS override for THISCDS
	MOV	WORD PTR ThisCDS,SI	;	    ThisCDS = TmpCDS;
	MOV	WORD PTR ThisCDS+2,DS
	XOR	CX,CX			;	    TmpCDS->text[3] = c = 0;
	MOV	[SI+3],CL		;	    }
SetCluster:
	MOV	[SI].curdir_ID,-1	;	TmpCDS->ID = -1;
	LDS	SI,ThisCDS		;	ThisCDS->ID = c;
	TEST	[SI].curdir_flags,curdir_splice      ;AN000;;MS.  for Join and Subst
	JZ	setdirclus			     ;AN000;;MS.
	MOV	CX,-1				     ;AN000;;MS.
setdirclus:
	MOV	[SI].curdir_ID,CX	;	}
RestoreCDS:

	LES	DI,SaveCDS
	MOV	WORD PTR ThisCDS,DI
	MOV	WORD PTR ThisCDS+2,ES
	CLC
FatFail:
	Invoke LcritDisk

	LES	DI,SaveCDS
	Leave
	return
EndProc ValidateCDS
DOSCODE ENDS
END
