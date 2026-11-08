; Bounded DOS 5 recovery of DOS_CHDIR from comparative DOS 6 dircall.asm.
; Other dircall procedures remain to be recovered. Common error tail is
; temporarily adjacent; its conditional branch is explicitly layout-relative.
TITLE DIRCALL - physical change-directory validation
include version.inc
include dosseg.inc
include dossym.inc
include devsym.inc
include curdir.inc
include fastopen.inc
include fastxxxx.inc
include mult.inc
I_Need NoSetDir,BYTE
I_Need SAttrib,BYTE
I_Need FastOpenFlg,BYTE
I_Need DirStart,WORD
DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:DOSDATA,SS:DOSDATA
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
	Invoke EcritDisk
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
	Invoke LcritDisk
	return

EndProc DOS_CHDIR
NOTDIRPATH:
    JMP NODEACCERRJ
NODEACCERRJ:
    MOV AX,error_access_denied
    STC
    Invoke LcritDisk
    return
DOSCODE ENDS
END
