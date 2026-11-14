	page	,164
	TITLE   DISK3 - Disk utility routines
	NAME    Disk3

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**     Low level Read and write routines for local SFT I/O on files and devs
;
;       DISKWRITE
;       WRTERR
;
;       Revision history:
;
;           1.  AN000 version 4.00 Jan. 1988
;           2.  SR; 10/12/89; Fixed bug in DISKWRITE that caused incorrect
;               calculation of filesizes when they cross the 32M boundary
;               if the filesize is not a multiple of 512 bytes
;             AN002 - Sept. 1988, PTM#4977 fix (writing cluster bug)  Bill Lawton
;		M017 MD 8/30/90 - Rewrite SHR32 for better speed
;        	M039 DB 10/17/90 - Disk write optimization

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include dpb.inc
	include sf.inc
        include dosmac.inc              ;M039
	.cref
	.list

Installed = TRUE

	i_need	READOP,BYTE
	i_need	DISK_FULL,BYTE
	i_need  THISSFT,DWORD
	i_need  DMAADD,DWORD
	i_need  SecClusPos,BYTE
	i_need  ClusNum,WORD
	i_need  FatClusterHigh,WORD
	i_need  FatEntryHigh,WORD
	i_need  ClusterCountHigh,WORD
	i_need  ClusNumHigh,WORD
	i_need  LastPosHigh,WORD
	i_need  FatNextHigh,WORD
	i_need  Trans,BYTE
	i_need  BytPos,4
	i_need  SecPos,DWORD              ;F.C. >32mb   ;AN000;
	i_need  BytSecPos,WORD
	i_need  BytCnt1,WORD
	i_need  BytCnt2,WORD
	i_need  SecCnt,WORD
	i_need  ThisDPB,DWORD
	i_need  LastPos,WORD
	i_need  ValSec,WORD               ;F.C. >32mb          ;AN000;
	i_need  GrowCnt,DWORD
	i_need  ALLOWED,BYTE
	I_need  JShare,DWORD


	I_need  HIGH_SECTOR,WORD          ;F.C. >32mb          ;AN000;
;	I_need  HIGH_SECTOR_TEMP,WORD     ;M039: Removed; F.C. >32mb ;AN000;

	I_need  EXTERR,WORD                        ; DOS 4.00   ;AN000;
	I_need  EXTERR_LOCUS,BYTE                  ; DOS 4.00   ;AN000;
	I_need  EXTERR_ACTION,BYTE                 ; DOS 4.00   ;AN000;
	I_need  EXTERR_CLASS,BYTE                  ; DOS 4.00   ;AN000;
	I_need  EXITHOLD,DWORD                     ; DOS 4.00   ;AN000;

;**RMFHFE**     I_need  DISK_FULL,BYTE                     ; DOS 4.00   ;AN000;

	I_need  SC_CACHE_COUNT,WORD                ; DOS 4.00   ;AN000;


	I_need  ThisDRV,BYTE                       ; DOS 4.00   ;AN000;
	I_need  User_In_AX,WORD                    ; DOS 4.00   ;AN000;
	I_need  DOS34_FLAG,WORD                    ; DOS 4.00   ;AN000;

        I_need  TEMP_VAR,WORD                      ;M039
        I_need  TEMP_VAR2,WORD                     ;M039


DOSCODE Segment
        EXTRN SC_DRIVE:BYTE
        EXTRN SC_STATUS:WORD
        EXTRN CURSC_SECTOR:WORD
        EXTRN CURSC_DRIVE:BYTE
        EXTRN FIRST_BUFF_ADDR:WORD
	ASSUME  SS:DOSDATA,CS:DOSCODE

Break   <DISKWRITE -- PERFORM USER DISK WRITE>
;----------------------------------------------------------------------------
;
; Procedure Name : DISKWRITE
;
; Inputs:
;       Outputs of SETUP
; Function:
;       Perform disk write
; Outputs:
;    Carry clear
;       CX = No. of bytes read
;       ES:DI point to SFT
;       SFT offset and cluster pointers updated
;    Carry set
;       CX = 0
;       ES:DI point to SFT
;       AX has error code
;----------------------------------------------------------------------------

;hkn; called by DOS_WRITE. DS already set up at this point.

procedure   DISKWRITE,NEAR
	DOSAssume   <DS>,"DiskWrite"

	Assert  ISSFT,<ES,DI>,"DiskWrite"


	invoke  CHECK_WRITE_LOCK          ;IFS. check write lock                 ;AN000;
	JNC     WRITE_OK                  ;IFS. lock check ok                    ;AN000;
	return

WRTEOFJ:
	STI
	MOV     DX,WORD PTR [BYTPOS+2]
	JMP     WRTEOF

WRITE_OK:
	AND     ES:[DI].SF_FLAGS,NOT (sf_close_nodate OR devid_file_clean)
				; Mark file as dirty, clear no date on close

	MOV	AX,WORD PTR ES:[DI.sf_size]		;M039
        MOV     [TEMP_VAR],AX                           ;M039
	MOV	AX,WORD PTR ES:[DI.sf_size+2]		;M039
        MOV     [TEMP_VAR2],AX                          ;M039

;	TEMP_VAR2:TEMP_VAR = Current file size (sf_size);M039

	PUSH    ES:[DI].sf_mode
	LES     BP,[THISDPB]
	Assert  ISDPB,<ES,BP>,"DiskWrite/WriteOk"

	invoke  BREAKDOWN
	POP     DX
	CLI
	.386
	MOV     EAX,DWORD PTR BYTPOS
	JCXZ    WRTEOFJ                 ;Make the file length = sf_position
	MOVZX   ECX,CX
	ADD     EAX,ECX
	JC      SET_ACC_ERRW
	TEST    DX,1000H
	JNZ     write_size_ok
	CMP     EAX,7FFFFFFFH
	JA      SET_ACC_ERRW
write_size_ok:
	MOVZX   EBX,ES:[BP.dpb_sector_size]
	XOR     EDX,EDX
	DIV     EBX
	MOV     ECX,EAX
	SHR     ECX,16
	MOV     SI,AX
        MOV     [HIGH_SECTOR],CX

;       [HIGH_SECTOR]:SI = Last full sector to write.

	OR	DX,DX
	JNZ     CALCLUS
	DEC     EAX

CALCLUS:
	MOV     CL,ES:[BP.dpb_cluster_shift]
	SHR     EAX,CL

;       AX = Last cluster to write.
;       DX = # of bytes in last sector to write (the "tail").
;       BX = ES:[BP.dpb_sector_size]

	PUSH    EAX
	PUSH	DX

;M039
        MOV     EAX,DWORD PTR TEMP_VAR
        XOR     EDX,EDX
        DIV     EBX
        MOV     DWORD PTR TEMP_VAR,EAX
        MOV     DWORD PTR VALSEC,EAX
        STI
        mov     cx,ax
        mov     bx,si

;       [HIGH_SECTOR]:BX = Last full sector to write.
;          [VALSEC+2]:CX = Last full sector of current file.
;         [TEMP_VAR2]:CX = Last full sector of current file.
;                     DX = # of bytes in last sector of current file.
;M039

	OR      DX,DX
	JZ      NORND
        INC     DWORD PTR VALSEC
NORND:

;       [VALSEC] = Last sector of current file.

	XOR     AX,AX
	MOV     WORD PTR [GROWCNT],AX
	MOV     WORD PTR [GROWCNT+2],AX
	POP     AX

	MOV     DI,[HIGH_SECTOR]        ;F.C. >32mb                             ;AN000;
	CMP     DI,[TEMP_VAR2]		;M039; F.C. >32mb				;AN000;
	JAE     write_growth_check
	JMP     NOGROW
write_growth_check:
	JZ      lowsec                  ;F.C. >32mb                             ;AN000;
	SUB     BX,CX                   ;F.C. >32mb                             ;AN000;
	SBB     DI,[TEMP_VAR2]   	;M039; F.C. >32mb di:bx no. of sectors    ;AN000;
	JMP     short yesgrow           ;F.C. >32mb                             ;AN000;
lowsec:
	XOR     DI,DI
	SUB     BX,CX           ; Number of full sectors
	JB      NOGROW
	JZ      TESTTAIL
yesgrow:
	MOV     CX,DX
	XCHG    AX,BX
	MUL     ES:[BP.dpb_sector_size]  ; Bytes of full sector growth
	MOV     [HIGH_SECTOR],DX         ;F.C. >32mb save dx                    ;AN000;
	MOV     [TEMP_VAR2],AX    	 ;M039; F.C. >32mb save ax                ;AN000;
	MOV     AX,DI                    ;F.C. >32mb                            ;AN000;
	MUL     ES:[BP.dpb_sector_size]  ;F.C. >32mb do higher word multiply    ;AN000;
	ADD     AX,[HIGH_SECTOR]         ;F.C. >32mb add lower value            ;AN000;
	MOV     DX,AX                    ;F.C. >32mb DX:AX is the result of     ;AN000;
	MOV     AX,[TEMP_VAR2]    	 ;M039; F.C. >32mb a 32 bit multiply      ;AN000;

	SUB     AX,CX           ; Take off current "tail"
	SBB     DX,0            ; 32-bit extension
	ADD     AX,BX           ; Add on new "tail"
	ADC     DX,0            ; ripple tim's head off
	JMP     SHORT SETGRW
HAVSTART:
;int 3
	MOV     ECX,EAX
	invoke  SKPCLP
	OR      ECX,ECX
	JZ      DOWRT
	ROR     ECX,16
	MOV     ClusterCountHigh,CX
	ROR     ECX,16
	ROR     EBX,16
	MOV     FatClusterHigh,BX
	ROR     EBX,16
	STI
	invoke  ALLOCATE
	JNC     DOWRT

entry   WRTERR
	DOSAssume   <DS>,"DiskWrite/WrtErr"
	ASSUME  ES:NOTHING

	MOV     AH,0FH                          ;MS. write/data/fail/abort      ;AN000;
entry WRTERR22
	STI
	MOV     AL,[THISDRV]                    ;MS.                            ;AN000;

;**RMFHFE**     CALL    File_Handle_Fail_Error  ;MS. issue disk full I24

;**RMFHFE**     MOV     CX,0                    ;No bytes transferred
	XOR     CX,CX                   ; will be deleted

	LES     DI,[THISSFT]
	Assert  ISSFT,<ES,DI>,"DiskWrite/WrtErr"
	CLC
	return

TESTTAIL:
	SUB     AX,DX
	JBE     NOGROW
	XOR     DX,DX
SETGRW:
	MOV     WORD PTR [GROWCNT],AX
	MOV     WORD PTR [GROWCNT+2],DX
NOGROW:
	CLI
	MOV     CX,ClusNumHigh
	SHL     ECX,16
	MOV     CX,[CLUSNUM]    ; First cluster accessed
	invoke  FNDCLUS
	POP     EAX
	JC      SET_ACC_ERRW
	MOV     [CLUSNUM],BX
	MOV     [LASTPOS],DX
	ROR     EBX,16
	ROR     EDX,16
	MOV     ClusNumHigh,BX
	MOV     LastPosHigh,DX
	ROR     EBX,16
	ROR     EDX,16
	SUB     EAX,EDX         ; Last cluster minus current cluster
	JZ      DOWRT           ; If we have last clus, we must have first
	OR      ECX,ECX
	JZ      HAVSTART
	PUSH    ECX
	MOV     ECX,EAX
	ROR     ECX,16
	MOV     ClusterCountHigh,CX
	ROR     ECX,16
	ROR     EBX,16
	MOV     FatClusterHigh,BX
	ROR     EBX,16
	STI
	invoke  ALLOCATE
	CLI
	POP     ECX
	PUSHF
	ROR     EBX,16
	MOV     BX,FatClusterHigh
	ROR     EBX,16
	POPF
	JC      WRTERR
	MOV     DX,LastPosHigh
	SHL     EDX,16
	MOV     DX,[LASTPOS]
	INC     EDX
	DEC     ECX
	JZ      NOSKIP
	invoke  SKPCLP
	JC      SET_ACC_ERRW
NOSKIP:
	MOV     [CLUSNUM],BX
	MOV     [LASTPOS],DX
	ROR     EBX,16
	ROR     EDX,16
	MOV     ClusNumHigh,BX
	MOV     LastPosHigh,DX
	ROR     EBX,16
	ROR     EDX,16
DOWRT:
	STI
	.8086
	CMP     [BYTCNT1],0
	JZ      WRTMID
	MOV     BX,ClusNumHigh
	MOV     FatClusterHigh,BX
	MOV     BX,[CLUSNUM]
	invoke  BUFWRT
	JNC     WRTMID
	JMP     SET_ACC_ERRW
WRTMID:
	MOV     AX,[SECCNT]
	OR      AX,AX
	JNZ     write_middle
	JMP     WRTLAST
write_middle:
	ADD     WORD PTR [SECPOS],AX
	ADC     WORD PTR [SECPOS+2],0    ;F.C. >32mb                            ;AN000;
	invoke  NEXTSEC
	JC      SET_ACC_ERRW             ;M039
	MOV     BYTE PTR [TRANS],1       ; A transfer is taking place
	MOV     DL,[SECCLUSPOS]
	MOV     BX,ClusNumHigh
	MOV     FatClusterHigh,BX
	MOV     BX,[CLUSNUM]
	MOV     CX,[SECCNT]
WRTLP:
	invoke  OPTIMIZE
	JC     	SET_ACC_ERRW

;M039
;       DI = Next physical cluster.
;       AX = # sectors remaining.
;       [DMAADD+2]:BX = transfer address (source data address).
;       CX = # of contiguous sectors to write. (These constitute a block of
;	     sectors, also termed an "Extent".)
;       [HIGH_SECTOR]:DX = physical sector # of first sector in extent.
;       ES:BP -> Drive Parameter Block (DPB).
;
;       Purge the Buffer Queue and the Secondary Cache of any buffers which
;	are in Extent; they are being over-written.

	PUSH    FatNextHigh
	push    di
	push    ax
        call    DskWrtBufPurge          ;DS trashed.
ASSUME DS:NOTHING
;M039

;hkn; SS override for DMAADD and ALLOWED
	MOV     DS,WORD PTR [DMAADD+2]
	MOV	[ALLOWED],allowed_RETRY + allowed_FAIL + allowed_IGNORE

;	put logic from DWRITE in-line here so we can modify it
;	for DISK FULL conditions.

DWRITE_LUP:
	invoke	DSKWRITE
	jz	DWRITE_OKAY

;	int	3
	cmp	al,error_handle_Disk_Full	; compressed volume full?
	jz	DWRITE_DISK_FULL

;hkn; SS override
	MOV	BYTE PTR [READOP],1
	invoke	HARDERRRW
	CMP	AL,1		; Check for retry
	JZ	DWRITE_LUP
	CMP	AL,3		; Check for FAIL
	CLC
	JNZ	DWRITE_OKAY 	; Ignore
	STC

DWRITE_OKAY:


	POP     CX
	POP     BX
	POP     FatClusterHigh

;       CX = # sectors remaining.
;       BX = Next physical cluster.

;hkn; SS override
	Context DS

	JC      SET_ACC_ERRW
	JCXZ    WRTLAST
	MOV     DL,0
	ADD     [LASTPOS],1
	ADC     LastPosHigh,0
	JMP     WRTLP

DWRITE_DISK_FULL:
        Context DS		;SQ 3-5-93 DS must be setup on return!
	pop	cx		; unjunk stack
	pop	bx
	pop	bx
	mov	[DISK_FULL],1
	stc
	jmp	WRTERR		; go to disk full exit

SET_ACC_ERRW:
	STI
	transfer SET_ACC_ERR_DS

WRTLAST:
	MOV     AX,[BYTCNT2]
	OR      AX,AX
	JZ      FINWRT
	MOV     [BYTCNT1],AX
	invoke  NEXTSEC
	JC      SET_ACC_ERRW
	MOV     [BYTSECPOS],0
	invoke  BUFWRT
	JC      SET_ACC_ERRW
FINWRT:
	LES     DI,[THISSFT]
	Assert  ISSFT,<ES,DI>,"DiskWrite/FinWrt"
	MOV     AX,WORD PTR [GROWCNT]
	MOV     CX,WORD PTR [GROWCNT+2]
	OR      AX,AX
	JNZ     UPDATE_size
	JCXZ    SAMSIZ
Update_size:
	ADD     WORD PTR ES:[DI.sf_size],AX
	ADC     WORD PTR ES:[DI.sf_size+2],CX
;
; Make sure that all other SFT's see this growth also.
;
	MOV     AX,1
SAMSIZ:
	transfer SETCLUS                  ; ES:DI already points to SFT

WRTEOF:
	MOV     CX,AX
	OR      CX,DX
	JNZ     wrteof_nonzero
	JMP     KILLFIL
wrteof_nonzero:
	MOV     CX,DX
	CLI
	.386
	SHL     ECX,16
	MOV     CX,AX
	CMP     ECX,7FFFFFFFH
	JBE     wrteof_size_ok
	PUSH    ES
	LES     DI,THISSFT
	TEST    ES:[DI].sf_mode,1000H
	POP     ES
	JZ      SET_ACC_ERRW
wrteof_size_ok:
	SUB     AX,1
	SBB     DX,0

	PUSH    BX
	MOVZX   EBX,ES:[BP.dpb_sector_size]
	SHL     EDX,16
	MOVZX   EAX,AX
	OR      EAX,EDX
	XOR     EDX,EDX
	DIV     EBX
	MOV     EDX,EAX
	SHR     EDX,16
	MOV     HIGH_SECTOR,DX
	POP     BX
	MOV     CL,ES:[BP.dpb_cluster_shift]
	SHR     EAX,CL
	MOV     ECX,EAX
	invoke  FNDCLUS
SET_ACC_ERRWJ2:
	JC      SET_ACC_ERRW


	JECXZ   RELFILE
	ROR     ECX,16
	MOV     ClusterCountHigh,CX
	ROR     ECX,16
	ROR     EBX,16
	MOV     FatClusterHigh,BX
	ROR     EBX,16
	STI
	invoke  ALLOCATE
	JC      WRTERR
UPDATE:
	LES     DI,[THISSFT]
	Assert  ISSFT,<ES,DI>,"DiskWrite/update"
	MOV     AX,WORD PTR [BYTPOS]
	MOV     WORD PTR ES:[DI.sf_size],AX
	MOV     AX,WORD PTR [BYTPOS+2]
	MOV     WORD PTR ES:[DI.sf_size+2],AX
;
; Make sure that all other SFT's see this growth also.
;
	MOV     AX,2
	XOR     CX,CX
	transfer ADDREC

;;;;;;;;;;;;;;;; 7/18/86
;;;;;;;;;;;;;;;;;
RELFILE:
	PUSH    ES                    ;AN002; BL   Reset Lstclus and cluspos to
	LES     DI,[THISSFT]          ;AN002; BL   beginning of file if current
	MOV     AX,ES:[DI.sf_cluspos_hi]
	SHL     EAX,16
	MOV     AX,ES:[DI.sf_cluspos]
	CMP     EDX,EAX
	JAE     SKIPRESET             ;AN002; BL
	MOV     ES:[DI.sf_cluspos],0  ;AN002; BL
	MOV     ES:[DI.sf_cluspos_hi],0
	MOV     EDX,ES:[DI.sf_firclus32]
	MOV     ES:[DI.sf_lstclus32],EDX
SKIPRESET:                            ;AN002; BL
	POP     ES                    ;AN002; BL
;
	ROR     EBX,16
	MOV     FatClusterHigh,BX
	ROR     EBX,16
	STI
	XOR     DX,DX
	DEC     DX
	MOV     FatEntryHigh,DX
	invoke  RELBLKS
Set_Acc_ERRWJJ:
	JC      SET_ACC_ERRW
	JMP     SHORT UPDATE

KILLFIL:
	XOR     BX,BX
	PUSH    ES
	LES     DI,[THISSFT]
	Assert  ISSFT,<ES,DI>,"DiskWrite/KillFil"
	MOV     ES:[DI.sf_cluspos_hi],BX
	MOV     ES:[DI.sf_cluspos],BX
	MOV     ES:[DI.sf_lstclus],BX
	MOV     ES:[DI.sf_lstclus_hi],BX
	MOV     BX,ES:[DI.sf_firclus_hi]
	MOV     FatClusterHigh,BX
	XOR     BX,BX
	MOV     ES:[DI.sf_firclus_hi],BX
	XCHG    BX,WORD PTR ES:[DI.sf_firclus32]
	POP     ES

	CMP     FatClusterHigh,0
	JNZ     kill_chain
	OR      BX,BX
	JNZ     kill_chain
	JMP     UPDATE
kill_chain:
	invoke  RELEASE
	JMP     SHORT SET_ACC_ERRWJJ
EndProc DISKWRITE
	.8086



Break   <DskWrtBufPurge -- Disk Write Buffer Purge>
;----------------------------------------------------------------------------
;
; Procedure Name : DskWrtBufPurge
;
; Inputs:
;       CX = # of contiguous sectors to write. (These constitute a block of
;	     sectors, also termed an "Extent".)
;       [HIGH_SECTOR]:DX = physical sector # of first sector in extent.
;       ES:BP -> Drive Parameter Block (DPB).
;
; Function:
;       Purge the Buffer Queue and the Secondary Cache of any buffers which
;	are in Extent; they are being over-written.
;
; Outputs:
;       (Same as Input.)
; Uses:
;       All registers except DS,AX,SI,DI preserved.
;       SS override for all global variables.
;----------------------------------------------------------------------------
;M039: Created

procedure   DskWrtBufPurge,NEAR

ASSUME  DS:NOTHING

        SaveReg <bx,cx>
        mov	bx,[HIGH_SECTOR]	;BX:DX = Extent start (sector #).
        mov     si,bx
        add     cx,dx
        adc     si,0                    ;SI:CX = Extent end + 1.

	Assert  ISDPB,<ES,BP>,"DskWrtBufPurge"
	mov     al,es:[bp.dpb_drive]

;       BX:DX = Extent start.
;       SI:CX = Extent end + 1.
;          AL = Drive #

	cmp     [SC_CACHE_COUNT],0      ;Secondary cache in-use?
	je      nosc                    ; -no, jump.

;       If any of the sectors to be written are in the secondary cache (SC),
;       invalidate the entire SC. (This is an optimization; we really only
;	need to invalidate those sectors which intersect, but that's slower.)

        cmp     al,CS:[CURSC_DRIVE]        ;Same drive?
        jne     nosc                    ; -no, jump.

        push    ax
        mov     ax,CS:[CURSC_SECTOR]
        mov     di,CS:[CURSC_SECTOR+2]     ;DI:AX = SC start.
        Cmp32   si,cx,di,ax             ;Extent end < SC start?
        jbe     sc5                     ; -yes, jump.
        add     ax,[SC_CACHE_COUNT]
        adc     di,0                    ;DI:AX = SC end + 1.
        Cmp32   bx,dx,di,ax             ;Extent start > SC end?
        jae     sc5                     ; -yes, jump.
        mov     CS:[SC_STATUS],0           ;Extent intersects SC: invalidate SC.
sc5:	pop     ax

;       Free any buffered sectors which are in Extent; they are being over-
;       written.

nosc:	invoke  GETCURHEAD              ;DS:DI -> first buffer in queue.

bufq:   cmp     al,BYTE PTR [di.buf_ID] ;Same drive?
        jne     bufq5                   ; -no, jump.

        Cmp32   bx,dx,<WORD PTR [di.buf_sector+2]>,<WORD PTR [di.buf_sector]>
        ja	bufq5			;Jump if Extent start > buffer sector.
        Cmp32   si,cx,<WORD PTR [di.buf_sector+2]>,<WORD PTR [di.buf_sector]>
        jbe	bufq5                   ;Jump if Extent end < buffer sector.

;       Buffer's sector is in Extent, so free it; it is being over-written.

        testb   [di.buf_flags],buf_dirty ;Buffer dirty?
        jz      bufq2                    ; -no, jump.
        invoke  DEC_DIRTY_COUNT          ; -yes, decrement dirty count.
bufq2:  mov     WORD PTR [di.buf_ID],((buf_visit SHL 8) OR 0FFh)

        invoke  SCANPLACE
        jmp     short bufq6

bufq5:  mov     di,[di.buf_next]
bufq6:  cmp     di,CS:[FIRST_BUFF_ADDR]    ;Scanned entire buffer queue?
        jne     bufq	                ; --no, go do next buffer.

        RestoreReg <cx,bx>
        return

EndProc DskWrtBufPurge


COMMENT @

;**RMFHFE** Remove File_Handle_Fail_Error support

;---------------------------------------------------------------------------
;
; Procedure Name : File_Handle_Fail_Error
;
; Issue File Handle Fail INT 24 Critical Error
; Input: Disk_Full=0  ok
;                  1  disk full or EOF
; Function: issue critical error for disk full or EOF error
;
; OutPut: carry clear , no I24
;         carry set, fail from I24
;---------------------------------------------------------------------------

procedure File_Handle_Fail_Error,NEAR                                           ;AN000;

;hkn; SS override for all variables in this procedure
										;AN000;
	CMP     [DISK_FULL],0    ;MS. disk full or EOF                          ;AN000;
	JZ      Fexit            ;MS. no                                        ;AN000;
	TESTB   [DOS34_FLAG],Disable_EOF_I24   ;MS. check input status ?        ;AN000;
	JNZ     Fexit            ;MS. yes                                       ;AN000;
										;AN000;
	LES     DI,[THISSFT]     ;MS. get current SFT                           ;AN000;
;       LES     DI,ES:[DI.sf_DEVPTR];MS. get device header                      ;AN000;
	TESTB   ES:[DI].SF_FLAGS,Handle_Fail_I24  ;MS. gen I24 ?                ;AN000;
	JZ      Fexit            ;MS. no                                        ;AN000;
	PUSH    DS               ;MS. save DS                                   ;AN000;
	test    AH,1                            ;MS. READ ?                     ;AN000;
	JZ      readeof                         ;MS. yes                        ;AN000;
	MOV     [EXTERR],error_Handle_Disk_Full ;MS. set extended error         ;AN000;
	JMP     SHORT errset                    ;MS. set extended error         ;AN000;
readeof:
	MOV     [EXTERR],error_Handle_EOF       ;MS. set extended error         ;AN000;
errset:
	MOV     [EXTERR_CLASS],errCLASS_OutRes  ;MS. set class                  ;AN000;
	MOV     [EXTERR_ACTION],errACT_Abort    ;MS. set action                 ;AN000;
	MOV     [EXTERR_LOCUS],errLOC_Unk       ;MS. set locus                  ;AN000;
	MOV     word ptr [EXITHOLD + 2],ES      ;MS. save es:bp in exithold     ;AN000;
	MOV     word ptr [EXITHOLD],BP          ;MS.                            ;AN000;
	TESTB   ES:[DI].SF_FLAGS,devid_device     ;MS. device  ?                ;AN000;
	JNZ     chardev2                          ;MS. yes                      ;AN000;
	LDS     SI,ES:[DI.sf_DEVPTR]              ;MS. get dpb                  ;AN000;
	LDS     SI,[SI.dpb_driver_addr]           ;MS. get drive device haeder  ;AN000;
	JMP     SHORT doi24                       ;MS. gen I24 ?                ;AN000;
chardev2:
	LDS     SI,ES:[DI.sf_DEVPTR]              ;MS. get chr dev header       ;AN000;
doi24:
	MOV     BP,DS                             ;MS. bp:si -> device header   ;AN000;
	MOV     DI,error_I24_gen_failure        ;MS. general error              ;AN000;
	invoke  NET_I24_ENTRY                   ;MS. issue I24                  ;AN000;
	STC                                     ;MS. must be fail               ;AN000;
	POP     DS                              ;MS. restore DS                 ;AN000;
	MOV     AX,[EXTERR]                     ;MS. set error                  ;AN000;
	JMP     SHORT Fend                      ;MS. exit                       ;AN000;
Fexit:                                                                          ;AN000;
	CLC                                     ;MS. clear carry                ;AN000;
Fend:                                                                           ;AN000;
	return                                  ;MS.                            ;AN000;
										;AN000;
EndProc File_Handle_Fail_Error                                                  ;AN000;

@       ;End COMMENT.

DOSCODE ENDS
	END
