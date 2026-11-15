	TITLE MISC - Miscellanious routines for MS-DOS
	NAME  MISC

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	Miscellaneous system calls most of which are CAVEAT
;
;	$SLEAZEFUNC
;	$SLEAZEFUNCDL
;	$GET_INDOS_FLAG
;	$GET_IN_VARS
;	$GET_DEFAULT_DPB
;	$GET_DPB
;	$DISK_RESET
;	$SETDPB
;	$Dup_PDB
;	$CREATE_PROCESS_DATA_BLOCK
;	SETMEM
;	FETCHI_CHECK
;	$GSetMediaID
;
;	Revision  history:
;
;	    Created: ARR 30 March 1983
;
;	    A000   version 4.00   Jan. 1988
;	    A001   D490 -- Change IOCTL subfunctions from 63h, 43h to 66h , 46h

;
;------------------------------------------------------------------------------
;
; M041 : Fixing Secondary cache problem with DISK_RESET
;
;------------------------------------------------------------------------------
;
	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include mult.inc
	include pdb.inc
	include dpb.inc
	include bpb.inc
	include vector.inc
	include sf.inc
	include filemode.inc
	include mi.inc
	include curdir.inc
	include bugtyp.inc
	.cref
	.list

	i_need	NlsBuffer,BYTE
	i_need	CURDRV,BYTE
	i_need	LASTBUFFER,DWORD
	i_need	INDOS,BYTE
	i_need	SYSINITVAR,BYTE
	i_need	CurrentPDB,WORD
	i_need	CreatePDB,BYTE
	i_need	FATBYTE,BYTE
	i_need	THISCDS,DWORD
	i_need	THISSFT,DWORD
	i_need	HIGH_SECTOR,WORD		 ;AN000; high word of sector #
	i_need	DOS34_FLAG,WORD 		 ;AN000;
	i_need	DPBHead,DWORD
	i_need	LoMemBuff,DWORD
	i_need	BuffInHMA,BYTE
	i_need	ALLOWED,BYTE


DOSCODE	SEGMENT
	EXTRN	SC_STATUS:WORD

	allow_getdseg


	ASSUME	SS:DOSDATA,CS:DOSCODE

ENTRYPOINTSEG	EQU	0CH
MAXDIF		EQU	0FFFH
SAVEXIT 	EQU	10
WRAPOFFSET	EQU	0FEF0h


	BREAK	<SleazeFunc -- get a pointer to media byte>
;
;----------------------------------------------------------------------------
;
;**	$SLEAZEFUNC - Get a Pointer to the Media Byte
;
;	Return Stuff sort of like old get fat call
;
;	ENTRY	none
;	EXIT	DS:BX = Points to FAT ID byte (IBM only)
;			GOD help anyone who tries to do ANYTHING except
;			READ this ONE byte.
;		DX = Total Number of allocation units on disk
;		CX = Sector size
;		AL = Sectors per allocation unit
;		   = -1 if bad drive specified
;	USES	all
;
;**	$SLEAZEFUNCDL - Get a Pointer to the Media Byte
;
;	Identical to $SLEAZEFUNC except (dl) = drive
;
;	ENTRY	(dl) = drive (0=default, 1=A, 2=B, etc.)
;	EXIT	DS:BX = Points to FAT ID byte (IBM only)
;			GOD help anyone who tries to do ANYTHING except
;			READ this ONE byte.
;		DX = Total Number of allocation units on disk
;		CX = Sector size
;		AL = Sectors per allocation unit
;		   = -1 if bad drive specified
;	USES	all
;
;----------------------------------------------------------------------------
;


procedure   $SLEAZEFUNC,NEAR

	MOV	DL,0

entry	$SLEAZEFUNCDL

;hkn; 	SS is DOSDATA
	context DS

	MOV	AL,DL
	invoke	GETTHISDRV		; Get CDS structure
SET_AL_RET:
;	MOV	AL,error_invalid_drive	; Assume error				;AC000;
	JC	BADSLDRIVE
	invoke	DISK_INFO
	JC	BADSLDRIVE		; User FAILed to I 24
	MOV	[FATBYTE],AH
; NOTE THAT A FIXED MEMORY CELL IS USED --> THIS CALL IS NOT
; RE-ENTRANT. USERS BETTER GET THE ID BYTE BEFORE THEY MAKE THE
; CALL AGAIN

;hkn;	FATBYTE is in DATA seg (DOADATA)
	invoke	get_user_stack
ASSUME	DS:NOTHING
	XCHG	DX,BX
	invoke	FreeSpaceScale
	MOV	AH,SS:[FATBYTE]
	MOV	[SI.user_AX],AX
	MOV	DI,OFFSET DOSDATA:FATBYTE
	MOV	[SI.user_BX],DI

;hkn; Use SS as pointer to DOSDATA
	mov	[si.user_DS],SS
;	MOV     [SI.user_DS],CS         ; stash correct pointer

	return
BADSLDRIVE:
	transfer    FCB_Ret_ERR

EndProc $SleazeFunc

	BREAK <$Get_INDOS_Flag -- Return location of DOS critical-section flag>

;
;----------------------------------------------------------------------------
;
;**	$Get_INDOS_Flag - Return location of DOS Crit Section Flag
;
;	Returns location of DOS status for interrupt routines
;									   ;
;	ENTRY	none
;	EXIT	(es:bx) = flag location
;	USES	all
;
;----------------------------------------------------------------------------
;

procedure   $GET_INDOS_FLAG,NEAR

	invoke	get_user_stack

;hkn;	INDOS is in DATA seg (DOSDATA)
	MOV     [SI.user_BX],OFFSET DOSDATA:INDOS

	MOV	[SI.user_ES],SS
	return

EndProc $GET_INDOS_FLAG


	BREAK <$Get_IN_VARS -- Return a pointer to DOS variables>

;
;----------------------------------------------------------------------------
;
;**	$Get_IN_Vars - Return Pointer to DOS Variables
;
;	Return a pointer to interesting DOS variables This call is version
;	dependent and is subject to change without notice in future versions.
;	Use at risk.
;
;	ENTRY	none
;	EXIT	(es:bx) = address of SYSINITVAR
;	uses	ALL
;
;----------------------------------------------------------------------------
;

procedure   $GET_IN_VARS,NEAR

	invoke	get_user_stack
    ASSUME DS:nothing
;hkn;	SYSINITVAR is in CONST seg (DOSDATA)
	MOV     [SI.user_BX],OFFSET DOSDATA:SYSINITVAR

	MOV	[SI.user_ES],SS
	return
EndProc $GET_IN_VARS


BREAK <$Get_Default_DPB,$Get_DPB -- Return pointer to DPB>

;
;----------------------------------------------------------------------------
;
;**	$Get_Default_DPB - Return a pointer to the Default DPB
;
;	Return pointer to drive parameter table for default drive
;
;	ENTRY	none
;	EXIT	(ds:bx) = DPB address
;	USES	all
;
;**	$Get_DPB - Return a pointer to a specified DPB
;
;	Return pointer to a specified drive parameter table
;
;	ENTRY	(dl) = drive # (0 = default, 1=A, 2=B, etc.)
;	EXIT	(al) = 0 iff ok
;		  (ds:bx) = DPB address
;		(al) = -1 if bad drive
;	USES	all
;
;----------------------------------------------------------------------------
;

procedure   $GET_DEFAULT_DPB,NEAR

	MOV	DL,0

	entry	$GET_DPB

	context DS

	MOV	AL,DL
	invoke	GETTHISDRV		; Get CDS structure
	MOV	AL,error_invalid_drive
	.386
	JC	NEAR PTR ISNODRV
	.8086
	LES	DI,[THISCDS]		; check for net CDS
	TESTB	ES:[DI.curdir_flags],curdir_isnet
	.386
	JNZ	NEAR PTR ISNODRV
	.8086
	invoke	CheckCDSDrive
	.386
	JNZ	NEAR PTR ISNODRV
	.8086
	EnterCrit CritDisk
	invoke	FATRead_CDS		; Force Media Check and return DPB
	LeaveCrit CritDisk
	MOV	AL,error_fail_I24
	.386
	JC	NEAR PTR ISNODRV
	.8086
	invoke	get_user_stack
ASSUME	DS:NOTHING
	CMP	[SI.user_AX],7302h
	JZ	DPBCopyExtended
	CMP	ES:[BP.dpb_fat_size],0
	.386
	JZ	NEAR PTR ISNODRV
	.8086
	MOV	[SI.user_BX],BP
	MOV	[SI.user_DS],ES
	XOR	AL,AL
	return

; Extended callers receive a copy, with legacy fields expanded for FAT16.

DPBCopyExtended:
	MOV	AL,error_bad_length
	CMP	[SI.user_CX],DPBSIZ+2
	JAE	DPBCopyBuffer
DPBReturnError:
	JMP	SYS_RET_ERR
DPBCopyBuffer:
	PUSH	ES
	PUSH	BP
	MOV	ES,[SI.user_ES]
	MOV	DI,[SI.user_DI]
	POP	SI
	POP	DS
	MOV	AX,DPBSIZ
	STOSW
	MOV	CX,AX
	PUSH	DI
	REP	MOVSB
	POP	DI
	invoke	get_user_stack
	CMP	[SI.user_SI],0F1A6h
	JZ	DPBExpandFields
	XOR	AX,AX
	DEC	AX
	MOV	WORD PTR ES:[DI.dpb_next_dpb],AX
	MOV	WORD PTR ES:[DI.dpb_next_dpb+2],AX
	MOV	WORD PTR ES:[DI.dpb_driver_addr],AX
	MOV	WORD PTR ES:[DI.dpb_driver_addr+2],AX
DPBExpandFields:
	CMP	ES:[DI.dpb_fat_size],0
	JZ	DPBCopyDone
	MOV	AX,ES:[DI.dpb_max_cluster]
	MOV	WORD PTR ES:[DI.dpb_max_cluster32],AX
	MOV	AX,ES:[DI.dpb_fat_size]
	MOV	WORD PTR ES:[DI.dpb_fat_size32],AX
	MOV	AX,ES:[DI.dpb_next_free]
	MOV	WORD PTR ES:[DI.dpb_next_free32],AX
	MOV	AX,ES:[DI.dpb_first_sector]
	MOV	WORD PTR ES:[DI.dpb_first_sector32],AX
	XOR	AX,AX
	MOV	WORD PTR ES:[DI.dpb_rootclus],AX
	MOV	WORD PTR ES:[DI.dpb_rootclus+2],AX
	MOV	WORD PTR ES:[DI.dpb_max_cluster32+2],AX
	MOV	WORD PTR ES:[DI.dpb_fat_size32+2],AX
	MOV	WORD PTR ES:[DI.dpb_next_free32+2],AX
	MOV	WORD PTR ES:[DI.dpb_first_sector32+2],AX
	MOV	ES:[DI.dpb_extflags],AX
	DEC	AX
	MOV	ES:[DI.dpb_fsinfo],AX
	MOV	ES:[DI.dpb_bkbootsec],AX
	CMP	WORD PTR ES:[DI.dpb_free_cnt],AX
	JZ	DPBFreeCountHigh
	XOR	AX,AX
DPBFreeCountHigh:
	MOV	WORD PTR ES:[DI.dpb_free_cnt+2],AX
DPBCopyDone:
	XOR	AX,AX
	JMP	SYS_RET_OK
ISNODRV:
	invoke	get_user_stack
	CMP	[SI.user_AX],7302h
	.386
	JZ	NEAR PTR DPBReturnError
	.8086
	MOV	AL,-1
	return

EndProc $GET_Default_dpb


	BREAK <$Disk_Reset -- Flush out all dirty buffers>

;
;----------------------------------------------------------------------------
;
;**	$Disk_Reset - Flush out Dirty Buffers
;
;	$DiskReset flushes and invalidates all buffers.  BUGBUG - do
;		we really invalidate?  SHould we?  THis screws non-removable
;		caching.  Maybe CHKDSK relies upon it, though....
;
;	ENTRY	none
;	EXIT	none
;	USES	all
;
;----------------------------------------------------------------------------
;

procedure   $DISK_RESET,NEAR

	MOV	AL,-1
;hkn; SS is DOSDATA
	context DS

	EnterCrit   critDisk
	OR	[DOS34_FLAG],FROM_DISK_RESET					;AN000;
	invoke	DeferredFlush
	AND	[DOS34_FLAG],NO_FROM_DISK_RESET 				;AN000;
	LES	BP,[DPBHead]
ResetFSInfo:
	CMP	BP,-1
	JZ	ResetBuffers
	invoke	UpdateFSInfo
	LES	BP,ES:[BP.dpb_next_dpb]
	JMP	SHORT ResetFSInfo
ResetBuffers:

	mov	CS:SC_STATUS, 0		; Throw out secondary cache M041

;
; We will "ignore" any errors on the flush, and go ahead and invalidate.  This
; call doesn't return any errors and it is supposed to FORCE a known state, so
; let's do it.
;
; Invalidate 'last-buffer' used
;
	MOV	BX,-1
	MOV	WORD PTR [LASTBUFFER],BX
	MOV	WORD PTR [LASTBUFFER+2],BX
	LeaveCrit   critDisk
	MOV	AX,-1
	CallInstall NetFlushBuf,multNET,32,AX,AX
	return

EndProc $DISK_RESET

	BREAK <$SetDPB - Create a valid DPB from a user-specified BPB>

;
;----------------------------------------------------------------------------
;
;**	$SetDPB - Create a DPB
;
;	SetDPB Creates a valid DPB from a user-specified BPB
;
;	ENTRY	eS:BP Points to DPB
;		DS:SI Points to BPB
;	EXIT	DPB setup
;	USES	ALL but BP, DS, ES
;
;----------------------------------------------------------------------------
;
procedure   $SETDPB,NEAR
	CLC
	PUSHF
	MOV	DI,BP
	XOR	AX,AX
	CMP	CX,4558h
	JNZ	SetDPBMode
	CMP	DX,4152h
	JNZ	SetDPBMode
	INC	AX
SetDPBMode:
	PUSH	AX			; Extended DPB requested
	MOV	BL,ES:[DI.dpb_drive]
	MOV	BH,0
	TEST	BYTE PTR SS:[BX+NlsBuffer+20],2
	JZ	SetDPBFields
	OR	BYTE PTR SS:[BX+NlsBuffer+20],4
SetDPBFields:
	MOV	BX,SP
	LEA	DI,[DI+2]
	LODSW
	STOSW				; Sector size
	CMP	BYTE PTR [SI.BPB_NUMBEROFFATS-2],0
	JNZ	SetDPBVersion
SetDPBNoFat:
	MOV	BYTE PTR ES:[DI.dpb_FAT_count-4],0
	.386
	XOR	EAX,EAX
	JMP	setend
SetDPBVersion:
	CMP	WORD PTR [SI.BPB_SECTORSPERFAT-2],0
	JNZ	yesfat
	CMP	WORD PTR [SI.BPB_FSVER-2],0
	JA	SetDPBNoFat
yesfat:
	MOV	DX,AX
	LODSB
	DEC	AL
	STOSB				; dpb_cluster_mask
	INC	AL
	XOR	AH,AH
LOG2LOOP:
	test	AL,1
	JNZ	SAVLOG
	INC	AH
	SHR	AL,1
	JMP	SHORT LOG2LOOP
SAVLOG:
	MOV	AL,AH
	STOSB				; Cluster shift
	MOVSW				; First FAT
	LODSB
	STOSB				; FAT count
	LODSW
	STOSW				; Root entries
	SHR	DX,5
	DEC	AX
	ADD	AX,DX			; Cause Round Up
	MOV	CX,DX
	XOR	DX,DX
	DIV	CX
	MOV	CX,AX			; Directory sectors
	INC	DI
	INC	DI
	MOVSW				; Temporary total sectors
	LODSB
	MOV	ES:[BP.dpb_media],AL
	LODSW
	STOSW				; FAT size
	MOVZX	EAX,AX
	CMP	WORD PTR SS:[BX],0
	JZ	SetDPBFatSize
	OR	AX,AX
	JNZ	SetDPBSaveFatSize
	MOV	EAX,DWORD PTR [SI+BPB_BIGSECTORSPERFAT-BPB_SECTORSPERTRACK]
SetDPBSaveFatSize:
	MOV	ES:[BP.dpb_fat_size32],EAX
SetDPBFatSize:
	OR	EAX,EAX
	JZ	setend
	MOVZX	EDX,ES:[BP.dpb_fat_count]
	MUL	EDX
	MOVZX	EDX,ES:[BP.dpb_first_FAT]
	ADD	EAX,EDX
	STOSW				; Legacy directory sector
	CMP	WORD PTR SS:[BX],0
	JZ	SetDPBDataStart
	CMP	ES:[BP.dpb_fat_size],0
	JNZ	SetDPBDataStart
	MOV	DX,[SI+BPB_FSINFO-BPB_SECTORSPERTRACK]
	OR	DX,DX
	JZ	SetDPBNoInfo
	CMP	DX,ES:[BP.dpb_first_FAT]
	JB	SetDPBInfo
	XOR	DX,DX
SetDPBNoInfo:
	DEC	DX
SetDPBInfo:
	MOV	ES:[BP.dpb_fsinfo],DX
	MOV	DX,[SI+BPB_BKBOOTSEC-BPB_SECTORSPERTRACK]
	OR	DX,DX
	JZ	SetDPBNoBackup
	CMP	DX,ES:[BP.dpb_first_FAT]
	JB	SetDPBBackup
	XOR	DX,DX
SetDPBNoBackup:
	DEC	DX
SetDPBBackup:
	MOV	ES:[BP.dpb_bkbootsec],DX
	MOV	EDX,DWORD PTR [SI+BPB_ROOTCLUS-BPB_SECTORSPERTRACK]
	MOV	CX,[SI+BPB_EXTFLAGS-BPB_SECTORSPERTRACK]
	MOV	ES:[BP.dpb_rootclus],EDX
	XOR	DX,DX
	MOV	ES:[BP.dpb_root_entries],DX
	DEC	DX
	MOV	ES:[BP.dpb_dir_sector],DX
	MOV	DX,CX
	AND	DX,0Fh
	TEST	CX,80h
	JNZ	SetDPBActiveFat
SetDPBMirror:
	AND	CX,0FFF0h
	XOR	DL,DL
SetDPBActiveFat:
	CMP	DL,ES:[BP.dpb_fat_count]
	JAE	SetDPBMirror
	MOV	ES:[BP.dpb_extflags],CX
	XOR	CX,CX
SetDPBDataStart:
	MOVZX	ECX,CX
	ADD	EAX,ECX
	MOV	ES:[BP.dpb_first_sector],AX
	CMP	WORD PTR SS:[BX],0
	JZ	SetDPBClusterCount
	MOV	ES:[BP.dpb_first_sector32],EAX
SetDPBClusterCount:
	MOV	CL,ES:[BP.dpb_cluster_shift]
	MOVZX	EDX,WORD PTR ES:[BP.DSKSIZ]
	OR	DX,DX
	JNZ	SetDPBTotal
	MOV	EDX,DWORD PTR [SI+BPB_BIGTOTALSECTORS-BPB_SECTORSPERTRACK]
SetDPBTotal:
	SUB	EDX,EAX
	SHR	EDX,CL
	MOV	EAX,EDX
setend:
	INC	EAX
	MOV	ECX,EAX			; Calculated maximum cluster
	MOVZX	EAX,ES:[BP.dpb_fat_size]
	OR	AX,AX
	JNZ	SetDPBFatBytes
	CMP	WORD PTR SS:[BX],0
	JZ	SetDPBFatBytes
	MOV	EAX,ES:[BP.dpb_fat_size32]
SetDPBFatBytes:
	MOVZX	EDX,ES:[BP.dpb_sector_size]
	MUL	EDX
	CMP	ECX,4096-10
	JB	setend_fat12
	SHR	EAX,1
	CMP	ECX,65536-10
	JB	SetDPBFatMinimum
	SHR	EAX,1
SetDPBFatMinimum:
	CMP	EAX,4096-10+1
	JB	setend_faterr
	JMP	SHORT setend_fat16
setend_fat12:
	XOR	EDX,EDX
	SHL	EAX,1
	RCL	EDX,1
	PUSH	ECX
	MOV	ECX,3
	DIV	ECX
	POP	ECX
setend_fat16:
	DEC	EAX
	CMP	EAX,ECX
	JBE	setend_fat
setend_faterr:
	MOV	EAX,ECX
setend_fat:
	CMP	WORD PTR SS:[BX],0
	JZ	SetDPBLegacyCount
	MOV	ES:[BP.dpb_next_free32],0
	MOV	WORD PTR ES:[BP.dpb_free_cnt+2],-1
	MOV	ES:[BP.dpb_max_cluster32],EAX
	CMP	EAX,65536-10
	JAE	SetDPBClearCount
	CMP	ES:[BP.dpb_fat_size],0
	JNZ	SetDPBLegacyCount
	XOR	EAX,EAX
	MOV	ES:[BP.dpb_max_cluster32],EAX
	MOV	ES:[BP.dpb_fat_count],AL
SetDPBClearCount:
	XOR	AX,AX
SetDPBLegacyCount:
	MOV	ES:[BP.dpb_max_cluster],AX
	MOV	ES:[BP.dpb_next_free],0
	MOV	WORD PTR ES:[BP.dpb_free_cnt],-1
	ADD	SP,2
	POPF
SetDPBReturn:
	RET
	.8086
EndProc $SETDPB

;	now ax = maximum legal cluster

;	end M008

procedure DriveRoot,NEAR
	XOR	AL,AL
	DEC	AL
	CMP	BYTE PTR [SI+3],0
	JNZ	SetDPBReturn
	CMP	BYTE PTR [SI+1],':'
	JNZ	SetDPBReturn
	PUSH	AX
	MOV	AL,[SI+2]
	invoke	PathChrCmp
	POP	AX
	JNZ	SetDPBReturn
	invoke	DriveFromText
	return
EndProc DriveRoot

ExtendedDPB:
	JMP	$GET_DPB
ExtendedFreeSpace:
	PUSH	SI
	PUSH	AX
	MOV	SI,DX
	CALL	DriveRoot
	MOV	DX,AX
	POP	AX
	POP	SI
	CMP	DL,-1
	.386
	JZ	NEAR PTR drive_flags_bad_drive
	.8086
	transfer $GET_DRIVE_FREESPACE

; AL = 0 query, 1 set; DL = drive (0 default); CL = flag group.
; CH supplies new flags. Query returns the group and flags in CX.
; AL = 2 returns the extended DPB; AL = 3 queries extended free space.
; AL = 4 controls DPB parameters, FAT mirroring and cached free space.
; AL = 5 performs extended absolute disk I/O using DS:BX parameters.
; Procedure name assigned from target behavior.
        EXTRN   SYS_RET_OK:NEAR,SYS_RET_ERR:NEAR
procedure $DriveFlags,near
        ASSUME  DS:NOTHING,SS:DOSDATA
        cmp     al,5
        .386
        ja      SHORT drive_flags_bad_function
        je      NEAR PTR drive_absolute_io
        cmp     al,4
        je      NEAR PTR drive_control
        .8086
        cmp     al,3
        je      ExtendedFreeSpace
        cmp     al,2
        je      ExtendedDPB
        cmp     dl,26
        ja      drive_flags_bad_drive
        dec     dl
        jns     drive_flags_number
        mov     dl,CURDRV
drive_flags_number:
	mov     dh,0
	mov     bx,dx
	cmp     cl,1
	ja      drive_flags_bad_function
	mov     ah,BYTE PTR [bx+NlsBuffer+20]
	cmp     cl,0
	je      drive_flags_access
	test    al,al
	jz      drive_flags_get_flush
	and     ah,0F7h
	and     ch,8
	or      ah,ch
	mov     BYTE PTR [bx+NlsBuffer+20],ah
	test    ah,8
	jnz     drive_flags_done
	mov     al,0FFh
	invoke  DeferredFlush
	jmp     short drive_flags_done
drive_flags_get_flush:
	and     ah,8
	jmp     short drive_flags_result
drive_flags_access:
	test    al,al
	jz      drive_flags_get_access
	and     ah,0F9h
	test    ch,2
	jz      drive_flags_store
	or      ah,6
drive_flags_store:
	mov     BYTE PTR [bx+NlsBuffer+20],ah
	jmp     short drive_flags_done
drive_flags_get_access:
	and     ah,6
drive_flags_result:
	mov     al,cl
	invoke  Get_User_Stack
	mov     [si.user_CX],ax
drive_flags_done:
        jmp     SYS_RET_OK
drive_flags_bad_drive:
	mov     al,error_invalid_drive
drive_flags_error:
	jmp     SYS_RET_ERR
drive_flags_bad_function:
        mov     al,error_invalid_function
drive_flags_function_error:
        jmp     short drive_flags_error
drive_flags_bad_parameter:
	MOV	AL,error_invalid_parameter
drive_flags_parameter_error:
	JMP	SHORT drive_flags_function_error

; AH selects the near-return path in the existing absolute-I/O handler.

drive_absolute_io:
	CMP	CX,-1
	JNZ	drive_flags_bad_parameter
	TEST	SI,1FFEh
	JNZ	drive_flags_bad_parameter
	MOV	AL,DL
	DEC	AL
	MOV	AH,1
	TEST	SI,1
	JZ	drive_absolute_read
	invoke	AbsWriteExtended
	JMP	SHORT drive_absolute_return
drive_absolute_read:
	invoke	AbsReadExtended
drive_absolute_return:
	JNC	drive_flags_done
	invoke	Get_User_Stack
	OR	[SI.user_F],f_Carry
	STC
	MOV	[SI.user_AX],AX
	RET

; Extended drive control.  ES:DI receives a 24-byte control record.

drive_control:
	CMP	CX,24
	JAE	drive_control_drive
	MOV	AL,error_bad_length
drive_control_error:
	JMP	SHORT drive_flags_parameter_error
drive_control_drive:
	Context DS
	MOV	AL,DL
	invoke	GetThisDrv
	MOV	AL,error_invalid_drive
	JC	drive_control_error
	LES	DI,[THISCDS]
	TESTB	ES:[DI.curdir_flags],curdir_isnet
	JNZ	drive_control_error
	invoke	CheckCDSDrive
	JNZ	drive_control_error
	EnterCrit CritDisk
	invoke	FATRead_CDS
	LeaveCrit CritDisk
	MOV	AL,error_FAIL_I24
	JC	drive_control_error
	invoke	Get_User_Stack
	PUSH	ES
	PUSH	BP
	MOV	ES,[SI.user_ES]
	MOV	DI,[SI.user_DI]
	POP	SI
	POP	DS
	ASSUME	DS:NOTHING
	CMP	WORD PTR ES:[DI+2],0
	JA	drive_flags_bad_parameter
	.386
	CMP	DWORD PTR ES:[DI+4],4
	JA	drive_flags_bad_parameter
	MOV	WORD PTR ES:[DI],24
	MOV	WORD PTR ES:[DI+2],0
	MOV	AL,ES:[DI+4]
	OR	AL,AL
	JZ	drive_control_free
	DEC	AL
	JZ	drive_control_bpb
	DEC	AL
	JZ	drive_control_invalidate
	DEC	AL
	JZ	drive_control_mirror

; Query or change the FAT32 root-directory cluster.

	MOV	AL,error_invalid_drive
	CMP	[SI.dpb_fat_size],0
	JNZ	drive_control_error
	MOV	AL,error_invalid_parameter
	MOV	ECX,[SI.dpb_rootclus]
	MOV	ES:[DI+12],ECX
	MOV	EDX,ES:[DI+8]
	INC	EDX
	JZ	drive_flags_done
	DEC	EDX
	CMP	EDX,2
	JB	drive_control_error
	CMP	EDX,[SI.dpb_max_cluster32]
	JA	drive_control_error
	MOV	[SI.dpb_rootclus],EDX
	OR	[SI.dpb_first_access],2
drive_control_update:
	PUSH	DS
	PUSH	SI
	POP	BP
	POP	ES
	EnterCrit CritDisk
	invoke	UpdateFSInfo
	LeaveCrit CritDisk
	JNC	drive_flags_done
	MOV	AL,error_gen_failure
	JMP	drive_control_error
drive_control_invalidate:
	OR	[SI.dpb_first_access],80h
	JMP	drive_flags_done
drive_control_bpb:
	PUSH	DS
	PUSH	SI
	LDS	SI,DWORD PTR ES:[DI+8]
	POP	BP
	POP	ES
	MOV	CX,4558h
	MOV	DX,4152h
	CALL	$SETDPB
	JMP	drive_flags_done

; Changing from one active FAT to mirrored FATs copies the active FAT
; to every copy before committing the new flags.

drive_control_mirror:
	MOV	AL,error_invalid_drive
	CMP	[SI.dpb_fat_size],0
	JNZ	drive_control_error
	MOV	AL,error_invalid_parameter
	MOVZX	ECX,[SI.dpb_extflags]
	AND	ECX,8Fh
	MOV	ES:[DI+12],ECX
	MOV	EDX,ES:[DI+8]
	INC	EDX
	JZ	drive_flags_done
	DEC	EDX
	TEST	EDX,0FFFFFF70h
	JNZ	drive_control_error
	TEST	DX,80h
	JNZ	drive_control_active
	TEST	DX,0Fh
	JNZ	drive_control_error
	TEST	CX,80h
	JZ	drive_control_store_flags
	CMP	[SI.dpb_fat_count],1
	JBE	drive_control_store_flags
	AND	CX,0Fh
	PUSH	DX
	PUSH	DS
	PUSH	SI
	EnterCrit CritDisk
	LDS	BX,SS:[LoMemBuff]
	CMP	SS:[BuffInHMA],0
	JNZ	drive_mirror_buffer
	PUSH	CX
	invoke	GETCURHEAD
	invoke	BUFWRITE
	POP	CX
	JC	drive_mirror_done
	ADD	DI,BUFINSIZ
	MOV	BX,DI
drive_mirror_buffer:
	MOV	SS:[ALLOWED],allowed_FAIL+allowed_RETRY
	POP	BP
	POP	ES
	PUSH	ES
	PUSH	BP
	MOVZX	EAX,CX
	MOV	ECX,ES:[BP.dpb_fat_size32]
	MUL	ECX
	MOV	EDX,EAX
	MOVZX	EAX,ES:[BP.dpb_first_FAT]
	ADD	EDX,EAX
	XOR	EAX,EAX
drive_mirror_sector:
	PUSH	ECX
	PUSH	EDX
	PUSH	EAX
	PUSH	BX
	ROR	EDX,16
	MOV	SS:[HIGH_SECTOR],DX
	ROR	EDX,16
	MOV	CX,1
	invoke	DREAD
	POP	BX
	JC	drive_mirror_error
	POP	EAX
	PUSH	EAX
	MOVZX	CX,ES:[BP.dpb_fat_count]
	MOVZX	EDX,ES:[BP.dpb_first_FAT]
	ADD	EDX,EAX
drive_mirror_copy:
	PUSH	CX
	PUSH	EDX
	PUSH	BX
	ROR	EDX,16
	MOV	SS:[HIGH_SECTOR],DX
	ROR	EDX,16
	MOV	CX,1
	invoke	DWRITE
	POP	BX
	POP	EDX
	POP	CX
	JC	drive_mirror_error
	ADD	EDX,ES:[BP.dpb_fat_size32]
	DEC	CX
	JNZ	drive_mirror_copy
	POP	EAX
	POP	EDX
	POP	ECX
	INC	EDX
	INC	EAX
	DEC	ECX
	JNZ	drive_mirror_sector
	CLC
	JMP	SHORT drive_mirror_done
drive_mirror_error:
	POP	EAX
	POP	EDX
	POP	ECX
drive_mirror_done:
	LeaveCrit CritDisk
	POP	SI
	POP	DS
	POP	DX
	MOV	AL,error_gen_failure
	JC	drive_control_error
	JMP	SHORT drive_control_store_flags
drive_control_active:
	MOV	BX,DX
	AND	BX,0Fh
	CMP	BL,[SI.dpb_fat_count]
	JAE	drive_control_error
drive_control_store_flags:
	AND	[SI.dpb_extflags],0FF70h
	OR	[SI.dpb_extflags],DX
	OR	[SI.dpb_first_access],8
	JMP	drive_control_update

; Validate and replace cached free-cluster and next-allocation values.

drive_control_free:
	MOVZX	EBX,[SI.dpb_max_cluster]
	CMP	[SI.dpb_fat_size],0
	JNZ	drive_control_counts
	MOV	EBX,[SI.dpb_max_cluster32]
drive_control_counts:
	MOV	AL,error_invalid_parameter
	MOV	ECX,ES:[DI+8]
	MOV	EDX,ES:[DI+12]
	JECXZ	drive_control_next
	CMP	ECX,-1
	JZ	drive_control_next
	CMP	ECX,EBX
	JAE	drive_control_error
drive_control_next:
	CMP	EDX,1
	JB	drive_control_save_free
	JZ	drive_control_error
	CMP	EDX,-1
	JZ	drive_control_save_free
	CMP	EDX,EBX
	JA	drive_control_error
drive_control_save_free:
	JECXZ	drive_control_save_next
	OR	[SI.dpb_first_access],1
	MOV	WORD PTR [SI.dpb_free_cnt],CX
	CMP	[SI.dpb_fat_size],0
	JNZ	drive_control_save_next
	MOV	[SI.dpb_free_cnt],ECX
drive_control_save_next:
	OR	EDX,EDX
	JZ	drive_flags_done
	OR	[SI.dpb_first_access],1
	CMP	EDX,-1
	JNZ	drive_control_next_value
	MOV	EDX,2
drive_control_next_value:
	MOV	[SI.dpb_next_free],DX
	CMP	[SI.dpb_fat_size],0
	JNZ	drive_flags_done
	MOV	[SI.dpb_next_free32],EDX
	JMP	drive_flags_done
	.8086
EndProc $DriveFlags

BREAK <$Create_Process_Data_Block,SetMem -- Set up process data block>

;
;----------------------------------------------------------------------------
;
;**	$Dup_PDB
;
; Inputs:   DX is new segment address of process
;	    SI is end of new allocation block
;
;----------------------------------------------------------------------------
;

procedure   $Dup_PDB,NEAR
	ASSUME	SS:NOTHING

;hkn;	CreatePDB would have a CS override. This is not valid.
;hkn;	Must set up ds in order to acess CreatePDB. Also SS is 
;hkn;	has been assumed to be NOTHING. It may not have DOSDATA.

	getdseg	<ds>			; ds -> dosdata

	MOV	CreatePDB,0FFH		; indicate a new process
	MOV	DS,CurrentPDB
	PUSH	SI
	JMP	SHORT	CreateCopy
EndProc $Dup_PDB

;
;----------------------------------------------------------------------------
;
; Inputs:
;	DX = Segment number of new base
; Function:
;	Set up program base and copy term and ^C from int area
; Returns:
;	None
; Called at DOS init
;
;----------------------------------------------------------------------------
;

procedure   $CREATE_PROCESS_DATA_BLOCK,NEAR
	ASSUME	SS:NOTHING

	CALL	get_user_stack
	MOV	DS,[SI.user_CS]
	PUSH	DS:[PDB_Block_len]
CreateCopy:
	MOV	ES,DX

	XOR	SI,SI			; copy entire PDB
	MOV	DI,SI
	MOV	CX,40H
	.386
	REP	MOVSD
	.8086
; DOS 3.3 7/9/86


	MOV	CX,FilPerProc		; copy handles in case of
	MOV	DI,PDB_JFN_Table	; Set Handle Count has been issued
	PUSH	DS
	LDS	SI,DS:[PDB_JFN_Pointer]
	REP	MOVSB
	POP	DS

; DOS 3.3 7/9/86

		;hkn;CreatePDB would have a CS override. This is not valid.
		;hkn;Must set up ds in order to acess CreatePDB. Also SS is 
		;hkn;has been assumed to be NOTHING. It may not have DOSDATA.

	getdseg	<ds>			; ds -> dosdata

	cmp	CreatePDB,0		; Shall we create a process?
	JZ	Create_PDB_cont 	; nope, old style call
;
; Here we set up for a new process...
;

;hkn;	PUSH    CS                      ; Called at DOSINIT time, NO SS
;hkn;	POP     DS

;hkn;	must set up DS to DOSDATA

	getdseg	<ds>			; ds -> dosdata

	DOSAssume   <DS>,"Create PDB"
	XOR	BX,BX			; dup all jfns
	MOV	CX,FilPerProc		; only 20 of them

Create_dup_jfn:
	PUSH	ES			; save new PDB
	invoke	SFFromHandle		; get sf pointer
	MOV	AL,-1			; unassigned JFN
	JC	CreateStash		; file was not really open
	CMP	ES:[DI].sf_ref_count,0
	JZ	CreateStash
	CMP	ES:[DI].sf_ref_count,-1
	JZ	CreateStash
	TESTB	ES:[DI].sf_flags,sf_no_inherit
	JNZ	CreateStash		; if no-inherit bit is set, skip dup.
;
; We do not inherit network file handles.
;
	MOV	AH,BYTE PTR ES:[DI].sf_mode
	AND	AH,sharing_mask
	CMP	AH,sharing_net_fcb
	jz	CreateStash
;
; The handle we have found is duplicatable (and inheritable).  Perform
; duplication operation.
;
	MOV	WORD PTR [THISSFT],DI
	MOV	WORD PTR [THISSFT+2],ES
	invoke	DOS_DUP 		; signal duplication
;
; get the old sfn for copy
;
	invoke	pJFNFromHandle		; ES:DI is jfn
	MOV	AL,ES:[DI]		; get sfn
;
; Take AL (old sfn or -1) and stash it into the new position
;
CreateStash:
	POP	ES
	MOV	ES:[BX].PDB_JFN_Table,AL; copy into new place!
	INC	BX			; next jfn...
	LOOP	create_dup_jfn

	MOV	BX,CurrentPDB		; get current process
	MOV	ES:[PDB_Parent_PID],BX	; stash in child
	MOV	[CurrentPDB],ES
	ASSUME	DS:NOTHING
	MOV	DS,BX
;
; end of new process create
;
Create_PDB_cont:

;hkn; It comes to this point from 2 places. So, change to DOSDATA temporarily
	push	ds
	getdseg	<ds>			; ds -> dosdata

	MOV     BYTE PTR [CreatePDB],0h ; reset flag
	pop	ds

	POP	AX

	entry	SETMEM
ASSUME	DS:NOTHING,ES:NOTHING,SS:NOTHING
;---------------------------------------------------------------------------
; Inputs:
;	AX = Size of memory in paragraphs
;	DX = Segment
; Function:
;	Completely prepares a program base at the
;	specified segment.
; Called at DOS init
; Outputs:
;	DS = DX
;	ES = DX
;	[0] has INT int_abort
;	[2] = First unavailable segment
;	[5] to [9] form a long call to the entry point
;	[10] to [13] have exit address (from int_terminate)
;	[14] to [17] have ctrl-C exit address (from int_ctrl_c)
;	[18] to [21] have fatal error address (from int_fatal_abort)
; DX,BP unchanged. All other registers destroyed.
;---------------------------------------------------------------------------

	XOR	CX,CX
	MOV	DS,CX
	MOV	ES,DX
	MOV	SI,addr_int_terminate
	MOV	DI,SAVEXIT
	MOV	CX,6
	REP	MOVSW
	MOV	ES:[2],AX
	SUB	AX,DX
	CMP	AX,MAXDIF
	JBE	HAVDIF
	MOV	AX,MAXDIF
HAVDIF:
	DB	083h,0E8h,010h		; SUB AX,10H; signed immediate, 100h stack
	MOV	BX,ENTRYPOINTSEG	;	in .COM files
	SUB	BX,AX
	MOV	CL,4
	SHL	AX,CL
	MOV	DS,DX

	;
	; The address in BX:AX will be F01D:FEF0 if there is 64K or more 
	; memory in the system. This is equivalent to 0:c0 if A20 is OFF.
	; If DOS is in HMA this equivalence is no longer valid as A20 is ON.
	; But the BIOS which now resides in FFFF:30 has 5 bytes in FFFF:D0
	; (F01D:FEF0) which is the same as the ones in 0:C0, thereby 
	; making this equvalnce valid for this particular case. If however
	; there is less than 64K remaining the address in BX:AX will not 
	; be the same as above. We will then stuff 0:c0 , the call 5 address
	; into the PSP.
	;
	; Therefore for the case where there is less than 64K remaining in 
	; the system old CPM Apps that look at PSP:6 to determine memory
	; requirements will not work. Call 5, however will continue to work
	; for all cases.
	;

	MOV	WORD PTR DS:[PDB_CPM_Call+1],AX
	MOV	WORD PTR DS:[PDB_CPM_Call+3],BX

	cmp	ax, WRAPOFFSET		; Q: does the system have >= 64k of
					;    memory left
	je	addr_ok			; Y: the above calculated address is
					;    OK
					; N: 


	MOV	WORD PTR DS:[PDB_CPM_Call+1],0c0h
	MOV	WORD PTR DS:[PDB_CPM_Call+3],0

addr_ok:

	MOV	DS:[PDB_Exit_Call],(int_abort SHL 8) + mi_INT
	MOV	BYTE PTR DS:[PDB_CPM_Call],mi_Long_CALL
	MOV	WORD PTR DS:[PDB_Call_System],(int_command SHL 8) + mi_INT
	MOV	BYTE PTR DS:[PDB_Call_System+2],mi_Long_RET
	MOV	WORD PTR DS:[PDB_JFN_Pointer],PDB_JFN_Table
	MOV	WORD PTR DS:[PDB_JFN_Pointer+2],DS
	MOV	WORD PTR DS:[PDB_JFN_Length],FilPerProc
;
; The server runs several PDB's without creating them VIA EXEC.  We need to
; enumerate all PDB's at CPS time in order to find all references to a
; particular SFT.  We perform this by requiring that the server link together
; for us all sub-PDB's that he creates.  The requirement for us, now, is to
; initialize this pointer.
;
	.386
	MOV	DWORD PTR DS:[PDB_Next_PDB],-1
	.8086

			; Set the real version number in the PSP
	mov	ES:[PDB_Version],(MINOR_VERSION SHL 8)+MAJOR_VERSION

	return

EndProc $CREATE_PROCESS_DATA_BLOCK


BREAK <$GSetMediaID -- get set media ID>
;---------------------------------------------------------------------------
; Inputs:
;	BL= drive number as defined in IOCTL
;	AL= 0 get media ID
;	    1 set media ID
;	DS:DX= buffer containing information
;		DW  0  info level (set on input)
;		DD  ?  serial #
;		DB  11 dup(?)  volume id
;		DB   8 dup(?)  file system type
; Function:
;	Get or set media ID
; Returns:
;	carry clear, DS:DX is filled
;	carry set, error
;---------------------------------------------------------------------------

procedure   $GSetMediaID,NEAR ;AN000;

	MOV	CX,0866H	      ;AN000;MS.; assume get  for IOCTL
	CMP	AL,0		      ;AN001;MS.; get ?
	JZ	doioctl 	      ;AN000;MS.; yes
	CMP	AL,1		      ;AN000;MS.; set ?
	JNZ	errorfunc	      ;AN000;MS.; no
	MOV	CX,0846H	      ;AN001;MS.;
doioctl:			      ;AN000;
	MOV	AL,0DH		      ;AN000;MS.; generic IOCTL
	invoke	$IOCTL		      ;AN000;MS.; let IOCTL take care of it
	return			      ;AN000;MS.;
errorfunc:			      ;AN000;
	error	error_invalid_function;AN000;MS.	; invalid function
EndProc $GSetMediaID		      ;AN000;

DOSCODE	ENDS
END
