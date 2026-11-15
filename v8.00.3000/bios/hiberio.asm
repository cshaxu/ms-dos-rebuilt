	page	,160
	title	HIBERIO - DOS services for system resume

	include	syscall.inc

	.386p
SysResume	segment byte public use16 'RESUME_CODE'
	assume	cs:SysResume,ds:nothing,es:nothing

; Far C calls leave the first word argument at BP+6.
Arg1	equ	6
Arg2	equ	8
Arg3	equ	10
Arg4	equ	12

	public	ResumeOpen,ResumeDelete,ResumeClose
	public	ResumeRead,ResumeWrite,ResumeSeek
	public	ResumeAlloc,ResumeFree,ResumePrint,ResumeReadKey

; Open a file for read and write. Return -1 if DOS reports an error.
ResumeOpen proc far
	push	bp
	mov	bp,sp
	push	ds
	lds	dx,[bp+Arg1]
	mov	ax,(Open shl 8) or 2
	int	21h
	sbb	cx,cx
	or	ax,cx
	pop	ds
	pop	bp
	ret
ResumeOpen endp

; Delete the ASCIIZ file passed by the caller.
ResumeDelete proc far
	push	bp
	mov	bp,sp
	push	ds
	lds	dx,[bp+Arg1]
	mov	ah,Unlink
	int	21h
	pop	ds
	pop	bp
	ret
ResumeDelete endp

ResumeClose proc far
	push	bp
	mov	bp,sp
	push	bx
	mov	bx,[bp+Arg1]
	mov	ah,Close
	int	21h
	pop	bx
	pop	bp
	ret
ResumeClose endp

; Read up to the requested count. Return zero on a DOS error.
ResumeRead proc far
	push	bp
	mov	bp,sp
	push	ds
	push	bx
	mov	bx,[bp+Arg1]
	mov	cx,[bp+Arg2]
	lds	dx,[bp+Arg3]
	mov	ah,Read
	int	21h
	cmc
	sbb	cx,cx
	and	ax,cx
	pop	bx
	pop	ds
	pop	bp
	ret
ResumeRead endp

; Write and commit the requested bytes. Return the saved write count.
ResumeWrite proc far
	push	bp
	mov	bp,sp
	push	ds
	push	bx
	mov	bx,[bp+Arg1]
	mov	cx,[bp+Arg2]
	lds	dx,[bp+Arg3]
	mov	ah,Write
	int	21h
	cmc
	sbb	cx,cx
	and	ax,cx
	push	ax
	mov	ah,Commit
	int	21h
	pop	ax
	pop	bx
	pop	ds
	pop	bp
	ret
ResumeWrite endp

; Seek either from the beginning or from the current position.
ResumeSeek proc far
	push	bp
	mov	bp,sp
	push	bx
	mov	bx,[bp+Arg1]
	mov	cx,[bp+Arg3]
	mov	dx,[bp+Arg2]
	mov	ax,LSeek shl 8
	cmp	word ptr [bp+Arg4],0
	jnz	short DoResumeSeek
	inc	ax
DoResumeSeek:
	int	21h
	sbb	ax,ax
	inc	ax
	pop	bx
	pop	bp
	ret
ResumeSeek endp

; Allocate paragraphs and pass the returned block size to the caller.
ResumeAlloc proc far
	push	bp
	mov	bp,sp
	push	ds
	push	bx
	mov	bx,[bp+Arg1]
	mov	ah,Alloc
	int	21h
	mov	cx,bx
	cmc
	lds	bx,[bp+Arg2]
	sbb	dx,dx
	mov	[bx],cx
	and	ax,dx
	pop	bx
	pop	ds
	pop	bp
	ret
ResumeAlloc endp

ResumeFree proc far
	push	bp
	mov	bp,sp
	push	es
	mov	es,[bp+Arg1]
	mov	ah,Dealloc
	int	21h
	pop	es
	pop	bp
	ret
ResumeFree endp

; Print the writable ASCIIZ buffer as a DOS string and restore its null.
ResumePrint proc far
	push	bp
	mov	bp,sp
	push	es
	push	ds
	push	di
	lds	di,[bp+Arg1]
	mov	ax,ds
	mov	es,ax
	cld
	mov	cx,-1
	xor	al,al
	repnz	scasb
	dec	di
	mov	byte ptr [di],'$'
	mov	dx,di
	add	dx,cx
	inc	dx
	inc	dx
	mov	ah,Std_Con_String_Output
	int	21h
	mov	byte ptr [di],0
	pop	di
	pop	ds
	pop	es
	pop	bp
	ret
ResumePrint endp

ResumeReadKey proc far
	mov	ax,(Std_Con_Input_Flush shl 8) or 1
	int	21h
	ret
ResumeReadKey endp

; GDT for the page-copy transition.
ResumeGdt label byte
	dq	0
	dw	0FFFFh
ResumeCodeBase dw 0
ResumeCodeBaseHigh db 0
	db	9Fh,0,0
	dw	0FFFFh,0
	db	0,93h,0CFh,0
ResumeGdtPointer label fword
	dw	$-ResumeGdt-1
ResumeGdtAddress dd 0
	dw	3 dup (0)

; Sum the saved doublewords.
	public ResumeChecksum
ResumeChecksum proc far
	push	bp
	mov	bp,sp
	push	ds
	push	si
	lds	si,dword ptr [bp+6]
	mov	ecx,[bp+0ah]
	shr	ecx,2
	xor	edx,edx
	cld
rchs_next:
	lodsd
	add	edx,eax
	loop	rchs_next
	movzx	eax,dx
	shr	edx,10h
	pop	si
	pop	ds
	pop	bp
	retf
ResumeChecksum endp

; Copy saved pages to their physical addresses in protected mode.
	public ResumeCopyPages
ResumeCopyPages proc far
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	esi
	push	edi
	push	ebx
	pushf
	cli
	mov	ebx,[bp+6]
	mov	esi,[bp+0ah]
	mov	edx,[bp+0eh]
	xor	eax,eax
	mov	ax,cs
	shl	eax,4
	mov	cs:ResumeCodeBase,ax
	rol	eax,10h
	mov	cs:ResumeCodeBaseHigh,al
	rol	eax,10h
	add	eax,offset ResumeGdt
	db 66h
	mov word ptr cs:ResumeGdtAddress,ax
	db 66h
	lgdt fword ptr cs:ResumeGdtPointer
	mov	eax,cr0
	or	al,1
	mov	cr0,eax
	db 0EAh			; far jump to the protected-mode code selector
	dw offset rcp_protected,8
rcp_protected:
	mov	ax,10h
	mov	es,ax
	mov	ds,ax
	cld
	xor	ecx,ecx
	xor	ebp,ebp
rcp_run:
	mov	edi,[ebx]
	inc	ecx
	add	ebx,4
	inc	edi
rcp_count:
	cmp	ecx,edx
	jz	short rcp_copy_run
	cmp	[ebx],edi
	jnz	short rcp_copy_run
	inc	ecx
	add	ebx,4
	inc	edi
	jmp	short rcp_count
rcp_copy_run:
	sub	edx,ecx
	sub	edi,ecx
	shl	ecx,0ah
	shl	edi,0ch
rcp_copy_page:
	db 67h
	lodsd
	add	ebp,eax
	db 67h
	stosd
	db 67h
	loop rcp_copy_page
	or	edx,edx
	jnz	short rcp_run
	mov	eax,cr0
	and	al,0feh
	mov	cr0,eax
	db 0EAh			; reload CS after returning to real mode
	dw offset rcp_real,seg rcp_real
rcp_real:
	mov	edx,ebp
	movzx	ebp,bp
	mov	ax,bp
	shr	edx,10h
	popf
	pop	ebx
	pop	edi
	pop	esi
	pop	es
	pop	ds
	pop	bp
	retf
ResumeCopyPages endp

; Set up the descending final copy and return to the resumed system.
	public ResumeTransferControl
ResumeTransferControl proc far
	push bp
	mov	bp,sp
	les	di,dword ptr [bp+6]
	xor	ax,ax
	lds	si,dword ptr [bp+0ch]
	mov	cx,[bp+0ah]
	mov	ss,ax
	mov	sp,700h
	push	es
	push	di
	add	si,cx
	add	di,cx
	dec	si
	dec	di
	cli
	std
	db 0EAh			; execute the transfer stub at physical address zero
	dw 0,0
ResumeTransferControl endp

SysResume ends
	end
