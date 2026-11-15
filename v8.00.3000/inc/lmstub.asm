
;===========================================================================
;
; 	TITLE Low Memory Stub for DOS when DOS runs in HMA
;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;
;	Revision History:
;
;	M003 - MS PASCAL 3.2 support. Please see under tag M003 in dossym.inc
;	       7/30/90
;
;	M006 - print A20 Hardware error using int 10.
;
;	M020 - Fix for Rational Bug - see exepatch.asm for details
;
;	M011 - check for wrap rather than do an XMS query 
;	       A20 after int 23,24 and 28
;
;	M012 - Rearranged stuff to make Share build with msdata
;
;	M023 - Added variable UmbSave1 for preserving umb_head arena across 
;	       win /3 session for win ver < 3.1
;
;       M032 - Correct length of Exec data block in Win 2.x instance table.
;
;	M034 - add a new variable i20to28count to be used by MSDOS.SYS
;		(msinit.asm). IF POWER is built into BIOS, then this var
;		should be 8 (which means, DOS will not patch INT 28 to an
;		IRET); otherwise, this should be 9.
;
;	M00x - Added a variable for storing the ROM Exclude list ptr
;
;============================================================================


DOSDATA    SEGMENT WORD PUBLIC 'DATA'
	   assume cs:DOSDATA

	EVEN
SS_Save	DW	?		; reserved stack segment
SP_Save	DW	?		; reserved stack offset

		public	RatBugCode
RatBugCode	proc	far
		push	cx
		mov	cx, word ptr ds:[10h]
		loop	$
		pop	cx
		ret
RatBugCode	endp

public	Mark3
	Mark3	label byte

IF2
	IF ((OFFSET MARK3) GT (OFFSET COUNTRY_CDPG) )
		%OUT !DATA CORRUPTION!MARK3 OFFSET TOO BIG. RE-ORGANIZE DATA.
	ENDIF
ENDIF

;############################################################################
;
; ** HACK FOR DOS 4.0 REDIR **
;
; The dos 4.X redir requires that country_cdpg is at offset 0122ah. Any new
; data variable that is to be added to DOSDATA must go in between Mark3
; COUNTRY_CDPG if it can. 
;
; MARK3 SHOULD NOT BE > 122AH 
;
; As of 9/6/90, this area is FULL!
;
;############################################################################
 
	ORG	0122ah

; The following table is used for DOS 3.3
;DOS country and code page information is defined here for DOS 3.3.
;The initial value for ccDosCountry is 1 (USA).
;The initial value for ccDosCodepage is 850.
;
;
		   PUBLIC  UCASE_TAB,FILE_UCASE_TAB,DBCS_TAB
		   PUBLIC  FILE_CHAR_TAB,COLLATE_TAB

PUBLIC	COUNTRY_CDPG

;
; country and code page infomation
;
COUNTRY_CDPG  label  byte

	 db   0,0,0,0,0,0,0,0	      ; reserved words
	 db   '\COUNTRY.SYS',0        ; path name of country.sys
	 db   51 dup (?)
; ------------------------------------------------<MSKK01>----------------------
ifdef	DBCS
  ifdef	  JAPAN
	 dw   932		      ; system code page id (JAPAN)
  endif
  ifdef	  TAIWAN
	 dw   938		      ; system code page id (TAIWAN)
  endif
  ifdef   KOREA
         dw   934                     ; system code page id (KOREA IBM)
  endif
else
	 dw   437		      ; system code page id
endif
; ------------------------------------------------<MSKK01>----------------------
	 dw   6 		      ; number of entries
	 db   SetUcase		      ; Ucase type
	 dw   OFFSET DOSDATA:UCASE_TAB    ;pointer to upper case table
	 dw   DOSDATA 			   ; segment of poiter
	 db   SetUcaseFile	      ; Ucase file char type
	 dw   OFFSET DOSDATA:FILE_UCASE_TAB	;pointer to file upper case table
	 dw   DOSDATA 			   ; segment of poiter
	 db   SetFileList	      ; valid file chars type
	 dw   OFFSET DOSDATA:FILE_CHAR_TAB   ;pointer to valid file char tab
	 dw   DOSDATA 			   ; segment of poiter
	 db   SetCollate	      ; collate type
	 dw   OFFSET DOSDATA:COLLATE_TAB  ;pointer to collate table
	 dw   DOSDATA 			   ; segment of poiter
	 db   SetDBCS		      ;AN000; DBCS Ev			  2/12/KK
	 dw   OFFSET DOSDATA:DBCS_TAB ;AN000;;pointer to DBCS Ev table   2/12/KK
	 dw   DOSDATA 		       ;AN000; segment of poiter	 2/12/KK
	 db   SetCountryInfo	      ; country info type
	 dw   NEW_COUNTRY_SIZE	      ; extended country info size
; ------------------------------------------------<MSKK01>----------------------
ifdef	DBCS
  ifdef	  JAPAN
	 dw   81 		      ; <MSKK01> JAPAN country id
	 dw   932		      ; <MSKK01> JAPAN system code page id
	 dw   2 		      ; <MSKK01> date format (YMD)
	 db   '\',0,0,0,0             ; <MSKK01> currency symbol (YEN)
	 db   ',',0                   ; thousand separator
	 db   '.',0                   ; decimal separator
	 db   '-',0                   ; date separator
	 db   ':',0                   ; time separator
	 db   0 		      ; currency format flag
	 db   0 		      ; <MSKK01> # of disgit in currency
	 db   1 		      ; <MSKK01> time format (HR24)
	 dw   OFFSET DOSDATA:MAP_CASE	;mono case routine entry point
	 dw   0 			; segment of entry point
	 db   ',',0                    ; data list separator
	 dw   0,0,0,0,0 	       ; reserved
  endif
  ifdef	  TAIWAN
	 dw   88		      ; TAIWAN country id
	 dw   938		      ; TAIWAN system code page id
	 dw   0 		      ; date format (MDY)
	 db   'N','T','$',0,0	      ; currency symbol
	 db   ',',0                   ; thousand separator
	 db   '.',0                   ; decimal separator
	 db   '-',0                   ; date separator
	 db   ':',0                   ; time separator
	 db   0 		      ; currency format flag
	 db   2 		      ; # of disgit in currency
	 db   1 		      ; time format (HR24)
	 dw   OFFSET DOSDATA:MAP_CASE	;mono case routine entry point
	 dw   0 			; segment of entry point
	 db   ',',0                    ; data list separator
	 dw   0,0,0,0,0 	       ; reserved
  endif
  ifdef   KOREA
         dw   82                      ; <MSCH> KOREA country id
         dw   934                     ; <MSCH> KOREA system code page id
         dw   2                       ; <MSCH> date format (YMD)
         db   '\',0,0,0,0             ; <MSCH> currency symbol (WON)
	 db   ',',0                   ; thousand separator
	 db   '.',0                   ; decimal separator
	 db   '-',0                   ; date separator
	 db   ':',0                   ; time separator
	 db   0 		      ; currency format flag
         db   0                       ; <MSCH> # of disgit in currency
         db   1                       ; <MSCH> time format (HR24)
	 dw   OFFSET DOSDATA:MAP_CASE	;mono case routine entry point
	 dw   0 			; segment of entry point
	 db   ',',0                    ; data list separator
	 dw   0,0,0,0,0 	       ; reserved
  endif
else
	 dw   1 		      ; USA country id
	 dw   437		      ; USA system code page id
	 dw   0 		      ; date format
	 db   '$',0,0,0,0             ; currency symbol
	 db   ',',0                   ; thousand separator
	 db   '.',0                   ; decimal separator
	 db   '-',0		      ; date separator
	 db   ':',0                   ; time separator
	 db   0 		      ; currency format flag
	 db   2 		      ; # of disgit in currency
	 db   0 		      ; time format
	 dw   OFFSET DOSDATA:MAP_CASE	;mono case routine entry point
	 dw   DOSDATA 			; segment of entry point
	 db   ',',0                    ; data list separator
	 dw   0,0,0,0,0 	       ; reserved
endif
; ------------------------------------------------<MSKK01>----------------------

	PUBLIC	LocaleInfo,LocaleInfoEnd
LocaleInfoPrefix LABEL WORD
        PUBLIC  DosCallDepth
DosCallDepth	db	0
        PUBLIC  DeviceCallDepth
DeviceCallDepth	db	0
LocaleInfo LABEL BYTE
        db      'ENU',0,'USA',0,'US'
        dw      1,2,0
        db      'AM',0,'PM',0
        db      'M/d/yy     dddd,MMMMdd,yyyy         '
LocaleInfoEnd LABEL BYTE
        PUBLIC  NlsBuffer,NlsResponseTable,BiosErrorVector
NlsBuffer LABEL BYTE
        db      56 dup (0)
NlsResponseTable LABEL WORD
        dw      4
        dw      OFFSET DOSDATA:LocaleInfoPrefix
        dw      OFFSET DOSDATA:NlsBuffer+20
        dw      OFFSET DOSDATA:NLS_YES
        dw      OFFSET DOSDATA:BiosErrorVector
include yesno.asm
BiosErrorVector	dd	0

; M034 BEGIN
IFDEF	ROMDOS

        public	i20To28Count		; M034


IFDEF	POWER			; if POWER Driver is part of BIOS
i20To28Count	dw	8	; then dont' patch I28 to an IRET
ELSE
i20To28Count	dw	9	; else patch I28 to an IRET
ENDIF

ENDIF
; M034 END

; M035 BEGIN

IFDEF	ROMEXEC
	public	RomExclRegPtr
RomExclRegPtr	dd	0
ENDIF ; ROMEXEC

; M035 END


DOSDATA	ends

