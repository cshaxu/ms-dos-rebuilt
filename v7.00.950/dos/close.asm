	TITLE	DOS_CLOSE/COMMIT - Internal SFT close and commit call for MSDOS
	NAME	DOS_CLOSE

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	Internal Close and Commit calls to close a local or NET SFT.
;
;	DOS_CLOSE
;	DOS_COMMIT
;	FREE_SFT
;	SetSFTTimes
;
;	Revision history:
;
;	   AN000  version 4.00	Jan. 1988
;	   A005   PTM 3718 --- lost clusters when fastopen installed
;	   A011   PTM 4766 --- C2 fastopen problem

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include sf.inc
	include mult.inc
	include bugtyp.inc
	.cref
	.list

Installed = TRUE

	i_need	DOS_FLAG,BYTE
	i_need	EXTOPEN_ON,BYTE
	i_need	NlsBuffer,BYTE
	i_need	THISSFT,DWORD
	i_need	CURBUF,DWORD
	i_need	THISDRV,BYTE
	I_need	FailErr,BYTE
	I_Need	PROC_ID,WORD
	I_Need	USER_ID,WORD
	i_need	JShare,DWORD
	i_need	OLD_FIRSTCLUS,WORD	  ;F.O. >32mb

DOSCODE SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE


Break <DOS_CLOSE -- CLOSE FILE from SFT>
;---------------------------------------------------------------------------
;
; Procedure Name : DOS_CLOSE
;
; Inputs:
;	[THISSFT] set to the SFT for the file being used
; Function:
;	Close the indicated file via the SFT
; Returns:
;	sf_ref_count decremented otherwise
;	ES:DI point to SFT
;	Carry set if error
;	    AX has error code
; DS = DOSDATA on return, others destroyed
;---------------------------------------------------------------------------

;hkn; DOS_CLOSE called from fcbio.asm and handle.asm. DS alreday set up.

	PUBLIC	CloseClean
CloseClean:
	push	ds
	pop	es
	mov	di,si
CloseDevice:
	clc
	jmp	CloseFinish
CloseReadError:
	test	bp,devid_file_clean
	jnz	CloseReadDone
	mov	al,error_access_denied
	stc
CloseReadDone:
	jmp	CloseFinish
CloseAccessDate:
	mov	es:[di+12h],ax
	jmp	short clook

procedure   DOS_CLOSE,NEAR
	DOSAssume   <DS>,"DOS_Close"

	LES	DI,[THISSFT]
	Assert	ISSFT,<ES,DI>,<"DOS_CLOSE">
	fmt	TypAccess,LevBUSY,<"$p: CLOSE SFT: $x:$x\n">,<ES,DI>
	MOV	BX,ES:[DI.sf_flags]

;	Network closes are handled entirely by the net code.

	TEST	BX,sf_isnet
	JZ	LocalClose
	CallInstall Net_Close,multnet,6
	return

;
; All closes release the sharing information.
; No commit releases sharing information
;
; All closes decrement the ref count.
; No commit decrements the ref count.
;
LocalClose:
	EnterCrit   critDisk
	CALL	SetSFTTimes
	CALL	Free_SFT		; dec ref count or mark as busy

;hkn; SS is DOSDATA
	Context DS

	SAVE	<AX,BX>
	invoke	ShareEnd
	RESTORE <BX,AX>
;
; Commit enters here.  AX from commit MUST be <> 1, BX is flags word
;
CloseEntry:
	PUSH	AX
;
; Devices bypass directory access. Clean files may update the access date.
;
	TEST	BX,devid_device
	jnz	CloseDevice
	push	bx
	invoke	DirFromSFT
	pop	bp
	jc	CloseReadError
	ASSUME	DS:NOTHING
	test	DOS_FLAG,40h
	jnz	CloseCheckClean
	test	[si].sf_mode,4
	jnz	CloseCheckClean
	push	ds
	push	bx
	lds	bx,[si].sf_devptr
	mov	bl,[bx]
	mov	bh,0
	test	BYTE PTR ss:[bx+NlsBuffer+20],4
	pop	bx
	pop	ds
	jz	CloseCheckClean
	test	bp,devid_file_clean
	jz	CloseGetDate
	or	EXTOPEN_ON,2
CloseGetDate:
	push	ds
	invoke	DATE16
	pop	ds
	ASSUME	DS:NOTHING
	cmp	ax,es:[di+12h]
	jnz	CloseAccessDate
CloseCheckClean:
	test	bp,devid_file_clean
	jz	clook
	jmp	CloseClean
clook:
;
; ES:DI points to entry
; DS:SI points to SFT
; ES:BX points to buffer header
;
	SAVE	<DI,SI>
	LEA	SI,[SI].sf_name
;
; ES:DI point to directory entry
; DS:SI point to unpacked name
;
	invoke	XCHGP
;
; ES:DI point to unpacked name
; DS:SI point to directory entry
;
	invoke	MetaCompare
	invoke	XCHGP
	RESTORE <SI,DI>
	JZ	CLOSE_GO		; Name OK
Bye:	MOV	DI,SI
	PUSH	DS
	POP	ES			; ES:DI points to SFT
	PUSH	SS
	POP	DS
	STC
	MOV	AL,error_file_not_found
	JMP	CloseFinish

CLOSE_GO:
	test	bp,devid_file_clean
	jnz	CloseSetFields
	TEST	[SI].sf_mode,sf_isfcb
	jnz	setattr
	MOV	AL,[SI].sf_attr
	MOV	ES:[DI].dir_attr,AL
setattr:
	OR	BYTE PTR ES:[DI.dir_attr],attr_archive	;Set archive
CloseSetFields:
	MOV	AX,ES:[DI.dir_first]	;AN011;F.O. save old first clusetr

;hkn; SS override
	MOV	[OLD_FIRSTCLUS],AX	;AN011;F.O. save old first clusetr

	MOV	AX,[SI.sf_firclus]
	MOV	ES:[DI.dir_first],AX	;Set firclus pointer
	MOV	AX,WORD PTR [SI.sf_size]
	MOV	ES:[DI.dir_size_l],AX	;Set size
	MOV	AX,WORD PTR [SI.sf_size+2]
	MOV	ES:[DI.dir_size_h],AX
	MOV	AX,[SI.sf_date]
	MOV	ES:[DI.dir_date],AX	;Set date
	MOV	AX,[SI.sf_time]
	MOV	ES:[DI.dir_time],AX	;Set time
;; File Tagging

;	MOV	AX,[SI.sf_codepage]	   ;AN000;
;	MOV	ES:[DI.dir_codepg],AX	   ;AN000;Set code page
;	MOV	AX,[SI.sf_extcluster]	   ;AN000;
;	MOV	ES:[DI.dir_extcluster],AX  ;AN000;   ;Set XA cluster
;	MOV	AL,[SI.sf_attr_hi]	   ;AN000;
;	MOV	ES:[DI.dir_attr2],AL	   ;AN000;   ;Set high attr

;; File Tagging
	TEST	ES:[BX.buf_flags],buf_dirty  ;LB. if already dirty		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	ES:[BX.buf_flags],buf_dirty ;Buffer dirty
yesdirty:
	SAVE	<DS,SI>
	MOV	CX,[SI.sf_firclus]	; do this for Fastopen

;hkn; SS override
	MOV	AL,[THISDRV]
;;; 10/1/86  update fastopen cache
	PUSH	DX
	MOV	AH,0			; dir entry update
	MOV	DL,AL			; drive number A=0, B=1,,,
	OR	CX,CX			  ;AN005; first cluster 0; may be truncated
	JNZ	do_update2		  ;AN005; no, do update
	MOV	AH,3			  ;AN005; do a delete cache entry
	MOV	DI,WORD PTR [SI.sf_dirsec]   ;AN005; cx:di = dir sector
	MOV	CX,WORD PTR [SI.sf_dirsec+2] ;AN005;
	MOV	DH,[SI.sf_dirpos]	     ;AN005; dh= dir pos
	JMP	SHORT do_update 	;AN011;F.O.
do_update2:				;AN011;F.O.

;hkn; SS override fort OLD_FIRSTCLUS
	CMP	CX,[OLD_FIRSTCLUS]	;AN011;F.O. same as old first clusetr?
	JZ	do_update		;AN011;F.O. yes
	MOV	AH,2			;AN011;F.O. delete the old entry
	MOV	CX,[OLD_FIRSTCLUS]	;AN011;F.O.
do_update:				  ;AN005;

;hkn; SS is DOSDATA
	Context DS
	invoke	FastOpen_Update 	; invoke fastopen
	POP	DX

;;; 10/1/86  update fastopen cache
	invoke	DeferredFlush		; flush all relevant buffers
	RESTORE <DI,ES>
	jnc	CloseFinish
	push	ds
	push	bx
	lds	bx,es:[di].sf_devptr
	mov	bl,[bx]
	mov	bh,0
	ASSUME	DS:DOSDATA
	and	BYTE PTR [bx+NlsBuffer+20],0FBh
	pop	bx
	pop	ds
	ASSUME	DS:NOTHING
	mov	al,error_access_denied
	stc
CloseFinish:
;
; Indicate to the device that the SFT is being closed.
;
;;;; 7/21/86
	PUSHF				; save flag from DirFromSFT
	invoke	Dev_Close_SFT
	POPF
;;;; 7/21/86
;
; See if the ref count indicates that we have busied the SFT.  If so, mark the
; SFT as being free.  Note that we do NOT need to be in critSFT as we are ONLY
; going to be moving from busy to free.
;
	POP	CX			; get old ref count
	PUSHF
	fmt	TypAccess,LevBUSY,<"$p: DOSFreeSFT: $x:$x from $x\n">,<ES,DI,AX>
	DEC	CX			; if cx != 1
	JNZ	NoFree			; then do NOT free SFT
	Assert	ISSFT,<ES,DI>,"DOS_FREE_SFT"
	invoke	ClearDirSft
NoFree:
	LeaveCrit   critDisk
	POPF
	push	ss
	pop	ds
	ASSUME	DS:DOSDATA
	return
EndProc DOS_Close

;---------------------------------------------------------------------------
;
; Procedure Name : FREE_SFT
;
; ES:DI -> SFT. Decs sft_ref_count.  If the count goes to 0, mark it as busy.
; Flags preserved.  Return old ref count in AX
;
; Note that busy is indicated by the SFT ref count being -1.
;
;---------------------------------------------------------------------------

Procedure   FREE_SFT,NEAR
	DOSAssume   <DS>,"Free_SFT"

	PUSHF		; Save carry state
	MOV	AX,ES:[DI.sf_ref_count]
	DEC	AX
	JNZ	SetCount
	DEC	AX
SetCount:
	XCHG	AX,ES:[DI.sf_ref_count]
	POPF
	return

EndProc Free_SFT

	Break	<DOS_Commit - update directory entries>
;
;----------------------------------------------------------------------------
;
;**	DOS_Commit - UPdate Directory Entries
;
;	ENTRY	same as DOS_CLOSE (??? BUGBUG - update this jgl)
;		(DS) = DOSGROUP
;	EXIT	Same as DOS_CLOSE except ref_count field is not altered
;	USES	all but DS
;
;----------------------------------------------------------------------------
;

procedure   DOS_COMMIT,NEAR
	DOSAssume   <DS>,"DOS_Commit"	 ;hkn; called from srvcall. DS already set up.

	LES	DI,[THISSFT]
	MOV	BX,ES:[DI.sf_flags]
	TEST	BX,devid_file_clean + devid_device	;Clears carry
	jnz	CommitReturn
	TEST	BX,sf_isnet
	JZ	LOCAL_COMMIT
IF NOT Installed
	transfer NET_COMMIT
ELSE
	MOV	AX,(multNET SHL 8) OR 7
	INT	2FH
CommitReturn:
	return
ENDIF

;
; Perform local commit operation by doing a close but not releaseing the SFT.
; There are three ways we can do this.	One is to enter a critical section to
; protect a potential free.  The second is to increment the ref count to mask
; the close decrementing.
;
; The proper way is to let the caller's of close decide if a decrement should
; be done.  We do this by providing another entry into close after the
; decrement and after the share information release.
;
LOCAL_COMMIT:
	EnterCrit   critDisk
	EnterCrit   critDisk		;PTM.					;AN000;
	call	SetSFTTimes
	MOV	AX,-1
	call	CloseEntry
	PUSHF				;PTM.					;AN000;
	invoke	DEV_OPEN_SFT		;PTM.  increment device count		;AN000;
	POPF				;PTM.					;AN000;
	LeaveCrit CritDisk		;PTM.					;AN000;
	return

EndProc DOS_COMMIT

Break	<SetSFTTimes - signal a change in the times for an SFT>
;----------------------------------------------------------------------------
;
; Procedure Name : SetSFTTimes
;
;   SetSFTTimes - Examine the flags for a SFT and set the time appropriately.
;   Reflect these times in other SFT's for the same file.
;
;   Inputs:	ES:DI point to SFT
;		BX = sf_flags set apprpriately
;   Outputs:	Set sft times to current time iff File & dirty & !nodate
;   Registers modified: All except ES:DI, BX, AX
;
;----------------------------------------------------------------------------

Procedure   SetSFTTimes,NEAR
	Assert	ISSFT,<ES,DI>,"SetSFTTimes"

;	File clean or device does not get stamped nor disk looked at.

	TEST	BX,devid_file_clean + devid_device
	jnz	SetTimesDone

;	file and dirty.  See if date is good

	TEST	BX,sf_close_nodate
	jnz	SetTimesDone
	SAVE	<AX,BX>
	invoke	DATE16			; Date/Time to AX/DX
    ASSUME DS:DOSDATA
	MOV	ES:[DI.sf_date],AX
	MOV	ES:[DI.sf_time],DX
	XOR	AX,AX
if installed
	call	JShare + 14 * 4
else
	call	ShSU
endif
	RESTORE <BX,AX>
SetTimesDone:
	return
EndProc SetSFTTimes

DOSCODE	ENDS
	END
