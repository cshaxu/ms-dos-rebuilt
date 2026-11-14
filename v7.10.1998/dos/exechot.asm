;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;** EXECHOT.ASM - Execution preparation and Rational 386 patches
;
;	Contains the foll:
;
;		- execution preparation and notifications
;		- Rational 386 patch detection and replacement
;
;	Revision history:
;
;		Created: 5/14/90
;
;
;
;----------------------------------------------------------------------------
;
; M020 : Fix for rational bug - for details see routine header
; M028 : 4b04 implementation
; M030 : Fixing bug in EXEPACKPATCH (EXEC_CS is an un-relocated value)
; M032 : set turnoff bit only if DOS in HMA.
; M033 : if IP < 2 then not exepacked.
; M046 : support for a 4th version of exepacked files.
; M068 : support for copy protected apps.
; M071 : use A20OFF_COUNT of 10.
;
;----------------------------------------------------------------------------
;
.XLIST
.XCREF

INCLUDE version.inc
INCLUDE dosseg.inc
INCLUDE DOSSYM.INC
INCLUDE exe.inc
INCLUDE	PDB.INC

.CREF
.LIST


	public	Rational386Patch

DOSDATA	SEGMENT

;	EXTRN	exec_signature	:WORD	; Must contain 4D5A  (yay zibo!)

;	EXTRN	exec_init_IP 	:WORD	; IP of entry
;	EXTRN	exec_init_CS 	:WORD	; CS of entry

	EXTRN	fixexepatch	:word		; M028
	EXTRN	Rational386PatchPtr:word
	EXTRN	Special_Version	:word		; M028
;	EXTRN	A20OFF_FLAG	:byte
	extrn	DosHasHMA	:byte		
	extrn	A20OFF_COUNT	:byte		; M068
	extrn	A20OFF_PSP	:word		; M068
	extrn	DOS_FLAG	:byte		; M068

DOSDATA	ENDS


DOSCODE	SEGMENT
	EXTRN	IsCopyProt:NEAR
	EXTRN	ExecSaveState:NEAR,ExecNotify:NEAR

; M028 - BEGIN

	EXTRN	Scan_Execname1:near
	EXTRN	Scan_Special_Entries:near

	ASSUME	CS:DOSCODE, SS:DOSDATA

	public	ExecReady

;-------------------------------------------------------------------------
;
;	Procedure Name		: ExecReady
;
;	Input			: DS:DX -> ERStruc (see exe.inc)
;
;--------------------------------------------------------------------------

ExecReady	proc	near
	call	ExecSaveState

	mov	si, dx			; move the pointer into a friendly one
	test	[si].ER_Flags, ER_EXE	; COM or EXE ?
	jz	er_setver		; only setver for .COM files

	mov	ax, [si].ER_PSP
	db	083h,0c0h,10h		; ADD AX,10h (signed immediate)
	mov	es, ax

	mov	cx, word ptr ds:[si].ER_StartAddr	; M030
	mov	ax, word ptr ds:[si+2].ER_StartAddr	; M030

	call	[fixexepatch]
	call	[Rational386PatchPtr]

er_setver:
					; Q: is this an overlay
	test	[si].ER_Flags, ER_OVERLAY
	jnz	er_chkdoshi		; Y: set A20OFF_COUNT if DOS high
					; N: set up lie version first
	push	ds
	push	si
	lds	si, [si].ER_ProgName
	call	Scan_Execname1
	call	Scan_Special_Entries
	pop	si
	pop	ds
	mov	es, [si].ER_PSP
	mov	ax, Special_Version
	mov	es:[0].PDB_Version, ax
er_chkdoshi:
	cmp	[DosHasHMA], 0		; M032: Q: is dos in HMA (M021)
	je	er_done			; M032: N: done

					; M068 - Start
	mov	ax, [si].ER_PSP		; ax = PSP

	or	[DOS_FLAG], EXECA20OFF	; Set bit to signal int 21
					; ah = 25 & ah= 49. See dossym.inc 
					; under TAG M003 & M009 for 
					; explanation

	test	[si].ER_Flags, ER_EXE	; Q: COM file
	jnz	er_setA20		; N: inc a20off_count , set 
					;    a20off_psp and ret
   	push	ds
	mov	ds, ax			; DS = load segment of com file.
	call	IsCopyProt		; check if copy protected
	pop	ds

er_seta20:

	;
	; We need to inc the A20OFF_COUNT here. Note that if the count
	; is non-zero at this point it indicates that the A20 is to be 
	; turned off for that many int 21 calls made by the app. In 
	; addition the A20 has to be turned off when we exit from this 
	; call. Hence the inc.
	;

	inc	[A20OFF_COUNT]		
	mov	[A20OFF_PSP], ax	; set the PSP for which A20 is to be
					; turned OFF.
er_done:				; M068 - End
	call	ExecNotify
	xor	ax, ax
	ret
ExecReady	endp

; M028 - END

;----------------------------------------------------------------------------
;
; procedure : Rational386Patch
;
; Older versions of the Rational DOS Extender have several bugs which trash
; 386 registers (usually just the high word of 32 bit registers) during
; interrupt processing.  Lotus 123 3.1+ is a popular application that uses a
; version of the Rational extender with the 32 bit register trashing bugs.
;
; This routine applies patches to the Rational DOS Extender to work around
; most of the register trashing bugs.
;
; Note that there are additional register trashing bugs not fixed by these
; patches.  In particular, the high word of ESP and the FS and GS registers
; may be modified on interrupts.
;
; There are two different Rational DOS Extender patchs in this module.
; Rational386Patch is to correct 386 register trashing bugs on 386 or later
; processors.  This patch code is executed when MS-DOS is running on a 386
; or later processor, regardless of whether MS-DOS is running in the HMA
; or not.
;
; The other Rational patch routine (RationalPatch in EXEPATCH.ASM) fixes a register
; trashing problem on 286 processors, and is only executed if MS-DOS is
; running in the HMA.
;
; This patch detection and replacement is based on an example supplied by
; Ben Williams at Rational.
;
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;
; INPUT : ES = segment where program got loaded
;
;----------------------------------------------------------------------------

rpFind1 	db	0FAh, 0E4h, 21h, 60h, 33h, 0C0h, 0E6h, 43h, 8Bh, 16h
rpFind1Len	equ	$ - offset rpFind1

;	cli
;	in	al, 21h
;	pusha
;	xor	ax, ax
;	out	43h, al
;	mov	dx, ...

rpFind1a	db	0B0h, 0Eh, 0E6h, 37h, 33h, 0C0h, 0E6h, 0F2h
rpFind1aLen	equ	$ - offset rpFind1a

;	mov	al, 0Eh
;	out	37h, al
;	xor	ax, ax
;	out	0F2h, al


; bug # 1 -- loss of high EAX on 386+ if not VCPI or DPMI

rpFind2 	db	0Fh, 20h, 0C0h
rpFind2Len	equ	$ - offset rpFind2

;	mov	eax, cr0	;may be preceeded by PUSH CX (51h)

rpFind3 	db	0Fh, 22h, 0C0h, 0EAh
rpFind3Len	equ	$ - offset rpFind3

;	mov	cr0, eax	;may be preceeded by POP CX (59h)
;	jmp	far ptr xxx	;change far ptr to go to replace3
;	mov	ss, bx		;8E D3 ... and come back at or after this

; note, there is no rpRepl1 string

rpRepl2 	db	66h, 50h, 51h, 0Fh, 20h, 0C0h
rpRepl2Len	equ	$ - offset rpRepl2

;	push	eax
;	push	cx
;	mov	eax, cr0

rpRepl3 	db	8Eh, 0D3h, 59h, 66h, 58h
rpRepl3Len	equ	$ - offset rpRepl3

;	mov	ss, bx
;	pop	cx
;	pop	eax

; bug # 2 -- loss of high EAX and ESI on 386+ only if VCPI

rpFind4 	db	93h, 58h, 8Bh, 0CCh
rpFind4Len	equ	$ - offset rpFind4

;	xchg	bx, ax
;	pop	ax
;	mov	cx, sp

rpFind5 	db	0B8h, 0Ch, 0DEh, 0CDh, 67h, 8Bh, 0E1h, 0FFh, 0E3h
rpFind5Len	equ	$ - offset rpFind5

;	mov	ax, DE0Ch
;	int	67h
;	mov	sp, cx
;	jmp	bx

rpRepl4 	db	93h, 58h, 8Bh, 0CCh
		db	02Eh, 066h, 0A3h
rpRepl4o1Len	equ	$ - offset rpRepl4
		db	00h, 00h
		db	02Eh, 066h, 89h, 36h
rpRepl4o2Len	equ	$ - offset rpRepl4
		db	00h, 00h
rpRepl4Len	equ	$ - offset rpRepl4

;	xchg	bx, ax
;	pop	ax
;	mov	cx, sp
;	mov	dword ptr cs:[xxxx], eax
;	mov	dword ptr cs:[xxxx], esi

rpRepl5 	db	8Bh, 0E1h
		db	2Eh, 66h, 0A1h
rpRepl5o1Len	equ	$ - offset rpRepl5
		db	00h, 00h
		db	2Eh, 66h, 8Bh, 36h
rpRepl5o2Len	equ	$ - offset rpRepl5
		db	00h, 00h
		db	0FFh, 0E3h
rpRepl5Len	equ	$ - offset rpRepl5

;	mov	sp, cx
;	mov	eax, dword ptr cs:[xxxx]
;	mov	esi, dword ptr cs:[xxxx]
;	jmp	bx

; bug # 3 -- loss of high EAX, EBX, ECX, EDX on 386+ only if VCPI

rpFind6 	db	0FAh, 52h, 51h
rpFind6Len	equ	$ - offset rpFind6

;	cli
;	push	dx
;	push	cx

rpFind7a	db	0B8h, 0Ch, 0DEh, 66h, 26h, 0FFh, 1Eh
rpFind7aLen	equ	$ - offset rpFind7a

;	mov	ax, 0DE0Ch
;	call	fword ptr es:[xxxx]

rpFind7b	db	59h, 5Ah, 5Bh
rpFind7bLen	equ	$ - offset rpFind7b

;	pop	cx
;	pop	dx
;	pop	bx

rpRepl6 	db	0FAh, 66h, 50h, 66h, 53h, 66h, 51h, 66h, 52h
rpRepl6Len	equ	$ - offset rpRepl6

;	cli
;	push	eax
;	push	ebx
;	push	ecx
;	push	edx

rpRepl7 	db	66h, 5Ah, 66h, 59h, 66h, 5Bh, 66h, 58h, 5Bh
rpRepl7Len	equ	$ - offset rpRepl7

;	pop	edx
;	pop	ecx
;	pop	ebx
;	pop	eax
;	pop	bx

; bug # 4 -- loss of high EAX and EBX on 386+ only if VCPI

rpFind8 	db	60h, 06h, 1Eh, 0B8h, 00h, 00h, 8Eh, 0D8h
rpFind8Len	equ	$ - offset rpFind8

;	pusha
;	push	es
;	push	ds
;	mov	ax, dgroup	;jump back to here from replace8
;	mov	ds, ax

rpFind9 	db	1Fh, 07h, 61h
rpFind9Len	equ	$ - rpFind9

;	pop	ds
;	pop	es
;	popa

rpRepl8 	db	66h, 60h, 06h, 1Eh
rpRepl8Len	equ	$ - offset rpRepl8

;	pushad
;	push	es
;	push	ds

rpRepl9 	db	1Fh, 07h, 66h, 61h, 0C3h
rpRepl9Len	equ	$ - offset rpRepl9

;	pop	ds
;	pop	es
;	popad
;	ret			;no need to jmp back to main-line

;----------------------------------------------------------------------------

SearchPair	STRUC
sp_off1 	dw	?		; offset of 1st search string
sp_len1 	dw	?		; length of 1st search string
sp_off2 	dw	?		; 2nd string
sp_len2 	dw	?		; 2nd string
sp_diff 	dw	?		; max difference between offsets
SearchPair	ENDS

rpBug1Strs	SearchPair	<offset rpFind2, rpFind2Len, offset rpFind3, rpFind3Len, 20h>
rpBug2Strs	SearchPair	<offset rpFind4, rpFind4Len, offset rpFind5, rpFind5Len, 80h>
rpBug3Strs	SearchPair	<offset rpFind6, rpFind6Len, offset rpFind7a, rpFind7aLen, 80h>
rpBug4Strs	SearchPair	<offset rpFind8, 4, offset rpFind9, rpFind9Len, 80h>

;----------------------------------------------------------------------------

StackVars	STRUC
sv_wVersion	dw	?		; Rational extender version #
sv_cbCodeSeg	dw	?		; code seg size to scan
sv_pPatch	dw	?		; offset of next avail patch byte
StackVars	ENDS

;----------------------------------------------------------------------------

Rational386Patch  proc	near

	; Do a few quick checks to see if this looks like a Rational
	; Extended application.  Hopefully this will quickly weed out
	; most non Rational apps.

	cmp	word ptr es:[0], 395	; version number goes here - versions
	jae	rp3QuickOut		;   3.95+ don't need patching

	cmp	word ptr es:[0Ch], 20h	; always has this value here
	jne	rp3QuickOut

	push	ax

	mov	ax, 18h 		; extender has 18h at
	cmp	es:[24], ax		;   offsets 24, 28, & 36
	jne	rp3QO_ax
	cmp	es:[28], ax
	jne	rp3QO_ax
	cmp	es:[36], ax
	je	rp3Maybe

rp3QO_ax:
	pop	ax

rp3QuickOut:
	ret

; It might be the rational extender, do more extensive checking

rp3Maybe:

	cld
	push	bx		; note ax pushed above
	push	cx
	push	dx
	push	si
	push	di
	push	es
	push	ds			; we use all of them
	push	bp
	sub	sp, SIZE StackVars	; make space for stack variables
	mov	bp, sp

	push	cs
	pop	ds
	assume	ds:nothing

	mov	ax, es:[0]		; save version #
	mov	[bp].sv_wVersion, ax
					; check that binary version # matches
	call	VerifyVersion		;   ascii string
	jne	rp3Exit_j


; Looks like this is it, find where to put the patch code.  The
; patch will be located on top of Rational code specific to 80286
; processors, so these patchs MUST NOT be applied if running on
; an 80286 system.

	; Rational says the code to patch will never be beyond offset 46xxh

	mov	cx, 4500h		; force search len to 4700h (searches
	mov	[bp].sv_cbCodeSeg, cx	;   start at offset 200h)

	mov	es, word ptr es:[20h]	; es=code segment

	mov	si, offset rpFind1	; string to find
	mov	dx, rpFind1Len		; length to match
	call	ScanCodeSeq		; look for code seq
	jz	rpGotPatch

; According to Rational, some very old versions of the extender may not
; have the find1 code sequence.  If the find1 code wasn't found above,
; try an alternative patch area which is on top of NEC 98xx switching code.

	mov	si, offset rpFind1a
	mov	dx, rpFind1aLen
	call	ScanCodeSeq
	jz	rpGotPatch

rp3Exit_j:
	jmp	rp3Exit

; Found the location to write patch code!  DI = offset in code seg.

rpGotPatch:
	mov	[bp].sv_pPatch, di	; save patch pointer

;----------------------------------------------------------------------------
; Bug # 1 -- loss of high EAX on 386+ if not VCPI or DPMI

	cmp	word ptr [bp].sv_wVersion, 381	; only need bug 1 if version
	jae	rpBug2				;   < 3.81

	mov	bx, offset rpBug1Strs		; locate find2 & find3 code
	call	FindBadCode
	jc	rpBug2

; si = rpFind2 offset, di = rpFind3 offset

	push	di
	mov	di, si				; rpFind2 offset
	mov	dx, rpFind2Len

	cmp	byte ptr es:[di-1], 51h 	; find2 preceeded by push cx?
	jne	rp_no_cx

	dec	di				;   yes, gobble up push cx too
	inc	dx
rp_no_cx:
	mov	si, offset rpRepl2		; patch out find2 sequence
	mov	cx, rpRepl2Len
	call	GenPatch

	pop	di				; rpFind3 offset
	cmp	byte ptr es:[di-1], 59h 	; find3 preceeded by pop cx?
	jne	rp_no_cx2

	mov	byte ptr es:[di-1], 90h 	;   yes, no-op it

rp_no_cx2:
	mov	ax, [bp].sv_pPatch		; change offset of far jmp
	mov	es:[di+rpFind3Len], ax		;   to go to patch code

	push	di				; save find3 offset
	mov	si, offset rpRepl3		; copy repl3 to patch area
	mov	cx, rpRepl3Len
	call	CopyPatch

	pop	bx				; find3 offset
	db	081h,0c3h		; ADD BX,rpFind3Len+4 (word immediate)
	dw	rpFind3Len+4		; skip over find3 and far jmp
	call	GenJump 			; jmp back from patch area
	mov	[bp].sv_pPatch, di		;   to main-line, update patch
						;   area pointer

;----------------------------------------------------------------------------
; Bug # 2 -- loss of high regs on 386+ under VCPI only

rpBug2:
	mov	bx, offset rpBug2Strs		; locate find4 & find5 code
	call	FindBadCode
	jc	rpBug3

; si = rpFind4 offset, di = rpFind5 offset

	push	[bp].sv_pPatch			; save current patch pointer
						;   (where repl4 goes)
	push	di				; save find5 offset

	mov	di, si
	mov	dx, rpFind4Len
	mov	si, offset rpRepl4
	mov	cx, rpRepl4Len
	call	GenPatch			; patch out find4 code

	pop	di				; find5 offset
	add	di, 5				; keep 5 bytes of find5 code
	mov	bx, [bp].sv_pPatch		; jump to patch area
	push	bx				; save repl5 location
	call	GenJump

	mov	si, offset rpRepl5		; copy repl5 code to patch
	mov	cx, rpRepl5Len			;   area -- it has a jmp bx
	call	CopyPatch			;   so no need to jmp back to
						;   main-line code

; patches have been made, now update the patch code to store/load dwords just
; after the code in the patch area

	pop	di				; repl5 location
	pop	si				; repl4 location

	mov	ax, [bp].sv_pPatch		; (where dwords go)

	mov	word ptr es:[si+rpRepl4o1Len], ax	; offset for EAX
	mov	word ptr es:[di+rpRepl5o1Len], ax
	db	083h,0c0h,4		; ADD AX,4 (signed immediate)
	mov	word ptr es:[si+rpRepl4o2Len], ax	; offset for ESI
	mov	word ptr es:[di+rpRepl5o2Len], ax

	add	[bp].sv_pPatch, 8		; reserve space for 2 dwords in
						; patch area

;----------------------------------------------------------------------------
; Bug # 3 -- loss of high regs on 386+ under VCPI only

rpBug3:
	mov	bx, offset rpBug3Strs		; locate find6 & find7a code
	call	FindBadCode
	jc	rpBug4

	db	081h,0c7h		; ADD DI,rpFind7aLen+2 (word immediate)
	dw	rpFind7aLen+2		; skip over offset in find7a
	push	si				;   code and locate find7b
	mov	si, offset rpFind7b		;   sequence
	mov	dx, rpFind7bLen
	call	ScanCodeSeq_di
	pop	si
	jnz	rpBug4

	push	di				; save find7b code offset

	mov	di, si
	mov	dx, rpFind6Len
	mov	si, offset rpRepl6
	mov	cx, rpRepl6Len
	call	GenPatch			; patch out find6 code

	pop	di
	mov	dx, rpFind7bLen
	mov	si, offset rpRepl7
	mov	cx, rpRepl7Len
	call	GenPatch			; patch out find7b code


;----------------------------------------------------------------------------
; Bug # 4 -- loss of high regs on 386+ under VCPI only

rpBug4:
	cmp	[bp].sv_wVersion, 360	; only applies if version > 3.60
	jbe	rp3Exit 		;   and < 3.95

	mov	bx, offset rpBug4Strs		; locate find8 & find9 code
	call	FindBadCode
	jc	rp3Exit

	push	di				; save find9 code offset

	mov	di, si
	mov	dx, 3
	mov	si, offset rpRepl8
	mov	cx, rpRepl8Len
	call	GenPatch			; patch out find8 code

	pop	di				; find9 offset
	mov	bx, [bp].sv_pPatch		; patch find9 to jmp to
	call	GenJump 			;   patch area

	mov	si, offset rpRepl9		; copy replacement code to
	mov	cx, rpRepl9Len			;   patch area--it does a RET
	call	CopyPatch			;   so no jmp back to main-line

rp3Exit:
	add	sp, SIZE StackVars
	pop	bp
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

Rational386Patch endp

;----------------------------------------------------------------------------
;
; FindBadCode
;
; Searches Rational code segment looking for a pair of find strings (all
; patches have at least two find strings).
;
; Entry:
;	ES    = code segment to search
;	DS:BX = search pair structure for this search
;	[bp].sv_cbCodeSeg = length of code seg to search
;
; Exit:
;	CY flag clear if both strings found, and
;	SI    = offset in ES of 1st string
;	DI    = offset in ES of 2nd string
;	CY set if either string not found, or strings too far apart
;
; Used:
;	CX
;
;----------------------------------------------------------------------------

FindBadCode proc near

	mov	cx, [bp].sv_cbCodeSeg	; search length

	mov	si, [bx].sp_off1	; ds:si -> search string
	mov	dx, [bx].sp_len1	; dx = search len
	call	ScanCodeSeq
	jnz	fbc_error		; done if 1st not found

	push	di			; save 1st string offset

	mov	si, [bx].sp_off2
	mov	dx, [bx].sp_len2
	call	ScanCodeSeq_di		; don't change flags after this!

	pop	si			; restore 1st string offset
	jnz	fbc_error

	mov	ax, di			; sanity check that
	sub	ax, si			;   si < di && di - si <= allowed diff
	jc	fbc_error
	cmp	ax, [bx].sp_diff
	ja	fbc_error

	clc
	ret

fbc_error:
	stc
	ret

FindBadCode endp

;----------------------------------------------------------------------------
;
; GenPatch
;
; Generate a patch sequence.  1) insert a jump at the buggy code location
; (jumps to the patch code area), 2) copy the selected patch code to the
; patch area, 3) insert a jump from the patch area back to the main-line
; code.
;
; Entry:
;	ES:DI = start of buggy code to be patched
;	DX    = length of buggy code to be patched
;	DS:SI = replacement patch code
;	CX    = length of replacement patch code
;	[bp].sv_pPatch = offset in ES of where to copy patch code
;
; Exit:
;	DI, [bp].sv_pPatch = byte after generated patch code
;
; Used:
;	AX, BX, SI, Flags
;
;----------------------------------------------------------------------------

GenPatch proc	near

	push	di			;save offset of buggy code

	mov	bx, [bp].sv_pPatch	;jump from buggy code to patch area
	call	GenJump

	call	CopyPatch		;copy replacement code to patch area

	pop	bx			;offset of buggy code + buggy code
	add	bx, dx			;  length = return from patch offset

	call	GenJump 		;jump from patch area back to main-
	mov	[bp].sv_pPatch, di	;  line code, update patch pointer

	ret

GenPatch endp


;----------------------------------------------------------------------------
;
; CopyPatch
;
; Copies patch code to patch location.
;
; Entry:
;	DS:SI = patch code to be copied
;	ES    = segment of code to patch
;	CX    = length of code to copy
;	[bp].sv_pPatch = offset in ES of where to copy patch code
;
; Exit:
;	DI, [bp].sv_pPatch = byte after copied patch code
;
; Used:
;	SI, Flags
;
;----------------------------------------------------------------------------

CopyPatch proc	near

	push	cx
	mov	di, [bp].sv_pPatch	;patch pointer is the dest offset
	cld
	rep movsb
	pop	cx

	mov	[bp].sv_pPatch, di	;update net pointer location

	ret

CopyPatch endp

;----------------------------------------------------------------------------
;
; GenJump
;
; Generates a rel16 JMP instruction at location 'from' to location 'to'.
;
; Entry:
;	ES:DI = from location (where to put jmp instruction)
;	BX    = to location (where to jump to)
;
; Exit:
;	DI = byte after generated jump
;
; Used:
;	AX
;
;----------------------------------------------------------------------------

GenJump proc	near

	mov	al, 0E9h		; jmp rel16 opcode
	stosb

	mov	ax, bx			; calc offset to 'to' location
	sub	ax, di
	db	083h,0e8h,2		; SUB AX,2 (signed immediate)

	stosw				; output offset

	ret

GenJump endp

;
;----------------------------------------------------------------------------
;
; ScanCodeSeq
;
; Looks for a pattern pointed to by DS:SI & len DX in ES:200 to ES:200+CX-1
;
; returns in ES:DI the start of the pattern if Zero flag is set
;
;----------------------------------------------------------------------------
;
ScanCodeSeq	proc	near
		mov	di, 200h
ScanCodeSeq_di	label	near
		push	cx
		sub	cx, dx
		inc	cx
scsagain:
		push	si
		push	di
		push	cx
		mov	cx, dx
		rep	cmpsb
		pop	cx
		pop	di
		pop	si
		je	scsfound
		inc	di
		loop	scsagain
scsfound:
		pop	cx
		ret
ScanCodeSeq	endp
	
;
;----------------------------------------------------------------------------
;
; VerifyVersion
;
; Checks whether the binary version from ES:0 matches the ASCII version
; from ES:2A.
;
;       Entry: AX = binary version number 
;       Exit : Z flag set if version numbers match
;
;----------------------------------------------------------------------------
;
VerifyVersion	proc	near
		mov	si, es:[2ah]		; offset of version number
						;  in ascii
		mov	bl, 10
		add	si, 3			; point to last digit

		call	VVDigit
		jne	vvexit
		call	VVDigit
		jne	vvexit
		cmp	byte ptr es:[si], '.'
		jne	vvexit
		dec	si
		call	VVDigit
vvexit:
		ret
VerifyVersion	endp

VVDigit		proc	near
		div	bl
		add	ah, '0'
		dec	si
		cmp	es:[si+1], ah
		mov	ah, 0			; do not xor or sub we need Z
		ret
VVDigit 	endp

;-----------------------------------------------------------------------

	public	ScanCodeSeq,VerifyVersion
	db	"MS-DOS Version 7 (C)Copyright 1981-1995 Microsoft Corp "
	db	"Licensed Material - Property of Microsoft All rights reserved "

DOSCODE	ENDS
	END
