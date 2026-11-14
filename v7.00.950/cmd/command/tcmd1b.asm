	page ,132
;	SCCSID = @(#)tcmd1b.asm 1.1 85/05/14
;	SCCSID = @(#)tcmd1b.asm 1.1 85/05/14
TITLE	PART4 COMMAND Transient routines.
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;	Internal commands DIR,PAUSE,ERASE,TYPE,VOL,VER

.xlist
.xcref
	include dossym.inc
	include bpb.inc
	include syscall.inc
	include filemode.inc
	include sf.inc
	include comseg.asm
	include comsw.asm		;ac000;
	include comequ.asm
	include ioctl.inc		;an000;
.list
.cref

DATARES SEGMENT PUBLIC BYTE             ;AN020;AC068;
        EXTRN   append_flag:byte        ;AN020;AC068;
        EXTRN   append_state:word       ;AN020;AC068;
DATARES ENDS                            ;AN020;AC068;

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	badcpmes_ptr:word	;AC022;
	EXTRN	Extend_buf_ptr:word	;AC000;
	EXTRN	Extend_buf_sub:byte	;AN000;
	EXTRN	inornot_ptr:word
	EXTRN	msg_disp_class:byte	;AC000;
	EXTRN	parse_erase:byte	;AC000;
	EXTRN	parse_rename:byte	;AC000;
	EXTRN	parse_vol:byte		;AC000;
	EXTRN	parse_ctty:byte
	EXTRN	PauseMes_ptr:word
	EXTRN	renerr_ptr:word
	EXTRN	volmes_ptr:word 	;AC000;
	EXTRN	volmes_ptr_2:word	;AC000;
	EXTRN	volsermes_ptr:word	;AC000;
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	bytcnt:word
	EXTRN	charbuf:byte
	EXTRN	comsw:word
	EXTRN	curdrv:byte
	EXTRN	destinfo:byte
	EXTRN	destisdir:byte
	EXTRN	dirflag:byte
	EXTRN	ObjCnt:BYTE
	EXTRN	ParseArgIndex:WORD
	EXTRN	ParseFileArg:WORD
	EXTRN	ParseResultType:BYTE
	EXTRN	PathOpenFunction:WORD
	EXTRN	PathRenameFunction:WORD
	EXTRN	CopyFindDataOffset:WORD
	EXTRN	RenameSourceArg:WORD
	EXTRN	DirEntryPos:WORD
	EXTRN	DirSearchPath:BYTE
	EXTRN	DirEntryPath:BYTE
	EXTRN	PathFindMode:BYTE
	EXTRN	DirNetworkPath:BYTE
	EXTRN	dirbuf:byte
	EXTRN	msg_numb:word		;AN022;
	EXTRN	one_char_val:byte
	EXTRN	parse1_addr:dword	;AN000;
	EXTRN	parse1_syn:word 	;AN000;
        EXTRN   resseg:word             ;AN020;AC068;
	EXTRN	srcbuf:byte		;AN000;
	EXTRN	string_ptr_2:word	;AN000;
	EXTRN	TPA:word
	EXTRN	vol_drv:byte
	EXTRN	vol_ioctl_buf:byte	;AC000;
	EXTRN	vol_label:byte		;AC000;
	EXTRN	vol_serial:dword	;AC000;
	EXTRN	zflag:byte

	extrn	TypeFilSiz:dword
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

;---------------

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	arg:byte		; the arg structure!
transpace   ends
;---------------

	EXTRN	cerror:near
	EXTRN	error_output:near
	EXTRN	notest2:near
	EXTRN	ParseArgument:NEAR
	EXTRN	DirStoreArgument:NEAR
	EXTRN	CheckParsedArgs:NEAR
	EXTRN	GetParsedArg:NEAR
	EXTRN	SelectPathInterface:NEAR
	EXTRN	IsNetworkPath:NEAR
	EXTRN	DirSetEntryPosition:NEAR
	EXTRN	DirAppendWildcard:NEAR
	EXTRN	DirSetupParamError:NEAR
	EXTRN	PathFindFirst:NEAR
	EXTRN	PathFindNext:NEAR
	EXTRN	DirAppendSearchName:NEAR
	EXTRN	CopyMakeTargetName:NEAR
	EXTRN	std_printf:near
	EXTRN	tcommand:near

	PUBLIC	badpath_err		;AN022;
	PUBLIC	crename
	PUBLIC	DisAppend
	PUBLIC	erase
	PUBLIC	extend_setup		;AN022;
	PUBLIC	Get_ext_error_number	;AN022;
	PUBLIC	pause
	PUBLIC	Set_ext_error_msg	;AN000;
	PUBLIC	typefil
	PUBLIC	volume


assume	ds:trangroup,es:trangroup

	break	Pause
assume	ds:trangroup,es:trangroup

PAUSE:
	mov	dx,offset trangroup:pausemes_ptr
	call	std_printf
	invoke	GetKeystroke
	invoke	crlf2
	return

	break	Erase

;****************************************************************
;*
;* ROUTINE:	DEL/ERASE - erase file(s)
;*
;* FUNCTION:	PARSE command line for file or path name and /P
;*		and invoke PATHCRUNCH.	If an error occurs, set
;*		up an error message and transfer control to CERROR.
;*		Otherwise, transfer control to NOTEST2 if /P not
;*		entered or SLASHP_ERASE if /P entered.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	if no error:
;*		FCB at 5ch set up with filename(s) entered
;*		Current directory set to entered directory
;*
;****************************************************************

assume	ds:trangroup,es:trangroup

ERASE:
	mov	comsw,0 			;AN000; clear switch indicator
	MOV	PathFindMode,0
	XOR	CX,CX
	MOV	ParseArgIndex,1
	MOV	ObjCnt,0
EraseScan:
	MOV	DI,OFFSET TRANGROUP:parse_erase
	INVOKE	ParseArgument
	JC	SHORT EraseParseEnd
	CMP	ParseResultType,1
	JZ	SHORT EraseSwitch
	CMP	BYTE PTR [SI+1],':'
	JNZ	SHORT ErasePath
	CMP	BYTE PTR [SI+2],0
	JNZ	SHORT ErasePath
	MOV	AX,error_file_not_found
	JMP	extend_setup
ErasePath:
	INC	ObjCnt
	CMP	ObjCnt,1
	JNA	SHORT EraseOnePath
	MOV	AX,1
	CALL	DirSetupParamError
	JMP	SHORT errj2
EraseOnePath:
	CALL	DirStoreArgument
	PUSH	SI
	CALL	SelectPathInterface
	MOV	PathFindMode,AL
	POP	SI
	CALL	IsNetworkPath
	MOV	DirNetworkPath,AL
	INVOKE	Move_To_SrcBuf
	JMP	SHORT EraseScan
EraseSwitch:
	CMP	COMSW,0
	JZ	SHORT EraseSetPrompt
	MOV	AX,1
	CALL	DirSetupParamError
	JMP	SHORT errj2
EraseSetPrompt:
	INC	COMSW
	JMP	SHORT EraseScan
EraseParseEnd:
	OR	AX,AX
	JZ	SHORT EraseCheckPath
	JMP	SHORT errj2
	RET
EraseMissing:
	MOV	AX,2
	CALL	DirSetupParamError
	JMP	SHORT errj2
EraseCheckPath:
	CMP	ObjCnt,1
	JNZ	SHORT EraseMissing
	MOV	dirflag,0
	INVOKE	PathCrunch
	JNC	SHORT EraseCrunched
	mov	ax,[msg_numb]			;AN022; get message number
	cmp	ax,0				;AN022; was message flag set?
	JNZ	SHORT extend_setup
	CMP	[destisdir],0
	JNZ	SHORT badpath_err
	JMP	SHORT EraseExecute
EraseCrunched:
	JNZ	SHORT EraseExecute
	CALL	DirSetEntryPosition
	CALL	DirAppendWildcard
EraseExecute:
	INVOKE	RestUDir1
	JMP	NOTEST2
badpath_err:
	MOV	AX,error_path_not_found
extend_setup:
	mov	msg_disp_class,ext_msg_class	;AN022; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AC022; get extended message pointer
	mov	Extend_Buf_ptr,ax		;AN022; get message number in control block
errj2:
	JMP	CERROR

	break	Rename

; ****************************************************************
; *
; * ROUTINE:	 CRENAME - rename file(s)
; *
; * FUNCTION:	 PARSE command line for one full filespec and one
; *		 filename.  Invoke PATHCRUNCH on the full filespec.
; *		 Make sure the second filespec only contains a
; *		 filename.  If both openands are valid, attempt
; *		 to rename the file.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

CRENAME:
	mov	ParseArgIndex,1
	mov	di,offset TRANGROUP:PARSE_RENAME
	call	ParseArgument
	jnc	RenameSource
	or	ax,ax
	jz	RenameMissing
	jmp	short RenameError
RenameSource:
	push	si
	mov	ax,[bx].argpointer
	mov	RenameSourceArg,ax
	invoke	Move_To_SrcBuf
	call	DirStoreArgument
	mov	si,offset TRANGROUP:DirSearchPath
	call	SelectPathInterface
	mov	PathFindMode,al
	mov	PathRenameFunction,5600H
	mov	CopyFindDataOffset,1EH
	or	al,al
	jz	RenameParseDest
	mov	PathRenameFunction,7156H
	mov	CopyFindDataOffset,2CH
RenameParseDest:
	pop	si
	mov	di,offset TRANGROUP:PARSE_RENAME
	call	ParseArgument
	jnc	RenameCheckDest
	or	ax,ax
	jz	RenameMissing
	jmp	short RenameError
RenameExtra:
	call	GetParsedArg
	mov	ax,1
	jmp	short RenameParamError
RenameMissing:
	mov	ax,2
	call	SetupMissingArgument
RenameError:
	jmp	CERROR
RenameCheckDest:
	test	[bx].argflags,4
	jnz	RenameBadDest
	mov	al,':'
	cmp	[si+1],al
	jnz	RenameFind
RenameBadDest:
	mov	ax,10
RenameParamError:
	call	DirSetupParamError
	jmp	short RenameError
RenameReturn:
	ret
RenameFind:
	push	si
	mov	dx,RenameSourceArg
	mov	cx,35H
	mov	di,offset TRANGROUP:DirBuf
	call	PathFindFirst
	pop	si
	jc	RenameFindError
RenameNext:
	push	si
	mov	bx,offset TRANGROUP:DirBuf
	add	bx,CopyFindDataOffset
	mov	di,DirEntryPos
	call	CopyMakeTargetName
	mov	si,offset TRANGROUP:DirBuf
	add	si,CopyFindDataOffset
	cmp	byte ptr [si],'.'
	jne	RenameFile
	cmp	byte ptr [si+1],0
	je	RenameSkip
	cmp	word ptr [si+1],'.'
	je	RenameSkip
RenameFile:
	call	DirAppendSearchName
	mov	dx,offset TRANGROUP:DirSearchPath
	mov	di,offset TRANGROUP:DirEntryPath
	mov	ax,PathRenameFunction
	int	21H
	pop	si
	jc	RenameFindError
RenameFindNext:
	push	si
	mov	di,offset TRANGROUP:DirBuf
	call	PathFindNext
	pop	si
	jnc	RenameNext
	xor	al,al
	jmp	short RenameFinish
RenameSkip:
	pop	si
	jmp	short RenameFindNext
RenameFindError:
	invoke	Get_ext_error_number
	cmp	ax,error_no_more_files
	jne	RenameSaveError
	mov	ax,error_file_not_found
RenameSaveError:
	push	ax
	mov	al,0FFH
RenameFinish:
	inc	al
	jz	RenameReport
	jmp	short RenameReturn
RenameReport:
	pop	ax
	cmp	ax,error_access_denied
	jne	RenameNotDenied
	mov	dx,offset TRANGROUP:RenErr_ptr
	jmp	CERROR
RenameNotDenied:
	cmp	ax,error_file_not_found
	jne	RenameExtended
	mov	string_ptr_2,offset TRANGROUP:DirSearchPath
	mov	Extend_buf_sub,one_subst
RenameExtended:
	jmp	extend_setup

	break	Type

;****************************************************************
;*
;* ROUTINE:	TYPEFIL - Display the contents of a file to the
;*		standard output device
;*
;* SYNTAX:	TYPE filespec
;*
;* FUNCTION:	If a valid filespec is found, read the file until
;*		1Ah and display the contents to STDOUT.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	none
;*
;****************************************************************

assume	ds:trangroup,es:trangroup

TYPEFIL:
	call	ParseTypeFile
	jnc	TypeArgument
	ret
TypeArgument:
	mov	si,ParseFileArg
	push	si
	call	SelectPathInterface
	pop	si
	invoke	Move_To_SrcBuf
	invoke	SetPath
	mov	ax,PathOpenFunction
	mov	bx,40H		;AN000; get open mode for TYPE
	xor	cx,cx				;AN000; no special files
	mov	dx,read_open_flag		;AN000; set up open flags
	mov	si,offset trangroup:srcbuf	;AN030; get file name
	int	21h
	jnc	typecont			; If open worked, continue. Otherwise load

Typerr: 					;AN022;
	push	cs				;AN022; make sure we have local segment
	pop	ds				;AN022;
	invoke	set_ext_error_msg		;AN022;
	mov	string_ptr_2,offset trangroup:srcbuf ;AC022; get address of failed string
	mov	Extend_buf_sub,one_subst	;AC022; put number of subst in control block
	jmp	cerror				;AC022; exit

typecont:
	mov	bx,ax				;AC000; get  Handle
;M043
; We should do the LSEEK for filesize only if this handle belongs to a file
;and not if it belongs to a device. If device, set TypeFilSiz+2 to -1 to
;indicate it is a device.
;
	mov	ax,(IOCTL shl 8) or 0
	int	21h

	test	dl,80h				;is it a device?
	jz	not_device			;no, a file

	mov	word ptr TypeFilSiz+2,-1 		;indicate it is a device
	jmp	short dotype
not_device:

;SR;
; Find the filesize by seeking to the end and then reset file pointer to
;start of file
;
	mov	ax,(LSEEK shl 8) or 2
	xor	dx,dx
	mov	cx,dx				;seek  to end of file
	int	21h

	mov	word ptr TypeFilSiz,ax
	mov	word ptr TypeFilSiz+2,dx		;store filesize

	mov	ax,(LSEEK shl 8) or 0
	xor	dx,dx
	int	21h	              			;reset file pointer to start
dotype:						;M043
	mov	zflag,0 			; Reset ^Z flag
	mov	ds,[TPA]
	xor	dx,dx
ASSUME	DS:NOTHING

typelp:
	cmp	cs:[zflag],0			;AC050; Is the ^Z flag set?
	retnz					; Yes, return
	mov	cx,cs:[bytcnt]			;AC056; No, continue
;
;Update the filesize left to read
;
	cmp	word ptr cs:TypeFilSiz+2,-1	;is it a device? M043
	je	typ_read			;yes, just read from it; M043

	cmp	word ptr cs:TypeFilSiz+2,0		;more than 64K left?
	jz	lt64k				;no, do word subtraction
	sub	word ptr cs:TypeFilSiz, cx
	sbb	word ptr cs:TypeFilSiz+2, 0 	;update filesize
      	jmp	short typ_read			;do the read
lt64k:
	cmp	cx,word ptr cs:TypeFilSiz		;readsize <= buffer?
	jbe	gtbuf				;yes, just update readsize
;
;Buffer size is larger than bytes to read
;
	mov	cx,word ptr cs:TypeFilSiz
	jcxz	typelp_ret
	mov	word ptr cs:TypeFilSiz,0
	jmp	short typ_read
gtbuf:
	sub	word ptr cs:TypeFilSiz,cx	   	;update filesize remaining
typ_read:
	mov	ah,read
	int	21h
	jnc	@f				;M043
	jmp	typerr				;M043
@@:						;M043
;M043;	jc	typerr				;AN022; Exit if error

	mov	cx,ax
	jcxz	typelp_ret			;AC000; exit if nothing read
	push	ds
	pop	es				; Check to see if a ^Z was read.
assume es:nothing
	xor	di,di
	push	ax
	mov	al,1ah
	repnz	scasb
	pop	ax
	xchg	ax,cx
	cmp	ax,0
	jnz	foundz				; Yes, handle it
	cmp	byte ptr [di-1],1ah		; No, double check
	jnz	typecont2			; No ^Z, continue

foundz:
	sub	cx,ax				; Otherwise change cx so that only those
	dec	cx				;  bytes up to but NOT including the ^Z
	push	cs				;  will be typed.
	pop	es
assume es:trangroup
	not	zflag				; Turn on ^Z flag so that the routine

typecont2:					;  will quit after this write.
	push	bx
	mov	bx,1
	mov	ah,write
	int	21h
	pop	bx
	jc	Error_outputj
	cmp	ax,cx
	jnz	@f				;M043
	jmp	typelp				;M043
@@:						;M043
;M043;	jz	typelp
	dec	cx
	cmp	ax,cx
	retz					; One less byte OK (^Z)

Error_outputj:
	mov	bx,1
	mov	ax,IOCTL SHL 8
	int	21h
	test	dl,devid_ISDEV
	retnz					; If device, no error message
	jmp	error_output

typelp_ret:
	ret

assume	ds:trangroup,es:trangroup

; Parse the one pathname accepted by TYPE.
ParseTypeFile PROC NEAR
	mov	ES:ParseArgIndex,1
	mov	ES:ObjCnt,0
TypeParseNext:
	mov	di,offset TRANGROUP:PARSE_CTTY
	call	ParseArgument
	jc	TypeParseDone
	inc	ES:ObjCnt
	cmp	ES:ObjCnt,1
	jna	TypeParseSave
	mov	ax,1
	call	SetupMissingArgument
	jmp	short TypeParseError
TypeParseSave:
	mov	ES:ParseFileArg,si
	jmp	short TypeParseNext
TypeParseDone:
	or	ax,ax
	jz	TypeParseCount
TypeParseError:
	jmp	CERROR
	stc
TypeParseReturn:
	ret
TypeParseCount:
	cmp	ES:ObjCnt,1
	clc
	je	TypeParseReturn
	mov	ax,2
	call	SetupMissingArgument
	jmp	short TypeParseError
ParseTypeFile ENDP

; Set up a parse error that has no substitution argument.
	PUBLIC	SetupMissingArgument
SetupMissingArgument PROC NEAR
	mov	ES:msg_disp_class,parse_msg_class
	mov	ES:Extend_Buf_ptr,ax
	mov	ES:Extend_buf_sub,0
	mov	dx,offset TRANGROUP:Extend_Buf_ptr
	ret
SetupMissingArgument ENDP

	break	Volume
;
; VOLUME command displays the volume ID on the specified drive
;
VOLUME:
	mov	ParseArgIndex,1
	mov	di,offset TRANGROUP:PARSE_VOL
	call	ParseArgument
	jnc	VolArgument
	or	ax,ax
	jz	OkVolArg
	jmp	short badvolarg
VolArgument:
	call	CheckParsedArgs
	jc	OkVolArg
	call	GetParsedArg
	mov	ax,1
	call	DirSetupParamError
badvolarg:
	jmp	Cerror


;***	DisAppend - disable APPEND
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	AX,BX
;
;	EFFECTS
;
;	  APPEND is disabled.  If it was active, it will be re-enabled
;	  after the command finishes, by the HeadFix routine.
;
;	NOTE
;
;	  This routine must not be called more than once during a single
;	  command cycle.  The second call would permanently disable APPEND.

DisAppend	proc

	assume	ds:TRANGROUP,es:NOTHING

	push	ds			; save DS
	push	es			; save ES
	push	di

	mov	ax,APPENDINSTALL	; AX = Append Installed Check code
	int	2Fh			; talk to APPEND via multiplex
	or	al,al
	jz	daRet			; APPEND not installed, return

	mov	ax,APPENDDOS		; AX = Get Append Version code
	int	2Fh			; talk to APPEND via multiplex
	cmp	ax,0FFFFh
	jne	daRet			; it's not a local version, return

	mov	ax,APPENDGETSTATE	; AX = Get Function State code
	int	2Fh			; talk to APPEND via multiplex

	mov	ds,ResSeg		; DS = resident seg addr

	assume	ds:RESGROUP

	mov	Append_State,bx		; Append_State = saved APPEND state
	mov	Append_Flag,-1		; Append_Flag = true, restore state

	xor	bx,bx			; BX = APPEND state = off
	mov	AX,APPENDSETSTATE	; AX = Set Append State code
	int	2Fh			; talk to APPEND via multiplex

daRet:	pop	di
	pop	es			; restore ES
	pop	ds			; restore DS

	assume	ds:TRANGROUP

	ret

DisAppend	endp



;
; Find the Volume ID on the disk.
;
PUBLIC	OkVolArg
OKVOLARG:
	assume	ds:TRANGROUP,es:TRANGROUP

	call	DisAppend			; disable APPEND
	invoke	crlf2
	mov	al,blank			;AN051; Print out a blank
	invoke	print_char			;AN051;   before volume message
	push	ds
	pop	es
;
; Volume IDs are only findable via extended FCBs or find_first with attributes
; of volume_id ONLY.
;

	mov	di,FCB-7			; Point to extended FCB beginning
	mov	al,-1				; Tag to indicate Extention
	stosb
	xor	ax,ax				; Zero padding to volume label
	stosw
	stosw
	stosb
	mov	al,attr_volume_ID		; Look for volume label
	stosb
	inc	di				; Skip drive byte; it is already set
	mov	cx,11				; fill in remainder of file
	mov	al,'?'
	rep	stosb
;
; Set up transfer address (destination of search first information)
;
	mov	dx,offset trangroup:dirbuf
	mov	ah,set_DMA
	int	21h
;
; Do the search
;
	mov	dx,FCB-7
	mov	ah,Dir_Search_First
	int	21h

;********************************
; Print volume ID info

	push	ax				;AC000; AX return from SEARCH_FIRST for VOL ID
	mov	al,DS:[FCB]			;AC000; get drive letter
	add	al,'@'
	cmp	al,'@'
	jnz	drvok
	mov	al,[curdrv]
	add	al,capital_A
drvok:
	mov	vol_drv,al			;AC000; get drive letter into argument
	pop	ax				;AC000; get return code back
	or	al,al				;AC000; volume label found?
	jz	Get_vol_name			;AC000; volume label exists - go get it
	mov	dx,offset trangroup:VolMes_ptr_2 ;AC000; set up no volume message
	jmp	short print_serial		;AC000; go print it

Get_vol_name:
	mov	di,offset trangroup:charbuf
	mov	dx,di
	mov	si,offset trangroup:dirbuf + 8	;AN000;  3/3/KK
	mov	cx,11				;AN000;  3/3/KK
	rep	movsb				;AN000;  3/3/KK

	xor	al,al				;AC000; store a zero to terminate the string
	stosb
	mov	dx,offset trangroup:VolMes_ptr	;AC000; set up message

PRINT_SERIAL:

;
; Attempt to get the volume serial number from the disk.  If an error
; occurs, do not print volume serial number.
;

	push	dx				;AN000; save message offset
	mov	ax,(IOCTL SHL 8)+GENERIC_IOCTL ; Get the volume serial info
	xor	bh,bh
	mov	bl,DS:[FCB]			;AN000; get drive number from FCB
	mov	cx,(IOC_DC SHL 8)+GET_MEDIA_ID
	mov	dx,offset trangroup:vol_ioctl_buf ;AN000;target buffer
	int	21h			;AN000; do the call
	pop	dx				;AN000; get message offset back
	jc	printvol_end			;AN000; if error, just go print label
	call	std_printf			;AC000; go print volume message
	mov	al,blank			;AN051; Print out a blank
	invoke	print_char			;AN051;   before volume message
	mov	dx,offset trangroup:VolSerMes_ptr ;AN000; get serial number message

printvol_end:
	jmp	std_printf			;AC000; go print and exit


;****************************************************************
;*
;* ROUTINE:	Set_ext_error_msg
;*
;* FUNCTION:	Sets up extended error message for printing
;*
;* INPUT:	return from INT 21
;*
;* OUTPUT:	extended error message set up in extended error
;*		buffer.
;*
;****************************************************************

Set_ext_error_msg proc near			;AN000;

	call	get_ext_error_number		;AC022; get the extended error
	PUBLIC	Set_ext_error_from_ax
Set_ext_error_from_ax LABEL NEAR
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,ax		;AN000; get message number in control block
	stc					;AN000; make sure carry is set

	ret					;AN000; return

Set_ext_error_msg endp				;AN000;

;****************************************************************
;*
;* ROUTINE:	Get_ext_error_number
;*
;* FUNCTION:	Does get extended error function call
;*
;* INPUT:	return from INT 21
;*
;* OUTPUT:	AX - extended error number
;*
;****************************************************************

Get_ext_error_number proc near			;AN022;

	SaveReg <BX,CX,DX,SI,DI,BP,ES,DS>	;AN022; save registers
	mov	ah,GetExtendedError		;AN022; get extended error
	xor	bx,bx				;AN022; clear BX
	int	21h			;AN022;
	RestoreReg  <DS,ES,BP,DI,SI,DX,CX,BX>	;AN022; restore registers

	ret					;AN022; return

Get_ext_error_number endp			;AN022;

trancode    ends
	    end
