	TITLE	DOS_DELETE - Internal DELETE call for MS-DOS
	NAME	DOS_DELETE

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	DELETE.ASM - Low level routine for deleting files
;
;		DOS_DELETE
;		REN_DEL_Check


;   Revision history:
;
;   A000  version 4.00	Jan. 1988
;   A001  Fastopen Rename fix	April 1989

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	INCLUDE FASTOPEN.INC
	include sf.inc
	include filemode.inc
	include mult.inc
	include dpb.inc
	INCLUDE fastxxxx.inc
	.cref
	.list

Installed = TRUE

	i_need	IoState1,WORD
	i_need	FatClusterHigh,WORD
	i_need	NoSetDir,BYTE
	i_need	Creating,BYTE
	i_need	DELALL,BYTE
	i_need	THISDPB,DWORD
	i_need	THISSFT,DWORD
	i_need	THISCDS,DWORD
	i_need	CURBUF,DWORD
	i_need	ATTRIB,BYTE
	i_need	SATTRIB,BYTE
	i_need	WFP_START,WORD
	i_need	REN_WFP,WORD			 ;BN001
	i_need	NAME1,BYTE			 ;BN001
	i_need	FoundDel,BYTE
	i_need	AUXSTACK,BYTE
	i_need	VOLCHNG_FLAG,BYTE
	i_need	JShare,DWORD

	i_need	SAVE_BX,WORD			  ; DOS 4.00
	i_need	DMAADD,DWORD
	i_need	RENAMEDMA,BYTE

DOSCODE SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE

;---------------------------------------------------------------------------
;
; Procedure Name : DOS_DELETE
;
; Inputs:
;	[WFP_START] Points to WFP string ("d:/" must be first 3 chars, NUL
;		terminated)
;	[CURR_DIR_END] Points to end of Current dir part of string
;		( = -1 if current dir not involved, else
;		 Points to first char after last "/" of current dir part)
;	[THISCDS] Points to CDS being used
;		(Low word = -1 if NUL CDS (Net direct request))
;	[SATTRIB] Is attribute of search, determines what files can be found
; Function:
;	Delete the specified file(s)
; Outputs:
;	CARRY CLEAR
;		OK
;	CARRY SET
;	    AX is error code
;		error_file_not_found
;			Last element of path not found
;		error_path_not_found
;			Bad path (not in curr dir part if present)
;		error_bad_curr_dir
;			Bad path in current directory part of path
;		error_access_denied
;			Attempt to delete device or directory
;		***error_sharing_violation***
;			Deny both access required, generates an INT 24.
;			This error is NOT returned. The INT 24H is generated,
;			  and the file is ignored (not deleted). Delete will
;			  simply continue on looking for more files.
;			  Carry will NOT be set in this case.
; DS preserved, others destroyed
;---------------------------------------------------------------------------

FILEFOUND   = 01h
FILEDELETED = 10h

procedure   DOS_DELETE,NEAR

;hkn; DOS_Delete is called from file.asm and fcbio.asm. DS has been set up 
;hkn; appropriately at this point.

	DOSAssume   <DS>,"DOS_Delete"

	Invoke	TestNet
	JNC	LOCAL_DELETE

IF Installed EQ FALSE
	transfer NET_DELETE
ELSE
	MOV	AX,(multNET SHL 8) OR 19
	INT	2FH
	return
ENDIF

LOCAL_DELETE:
	MOV	FoundDel,00	; No files found and no files deleted
	EnterCrit   critDisk
	MOV	WORD PTR [CREATING],DIRFREE*256+0	; Assume not del *.*
	MOV	SI,[WFP_START]
SKPNUL:
	LODSB
	OR	AL,AL
	JNZ	SKPNUL			    ; go to end
	SUB	SI,4			    ; Back over possible "*.*"
	CMP	WORD PTR [SI],("." SHL 8 OR "*")
	JNZ	TEST_QUEST
	CMP	BYTE PTR [SI+2],"*"
	JZ	CHECK_ATTS
TEST_QUEST:
	SUB	SI,9		; Back over possible "????????.???"
	XCHG	DI,SI

;hkn; SS is DOSDATA
	context ES

	MOV	AX,"??"
	MOV	CX,4		; four sets of "??"
	REPE	SCASW
	JNZ	NOT_ALL
	XCHG	DI,SI
	LODSW
	CMP	AX,("?" SHL 8) OR "."
	JNZ	NOT_ALL
	LODSW
	CMP	AX,"??"
	JNZ	NOT_ALL
CHECK_ATTS:
	MOV	AL,BYTE PTR [SATTRIB]
	AND	AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
					; Look only at hidden bits
	CMP	AL,attr_hidden+attr_system+attr_directory+attr_volume_id+attr_read_only
					; All must be set
	JNZ	NOT_ALL

; NOTE WARNING DANGER-----
;    This DELALL stuff is not safe. It allows directories to be deleted.
;	It should ONLY be used by FORMAT in the ROOT directory.
;

	MOV	DELALL,0	     ; DEL *.* - flag deleting all
NOT_ALL:
	MOV	[NoSetDir],1
	invoke	GetPathNoSet
	ASSUME	ES:NOTHING
	JNC	Del_found
	JNZ	bad_path
	OR	CL,CL
	JZ	bad_path
No_file:
	MOV	AX,error_file_not_found
ErrorReturn:
	STC
	LeaveCrit   critDisk
	return

bad_path:
	MOV	AX,error_path_not_found
	JMP	ErrorReturn

Del_found:
	JNZ	NOT_DIR 		; Check for dir specified
	CMP	DelAll,0		; DelAll = 0 allows delete of dir.
	JZ	Not_Dir
Del_access_err:
	MOV	AX,error_access_denied
	JMP	ErrorReturn

NOT_DIR:
	OR	AH,AH		; Check if device name
	JS	Del_access_err	; Can't delete I/O devices

; Main delete loop.  CURBUF+2:BX points to a matching directory entry.

DELFILE:
	OR	FoundDel,FILEFOUND	; file found, not deleted yet

; If we are deleting the Volume ID, then we set VOLUME_CHNG flag to make
; DOS issue a build BPB call the next time this drive is accessed.

	PUSH	DS
	MOV	AH,DelAll
	LDS	DI,CURBUF
	ASSUME	DS:NOTHING

;hkn; SS override
	TEST	Attrib,attr_read_only	; are we deleting RO files too?
	JNZ	DoDelete		; yes

	TEST	DS:[BX.dir_attr],attr_read_only
	JZ	DoDelete		; not read only

	POP	DS
	JMP	SHORT DelNxt		; Skip it (Note ES:BP not set)

DoDelete:
	call	REN_DEL_Check		; Sets ES:BP = [THISDPB]
	JNC	DEL_SHARE_OK
	POP	DS
	JMP	SHORT DelNxt		; Skip it

DEL_SHARE_OK:
	Assert	ISBUF,<DS,DI>,"Del_Share_OK"
	TEST	[DI.buf_flags],buf_dirty  ;LB. if already dirty 		;AN000;
	JNZ	yesdirty		  ;LB.	  don't increment dirty count   ;AN000;
	invoke	INC_DIRTY_COUNT 	  ;LB.					;AN000;
	OR	[DI.buf_flags],buf_dirty
yesdirty:
	MOV	[BX].DIR_NAME,AH	; Put in E5H or 0
	MOV	BX,[SI+dir_first_hi-dir_first]
	MOV	[FatClusterHigh],BX
	.386
	SHL	EBX,16
	MOV	BX,[SI] 		; Get firclus pointer
	CMP	ES:[BP.dpb_fat_size],0
	JZ	DeleteClusterReady
	MOVZX	EBX,BX
DeleteClusterReady:
	POP	DS
	DOSAssume   <DS>,"Del_Share_OK"
	OR	[FoundDel],FILEDELETED	; Deleted file

	CMP	EBX,2
	JB	DeleteLongNames		; File has invalid FIRCLUS (too small)
	CMP	ES:[BP.dpb_fat_size],0
	JZ	DeleteCluster32
	CMP	BX,ES:[BP.dpb_max_cluster]
	JMP	SHORT DeleteClusterCheck
DeleteCluster32:
	CMP	EBX,ES:[BP.dpb_max_cluster32]
DeleteClusterCheck:
	JA	DeleteLongNames		; File has invalid FIRCLUS (too big)
	ROR	EBX,16
	MOV	[FatClusterHigh],BX
	ROR	EBX,16

	invoke	RELEASE 		; Free file data
	JC	No_fileJ

DeleteLongNames:
	MOV	DI,OFFSET DOSDATA:IoState1
	invoke	LfnDeleteEntries


; DOS 3.3  FastOpen

DELNXT:
	LES	BP,[THISDPB]		; Possible to get here without this set
	invoke	GETENTRY		; Registers need to be reset
	JC	No_fileJ
	invoke	NEXTENT
	JNC	DELFILE
	LES	BP,[THISDPB]		; NEXTENT sets ES=DOSGROUP
	invoke	UpdateFSInfo
	MOV	AL,ES:[BP.dpb_drive]
	invoke	DeferredFlush
	JC	No_fileJ
;
; Now we need to test FoundDel for our flags.  The cases to consider are:
;
;   not found not deleted		file not found
;   not found	  deleted		*** impossible ***
;	found not deleted		access denied (read-only)
;	found	  deleted		no error
;
	TEST	FoundDel,FILEDELETED	; did we delete a file?
	JZ	DelError		; no, figure out what's wrong.
; We set VOLCHNG_FLAG to indicate that we have changed the volume label
; and to force the DOS to issue a media check.
	TEST	[Attrib],attr_volume_id
	jz	No_Set_Flag
	PUSH	AX
	PUSH	ES
	PUSH	DI
	LES	DI,[THISCDS]
ASSUME	ES:NOTHING
	MOV	AH,BYTE PTR ES:[DI]	; Get drive
	SUB	AH,'A'                  ; Convert to 0-based
	mov	byte ptr [VOLCHNG_FLAG],AH
	XOR	BH,BH			;>32mb delte volume id from boot record ;AN000;
	invoke	Set_Media_ID		;>32mb set voulme id to boot record	;AN000;
	invoke	FATRead_CDS		; force media check
	POP	DI
	POP	ES
	POP	AX
No_Set_Flag:
	LeaveCrit   critDisk		; carry is clear
	return
DelError:
	TEST	FoundDel,FILEFOUND	; not deleted.	Did we find file?
	JNZ	Del_access_errJ 	; yes. Access denied
No_fileJ:
	JMP	No_file 		; Nope
Del_Access_errJ:
	JMP	Del_access_err

	.8086
EndProc DOS_DELETE

Break	<REN_DEL_Check - check for access for rename and delete>
;-----------------------------------------------------------------------------
; Procedure Name : REN_DEL_Check
;
; Inputs:
;	[THISDPB] set
;	[CURBUF+2]:BX points to entry
;	[CURBUF+2]:SI points to firclus field of entry
;	[WFP_Start] points to name
; Function:
;	Check for Exclusive access on given file.
;	  Used by RENAME, SET_FILE_INFO, and DELETE.
; Outputs:
;	ES:BP = [THISDPB]
;	NOTE: The WFP string pointed to by [WFP_Start] Will be Modified.  The
;		last element will be loaded from the directory entry.  This is
;		so the name given to the sharer doesn't have any meta chars in
;		it.
;	Carry set if sharing violation, INT 24H generated
;	    NOTE THAT AX IS NOT error_sharing_violation.
;		This is because input AX is preserved.
;		Caller must set the error if needed.
;	Carry clear
;		OK
; AX,DS,BX,SI,DI preserved
;----------------------------------------------------------------------------

procedure  REN_DEL_Check,NEAR

	PUSH	DS
	PUSH	DI
	PUSH	AX
	PUSH	BX
	PUSH	SI		; Save CURBUF pointers
	context ES

;hkn; context ES will assume ES to DOSDATA
;hkn; ASSUME	ES:DOSGROUP

;hkn; SS override
	MOV	DI,[WFP_START]	; ES:DI -> WFP
	MOV	SI,BX

;hkn; SS override
	MOV	DS,WORD PTR [CURBUF+2]	; DS:SI -> entry (FCB style name)
	MOV	BX,DI		; Set backup limit for skipback
	ADD	BX,2		; Skip over d: to point to leading '\'
	invoke	StrLen		; CX is length of ES:DI including NUL
	DEC	CX		; Don't include nul in count
	ADD	DI,CX		; Point to NUL at end of string
	invoke	SkipBack	; Back up one element
	INC	DI		; Point to start of last element

;hkn; SS override
	MOV	[SAVE_BX],DI	;IFS. save for DOS_RENAME			   ;AN000;
	invoke	PackName	; Transfer name from entry to ASCIZ tail.
	POP	SI		; Get back entry pointers
	POP	BX
	PUSH	BX
	PUSH	SI		; Back on stack
	context DS

;hkn; context DS will assume ES to DOSDATA
;hkn; ASSUME	DS:DOSGROUP

;
; Close the file if possible by us.
;
	MOV	WORD PTR [THISSFT+2],DS

;hkn; AUXSTACK is in DOSDATA
	MOV	WORD PTR [THISSFT],OFFSET DOSDATA:AUXSTACK - (SIZE sf_entry)
				; Scratch space
	XOR	AH,AH		; Indicate file to DOOPEN (high bit off)
	invoke	DOOPEN		; Fill in SFT for share check
	LES	DI,[THISSFT]
	MOV	ES:[DI.sf_mode],sharing_deny_both   ; requires exclusive access
	MOV	ES:[DI.sf_MFT],0
	MOV	ES:[DI.sf_ref_count],0	; Pretend closed and free
	CLC
CheckDone:
	LES	BP,[THISDPB]
	POP	SI
	POP	BX
	POP	AX
	POP	DI
	POP	DS
	return

EndProc REN_DEL_Check

DOSCODE	ENDS
	END

