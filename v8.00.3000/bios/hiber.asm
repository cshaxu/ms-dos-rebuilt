;** HIBER.ASM - Resume a saved Windows session at boot
;
	.386
HiberFileSignature equ 5059534Ah
HiberRestoreSignature equ 534A5059h
_DATA segment word public use16 'RESUME_DATA'
	extrn HiberFileName:byte
_DATA ends
DGROUP group _DATA
SysResume segment byte public use16 'RESUME_CODE'
	assume cs:SysResume,ds:DGROUP
	extrn AsdJoinPath:far
	extrn ResumeOpen:far,ResumeDelete:far,ResumeClose:far
	extrn ResumeRead:far,ResumeWrite:far,ResumeSeek:far
	extrn ResumeAlloc:far,ResumeFree:far
	extrn ResumeChecksum:far,ResumeCopyPages:far,ResumeTransferControl:far

; Check the resume file and record that restoration has started.
	public ResumeCheckHeader
ResumeCheckHeader proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	si,[bp+8]
	mov	es,word ptr [bp+0ah]
	cmp	dword ptr es:[si],2
	jna	short rhc_signature
rhc_false:
	xor	ax,ax
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
rhc_signature:
	cmp	dword ptr es:[si+4],HiberRestoreSignature
	jz	short rhc_prompt
	cmp	dword ptr es:[si+4],HiberFileSignature
	jnz	short rhc_false
	mov	di,[bp+6]
	mov	dword ptr es:[si+4],HiberRestoreSignature
	db 66h,68h		; PUSH dword immediate
	dd 10000h
	push	0
	push	di
	call	far ptr ResumeSeek
	add	sp,8
	push	word ptr [bp+0ah]
	push	si
	push	18h
	push	di
	call	far ptr ResumeWrite
	add	sp,8
	jmp	short rhc_true
rhc_prompt:
	db 66h
	push 2
	call	dword ptr [bp+10h]
	add	sp,4
	cbw
	cmp	ax,79h
	jz	short rhc_true
	ja	short rhc_prompt
	sub	al,4eh
	jz	short rhc_delete
	sub	al,0bh
	jz	short rhc_true
	sub	al,15h
	jnz	short rhc_prompt
rhc_delete:
	push	dword ptr [bp+0ch]
	call	far ptr ResumeDelete
	add	sp,4
	jmp	short rhc_false
	nop
rhc_true:
	mov	ax,1
	pop	ds
	pop	si
	pop	di
	leave
	retf
ResumeCheckHeader endp

; Validate the saved pages and restore their contents.
	public ResumeRestoreFile
ResumeRestoreFile proc far
	enter	40h,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	word ptr [bp-24h],0fh
	db 66h
	push 1
	call	dword ptr [bp+0ch]
	add	sp,4
	mov	word ptr [bp-20h],0
	lea	ax,[bp-20h]
	push	ss
	push	ax
	push	-1
	call	far ptr ResumeAlloc
	add	sp,6
	mov	al,[bp-1fh]
	sub	ah,ah
	mov	si,ax
	cmp	si,3
	jnc	short rrf_alloc_pages
rrf_alloc_failed:
	xor	ax,ax
	cwd
	pop	ds
	pop	si
	pop	di
	leave
	retf
rrf_alloc_pages:
	mov	[bp-2ch],ax
	lea	ax,[bp-20h]
	push	ss
	push	ax
	push	word ptr [bp-20h]
	call	far ptr ResumeAlloc
	add	sp,6
	mov	[bp-20h],ax
	or	ax,ax
	jz	short rrf_alloc_failed
	mov	[bp-22h],ax
	mov	si,[bp-2ch]
	test	al,0ffh
	jz	short rrf_setup
	dec	si
	mov	byte ptr [bp-20h],0
	add	byte ptr [bp-1fh],1
rrf_setup:
	mov	ax,[bp-20h]
	sub	dx,dx
	mov	cx,ax
	mov	bx,dx
	mov	[bp-2ah],dx
	mov	[bp-28h],ax
	add	cx,ax
	adc	bx,dx
	add	cx,cx
	adc	bx,bx
	add	cx,cx
	adc	bx,bx
	add	cx,cx
	adc	bx,bx
	mov	[bp-14h],cx
	mov	[bp-12h],bx
	dec	si
	cmp	si,0fh
	jnc	short rrf_header
	mov	[bp-24h],si
rrf_header:
	mov	[bp-2ch],si
	mov	di,[bp+8]
	add	ah,1
	mov	[bp-34h],dx
	mov	[bp-32h],ax
	add	ax,ax
	adc	dx,dx
	add	ax,ax
	adc	dx,dx
	add	ax,ax
	adc	dx,dx
	add	ax,ax
	adc	dx,dx
	mov	[bp-18h],ax
	mov	[bp-16h],dx
	mov	es,word ptr [bp+0ah]
	mov	dword ptr es:[di+4],HiberFileSignature
	db 66h
	push 24
	push	es
	push	di
	call	far ptr ResumeChecksum
	add	sp,8
	mov	[bp-1ch],ax
	mov	[bp-1ah],dx
	mov	es,word ptr [bp+0ah]
	db 66h
	mov	ax,es:[di+8]
	mov	[bp-38h],eax
	mov	ecx,4ch
	xor	edx,edx
	div	ecx
	mov	[bp-4],eax
	or	eax,eax
	jnz	short rrf_table
	inc	dword ptr [bp-4]
rrf_table:
	mov	eax,[bp-4]
	mov	[bp-0ch],eax
	mov	eax,[bp-38h]
	mov	[bp-8],eax
	mov	dword ptr [bp-10h],3fah
	or	eax,eax
	jz	near ptr rrf_result
rrf_first_page:
	mov	si,[bp-2ah]
	mov	eax,[bp-10h]
	cmp	eax,[bp-8]
	jna	short rrf_read_table
	mov	ax,[bp-8]
rrf_read_table:
	mov	di,ax
	mov	word ptr [bp-1eh],0
	push	word ptr [bp-28h]
	push	si
	shl	ax,2
	push	ax
	push	word ptr [bp+6]
	mov	[bp-3ah],ax
	call	far ptr ResumeRead
	add	sp,8
	cmp	[bp-3ah],ax
	jnz	near ptr rrf_cleanup
	sub	ax,ax
	mov	[bp-3eh],di
	mov	[bp-3ch],ax
	cmp	[bp-8],di
	jnz	short rrf_verification
	cmp	[bp-6],ax
	jnz	short rrf_verification
	push	ax
	mov	ax,[bp-10h]
	mov	dx,[bp-0eh]
	sub	ax,di
	sbb	dx,[bp-3ch]
	add	ax,ax
	adc	dx,dx
	add	ax,ax
	adc	dx,dx
	push	dx
	push	ax
	push	word ptr [bp+6]
	call	far ptr ResumeSeek
	add	sp,8
	or	ax,ax
	jz	near ptr rrf_cleanup
rrf_verification:
	mov	ax,di
	shl	ax,2
	push	0
	push	ax
	push	word ptr [bp-28h]
	push	si
	call	far ptr ResumeChecksum
	add	sp,8
	add	[bp-1ch],ax
	adc	[bp-1ah],dx
	mov	[bp-0eh],di
	or	di,di
	jz	near ptr rrf_next_run
	mov	[bp-26h],di
rrf_table_count:
	mov	eax,[bp-34h]
	mov	[bp-30h],eax
	mov	di,[bp-0eh]
	mov	si,[bp-2ch]
	cmp	di,si
	jna	short rrf_copy_page
	mov	di,si
rrf_copy_page:
	mov	[bp-10h],di
	or	di,di
	jz	short rrf_copy
rrf_next_page:
	mov	si,[bp-24h]
	cmp	si,di
	jna	short rrf_read_page
	mov	si,di
rrf_read_page:
	push	dword ptr [bp-30h]
	mov	ax,si
	shl	ax,0ch
	push	ax
	push	word ptr [bp+6]
	mov	[bp-40h],ax
	call	far ptr ResumeRead
	add	sp,8
	cmp	ax,[bp-40h]
	jnz	near ptr rrf_cleanup
	mov	ax,[bp-2eh]
	mov	cx,si
	mov	ch,cl
	sub	cl,cl
	add	ax,cx
	mov	word ptr [bp-30h],0
	mov	[bp-2eh],ax
	sub	di,si
	sub	ax,ax
	sub	[bp-0ch],si
	sbb	[bp-0ah],ax
	cmp	[bp-0ah],ax
	jnl	short rrf_progress
	mov	eax,[bp-4]
	add	[bp-0ch],eax
	db 66h
	push 3
	call	dword ptr [bp+0ch]
	add	sp,4
rrf_progress:
	or	di,di
	jnz	short rrf_next_page
rrf_copy:
	push	0
	push	word ptr [bp-10h]
	push	dword ptr [bp-18h]
	mov	ax,[bp-1eh]
	shl	ax,2
	sub	dx,dx
	add	ax,[bp-14h]
	adc	dx,[bp-12h]
	push	dx
	push	ax
	call	far ptr ResumeCopyPages
	add	sp,0ch
	add	[bp-1ch],ax
	adc	[bp-1ah],dx
	mov	ax,[bp-10h]
	add	[bp-1eh],ax
	sub	[bp-0eh],ax
	jnz	near ptr rrf_table_count
rrf_next_run:
	mov	dword ptr [bp-10h],400h
	mov	eax,[bp-3eh]
	sub	[bp-8],eax
	cmp	dword ptr [bp-8],0
	jnz	near ptr rrf_first_page
rrf_result:
	mov	dx,[bp-20h]
	sub	cx,cx
	mov	si,cx
	mov	[bp-2],dx
	push	dx
	push	cx
	push	1000h
	push	word ptr [bp+6]
	call	far ptr ResumeRead
	add	sp,8
	cmp	ax,1000h
	jz	short rrf_checksum
rrf_cleanup:
	push	word ptr [bp-22h]
	call	far ptr ResumeFree
	add	sp,2
	jmp	near ptr rrf_alloc_failed
rrf_checksum:
	push	si
	push	1000h
	push	word ptr [bp-2]
	push	si
	call	far ptr ResumeChecksum
	add	sp,8
	add	ax,[bp-1ch]
	adc	dx,[bp-1ah]
	or	dx,ax
	jnz	short rrf_cleanup
	mov	ax,si
	mov	dx,[bp-2]
	pop	ds
	pop	si
	pop	di
	leave
	retf
ResumeRestoreFile endp

; Open the resume file and transfer control to the restored system.
	public BootResume
BootResume proc far
	enter	11ch,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	push	ax
	push	offset DGROUP:HiberFileName
	push	dword ptr [bp+6]
	lea	ax,[bp-11ch]
	push	ss
	push	ax
	push	cs
	call	near ptr AsdJoinPath
	add	sp,0ch
	lea	ax,[bp-11ch]
	push	ss
	push	ax
	call	far ptr ResumeOpen
	add	sp,4
	mov	si,ax
	cmp	si,-1
	jz	near ptr br_done
	lea	ax,[bp-1ch]
	push	ss
	push	ax
	push	18h
	push	si
	call	far ptr ResumeRead
	add	sp,8
	cmp	ax,18h
	jz	short br_header
br_close:
	push	si
	call	far ptr ResumeClose
	add	sp,2
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
br_header:
	push	dword ptr [bp+0ah]
	lea	ax,[bp-11ch]
	push	ss
	push	ax
	lea	ax,[bp-1ch]
	push	ss
	push	ax
	push	si
	push	cs
	call	near ptr ResumeCheckHeader
	add	sp,0eh
	or	ax,ax
	jz	short br_close
	push	dword ptr [bp+0ah]
	lea	ax,[bp-1ch]
	push	ss
	push	ax
	push	si
	push	cs
	call	near ptr ResumeRestoreFile
	add	sp,0ah
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jnz	short br_transfer
	db 66h
	push 4
	call	dword ptr [bp+0ah]
	add	sp,4
	jmp	short br_close
	nop
br_transfer:
	db 66h
	push 5
	call	dword ptr [bp+0ah]
	add	sp,4
	mov	eax,[bp-8]
	shr	eax,4
	mov	edx,eax
	shr	edx,10h
	mov	cx,ax
	xor	bx,bx
	mov	es,bx
	mov	dword ptr es:[0],0cbfca4f3h
	push	dword ptr [bp-4]
	push	1000h
	sub	ax,ax
	push	cx
	push	ax
	mov	si,ax
	mov	di,cx
	call	far ptr ResumeTransferControl
	add	sp,0ah
	push	dword ptr [bp-4]
	push	1000h
	push	di
	push	si
	call	far ptr ResumeTransferControl
	add	sp,0ah
br_done:
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
BootResume endp

SysResume ends
	end
