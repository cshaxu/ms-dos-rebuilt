;** REGOPEN - Registry paths and values
;
; FAR C entries call the key cache and record services through near entries.
; Path and value-name operations use the shared registry state in DGROUP.
;
	.386
_DATA segment word public use16 'RESUME_DATA'
	extrn RegClassesMachine:dword,RegClassesAux:dword,RegClassesCell:dword,RegClassesFile:dword
	extrn RegClassesName:byte,RegClassesLength:word,RegClassesSum:word
	extrn RegSoftwareName:byte,RegSoftwareLength:word,RegSoftwareSum:word
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'RESUME_CODE'
_TEXT ends
REGTEXT segment word public use16 'RESUME_CODE'
SysResume segment byte public use16 'RESUME_CODE'
SysResume ends
CGROUP group SysResume,_TEXT,REGTEXT
	assume cs:CGROUP,ds:DGROUP
	extrn RegMoveMemory:near
	extrn RegIsClassesKey:near,RegFlushDeferredKeys:near
RegistryCode label byte
	extrn RegAcquireKeyHandle:near
	extrn RegReleaseKeyHandle:near
	extrn RegValidateKeyHandle:near
	extrn RegRetainKeyHandle:near
	extrn RegLookupKeyHandle:near
	extrn RegFetchKeyRecord:near
	extrn RegUnlockKeyCache:near
	extrn RegAllocateKeyRecord:near
	extrn RegFreeKeyRecord:near
	extrn RegUnlockDataCache:near
	extrn RegFetchDataRecord:near
	extrn RegAllocateDataRecord:near
	extrn RegNameChecksum:near
	extrn RegCompareName:near
	extrn RegAllocate:near
	extrn RegDosFree:near
	extrn RegEnumValueRecord:near
	extrn RegMaintainCache:near
	extrn RegForEachFile:near
	public RegCheckPath
RegCheckPath proc near
	enter 6,0
	push di
	push si
	mov di,[bp+4]
	mov ax,[bp+6]
	or ax,di
	jnz short rcpt_start
rcpt_valid:
	xor ax,ax
	jmp short rcpt_done
rcpt_start:
	mov ax,[bp+6]
	mov si,di
	mov [bp-4],ax
	xor cx,cx
rcpt_next:
	mov es,word ptr [bp-4]
	mov al,es:[si]
	mov [bp-1],al
	or al,al
	jz short rcpt_valid
	cmp al,'\'
	jnz short rcpt_character
	or cx,cx
	jnz short rcpt_separator
	mov ax,es
	cmp si,di
	jnz short rcpt_invalid
	cmp ax,[bp+6]
	jnz short rcpt_invalid
rcpt_separator:
	xor cx,cx
	jmp short rcpt_advance
rcpt_character:
	cmp byte ptr [bp-1],20h
	jb short rcpt_invalid
	inc cx
	cmp cx,100h
	jae short rcpt_invalid
rcpt_advance:
	inc si
	jmp short rcpt_next
rcpt_invalid:
	mov ax,1
rcpt_done:
	pop si
	pop di
	leave
	ret 4
RegCheckPath endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegPathPart
RegPathPart proc near
	enter	4,0
	push	si
	mov	bx,[bp+10h]
	mov	ax,[bp+12h]
	or	ax,bx
	jz	short rnpp_scan
	mov	ax,[bp+12h]
	les	si,dword ptr [bp+4]
	mov	es:[si],bx
	mov	es:[si+2],ax
rnpp_scan:
	les	bx,dword ptr [bp+4]
	les	bx,dword ptr es:[bx]
	mov	si,bx
	mov	word ptr [bp-2],es
	cmp	byte ptr es:[bx],0
	jnz	short rnpp_start
	les	bx,dword ptr [bp+0ch]
	sub	eax,eax
	db 66h
	mov	es:[bx],ax
	les	bx,dword ptr [bp+8]
	mov	es:[bx],ax
	jmp	short rnpp_done
rnpp_start:
	cmp	byte ptr es:[si],5ch
	jnz	short rnpp_store
	inc	si
rnpp_store:
	mov	ax,es
	les	bx,dword ptr [bp+0ch]
	mov	es:[bx],si
	mov	es:[bx+2],ax
	mov	es,ax
	cmp	byte ptr es:[si],0
	jz	short rnpp_end
rnpp_next:
	mov	es,word ptr [bp-2]
	cmp	byte ptr es:[si],5ch
	jz	short rnpp_end
	inc	si
	cmp	byte ptr es:[si],0
	jnz	short rnpp_next
rnpp_end:
	mov	ax,[bp-2]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],si
	mov	es:[bx+2],ax
	mov	ax,si
	les	si,dword ptr [bp+0ch]
	sub	ax,es:[si]
	les	si,dword ptr [bp+8]
	mov	es:[si],ax
rnpp_done:
	pop	si
	leave
	ret	10h
RegPathPart endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Test whether a key is the machine SOFTWARE root.
RegIsSoftwareKey proc near
	enter	0ch,0
	push	di
	push	si
	xor	si,si
	push	dword ptr [bp+8]
	push	dword ptr [bp+4]
	lea	ax,[bp-8]
	push	ss
	push	ax
	call	RegFetchKeyRecord
	or	ax,ax
	jnz	near ptr risk_done
	mov	ax,[RegSoftwareSum]
	les	bx,dword ptr [bp-8]
	cmp	es:[bx+0eh],ax
	jnz	near ptr risk_release
	push	dword ptr [bp+8]
	push	word ptr es:[bx+0ch]
	mov	al,es:[bx+0bh]
	sub	ah,ah
	push	ax
	lea	ax,[bp-0ch]
	push	ss
	push	ax
	call	RegFetchDataRecord
	or	ax,ax
	jnz	near ptr risk_release
	mov	ax,[RegSoftwareLength]
	les	bx,dword ptr [bp-0ch]
	cmp	es:[bx+0ch],ax
	jnz	short risk_unlock
	push	DGROUP
	push	offset DGROUP:RegSoftwareName
	lea	ax,[bx+14h]
	push	es
	push	ax
	push	word ptr [RegSoftwareLength]
	call	RegCompareName
	or	ax,ax
	jz	short risk_unlock
	push	dword ptr [bp+8]
	les	bx,dword ptr [bp-8]
	push	word ptr es:[bx+0ch]
	push	si
	call	RegUnlockDataCache
	jmp	short risk_release
risk_unlock:
	push	dword ptr [bp+8]
	les	bx,dword ptr [bp-8]
	push	word ptr es:[bx+0ch]
	push	si
	call	RegUnlockDataCache
	les	bx,dword ptr [bp-8]
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+0ah]
	sub	dh,dh
	cmp	dx,0ffh
	ja	short risk_release
	jc	short risk_lookup
	cmp	ax,0ffffh
	jnc	short risk_release
risk_lookup:
	push	dword ptr [bp+8]
	mov	dx,es:[bx+0ah]
	sub	dh,dh
	push	dx
	push	ax
	call	RegLookupKeyHandle
	mov	di,ax
	mov	[bp-2],dx
	or	dx,ax
	jz	short risk_release
	mov	ax,[bp-2]
	cmp	di,word ptr [RegClassesMachine]
	jnz	short risk_release
	cmp	ax,word ptr [RegClassesMachine+2]
	jnz	short risk_release
	mov	si,1
risk_release:
	push	dword ptr [bp+8]
	push	dword ptr [bp+4]
	push	0
	call	RegUnlockKeyCache
risk_done:
	mov	ax,si
	pop	si
	pop	di
	leave
	ret	8
RegIsSoftwareKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegOpenPath
RegOpenPath proc near
	enter	38h,0
	push	di
	push	si
	mov	di,[bp+0eh]
	mov	si,[bp+0ah]
	sub	eax,eax
	mov	[bp-32h],eax
	mov	es,word ptr [bp+10h]
	mov	al,es:[di+19h]
	mov	[bp-13h],al
	mov	word ptr [bp-34h],0
	mov	ax,[bp+0ch]
	or	ax,si
	jz	short rop_root_only
	push	word ptr [bp+0ch]
	push	si
	lea	ax,[bp-26h]
	push	ss
	push	ax
	lea	ax,[bp-16h]
	push	ss
	push	ax
	lea	ax,[bp-32h]
	push	ss
	push	ax
	call	RegPathPart
	or	ax,ax
	jnz	short rop_component
rop_root_only:
	jmp	near ptr rop_use_root
rop_component:
	mov	al,[bp+4]
	and	al,1
	jnz	short rop_root
	mov	ax,si
	sub	ax,[bp-26h]
	neg	ax
	add	[bp-16h],ax
	mov	ax,[bp+0ch]
	mov	[bp-26h],si
	mov	[bp-24h],ax
rop_root:
	mov	es,word ptr [bp+10h]
	db 66h
	mov	ax,es:[di+0ah]
	mov	[bp-12h],eax
	db 66h
	mov	ax,es:[di+12h]
	mov	[bp-1eh],eax
	db 66h
	mov	ax,es:[di+0eh]
	mov	[bp-0ah],eax
	mov	word ptr [bp-1ah],0
rop_checksum:
	push	dword ptr [bp-26h]
	push	word ptr [bp-16h]
	call	RegNameChecksum
	mov	[bp-6],ax
	mov	[bp-4],dx
	cmp	dword ptr [bp-1eh],0ffffffh
	jnc	short rop_no_cell
	mov	si,[bp-12h]
rop_fetch:
	mov	word ptr [bp-2],0
rop_retry:
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-1eh]
	lea	ax,[bp-22h]
	push	ss
	push	ax
	call	RegFetchKeyRecord
	mov	di,ax
	or	di,ax
	jnz	near ptr rop_result
	les	bx,dword ptr [bp-22h]
	sub	dx,dx
	mov	ax,es:[bx+0eh]
	cmp	ax,[bp-6]
	jnz	short rop_mismatch
	cmp	dx,[bp-4]
	jz	short rop_name
rop_mismatch:
	jmp	near ptr rop_check_sibling
rop_name:
	push	word ptr [bp-10h]
	push	si
	push	word ptr es:[bx+0ch]
	mov	al,es:[bx+0bh]
	sub	ah,ah
	push	ax
	lea	ax,[bp-2ah]
	push	ss
	push	ax
	call	RegFetchDataRecord
	mov	di,ax
	or	di,ax
	jz	short rop_check_create
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-1eh]
	push	0
	call	RegUnlockKeyCache
	cmp	word ptr [bp-2],0
	jnz	near ptr rop_result
	mov	word ptr [bp-2],1
	push	offset CGROUP:RegMaintainCache
	call	RegForEachFile
	push	offset CGROUP:RegMaintainCache
	call	RegForEachFile
	jmp	short rop_retry
rop_no_cell:
	mov	si,[bp-12h]
	jmp	near ptr rop_next_component
rop_check_create:
	mov	[bp-18h],di
	les	bx,dword ptr [bp-22h]
	test	word ptr es:[bx+2],400h
	jnz	short rop_no_flags
	mov	ax,1
	jmp	short rop_compare_flags
rop_no_flags:
	xor	ax,ax
rop_compare_flags:
	mov	cl,[bp+4]
	and	cx,4
	cmp	cx,1
	sbb	cx,cx
	neg	cx
	cmp	ax,cx
	jnz	short rop_clear_result
	mov	ax,[bp-16h]
	les	bx,dword ptr [bp-2ah]
	cmp	es:[bx+0ch],ax
	jnz	short rop_clear_result
	push	dword ptr [bp-26h]
	lea	ax,[bx+14h]
	push	es
	push	ax
	push	word ptr [bp-16h]
	call	RegCompareName
	or	ax,ax
	jnz	short rop_clear_result
	mov	di,1
	jmp	short rop_unlock
rop_clear_result:
	xor	di,di
rop_unlock:
	push	word ptr [bp-10h]
	push	si
	les	bx,dword ptr [bp-22h]
	push	word ptr es:[bx+0ch]
	push	0
	call	RegUnlockDataCache
	or	di,di
	jnz	short rop_next_component
rop_enable_create:
	mov	word ptr [bp-1ah],1
	mov	eax,[bp-1eh]
	mov	[bp-0ah],eax
	les	bx,dword ptr [bp-22h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	sub	dh,dh
	mov	[bp-1eh],ax
	mov	[bp-1ch],dx
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	push	0
	call	RegUnlockKeyCache
	cmp	dword ptr [bp-1eh],0ffffffh
	jc	near ptr rop_fetch
rop_next_component:
	cmp	dword ptr [bp-1eh],0ffffffh
	jnc	near ptr rop_next_sibling
	push	0
	push	0
	lea	ax,[bp-26h]
	push	ss
	push	ax
	lea	ax,[bp-16h]
	push	ss
	push	ax
	lea	ax,[bp-32h]
	push	ss
	push	ax
	call	RegPathPart
	or	ax,ax
	jz	short rop_next_sibling
	mov	eax,[bp-1eh]
	mov	[bp-0ah],eax
	les	bx,dword ptr [bp-22h]
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	sub	dh,dh
	mov	[bp-1eh],ax
	mov	[bp-1ch],dx
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	xor	ax,ax
	mov	[bp-1ah],ax
	push	ax
	call	RegUnlockKeyCache
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	call	RegIsClassesKey
	or	ax,ax
	jz	near ptr rop_checksum
	les	bx,dword ptr [RegClassesAux]
	db 66h
	mov	ax,es:[bx+0ah]
	mov	[bp-12h],eax
	db 66h
	mov	ax,es:[bx+12h]
	mov	[bp-1eh],eax
	db 66h
	mov	ax,es:[bx+0eh]
	mov	[bp-0ah],eax
	mov	al,es:[bx+19h]
	mov	[bp-13h],al
	jmp	near ptr rop_checksum
rop_check_sibling:
	mov	[bp-18h],di
	jmp	near ptr rop_enable_create
rop_next_sibling:
	cmp	dword ptr [bp-1eh],0ffffffh
	jc	near ptr rop_resume_path
	mov	al,[bp+4]
	and	al,1
	jz	near ptr rop_access_denied
	mov	es,word ptr [bp-10h]
	test	byte ptr es:[si+56h],80h
	jnz	near ptr rop_invalid_flags
	push	es
	push	si
	push	dword ptr [bp-0ah]
	lea	ax,[bp-22h]
	push	ss
	push	ax
	call	RegFetchKeyRecord
	mov	di,ax
	or	di,ax
	jnz	near ptr rop_result
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	call	RegLookupKeyHandle
	mov	[bp-0eh],ax
	mov	[bp-0ch],dx
rop_create:
	push	word ptr [bp-10h]
	push	si
	lea	ax,[bp-1eh]
	push	ss
	push	ax
	lea	ax,[bp-2eh]
	push	ss
	push	ax
	call	RegAllocateKeyRecord
	mov	di,ax
	or	di,ax
	jnz	near ptr rop_saved_result
	push	word ptr [bp-10h]
	push	si
	mov	ax,[bp-16h]
	add	ax,14h
	push	ax
	lea	ax,[bp-2ah]
	push	ss
	push	ax
	call	RegAllocateDataRecord
	mov	[bp-18h],ax
	or	ax,ax
	jnz	near ptr rop_release_record
	cmp	[bp-1ah],ax
	jz	short rop_init_record
	mov	[bp-1ah],ax
	cwd
	mov	bx,ax
	mov	[bp-0ch],dx
	les	di,dword ptr [bp-2eh]
	mov	ax,es:[di+8]
	mov	dx,es:[di+0ah]
	les	di,dword ptr [bp-22h]
	xor	ax,es:[di+8]
	xor	dx,es:[di+0ah]
	sub	dh,dh
	les	di,dword ptr [bp-2eh]
	xor	es:[di+8],ax
	xor	es:[di+0ah],dx
	les	di,dword ptr [bp-22h]
	mov	ax,es:[di]
	mov	dx,es:[di+2]
	xor	ax,[bp-1eh]
	xor	dx,[bp-1ch]
	sub	dh,dh
	xor	es:[di],ax
	xor	es:[di+2],dx
	jmp	short rop_set_child
rop_init_record:
	les	bx,dword ptr [bp-2eh]
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+0ah]
	xor	ax,[bp-0ah]
	xor	dx,[bp-8]
	sub	dh,dh
	xor	es:[bx+8],ax
	xor	es:[bx+0ah],dx
	les	bx,dword ptr [bp-22h]
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	xor	ax,[bp-1eh]
	xor	dx,[bp-1ch]
	sub	dh,dh
	xor	es:[bx+4],ax
	xor	es:[bx+6],dx
	mov	bx,[bp-0eh]
	mov	ax,[bp-0ch]
	or	ax,bx
	jz	short rop_set_child
	mov	es,word ptr [bp-0ch]
	db 66h,26h,81h,7Fh,12h	; CMP dword ptr es:[bx+12h],0FFFFFFh
	dd 0FFFFFFh
	jc	short rop_clear_child
	mov	eax,[bp-1eh]
	db 66h
	mov	es:[bx+12h],ax
rop_clear_child:
	xor	ax,ax
	cwd
	mov	bx,ax
	mov	[bp-0ch],dx
rop_set_child:
	mov	[bp-0eh],bx
	cmp	dword ptr [bp-6],0
	jnz	short rop_store_new
	push	dword ptr [bp-26h]
	push	word ptr [bp-16h]
	call	RegNameChecksum
	mov	[bp-6],ax
	mov	[bp-4],dx
rop_store_new:
	les	bx,dword ptr [bp-2eh]
	db 66h,26h,81h,0Fh	; OR dword ptr es:[bx],0FFFFFFh
	dd 0FFFFFFh
	les	bx,dword ptr [bp-2eh]
	db 66h,26h,81h,4Fh,4	; OR dword ptr es:[bx+4],0FFFFFFh
	dd 0FFFFFFh
	les	bx,dword ptr [bp-2ah]
	mov	ax,es:[bx+6]
	les	bx,dword ptr [bp-2eh]
	mov	es:[bx+0ch],ax
	les	bx,dword ptr [bp-2ah]
	sub	al,al
	mov	ah,es:[bx+4]
	mov	dx,ax
	sub	cx,cx
	les	bx,dword ptr [bp-2eh]
	mov	[bp-38h],cx
	mov	[bp-36h],ax
	xor	cx,es:[bx+8]
	xor	dx,es:[bx+0ah]
	and	dh,al
	xor	cx,[bp-38h]
	xor	dx,ax
	mov	es:[bx+8],cx
	mov	es:[bx+0ah],dx
	mov	ax,[bp-6]
	les	bx,dword ptr [bp-2eh]
	mov	es:[bx+0eh],ax
	mov	ax,[bp-16h]
	add	ax,14h
	les	bx,dword ptr [bp-2ah]
	mov	es:[bx+8],ax
	mov	word ptr es:[bx+0ah],0
	mov	ax,[bp-16h]
	les	bx,dword ptr [bp-2ah]
	mov	es:[bx+0ch],ax
	mov	eax,[bp-2ah]
	add	ax,14h
	push	eax
	push	dword ptr [bp-26h]
	push	word ptr [bp-16h]
	call	RegMoveMemory
	les	bx,dword ptr [bp-2ah]
	mov	word ptr es:[bx+0eh],0
	les	bx,dword ptr [bp-2ah]
	mov	word ptr es:[bx+10h],0
	les	bx,dword ptr [bp-2ah]
	mov	word ptr es:[bx+12h],0
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	push	1
	call	RegUnlockKeyCache
	mov	eax,[bp-1eh]
	mov	[bp-0ah],eax
	mov	eax,[bp-2eh]
	mov	[bp-22h],eax
	push	word ptr [bp-10h]
	push	si
	les	bx,dword ptr [bp-2ah]
	push	word ptr es:[bx+6]
	mov	ax,1
	mov	[bp-34h],ax
	push	ax
	call	RegUnlockDataCache
	cmp	dword ptr [RegClassesCell],0ffffffh
	jc	short rop_no_classes
	mov	ax,[RegClassesSum]
	sub	dx,dx
	cmp	[bp-6],ax
	jnz	short rop_no_classes
	cmp	[bp-4],dx
	jnz	short rop_no_classes
	cmp	byte ptr [bp-13h],2
	jnz	short rop_no_classes
	mov	ax,[RegClassesLength]
	cmp	[bp-16h],ax
	jnz	short rop_no_classes
	push	dword ptr [bp-26h]
	push	DGROUP
	push	offset DGROUP:RegClassesName
	push	word ptr [bp-16h]
	call	RegCompareName
	or	ax,ax
	jnz	short rop_no_classes
	push	word ptr [bp-10h]
	push	si
	les	bx,dword ptr [bp-2eh]
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+0ah]
	sub	dh,dh
	push	dx
	push	ax
	call	RegIsSoftwareKey
	or	ax,ax
	jnz	short rop_classes_result
rop_no_classes:
	sub	eax,eax
	mov	[bp-6],eax
	push	ax
	push	ax
	lea	ax,[bp-26h]
	push	ss
	push	ax
	lea	ax,[bp-16h]
	push	ss
	push	ax
	lea	ax,[bp-32h]
	push	ss
	push	ax
	call	RegPathPart
	or	ax,ax
	jnz	near ptr rop_create
rop_resume_path:
	mov	si,[bp-18h]
	test	byte ptr [bp+4],8
	jnz	near ptr rop_find_handle
	push	dword ptr [bp-12h]
	push	dword ptr [bp-1eh]
	call	RegIsClassesKey
	or	ax,ax
	jz	near ptr rop_find_handle
	mov	ax,word ptr [RegClassesAux]
	mov	dx,word ptr [RegClassesAux+2]
	mov	di,ax
	mov	[bp-0ch],dx
	jmp	near ptr rop_unlock_cell
rop_classes_result:
	mov	eax,[bp-0ah]
	mov	dx,[bp-8]
	mov	[RegClassesCell],eax
	mov	ecx,[bp-12h]
	mov	[RegClassesFile],ecx
	push	ecx
	push	dx
	push	ax
	push	1
	call	RegUnlockKeyCache
	les	bx,dword ptr [RegClassesAux]
	db 66h
	mov	ax,es:[bx+0ah]
	mov	[bp-12h],eax
	db 66h
	mov	ax,es:[bx+0eh]
	mov	[bp-0ah],eax
	db 66h
	mov	ax,es:[bx+12h]
	mov	[bp-1eh],eax
	mov	al,es:[bx+19h]
	mov	[bp-13h],al
	push	0
	push	0
	lea	ax,[bp-26h]
	push	ss
	push	ax
	lea	ax,[bp-16h]
	push	ss
	push	ax
	lea	ax,[bp-32h]
	push	ss
	push	ax
	call	RegPathPart
	or	ax,ax
	jnz	near ptr rop_checksum
	mov	eax,[bp-0ah]
	mov	[bp-1eh],eax
	push	dword ptr [bp-12h]
	push	eax
	lea	ax,[bp-22h]
	push	ss
	push	ax
	call	RegFetchKeyRecord
	mov	di,ax
	mov	[bp-18h],ax
	or	di,ax
	jz	near ptr rop_resume_path
	jmp	near ptr rop_result
rop_access_denied:
	mov	ax,3f3h
	jmp	near ptr rop_done
rop_invalid_flags:
	mov	ax,5
	jmp	near ptr rop_done
rop_release_record:
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-1eh]
	push	0
	call	RegUnlockKeyCache
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-1eh]
	call	RegFreeKeyRecord
rop_free_record:
	push	word ptr [bp-10h]
	push	si
	push	dword ptr [bp-0ah]
	push	word ptr [bp-34h]
	call	RegUnlockKeyCache
	jmp	near ptr rop_no_handle
rop_saved_result:
	mov	[bp-18h],di
	jmp	short rop_free_record
rop_find_handle:
	push	dword ptr [bp-12h]
	push	dword ptr [bp-1eh]
	call	RegLookupKeyHandle
	mov	di,ax
	mov	[bp-0ch],dx
	or	dx,ax
	jnz	short rop_unlock_cell
	call	RegAcquireKeyHandle
	mov	di,ax
	mov	[bp-0ch],dx
	or	dx,ax
	jnz	short rop_fill_handle
	mov	si,0eh
	jmp	short rop_unlock_cell
rop_fill_handle:
	mov	eax,[bp-12h]
	mov	es,word ptr [bp-0ch]
	db 66h
	mov	es:[di+0ah],ax
	mov	eax,[bp-1eh]
	db 66h
	mov	es:[di+0eh],ax
	les	bx,dword ptr [bp-22h]
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	sub	dh,dh
	mov	es,word ptr [bp-0ch]
	mov	es:[di+12h],ax
	mov	es:[di+14h],dx
	les	bx,dword ptr [bp-22h]
	mov	ax,es:[bx+0ch]
	mov	es,word ptr [bp-0ch]
	mov	es:[di+16h],ax
	les	bx,dword ptr [bp-22h]
	sub	ah,ah
	mov	al,es:[bx+0bh]
	mov	es,word ptr [bp-0ch]
	mov	es:[di+18h],al
	mov	al,[bp-13h]
	mov	es:[di+19h],al
	les	bx,dword ptr [bp-22h]
	test	word ptr es:[bx+2],200h
	jz	short rop_unlock_cell
	mov	es,word ptr [bp-0ch]
	or	byte ptr es:[di+5],1
rop_unlock_cell:
	push	dword ptr [bp-12h]
	push	dword ptr [bp-1eh]
	push	word ptr [bp-34h]
	call	RegUnlockKeyCache
	mov	[bp-18h],si
	mov	ax,[bp-0ch]
	or	ax,di
	jnz	short rop_keep_handle
rop_no_handle:
	mov	di,[bp-18h]
	jmp	short rop_result
rop_keep_handle:
	mov	[bp-0eh],di
	mov	si,di
	jmp	short rop_retain
rop_use_root:
	mov	ax,[bp+10h]
	mov	si,di
	mov	[bp-0ch],ax
rop_retain:
	mov	ax,[bp-0ch]
	push	ax
	push	si
	mov	di,ax
	call	RegRetainKeyHandle
	les	bx,dword ptr [bp+6]
	mov	es:[bx],si
	mov	es:[bx+2],di
	xor	di,di
rop_result:
	mov	ax,di
rop_done:
	pop	si
	pop	di
	leave
	ret	0eh
RegOpenPath endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFindOrCreate
RegFindOrCreate proc near
	push bp
	mov bp,sp
	push di
	push dword ptr [bp+0Ah]
	call RegCheckPath
	or ax,ax
	jz short rokt_validate
	mov ax,3F2h
	jmp short rokt_done
rokt_validate:
	lea ax,[bp+0Eh]
	push ss
	push ax
	call RegValidateKeyHandle
	mov di,ax
	or di,ax
	jnz short rokt_result
	push dword ptr [bp+0Eh]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	call RegOpenPath
	mov di,ax
rokt_result:
	call RegFlushDeferredKeys
	mov ax,di
rokt_done:
	pop di
	leave
	ret 0Eh
RegFindOrCreate endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Open a key through the common path resolver.
	public RegOpenKey
RegOpenKey proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push ds
	mov ds,ax
	push dword ptr [bp+6]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+0Eh]
	push 0
	call RegFindOrCreate
	cwd
	pop ds
	leave
	retf
RegOpenKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCloseKey
RegCloseKey proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push si
	push ds
	mov ds,ax
	lea ax,[bp+6]
	push ss
	push ax
	call RegValidateKeyHandle
	mov si,ax
	or si,ax
	jz short rckt_release
	cmp si,3FAh
	jnz short rckt_done
rckt_release:
	push dword ptr [bp+6]
	call RegReleaseKeyHandle
	xor si,si
rckt_done:
	call RegFlushDeferredKeys
	mov ax,si
	cwd
	pop ds
	pop si
	leave
	retf
RegCloseKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Find a named value in the key or its chained children.
	public RegFindChainedValue
RegFindChainedValue proc near
	enter	0eh,0
	push	di
	push	si
	mov	di,[bp+14h]
	mov	es,word ptr [bp+16h]
	mov	ax,es:[di+16h]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],ax
	push	word ptr [bp+16h]
	push	di
	push	dword ptr [bp+10h]
	push	dword ptr [bp+0ch]
	push	dword ptr [bp+8]
	call	RegFindValue
	mov	si,ax
	cmp	si,3f4h
	jnz	short rcv_cached
	mov	es,word ptr [bp+16h]
	test	byte ptr es:[di+5],1
	jnz	short rcv_allocate
rcv_cached:
	jmp	near ptr rcv_result
rcv_allocate:
	push	100h
	call	RegAllocate
	mov	[bp-4],dx
	or	dx,ax
	jnz	short rcv_ready
	mov	ax,0eh
	jmp	near ptr rcv_done
rcv_ready:
	mov	word ptr [bp-2],0
	mov	[bp-6],ax
	mov	di,ax
rcv_enumerate:
	mov	dword ptr [bp-0eh],100h
	push	dword ptr [bp+14h]
	push	word ptr [bp-2]
	inc	word ptr [bp-2]
	push	word ptr [bp-4]
	push	di
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	push	4
	call	RegEnumValueRecord
	or	ax,ax
	jnz	short rcv_missing
	push	dword ptr [bp+14h]
	push	word ptr [bp-4]
	push	di
	lea	ax,[bp-0ah]
	push	ss
	push	ax
	push	4
	call	RegOpenPath
	or	ax,ax
	jnz	short rcv_missing
	les	bx,dword ptr [bp-0ah]
	mov	ax,es:[bx+16h]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],ax
	push	dword ptr [bp-0ah]
	push	dword ptr [bp+10h]
	push	dword ptr [bp+0ch]
	push	dword ptr [bp+8]
	call	RegFindValue
	mov	si,ax
	push	dword ptr [bp-0ah]
	call	RegReleaseKeyHandle
	cmp	si,3f4h
	jz	short rcv_enumerate
	jmp	short rcv_free
rcv_missing:
	mov	si,3f4h
rcv_free:
	push	word ptr [bp-4]
	push	di
	call	RegDosFree
rcv_result:
	mov	ax,si
rcv_done:
	pop	si
	pop	di
	leave
	ret	14h
RegFindChainedValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Find the named record and return its locked data block.
	public RegFindValue
RegFindValue proc near
	enter	0ch,0
	push	di
	push	si
	les	bx,dword ptr [bp+10h]
	cmp	word ptr es:[bx+16h],-1
	jnz	short rfgv_fetch
	mov	ax,3f4h
	jmp	near ptr rfgv_done
rfgv_fetch:
	db 66h
	push	word ptr es:[bx+0ah]
	push	word ptr es:[bx+16h]
	mov	al,es:[bx+18h]
	push	ax
	lea	ax,[bp-0ch]
	push	ss
	push	ax
	call	RegFetchDataRecord
	mov	si,ax
	or	si,ax
	jnz	near ptr rfgv_result
	cmp	dword ptr [bp+0ch],0
	jnz	short rfgv_empty_name
	xor	si,si
	jmp	short rfgv_name
rfgv_empty_name:
	les	di,dword ptr [bp+0ch]
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	dec	cx
	mov	si,cx
rfgv_name:
	les	bx,dword ptr [bp-0ch]
	mov	ax,es:[bx+0ch]
	add	ax,es:[bx+10h]
	add	ax,bx
	add	ax,14h
	mov	cx,ax
	mov	word ptr [bp-2],es
	mov	ax,es:[bx+0eh]
	mov	[bp-8],ax
	or	ax,ax
	jz	short rfgv_release
	mov	[bp-4],cx
	mov	[bp-6],si
	mov	si,cx
	mov	di,[bp-6]
rfgv_length:
	cmp	es:[si+8],di
	jnz	short rfgv_compare
	or	di,di
	jz	short rfgv_found
	push	dword ptr [bp+0ch]
	lea	ax,[si+0ch]
	push	es
	push	ax
	push	di
	call	RegCompareName
	or	ax,ax
	jz	short rfgv_found
rfgv_compare:
	mov	es,word ptr [bp-2]
	mov	ax,es:[si+8]
	add	ax,es:[si+0ah]
	add	ax,0ch
	add	si,ax
	dec	word ptr [bp-8]
	jnz	short rfgv_length
	jmp	short rfgv_release
rfgv_found:
	mov	eax,[bp-0ch]
	les	bx,dword ptr [bp+8]
	db 66h
	mov	es:[bx],ax
	les	bx,dword ptr [bp+4]
	mov	ax,[bp-2]
	mov	es:[bx],si
	mov	es:[bx+2],ax
	xor	ax,ax
	jmp	short rfgv_done
rfgv_release:
	les	bx,dword ptr [bp+10h]
	db 66h
	push	word ptr es:[bx+0ah]
	push	word ptr es:[bx+16h]
	push	0
	call	RegUnlockDataCache
	mov	si,3f4h
rfgv_result:
	mov	ax,si
rfgv_done:
	pop	si
	pop	di
	leave
	ret	10h
RegFindValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Copy the name, type and data returned by a registry query.
	public RegQueryValueCore
RegQueryValueCore proc near
	enter	2,0
	push	di
	push	si
	mov	bx,[bp+0ch]
	mov	di,[bp+18h]
	mov	ax,[bp+0eh]
	or	ax,bx
	jz	short rqvc_finish_size
	mov	es,word ptr [bp+1ah]
	db 66h
	mov	ax,es:[di]
	mov	es,word ptr [bp+0eh]
	db 66h
	mov	es:[bx],ax
rqvc_finish_size:
	mov	es,word ptr [bp+1ah]
	mov	si,es:[di+0ah]
	db 66h
	cmp	word ptr es:[di],1
	jnz	short rqvc_name
	inc	si
rqvc_name:
	cmp	dword ptr [bp+8],0
	jz	short rqvc_value_type
	sub	ax,ax
	les	bx,dword ptr [bp+4]
	cmp	es:[bx+2],ax
	ja	short rqvc_copy_name
	jc	short rqvc_set_length
	cmp	es:[bx],si
	jnc	short rqvc_copy_name
rqvc_set_length:
	mov	es:[bx],si
	mov	es:[bx+2],ax
rqvc_more_name:
	mov	ax,0eah
	jmp	near ptr rqvc_done
rqvc_copy_name:
	push	dword ptr [bp+8]
	mov	es,word ptr [bp+1ah]
	mov	ax,es:[di+8]
	add	ax,di
	add	ax,0ch
	push	es
	push	ax
	push	word ptr es:[di+0ah]
	call	RegMoveMemory
	mov	es,word ptr [bp+1ah]
	db 66h
	cmp	word ptr es:[di],1
	jnz	short rqvc_value_type
	mov	bx,es:[di+0ah]
	add	bx,[bp+8]
	mov	es,word ptr [bp+0ah]
	mov	byte ptr es:[bx],0
rqvc_value_type:
	cmp	dword ptr [bp+4],0
	jz	short rqvc_value_data
	les	bx,dword ptr [bp+4]
	mov	es:[bx],si
	mov	word ptr es:[bx+2],0
rqvc_value_data:
	cmp	dword ptr [bp+14h],0
	jz	short rqvc_ok
	mov	word ptr [bp-2],0
	mov	cx,[bp+10h]
	mov	bx,cx
	mov	es,word ptr [bp+12h]
	mov	ax,es
	mov	es,word ptr [bp+1ah]
	mov	dx,es:[di+8]
	sub	si,si
	mov	es,ax
	cmp	si,es:[bx+2]
	jc	short rqvc_copy_size
	ja	short rqvc_more_data
	cmp	dx,es:[bx]
	jc	short rqvc_copy_size
rqvc_more_data:
	mov	word ptr [bp-2],0eah
	db 66h
	cmp	word ptr es:[bx],0
	jz	near ptr rqvc_more_name
	mov	si,es:[bx]
	dec	si
	jmp	short rqvc_copy_data
rqvc_copy_size:
	les	bx,dword ptr [bp+18h]
	mov	si,es:[bx+8]
rqvc_copy_data:
	push	dword ptr [bp+14h]
	mov	eax,[bp+18h]
	add	ax,0ch
	push	eax
	push	si
	call	RegMoveMemory
	les	bx,dword ptr [bp+14h]
	mov	byte ptr es:[bx+si],0
	les	bx,dword ptr [bp+10h]
	mov	es:[bx],si
	mov	word ptr es:[bx+2],0
	mov	ax,[bp-2]
	jmp	short rqvc_done
rqvc_ok:
	xor	ax,ax
rqvc_done:
	pop	si
	pop	di
	leave
	ret	1ch
RegQueryValueCore endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Query a named value and return the required buffer length.
	public RegQueryValueEx
RegQueryValueEx proc far
	mov	ax,DGROUP
	enter	10h,0
	push	di
	push	ds
	mov	ds,ax
	cmp	dword ptr [bp+1ah],0
	jnz	short rqvt_length
	cmp	dword ptr [bp+16h],0
	jz	short rqvt_length
	mov	ax,57h
	jmp	near ptr rqvt_done
rqvt_length:
	mov	dword ptr [bp-8],0
	cmp	dword ptr [bp+1ah],0
	jz	short rqvt_type
	les	bx,dword ptr [bp+1ah]
	db 66h
	mov	ax,es:[bx]
	mov	[bp-8],eax
rqvt_type:
	mov	di,[bp+12h]
	mov	ax,[bp+14h]
	or	ax,di
	jz	short rqvt_validate
	mov	es,word ptr [bp+14h]
	db 66h
	mov	word ptr es:[di],0
	dw 0
rqvt_validate:
	lea	ax,[bp+6]
	push	ss
	push	ax
	call	RegValidateKeyHandle
	mov	[bp-2],ax
	or	ax,ax
	jnz	near ptr rqvt_result
	push	dword ptr [bp+6]
	push	dword ptr [bp+0ah]
	lea	ax,[bp-10h]
	push	ss
	push	ax
	lea	ax,[bp-0ch]
	push	ss
	push	ax
	lea	ax,[bp-4]
	push	ss
	push	ax
	call	RegFindChainedValue
	mov	[bp-2],ax
	or	ax,ax
	jnz	short rqvt_missing
	push	dword ptr [bp+6]
	push	dword ptr [bp-0ch]
	push	ax
	push	ax
	push	ax
	push	ax
	push	word ptr [bp+14h]
	push	di
	push	dword ptr [bp+16h]
	lea	ax,[bp-8]
	push	ss
	push	ax
	call	RegQueryValueCore
	mov	[bp-2],ax
	les	bx,dword ptr [bp+6]
	db 66h
	push	word ptr es:[bx+0ah]
	push	word ptr [bp-4]
	push	0
	call	RegUnlockDataCache
	jmp	short rqvt_write_length
rqvt_missing:
	cmp	ax,3f4h
	jnz	short rqvt_write_length
	mov	bx,[bp+0ah]
	mov	ax,[bp+0ch]
	or	ax,bx
	jz	short rqvt_default
	mov	es,word ptr [bp+0ch]
	cmp	byte ptr es:[bx],0
	jnz	short rqvt_write_length
rqvt_default:
	mov	ax,[bp+14h]
	or	ax,di
	jz	short rqvt_buffer
	mov	es,word ptr [bp+14h]
	db 66h
	mov	word ptr es:[di],1
	dw 0
rqvt_buffer:
	cmp	dword ptr [bp+16h],0
	jz	short rqvt_set_length
	cmp	dword ptr [bp-8],0
	jz	short rqvt_set_length
	les	bx,dword ptr [bp+16h]
	mov	byte ptr es:[bx],0
rqvt_set_length:
	mov	dword ptr [bp-8],1
	mov	word ptr [bp-2],0
rqvt_write_length:
	cmp	dword ptr [bp+1ah],0
	jz	short rqvt_result
	mov	eax,[bp-8]
	les	bx,dword ptr [bp+1ah]
	db 66h
	mov	es:[bx],ax
rqvt_result:
	call	RegFlushDeferredKeys
	mov	ax,[bp-2]
rqvt_done:
	cwd
	pop	ds
	pop	di
	leave
	retf
RegQueryValueEx endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Find an indexed record across the key and its chained children.
	public RegFindIndexedValue
RegFindIndexedValue proc near
	enter	12h,0
	push	di
	push	si
	mov	di,[bp+0eh]
	push	word ptr [bp+10h]
	push	di
	push	dword ptr [bp+0ah]
	push	word ptr [bp+8]
	lea	ax,[bp-0ah]
	push	ss
	push	ax
	call	RegFindValueByIndex
	mov	[bp-4],ax
	mov	es,word ptr [bp+10h]
	mov	ax,es:[di+16h]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],ax
	cmp	word ptr [bp-4],103h
	jnz	short rfiv_cached
	mov	es,word ptr [bp+10h]
	test	byte ptr es:[di+5],1
	jnz	short rfiv_allocate
rfiv_cached:
	jmp	near ptr rfiv_result
rfiv_allocate:
	push	100h
	call	RegAllocate
	mov	[bp-8],ax
	mov	[bp-6],dx
	or	dx,ax
	jnz	short rfiv_ready
	mov	ax,0eh
	jmp	near ptr rfiv_done
rfiv_ready:
	mov	word ptr [bp-2],0
	mov	di,ax
	cmp	word ptr [bp-4],103h
	jnz	short rfiv_free
	mov	si,[bp+0ch]
rfiv_enumerate:
	cmp	[bp-0ah],si
	ja	short rfiv_free
	sub	si,[bp-0ah]
	mov	dword ptr [bp-12h],100h
	push	dword ptr [bp+0eh]
	push	word ptr [bp-2]
	inc	word ptr [bp-2]
	push	word ptr [bp-6]
	push	di
	lea	ax,[bp-12h]
	push	ss
	push	ax
	push	4
	call	RegEnumValueRecord
	or	ax,ax
	jnz	short rfiv_missing
	push	dword ptr [bp+0eh]
	push	word ptr [bp-6]
	push	di
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	push	4
	call	RegOpenPath
	or	ax,ax
	jnz	short rfiv_missing
	les	bx,dword ptr [bp-0eh]
	mov	ax,es:[bx+16h]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],ax
	push	dword ptr [bp-0eh]
	push	si
	push	dword ptr [bp+8]
	lea	ax,[bp-0ah]
	push	ss
	push	ax
	call	RegFindValueByIndex
	mov	[bp-4],ax
	push	dword ptr [bp-0eh]
	call	RegReleaseKeyHandle
	cmp	word ptr [bp-4],103h
	jz	short rfiv_enumerate
	jmp	short rfiv_free
rfiv_missing:
	mov	word ptr [bp-4],103h
rfiv_free:
	push	word ptr [bp-6]
	push	di
	call	RegDosFree
rfiv_result:
	mov	ax,[bp-4]
rfiv_done:
	pop	si
	pop	di
	leave
	ret	0eh
RegFindIndexedValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Find the value record with the supplied index in a single key.
	public RegFindValueByIndex
RegFindValueByIndex proc near
	enter	8,0
	push	di
	push	si
	mov	si,[bp+0eh]
	les	bx,dword ptr [bp+4]
	mov	word ptr es:[bx],0
	mov	es,word ptr [bp+10h]
	cmp	word ptr es:[si+16h],-1
	jnz	short rfvi_next
	mov	ax,103h
	jmp	near ptr rfvi_done
rfvi_next:
	db 66h
	push	word ptr es:[si+0ah]
	push	word ptr es:[si+16h]
	mov	al,es:[si+18h]
	push	ax
	lea	ax,[bp-8]
	push	ss
	push	ax
	call	RegFetchDataRecord
	mov	di,ax
	or	di,ax
	jnz	short rfvi_result
	les	bx,dword ptr [bp-8]
	mov	ax,es:[bx+0eh]
	les	bx,dword ptr [bp+4]
	mov	es:[bx],ax
	mov	cx,[bp+0ch]
	les	bx,dword ptr [bp-8]
	cmp	es:[bx+0eh],cx
	ja	short rfvi_record
	mov	es,word ptr [bp+10h]
	db 66h
	push	word ptr es:[si+0ah]
	push	word ptr es:[si+16h]
	push	0
	call	RegUnlockDataCache
	mov	di,103h
	jmp	short rfvi_result
rfvi_record:
	mov	si,bx
	mov	ax,es:[si+0ch]
	add	ax,es:[si+10h]
	add	ax,bx
	add	ax,14h
	mov	bx,ax
	mov	word ptr [bp-2],es
	jmp	short rfvi_save
rfvi_available:
	mov	es,word ptr [bp-2]
	mov	ax,es:[bx+8]
	add	ax,es:[bx+0ah]
	add	ax,0ch
	add	bx,ax
rfvi_save:
	mov	ax,cx
	dec	cx
	or	ax,ax
	jnz	short rfvi_available
	les	si,dword ptr [bp+8]
	mov	ax,[bp-2]
	mov	es:[si],bx
	mov	es:[si+2],ax
	xor	di,di
rfvi_result:
	mov	ax,di
rfvi_done:
	pop	si
	pop	di
	leave
	ret	0eh
RegFindValueByIndex endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Return a value name and its data by index.
	public RegEnumValue
RegEnumValue proc far
	mov	ax,DGROUP
	enter	6,0
	push	si
	push	ds
	mov	ds,ax
	cmp	dword ptr [bp+22h],0
	jnz	short rgev_check_buffer
	cmp	dword ptr [bp+1eh],0
	jz	short rgev_check_buffer
	mov	ax,57h
rgev_bad_length:
	xor	dx,dx
	jmp	short rgev_done
rgev_check_buffer:
	cmp	word ptr [bp+0ch],0
	jz	short rgev_validate
	mov	ax,103h
	jmp	short rgev_bad_length
rgev_validate:
	lea	ax,[bp+6]
	push	ss
	push	ax
	call	RegValidateKeyHandle
	mov	si,ax
	or	si,ax
	jnz	short rgev_result
	push	dword ptr [bp+6]
	push	word ptr [bp+0ah]
	lea	ax,[bp-6]
	push	ss
	push	ax
	lea	ax,[bp-2]
	push	ss
	push	ax
	call	RegFindIndexedValue
	mov	si,ax
	or	si,ax
	jnz	short rgev_result
	push	dword ptr [bp+6]
	push	dword ptr [bp-6]
	push	dword ptr [bp+0eh]
	push	dword ptr [bp+12h]
	push	dword ptr [bp+1ah]
	push	dword ptr [bp+1eh]
	push	dword ptr [bp+22h]
	call	RegQueryValueCore
	mov	si,ax
	les	bx,dword ptr [bp+6]
	db 66h
	push	word ptr es:[bx+0ah]
	push	word ptr [bp-2]
	push	0
	call	RegUnlockDataCache
rgev_result:
	call	RegFlushDeferredKeys
	mov	ax,si
	cwd
rgev_done:
	pop	ds
	pop	si
	leave
	retf
RegEnumValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Return the key class and its value and subkey limits.
	public RegQueryInfoKey
RegQueryInfoKey proc far
	mov	ax,DGROUP
	enter	1eh,0
	push	di
	push	si
	push	ds
	mov	ds,ax
	lea	ax,[bp+6]
	push	ss
	push	ax
	call	RegValidateKeyHandle
	mov	di,ax
	or	di,ax
	jnz	near ptr rqik_done
	cmp	dword ptr [bp+22h],0
	jnz	short rqik_count
	cmp	dword ptr [bp+26h],0
	jnz	short rqik_count
	cmp	dword ptr [bp+2ah],0
	jz	near ptr rqik_check_subkeys
rqik_count:
	xor	si,si
	sub	eax,eax
	mov	[bp-4],eax
	mov	[bp-8],eax
	jmp	short rqik_value_count
rqik_scan_class:
	inc	si
	les	bx,dword ptr [bp-12h]
	sub	dx,dx
	mov	ax,es:[bx+8]
	mov	[bp-1eh],ax
	mov	[bp-1ch],dx
	cmp	dx,[bp-2]
	jc	short rqik_class_value
	ja	short rqik_store_class
	cmp	ax,[bp-4]
	jna	short rqik_class_value
rqik_store_class:
	mov	dx,[bp-1ch]
	mov	[bp-4],ax
	mov	[bp-2],dx
rqik_class_value:
	push	dword ptr [bp+6]
	push	es
	push	bx
	push	0
	push	0
	push	0
	push	0
	push	0
	push	0
	push	0
	push	0
	lea	ax,[bp-1ah]
	push	ss
	push	ax
	call	RegQueryValueCore
	mov	di,ax
	les	bx,dword ptr [bp+6]
	db 66h
	push	word ptr es:[bx+0ah]
	push	word ptr [bp-0eh]
	push	0
	call	RegUnlockDataCache
	or	di,di
	jnz	near ptr rqik_done
	mov	eax,[bp-1ah]
	mov	dx,[bp-18h]
	cmp	[bp-8],eax
	jnc	short rqik_value_count
	mov	[bp-8],ax
	mov	[bp-6],dx
rqik_value_count:
	push	dword ptr [bp+6]
	push	si
	lea	ax,[bp-12h]
	push	ss
	push	ax
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	call	RegFindIndexedValue
	mov	di,ax
	or	di,ax
	jz	near ptr rqik_scan_class
	mov	[bp-0ah],di
	mov	[bp-0ch],si
	cmp	di,103h
	jnz	short rqik_check_subkeys
	mov	ecx,[bp+22h]
	or	ecx,ecx
	jz	short rqik_max_value
	mov	bx,cx
	mov	es,word ptr [bp+24h]
	mov	es:[bx],si
	mov	word ptr es:[bx+2],0
rqik_max_value:
	mov	bx,[bp+26h]
	mov	ax,[bp+28h]
	or	ax,bx
	jz	short rqik_data_count
	mov	eax,[bp-4]
	mov	es,word ptr [bp+28h]
	db 66h
	mov	es:[bx],ax
rqik_data_count:
	mov	bx,[bp+2ah]
	mov	ax,[bp+2ch]
	or	ax,bx
	jz	short rqik_subkey_count
	mov	eax,[bp-8]
	mov	es,word ptr [bp+2ch]
	db 66h
	mov	es:[bx],ax
rqik_subkey_count:
	xor	di,di
rqik_check_subkeys:
	cmp	dword ptr [bp+16h],0
	jnz	short rqik_first_subkey
	cmp	dword ptr [bp+1ah],0
	jz	near ptr rqik_done
rqik_first_subkey:
	xor	si,si
	sub	eax,eax
	mov	[bp-4],eax
	mov	[bp-16h],eax
rqik_scan_subkey:
	push	dword ptr [bp+6]
	push	si
	push	0
	push	0
	lea	ax,[bp-16h]
	push	ss
	push	ax
	push	0
	call	RegEnumValueRecord
	mov	di,ax
	or	di,ax
	jz	short rqik_next_subkey
	cmp	di,0eah
	jnz	short rqik_subkey_result
rqik_next_subkey:
	inc	si
	cmp	dword ptr [bp-16h],0
	jz	short rqik_scan_subkey
	mov	eax,[bp-16h]
	inc	eax
	cmp	eax,[bp-4]
	jna	short rqik_scan_subkey
	mov	eax,[bp-16h]
	inc	eax
	mov	[bp-4],eax
	jmp	short rqik_scan_subkey
rqik_subkey_result:
	mov	[bp-0ah],di
	cmp	di,103h
	jnz	short rqik_done
	mov	ecx,[bp+16h]
	or	ecx,ecx
	jz	short rqik_max_subkey
	mov	bx,cx
	mov	es,word ptr [bp+18h]
	mov	es:[bx],si
	mov	word ptr es:[bx+2],0
rqik_max_subkey:
	mov	bx,[bp+1ah]
	mov	ax,[bp+1ch]
	or	ax,bx
	jz	short rqik_ok
	mov	eax,[bp-4]
	mov	es,word ptr [bp+1ch]
	db 66h
	mov	es:[bx],ax
rqik_ok:
	xor	di,di
rqik_done:
	call	RegFlushDeferredKeys
	mov	ax,di
	cwd
	pop	ds
	pop	si
	pop	di
	leave
	retf
RegQueryInfoKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

REGTEXT ends
	end
