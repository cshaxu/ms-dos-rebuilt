;** REGOPEN - Registry paths and values
;
; FAR C entries call the key cache and record services through near entries.
; Path and value-name operations use the shared registry state in DGROUP.
;
	.386
_DATA segment word public use16 'RESUME_DATA'
	extrn RegPathCursor:dword
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
	extrn RegGrowDataExtent:near
	extrn RegFreeDataExtent:near
	extrn RegTrimDataSlots:near
	extrn RegTakeDataExtent:near
	extrn RegRemoveValueRecord:near
	extrn RegValueNameNumber:near
	extrn RegFormatValueName:near
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
	enter 4,0
	push si
	mov bx,[bp+0Ch]
	mov ax,[bp+0Eh]
	or ax,bx
	jz short rnpp_scan
	mov ax,[bp+0Eh]
	mov word ptr RegPathCursor,bx
	mov word ptr RegPathCursor+2,ax
rnpp_scan:
	les bx,RegPathCursor
	mov si,bx
	mov [bp-2],es
	cmp byte ptr es:[bx],0
	jnz short rnpp_start
	les bx,[bp+8]
	sub eax,eax
	db 66h
	mov es:[bx],ax
	les bx,[bp+4]
	mov es:[bx],ax
	jmp short rnpp_done
rnpp_start:
	mov es,word ptr [bp-2]
	cmp byte ptr es:[si],'\'
	jnz short rnpp_store
	inc si
rnpp_store:
	mov ax,es
	les bx,[bp+8]
	mov es:[bx],si
	mov es:[bx+2],ax
	mov es,ax
	cmp byte ptr es:[si],0
	jz short rnpp_end
rnpp_next:
	mov es,word ptr [bp-2]
	cmp byte ptr es:[si],'\'
	jz short rnpp_end
	inc si
	cmp byte ptr es:[si],0
	jnz short rnpp_next
rnpp_end:
	mov ax,[bp-2]
	mov word ptr RegPathCursor,si
	mov word ptr RegPathCursor+2,ax
	mov ax,si
	les si,[bp+8]
	sub ax,es:[si]
	les si,[bp+4]
	mov es:[si],ax
rnpp_done:
	pop si
	leave
	ret 0Ch
RegPathPart endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegOpenPath
RegOpenPath proc near
	enter 2Eh,0
	push di
	push si
	mov si,[bp+0Ah]
	mov word ptr [bp-02Ah],0
	mov ax,[bp+0Ch]
	or ax,si
	jz short ropt_empty
	push word ptr [bp+0Ch]
	push si
	lea ax,[bp-024h]
	push ss
	push ax
	lea ax,[bp-010h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jnz short ropt_start
ropt_empty:
	jmp near ptr ropt_parent
ropt_start:
	mov al,[bp+4]
	and al,1
	jnz short ropt_parent_key
	mov ax,si
	sub ax,[bp-024h]
	neg ax
	add [bp-010h],ax
	mov ax,[bp+0Ch]
	mov [bp-024h],si
	mov [bp-022h],ax
ropt_parent_key:
	les bx,[bp+0Eh]
	db 66h
	mov ax,es:[bx+6]
	mov [bp-0Ah],eax
	db 66h
	mov ax,es:[bx+0Eh]
	mov [bp-018h],eax
	db 66h
	mov ax,es:[bx+0Ah]
	mov [bp-0Eh],eax
	mov word ptr [bp-014h],0
ropt_component:
	push dword ptr [bp-024h]
	push word ptr [bp-010h]
	call RegNameChecksum
	mov [bp-6],ax
	mov [bp-4],dx
	cmp dword ptr [bp-018h],0FFFFFFh
	jnc short ropt_nochild
	mov si,[bp-0Ah]
ropt_find:
	mov word ptr [bp-2],0
ropt_fetch:
	push word ptr [bp-8]
	push si
	push dword ptr [bp-018h]
	lea ax,[bp-01Ch]
	push ss
	push ax
	call RegFetchKeyRecord
	mov di,ax
	or di,ax
	jnz near ptr ropt_data_error
	les bx,[bp-01Ch]
	sub dx,dx
	mov ax,es:[bx+0Eh]
	cmp ax,[bp-6]
	jnz short ropt_next_nomatch
	cmp dx,[bp-4]
	jz short ropt_fetch_data
ropt_next_nomatch:
	jmp near ptr ropt_skip_record
ropt_fetch_data:
	push word ptr [bp-8]
	push si
	push word ptr es:[bx+0Ch]
	mov al,es:[bx+0Bh]
	sub ah,ah
	push ax
	lea ax,[bp-020h]
	push ss
	push ax
	call RegFetchDataRecord
	mov di,ax
	or di,ax
	jz short ropt_check_class
	push word ptr [bp-8]
	push si
	push dword ptr [bp-018h]
	push 0
	call RegUnlockKeyCache
	cmp word ptr [bp-2],0
	jnz near ptr ropt_data_error
	mov word ptr [bp-2],1
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	push offset CGROUP:RegMaintainCache
	call RegForEachFile
	jmp short ropt_fetch
ropt_nochild:
	mov si,[bp-0Ah]
	jmp near ptr ropt_found
ropt_check_class:
	mov [bp-012h],di
	les bx,[bp-01Ch]
	test word ptr es:[bx+2],0400h
	jnz short ropt_ordinary_key
	mov ax,1
	jmp short ropt_key_class
ropt_ordinary_key:
	xor ax,ax
ropt_key_class:
	mov cl,[bp+4]
	and cx,4
	cmp cx,1
	sbb cx,cx
	neg cx
	cmp ax,cx
	jnz short ropt_nomatch
	mov ax,[bp-010h]
	les bx,[bp-020h]
	cmp es:[bx+0Ch],ax
	jnz short ropt_nomatch
	push dword ptr [bp-024h]
	lea ax,[bx+014h]
	push es
	push ax
	push word ptr [bp-010h]
	call RegCompareName
	or ax,ax
	jnz short ropt_nomatch
	mov di,1
	jmp short ropt_release_data
ropt_nomatch:
	xor di,di
ropt_release_data:
	push word ptr [bp-8]
	push si
	les bx,[bp-01Ch]
	push word ptr es:[bx+0Ch]
	push 0
	call RegUnlockDataCache
	or di,di
	jnz short ropt_found
ropt_next:
	mov word ptr [bp-014h],1
	mov eax,[bp-018h]
	mov [bp-0Eh],eax
	les bx,[bp-01Ch]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	sub dh,dh
	mov [bp-018h],ax
	mov [bp-016h],dx
	push word ptr [bp-8]
	push si
	push dword ptr [bp-0Eh]
	push 0
	call RegUnlockKeyCache
	cmp dword ptr [bp-018h],0FFFFFFh
	jc near ptr ropt_find
ropt_found:
	cmp dword ptr [bp-018h],0FFFFFFh
	jnc short ropt_create_check
	push 0
	push 0
	lea ax,[bp-024h]
	push ss
	push ax
	lea ax,[bp-010h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jz short ropt_create_check
	mov eax,[bp-018h]
	mov [bp-0Eh],eax
	les bx,[bp-01Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	sub dh,dh
	mov [bp-018h],ax
	mov [bp-016h],dx
	push word ptr [bp-8]
	push si
	push dword ptr [bp-0Eh]
	xor ax,ax
	mov [bp-014h],ax
	push ax
	call RegUnlockKeyCache
	jmp near ptr ropt_component
ropt_skip_record:
	mov [bp-012h],di
	jmp near ptr ropt_next
ropt_data_error:
	mov ax,di
	jmp near ptr ropt_exit
ropt_create_check:
	cmp dword ptr [bp-018h],0FFFFFFh
	jc near ptr ropt_finish_key
	mov al,[bp+4]
	and al,1
	jnz short ropt_permission
	mov ax,03F3h
	jmp near ptr ropt_exit
ropt_permission:
	mov es,[bp-8]
	test byte ptr es:[si+056h],080h
	jz short ropt_parent_record
	mov ax,5
	jmp near ptr ropt_exit
ropt_parent_record:
	push es
	push si
	push dword ptr [bp-0Eh]
	lea ax,[bp-01Ch]
	push ss
	push ax
	call RegFetchKeyRecord
	mov di,ax
	or di,ax
	jnz short ropt_data_error
	push word ptr [bp-8]
	push si
	push dword ptr [bp-0Eh]
	call RegLookupKeyHandle
	mov [bp-4],ax
	mov [bp-2],dx
ropt_create:
	push word ptr [bp-8]
	push si
	lea ax,[bp-018h]
	push ss
	push ax
	lea ax,[bp-028h]
	push ss
	push ax
	call RegAllocateKeyRecord
	mov di,ax
	or di,ax
	jnz near ptr ropt_alloc_error
	push word ptr [bp-8]
	push si
	mov ax,[bp-010h]
	add ax,014h
	push ax
	lea ax,[bp-020h]
	push ss
	push ax
	call RegAllocateDataRecord
	mov [bp-012h],ax
	or ax,ax
	jnz near ptr ropt_free_new
	cmp [bp-014h],ax
	jz short ropt_first_child
	mov [bp-014h],ax
	cwd
	mov di,ax
	mov [bp-2],dx
	les bx,[bp-028h]
	mov ax,es:[bx+8]
	mov dx,es:[bx+0Ah]
	les bx,[bp-01Ch]
	xor ax,es:[bx+8]
	xor dx,es:[bx+0Ah]
	sub dh,dh
	les bx,[bp-028h]
	xor es:[bx+8],ax
	xor es:[bx+0Ah],dx
	les bx,[bp-01Ch]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	xor ax,[bp-018h]
	xor dx,[bp-016h]
	sub dh,dh
	xor es:[bx],ax
	xor es:[bx+2],dx
	jmp short ropt_linked
ropt_first_child:
	les bx,[bp-028h]
	mov ax,es:[bx+8]
	mov dx,es:[bx+0Ah]
	xor ax,[bp-0Eh]
	xor dx,[bp-0Ch]
	sub dh,dh
	xor es:[bx+8],ax
	xor es:[bx+0Ah],dx
	les bx,[bp-01Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	xor ax,[bp-018h]
	xor dx,[bp-016h]
	sub dh,dh
	xor es:[bx+4],ax
	xor es:[bx+6],dx
	mov di,[bp-4]
	mov ax,[bp-2]
	or ax,di
	jz short ropt_linked
	mov es,[bp-2]
	db 66h,26h,81h,7Dh,0Eh
	dd 0FFFFFFh
	jc short ropt_clear_handle
	mov eax,[bp-018h]
	db 66h
	mov es:[di+0Eh],ax
ropt_clear_handle:
	xor ax,ax
	cwd
	mov di,ax
	mov [bp-2],dx
ropt_linked:
	les bx,[bp-028h]
	db 66h,26h,81h,0Fh
	dd 0FFFFFFh
	les bx,[bp-028h]
	db 66h,26h,81h,4Fh,4
	dd 0FFFFFFh
	les bx,[bp-020h]
	mov ax,es:[bx+6]
	les bx,[bp-028h]
	mov es:[bx+0Ch],ax
	les bx,[bp-020h]
	sub al,al
	mov ah,es:[bx+4]
	mov dx,ax
	sub cx,cx
	les bx,[bp-028h]
	mov [bp-02Eh],cx
	mov [bp-02Ch],ax
	xor cx,es:[bx+8]
	xor dx,es:[bx+0Ah]
	and dh,al
	xor cx,[bp-02Eh]
	xor dx,ax
	mov es:[bx+8],cx
	mov es:[bx+0Ah],dx
	push dword ptr [bp-024h]
	push word ptr [bp-010h]
	call RegNameChecksum
	les bx,[bp-028h]
	mov es:[bx+0Eh],ax
	mov ax,[bp-010h]
	add ax,014h
	les bx,[bp-020h]
	mov es:[bx+8],ax
	mov word ptr es:[bx+0Ah],0
	mov ax,[bp-010h]
	les bx,[bp-020h]
	mov es:[bx+0Ch],ax
	mov eax,[bp-020h]
	add ax,014h
	push eax
	push dword ptr [bp-024h]
	push word ptr [bp-010h]
	call RegMoveMemory
	les bx,[bp-020h]
	mov word ptr es:[bx+0Eh],0
	les bx,[bp-020h]
	mov word ptr es:[bx+010h],0
	les bx,[bp-020h]
	mov word ptr es:[bx+012h],0
	push word ptr [bp-8]
	push si
	push dword ptr [bp-0Eh]
	push 1
	call RegUnlockKeyCache
	mov eax,[bp-018h]
	mov [bp-0Eh],eax
	mov eax,[bp-028h]
	mov [bp-01Ch],eax
	push word ptr [bp-8]
	push si
	les bx,[bp-020h]
	push word ptr es:[bx+6]
	push 1
	call RegUnlockDataCache
	mov word ptr [bp-02Ah],1
	mov [bp-4],di
	push 0
	push 0
	lea ax,[bp-024h]
	push ss
	push ax
	lea ax,[bp-010h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jnz near ptr ropt_create
ropt_finish_key:
	push dword ptr [bp-0Ah]
	push dword ptr [bp-018h]
	call RegLookupKeyHandle
	mov di,ax
	mov [bp-2],dx
	or dx,ax
	jnz near ptr ropt_release_key
	call RegAcquireKeyHandle
	mov di,ax
	mov [bp-2],dx
	or dx,ax
	jnz short ropt_init_handle
	mov word ptr [bp-012h],0Eh
	jmp near ptr ropt_release_key
ropt_free_new:
	push word ptr [bp-8]
	push si
	push dword ptr [bp-018h]
	push 0
	call RegUnlockKeyCache
	push word ptr [bp-8]
	push si
	push dword ptr [bp-018h]
	call RegFreeKeyRecord
ropt_release_parent:
	push word ptr [bp-8]
	push si
	push dword ptr [bp-0Eh]
	push word ptr [bp-02Ah]
	call RegUnlockKeyCache
	jmp near ptr ropt_result
ropt_alloc_error:
	mov [bp-012h],di
	jmp short ropt_release_parent
ropt_init_handle:
	mov eax,[bp-0Ah]
	mov es,[bp-2]
	db 66h
	mov es:[di+6],ax
	mov eax,[bp-018h]
	db 66h
	mov es:[di+0Ah],ax
	les bx,[bp-01Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	sub dh,dh
	mov es,[bp-2]
	mov es:[di+0Eh],ax
	mov es:[di+010h],dx
	les bx,[bp-01Ch]
	mov ax,es:[bx+0Ch]
	mov es,[bp-2]
	mov es:[di+012h],ax
	les bx,[bp-01Ch]
	sub ah,ah
	mov al,es:[bx+0Bh]
	mov es,[bp-2]
	mov es:[di+016h],al
	les bx,[bp+0Eh]
	mov al,es:[bx+017h]
	mov es,[bp-2]
	mov es:[di+017h],al
	les bx,[bp-01Ch]
	test word ptr es:[bx+2],0200h
	jz short ropt_release_key
	mov es,[bp-2]
	or byte ptr es:[di+3],1
ropt_release_key:
	push dword ptr [bp-0Ah]
	push dword ptr [bp-018h]
	push word ptr [bp-02Ah]
	call RegUnlockKeyCache
	mov ax,[bp-2]
	or ax,di
	jz short ropt_result
	mov [bp-4],di
	mov si,di
	jmp short ropt_retain
ropt_parent:
	mov ax,[bp+0Eh]
	mov dx,[bp+010h]
	mov si,ax
	mov [bp-2],dx
ropt_retain:
	mov ax,[bp-2]
	push ax
	push si
	mov di,ax
	call RegRetainKeyHandle
	les bx,[bp+6]
	mov es:[bx],si
	mov es:[bx+2],di
	mov word ptr [bp-012h],0
ropt_result:
	mov ax,[bp-012h]
ropt_exit:
	pop si
	pop di
	leave
	ret 0Eh
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
	mov ax,di
rokt_done:
	pop di
	leave
	ret 0Eh
RegFindOrCreate endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Create or open a key through the common path resolver.
	public RegCreateKey
RegCreateKey proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push ds
	mov ds,ax
	push dword ptr [bp+6]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+0Eh]
	push 1
	call RegFindOrCreate
	cwd
	pop ds
	leave
	retf
RegCreateKey endp
	if ($ - RegistryCode) and 1
	db 0
	endif

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

; Expand the locked value record in place or move it to a new extent.
	public RegResizeValueRecord
RegResizeValueRecord proc near
	enter 022h,0
	push di
	push si
	cmp dword ptr [bp+8],0EFE0h
	jna short rrvr_try_next
	mov ax,0401h
	jmp near ptr rrvr_no_memory
rrvr_try_next:
	mov si,[bp+4]
	mov es,[bp+6]
	db 66h
	mov ax,es:[si]
	mov dx,es:[si+2]
	mov [bp-0Ah],eax
	mov bx,ax
	mov es,dx
	mov cx,es:[bx+4]
	mov dx,es:[bx+6]
	mov di,dx
	mov [bp-6],cx
	les bx,[bp+0Ch]
	db 66h
	push word ptr es:[bx+6]
	push dx
	push word ptr [bp+8]
	push word ptr [bp-8]
	push ax
	call RegGrowDataExtent
	or ax,ax
	jnz short rrvr_copy_record
rrvr_allocate_record:
	xor ax,ax
	jmp near ptr rrvr_no_memory
rrvr_copy_record:
	mov si,[bp+0Ch]
	mov es,[bp+0Eh]
	db 66h
	push word ptr es:[si+6]
	push di
	push dword ptr [bp+6]
	push word ptr [bp+4]
	call RegTakeDataExtent
	or ax,ax
	jnz near ptr rrvr_release_old
	mov es,[bp+0Eh]
	les bx,es:[si+6]
	mov ax,es:[bx+010h]
	mov dx,es:[bx+012h]
	imul cx,di,014h
	add ax,cx
	mov [bp-4],ax
	mov [bp-2],dx
	mov cx,[bp-6]
	add cx,cx
	mov es,dx
	mov bx,ax
	mov [bp-014h],ax
	mov word ptr [bp-012h],es
	les bx,es:[bx+4]
	add bx,cx
	mov ax,es:[bx]
	les bx,[bp-014h]
	add ax,es:[bx]
	mov dx,es:[bx+2]
	mov [bp-0Ah],ax
	mov [bp-8],dx
	les bx,[bp+4]
	mov [bp-018h],ax
	mov [bp-016h],dx
	db 66h
	mov ax,es:[bx]
	add ax,4
	push eax
	mov eax,[bp-018h]
	add ax,4
	push eax
	les bx,[bp-018h]
	mov ax,es:[bx+8]
	sub ax,4
	push ax
	mov [bp-01Ah],cx
	call RegMoveMemory
	push dword ptr [bp-4]
	push dword ptr [bp-0Ah]
	call RegFreeDataExtent
	les bx,[bp+4]
	mov ax,es:[bx]
	les bx,[bp-4]
	sub ax,es:[bx]
	les bx,es:[bx+4]
	add bx,[bp-01Ah]
	mov es:[bx],ax
	jmp near ptr rrvr_allocate_record
rrvr_release_old:
	mov es,[bp+0Eh]
	db 66h
	push word ptr es:[si+6]
	db 66h
	push word ptr es:[si+0Ah]
	lea ax,[bp-010h]
	push ss
	push ax
	call RegFetchKeyRecord
	or ax,ax
	jnz near ptr rrvr_finish
	mov es,[bp+0Eh]
	db 66h
	push word ptr es:[si+6]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	call RegAllocateDataRecord
	mov [bp-0Ch],ax
	or ax,ax
	jnz near ptr rrvr_install_new
	mov es,[bp+0Eh]
	les bx,es:[si+6]
	mov ax,es:[bx+010h]
	mov dx,es:[bx+012h]
	imul cx,di,014h
	add ax,cx
	mov [bp-4],ax
	mov [bp-2],dx
	mov cx,[bp-6]
	add cx,cx
	mov es,dx
	mov bx,ax
	les bx,es:[bx+4]
	add bx,cx
	mov cx,es:[bx]
	mov bx,ax
	mov es,dx
	add cx,es:[bx]
	mov ax,es:[bx+2]
	mov [bp-0Ah],cx
	mov [bp-8],ax
	les bx,[bp+4]
	mov [bp-01Eh],cx
	mov [bp-01Ch],ax
	db 66h
	mov ax,es:[bx]
	add ax,8
	push eax
	mov ax,cx
	mov dx,[bp-01Ch]
	add ax,8
	push dx
	push ax
	mov bx,ax
	mov es,dx
	mov ax,es:[bx]
	sub ax,8
	push ax
	call RegMoveMemory
	push dword ptr [bp-4]
	push dword ptr [bp-0Ah]
	call RegFreeDataExtent
	push dword ptr [bp-4]
	push word ptr [bp-6]
	call RegTrimDataSlots
	mov es,[bp+0Eh]
	db 66h
	push word ptr es:[si+6]
	push di
	push 1
	call RegUnlockDataCache
	les bx,[bp+4]
	les bx,es:[bx]
	mov ax,es:[bx+6]
	mov es,[bp+0Eh]
	mov es:[si+012h],ax
	mov es:[si+014h],ax
	mov ax,es:[si+012h]
	les bx,[bp-010h]
	mov es:[bx+0Ch],ax
	les bx,[bp+4]
	les bx,es:[bx]
	mov al,es:[bx+4]
	mov es,[bp+0Eh]
	mov es:[si+016h],al
	mov ah,al
	sub al,al
	mov dx,ax
	sub cx,cx
	les bx,[bp-010h]
	mov [bp-022h],cx
	mov [bp-020h],ax
	xor cx,es:[bx+8]
	xor dx,es:[bx+0Ah]
	and dh,al
	xor cx,[bp-022h]
	xor dx,ax
	mov es:[bx+8],cx
	mov es:[bx+0Ah],dx
rrvr_install_new:
	mov es,[bp+0Eh]
	db 66h
	push word ptr es:[si+6]
	db 66h
	push word ptr es:[si+0Ah]
	push 1
	call RegUnlockKeyCache
	mov ax,[bp-0Ch]
	jmp short rrvr_no_memory
rrvr_finish:
	mov ax,0Eh
rrvr_no_memory:
	pop si
	pop di
	leave
	ret 0Ch
RegResizeValueRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Find the value in its owning key or select a continuation key for the write.
	public RegWriteChainedValue
RegWriteChainedValue proc near
	enter 020h,0
	push di
	push si
	mov si,[bp+0Eh]
	mov di,[bp+012h]
	mov word ptr [bp-0Ch],1
	mov word ptr [bp-6],0
	push word ptr [bp+014h]
	push di
	push word ptr [bp+010h]
	push si
	push dword ptr [bp+0Ah]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	xor ax,ax
	mov [bp-2],ax
	push ax
	call RegWriteValueRecord
	mov [bp-4],ax
	cmp ax,0401h
	jnz near ptr rwcv_enumerate
	push word ptr [bp+014h]
	push di
	push word ptr [bp+010h]
	push si
	lea ax,[bp-018h]
	push ss
	push ax
	lea ax,[bp-01Ch]
	push ss
	push ax
	call RegFindChainedValue
	mov [bp-4],ax
	or ax,ax
	jnz near ptr rwcv_select_key
	mov es,[bp+014h]
	mov ax,es:[di+014h]
	cmp es:[di+012h],ax
	jz short rwcv_search_existing
	mov word ptr [bp-2],1
rwcv_search_existing:
	push dword ptr [bp-018h]
	push dword ptr [bp-01Ch]
	call RegRemoveValueRecord
	mov es,[bp+014h]
	db 66h
	push word ptr es:[di+6]
	push word ptr es:[di+014h]
	push 1
	call RegUnlockDataCache
rwcv_use_chain:
	push 0100h
	call RegAllocate
	mov [bp-0Ah],ax
	mov [bp-8],dx
	or dx,ax
	jz near ptr rwcv_check_next
	mov di,[bp+012h]
	mov es,[bp+014h]
	test byte ptr es:[di+3],1
	jz near ptr rwcv_create_key
	cmp word ptr [bp-2],0
	jz short rwcv_replace_value
	push es
	push di
	push dword ptr [bp+0Eh]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	push 1
	call RegWriteValueRecord
	mov si,ax
	or si,ax
	jz near ptr rwcv_done_chain
rwcv_replace_value:
	mov word ptr [bp-2],0
	mov di,[bp-0Ah]
rwcv_alloc_error:
	mov dword ptr [bp-020h],0100h
	push dword ptr [bp+012h]
	push word ptr [bp-2]
	inc word ptr [bp-2]
	push word ptr [bp-8]
	push di
	lea ax,[bp-020h]
	push ss
	push ax
	push 4
	call RegEnumValueRecord
	or ax,ax
	jnz short rwcv_make_name
	push word ptr [bp-8]
	push di
	call RegValueNameNumber
	mov [bp-0Ch],ax
	cmp ax,[bp-6]
	jna short rwcv_write_current
	mov [bp-6],ax
rwcv_write_current:
	push dword ptr [bp+012h]
	push word ptr [bp-8]
	push di
	lea ax,[bp-010h]
	push ss
	push ax
	push 4
	call RegOpenPath
	or ax,ax
	jnz short rwcv_make_name
	push dword ptr [bp-010h]
	push dword ptr [bp+0Eh]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	push 1
	call RegWriteValueRecord
	mov si,ax
	push dword ptr [bp-010h]
	call RegReleaseKeyHandle
	cmp si,0401h
	jz short rwcv_alloc_error
	jmp near ptr rwcv_done_chain
rwcv_enumerate:
	mov si,ax
	jmp near ptr rwcv_release_buffer
rwcv_select_key:
	cmp ax,03F4h
	jz near ptr rwcv_use_chain
rwcv_check_next:
	mov ax,0Eh
	jmp near ptr rwcv_done
rwcv_make_name:
	mov di,[bp+012h]
rwcv_create_key:
	cmp word ptr [bp-6],0
	jz short rwcv_mark_child
	mov ax,[bp-6]
	inc ax
	mov [bp-0Ch],ax
rwcv_mark_child:
	push word ptr [bp-0Ch]
	push dword ptr [bp-0Ah]
	call RegFormatValueName
	push word ptr [bp+014h]
	push di
	push dword ptr [bp-0Ah]
	lea ax,[bp-010h]
	push ss
	push ax
	push 1
	call RegOpenPath
	mov si,ax
	or si,ax
	jnz near ptr rwcv_done_chain
	mov es,[bp+014h]
	test byte ptr es:[di+3],1
	jnz short rwcv_write_new
	db 66h
	push word ptr es:[di+6]
	db 66h
	push word ptr es:[di+0Ah]
	lea ax,[bp-014h]
	push ss
	push ax
	call RegFetchKeyRecord
	mov si,ax
	or si,ax
	jnz short rwcv_done_chain
	les bx,[bp-014h]
	or byte ptr es:[bx+3],2
	mov es,[bp+014h]
	or byte ptr es:[di+3],1
	db 66h
	push word ptr es:[di+6]
	db 66h
	push word ptr es:[di+0Ah]
	push 1
	call RegUnlockKeyCache
rwcv_write_new:
	les bx,[bp-010h]
	db 66h
	push word ptr es:[bx+6]
	db 66h
	push word ptr es:[bx+0Ah]
	lea ax,[bp-014h]
	push ss
	push ax
	call RegFetchKeyRecord
	mov si,ax
	or si,ax
	jnz short rwcv_done_chain
	les bx,[bp-014h]
	or byte ptr es:[bx+3],4
	les bx,[bp-010h]
	db 66h
	push word ptr es:[bx+6]
	db 66h
	push word ptr es:[bx+0Ah]
	push 1
	call RegUnlockKeyCache
	push dword ptr [bp-010h]
	push dword ptr [bp+0Eh]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+6]
	push word ptr [bp+4]
	push 1
	call RegWriteValueRecord
	mov si,ax
	push dword ptr [bp-010h]
	call RegReleaseKeyHandle
rwcv_done_chain:
	push dword ptr [bp-0Ah]
	call RegDosFree
	cmp si,0401h
	jnz short rwcv_release_buffer
	mov si,0Eh
rwcv_release_buffer:
	mov ax,si
rwcv_done:
	pop si
	pop di
	leave
	ret 012h
RegWriteChainedValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Update the value within one key and release the modified data record.
	public RegWriteValueRecord
RegWriteValueRecord proc near
	enter 01Ah,0
	push di
	push si
	cmp dword ptr [bp+010h],0
	jnz short rwvr_find_value
	xor bx,bx
	jmp short rwvr_found_value
rwvr_find_value:
	les di,[bp+010h]
	mov cx,0FFFFh
	xor ax,ax
	repne scasb
	not cx
	dec cx
	mov bx,cx
rwvr_found_value:
	cmp bx,0FFh
	jna short rwvr_new_value
	mov ax,057h
	jmp near ptr rwvr_no_value
rwvr_new_value:
	mov [bp-0Eh],bx
	mov ax,bx
	add ax,[bp+6]
	add ax,0Ch
	mov [bp-0Ch],ax
	cmp word ptr [bp+4],0
	jnz short rwvr_check_record
	push dword ptr [bp+014h]
	push dword ptr [bp+010h]
	lea ax,[bp-012h]
	push ss
	push ax
	lea ax,[bp-016h]
	push ss
	push ax
	call RegFindChainedValue
	mov [bp-0Ah],ax
	jmp short rwvr_check_type
rwvr_check_record:
	mov word ptr [bp-0Ah],03F4h
rwvr_check_type:
	cmp word ptr [bp-0Ah],0
	jnz near ptr rwvr_unlock_key
	les bx,[bp-016h]
	mov ax,es:[bx+8]
	add ax,es:[bx+0Ah]
	add ax,0Ch
	mov [bp-6],ax
	cmp ax,[bp-0Ch]
	jnz short rwvr_new_length
	mov ax,[bp+6]
	cmp es:[bx+0Ah],ax
	jnz short rwvr_new_length
	mov eax,[bp+0Ch]
	db 66h
	cmp es:[bx],ax
	jnz short rwvr_new_length
	mov si,[bp-0Eh]
	mov ax,[bp+8]
	mov dx,[bp+0Ah]
	mov cx,[bp+6]
	push ds
	mov di,ax
	lea si,[bx+si+0Ch]
	push es
	pop ds
	mov es,dx
	shr cx,1
	sbb ax,ax
	cmp cx,cx
	repe cmpsw
	jnz short rwvr_old_length
	sub cx,ax
	repe cmpsb
rwvr_old_length:
	pop ds
	jnz short rwvr_new_length
	les bx,[bp+014h]
	db 66h
	push word ptr es:[bx+6]
	push word ptr es:[bx+014h]
	push 0
	call RegUnlockDataCache
	xor ax,ax
	jmp near ptr rwvr_no_value
rwvr_new_length:
	mov si,[bp-0Ch]
	cmp [bp-6],si
	jna short rwvr_ensure_space
	mov ax,[bp-6]
	sub ax,si
	sub dx,dx
	les bx,[bp-012h]
	sub es:[bx+8],ax
	sbb es:[bx+0Ah],dx
	jmp short rwvr_empty_slot
rwvr_ensure_space:
	cmp [bp-6],si
	jnc short rwvr_empty_slot
	les bx,[bp-012h]
	mov ax,es:[bx]
	sub ax,es:[bx+8]
	mov cx,si
	sub cx,[bp-6]
	mov [bp-2],cx
	cmp ax,cx
	jnc short rwvr_shift_data
	mov ax,[bp-016h]
	sub ax,bx
	mov [bp-8],ax
	push dword ptr [bp+014h]
	mov ax,cx
	sub dx,dx
	add ax,es:[bx+8]
	adc dx,es:[bx+0Ah]
	push dx
	push ax
	lea ax,[bp-012h]
	push ss
	push ax
	call RegResizeValueRecord
	mov [bp-0Ah],ax
	or ax,ax
	jz short rwvr_unlock_error
	les bx,[bp+014h]
	db 66h
	push word ptr es:[bx+6]
	push word ptr es:[bx+014h]
	push 0
	call RegUnlockDataCache
	mov ax,[bp-0Ah]
	jmp near ptr rwvr_no_value
rwvr_unlock_error:
	mov eax,[bp-012h]
	add ax,[bp-8]
	mov [bp-016h],eax
rwvr_shift_data:
	mov ax,[bp-2]
	sub dx,dx
	les bx,[bp-012h]
	add es:[bx+8],ax
	adc es:[bx+0Ah],dx
rwvr_empty_slot:
	mov eax,[bp-016h]
	mov dx,[bp-014h]
	add ax,si
	mov [bp-4],eax
	les bx,[bp-012h]
	sub ax,es:[bx+8]
	neg ax
	add ax,bx
	mov [bp-8],ax
	or ax,ax
	jz short rwvr_allocate_block
	push dx
	push word ptr [bp-4]
	mov ax,[bp-016h]
	add ax,[bp-6]
	push dx
	push ax
	push word ptr [bp-8]
	call RegMoveMemory
rwvr_allocate_block:
	mov di,[bp+014h]
	mov si,[bp-0Ah]
	jmp near ptr rwvr_complete
rwvr_unlock_key:
	mov si,[bp-0Ah]
	cmp si,03F4h
	jnz short rwvr_set_record
	les bx,[bp+014h]
	cmp word ptr es:[bx+012h],-1
	jnz near ptr rwvr_copy_name
	db 66h
	push word ptr es:[bx+6]
	db 66h
	push word ptr es:[bx+0Ah]
	lea ax,[bp-01Ah]
	push ss
	push ax
	call RegFetchKeyRecord
	or ax,ax
	jnz short rwvr_use_record
	les bx,[bp+014h]
	db 66h
	push word ptr es:[bx+6]
	mov ax,[bp-0Ch]
	add ax,015h
	push ax
	lea ax,[bp-012h]
	push ss
	push ax
	call RegAllocateDataRecord
	or ax,ax
	jz short rwvr_unlock_new
	les bx,[bp+014h]
	db 66h
	push word ptr es:[bx+6]
	db 66h
	push word ptr es:[bx+0Ah]
	push 0
	call RegUnlockKeyCache
rwvr_use_record:
	mov ax,03F3h
	jmp near ptr rwvr_no_value
rwvr_set_record:
	mov di,[bp+014h]
	jmp near ptr rwvr_complete
rwvr_unlock_new:
	les bx,[bp-012h]
	db 66h
	mov word ptr es:[bx+8],015h
	dw 0
	les bx,[bp-012h]
	mov word ptr es:[bx+0Ch],1
	les bx,[bp-012h]
	mov byte ptr es:[bx+014h],0
	les bx,[bp-012h]
	mov word ptr es:[bx+0Eh],0
	les bx,[bp-012h]
	mov word ptr es:[bx+010h],0
	les bx,[bp-012h]
	mov word ptr es:[bx+012h],0
	les bx,[bp-012h]
	mov ax,es:[bx+6]
	les bx,[bp-01Ah]
	mov es:[bx+0Ch],ax
	les bx,[bp-012h]
	sub al,al
	mov ah,es:[bx+4]
	mov dx,ax
	sub cx,cx
	les bx,[bp-01Ah]
	mov si,cx
	mov di,ax
	xor cx,es:[bx+8]
	xor dx,es:[bx+0Ah]
	and dh,al
	xor si,cx
	xor di,dx
	mov es:[bx+8],si
	mov es:[bx+0Ah],di
	les bx,[bp-01Ah]
	mov ax,es:[bx+0Ch]
	les bx,[bp+014h]
	mov es:[bx+012h],ax
	les bx,[bp-01Ah]
	mov al,es:[bx+0Bh]
	les bx,[bp+014h]
	mov es:[bx+016h],al
	db 66h
	push word ptr es:[bx+6]
	db 66h
	push word ptr es:[bx+0Ah]
	push 1
	call RegUnlockKeyCache
	xor si,si
	mov di,[bp+014h]
	jmp short rwvr_copy_data
rwvr_copy_name:
	mov di,bx
	db 66h
	push word ptr es:[di+6]
	push word ptr es:[di+012h]
	mov al,es:[di+016h]
	push ax
	lea ax,[bp-012h]
	push ss
	push ax
	call RegFetchDataRecord
	mov si,ax
	or si,ax
	jnz short rwvr_complete
	les bx,[bp-012h]
	mov ax,es:[bx]
	sub ax,es:[bx+8]
	cmp ax,[bp-0Ch]
	jnc short rwvr_copy_data
	push word ptr [bp+016h]
	push di
	mov ax,[bp-0Ch]
	sub dx,dx
	add ax,es:[bx+8]
	adc dx,es:[bx+0Ah]
	push dx
	push ax
	lea ax,[bp-012h]
	push ss
	push ax
	call RegResizeValueRecord
	mov si,ax
	or si,ax
	jz short rwvr_copy_data
	mov es,[bp+016h]
	db 66h
	push word ptr es:[di+6]
	push word ptr es:[di+012h]
	push 0
	jmp near ptr rwvr_done
rwvr_copy_data:
	mov es,[bp+016h]
	mov ax,es:[di+012h]
	mov es:[di+014h],ax
	les bx,[bp-012h]
	add bx,es:[bx+8]
	mov [bp-016h],bx
	mov word ptr [bp-014h],es
	mov ax,[bp-0Ch]
	sub dx,dx
	mov bx,[bp-012h]
	add es:[bx+8],ax
	adc es:[bx+0Ah],dx
	les bx,[bp-012h]
	inc word ptr es:[bx+0Eh]
rwvr_complete:
	or si,si
	jnz short rwvr_result
	mov eax,[bp+0Ch]
	les bx,[bp-016h]
	db 66h
	mov es:[bx],ax
	mov ax,[bp-0Eh]
	les bx,[bp-016h]
	mov es:[bx+8],ax
	mov ecx,[bp-016h]
	add cx,0Ch
	push ecx
	push dword ptr [bp+010h]
	push ax
	call RegMoveMemory
	mov ax,[bp+6]
	les bx,[bp-016h]
	mov es:[bx+0Ah],ax
	mov ecx,[bp-016h]
	add cx,[bp-0Eh]
	add cx,0Ch
	push ecx
	push dword ptr [bp+8]
	push ax
	call RegMoveMemory
	mov es,[bp+016h]
	db 66h
	push word ptr es:[di+6]
	push word ptr es:[di+014h]
	push 1
rwvr_done:
	call RegUnlockDataCache
rwvr_result:
	mov ax,si
rwvr_no_value:
	pop si
	pop di
	leave
	ret 014h
RegWriteValueRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Validate the public value arguments and write through the existing key handle.
	public RegSetValueCore
RegSetValueCore proc far
	mov ax,DGROUP
	enter 2,0
	push di
	push ds
	mov ds,ax
	cmp dword ptr [bp+012h],1
	jnz short rsvc_check_size
	les di,[bp+016h]
	mov cx,0FFFFh
	xor ax,ax
	repne scasb
	not cx
	dec cx
	mov [bp+01Ah],cx
	mov [bp+01Ch],ax
	cmp cx,04000h
	jc short rsvc_check_size
rsvc_invalid:
	mov ax,057h
	jmp short rsvc_done
rsvc_check_size:
	cmp dword ptr [bp+01Ah],04000h
	ja short rsvc_invalid
	lea ax,[bp+6]
	push ss
	push ax
	call RegValidateKeyHandle
	mov [bp-2],ax
	or ax,ax
	jnz short rsvc_result
	les bx,[bp+6]
	les bx,es:[bx+6]
	test byte ptr es:[bx+056h],080h
	jz short rsvc_write
	mov word ptr [bp-2],5
	jmp short rsvc_result
rsvc_write:
	push dword ptr [bp+6]
	push dword ptr [bp+0Ah]
	push dword ptr [bp+012h]
	push dword ptr [bp+016h]
	push word ptr [bp+01Ah]
	call RegWriteChainedValue
	mov [bp-2],ax
rsvc_result:
	mov ax,[bp-2]
rsvc_done:
	cwd
	pop ds
	pop di
	leave
	retf
RegSetValueCore endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Search the current key and, for a chained key, its linked records.
	public RegFindChainedValue
RegFindChainedValue proc near
	enter 10h,0
	push di
	push si
	mov si,[bp+010h]
	mov es,[bp+012h]
	mov ax,es:[si+012h]
	mov es:[si+014h],ax
	push es
	push si
	push dword ptr [bp+0Ch]
	push dword ptr [bp+8]
	push dword ptr [bp+4]
	call RegFindValue
	mov di,ax
	mov [bp-4],ax
	cmp di,03F4h
	jnz short rcv_return_search
	mov es,[bp+012h]
	test byte ptr es:[si+3],1
	jz short rcv_return_search
	push 0100h
	call RegAllocate
	mov di,ax
	mov [bp-6],dx
	or dx,ax
	jnz short rcv_start
	mov ax,0Eh
	jmp near ptr rcv_done
rcv_return_search:
	mov si,ax
	jmp near ptr rcv_result
rcv_start:
	mov word ptr [bp-2],0
	mov si,[bp+010h]
	mov [bp-8],ax
rcv_enumerate:
	mov dword ptr [bp-010h],0100h
	push word ptr [bp+012h]
	push si
	push word ptr [bp-2]
	inc word ptr [bp-2]
	push word ptr [bp-6]
	push di
	lea ax,[bp-010h]
	push ss
	push ax
	push 4
	call RegEnumValueRecord
	or ax,ax
	jnz short rcv_missing
	push word ptr [bp+012h]
	push si
	push word ptr [bp-6]
	push di
	lea ax,[bp-0Ch]
	push ss
	push ax
	push 4
	call RegOpenPath
	or ax,ax
	jnz short rcv_missing
	les bx,[bp-0Ch]
	mov ax,es:[bx+012h]
	mov es,[bp+012h]
	mov es:[si+014h],ax
	push dword ptr [bp-0Ch]
	push dword ptr [bp+0Ch]
	push dword ptr [bp+8]
	push dword ptr [bp+4]
	call RegFindValue
	mov [bp-4],ax
	push dword ptr [bp-0Ch]
	call RegReleaseKeyHandle
	cmp word ptr [bp-4],03F4h
	jz short rcv_enumerate
	mov si,[bp-4]
	jmp short rcv_free
rcv_missing:
	mov si,03F4h
rcv_free:
	push word ptr [bp-6]
	push di
	call RegDosFree
rcv_result:
	mov ax,si
rcv_done:
	pop si
	pop di
	leave
	ret 10h
RegFindChainedValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFindValue
RegFindValue proc near
	enter 0Ch,0
	push di
	push si
	les bx,[bp+10h]
	cmp word ptr es:[bx+12h],-1
	jnz short rfvt_load
	mov ax,3F4h
	jmp rfvt_done
rfvt_load:
	db 66h
	push word ptr es:[bx+6]
	push word ptr es:[bx+12h]
	mov al,es:[bx+16h]
	push ax
	lea ax,[bp-0Ch]
	push ss
	push ax
	call RegFetchDataRecord
	mov si,ax
	or si,ax
	jnz rfvt_error
	cmp dword ptr [bp+0Ch],0
	jnz short rfvt_length
	xor si,si
	jmp short rfvt_values
rfvt_length:
	les di,[bp+0Ch]
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	dec cx
	mov si,cx
rfvt_values:
	les bx,[bp-0Ch]
	mov ax,es:[bx+0Ch]
	add ax,es:[bx+10h]
	add ax,bx
	add ax,14h
	mov cx,ax
	mov [bp-2],es
	mov ax,es:[bx+0Eh]
	mov [bp-8],ax
	or ax,ax
	jz short rfvt_missing
	mov [bp-4],cx
	mov [bp-6],si
	mov si,cx
	mov di,[bp-6]
rfvt_next:
	cmp es:[si+8],di
	jnz short rfvt_advance
	or di,di
	jz short rfvt_found
	push dword ptr [bp+0Ch]
	lea ax,[si+0Ch]
	push es
	push ax
	push di
	call RegCompareName
	or ax,ax
	jz short rfvt_found
rfvt_advance:
	mov es,word ptr [bp-2]
	mov ax,es:[si+8]
	add ax,es:[si+0Ah]
	add ax,0Ch
	add si,ax
	dec word ptr [bp-8]
	jnz short rfvt_next
	jmp short rfvt_missing
rfvt_found:
	mov eax,[bp-0Ch]
	les bx,[bp+8]
	db 66h
	mov es:[bx],ax
	les bx,[bp+4]
	mov ax,[bp-2]
	mov es:[bx],si
	mov es:[bx+2],ax
	xor ax,ax
	jmp short rfvt_done
rfvt_missing:
	les bx,[bp+10h]
	db 66h
	push word ptr es:[bx+6]
	push word ptr es:[bx+12h]
	push 0
	call RegUnlockDataCache
	mov si,3F4h
rfvt_error:
	mov ax,si
rfvt_done:
	pop si
	pop di
	leave
	ret 10h
RegFindValue endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegQueryValueCore
RegQueryValueCore proc near
	enter 2,0
	push di
	push si
	mov bx,[bp+0Ch]
	mov di,[bp+18h]
	mov ax,[bp+0Eh]
	or ax,bx
	jz short rcvt_type_done
	mov es,word ptr [bp+1Ah]
	db 66h
	mov ax,es:[di]
	mov es,word ptr [bp+0Eh]
	db 66h
	mov es:[bx],ax
rcvt_type_done:
	mov es,word ptr [bp+1Ah]
	mov si,es:[di+0Ah]
	db 66h
	cmp word ptr es:[di],1
	jnz short rcvt_length
	inc si
rcvt_length:
	cmp dword ptr [bp+8],0
	jz short rcvt_size
	sub ax,ax
	les bx,[bp+4]
	cmp es:[bx+2],ax
	ja short rcvt_copy
	jb short rcvt_small
	cmp es:[bx],si
	jae short rcvt_copy
rcvt_small:
	mov es:[bx],si
	mov es:[bx+2],ax
rcvt_more_data:
	mov ax,0EAh
	jmp rcvt_done
rcvt_copy:
	push dword ptr [bp+8]
	mov es,word ptr [bp+1Ah]
	mov ax,es:[di+8]
	add ax,di
	add ax,0Ch
	push es
	push ax
	push word ptr es:[di+0Ah]
	call RegMoveMemory
	mov es,word ptr [bp+1Ah]
	db 66h
	cmp word ptr es:[di],1
	jnz short rcvt_size
	mov bx,es:[di+0Ah]
	add bx,[bp+8]
	mov es,word ptr [bp+0Ah]
	mov byte ptr es:[bx],0
rcvt_size:
	cmp dword ptr [bp+4],0
	jz short rcvt_name
	les bx,[bp+4]
	mov es:[bx],si
	mov word ptr es:[bx+2],0
rcvt_name:
	cmp dword ptr [bp+14h],0
	jz short rcvt_success
	mov word ptr [bp-2],0
	mov cx,[bp+10h]
	mov bx,cx
	mov es,word ptr [bp+12h]
	mov ax,es
	mov es,word ptr [bp+1Ah]
	mov dx,es:[di+8]
	sub si,si
	mov es,ax
	cmp si,es:[bx+2]
	jb short rcvt_name_fits
	ja short rcvt_name_small
	cmp dx,es:[bx]
	jb short rcvt_name_fits
rcvt_name_small:
	mov word ptr [bp-2],0EAh
	db 66h
	cmp word ptr es:[bx],0
	jz rcvt_more_data
	mov si,es:[bx]
	dec si
	jmp short rcvt_name_copy
rcvt_name_fits:
	les bx,[bp+18h]
	mov si,es:[bx+8]
rcvt_name_copy:
	push dword ptr [bp+14h]
	mov eax,[bp+18h]
	add ax,0Ch
	push eax
	push si
	call RegMoveMemory
	les bx,[bp+14h]
	mov byte ptr es:[bx+si],0
	les bx,[bp+10h]
	mov es:[bx],si
	mov word ptr es:[bx+2],0
	mov ax,[bp-2]
	jmp short rcvt_done
rcvt_success:
	xor ax,ax
rcvt_done:
	pop si
	pop di
	leave
	ret 1Ch
RegQueryValueCore endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegQueryValueEx
RegQueryValueEx proc far
	mov ax,DGROUP
	enter 0Ah,0
	push di
	push si
	push ds
	mov ds,ax
	mov si,[bp+12h]
	mov ax,[bp+14h]
	or ax,si
	jz short rqvt_check_buffer
	mov es,[bp+14h]
	db 66h
	mov word ptr es:[si],0
	dw 0
rqvt_check_buffer:
	mov di,[bp+1Ah]
	mov ax,[bp+1Ch]
	or ax,di
	jnz short rqvt_validate
	cmp dword ptr [bp+16h],0
	jz short rqvt_validate
	mov ax,57h
	jmp rqvt_exit
rqvt_validate:
	lea ax,[bp+6]
	push ss
	push ax
	call RegValidateKeyHandle
	mov [bp-2],ax
	or ax,ax
	jnz rqvt_result
	push dword ptr [bp+6]
	push dword ptr [bp+0Ah]
	lea ax,[bp-0Ah]
	push ss
	push ax
	lea ax,[bp-6]
	push ss
	push ax
	call RegFindChainedValue
	mov [bp-2],ax
	or ax,ax
	jnz short rqvt_missing
	push dword ptr [bp+6]
	push dword ptr [bp-6]
	push ax
	push ax
	push ax
	push ax
	push word ptr [bp+14h]
	push si
	push dword ptr [bp+16h]
	push word ptr [bp+1Ch]
	push di
	call RegQueryValueCore
	mov [bp-2],ax
	les bx,[bp+6]
	db 66h
	push word ptr es:[bx+6]
	push word ptr es:[bx+14h]
	push 0
	call RegUnlockDataCache
	jmp short rqvt_result
rqvt_missing:
	cmp ax,3F4h
	jnz short rqvt_result
	mov ecx,[bp+0Ah]
	or ecx,ecx
	jz short rqvt_default
	mov es,word ptr [bp+0Ch]
	mov bx,cx
	cmp byte ptr es:[bx],0
	jnz short rqvt_result
rqvt_default:
	mov ax,[bp+14h]
	or ax,si
	jz short rqvt_buffer
	mov es,[bp+14h]
	db 66h
	mov word ptr es:[si],1
	dw 0
rqvt_buffer:
	cmp dword ptr [bp+16h],0
	jz short rqvt_set_length
	mov es,word ptr [bp+1Ch]
	db 66h
	cmp word ptr es:[di],0
	jz short rqvt_set_length
	les bx,[bp+16h]
	mov byte ptr es:[bx],0
rqvt_set_length:
	mov ax,[bp+1Ch]
	or ax,di
	jz short rqvt_ok
	mov es,word ptr [bp+1Ch]
	db 66h
	mov word ptr es:[di],1
	dw 0
rqvt_ok:
	mov word ptr [bp-2],0
rqvt_result:
	mov ax,[bp-2]
rqvt_exit:
	cwd
	pop ds
	pop si
	pop di
	leave
	retf
RegQueryValueEx endp
	if ($ - RegistryCode) and 1
	db 0
	endif

REGTEXT ends
	end
