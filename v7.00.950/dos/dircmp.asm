	TITLE	DIRCMP - Directory name comparison
	NAME	DirCmp

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
	.cref
	.list


; Extracted comparison procedure; linked in the DOS 7 late-code region.
DOSCODE Segment
        ASSUME CS:DOSCODE,SS:DOSDATA,DS:NOTHING,ES:NOTHING
	procedure   MetaCompare,near
	MOV	CX,11
 IFDEF  DBCS				;AN000;
;-------------------- Start of DBCS	;AN000;
	CMP	BYTE PTR DS:[SI],05H	;AN000;; Special case for lead byte of 05h
	JNE	WILDCRD2		;AN000;; Compare as normal if not an 05h
	CMP	BYTE PTR ES:[DI],0E5H	;AN000;; 05h and 0E5h equivalent for lead byte
	JNE	WILDCRD2		;AN000;; Compare as normal if not an 05h
	DEC	CX			;AN000;; One less byte to compare
	INC	SI			;AN000;; Bypass lead byte in source and
	INC	DI			;AN000;;  destination when 05h and 0E5h found.
WILDCRD2:				;AN000;
	PUSH	AX			;AN000;;KK. save ax
cagain: 				;AN000;;KK.
	CMP	CX,0			;AN000;;KK. end of compare ?
	JLE	metaend2		;AN000;;KK. yes
	MOV	AL,[SI] 		;AN000;;KK. is it a Kanji
	invoke	testkanj		;AN000;;KK.
	JZ	notdb			;AN000;;KK. no
	MOV	AX,'??'                 ;AN000;;KK.
	CMP	ES:[DI],AX		;AN000;;KK. is es:di pointing to '??'
	JNZ	metaend3		;AN000;;KK. no
	ADD	SI,2			;AN000;;KK.
	ADD	DI,2			;AN000;;KK. update pointers and count
subcx:					;AN000;
	SUB	CX,2			;AN000;;KK.
	JMP	cagain			;AN000;;KK.
metaend3:				;AN000;;KK.
	CMPSW				;AN000;;KK.
	JNZ	metaend2		;AN000;;KK.
	JMP	subcx			;AN000;;KK.
notdb:					;AN000;
	CMPSB				;AN000;;KK. same code ?
	JZ	sameco			;AN000;;KK. yes
	CMP	BYTE PTR ES:[DI-1],"?"  ;AN000;;KK. ?
	JNZ	metaend2		;AN000;;KK. no
sameco: 				;AN000;
	DEC	CX			;AN000;;KK. decrement count
	JMP	cagain			;AN000;;KK.

metaend2:				;AN000;
	POP	AX			;AN000;;KK.
;-------------------- End of DBCS	;AN000; KK.
 ELSE					;AN000;
WILDCRD:
	REPE	CMPSB
	JZ	MetaRet 		; most of the time we will fail.
CHECK_META:
	CMP	BYTE PTR ES:[DI-1],"?"
	JZ	WildCrd
MetaRet:
 ENDIF					;AN000;
	return				; Zero set, Match
EndProc MetaCompare
DOSCODE ENDS
        END
