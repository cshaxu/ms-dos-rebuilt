;** REGSTART - Registry root initialization and lifetime
;
; FAR C entries initialize predefined roots and release their storage.
; Local registry files share the key pool and transfer buffer.
;
	.386
_DATA segment word public use16 'DATA'
	extrn RegTransferBuffer:dword
	extrn RegActiveFiles:dword
	extrn RegCurrentDirectory:byte
	extrn RegMachineRoot:byte
	extrn RegUserRoot:byte
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'CODE'
_TEXT ends
REGTEXT segment word public use16 'CODE'
CGROUP group _TEXT,REGTEXT
	assume cs:CGROUP,ds:DGROUP
	extrn RegDosCreate:near
	extrn RegDosOpen:near
	extrn RegDosWrite:near
	extrn RegDosRead:near
	extrn RegDosClose:near
	extrn RegZeroMemory:near
	extrn RegDosFree:near
	extrn RegDosGetAttr:near
	extrn RegDosSetAttr:near
	extrn RegDosDelete:near
	extrn RegDosRename:near
	extrn RegDosTempFile:near
RegistryCode label byte
	extrn RegAllocate:near
	extrn RegInitKeyPool:near
	extrn RegFreeKeyPool:near
	extrn RegValidateKeyHandle:near
	extrn RegInvalidateKeyHandles:near
	extrn RegFetchKeyRecord:near
	extrn RegUnlockKeyCache:near
	extrn RegAllocateKeyRecord:near
	extrn RegWriteKeyBlocks:near
	extrn RegCommitKeyCache:near
	extrn RegTrimKeyCache:near
	extrn RegInitKeyCache:near
	extrn RegFreeDataBlock:near
	extrn RegWriteDataBlock:near
	extrn RegCommitDataCache:near
	extrn RegScanDataBlocks:near
	extrn RegInitDataCache:near
	extrn RegChecksum:near
	public RegInitialize
RegInitialize proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push ds
	mov ds,ax
	push 7000h
	call RegAllocate
	mov word ptr RegTransferBuffer,ax
	mov word ptr RegTransferBuffer+2,dx
	mov ax,dx
	or ax,word ptr RegTransferBuffer
	jz short rit_error
	call RegInitKeyPool
	or ax,ax
	jz short rit_error
	xor ax,ax
	jmp short rit_done
rit_error:
	call far ptr RegTerminate
	mov ax,0Eh
rit_done:
	xor dx,dx
	pop ds
	leave
	retf
RegInitialize endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCloseRoot
RegCloseRoot proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	test byte ptr es:[si+2],4
	jnz short rcrt_done
	db 66h
	push word ptr es:[si+6]
	call RegReleaseFileBuffers
	mov es,word ptr [bp+6]
	or byte ptr es:[si+2],4
rcrt_done:
	pop si
	leave
	ret 4
RegCloseRoot endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegTerminate
RegTerminate proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push ds
	mov ds,ax
	push offset CGROUP:RegSaveFile
	call RegForEachFile
	push ds
	push offset DGROUP:RegMachineRoot
	call RegCloseRoot
	push ds
	push offset DGROUP:RegUserRoot
	call RegCloseRoot
	call RegFreeKeyPool
	cmp dword ptr RegTransferBuffer,0
	jz short rtt_done
	push RegTransferBuffer
	call RegDosFree
rtt_done:
	pop ds
	leave
	retf
RegTerminate endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCreateEmptyFile
RegCreateEmptyFile proc near
	enter 0Eh,0
	push di
	push si
	les di,[bp+6]
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	dec cx
	add cx,59h
	push cx
	call RegAllocate
	mov [bp-4],ax
	mov [bp-2],dx
	or dx,ax
	jnz short rcft_allocated
	mov si,0Eh
	jmp rcft_result
rcft_allocated:
	push word ptr [bp-2]
	push ax
	push 59h
	call RegZeroMemory
	mov bx,[bp-4]
	mov cx,[bp-2]
	add bx,58h
	push ds
	mov si,bx
	mov ds,cx
	les di,[bp+6]
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
	mov al,[bp+4]
	and ax,2
	mov [bp-0Eh],ax
	or ax,ax
	jnz short rcft_header
	push dword ptr [bp+6]
	call RegDosCreate
	mov si,ax
	cmp si,-1
	jnz short rcft_close
	mov si,3F8h
	jmp rcft_free
rcft_close:
	push si
	call RegDosClose
rcft_header:
	mov di,[bp+4]
	les bx,[bp-4]
	mov word ptr es:[bx+56h],3
	cmp word ptr [bp-0Eh],0
	jz short rcft_signature
	les bx,[bp-4]
	mov word ptr es:[bx+56h],43h
rcft_signature:
	les bx,[bp-4]
	db 66h
	mov word ptr es:[bx+16h],5243h
	dw 4745h
	test di,4
	jz short rcft_version1
	les bx,[bp-4]
	db 66h
	mov word ptr es:[bx+1Ah],0
	dw 2
	or byte ptr es:[bx+56h],8
	jmp short rcft_header_flags
rcft_version1:
	les bx,[bp-4]
	db 66h
	mov word ptr es:[bx+1Ah],0
	dw 1
rcft_header_flags:
	les bx,[bp-4]
	db 66h
	mov word ptr es:[bx+28h],1
	dw 0
	mov ax,di
	and ax,1
	cmp ax,1
	sbb ax,ax
	and al,81h
	add ax,80h
	mov es:[bx+2Ch],ax
	db 66h
	mov word ptr es:[bx+36h],4752h
	dw 4E4Bh
	mov eax,-1
	db 66h
	mov es:[bx+3Eh],ax
	mov es:[bx+42h],ax
	mov es:[bx+44h],ax
	db 66h
	mov word ptr es:[bx+46h],9
	dw 0
	push es
	push bx
	call RegInitKeyCache
	mov si,ax
	or si,ax
	jnz rcft_failure
	les bx,[bp-4]
	test byte ptr es:[bx+56h],8
	jnz short rcft_data
	db 66h
	mov word ptr es:[bx+0Ch],20h
	dw 0
rcft_data:
	push dword ptr [bp-4]
	push -1
	call RegInitDataCache
	mov si,ax
	or si,ax
	jnz rcft_failure
	push dword ptr [bp-4]
	lea ax,[bp-0Ch]
	push ss
	push ax
	lea ax,[bp-8]
	push ss
	push ax
	call RegAllocateKeyRecord
	mov si,ax
	or si,ax
	jnz short rcft_failure
	mov eax,[bp-0Ch]
	les bx,[bp-4]
	db 66h
	mov es:[bx+3Eh],ax
	les bx,[bp-8]
	db 66h,26h,81h,4Fh,08h
	dd 0FFFFFFh
	les bx,[bp-8]
	db 66h,26h,81h,0Fh
	dd 0FFFFFFh
	les bx,[bp-8]
	db 66h,26h,81h,4Fh,04h
	dd 0FFFFFFh
	les bx,[bp-8]
	mov word ptr es:[bx+0Eh],0
	les bx,[bp-8]
	mov word ptr es:[bx+0Ch],-1
	push dword ptr [bp-4]
	push dword ptr [bp-0Ch]
	push 1
	call RegUnlockKeyCache
	push dword ptr [bp-4]
	call RegSaveFile
	mov si,ax
	or si,ax
	jnz short rcft_failure
	mov eax,RegActiveFiles
	les bx,[bp-4]
	db 66h
	mov es:[bx],ax
	mov word ptr RegActiveFiles,bx
	mov word ptr RegActiveFiles+2,es
	les bx,[bp+0Ah]
	mov eax,[bp-4]
	db 66h
	mov es:[bx],ax
	xor ax,ax
	jmp short rcft_done
rcft_failure:
	cmp word ptr [bp-0Eh],0
	jnz short rcft_free
	push dword ptr [bp+6]
	call RegDosDelete
rcft_free:
	push dword ptr [bp-4]
	call RegReleaseFileBuffers
rcft_result:
	mov ax,si
rcft_done:
	pop si
	pop di
	leave
	ret 0Ah
RegCreateEmptyFile endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegReadFile
RegReadFile proc near
	enter 0Ah,0
	push di
	push si
	les di,[bp+4]
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	dec cx
	add cx,59h
	push cx
	call RegAllocate
	mov [bp-4],ax
	mov [bp-2],dx
	or dx,ax
	jnz short roft_allocated
	mov si,0Eh
	jmp roft_result
roft_allocated:
	push word ptr [bp-2]
	push ax
	push 59h
	call RegZeroMemory
	mov bx,[bp-4]
	mov cx,[bp-2]
	add bx,58h
	push ds
	mov si,bx
	mov ds,cx
	les di,[bp+4]
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
	mov word ptr [bp-6],3F8h
	push dword ptr [bp+4]
	push ax
	call RegDosOpen
	mov [bp-0Ah],ax
	inc ax
	jz short roft_open_error
	push word ptr [bp-0Ah]
	mov eax,[bp-4]
	add ax,16h
	push eax
	push 20h
	call RegDosRead
	or ax,ax
	jz short roft_read_error
	mov eax,[bp-4]
	add ax,16h
	push eax
	call RegValidateHeader
	or ax,ax
	jnz short roft_header
roft_invalid:
	mov si,3F1h
	jmp roft_close_error
roft_open_error:
	mov si,[bp-6]
	jmp roft_free
roft_header:
	les bx,[bp-4]
	and byte ptr es:[bx+28h],0FAh
	; CMP DWORD PTR ES:[BX+1Ah],00020000h, operand prefix first.
	db 66h,26h,81h,7Fh,1Ah
	dd 20000h
	jnz short roft_key_header
	les bx,[bp-4]
	or byte ptr es:[bx+56h],8
roft_key_header:
	push word ptr [bp-0Ah]
	mov eax,[bp-4]
	add ax,36h
	push eax
	push 20h
	call RegDosRead
	or ax,ax
	jz short roft_read_error
	les bx,[bp-4]
	; CMP DWORD PTR ES:[BX+36h],'RGKN', operand prefix first.
	db 66h,26h,81h,7Fh,36h
	dd 4E4B4752h
	jz short roft_caches
	jmp short roft_invalid
roft_read_error:
	mov si,[bp-6]
	jmp short roft_close_error
roft_caches:
	push es
	push bx
	call RegInitKeyCache
	mov si,ax
	or si,ax
	jnz short roft_close_error
	push dword ptr [bp-4]
	push word ptr [bp-0Ah]
	call RegInitDataCache
	mov si,ax
	or si,ax
	jnz short roft_close_error
	push word ptr [bp-0Ah]
	call RegDosClose
	push dword ptr [bp+4]
	call RegDosGetAttr
	cmp ax,-1
	jnz short roft_attributes
	cmp dx,ax
	jz short roft_link
roft_attributes:
	push dword ptr [bp+4]
	push ax
	call RegDosSetAttr
	or ax,ax
	jnz short roft_link
	les bx,[bp-4]
	or byte ptr es:[bx+56h],80h
roft_link:
	mov eax,RegActiveFiles
	les bx,[bp-4]
	db 66h
	mov es:[bx],ax
	mov word ptr RegActiveFiles,bx
	mov word ptr RegActiveFiles+2,es
	les bx,[bp+8]
	mov eax,[bp-4]
	db 66h
	mov es:[bx],ax
	xor ax,ax
	jmp short roft_done
roft_close_error:
	push word ptr [bp-0Ah]
	call RegDosClose
roft_free:
	push dword ptr [bp-4]
	call RegReleaseFileBuffers
roft_result:
	mov ax,si
roft_done:
	pop si
	pop di
	leave
	ret 8
RegReadFile endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegValidateHeader
RegValidateHeader proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	db 66h,26h,81h,3Ch
	dd 47455243h
	jnz short rcht_bad
	db 66h,26h,81h,7Ch,04h
	dd 10000h
	jz short rcht_checksum
	db 66h,26h,81h,7Ch,04h
	dd 20000h
	jnz short rcht_bad
rcht_checksum:
	test byte ptr es:[si+12h],4
	jz short rcht_valid
	push es
	push si
	push 20h
	call RegChecksum
	or dx,ax
	jnz short rcht_bad
rcht_valid:
	mov ax,1
	jmp short rcht_done
rcht_bad:
	xor ax,ax
rcht_done:
	pop si
	leave
	ret 4
RegValidateHeader endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegReleaseFileBuffers
RegReleaseFileBuffers proc near
	enter 8,0
	push di
	push si
	mov di,[bp+4]
	push word ptr [bp+6]
	push di
	push -1
	call RegInvalidateKeyHandles
	xor ax,ax
	cwd
	mov si,ax
	mov [bp-6],dx
	mov ecx,RegActiveFiles
	mov bx,word ptr RegActiveFiles+2
	mov [bp-4],ecx
	cmp cx,ax
	jnz short rfft_list
	cmp bx,dx
	jz short rfft_keys
rfft_list:
	mov bx,[bp-4]
	mov cx,si
rfft_next:
	mov ax,[bp-2]
	cmp bx,di
	jnz short rfft_advance
	cmp ax,[bp+6]
	jz short rfft_unlink
rfft_advance:
	mov cx,bx
	mov [bp-6],ax
	mov es,ax
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	mov bx,ax
	mov [bp-2],dx
	or dx,ax
	jnz short rfft_next
	jmp short rfft_keys
rfft_unlink:
	mov ax,[bp-6]
	or ax,cx
	jnz short rfft_link
	mov es,word ptr [bp-2]
	db 66h
	mov ax,es:[bx]
	mov RegActiveFiles,eax
	jmp short rfft_keys
rfft_link:
	mov es,word ptr [bp-2]
	db 66h
	mov ax,es:[bx]
	mov bx,cx
	mov es,word ptr [bp-6]
	db 66h
	mov es:[bx],ax
rfft_keys:
	mov es,word ptr [bp+6]
	db 66h
	cmp word ptr es:[di+4],0
	jz short rfft_data
	xor cx,cx
	mov ax,es:[di+4]
	mov dx,es:[di+6]
	mov si,ax
	mov [bp-4],dx
	cmp es:[di+8],cx
	jz short rfft_key_table
	mov [bp-2],cx
	mov di,cx
rfft_key_next:
	mov es,word ptr [bp-4]
	db 66h
	cmp word ptr es:[si],0
	jz short rfft_key_advance
	db 66h
	push word ptr es:[si]
	call RegDosFree
rfft_key_advance:
	add si,6
	inc di
	les bx,[bp+4]
	cmp es:[bx+8],di
	ja short rfft_key_next
	mov di,bx
rfft_key_table:
	db 66h
	push word ptr es:[di+4]
	call RegDosFree
rfft_data:
	mov es,word ptr [bp+6]
	db 66h
	cmp word ptr es:[di+10h],0
	jz short rfft_file
	xor cx,cx
	mov ax,es:[di+10h]
	mov dx,es:[di+12h]
	mov si,ax
	mov [bp-4],dx
	cmp es:[di+26h],cx
	jz short rfft_data_table
	mov [bp-2],cx
	mov di,cx
rfft_data_next:
	push word ptr [bp-4]
	push si
	call RegFreeDataBlock
	add si,14h
	inc di
	les bx,[bp+4]
	cmp es:[bx+26h],di
	ja short rfft_data_next
	mov di,bx
rfft_data_table:
	db 66h
	push word ptr es:[di+10h]
	call RegDosFree
rfft_file:
	push word ptr [bp+6]
	push di
	call RegDosFree
	xor ax,ax
	pop si
	pop di
	leave
	ret 4
RegReleaseFileBuffers endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegSaveFile
RegSaveFile proc near
	enter 10Ch,0
	push di
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	test byte ptr es:[si+56h],1
	jnz short rsfs_check
rsfs_clean:
	xor ax,ax
	jmp rsfs_done
rsfs_check:
	test byte ptr es:[si+56h],50h
	jnz short rsfs_clean
	mov bx,si
	or byte ptr es:[bx+56h],10h
	mov word ptr [bp-8],3F8h
	mov ax,-1
	mov [bp-6],ax
	mov [bp-4],ax
	lea ax,[bx+58h]
	push es
	push ax
	push 0
	call RegDosSetAttr
	or ax,ax
	jz rsfs_path_error
	les bx,[bp+4]
	test byte ptr es:[bx+56h],4
	jz rsfs_inplace
	mov ax,bx
	add ax,58h
	mov di,ax
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	dec cx
	mov [bp-2],cx
	cmp cx,104h
	jae rsfs_path_error
	mov bx,[bp+4]
	add bx,58h
	push ds
	mov di,bx
	lea si,[bp-10Ch]
	push ss
	pop ds
	mov cx,-1
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
	mov bx,[bp-2]
rsfs_separator:
	dec bx
	jz short rsfs_directory
	mov si,bx
	cmp byte ptr [bp+si-10Ch],'\'
	jnz short rsfs_separator
rsfs_directory:
	or bx,bx
	jz short rsfs_default
	mov si,bx
	mov byte ptr [bp+si-10Bh],0
	jmp short rsfs_temp
rsfs_default:
	push ds
	mov di,offset DGROUP:RegCurrentDirectory
	lea si,[bp-10Ch]
	push ds
	pop es
	push ss
	pop ds
	mov cx,-1
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
rsfs_temp:
	lea ax,[bp-10Ch]
	push ss
	push ax
	call RegDosTempFile
	mov [bp-4],ax
	inc ax
	jz short rsfs_path_error
	mov eax,[bp+4]
	add ax,58h
	push eax
	push 0
	call RegDosOpen
	mov [bp-6],ax
	inc ax
	jnz short rsfs_have_input
rsfs_path_error:
	mov si,[bp+4]
	jmp rsfs_error
rsfs_have_input:
	mov si,[bp+4]
	jmp short rsfs_header
rsfs_inplace:
	mov si,bx
	lea ax,[bx+58h]
	push es
	push ax
	push 1
	call RegDosOpen
	mov [bp-4],ax
	inc ax
	jz rsfs_error
rsfs_header:
	cmp word ptr [bp-6],-1
	jnz short rsfs_extent
	mov es,word ptr [bp+6]
	test byte ptr es:[si+28h],1
	jz short rsfs_keys
rsfs_extent:
	mov es,word ptr [bp+6]
	test byte ptr es:[si+56h],8
	jz short rsfs_packed
	mov ax,es:[si+0Ch]
	mov dx,es:[si+0Eh]
	add ah,10h
	jmp short rsfs_position
rsfs_packed:
	mov ax,es:[si+0Ch]
	mov dx,es:[si+0Eh]
	add ax,20h
rsfs_position:
	adc dx,0
	mov es:[si+1Eh],ax
	mov es:[si+20h],dx
	push word ptr [bp-4]
	mov ax,si
	mov dx,[bp+6]
	add ax,16h
	push dx
	push ax
	push 20h
	call RegDosWrite
	or ax,ax
	jz rsfs_error
rsfs_keys:
	push word ptr [bp+6]
	push si
	push word ptr [bp-6]
	push word ptr [bp-4]
	call RegWriteKeyBlocks
	mov [bp-8],ax
	or ax,ax
	jnz short rsfs_error
	push word ptr [bp+6]
	push si
	push word ptr [bp-6]
	push word ptr [bp-4]
	call RegWriteDataBlock
	mov [bp-8],ax
	or ax,ax
	jnz short rsfs_error
	push word ptr [bp-4]
	call RegDosClose
	cmp word ptr [bp-6],-1
	jz short rsfs_commit
	push word ptr [bp-6]
	call RegDosClose
	mov word ptr [bp-8],3F8h
	mov ax,si
	mov dx,[bp+6]
	add ax,58h
	push dx
	push ax
	call RegDosDelete
	or ax,ax
	jz short rsfs_attributes
	lea ax,[bp-10Ch]
	push ss
	push ax
	mov ax,si
	mov dx,[bp+6]
	add ax,58h
	push dx
	push ax
	call RegDosRename
	or ax,ax
	jz short rsfs_attributes
rsfs_commit:
	push word ptr [bp+6]
	push si
	call RegCommitDataCache
	push word ptr [bp+6]
	push si
	call RegCommitKeyCache
	mov es,word ptr [bp+6]
	and word ptr es:[si+28h],0FFFEh
	and word ptr es:[si+56h],0FFFAh
	mov word ptr [bp-8],0
	jmp short rsfs_attributes
rsfs_error:
	cmp word ptr [bp-6],-1
	jz short rsfs_output
	push word ptr [bp-6]
	call RegDosClose
rsfs_output:
	cmp word ptr [bp-4],-1
	jz short rsfs_attributes
	cmp word ptr [bp-6],-1
	jz short rsfs_restore
	lea ax,[bp-10Ch]
	push ss
	push ax
	call RegDosDelete
rsfs_restore:
	mov ax,si
	mov dx,[bp+6]
	add ax,58h
	push dx
	push ax
	push 7
	call RegDosSetAttr
rsfs_attributes:
	mov ax,si
	mov dx,[bp+6]
	add ax,58h
	push dx
	push ax
	push 7
	call RegDosSetAttr
	mov es,word ptr [bp+6]
	and byte ptr es:[si+56h],0EFh
	mov ax,[bp-8]
rsfs_done:
	pop si
	pop di
	leave
	ret 4
RegSaveFile endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegMaintainCache
RegMaintainCache proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	test byte ptr es:[si+56h],50h
	jnz short rdc_exit
	or byte ptr es:[si+56h],20h
	push es
	push si
	call RegTrimKeyCache
	push word ptr [bp+6]
	push si
	call RegScanDataBlocks
	mov es,word ptr [bp+6]
	and byte ptr es:[si+56h],0DFh
rdc_exit:
	xor ax,ax
	pop si
	leave
	ret 4
RegMaintainCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegForEachFile
RegForEachFile proc near
	enter 8,0
	push di
	push si
	mov ax,word ptr RegActiveFiles
	mov dx,word ptr RegActiveFiles+2
	mov si,ax
	mov [bp-6],dx
	or dx,ax
	jz short rfef_done
rfef_next:
	mov es,word ptr [bp-6]
	mov di,si
	mov ax,es:[si]
	mov dx,es:[si+2]
	mov si,ax
	mov [bp-6],dx
	push es
	push di
	call word ptr [bp+4]
	mov ax,[bp-6]
	or ax,si
	jnz short rfef_next
rfef_done:
	pop si
	pop di
	leave
	ret 2
RegForEachFile endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegBindRoot
RegBindRoot proc near
	enter 4,0
	push di
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	les bx,es:[si+6]
	db 66h
	mov ax,es:[bx+3Eh]
	mov dx,es:[bx+40h]
	mov es,word ptr [bp+6]
	db 66h
	mov es:[si+0Ah],ax
	db 66h
	push word ptr es:[si+6]
	push dx
	push word ptr es:[si+0Ah]
	lea ax,[bp-4]
	push ss
	push ax
	call RegFetchKeyRecord
	mov di,ax
	or di,ax
	jnz short rbrt_error
	mov es,word ptr [bp+6]
	mov word ptr es:[si],4B48h
	and byte ptr es:[si+2],0E9h
	les bx,[bp-4]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	sub dh,dh
	mov es,word ptr [bp+6]
	mov es:[si+0Eh],ax
	mov es:[si+10h],dx
	les bx,[bp-4]
	mov ax,es:[bx+0Ch]
	mov es,word ptr [bp+6]
	mov es:[si+12h],ax
	les bx,[bp-4]
	mov al,es:[bx+0Bh]
	mov es,word ptr [bp+6]
	mov es:[si+14h],al
	db 66h
	push word ptr es:[si+6]
	db 66h
	push word ptr es:[si+0Ah]
	push 0
	call RegUnlockKeyCache
	jmp short rbrt_done
rbrt_error:
	mov es,word ptr [bp+6]
	db 66h
	push word ptr es:[si+6]
	call RegReleaseFileBuffers
rbrt_done:
	mov ax,di
	pop si
	pop di
	leave
	ret 4
RegBindRoot endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegMountRoot
RegMountRoot proc far
	mov ax,DGROUP
	push bp
	mov bp,sp
	push si
	push ds
	mov ds,ax
	cmp dword ptr [bp+6],80000002h
	jz short rmrt_root
	cmp dword ptr [bp+6],80000003h
	jz short rmrt_root
	mov ax,57h
rmrt_zero_dx:
	xor dx,dx
	jmp short rmrt_exit
rmrt_root:
	lea ax,[bp+6]
	push ss
	push ax
	call RegValidateKeyHandle
	les bx,[bp+6]
	test byte ptr es:[bx+2],4
	jnz short rmrt_path
	db 66h
	push word ptr es:[bx+6]
	call RegReleaseFileBuffers
rmrt_path:
	cmp dword ptr [bp+0Ah],0
	jnz short rmrt_flags
	xor ax,ax
	jmp short rmrt_zero_dx
rmrt_flags:
	mov cx,[bp+0Eh]
	test cl,1
	jz short rmrt_open
	mov eax,[bp+6]
	add ax,6
	push eax
	push dword ptr [bp+0Ah]
	and cx,2
	cmp cx,1
	cmc
	sbb ax,ax
	and ax,4
	push ax
	call RegCreateEmptyFile
	jmp short rmrt_bind
rmrt_open:
	mov eax,[bp+6]
	add ax,6
	push eax
	push dword ptr [bp+0Ah]
	call RegReadFile
rmrt_bind:
	mov si,ax
	or si,ax
	jnz short rmrt_result
	push dword ptr [bp+6]
	call RegBindRoot
	mov si,ax
rmrt_result:
	mov ax,si
	cwd
rmrt_exit:
	pop ds
	pop si
	leave
	retf
RegMountRoot endp
	if ($ - RegistryCode) and 1
	db 0
	endif

REGTEXT ends
	end
