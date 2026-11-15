; Registry key handles and file descriptor lists.
;
; Near entries take stack arguments and use DS = DGROUP.
; Pointer results are returned in DX:AX where specified.
;
	.386
_DATA segment word public use16 'RESUME_DATA'
	extrn RegClassesPath:byte
	extrn RegDefaultUser:byte
	extrn RegClassesCell:dword,RegClassesFile:dword
	extrn RegKeyPool:dword
	extrn RegDynamicKeys:dword,RegDeferredKeys:dword,RegDeferredCount:dword
	extrn RegMachineRoot:byte
	extrn RegUserRoot:byte,RegAuxRoot:byte
	extrn RegClassesFileName:byte
	extrn RegClassesName:byte,RegClassesLength:word,RegClassesSum:word
	extrn RegSoftwareName:byte,RegSoftwareLength:word,RegSoftwareSum:word
	extrn RegPredefinedKeys:dword
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'RESUME_CODE'
_TEXT ends
REGTEXT segment word public use16 'RESUME_CODE'
SysResume segment byte public use16 'RESUME_CODE'
SysResume ends
CGROUP group SysResume,_TEXT,REGTEXT
	assume cs:CGROUP,ds:DGROUP
	extrn RegDosAlloc:near
	extrn RegDosFree:near
	extrn RegDosRealloc:near
RegistryCode label byte
	extrn RegSaveFile:near
	extrn RegMaintainCache:near
	extrn RegForEachFile:near
	extrn RegOpenPath:near
	extrn RegNameChecksum:near,RegLastPathSeparator:near,RegAttachRoot:near
	public RegAllocate
RegAllocate proc near
	enter 6,0
	push di
	mov ax,[bp+4]
	mov [bp-2],ax
	push ax
	call RegDosAlloc
	mov [bp-4],dx
	or dx,ax
	jnz short rar_done
	mov di,[bp-2]
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push di
	call RegDosAlloc
	mov [bp-4],dx
	or dx,ax
	jnz short rar_done
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push di
	call RegDosAlloc
	mov [bp-4],dx
	or dx,ax
	jnz short rar_done
	push offset CGROUP:RegSaveFile
	call RegForEachFile
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push di
	call RegDosAlloc
	mov [bp-4],dx
rar_done:
	mov dx,[bp-4]
	pop di
	leave
	ret 2
RegAllocate endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegReallocRetry
RegReallocRetry proc near
	enter 6,0
	push di
	mov di,[bp+6]
	push word ptr [bp+8]
	push di
	mov ax,[bp+4]
	mov [bp-2],ax
	push ax
	call RegDosRealloc
	mov [bp-4],dx
	or dx,ax
	jnz short rrr_done
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push word ptr [bp+8]
	push di
	push word ptr [bp-2]
	call RegDosRealloc
	mov [bp-4],dx
	or dx,ax
	jnz short rrr_done
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push word ptr [bp+8]
	push di
	push word ptr [bp-2]
	call RegDosRealloc
	mov [bp-4],dx
	or dx,ax
	jnz short rrr_done
	push offset CGROUP:RegSaveFile
	call RegForEachFile
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push word ptr [bp+8]
	push di
	push word ptr [bp-2]
	call RegDosRealloc
	mov [bp-4],dx
rrr_done:
	mov dx,[bp-4]
	pop di
	leave
	ret 6
RegReallocRetry endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Reinitialize the machine and user handles after allocating the key pool.
	public RegResetRootHandles
RegResetRootHandles proc near
	enter	78h,0
	push	di
	push	si
	sub	eax,eax
	mov	[bp-6eh],eax
	mov	byte ptr [bp-5fh],2
	mov	[bp-5ch],ax
	mov	[bp-5eh],ax
	mov	[bp-58h],ax
	mov	[bp-5ah],ax
	mov	eax,25h
	mov	[bp-74h],eax
	mov	[bp-24h],eax
	sub	eax,eax
	mov	[bp-1eh],eax
	mov	byte ptr [bp-0fh],3
	mov	[bp-0ch],ax
	mov	[bp-0eh],ax
	mov	[bp-8],ax
	mov	[bp-0ah],ax
	mov	ax,4b48h
	mov	[bp-78h],ax
	mov	[bp-28h],ax
	mov	[bp-50h],ax
	mov	dword ptr [bp-4ch],5
	sub	eax,eax
	mov	[bp-46h],eax
	mov	[bp-76h],ax
	mov	[bp-70h],ax
	mov	[bp-62h],ax
	mov	[bp-26h],ax
	mov	[bp-20h],ax
	mov	[bp-12h],ax
	mov	[bp-4eh],ax
	mov	[bp-48h],ax
	mov	[bp-3ah],ax
	mov	[bp-60h],al
	mov	[bp-10h],al
	mov	[bp-38h],al
	mov	[bp-37h],al
	mov	[bp-34h],ax
	mov	[bp-36h],ax
	mov	[bp-30h],ax
	mov	[bp-32h],ax
	mov	ax,0ffffh
	mov	[bp-56h],ax
	mov	[bp-6],ax
	mov	[bp-2eh],ax
	cwd
	mov	[bp-6ah],ax
	mov	[bp-68h],dx
	mov	[bp-66h],ax
	mov	[bp-64h],dx
	mov	[bp-54h],ax
	mov	[bp-52h],dx
	mov	[bp-1ah],ax
	mov	[bp-18h],dx
	mov	[bp-16h],ax
	mov	[bp-14h],dx
	mov	[bp-4],ax
	mov	[bp-2],dx
	mov	[bp-42h],ax
	mov	[bp-40h],dx
	mov	[bp-3eh],ax
	mov	[bp-3ch],dx
	mov	[bp-2ch],ax
	mov	[bp-2ah],dx
	push	ds
	mov	di,offset DGROUP:RegMachineRoot
	lea	si,[bp-78h]
	push	ds
	pop	es
	push	ss
	pop	ds
	mov	cx,14h
	rep	movsw
	pop	ds
	push	ds
	mov	di,offset DGROUP:RegUserRoot
	lea	si,[bp-28h]
	push	ds
	pop	es
	push	ss
	pop	ds
	mov	cx,14h
	rep	movsw
	pop	ds
	push	ds
	mov	di,offset DGROUP:RegAuxRoot
	lea	si,[bp-50h]
	push	ds
	pop	es
	push	ss
	pop	ds
	mov	cx,14h
	rep	movsw
	pop	ds
	push	ds
	push	offset DGROUP:RegClassesName
	push	word ptr [RegClassesLength]
	call	RegNameChecksum
	mov	[RegClassesSum],ax
	push	ds
	push	offset DGROUP:RegSoftwareName
	push	word ptr [RegSoftwareLength]
	call	RegNameChecksum
	mov	[RegSoftwareSum],ax
	pop	si
	pop	di
	leave
	ret
RegResetRootHandles endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegInitKeyPool
	public RegFreeKeyPool,RegAcquireKeyHandle,RegReleaseKeyHandle
	public RegFlushDeferredKeys

KeySize		equ	28h
KeyFlags		equ	4
KeyReference	equ	8
KeyFile equ 0Ah
KeyCell equ 0Eh
KeyRootId equ 19h
KeyNext		equ	1ah
KeyPrevious	equ	1eh

; Allocate and initialize the 32 fixed-size key records.
RegInitKeyPool proc near
	enter	4,0
	push	32*KeySize
	call	RegAllocate
	mov	word ptr [RegKeyPool],ax
	mov	word ptr [RegKeyPool+2],dx
	mov	ax,dx
	or	ax,word ptr [RegKeyPool]
	jnz	short rikp_ready
	xor	ax,ax
	leave
	ret
rikp_ready:
	mov	cx,20h
	mov	ax,word ptr [RegKeyPool]
	mov	bx,ax
	mov	[bp-2],dx
	mov	es,word ptr [bp-2]
rikp_next:
	mov	word ptr es:[bx],4b48h
	db 66h
	mov	word ptr es:[bx+KeyFlags],0ch
	dw	0			; high word of the prefixed immediate
	mov	word ptr es:[bx+KeyReference],0
	add	bx,KeySize
	loop	rikp_next
	mov	ax,1
	leave
	ret
RegInitKeyPool endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Release the active dynamic handles and the fixed key pool.
RegFreeKeyPool proc near
	enter	8,0
	push	di
	push	si
	mov	ax,word ptr [RegDynamicKeys]
	mov	dx,word ptr [RegDynamicKeys+2]
	mov	si,ax
	mov	[bp-6],dx
	or	dx,ax
	jz	short rfkp_pool
rfkp_next:
	mov	es,word ptr [bp-6]
	mov	di,si
	mov	ax,es:[si+KeyNext]
	mov	dx,es:[si+KeyNext+2]
	mov	si,ax
	mov	[bp-6],dx
	push	es
	push	di
	call	RegDosFree
	mov	ax,[bp-6]
	cmp	si,word ptr [RegDynamicKeys]
	jnz	short rfkp_next
	cmp	ax,word ptr [RegDynamicKeys+2]
	jnz	short rfkp_next
rfkp_pool:
	mov	dword ptr [RegDynamicKeys],0
	cmp	dword ptr [RegKeyPool],0
	jz	short rfkp_done
	push	dword ptr [RegKeyPool]
	call	RegDosFree
	mov	dword ptr [RegKeyPool],0
rfkp_done:
	pop	si
	pop	di
	leave
	ret
RegFreeKeyPool endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Acquire an unused pool entry or link a newly allocated key.
RegAcquireKeyHandle proc near
	enter	4,0
	push	si
	cmp	dword ptr [RegKeyPool],0
	jz	short rakh_dynamic
	mov	cx,20h
	mov	ax,word ptr [RegKeyPool]
	mov	dx,word ptr [RegKeyPool+2]
	mov	bx,ax
	mov	[bp-2],dx
rakh_scan:
	mov	es,word ptr [bp-2]
	test	byte ptr es:[bx+KeyFlags],4
	jnz	short rakh_reuse
	add	bx,KeySize
	loop	rakh_scan
rakh_dynamic:
	push	KeySize
	call	RegAllocate
	mov	si,ax
	mov	[bp-2],dx
	or	dx,ax
	jz	near ptr rakh_done
	mov	es,word ptr [bp-2]
	mov	word ptr es:[si],4b48h
	sub	eax,eax
	db 66h
	mov	es:[si+KeyFlags],ax
	mov	es:[si+KeyReference],ax
	cmp	dword ptr [RegDynamicKeys],0
	jnz	short rakh_has_list
	mov	ax,[bp-2]
	mov	es,ax
	mov	es:[si+KeyPrevious],si
	mov	es:[si+KeyPrevious+2],ax
	mov	es:[si+KeyNext],si
	mov	es:[si+KeyNext+2],ax
	jmp	short rakh_save_list
rakh_reuse:
	and	word ptr es:[bx+KeyFlags],0fbe9h
	mov	ax,bx
	mov	dx,es
	pop	si
	leave
	ret
rakh_has_list:
	mov	ax,[bp-2]
	cmp	si,word ptr [RegDynamicKeys]
	jnz	short rakh_insert
	cmp	ax,word ptr [RegDynamicKeys+2]
	jz	short rakh_save_list
rakh_insert:
	mov	eax,[RegDynamicKeys]
	mov	es,word ptr [bp-2]
	db 66h
	mov	es:[si+KeyNext],ax
	les	bx,dword ptr [RegDynamicKeys]
	les	bx,dword ptr es:[bx+KeyPrevious]
	mov	ax,es
	mov	es,word ptr [bp-2]
	mov	es:[si+KeyPrevious],bx
	mov	es:[si+KeyPrevious+2],ax
	mov	cx,es
	mov	es,ax
	mov	es:[bx+KeyNext],si
	mov	es:[bx+KeyNext+2],cx
	les	bx,dword ptr [RegDynamicKeys]
	mov	es:[bx+KeyPrevious],si
	mov	es:[bx+KeyPrevious+2],cx
rakh_save_list:
	mov	ax,[bp-2]
	mov	word ptr [RegDynamicKeys],si
	mov	word ptr [RegDynamicKeys+2],ax
rakh_done:
	mov	ax,si
	mov	dx,[bp-2]
	pop	si
	leave
	ret
RegAcquireKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Queue an unlinked key for deferred release.
RegQueueFreeKey proc near
	enter	4,0
	push	si
	mov	si,[bp+4]
	inc	dword ptr [RegDeferredCount]
	mov	eax,[RegDeferredKeys]
	mov	es,word ptr [bp+6]
	db 66h
	mov	es:[si+KeyNext],ax
	mov	word ptr [RegDeferredKeys],si
	mov	word ptr [RegDeferredKeys+2],es
	pop	si
	leave
	ret	4
RegQueueFreeKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Drop a reference and unlink the key when its last reference is gone.
RegReleaseKeyHandle proc near
	enter	4,0
	push	si
	mov	si,[bp+4]
	mov	es,word ptr [bp+6]
	mov	ax,es:[si+KeyReference]
	sub	dx,dx
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jz	short rrkh_no_refs
	mov	dx,[bp-2]
	sub	ax,1
	sbb	dx,0
	mov	es:[si+KeyReference],ax
	mov	es:[si+KeyReference+2],dx
	jmp	short rrkh_count
rrkh_no_refs:
	inc	dword ptr [bp-4]
rrkh_count:
	cmp	dword ptr [bp-4],1
	jnz	short rrkh_done
	mov	es,word ptr [bp+6]
	test	byte ptr es:[si+KeyFlags],81h
	jnz	short rrkh_done
	test	byte ptr es:[si+KeyFlags],8
	jz	short rrkh_dynamic
	or	byte ptr es:[si+KeyFlags],4
	jmp	short rrkh_done
rrkh_dynamic:
	mov	ax,es
	cmp	es:[si+KeyNext],si
	jnz	short rrkh_unlink
	cmp	es:[si+KeyNext+2],ax
	jnz	short rrkh_unlink
	mov	dword ptr [RegDynamicKeys],0
	jmp	short rrkh_release
rrkh_unlink:
	db 66h
	mov	ax,es:[si+KeyNext]
	les	bx,dword ptr es:[si+KeyPrevious]
	db 66h
	mov	es:[bx+KeyNext],ax
	mov	es,word ptr [bp+6]
	db 66h
	mov	ax,es:[si+KeyPrevious]
	les	bx,dword ptr es:[si+KeyNext]
	db 66h
	mov	es:[bx+KeyPrevious],ax
	mov	ax,[bp+6]
	cmp	si,word ptr [RegDynamicKeys]
	jnz	short rrkh_release
	cmp	ax,word ptr [RegDynamicKeys+2]
	jnz	short rrkh_release
	mov	es,ax
	db 66h
	mov	ax,es:[si+KeyNext]
	mov	[RegDynamicKeys],eax
rrkh_release:
	mov	es,word ptr [bp+6]
	mov	word ptr es:[si],0
	push	es
	push	si
	call	RegQueueFreeKey
rrkh_done:
	pop	si
	leave
	ret	4
RegReleaseKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Release a dynamic record when no flags pin it.
RegFreeHandleMemory proc near
	push	bp
	mov	bp,sp
	push	si
	mov	si,[bp+4]
	mov	es,word ptr [bp+6]
	test	byte ptr es:[si+KeyFlags],89h
	jnz	short rfhm_done
	push	es
	push	si
	call	RegDosFree
rfhm_done:
	pop	si
	leave
	ret	4
RegFreeHandleMemory endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Drain the deferred-release list.
RegFlushDeferredKeys proc near
	push	si
	cmp	dword ptr [RegDeferredKeys],0
	jz	short rfdk_done
rfdk_next:
	mov	ax,word ptr [RegDeferredKeys]
	mov	dx,word ptr [RegDeferredKeys+2]
	mov	si,ax
	mov	bx,ax
	mov	es,dx
	db 66h
	mov	ax,es:[bx+KeyNext]
	mov	[RegDeferredKeys],eax
	dec	dword ptr [RegDeferredCount]
	push	es
	push	si
	call	RegFreeHandleMemory
	cmp	dword ptr [RegDeferredKeys],0
	jnz	short rfdk_next
rfdk_done:
	pop	si
	ret
RegFlushDeferredKeys endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegValidateKeyHandle
RegValidateKeyHandle proc near
	enter	112h,0
	push	di
	push	si
	les	bx,dword ptr [bp+4]
	db 66h
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	mov	[bp-0eh],eax
	cmp	dx,8000h
	jc	short rvht_ordinary
	jna	short rvht_range
rvht_ordinary:
	jmp	near ptr rvht_validate
rvht_range:
	jc	short rvht_predefined
	cmp	ax,6
	jnc	near ptr rvht_validate
rvht_predefined:
	mov	si,ax
	mov	bx,ax
	shl	bx,2
	mov	eax,[bx+RegPredefinedKeys]
	mov	[bp-0eh],eax
	or	eax,eax
	jz	short rvht_create
	les	bx,dword ptr [bp-0eh]
	test	byte ptr es:[bx+KeyFlags],2
	jz	near ptr rvht_set
rvht_create:
	or	si,si
	jz	short rvht_prepare
	cmp	si,1
	jnz	near ptr rvht_existing
	mov	word ptr [bp-4],offset DGROUP:RegUserRoot
	mov	word ptr [bp-2],ds
	mov	word ptr [bp-0ah],offset DGROUP:RegDefaultUser
	mov	word ptr [bp-8],ds
rvht_prepare:
	mov	[bp-6],si
	cmp	dword ptr [bp-0eh],0
	jz	short rvht_check_aux
	mov	bx,si
	shl	bx,2
	mov	dword ptr [bx+RegPredefinedKeys],0
	les	bx,dword ptr [bp-0eh]
	and	byte ptr es:[bx+KeyFlags],0feh
	push	dword ptr [bp-0eh]
	call	RegReleaseKeyHandle
rvht_check_aux:
	cmp	word ptr [bp-6],0
	jnz	near ptr rvht_open
	; Locate CLASSES.DAT beside the machine registry file.
	mov	ax,offset DGROUP:RegAuxRoot
	mov	[bp-0eh],ax
	mov	word ptr [bp-0ch],ds
	mov	bx,[bp-6]
	shl	bx,2
	mov	word ptr [bx+RegPredefinedKeys],ax
	mov	word ptr [bx+RegPredefinedKeys+2],ds
	mov	bx,word ptr [RegMachineRoot+0Ah]
	mov	cx,word ptr [RegMachineRoot+0Ch]
	add	bx,58h
	push	ds
	mov	di,bx
	lea	si,[bp-112h]
	mov	es,cx
	push	ss
	pop	ds
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	lea	ax,[bp-112h]
	push	ss
	push	ax
	push	5ch
	call	RegLastPathSeparator
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jz	short rvht_path_error
	mov	bx,ax
	mov	cx,[bp-2]
	inc	bx
	push	ds
	mov	di,offset DGROUP:RegClassesFileName
	mov	si,bx
	push	ds
	pop	es
	mov	ds,cx
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	push	dword ptr [bp-0eh]
	lea	ax,[bp-112h]
	push	ss
	push	ax
	push	0
	call	RegAttachRoot
	or	dx,ax
	jz	short rvht_aux_ready
rvht_path_error:
	jmp	near ptr rvht_bad
rvht_aux_ready:
	jmp	short rvht_set
rvht_existing:
	cmp	si,3
	jz	short rvht_set
	jmp	near ptr rvht_bad
rvht_open:
	les	bx,dword ptr [bp-4]
	test	byte ptr es:[bx+KeyFlags],4
	jnz	short rvht_bad
	push	es
	push	bx
	push	dword ptr [bp-0ah]
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	push	1
	call	RegOpenPath
	or	ax,ax
	jnz	short rvht_bad
	mov	si,[bp-6]
	mov	ax,[bp-0eh]
	mov	dx,[bp-0ch]
	mov	bx,si
	shl	bx,2
	mov	word ptr [bx+RegPredefinedKeys],ax
	mov	word ptr [bx+RegPredefinedKeys+2],dx
	mov	bx,ax
	mov	es,dx
	or	byte ptr es:[bx+KeyFlags],1
	mov	ax,si
	les	bx,dword ptr [bp-0eh]
	mov	es:[bx+KeyRootId],al
rvht_set:
	mov	eax,[bp-0eh]
	les	bx,dword ptr [bp+4]
	db 66h
	mov	es:[bx],ax
	les	bx,dword ptr [bp-0eh]
	mov	al,es:[bx+KeyFlags]
	and	ax,4
	cmp	ax,1
	cmc
	sbb	ax,ax
	and	ax,3f2h
	jmp	short rvht_done
rvht_validate:
	les	bx,dword ptr [bp-0eh]
	cmp	word ptr es:[bx],4b48h
	jnz	short rvht_bad
	test	byte ptr es:[bx+KeyFlags],4
	jnz	short rvht_bad
	mov	al,es:[bx+KeyFlags]
	and	ax,2
	cmp	ax,1
	cmc
	sbb	ax,ax
	and	ax,3fah
	jmp	short rvht_done
rvht_bad:
	mov	ax,3f2h
rvht_done:
	pop	si
	pop	di
	leave
	ret	4
RegValidateKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegRetainKeyHandle
RegRetainKeyHandle proc near
	enter	4,0
	mov	bx,[bp+4]
	mov	es,word ptr [bp+6]
	mov	ax,es:[bx+KeyReference]
	sub	dx,dx
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short rrkh_increment
	mov	al,es:[bx+KeyFlags]
	and	al,80h
	cmp	al,80h
	jnz	short rrkh_saturated
	xor	cx,cx
	jmp	short rrkh_retained
rrkh_increment:
	mov	dx,[bp-2]
	add	ax,1
	adc	dx,0
	mov	es:[bx+KeyReference],ax
	mov	es:[bx+KeyReference+2],dx
	jmp	short rrkh_retained
rrkh_saturated:
	or	byte ptr es:[bx+KeyFlags],80h
rrkh_retained:
	leave
	ret	4
RegRetainKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegLookupKeyHandle
RegLookupKeyHandle proc near
	enter 8,0
	push di
	mov cx,6
	mov ax,offset DGROUP:RegPredefinedKeys
	mov di,ax
	mov [bp-2],ds
rlkh_root:
	mov es,word ptr [bp-2]
	mov ax,es:[di]
	mov dx,es:[di+2]
	mov bx,ax
	mov [bp-6],dx
	or dx,ax
	jz short rlkh_next_root
	mov es,word ptr [bp-6]
	mov eax,[bp+8]
	db 66h
	cmp es:[bx+KeyFile],ax
	jnz short rlkh_next_root
	mov eax,[bp+4]
	db 66h
	cmp es:[bx+KeyCell],ax
	jnz short rlkh_next_root
	test byte ptr es:[bx+KeyFlags],6
	jz rlkh_found
rlkh_next_root:
	add di,4
	loop rlkh_root
	mov di,[bp+8]
	cmp RegKeyPool,0
	jz short rlkh_dynamic
	mov cx,20h
	mov ax,word ptr RegKeyPool
	mov dx,word ptr RegKeyPool+2
	mov bx,ax
	mov [bp-6],dx
rlkh_pool:
	mov es,word ptr [bp-6]
	mov ax,[bp+0Ah]
	cmp es:[bx+KeyFile],di
	jnz short rlkh_next_pool
	cmp es:[bx+KeyFile+2],ax
	jnz short rlkh_next_pool
	mov eax,[bp+4]
	db 66h
	cmp es:[bx+KeyCell],ax
	jnz short rlkh_next_pool
	test byte ptr es:[bx+KeyFlags],6
	jz short rlkh_found
rlkh_next_pool:
	add bx,KeySize
	loop rlkh_pool
rlkh_dynamic:
	mov ax,word ptr RegDynamicKeys
	mov dx,word ptr RegDynamicKeys+2
	mov bx,ax
	mov [bp-6],dx
	or dx,ax
	jz short rlkh_missing
rlkh_list:
	mov eax,[bp+4]
	mov es,word ptr [bp-6]
	db 66h
	cmp es:[bx+KeyCell],ax
	jnz short rlkh_next
	mov ax,[bp+0Ah]
	cmp es:[bx+KeyFile],di
	jnz short rlkh_next
	cmp es:[bx+KeyFile+2],ax
	jnz short rlkh_next
	test byte ptr es:[bx+KeyFlags],2
	jz short rlkh_found
rlkh_next:
	mov ax,es:[bx+KeyNext]
	mov dx,es:[bx+KeyNext+2]
	mov bx,ax
	mov [bp-6],dx
	mov ax,dx
	cmp bx,word ptr RegDynamicKeys
	jnz short rlkh_list
	cmp ax,word ptr RegDynamicKeys+2
	jnz short rlkh_list
rlkh_missing:
	xor ax,ax
	cwd
	mov bx,ax
	mov [bp-6],dx
rlkh_found:
	mov ax,bx
	mov dx,[bp-6]
	pop di
	leave
	ret 8
RegLookupKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegInvalidateKeyHandles
RegInvalidateKeyHandles proc near
	enter 8,0
	push di
	mov cx,6
	mov ax,offset DGROUP:RegPredefinedKeys
	mov di,ax
	mov [bp-6],ds
rikh_root:
	mov es,word ptr [bp-6]
	mov ax,es:[di]
	mov dx,es:[di+2]
	mov bx,ax
	mov [bp-2],dx
	or dx,ax
	jz short rikh_next_root
	mov es,word ptr [bp-2]
	mov eax,[bp+6]
	db 66h
	cmp es:[bx+KeyFile],ax
	jz short rikh_mark_root
	mov al,[bp+4]
	cmp es:[bx+KeyRootId],al
	jnz short rikh_next_root
rikh_mark_root:
	or byte ptr es:[bx+KeyFlags],6
rikh_next_root:
	add di,4
	loop rikh_root
	mov di,[bp+6]
	cmp RegKeyPool,0
	jz short rikh_dynamic
	mov cx,20h
	mov ax,word ptr RegKeyPool
	mov dx,word ptr RegKeyPool+2
	mov bx,ax
	mov [bp-2],dx
rikh_pool:
	mov es,word ptr [bp-2]
	mov ax,[bp+8]
	cmp es:[bx+KeyFile],di
	jnz short rikh_pool_root
	cmp es:[bx+KeyFile+2],ax
	jz short rikh_mark_pool
rikh_pool_root:
	mov al,es:[bx+KeyRootId]
	sub ah,ah
	cmp ax,[bp+4]
	jnz short rikh_next_pool
rikh_mark_pool:
	or byte ptr es:[bx+KeyFlags],6
rikh_next_pool:
	add bx,KeySize
	loop rikh_pool
rikh_dynamic:
	mov ax,word ptr RegDynamicKeys
	mov dx,word ptr RegDynamicKeys+2
	mov bx,ax
	mov [bp-2],dx
	or dx,ax
	jz short rikh_done
	mov cx,[bp+4]
rikh_list:
	mov es,word ptr [bp-2]
	mov ax,[bp+8]
	cmp es:[bx+KeyFile],di
	jnz short rikh_list_root
	cmp es:[bx+KeyFile+2],ax
	jz short rikh_mark_list
rikh_list_root:
	cmp es:[bx+KeyRootId],cl
	jnz short rikh_next
rikh_mark_list:
	or byte ptr es:[bx+KeyFlags],6
rikh_next:
	mov es,word ptr [bp-2]
	mov ax,es:[bx+KeyNext]
	mov dx,es:[bx+KeyNext+2]
	mov bx,ax
	mov [bp-2],dx
	mov ax,dx
	cmp bx,word ptr RegDynamicKeys
	jnz short rikh_list
	cmp ax,word ptr RegDynamicKeys+2
	jnz short rikh_list
rikh_done:
	pop di
	leave
	ret 6
RegInvalidateKeyHandles endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Test a file and cell against the cached CLASSES key.
	public RegIsClassesKey
RegIsClassesKey proc near
	push	bp
	mov	bp,sp
	cmp	dword ptr RegClassesCell,0FFFFFFh
	jae	short rick_no
	mov	eax,RegClassesFile
	cmp	[bp+8],eax
	jnz	short rick_no
	mov	eax,RegClassesCell
	cmp	[bp+4],eax
	jnz	short rick_no
	mov	ax,1
	jmp	short rick_done
rick_no:
	xor	ax,ax
rick_done:
	leave
	ret	8
RegIsClassesKey endp

REGTEXT ends
	end
