	TITLE	DIRCALL - Directory operations
	NAME	DirCall

;**	Directory operation entry points
;
;	DOS_CHDIR
;

	include	version.inc
	include	dosseg.inc
	include	dossym.inc
	include	devsym.inc
	include	curdir.inc
	include	fastopen.inc
	include	fastxxxx.inc
	include	mult.inc
	I_Need	NoSetDir,BYTE
	I_Need	SAttrib,BYTE
	I_Need	FastOpenFlg,BYTE
	I_Need	DirStart,WORD
DOSCODE	SEGMENT
	ASSUME	CS:DOSCODE,DS:DOSDATA,SS:DOSDATA
	PUBLIC	NODEACCERRJ,NOTDIRPATH
NODEACCERRJ:
	MOV	AX,error_access_denied
	STC
	Invoke	LcritDisk
	return
;---------------------------------------------------------------------------
; Procedure Name : DOS_ChDir
;
; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used May not be NUL
; Function:
;	Validate the path for potential new current directory
; Returns:
;	NOTE:
;	    [SATTRIB] is modified by this call
;	Carry Clear
;	    CX is cluster number of the DIR, LOCAL CDS ONLY
;		Caller must NOT set ID fields on a NET CDS.
;	Carry Set
;	    AX is error code
;		error_path_not_found
;			Bad path
;		error_access_denied
;			device or file name
; DS preserved, Others destroyed
;----------------------------------------------------------------------------

;hkn; called from path.asm and dir2.asm. DS already set up.

	ASSUME	ES:NOTHING
procedure   DOS_CHDIR,NEAR
	DOSAssume   <DS>,"DOS_Chdir"

	Invoke	TestNet
	JNC	LOCAL_CHDIR
IF NOT Installed
	transfer NET_CHDIR
ELSE
	MOV	AX,(multNET SHL 8) OR 5
	INT	2FH
	return
ENDIF

LOCAL_CHDIR:
	Invoke	EcritDisk
	TEST	ES:[DI.curdir_flags],curdir_splice ;PTM.
	JZ	nojoin				   ;PTM.
	MOV	ES:[DI.curdir_ID],0FFFFH	   ;PTM.
nojoin:
	MOV	[NoSetDir],FALSE
	MOV	[SATTRIB],attr_directory+attr_system+attr_hidden
				; Dir calls can find these
; DOS 3.3  6/24/86 FastOpen

	OR	[FastOpenFlg],FastOpen_Set	   ; set fastopen flag
	invoke	GetPath
	PUSHF									;AN000;
	AND	[FastOpenFlg],Fast_yes		   ; clear it all		;AC000;
	POPF									;AN000;
; DOS 3.3  6/24/86 FastOpen
	MOV	AX,error_path_not_found
	JC	ChDirDone
	JNZ	SHORT NOTDIRPATH	; Path not a DIR
	MOV	CX,[DIRSTART]	; Get cluster number
	CLC
ChDirDone:
	Invoke	LcritDisk
	return

EndProc DOS_CHDIR
NOTDIRPATH:
	JMP	NEAR PTR NODEACCERRJ
DOSCODE	ENDS
	END
