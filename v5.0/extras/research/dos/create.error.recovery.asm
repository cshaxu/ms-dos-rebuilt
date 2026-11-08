	TITLE	CREATE - File creation error mapping
	NAME	Create

	include version.inc
	include dosseg.inc
	include dossym.inc

DOSCODE SEGMENT
	ASSUME SS:DOSDATA,CS:DOSCODE

entry	SET_MKND_ERR
	DOSAssume   <DS>,"Set_MkNd_Err"
	ASSUME	ES:NOTHING

;	Looks up MakeNode errors and converts them. AL is MakeNode
;	error, SI is GetPath bad spot return if path_not_found error.

;hkn; CRTERRTAB is in TABLE seg (DOSCODE)
	MOV     BX,OFFSET DOSCODE:CRTERRTAB
;hkn;	XLAT
	XLAT	byte ptr CS:[BX]
CreatBadRet:
	STC
	return

Public CREAT001S,CREAT001E
CREAT001S  label  byte
CRTERRTAB LABEL BYTE		; Lookup table for MakeNode returns
	DB	?			; none
	DB	error_access_denied	; MakeNode error 1
	DB	error_cannot_make	; MakeNode error 2
	DB	error_file_exists	; MakeNode error 3
	DB	error_path_not_found	; MakeNode error 4
	DB	error_access_denied	; MakeNode error 5
	DB	error_sharing_violation ; MakeNode error 6
	DB	error_file_not_found	; MakeNode error 7
CREAT001E  label byte

DOSCODE ENDS
	END
