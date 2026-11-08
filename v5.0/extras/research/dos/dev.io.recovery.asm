; Bounded comparative device tail; not yet production linked.
	TITLE	DEV - Device call routines
	NAME	Dev

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;


;**	Misc Routines to do 1-12 low level I/O and call devices
;
;	IOFUNC
;	DEVIOCALL
;	SETREAD
;	SETWRITE
;	DEVIOCALL2
;	DEV_OPEN_SFT
;	DEV_CLOSE_SFT
;	RW_SC
;	IN_SC
;	INVALIDATE_SC
;	VIRREAD
;	SC2BUF
;
;	Revision history:
;
;		A000  version 4.00     Jan. 1988
;		A010  disable change line for SHARE /NC

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	INCLUDE DEVSYM.INC
	include dpb.inc
	include sf.inc
	.cref
	.list

	i_need	IOXAD,DWORD
	i_need	IOSCNT,WORD
	i_need	DEVIOBUF,4
	i_need	IOCALL,BYTE
	i_need	IOMED,BYTE
	i_need	IORCHR,BYTE
	i_need	CALLSCNT,WORD
	i_need	DMAAdd,DWORD
	i_need	CallDevAd,DWORD
	i_need	CallXAD,DWORD
	i_need	DPBHead,DWORD
	i_need	ThisSFT,DWORD
	i_need	ThisDPB,DWORD
	i_need	DevCall,DWORD
	i_need	VerFlg,BYTE
	i_need	HIGH_SECTOR,WORD	       ;AN000;
	i_need	CALLSSEC,WORD		       ;AN000;
	i_need	CALLNEWSC,DWORD 	       ;AN000;
	i_need	SC_CACHE_COUNT,WORD	       ;AN000;
	i_need	SC_CACHE_PTR,DWORD	       ;AN000;
	i_need	CURSC_SECTOR,WORD	       ;AN000;
	i_need	SEQ_SECTOR,DWORD	       ;AN000;
	i_need	SC_SECTOR_SIZE,WORD	       ;AN000;
	i_need	CURSC_DRIVE,BYTE	       ;AN000;
	i_need	SC_DRIVE,BYTE		       ;AN000;
	i_need	SC_STATUS,WORD		       ;AN000;
	i_need	SC_FLAG,BYTE		       ;AN000;
	i_need	TEMP_VAR,WORD		       ;AN000;
	i_need	TEMP_VAR2,WORD		       ;AN000;
	i_need	InterChar,BYTE	;AN000; interim character flag 2/13/KK
	i_need	InterCon,BYTE	;AN000; Console mode flag(1:interim mode) 2/13/KK
	i_need	SaveCurFlg,BYTE ;AN000; Console out mode(1:print & don't adv cursor) 2 /13/KK
	i_need	DDMOVE,BYTE	;AN000; flag for DWORD move
	i_need	DOS34_FLAG,WORD ;AN000;
	i_need	fshare,BYTE	;AN010; share flag

	i_need 	IoStatFail,BYTE	;SR; set if user failed on I24 in IOFUNC


DOSCODE	Segment

	ASSUME	CS:DOSCODE

ASSUME SS:DOSDATA,DS:NOTHING,ES:NOTHING
procedure   DEVIOCALL,NEAR

					; SS override for CALLSSEC, 
					; CALLNEWSC, HIGH_SECTOR & CALLDEVAD
	Assert	ISSFT,<DS,SI>,"DevIOCall"
	LDS	SI,[SI.sf_devptr]

entry	DEVIOCALL2

	invoke EcritDevice

	TESTB	[SI.SDEVATT],DevTyp    ;AN000; >32mb   block device ?
	JNZ	chardev2	       ;AN000; >32mb   no
	CMP	ES:[BX.REQFUNC],DEVRD  ;AN000; >32mb   read ?
	JZ	chkext		       ;AN000; >32mb   yes
	CMP	ES:[BX.REQFUNC],DEVWRT ;AN000; >32mb   write ?
	JZ	chkext		       ;AN000; >32mb   yes
	CMP	ES:[BX.REQFUNC],DEVWRTV;AN000; >32mb   write/verify ?
	JNZ	chardev2	       ;AN000; >32mb   no
chkext:
	CALL	RW_SC		       ;AN000;LB. use secondary cache if there
	JC	dev_exit	       ;AN000;LB. done

	TESTB	[SI.SDEVATT],EXTDRVR   ;AN000;>32mb   extended driver?
	JZ	chksector	       ;AN000;>32mb   no
	ADD	BYTE PTR ES:[BX],8     ;AN000;>32mb   make length to 30
	MOV	AX,[CALLSSEC]	       ;AN000;>32mb
	MOV	[CALLSSEC],-1	       ;AN000;>32mb   old sector  =-1
	MOV	WORD PTR [CALLNEWSC],AX   ;AN000;>32mb	 new sector  =
	MOV	AX,[HIGH_SECTOR]       ;AN000; >32mb   low sector,high sector
	MOV	WORD PTR [CALLNEWSC+2],AX  ;AN000; >32mb
	JMP	short chardev2	       ;AN000; >32mb
chksector:			       ;AN000; >32mb
	CMP	[HIGH_SECTOR],0        ;AN000; >32mb   if >32mb
	JZ	chardev2	       ;AN000; >32mb   then fake error
	MOV	ES:[BX.REQSTAT],STERR+STDON+ERROR_I24_NOT_DOS_DISK  ;AN000; >32mb
	JMP	SHORT dev_exit	       ;AN000; >32mb

chardev2:			       ;AN000;

	;
	; As above only DS:SI points to device header on entry, and DS:SI is 
	; preserved
	;

	MOV	AX,[SI.SDEVSTRAT]
	MOV	WORD PTR [CALLDEVAD],AX
	MOV	WORD PTR [CALLDEVAD+2],DS
	CALL	DWORD PTR [CALLDEVAD]
	MOV	AX,[SI.SDEVINT]
	MOV	WORD PTR [CALLDEVAD],AX
	CALL	DWORD PTR [CALLDEVAD]
	CALL	VIRREAD 		;AN000;LB. move data from SC to buffer
	JC	chardev2		;AN000;LB. bad sector or exceeds max sec
dev_exit:
	invoke LcritDevice
	return
EndProc DEVIOCALL

Break	<SETREAD, SETWRITE -- SET UP HEADER BLOCK>
;---------------------------------------------------------------------------
;
; Procedure Name : SETREAD, SETWRITE
;
; Inputs:
;	DS:BX = Transfer Address
;	CX = Record Count
;	DX = Starting Record
;	AH = Media Byte
;	AL = Unit Code
; Function:
;	Set up the device call header at DEVCALL
; Output:
;	ES:BX Points to DEVCALL
; No other registers effected
;
;---------------------------------------------------------------------------

procedure   SETREAD,NEAR

	PUSH	DI
	PUSH	CX
	PUSH	AX
	MOV	CL,DEVRD
SETCALLHEAD:
	MOV	AL,DRDWRHL
	PUSH	SS
	POP	ES

					; DEVCALL is in DOSDATA
	MOV	DI,OFFSET DOSDATA:DEVCALL

	STOSB				; length
	POP	AX
	STOSB				; Unit
	PUSH	AX
	MOV	AL,CL
	STOSB				; Command code
	XOR	AX,AX
	STOSW				; Status
	ADD	DI,8			; Skip link fields
	POP	AX
	XCHG	AH,AL
	STOSB				; Media byte
	XCHG	AL,AH
	PUSH	AX
	MOV	AX,BX
	STOSW
	MOV	AX,DS
	STOSW				; Transfer addr
	POP	CX			; Real AX
	POP	AX			; Real CX
	STOSW				; Count
	XCHG	AX,DX			; AX=Real DX, DX=real CX, CX=real AX
	STOSW				; Start
	XCHG	AX,CX
	XCHG	DX,CX
	POP	DI
					; DEVCALL is in DOSDATA
	MOV	BX,OFFSET DOSDATA:DEVCALL
	return

	entry	SETWRITE
ASSUME	DS:NOTHING,ES:NOTHING

; Inputs:
;	DS:BX = Transfer Address
;	CX = Record Count
;	DX = Starting Record
;	AH = Media Byte
;	AL = Unit Code
; Function:
;	Set up the device call header at DEVCALL
; Output:
;	ES:BX Points to DEVCALL
; No other registers effected

	PUSH	DI
	PUSH	CX
	PUSH	AX
	MOV	CL,DEVWRT
	ADD	CL,[VERFLG]		; SS override
	JMP	SHORT SETCALLHEAD
EndProc SETREAD


Break	<RW_SC -- Read Write Secondary Cache>
;---------------------------------------------------------------------------
;
; Procedure Name : RW_SC
;
; Inputs:
;	 [SC_CACHE_COUNT]= secondary cache count
;	 [SC_STATUS]= SC validity status
;	 [SEQ_SECTOR]= last sector read
; Function:
;	Read from or write through secondary cache
; Output:
;	ES:BX Points to DEVCALL
;	carry clear, I/O is not done
;		     [SC_FLAG]=1 if continuos sectors will be read
;	carry set, I/O is done
;
;----------------------------------------------------------------------------


procedure   RW_SC,NEAR		;AN000;

	; SS override for all variables used.

	CMP	[SC_CACHE_COUNT],0	;AN000;LB. secondary cache exists?
	JZ	scexit4 		;AN000;LB. no, do nothing
	CMP	[CALLSCNT],1		;AN000;LB. sector count = 1 (buffer I/O)
	JNZ	scexit4 		;AN000;LB. no, do nothing
	PUSH	CX			    ;AN000;;LB.
	PUSH	DX			    ;AN000;;LB. yes
	PUSH	DS			    ;AN000;;LB. save registers
	PUSH	SI			    ;AN000;;LB.
	PUSH	ES			    ;AN000;;LB.
	PUSH	DI			    ;AN000;;LB.
	MOV	DX,WORD PTR [CALLSSEC]	    ;AN000;;LB.  starting sector
	CMP	BYTE PTR [DEVCALL.REQFUNC],DEVRD ;AN000;LB. read ?		      ;AN000;
	JZ	doread			;AN000;LB. yes				      ;AN000;
	CALL	INVALIDATE_SC		    ;AN000;LB. invalidate SC		      ;AN000;
	JMP	scexit2 		    ;AN000;LB. back to normal		      ;AN000;
scexit4:				    ;AN000;				       ;AN000;
	CLC				    ;AN000;LB. I/O not done yet 	  ;AN000;
	return				    ;AN000;LB.				  ;AN000;
doread: 				    ;AN000;				       ;AN000;
	CALL	SC2BUF			    ;AN000;LB. check if in SC		      ;AN000;
	JC	readSC			    ;AN000;LB.					  ;AN000;
	MOV	[DEVCALL.REQSTAT],STDON     ;AN000;LB. fake done and ok 	  ;AN000;
	STC				    ;AN000;LB. set carry		  ;AN000;
	JMP	short saveseq 		    ;AN000;LB. save seq. sector #	  ;AN000;
readSC: 				    ;AN000;
	MOV	AX,WORD PTR [HIGH_SECTOR]   ;AN000;;LB. subtract sector num from
	MOV	CX,WORD PTR [CALLSSEC]	    ;AN000;;LB. saved sequential sector
	SUB	CX,WORD PTR [SEQ_SECTOR]    ;AN000;;LB. number
	SBB	AX,WORD PTR [SEQ_SECTOR+2]  ;AN000;;LB.
	CMP	AX,0			    ;AN000;;LB. greater than 64K
	JNZ	saveseq2		    ;AN000;;LB. yes,save seq. sector #
chklow: 									;AN000;
	CMP	CX,1			    ;AN000;;LB. <= 1
	JA	saveseq2		    ;AN000;;LB. no, not sequential
	MOV	[SC_STATUS],-1		    ;AN000;;LB. prsume all SC valid
	MOV	AX,[SC_CACHE_COUNT]	    ;AN000;;LB. yes, sequential
	MOV	[CALLSCNT],AX		    ;AN000;;LB. read continuous sectors
readsr:
	MOV	AX,WORD PTR [CALLXAD+2]     ;AN000;;LB. save buffer addr
	MOV	[TEMP_VAR2],AX		    ;AN000;;LB. in temp vars
	MOV	AX,WORD PTR [CALLXAD]	    ;AN000;;LB.
	MOV	[TEMP_VAR],AX		    ;AN000;;LB.
										;AN000;
	MOV	AX,WORD PTR [SC_CACHE_PTR]  ;AN000;LB. use SC cache addr as	      ;AN000;
	MOV	WORD PTR [CALLXAD],AX	    ;AN000;LB. transfer addr		      ;AN000;
	MOV	AX,WORD PTR [SC_CACHE_PTR+2]  ;AN000;LB.			      ;AN000;
	MOV	WORD PTR [CALLXAD+2],AX       ;AN000;LB.			      ;AN000;
	MOV	[SC_FLAG],1		      ;AN000;LB. flag it for later	      ;AN000;
	MOV	AL,[SC_DRIVE]		    ;AN000;;LB. current drive
	MOV	[CURSC_DRIVE],AL	    ;AN000;;LB. set current drive
	MOV	AX,WORD PTR [CALLSSEC]	    ;AN000;;LB. current sector
	MOV	[CURSC_SECTOR],AX	    ;AN000;;LB. set current sector
	MOV	AX,WORD PTR [HIGH_SECTOR]   ;AN000;;LB.
	MOV	[CURSC_SECTOR+2],AX	    ;AN000;;LB.
saveseq2:				    ;AN000;
	CLC				    ;AN000;LB. clear carry		      ;AN000;
saveseq:				    ;AN000;				       ;AN000;
	MOV	AX,[HIGH_SECTOR]	    ;AN000;LB. save current sector #	  ;AN000;
	MOV	WORD PTR [SEQ_SECTOR+2],AX  ;AN000;LB. for access mode ref.	  ;AN000;
	MOV	AX,[CALLSSEC]		    ;AN000;LB.				  ;AN000;
	MOV	WORD PTR [SEQ_SECTOR],AX    ;AN000;LB.				  ;AN000;
	JMP	short scexit 		    ;AN000;LB.				  ;AN000;
										;AN000;
scexit2:				    ;AN000;LB.				      ;AN000;
	CLC				    ;AN000;LB.	       clear carry	      ;AN000;
scexit: 				    ;AN000;				       ;AN000;
	POP	DI			    ;AN000;;LB.
	POP	ES			    ;AN000;;LB. restore registers
	POP	SI			    ;AN000;;LB.
	POP	DS			    ;AN000;;LB.
	POP	DX			    ;AN000;;LB.
	POP	CX			    ;AN000;;LB.
	return				    ;AN000;;LB.
										;AN000;
EndProc RW_SC				    ;AN000;

Break	<IN_SC -- check if in secondary cache>
;--------------------------------------------------------------------------
;
; Procedure Name : IN_SC
;
; Inputs:  [SC_DRIVE]= requesting drive
;	   [CURSC_DRIVE]= current SC drive
;	   [CURSC_SECTOR] = starting scetor # of SC
;	   [SC_CACHE_COUNT] = SC count
;	   [HIGH_SECTOR]:DX= sector number
; Function:
;	Check if the sector is in secondary cache
; Output:
;	carry clear, in SC
;	   CX= the index in the secondary cache
;	carry set, not in SC
;
;---------------------------------------------------------------------------

procedure   IN_SC,NEAR		    ;AN000;

	; SS override for all variables used

	MOV	AL,[SC_DRIVE]		    ;AN000;;LB. current drive
	CMP	AL,[CURSC_DRIVE]	    ;AN000;;LB. same as SC drive
	JNZ	outrange2		    ;AN000;;LB. no
	MOV	AX,WORD PTR [HIGH_SECTOR]   ;AN000;;LB. subtract sector num from
	MOV	CX,DX			    ;AN000;;LB. secondary starting sector
	SUB	CX,WORD PTR [CURSC_SECTOR]    ;AN000;;LB. number
	SBB	AX,WORD PTR [CURSC_SECTOR+2]  ;AN000;;LB.
	CMP	AX,0			    ;AN000;;LB. greater than 64K
	JNZ	outrange2		    ;AN000;;LB. yes
	CMP	CX,[SC_CACHE_COUNT]	    ;AN000;;LB. greater than SC count
	JAE	outrange2		    ;AN000;;LB. yes
	CLC				    ;AN000;;LB. clear carry
	JMP	short inexit		    ;AN000;;LB. in SC
outrange2:				    ;AN000;;LB. set carry
	STC				    ;AN000;;LB.
inexit: 				    ;AN000;;LB.
	return				    ;AN000;;LB.

EndProc IN_SC				    ;AN000;

Break	<INVALIDATE_SC - invalide secondary cache>
;---------------------------------------------------------------------------
;
; Procedure Name : Invalidate_Sc
;
; Inputs:  [SC_DRIVE]= requesting drive
;	   [CURSC_DRIVE]= current SC drive
;	   [CURSC_SECTOR] = starting scetor # of SC
;	   [SC_CACHE_COUNT] = SC count
;	   [SC_STAUS] = SC status word
;	   [HIGH_SECTOR]:DX= sceotor number
;
; Function:
;	invalidate secondary cache if in there
; Output:
;	[SC_STATUS] is updated
;---------------------------------------------------------------------------

procedure   INVALIDATE_SC,NEAR	    ;AN000;

	; SS override for all variables used

	CALL	IN_SC			    ;AN000;;LB. in secondary cache
	JC	outrange		    ;AN000;;LB. no
	MOV	AX,1			    ;AN000;;LB. invalidate the sector
	SHL	AX,CL			    ;AN000;;LB. in the secondary cache
	NOT	AX			    ;AN000;;LB.
	AND	[SC_STATUS],AX		    ;AN000;;LB. save the status
outrange:				    ;AN000;;LB.
	return				    ;AN000;;LB.

EndProc INVALIDATE_SC			    ;AN000;


Break	<VIRREAD- virtually read data into buffer>
;--------------------------------------------------------------------------
;
; Procedure Name : SC_FLAG
;
; Inputs:  SC_FLAG = 0 , no sectors were read into SC
;		     1, continous sectors were read into SC
; Function:
;	   Move data from SC to buffer
; Output:
;	 carry clear, data is moved to buffer
;	 carry set, bad sector or exceeds maximum sector
;	   SC_FLAG =0
;	   CALLSCNT=1
;	   SC_STATUS= -1 if succeeded
;     
;		       0 if failed
;--------------------------------------------------------------------------

procedure   VIRREAD,NEAR	    ;AN000;

	; SS override for all variables used

	CMP	[SC_FLAG],0		    ;AN000;;LB.  from SC fill
	JZ	sc2end			    ;AN000;;LB.  no
	MOV	AX,[TEMP_VAR2]		    ;AN000;;LB. restore buffer addr
	MOV	WORD PTR [CALLXAD+2],AX     ;AN000;;LB.
	MOV	AX,[TEMP_VAR]		    ;AN000;;LB.
	MOV	WORD PTR [CALLXAD],AX	    ;AN000;;LB.
	MOV	[SC_FLAG],0		    ;AN000;;LB.  reset sc_flag
	MOV	[CALLSCNT],1		    ;AN000;;LB.  one sector transferred

	TESTB	[DEVCALL.REQSTAT],STERR     ;AN000;;LB.  error?
	JNZ	scerror 		    ;AN000;;LB. yes
	PUSH	DS			    ;AN000;;LB.
	PUSH	SI			    ;AN000;;LB.
	PUSH	ES			    ;AN000;;LB.
	PUSH	DI			    ;AN000;;LB.
	PUSH	DX			    ;AN000;;LB.
	PUSH	CX			    ;AN000;;LB.
	XOR	CX,CX			    ;AN000;;LB. we want first sector in SC
	CALL	SC2BUF2 		    ;AN000;;LB. move data from SC to buffer
	POP	CX			    ;AN000;;LB.
	POP	DX			    ;AN000;;LB.
	POP	DI			    ;AN000;;LB.
	POP	ES			    ;AN000;;LB.
	POP	SI			    ;AN000;;LB.
	POP	DS			    ;AN000;;LB.
	JMP	SHORT sc2end		    ;AN000;;LB. return

scerror:				    ;AN000;
	MOV	[CALLSCNT],1		    ;AN000;;LB. reset sector count to 1
	MOV	[SC_STATUS],0		    ;AN000;;LB. invalidate all SC sectors
	MOV	[CURSC_DRIVE],-1	    ;AN000;;LB. invalidate drive
	STC				    ;AN000;;LB. carry set
	return				    ;AN000;;LB.

sc2end: 				    ;AN000;
	CLC				    ;AN000;;LB. carry clear
	return				    ;AN000;;LB.

EndProc VIRREAD 			    ;AN000;

Break	<SC2BUF- move data from SC to buffer>
;----------------------------------------------------------------------------
;
; Procedure Name : SC2BUF
;
; Inputs:  [SC_STATUS] = SC validity status
;	   [SC_SECTOR_SIZE] = request sector size
;	   [SC_CACHE_PTR] = pointer to SC
; Function:
;	   Move data from SC to buffer
; Output:
;	   carry clear, in SC  and data is moved
;	   carry set, not in SC and data is not moved
;---------------------------------------------------------------------------

procedure   SC2BUF,NEAR 	    ;AN000;

	; SS override for all variables used

	CALL	IN_SC			    ;AN000;;LB. in secondary cache
	JC	noSC			    ;AN000;;LB. no
	MOV	AX,1			    ;AN000;;LB. check if valid sector
	SHL	AX,CL			    ;AN000;;LB. in the secondary cache
	TEST	[SC_STATUS],AX		    ;AN000;;LB.
	JZ	noSC			    ;AN000;;LB. invalid
entry SC2BUF2				    ;AN000;
	MOV	AX,CX			    ;AN000;;LB. times index with
	MUL	[SC_SECTOR_SIZE]	    ;AN000;;LB. sector size
	ADD	AX,WORD PTR [SC_CACHE_PTR]  ;AN000;;LB. add SC starting addr
	ADC	DX,WORD PTR [SC_CACHE_PTR+2];AN000;;LB.
	MOV	DS,DX			    ;AN000;    ;LB. DS:SI-> SC sector addr
	MOV	SI,AX			    ;AN000;    ;LB.
	MOV	ES,WORD PTR [CALLXAD+2]     ;AN000;    ;LB. ES:DI-> buffer addr
	MOV	DI,WORD PTR [CALLXAD]	    ;AN000;    ;LB.
	MOV	CX,[SC_SECTOR_SIZE]	    ;AN000;    ;LB. count= sector size
	SHR	CX,1			    ;AN000;    ;LB. may use DWORD move for 386
entry MOVWORDS				    ;AN000;
	CMP	[DDMOVE],0		    ;AN000;    ;LB. 386 ?
	JZ	nodd			    ;AN000;    ;LB. no
	SHR	CX,1			    ;AN000;    ;LB. words/2
	DB	66H			    ;AN000;    ;LB. use double word move
nodd:
	REP	MOVSW			    ;AN000;    ;LB. move to buffer
	CLC				    ;AN000;    ;LB. clear carry
	return				    ;AN000;    ;LB. exit
noSC:					    ;AN000;
	STC				    ;AN000;    ;LB. set carry
sexit:					    ;AN000;
	return				    ;AN000;    ;LB.

EndProc SC2BUF
DOSCODE	ENDS
	END
