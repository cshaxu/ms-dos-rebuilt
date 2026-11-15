	TITLE	DIR - Directory and path cracking
	NAME	Dir

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	Main Path cracking routines, low level search routines
;
;	  FindEntry
;	  SEARCH
;	  Srch
;	  NEXTENT
;	  MetaCompare
;	  NEXTENTRY
;	  GETENTRY
;	  GETENT
;	  SETDIRSRCH
;	  SETROOTSRCH
;
;	  Revision history:
;
;		A000   version 4.00    Jan. 1988

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	include fastopen.inc
	include dossym.inc
	include dpb.inc
	include sf.inc
	.cref
	.list


	i_need	sft_addr,DWORD
	i_need	IoState1,WORD
	i_need	EntFree,WORD
	i_need	DirStart,WORD
	i_need	DirStartHigh,WORD
	i_need	ClusNumHigh,WORD
	i_need	ClusterWorkHigh,WORD
	i_need	FatClusterHigh,WORD
	i_need	FatNextHigh,WORD
	i_need	LastEnt,WORD
	i_need	ClusNum,WORD
	i_need	CurBuf,DWORD
	i_need	Attrib,BYTE
	i_need	DelAll,BYTE
	i_need	VolID,BYTE
	i_need	Name1,BYTE
	i_need	ThisDPB,DWORD
	i_need	EntLast,WORD
	i_need	Creating,BYTE
	i_need	SecClusPos,BYTE
	i_need	ClusFac,BYTE
	i_need	NxtClusNum,WORD
	i_need	NxtClusNumHigh,WORD
	i_need	DirSec,DWORD			;AN000;
	I_need	HIGH_SECTOR,WORD		;AN000;


DOSCODE	Segment
	allow_getdseg
	EXTRN	MetaCompare:NEAR
	ASSUME	SS:DOSDATA,CS:DOSCODE

Break	<FINDENTRY -- LOOK FOR AN ENTRY>
;---------------------------------------------------------------------------
;
; Procedure Name : FINDENTRY,SEARCH
;
; Inputs:
;	[THISDPB] set
;	[SECCLUSPOS] = 0
;	[DIRSEC] = Starting directory sector number
;	[CLUSNUM] = Next cluster of directory
;	[CLUSFAC] = Sectors/Cluster
;	[NAME1] = Name to look for
; Function:
;	Find file name in disk directory.
;	"?" matches any character.
; Outputs:
;	Carry set if name not found
;	ELSE
;	Zero set if attributes match (always except when creating)
;	AH = Device ID (bit 7 set if not disk)
;	[THISDPB] = Base of drive parameters
;	DS = DOSGROUP
;	ES = DOSGROUP
;	[CURBUF+2]:BX = Pointer into directory buffer
;	[CURBUF+2]:SI = Pointer to First Cluster field in directory entry
;	[CURBUF] has directory record with match
;	[NAME1] has file name
;	[LASTENT] is entry number of the entry
; All other registers destroyed.
;----------------------------------------------------------------------------

;hkn; called from rename.asm and dir2.asm. DS must be already set up at
;hkn; this point.

procedure   SEARCH,near
entry	FindEntry
	DOSAssume   <DS>,"FindEntry"

	invoke	STARTSRCH
	MOV	AL,Attrib
	AND	AL,NOT attr_ignore	; Ignore useless bits
	CMP	AL,attr_volume_id	; Looking for vol ID only ?
	JNZ	NOTVOLSRCH		; No
	CALL	SETROOTSRCH		; Yes force search of root
NOTVOLSRCH:
	CALL	GETENTRY
	.386
	JC	NEAR PTR SETESRET
	.8086

	entry	Srch
	MOV	IoState1,0
LfnSearchEntry:


	PUSH	DS
	MOV	DS,WORD PTR [CURBUF+2]
ASSUME	DS:NOTHING

;	(DS:bx) = directory entry address

	MOV	AH,DIR_NAME[BX]
	MOV	AL,DIR_ATTR[BX]
	invoke	LfnScanEntry
	JZ	LfnSkipEntry
	OR	AH,AH			; End of directory?
	JZ	FREE

;hkn; SS override
	CMP	AH,DelAll		; Free entry?
	JZ	FREE
	TEST	DIR_ATTR[BX],attr_volume_id	; Volume ID file?
	JZ	CHKFNAM 		; NO

;hkn; SS override
	INC	BYTE PTR [VOLID]
CHKFNAM:
;	Context ES

;hkn;	ASSUME	ES:DOSGroup
	ASSUME	ES:DOSDATA

	MOV	SI,SS
	MOV	ES,SI
	MOV	SI,BX

;hkn; NAME1 is in DOSDATA
	MOV	DI,OFFSET DOSDATA:NAME1
;;;;; 7/29/86

;hkn; SS override for NAME1
	CMP	BYTE PTR [NAME1],0E5H	 ; special char check
	JNZ	NO_E5
	MOV	BYTE PTR [NAME1],05H
NO_E5:
;;;;; 7/29/86
	CALL	MetaCompare
	JZ	FOUND
	POP	DS

entry	NEXTENT
	DOSAssume   <DS>,"NextEnt"

	Assert	ISDPB,<<WORD PTR THISDPB+2>,<WORD PTR THISDPB>>,"NextEnt"
	LES	BP,[THISDPB]
ASSUME	ES:NOTHING
	CALL	NEXTENTRY
	JNC	SRCH
	JMP	SHORT SETESRET

FREE:
	POP	DS
	DOSAssume   <DS>,"Free"
	MOV	CX,LASTENT
	CMP	CX,ENTFREE
	JAE	TSTALL
	MOV	ENTFREE,CX
TSTALL:
	CMP	AH,DelAll		; At end of directory?
NextEntJ:
	je	LfnNextEntry		; No - continue search
	MOV	[ENTLAST],CX
	STC
	JMP	SHORT SETESRET

LfnSkipEntry:
	POP	DS
LfnNextEntry:
	ASSUME	DS:DOSDATA
	LES	BP,[THISDPB]
	CALL	NEXTENTRY
	JNC	LfnSearchEntry
	JMP	SHORT SETESRET

FOUND:
;
; We have a file with a matching name.	We must now consider the attributes:
; ATTRIB	Action
; ------	------
; Volume_ID	Is Volume_ID in test?
; Otherwise	If no create then Is ATTRIB+extra superset of test?
;		If create then Is ATTRIB equal to test?
;
	MOV	CH,[SI] 		; Attributes of file
	POP	DS
	DOSAssume   <DS>,"found"
	MOV	AH,Attrib		; Attributes of search
	AND	AH,NOT attr_ignore
	LEA	SI,[SI+Dir_First-Dir_Attr]  ; point to firclus field
	TEST	CH,attr_volume_id	; Volume ID file?
	JZ	check_one_volume_id	; Nope check other attributes
	TEST	AH,attr_volume_id	; Can we find Volume ID?
	JZ	NEXTENT		; Nope, (not even $FCB_CREATE)
	XOR	AH,AH			; Set zero flag for $FCB_CREATE
	JMP	SHORT RETFF		; Found Volume ID
check_one_volume_id:
	CMP	AH,attr_volume_id	; Looking only for Volume ID?
	JZ	NEXTENT		; Yes, continue search
	invoke	MatchAttributes
	JZ	RETFF
	TEST	BYTE PTR [CREATING],-1	; Pass back mismatch if creating
	JZ	NEXTENT		; Otherwise continue searching
RETFF:
	LES	BP,[THISDPB]
	MOV	AH,ES:[BP.dpb_drive]
SETESRET:
        PUSH    SS
        POP     ES
        PUSH    ENTLAST
        POP     IoState1+16
        JNC     LfnSearchReturn
        MOV     IoState1,0
LfnSearchReturn:
	return
EndProc Search

;----------------------------------------------------------------------------
;
; Procedure Name : MetaCompare
;
; Inputs:
;	DS:SI -> 11 character FCB style name NO '?'
;	    Typically this is a directory entry.  It MUST be in upper case
;	ES:DI -> 11 character FCB style name with possible '?'
;	    Typically this is a FCB or SFT.  It MUST be in upper case
; Function:
;	Compare FCB style names allowing for ? match to any char
; Outputs:
;	Zero if match else NZ
; Destroys CX,SI,DI all others preserved
;----------------------------------------------------------------------------



Break	<NEXTENTRY -- STEP THROUGH DIRECTORY>
;----------------------------------------------------------------------------
;
; Procedure Name : NEXTENTRY
;
; Inputs:
;	Same as outputs of GETENTRY, above
; Function:
;	Update BX, and [LASTENT] for next directory entry.
;	Carry set if no more.
;----------------------------------------------------------------------------

Procedure NextEntry
	.386
	DOSAssume   <DS>,"NextEntry"

	MOV	AX,[LASTENT]
	CMP	AX,[ENTLAST]
	JZ	NONE
	INC	AX
	LEA	BX,[BX+32]
	CMP	BX,DX
	JNZ	HAVIT
	CMP	[DirStart],0
	JNZ	NEXT_CLUSTER_ENTRY
	CMP	[DirStartHigh],0
	JNZ	NEXT_CLUSTER_ENTRY
	CMP	AX,ES:[BP.dpb_root_entries]
	JAE	NONE
	JMP	SHORT GETENT
NEXT_CLUSTER_ENTRY:
	MOV	BL,BYTE PTR [SECCLUSPOS]
	INC	BL
	CMP	BL,BYTE PTR [CLUSFAC]
	JB	SAMECLUS
	MOV	BX,[NxtClusNumHigh]
	MOV	[FatClusterHigh],BX
	MOV	BX,[NXTCLUSNUM]
	Invoke	IsEOF
	JAE	NONE
	CMP	[FatClusterHigh],0
	JNZ	GETENT
	CMP	BX,2
	JB	NONE
	JMP	short GETENT

NONE:
	STC
	return

HAVIT:
	MOV	[LASTENT],AX
	CLC
	return

SAMECLUS:
	MOV	BYTE PTR [SECCLUSPOS],BL
	MOV	[LASTENT],AX
	PUSH	DS
	LDS	DI,[CURBUF]
ASSUME	DS:NOTHING
	MOV	DX,WORD PTR [DI.buf_sector+2]	;AN000; >32mb

;hkn; SS override
	MOV	[HIGH_SECTOR],DX		;AN000; >32mb
	MOV	DX,WORD PTR [DI.buf_sector]	;AN000; >32mb

	ADD	DX,1				;AN000; >32mb
	ADC	[HIGH_SECTOR],0 		;AN000; >32mb
	POP	DS
	DOSAssume   <DS>,"SameClus"
	invoke	FIRSTCLUSTER
	XOR	BX,BX
	JMP	short SETENTRY

EndProc NextEntry

;----------------------------------------------------------------------------
;
; Procedure Name : GETENTRY
;
; Inputs:
;	[LASTENT] has directory entry
;	ES:BP points to drive parameters
;	[DIRSEC],[CLUSNUM],[CLUSFAC],[ENTLAST] set for DIR involved
; Function:
;	Locates directory entry in preparation for search
;	GETENT provides entry for passing desired entry in AX
; Outputs:
;	[CURBUF+2]:BX = Pointer to next directory entry in CURBUF
;	[CURBUF+2]:DX = Pointer to first byte after end of CURBUF
;	[LASTENT] = New directory entry number
;	[NXTCLUSNUM],[SECCLUSPOS] set via DIRREAD
;	Carry set if error (currently user FAILed to I 24)
;----------------------------------------------------------------------------

Procedure GETENTRY,NEAR
	DOSAssume   <DS>,"GetEntry"

	MOV	AX,[LASTENT]

	entry	GETENT

	Assert	ISDPB,<ES,BP>,"GetEntry/GetEnt"
	MOV	[LASTENT],AX
;
; Convert the entry number in AX into a byte offset from the beginning of the
; directory.
;
	rol	ax,5			; keep high order bits
	mov	dx,ax
	db	083h,0E0h,0E0h		; AND AX,NOT (32-1), short immediate
	and	dx, 32-1		; mask off low order bits
;
; DX:AX contain the byte offset of the required directory entry from the
; beginning of the directory.  Convert this to a sector number.  Round the
; sector size down to a multiple of 32.
;
	MOV	BX,ES:[BP.dpb_sector_size]
	AND	BL,255-31		; Must be multiple of 32
	DIV	BX
	PUSH	DX			; Position within sector
	invoke	DIRREAD
	POP	BX
	retc
SETENTRY:
	MOV	DX,WORD PTR [CURBUF]
	ADD	DX,BUFINSIZ
	ADD	BX,DX
	ADD	DX,ES:[BP.dpb_sector_size]
	CLC				; no error
	return
EndProc GetEntry

Break	<SETDIRSRCH SETROOTSRCH -- Set Search environments>
;----------------------------------------------------------------------------
;
; Procedure Name : SETDIRSRCH,SETROOTSRCH
;
; Inputs:
;	BX cluster number of start of directory
;	ES:BP Points to DPB
;	DI next cluster number from fastopen extended info. DOS 3.3 only
; Function:
;	Set up a directory search
; Outputs:
;	[DIRSTART] = BX
;	[CLUSFAC],[CLUSNUM],[SECCLUSPOS],[DIRSEC] set
;	Carry set if error (currently user FAILed to I 24)
; destroys AX,DX,BX
;----------------------------------------------------------------------------

; Associate open SFT entries with their directory position.
; Each position contains a DWORD cluster and a WORD entry number.
        PUBLIC DirSftIds,DirSftPositions,DirSftCluster
DirSftIds       DB      20 DUP (0)
DirSftPositions DW      60 DUP (0)
DirSftCluster   DD      0
	.386
procedure SETDIRSRCH
	DOSAssume   <DS>,"SetDirSrch"

	Assert	ISDPB,<ES,BP>,"SetDirSrch"
	CMP	[ClusterWorkHigh],0
	JNZ	SET_SEARCH_CLUSTER
	OR	BX,BX
	JZ	SETROOTSRCH
SET_SEARCH_CLUSTER:
	MOV	AX,[ClusterWorkHigh]
	MOV	[DirStartHigh],AX
	MOV	[FatClusterHigh],AX
	MOV	[DIRSTART],BX
	MOV	AL,ES:[BP.dpb_cluster_mask]
	INC	AL
	MOV	BYTE PTR [CLUSFAC],AL
	SAVE	<SI>
	invoke	UNPACK
	JNC	UNP_OK
	RESTORE <SI>
	return

UNP_OK:
	MOV	[CLUSNUM],DI
	MOV	DX,[FatNextHigh]
	MOV	[ClusNumHigh],DX
	MOV	WORD PTR CS:DirSftCluster,BX
	MOV	DX,[FatClusterHigh]
	MOV	WORD PTR CS:DirSftCluster+2,DX
	MOV	DX,BX
	XOR	BL,BL
	MOV	BYTE PTR [SECCLUSPOS],BL
	invoke	FIGREC
	MOV	WORD PTR [DIRSEC],DX
	MOV	SI,[HIGH_SECTOR]
	MOV	WORD PTR [DIRSEC+2],SI
	RESTORE <SI>
	CLC
	return

entry	SETROOTSRCH
	DOSAssume   <DS>,"SetRootSrch"
	ASSUME	ES:NOTHING
	MOV	[ClusterWorkHigh],0
	CMP	ES:[BP.dpb_fat_size],0
	JNZ	ROOT_FIXED
	MOV	EBX,ES:[BP.dpb_rootclus]
	CMP	EBX,ES:[BP.dpb_max_cluster32]
	JA	ROOT_BAD
	CMP	EBX,2
	JB	ROOT_BAD
	ROR	EBX,16
	MOV	[ClusterWorkHigh],BX
	ROR	EBX,16
	JMP	SET_SEARCH_CLUSTER
ROOT_BAD:
	STC
	JMP	SHORT ROOT_DONE
ROOT_FIXED:
	XOR	AX,AX
	MOV	[DIRSTART],AX
	MOV	[DirStartHigh],AX
	MOV	CS:DirSftCluster,1
	MOV	BYTE PTR [SECCLUSPOS],AL
	DEC	AX
	MOV	[CLUSNUM],AX
	MOV	[ClusNumHigh],AX
	MOVZX	EAX,ES:[BP.dpb_first_sector]
	MOVZX	EDX,ES:[BP.dpb_dir_sector]
	SUB	EAX,EDX
	MOV	BYTE PTR [CLUSFAC],AL
	MOV	[DIRSEC],EDX
	CLC
ROOT_DONE:
	return
EndProc SETDIRSRCH,NoCheck

procedure SaveDirSft,near
        ASSUME  DS:NOTHING,ES:NOTHING,SS:DOSDATA
        pusha
        call    DirSftNumber
        xor     bx,bx
        mov     cx,20
dir_sft_free:
        cmp     DWORD PTR CS:DirSftPositions[bx],0
        jz      dir_sft_store
        add     bx,6
        loop    dir_sft_free
        jmp     short dir_sft_saved
dir_sft_store:
        push    cx
        mov     cx,WORD PTR CS:DirSftCluster
        mov     WORD PTR CS:DirSftPositions[bx],cx
        mov     cx,WORD PTR CS:DirSftCluster+2
        mov     WORD PTR CS:DirSftPositions[bx+2],cx
        pop     cx
        mov     dx,LastEnt
        mov     WORD PTR CS:DirSftPositions[bx+4],dx
        xchg    ax,bx
        xor     dx,dx
        mov     cx,6
        div     cx
        xchg    ax,bx
        mov     CS:DirSftIds[bx],al
dir_sft_saved:
	popa
	ret
EndProc SaveDirSft

; ES:DI points to an SFT. Return its number in AL, carry on failure.
procedure   DirSftNumber,NEAR
	push	es
	xor	cx,cx
	mov	dx,es
	getdseg	<es>
	les	bx,es:sft_addr
dir_sft_block:
	mov	ax,es
	cmp	ax,dx
	jne	dir_sft_next_block
	mov	ax,di
	sub	ax,bx
	db	083h,0E8h,SFTable ; SUB AX,SFTable - short immediate
	mov	bl,SIZE sf_entry
	div	bl
	add	ax,cx
	jmp	short dir_sft_number_done
dir_sft_next_block:
	add	cx,es:[bx.SFCount]
	les	bx,es:[bx.SFLink]
	cmp	bx,-1
	jne	dir_sft_block
	stc
dir_sft_number_done:
	pop	es
	ret
EndProc DirSftNumber

; ES:DI points to an SFT. Return directory cluster in SI:CX, entry in DX.
procedure FindDirSft,near
        call    DirSftNumber
        jc      dir_sft_find_done
        push    es
        push    di
        push    cs
        pop     es
        ASSUME  ES:DOSCODE
        mov     cx,20
        mov     di,OFFSET DirSftIds
dir_sft_scan:
        repne   scasb
        stc
        jne     dir_sft_find_exit
        lea     bx,[di-1]
        sub     bx,OFFSET DirSftIds
        mov     dx,bx
        shl     bx,1
        add     bx,dx
        shl     bx,1
        cmp     DWORD PTR es:DirSftPositions[bx],0
        jne     dir_sft_found
        test    cx,cx
        jnz     dir_sft_scan
        stc
        jmp     short dir_sft_find_exit
dir_sft_found:
        mov     cx,WORD PTR es:DirSftPositions[bx]
        mov     si,WORD PTR es:DirSftPositions[bx+2]
        mov     dx,WORD PTR es:DirSftPositions[bx+4]
        clc
dir_sft_find_exit:
	pop	di
	pop	es
	ASSUME	ES:NOTHING
dir_sft_find_done:
	mov	ax,0
	ret
EndProc FindDirSft

procedure ClearDirSft,near
        pusha
        mov     WORD PTR es:[di],0
        call    FindDirSft
        jc      dir_sft_clear_done
        mov     DWORD PTR CS:DirSftPositions[bx],0
dir_sft_clear_done:
	popa
	ret
EndProc ClearDirSft
	.8086

DOSCODE	ENDS
	END

