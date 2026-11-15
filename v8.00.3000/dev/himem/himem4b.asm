;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1988-1992
; *                      All Rights Reserved.
; */
	page	,160
	title	HIMEM - extended memory block allocation

	include	himem.inc

	include	bioscode.inc

Bios_Code	segment byte public 'CODE'
	.386p
	assume	cs:Bios_Code,ds:Bios_Code

	extrn	KiddValley:word,cHandles:word,ValidateHandle:near
	public	aQueryExtMemory,aAllocExtMemory,aFreeExtMemory
	public	aGetExtMemoryInfo,aReallocExtMemory

; Return the available memory in kilobytes, with 16-bit saturation.
aQueryExtMemory proc near
	test	ah,80h
	jnz	near ptr SQueryExtMemory
	push	si
	push	di
	push	eax
	push	ecx
	push	edx
	call	SQueryExtMemory
	mov	si,ax
	cmp	eax,0ffffh
	jna	short AQTotal
	mov	si,0ffffh
AQTotal:
	mov	di,dx
	cmp	edx,0ffffh
	jna	short AQReturn
	mov	di,0ffffh
AQReturn:
	pop	edx
	pop	ecx
	pop	eax
	mov	ax,si
	mov	dx,di
	pop	di
	pop	si
	ret
aQueryExtMemory endp

; Allocate an extended memory block.
aAllocExtMemory proc near
	test	ah,80h
	jnz	near ptr SAllocExtMemory
	push	si
	push	edx
	movzx	edx,dx
	call	SAllocExtMemory
	mov	si,dx
	pop	edx
	mov	dx,si
	pop	si
	ret
aAllocExtMemory endp

; Free a block and merge adjacent free blocks.
aFreeExtMemory proc near
	cli
	push	si
	push	di
	push	cx
	push	edx
	push	eax
	push	ebx
	call	ValidateHandle
	jnc	short AFBadHandle
	mov	si,dx
	cmp	byte ptr [si].cLock,0
	jnz	short AFLocked
	mov	byte ptr [si],4
	cmp	dword ptr [si].Len,0
	jz	short AFSuccess
	mov	byte ptr [si],1
AFMerge:
	mov	ebx,[si].Base
	mov	eax,ebx
	add	eax,[si].Len
	mov	di,cs:KiddValley
	mov	cx,cs:cHandles
AFScan:
	cmp	byte ptr [di],1
	jnz	short AFNext
	mov	edx,[di].Base
	cmp	edx,eax
	jz	short AFMergeBlocks
	add	edx,[di].Len
	cmp	edx,ebx
	jz	short AFMergePrevious
AFNext:
	add	di,0ah
	loop	AFScan
AFSuccess:
	pop	ebx
	pop	eax
	mov	ax,1
	xor	bl,bl
AFExit:
	pop	edx
	pop	cx
	pop	di
	pop	si
	ret
AFMergePrevious:
	xchg	si,di
AFMergeBlocks:
	mov	edx,[si].Len
	add	edx,[di].Len
	mov	[si].Len,edx
	mov	byte ptr [di],4
	jmp	short AFMerge
AFBadHandle:
	pop	ebx
	mov	bl,0a2h
	jmp	short AFError
AFLocked:
	pop	ebx
	mov	bl,0abh
AFError:
	pop	eax
	xor	ax,ax
	jmp	short AFExit
aFreeExtMemory endp

; Return the size and lock count of the specified block.
aGetExtMemoryInfo proc near
	test	ah,80h
	jnz	near ptr SGetExtMemoryInfo
	cli
	push	cx
	push	si
	call	ValidateHandle
	jnc	short AGInfoBadHandle
	mov	si,dx
	cmp	word ptr [si].Len+2,0
	jnz	short AGInfoBadHandle
	xor	ax,ax
	mov	bx,cs:KiddValley
	mov	cx,cs:cHandles
AGInfoScan:
	cmp	byte ptr [bx],2
	jz	short AGInfoNext
	inc	ax
AGInfoNext:
	add	bx,0ah
	loop	AGInfoScan
	mov	dx,word ptr [si].Len
	mov	bh,[si].cLock
	or	ah,ah
	jz	short AGInfoExit
	mov	al,0ffh
AGInfoExit:
	pop	si
	pop	cx
	mov	bl,al
	mov	ax,1
	ret
AGInfoBadHandle:
	pop	si
	pop	cx
	mov	bl,0a2h
	xor	ax,ax
	ret
aGetExtMemoryInfo endp

; Change the size of an allocated block.
aReallocExtMemory proc near
	test	ah,80h
	jnz	near ptr SReallocExtMemory
	push	si
	push	di
	push	eax
	push	ebx
	movzx	ebx,bx
	call	SReallocExtMemory
	mov	si,ax
	mov	di,bx
	pop	ebx
	mov	bx,di
	pop	eax
	mov	ax,si
	pop	di
	pop	si
	ret
aReallocExtMemory endp

; Return the largest block, total free memory, and highest address.
SQueryExtMemory proc near
	push	esi
	push	edi
	xor	eax,eax
	xor	edx,edx
	xor	esi,esi
	mov	bx,cs:KiddValley
	mov	cx,cs:cHandles
SQScan:
	cmp	byte ptr [bx],4
	jz	short SQNext
	mov	edi,[bx].Base
	add	edi,[bx].Len
	dec	edi
	cmp	esi,edi
	jnc	short SQFree
	mov	esi,edi
SQFree:
	cmp	byte ptr [bx],1
	jnz	short SQNext
	mov	edi,[bx].Len
	add	edx,edi
	cmp	eax,edi
	jnc	short SQNext
	mov	eax,edi
SQNext:
	add	bx,0ah
	loop	SQScan
	mov	ecx,esi
	mov	bl,0a0h
	or	edx,edx
	jz	short SQExit
	xor	bl,bl
SQExit:
	pop	edi
	pop	esi
	ret
SQueryExtMemory endp

; The XMS 3.0 allocation entry accepts a 32-bit size.
SAllocExtMemory proc near
	cli
	push	cx
	push	si
	push	di
	xor	si,si
	mov	di,si
	mov	bx,cs:KiddValley
	mov	cx,cs:cHandles
SAEMhLoop:
	or	si,si
	jnz	short SAEMUnused
	cmp	byte ptr [bx],1
	jnz	short SAEMUnused
	cmp	edx,[bx].Len
	ja	short SAEMNexth
	mov	si,bx
	jmp	short SAEMBottom
SAEMUnused:
	or	di,di
	jnz	short SAEMNexth
	cmp	byte ptr [bx],4
	jnz	short SAEMNexth
	mov	di,bx
	cmp	si,0
	jz	short SAEMNexth
SAEMBottom:
	cmp	di,0
	jnz	short SAEMGotBoth
SAEMNexth:
	add	bx,0ah
	loop	SAEMhLoop
	or	si,si
	jnz	short SAEMRetSuc
	or	di,di
	jz	short SAEMOOHandles
	or	edx,edx
	jnz	short SAEMOOMemory
	mov	si,di
	mov	dword ptr [si].Len,0
	jmp	short SAEMRetSuc
SAEMGotBoth:
	push	eax
	mov	eax,[si].Base
	add	eax,edx
	mov	[di].Base,eax
	mov	eax,edx
	xchg	eax,[si].Len
	sub	eax,edx
	mov	[di].Len,eax
	mov	byte ptr [di],1
	jnz	short SAEMRestore
	mov	byte ptr [di],4
SAEMRestore:
	pop	eax
SAEMRetSuc:
	mov	byte ptr [si],2
	mov	dx,si
	mov	ax,1
	xor	bl,bl
SAEM9:
	pop	di
	pop	si
	pop	cx
	ret
SAEMOOMemory:
	mov	bl,0a0h
	jmp	short SAEMErrRet
SAEMOOHandles:
	mov	bl,0a1h
SAEMErrRet:
	xor	ax,ax
	mov	dx,ax
	jmp	short SAEM9
SAllocExtMemory endp

; The XMS 3.0 information entry returns a 32-bit size.
SGetExtMemoryInfo proc near
	cli
	push	cx
	push	si
	call	ValidateHandle
	jnc	short SGInfoExit
	mov	si,dx
	xor	ax,ax
	mov	bx,cs:KiddValley
	mov	cx,cs:cHandles
SGInfoScan:
	cmp	byte ptr [bx],2
	jz	short SGInfoNext
	inc	ax
SGInfoNext:
	add	bx,0ah
	loop	SGInfoScan
	mov	edx,[si].Len
	mov	bh,[si].cLock
	xchg	ax,cx
	pop	si
	pop	cx
	mov	ax,1
	xor	bl,bl
	ret
SGInfoExit:
	pop	si
	pop	cx
	mov	bl,0a2h
	xor	ax,ax
	ret
SGetExtMemoryInfo endp

; Resize a block, moving its contents if required.
SReallocExtMemory proc near
	cli
	push	bp
	push	edx
	push	si
	push	di
	call	ValidateHandle
	mov	si,dx
	mov	edx,ebx
	mov	bl,0a2h
	jnc	short REMError
	cmp	byte ptr [si].cLock,0
	mov	bl,0abh
	jnz	short REMError
	cmp	edx,[si].Len
	ja	short REMGrow
	jc	short REMShrink
REMExit:
	mov	ax,1
	xor	bl,bl
	pop	di
	pop	si
	pop	edx
	pop	bp
	ret
REMShrink:
	push	edx
	call	FindAdjacent
	pop	edx
	or	bp,bp
	jz	short REMShrink5
	mov	eax,[si].Len
	sub	eax,edx
	mov	[si].Len,edx
	add	ds:[bp+6],eax
	sub	ds:[bp+2],eax
	jmp	short REMExit
REMError:
	xor	ax,ax
	pop	di
	pop	si
	pop	edx
	pop	bp
	ret
REMShrink5:
	push	cx
	mov	di,cs:KiddValley
	mov	cx,cs:cHandles
REMShrinkScan:
	cmp	byte ptr [di],4
	jz	short REMS5b
	add	di,0ah
	loop	REMShrinkScan
	pop	cx
	mov	bl,0a1h
	jmp	short REMError
REMS5b:
	pop	cx
	mov	eax,edx
	add	eax,[si].Base
	mov	[di].Base,eax
	mov	eax,[si].Len
	sub	eax,edx
	mov	[di].Len,eax
	mov	byte ptr [di],1
	mov	byte ptr [di].cLock,0
	mov	[si].Len,edx
	jmp	short REMExit
REMGrow:
	push	edx
	call	FindAdjacent
	pop	edx
	or	bp,bp
	jz	short REMGrow4
	mov	eax,edx
	sub	eax,[si].Len
	cmp	eax,ds:[bp+6]
	ja	short REMGrow4
	jz	short REMGrow2
	sub	ds:[bp+6],eax
	add	ds:[bp+2],eax
	jmp	short REMGrow3
REMGrow2:
	mov	byte ptr ds:[bp+0],4
REMGrow3:
	mov	[si].Len,edx
	jmp	near ptr REMExit
REMGrow4:
	or	di,di
	jz	short REMGrow7x
	mov	eax,[di].Len
	add	eax,[si].Len
	or	bp,bp
	jz	short REMGrow4a
	add	eax,ds:[bp+6]
REMGrow4a:
	cmp	edx,eax
	jna	short REMGrow5
REMGrow7x:
	jmp	near ptr REMGrow7
REMGrow5:
	sub	sp,10h
	push	ss
	pop	es
	mov	bx,sp
	push	dword ptr [si].Len
	or	bp,bp
	jz	short REMGrow5a
	mov	eax,ds:[bp+6]
	add	[si].Len,eax
	mov	byte ptr ds:[bp+0],4
REMGrow5a:
	mov	eax,[di].Len
	add	[si].Len,eax
	push	dword ptr [si].Base
	mov	eax,[di].Base
	mov	[si].Base,eax
	inc	byte ptr [di].cLock
	inc	byte ptr [si].cLock
	mov	es:[bx+4],si
	mov	es:[bx+0ah],si
	mov	dword ptr es:[bx+0ch],0
	pop	eax
	sub	eax,[si].Base
	shl	eax,0ah
	mov	es:[bx+6],eax
	pop	eax
	shl	eax,0ah
	mov	es:[bx],eax
	push	si
	push	di
	push	edx
	mov	si,bx
	call	Movext386
	pop	edx
	pop	di
	pop	si
	add	sp,10h
	cli
	dec	byte ptr [di].cLock
	dec	byte ptr [si].cLock
	mov	eax,[si].Len
	sub	eax,edx
	mov	[si].Len,edx
	jz	short REMGrow5b
	add	edx,[si].Base
	mov	[di].Base,edx
	mov	[di].Len,eax
	jmp	near ptr REMExit
REMGrow5b:
	mov	byte ptr [di],4
	jmp	near ptr REMExit
REMErrora:
	xor	ax,ax
	pop	di
	pop	si
	pop	edx
	pop	bp
	ret
REMGrow7:
	push	si
	push	dx
	call	SAllocExtMemory
	cli
	mov	di,dx
	pop	dx
	pop	si
	or	ax,ax
	mov	bl,0a0h
	jz	short REMErrora
	inc	byte ptr [di].cLock
	inc	byte ptr [si].cLock
	sub	sp,10h
	push	ss
	pop	es
	mov	bx,sp
	mov	es:[bx+4],si
	mov	es:[bx+0ah],di
	xor	eax,eax
	mov	es:[bx+0ch],eax
	mov	es:[bx+6],eax
	mov	eax,[si].Len
	shl	eax,0ah
	mov	es:[bx],eax
	push	si
	push	di
	mov	si,bx
	call	Movext386
	pop	di
	pop	si
	add	sp,10h
	cli
	mov	eax,[si].Base
	xchg	eax,[di].Base
	mov	[si].Base,eax
	mov	eax,[si].Len
	xchg	eax,[di].Len
	mov	[si].Len,eax
	dec	byte ptr [si].cLock
	dec	byte ptr [di].cLock
	mov	ax,di
	pop	di
	pop	si
	pop	edx
	mov	dx,ax
	pop	bp
	jmp	near ptr aFreeExtMemory
SReallocExtMemory endp

; Scan the handle table for free blocks adjoining the current block.
FindAdjacent proc near
	mov	eax,[si].Base
	mov	edx,[si].Len
	add	edx,eax
	xor	di,di
	mov	bp,di
	mov	bx,cs:KiddValley
	mov	cx,cs:cHandles
	push	esi
FAScan:
	cmp	byte ptr [bx],1
	jnz	short FANext
	mov	esi,[bx].Base
	cmp	edx,esi
	jnz	short FACheckPrevious
	mov	bp,bx
	or	di,di
	jnz	short FAExit
FACheckPrevious:
	add	esi,[bx].Len
	cmp	esi,eax
	jnz	short FANext
	mov	di,bx
	or	bp,bp
	jnz	short FAExit
FANext:
	add	bx,0ah
	loop	FAScan
FAExit:
	pop	esi
	ret
FindAdjacent endp
; Descriptor tables used by the 386 and BIOS memory-move paths.
	public	GDT,GDTptr,RealModeSegment
GDT	label	byte
	dd	0,0
	dw	0ffffh,0
	db	0,09fh,0,0
	dw	0ffffh,0
	db	0,093h,0cfh,0
GDTptr	label	fword
	dw	18h
	dd	0

PrevInt13	dd	0
BIOSMoveGDT	label	byte
	dd	4 dup (0)
	dw	0ffffh
BIOSMoveSource	label	byte
	dw	0
	db	0,93h,0,0
	dw	0ffffh
BIOSMoveDest	label	byte
	dw	0
	db	0,93h,0,0
	dd	4 dup (0)

; Move a block using linear addresses, or use the BIOS in virtual 8086 mode.
	public	Movext386
Movext386	proc near

	sti
	push	bp
	mov	bp,sp
	sub	sp,12h
	push	eax
	push	ecx
	push	esi
	push	edi
	push	bx
	xor	ax,ax
	mov	[bp-6],ax
	mov	[bp-8],ax
	mov	[bp-0ah],ax
	mov	ecx,es:[si]
	mov	[bp-4],ecx
	shr	dword ptr [bp-4],1
	jc	near ptr MoveBadLength
	jz	short MoveDone
	lea	bx,[si+4]
	call	GetLinear386
	jc	near ptr MoveSourceError
	xchg	esi,edi
	mov	[bp-8],bx
	lea	bx,[di+0ah]
	call	GetLinear386
	jc	near ptr MoveError
	mov	[bp-0ah],bx
	smsw	ax
	shr	ax,1
	jc	near ptr MoveWithBios
	xor	cx,cx
	mov	es,cx
	mov	ax,cs
	shl	eax,10h
	mov	ax,offset Int13Handler
	cli
	push	dword ptr [PrevInt13]
	xchg	eax,es:[34h]
	mov	[PrevInt13],eax
	sti
	push	ds
	mov	ds,cx
	mov	ecx,[bp-4]
	shr	ecx,1
	cld
MoveDwords:
	rep	movs	dword ptr es:[edi],dword ptr ds:[esi]
	db	67h
	nop
	rcl	ecx,1
MoveWords:
	rep	movs	word ptr es:[edi],word ptr ds:[esi]
	db	67h
	nop
	pop	ds
	pop	eax
	cli
	xchg	eax,[PrevInt13]
	mov	es:[34h],eax
	sti
MoveDone:
	mov	bx,[bp-8]
	or	bx,bx
	jz	short MoveUnlockDest
	dec	byte ptr [bx+1]
MoveUnlockDest:
	mov	bx,[bp-0ah]
	or	bx,bx
	jz	short MoveResult
	dec	byte ptr [bx+1]
MoveResult:
	pop	bx
	pop	edi
	pop	esi
	pop	ecx
	pop	eax
	mov	ax,1
	cmp	word ptr [bp-6],0
	jz	short MoveReturn
	dec	ax
	mov	bl,[bp-6]
MoveReturn:
	mov	sp,bp
	pop	bp
	ret
MoveBadLength:
	mov	bl,0a7h
	jmp	short MoveError
MoveSourceError:
	cmp	bl,0a7h
	jz	short MoveError
	sub	bl,2
MoveError:
	mov	[bp-6],bl
	jmp	short MoveDone
Movext386 endp

; Convert the XMS handle and byte offset to a linear address.
GetLinear386 proc near
	cli
	mov	edi,es:[bx+2]
	mov	bx,es:[bx]
	or	bx,bx
	jz	short GLConventional
	cmp	byte ptr [bx],2
	jnz	short GLBadHandle
	mov	eax,[bx+6]
	shl	eax,0ah
	sub	eax,edi
	jc	short GLBadLength
	cmp	eax,ecx
	jc	short GLBadOffset
	inc	byte ptr [bx+1]
	mov	eax,[bx+2]
	shl	eax,0ah
	add	edi,eax
GLSuccess:
	clc
	sti
	ret
GLConventional:
	movzx	eax,di
	shr	edi,10h
	shl	edi,4
	add	edi,eax
	mov	eax,edi
	add	eax,ecx
	cmp	eax,10fff0h
	jna	short GLSuccess
GLBadOffset:
	mov	bl,0a7h
	jmp	short GLError
GLBadHandle:
	mov	bl,0a5h
	jmp	short GLError
GLBadLength:
	mov	bl,0a6h
GLError:
	stc
	sti
	ret
GetLinear386 endp

; Handle exception 13 for the real-mode move with extended segment limits.
Int13Handler proc far
	push	bp
	mov	bp,sp
	push	ax
	mov	al,0bh
	out	20h,al
	jmp	short CheckPIC
CheckPIC:
	in	al,20h
	test	al,20h
	jnz	short ChainInt13
	mov	ax,cs
	cmp	[bp+4],ax
	jnz	short ChainInt13
	cmp	word ptr [bp+2],offset MoveDwords
	jz	short SetLargeLimits
	cmp	word ptr [bp+2],offset MoveWords
	jnz	short ChainInt13
SetLargeLimits:
	mov	bx,10h
	lgdt	fword ptr cs:[GDTptr]
	mov	eax,cr0
	or	al,1
	mov	cr0,eax
	db	0eah			; far jump to the protected-mode code selector
	dw	offset SetProtectedSegments,8
SetProtectedSegments:
	mov	es,bx
	mov	ds,bx
	and	al,0feh
	mov	cr0,eax
	db	0eah			; far jump back to the resident real-mode segment
	dw	offset ReturnToRealMode
RealModeSegment dw 0
ReturnToRealMode:
	xor	ax,ax
	mov	ds,ax
	mov	es,ax
	pop	ax
	pop	bp
	iret
ChainInt13:
	pop	ax
	pop	bp
	jmp	dword ptr cs:PrevInt13
Int13Handler endp

; Use the BIOS block-move service in a virtual 8086 session.
MoveWithBios label near
	mov	[bp-0eh],esi
	mov	[bp-12h],edi
	push	cs
	pop	es
BiosMoveNext:
	mov	ecx,200h
	cmp	ecx,[bp-4]
	jna	short BiosMoveCount
	mov	ecx,[bp-4]
BiosMoveCount:
	push	ecx
	db	8dh,36h		; lea si,BIOSMoveGDT
	dw	offset BIOSMoveGDT
	db	8dh,3eh		; lea di,BIOSMoveSource
	dw	offset BIOSMoveSource
	mov	eax,[bp-0eh]
	cli
	cld
	stosw
	shr	eax,10h
	stosb
	mov	es:[di+2],ah
	db	8dh,3eh		; lea di,BIOSMoveDest
	dw	offset BIOSMoveDest
	mov	eax,[bp-12h]
	stosw
	shr	eax,10h
	stosb
	mov	es:[di+2],ah
	clc
	mov	ah,87h
	int	15h
	sti
	pop	ecx
	jc	short BiosMoveError
	sub	[bp-4],ecx
	jz	near ptr MoveDone
	shl	ecx,1
	add	[bp-0eh],ecx
	add	[bp-12h],ecx
	jmp	short BiosMoveNext
BiosMoveError:
	xor	bh,bh
	mov	bl,ah
	mov	bl,cs:[bx+BIOSMoveErrors]
	jmp	near ptr MoveError

BIOSMoveErrors db 0,0a9h,0a7h,82h
	db	7 dup (0)

Bios_Code	ends
	end
