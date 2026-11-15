;** CFGPUB.ASM - Publish boot configuration records through XMS
;
	.386
BootRegistryInfo equ 2d46h
_DATA segment word public use16 'RESUME_DATA'
	extrn ConfigXmsMove:byte,ConfigXmsHandle:word,ConfigXmsDriver:dword
	extrn ConfigFileLength:dword,ConfigXmsSize:word
_DATA ends
DGROUP group _DATA
SysResume segment byte public use16 'RESUME_CODE'
	assume cs:SysResume,ds:DGROUP

; Allocate an XMS block and copy the registry file into it.
	public ConfigBeginRecordFile
ConfigBeginRecordFile proc far
	push	bp
	mov	bp,sp
	add	sp,-2
	push	es
	push	ds
	push	si
	push	di
	mov	ax,4310h
	int	2fh
	mov	word ptr [ConfigXmsDriver],bx
	mov	ax,es
	mov	word ptr [ConfigXmsDriver+2],ax
	mov	word ptr [bp-2],0ffffh
	push	ds
	lds	di,dword ptr [bp+6]
	mov	ax,3d00h
	int	21h
	pop	ds
	mov	dx,2
	jc	short cpub_cleanup
	mov	[bp-2],ax
	mov	bx,ax
	mov	ax,4202h
	xor	cx,cx
	mov	dx,cx
	int	21h
	shl	edx,10h
	mov	dx,ax
	mov	[ConfigFileLength],edx
	mov	ax,4200h
	xor	cx,cx
	mov	dx,cx
	int	21h
	mov	edx,[ConfigFileLength]
	add	edx,[bp+0ah]
	add	edx,3ffh
	shr	edx,0ah
	mov	cx,dx
	mov	ah,9
	call	dword ptr [ConfigXmsDriver]
	or	ax,ax
	jz	short cpub_alloc_error
	mov	[ConfigXmsHandle],dx
	mov	[ConfigXmsSize],cx
	push	word ptr [bp-2]
	push	cs
	call	near ptr ConfigCopyRegistryFile
	add	sp,2
	mov	dx,ax
	jmp	short cpub_close
cpub_alloc_error:
	mov	dx,0eh
cpub_cleanup:
	cmp	word ptr [ConfigXmsHandle],-1
	jnz	short cpub_close
	mov	ah,0ah
	call	dword ptr [ConfigXmsDriver]
	mov	word ptr [ConfigXmsHandle],-1
cpub_close:
	mov	bx,[bp-2]
	cmp	bx,-1
	jz	short cpub_result
	mov	ah,3eh
	int	21h
cpub_result:
	or	dx,dx
	jnz	short cpub_done
	mov	ax,0ffffh
	mov	es,ax
	mov	di,BootRegistryInfo
	mov	eax,[ConfigFileLength]
	db 66h
	mov	es:[di],ax
	mov	eax,[bp+0ah]
	db 66h
	mov	es:[di+4],ax
	mov	ax,[ConfigXmsHandle]
	mov	es:[di+8],ax
	mov	ax,[ConfigXmsSize]
	mov	es:[di+0ah],ax
cpub_done:
	mov	ax,dx
	pop	di
	pop	si
	pop	ds
	pop	es
	mov	sp,bp
	pop	bp
	retf
ConfigBeginRecordFile endp

; Read the registry file in chunks and move them to XMS.
	public ConfigCopyRegistryFile
ConfigCopyRegistryFile proc far
	push	bp
	mov	bp,sp
	add	sp,-6
	push	ds
	push	si
	push	di
	mov	dword ptr [bp-4],0
	mov	word ptr [bp-6],0
	mov	bx,800h
	mov	ah,48h
	int	21h
	mov	dx,800eh
	jc	short ccrf_release
	mov	[bp-6],ax
ccrf_read:
	push	ds
	mov	bx,[bp+6]
	mov	ax,[bp-6]
	mov	ds,ax
	xor	dx,dx
	mov	cx,8000h
	mov	ah,3fh
	int	21h
	pop	ds
	jc	short ccrf_error
	or	ax,ax
	jz	short ccrf_error
	movzx	eax,ax
	lea	si,[ConfigXmsMove]
	add	eax,3
	and	eax,-4
	mov	[si],eax
	mov	word ptr [si+4],0
	mov	word ptr [si+6],0
	mov	dx,[bp-6]
	mov	[si+8],dx
	mov	dx,[ConfigXmsHandle]
	mov	[si+0ah],dx
	mov	ecx,[bp-4]
	mov	[si+0ch],ecx
	lea	ecx,[eax+ecx]
	mov	[bp-4],ecx
	mov	ah,0bh
	call	dword ptr [ConfigXmsDriver]
	or	ax,ax
	jz	short ccrf_error
	cmp	ecx,[ConfigFileLength]
	jc	short ccrf_read
	mov	dx,0
	jmp	short ccrf_release
ccrf_error:
	mov	dx,3f4h
ccrf_release:
	cmp	word ptr [bp-6],0
	jz	short ccrf_result
	mov	es,word ptr [bp-6]
	mov	ah,49h
	int	21h
ccrf_result:
	mov	ax,dx
	pop	di
	pop	si
	pop	ds
	mov	sp,bp
	pop	bp
	retf
ConfigCopyRegistryFile endp

; Append a configuration record after the registry file.
	public ConfigWriteRecord
ConfigWriteRecord proc far
	push	bp
	mov	bp,sp
	push	es
	push	si
	lea	si,[ConfigXmsMove]
	mov	eax,[bp+0eh]
	mov	[si],eax
	mov	word ptr [si+4],0
	mov	ecx,[bp+6]
	mov	[si+6],ecx
	mov	cx,[ConfigXmsHandle]
	mov	[si+0ah],cx
	mov	ecx,[ConfigFileLength]
	add	ecx,[bp+0ah]
	mov	[si+0ch],ecx
	mov	ah,0bh
	call	dword ptr [ConfigXmsDriver]
	or	ax,ax
	jnz	short cwr_done
	mov	ax,0
cwr_done:
	pop	si
	pop	es
	pop	bp
	retf
ConfigWriteRecord endp

SysResume ends
	end
