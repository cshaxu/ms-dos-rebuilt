	page ,132
	title	COMMAND2 - resident code for COMMAND.COM part II
	name	COMMAND2
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;
; M038	SR  11/5/90	Changed stuff for Novell RPL. These guys cannot
;			reserve memory by changing int 12h and then give it
;			back to DOS by changing arenas in autoexec.bat.
;			This makes command.com reload transient and this
;			cannot be done at this stage.
;
;



.xcref
.xlist
	include dossym.inc
	include pdb.inc
	include syscall.inc
	include comsw.asm
	include comequ.asm
	include resmsg.equ

	include comseg.asm
.list
.cref


DATARES 	segment public byte
		extrn	Append_State:word
		extrn	Append_Flag:byte
		extrn	ResMsg128Ptr:word
		extrn	ResMsg118Ptr:word, ResMsg119Ptr:word
		extrn	ResMsg125Ptr:word
		extrn	SafePathBuffer:byte
		extrn	ComDrv:byte
		extrn	ComSpec:byte
		extrn	CmdBufSize:word
		extrn	OriginalComSpec:byte, BootComSpec:byte
		extrn	YSwitchFlags:word
		extrn	EnvirSeg:word
		extrn	OriginalDataSeg:word
		extrn	Int2fHandler:dword
		extrn	Int2eHandler:dword
		extrn	ExtCom:byte
		extrn	ResMsg130Ptr:word
		extrn	ResMsg129Ptr:word
		extrn	Handle01:word
		extrn	InitFlag:BYTE
		extrn	Int_2e_Ret:dword
		extrn	Io_Save:word
		extrn	Loading:byte
		extrn	LTpa:word
		extrn	MemSiz:word
		extrn	ExeHeaderParas:word
		extrn	OldTerm:dword
		extrn	Parent:word
		extrn	PermCom:byte
		extrn	PutBackDrv:byte
		extrn	PutBackSubst:byte
		extrn	Res_Tpa:word
		extrn	RetCode:word
		extrn	Save_Pdb:word
		extrn	SingleCom:word
		extrn	Sum:word
		extrn	SumHigh:word
		extrn	Trans:dword
		extrn	TranVarEnd:byte
		extrn	TranVars:byte
		extrn	TrnSeg:word
		extrn	VerVal:word

		extrn	ResSize:word
		extrn	OldDS:word
		extrn	RStack:word

		extrn	Ctrlc_Trap:near
		extrn	CritErr_Trap:near
		extrn	LodCom_Trap:near

DATARES 	ends

;;ENVARENA 	segment public para
;;ENVARENA 	ends

;;ENVIRONMENT 	segment public para      ; default COMMAND environment
;;ENVIRONMENT 	ends

INIT		segment public para
		extrn	EnvSiz:word
		extrn	OldEnv:word
		extrn	ResetEnv:byte
		extrn	UsedEnv:word
                extrn   AllocedEnv:byte
INIT		ends


TRANDATA	segment public byte
		extrn	trandataend:byte
TRANDATA	ends

TRANSPACE	segment public byte
	extrn	PrimaryResourceHeader:byte
	extrn	$M_RT:byte, PrimaryMsgChecksumEnd:byte
	extrn	PrimaryMsgDirectory:byte
	extrn	StackGuard:word
	extrn	msg_disp_class:byte, Extend_Buf_off:word
	extrn	String_ptr_2:byte
		extrn	transpaceend:byte
		extrn	headcall:dword
TRANSPACE	ends




CODERES segment public byte

	public	BadMemErr

	public	ChkSum
;;	public	EndInit
	public	Int_2e
	public	LoadCom
	public	LodCom
	public	LodCom1
	public	RestHand
	public	SavHand
	public	SetVect
	public	THeadFix
	public	TRemCheck
	public	TJmp

	assume	cs:CODERES,ds:NOTHING,es:NOTHING,ss:NOTHING

	extrn	ContC:near
	extrn	DskErr:near
	extrn	Crlf:near

	extrn	Alloc_error:near

;*	If we cannot allocate enough memory for the transient or there
;	was some other allocation error, we display a message and
;	then die.

;SR;
; We will have to make sure that at this entry point and at FatalC, 
;ds = DATARES. All jumps to these points are made from only within this file
;and so we should be able to do this

	assume	ds:DATARES
;*** PrepareTransientMessages - load and initialize transient messages
;	ENTRY:	DS = resident data segment, BX = open COMMAND handle
;	EXIT:	Transient message state initialized
;	USES:	SI, flags; AX, BX, DX, DI, DS and ES preserved
;
MsgDiskCallback	EQU	34h
MsgCRLF		EQU	40h
MsgNumber	EQU	44h
MsgDivisor	EQU	48h
MsgBufferTerm	EQU	95h

	public	PrepareTransientMessages,SetupPrimaryMessageState
PrepareTransientMessages proc near
	push	ds
	push	ax
	push	bx
	push	dx
	push	es
	push	di
	mov	ds,TrnSeg
	push	ds
	pop	es
	call	ReadPrimaryResource
SetupPrimaryMessageState label near
	mov	ax,122Eh
	mov	dl,8
	int	2Fh
	mov	si,offset TRANGROUP:$M_RT
	mov	[si+MsgDiskCallback+2],es
	mov	[si+MsgDiskCallback],di
	mov	word ptr [si+MsgCRLF],0A0Dh
	mov	byte ptr [si+MsgBufferTerm],'$'
	mov	word ptr [si+MsgNumber],0
	mov	word ptr [si+MsgDivisor],10
	call	InitMessageCountry
	pop	di
	pop	es
	pop	dx
	pop	bx
	pop	ax
PrimaryMessageRestoreDS:
	pop	ds
	ret
PrimaryMessageError:
	add	sp,10			; discard saved registers
	stc
	jmp	short PrimaryMessageRestoreDS
PrepareTransientMessages endp

;*** ReadPrimaryResource - locate the primary message resource
;	ENTRY:	BX = open COMMAND file, DS = transient segment
;	EXIT:	Carry set on error; ES:DX addresses the resource directory
;	USES:	AX, CX, DX, SI, flags
;
	public	ReadPrimaryResource
ReadPrimaryResource proc near
	push	es
	xor	cx,cx
	mov	dx,cx
	mov	ax,LSEEK shl 8
	int	21h
	mov	cx,1Ah
	mov	ax,READ shl 8
	mov	dx,offset TRANGROUP:PrimaryResourceHeader
	int	21h
	jnc	short PrimaryCheckExe
PrimaryReadError:
	jmp	short PrimaryReadExit
PrimaryCheckExe:
	mov	si,offset TRANGROUP:PrimaryResourceHeader
	mov	ax,[si]
	cmp	ax,5A4Dh
	je	short PrimaryExe
	xor	cx,cx
	xor	dx,dx
	sub	dx,7
	sbb	cx,0
	mov	ax,(LSEEK shl 8) or 2
	int	21h
	mov	cx,7
	mov	ax,READ shl 8
	mov	dx,offset TRANGROUP:PrimaryResourceHeader
	int	21h
	jc	short PrimaryReadError
	cmp	word ptr [si+3],534Eh
	jne	short PrimaryReadError
	mov	ax,[si+5]
	jmp	short PrimaryFind
PrimaryExe:
	mov	ax,[si+6]
	shl	ax,1
	shl	ax,1
	add	ax,[si+24]
	cmp	ax,3Fh
	jbe	short PrimaryMinimum
	add	ax,0Fh
	mov	cx,4
	shr	ax,cl
	shl	ax,cl
	jmp	short PrimaryFind
PrimaryMinimum:
	mov	ax,40h
PrimaryFind:
	call	ReadPrimaryClass
	jc	short PrimaryReadExit
	call	InitPrimaryClassPointers
PrimaryReadExit:
	pop	es
	ret
ReadPrimaryResource endp

;*** ReadPrimaryClass - read the primary NSCO resource payload
;	ENTRY:	AX = file offset, BX = file handle, DS = transient segment
;	EXIT:	Carry set on error; ES:DX addresses the resource directory
;	USES:	AX, CX, DX, SI, flags
;
	public	ReadPrimaryClass
ReadPrimaryClass proc near
	xor	cx,cx
	mov	dx,ax
	push	cx
	push	dx
	mov	ax,LSEEK shl 8
	int	21h
	mov	cx,10h
	mov	ah,READ
	mov	dx,offset TRANGROUP:PrimaryResourceHeader
	int	21h
	jc	short PrimaryBadHeader
	cmp	ax,cx
	jne	short PrimaryBadHeader
	mov	si,offset TRANGROUP:PrimaryResourceHeader
	mov	ax,[si+11]
	cmp	ax,534Eh
	jne	short PrimaryBadHeader
	jmp	short PrimaryHeaderOK
PrimaryBadHeader:
	pop	dx
	pop	cx
	stc
	jmp	short PrimaryClassExit
PrimaryHeaderOK:
	pop	dx
	pop	cx
	push	bx
	mov	bx,[si+2]
	sub	bx,10h
	mov	ax,4200h
	sub	ax,bx
	pop	bx
	js	short PrimaryClassError
	mov	cx,[si]
	sub	cx,10h
	push	ds
	mov	ax,ds
	mov	es,ax
	mov	dx,offset TRANGROUP:PrimaryMsgDirectory
	mov	ah,READ
	int	21h
	pop	ds
	jc	short PrimaryClassError
PrimaryClassExit:
	ret
PrimaryClassError:
	stc
	jmp	short PrimaryClassExit
ReadPrimaryClass endp

;*** InitPrimaryClassPointers - initialize the message class table
;	ENTRY:	DS = ES = transient segment, DX = resource directory
;	EXIT:	Message class pointers initialized
;	USES:	AX, CX, DI, SI, flags; BX preserved
;
MsgExtClass	EQU	00h
MsgParseClass	EQU	14h
MsgCritClass	EQU	1Ch
MsgUtilClass	EQU	28h

	public	InitPrimaryClassPointers
InitPrimaryClassPointers proc near
	mov	di,dx
	mov	cl,es:[di]
	sub	cl,2
	inc	di
	mov	ax,es:[di]
	add	ax,di
	mov	si,offset TRANGROUP:$M_RT
	mov	[si+MsgExtClass],ax
	mov	[si+MsgExtClass+2],es
	mov	[si+MsgCritClass+2],es
	mov	[si+MsgCritClass],ax
	add	di,2
	mov	ax,es:[di]
	add	ax,di
	mov	[si+MsgParseClass+2],es
	mov	[si+MsgParseClass],ax
	mov	si,0
	push	bx
	mov	bx,offset TRANGROUP:$M_RT
ipcpNext:
	add	di,2
	mov	ax,es:[di]
	add	ax,di
	mov	[bx+si+MsgUtilClass],ax
	mov	[bx+si+MsgUtilClass+2],es
	add	si,4
	dec	cl
	jnz	short ipcpNext
	pop	bx
	ret
InitPrimaryClassPointers endp

;*** InitMessageCountry - initialize the transient country format
;	ENTRY:	DS = transient segment; direction flag clear
;	EXIT:	Country format and separators initialized when available
;	USES:	AX, BX, DX, flags; SI preserved
;
MsgDateFormat	EQU	4Ah
MsgThouSep	EQU	4Ch
MsgDeciSep	EQU	4Eh
MsgDateSep	EQU	50h
MsgTimeSep	EQU	52h
MsgTimeFormat	EQU	54h
MsgCountryBuffer EQU	55h

	public	InitMessageCountry
InitMessageCountry proc near
	mov	ah,INTERNATIONAL
	mov	al,0
	mov	dx,offset TRANGROUP:$M_RT + MsgCountryBuffer
	int	21h
	jc	short imcDone
	push	si
	mov	bx,offset TRANGROUP:$M_RT
	mov	si,dx
	lodsw
	mov	[bx+MsgDateFormat],ax
	add	si,5
	lodsw
	mov	[bx+MsgThouSep],ax
	lodsw
	mov	[bx+MsgDeciSep],ax
	lodsw
	mov	[bx+MsgDateSep],ax
	lodsw
	mov	[bx+MsgTimeSep],ax
	lodsw
	lodsb
	mov	[bx+MsgTimeFormat],al
	pop	si
imcDone:
	ret
InitMessageCountry endp

	assume	ds:DATARES
	public	BadMemEntry
BadMemEntry:
	pop	ds			; resident data segment from stub
	pop	dx			; discard saved data segment
BadMemErr:
	mov	dx,ResMsg128Ptr	; DX = ptr to msg
	public	FatalC
FatalC:

;;	push	cs
;;	pop	ds
;;	assume	ds:ResGroup
	invoke	RPrint

;	If this is NOT a permanent (top-level) COMMAND, then we exit;
;	we can't do anything else!

	cmp	PermCom,0
	je	FatalRet

;	We are a permanent command.  If we are in the process of the
;	magic interrupt (Singlecom) then exit too.

	cmp	SingleCom,0			; if permcom and singlecom
	jne	FatalRet			; must take int_2e exit

;	Permanent command.  We can't do ANYthing except halt.

	mov	dx,ResMsg129Ptr	; DX = ptr to msg
	invoke	RPrint
	sti
Stall:
	hlt
	jmp	Stall				; crash the system nicely

FatalRet:
	mov	dx,ResMsg130Ptr	; DX = ptr to msg
	invoke	RPrint
	public	FatalRet2
FatalRet2:
	cmp	word ptr Int_2e_Ret+2,0	; active int 2e caller?
	jne	Ret_2e

	mov	ax,Parent
	mov	word ptr ds:Pdb_Parent_Pid,ax
	mov	ax,word ptr OldTerm
	mov	word ptr ds:Pdb_Exit,ax
	mov	ax,word ptr OldTerm+2
	mov	word ptr ds:Pdb_Exit+2,ax
	mov	ax,(EXIT shl 8) 		; return to lower level
	push	ds
	pop	es
	push	ax
	push	ds
	lds	dx,Int2eHandler
	mov	ax,ds
	or	ax,dx
	jz	Restore2f
	mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 2Eh
	int	21h
Restore2f:
	lds	dx,es:Int2fHandler
	mov	ax,ds
	or	ax,dx
	jz	ExitCommand
	mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 2Fh
	int	21h
ExitCommand:
	pop	ds
	pop	ax
	mov	ah,EXIT
	int	21h

Ret_2e:
;SR;
; We will ensure that ds = DATARES for all entries to this place
;

;;	push	cs
;;	pop	ds
;;	assume	ds:resgroup,es:nothing,ss:nothing
  	
	assume	ds:DATARES

	mov	SingleCom,0		; turn off singlecom
	mov	es,Res_Tpa
	mov	ah,DEALLOC
	int	21h			; free up space used by transient
	mov	bx,Save_Pdb
	mov	ah,SET_CURRENT_PDB
	int	21h			; current process is user
	mov	ax,RetCode
	cmp	ExtCom,0
	jne	GotECode
	xor	ax,ax			; internals always return 0
GotECode:
	mov	ExtCom,1		; force external

;SR; This is actually returning to the caller. However, the old code had
;ds = RESGROUP so I guess we can keep ds = DATARES for us.
;Yes, int 2eh can corrupt all registers so we are ok.
;
	xor	ax,ax
	xchg	ax,word ptr Int_2e_Ret+2
	push	ax
	push	word ptr Int_2e_Ret
	retf




;***	Int_2e, magic command executer

Int_2e:
	assume	ds:NOTHING,es:NOTHING,ss:NOTHING
;SR;
; We are going to come here from the stub with the old ds and DATARES value
;pushed on the stack in that order. Pick up this stuff off the stack
;
	pop	ds			;ds = DATARES
	assume	ds:DATARES
	pop	ax
;	pop	ds:OldDS 		;Save old value of ds

	pop	word ptr Int_2e_Ret
	pop	word ptr [Int_2e_Ret+2] ; store return address
	;pop	ax			; chuck flags
	add	sp,2

;;	push	cs
;;	pop	es

	push	ds
	pop	es			;es = DATARES
;	mov	ds,OldDS
	mov	ds,ax
	assume	ds:nothing		;ds = old value

	mov	di,80h
	mov	cx,64
;	Bugbug:	cld
	rep	movsw
	mov	ah,GET_CURRENT_PDB
	int	21h			; get user's header
	mov	es:Save_Pdb,bx
	mov	ah,SET_CURRENT_PDB

;;	mov	bx,cs
;SR;
; Set ds = DATARES because BadMemErr expects this
;
	push	es
	pop	ds
	assume	ds:DATARES

	mov	bx,ds			;es = our PSP now

	int	21h			; current process is me
	mov	SingleCom,81h
	mov	ExtCom,1		; make sure this case forced

;SR;
; We can enter LodCom directly after a command shell is terminated or we
;can fall thru from above. When we enter directly from the stub, the stack
;has the old ds value and the data seg value on the stack, so that ds can
;be properly set. To fake this, we push dummy values here.
;
	push	ds			;old value of ds
	push	ds			;data seg value, ds = DATARES

LodCom: 					; termination handler
	pop	ds			;ds = DATARES 
	assume	ds:DATARES
	add	sp,2
;	pop	OldDS			;store old ds

	cmp	ExtCom,0
	jne	@f 		; internal cmd - memory allocated
	jmp	LodCom1
@@:
	mov	bx,0FFFFh
	mov	ah,ALLOC
	int	21h
	call	SetSize
	add	ax,62h			; workspace and reserve
	cmp	bx,ax
	jnc	MemOk			; > 512 byte buffer - good enough
	public	BadMemErrJ
BadMemErrJ:
	jmp BadMemErr			; not enough memory




;***	SetSize - get transient size in paragraphs

	public	SetSize
SetSize	proc
	assume	ds:DATARES,es:NOTHING
	mov	ax,CmdBufSize
	add	ax,ax
	add	ax,ax
	add	ax,CmdBufSize
	cmp	CmdBufSize,0FFh
	jbe	short SmallCommandBuffer
	add	ax,0FFh
	jmp	short SizeCommandBuffer
SmallCommandBuffer:
	add	ax,CmdBufSize
SizeCommandBuffer:
	add	ax,offset TRANGROUP:TranSpaceEnd + 19h
	mov	cl,4
	shr	ax,cl
	ret
SetSize	endp




	public	MemOk
MemOk:
	assume	ds:DATARES		;we have set ds = DATARES 

	mov	ah,ALLOC
	int	21h
	jc	BadMemErrJ		; memory arenas probably trashed
	push	bx
	push	es
	mov	bx,41h
	mov	es,ax
	mov	dx,ax
	mov	ah,SETBLOCK
	int	21h
	pop	es
	pop	bx
	jc	BadMemErrJ
	sub	bx,42h
	mov	ah,ALLOC
	int	21h
	jc	BadMemErrJ
	push	ax
	push	es
	mov	es,dx
	mov	ah,DEALLOC
	int	21h
	pop	es
	pop	ax
	mov	ExtCom,0		; flag not to alloc again
	mov	Res_Tpa,ax		; save current tpa segment
	and	ax, 0F000h
	add	ax, 01000h		; round up to next 64k boundary
	jc	Bad_Tpa 		; memory wrap if carry set

;	Make sure that new boundary is within allocated range

	mov	dx,Res_Tpa
	add	dx,bx			; compute maximum address
	cmp	dx,ax			; is 64k address out of range?
	jbe	Bad_Tpa

;	Must have 64K of usable space.

	sub	dx,ax			; compute the usable space
	cmp	dx,01000h		; is space >= 64k ?
	jae	LTpaSet
Bad_Tpa:
	mov	ax,Res_Tpa
LTpaSet:
	mov	LTpa,ax			; usable tpa is 64k buffer aligned
	mov	ax,Res_Tpa		; actual tpa is buffer allocated
	add	bx,ax
	mov	MemSiz,bx
	call	SetSize
	sub	bx,ax
;
;M038; Start of changes
; Changes for Novell RPL. These guys reserve memory for themselves by
;reducing int 12h size and add this memory to the system at autoexec time by
;running a program that changes arenas. This changes the largest block that
;command.com gets and so changes the transient segment. So, command.com does
;a checksum at the wrong address and thinks that the transient is destroyed
;and tries to reload it. At this point, no Comspec is defined and so the
;reload fails, hanging the system. To get around this we just copy the
;transient from the previous address to the new address(if changed) and
;then let command.com do the checksum. So, if the transient area is not
;corrupted, there will not be any reload. In Novell's case, the transient
;is not really corrupted and so this should work.
;
	public	MoveTransient
MoveTransient:
	cmp	bx,TrnSeg		;Segment still the same?
	je	LodCom1		;yes, dont copy
;
;Check if the new segment is above or below the current move. If the new
;segment is above(i.e new block is larger than previous block), then we
;have to move in the reverse direction
;
	pushf				; preserve segment comparison
	mov	cx,offset TRANGROUP:TranSpaceEnd
	mov	ax,CmdBufSize
	add	ax,ax
	add	ax,ax
	add	cx,ax			; include command buffers
	popf
	ja	mov_down		;new seg > old seg, reverse move
	xor	si,si			;normal move
	mov	di,si
	cld
	jmp	short copy_trans
mov_down:
	mov	si,cx			;reverse move, start from end
	dec	si
	mov	di,si
	std
copy_trans:
	push	ds
	push	es
	mov	es,bx			;dest segment
	mov	ds,TrnSeg		;source segment
	assume	ds:nothing

	rep	movsb			;copy transient
	cld
	pop	es
	pop	ds
	assume	ds:DATARES
;
;M038; End of changes
;

	mov	TrnSeg,bx		;new location of transient
LodCom1:
;;	mov	ax,cs
;;	mov	ss,ax
;SR; At this point ds = DATARES which is where the stack is located
;
	mov	ax,ds
	cli
	mov	ss,ax
	assume	ss:DATARES
	mov	sp,offset DATARES:RStack
	sti

;;	mov	ds,ax

	assume	ds:DATARES
	call	HeadFix 		; close files, restore stdin, stdout
	xor	bp,bp			; flag command ok
	mov	ax,-1
	xchg	ax,VerVal
	cmp	ax,-1
	je	NoSetVer
	mov	ah,SET_VERIFY_ON_WRITE	; AL has correct value
	int	21h
NoSetVer:
	cmp	SingleCom,-1
	jne	NoSng
	jmp	FatalRet2		; we have finished the single command
	public	NoSng
NoSng:
	call	ChkSum			; check the transient
	cmp	dx,Sum
	jne	short Bogus_Com
	cmp	SumHigh,0
	je	short Bogus_Com
	call	ChkPrimaryMessages
	cmp	dx,SumHigh
	je	short HavCom
Bogus_Com:
	mov	Loading,1		; flag DskErr routine
	call	LoadCom
	public	HavCom
HavCom:
	mov	es,TrnSeg
	mov	di,offset TRANGROUP:StackGuard
	mov	word ptr es:[di],55AAh	; transient stack boundary
	mov	Loading,0		; flag to DskErr
	mov	si,offset DATARES:TranVars
	mov	di,offset TRANGROUP:HeadCall
	cld
	mov	cx,offset DATARES:TranVarEnd
	sub	cx,si
	rep	movsb			; transfer info to transient
	mov	ax,MemSiz
	mov	word ptr ds:Pdb_Block_Len,ax	; adjust my own header

	public	InitTransientMessageState
InitTransientMessageState:
	push	di
	push	ds
	push	es
	mov	ax,TrnSeg
	mov	ds,ax
	assume	ds:TRANGROUP
	mov	es,ax
	mov	di,offset TRANGROUP:msg_disp_class
	xor	ax,ax
	mov	byte ptr [di],util_msg_class
	inc	di
	mov	byte ptr [di],no_cont_flag
	inc	di
	stosw
	stosb
	mov	byte ptr [di],parm_block_size
	inc	di
	stosb
	inc	di
	inc	di
	stosw
	stosb
	mov	byte ptr [di],10h	; ASCIIZ substitution
	inc	di
	mov	byte ptr [di],128
	inc	di
	stosb
	mov	byte ptr [di],blank
	mov	ax,offset TRANGROUP:String_ptr_2
	mov	Extend_Buf_off,ax
	assume	ds:DATARES
	pop	es
	pop	ds
	pop	di

;***	TJmp - jump-off to transient
;
;	Public label so debugger can find this spot.

TJmp:
	jmp	Trans




;***	TRemCheck - far version of RemCheck for transient

TRemCheck	proc	far

	pop	ds			;ds = DATARES
	add	sp,2			;discard old value of ds

	call	RemCheck
	ret

TRemCheck endp




;***	RemCheck
;
;	ENTRY	AL = drive (0=default, 1=A, ...)
;
;	EXIT	ZR set if removeable media
;		ZR clear if fixed media
;
;	USED	none

RemCheck:
	savereg	<ax,bx>
	mov	bx,ax
	mov	ax,(IOCTL shl 8) + 8
	int	21h
	jnc	rcCont			

;	If an error occurred, assume the media is non-removable.
;	AX contains the non-zero error code from the int 21, so
;	'or ax,ax; sets non-zero. This behavior makes network drives
;	appear to be non-removable.				
					
	or	ax,ax			
	jmp	short ResRegs
rcCont:
	and	ax,1
	not	ax
ResRegs:
	restorereg  <bx,ax>
	ret




;***	THeadFix
;
;	Far version of HeadFix, called from transient.

THeadFix	proc	far
	pop	ds			;ds = DATARES
	add	sp,2			;discard old ds value on stack

	call	HeadFix
	ret

THeadFix	endp




;***	HeadFix

	public	HeadFix
HeadFix:
	call	SetVect			; set vectors to our values

;	Clean up header

;	Bugbug:	optimize:
;	mov	word ptr ds:Pdb_Jfn_Table,cx  instead of separate bytes

	xor	bx,bx				; BX = handle = 0
	mov	cx,Io_Save			; CX = original stdin, stdout
	mov	dx,word ptr ds:Pdb_Jfn_Table	; DX = current stdin, stdout
	cmp	cl,dl
	je	Chk1			; stdin matches
	mov	ah,CLOSE
	int	21h			; close stdin
	mov	ds:Pdb_Jfn_Table,cl	; restore stdin
Chk1:
	inc	bx			; BX = handle = 1
	cmp	ch,dh			
	je	ChkOtherHand		; stdout matches
	mov	ah,CLOSE
	int	21h			; close stdout
	mov	ds:Pdb_Jfn_Table+1,ch	; restore stdout

ChkOtherHand:
	add	bx,4			; skip handles 2,3,4
	mov	cx,FILPERPROC - 5	; CX = # handles to close
					;   (handles 0-4 already done)
CloseLoop:
	mov	ah,CLOSE
	int	21h			; close each handle
	inc	bx			; BX = next handle
	loop	CloseLoop

;	Bugbug:	since this is for transient code, move it there

;	M012: remove this CS -> DS.  Must've been missed during
;	purification.
;;	push	ds			; save data segment
;;	push	cs			; get local segment into DS
;;	pop	ds			;
	cmp	Append_Flag,-1		; do we need to reset APPEND?
	jne	Append_Fix_End		; no - just exit
	mov	ax,AppendSetState	; set the state of Append
	mov	bx,Append_State 	;     back to the original state
	int	2Fh			;
	mov	Append_Flag,0		; set append flag to invalid
Append_Fix_End: 			;
;;	pop	ds			; get data segment back
	ret




;***	SavHand - save current program's stdin/out & set to our stderr
;
;	ENTRY	nothing
;
;	EXIT	nothing
;
;	USED	flags
;
;	EFFECTS
;	  Handle01 = current program's stdin,stdout JFN entries
;	  current program's stdin,stdout set to our stderr
;

;SR;
; Changed ds = DATARES. We need it to access our JFN_Table
; Called from ContC ( ds = DATARES ) and DskErr ( ds = DATARES ).
;
SavHand	proc

	assume	ds:DATARES,es:NOTHING,ss:NOTHING

	push	bx			;preserve registers
	push	ax
	push	es
	push	ds			; save DATARES value

	mov	ah,GET_CURRENT_PDB
	int	21h			; BX = user's header seg addr
	mov	ds,bx			; DS = user's header seg addr
	lds	bx,ds:PDB_JFN_POINTER	; DS:BX = ptr to JFN table
	mov	ax,word ptr ds:[bx]	; AX = stdin,stdout JFN's

	pop	es			;es = DATARES
	push	es			;save it back on stack
	mov	es:Handle01,ax		; save user's stdin, stdout

;SR;
; Use es to address Handle01 & our JFN_Table
;

	mov	al,es:[PDB_JFN_TABLE+2] ; AL = COMMAND stderr
	mov	ah,al			; AH = COMMAND stderr
	mov	word ptr ds:[bx],ax	; set user's stdin/out to our stderr

	pop	ds			; restore registers
	pop	es
	pop	ax
	pop	bx
	ret

SavHand	endp




	assume	ds:DATARES

RestHand:
	push	ds
	push	bx			; restore stdin, stdout to user
	push	ax
	mov	ah,GET_CURRENT_PDB
	int	21h			; point to user's header
	mov	ax,Handle01
	mov	ds,bx
	assume ds:NOTHING
	lds	bx,ds:Pdb_Jfn_Pointer	; DS:BX = ptr to jfn table
	mov	word ptr ds:[bx],ax	; stuff his old 0 and 1
	pop	ax
	pop	bx
	pop	ds
	ret




	assume ds:DATARES,ss:DATARES

;*** GetReloadPath - read a replacement COMMAND pathname
; Returns DS:DX pointing to the null-terminated name.

	public	GetReloadPath
GetReloadPath:
	push	si
	lea	si,SafePathBuffer
	mov	dx,si
	mov	byte ptr [si],0FDh
	inc	si
	xor	al,al
	mov	[si],al
	inc	si
	mov	ah,STD_CON_INPUT_FLUSH
	int	21h
	mov	ah,STD_CON_STRING_INPUT
	int	21h
	call	Crlf
	mov	dx,si
	xor	ax,ax
	add	al,[si-1]
	add	si,ax
	mov	[si],ah
	pop	si
	ret


;***	LoadCom - load in transient

LoadCom:
	assume	ds:DATARES
ifndef	ROMDOS
	mov	dx,offset DATARES:ComSpec
	call	TryLoadCom
	jc	short TryOriginalComSpec
	jz	short LoadComDone
TryOriginalComSpec:
	mov	dx,offset DATARES:OriginalComSpec
	call	TryLoadCom
	jc	short TryBootComSpec
	jz	short LoadComDone
TryBootComSpec:
	mov	ax,(SET_CTRL_C_TRAPPING shl 8) or 5		; get boot drive
	int	21h
	dec	dl
	add	dl,'A'
	mov	BootComSpec,dl
	mov	dx,offset DATARES:BootComSpec
	call	TryLoadCom
	jc	short PromptForCommand
	jz	short LoadComDone
PromptForCommand:
	mov	dx,ResMsg118Ptr
	invoke	RPrint
	mov	dx,ResMsg119Ptr
	invoke	RPrint
	call	GetReloadPath
	call	TryLoadCom
	jc	short PromptForCommand
	jnz	short PromptForCommand
	public	LoadComDone
LoadComDone:
	ret

; Try one pathname.  Carry indicates an I/O error; zero indicates a
; matching transient checksum when carry is clear.
	public	TryLoadCom
TryLoadCom:
	or	byte ptr YSwitchFlags,2
	inc	bp				; flag command read
	mov	ax,(OPEN shl 8) + 20h	; deny write sharing
	int	21h
	jnc	ReadCom
	cmp	ax,ERROR_TOO_MANY_OPEN_FILES
	jnz	LoadComReturn
	mov	dx,offset DATARES:ResMsg125Ptr
	jmp	FatalC

ReadCom:
	mov	bx,ax				; BX = handle
;	Read the executable header size and seek to the transient image.
;	The MZ header includes the message resources.
;
	mov	dx,8				; e_cparhdr
	xor	cx,cx
	mov	ax,LSEEK shl 8
	int	21h
	jc	WrongCom1
	mov	dx,offset DATARES:ExeHeaderParas
	mov	cx,2
	mov	ah,READ
	int	21h
	jc	WrongCom1
	cmp	ax,cx
	jne	WrongCom1
	mov	dx,ExeHeaderParas
	mov	cl,4
	shl	dx,cl
	add	dx,offset RESGROUP:TranStart + 100h	; file image before relocation
	xor	cx,cx
	mov	ax,LSEEK shl 8
	int	21h
	jc	WrongCom1
	mov	cx,offset TRANGROUP:TranSpaceEnd - 100h

	push	ds
	mov	ds,TrnSeg
	assume	ds:NOTHING
	mov	dx,100h
	mov	ah,READ
	int	21h
	pop	ds
	assume	ds:DATARES
	public	ReadComEnd
ReadComEnd:
	jc	short WrongCom1
	cmp	ax,cx
	jne	short WrongCom1
	call	ChkSum
	cmp	dx,Sum
	clc
	jne	short CloseComJump
	pushf
	call	PrepareTransientMessages
	popf
CloseComJump:
	jmp	short CloseCom
WrongCom1:
	stc
CloseCom:
	pushf
	push	ax
	mov	ah,CLOSE
	int	21h			; close command.com
	pop	ax
	popf
	public	LoadComReturn
LoadComReturn:
	ret

else	;ROMDOS

	push	si			; preserve registers
	push	di
	push	es

	mov	si,offset RESGROUP:TranStart
					; SI = offset in image
	mov	es,TrnSeg
	mov	di,100h			; ES:DI = ptr to destination

	mov	cx,offset TRANGROUP:TranSpaceEnd-100h
					; CX = size of transient image
	invoke	LoadFromROM		; copy transient to RAM

	pop	es			; restore registers
	pop	di
	pop	si
	ret

;;	mov	dx,80h			; DS:DX = ptr to desired DTA
;;					;   Ok to use command tail buffer?
;;	mov	ah,SET_DMA		; AH = 'Set DTA Address'
;;	int	21h
;;
;;;	Bugbug:  Are we screwing anybody up by setting DTA here?
;;
;;	mov	dx,offset RESGROUP:ComSpec	; DS:DX = ptr to "COMMAND",0
;;	mov	ah,ROM_FIND_FIRST		; AH = 'ROM Find First'
;;	int	21h
;;	jc	WrongCom			; couldn't find our image
;;
;;;	Relevant DTA contents:
;;;	  Offset 15 = segment address of ROM header
;;;
;;;	We're going to be stupid right now, and just know that
;;;	the command.com image is at offset 30h in the ROM.
;;
;;	push	si			; save registers
;;	push	di
;;	push	ds
;;	push	es
;;
;;	mov	ds,ds:80h+15		; DS = ROM seg addr
;;	assume	ds:NOTHING
;;	mov	si,30h+offset RESGROUP:TranStart
;;					; DS:SI = ptr to transient in ROM
;;	mov	es,TrnSeg
;;	mov	di,100h			; ES:DI = ptr to transient destination
;;
;;	mov	cx,offset TRANGROUP:TranSpaceEnd - 100h
;;					; CX = size of transient image
;;	cld
;;	rep	movsb			; copy transient to RAM
;;
;;	pop	es			; restore registers
;;	pop	ds
;;	assume	ds:DATARES
;;	pop	di
;;	pop	si
;;	ret

WrongCom:
	mov	dx,ResMsg118Ptr		; DX = ptr to error message
	jmp	FatalC				; print message and give up

endif	;ROMDOS



;***	ChkSum - compute transient checksum

ChkSum:
	mov	si,100h
	mov	cx,offset TRANGROUP:TranDataEnd - 100H
	xor	dx,dx
ChkMessageBlock proc near
	push	ds
	mov	ds,TrnSeg
	cld
	shr	cx,1
cmbNext:
	lodsw
	add	dx,ax
	adc	dx,0
	loop	cmbNext
	pop	ds
	ret
ChkMessageBlock endp

ChkPrimaryMessages proc near
	xor	dx,dx
	mov	si,offset TRANGROUP:$M_RT
	mov	cx,3Ch
	call	ChkMessageBlock
	mov	si,offset TRANGROUP:PrimaryMsgDirectory
	mov	cx,offset TRANGROUP:PrimaryMsgChecksumEnd
	sub	cx,si
	call	ChkMessageBlock
	ret
ChkPrimaryMessages endp



;***	SetVect - set interrupt vectors

SetVect:
	mov	dx,offset DATARES:LodCom_Trap
	mov	word ptr ds:Pdb_Exit+2,ds
	mov	word ptr ds:Pdb_Exit,dx
	mov	ax,(SET_INTERRUPT_VECTOR shl 8) or 22h
	int	21h
	mov	dx,offset DATARES:Ctrlc_Trap
	inc	al
	int	21h
	mov	dx,offset DATARES:CritErr_Trap
	inc	al
	int	21h
	ret

;SR;
; We have this to take care of the extra values pushed on the stack by 
;the stub before jumping to LodCom1. We set up ds here and then jump to
;Lodcom1
;
public	TrnLodCom1
TrnLodCom1:
	pop	ds			;ds = DATARES
	add	sp,2
;	pop	ds:OldDS
	jmp	LodCom1




;***	EndInit - end up initialization sequence
;
;	Move the environment to a newly allocated segment.

;;EndInit:
;;	push	ds			; save segments
;;	push	es			;
;;	push	cs			; get resident segment to DS
;;	pop	ds			;
;;	assume	ds:RESGROUP
;;	mov	cx,UsedEnv		; get number of bytes to move
;;	mov	es,EnvirSeg		; get target environment segment
;;	assume	es:NOTHING
;;
;;	mov	ds:Pdb_Environ,es	; put new environment in my header
;;	mov	ds,OldEnv		; source environment segment
;;	assume	ds:NOTHING
;;	xor	si,si			; set up offsets to start of segments
;;	xor	di,di
;;	cld
;;	rep	movsb			; move it
;;	xor	ax,ax
;;	stosb				; make sure it ends with double-null
;;
;;	cmp	ResetEnv,1		; do we need to setblock to env end?
;;	jne	NoReset 		; no - we already did it
;;	mov	bx,EnvSiz		; BX = size of environ in paragraphs
;;	push	es			; save environment - just to be sure
;;	mov	ah,SETBLOCK		;
;;	int	21h
;;	pop	es
;;
;;NoReset:
;;	mov	InitFlag,FALSE		; turn off init flag
;;	pop	es
;;	pop	ds
;;	jmp	LodCom			; allocate transient

;
;The init code has been changed to take care of the new way in which the
;environment segment is allocated.
;NB: We can use all the init variables at this point because they are all in
;RESGROUP
;Bugbug: The above approach will not work for ROMDOS
;

IF 0

EndInit:
	push	ds
	push	es			;save segments
	push	cs
	pop	ds		
	assume	ds:RESGROUP
;
; AllocedEnv flag signals whether it is a passed environment or not
;
	mov	bx,ds
	mov	es,bx			;es = RESGROUP
;
;ResSize is the actual size to be retained -- only data for HIMEM COMMAND, 
; code + data for low COMMAND
;
	mov	bx,ResSize		;Total size of resident
	mov	ah,SETBLOCK
	int	21h			;Set block to resident size
;
;Allocate the correct size for the environment
;
	mov	bx,EnvSiz		;bx = env size in paras
	mov	ah,ALLOC
	int	21h			;get memory
	jc	nomem_err		;out of memory,signal error

	mov	EnvirSeg,ax		;Store new environment segment
	mov	ds:PDB_Environ,ax		;Put new env seg in PSP
	mov	es,ax			;es = address of allocated memory
	assume	es:nothing

;
;Copy the environment to the newly allocated segment
;
	mov	cx,UsedEnv		;number of bytes to move

	push	ds
	mov	ds,OldEnv		;ds = Old environment segment
	assume	ds:nothing

	xor	si,si
	mov	di,si			;Start transfer from 0

	cld
	rep	movsb			;Do the copy

	xor	ax,ax			
	stosb				;Make it end with double-null

	pop	ds			;ds = RESGROUP
	assume	ds:RESGROUP
;
;We have to free the old environment block if it was allocated by INIT
;
        cmp     AllocedEnv,0            ;has env been allocated by INIT?
        je      no_free                 ;no, do not free it

	mov	ax,OldEnv		;Get old environment
	mov	es,ax
	mov	ah,DEALLOC	
	int	21h			;Free it
no_free:
	mov	InitFlag,FALSE		;indicate INIT is done
	
	pop	es
	pop	ds
	assume	ds:nothing
	
	jmp	LodCom			;allocate transient

nomem_err:
;
;We call the error routine which will never return. It will either exit
;with an error ( if not the first COMMAND ) or just hang after an error 
;message ( if first COMMAND )
;

	call	Alloc_error
ENDIF

;*** ReleaseInit -- Release the original initialization allocation.
;
;	ENTRY:	cs = resident data segment
;		es = owner of the original allocation
;
;	EXIT:	Original allocation and environment released, if present.
;
;	USED:	ax, bx, ds, flags
;
	public	ReleaseInit
ReleaseInit	proc	far
	assume	cs:CODERES,ds:nothing,es:nothing

	push	cs
	pop	ds
	assume	ds:DATARES
	mov	bx,OriginalDataSeg
	test	bx,bx
	jz	riDone
	push	es
	dec	bx			; address of original arena
	push	bx
	push	es
	pop	bx			; new arena owner
	pop	es
	mov	es:[1],bx
	mov	bx,10h			; original PSP
	mov	byte ptr es:[bx],0CFh	; IRET for the old interrupt entry
	add	bx,6
	mov	ax,word ptr Int2fHandler
	mov	es:[bx],ax
	mov	ax,word ptr Int2fHandler+2
	mov	es:[bx+2],ax
	mov	es,EnvirSeg
	mov	ah,DEALLOC
	int	21h
	push	ds
	pop	es
	mov	ah,DEALLOC
	int	21h
	pop	es
riDone:
	ret
ReleaseInit	endp

CODERES ends



;	This TAIL segment is used to produce a PARA aligned label in
;	the resident group which is the location where the transient
;	segments will be loaded initial.

TAIL		segment public para

		org	0
TranStart	label	word
		public	TranStart

TAIL		ends



;	This TAIL segment is used to produce a PARA aligned label in
;	the transient group which is the location where the exec
;	segments will be loaded initial.
;
;	Bugbug:	Is TRANTAIL used anymore?

TRANTAIL	segment public para

		org	0
ExecStart   	label   word

TRANTAIL    	ends

		end

