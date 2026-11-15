;/*
; *                      Microsoft Confidential
; *			 Copyright (C) Microsoft Corporation 1988-1992
; *                      All Rights Reserved.
; */
	page	,160
	title	HIMEM1 - A20 Handler stuff

HimemInitSeg	segment byte public 'HIMEM_INIT'
	.386p
	assume	cs:HimemInitSeg,ds:HimemInitSeg

	public	TestA20,EnableATA20

ATA20Delay	db	0	; Keyboard controller delay method

; Save the first interrupt vector while checking for wrap at one megabyte.
TestA20 proc near
	push	ds
	push	es
	xor	eax,eax
	mov	ds,ax
	dec	ax
	mov	es,ax
	mov	eax,ds:[0]
	mov	dword ptr ds:[0],55aa55aah
	cmp	dword ptr es:[10h],55aa55aah
	jnz	short RestoreVector
	mov	dword ptr ds:[0],0aa55aa55h
	cmp	dword ptr es:[10h],0aa55aa55h
RestoreVector:
	mov	ds:[0],eax
	pop	es
	pop	ds
	ret
TestA20 endp

; Change A20 through the keyboard controller input port.
AT_A20Handler proc near
	or	ax,ax
	mov	ah,0dfh
	jnz	short SendA20Command
	mov	ah,0ddh
SendA20Command:
	call	Sync8042
	jnz	short A20Failure
	mov	al,0d1h
	out	64h,al
	call	Sync8042
	jnz	short A20Failure
	mov	al,ah
	out	60h,al
	call	Sync8042
	jnz	short A20Failure
	xor	cx,cx
	mov	cl,cs:[ATA20Delay]
	jcxz	Pulse8042
	dec	cx
	jcxz	A20Success
	jmp	short WaitRefresh
Pulse8042:
	mov	al,0ffh
	out	64h,al
	call	Sync8042
	jnz	short A20Failure
	jmp	short A20Success
WaitRefresh:
	mov	cx,2
WaitRefreshHigh:
	jmp	short ReadRefreshHigh
ReadRefreshHigh:
	in	al,61h
	test	al,10h
	jz	short WaitRefreshHigh
WaitRefreshLow:
	jmp	short ReadRefreshLow
ReadRefreshLow:
	in	al,61h
	test	al,10h
	jnz	short WaitRefreshLow
	loop	WaitRefreshHigh
A20Success:
	mov	ax,1
	ret
A20Failure:
	xor	ax,ax
	ret
AT_A20Handler endp

; Wait for the keyboard controller to accept an input byte.
Sync8042 proc near
	xor	cx,cx
WaitInputBuffer:
	jmp	short Read8042
Read8042:
	in	al,64h
	and	al,2
	loopne	WaitInputBuffer
	ret
Sync8042 endp

; Try each keyboard-controller delay method before reporting failure.
EnableATA20 proc near
	pushf
	cli
	mov	ax,1
	call	AT_A20Handler
	popf
	or	ax,ax
	jnz	short EnableA20Exit
	xor	ax,ax
	call	AT_A20Handler
	inc	byte ptr [ATA20Delay]
	cmp	byte ptr [ATA20Delay],2
	jna	short EnableATA20
	stc
EnableA20Exit:
	ret
EnableATA20 endp

HimemInitSeg	ends
	end
