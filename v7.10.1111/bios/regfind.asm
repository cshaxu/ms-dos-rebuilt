;** regfind.ASM
;
;
	.386
_DATA segment word public use16 'DATA'
	extrn RegClassesPath:byte
	extrn RegDefaultUser:byte
	extrn RegKeyPool:dword
	extrn RegDynamicKeys:dword
	extrn RegMachineRoot:byte
	extrn RegUserRoot:byte
	extrn RegPredefinedKeys:dword
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'CODE'
_TEXT ends
REGTEXT segment word public use16 'CODE'
CGROUP group _TEXT,REGTEXT
	assume cs:CGROUP,ds:DGROUP
	extrn RegDosAlloc:near
	extrn RegDosFree:near
	extrn RegDosRealloc:near
RegistryCode label byte
	extrn RegSaveFile:near
	extrn RegMaintainCache:near
	extrn RegForEachFile:near
	extrn RegOpenPath:near
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

	public RegInitKeyPool
RegInitKeyPool proc near
	enter 4,0
	push 480h
	call RegAllocate
	mov word ptr RegKeyPool,ax
	mov word ptr RegKeyPool+2,dx
	mov ax,dx
	or ax,word ptr RegKeyPool
	jnz short rikp_fill
	xor ax,ax
	leave
	ret
rikp_fill:
	mov cx,20h
	mov ax,word ptr RegKeyPool
	mov bx,ax
	mov [bp-2],dx
	mov es,word ptr [bp-2]
rikp_next:
	db 66h
	mov word ptr es:[bx],4B48h
	dw 000Ch
	mov word ptr es:[bx+4],0
	add bx,24h
	loop rikp_next
	mov ax,1
	leave
	ret
RegInitKeyPool endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFreeKeyPool
RegFreeKeyPool proc near
	enter 8,0
	push di
	push si
	mov ax,word ptr RegDynamicKeys
	mov dx,word ptr RegDynamicKeys+2
	mov si,ax
	mov [bp-6],dx
	or dx,ax
	jz short rfkp_pool
rfkp_next:
	mov es,word ptr [bp-6]
	mov di,si
	mov ax,es:[si+16h]
	mov dx,es:[si+18h]
	mov si,ax
	mov [bp-6],dx
	push es
	push di
	call RegDosFree
	mov ax,[bp-6]
	cmp si,word ptr RegDynamicKeys
	jnz short rfkp_next
	cmp ax,word ptr RegDynamicKeys+2
	jnz short rfkp_next
rfkp_pool:
	mov RegDynamicKeys,0
	cmp RegKeyPool,0
	jz short rfkp_done
	push RegKeyPool
	call RegDosFree
	mov RegKeyPool,0
rfkp_done:
	pop si
	pop di
	leave
	ret
RegFreeKeyPool endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegAcquireKeyHandle
RegAcquireKeyHandle proc near
	enter 4,0
	push si
	cmp RegKeyPool,0
	jz short rakh_dynamic
	mov cx,20h
	mov ax,word ptr RegKeyPool
	mov dx,word ptr RegKeyPool+2
	mov bx,ax
	mov [bp-2],dx
rakh_scan:
	mov es,word ptr [bp-2]
	test byte ptr es:[bx+2],4
	jnz short rakh_slot
	add bx,24h
	loop rakh_scan
rakh_dynamic:
	push 24h
	call RegAllocate
	mov si,ax
	mov [bp-2],dx
	or dx,ax
	jz rakh_result
	mov es,word ptr [bp-2]
	mov word ptr es:[si],4B48h
	xor ax,ax
	mov es:[si+2],ax
	mov es:[si+4],ax
	cmp RegDynamicKeys,0
	jnz short rakh_link
	mov ax,[bp-2]
	mov es,ax
	mov es:[si+1Ah],si
	mov es:[si+1Ch],ax
	mov es:[si+16h],si
	mov es:[si+18h],ax
	jmp short rakh_head
rakh_slot:
	and byte ptr es:[bx+2],0E9h
	mov ax,bx
	mov dx,es
	pop si
	leave
	ret
rakh_link:
	mov ax,[bp-2]
	cmp si,word ptr RegDynamicKeys
	jnz short rakh_insert
	cmp ax,word ptr RegDynamicKeys+2
	jz short rakh_head
rakh_insert:
	mov eax,RegDynamicKeys
	mov es,word ptr [bp-2]
	db 66h
	mov es:[si+16h],ax
	les bx,RegDynamicKeys
	les bx,es:[bx+1Ah]
	mov ax,es
	mov es,word ptr [bp-2]
	mov es:[si+1Ah],bx
	mov es:[si+1Ch],ax
	mov cx,es
	mov es,ax
	mov es:[bx+16h],si
	mov es:[bx+18h],cx
	les bx,RegDynamicKeys
	mov es:[bx+1Ah],si
	mov es:[bx+1Ch],cx
rakh_head:
	mov ax,[bp-2]
	mov word ptr RegDynamicKeys,si
	mov word ptr RegDynamicKeys+2,ax
rakh_result:
	mov ax,si
	mov dx,[bp-2]
	pop si
	leave
	ret
RegAcquireKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegReleaseKeyHandle
RegReleaseKeyHandle proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	cmp word ptr es:[si+4],0
	jz short rrkh_count
	dec word ptr es:[si+4]
rrkh_count:
	mov es,word ptr [bp+6]
	cmp word ptr es:[si+4],0
	jnz short rrkh_done
	test byte ptr es:[si+2],81h
	jnz short rrkh_done
	test byte ptr es:[si+2],8
	jz short rrkh_dynamic
	or byte ptr es:[si+2],4
	jmp short rrkh_done
rrkh_dynamic:
	mov ax,es
	cmp es:[si+16h],si
	jnz short rrkh_unlink
	cmp es:[si+18h],ax
	jnz short rrkh_unlink
	mov RegDynamicKeys,0
	jmp short rrkh_free
rrkh_unlink:
	db 66h
	mov ax,es:[si+16h]
	les bx,es:[si+1Ah]
	db 66h
	mov es:[bx+16h],ax
	mov es,word ptr [bp+6]
	db 66h
	mov ax,es:[si+1Ah]
	les bx,es:[si+16h]
	db 66h
	mov es:[bx+1Ah],ax
	mov ax,[bp+6]
	cmp si,word ptr RegDynamicKeys
	jnz short rrkh_free
	cmp ax,word ptr RegDynamicKeys+2
	jnz short rrkh_free
	mov es,ax
	db 66h
	mov ax,es:[si+16h]
	mov RegDynamicKeys,eax
rrkh_free:
	mov es,word ptr [bp+6]
	mov word ptr es:[si],0
	push es
	push si
	call RegDosFree
rrkh_done:
	pop si
	leave
	ret 4
RegReleaseKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegValidateKeyHandle
RegValidateKeyHandle proc near
	enter 0Ch,0
	push di
	push si
	mov di,[bp+4]
	mov es,word ptr [bp+6]
	db 66h
	mov ax,es:[di]
	mov dx,es:[di+2]
	mov [bp-0Ch],eax
	cmp dx,8000h
	jb short rvht_ordinary
	jbe short rvht_range
rvht_ordinary:
	jmp rvht_validate
rvht_range:
	jb short rvht_predefined
	cmp ax,6
	jae rvht_validate
rvht_predefined:
	mov si,ax
	mov bx,ax
	shl bx,2
	mov eax,dword ptr RegPredefinedKeys[bx]
	mov [bp-0Ch],eax
	or eax,eax
	jz short rvht_create
	les bx,[bp-0Ch]
	test byte ptr es:[bx+2],2
	jz rvht_set
rvht_create:
	or si,si
	jnz short rvht_default
	mov word ptr [bp-4],offset DGROUP:RegMachineRoot
	mov [bp-2],ds
	mov word ptr [bp-8],offset DGROUP:RegClassesPath
	jmp short rvht_prepare
rvht_default:
	cmp si,1
	jnz rvht_bad
	mov word ptr [bp-4],offset DGROUP:RegUserRoot
	mov [bp-2],ds
	mov word ptr [bp-8],offset DGROUP:RegDefaultUser
rvht_prepare:
	mov [bp-6],ds
	cmp dword ptr [bp-0Ch],0
	jz short rvht_open
	mov bx,si
	shl bx,2
	mov dword ptr RegPredefinedKeys[bx],0
	les bx,[bp-0Ch]
	and byte ptr es:[bx+2],0FEh
	push dword ptr [bp-0Ch]
	call RegReleaseKeyHandle
rvht_open:
	les bx,[bp-4]
	test byte ptr es:[bx+2],4
	jnz short rvht_bad
	push es
	push bx
	push dword ptr [bp-8]
	lea ax,[bp-0Ch]
	push ss
	push ax
	push 1
	call RegOpenPath
	or ax,ax
	jnz short rvht_bad
	mov ax,[bp-0Ch]
	mov dx,[bp-0Ah]
	mov bx,si
	shl bx,2
	mov word ptr RegPredefinedKeys[bx],ax
	mov word ptr RegPredefinedKeys[bx+2],dx
	mov bx,ax
	mov es,dx
	or byte ptr es:[bx+2],1
	mov ax,si
	les bx,[bp-0Ch]
	mov es:[bx+15h],al
rvht_set:
	mov eax,[bp-0Ch]
	mov es,word ptr [bp+6]
	db 66h
	mov es:[di],ax
	les bx,[bp-0Ch]
	mov al,es:[bx+2]
	and ax,4
	cmp ax,1
	cmc
	sbb ax,ax
	and ax,3F2h
	jmp short rvht_done
rvht_validate:
	les bx,[bp-0Ch]
	cmp word ptr es:[bx],4B48h
	jnz short rvht_bad
	test byte ptr es:[bx+2],4
	jnz short rvht_bad
	mov al,es:[bx+2]
	and ax,2
	cmp ax,1
	cmc
	sbb ax,ax
	and ax,3FAh
	jmp short rvht_done
rvht_bad:
	mov ax,3F2h
rvht_done:
	pop si
	pop di
	leave
	ret 4
RegValidateKeyHandle endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegRetainKeyHandle
RegRetainKeyHandle proc near
	push bp
	mov bp,sp
	mov bx,[bp+4]
	mov es,word ptr [bp+6]
	cmp word ptr es:[bx+4],-1
	jz short rrkh_saturated
	inc word ptr es:[bx+4]
	jmp short rrkh_retained
rrkh_saturated:
	or byte ptr es:[bx+2],80h
rrkh_retained:
	leave
	ret 4
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
	cmp es:[bx+6],ax
	jnz short rlkh_next_root
	mov eax,[bp+4]
	db 66h
	cmp es:[bx+0Ah],ax
	jnz short rlkh_next_root
	test byte ptr es:[bx+2],6
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
	cmp es:[bx+6],di
	jnz short rlkh_next_pool
	cmp es:[bx+8],ax
	jnz short rlkh_next_pool
	mov eax,[bp+4]
	db 66h
	cmp es:[bx+0Ah],ax
	jnz short rlkh_next_pool
	test byte ptr es:[bx+2],6
	jz short rlkh_found
rlkh_next_pool:
	add bx,24h
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
	cmp es:[bx+0Ah],ax
	jnz short rlkh_next
	mov ax,[bp+0Ah]
	cmp es:[bx+6],di
	jnz short rlkh_next
	cmp es:[bx+8],ax
	jnz short rlkh_next
	test byte ptr es:[bx+2],2
	jz short rlkh_found
rlkh_next:
	mov ax,es:[bx+16h]
	mov dx,es:[bx+18h]
	mov bx,ax
	mov [bp-6],dx
	mov ax,dx
	cmp bx,word ptr RegDynamicKeys
	jnz short rlkh_list
	cmp ax,word ptr RegDynamicKeys+2
	jnz short rlkh_list
	jmp short rlkh_missing
rlkh_found:
	mov ax,bx
	mov dx,[bp-6]
	jmp short rlkh_done
rlkh_missing:
	xor ax,ax
	cwd
rlkh_done:
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
	cmp es:[bx+6],ax
	jz short rikh_mark_root
	mov al,[bp+4]
	cmp es:[bx+15h],al
	jnz short rikh_next_root
rikh_mark_root:
	or byte ptr es:[bx+2],6
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
	cmp es:[bx+6],di
	jnz short rikh_pool_root
	cmp es:[bx+8],ax
	jz short rikh_mark_pool
rikh_pool_root:
	mov al,es:[bx+15h]
	sub ah,ah
	cmp ax,[bp+4]
	jnz short rikh_next_pool
rikh_mark_pool:
	or byte ptr es:[bx+2],6
rikh_next_pool:
	add bx,24h
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
	cmp es:[bx+6],di
	jnz short rikh_list_root
	cmp es:[bx+8],ax
	jz short rikh_mark_list
rikh_list_root:
	cmp es:[bx+15h],cl
	jnz short rikh_next
rikh_mark_list:
	or byte ptr es:[bx+2],6
rikh_next:
	mov es,word ptr [bp-2]
	mov ax,es:[bx+16h]
	mov dx,es:[bx+18h]
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

REGTEXT ends
	end
