;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1988-1992
; *                      All Rights Reserved.
; */
	page	,160
	title	HIMEM2 - Initialization code

	include	himem.inc
	include	bioscode.inc

Bios_Code	segment byte public 'CODE'
	extrn	Int2fHandler:far,Int15Handler:far
	extrn	PrevInt2f:dword,PrevInt15:dword
	extrn	cHandles:word,KiddValley:word,KiddValleyTop:word
	extrn	RealModeSegment:word,segKiddValley:word
	extrn	GDT:byte,GDTptr:fword
Bios_Code	ends

HimemInitSeg	segment byte public 'HIMEM_INIT'
	.386p
	assume	cs:HimemInitSeg,ds:HimemInitSeg,es:Bios_Code

	extrn	TestA20:near,EnableATA20:near
	public	InitMemory,InitInterrupt,HimemMessage

InitData	dd	54h
HimemMessage	dd	-1	; SYSINIT message routine
fInfoMsg	db	1	; Display informational messages
MaxExtMemory	dd	0	; Highest extended-memory address in K
MemoryCount	db	'00000000$'

; Discover extended memory and reserve the first 64K for the HMA.
InitDriver proc near
	cld
	mov	ah,2
	int	16h
	test	al,8
	jz	short CheckA20
	mov	byte ptr [fInfoMsg],0
CheckA20:
	call	TestA20
	jnz	short InitHandleTable
	call	EnableATA20
	jc	short InitMemoryError
InitHandleTable:
	call	InitHandles
	call	GetMemoryMap
	jnc	short SetDosMemory
	call	GetInt15Memory
	or	ax,ax
	jz	short TryE801
	movzx	edx,ax
	mov	eax,400h
	call	AddMem
TryE801:
	call	GetBIGMemory
SetDosMemory:
	push	es
	mov	ah,52h
	int	21h
	mov	eax,[MaxExtMemory]
	cmp	eax,10000h
	sbb	ecx,ecx
	not	cx
	or	ax,cx
	mov	es:[bx+45h],ax
	pop	es
	mov	bx,es:[KiddValley]
	mov	cx,es:[cHandles]
	xor	eax,eax
FindHma:
	cmp	byte ptr es:[bx],1
	jnz	short NextHmaBlock
	mov	eax,es:[bx].Base
	cmp	eax,400h
	jz	short ReserveHma
NextHmaBlock:
	add	bx,size Handle
	loop	FindHma
NoHmaBlock:
	mov	dx,14h
	or	eax,eax
	jnz	short InitMemoryError
	mov	dx,9
InitMemoryError:
	push	dx
	call	DispErrMsg
	pop	dx
	mov	dx,0ch
	call	DispErrMsg
InitMemoryHalt:
	cli
	hlt
	jmp	short InitMemoryHalt
ReserveHma:
	mov	ecx,es:[bx].Len
	cmp	ecx,40h
	jna	short NoHmaBlock
	add	dword ptr es:[bx].Base,40h
	sub	dword ptr es:[bx].Len,40h
	mov	dx,17h
	call	DispInfoMsg
	ret
InitDriver endp

; Check whether informational output is enabled.
DispInfoMsg proc near
	cmp	byte ptr cs:[fInfoMsg],0
	jnz	short InfoMsgExit
InfoMsgExit:
	ret
DispInfoMsg endp

; Pass the initialization message index to SYSINIT.
DispErrMsg proc near
	mov	byte ptr cs:[fInfoMsg],0
	mov	ax,dx
	push	ax
	call	dword ptr cs:[HimemMessage]
	add	sp,2
	ret
DispErrMsg endp

; Read the original BIOS extended-memory count.
GetInt15Memory proc near
	mov	ah,88h
	clc
	int	15h
	jnc	short Int15MemoryExit
	xor	ax,ax
Int15MemoryExit:
	ret
GetInt15Memory endp

; Read the BIOS memory count above sixteen megabytes.
GetBIGMemory proc near
	push	dx
	push	cx
	push	bx
	push	si
	push	es
	push	es
	push	bp
	mov	bp,sp
	sub	sp,20h
	mov	bx,sp
	shr	bx,4
	inc	bx
	mov	ax,ss
	add	ax,bx
	mov	es,ax
	mov	ax,0e801h
	xor	bx,bx
	stc
	int	15h
	mov	sp,bp
	pop	bp
	pop	es
	jc	short BigMemoryExit
	test	bx,bx
	jz	short BigMemoryExit
	cmp	ax,4000h
	ja	short BigMemoryExit
	movzx	edx,bx
	shl	edx,6
	mov	eax,4000h
	call	AddMem
BigMemoryExit:
	pop	es
	pop	si
	pop	bx
	pop	cx
	pop	dx
	ret
	db	4 dup (0)
SMAPBuffer	db	20 dup (0)
GetBIGMemory endp

; Walk the BIOS SMAP entries and add usable extended-memory ranges.
GetMemoryMap proc near
	push	es
	push	ds
	pop	es
	xor	ebx,ebx
NextMemoryRange:
	mov	di,offset SMAPBuffer
	mov	ecx,14h
	mov	edx,534d4150h
	mov	eax,0e820h
	int	15h
	jc	short MemoryMapExit
	cmp	eax,534d4150h
	jnz	short MemoryMapExit
	cmp	ecx,14h
	jnz	short MemoryMapExit
	cmp	dword ptr [di+10h],1
	jnz	short ContinueMemoryMap
	cmp	dword ptr [di+4],0
	jnz	short ContinueMemoryMap
	mov	eax,es:[di]
	cmp	eax,100000h
	jc	short ContinueMemoryMap
	mov	edx,0ffffffffh
	cmp	dword ptr es:[di+0ch],0
	jnz	short AddMemoryRange
	mov	edx,es:[di+8]
AddMemoryRange:
	shr	eax,0ah
	shr	edx,0ah
	call	AddMem
ContinueMemoryMap:
	or	ebx,ebx
	jnz	short NextMemoryRange
MemoryMapExit:
	cmp	dword ptr [MaxExtMemory],1
	pop	es
	ret
GetMemoryMap endp

; Initialize Kidd Valley with the configured number of empty handles.
InitHandles proc near
	push	ds
	push	es
	pop	ds
	assume	ds:Bios_Code
	mov	cx,[cHandles]
	mov	bx,[KiddValley]
	xor	eax,eax
InitOneHandle:
	mov	byte ptr [bx],4
	mov	[bx].cLock,al
	mov	[bx].Base,eax
	mov	[bx].Len,eax
	add	bx,size Handle
	loop	InitOneHandle
	mov	[KiddValleyTop],bx
	pop	ds
	ret
	assume	ds:HimemInitSeg
InitHandles endp

; Hook the HMA INT 2Fh and INT 15h handlers and set up the GDT.
InitInterrupt proc far
	push	ds
	push	eax
	mov	eax,0ffff0000h
	mov	ds,ax
	mov	ax,offset Int2fHandler
	xchg	eax,ds:[2fh*4]
	mov	es:[PrevInt2f],eax
	db	66h,0b8h		; MOV EAX, HMA vector
	dw	offset Int15Handler,0ffffh
	xchg	eax,ds:[15h*4]
	mov	es:[PrevInt15],eax
	mov	ax,0ffffh
	call	InitGDT
	pop	eax
	pop	ds
	retf
InitInterrupt endp

; Add a free block in kilobytes, coalescing overlapping ranges.
AddMem proc near
	pushad
	lea	esi,[edx+eax*1]
	cmp	esi,[MaxExtMemory]
	jna	short ScanHandles
	mov	[MaxExtMemory],esi
ScanHandles:
	push	ds
	push	Bios_Code
	pop	ds
	assume	ds:Bios_Code
	xor	di,di
	mov	bx,[KiddValley]
	mov	cx,[cHandles]
TestHandle:
	cmp	byte ptr [bx],4
	jnz	short TestFreeHandle
	or	di,di
	jnz	short NextHandle
	mov	di,bx
	jmp	short NextHandle
TestFreeHandle:
	cmp	byte ptr [bx],1
	jnz	short NextHandle
	mov	ebp,[bx].Base
	add	ebp,[bx].Len
	cmp	ebp,eax
	jc	short NextHandle
	cmp	esi,[bx].Base
	jc	short NextHandle
	mov	edx,esi
	cmp	eax,[bx].Base
	jna	short MergeUpper
	mov	eax,[bx].Base
MergeUpper:
	cmp	edx,ebp
	jnc	short SetMergedRange
	mov	edx,ebp
SetMergedRange:
	mov	esi,edx
	sub	edx,eax
	mov	byte ptr [bx],4
	or	di,di
	jnz	short NextHandle
	mov	di,bx
NextHandle:
	add	bx,size Handle
	loop	TestHandle
	or	di,di
	jz	short AddMemExit
	mov	byte ptr [di].cLock,0
	mov	byte ptr [di],1
	mov	[di].Base,eax
	mov	[di].Len,edx
AddMemExit:
	pop	ds
	popad
	ret
	assume	ds:HimemInitSeg
AddMem endp

; Initialize the XMS memory map using the caller supplied resident segment.
InitMemory proc far
	pusha
	mov	bp,sp
	push	ds
	push	es
	push	cs
	pop	ds
	mov	ax,[bp+14h]
	mov	es,ax
	call	InitDriver
	pop	es
	pop	ds
	popa
	retf	2
InitMemory endp

; Set the code descriptor and GDT pointer from the resident segment.
InitGDT proc near
	push	ds
	mov	ds,ax
	assume	ds:Bios_Code
	mov	[RealModeSegment],ax
	mov	[segKiddValley],ax
	mov	cx,10h
	mul	cx
	mov	word ptr [GDT+0ah],ax
	mov	[GDT+0ch],dl
	add	ax,offset GDT
	adc	dx,0
	mov	word ptr [GDTptr+2],ax
	mov	word ptr [GDTptr+4],dx
	pop	ds
	ret
	assume	ds:HimemInitSeg
InitGDT endp

	db	0
HimemInitSeg	ends
	end
