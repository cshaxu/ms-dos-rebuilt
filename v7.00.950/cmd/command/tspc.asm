	page ,132
;	SCCSID = @(#)tspc.asm	4.1 85/09/22
;	SCCSID = @(#)tspc.asm	4.1 85/09/22
TITLE	COMMAND Transient Uninitialized DATA
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

comment %

The TRANSPACE segment contains variable data that is considered
volatile between command cycles, and therefore is not included in the
transient checksum area.  Contents of these variables MUST be
initialized before use, and must not be relied upon from command
cycle to command cycle.

No constant data values should be stored here.

%
        



.xlist
.xcref
	include version.inc
	include comsw.asm
	include dossym.inc
	include find.inc
	include intnat.inc
	include comequ.asm
	include comseg.asm
ifdef DBLSPACE_HOOKS
	include magicdrv.inc
endif
.list
.cref

; Uninitialized transient data
TRANSPACE	SEGMENT PUBLIC BYTE

	PUBLIC	msg_disp_class
	PUBLIC	msg_cont_flag
	PUBLIC	Extend_Buf_ptr
	PUBLIC	Extend_Buf_sub
	PUBLIC	Extend_Buf_off
	PUBLIC	Extend_Buf_seg
	PUBLIC	ALLSWITCH
	PUBLIC	append_exec		;AN041;
	PUBLIC	arg
	PUBLIC	argbufptr
	PUBLIC	ARGC
	PUBLIC	ARG1S
	PUBLIC	ARG2S
	PUBLIC	ARGTS
	PUBLIC	arg_buf
	PUBLIC	ASCII
        PUBLIC  AttrSelect
        PUBLIC  AttrSpecified
	PUBLIC	BatBuf
	PUBLIC	BatBufEnd
	PUBLIC	BatBufPos
	PUBLIC	BATHAND
	PUBLIC	prompt_sublist, confirm_overwrite, dest_exists, copy_state
	PUBLIC	BINARY
	PUBLIC	BITS
	PUBLIC	BWDBUF
	PUBLIC	BYTCNT
	PUBLIC	bytes_free
	PUBLIC	CFLAG
	PUBLIC	CHARBUF
	PUBLIC	CHKDRV
	PUBLIC	COM
	PUBLIC	COMBUF
	PUBLIC	comma
	PUBLIC	comptr
	PUBLIC	COMSW
	PUBLIC	CONCAT
	PUBLIC	copy_Num
	PUBLIC	CountryPtrInfo
	PUBLIC	CountryPtrId
	PUBLIC	CountryPtr
	PUBLIC	CPDATE
	PUBLIC	CPTIME
	PUBLIC	cpyflag
	PUBLIC	CURDRV
	PUBLIC	DATE_DAY		;AN000;
	PUBLIC	DATE_MONTH		;AN000;
	PUBLIC	DATE_OUTPUT		;AN000;
	PUBLIC	DATE_TYPE		;AN000;
	PUBLIC	DATE_YEAR		;AN000;
	PUBLIC	DEST
	PUBLIC	DESTBUF
	PUBLIC	DestClosed
	PUBLIC	DESTDIR
	PUBLIC	DESTFCB
	PUBLIC	DESTFCB2
	PUBLIC	DESTHAND
	PUBLIC	DESTINFO
	PUBLIC	DESTISDEV
	PUBLIC	DESTISDIR
	PUBLIC	DESTNAME
	PUBLIC	DESTSIZ
	PUBLIC	DESTSWITCH
	PUBLIC	DESTTAIL
	PUBLIC	DESTVARS
	PUBLIC	DIRBUF
	PUBLIC	DIRCHAR
	PUBLIC	dirflag 		;AN015;
	PUBLIC	Dir_Num
ifdef DBLSPACE_HOOKS
	PUBLIC	Dir_CRatio_1
	PUBLIC	Dir_CRatio_2
endif
	PUBLIC	display_ioctl		;AN000;
	PUBLIC	display_mode		;AN000;
	PUBLIC	display_width		;AN000;
	PUBLIC	DRIVE_NUMBER		;AN000;
	PUBLIC	DRIVE_OUTPUT		;AN000;
	PUBLIC	DRIVE_TYPE		;AN000;
	PUBLIC	DRIVE_VALUE		;AN000;
	PUBLIC	ELCNT
	PUBLIC	ELPOS
	PUBLIC	ENDDESTBUF
	PUBLIC	EXECPATH
	PUBLIC	EXEC_ADDR
	PUBLIC	EXEFCB
	PUBLIC	expand_star
	PUBLIC	ext_entered		;AN005;
	PUBLIC	FBUF
        PUBLIC  FileCnt
        PUBLIC  FileCntTotal
        PUBLIC  FileSiz
        PUBLIC  FileSizTotal
	PUBLIC	file_size_high
	PUBLIC	file_size_low
	PUBLIC	FILTYP
	PUBLIC	FIRSTDEST
	PUBLIC	FRSTSRCH
	PUBLIC	GOTOLEN
	PUBLIC	HEADCALL
	PUBLIC	ID
	PUBLIC	IDLEN
	PUBLIC	IFNOTFLAG
	PUBLIC	if_not_count
	PUBLIC	INEXACT
	PUBLIC	INTERNATVARS
	PUBLIC	KPARSE
	PUBLIC	last_arg
        PUBLIC  PerLine
        PUBLIC  LeftOnLine
        PUBLIC  LeftOnPage
	PUBLIC	linperpag		;AN000;
	PUBLIC	major_ver_num
	PUBLIC	MELCOPY
	PUBLIC	MELSTART
	PUBLIC	minor_ver_num
	PUBLIC	msg_flag		;AN022;
	PUBLIC	msg_numb		;AN022;
	PUBLIC	NOWRITE
	PUBLIC	NXTADD
	PUBLIC	objcnt
	PUBLIC	OCtrlZ
	PUBLIC	OFilePtr_Hi
	PUBLIC	OFilePtr_Lo
	PUBLIC	OldCtrlCHandler
	PUBLIC	one_char_val
	PUBLIC	PARM1
	PUBLIC	PARM2
	PUBLIC	parse_last		;AN018;
	PUBLIC	PARSE1_ADDR		;AN000;
	PUBLIC	PARSE1_CODE		;AN000;
	PUBLIC	PARSE1_OUTPUT		;AN000;
	PUBLIC	PARSE1_SYN		;AN000;
	PUBLIC	PARSE1_TYPE		;AN000;
	PUBLIC	PATHCNT
	PUBLIC	pathinfo
	PUBLIC	PATHPOS
	PUBLIC	PATHSW
	PUBLIC	PLUS
	PUBLIC	plus_comma
	PUBLIC	print_err_flag		;AN000;
	PUBLIC	psep_char
	PUBLIC	RCH_ADDR
	PUBLIC	RDEOF
	PUBLIC	RE_INSTR
	PUBLIC	RESSEG
	PUBLIC	SCANBUF
	PUBLIC	SDIRBUF
	PUBLIC	search_best
	PUBLIC	search_best_buf
	PUBLIC	search_curdir_buf
	PUBLIC	search_error
	PUBLIC	SKPDEL
	PUBLIC	SOURCE
	PUBLIC	SPECDRV
	PUBLIC	SRCBUF
	PUBLIC	SRCHAND
	PUBLIC	SRCINFO
	PUBLIC	SRCISDEV
	PUBLIC	SRCISDIR
	PUBLIC	SRCPT
	PUBLIC	SRCSIZ
	PUBLIC	SRCTAIL
	PUBLIC	SRCVARS
	PUBLIC	srcxname
	PUBLIC	STACK
	PUBLIC	STARTEL
	PUBLIC	string_ptr_2
;AD061; PUBLIC	string_ptr_2_sb 	;AN000;
	PUBLIC	subst_buffer		;AN061;
	PUBLIC	SWITCHAR
	PUBLIC	system_cpage
	PUBLIC	TERMREAD
	PUBLIC	TIME_FRACTION		;AN000;
	PUBLIC	TIME_HOUR		;AN000;
	PUBLIC	TIME_MINUTES		;AN000;
	PUBLIC	TIME_OUTPUT		;AN000;
	PUBLIC	TIME_SECONDS		;AN000;
	PUBLIC	TIME_TYPE		;AN000;
	PUBLIC	TPA
	PUBLIC	TRANSPACEEND
	PUBLIC	TRAN_TPA
	PUBLIC	trgxname
	PUBLIC	USERDIR1
	PUBLIC	vol_drv
	PUBLIC	vol_ioctl_buf		;AC030;
	PUBLIC	vol_serial		;AC030;
	PUBLIC	vol_label		;AC030;
	PUBLIC	WRITTEN
	PUBLIC	zflag

	Public	TypeFilSiz		;stores size of file to be typed

ifdef DBLSPACE_HOOKS
	PUBLIC	ccluUsed, ccluUsedDir, ccluUsedTotal
	PUBLIC	csecUsed, csecUsedDir, csecUsedTotal
	PUBLIC	csecPerCluster, fUseHostSize
endif

	IF  IBM_ROM_FIND
	PUBLIC	ROM_CALL
	PUBLIC	ROM_CS
	PUBLIC	ROM_IP
	ENDIF


	ORG	0
ZERO	=	$
SRCXNAME	DB	104H DUP (?)		; buffer for name translation
TRGXNAME	DB	104H DUP (?)		; buffer for name translation
USERDIR1	DB	104H DUP (?)		; Storage for users current directory
EXECPATH	DB	260 DUP(?)	; Path for external command

; Variables passed up from resident
HEADCALL	LABEL	DWORD
		DW	?
RESSEG		DW	?
TPA		DW	?
SWITCHAR	DB	?
DIRCHAR 	DB	?
EXEC_ADDR	DD	?
RCH_ADDR	DD	?
		DW	?			; resident test word
TRAN_TPA	DW	?
	PUBLIC	fTest
	PUBLIC	TraceReturnCode
	PUBLIC	TracePrinted
fTest		DW	?
TraceReturnCode DB	?
TracePrinted	DB	?
	PUBLIC	CmdBufferLength
	PUBLIC	InputBufferLength
	PUBLIC	ComBufPtr
CmdBufferLength DW	?
InputBufferLength DW	?

CHKDRV		DB	?
RDEOF		LABEL	BYTE			; Misc flags
IFNOTFLAG	LABEL	BYTE
FILTYP		DB	?
CURDRV		DB	?
CONCAT		LABEL	BYTE
PARM1		DB	?
ARGC		LABEL	BYTE
PARM2		DB	?
COMSW		DW	?			; Switches between command and 1st arg
ARG1S		DW	?			; Switches between 1st and 2nd arg
DESTSWITCH	LABEL	WORD
ARG2S		DW	?			; Switches after 2nd arg
ALLSWITCH	LABEL	WORD
ARGTS		DW	?			; ALL switches except for COMSW
CFLAG		DB	?
DESTCLOSED	LABEL	BYTE
SPECDRV 	DB	?
BYTCNT		DW	?			; Size of buffer between RES and TRANS
NXTADD		DW	?
FRSTSRCH	DB	?
LeftOnLine      DB      ?                       ; entries left on line u.b. DIR
PerLine         DB      ?                       ; entries/line u.b. DIR
LeftOnPage      DW      ?                       ; lines left on page u.b. DIR
FileCnt         DW      ?                       ; file count u.b. DIR
FileSiz         DD      ?                       ; file size u.b. DIR
	PUBLIC	DirEntryCount
	PUBLIC	DirCount
	PUBLIC	DirCountTotal
DirEntryCount   DW      ?			; entries in this directory
DirCount        DW      ?			; directories in this directory
	PUBLIC	DirAllocatedBytes
	PUBLIC	DirCountOutput
DirAllocatedBytes DD    ?
	PUBLIC	DirAllocatedClusters
	PUBLIC	DirAllocatedClustersTotal
DirAllocatedClusters DW ?
DirAllocatedClustersTotal DW ?

DirUsedPercent	dw	?
DirClusterSize      DW  ?		; sectors per cluster
DirSectorShift      DB  ?		; log2 of bytes per sector
DirBytesPerSector   DW  ?
DirFreeClusters     DW  ?
DirTotalClusters    DW  ?
DirHeaderPending    DB  ?
DirClusterInvalid   DB  ?
DirNeedInfo         DB  ?
ParseSwitchFlag	DB	?		; switch mask 0008h present
	PUBLIC	DirArgumentCount
	PUBLIC	ExecState
DirArgumentCount DB	?
ParseArgIndex      DW  ?       ; next parsed argument
ParseFileArg       DW  ?       ; parsed file argument
ParseDateParts     DW  4 DUP (?)
ParseResultType    DB  ?       ; command parser result type
ParseResultValue   DD  ?       ; numeric value or string address
ExecState	DB	?			; state cleared before execution

;		Note:  keep FileCntTotal through csecUsedTotal together!

FileCntTotal    DD      ?                       ; total file count u.b. DIR
FileSizTotal	DD	?			; total file size u.b. DIR
DirCountTotal	DD	?			; total directories u.b. DIR

ifdef DBLSPACE_HOOKS
ccluUsed	DW	?			; count of DOS clusters used
ccluUsedDir	DW	?
ccluUsedTotal	DW	?
csecUsed	DD	?			; count of comp sectors used
csecUsedDir	DD	?
csecUsedTotal	DD	?
	PUBLIC	DirCompressionMask
	PUBLIC	DirCompressionShift
DirCompressionMask DD	?
DirCompressionShift DB	?
		DB	?			; reserved

;		Note:  keep FileCntTotal through csecUsedTotal together!

csecPerCluster	DB	?			; sectors/cluster for ratio calc
fUseHostSize	DB	?			; NZ if using host cluster size

endif

CHARBUF 	DB	80 DUP (?)		;line byte character buffer for xenix write
DESTFCB2	LABEL	BYTE
IDLEN		DB	?
ID		DB	8 DUP(?)
COM		DB	3 DUP(?)
DEST		DB	37 DUP(?)
DESTNAME	DB	11 DUP(?)
DESTFCB 	LABEL	BYTE
DESTDIR 	DB	DIRSTRLEN DUP(?)	; Directory for PATH searches
GOTOLEN 	LABEL	WORD
BWDBUF		DB	260 DUP (?)
EXEFCB		LABEL	WORD
DIRBUF		DB	318 DUP(?)	; DOS or long-name search result
SDIRBUF 	DB	104h DUP(?)	; first source name
BITS		DW	?
PATHCNT 	DW	?
PATHPOS 	DW	?
PATHSW		DW	?
AttrSpecified   db      ?                       ; attribute bits u.b. DIR
AttrSelect      db      ?                       ; attribute bits u.b. DIR
dirflag 	db	0			;AN015; set when pathcrunch called from DIR
	PUBLIC	ForTokenFound
	PUBLIC	ForVariable
ForTokenFound	DB	?
parse_last	dw	0			;AN018; used to hold parsing position

ForVariable	DB	2 DUP (?)
system_cpage	DW	0			;AC001; used for CHCP variable



; The attribute string terminator shares the file-size workspace.
	PUBLIC	DirAttributeText
DirAttributeText DB	6 DUP (?)
file_size_low	dw	?			;AC000;
file_size_high	dw	?			;AC000;
string_ptr_2	dw	?
;AD061;string_ptr_2_sb dw      ?
cpyflag 	db	?
DirCountOutput	DW	?
Dir_Num 	DW	?
ifdef DBLSPACE_HOOKS
Dir_CRatio_1	dw	?
Dir_CRatio_2	db	?
endif
bytes_free	dw	?
		dw	?
	PUBLIC	DirTotalBytes
	PUBLIC	DirUsedPercent
DirTotalBytes	dd	?
major_ver_num	dw	?
minor_ver_num	dw	?
one_char_val	db	?,0
vol_drv 	db	?
	PUBLIC	DirSortOverflow
DirSortOverflow DB	?

IFDEF ROMEXEC

	PUBLIC  ExecFromROM
ExecFromROM	db	?		; flag for ROM executable commands

ENDIF ; ROMEXEC

IF  IBM_ROM_FIND
ROM_CALL	DB	?			; flag for rom function
ROM_IP		DW	?
ROM_CS		DW	?
ENDIF

SCANBUF 	DB	104h DUP (?)

DESTVARS	LABEL	BYTE
DESTISDIR	DB	?
DESTSIZ 	DB	?
DESTTAIL	DW	?
DESTINFO	DB	?
DESTBUF 	DB	104h DUP (?)
ENDDESTBUF	LABEL	BYTE

DESTHAND	DW	?
DESTISDEV	DB	?
FIRSTDEST	DB	?

SRCVARS 	LABEL	BYTE
SRCISDIR	DB	?
SRCSIZ		DB	?
SRCTAIL 	DW	?
SRCINFO 	DB	?
SRCBUF		DB	104h DUP (?)

SRCHAND 	DW	?
SRCISDEV	DB	?
copy_Num	DW	?
comma		DB	0			;g flag set if +,, occurs
plus_comma	DB	0			;g flag set if +,, occurs
MELCOPY 	DB	?
MELSTART	DW	?

SRCPT		DW	?
INEXACT 	DB	?
NOWRITE 	DB	?
BINARY		DB	?
WRITTEN 	DW	?
TERMREAD	DB	?
ASCII		DB	?
PLUS		DB	?
objcnt		db	?		; Used in copy
CPDATE		DW	?
CPTIME		DW	?

OFilePtr_Lo	DW	?		; original file ptr for COPY when
OFilePtr_Hi	DW	?		; 1st source is also destination
OCtrlZ		DB	?		; original ctrl+Z for COPY when ditto

prompt_sublist	DB	parm_block_size DUP (?)	; COPY overwrite message substitution
confirm_overwrite DB	?		; prompt before overwriting
dest_exists	DB	?		; destination exists
copy_state	DB	?		; COPY control state
	PUBLIC	answer_buffer
answer_buffer	DB	?

BATHAND 	DW	?		; Batch handle
STARTEL 	DW	?
ELCNT		DB	?
ELPOS		DB	?
SKPDEL		DB	?
SOURCE		DB	11 DUP(?)

ext_entered	db	0			;AN005;

display_ioctl	db	0			;AN000; info level
		db	0			;AN000; reserved
		dw	crt_ioctl_ln		;AN000; length of data
		dw	?			;AN000; control flags
display_mode	db	?			;AN000; display mode, colors
		db	0			;AN000; reserved
		dw	?			;AN023; colors
		dw	?			;AN000; display width (PELS)
		dw	?			;AN000; display length (PELS)
display_width	dw	?			;AN000; display width
linperpag	dw	linesperpage		;AN000; display length (default to linesperpage)

vol_ioctl_buf	label	byte			;AN000; buffer for ioctl volume label/serial call
		dw	0			;AN000; info level
vol_serial	dd	0			;AN000; volume serial number
vol_label	db	11 dup (" ")            ;AN000; volume label - init to blanks
		db	8  dup (" ")            ;AN000; file system type

expand_star	db	?
msg_flag	db	?			;AN022; flag set if non-utility message issued
msg_numb	dw	0			;AN022; set with extended error message issued
append_exec	db	0			;AN041; set if internal append executed
print_err_flag	dw	0			;AN000; flag set if error during sysdispmsg
subst_buffer	db	parm_block_size*2 dup (0);AN061;

;;;;	IFDEF	DBCS		3/3/KK
KPARSE		DB	?
;;;;	ENDIF			3/3/KK

; Data declarations taken out of parse.asm

arg	arg_unit	<>			; pointers, arg count, string buffer
	PUBLIC	ArgBufferEnd
	PUBLIC	ParseSwitchFlag
	PUBLIC	ParseArgIndex
	PUBLIC	ParseFileArg
	PUBLIC	ParseResultType
	PUBLIC	ParseResultValue
	PUBLIC	ParseDateParts
		DW	?			; reserved parser word
ArgBufferEnd	DW	?
		DW	?			; reserved parser word
argbufptr	DW	?			; index for argv[].argpointer
ComBufPtr	DW	?			; command buffer pointer
LAST_ARG	DW	?			; point at which to accumulate switch info
comptr		dw	?			; ptr into combuf

; Data declarations taken out of path.asm
fbuf	find_buf	<>			; dma buffer for findfirst/findnext
pathinfo	DW	3 DUP (?)		; ES, SI(old), and SI(new) of user path
psep_char	DB	?			; '/' or '\'
search_best	DW	(?)			; best code, best filename so far
fname_max_len	equ	13
search_best_buf DB	fname_max_len DUP (?)
search_curdir_buf DB	64 DUP (?)		; a place for CurDir info, if successful
search_error	DW	(?)			; address of error message to be printed

; Data declarations taken out of tbatch.asm
if_not_count	DW	?

zflag		db	?			; Used by typefil to indicate ^Z's

	PUBLIC	StackGuard
StackGuard	DW	55AAh			; transient stack boundary
		DW	100H DUP(55AAh)		; transient stack
STACK		LABEL	WORD

INTERNATVARS	internat_block <>
		DB	(internat_block_max - ($ - INTERNATVARS)) DUP (?)

;		Buffer for DOS function 64h (Get extended country information)
;		subfunctions 2, 4, 6, or 7:

CountryPtrInfo	label	byte
CountryPtrId	db	?
CountryPtr	dd	?
		.erre	(($ - CountryPtrInfo) GE 5)

OldCtrlCHandler	dd	?			; previous int 23 vector


BatBufPos	DW	?			; integer position in buffer of next byte
BatBuf		DB	BatLen DUP (?)
BatBufEnd	DW	?

TypeFilSiz	dd	?		;stores size of file to be typed

msg_disp_class	db	Util_msg_class
msg_cont_flag	db	No_cont_flag

;  extended error string output
;
Extend_Buf_ptr	dw	0				;AN000;set to no message
Extend_Buf_sub	db	0				;AN000;set to no substitutions
		db	parm_block_size 		;AN000;size of sublist
		db	0				;AN000;reserved
Extend_Buf_off	dw	OFFSET	TranGroup:String_ptr_2	;AN000;offset of arg
Extend_Buf_seg	dw	0				;AN000;segment of arg
		db	0				;AN000;first subst
		db	0				; message format byte
		dw	128				;AN000;maximum width
		dw	0				;AN000;minimum width
		db	blank				;AN000;pad character


; *****************************************************
; EMG 4.00
; DATA STARTING HERE WAS ADDED BY EMG FOR 4.00
; FOR IMPLEMENTATION OF COMMON PARSE ROUTINE
; *****************************************************
;
; COMMON PARSE OUTPUT BLOCKS
;


;
; Common output blocks for PARSE number, complex, or string values.
;

	PUBLIC	DirDateTimeBuffer
DirDateTimeBuffer DB	48 DUP (?)

PARSE1_OUTPUT	LABEL	BYTE			;AN000;
PARSE1_TYPE	DB	0			;AN000;  type
PARSE1_CODE	DB	0			;AN000;  return value
PARSE1_SYN	DW	0			;AN000;  es offset of synonym
PARSE1_ADDR	DD	0			;AN000;  numeric value / address
						;	 of string value

;
;  Common output block for PARSE date strings.
;

DATE_OUTPUT	LABEL	BYTE			;AN000;
DATE_TYPE	DB	0			;AN000;  type
		DB	0			;AN000;  return value
		DW	0			;AN000;  es offset of synonym
DATE_YEAR	DW	0			;AN000;  year
DATE_MONTH	DB	0			;AN000;  month
DATE_DAY	DB	0			;AN000;  day

;
;  Common output block for PARSE time strings.
;

TIME_OUTPUT	LABEL	BYTE			;AN000;
TIME_TYPE	DB	0			;AN000;  type
		DB	0			;AN000;  return value
		DW	0			;AN000;  es offset of synonym
TIME_HOUR	DB	0			;AN000;  hour
TIME_MINUTES	DB	0			;AN000;  minutes
TIME_SECONDS	DB	0			;AN000;  seconds
TIME_FRACTION	DB	0			;AN000;  hundredths

;
;  Common output block for PARSE drive specifier (one based drive number).
;

DRIVE_OUTPUT	LABEL	BYTE			;AN000;
DRIVE_TYPE	DB	0			;AN000;  type
DRIVE_VALUE	DB	0			;AN000;  return value
		DW	0			;AN000;  es offset of synonym
DRIVE_NUMBER	DB	0			;AN000;  drive number
		DB	0,0,0			;AN000;  reserved

; File system pathname interface, initialized by SelectPathInterface.
	PUBLIC	PathQueryRoot
	PUBLIC	PathChdirFunction
	PUBLIC	PathGetdirFunction
	PUBLIC	PathOpenFunction
	PUBLIC	PathAttribFunction
	PUBLIC	PathFindMode
	PUBLIC	PathFindHandle
	PUBLIC	DirBasePath
	PUBLIC	DirTraversalActive
	PUBLIC	DirOutputBuffer
	PUBLIC	DeleteCount
	PUBLIC	DeleteError
	PUBLIC	DirSearchPath
	PUBLIC	DirEntryPath
	PUBLIC	DirSearchPos
	PUBLIC	DirEntryPos
	PUBLIC	DirSearchLength
	PUBLIC	DirSavedByteCount
	PUBLIC	DirHeaderPending
	PUBLIC	DirClusterSize
	PUBLIC	DirClusterInvalid
	PUBLIC	DirNeedInfo
	PUBLIC	DirSectorShift
	PUBLIC	DirBytesPerSector
	PUBLIC	DirFreeClusters
	PUBLIC	DirTotalClusters
	PUBLIC	PathFindBuffer
	PUBLIC	CopyDestMode
	PUBLIC	RenameSourceArg
	PUBLIC	PathRmdirFunction
	PUBLIC	PathMkdirFunction
	PUBLIC	PathRenameFunction
	PUBLIC	CopySourceOpenFunction
	PUBLIC	CopyDestOpenFunction
	PUBLIC	CopyFindDataOffset
	PUBLIC	CopyPatternExt
	PUBLIC	CopySourceExt
	PUBLIC	DirNetworkPath
	PUBLIC	CopyDestOpenAction
DirBasePath	DB	104h DUP (?)
DirSearchPos	DW	?
DirEntryPos	DW	?
PathFindMode	DB	?
CopyDestMode	DB	?
DirSearchLength DW	?
RE_INSTR	DB	104h DUP (?)	; path for input to redirection
DirSearchPath	DB	104h DUP (?)	; directory search path
DirEntryPath	DB	104h DUP (?)	; current directory entry
PathQueryRoot	DB	'A:\',0
PathFindHandle	DW	?
RenameSourceArg DW	?
PathFindBuffer	DB	318 DUP (?)
PathChdirFunction DW	?
PathGetdirFunction DW	?
PathRmdirFunction DW	?
PathMkdirFunction DW	?
PathOpenFunction DW	?
PathRenameFunction DW	?
PathAttribFunction DW	?
CopySourceOpenFunction DW ?
CopyDestOpenFunction DW ?
CopyFindDataOffset DW ?
CopyPatternExt	DW	?
CopySourceExt	DW	?
DirNetworkPath	DB	?		; nonzero for a UNC pathname
CopyDestOpenAction DB	?
DirOutputBuffer DB	15Ah DUP (?)
DeleteCount	EQU	DirOutputBuffer+156h
DeleteError	EQU	DirOutputBuffer+158h
DirTraversalActive DB	?
DirSavedByteCount DW	?
	PUBLIC	answer_yes
	PUBLIC	answer_no
	PUBLIC	answer_all
answer_yes	DB	?
answer_no	DB	?
answer_all	DB	?

	PUBLIC	SavedBatchPosition
SavedBatchPosition DD	-1
	PUBLIC	EnvCaseMode
EnvCaseMode	DB	?

COMBUF		LABEL	BYTE		; Cooked console workspace
TRANSPACEEND	LABEL	BYTE
		DB	COMBUFLEN,0	; cooked input buffer prefix
arg_buf		EQU	TRANSPACEEND+2	; dynamic message workspace

TRANSPACE	ENDS
	END

