	page	,160
	title	HIBERIO - DOS services for system resume

	include	syscall.inc

SysResume	segment byte public 'RESUME_CODE'
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

SysResume	ends
	end
