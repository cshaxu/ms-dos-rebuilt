;** REGOPEN - Registry paths and values
;
; FAR C entries call the key cache and record services through near entries.
; Path and value-name operations use the shared registry state in DGROUP.
;
	.386
_DATA segment word public use16 'DATA'
	extrn RegPathCursor:dword
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'CODE'
_TEXT ends
REGTEXT segment word public use16 'CODE'
CGROUP group _TEXT,REGTEXT
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
	enter 2Ch,0
	push di
	push si
	mov cx,[bp+0Ah]
	mov word ptr [bp-14h],0
	mov ax,[bp+0Ch]
	or ax,cx
	jz short ropt_empty
	mov ax,[bp+0Ch]
	push ax
	push cx
	lea ax,[bp-28h]
	push ss
	push ax
	lea ax,[bp-10h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jnz short ropt_start
ropt_empty:
	jmp ropt_parent
ropt_start:
	mov bx,[bp+0Eh]
	mov es,word ptr [bp+10h]
	db 66h
	mov ax,es:[bx+6]
	mov [bp-8],eax
	db 66h
	mov ax,es:[bx+0Eh]
	mov [bp-18h],eax
	db 66h
	mov ax,es:[bx+0Ah]
	mov [bp-0Ch],eax
	mov word ptr [bp-12h],0
ropt_component:
	push dword ptr [bp-28h]
	push word ptr [bp-10h]
	call RegNameChecksum
	mov [bp-4],ax
	mov [bp-2],dx
	cmp dword ptr [bp-18h],0FFFFFFh
	jae near ptr ropt_nochild
	mov si,[bp-8]
ropt_find:
	push word ptr [bp-6]
	push si
	push dword ptr [bp-18h]
	lea ax,[bp-1Ch]
	push ss
	push ax
	call RegFetchKeyRecord
	mov [bp-0Eh],ax
	or ax,ax
	jnz ropt_result
	les bx,[bp-1Ch]
	sub dx,dx
	mov ax,es:[bx+0Eh]
	cmp ax,[bp-4]
	jnz near ptr ropt_next
	cmp dx,[bp-2]
	jnz near ptr ropt_next
	push word ptr [bp-6]
	push si
	push word ptr es:[bx+0Ch]
	mov al,es:[bx+0Bh]
	sub ah,ah
	push ax
	lea ax,[bp-20h]
	push ss
	push ax
	call RegFetchDataRecord
	mov [bp-0Eh],ax
	or ax,ax
	jnz ropt_data_error
	les bx,[bp-1Ch]
	test word ptr es:[bx+2],400h
	jnz short ropt_ordinary_key
	xor ax,ax
	jmp short ropt_key_class
ropt_ordinary_key:
	mov ax,4
ropt_key_class:
	mov cx,[bp+4]
	and cx,4
	cmp ax,cx
	jne short ropt_nomatch
	mov ax,[bp-10h]
	les bx,[bp-20h]
	cmp es:[bx+0Ch],ax
	jnz short ropt_nomatch
	push dword ptr [bp-28h]
	lea ax,[bx+14h]
	push es
	push ax
	push word ptr [bp-10h]
	call RegCompareName
	or ax,ax
	jnz short ropt_nomatch
	mov di,1
	jmp short ropt_release_data
ropt_nochild:
	mov si,[bp-8]
	jmp short ropt_found
ropt_nomatch:
	xor di,di
ropt_release_data:
	push word ptr [bp-6]
	push si
	les bx,[bp-1Ch]
	push word ptr es:[bx+0Ch]
	push 0
	call RegUnlockDataCache
	or di,di
	jnz short ropt_found
ropt_next:
	mov word ptr [bp-12h],1
	mov eax,[bp-18h]
	mov [bp-0Ch],eax
	les bx,[bp-1Ch]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	sub dh,dh
	mov [bp-18h],ax
	mov [bp-16h],dx
	push word ptr [bp-6]
	push si
	push dword ptr [bp-0Ch]
	push 0
	call RegUnlockKeyCache
	cmp dword ptr [bp-18h],0FFFFFFh
	jb ropt_find
ropt_found:
	cmp dword ptr [bp-18h],0FFFFFFh
	jae short ropt_create_check
	push 0
	push 0
	lea ax,[bp-28h]
	push ss
	push ax
	lea ax,[bp-10h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jz short ropt_create_check
	mov eax,[bp-18h]
	mov [bp-0Ch],eax
	les bx,[bp-1Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	sub dh,dh
	mov [bp-18h],ax
	mov [bp-16h],dx
	push word ptr [bp-6]
	push si
	push dword ptr [bp-0Ch]
	xor ax,ax
	mov [bp-12h],ax
	push ax
	call RegUnlockKeyCache
	jmp ropt_component
ropt_data_error:
	push word ptr [bp-6]
	push si
	push dword ptr [bp-18h]
	push 0
ropt_data_error_release:
	call RegUnlockKeyCache
	jmp ropt_result
ropt_create_check:
	cmp dword ptr [bp-18h],0FFFFFFh
	jb ropt_finish_key
	mov bx,[bp+4]
	test bl,1
	jnz short ropt_permission
	mov ax,3F3h
	jmp ropt_exit
ropt_permission:
	les di,[bp+0Eh]
	cmp byte ptr es:[di+17h],6
	jnz short ropt_readonly
	test bl,2
	jz short ropt_denied
ropt_readonly:
	mov es,word ptr [bp-6]
	test byte ptr es:[si+56h],80h
	jz short ropt_parent_record
ropt_denied:
	jmp ropt_access_denied
ropt_parent_record:
	push es
	push si
	push dword ptr [bp-0Ch]
	lea ax,[bp-1Ch]
	push ss
	push ax
	call RegFetchKeyRecord
	mov di,ax
	or di,ax
	jnz ropt_exit
	push word ptr [bp-6]
	push si
	push dword ptr [bp-0Ch]
	call RegLookupKeyHandle
	mov [bp-4],ax
	mov [bp-2],dx
ropt_create:
	push word ptr [bp-6]
	push si
	lea ax,[bp-18h]
	push ss
	push ax
	lea ax,[bp-24h]
	push ss
	push ax
	call RegAllocateKeyRecord
	mov di,ax
	or di,ax
	jnz ropt_alloc_error
	push word ptr [bp-6]
	push si
	mov ax,[bp-10h]
	add ax,14h
	push ax
	lea ax,[bp-20h]
	push ss
	push ax
	call RegAllocateDataRecord
	mov [bp-0Eh],ax
	or ax,ax
	jnz ropt_free_new
	cmp [bp-12h],ax
	jz short ropt_first_child
	mov [bp-12h],ax
	cwd
	mov di,ax
	mov [bp-2],dx
	les bx,[bp-24h]
	mov ax,es:[bx+8]
	mov dx,es:[bx+0Ah]
	les bx,[bp-1Ch]
	xor ax,es:[bx+8]
	xor dx,es:[bx+0Ah]
	sub dh,dh
	les bx,[bp-24h]
	xor es:[bx+8],ax
	xor es:[bx+0Ah],dx
	les bx,[bp-1Ch]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	xor ax,[bp-18h]
	xor dx,[bp-16h]
	sub dh,dh
	xor es:[bx],ax
	xor es:[bx+2],dx
	jmp short ropt_linked
ropt_first_child:
	les bx,[bp-24h]
	mov ax,es:[bx+8]
	mov dx,es:[bx+0Ah]
	xor ax,[bp-0Ch]
	xor dx,[bp-0Ah]
	sub dh,dh
	xor es:[bx+8],ax
	xor es:[bx+0Ah],dx
	les bx,[bp-1Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	xor ax,[bp-18h]
	xor dx,[bp-16h]
	sub dh,dh
	xor es:[bx+4],ax
	xor es:[bx+6],dx
	mov di,[bp-4]
	mov ax,[bp-2]
	or ax,di
	jz short ropt_linked
	mov es,word ptr [bp-2]
	db 66h,26h,81h,7Dh,0Eh
	dd 0FFFFFFh
	jb short ropt_clear_handle
	mov eax,[bp-18h]
	db 66h
	mov es:[di+0Eh],ax
ropt_clear_handle:
	xor ax,ax
	cwd
	mov di,ax
	mov [bp-2],dx
ropt_linked:
	les bx,[bp-24h]
	db 66h,26h,81h,0Fh
	dd 0FFFFFFh
	les bx,[bp-24h]
	db 66h,26h,81h,4Fh,04h
	dd 0FFFFFFh
	les bx,[bp-20h]
	mov ax,es:[bx+6]
	les bx,[bp-24h]
	mov es:[bx+0Ch],ax
	les bx,[bp-20h]
	sub al,al
	mov ah,es:[bx+4]
	mov dx,ax
	sub cx,cx
	les bx,[bp-24h]
	mov [bp-2Ch],cx
	mov [bp-2Ah],ax
	xor cx,es:[bx+8]
	xor dx,es:[bx+0Ah]
	and dh,al
	xor cx,[bp-2Ch]
	xor dx,ax
	mov es:[bx+8],cx
	mov es:[bx+0Ah],dx
	push dword ptr [bp-28h]
	push word ptr [bp-10h]
	call RegNameChecksum
	les bx,[bp-24h]
	mov es:[bx+0Eh],ax
	mov ax,[bp-10h]
	add ax,14h
	les bx,[bp-20h]
	mov es:[bx+8],ax
	mov word ptr es:[bx+0Ah],0
	mov ax,[bp-10h]
	les bx,[bp-20h]
	mov es:[bx+0Ch],ax
	mov eax,[bp-20h]
	add ax,14h
	push eax
	push dword ptr [bp-28h]
	push word ptr [bp-10h]
	call RegMoveMemory
	les bx,[bp-20h]
	mov word ptr es:[bx+0Eh],0
	les bx,[bp-20h]
	mov word ptr es:[bx+10h],0
	les bx,[bp-20h]
	mov word ptr es:[bx+12h],0
	push word ptr [bp-6]
	push si
	push dword ptr [bp-0Ch]
	push 1
	call RegUnlockKeyCache
	mov eax,[bp-18h]
	mov [bp-0Ch],eax
	mov eax,[bp-24h]
	mov [bp-1Ch],eax
	push word ptr [bp-6]
	push si
	les bx,[bp-20h]
	push word ptr es:[bx+6]
	push 1
	call RegUnlockDataCache
	mov word ptr [bp-14h],1
	mov [bp-4],di
	push 0
	push 0
	lea ax,[bp-28h]
	push ss
	push ax
	lea ax,[bp-10h]
	push ss
	push ax
	call RegPathPart
	or ax,ax
	jnz ropt_create
ropt_finish_key:
	push dword ptr [bp-8]
	push dword ptr [bp-18h]
	call RegLookupKeyHandle
	mov di,ax
	mov [bp-2],dx
	or dx,ax
	jnz ropt_release_key
	call RegAcquireKeyHandle
	mov di,ax
	mov [bp-2],dx
	or dx,ax
	jnz short ropt_init_handle
	mov word ptr [bp-0Eh],0Eh
	jmp ropt_release_key
ropt_free_new:
	push word ptr [bp-6]
	push si
	push dword ptr [bp-18h]
	push 0
	call RegUnlockKeyCache
	push word ptr [bp-6]
	push si
	push dword ptr [bp-18h]
	call RegFreeKeyRecord
ropt_release_parent:
	push word ptr [bp-6]
	push si
	push dword ptr [bp-0Ch]
	push word ptr [bp-14h]
	jmp ropt_data_error_release
ropt_alloc_error:
	mov [bp-0Eh],di
	jmp short ropt_release_parent
ropt_access_denied:
	mov ax,5
	jmp ropt_exit
ropt_init_handle:
	mov eax,[bp-8]
	mov es,word ptr [bp-2]
	db 66h
	mov es:[di+6],ax
	mov eax,[bp-18h]
	db 66h
	mov es:[di+0Ah],ax
	les bx,[bp-1Ch]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	sub dh,dh
	mov es,word ptr [bp-2]
	mov es:[di+0Eh],ax
	mov es:[di+10h],dx
	les bx,[bp-1Ch]
	mov ax,es:[bx+0Ch]
	mov es,word ptr [bp-2]
	mov es:[di+12h],ax
	les bx,[bp-1Ch]
	mov al,es:[bx+0Bh]
	mov es,word ptr [bp-2]
	mov es:[di+16h],al
	les bx,[bp+0Eh]
	mov al,es:[bx+17h]
	mov es,word ptr [bp-2]
	mov es:[di+17h],al
	les bx,[bp-1Ch]
	test word ptr es:[bx+2],200h
	jz short ropt_release_key
	mov es,[bp-2]
	or byte ptr es:[di+3],1
ropt_release_key:
	push dword ptr [bp-8]
	push dword ptr [bp-18h]
	push word ptr [bp-14h]
	call RegUnlockKeyCache
	mov ax,[bp-2]
	or ax,di
	jz short ropt_result
	mov [bp-4],di
	mov si,di
	jmp short ropt_retain
ropt_parent:
	mov ax,[bp+0Eh]
	mov dx,[bp+10h]
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
	mov word ptr [bp-0Eh],0
ropt_result:
	mov ax,[bp-0Eh]
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
	mov di,[bp+1Ah]
	mov si,[bp+16h]
	mov ax,[bp+1Ch]
	or ax,di
	jnz short rqvt_validate
	mov ax,[bp+18h]
	or ax,si
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
	push dword ptr [bp+12h]
	push word ptr [bp+18h]
	push si
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
	cmp dword ptr [bp+12h],0
	jz short rqvt_buffer
	les bx,[bp+12h]
	db 66h
	mov word ptr es:[bx],1
	dw 0
rqvt_buffer:
	mov ax,[bp+18h]
	or ax,si
	jz short rqvt_set_length
	mov es,word ptr [bp+1Ch]
	db 66h
	cmp word ptr es:[di],0
	jz short rqvt_set_length
	mov es,word ptr [bp+18h]
	mov byte ptr es:[si],0
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
