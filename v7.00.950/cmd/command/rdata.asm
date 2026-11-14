	page ,132
	title	COMMAND Resident DATA
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;
;	Revision History
;	================
;	M003	SR	07/16/90	Added LoadHiFlg for LoadHigh support
;
;	M004	SR	07/17/90	Transient is now moved to its final
;				location at EndInit time by allocating
;				the largest available block, moving 
;				the transient to the top of the block
;				and then freeing up the block.
;
;	M027	SR	9/20/90	Fixed bug #2827. EndInit was using
;				INIT seg variables after INIT seg
;				had been freed.
;
;	M036	SR	11/1/90	Free up environment segment passed
;				by Exec always.
;
;	t-richj		5-20-92 Removed LoadHiFlg

.xlist
.xcref
	include dossym.inc
	include pdb.inc
	include syscall.inc
	include comsw.asm
	include comseg.asm
	include	resmsg.equ
	include comequ.asm
.list
.cref

;	Equates for initialization (from COMEQU)
;
;	Bugbug:  Toss these after putting ctrl-c handler in init module.

INITINIT    equ     01h 		; initialization in progress
INITSPECIAL equ     02h 		; in initialization time/date routine
INITCTRLC   equ     04h 		; already in ^C handler


CODERES segment public byte
	extrn	Ext_Exec:near
	extrn	MsgRetriever:far
	extrn	TRemCheck:near

;SR;
; The stack has no right to be in the code segment. Moved it to DATARES
;
;	bugbug:	Why this odd stack size?  And what should stack size be?
;;	db	(80h - 3) dup (?)
;;RStack	label	word
;;	public	RStack
CODERES ends

INIT	segment

	extrn	ConProc:near
        extrn   AllocedEnv:byte
	extrn	UsedEnv:word
	extrn	OldEnv:word
	extrn	TrnSize:word		; M004

INIT	ends

TAIL	segment

	extrn	TranStart	:word

TAIL	ends

TRANCODE	segment public byte
	extrn	Command:near
TRANCODE	ends

TRANSPACE	segment

	extrn	TranSpaceEnd	:byte

TRANSPACE	ends

;SR;
; All the routines below are entry points into the stub from the transient.
;The stub will then transfer control to the appropriate routines in the
;resident code segment, wherever it is present.
;

DATARES	segment

	extrn	Exec_Trap	:near
	extrn	RemCheck_Trap	:near
	extrn	MsgRetrv_Trap	:near
	extrn	HeadFix_Trap	:near
	extrn	Issue_Exec_Call	:near

DATARES	ends


DATARES segment public byte
	assume	cs:DATARES
	Org	0
ZERO	=	$

;;	Org	100h
;;ProgStart:
;;	jmp	RESGROUP:ConProc
	public	Append_Flag
	public	Append_State
	public	BadFatSubst
	public	Batch
	public	Batch_Abort
	public	BlkDevErrRw
	public	BlkDevErrSubst
	public	Call_Batch_Flag
	public	CopyNonInteractive
	public	Call_Flag
	public	CDevAt
	public	CharDevErrSubst
	public	CharDevErrRw
	public	Com_Fcb1
	public	Com_Fcb2
	public	Com_Ptr
	public	ComDrv
	public	ComSpec
	public	ComSpec_End
	public	Crit_Err_Info
	public	Crit_Msg_Off
	public	Crit_Msg_Seg
	public	CritMsgPtrs
	public	DataResEnd
	public	Dbcs_Vector_Addr
	public	DevName
	public	DrvLet
	public	EchoFlag
	public	EnvirSeg
	public	ErrCd_24
	public	ErrType
	public	Exec_block
	public	ExecErrSubst
	public	Extcom
	public	ExtMsgEnd
	public	fFail
	public	ForFlag
	public	ForPtr
	public	FUCase_Addr
	public	Handle01
	public	IfFlag
	public	In_Batch
	public	InitFlag
	public	InPipePtr
	public	Int_2e_Ret
	public	Int2fHandler
	public	Io_Save
	public	LenMsgOrPathBuf
	public	Loading
	public	LTpa
	public	MemSiz
	public	MsgBuffer
	public	MsgPtrLists
	public	MySeg
	public	MySeg1
	public	MySeg2
	public	MySeg3
	public	NeedVol
	public	NeedVolSubst
	public	Nest
	public	Next_Batch
	public	NullFlag
	public	NUMEXTMSGS
	public	NUMPARSMSGS
	public	OldErrNo
	public	OldTerm
	public	OutPipePtr
	public	Parent
	public	ParsMsgPtrs
	public	PermCom
        public  SemiPermCom
	public	Pipe1
;;;	public	Pipe1T
	public	Pipe2
;;;	public	Pipe2T
	public	PipeFiles
	public	PipeFlag
	public	PipePtr
	public	PutBackComSpec
	public	PutBackDrv
	public	PutBackSubst
	public	RDirChar
	public	Re_Out_App
	public	Re_OutStr
	public	ResMsgEnd
	public	Res_Tpa
	public	RestDir
	public	ResTest
	public	RetCode
	public	RSwitChar
	public	SafePathBuffer		; MSKK01 07/14/89
	public	Save_Pdb
	public	SingleCom
	public	Sum
	public	Suppress
	public	Trans
	public	TranVarEnd
	public	TranVars
	public	TrnSeg
	public	TrnMvFlg
	public	VerVal
	public	VolName
	public	VolSer
	public	YSwitchFlags

	public	ResSize
	public	RStack
	public	OldDS

;	public	LoadHiFlg		;For LoadHigh support ; M003

	extrn	LodCom_Trap:near
	extrn	BadMem_Trap:near
	extrn	Alloc_error:near

ifdef ROMDOS

	include	command.loc

ifdef COMMAND_LO

;	COMMAND image is in extended address space.

;	Global Descriptor Table (GDT) for use with int 15h block move

Int15GDT	db	10h dup (0)		; reserved zero
gdtSrcLen	dw	COMMAND_SIZ		; src segment length
gdtSrcLo	dw	COMMAND_LO		; low 16 bits of src address
gdtSrcHi	db	COMMAND_HI		; high 8 bits of src address
		db	93h			; access rights byte
		db	2 dup (0)		; reserved zero
gdtDstLen	dw	COMMAND_SIZ		; dst segment length
gdtDstLo	dw	?			; low 16 bits of dst address
gdtDstHi	db	?			; high 8 bits of dst address
		db	93h			; access rights byte
		db	12h dup (0)		; reserved zero

	public	Int15GDT,gdtSrcLen,gdtSrcLo,gdtSrcHi
	public	gdtDstLen,gdtDstLo,gdtDstHi

endif
endif ; ROMDOS



;***	Message substitution blocks


CopyNonInteractive dw	0		; nonzero for noninteractive command

BlkDevErrSubst	label	byte
BlkDevErrRw	subst	<STRING,>		; "reading" or "writing"
		subst	<CHAR,DATARES:DrvLet>	; block device drive letter

DrvLet		db	'A'			; drive letter


CharDevErrSubst	label	byte
CharDevErrRw	subst	<STRING,>		  ; "reading" or "writing"
CharDevErrDev	subst	<STRING,DATARES:DevName> ; character device name

DevName		db	8 dup (?),0		  ; device name, asciiz


NeedVolSubst	label	byte
		subst	<STRING,DATARES:VolName>	; volume name
		subst	<HEX,DATARES:VolSer+2>		; hi word of serial #
		subst	<HEX,DATARES:VolSer>		; lo word of serial #

;		NOTE:	VolName and VolSer must be adjacent
VolName		db	11 dup (?),0		; volume name
VolSer		dd	0			; volume serial #


CDevAt		db	?


BadFatSubst	label	byte
		subst	<CHAR,DATARES:DrvLet>	; drive letter


PutBackSubst	label	byte
PutBackComSpec	subst	<STRING,>			; comspec string
		subst	<CHAR,DATARES:PutBackDrv>	; drive to put it in

PutBackDrv	db	' '			; drive letter


ExecErrSubst	subst	<STRING,DATARES:SafePathBuffer>


NeedVol		dd	?	; ptr to volume name from get ext err
ErrType 	db	?	; critical error message style, 0=old, 1=new

Int_2e_Ret	dd	?	; magic command executer return address
Save_Pdb	dw	?
Parent		dw	?
OldTerm 	dd	?
ErrCd_24	dw	?
Handle01	dw	?
Loading 	db	0
Batch		dw	0	; assume no batch mode initially

;;;;SR;
;;;; This flag has been added for a gross hack introduced in batch processing. 
;;;;We use it to indicate that this batch file has no CR-LF before EOF and that
;;;;we need to fake the CR-LF for the line to be properly processed
;;;;
;;;BatchEOF		db	0

;		Bugbug:	ComSpec should be 64+3+12+1?
;		What's this comspec_end about?
ComSpec 	db	64 dup (0)
ComSpec_End	dw	?
        public  ComSpecName
ComSpecName     dw      ?       ; filename within COMSPEC

	public	BootComSpec
BootComSpec	db	"A:\COMMAND.COM",0	; command on boot drive

Trans		label	dword
		dw	TRANGROUP:Command
TrnSeg		dw	?

TrnMvFlg	db	0	; set if transient portion has been moved

In_Batch	db	0	; set if we are in batch processing mode
Batch_Abort	db	0	; set if user wants to abort from batch mode

ComDrv		db	?	; drive spec to load autoexec and command
MemSiz		dw	?
Sum		dw	?
        public  SumHigh
SumHigh         dw      ?       ; high word of transient checksum
ExtCom		db	1	; for init, pretend just did an external
Crit_Err_Info	db	?	; hold critical error flags for r,i,f


; The echo flag needs to be pushed and popped around pipes and batch files.
; We implement this as a bit queue that is shr/shl for push and pop.

EchoFlag	db	00000001b	; low bit true => echo commands
Suppress	db	1		; used for echo, 1=echo line
Io_Save 	dw	?
RestDir 	db	0
PermCom 	db	0		; true => permanent command
SemiPermCom     db      0               ; single-command mode flags
SingleCom	dd	0		; address of single command line
VerVal		dw	-1
fFail		db	0		; true => fail all int 24s
IfFlag		db	0		; true => IF statement in progress

ForFlag 	db	0		; true => FOR statement in progress
ForPtr		dw	0

Nest		dw	0		; nested batch file counter
Call_Flag	db	0		; no CALL (batch command) in progress
Call_Batch_Flag db	0
Next_Batch	dw	0		; address of next batch segment
NullFlag	db	0		; flag if no command on command line
FUCase_Addr	db	5 dup (0)	; buffer for file ucase address
; Bugbug: don't need crit_msg_ anymore?
Crit_Msg_Off	dw	0		; saved critical error message offset
Crit_Msg_Seg	dw	0		; saved critical error message segment
Dbcs_Vector_Addr dw	0		; DBCS vector offset
		 dw	0		; DBCS vector segment

Append_State	dw	0		; current state of append
					;  (if Append_Flag is set)
Append_Flag	db	0		; set if append state is valid

Re_Out_App	db	0

	public	ResidentDataSeg, OriginalDataSeg
ResidentDataSeg	dw	0		; relocated resident data segment
OriginalDataSeg	dw	0		; original resident data segment
	public	LFNForFlag
LFNForFlag	db	0		; long names in FOR expansion




; We flag the state of COMMAND in order to correctly handle the ^Cs at
; various times.  Here is the breakdown:
;
;   INITINIT	We are in the init code.
;   INITSPECIAL We are in the date/time prompt
;   INITCTRLC	We are handling a ^C already.
;
; If we get a ^C in the initialization but not in the date/time prompt, we
; ignore the ^C.  This is so the system calls work on nested commands.
;
; If we are in the date/time prompt at initialization, we stuff the user's
; input buffer with a CR to pretend an empty response.
;
; If we are already handling a ^C, we set the carry bit and return to the user
; (ourselves).	We can then detect the carry set and properly retry the
; operation.

InitFlag	db	INITINIT

; Note:  these two bytes are referenced as a word
PipeFlag	db	0
PipeFiles	db	0

;--- 2.x data for piping
;
; All the "_" are substituted later, the one before the : is substituted
; by the current drive, and the others by the CreateTemp call with the
; unique file name. Note that the first 0 is the first char of the pipe
; name. -MU
;
;--- Order-dependent, do not change

;;;Pipe1		db	"_:/"
;;;Pipe1T		db	0
;;;		db	"_______.___",0
;;;Pipe2		db	"_:/"
;;;Pipe2T		db	0
;;;		db	"_______.___",0

;SR
; Pipe1 & Pipe2 now need to store full-fledged pathnames
;

; Bugbug:  can we find any way around maintaining these
; large buffers?

	public	InitStubSegment, OriginalComSpec
InitStubSegment label word		; reused after initialization
Pipe1		db	67+12 dup (?)
Pipe2		db	67+12 dup (?)

PipePtr 	dd	0		; offset and segment of allocated pipe text

Re_OutStr	db	260 dup (?)	; redirection pathname
;*		NOTE:  MsgBuffer and SafePathBuffer use the same
;		memory.  MsgBuffer is only used while a command
;		is being executed.  SafePathBuffer is no longer
;		needed, since it is used for unsuccessful program
;		launches.




MsgBuffer	label	byte
SafePathBuffer	label	byte
		db	260 dup (?)	; pathname for EXEC
LenMsgOrPathBuf	equ	$ - MsgBuffer

EndPipe	label	byte			; marks end of buffers; M004

;SR;
; We can move our EndInit code into above buffers. This way, the code will
;automatically be discarded after init.
;
; M004; We overlap our code with the Pipe buffers located above by changing
; M004; the origin.
;
	ORG	Pipe1+2			; preserve initialization stub segment

; Bugbug:  really need a procedure header for EndInit, describing
; what it expects, what it does.

	assume	ds:RESGROUP

Public	EndInit
EndInit:
	push	cs
	pop	es
	mov	di,offset DATARES:OriginalComSpec
	cmp	byte ptr es:[di],0
	jne	eiPathReady
	mov	si,offset DATARES:ComSpec
	push	cs
	pop	ds
eiCopyPath:
	lodsb
	stosb
	or	al,al
	jnz	eiCopyPath
eiPathReady:
	mov	ax,cs:OriginalDataSeg
	mov	ds,ax
	mov	dx,TrnSize
	push	UsedEnv
	push	OldEnv
	mov	bx,cs
	mov	ds,bx
	mov	es,bx
	cmp	bx,OriginalDataSeg
	je	eiResize
	mov	es,OriginalDataSeg
	mov	ah,DEALLOC
	int	21h
	jmp	short eiEnvironment
eiResize:
	mov	es,bx
	mov	bx,ResSize
	mov	ah,SETBLOCK
	int	21h
eiEnvironment:
	pop	cx
	push	cx
	mov	ax,word ptr ds:PDB_Environ
	cmp	ax,cx
	je	eiTopStub
	call	FreeInitEnv
eiTopStub:
	test	PermCom,2
	jz	eiStrategy
	mov	ah,ALLOC
	mov	bx,1
	int	21h
	push	ds
	mov	InitStubSegment,ax
	mov	es,ax
	dec	ax
	mov	ds,ax
	xor	si,si
	mov	word ptr [si+8],4F43h
	mov	word ptr [si+10],4D4Dh
	mov	word ptr [si+12],4E41h
	mov	word ptr [si+14],0044h
	mov	ds,si
	cld
	mov	al,0EAh
	xor	di,di
	mov	si,2Eh*4
	cli
	call	CopyInitVector
	call	CopyInitVector
	sti
	pop	ds
eiStrategy:
	mov	bx,81h
	test	PermCom,2
	jz	eiSetStrategy
	mov	bl,1
eiSetStrategy:
	mov	ax,(ALLOCOPER shl 8) or 1
	int	21h
	cmp	PermCom,0
	je	adjust_env
	cmp	Batch,0
	je	adjust_env
	mov	bx,4
	mov	ah,ALLOC
	int	21h
	jc	adjust_env
	mov	es,ax
	xor	di,di
	mov	si,di
	push	ds
	mov	ds,Batch
	mov	cx,SIZE BatchSegment+16
	cld
	rep	movsb
	pop	ds
	mov	cx,es
	mov	es,Batch
	mov	ah,DEALLOC
	int	21h
	mov	Batch,cx
adjust_env:
	pop	bp
	pop	cx
	mov	ax,cs
	cmp	ax,OriginalDataSeg
	jne	eiAllocateEnv
	cmp	bp,word ptr ds:PDB_Environ
	jne	eiAllocateEnv
eiResizeEnv:
	mov	bx,EnvSiz
	mov	es,word ptr ds:PDB_Environ
	mov	ah,SETBLOCK
	int	21h
	jnc	eiEnvReady
eiAllocateEnv:
	mov	bx,EnvSiz
	mov	ah,ALLOC
	int	21h
	jnc	eiCheckEnv
	jmp	nomem_err
eiCheckEnv:
	cmp	ax,0A000h
	jae	eiCopyEnv
	mov	bx,cs
	cmp	ax,bx
	jb	eiAdjacent
	test	PermCom,2
	jnz	eiCopyEnv
eiAdjacent:
	mov	bx,word ptr ds:PDB_Environ
	cmp	bp,bx
	jne	eiCopyEnv
	dec	bx
	mov	es,bx
	add	bx,es:[3]
	inc	bx
	inc	bx
	cmp	ax,bx
	je	eiRetryResize
	push	ax
	mov	bx,EnvSiz
	mov	es,word ptr ds:PDB_Environ
	mov	ah,SETBLOCK
	int	21h
	pop	ax
	jc	eiCopyEnv
	mov	es,ax
	mov	ah,DEALLOC
	int	21h
	mov	es,word ptr ds:PDB_Environ
	jmp	short eiEnvReady
eiRetryResize:
	mov	es,ax
	mov	ah,DEALLOC
	int	21h
	jmp	short eiResizeEnv
eiCopyEnv:
	mov	es,ax
	push	ds
	mov	ds,bp
	xor	si,si
	mov	di,si
	cld
	rep	movsb
	pop	ds
	mov	bx,es
	cmp	bx,bp
	je	eiSetEnv
	mov	ax,bp
	call	FreeInitEnv
eiSetEnv:
	mov	word ptr ds:PDB_Environ,es
eiEnvReady:
	mov	EnvirSeg,es
	mov	ax,(ALLOCOPER shl 8) or 3
	xor	bx,bx
	int	21h
	mov	ax,(ALLOCOPER shl 8) or 1
	mov	bx,0
	int	21h
	mov	TrnMvFlg,1
	push	es
	mov	cx,offset TRANGROUP:TranSpaceEnd
	mov	ax,CmdBufSize
	add	cx,ax
	add	ax,ax
	add	ax,8
	add	cx,ax
	mov	bx,0FFFFh
	mov	ah,ALLOC
	int	21h
	cmp	bx,dx
	jb	nomem_err
	mov	ah,ALLOC
	int	21h
	jc	nomem_err
	push	ds
	push	ax
	add	ax,bx
	sub	ax,dx
	mov	TrnSeg,ax
	mov	es,ax
	mov	ax,cs:InitStubSegment
	xchg	ax,cs:OriginalDataSeg
	mov	ds,ax
	pop	ax
	mov	si,ds
	mov	bx,offset RESGROUP:TranStart
	shr	bx,1
	shr	bx,1
	shr	bx,1
	shr	bx,1
	add	si,bx
	mov	ds,si
;
; Everything is set for a move. We need to move in the reverse direction to
; make sure we dont overwrite ourselves while copying
;
	mov	si,cx
	dec	si
	mov	di,si
	std
	rep	movsb
	cld
	pop	ds
	mov	es,ax
	mov	ah,DEALLOC
	int	21h
	mov	cs:InitFlag,FALSE	;indicate INIT is done
	jmp	LodCom_Trap
nomem_err:
	jmp	BadMem_Trap

;*** FreeInitEnv -- Release an initialization environment block.
;
;	ENTRY:	ax = environment segment, ds = resident data segment
;	EXIT:	ES preserved; the PSP environment is retained if the
;		following arena is owned.
;	USED:	ax, flags
;
	public	FreeInitEnv, CopyInitVector
FreeInitEnv	proc	near
	push	es
	cmp	ax,word ptr ds:PDB_Environ
	jne	fieFree
	push	ax
	dec	ax
	mov	es,ax
	add	ax,es:[3]		; arena size
	inc	ax
	mov	es,ax
	pop	ax
	cmp	word ptr es:[1],0	; following arena owner
	jne	fieDone
fieFree:
	mov	es,ax
	mov	ah,DEALLOC
	int	21h
fieDone:
	pop	es
	ret
FreeInitEnv	endp

;*** CopyInitVector -- Preserve a vector in a resident far-jump stub.
;
;	ENTRY:	ds:si = vector, es:di = stub, al = far-jump opcode
;		Direction flag clear; interrupts disabled by caller.
;	EXIT:	Vector points to the stub; SI += 4, DI += 5.
;	USED:	bx
;
CopyInitVector	proc	near
	mov	bx,di
	stosb
	movsw
	movsw
	mov	[si-4],bx
	mov	[si-2],es
	ret
CopyInitVector	endp

public EndCodeInit			; M004
EndCodeInit	label	byte		; M004

;
; M004; Check if the EndInit code will fit into the Pipe buffers above.
; M004; If not, we signal an assembly error
;
IF2
	IF ($ GT EndPipe)
		.err
		%out	"ENDINIT CODE TOO BIG"
	ENDIF
ENDIF
;
; M004; Set the origin back to what it was at the end of the buffers
;
		ORG	EndPipe		; M004

OriginalComSpec db	80 dup (0)	; original executable pathname



InPipePtr	dw	offset DATARES:Pipe1
OutPipePtr	dw	offset DATARES:Pipe2

	public	EnvSiz
EnvSiz		dw	0		; resident environment allocation size

Exec_Block	label	byte		; the data block for exec calls
EnvirSeg        dw      ?
Com_Ptr 	label	dword
		dw	80h		; point at unformatted parameters
		dw	?
Com_Fcb1	label	dword
		dw	5Ch
		dw	?
Com_Fcb2	label	dword
		dw	6Ch
		dw	?

;		variables passed to transient
TranVars	label	byte			
		dw	offset DATARES:HeadFix_Trap
MySeg		dw	0		; put our own segment here
LTpa		dw	0		; will store tpa segment here
RSwitChar	db	"/"
RDirChar	db	"\"
		dw	offset DATARES:Issue_Exec_Call
MySeg1		dw	?
		dw	offset DATARES:RemCheck_Trap
MySeg2		dw	0
ResTest 	dw	0
Res_Tpa 	dw	0		; original tpa (not rounded to 64k)
YSwitchFlags	dw	100h		; command switch state
RetCode		dw	?		; return code for transient
		db	0		; reserved transfer byte
	public	CmdBufSize
CmdBufSize	dw	400h		; command-line buffer capacity
	public	InputBufSize
InputBufSize	dw	80h		; raw input buffer capacity
TranVarEnd	label	byte

OldErrNo	dw	?


	public	Int2eHandler
Int2eHandler	dd	0	; address of previous int 2e handler
Int2fHandler	dd	?	; address of next int 2f handler
ResMsgEnd	dw	0	; holds offset of msg end (end of resident)

;SR;
; The three vars below have been added for a pure COMMAND.COM
;

ResSize		dw	?

; Resident stack and the state preserved by the interrupt handlers.

	public	RStackGuard
RStackGuard	dw	55AAh
		db	100h dup (0AAh)
RStack	label	word
	public	ResidentBreakFlag
ResidentBreakFlag db	0		; resident break state
	public	ExeHeaderParas
ExeHeaderParas	dw	0		; executable header size in paragraphs
OldDS		dw	?		; saved data segment for critical errors
		db	0		; reserved
	public	DosCommandState
DosCommandState dd	0

ifdef	BETA3WARN
	%out	Take this out before we ship
public	Beta3Warned
Beta3Warned	db	0
endif

;
; -----------------------------------------------------------------------------
;
include highvar.inc		;Add variables for 6.0 loadhigh functionality
;
; -----------------------------------------------------------------------------
;

;***	MESSAGES
;	and other translatable text

		db	6 dup (0)	; reserved resident message state
ResidentMsgId	dw	0		; requested resident resource message
	public	ResidentMsgId

        public  ResidentMsgBuffer,ResidentMsgFileOffset
ResidentMsgBuffer db 3 dup (0)  ; resource class header
RESIDENT_MSG_BUFFER equ 1
	include	comrmsg.inc	;M00

DATARES ends
	end

