	page	,132
	title	DIR Internal Command
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;***	DIR.ASM - DIR internal command

comment	% =================================================================

This module replaces TCMD1A.ASM.  The old module was titled 
"PART4 COMMAND Transient routines".

From residual documentation, I surmise that TCMD.ASM originally
contained the internal commands DIR, PAUSE, ERASE, TYPE, VOL, and
VER.  The file seems to have been successively split:

  TCMD -> TCMD1,TCMD2 -> TCMD1A,TCMD1B,TCMD2A,TCMD2B

TCMD1A.ASM contained only the DIR command.

Usage:
------

DIR <filespec> /w /p /b /s /l /c /o<sortorder> /a<attriblist>

DIR /?


<filespec> may include any or none of:  drive; directory path;
           wildcarded filename.  If drive or directory path are
	   omitted, the current defaults are used.  If the
	   file name or extension is omitted, wildcards are
	   assumed.

/w	Wide listing format.  Files are displayed in compressed
	'name.ext' format.  Subdirectory files are enclosed in
	brackets, '[dirname]'.

/p	Paged, or prompted listing.  A screenful is displayed
	at a time.  The name of the directory being listed appears
	at the top of each page.

	Bugbug:  pages nead to be uniform length..?

/b	Bare listing format.  Turns off /w or /p.  Files are 
	listed in compressed 'name.ext' format, one per line,
	without additional information.  Good for making batch
	files or for piping.  When used with /s, complete
	pathnames are listed.

/s	Descend subdirectory tree.  Performs command on current
	or specified directory, then for each subdirectory below
	that directory.  Directory header and footer is displayed
	for each directory where matching files are found, unless
	used with /b.  /b suppresses headers and footers.

	Tree is explored depth first, alphabetically within the
	same level.

	Bugbug:  hidden directories aren't searched.

/l	Display file names, extensions and paths in lowercase.	;M010

/c	Display file compression ratio, if the file is on a MagicDrv
	compressed volume.

/o	Sort order.  /o alone sorts by default order (dirs-first, name,
	extension).  A sort order may be specified after /o.  Any of
	the following characters may be used: nedsgc (name, extension,
	date/time, size, group-dirs-first, compression ratio).	Placing
	a '-' before any letter causes a downward sort on that field.
	E.g., /oe-d means sort first by extension in alphabetical order,
	then within each extension sort by date and time in reverse
	chronological order.

/a	Attribute selection.  Without /a, hidden and system files
	are suppressed from the listing.  With /a alone, all files
	are listed.  An attribute list may follow /a, consisting of
	any of the following characters:  hsdar (hidden, system,
	directory, archive, read-only).  A '-' before any letter
	means 'not' that attribute.  E.g., /ar-d means files that
	are marked read-only and are not directory files.  Note
	that hidden or system files may be included in the listing.
	They are suppressed without /a but are treated like any other
	attribute with /a.

/?	Help listing.  Display DIR useage information.	;M008;Handled externally

/h has been removed.					;M008

DIRCMD	An environment variable named DIRCMD is parsed before the
	DIR command line.  Any command line options may be specified
	in DIRCMD, and become defaults.  /? will be ignored in DIRCMD.
	A filespec may be specified in DIRCMD and will be used unless
	a filespec is specified on the command line.  Any switch
	specified in DIRCMD may be overridden on the command line.
	If the original DIR default action is desired for a particular
	switch, the switch letter may be preceded by a '-' on the
	command line.  E.g.,

	  /-w	use long listing format
	  /-p	don't page the listing
	  /-b	don't use bare format
	  /-s	don't descend subdirectory tree
	  /-o	display files in disk order
	  /-a	suppress hidden and system files


Notes:
------

For sorted listings, file entries are loaded into the TPA buffer, which
is usually about 64K in size.  This allows sorts of up to 3000 files at
a time.  Each entry takes up 21 bytes in the buffer (see EntryStruc below).
The byte after the last entry is 0FFh.  The first byte of each entry is
a flag byte which is made zero when the entry is loaded, and made one
when the entry is used.


Revision History
================
M01	md	7/13/90 	Use ROM BIOS data area to obtain screen height
				in the absence of ANSI.SYS

M007	sa	8/1/90		Allow /p/b combination

M008	sa	8/1/90		Remove /h parameter.  Eliminate code used
				to internally handle /? message.

M010	sa	8/5/90		Add support for /l (lowercase) option.

M011	sa	8/5/90		Patch up bug where MS-DOS does not load the
				first FCB with the drive number when the drive
				letter in the command line is preceded by a
				switch.  Now dir manually loads the drive
				number after parsing.

M018	md	8/12/90 	Increment the screen height by 1 when obtained
				from the ROM BIOS.

M023	sa	8/31/90		Prevent DIR from failing if it encounters
				a subdirectory having len(pathname)>MAXPATH.
				Just skip over that subdirectory.

M028	dbo	9/24/90		When country=US, sort by strict character
				byte value, rather than collating table.
				This to match MS-DOS Shell's sort order.

========================================================================= %




;***	SYMBOLS & MACROS

	.xlist
	.xcref

	include version.inc
	include	comsw.asm	; get COMMAND version switches
	include dossym.inc	; get DOS basic symbol set
	include syscall.inc	; get DOS call names
	include doscntry.inc	; get extended country info symbols
	include bpb.inc
	include filemode.inc
	include find.inc
	include	comseg.asm	; define segment order
	include comequ.asm	; get equates for COMMAND routines
	include ioctl.inc	; get symbols for ioctl's
	include rombios.inc	; get ROM BIOS data definition

	.list
	.cref

				;M008;NUM_DIR_SWS reduced by 2 for /h,/? not used
				;M010;NUM_DIR_SWS increased by 2 for /l,/-l
ifdef DBLSPACE_HOOKS
NUM_DIR_SWS	equ	20	; # of dir switch synonyms in Dir_Sw_Ptrs list
else
NUM_DIR_SWS	equ	18	; # of dir switch synonyms in Dir_Sw_Ptrs list
endif
				;M010;'lcase' replaces removed 'help' in OptionRec
ifdef DBLSPACE_HOOKS
OptionRec	record	inmem:1,dirz:1,cratio:1,verbose:1,lcase:1,bare:1,subd:1,pagd:1,wide:1
else
OptionRec	record	inmem:1,dirz:1,reserved:1,verbose:1,lcase:1,bare:1,subd:1,pagd:1,wide:1
endif

;		on/off bit record for /l, /b, /s, /p, /w, /c options
;		(order is hard-coded; see OnOffSw)
;		Inmem is set when entries are loaded in memory.

NUM_ATTR_LTRS	equ	6	; length of attribute letter list

ifdef DBLSPACE_HOOKS
NUM_ORDER_LTRS	equ	7	; length of sort order letter list
CRATIO_ORDER	equ	7	; position of 'C' in ORDER_LTRS
else
NUM_ORDER_LTRS	equ	6	; length of sort order letter list
endif



ResultBuffer	struc		; structure of parse result buffer
ValueType	db	?
ValueTag	db	?
SynPtr		dw	?
ValuePtr	dd	?
ResultBuffer	ends

ErrorRec	record	baddir:1,dev:1
;		Error bits are:
;		  Invalid directory format
;		  File is device

EntryStruc	struc			; our private directory entry structure
used		db	?		; =0 until entry used, then =1
filename	db	8 dup (?)	; filename
fileext		db	3 dup (?)	; extension
fileattr	db	?		; file attributes
filetime	dw	?		; file time
filedate	dw	?		; file date
filesize	dd	?		; file size
fileaccessdate	dw	?		; last access date
compratio	dw	?		; compression ratio
longname	dw	?		; long filename in TPA
EntryStruc	ends

shove	macro	val		; hose-bag 8086 doesn't push immediate
	mov	ax,val		; invisible, dangerous use of AX!
	push	ax
	endm


	
	
;***	DATA

DATARES	segment public byte

	extrn	Append_Flag:byte	; true when APPEND needs to be reset
	extrn	Append_State:word	; state to reset APPEND to

DATARES	ends


TRANDATA segment public byte

	extrn	AttrLtrs:byte		; list of attribute letters
	extrn	BadCd_Ptr:word		; "invalid directory" msg block
	extrn	Bytes_Ptr:word		; "%1 bytes" msg block
	extrn	BytMes_Ptr:word		; "%1 bytes free" msg block
ifdef DBLSPACE_HOOKS
	extrn	DirCompRatio_Ptr:word	; compression ratio msg block
	extrn	AveCompRatio_Ptr:word	; average comp ratio msg block
endif
	extrn	DirEnvVar:byte		; DIR environment variable name

	extrn	EnvCaseMode:byte	; environment name matching mode
	extrn	cpyflag:byte, EXECPATH:byte
	extrn	DirDateTimeTemplate:byte, DirAttributePtr:word
	extrn	DirVerboseHeader_Ptr:word, Acrlf_Ptr:word
	extrn	DirContRoot_Ptr:word, DirContCurrent_Ptr:word
	extrn	DirRootHead_Ptr:word
	extrn	DirHead_Ptr:word	; directory header message block
	extrn	DirMes_Ptr:word		; "%1 File(s)" msg block
	extrn	Dir_Sw_Ptrs:word	; list of DIR switch synonym ptrs
	extrn	Disp_File_Size_Ptr:word	; file size message block
	extrn	DMes_Ptr:word		; <DIR> message block
	extrn	ErrParsEnv_Ptr:word	; "(Error occurred in env.." msg blk
	extrn	Extend_Buf_Ptr:word	; extended error message block
	extrn	Extend_Buf_Sub:byte	; # substitions in message block
	extrn	Msg_Disp_Class:byte	; message display class
	extrn	OrderLtrs:byte		; list of sort order letters
	extrn	String_Buf_Ptr:word	; message block ptr to string
	extrn	Tab_Ptr:word		; tab output block
	extrn	Total_Ptr:word		; "Total:" msg block

TRANDATA ends


TRANSPACE segment public byte
	extrn	DirOutputPtr:dword, DirOutputActive:byte

	extrn	DirArgumentCount:byte


ifdef DBLSPACE_HOOKS
	extrn	DirCompressionMask:dword, DirCompressionShift:byte
endif

	extrn	arg:byte			; parsed argument array
	extrn	AttrSelect:byte		; attribute select states -
	extrn	AttrSpecified:byte	; attribute mask -

;		Attribute conditions are recorded in two steps.  
;		AttrSpecified indicates which attributes are to be checked.
;		AttrSelect indicates which state the specified attributes
;		 must be in for a file to be included in the listing.
;		Attributes not indicated in AttrSpecified are ignored when
;		 deciding which files to include.

	extrn	Bits:word		; some option flags (see OptionRec)
	extrn	BwdBuf:byte		; 'build working dir string' buf
	extrn	BytCnt:word		; # bytes in TPA
	extrn	DirTotalBytes:dword, DirUsedPercent:word
	extrn	DirDiskUsage_Ptr:word
	extrn	Bytes_Free:word		; #bytes free for BytMes_Ptr msg block
	extrn	CharBuf:byte		; character string buffer
	extrn	ComSw:word		; error bits (see ErrorRec)
	extrn	CountryPtrInfo:byte	; buffer for collating table ptr
	extrn	CountryPtrId:byte	; info ID for collating table ptr
	extrn	CountryPtr:dword	; collating table ptr
	extrn	CurDrv:byte		; current drive # (0-based)
	extrn	DestBuf:byte		; null-terminated sort codes -

;	Sort order is specified as a series of 0 to 5 sort code
;	bytes, followed by a zero byte.
;	Codes are 1=name, 2=extension, 3=date&time, 4=size, and
;	5=filetype (subdir or not).
;	Bit 7 of code is set for a downwards sort.

	extrn	DestIsDir:byte		; indicator of delim char's in path
	extrn	DestTail:word		; ptr to filename in pathname
	extrn	Dir_Num:word		; #files for DirMes_Ptr msg block
ifdef DBLSPACE_HOOKS
	extrn	Dir_CRatio_1:word	; Compression ratio for msg block
	extrn	Dir_CRatio_2:byte	; Compression ratio for msg block
endif
	extrn	DirBuf:byte		; DTA buffer for DOS calls
	extrn	DirSearchPath:byte, DirEntryPath:byte
	extrn	DirSearchPos:word, DirEntryPos:word, DirSearchLength:word
	extrn	DirHeaderPending:byte, PathFindHandle:word
	extrn	PathFindBuffer:byte
	extrn	DirDateTimeBuffer:byte, DirSavedByteCount:word
	extrn	DirAttributeText:byte
	extrn	DirBasePath:byte, DirTraversalActive:byte, DirOutputBuffer:byte
	extrn	DirClusterSize:word, DirClusterInvalid:byte, DirNeedInfo:byte
	extrn	DirSectorShift:byte, DirBytesPerSector:word
	extrn	DirFreeClusters:word, DirTotalClusters:word
	extrn	DirFlag:byte		; signal to PathCrunch routine
	extrn	Display_Ioctl:word	; display info block for IOCTL call
	extrn	EndDestBuf:byte		; end of DestBuf (sort order codes)
	extrn	File_Size_High:word	; field for file size message block
	extrn	File_Size_Low:word	; field for file size message block
	extrn	DirEntryCount:word, DirCount:word, DirCountTotal:dword
	extrn	DirAllocatedBytes:dword, DirCountOutput:word
	extrn	DirAllocatedClusters:word, DirAllocatedClustersTotal:word
	extrn	DirCount_Ptr:word, DirAllocated_Ptr:word
	extrn	DirSortOverflow:byte, DirSortOverflow_Ptr:word
	extrn	FileCnt:word		; file count in a single directory
	extrn	FileCntTotal:dword	; file count in all directories
	extrn	FileSiz:dword		; file sizes in a single directory
	extrn	FileSizTotal:dword	; file sizes in all directories
	extrn	InternatVars:byte	; buffer for international info
	extrn	LeftOnLine:byte		; entries left on current display line
	extrn	LeftOnPage:word		; lines left on page
	extrn	LinPerPag:word		; lines/page entry in Display_Ioctl
	extrn	Msg_Numb:word		; extended error code
	extrn	OldCtrlCHandler:dword	; old int 23 vector
	extrn	Parse1_Syn:word		; ptr to matched synonym
	extrn	PathCnt:word		; length of pathname (see PathPos)
	extrn	PathFindMode:byte, DirNetworkPath:byte
	extrn	DirUNCError_Ptr:word
	extrn	PathChdirFunction:word, PathGetdirFunction:word
	extrn	PathAttribFunction:word
	extrn	PathPos:word		; ptr to pathname buffer (see SrcBuf)
	extrn	PerLine:byte		; # entries per line
	extrn	ResSeg:word		; RESGROUP seg addr
	extrn	ScanBuf:byte		; buffer for environment value and
					;  subdirectory names
	extrn	SrcBuf:byte		; pathname buffer
	extrn	String_Ptr_2:word	; message substitution string ptr
	extrn	Tpa:word		; TPA buffer seg addr
ifdef DBLSPACE_HOOKS
	extrn	csecUsed:dword		; count of compressed sectors used-file
	extrn	csecUsedDir:dword	; count of compressed sectors used-dir
	extrn	csecUsedTotal:dword	; count of compressed sectors used-total
	extrn	ccluUsed:word		; count of DOS clusters used - file
	extrn	ccluUsedDir:word	; count of DOS clusters used - dir
	extrn	ccluUsedTotal:word	; count of DOS clusters used - total
	extrn	csecPerCluster:byte
	extrn	fUseHostSize:byte	; use host cluster size with /C
endif

TRANSPACE ends




;***	PRINCIPAL ROUTINES

TRANCODE segment public byte
	extrn	DirStoreArgument:near
	extrn	DirAppendWildcard:near
	extrn	DirAppendEntryName:near
	extrn	DirAppendSearchName:near
	extrn	DirSetEntryPosition:near
	extrn	DirNormalizePattern:near
	extrn	MOVE_TO_SRCBUF:near
	extrn	DirRoundCompressionClusters:near

	extrn	CError:near		; COMMAND error recycle point
	extrn	TCOMMAND:near
	extrn	Print_Char:near
	extrn	SelectPathInterface:near
	extrn	argv_calc:near, TSYSGETMSG:near
ifdef DBLSPACE_HOOKS
	extrn	ComputeRatio:near	; Calculate ratio of two sector counts
endif

	public	Catalog		; our entry point

	break	<DIR (Catalog) principal routines>

	assume	cs:TRANGROUP,ds:TRANGROUP,es:nothing,ss:TRANGROUP

;	Bugbug:	Each routine should start with it's own ASSUME.




;***	Catalog - DIR command main routine
;
;	ENTRY	FCB #1 in PSP has drive# from cmd-line or default
;		Cmd-line tail text is at 81h, terminated by 0Dh
;		CS, DS, ES, SS = TRANGROUP seg addr
;		Tpa = TPA buffer seg addr
;		BytCnt = # bytes in TPA buffer
;
;	EXIT	nothing
;
;	USED	AX,BX,CX,DX,SI,DI,BP
;
;	ERROR EXITS
;
;	  Errors are handled by setting up error message pointers
;	   for Std_EPrintf and jumping to CError.  Syntax errors in
;	   the environment variable, however, are handled by printing
;	   an error message and continuing.
;
;	EFFECTS
;
;	  Directory listing is displayed (on standard output).
;	  APPEND is disabled.  HeadFix routine is expected to
;	   restore APPEND state.
;	  Working directory may be changed.  The user's default
;	   directory is saved and flagged for restoration by RestUDir
;	   during COMMAND cycle.
;	  Lots of variables may be changed in TRANSPACE segment.
;
;	NOTES
;
;	  ES = TRANGROUP seg addr except when used to address the
;	   the TPA buffer, where directory entries are loaded from disk.

Catalog	proc

	call	SetDefaults
	call	ParseEnvironment
	call	ParseCmdLine
	jnc	@F		; no parse error
	jmp	catRet		; parser has handled the error
@@:	mov	si,offset TRANGROUP:DirSearchPath
	call	DirSelectPathInterface
	mov	PathFindMode,al
	call	SetOptions
	call	SetCollatingTable

;	Drive # to operate on has already been placed in FCB by
;	COMMAND preprocessing.  OkVolArg & PathCrunch depend on that.

	test	Bits,mask bare
	jnz	@F		; don't display volume info for /b
	mov	si,offset TRANGROUP:DirSearchPath
	invoke	IsNetworkPath
	mov	DirNetworkPath,al
	or	al,al
	jz	short catVolume
	test	Bits,mask subd or mask verbose or mask cratio
	jz	@F
	mov	dx,offset TRANGROUP:DirUNCError_Ptr
	jmp	CError
catVolume:
	invoke	OkVolArg	; find & display volume info
	sub	LeftOnPage,2	; record display lines used by volume info
	jmp	short catCrunch

;	OkVolArg side effects:
;	APPEND is disabled;
;	DTA established at DirBuf;
;	Filename fields in FCB are wildcarded.

@@:
;	OkVolArg wasn't executed, so we have to do these ourselves.

	invoke	DisAppend	; disable APPEND

	mov	dx,offset TRANGROUP:DirBuf
	mov	ah,Set_DMA
	int	21h		; set DTA

	mov	di,FCB		; ES:DI = ptr to FCB
	inc	di		; ES:DI = ptr to filename field of FCB
	mov	al,'?'		; AL = wildcard character
	mov	cx,11
	rep	stosb		; wildcard filename field

catCrunch:
	call	CrunchPath	; crunch pathname to get directory and filename
	jc	catRecErr	; handle recorded or extended error
	call	DirNormalizePattern	; complete the search pattern
	call	BuildDirBasePath	; preserve the initial directory path
	invoke	RestUDir1		; restore before searching the supplied path

;	User's directory has been saved, we've changed to specified directory.
;	ComSw = error bits for later use
;	FCB contains parsed filename

	cmp	ComSw,0
	jne	catRecErr	; handle recorded error

	call	InstallCtrlC	; install control-C handler
ifdef DBLSPACE_HOOKS
	test	Bits, mask cratio	; compression ratio wanted?
	jz	@f

	call	DirInitCompression	; yes, initialize volume geometry
	jnc	@f			; CY clear if geometry is available

	and	Bits, not (mask cratio) ; failed, clear cratio option bit
@@:
endif
	call	ZeroTotals	; zero grand totals
	mov	DirTraversalActive,0
	call	ListDir		; list main directory
	jnc	@F
	jmp	catExtErr
@@:

	test	Bits,mask subd
	jz	@F		; subdirectories option not set
	call	DirSearchDrive
	invoke	SavUDir
	invoke	SetRest1
	call	ChangeDirBasePath
	call	DirMakeRelativePattern
	call	DirNormalizePattern
	mov	DirTraversalActive,1
	call	ListSubds	; list subdirectories
	pushf
	invoke	RestUDir1	; restore user directory after recursion
	popf
	jc	catExtErr
@@:
;	Check if any files were found.

	test	Bits,mask bare
	jnz	catRet		; don't bother for bare format

	mov	ax,word ptr FileCntTotal
	or	ax,ax
	jnz	short catHaveFiles
	cmp	word ptr DirCountTotal,0
	jz	catNoFiles
catHaveFiles:

	call	DisplayTotals	; display trailing grand totals
	jmp	short catRet	; all done

catRecErr:
	mov	DirTraversalActive,1

;	ComSw may have error bit set.  If not, do extended error.

	test	ComSw,mask dev
	jnz	catNoFiles	; filename is device, respond 'file not found'

	test	ComSw,mask baddir
	jz	catExtErr	; no ComSw error bits, must be extended error
	mov	dx,offset TRANGROUP:BadCd_Ptr	; invalid directory
	jmp	short catErr

catNoFiles:

;	Display header and force 'file not found' message.

	call	DisplayHeader
	invoke	Crlf2
	mov	ax,ERROR_FILE_NOT_FOUND
	mov	Msg_Disp_Class,EXT_MSG_CLASS
	mov	dx,offset TRANGROUP:Extend_Buf_ptr
	mov	Extend_Buf_ptr,ax
	invoke	Std_EPrintf
	test	ComSw,mask dev
	jnz	short catNoFilesDone
	mov	ax,19
	call	DirPrintPadding
	call	dtFree
catNoFilesDone:
	jmp	TCOMMAND

catExtErr:

;	DOS has returned an error status.  Get the extended error#, and
;	set up an error message, changing 'No more files' error 
;	to 'File not found' error.

	invoke	Set_Ext_Error_Msg
	cmp	Extend_Buf_Ptr,ERROR_NO_MORE_FILES
	jne	@F
	mov	Extend_Buf_Ptr,ERROR_FILE_NOT_FOUND
@@:

;	Error exit.  Error message information has been set up
;	for Std_EPrintf.

catErr:
	jmp	CError

catRet:
	ret

Catalog	endp




;***	SetDefaults - set default pathname, options
;
;	ENTRY	DS = TRANGROUP seg addr
;
;	EXIT	nothing
;
;	USED	AX,DI
;
;	EFFECTS
;	  SrcBuf = '*',EOL - default pathname
;	  PathPos = ptr to pathname
;	  PathCnt = length of pathname



	public	SetDefaults
SetDefaults	proc

	mov	ax,'*'			; default search pathname
	mov	word ptr DirSearchPath,ax
	mov	word ptr DirEntryPath,ax
	mov	DirSearchLength,1
	mov	DirEntryPos,offset TRANGROUP:DirEntryPath
	mov	si,offset TRANGROUP:DirSearchPath
	mov	DirSearchPos,si
	mov	di,offset TRANGROUP:SrcBuf	; DI = ptr to pathname buffer
	mov	PathPos,di			; PathPos = ptr to pathname
	mov	al,STAR
	stosb
	mov	al,END_OF_LINE_IN
	stosb				; SrcBuf = '*',0Dh
	mov	PathCnt,1		; PathCnt = pathname length

	mov	DirHeaderPending,0	; no pending header
	xor	ax,ax			; AX = 0
	mov	Bits,ax			; = options off
	mov	PathFindHandle,ax	; no open directory search
	mov	ComSw,ax		; = no error
	mov	DestBuf,al		; = no sort
	mov	AttrSpecified,ATTR_HIDDEN+ATTR_SYSTEM
	mov	AttrSelect,al		; exclude hidden, system files
	mov	DirClusterSize,ax	; drive cluster size not yet known
	mov	DirClusterInvalid,0
	mov	DirNeedInfo,0
ifdef DBLSPACE_HOOKS
	mov	fUseHostSize, al	; use CVF cluster size, not Host
endif
	mov	di,offset TRANGROUP:DirDateTimeBuffer
	mov	si,offset TRANGROUP:DirDateTimeTemplate
	mov	cx,48
	rep	movsb
	mov	ax,BytCnt
	mov	DirSavedByteCount,ax
	ret

SetDefaults	endp




;***	ParseEnvironment - find and parse our environment variable
;
;	Find our environment variable and parse it.  If a parse
;	error occurs, issue an error message.  The parse results
;	up to the error will still have effect.  Always leave
;	the option variables in a useable state.
;
;	ENTRY	DS = TRANGROUP seg addr
;
;	EXIT	nothing
;
;	USED	AX,BX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Bits may contain new option settings.
;	  DestBuf may contain new series of sort codes.
;	  AttrSpecified, AttrSelect may contain new attribute conditions.
;	  SrcBuf may contain a new default pathname/filespec.
;	  PathPos, PathCnt updated for new pathname.
;
;	  If a parse error occurred, an error message will be issued.

	public	ParseEnvironment
ParseEnvironment proc
	call	GetEnvValue
	jc	short peRet
	mov	cpyflag,2
peNext:
	mov	di,offset TRANGROUP:EXECPATH
	xor	bp,bp
	mov	bl,' '
	invoke	CPARSE
	jc	short peEnd
peArgument:
	push	si
	mov	si,offset TRANGROUP:EXECPATH
	call	DirParseArgument
	jnc	short peContinue
	invoke	Std_EPrintf
	mov	Msg_Disp_Class,UTIL_MSG_CLASS
	mov	dx,offset TRANGROUP:ErrParsEnv_Ptr
	invoke	Printf_Crlf
	pop	si
peRet:
	ret
peContinue:
	pop	si
	jmp	short peNext
peEnd:
	or	bp,bp
	jz	short peRet
	inc	si
	jmp	short peArgument
ParseEnvironment endp




;***	ParseCmdLine - parse and record command line parameters
;
;	ENTRY	PSP offset 81h is beginning of cmd line buffer
;		DS, ES, CS = TRANGROUP seg addr
;
;	EXIT	CY = set if parse error occurred
;
;		If parse error occurred, we're set up for Std_EPrintf call:
;		AX = system parser error code
;		DX = ptr to message block
;
;	USED	AX,BX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Bits may contain new option settings.
;	  DestBuf may contain new series of sort codes.
;	  AttrSpecified, AttrSelect may contain new attribute conditions.
;	  SrcBuf may contain a new default pathname/filespec.
;	  PathPos, PathCnt updated for new pathname.
;
;	  If parse error occurred, we're set up for Std_EPrintf call:
;	  Msg_Disp_Class = parse error class
;	  Byte after last parameter in text is zeroed to make ASCIIZ string
;	  Message block (see DX) is set up for parse error message

	public	ParseCmdLine
ParseCmdLine proc
	mov	DirArgumentCount,0
	mov	bx,0
pcNext:
	inc	bx
	cmp	bx,arg.argvcnt
	jae	short pcRet
	push	bx
	mov	ax,offset TRANGROUP:arg.argv
	call	argv_calc
	mov	si,[bx].argpointer
	mov	bp,[bx].argsw_word
	push	cx
	mov	cx,bx
	mov	bh,[bx].argflags
	call	DirParseArgument
	pop	cx
	jnc	short pcNextArg
	invoke	Std_EPrintf
	jmp	short pcError
pcNextArg:
	pop	bx
	jmp	short pcNext
pcError:
	pop	bx
	stc
pcRet:
	ret
ParseCmdLine endp

; Process one shared argument, permitting at most one pathname.
	public	DirParseArgument
DirParseArgument proc near
	test	bh,mask sw_flag
	jnz	short dpaSwitch
	inc	DirArgumentCount
	cmp	DirArgumentCount,1
	jna	short dpaPath
	mov	ax,1
	call	DirSetupParamError
	jmp	short dpaError
dpaPath:
	push	bx
	mov	bx,cx
	call	DirStoreArgument
	pop	bx
	call	MOVE_TO_SRCBUF
dpaSuccess:
	clc
dpaSuccessRet:
	ret
dpaSwitch:
	call	DirDispatchSwitch
	jnc	short dpaSuccessRet
dpaError:
	stc
	jmp	short dpaSuccessRet
DirParseArgument endp


ifdef DBLSPACE_HOOKS


; Parse the optional host-size suffix at DS:SI.
	public	DirParseRatio
DirParseRatio proc near
	call	OnOffSet
	mov	ax,[si]
	or	al,al
	jz	short dprDone
	cmp	ax,'H'
	je	short dprDone
	call	DirSetupParamError
	stc
	jmp	short dprReturn
dprDone:
	mov	fUseHostSize,al
	clc
dprReturn:
	ret
DirParseRatio endp
endif



; Parse a switch from the shared command argument array.
	public	DirDispatchSwitch, DirDispatchHandlers, DirMatchSwitch
DirDispatchSwitch proc near
	mov	di,offset TRANGROUP:Dir_Sw_Ptrs
	mov	cx,NUM_DIR_SWS
	call	DirMatchSwitch
	jc	short ddsError
	mov	di,NUM_DIR_SWS
	sub	di,cx
	shl	di,1
	push	si
	call	word ptr cs:DirDispatchHandlers[di]
	pop	si
	jc	short ddsError
ddsReturn:
	ret
ddsError:
	mov	ax,3
	call	DirSetupParamError
	stc
	jmp	short ddsReturn
DirDispatchSwitch endp

DirDispatchHandlers label word
	dw	OnOffSw,OnOffSw,OnOffSw,OnOffSw
	dw	OnOffSw,OnOffSw,OnOffSw,OnOffSw
	dw	OnOffSw,OnOffSw,OnOffSw,OnOffSw
ifdef DBLSPACE_HOOKS
	dw	OnOffSw,DirParseRatio
endif
	dw	OnOffSw,OnOffSw,NoOrder,DirParseOrder,DefaultAttr,DirParseAttr

; Find a matching synonym and leave SI at the value following it.
DirMatchSwitch proc near
dmsNext:
	jcxz	dmsFail
	push	si
	push	di
	mov	di,[di]
	inc	si
	inc	di
dmsChar:
	cmp	byte ptr [di],0
	jz	short dmsFound
	cmpsb
	je	short dmsChar
	pop	di
	add	di,2
	pop	si
	loop	dmsNext
dmsFail:
	stc
dmsReturn:
	ret
dmsFound:
	pop	di
	pop	di
	jmp	short dmsReturn
DirMatchSwitch endp




;***	SetCollatingTable - set up character collating table for sorting
;
;	If country is other than USA, try to get a collating table
;	for character sorting.  For USA, use straight byte values.
;	This is so DIR behaves like the MS-DOS Shell, which sorts
;	by straight byte values in the USA for better performance.
;
;	ENTRY	ES = TRANGROUP seg addr
;
;	EXIT	nothing
;
;	USED	AX,BX,CX,DX,DI
;
;	EFFECTS
;
;	  If collating table is set -
;	    CountryPtrId = 6.
;	    CountryPtr points to collating table.
;
;	  Otherwise -
;	    CountryPtrId = 0.

SetCollatingTable	proc

;	Begin modification M028

	mov	dx,offset TRANGROUP:InternatVars
				; DS:DX = ptr to international info buffer
	mov	ax,INTERNATIONAL shl 8
				; AX = 'Get current country info'
	int	21h		; call DOS
	jc	scNoTable	; error - so don't collate

;	BX = country code

	cmp	bx,1
	je	scNoTable	; we're in USA, don't collate

;	End modification M028

;*	Country code is other than USA.  Try to get a collating table.

	mov	ax,(GETEXTCNTRY shl 8) + SETCOLLATE
				; AH = 'Get Extended Country Info'
				; AL = 'Get Pointer to Collating Table'
	mov	bx,-1		; BX = code page of interest = CON
	mov	cx,5		; CX = length of info buffer
	mov	dx,bx		; DX = country ID = default
	mov	di,offset TRANGROUP:CountryPtrInfo
				; ES:DI = ptr to info buffer
	int	21h		; call DOS
	jnc	scRet		; success

;*	Set CountryPtrId = 0 to signal no collating table.

scNoTable:			;M028
	mov	CountryPtrId,0

scRet:	ret

SetCollatingTable	endp




;***	SetOptions - check and set options
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	AX,BX,CX,DX
;
;	EFFECTS
;
;	  Bits may contain modified option settings.
;	  Display_Ioctl table, including LinPerPag variable, is filled in.
;	  LeftOnPage is initialized to # lines till end of page is handled.
;	  PerLine is set according to /w presence.

	public	SetOptions
SetOptions	proc

;	If bare listing requested, cancel wide listings.

	test	Bits,mask bare
	jz	@F
	and	Bits,not mask wide		;M007;Allow /p with /b
	and	Bits,not mask verbose		; /b excludes /v

@@:
ifdef DBLSPACE_HOOKS
;	Cancel compression ratio if wide or bare listing

	test	Bits, (mask bare) or (mask wide)
	jz	@f
	and	Bits, not mask cratio
@@:
endif
;	Set # lines per display page.

;M01  Obtain screen height from ROM BIOS data area
;
;M01	mov	LinPerPag,LINESPERPAGE			; default value

ifndef JAPAN
	push	ds
	MOV	AX,ROMBIOS_DATA 	; Get ROM Data segment
	MOV	DS,AX			;
	Assume	DS:ROMBIOS_DATA

	MOV	al,CRT_Rows		; Get max rows
	pop	ds			;
	Assume	DS:Trangroup

	or	al,al			; If zero specified
	jnz	@F			;
endif
	MOV	al,LINESPERPAGE 	; assume 24 rows

@@:
	xor	ah,ah
ifndef JAPAN
	inc	al			; height + 1 ;M018
endif
	mov	LinPerPag,ax		; set the rows now

; Now the console driver can change the rows if it knows better (M01 end)

	mov	ax,(IOCTL shl 8)+GENERIC_IOCTL_HANDLE	; IOCTL for handles
	mov	bx,STDOUT				; handle #
	mov	ch,IOC_SC				; screen
	mov	cl,GET_GENERIC				; get display info
	mov	dx,offset TRANGROUP:Display_Ioctl	; info block
	int	21h					; call DOS

	mov	ax,LinPerPag		; AX = # lines per page
	mov	LeftOnPage,ax		; initialize # lines left on page

;	Set # entries per line.

	mov	PerLine,NORMPERLIN	; # entries per line without /w
	test	Bits,mask wide
	jz	@F
	and	Bits,not mask verbose	; /w excludes /v
	mov	PerLine,WIDEPERLIN	; # entries per line with /w
@@:
				;M011;start;The following code checks if a drive
				;letter has been parsed into SrcBuf, and if
				;so, the correct drive number is loaded into
				;the first FCB, at offset 5C.

	cmp	TRANGROUP:[SrcBuf+1],COLON_CHAR	; is this a drive letter?
	jne	soRet
	mov	al,TRANGROUP:[SrcBuf]		; load drive letter into al
	and	al,not 20h			; capitalize ASCII drive letter (LowerCase-32)-->UpperCase
	sub	al,'@'				; convert to 1-based number (1=A)
	mov	ds:FCB,al 			; store in first FCB
						;M011;end
soRet:
	test	Bits,mask verbose
	jnz	short soNeedAccess
	mov	si,offset TRANGROUP:DestBuf
soNextOrder:
	lodsb
	or	al,al
	jz	short soDone
	and	al,7Fh
	cmp	al,6			; access date sort
	jne	short soNextOrder
soNeedAccess:
	inc	DirNeedInfo
soDone:
	ret

SetOptions	endp




;***	CrunchPath - analyze supplied or default pathname
;
;	ENTRY	PathPos = ptr to pathname buffer
;		PathCnt = length of pathname, not incl trailing delimiter
;		Pathname in buffer must end in delimiter (like CR) and
;		 must have space for another char after the delimiter.
;
;	EXIT	CY = clear if no error
;		We are changed to directory found in pathname
;		Previous directory ready to be restored via RestUDir
;		FCB filename fields contain filename (possibly w/ wildcards)
;
;		If error occurred,
;		CY = set
;		ComSw = error bits (see ErrorRec)
;		If ComSw not set,
;		Ready for DOS Get Extended Error call


CrunchPath	proc

	call	FileIsDevice
	jne	@F		; not a device, skip ahead
	or	ComSw,mask dev	; signal file is device
	jmp	short cpErr	; return error
@@:
	push	PathPos		; save ptr to pathname
	mov	DirFlag,1	; do not parse the filename into the FCB
	cmp	PathFindMode,0
	jz	short cpCrunch
	or	DirFlag,4	; use the selected pathname interface
cpCrunch:
	invoke	PathCrunch	; change to directory in pathname
	pop	si		; SI = ptr to pathname
	jc	cpNoDir		; didn't find directory path
	jz	short cpDirOnly

;*	We found a directory, and there was a filename attached.
;	DestTail = ptr to ASCIIZ filename

	mov	si,DestTail	; SI = ptr to filename
	jmp	short cpFile	; go parse the file into FCB

cpDirOnly:
	pushf
	call	DirAppendWildcard	; search the directory contents
	popf
	jmp	short cpRet

;*	PathCrunch failed to find a directory in the pathname.
;
;	Msg_Numb = error code
;	DestIsDir = nonzero if path delimiter char's occur in pathname
;	SI = ptr to pathname (now an ASCIIZ string)

cpNoDir:
	mov	ax,Msg_Numb	  ; AX = error code from PathCrunch
	or	ax,ax
	jnz	cpErr		  ; error occurred - return it
	cmp	DestIsDir,0
	je	cpMaybe		  ; no path delimiters seen, maybe it's a file
	or	ComSw,mask baddir ; signal invalid directory name
	jmp	short cpErr	  ; return error

cpMaybe:

;	SI = ptr to pathname

	cmp	byte ptr [si+1],COLON_CHAR
	jnz	@F		  ; no drive specifier, skip ahead
	lodsw			  ; SI = ptr past drive specifier "d:"
@@:	cmp	[si],".."
	jne	cpFile		  ; if not "..", treat as a file
	cmp	byte ptr [si+2],0
	jne	cpFile		  ; or if there's more after "..", treat as file
	or	ComSw,mask baddir ; signal invalid directory
	jmp	short cpErr	  ; return error

;	The preceding code was taken from the old DIR routine.
;	It's garbage, I'm afraid.  It's meant to check for ".."
;	occurring when we're at the root directory.  Too bad it
;	doesn't handle problems with "..\..", etc.


;	We're ready to parse a filename into the FCB.
;	SI = ptr to ASCIIZ filename

cpFile:	mov	di,FCB		; DI = ptr to FCB
	mov	ax,(PARSE_FILE_DESCRIPTOR shl 8) or 0Eh
				; wildcards already in FCB used as defaults
	int	21h
	clc			; return success
	jmp	short cpRet

cpErr:	stc			; return error

cpRet:	ret

CrunchPath	endp




;***	InstallCtrlC - install our private control-C handler
;
;	Put our control-c handler in front of command.com's default
;	handler, to make sure the user's default directory gets restored.
;	This shouldn't be necessary, but, for now, there are situations
;	where the TDATA segment is left in a modified state when a
;	control-c occurs.  This means that the transient will be
;	reloaded, and the user's directory cannot be restored.
;
;	Bugbug:  fix the wider problem?  Involves message services.  Ugly.
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	AX,BX,DX
;
;	EFFECTS
;
;	  CtrlCHandler address placed in int 23 vector.
;
;	NOTE
;
;	  Command.com's basic control-c handler will be restored
;	  to the int 23 vector by the HeadFix routine, after DIR finishes.

InstallCtrlC	proc

	push	es				 ; preserve ES
	mov	ax,(GET_INTERRUPT_VECTOR shl 8) + 23h
	int	21h
	mov	word ptr OldCtrlCHandler,bx	 ; save old int 23 vector
	mov	word ptr OldCtrlCHandler+2,es	 
	pop	es				 ; restore ES

	mov	dx,offset TRANGROUP:CtrlCHandler ; DS:DX = ptr to CtrlCHandler
	mov	ax,(SET_INTERRUPT_VECTOR shl 8) + 23h
	int	21h
	ret

InstallCtrlC	endp



;***	ListSubds - search and list files in subdirectories
;
;	ENTRY	Current directory (on selected drive) is top of subdir tree
;		FCB is still set up for file searches
;		Bits, AttrSpecified, AttrSelect, DestBuf all still set up
;
;	EXIT	CY = clear if no error
;		FileCnt = # files found & displayed
;		FileSiz = total size of files found
;
;		If error,
;		CY = set
;		Ready for DOS Get Extended Error call
;
;	USED	AX,BX,CX,DX,SI,DI,BP
;
;	EFFECTS
;
;	  FileCntTotal, FileSizTotal are updated.
;	  Subdirectories may be listed on standard output device.
;
;	NOTES
;
;	  ListSubds seeds the recursive entry point lsNode with a ptr
;	   to a buffer where we'll stack up subdirectory filenames.
;	   Each name is stored ASCIIZ.

ListSubds	proc

	invoke	SetRest1		; make sure user's dir gets restored

	mov	bx,offset TRANGROUP:ScanBuf   ; BX = ptr to child name buffer

lsNode:
	mov	byte ptr ds:[bx],0	; start with null child name
lsLoop:
	call	FindNextChild		; search for next subdirectory
	jc	lsErr			; search failed - examine error

	mov	dx,bx			; DX = ptr to child's name
	call	ChangeDir		; enter child directory

					; M023;start
	jnc	@F			; check for error
	cmp	ax,ERROR_PATH_NOT_FOUND	; error due to len(pathname)>MAXPATH?
	je	lsLoop			; yes, skip over this subdirectory
	jmp	SHORT lsRet		; no, other error: DIR must fail
					; M023;end

@@:	push	bx
	call	ListDir			; list the directory
	pop	bx

;	Note we're ignoring errors returned here.

	mov	di,bx			; DI = ptr to child's name
	mov	cx,13			; CX = max name length w/ null
	xor	al,al			; AL = zero byte to look for
	repne	scasb			; DI = ptr to next name pos'n in buf
	push	bx			; save ptr to child's name
	mov	bx,di			; BX = ptr to next name pos'n in buf
	call	lsNode			; recurse from new node
	pop	bx			; BX = ptr to child's name
	pushf				; save error condition
	
	shove	0
	shove	".."
	mov	dx,sp			; DX = ptr to "..",0 on stack
	call	ChangeDir		; return to parent directory
	pop	ax			; restore stack
	pop	ax

	popf				; restore error condition from child
	jc	lsRet			; return error

	jmp	lsLoop			; look for more children
lsErr:
	invoke	Get_Ext_Error_Number	; AX = extended error code
	cmp	ax,ERROR_FILE_NOT_FOUND
	je	lsRet			; file not found, we're ok
	cmp	ax,ERROR_NO_MORE_FILES
	je	lsRet			; no more files, we're ok
	stc				; return other errors

lsRet:	ret

ListSubds	endp




	break	<DIR support routines>

;***	SUPPORT ROUTINES




;***	CheckChild - check potential subdirectory name for FindNextChild
;
;	ENTRY	DirBuf contains DOS Find-buffer with potential child
;		BX = ptr to last child's name
;		BP = ptr to temp child's name
;
;	EXIT	nothing
;
;	USED	AX,CX,SI,DI
;
;	EFFECTS
;
;	  Filename pointed to by BP may be changed.
;
;	NOTES
;
;	  Potential filename replaces temp filename if:
;	   it's a subdirectory file;
;	   it doesn't start with a '.';
;	   it's alphanumerically greater than last child's name;
;	   and it's alphanumerically less than temp name.

CheckChild	proc

	test	DirBuf.find_buf_attr,ATTR_DIRECTORY
	jz	ccRet		; not a subdirectory file- return

	cmp	DirBuf.find_buf_pname,'.'
	je	ccRet		; starts with a dot- return

	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	mov	di,bx
	call	CmpAscz		; compare candidate to last child's name
	jna	ccRet		; it's not above it- return

	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	mov	di,bp
	call	CmpAscz		; compare candidate to temp name
	jnb	ccRet		; it's not below it- return

;	New kid is alright.  Copy to temp.

	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	mov	di,bp
	mov	cx,13
	rep	movsb

ccRet:	ret

CheckChild	endp




;***	CmpEntry - compare one directory entry to another in sort order
;
;	Compare one directory entry against another according to
;	the sort codes in DestBuf.  One or more comparisons
;	may be made of file name, extension, time/date, and
;	size.  Comparisons may be made for upward or downward
;	sort order.
;
;	ENTRY	ES:BX = ptr to entry to compare
;		ES:BP = ptr to entry to be compared against
;		DestBuf contains sort codes (see DestBuf)
;		DS = TRANGROUP seg addr
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry against BP entry.
;		 'Same, above, below' translate to 'same, after, before'.
;
;	USED:	AX,CX,DX,SI,DI

CmpEntry	proc

	mov	si,offset TRANGROUP:DestBuf	; (DS:SI) = ptr to sort codes
ceLoop:
	xor	ax,ax			; AX = 0
	mov	al,[si]			; AL = sort code
	or	al,al
	jz	ceDone			; sort code is zero, we're done
	inc	si			; DS:SI = ptr to next sort code
	push	si			; save ptr to next sort code
	dec	al
	sal	al,1			; AX = index into cmp call table
					; CY set for downward sort order
	mov	si,ax			; SI = index into cmp call table
	mov	ax,cs:FieldCmps[si]	; AX = addr of compare routine
	jc	ceDn			; downwards sort - go swap entries
	call	ax 			; do upwards sort
	jmp	short @F
ceDn:
	xchg	bx,bp		; swap entry ptrs for downward sort order
	call	ax		; do sort
	xchg	bx,bp		; swap ptrs back
@@:
	pop	si		; SI = ptr to next sort code
	je	ceLoop		; compare showed no difference, keep trying

ceDone:

;	Get here either from unequal compare or sort code = 0.
;	In the latter case, condition codes indicate equality,
;	which is correct.

	ret

FieldCmps	label	word	; call table of entry comparisons
		dw	CmpName
		dw	CmpExt
		dw	CmpTime
		dw	CmpSize
		dw	CmpType
		dw	CmpAccessDate
ifdef DBLSPACE_HOOKS
		dw	CmpCratio
endif

CmpEntry	endp




;***	CmpName - compare file name of two entries
;***	CmpExt - compare extension of two entries
;
;	ENTRY	ES:BX = ptr to one entry
;		ES:BP = ptr to another entry
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry to BP entry.
;
;	USED:	AX,CX,DX,SI,DI

CmpName	proc

	mov	si,bx		; ES:SI = ptr to BX entry
	mov	di,bp		; ES:DI = ptr to BP entry
	add	si,filename	; ES:SI = ptr to BX name
	add	di,filename	; ES:DI = ptr to BP name
	mov	cx,size filename; CX = length of name
	jmp	short CmpStr

CmpExt:	mov	si,bx		; ES:SI = ptr to BX entry
	mov	di,bp		; ES:DI = ptr to BP entry
	add	si,fileext	; ES:SI = ptr to BX extension
	add	di,fileext	; ES:DI = ptr to BP extension
	mov	cx,size fileext	; CX = length of extension field

;	Bugbug:	use symbol for subfunction code.

CmpStr:	cmp	CountryPtrId,6
	jne	cnNoCollTable	; no collating table available

;*	Compare strings using collating table.
;
;	ES:SI = ptr to 1st string
;	ES:DI = ptr to 2nd string
;	CX = length

	push	bp			; preserve BP
	push	bx			; preserve BX
	push	ds			; preserve DS
	lds	bx,CountryPtr		; DS:BX = ptr to collating table
	assume	ds:NOTHING
	mov	bp,ds:[bx]		; BP = size of collating table
	inc	bx
	inc	bx			; DS:BX = ptr to collating values
					; DS:[BX]-2 = size of table
	xor	ax,ax			; AX = 0 for starters

;	Bugbug:	Investigate removing collating table length checks.

cnNextChar:
	mov	al,es:[di]		; AL = AX = char from 2nd string
	inc	di			; ES:DI = ptr to next char 2nd string
	cmp	ax,bp			; compare to collating table length
	jae	@F			; char not in table
	xlat				
@@:					; AL = AX = collating value
	mov	dx,ax			; DX = collating value from 2nd string
	lods	byte ptr es:[si]	; AL = AX = char from 1st string
					; ES:SI = ptr to next char 1st string
	cmp	ax,bp			; compare to collating table length
	jae	@F			; char not in table
	xlat				
@@:					; AL = AX = collating value
	cmp	ax,dx			; compare collating values

ifdef DBCS				; DBCS tail byte must not use
					; collating table
	jnz	cnNot_Same
	mov	al,es:[di-1]		; get previous 2nd string character
	invoke	testkanj
	jz	cnDo_Next		; if it was not DBCS lead byte
	mov	al,es:[di]		; get tail byte from 2nd string
	cmp	es:[si],al		; compare with 1st strings tail byte
	jnz	cnNot_Same
	inc	si			; pass tail byte
	inc	di
	dec	cx
cnDo_Next:
	loop	cnNextChar
cnNot_Same:

else					; Not DBCS

	loope	cnNextChar		; until unequal or no more left
endif

	pop	ds			; restore DS
	assume	ds:TRANGROUP
	pop	bx			; restore BX
	pop	bp			; restore BP
	ret

;*	If no collating table is available, simply compare raw ASCII values.
;	Don't we wish we could just do this all the time?  Sigh.

cnNoCollTable:
	rep	cmps byte ptr es:[si],[di]
	ret

CmpName	endp




;***	CmpTime - compare entries by date/time
;
;	ENTRY	ES:BX = ptr to one entry
;		ES:BP = ptr to another entry
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry to BP entry.
;
;	USED:	CX,SI,DI
;
;	NOTE	Filetime and filedate fields in our private entry
;		structure must be adjacent and in that order.

CmpTime	proc

	mov	si,bx
	mov	di,bp
	add	si,filedate + size filedate - 1
	add	di,filedate + size filedate - 1
	mov	cx,size filetime + size filedate
	std
	repe	cmps byte ptr es:[si],[di]
	cld
	ret

CmpTime	endp

;*** CmpAccessDate - compare the last access dates of two entries.
;
;	ENTRY	ES:BX and ES:BP point to directory entries
;	EXIT	condition flags reflect the comparison
;	USED	CX,SI,DI
;
	public	CmpAccessDate
CmpAccessDate proc near
	mov	si,bx
	mov	di,bp
	add	si,fileaccessdate + size fileaccessdate - 1
	add	di,fileaccessdate + size fileaccessdate - 1
	mov	cx,size fileaccessdate
	std
	repe	cmps byte ptr es:[si],[di]
	cld
	ret
CmpAccessDate endp




;***	CmpSize - compare entries by size
;
;	ENTRY	ES:BX = ptr to one entry
;		ES:BP = ptr to another entry
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry to BP entry.
;
;	USED:	CX,SI,DI

CmpSize	proc

	mov	si,bx
	mov	di,bp
	add	si,filesize + size filesize - 1
	add	di,filesize + size filesize - 1
	mov	cx,size filesize
	std
	repe	cmps byte ptr es:[si],[di]
	cld
	ret

CmpSize	endp




;***	CmpType - compare entries by file type (subdirectory or not)
;
;	ENTRY	ES:BX = ptr to one entry
;		ES:BP = ptr to another entry
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry to BP entry.
;
;	USED:	AX

CmpType	proc

	mov	al,es:[bx].fileattr
	mov	ah,es:[bp].fileattr
	and	ax,(ATTR_DIRECTORY shl 8) + ATTR_DIRECTORY
	cmp	ah,al
	ret

CmpType	endp


ifdef DBLSPACE_HOOKS
;***	CmpCratio - compare entries by compression ratio
;
;	ENTRY	ES:BX = ptr to one entry
;		ES:BP = ptr to another entry
;
;	EXIT	BX = unchanged
;		BP = unchanged
;		Condition flags set for same, above, or below
;		 comparing BX entry to BP entry.
;
;	USED:	AX

CmpCratio	proc

	mov	ax, es:[bx].compratio
	cmp	ax, es:[bp].compratio
	ret

CmpCratio	endp
endif

;***	DefaultAttr - set default attribute conditions
;
;	ENTRY	nothing
;
;	EXIT	CY clear
;
;	USED
;
;	EFFECTS
;
;	  AttrSpecified, AttrSelect are updated with new attribute conditions.

DefaultAttr	proc

	mov	AttrSpecified,ATTR_HIDDEN+ATTR_SYSTEM	; specify H and S
	mov	AttrSelect,0				; H and S must be off
	clc						; return success
	ret

DefaultAttr	endp




;***	DisplayTotals - display grand total stats
;
;	If we searched subdirectories, display the total # files found
;	 and total size of files found.
;	Display disk space remaining.
;
;	ENTRY	FileCntTotal, FileSizTotal contain correct values
;		Bits contains setting of /s
;		FCB contains drive #
;
;	EXIT	nothing
;
;	USES	AX,DX
;		FileSiz

DisplayTotals	proc

	test	Bits,mask subd
	jz	dtFree			; no subdirectories- do bytes free

	invoke	Crlf2			; start on new line
	call	UseLine

	mov	dx,offset TRANGROUP:Total_Ptr
	invoke	Std_Printf			; "Total:",cr,lf
	call	UseLine
ifdef DBLSPACE_HOOKS
	test	Bits, mask cratio
	jz	dtCntSize

	mov	ax, [ccluUsedTotal]	; setup compression ratio counts for
	mov	[ccluUsedDir], ax	;   display routine
	mov	si, offset TRANGROUP:csecUsedTotal
	mov	di, offset TRANGROUP:csecUsedDir
	movsw
	movsw

dtCntSize:
endif
	mov	ax,DirAllocatedClustersTotal
	mov	DirAllocatedClusters,ax
	mov	ax,word ptr FileCntTotal	; AX = # files found mod 64K
	mov	dx,word ptr DirCountTotal
	mov	si,offset TRANGROUP:FileSizTotal
	mov	di,offset TRANGROUP:FileSiz
	movsw
	movsw				; move total size to size variable
	mov	bx,1			; grand total
	call	DisplayCntSiz		; display file count & size &
dtFree: 				;   (maybe) compression ratio
	cmp	DirNetworkPath,0	; no local free-space query for UNC
	jz	short dtLocalFree
	invoke	Crlf2
	call	UseLine
	ret
dtLocalFree:
	call	GetDirDiskInfo
	jc	dtRet
	mov	ax,DirTotalClusters
	call	DirClusterBytes
	mov	word ptr DirTotalBytes,ax
	mov	word ptr DirTotalBytes+2,dx
	mov	ax,DirFreeClusters
	call	DirClusterBytes
	mov	Bytes_Free,ax
	mov	Bytes_Free+2,dx
	mov	dx,offset TRANGROUP:BytMes_Ptr
	invoke	Std_Printf
	call	UseLine
	test	Bits,mask verbose
	jz	dtRet
	mov	ax,DirTotalClusters
	call	DirClusterBytes
	mov	Bytes_Free,ax
	mov	Bytes_Free+2,dx
	mov	ax,DirTotalClusters
	sub	ax,DirFreeClusters
	mov	cx,100
	mul	cx
	mov	cx,DirTotalClusters
	div	cx
	mov	DirUsedPercent,ax
	mov	dx,offset TRANGROUP:DirDiskUsage_Ptr
	invoke	Std_Printf
	call	UseLine
dtRet:	ret

DisplayTotals	endp

;*** GetDirDiskInfo - obtain and cache disk cluster information.
;
;	ENTRY	DS = TRANGROUP, FCB = drive number
;	EXIT	carry set if the drive is invalid
;	USED	AX, flags; BX, CX and DX preserved
;
	public	GetDirDiskInfo
GetDirDiskInfo proc near
	cmp	DirClusterSize,0
	jnz	short gdiReturn
	push	bx
	push	cx
	push	dx
	mov	ah,GET_DRIVE_FREESPACE
	mov	dl,byte ptr ds:[FCB]
	int	21h
	cmp	ax,-1
	je	short gdiError
	mov	DirTotalClusters,dx
	mov	DirClusterSize,ax
	mov	DirBytesPerSector,cx
	xor	al,al
	mov	DirSectorShift,al
	jcxz	gdiFreeCount
	dec	al
gdiShift:
	inc	al
	shr	cx,1
	jnc	short gdiShift
	mov	DirSectorShift,al
gdiFreeCount:
	mov	DirFreeClusters,bx
	mov	bl,byte ptr ds:[FCB]
	mov	ax,(IOCTL shl 8) or 9
	int	21h
	jc	short gdiDone
	test	dh,10h
	jz	short gdiDone
	mov	DirClusterInvalid,1
	clc
gdiDone:
	pop	dx
	pop	cx
	pop	bx
gdiReturn:
	ret
gdiError:
	stc
	jmp	short gdiDone
GetDirDiskInfo endp


















;***	FileIsDevice - see if file looks like a device
;
;	ENTRY	PathPos = ptr to pathname
;		PathCnt = length of pathname w/o terminating char
;		DirBuf is DOS DTA
;
;	EXIT	ZR = set if file looks like a device
;
;	USED	AX,BX,CX,DX,DI
;
;	EFFECTS
;
;	  DTA buffer holds results of Find First function
;
;	NOTES
;
;	  We try to flag devices in two ways.  First, we try
;	  the DOS Find First function.  It returns attribute bit 6
;	  set on a successful find if it identifies a device name.
;	  Unfortunately, it returns 'path not found' for a device
;	  name terminated with colon, such as "CON:".  So, we look
;	  for any colon in the pathname after the 2nd character,
;	  and flag the pathname as a device if we find one.

FileIsDevice	proc

	mov	dx,PathPos	 ; DX = ptr to pathname

	mov	di,dx
	add	di,PathCnt	 ; DI = ptr to byte after pathname
	xor	bl,bl		 ; BL = NUL to terminate pathname with
	xchg	bl,byte ptr [di] ; BL = saved pathname terminating char

	xor	cx,cx		 ; CX = attribute mask (normal search)
	mov	ah,FIND_FIRST	 ; AH = DOS Find First function code
	int	21h	 	 ; call DOS
	xchg	bl,byte ptr [di] ; restore pathname terminating char
	jc	piCol		 ; didn't find a dir entry, check for colon

;	Found a dir entry, see if Find First thinks it's a device.

	test	byte ptr DirBuf.Find_Buf_Attr,ATTR_DEVICE
	jz	piCol		 ; device attribute not set, look for colon
	xor	cx,cx		 ; it's a device, return ZR flag
	jmp	short piRet

;	Device attribute not returned by Find First function.  But
;	let's check for a colon anywhere in the pathname after the
;	second byte.
;
;	DI = ptr to byte after pathname

piCol:	dec	di		 ; DI = ptr to last char in pathname
	mov	al,COLON_CHAR	 ; AL = colon char to search for
	mov	cx,PathCnt	 ; CX = # chars to scan
	dec	cx
	dec	cx		 ; ignore 1st two chars of pathname
	or	cx,cx
	js	piRet		 ; if < 2 chars in pathname, just return
	or	di,di		 ; clear ZR in case CX = 0
	std			 ; scan downward
	repne	scasb
	cld			 ; restore default upward direction

;	After scanning, the ZR flag is set to indicate presence of a colon.

piRet:	ret

FileIsDevice	endp




;***	FindFirst - find first directory entry to display
;***	FindNext - find next directory entry to display
;
;	ENTRY	Bits<inmem> = set if entries are loaded in TPA
;		AttrSpecified, AttrSelect are set
;
;	EXIT	CY = clear if successful
;		BX = offset in TPA buffer of directory entry found
;
;		If unsuccessful,
;		CY = set
;		AX = DOS error code
;		DOS Get Extended Error call will get error code
;
;		NOTE:  if entries were loaded into TPA, AX contains
;		ERROR_NO_MORE_FILES when no more entries are available,
;		but DOS Get Extended Error call WON'T return the correct
;		error.  That's ok, because we'll see the value in AX
;		and recognize it as a non-error condition.
;
;	USED	AX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Entries in memory may be marked as output.
;	  If not sorted, entry is loaded at TPA.
;
;	NOTES
;
;	  If we don't find a qualifying file, we return after the final
;	   DOS Find File call.  A DOS Get Extended Error call will then
;	   indicate an appropriate condition.

FindFirst	proc

	mov	ax,offset TRANGROUP:DirFindFirst
	jmp	short ffFindEntry

FindNext:
	mov	ax,offset TRANGROUP:DirFindNext

;	AX = address of correct disk get routine to use.

ffFindEntry:
	push	es			; save TRANGROUP seg addr
	test	Bits,mask inmem
	jz	ffDisk			; entries not in memory, search disk

;	Entries are loaded in memory to sort out.  Find the first one.
;	There will always be one, or LoadEntries would've failed.

	call	FindInMem		; find first entry in TPA
	jmp	short ffRet		; return what TPA search returns

;	Get entry from disk.

ffDisk:
	call	ax			; get entry from disk
	jc	ffGetErr		; get & return error
	mov	es,Tpa			; ES = seg addr of TPA
	xor	di,di			; ES:DI = ptr to TPA
	mov	bx,di			; BX = offset of entry in TPA
	mov	ax,offset TRANGROUP:LoadShortEntry
	cmp	PathFindMode,0
	jz	short ffLoad
	mov	ax,offset TRANGROUP:LoadLongEntry
ffLoad:
	call	ax
	clc				; return success
	jmp	short ffRet

ffGetErr:
	invoke	Get_Ext_Error_Number	; AX = DOS error code
	stc

ffRet:	pop	es			; ES = TRANGROUP seg addr again
	ret

FindFirst	endp




;***	FindInMem - find next directory entry in TPA buffer
;
;	ENTRY	TPA is loaded (see LoadEntries)
;
;	EXIT	BX = offset in TPA of entry found
;
;		If no more files,
;		CY = set
;		AX = DOS 'no more files' error code
;
;	USED	AX,BX,CX,DX,SI,DI,BP,ES
;
;	EFFECTS
;
;	  Entry found is flagged as 'used' (see EntryStruc).

FindInMem	proc

	mov	es,Tpa		; ES = TPA seg addr
	xor	bx,bx		; ES:BX = ptr to 1st entry in TPA
	cld			; make sure default string direction is up
	
	call	FindOneInMem	; locate an entry
	jc	fiNoMore	; none left, set up 'no more files' error

;	BX = ptr to entry in TPA

fiBest:
	mov	bp,bx		; BP = ptr to best entry so far
fiNext:
	call	FindNextInMem	; locate next entry
	jc	fiFound		; no more, best entry so far wins

;	BX = ptr to next entry

	call	CmpEntry	; compare it to best found so far (BP)
	jnb	fiNext		; it's not better, go look at next one
	jmp	fiBest		; it's better, go mark it as best so far

fiNoMore:

;	No more entries available in TPA.  Set up 'no more files' error.

	mov	ax,ERROR_NO_MORE_FILES	; AX = 'no more files' error code
	stc				; return error
	jmp	short fiRet

fiFound:
	mov	bx,bp			; BX = ptr to best entry found
	mov	byte ptr es:[bx],1	; mark entry 'used'
	clc				; return success
fiRet:	ret

FindInMem	endp




;***	FindNextChild - find next subdirectory in current directory
;
;	ENTRY	BX = ptr to last child found, ASCIIZ filename
;		DirBuf is established DTA
;
;	EXIT	BX = ptr (same addr) to next child found, ASCIIZ filename
;
;		If failure,
;		CY = set
;		DOS Get Extended Error call will get error
;
;	USED	AX,CX,DX,SI,DI,BP
;
;	EFFECTS
;
;	  DirBuf is used for find first/next calls.
;
;	NOTES
;
;	  We keep on checking files until DOS returns an error.  If
;	  the error is 'no more files' and the temp filename is not
;	  the initial high tag, copy the temp to the child's name spot
;	  and return success.  Otherwise, send the error back to caller.
;
;	  This routine depends on DS,ES,CS, & SS all being equal.

FindNextChild	proc

	sub	sp,12			; make temp filename buf on stack
	shove	00FFh			; temp filename = high tag
	mov	bp,sp			; BP = ptr to temp filename buf
	shove	"*"
	shove	".*"
	call	GetDriveLtr		; AX = "d:"
	push	ax
	mov	dx,sp			; DX = ptr to "d:*.*",0 on stack

;	See that the stack is restored properly at the end of this proc.

	mov	cx,ATTR_DIRECTORY	; CX = attributes for file search
	mov	ah,FIND_FIRST
	int	21h			; DOS- Find First matching file
	jc	fcRet			; return error

	call	CheckChild		; check child against last, temp

fcNext:	mov	cx,ATTR_DIRECTORY	; CX = attributes for file search
	mov	ah,FIND_NEXT
	int	21h			; DOS- Find Next matching file
	jc	fcErr			; examine error

	call	CheckChild		; check child against last, temp
	jmp	fcNext			; go find another child

fcErr:
	invoke	Get_Ext_Error_Number	; AX = extended error code
	cmp	ax,ERROR_NO_MORE_FILES	; no more files?
	jne	short fcNope		; some other error- return it

;	We ran out of files.  See if we qualified at least one.

	cmp	byte ptr [bp],0FFh
	je	fcNope			; temp filename is unused- no child

;	Move temp filename to child name position.

	mov	si,bp		; SI = ptr to temp filename
	mov	di,bx		; DI = ptr to child name pos'n
fcMove:	lodsb			; AL = next byte of filename
	stosb			; store byte
	or	al,al
	jz	fcRet		; byte was zero, return success (CY clear)
	jmp	fcMove		; go move another byte

fcNope:	stc			; return error
fcRet:	lahf
	add	sp,20		; restore stack
	sahf
	ret

FindNextChild	endp





;***	FindOneInMem - find the first available entry in TPA
;***	FindNextInMem - find the next available entry in TPA
;
;	ENTRY	ES = TPA seg addr
;		BX = ptr to entry in TPA
;
;	EXIT	BX = ptr to entry found
;		CY = set if no more entries available in TPA
;
;	USED	AL

FindOneInMem	proc

	mov	al,es:[bx]	; examine 'used' byte of starting entry
	cmp	al,1
	je	FindNextInMem	; entry has already been used
	cmp	al,0FFh
	je	foNoMore	; 0FFh, we're at the end of the list

;	BX = ptr to entry that hasn't been output yet.

	clc			; return success
	ret

FindNextInMem:
	add	bx,size EntryStruc	; BX = ptr to next entry
	jmp	FindOneInMem		; go look at it

foNoMore:
	stc				; ran out of entries, return failure
	ret

FindOneInMem	endp




;***	GetEnvValue - get value of our environment variable
;
;	ENTRY	DS, ES = TRANGROUP seg addr
;
;	EXIT	CY = set if environment variable not in environment
;
;		Otherwise:
;		SI = ptr to environment variable asciiz value in TRANGROUP
;
;	USED	AX,BX,CX,DX,DI
;		(We assume the (almost) worst, since we don't know about
;		Find_Name_In_Environment.)
;
;	EFFECTS
;
;	  ScanBuf is loaded with value text

	public	GetEnvValue
GetEnvValue proc

	push	es				; save ES
	mov	si,offset TRANGROUP:DirEnvVar	; DS:SI = ptr to variable name
	mov	EnvCaseMode,0			; use normal environment matching
	invoke	Find_Name_In_Environment
	jc	geRet				; name not found in environment

;	ES:DI = ptr to value of environment variable
;	We're assuming DS, CS, and SS are unchanged.

	push	ds
	push	es
	pop	ds
	pop	es

	assume	ds:nothing

;	DS = seg addr of environment variable value (in environment segment)
;	ES = TRANGROUP seg addr

	mov	si,di				; DS:SI = ptr to value string
	mov	di,offset TRANGROUP:ScanBuf	; ES:DI = ptr to dest buffer
@@:	lodsb
	or	al,al
	stosb
	loopnz	@B		; move the string, including trailing null

	push	es
	pop	ds		; DS = TRANGROUP seg addr again
	assume	ds:TRANGROUP

	mov	si,offset TRANGROUP:ScanBuf	; SI = ptr to var value
geRet:	pop	es				; restore ES
	ret

GetEnvValue endp




;***	GetFirst - get first directory entry from disk
;
;	ENTRY	DOS DTA established at DirBuf
;		FCB contains drive # and filename
;		Current directory (on selected drive) is the one to search
;		AttrSpecified & AttrSelect masks set
;
;	EXIT	CY = clear if success
;		DirBuf contains extended FCB for file found
;
;		If unsuccessful,
;		CY = set
;		Ready for DOS Get Extended Error call
;
;	USED	AX,DX
;
;	EFFECTS
;
;	  FCB-7 = 0FFh to mark extended FCB
;	  FCB-1 = attribute mask to find all files
;	  These fields should remain unmodified for GetNext calls.
;
;
;***	GetNext - get next directory entry from disk
;
;	ENTRY	As for GetFirst, plus
;		FCB-7 set up as extended FCB w/ find-all attribute byte
;
;	EXIT	As for GetFirst
;
;	USED	AX,DX

; Search using the 7.0 short- or long-name result format.
; The DTA is DirBuf for short names; long-name results use PathFindBuffer.
	public	DirFindFirst, DirFindNext
DirFindFirst proc near
	cmp	PathFindMode,0
	jnz	short dffLong
	push	ds
	push	cx
	mov	dx,offset TRANGROUP:DirSearchPath
	mov	ah,FIND_FIRST
	mov	cx,16h
	int	21h
	jc	short dffShortDone
	jmp	short dffShortAttr
DirFindNext label near
	cmp	PathFindMode,0
	jnz	short dfnLong
	push	ds
	push	cx
dffShortNext:
	mov	ah,FIND_NEXT
	int	21h
	jc	short dffShortDone
dffShortAttr:
	mov	al,DirBuf.find_buf_attr
	mov	ah,AttrSpecified
	and	al,ah
	and	ah,AttrSelect
	cmp	al,ah
	jnz	short dffShortNext
dffShortDone:
	pop	cx
	pop	ds
	ret
dffLong:
	push	cx
	push	es
	push	di
	push	si
	push	cs
	pop	es
	mov	dx,offset TRANGROUP:DirSearchPath
	mov	cx,16h
	mov	di,offset TRANGROUP:PathFindBuffer
	mov	ax,714Eh
	xor	si,si
	int	21h
	jc	short dffLongDone
	mov	PathFindHandle,ax
	jmp	short dffLongAttr
dfnLong:
	push	cx
	push	es
	push	di
	push	si
	push	cs
	pop	es
dffLongNext:
	mov	bx,PathFindHandle
	mov	ax,714Fh
	mov	di,offset TRANGROUP:PathFindBuffer
	xor	si,si
	int	21h
	jnc	short dffLongAttr
	invoke	ClosePathFind
	stc
	jmp	short dffLongDone
dffLongAttr:
	mov	al,PathFindBuffer
	mov	ah,AttrSpecified
	and	al,ah
	and	ah,AttrSelect
	cmp	al,ah
	jnz	short dffLongNext
dffLongDone:
	pop	si
	pop	di
	pop	es
	pop	cx
	ret
DirFindFirst endp






;***	ListDir - search for and list files in the current directory
;
;	List header, files, and trailer for current directory on selected
;	drive.  Header & trailer are listed if at least one file is found.
;	If no qualifying files are found, no display output occurs.
;
;	ENTRY	Current directory (on selected drive) is the one to be listed
;		FCB contains selected drive # and filename spec
;		Option bits, attribute masks, and sort codes set up
;
;	EXIT	CY = clear if no error
;		FileCnt = # files found & displayed
;
;		If error,
;		CY = set
;		Ready for DOS Get Extended Error call
;
;	USED	AX,BX,CX,DX,SI,DI,BP
;		FileSiz
;
;	EFFECTS
;
;	  FileCntTotal, FileSizTotal are updated.
;	  Files found are listed.  A directory header and trailer are
;	   displayed only if files are found.

ListDir	proc

	xor	ax,ax
	mov	FileCnt,ax		; zero file count
	mov	DirEntryCount,ax
	mov	word ptr FileSiz,ax	; zero file size accumulator
	mov	word ptr FileSiz+2,ax
	mov	DirAllocatedClusters,ax
	mov	DirCount,ax
ifdef DBLSPACE_HOOKS
	mov	ccluUsedDir, ax 	; zero count clusters used
	mov	word ptr csecUsedDir, ax ;zero count compressed sectors used
	mov	word ptr csecUsedDir+2, ax
endif
	mov	DirSortOverflow,al
	cmp	DestBuf,0		; check for sort code
	je	@F			; no sort
	call	LoadEntries		; load entries for sorted listing
	jnc	@F			; no error - continue
	invoke	Get_Ext_Error_Number	; AX = DOS error code
	stc
	jmp	short ldErr		; check end-of-search errors
@@:
	call	FindFirst		; find first file
	jc	ldErr			; not found, return error

;	BX = offset in TPA buffer of entry found

	mov	DirHeaderPending,1
	call	DisplayHeader		; if at least one file, display header
	call	PrepareDirHeader
	cmp	DirSortOverflow,0
	jz	short ldDisplayFirst
	mov	dx,offset TRANGROUP:DirSortOverflow_Ptr
	invoke	Std_Printf
ldDisplayFirst:
	call	DisplayFile		; display the file entry
	test	Bits,mask inmem
	jnz	short ldNext
	cmp	PathFindMode,0
	jnz	short ldNext
	call	FindFirst		; restore the short-name search
ldNext:
	call	FindNext		; find another file
	jc	ldErr			; not found
	call	DisplayFile		; display entry
	test	Bits,mask inmem
	jnz	short ldNext
	mov	ax,BytCnt
	mov	DirSavedByteCount,ax
	jmp	short ldNext		; go find another one

ldErr:
	cmp	ax,ERROR_FILE_NOT_FOUND
	je	ldDone			; file not found, we're done
	cmp	ax,ERROR_NO_MORE_FILES
	je	ldDone			; no more files, we're done
	stc
	jmp	short ldRet

ldDone:
	cmp	DirEntryCount,0
	je	@F			; no entries found, just return
	call	DisplayTrailer		; display trailing info
	test	Bits,mask verbose
	jz	short @F
	test	DirClusterInvalid,1
	jz	short @F
	test	Bits,mask subd
	jz	short @F
	invoke	Crlf2
	call	UseLine
@@:	clc				; return success

ldRet:	ret

ListDir	endp




;***	LoadEntries - attempt to load entries from current directory
;
;	Load all qualifying directory entries from the current directory
;	into the TPA.  If an error is returned by FindFirst/FindNext calls
;	other than 'no more files', return to caller with carry flag set.
;	If we run out of buffer space, display a message that we haven't
;	enough memory to sort this directory, but return without error.
;	Other routines know whether or not entries have been loaded by
;	the 'inmem' flag bit, which we set here.
;
;	The TPA is usually 64K - 512 bytes long.  At 20 bytes per entry,
;	this allows sorting over 3000 entries in a directory.
;
;	ENTRY	Tpa = buffer seg addr
;		BytCnt = buffer length, in bytes
;		Current directory (on selected drive) is the one to load
;		FCB contains drive # and filespec
;		Bits, AttrSpecified, AttrSelect, & DestBuf (sort codes) are set
;
;	EXIT	CY = set if error
;		If error, DOS Get Extended Error will get error info
;
;	USED	AX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Inmem bit of Bits = set if load succeeded.
;	  Tpa buffer contains directory entries.
;	  Byte after last entry = 0FFh.

LoadEntries	proc

	push	es			; save TRANGROUP seg addr
	mov	es,Tpa			; ES = TPA seg addr
	xor	di,di			; ES:DI = destination ptr
	and	Bits,not mask inmem	; signal entries not loaded

	call	DirFindFirst		; look for first file
	jc	leRet			; return any error
	mov	ax,offset TRANGROUP:LoadShortEntry
	cmp	PathFindMode,0
	jz	short leLoadFirst
	mov	ax,offset TRANGROUP:LoadLongEntry
leLoadFirst:
	call	ax

leNext:	call	DirFindNext		; get another file
	jc	leLoaded		; assume any error is no more files
	mov	ax,DirSavedByteCount	; AX = first byte used by long names
	sub	ax,di			; AX = bytes left in TPA
	cmp	ax,121h			; room for entry and long name
	jae	short leLoadMore
leOverflow:
	mov	DirSortOverflow,1
	jmp	short leOk
leLoadMore:
	mov	ax,offset TRANGROUP:LoadShortEntry
	cmp	PathFindMode,0
	jz	short leLoadNext
	mov	ax,offset TRANGROUP:LoadLongEntry
leLoadNext:
	call	ax
	jmp	leNext			; go get another file

leLoaded:
	mov	byte ptr es:[di],0FFh	; mark end of entry list
	or	Bits,mask inmem		; signal entries loaded in memory
leOk:	clc				; return no error

leRet:	pop	es			; ES = TRANGROUP seg addr again
	ret

LoadEntries	endp




; Get the access date for a short-name search result.
; ES:DI addresses the directory entry to receive the date.
	public	DirLoadAccessDate, LoadShortEntry
LoadShortEntry proc near
DirLoadAccessDate label near
	cmp	DirNeedInfo,0
	jz	short dladDone
	push	di
	push	ds
	push	es
	push	bx
	push	di
	test	DirBuf.find_buf_attr,ATTR_DIRECTORY
	jnz	short dladFallback
	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	push	es
	push	ds
	pop	es
	call	DirAppendEntryName
	pop	es
	mov	si,offset TRANGROUP:DirEntryPath
	mov	ax,EXTOPEN shl 8
	mov	bx,44h
	mov	cx,2Fh
	mov	dx,1
	int	21h
	jc	short dladFallback
	xchg	ax,bx
	mov	ax,(FILE_TIMES shl 8) or 4
	int	21h
	pushf
	mov	ah,CLOSE
	int	21h
	popf
	jc	short dladFallback
	mov	es:[di].fileaccessdate,dx
	jmp	short dladRestore
dladFallback:
	mov	ax,DirBuf.find_buf_date
	mov	es:[di].fileaccessdate,ax
dladRestore:
	pop	di
	pop	bx
	pop	es
	pop	ds
	pop	di
dladDone:
	public	DirShortEntryBody
DirShortEntryBody label near
	xor	al,al
	stosb
	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	call	DirFormatShortName
	mov	al,DirBuf.find_buf_attr
	stosb
	and	al,ATTR_DIRECTORY
	mov	ax,DirBuf.find_buf_time
	stosw
	mov	ax,DirBuf.find_buf_date
	stosw
	jnz	short lseDirectory
	mov	ax,DirBuf.find_buf_size_l
	stosw
	mov	ax,DirBuf.find_buf_size_h
	stosw
	jmp	short lseSizeDone
lseDirectory:
	xor	ax,ax
	stosw
	stosw
lseSizeDone:
	add	di,2			; access date already stored
	xor	ax,ax
ifdef DBLSPACE_HOOKS
	test	Bits,mask cratio
	jz	short lseNoRatio
	test	DirBuf.find_buf_attr,ATTR_DIRECTORY
	jnz	short lseNoRatio
	mov	ax,DirBuf.find_buf_size_l
	mov	dx,DirBuf.find_buf_size_h
	mov	si,offset TRANGROUP:DirBuf+find_buf_pname
	mov	cl,byte ptr ds:[FCB]
	or	cl,cl
	jnz	short lseDrive
	call	DirGetCompressionRatio
	jmp	short lseRatioReady
lseDrive:
	sub	si,2
	push	word ptr [si]
	add	cl,'@'
	mov	ch,':'
	mov	[si],cx
	call	DirGetCompressionRatio
	pop	word ptr [si]
lseRatioReady:
	or	ax,ax
	jz	short lseNoRatio
lseStoreRatio:
	stosw
	xor	ax,ax
	stosw
	ret
lseNoRatio:
	dec	ax
	jmp	short lseStoreRatio
else
	dec	ax
	stosw
	xor	ax,ax
	stosw
	ret
endif
LoadShortEntry endp

; Copy at most CX characters from a name component.
; DS:SI addresses the name and ES:DI addresses its destination.
	public	DirCopyNamePart
DirCopyNamePart proc near
dcnNext:
	lodsb
	or	al,al
	jz	short dcnDone
	cmp	al,'.'
	jz	short dcnDone
	stosb
	loop	dcnNext
dcnDone:
	ret
DirCopyNamePart endp

; Format a zero-terminated filename as the eleven-byte DOS name field.
	public	DirFormatShortName
DirFormatShortName proc near
	push	di
	mov	cx,11
	mov	al,' '
	rep	stosb
	pop	di
	push	di
	cmp	byte ptr [si],'.'
	jne	short dfsName
dfsDot:
	lodsb
	or	al,al
	jz	short dfsDone
	stosb
	jmp	short dfsDot
dfsName:
	mov	cx,8
	call	DirCopyNamePart
dfsScan:
	or	al,al
	jz	short dfsDone
	cmp	al,'.'
	jz	short dfsExt
	lodsb
	jmp	short dfsScan
dfsExt:
	pop	di
	push	di
	add	di,8
	mov	cx,3
	call	DirCopyNamePart
dfsDone:
	pop	di
	add	di,11
	ret
DirFormatShortName endp

; Load the long-name search result into the TPA directory record.
	public	LoadLongEntry
LoadLongEntry proc near
	xor	al,al
	stosb
	mov	si,offset TRANGROUP:PathFindBuffer+130h
	invoke	SelectReturnedName
	call	DirFormatShortName
	mov	si,offset TRANGROUP:PathFindBuffer
	mov	al,[si]
	stosb
	and	al,ATTR_DIRECTORY
	pushf
	push	si
	lea	si,[si+14h]
	call	DirConvertFileTime
	pop	si
	mov	ax,cx
	stosw
	mov	ax,dx
	stosw
	popf
	jz	short lleSize
	and	word ptr [si+20h],0
	and	word ptr [si+22h],0
lleSize:
	mov	ax,[si+20h]
	stosw
	mov	ax,[si+22h]
	stosw
	push	si
	lea	si,[si+0Ch]
	call	DirConvertFileTime
	pop	si
	mov	ax,dx
	stosw
	lea	si,[si+2Ch]
	push	di
	push	es
	mov	di,si
	xor	al,al
	mov	cx,-1
	push	ds
	pop	es
	repne	scasb
	inc	cx
	neg	cx
	mov	di,DirSavedByteCount
	sub	di,cx
	mov	DirSavedByteCount,di
	pop	es
	rep	movsb
	pop	di
	xor	ax,ax
ifdef DBLSPACE_HOOKS
	test	Bits,mask cratio
	jz	short lleNoRatio
	test	PathFindBuffer,ATTR_DIRECTORY
	jnz	short lleNoRatio
	mov	si,offset TRANGROUP:PathFindBuffer+130h
	invoke	SelectReturnedName
	mov	ax,word ptr PathFindBuffer+20h
	mov	dx,word ptr PathFindBuffer+22h
	mov	cl,byte ptr ds:[FCB]
	or	cl,cl
	jnz	short lleDrive
	call	DirGetCompressionRatio
	jmp	short lleRatioReady
lleDrive:
	sub	si,2
	push	word ptr [si]
	add	cl,'@'
	mov	ch,':'
	mov	[si],cx
	call	DirGetCompressionRatio
	pop	word ptr [si]
lleRatioReady:
	or	ax,ax
	jz	short lleNoRatio
lleStoreRatio:
	stosw
	mov	ax,DirSavedByteCount
	stosw
	ret
lleNoRatio:
	dec	ax
	jmp	short lleStoreRatio
else
	dec	ax
	stosw
	mov	ax,DirSavedByteCount
	stosw
	ret
endif
LoadLongEntry endp








;***	NoOrder - turn sorting off
;
;	ENTRY	nothing
;
;	EXIT	CY clear
;
;	USED	AX
;
;	EFFECTS
;
;	  DestBuf is updated with sort code bytes.  See DestBuf description.

NoOrder	proc

	mov	DestBuf,0	; no sort
	clc			; no error
	ret

NoOrder	endp




;***	OnOffSw - record occurence of on/off option switch
;
;	ENTRY	DI = index into word list of switches
;
;	EXIT	CY clear
;
;	USED	AX,CX
;
;	EFFECTS
;
;	  Bits modified to indicate option state.




	public	OnOffSw
OnOffSw	proc
	cmp	byte ptr [si],0
	jnz	short ooError
OnOffSet:

	mov	cx,di		; CX = index into word list of options
	shr	cx,1
	shr	cx,1		; CX = bit position of option
	mov	ax,1		
	shl	ax,cl		; AX = bit mask of option
	test	di,2		; check if it is a negated option
	jz	@F		; it's negated
	or	Bits,ax		; turn option on, clear carry
	jmp	short ooDone

@@:	not	ax		; AX = complemented bit mask of option
	and	Bits,ax		; turn option off

ooRet:	clc			; return success
ooDone:	ret
ooError:
	stc
	jmp	short ooDone

OnOffSw	endp






	public	DirParseAttr
DirParseAttr proc near
	push	si			; save SI
	mov	AttrSpecified,0		; cancel all attribute conditions
	cmp	byte ptr [si],':'
	jne	short paLoop
	inc	si
	cmp	byte ptr [si],0
	je	short paErr
paLoop:
	mov	dx,1
	lodsb
	or	al,al
	jz	short paOk
	cmp	al,'-'
	jne	short paFind
	dec	dx			; DX = 0 (for negated attribute)
	lodsb
paFind:
	mov	di,offset TRANGROUP:AttrLtrs  ; DI = ptr to attrib letter list
	mov	cx,NUM_ATTR_LTRS	; CX = length of attrib letter list
	repne	scasb			; look for our letter in the list
	jne	short paErr
	not	cx
	add	cx,NUM_ATTR_LTRS	; CX = attrib bit #, 0-5
	mov	al,1
	shl	al,cl			; AL = mask for our bit
	or	AttrSpecified,al	; set it in the 'specified' mask
	not	al			; AL = mask for all other bits
	and	AttrSelect,al		; clear our bit
	shl	dl,cl			; DL = our bit state in position
	or	AttrSelect,dl		; set selected attr state
	jmp	short paLoop
paErr:	
	stc		   		; return error
	jmp	short paExit
paOk:
	clc
paExit:
	pop	si
	ret
DirParseAttr endp











; Parse the sort letters at DS:SI and return carry on invalid input.
	public	DirParseOrder
DirParseOrder proc near
	push	si				; save SI
	push	bx				; save BX
	cmp	byte ptr [si],':'
	jne	short poStart
	inc	si
	cmp	byte ptr [si],0
	je	poErr
poStart:
	mov	bx,offset TRANGROUP:DestBuf	; BX = ptr to sort code buffer
	mov	al,[si]				; AL = 1st char of order string
	or	al,al
	jnz	short poLtr
	mov	byte ptr [bx],5		; sort 1st by group (subdirs 1st)
	inc	bx
	mov	byte ptr [bx],1		; then by name
	inc	bx
	mov	byte ptr [bx],2		; then by extension
	inc	bx
	jmp	short poOk		; return success
poLtr:
	xor	dl,dl
	lodsb
	or	al,al
	jz	short poOk
	cmp	al,'-'
	jne	short poFind
	mov	dl,80h			; DL = downward sort mask
	lodsb
poFind:
	mov	di,offset TRANGROUP:OrderLtrs  ; DI = ptr to list of letters
	mov	cx,NUM_ORDER_LTRS	; CX = length of list
	repne	scasb			; look for our letter in the list
	jne	short poErr
	neg	cx
	add	cx,NUM_ORDER_LTRS	; CL = sort order code
ifdef DBLSPACE_HOOKS
	cmp	cl, CRATIO_ORDER	; force compression ratio reporting
	jne	short poSet
	or	Bits, mask cratio
poSet:
endif
	or	cl,dl			; CL = sort code with up/dn bit
	mov	[bx],cl			; store sort order code in buffer
	inc	bx
	cmp	bx,offset TRANGROUP:EndDestBuf
	jae	short poErr
	jmp	short poLtr
poErr:
	stc				; return failure
	jmp	short poExit
poOk:
	mov	byte ptr [bx],0
	clc				; return success
poExit:
	pop	bx			; restore BX
	pop	si
	ret
DirParseOrder endp








	break	<DIR utility routines>

;***	UTILITY ROUTINES




;***	ChangeDir - change directory on target drive
;
;	ENTRY	FCB contains drive #
;		DS:DX = ptr to ASCIIZ string w/o drive specifier
;
;	EXIT	Changed current directory on drive
;
;		If error,
;		CY = set
;		DOS Get Extended Error call will get error
;
;	USED	AX,DX,SI,DI
;
;	EFFECTS
;
;	  DirBuf is used to build "d:string".

ChangeDir	proc

	mov	di,offset TRANGROUP:DirBuf
	call	GetDriveLtr	; AX = "d:"
	stosw			; put drive specifier in buffer
	mov	si,dx		; SI = ptr to argument string
cdLoop:
	lodsb
	stosb			; move byte to buffer
	or	al,al
	jne	cdLoop		; continue until null transferred

	mov	dx,offset TRANGROUP:DirBuf	; DX = ptr to "d:string"
	mov	ah,CHDIR
	int	21h				; change directory
	ret					; return what CHDIR returns

ChangeDir	endp




;***	CmpAscz - compare two ASCIIZ strings alphanumerically
;
;	ENTRY	DS:SI = ptr to one ASCIIZ string
;		ES:DI = ptr to another ASCIIZ string
;
;	EXIT	flags set after REPE CMPSB
;
;	USED	AL,CX,SI,DI
;
;	NOTES
;
;	Maximum run of comparison is length of DS:SI string.
;	This ensures that two identical strings followed by
;	random characters will compare correctly.

CmpAscz	proc

	push	di

	mov	di,si
	xor	al,al
	mov	cx,0FFFFh
	repne	scasb
	not	cx

	pop	di
	repe	cmpsb
	ret

CmpAscz	endp








;***	CountFile - update counters with current file
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	nothing
;
;	USED	AX,DX
;
;	EFFECTS
;
;	  FileCnt, FileCntTotal, FileSiz, FileSizTotal are updated.

CountFile	proc
	push	es			; save TRANGROUP seg addr
	mov	es,Tpa			; ES = TPA seg addr
	inc	DirEntryCount
	test	es:[bx].fileattr,ATTR_DIRECTORY
	jnz	short cfDirectory
	inc	FileCnt			; # files this directory
	inc	word ptr FileCntTotal	; # files total
	jnz	short cfSize
	inc	word ptr FileCntTotal+2
cfSize:
	mov	ax,word ptr es:[bx].filesize	; AX = low word of file size
	mov	dx,word ptr es:[bx].filesize+2	; DX = high word of file size
	add	word ptr FileSiz,ax
	adc	word ptr FileSiz+2,dx		; size of this directory
	add	word ptr FileSizTotal,ax
	adc	word ptr FileSizTotal+2,dx	; total size of files listed
ifdef DBLSPACE_HOOKS
	or	ax,dx
	jz	short cfDone
	test	Bits,mask verbose
	jz	short cfDone
	test	DirClusterInvalid,1
	jnz	short cfDone
	call	DirFileClusters
	add	DirAllocatedClusters,ax
	add	DirAllocatedClustersTotal,ax
	jmp	short cfDone
endif
cfDirectory:
	inc	DirCount
	inc	word ptr DirCountTotal
	jnz	short cfDone
	inc	word ptr DirCountTotal+2
cfDone:
	pop	es			; ES = TRANGROUP seg addr again
	ret
CountFile	endp





;***	DisplayBare - display filename in bare format
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	DX = # char's displayed, including dot
;
;	USED	AX,CX,SI,DI
;
;	EFFECTS
;
;	  Filename is displayed in name.ext format, followed by cr/lf.
;	  If /s is on, complete pathname is displayed.
;
;	NOTE
;
;	  Directory pseudofiles . and .. and suppressed in bare listing.

DisplayBare	proc

;	Suppress . and .. files from bare listing.

	mov	cx,ds			; CX = saved TRANGROUP seg addr
	mov	ds,Tpa			; DS:BX = ptr to file entry
	assume	ds:NOTHING
	cmp	ds:[bx].filename,'.'	; check 1st char of filename
	mov	ds,cx			; DS = TRANGROUP seg addr again
	assume	ds:TRANGROUP
	je	dbRet			; it's . or .. - don't display

	test	Bits,mask subd
	jz	dbNameExt		; not /s - display filename only

; Prepare the directory prefix for bare recursive output.
	public	DirBareDirectoryPath
DirBareDirectoryPath label near
	cmp	DirTraversalActive,0
	jnz	short dbdpCurrent
	mov	si,offset TRANGROUP:DirBasePath
	mov	di,offset TRANGROUP:BwdBuf
	push	di
	cld
dbdpCopy:
	lodsb
	stosb
	or	al,al
	jnz	short dbdpCopy
	pop	di
	jmp	short dbdpDone
dbdpCurrent:
	invoke	Build_Dir_String
	mov	di,offset TRANGROUP:BwdBuf
dbdpDone:
   
	test	Bits,mask lcase		;M010;check for lowercase option
	jz	@F			;M010;lowercase not needed
	mov	si,di			;M010;DS:SI --> ASCIIZ string in BwdBuf	
	call	LowercaseString		;M010;path string is in BwdBuf

@@:	xor	al,al			; AL = 0
	mov	cx,0FFFFh
	cld
	repne	scasb			; ES:DI = ptr to byte after null
	dec	di			; ES:DI = ptr to null byte

ifdef DBCS
	push	si
	push	di
	mov	si,offset TRANGROUP:BwdBuf
	dec	di
	call	CheckDBCSTailByte
	pop	di
	pop	si
	jz	dbTailByte		; if last char is double byte
endif

	cmp	byte ptr es:[di-1],'\'
	je	@F			; already terminated w/ '\'

ifdef DBCS
dbTailByte:
endif

	mov	ax,'\'			; AX = '\',0
	stosw				; add to dir string
@@:
	mov	String_Ptr_2,offset TRANGROUP:BwdBuf
	mov	dx,offset TRANGROUP:String_Buf_Ptr
	invoke	Std_Printf		; display device & directory path

dbNameExt:
; Display a long name in bare format, falling back to the 8.3 name.
	public	DirDisplayBareName
DirDisplayBareName label near
	push	ds
	mov	ds,Tpa
	assume	ds:nothing
	mov	si,[bx].longname
	or	si,si
	jz	short dbnShort
dbnNext:
	lodsb
	or	al,al
	jz	short dbnDone
	test	word ptr ss:Bits,mask lcase
	jz	short dbnOutput
	call	LowerCase
dbnOutput:
	call	DirOutputChar
	jmp	short dbnNext
dbnShort:
	call	DisplayDotForm
dbnDone:
	invoke	CrLf2
	pop	ds
	assume	ds:TRANGROUP

dbRet:	ret

DisplayBare	endp




;***	DisplayDotForm - display filename in compressed dot format
;
;	Display name.ext, with no cr/lf's.  Dot is displayed only
;	if the filename has a nonblank extension.
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	DX = # char's displayed, including dot
;
;	USED	AX,CX,SI,DI
;
;	EFFECTS
;
;	  Filename is displayed in name.ext format.
;
;	NOTE
;
;	  We allow for bogus filenames that have blanks embedded
;	  in the name or extension.

;	Bugbug:	might be a good performance gain if we buffered
;	up the output and used DOS function 9.

	public	DisplayDotForm
DisplayDotForm	proc

	push	ds			; save TRANGROUP seg addr
	push	es			; save ES
	mov	ax,cs:Tpa		; AX = TPA seg addr
	mov	ds,ax			; DS:BX = ptr to entry
	assume	ds:nothing
	mov	es,ax			; ES:BX = ptr to entry

	mov	di,bx			; ES:DI = ptr to entry
	add	di,filename + size filename - 1
					; ES:DI = ptr to last char in name field
	mov	cx,size filename	; CX = length of name field
	mov	al,' '
	std				; scan down
	repe	scasb			; scan for nonblank

;	Assume file name has at least one character.

	inc	cx			; CX = # chars in name
	mov	dx,cx			; DX = # chars to be displayed

	mov	si,bx			; DS:SI = ptr to entry
	add	si,filename		; DS:SI = ptr to name

NextNameChar:
	cld
	lodsb				; AL = next char

ifdef DBCS
	invoke	testkanj
	jz	@f			; if this is not lead byte
	call	DirOutputChar		; display lead byte
	dec	cx
	jz	ExtChar			; if this is end
	lodsb				; get tail byte
	jmp	short NameChar10	; display tail byte
@@:
endif

	test	Bits,mask lcase		;M010;check for lowercase option
	jz	@F			;M010;lowercase not required
	call	LowerCase		;M010;filename char is in AL

ifdef DBCS
NameChar10:
endif

@@:	call	DirOutputChar		; display it
	loop	NextNameChar

ifdef DBCS
ExtChar:
endif

;	Now do extension.

	mov	di,bx			; ES:DI = ptr to entry
	add	di,fileext + size fileext - 1
					; ES:DI = ptr to last char in ext field
	mov	cx,size fileext		; CX = length of ext field
	mov	al,' '
	std				; scan down
	repe	scasb			; scan for nonblank
	je	ddDone			; no nonblank chars in ext

	inc	cx			; CX = # chars in ext
	add	dx,cx			; DX = total # chars to be displayed
	inc	dx			;      including dot

	mov	al,'.'
	call	DirOutputChar
	mov	si,bx			; DS:SI = ptr to entry
	add	si,fileext		; DS:SI = ptr to ext

NextExtChar:
	cld
	lodsb				; AL = next char

ifdef DBCS
	invoke	testkanj
	jz	@f			; if this is not lead byte
	call	DirOutputChar		; display lead byte
	dec	cx
	jz	ddDone			; if this is end
	lodsb				; get tail byte
	jmp	short ExtChar10		; display tail byte
@@:
endif

	test	CS:Bits,mask lcase	;M010;check for lowercase option
	jz	@F			;M010;lowercase not required
	call	LowerCase		;M010;fileext char is in AL

ifdef DBCS
ExtChar10:
endif

@@:	call	DirOutputChar		; display it
	loop	NextExtChar

ddDone:	pop	es			; restore ES
	pop	ds			; DS = TRANGROUP seg addr again
	assume	ds:TRANGROUP
	cld				; leave direction flag = up
	ret

DisplayDotForm	endp








;***	DisplayFile - display file entry, update counters
;
;	ENTRY	BX = offset of entry in TPA buffer
;		Bits contains /w, /p settings
;
;	EXIT	nothing
;
;	USED	AX,CX,DX,SI,DI,BP
;
;	EFFECTS
;
;	  Entry is displayed.  
;	  If not /b,
;	    Cursor is left at end of entry on screen.
;	    FileCnt, FileCntTotal, FileSiz, FileSizTotal are updated.
;	  If /b,
;	    Cursor is left at beginning of next line.
;	    Cnt's and Siz's aren't updated.

DisplayFile	proc
	test	Bits,mask wide
	jnz	dfWide
	test	Bits,mask bare
	jnz	dfBegin
	invoke	Crlf2
dfBegin:
	call	DirBeginOutput
	test	Bits,mask bare
	jz	dfFull
	call	DisplayBare
	jmp	short dfFinish
dfFull:
	call	DisplayName
	call	DisplayTheRest
ifdef DBLSPACE_HOOKS
	test	Bits,mask cratio
	jz	@F
	call	DisplayCompRatio
@@:
endif
	cmp	PathFindMode,0
	jz	short dfCount
	call	DirDisplayLongName
dfCount:
	call	CountFile
dfFinish:
	call	DirFinishOutput
	ret
dfWide:
	call	DisplayNext
	call	DisplayWide
	call	CountFile
	ret
DisplayFile	endp

; Begin and flush a complete DIR output line.
	public	DirBeginOutput, DirFinishOutput
DirBeginOutput proc
	mov	DirOutputActive,1
	mov	word ptr DirOutputPtr,offset TRANGROUP:DirOutputBuffer
	mov	word ptr DirOutputPtr+2,cs
	ret
DirBeginOutput endp

DirFinishOutput proc
	mov	DirOutputActive,0
	mov	ax,word ptr DirOutputPtr
	sub	ax,offset TRANGROUP:DirOutputBuffer
	inc	ax
	mov	dl,80
	div	dl
	or	ah,ah
	jz	dfoLines
	inc	al
dfoLines:
	xor	ah,ah
	call	DirUseLines
	mov	si,word ptr DirOutputPtr
	mov	byte ptr cs:[si],0
	push	ds
	push	cs
	pop	ds
	mov	dx,offset TRANGROUP:DirOutputBuffer
	mov	String_Ptr_2,dx
	mov	dx,offset TRANGROUP:String_Buf_Ptr
	invoke	Std_Printf
	pop	ds
	ret
DirFinishOutput endp


;*** DirOutputChar - display AL or append it to the active DIR buffer
;
;       ENTRY AL = character to display
;       USED  flags
;
	public	DirOutputChar
DirOutputChar	proc
	cmp	byte ptr ss:[DirOutputActive],0
	jz	docPrint
	push	es
	push	di
	les	di,ss:[DirOutputPtr]
	cld
	stosb
	mov	word ptr ss:[DirOutputPtr],di
	pop	di
	pop	es
	ret
docPrint:
	jmp	Print_Char
DirOutputChar	endp

; Append an ASCIIZ string or CX bytes to the active DIR output buffer.
	public	DirAppendString, DirAppendBytes
DirAppendString proc
	push	es
	push	di
	les	di,ss:[DirOutputPtr]
	cld
dasNext:
	lodsb
	stosb
	or	al,al
	jnz	dasNext
DirAppendDone:
	mov	word ptr ss:[DirOutputPtr],di
	pop	di
	pop	es
	ret
DirAppendString endp

DirAppendBytes proc
	push	es
	push	di
	les	di,ss:[DirOutputPtr]
	cld
	rep	movsb
	jmp	short DirAppendDone
DirAppendBytes endp




;***	DisplayHeader - display directory header of working directory
;
;	ENTRY	Current directory (on selected drive) is the one to display
;		LeftOnPage = # lines left on display page
;
;	EXIT	nothing
;
;	ERROR EXIT
;
;	  Build_Dir_String will exit through CError with "Invalid drive
;	   specification" if there's a problem obtaining the current 
;	   directory pathname.
;
;	USED	AX,DX,SI,DI
;
;	EFFECTS
;
;	  BwdBuf (which is really the same buffer as DirBuf, which
;	   we are using for the DTA) contains the directory string.
;	  LeftOnPage is adjusted.





DisplayHeader	proc
	test	Bits,mask bare
	jnz	dhRet
	test	Bits,mask subd
	jz	short dhNorm
	invoke	Crlf2
	call	UseLine
	jmp	short dhCom
dhNorm:
	mov	al,BLANK
	invoke	Print_Char
dhCom:
	mov	dx,offset TRANGROUP:DirRootHead_Ptr
	cmp	DirTraversalActive,0
	jz	short dhPrint
	invoke	Build_Dir_String
	mov	dx,offset TRANGROUP:DirHead_Ptr
dhPrint:
	invoke	Std_Printf
	call	UseLine
dhRet:	ret
DisplayHeader	endp


; Prepare disk information and verbose headings for the first page.
	public	PrepareDirHeader
PrepareDirHeader:
	test	Bits,mask verbose
	jz	short dphReturn
	call	GetDirDiskInfo

; Print the verbose column headings on a continued page.
	public	DirPrintPageHeader
DirPrintPageHeader proc
	test	Bits,mask verbose
	jz	dphDone
	mov	dx,offset TRANGROUP:DirVerboseHeader_Ptr
	invoke	Std_Printf
	call	DirMarkHeader
	mov	dx,offset TRANGROUP:Acrlf_Ptr
	invoke	Std_Printf
	call	DirMarkHeader
dphDone:
	mov	DirHeaderPending,0
dphReturn:
	ret
DirPrintPageHeader endp








;***	DisplayName - display file name & extension
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	nothing
;
;	USED	AX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Filename & extension are displayed in spread format.
;	  Cursor is left at end of extension.

	public	DisplayName
DisplayName	proc
	push	ds				; save TRANGROUP seg addr
	mov	ds,Tpa				; DS:BX = ptr to entry
	assume	ds:nothing
	mov	si,bx				; DS:SI = ptr to entry
	add	si,filename			; DS:SI = ptr to filename
	mov	di,offset TRANGROUP:CharBuf	; ES:DI = ptr to CharBuf
	mov	cx,8
	cld
	rep	movsb
	mov	al,' '
	stosb
	mov	cx,3
	rep	movsb
	xor	al,al
	stosb
	pop	ds				; DS = TRANGROUP seg addr again
	assume	ds:TRANGROUP
	mov	si,offset TRANGROUP:CharBuf	;M010;DS:SI --> ASCIIZ string
	test	Bits,mask lcase			;M010;check for lowercase option
	jz	short dnCopy
	push	si
	call	LowercaseString			;M010;filename.ext string is in CharBuf
	pop	si
dnCopy:
	mov	cx,12
	call	DirAppendBytes
	ret
DisplayName endp


; Append the long filename after the short-name columns.
	public	DirDisplayLongName
DirDisplayLongName proc near
	push	ds
	mov	ds,Tpa
	assume	ds:nothing
	mov	si,[bx].longname
	mov	cx,1
	test	word ptr ss:Bits,mask verbose
	jz	short dlnSpaces
	mov	cx,5
dlnSpaces:
	mov	al,' '
dlnSpace:
	call	DirOutputChar
	loop	dlnSpace
	call	DirAppendString
	pop	ds
	assume	ds:TRANGROUP
	ret
DirDisplayLongName endp




;***	DisplayNext - move display cursor to next entry position
;
;	ENTRY	LeftOnLine = # entries can still be printed on this line
;		LeftOnPage = # lines can still be printed for this page
;		FileCnt = # files in this dir displayed before this one
;		Bits contains /w setting
;
;	EXIT	nothing
;
;	USED	AX,DX
;
;	EFFECTS
;
;	  LeftOnLine will be updated to reflect the entry about to be
;	   displayed.
;	  LeftOnPage may be updated.

	public	DisplayNext
DisplayNext proc
	cmp	word ptr ss:DirEntryCount,0
	je	short dnEol
	cmp	byte ptr ss:LeftOnLine,0
	jng	short dnEol
	mov	dx,offset TRANGROUP:Tab_Ptr
	invoke	Std_Printf
	jmp	short dnDone
dnEol:
	invoke	Crlf2
	call	DirMarkHeader
dn1st:
	mov	al,ss:PerLine
	mov	ss:LeftOnLine,al
dnDone:
	dec	byte ptr ss:LeftOnLine
	ret
DisplayNext endp




;***	DisplayTheRest - display file size/dir, date, time
;
;	ENTRY	BX = offset of entry in TPA buffer
;		Display cursor is at end of file extension
;
;	EXIT	nothing
;
;	USED	AX,CX,DX,SI,DI,BP
;
;	EFFECTS
;
;	  File size, date, & time are displayed.

	public	DisplayTheRest
DisplayTheRest proc
	push	es
	mov	es,ss:Tpa
	mov	bp,bx
	test	es:[bp].fileattr,ATTR_DIRECTORY
	jz	short drNonDir
	mov	dx,offset TRANGROUP:DMes_Ptr
	invoke	Std_Printf
	test	word ptr ss:Bits,mask verbose
	jz	short drCom
drBlankAllocation:
	mov	ax,14
	call	DirPrintPadding
	jmp	short drCom
drNonDir:
	mov	dx,word ptr es:[bp].filesize
	mov	ss:File_Size_Low,dx
	mov	dx,word ptr es:[bp].filesize+2
	mov	ss:File_Size_High,dx
	mov	dx,offset TRANGROUP:Disp_File_Size_Ptr
	invoke	Std_Printf
	test	word ptr ss:Bits,mask verbose
	jz	short drCom
	test	byte ptr ss:DirClusterInvalid,1
	jnz	short drBlankAllocation
	mov	ax,ss:File_Size_Low
	mov	dx,ss:File_Size_High
	or	ax,dx
	jz	short drPrintAllocated
	call	DirFileClusters
	call	DirClusterBytes
	mov	ss:File_Size_Low,ax
	mov	ss:File_Size_High,dx
drPrintAllocated:
	mov	dx,offset TRANGROUP:Disp_File_Size_Ptr
	invoke	Std_Printf
drCom:

;	For all files, display date & time.

	mov	ax,es:[bp].filedate	; AX = date word
	or	ax,ax			; test for null date (DOS 1.x)
	jnz	DirPrintDateTime
	mov	ax,17			; blank date and time fields
	call	DirPrintPadding
	jmp	short DirVerboseDate
	public	DirPrintDateTime
DirPrintDateTime:
	call	DirDecodeDate
	mov	word ptr ss:[DirDateTimeBuffer+5],cx
	mov	word ptr ss:[DirDateTimeBuffer+7],dx
	mov	cx,es:[bp].filetime
	jcxz	drPrint
	shr	cx,1
	shr	cx,1
	shr	cx,1
	shr	cl,1
	shr	cl,1
	xchg	ch,cl
	mov	word ptr ss:[DirDateTimeBuffer+21],cx
drPrint:
	mov	dx,offset TRANGROUP:DirDateTimeBuffer
	invoke	Std_Printf
	mov	dx,offset TRANGROUP:DirDateTimeBuffer+16
	invoke	Std_Printf

	public	DirVerboseDate
DirVerboseDate:
	test	word ptr ss:[Bits],mask verbose
	jz	drDone
	mov	ax,es:[bp].fileaccessdate
	or	ax,ax
	jnz	drAccessDate
	mov	ax,10
	call	DirPrintPadding
	jmp	short drAttributes
drAccessDate:
	call	DirDecodeDate
	mov	word ptr ss:[DirDateTimeBuffer+5],cx
	mov	word ptr ss:[DirDateTimeBuffer+7],dx
	mov	dx,offset TRANGROUP:DirDateTimeBuffer
	invoke	Std_Printf
drAttributes:
	call	DirMakeAttributes
	mov	dx,offset TRANGROUP:DirAttributePtr
	invoke	Std_Printf

drDone:	pop	es			; ES = TRANGROUP seg addr again	
	mov	bx,bp			; BX = offset of entry in TPA again
	ret

DisplayTheRest	endp


ifdef DBLSPACE_HOOKS
;***	DisplayCompRatio - display compression ratio
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	nothing
;
;	USED	AX,CX,DX
;
;	EFFECTS
;
;	  File compression ratio is displayed.


	public	DisplayCompRatio
DisplayCompRatio proc
	push	es
	mov	es,ss:Tpa
	mov	ax,es:[bx].compratio
	cmp	ax,-1
	je	short dcrRet
	mov	ss:Dir_CRatio_2,al
	and	byte ptr ss:Dir_CRatio_2,0Fh
	mov	cl,4
	shr	ax,cl
	mov	ss:Dir_CRatio_1,ax
	mov	dx,offset TRANGROUP:DirCompRatio_Ptr
	invoke	Std_Printf
dcrRet:
	pop	es
	ret
DisplayCompRatio endp
endif

; Convert a DOS date word to the year and month/day message fields.
; AX = packed date, returns CX = year and DX = month/day.
	public	DirDecodeDate
DirDecodeDate proc
	mov	bx,ax			; BX = date word
	and	ax,1Fh			; AX = day of month
	mov	dl,al			; DL = day of month
	mov	ax,bx			; AX = date word
	mov	cl,5
	shr	ax,cl			; shift day out
	and	al,0Fh			; AL = month
	mov	dh,al			; DH = month
	mov	cl,bh
	shr	cl,1
	xor	ch,ch			; CX = year - 1980
	add	cx,80			; CX = 2-digit year
	cmp	cl,100
	jb	datedone
	sub	cl,100			; adjust for 21st century
datedone:
	xchg	dh,dl
	ret
DirDecodeDate endp



; Build the six attribute letters for DIR /V.
	public	DirMakeAttributes
DirMakeAttributes proc
	push	ds
	push	es
	push	si
	push	di
	mov	cl,es:[bp].fileattr
	push	cx
	push	ds
	pop	es
	mov	ax,1100
	mov	dh,util_msg_class	; utility message class
	invoke	TSYSGETMSG
	pop	cx
	mov	di,offset TRANGROUP:DirAttributeText
	mov	ch,6
	mov	ah,' '
dmaNext:
	lodsb
	rcr	cl,1
	jc	dmaStore
	mov	al,ah
dmaStore:
	stosb
	dec	ch
	jnz	dmaNext
	mov	es:[di],ch
	pop	di
	pop	si
	pop	es
	pop	ds
	ret
DirMakeAttributes endp



;***	DisplayTrailer - display trailing lines for directory listing
;
;	ENTRY	LeftOnPage = # lines left on display page
;		FileCnt = # files listed
;		FileSiz = total size of files listed
;
;	EXIT	nothing
;
;	USED
;
;	EFFECTS
;
;	  Trailing info lines are displayed

DisplayTrailer	proc
	test	ss:Bits,mask bare
	jz	short dtrShow
	jmp	dtrRet
dtrShow:
	invoke	Crlf2
	call	UseLine
	mov	ax,ss:FileCnt
	mov	dx,ss:DirCount
	xor	bx,bx
DisplayCntSiz:
ifdef DBLSPACE_HOOKS
	test	ss:Bits,mask cratio
	jz	short dtrSize
	push	ax
	push	bx
	push	dx
	mov	ax,ss:ccluUsedDir
	or	ax,ax
	jz	short dtrSkipRatio
	mov	cx,word ptr ss:csecUsedDir+2
	mov	bx,word ptr ss:csecUsedDir
	call	ComputeRatio
	mov	ss:Dir_CRatio_2,al
	and	byte ptr ss:Dir_CRatio_2,0Fh
	mov	cl,4
	shr	ax,cl
	mov	ss:Dir_CRatio_1,ax
	mov	dx,offset TRANGROUP:AveCompRatio_Ptr
	invoke	Std_Printf
	call	UseLine
dtrSkipRatio:
	pop	dx
	pop	bx
	pop	ax
dtrSize:
endif
	push	bx
	mov	ss:Dir_Num,ax
	mov	ss:DirCountOutput,dx
	mov	dx,offset TRANGROUP:DirMes_Ptr
	invoke	Std_Printf
	mov	dx,offset TRANGROUP:Bytes_Ptr
	invoke	Std_Printf
	call	UseLine
	pop	bx
	test	ss:Bits,mask verbose
	jnz	short dtrDirCount
	test	ss:Bits,mask subd
	jz	short dtrDirCount
	or	bx,bx
	jz	short dtrAllocated
dtrDirCount:
	mov	dx,offset TRANGROUP:DirCount_Ptr
	invoke	Std_Printf
dtrAllocated:
	test	ss:Bits,mask verbose
	jz	short dtrRet
	test	ss:DirClusterInvalid,1
	jnz	short dtrRet
	call	GetDirDiskInfo
	mov	ax,ss:DirAllocatedClusters
	call	DirClusterBytes
	mov	word ptr ss:DirAllocatedBytes,ax
	mov	word ptr ss:DirAllocatedBytes+2,dx
	mov	dx,offset TRANGROUP:DirAllocated_Ptr
	invoke	Std_Printf
	call	UseLine
	mov	ax,19
	call	DirPrintPadding
dtrRet:	ret
DisplayTrailer	endp




;***	DisplayWide - display filename in wide format
;
;	ENTRY	BX = offset of entry in TPA buffer
;
;	EXIT	nothing
;
;	USED	AX,CX,DX,SI,DI
;
;	EFFECTS
;
;	  Name.ext is displayed.  Cursor left at end of field (padded
;	  with blanks).  Subdirectory files are displayed as [name.ext].

	public	DisplayWide
DisplayWide	proc

	push	ds				; save TRANGROUP seg addr
	mov	ds,ss:Tpa				; DS:BX = ptr to entry
	assume	ds:nothing

	test	ds:[bx].fileattr,ATTR_DIRECTORY
	jz	@F				; not a subdirectory file
	mov	al,'['
	invoke	Print_Char			; prefix subdirectory

@@:	call	DisplayDotForm			; display name.ext

;	DX = # chars displayed in name.ext

	test	ds:[bx].fileattr,ATTR_DIRECTORY
	jz	@F				; not a subdirectory file
	mov	al,']'
	invoke	Print_Char			; postfix subdirectory
@@:
;	Pad field with blanks.

	mov	cx,size filename + size fileext + 1
						; CX = field size
	sub	cx,dx				; CX = # pad char's
	jcxz	dwDone
	mov	al,' '

@@:	invoke	Print_Char
	loop	@B

dwDone:	pop	ds			; DS = TRANGROUP seg addr again
	assume	ds:TRANGROUP
	ret

DisplayWide	endp




;***	EndPage - end the current display page
;
;	ENTRY	LeftOnPage = # lines left on display page
;		Current directory (on selected drive) is the one being listed
;		Bits contains /p setting
;
;	EXIT	LeftOnPage = # lines left for next page
;
;	USED	AX,DX
;
;	EFFECTS
;
;	  Pause is invoked to display a message and wait for a keystroke.
;	  BwdBuf (same as DirBuf) used to build directory string.

	public	EndPage
EndPage	proc

	test	Bits,mask pagd
	jz	epNew			; paged display isn't enabled

	push	bx			; save BX
	push	cx			; save CX

	invoke	Pause			; "Press any key to continue..."

	mov	dx,offset TRANGROUP:DirContRoot_Ptr
	cmp	DirTraversalActive,0
	jz	epContinue
	invoke	Build_Dir_String
	mov	dx,offset TRANGROUP:DirContCurrent_Ptr
epContinue:
	invoke	Printf_Crlf		; "(continuing <dir>)", cr/lf

	pop	cx			; restore CX
	pop	bx			; restore BX

epNew:	mov	ax,LinPerPag		; AX = # lines per page
	dec	ax			; AX = # lines till next EndPage
	mov	LeftOnPage,ax		; LeftOnPage = countdown variable

	ret

EndPage	endp




;***	GetDriveLtr - get target drive letter
;
;	ENTRY	FCB contains drive #
;
;	EXIT	AX = "d:"
;
;	USED	nothing

GetDriveLtr	proc

	mov	al,ds:Fcb	; AL = target drive #
	or	al,al
	jnz	@F		; not current drive default, skip ahead
	mov	al,ds:CurDrv	; AL = current drive #
	inc	al		; AL = 1-based drive #
@@:	add	al,'A'-1	; AL = target drive letter
	mov	ah,':'		; AX = "d:"
	ret

GetDriveLtr	endp







; Set up a parse error for the text at DS:SI and message number in AX.
	public	DirSetupParamError
DirSetupParamError proc near
	mov	Msg_Disp_Class,PARSE_MSG_CLASS
	mov	Extend_Buf_Ptr,ax
	mov	String_Ptr_2,si
	mov	Extend_Buf_Sub,ONE_SUBST
	mov	dx,offset TRANGROUP:Extend_Buf_Ptr
	ret
DirSetupParamError endp




;***	UseLine - use a display line, start a new page if none left
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	flags

	public	DirMarkHeader, UseLine, DirUseLines
DirMarkHeader proc
	mov	DirHeaderPending,1
DirMarkHeader endp
UseLine	proc
	mov	ax,1
UseLine	endp
DirUseLines proc
	sub	LeftOnPage,ax
	inc	ax
	cmp	LeftOnPage,ax
	ja	ulRet
	call	EndPage
	test	Bits,mask pagd
	jz	ulRet
	cmp	DirHeaderPending,0
	jz	ulRet
	call	DirPrintPageHeader
ulRet:
	mov	DirHeaderPending,0
	ret
DirUseLines endp






;***	ZeroTotals - zero grand total file count, size
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	AX
;
;	EFFECTS
;
;	  FileCntTotal & FileSizTotal are zeroed.
;
;	NOTES
;
;	  FileCntTotal throuth csecUsedTotal must be together!
ifdef DBLSPACE_HOOKS
csecSIZE	EQU	size csecUsed + size csecUsedDir + size csecUsedTotal
ccluSIZE	EQU	size ccluUsed + size ccluUsedDir + size ccluUsedTotal
endif
ZeroTotals	proc

	mov	di,offset TRANGROUP:FileCntTotal
ifdef DBLSPACE_HOOKS
	mov	cx,size FileCntTotal+size FileSizTotal+size DirCountTotal+csecSIZE+ccluSIZE
else
	mov	cx,size FileCntTotal+size FileSizTotal+size DirCountTotal
endif
	xor	ax,ax
	rep	stosb
	mov	DirAllocatedClustersTotal,ax
	ret	

ZeroTotals	endp




;***	CtrlCHandler - our own control-c handler
;
;	Make sure user's default directory gets restored.  See notes
;	at InstallCtrlCHandler.
;
;	ENTRY	control-c
;
;	EXIT	to OldCtrlCHandler
;
;	USED	DS,flags
;
;	EFFECTS
;
;	  Restore user's default directory.
;
;	NOTES
;
;	  This handler is only installed after calling PathCrunch,
;	  which sets UserDir1, so the restoration will work.
;
;	  The original control-c vector will be restored, whether
;	  or not this one is invoked, in the HeadFix routine.

CtrlCHandler	proc	far

;SR;
; Save all registers used: ds, dx, ax. I know ax is being used by the 
;CtrlC handler, am not sure about ds & dx. Save them to be safe
;

	push	ds
	push	cs
	pop	ds			; DS = TRANGROUP seg addr
	push	ax
ifdef DBLSPACE_HOOKS
	push	bx
endif
	push	dx

	invoke	ClosePathFind		; close the active directory search
	invoke	RestUDir		; restore user's default directory

	pop	dx
ifdef DBLSPACE_HOOKS
	pop	bx
endif
	pop	ax
	pop	ds
	jmp	cs:OldCtrlCHandler		; go to previous int 23 handler

CtrlCHandler	endp


;M010;start
;***	LowerCase - convert ASCII character in AL to lowercase
;
;	ENTRY	AL = character to be displayed
;
;	EXIT	AL is lowercase
;
;	USED	nothing

	public	LowerCase
LowerCase	proc

	assume	ds:NOTHING,es:NOTHING

	cmp	al,'A'			; ensure AL is in range 'A'-'Z'
	jb	lcRet
	cmp	al,'Z'
	ja	lcRet

	or	al,20h			; convert to ASCII lowercase (UpperCase+32)-->LowerCase

lcRet:	ret

LowerCase	endp




;***	LowercaseString - convert ASCIIZ string at DS:SI to lowercase
;
;	ENTRY	DS:SI points to start of ASCIIZ string
;		ES = DS
;
;	EXIT	nothing
;	
;	USED	AL,SI

	public	LowercaseString
LowercaseString	proc

	assume	ds:NOTHING,es:NOTHING

	push	di			; save di
	mov	di,si			; ES:DI --> ASCIIZ string
	cld

NextChar: 
	lodsb				; get character from string into al
	or	al,al			; are we at end of string?
	jz	EndOfString

ifdef DBCS
	invoke	testkanj
	jz	@f			; if this is not lead byte
	stosb				; store lead byte
	lodsb				; get tail byte
	or	al,al
	jz	EndOfString		; if end
	stosb				; store tail byte
	jmp	short NextChar
@@:
endif

	call	LowerCase		; convert character to lowercase
	stosb				; store character back into buffer
	jmp	SHORT NextChar		; repeat until end of string

EndOfString:
	pop	di			; restore di
	ret

LowercaseString	endp


; Keep the drive and filename pattern while visiting subdirectories.
	public	DirMakeRelativePattern
DirMakeRelativePattern proc near
	push	si
	push	di
	push	es
	push	ds
	pop	es
	xor	dl,dl
	mov	si,ss:DirSearchPos
	mov	di,offset TRANGROUP:DirSearchPath
	cmp	byte ptr [di+1],':'
	jnz	short dmrpCopy
	mov	dl,[di]
dmrpCopy:
	cld
dmrpNext:
	lodsb
	stosb
	or	al,al
	jnz	short dmrpNext
	or	dl,dl
	jnz	short dmrpDrive
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
	add	al,'A'
	mov	dl,al
dmrpDrive:
	mov	si,di
	dec	si
	mov	di,si
	add	di,2
	mov	word ptr ss:DirSearchLength,0
	std
dmrpMove:
	lodsb
	stosb
	inc	word ptr ss:DirSearchLength
	cmp	si,offset TRANGROUP:DirSearchPath
	jae	short dmrpMove
	dec	word ptr ss:DirSearchLength
	mov	al,':'
	stosb
	mov	al,dl
	stosb
	add	word ptr ss:DirSearchLength,2
	add	di,3
	mov	ss:DirSearchPos,di
	cld
	pop	es
	pop	di
	pop	si
	ret
DirMakeRelativePattern endp

 ;*** BuildDirBasePath - form the initial path for DIR output.
;
;	ENTRY	DS = TRANGROUP, DirSearchPath = requested pathname
;	EXIT	DirBasePath contains the directory path
;	USED	AX, CX, flags
;
	public	BuildDirBasePath
BuildDirBasePath proc near
	cmp	ss:DirNetworkPath,0
	jnz	short bdbNetwork
	push	si
	push	dx
	xor	dl,dl
	cmp	byte ptr ss:DirSearchPath+1,':'
	jne	short bdbGetDir
	mov	dl,ss:DirSearchPath
	and	dl,0DFh
	sub	dl,40h
bdbGetDir:
	mov	si,offset TRANGROUP:DirBasePath+3
	mov	ax,ss:PathGetdirFunction
	int	21h
	or	dl,dl
	jnz	short bdbDrive
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
	mov	dl,al
	inc	dl
bdbDrive:
	add	dl,40h
	push	ds
	pop	es
	mov	si,offset TRANGROUP:DirBasePath
	mov	[si],dl
	mov	word ptr [si+1],5C3Ah
	cmp	ss:PathFindMode,0
	jz	short bdbDone
	mov	di,si
	mov	ax,7160h
	mov	cx,8002h
	int	21h
bdbDone:
	pop	dx
	pop	si
	ret
bdbNetwork:
	push	bx
	push	di
	push	si
	mov	si,offset TRANGROUP:DirSearchPath
	mov	di,offset TRANGROUP:DirBasePath
	push	ds
	pop	es
bdbCopy:
	lodsb
	stosb
	or	al,al
	jz	short bdbTerminate
	cmp	al,5Ch
	jne	short bdbCopy
	lea	bx,[di-1]
	jmp	short bdbCopy
bdbTerminate:
	mov	byte ptr [bx],0
	pop	si
	pop	di
	pop	bx
	ret
BuildDirBasePath endp

; Return to the initial directory before searching subdirectories.
	public	ChangeDirBasePath
ChangeDirBasePath proc near
	push	dx
	mov	dx,offset TRANGROUP:DirBasePath
	mov	ax,ss:PathChdirFunction
	int	21h
	pop	dx
	ret
ChangeDirBasePath endp


; Return the drive number for the current search path in DL.
	public	DirSearchDrive
DirSearchDrive proc near
	cmp	byte ptr ss:DirSearchPath+1,':'
	jz	short dsdSpecified
	mov	ah,GET_DEFAULT_DRIVE
	int	21h
	inc	al
	mov	dl,al
	ret
dsdSpecified:
	mov	dl,ss:DirSearchPath
	and	dl,0DFh
	sub	dl,40h
	ret
DirSearchDrive endp

; Divide DX:AX by the sector size, using the cached sector shift.
	public	DirShiftBytes
DirShiftBytes proc near
	mov	cl,ss:DirSectorShift
	mov	bx,dx
	shr	ax,cl
	shr	dx,cl
	add	cl,0F0h
	neg	cl
	shl	bx,cl
	or	ax,bx
	ret
DirShiftBytes endp

; Convert a cluster count in AX to bytes in DX:AX.
	public	DirClusterBytes
DirClusterBytes proc near
	mul	word ptr ss:DirClusterSize
	xor	ch,ch
	mov	cl,ss:DirSectorShift
	jcxz	dcbDone
dcbShift:
	shl	ax,1
	rcl	dx,1
	loop	dcbShift
dcbDone:
	ret
DirClusterBytes endp

; Return the number of clusters needed for a DX:AX byte length.
	public	DirFileClusters
DirFileClusters proc near
	push	bx
	xchg	ax,cx
	xchg	dx,bx
	mov	ax,ss:DirClusterSize
	mul	word ptr ss:DirBytesPerSector
	sub	ax,1
	sbb	dx,0
	add	ax,cx
	adc	dx,bx
	call	DirShiftBytes
	div	word ptr ss:DirClusterSize
	pop	bx
	ret
DirFileClusters endp

; Convert an LFN file time at DS:SI to DOS time and date in CX:DX.
	public	DirConvertFileTime
DirConvertFileTime proc near
	push	bx
	xor	bl,bl
	mov	ax,71A7h
	int	21h
	jnc	short dcftDone
	xor	cx,cx
	mov	dx,cx
dcftDone:
	pop	bx
	ret
DirConvertFileTime endp


; Select long-name calls unless DIR /Z requests short-name calls.
	public	DirSelectPathInterface
DirSelectPathInterface proc
	test	word ptr ss:[Bits],mask dirz
	jnz	dspShort
	call	SelectPathInterface
	ret
dspShort:
	mov	word ptr ss:[PathChdirFunction],CHDIR shl 8
	mov	word ptr ss:[PathGetdirFunction],CURRENT_DIR shl 8
	mov	word ptr ss:[PathAttribFunction],CHMOD shl 8
	xor	al,al
	ret
DirSelectPathInterface endp

; Print AX blanks using the third directory message substitution.
	public	DirPrintPadding
DirPrintPadding proc
	mov	word ptr ss:[DirDateTimeBuffer+43],ax
	mov	word ptr ss:[DirDateTimeBuffer+45],ax
	mov	dx,offset TRANGROUP:DirDateTimeBuffer+32
	invoke	Std_Printf
	ret
DirPrintPadding endp

	assume	ds:TRANGROUP,es:TRANGROUP

ifdef DBLSPACE_HOOKS
; Prepare the compression volume geometry for the selected drive.
DirCompressionRoot db '\',0
	public	DirInitCompression
DirInitCompression proc near
	call	GetDirDiskInfo
	jnc	short dicDrive
	jmp	dicError
dicDrive:
	mov	dl,byte ptr ds:[FCB]
	or	dl,dl
	jz	short dicDefault
	dec	dx
	jmp	short dicMap
dicDefault:
	mov	dl,CurDrv
dicMap:
	mov	ax,4A11h
	mov	bx,1
	int	2Fh
	or	ax,ax
	jnz	dicError
	test	bl,80h
	jz	dicError
	and	bl,7Fh
	push	bx
	push	dx
	mov	ax,4A11h
	mov	dl,bl
	mov	bx,1
	int	2Fh
	pop	dx
	pop	cx
	or	ax,ax
	jnz	short dicError
	and	bl,7Fh
	xchg	bx,cx
	cmp	dl,cl
	jz	short dicHost
	mov	bl,cl
dicHost:
	cmp	fUseHostSize,0
	jz	short dicSpace
	mov	dl,bl
dicSpace:
	mov	ah,GET_DRIVE_FREESPACE
	inc	dx
	int	21h
	cmp	ax,-1
	jz	short dicError
	mov	csecPerCluster,al
	mul	cx
	mov	cx,dx
	mov	bx,ax
	sub	bx,1
	sbb	cx,0
	mov	word ptr DirCompressionMask,bx
	mov	word ptr DirCompressionMask+2,cx
	and	bx,ax
	and	cx,dx
	or	bx,cx
	jnz	short dicError
.386
	bsf	cx,ax
	jnz	short dicShift
	bsf	cx,dx
	jz	short dicError
.8086
	add	cx,16
dicShift:
	mov	DirCompressionShift,cl
	mov	ax,7143h
	mov	bl,2
	mov	dx,offset TRANGROUP:DirCompressionRoot
	stc
	int	21h
	jc	short dicError
	clc
dicReturn:
	ret
dicError:
	stc
	jmp	short dicReturn
DirInitCompression endp

; Calculate the target packed ratio for a named file.
; DX:AX is the logical size and DS:SI addresses the filename.
	public	DirGetCompressionRatio
DirGetCompressionRatio proc near
	push	bx
	push	cx
	push	dx
	mov	bx,ax
	or	bx,dx
	jz	short dgcrEmpty
	call	DirRoundCompressionClusters
	mov	ccluUsed,ax
	call	DirQueryCompressedSize
	jc	short dgcrError
	call	DirShiftBytes
	mov	word ptr csecUsed,ax
	mov	word ptr csecUsed+2,dx
	mov	ax,ccluUsed
	add	ccluUsedDir,ax
	add	ccluUsedTotal,ax
	mov	cx,word ptr csecUsed+2
	mov	bx,word ptr csecUsed
	add	word ptr csecUsedDir,bx
	adc	word ptr csecUsedDir+2,cx
	add	word ptr csecUsedTotal,bx
	adc	word ptr csecUsedTotal+2,cx
	call	ComputeRatio
dgcrReturn:
	pop	dx
	pop	cx
	pop	bx
	ret
dgcrError:
	xor	ax,ax
	jmp	short dgcrReturn
dgcrEmpty:
	mov	ax,100h
	jmp	short dgcrReturn
DirGetCompressionRatio endp
endif

; Get compressed size of DS:SI, preserving the current directory.
; Returns DOS status in carry and the size in DX:AX.
	public	DirQueryCompressedSize
DirQueryCompressedSize proc near
	push	es
	push	ds
	push	di
	push	cs
	pop	es
	push	cs
	pop	ds
	cmp	DirTraversalActive,0
	jnz	short dqcsQuery
	push	si
	call	DirSearchDrive
	invoke	SavUDir
	invoke	SetRest1
	call	ChangeDirBasePath
	pop	si
dqcsQuery:
	mov	ax,7143h
	mov	bl,2
	mov	dx,si
	int	21h
	pushf
	cmp	DirTraversalActive,0
	jnz	short dqcsReturn
	push	ax
	push	dx
	invoke	RestUDir1
	pop	dx
	pop	ax
dqcsReturn:
	popf
	pop	di
	pop	ds
	pop	es
	ret
DirQueryCompressedSize endp
;M010;end	



ifdef DBCS
;
;	Check if the character position is at Tail Byte of DBCS
;
;	input:	ds:si = start address of the string
;		ds:di = character position to check
;	output:	ZF = 1 if at Tail Byte
;
CheckDBCSTailByte	proc	near
	push	ax
	push	cx
	push	di
	mov	cx,di			; save character position
cdtb_check:
	cmp	di,si
	jz	cdtb_next		; if at the top
	dec	di			; go back
	mov	al,[di]			; get character
	invoke	testkanj
	jnz	cdtb_check		; if DBCS lead byte do next
	inc	di			; adjust
cdtb_next:
	sub	cx,di			; if the length is odd then
	xor	cl,1			; the character position is
	test	cl,1			; at the tail byte
	pop	di
	pop	cx
	pop	ax
	ret
CheckDBCSTailByte	endp
endif


TRANCODE ends

	end

