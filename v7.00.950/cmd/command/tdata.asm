	page ,132
;	SCCSID = @(#)tdata.asm	4.3 85/05/17
;	SCCSID = @(#)tdata.asm	4.3 85/05/17
TITLE	COMMAND Transient Initialized DATA
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

; MODIFICATION HISTORY
;
;	EE 10-20-83	Changed the drive check indicator bytes (DCIB's) in
;			COMTAB to be a flag byte in which bit 0 is now the
;			DCIB(bit) and bit 1 is on if the command can take
;			switches.
;
;	M003	SR	07/16/90 	Added LoadHigh to command table, added
;					parse control block for LoadHigh
;
;	M008	SA	8/1/90		Remove /h parameter. Eliminate code to
;					internally handle /? message.
;
;	M010	SA	8/5/90		Add support for /l (lowercase) option.
;
;	M016	SR	08/09/90	Added public statements for new error
;				messages for LoadHigh.
;



comment %

The TRANDATA segment contains data that is assumed to have predefined
initial values at the beginning of each command cycle.  It is
included in the transient checksum area.  If values in TRANDATA
change, the transient will be reloaded for the next command cycle.

Modification History
--------------------

8/12/89         DBO     History resumes after six years.

8/12/89         DBO     Added for new DIR:
-8/14/89                DirEnvVar, AttrLtrs, OrderLtrs;
                        New PARSE_DIR and subordinate parse blocks
                        (called PARSE_DIR_E for now);

%




fmt macro   name,string,args
	local	a
a	db  string
PUBLIC	name
name	dw  offset trangroup:a
irp val,<args>
	dw  offset trangroup:val
endm
endm

btab	macro	b,sym
    db	b
    dw	    offset trangroup:sym
    endm

.xlist
.xcref
	INCLUDE version.inc
	INCLUDE comsw.asm				;AC000;
	INCLUDE comseg.asm
	INCLUDE dirent.inc				;AN042;
.list
.cref

BREAK	MACRO	subtitle
	SUBTTL	subtitle
	PAGE
ENDM

;
; WARNING: DO NOT INCLUDE DOSSYM.INC BECAUSE IT DESTROYS THE MACRO 'FMT' THAT
; has been defined above - RS.
;
	INCLUDE ERROR.INC
	INCLUDE ifequ.asm
	INCLUDE comequ.asm
;	Note curdir.inc is included by comequ.asm

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg_buf:BYTE
	EXTRN	bwdbuf:byte
	EXTRN	bytes_free:WORD,DirUsedPercent:WORD
	EXTRN	DirCountOutput:WORD,DirAllocatedBytes:DWORD
	EXTRN	charbuf:byte
	EXTRN	copy_Num:WORD
	EXTRN	DATE_OUTPUT:BYTE	;AC000;
	EXTRN	Dir_Num:WORD
ifdef DBLSPACE_HOOKS
	EXTRN	Dir_CRatio_1:BYTE
	EXTRN	Dir_CRatio_2:BYTE
endif
	EXTRN	DRIVE_OUTPUT:BYTE	;AC000;
	EXTRN	file_size_high:WORD
	EXTRN	file_size_low:WORD
        EXTRN   DirAttributeText:BYTE, DirBasePath:BYTE
        EXTRN   TraceReturnCode:BYTE
        EXTRN   FileSiz:DWORD           ; accumulated file size for DIR
	EXTRN	major_ver_num:WORD
	EXTRN	minor_ver_num:WORD
	EXTRN	one_char_val:BYTE
	EXTRN	PARSE1_OUTPUT:BYTE	;AC000;
	EXTRN	srcbuf:byte
	EXTRN	string_ptr_2:WORD
	EXTRN	system_cpage:word
	EXTRN	TIME_OUTPUT:BYTE	;AC000;
	EXTRN	vol_drv:BYTE
	EXTRN	vol_serial:dword	;AN000;
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	$CALL:NEAR
	EXTRN	$CHDIR:NEAR
	EXTRN	$EXIT:NEAR
	EXTRN	$FOR:NEAR
	EXTRN	$IF:NEAR
	EXTRN	$MKDIR:NEAR
	EXTRN	$RMDIR:NEAR
	EXTRN	ADD_NAME_TO_ENVIRONMENT:NEAR
	EXTRN	ADD_PROMPT:NEAR
	EXTRN	build_dir_for_prompt:near
	EXTRN	CATALOG:NEAR
	EXTRN	CHCP:NEAR
	EXTRN	CLS:NEAR
	EXTRN	CNTRLC:NEAR
	EXTRN	COPY:NEAR
	EXTRN	CRENAME:NEAR
	EXTRN	CRLF2:NEAR
	EXTRN	CTIME:NEAR
	EXTRN	CTTY:NEAR
	EXTRN	DATE:NEAR
	EXTRN	ECHO:NEAR
	EXTRN	LockDrive:NEAR,UnlockDrive:NEAR
	EXTRN	ERASE:NEAR
	EXTRN	GOTO:NEAR
	EXTRN	IFERLEV:NEAR
	EXTRN	IFEXISTS:NEAR
	EXTRN	IFNOT:NEAR
	EXTRN	PATH:NEAR
	EXTRN	PAUSE:NEAR
	EXTRN	PRINT_B:NEAR
	EXTRN	PRINT_BACK:NEAR
	EXTRN	PRINT_DATE:NEAR
	EXTRN	PRINT_CHAR:NEAR
	EXTRN	PRINT_DRIVE:NEAR
	EXTRN	PRINT_EQ:NEAR
	EXTRN	PRINT_ESC:NEAR
	EXTRN	PRINT_G:NEAR
	EXTRN	PRINT_L:NEAR
	EXTRN	PRINT_TIME:NEAR
	EXTRN	PRINT_VERSION:NEAR
	EXTRN	SHIFT:NEAR
	EXTRN	TCOMMAND:NEAR
	EXTRN	TRUENAME:NEAR		;AN000;
	EXTRN	TYPEFIL:NEAR
	EXTRN	VERSION:NEAR
	EXTRN	VOLUME:NEAR
	EXTRN	VERIFY:NEAR
	EXTRN	LFNFOR:NEAR

	extrn	LoadHigh:NEAR		; M003
;
; WARNING!!! No code may appear after this label!!!!
;
;
; Bugbug:
;   8/12/89 Looks like somebody ignored/missed this warning.  TRANCODE
;           is added to at the end of this file.  Fortunately, it looks
;           like no modules refer to this label.
;
PUBLIC	TranCodeLast
TranCodeLast	LABEL	BYTE
TRANCODE	ENDS

; Data for transient portion

TRANDATA	SEGMENT PUBLIC BYTE
	PUBLIC	DirDateTimeTemplate, DirDateBlank, DirAttributePtr
	PUBLIC	DirVerboseHeader_Ptr, DirContRoot_Ptr, DirContCurrent_Ptr
        PUBLIC OnOffControl,OnOffWords

	PUBLIC	accden_ptr		;AN000;
	PUBLIC	acrlf_ptr		;AN000;
	PUBLIC	arg_buf_ptr		;AN000;
        PUBLIC  AttrLtrs
	PUBLIC	badbat_ptr		;AN000;
	PUBLIC	badcd_ptr		;AN000;
	PUBLIC	badCPmes_ptr		;AN000;
	PUBLIC	badcurdrv		;AN000;
	PUBLIC	baddat_ptr		;AN000;
	PUBLIC	baddev_ptr		;AN000;
	PUBLIC	baddrv_ptr		;AN000;
	PUBLIC	badlab_ptr		;AN000;
	PUBLIC	badmkd_ptr		;AN000;
	PUBLIC	badnam_ptr		;AN000;
	PUBLIC	bad_on_off_ptr		;AN000;
	PUBLIC	badPmes_ptr		;AN000;
	PUBLIC	badrmd_ptr		;AN000;
	PUBLIC	badtim_ptr		;AN000;
	PUBLIC	batext
        PUBLIC  bytes_ptr
	PUBLIC	bytmes_ptr		;AN000;
	PUBLIC	CLSSTRING
	PUBLIC	comext
        PUBLIC  comspec_flag            ;AN071;
	PUBLIC	COMSPECSTR
	PUBLIC	COMTAB
	PUBLIC	copied_ptr		;AN000;
	PUBLIC	cp_active_ptr		;AN000;
	PUBLIC	cp_not_all_ptr		;AN000;
	PUBLIC	cp_not_set_ptr		;AN000;
	PUBLIC	ctrlcmes_ptr		;AN000;
	PUBLIC	curdat_mo_day		;AN000;
	PUBLIC	curdat_ptr		;AN000;
	PUBLIC	curdat_yr		;AN000;
	PUBLIC	curtim_hr_min		;AN000;
	PUBLIC	curtim_ptr		;AN000;
	PUBLIC	curtim_sec_hn		;AN000;
	PUBLIC	dback_ptr		;AN000;
	PUBLIC	del_Y_N_ptr		;AN000;
	PUBLIC	devwmes_ptr		;AN000;
ifdef DBLSPACE_HOOKS
	PUBLIC	DirCompRatio_Ptr
	PUBLIC	AveCompRatio_Ptr
endif
        PUBLIC  DirEnvVar
	PUBLIC	dirhead_ptr		;AN000;
	PUBLIC	dirmes_ptr		;AN000;
        PUBLIC  DIR_SW_PTRS
	PUBLIC	disp_file_size_ptr	;AN000;
	PUBLIC	DosHma_Ptr
	PUBLIC	DosLow_Ptr
	PUBLIC	DosRev_Ptr
	PUBLIC	DosRom_Ptr
	PUBLIC	dmes_ptr		;AN000;
	PUBLIC	echomes_ptr		;AN000;
	PUBLIC	enverr_ptr		;AN000;
        PUBLIC  errparsenv_ptr
	PUBLIC	eurdat_ptr		;AN000;
	PUBLIC	exeext
	PUBLIC	file_name_ptr		;AN000;
	PUBLIC	fornestmes_ptr		;AN000;
	PUBLIC	fuldir_ptr		;AN000;
	PUBLIC	IFTAB
	PUBLIC	inBdev_ptr		;AN000;
	PUBLIC	inornot_ptr		;AN000;
	PUBLIC	Inv_code_page		;AN000;
	PUBLIC	inval_path_ptr		;AN000;
	PUBLIC	japdat_ptr		;AN000;
	PUBLIC	Losterr_ptr		;AN000;
	PUBLIC	md_exists_ptr		;AN006;
	PUBLIC	needbat_ptr		;AN000;
	PUBLIC	newdat_format		;AN000;
	PUBLIC	newdat_ptr		;AN000;
	PUBLIC	newtim_ptr		;AN000;
	PUBLIC	NLSFUNC_ptr		;AN000;
	PUBLIC	nospace_ptr		;AN000;
	PUBLIC	no_values		;AN000;
	PUBLIC	nulpath_ptr		;AN000;
	PUBLIC	offmes_ptr		;AN000;
	PUBLIC	onmes_ptr		;AN000;
        PUBLIC  OrderLtrs               ; list of sort order letters for DIR
	PUBLIC	overwr_ptr		;AN000;
	PUBLIC	PARSE_CHCP		;AN000;
	PUBLIC	PARSE_CHDIR		;AN000;
	PUBLIC	PARSE_CTTY		;AN000;
	PUBLIC	PARSE_DATE		;AN000;
	PUBLIC	PARSE_ERASE		;AN000;
	PUBLIC	PARSE_RENAME		;AN000;
	PUBLIC	PARSE_TIME		;AN000;
	PUBLIC	PARSE_VER
	PUBLIC	PARSE_VOL		;AN000;

	PUBLIC	PATH_TEXT
	PUBLIC	pausemes_ptr		;AN000;
	PUBLIC	pipeEmes_ptr		;AN000;
	PUBLIC	promptdat_moday 	;AN000;
	PUBLIC	promptdat_ptr		;AN000;
	PUBLIC	promptdat_yr		;AN000;
	PUBLIC	PROMPT_TABLE
	PUBLIC	PROMPT_TEXT
	PUBLIC	promtim_hr_min		;AN000;
	PUBLIC	promtim_ptr		;AN000;
	PUBLIC	promtim_sec_hn		;AN000;
	PUBLIC	renerr_ptr		;AN000;
	PUBLIC	string_buf_ptr		;AN000;
	PUBLIC	suremes_ptr		;AN000;
	PUBLIC	switch_list
	PUBLIC	syntmes_ptr		;AN000;
	PUBLIC	tab_ptr 		;AN000;
        PUBLIC  total_ptr
	PUBLIC	TRANDATAEND
	PUBLIC	usadat_ptr		;AN000;
	PUBLIC	lfnformes_ptr
	PUBLIC	TraceReturn_Ptr, TraceReload_Ptr
	PUBLIC	verimes_ptr		;AN000;
	PUBLIC	vermes_ptr		;AN000;
	PUBLIC	volmes_ptr		;AN000;
	PUBLIC	volmes_ptr_2		;AN000;
	PUBLIC	volsermes_ptr		;AN000;
	PUBLIC	WEEKTAB

	public	NoExecBat_Ptr		; M016
	public	LhInvFil_Ptr		; M016
	public	NoCntry_Ptr		; M045
	public	LhInvArg_Ptr
	public	ReqParmMiss
	public	LhInvSwt_Ptr
	public	LhBadUMB_Ptr

INCLUDE tranmsg.asm

; Lists of help message numbers for internal commands and /?

;;NoHelpMsgs	dw	1200,0		;M014
BreakHelpMsgs	dw	1300,0
LFNForHelpMsgs dw	1310,0
ChcpHelpMsgs	dw	1320,1321,0
CdHelpMsgs	dw	1340,1341,1342,0
ClsHelpMsgs	dw	1360,0
CopyHelpMsgs	dw	1400,1401,1402,1403,1404,1405,1406,1407,0
CttyHelpMsgs	dw	1420,0
DateHelpMsgs	dw	1440,1441,0
DelHelpMsgs	dw	1460,1461,1462,0
DirHelpMsgs	dw	1480,1481,1482,1483,1484,1485,1486,1487,1488,0
ExitHelpMsgs	dw	1500,0
MdHelpMsgs	dw	1520,0
PathHelpMsgs	dw	1540,1541,1542,0
PromptHelpMsgs	dw	1560,1561,1562,1563,1564,1565,1566,1567,1568,0
RdHelpMsgs	dw	1580,0
RenHelpMsgs	dw	1600,1601,1602,0
SetHelpMsgs	dw	1620,1621,1622,0
TimeHelpMsgs	dw	1640,1641,0
TypeHelpMsgs	dw	1660,0
VerHelpMsgs	dw	1680,0
VerifyHelpMsgs	dw	1700,0
VolHelpMsgs	dw	1720,0

CallHelpMsgs	dw	1740,1741,0	;M014
RemHelpMsgs	dw	1760,0		;M014
PauseHelpMsgs	dw	1780,0		;M014
EchoHelpMsgs	dw	1800,1801,0	;M014
LockHelpMsgs	dw	1810,0
UnlockHelpMsgs	dw	1815,0
GotoHelpMsgs	dw	1820,1821,0	;M014
ShiftHelpMsgs	dw	1840,0		;M014
IfHelpMsgs	dw	1860,1861,1862,1863,1864,1865,1866,0	;M014
ForHelpMsgs	dw	1880,1881,1882,1883,0	;M014
TruenameHelpMsgs dw	1900,0			;M014
LoadhighHelpMsgs dw	1920,1921,1922,1923,1924,1925,1926,0	;M014


CLSSTRING DB	4,01BH,"[2J"            ; ANSI Clear screen

PROMPT_TABLE LABEL BYTE
	btab	"B",Print_B
	btab	"D",PRINT_DATE
	btab	"E",PRINT_ESC
	btab	"G",PRINT_G
	btab	"H",PRINT_BACK
	btab	"L",PRINT_L
	btab	"N",PRINT_DRIVE
	btab	"P",build_dir_for_prompt
	btab	"Q",PRINT_EQ
	btab	"T",PRINT_TIME
	btab	"V",PRINT_VERSION
	btab	"_",CRLF2
	btab	"$",PRINT_CHAR
	DB	0				; NUL TERMINATED

IFTAB	LABEL	BYTE				; Table of IF conditionals
	DB	3,"NOT"                         ; First byte is count
	DW	OFFSET TRANGROUP:IFNOT
	DB	10,"ERRORLEVEL"
	DW	OFFSET TRANGROUP:IFERLEV
	DB	5,"EXIST"
	DW	OFFSET TRANGROUP:IFEXISTS
	DB	0

; Table for internal command names
COMTAB LABEL BYTE
; Flags, handler and help list, indexed by the command-name table.
	DB	fSwitchAllowed+fCheckDrive	; DIR
	DW	OFFSET TRANGROUP:CATALOG
	DW	TRANGROUP:DirHelpMsgs
	DB	fSwitchAllowed	; CALL
	DW	OFFSET TRANGROUP:$CALL
	DW	TRANGROUP:CallHelpMsgs
	DB	fSwitchAllowed	; CHCP
	DW	OFFSET TRANGROUP:CHCP
	DW	TRANGROUP:ChcpHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; RENAME
	DW	OFFSET TRANGROUP:CRENAME
	DW	TRANGROUP:RenHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; REN
	DW	OFFSET TRANGROUP:CRENAME
	DW	TRANGROUP:RenHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; ERASE
	DW	OFFSET TRANGROUP:ERASE
	DW	TRANGROUP:DelHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; DEL
	DW	OFFSET TRANGROUP:ERASE
	DW	TRANGROUP:DelHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; TYPE
	DW	OFFSET TRANGROUP:TYPEFIL
	DW	TRANGROUP:TypeHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; REM
	DW	OFFSET TRANGROUP:TCOMMAND
	DW	TRANGROUP:RemHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; COPY
	DW	OFFSET TRANGROUP:COPY
	DW	TRANGROUP:CopyHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; PAUSE
	DW	OFFSET TRANGROUP:PAUSE
	DW	TRANGROUP:PauseHelpMsgs
	DB	fSwitchAllowed	; DATE
	DW	OFFSET TRANGROUP:DATE
	DW	TRANGROUP:DateHelpMsgs
	DB	fSwitchAllowed	; TIME
	DW	OFFSET TRANGROUP:CTIME
	DW	TRANGROUP:TimeHelpMsgs
	DB	fSwitchAllowed	; VER
	DW	OFFSET TRANGROUP:VERSION
	DW	TRANGROUP:VerHelpMsgs
	DB	fCheckDrive	; VOL
	DW	OFFSET TRANGROUP:VOLUME
	DW	TRANGROUP:VolHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; CD
	DW	OFFSET TRANGROUP:$CHDIR
	DW	TRANGROUP:CdHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; CHDIR
	DW	OFFSET TRANGROUP:$CHDIR
	DW	TRANGROUP:CdHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; MD
	DW	OFFSET TRANGROUP:$MKDIR
	DW	TRANGROUP:MdHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; MKDIR
	DW	OFFSET TRANGROUP:$MKDIR
	DW	TRANGROUP:MdHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; RD
	DW	OFFSET TRANGROUP:$RMDIR
	DW	TRANGROUP:RdHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; RMDIR
	DW	OFFSET TRANGROUP:$RMDIR
	DW	TRANGROUP:RdHelpMsgs
	DB	fSwitchAllowed	; BREAK
	DW	OFFSET TRANGROUP:CNTRLC
	DW	TRANGROUP:BreakHelpMsgs
	DB	fSwitchAllowed	; VERIFY
	DW	OFFSET TRANGROUP:VERIFY
	DW	TRANGROUP:VerifyHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; SET
	DW	OFFSET TRANGROUP:ADD_NAME_TO_ENVIRONMENT
	DW	TRANGROUP:SetHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; PROMPT
	DW	OFFSET TRANGROUP:ADD_PROMPT
	DW	TRANGROUP:PromptHelpMsgs
	DB	fSwitchAllowed	; PATH
	DW	OFFSET TRANGROUP:PATH
	DW	TRANGROUP:PathHelpMsgs
	DB	0	; EXIT
	DW	OFFSET TRANGROUP:$EXIT
	DW	TRANGROUP:ExitHelpMsgs
	DB	fCheckDrive	; CTTY
	DW	OFFSET TRANGROUP:CTTY
	DW	TRANGROUP:CttyHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; ECHO
	DW	OFFSET TRANGROUP:ECHO
	DW	TRANGROUP:EchoHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; LOCK
	DW	OFFSET TRANGROUP:LockDrive
	DW	TRANGROUP:LockHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; UNLOCK
	DW	OFFSET TRANGROUP:UnlockDrive
	DW	TRANGROUP:UnlockHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; GOTO
	DW	OFFSET TRANGROUP:GOTO
	DW	TRANGROUP:GotoHelpMsgs
	DB	fSwitchAllowed	; SHIFT
	DW	OFFSET TRANGROUP:SHIFT
	DW	TRANGROUP:ShiftHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; IF
	DW	OFFSET TRANGROUP:$IF
	DW	TRANGROUP:IfHelpMsgs
	DB	fSwitchAllowed+fLimitHelp	; FOR
	DW	OFFSET TRANGROUP:$FOR
	DW	TRANGROUP:ForHelpMsgs
	DB	0	; CLS
	DW	OFFSET TRANGROUP:CLS
	DW	TRANGROUP:ClsHelpMsgs
	DB	fSwitchAllowed+fCheckDrive	; TRUENAME
	DW	OFFSET TRANGROUP:TRUENAME
	DW	TRANGROUP:TruenameHelpMsgs
	DB	fSwitchAllowed	; LOADHIGH
	DW	OFFSET TRANGROUP:LoadHigh
	DW	TRANGROUP:LoadhighHelpMsgs
	DB	fSwitchAllowed	; LH
	DW	OFFSET TRANGROUP:LoadHigh
	DW	TRANGROUP:LoadhighHelpMsgs
	DB	fSwitchAllowed	; LFNFOR
	DW	OFFSET TRANGROUP:LFNFOR
	DW	TRANGROUP:LFNForHelpMsgs

PUBLIC CommandNames
CommandNames LABEL BYTE
	DB	3,"DIR"
	DB	4,"CALL"
	DB	4,"CHCP"
	DB	6,"RENAME"
	DB	3,"REN"
	DB	5,"ERASE"
	DB	3,"DEL"
	DB	4,"TYPE"
	DB	3,"REM"
	DB	4,"COPY"
	DB	5,"PAUSE"
	DB	4,"DATE"
	DB	4,"TIME"
	DB	3,"VER"
	DB	3,"VOL"
	DB	2,"CD"
	DB	5,"CHDIR"
	DB	2,"MD"
	DB	5,"MKDIR"
	DB	2,"RD"
	DB	5,"RMDIR"
	DB	5,"BREAK"
	DB	6,"VERIFY"
	DB	3,"SET"
	DB	6,"PROMPT"
	DB	4,"PATH"
	DB	4,"EXIT"
	DB	4,"CTTY"
	DB	4,"ECHO"
	DB	4,"LOCK"
	DB	6,"UNLOCK"
	DB	4,"GOTO"
	DB	5,"SHIFT"
	DB	2,"IF"
	PUBLIC	ForCommandName
ForCommandName LABEL BYTE
	DB	3,"FOR"
	DB	3,"CLS"
	DB	8,"TRUENAME"
	DB	8,"LOADHIGH"
	DB	2,"LH"
	DB	6,"LFNFOR"
	DB	0				; Terminate command names

comext	dB	".COM"
exeext	dB	".EXE"
batext	dB	".BAT"

switch_list	DB	"?VBAPWY-"                ; flags we can recognize

	PUBLIC	WinCommand
WinCommand	DB	3,"WIN",13

	PUBLIC	CParseSwitchList
CParseSwitchList DB 1,'?',1,'V',1,'B',2,'A*',1,'P',1,'W'
		 DB 1,'R',1,'S',2,'O*',1,'Y',2,'-*'

AttrLtrs        DB      "RHSvDA"                ; attribute letters for DIR

;               Attribute letters in AttrLtrs must appear in the order that
;               attribute bits occur in the attribute byte returned by
;               directory searches, starting with bit 0.
;               The volume label attribute is lowercased to keep it from
;               being matched (by an uppercase comparison).

ifdef DBLSPACE_HOOKS
OrderLtrs	DB	"NEDSGAC"		; sort order letters for DIR
else
OrderLtrs	DB	"NEDSGA" 		; sort order letters for DIR
endif
;               Sort order letters stand for file name, extension,
;		date/time, size, grouped (directory files before others),
;		access date and compression ratio. DIR routines rely on the specific
;		order of the letters in this list.

comspec_flag    db      0                       ;AN071;
DirDateBlank	DB	blank



PUBLIC	BatBufLen
BatBufLen   DW	BatLen

; *****************************************************
; EMG 4.00
; DATA STARTING HERE WAS ADDED BY EMG FOR 4.00
; FOR IMPLEMENTATION OF COMMON PARSE ROUTINE
; *****************************************************

;
; COMMON PARSE BLOCKS
;

;
; Indicates no value list for PARSE.
;

NO_VALUES	DW	0			;AN000;  no values

NULL_VALUE_LIST LABEL   BYTE                    ; for unvalidated value
                DB      0                       ; no value lists

;
; PARSE control block for a required file specification (upper cased)
;

FILE_REQUIRED	LABEL	BYTE			;AN000;
		DW	0200H			;AN000;  filespec - required
		DW	1			;AN000;  capitalize - file table
		DW	TRANGROUP:PARSE1_OUTPUT ;AN000;  result buffer
		DW	TRANGROUP:NO_VALUES	;AN000;
		DB	0			;AN000;  no keywords

OnOffWords DB 2,"ON",3,"OFF",0
PARSE_CHCP	DB	81H,0,0,0,0		; Optional numeric code page

;
; PARSE control block for an optional file specification (upper cased)
; or drive number
;


;
; PARSE BLOCK FOR CHCP
;

;
; The following parse control block can be used for any command which
; needs only one optional three digit decimal parameter for operands.
; Returns verified result in PARSE1_OUTPUT.  Currently used for the
; CHCP internal command.
;
CHCP_MINVAL	EQU	100			;AN000;
CHCP_MAXVAL	EQU	999			;AN000;



;
; PARSE BLOCK FOR DATE
;

;
; The following parse control block can be used for any command which
; needs only an optional date string as an operand.  Returns unverified
; result in DATE_OUTPUT.  Currently used for the DATE internal command.
;

PARSE_DATE	DB	40H,0,0,0,0		; Optional date

;
; PARSE BLOCK FOR TIME
;

;
; The following parse control block can be used for any command which
; needs only an optional time string as an operand.  Returns unverified
; result in TIME_OUTPUT.  Currently used for the TIME internal command.
;

PARSE_TIME	LABEL	BYTE			;AN000;
		DW	TRANGROUP:TIME_PARMS	;AN000;
		DB	0			;AN000;  no extra delimiter

TIME_PARMS	LABEL	BYTE			;AN000;
		DB	0,1			;AN000;  1 positional parm
		DW	TRANGROUP:TIME_CONTROL1 ;AN000;
		DB	0			;AN000;  no switches
		DB	0			;AN000;  no keywords

		DB	0			; end of parameter table
TIME_CONTROL1	LABEL	BYTE			;AN000;
		DW	0801H			;AN000;  TIME - optional
		DW	0			;AN000;  no function flags
		DW	TRANGROUP:TIME_OUTPUT	;AN000;  result buffer
		DW	TRANGROUP:NO_VALUES	;AN000;
		DB	0			;AN000;  no keywords


;
; PARSE BLOCK FOR VOL
;

;
; The following parse control block can be used for any command which
; needs only an optional drive letter as an operand.  Returns unverified
; drive number (one based) in DRIVE_OUTPUT.  Currently used for the VOL
; internal command.
;

;
; PARSE BLOCK FOR MKDIR, RMDIR, TYPE
;

;
; The following parse control block can be used for any command which
; needs only one required file specification as an operand.  Returns a
; pointer to the unverified string in PARSE1_OUTPUT.  Currently used
; for the MKDIR, RMDIR, and TYPE internal commands.
;

;
; PARSE BLOCK FOR CHDIR, TRUENAME
;

;
; The following parse control block can be used for any command which
; needs only one optional file specification an operand.  Returns a
; pointer to the unverified string in PARSE1_OUTPUT.  Currently used
; for the CHDIR and TRUENAME internal commands.
;

PARSE_VOL	DB	11H,0,0,0,0		; Optional drive
PARSE_CTTY	DB	20H,0,0,0,0		; Required device name
PARSE_CHDIR	DB	21H,0,0,0,0		; Optional pathname
OnOffControl	DB	21H,1,0,0,0		; ON/OFF argument
	PUBLIC	EchoOnOffControl
EchoOnOffControl DB	21H,1,0FFH,0FFH,0	; ECHO ON/OFF argument

;
; PARSE BLOCK FOR ERASE
;

;
; The following parse control block is used for the DEL/ERASE internal
; commands.  This command has one required file specification and an
; optional switch (/p) as operands. The verified switch or unverified
; file specification is returned in PARSE1_OUTPUT.
;

PARSE_ERASE	DB	20H,0,10H,0,0	; pathname and /P switch

;
; PARSE BLOCK FOR DIR
;

;
; The following parse control block is used for the DIR internal command.
; This command has one optional file specification and several optional
; switches.  Switches, switch values, and the filespec are returned in 
; PARSE1_OUTPUT.
;
; Switches are /a[value], /-a, /o[value], /-o, /s, /-s, /?, /b, /-b,
; /w, /-w, /p, and /-p.  The string values for /a and /o are optional,
; do not require colons, and are not checked against a value list.
;
; Switch /h has been removed from the DIR command	;M008
; Switch /? is no longer handled internally		;M008
;
; A list of pointers to all the switch synonyms is provided here to
; help identify which switch has been matched.
;

DIR_SW_A	DB	"/A",0
DIR_SW_O	DB	"/O",0
ifdef DBLSPACE_HOOKS
DIR_SW_C	DB	"/C",0
endif

DIR_SW_NEG_A	DB	"/-A",0
DIR_SW_NEG_O	DB	"/-O",0
DIR_SW_S	DB	"/S",0
DIR_SW_NEG_S	DB	"/-S",0
DIR_SW_B	DB	"/B",0
DIR_SW_NEG_B	DB	"/-B",0
DIR_SW_W	DB	"/W",0
DIR_SW_NEG_W	DB	"/-W",0
DIR_SW_P	DB	"/P",0
DIR_SW_NEG_P	DB	"/-P",0
DIR_SW_L	DB	"/L",0			;M010
DIR_SW_NEG_L	DB	"/-L",0 		;M010
DIR_SW_V	DB	"/V",0
DIR_SW_NEG_V	DB	"/-V",0
ifdef DBLSPACE_HOOKS
DIR_SW_NEG_C	DB	"/-C",0
endif
DIR_SW_NEG_Z	DB	"/-Z",0
DIR_SW_Z	DB	"/Z",0
;
; Here's a list of pointers to DIR's switch synonyms, for easier
; identification.  Order is critical - DIR routines rely on the
; specific order in this list.  Negated options appear at odd 
; positions in the list, and simple on/off options appear first.
;

DIR_SW_PTRS	LABEL	WORD		; list of ptrs to switch synonyms
		DW	TRANGROUP:DIR_SW_NEG_W
		DW	TRANGROUP:DIR_SW_W
		DW	TRANGROUP:DIR_SW_NEG_P
		DW	TRANGROUP:DIR_SW_P
		DW	TRANGROUP:DIR_SW_NEG_S
		DW	TRANGROUP:DIR_SW_S
		DW	TRANGROUP:DIR_SW_NEG_B
		DW	TRANGROUP:DIR_SW_B
		DW	TRANGROUP:DIR_SW_NEG_L	;M010
		DW	TRANGROUP:DIR_SW_L	;M010
		DW	TRANGROUP:DIR_SW_NEG_V
		DW	TRANGROUP:DIR_SW_V
ifdef DBLSPACE_HOOKS
		DW	TRANGROUP:DIR_SW_NEG_C
		DW	TRANGROUP:DIR_SW_C
endif
		DW	TRANGROUP:DIR_SW_NEG_Z
		DW	TRANGROUP:DIR_SW_Z
		DW	TRANGROUP:DIR_SW_NEG_O
		DW	TRANGROUP:DIR_SW_O
		DW	TRANGROUP:DIR_SW_NEG_A
		DW	TRANGROUP:DIR_SW_A

;
; PARSE BLOCK FOR RENAME
;

;
; The following parse control block can be used for any command which
; needs only two required file specifications as operands.  Returns
; pointers to the unverified string in PARSE1_OUTPUT.
; Currently used for the RENAME internal command.
;

PARSE_RENAME	DB	20H,0,0,0,0	; Required filename

;
; PARSE BLOCK FOR CTTY
;

;
; The following parse control block can be used for any command which
; needs one required device name as an operand.  Returns a pointer to
; unverified string in PARSE1_OUTPUT. Currently used for the CTTY
; internal command.
;


;
; PARSE BLOCK FOR VER
;

;
; The following parse control block can be used for any command which
; needs an optional switch "/debug".  Currently used for the VER command.
;

PARSE_VER	DB	0,0,40H,0,0		; Optional /R switch

;
; M003 ; Start of changes for LoadHigh support
;

;
;Parse Control Block for LOADHIGH command
;

;
; M003 ; End of changes for LoadHigh support
;

public TempVarName
TempVarName	db	"TEMP=",0

public	copycmd_name
copycmd_name	db	"COPYCMD="


ifdef	BETA3WARN
%out	Take this out before we ship
public Beta3WarnMsg
Beta3WarnMsg	label	byte

  db      '+------------------- WARNING! ------------------+', 0dh, 0ah
  db      '|                                               |', 0dh, 0ah
  db      '|                                               |', 0dh, 0ah
  db      '|  This pre-release version of MS-DOS 6 is out  |', 0dh, 0ah
  db      '|  of date.  Please replace it with an updated  |', 0dh, 0ah
  db      '|  version of MS-DOS 6.                         |', 0dh, 0ah
  db      '|                                               |', 0dh, 0ah
  db      '|                                               |', 0dh, 0ah
  db      '|          <Press any key to continue>          |', 0dh, 0ah
  db      '|                                               |', 0dh, 0ah
  db      '+-----------------------------------------------+', 0dh, 0ah
  db	  '$'
endif


TRANDATA	ENDS

DOS7_TRANSIENT_MSG EQU 1
INCLUDE SYSMSG.INC

TRANDATA	SEGMENT PUBLIC BYTE


TRANDATAEND	LABEL	BYTE		; end of checksummed transient data
	MSG_UTILNAME <COMMAND>
	MSG_SERVICES <COMT,MSGDATA>
	PUBLIC	$M_RT


TRANDATA	ENDS				;AN000;



	END
