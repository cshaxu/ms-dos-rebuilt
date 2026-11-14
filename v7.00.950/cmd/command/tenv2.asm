	page ,132
;	SCCSID = @(#)tenv2.asm	1.1 85/05/14
;	SCCSID = @(#)tenv2.asm	1.1 85/05/14
TITLE	Part6 COMMAND Transient routines.
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;	Environment utilities and misc. routines

.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include find.inc
	include comseg.asm
	include comequ.asm
.list
.cref


DATARES SEGMENT PUBLIC BYTE		;AC000;
	EXTRN	pipeflag:byte
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	ACRLF_PTR:WORD
	EXTRN	BadCD_Ptr:WORD
	EXTRN	BadCPMes_Ptr:WORD
	EXTRN	parse_ctty:BYTE
	EXTRN	Badmkd_ptr:word
	EXTRN	BADRMD_PTR:WORD
	EXTRN	Extend_buf_ptr:word	;AN000;
	EXTRN	Extend_buf_sub:byte	;AN022;
	EXTRN	MD_exists_ptr:word	;AN006;
	EXTRN	msg_disp_class:byte	;AC000;
	EXTRN	NOSPACE_PTR:WORD
	EXTRN	parse_chdir:byte	;AC000;
	EXTRN	PIPEEMES_PTR:WORD
	EXTRN	string_buf_ptr:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	CURDRV:BYTE
	EXTRN	DESTINFO:BYTE
	EXTRN	DESTTAIL:WORD
	EXTRN	DIRCHAR:BYTE
	EXTRN	dirflag:byte		;AN015;
	EXTRN	DirNetworkPath:byte
	EXTRN	PathAttribFunction:word
	EXTRN	KPARSE:BYTE		;AC000;  3/3/KK
	EXTRN	msg_numb:word		;AN022;
	EXTRN	parse1_addr:dword	;AC000;
	EXTRN	parse1_type:byte	;AC000;
	EXTRN	PATHPOS:WORD
	EXTRN	ParseArgIndex:WORD
	EXTRN	PathChdirFunction:WORD
	EXTRN	PathGetdirFunction:WORD
	EXTRN	PathRmdirFunction:WORD
	EXTRN	PathMkdirFunction:WORD
	EXTRN	ObjCnt:BYTE
	EXTRN	RESSEG:WORD
	EXTRN	srcxname:byte		;AC000;
	EXTRN	string_ptr_2:word
	EXTRN	SWITCHAR:BYTE
	EXTRN	USERDIR1:BYTE
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC byte

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	cerror:near
	EXTRN	ParseArgument:near
	EXTRN	CheckParsedArgs:near
	EXTRN	GetParsedArg:near
	EXTRN	SelectPathInterface:near
	EXTRN	IsNetworkPath:near
	EXTRN	SetupMissingArgument:near

	PUBLIC	$chdir
	PUBLIC	$mkdir
	PUBLIC	$rmdir
	PUBLIC	crlf2
	PUBLIC	crprint
	PUBLIC	delim
	PUBLIC	error_output
	PUBLIC	fcb_to_ascz
	PUBLIC	pathchrcmp
	PUBLIC	pathcrunch
	PUBLIC	savudir
	PUBLIC	savudir1
	PUBLIC	scanoff
	PUBLIC	strcomp

break	$Chdir

; ****************************************************************
; *
; * ROUTINE:	 $CHDIR
; *
; * FUNCTION:	 Entry point for CHDIR command. Parse the command
; *		 line. If path is found, CHDIR to path. If a drive
; *		 letter is found, get and display the current dir
; *		 of the specified drive. If nothing is found, get
; *		 and display the current dir of the default drive.
; *
; * INPUT:	 command line at offset 81H
; *
; * OUTPUT:	 none
; *
; ****************************************************************

assume	ds:trangroup,es:trangroup

$CHDIR:
	mov	ParseArgIndex,1
	mov	di,offset TRANGROUP:parse_chdir
	invoke	ParseArgument
	jnc	short ChDirArgument
	or	ax,ax
	jz	short bwdJ
	cmp	ax,-1
	jnz	short ChDirErr
	mov	ax,10
	jmp	short ChDirExtra
ChDirArgument:
	push	si
	invoke	SelectPathInterface
	pop	si
	cmp	[bx].arglen,2
	jnz	short REALCD
	cmp	byte ptr [si+1],':'
	jnz	short REALCD
	invoke	CheckParsedArgs
	jc	short bwdJ
ChDirExtra:
	invoke	GetParsedArg
	mov	ax,1
	invoke	DirSetupParamError
	jmp	short ChDirErr
bwdJ:
	invoke	build_dir_for_chdir
	call	crlf2
ChDirDone:
	ret
REALCD:
	push	si
	invoke	move_to_srcbuf
	invoke	CheckParsedArgs
	pop	si
	jnc	short ChDirExtra
	invoke	SETPATH
	test	[DESTINFO],2
	jnz	short BadChDir
	mov	ax,PathChdirFunction
	int	21h
	jnc	short ChDirDone
	invoke	get_ext_error_number
	cmp	ax,error_path_not_found
	jz	short BadChDir
;SR;
; We want to issue "Invalid Directory" message even if the path is valid
;but is not a directory. The extended error returns "Access denied" which
;is kind of confusing. Issue the old message if access denied error is 
;returned
;
	cmp	ax,error_access_denied
	jz	short BadChDir
	call	Set_Ext_Error_Subst
	jmp	short ChDirErr
BadChDir:
	mov	dx,offset TRANGROUP:BADCD_ptr
ChDirErr:
	invoke	Std_Eprintf
	ret

break	$Mkdir

assume	ds:trangroup,es:trangroup

$MKDIR:
	CALL	SETRMMK
	JC	MkDirErr
	MOV	AX,PathMkdirFunction
	INT	21h
	jnc	short MkDirDone

	invoke	get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; see if path not found
	jz	MD_other_err			;AN022; yes - issue old message
	cmp	ax,error_access_denied		;AN022; access denied?
	jz	badmderr			;AN022; yes - see if file exists

	call	Set_Ext_Error_Subst		;AN022;
	jmp	short MkDirerr			;AC022; yes - go print it

BADMDERR:
	mov	dx,offset trangroup:srcxname	;AN006; Set Disk transfer address
	mov	ah,Set_DMA			;AN006;
	int	21h			;AN006;
	MOV	AH,Find_First			;AN006; see if file/dir exists
	mov	cx,attr_directory		;AN006;   search for directory
	INT	21h			;AN006;
	jc	MD_other_err			;AN006; doesn't exist - must be something else
	mov	dl,srcxname.find_buf_attr	;AN006; we found a file/dir
	test	dl,attr_directory		;AN006; was it a directory?
	jz	MD_other_err			;AN006; no - must have been a file
	mov	dx,offset trangroup:MD_exists_ptr ;AN006; set up already exists error
	jmp	short MkDirErr			;AN006; make sure we didn't have network error
MD_other_err:					;AN006;
	MOV	DX,OFFSET TRANGROUP:BADMKD_ptr
MkDirErr:
	invoke	Std_Eprintf
MkDirDone:
	return

Break	<Common MkDir/RmDir set up code>

;****************************************************************
;*
;* ROUTINE:	SETRMMK
;*
;* FUNCTION:	Parse routine for the internal MKDIR and RMDIR
;*		commands. Parses the command line for a required
;*		filespec.
;*
;* INPUT:	command line at offset 81H
;*
;* OUTPUT:	carry clear
;*		    DS:DX points to ASCIIZ argument
;*		carry set
;*		    DS:DX has error message pointer
;*
;****************************************************************

SETRMMK:
	mov	ParseArgIndex,1
	mov	ObjCnt,0
	mov	PathRmdirFunction,RMDIR SHL 8
	mov	PathMkdirFunction,MKDIR SHL 8
mrdir_parse:
	mov	di,offset TRANGROUP:parse_ctty
	invoke	ParseArgument
	jc	short mrdir_end
	inc	ObjCnt
	cmp	ObjCnt,1
	ja	short mrdir_extra
	test	cl,2
	jnz	short mrdir_bad
	push	si
	invoke	SelectPathInterface
	pop	si
	or	al,al
	jz	short mrdir_copy
	mov	PathRmdirFunction,713AH
	mov	PathMkdirFunction,7139H
mrdir_copy:
	mov	di,offset TRANGROUP:srcxname
	push	di
	push	si
mrdir_move_filename:				;AN000; put filespec in srcxname
	lodsb					;get a char from buffer
	stosb					;AN000; store in srcxname
	cmp	al,end_of_line_out		;AC000; it char a terminator?
	jnz	mrdir_move_filename		;AC000; no - keep moving
	pop	si
	pop	di
	mov	dx,di
	clc
	jmp	short mrdir_parse
mrdir_end:
	or	ax,ax
	jz	short mrdir_count
	cmp	ax,-1
	je	short mrdir_bad
	jmp	cerror
mrdir_bad:
	mov	dx,offset TRANGROUP:BadCPMes_Ptr
mrdir_error:
	stc
mrdir_return:
	ret
mrdir_extra:
	dec	ParseArgIndex
	invoke	GetParsedArg
	mov	ax,1
	invoke	DirSetupParamError
	jmp	short mrdir_error
mrdir_count:
	cmp	ObjCnt,1
	clc
	jz	short mrdir_return
	mov	ax,2
	invoke	SetupMissingArgument
	jmp	short mrdir_error

break	$Rmdir

assume	ds:trangroup,es:trangroup

$RMDIR:
	CALL	SETRMMK
	JC	RmDirErr
	JNZ	BADRDERR
	MOV	AX,PathRmdirFunction
	INT	21h
	jnc	short RmDirDone

	invoke	get_ext_error_number		;AN022; get the extended error
	cmp	ax,error_path_not_found 	;AN022; see if path not found
	jz	badrderr			;AN022; yes - issue old message
	cmp	ax,error_access_denied		;AN022; access denied?
	jz	badrderr			;AN022; yes - issue old message

	call	Set_Ext_Error_Subst		;AN022;
	jmp	short RmDirerr			;AC022; yes - go print it

BADRDERR:
	MOV	DX,OFFSET TRANGROUP:BADRMD_ptr

RmDirErr:
	invoke	STD_Eprintf
RmDirDone:
	return

;****************************************************************
;*
;* ROUTINE:	Set_ext_error_subst
;*
;* FUNCTION:	Sets up substitution for extended error
;*
;* INPUT:	AX - extended error number
;*		DX - offset of string
;*
;* OUTPUT:	Extend_Buf_Ptr set up for STD_EPRINTF
;*
;****************************************************************

Set_ext_error_subst  proc near			;AN022;

	mov	msg_disp_class,ext_msg_class	;AN022; set up extended error msg class
	mov	string_ptr_2,dx 		;AN022; get address of failed string
	mov	Extend_buf_sub,one_subst	;AN022; put number of subst in control block
	mov	dx,offset TranGroup:Extend_Buf_ptr ;AN022; get extended message pointer
	mov	Extend_Buf_ptr,ax		;AN022; get message number in control block

	ret					;AN022; return

Set_ext_error_subst  endp			;AN022;





Break	<SavUDir - preserve the users current directory on a particular drive>

;
; SavUDir - move the user's current directory on a drive into UserDir1
; SavUDir1 - move the user's current directory on a drive into a specified
;   buffer
;
;   Inputs:	DL has 1-based drive number
;		ES:DI has destination buffer (SavUDir1 only)
;   Outputs:	Carry Clear
;		    DS = TranGroup
;		Carry Set
;		    AX has error code
;   Registers Modified: AX, SI
;

SAVUDIR:
	MOV	DI,OFFSET TRANGROUP:USERDIR1

SAVUDIR1:
	MOV	AL,DL
	ADD	AL,'@'
	CMP	AL,'@'
	JNZ	GOTUDRV
	ADD	AL,[CURDRV]
	INC	AL				; A = 1

GOTUDRV:
	STOSB
	MOV	AH,[DIRCHAR]
	MOV	AL,':'
	STOSW
	PUSH	ES
	POP	DS
ASSUME	DS:NOTHING

	MOV	SI,DI
	MOV	AX,ES:[PathGetdirFunction]	; Get the Directory Text
	INT	21h
	jc	short RmDirDone
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP

	return


CRLF2:
	PUSH	DX
	MOV	DX,OFFSET TRANGROUP:ACRLF_ptr

PR:
	PUSH	DS
	PUSH	CS
	POP	DS
	MOV	msg_disp_class,util_msg_class
	invoke	std_printf
	POP	DS
	POP	DX

	return

;
; These routines (SCANOFF, DELIM) are called in batch processing when DS
; may NOT be TRANGROUP
;
ASSUME	DS:NOTHING,ES:NOTHING

SCANOFF:
	LODSB
	CALL	DELIM
	JZ	SCANOFF
	DEC	SI				; Point to first non-delimiter
ScanDone:
	return

;
; Input:    AL is character to classify
; Output:   Z set if delimiter
;	    NZ set otherwise
; Registers modified: none
;

DELIM:
	CMP	AL,' '
	jz	short ScanDone
	CMP	AL,'='
	jz	short ScanDone
	CMP	AL,','
	jz	short ScanDone
	CMP	AL,';'
	jz	short ScanDone
	CMP	AL,9				; Check for TAB character
	jz	short ScanDone
	CMP	AL,0ah				; Check for line feed character - BAS
	return


ASSUME	DS:TRANGROUP,ES:TRANGROUP


FCB_TO_ASCZ:					; Convert DS:SI to ASCIZ ES:DI
	push	bx
	mov	cx,8
	mov	bx,di
MAINNAME:
	lodsb
	stosb
	cmp	al,' '
	jz	short SKIPSPC
	mov	bx,di
SKIPSPC:
	loop	MAINNAME
	mov	di,bx
	mov	al,dot_chr
	stosb
	mov	cl,3
EXTNAME:
	lodsb
	stosb
	cmp	al,' '
	jz	short EXTSPACE
	mov	bx,di
EXTSPACE:
	loop	EXTNAME
	mov	di,bx
	xor	al,al
	stosb
	pop	bx
FCBReturn:
	ret

STRCOMP:
;
; Compare ASCIZ DS:SI with ES:DI.
; SI,DI destroyed.
;
	cmpsb
	jnz	short FCBReturn			; Strings not equal
	cmp	byte ptr [SI-1],0		; Hit NUL terminator?
	jz	short FCBReturn			; Yes, strings equal
	jmp	short STRCOMP			; Equal so far, keep going


CRPRINT:
	PUSH	AX
	MOV	AL,13
	PUSH	CX
	PUSH	DI
	MOV	DI,DX
	MOV	CX,-1
	PUSH	ES
	PUSH	DS
	POP	ES

	REPNZ	SCASB				; LOOK FOR TERMINATOR
	mov	byte ptr [di-1],0		; nul terminate the string
	POP	ES
	mov	string_ptr_2,dx
	mov	dx,offset trangroup:string_buf_ptr
	invoke	std_printf
	mov	ds:byte ptr [di-1],13		; now put the CR back
	JC	ERROR_OUTPUT

	POP	DI
	POP	CX
	POP	AX

	return

ERROR_OUTPUT:
	PUSH	CS
	POP	DS
ASSUME	DS:TRANGROUP
	MOV	ES,[RESSEG]
ASSUME	ES:RESGROUP

	MOV	DX,OFFSET TRANGROUP:NOSPACE_ptr
	CMP	[PIPEFLAG],0
	JZ	GO_TO_ERROR

	invoke	PipeOff
	MOV	DX,OFFSET TRANGROUP:PIPEEMES_ptr
GO_TO_ERROR:
	JMP	CERROR

ASSUME	DS:TRANGROUP,ES:TRANGROUP

PATHCHRCMP:
;---- Mod for path invocation ----
PUBLIC pathchrcmp
;----

	push	ax
	mov	ah,'/'
	CMP	[SWITCHAR],ah
	JZ	NOSLASHT
	CMP	AL,'/'
	jz	pccont

NOSLASHT:
	CMP	AL,'\'
pccont:
	pop	ax

	return

;
; PATHCRUNCH -
;
; ENTRY FCB (in PSP) contains drive # to crunch on
;       PathPos = ptr to string with pathname in it
;       PathCnt = length of string
;
; EXIT  PathPos = ptr after pathname (w/ NULL) in string
;       PathCnt = length left in string
;       DestIsDir = nonzero if pathname delimiter char's found in pathname
;       DestInfo<bit1> = set if wildcard char's found in pathname
;       If path crunched successfully,
;         CY = clear
;         Current directory is changed to directory in pathname
;         UserDir1 contains previous directory for use by RestUDir
;         RestDir = nonzero to flag later restoration of user's dir
;         DestTail = ptr to beginning of filename
;         If filename found in pathname,
;           ZR = clear
;           FCB filename fields contain filename
;         If filename not found (pure directory path),
;           ZR = set
;           FCB filename fields are wildcarded with ?'s
;       If pathcrunch failed (no ChDir's worked),
;         CY = set
;         Msg_Numb = extended error code
;
; NOTE  DIR asks PathCrunch to forego parsing the filename into the
;       FCB by setting DirFlag.  In this case, the FCB is returned
;       with the filename wildcarded.
;
PATHCRUNCH:
        mov     [msg_numb],0            ;AN022; Set up message flag
        CMP     DirNetworkPath,0        ; network paths have no current drive
        JNZ     SHORT pcrunch_scan
        MOV     DL,DS:[FCB]             ; DL = drive # (1 = A)
        CALL    SAVUDIR                 ; save current directory in UserDir1
        jc      pcrunch_cderrJ           ;AN022; if error on current dir - report

pcrunch_scan:
        invoke  SETPATH                 ; scan past switches, whitespace

;       DX = ptr to pathname, NULL-terminated
;       PathPos = ptr to byte after NULL at end of pathname

        TEST    dirflag,2               ; caller requests filename handling
        JNZ     TRYPEEL
        TEST    [DESTINFO],2            ; test if wildcards (? or *) seen
        JNZ     TRYPEEL                 ; wildcard seen, peel filename

        CALL    pcrunch_chdir
        JNC     chdir_worked
        JZ      pcrunch_initial_error
        CALL    pcrunch_attrib
        JC      pcrunch_initial_error
        TEST    CL,18h                  ; directory or volume label
        JNZ     chdir_worked
        JMP     SHORT TRYPEEL

pcrunch_initial_error:
        invoke  get_ext_error_number    ;AN022; get the extended error
        cmp     ax,error_file_not_found
        jz      trypeel
        cmp     ax,error_path_not_found ;AN022; if path not found
        jz      trypeel                 ;AC022;     keep trying
        cmp     ax,error_access_denied  ;AN022; if access denied
        jz      trypeel                 ;AC022;     keep trying
        mov     [msg_numb],ax           ;AN022; set up message flag
        jmp     peelfail                ;AN022; exit with other error

chdir_worked:
        MOV     AL,'?'                  ; if pure dir, wildcard filename in FCB
        MOV     DI,5DH
	MOV	CX,11
        REP     STOSB
        XOR     AL,AL                   ; return carry clear, zero set
        return

pcrunch_cderrj: 				;AN022; need this for long jmp
	jmp	pcrunch_cderr			;AN022;

TRYPEEL:
        MOV     SI,[PATHPOS]
        DEC     SI                      ; SI = ptr to NULL at end of pathname
        MOV     AL,[SI-1]               ; AL = last char of pathname

	CMP	[KPARSE],0
	JNZ	DELSTRT 			; Last char is second KANJI byte, might be '\'

	CALL	PATHCHRCMP
	JZ	PEELFAIL			; Trailing '/'

DELSTRT:
        MOV     CX,SI                   ; CX = ptr to NULL at end of pathname
        MOV     SI,DX                   ; SI = ptr to start of pathname
        PUSH    DX                      ; save ptr to pathname
DELLOOP:
        CMP     SI,CX
        JZ      GOTDELE                 ; no char's left, we have what we have
        LODSB                           ; AL = next char of pathname
        invoke  TESTKANJ
        JZ      NOTKANJ8                ; not Kanji, move along
        INC     SI
	JMP	DELLOOP

NOTKANJ8:
        CALL    PATHCHRCMP
        JNZ     DELLOOP                 ; not a path delimiter, keep looking
        MOV     DX,SI
        DEC     DX                      ; DX = ptr to last delimiter found
        JMP     DELLOOP                 ; go look for more

GOTDELE:
        MOV     SI,DX                   ; SI = ptr to pathname or last delim
        POP     DX                      ; DX = ptr to pathname
        CMP     SI,DX
        JZ      BADRET                  ; didn't find path delim
        MOV     CX,SI                   ; CX = ptr to last path delimiter
        MOV     SI,DX                   ; SI = ptr to pathname

DELLOOP2:                               ; Set value of KPARSE
        CMP     SI,CX
        JZ      TRYCD                   ; roll up till SI meets CX
        MOV     [KPARSE],0
	LODSB
	INVOKE	TESTKANJ
	JZ	DELLOOP2
	INC	SI
	INC	[KPARSE]
	JMP	DELLOOP2

TRYCD:
        push    ax
        mov     al,dot_chr              ; AL = '.'
        CMP     BYTE PTR [SI+1],al      ; check for '.' after path delim
					;M019; allow continuation if '. ' or 
					;M019; '..' is not found.
	jnz	@F			;M019; '.' not found
	cmp	BYTE PTR [SI+2],al	;M019; check for '..'
	jz	@F			;M019; found '..'
	cmp	BYTE PTR [SI+2],0	;M019; check for '. ' (null terminated)
@@:     pop     ax
        JZ      PEELFAIL                ; if . or .., pure cd should have worked
        mov     al,[si-1]
        CMP     al,':'                  ; Special case d:\file
        JZ      BADRET

	CMP	[KPARSE],0
	JNZ	NOTDOUBLESL			; Last char is second KANJI byte, might be '\'

	CALL	PATHCHRCMP
	JNZ	NOTDOUBLESL
PEELFAIL:
	STC					; //
	return
NOTDOUBLESL:
	MOV	BYTE PTR [SI],0
	CALL    pcrunch_chdir
	JNC	CDSUCC
        JZ      pcrunch_cderr
        CALL    pcrunch_attrib
        JC      pcrunch_restore_error
        TEST    CL,18h
        JNZ     CDSUCC
pcrunch_restore_error:
        CALL    pcrunch_restore_slash
pcrunch_cderr:
	invoke	get_ext_error_number		;AN022; get the extended error
	mov	[msg_numb],ax			;AN022; set up message flag
	stc					;AN022; set up carry flag
	return

BADRET:
	MOV	AL,[SI]
	CALL	PATHCHRCMP			; Special case 'DIRCHAR'file
	STC
	retnz
	XOR	BX,BX
	XCHG	BH,[SI+1]
        CALL    pcrunch_chdir
        JNC     SHORT pcrunch_root_ok
        JZ      pcrunch_cderr
        CALL    pcrunch_attrib
        JC      pcrunch_cderr
        TEST    CL,18h
        JZ      pcrunch_cderr
pcrunch_root_ok:
	MOV	[SI+1],BH
        JMP     SHORT CDSUCC
CDSUCC:
	INC	SI				; Reset zero
	MOV	[DESTTAIL],SI
	pushf					;AN015; save flags
	test	dirflag,1			; don't parse if requested by caller
	jnz	pcrunch_end			;AN015;
	MOV	DI,FCB
	MOV	AX,(PARSE_FILE_DESCRIPTOR SHL 8) OR 02H ; Parse with default drive
	INT	21h
pcrunch_end:
	popf					;AN015; get flags back
	return

; Restore the delimiter when an attribute lookup reports file not found.
pcrunch_restore_slash:
        CMP     AX,error_file_not_found
        JNZ     SHORT pcrunch_restore_done
        MOV     BYTE PTR [SI],'\'
        MOV     AX,PathAttribFunction
        INT     21h
pcrunch_restore_done:
        RET

; Do not attempt to change the current directory to a network path.
pcrunch_chdir:
        PUSH    SI
        MOV     SI,DX
        CALL    IsNetworkPath
        OR      AL,AL
        STC
        JNZ     SHORT pcrunch_chdir_done
        MOV     AX,PathChdirFunction
        INT     21h
        MOV     AL,0FFh
        INC     AL
        PUSHF
        invoke  SETREST1
        POPF
pcrunch_chdir_done:
        POP     SI
        RET

pcrunch_attrib:
        MOV     AX,PathAttribFunction
        XOR     BL,BL
        INT     21h
        RET

trancode    ends
	    end
