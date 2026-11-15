;** REGREAD - Registry file storage, cache and block validation
;
; Near entries share the file and block services in REGTEXT.
; Load, save and cache maintenance use the same block index and validators.
;
	.386

DataBlockSize equ 1Ah
DataBlockLocks equ 16h
_DATA segment word public use16 'RESUME_DATA'
	extrn RegTransferBuffer:dword
_DATA ends
DGROUP group _DATA
_TEXT segment word public use16 'RESUME_CODE'
_TEXT ends
REGTEXT segment word public use16 'RESUME_CODE'
SysResume segment byte public use16 'RESUME_CODE'
SysResume ends
CGROUP group SysResume,_TEXT,REGTEXT
	assume cs:CGROUP,ds:DGROUP
	extrn __aFuldiv:far
	extrn __aFlshl:far
	extrn __aFulshr:far
	extrn RegDosOpen:near
	extrn RegDosWrite:near
	extrn RegDosRead:near
	extrn RegDosSeek:near
	extrn RegDosClose:near
	extrn RegMoveMemory:near
	extrn RegZeroMemory:near
	extrn RegDosFree:near
	extrn RegForEachFile:near
	extrn RegMaintainCache:near
RegistryCode label byte
	extrn RegAllocate:near
	extrn RegReallocRetry:near
	public RegKeyOffsetToIndex
RegKeyOffsetToIndex proc near
	push bp
	mov bp,sp
	cmp dword ptr [bp+4],-1
	jnz short rkoi_divide
	mov ax,[bp+4]
	mov dx,[bp+6]
	jmp short rkoi_done
rkoi_divide:
	push 0
	push 1Ch
	push dword ptr [bp+4]
	call __aFuldiv
rkoi_done:
	leave
	ret 4
RegKeyOffsetToIndex endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegKeyIndexToOffset
RegKeyIndexToOffset proc near
	push bp
	mov bp,sp
	push di
	push si
	cmp dword ptr [bp+4],00FFFFFFh
	jb short rkio_valid
	mov ax,-1
	cwd
	jmp short rkio_done
rkio_valid:
	cmp dword ptr [bp+4],124h
	jb short rkio_first
	mov eax,[bp+4]
	mov ecx,1Ch
	mul ecx
	add	eax,dword ptr 1Bh
	mov edx,eax
	shr edx,16
	mov cx,ax
	and ax,0F000h
	mov si,ax
	mov di,dx
	mov ax,cx
	and ah,0Fh
	mov cx,1Ch
	sub dx,dx
	div cx
	mul cx
	add ax,si
	adc dx,di
	jmp short rkio_done
rkio_first:
	mov eax,[bp+4]
	mov ecx,1Ch
	mul ecx
	add	eax,dword ptr 4
	mov edx,eax
	shr edx,16
rkio_done:
	pop si
	pop di
	leave
	ret 4
RegKeyIndexToOffset endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegDecodeKeyRecord
RegDecodeKeyRecord proc near
	enter 4,0
	push di
	push si
	mov di,[bp+8]
	mov si,[bp+4]
	mov es,[bp+0Ah]
	mov byte ptr es:[di+3],0
	mov es,[bp+6]
	db 66h
	cmp word ptr es:[si],0
	jz short rdkr_used
	db 66h
	cmp word ptr es:[si],1
	jz short rdkr_used
	db 66h
	cmp word ptr es:[si],2
	jz short rdkr_used
	db 66h,26h,81h,3Ch
	dd 80000000h
	jz short rdkr_copy_free
	db 66h
	cmp word ptr es:[si],-1
	jnz short rdkr_skip_free
rdkr_copy_free:
	db 66h
	mov ax,es:[si+4]
	mov es,[bp+0Ah]
	db 66h
	mov es:[di+8],ax
	mov es,[bp+6]
	db 66h
	push word ptr es:[si+8]
	call RegKeyOffsetToIndex
	mov es,[bp+0Ah]
	xor ax,es:[di]
	xor dx,es:[di+2]
	sub dh,dh
	xor es:[di],ax
	xor es:[di+2],dx
	db 66h
	cmp word ptr es:[di+8],038h
	ja short rdkr_free_ok
rdkr_skip_free:
	jmp near ptr rdkr_zero
rdkr_free_ok:
	mov ax,1
	jmp near ptr rdkr_done
rdkr_used:
	mov es,[bp+0Ah]
	mov dx,es:[di+2]
	mov dh,1
	mov es:[di+2],dx
	mov es,[bp+6]
	db 66h
	push word ptr es:[si+0Ch]
	call RegKeyOffsetToIndex
	mov es,[bp+0Ah]
	xor ax,es:[di+8]
	xor dx,es:[di+0Ah]
	sub dh,dh
	xor es:[di+8],ax
	xor es:[di+0Ah],dx
	mov es,[bp+6]
	db 66h
	push word ptr es:[si+014h]
	call RegKeyOffsetToIndex
	mov es,[bp+0Ah]
	xor ax,es:[di]
	xor dx,es:[di+2]
	sub dh,dh
	xor es:[di],ax
	xor es:[di+2],dx
	mov es,[bp+6]
	db 66h
	push word ptr es:[si+010h]
	call RegKeyOffsetToIndex
	mov es,[bp+0Ah]
	xor ax,es:[di+4]
	xor dx,es:[di+6]
	sub dh,dh
	xor es:[di+4],ax
	xor es:[di+6],dx
	mov es,[bp+6]
	mov ah,es:[si+018h]
	sub al,al
	mov dx,ax
	sub cx,cx
	mov es,[bp+0Ah]
	mov [bp-4],cx
	xor cx,es:[di+8]
	xor dx,es:[di+0Ah]
	and dh,al
	xor cx,[bp-4]
	xor dx,ax
	mov es:[di+8],cx
	mov es:[di+0Ah],dx
	mov es,[bp+6]
	mov ax,es:[si+01Ah]
	mov es,[bp+0Ah]
	mov es:[di+0Ch],ax
	mov es,[bp+6]
	mov ax,es:[si+4]
	mov es,[bp+0Ah]
	mov es:[di+0Eh],ax
	mov es,[bp+6]
	db 66h
	cmp word ptr es:[si],1
	jnz short rdkr_continuation
	mov es,[bp+0Ah]
	or byte ptr es:[di+3],2
	jmp short rdkr_zero
rdkr_continuation:
	db 66h
	cmp word ptr es:[si],2
	jnz short rdkr_zero
	mov es,[bp+0Ah]
	or byte ptr es:[di+3],4
rdkr_zero:
	xor ax,ax
rdkr_done:
	pop si
	pop di
	leave
	ret 8
RegDecodeKeyRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegEncodeKeyRecord
RegEncodeKeyRecord proc near
	enter 4,0
	push di
	push si
	mov di,[bp+8]
	mov es,[bp+0Ah]
	test word ptr es:[di+2],0100h
	jz near ptr rekr_free
	test word ptr es:[di+2],0200h
	jz short rekr_continuation
	mov si,[bp+4]
	mov es,[bp+6]
	mov word ptr es:[si],1
rekr_type_high:
	mov word ptr es:[si+2],0
	jmp short rekr_links
rekr_continuation:
	test word ptr es:[di+2],0400h
	jz short rekr_ordinary
	mov si,[bp+4]
	mov es,[bp+6]
	mov word ptr es:[si],2
	jmp short rekr_type_high
rekr_ordinary:
	mov si,[bp+4]
	mov es,[bp+6]
	db 66h
	mov word ptr es:[si],0
	dw 0
rekr_links:
	mov es,[bp+0Ah]
	mov ax,es:[di+8]
	mov dx,es:[di+0Ah]
	sub dh,dh
	push dx
	push ax
	call RegKeyIndexToOffset
	mov es,[bp+6]
	mov es:[si+0Ch],ax
	mov es:[si+0Eh],dx
	mov es,[bp+0Ah]
	mov ax,es:[di]
	mov dx,es:[di+2]
	sub dh,dh
	push dx
	push ax
	call RegKeyIndexToOffset
	mov es,[bp+6]
	mov es:[si+014h],ax
	mov es:[si+016h],dx
	mov es,[bp+0Ah]
	mov ax,es:[di+4]
	mov dx,es:[di+6]
	sub dh,dh
	push dx
	push ax
	call RegKeyIndexToOffset
	mov es,[bp+6]
	mov es:[si+010h],ax
	mov es:[si+012h],dx
	mov es,[bp+0Ah]
	mov ax,es:[di+0Eh]
	mov es,[bp+6]
	mov es:[si+4],ax
	mov word ptr es:[si+6],0
	mov es,[bp+0Ah]
	cmp word ptr es:[di+0Ch],-1
	jnz short rekr_data_fields
	mov es,[bp+6]
	db 66h
	mov word ptr es:[si+18h],-1
	dw -1
	jmp short rekr_done
rekr_data_fields:
	mov al,es:[di+0Bh]
	sub ah,ah
	mov cx,es:[di+0Ch]
	mov es,[bp+6]
	mov es:[si+018h],ax
	mov es:[si+01Ah],cx
	jmp short rekr_done
rekr_free:
	mov si,[bp+4]
	mov es,[bp+6]
	db 66h
	mov word ptr es:[si],0
	dw 8000h
	mov es,[bp+0Ah]
	db 66h
	mov ax,es:[di+8]
	mov es,[bp+6]
	db 66h
	mov es:[si+4],ax
	mov ax,es
	mov es,[bp+0Ah]
	mov cx,es:[di]
	mov dx,es:[di+2]
	sub dh,dh
	push dx
	push cx
	mov [bp-4],si
	mov [bp-2],ax
	call RegKeyIndexToOffset
	les bx,[bp-4]
	mov es:[bx+8],ax
	mov es:[bx+0Ah],dx
rekr_done:
	xor ax,ax
	pop si
	pop di
	leave
	ret 8
RegEncodeKeyRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegWalkKeyRecords
RegWalkKeyRecords proc near
	enter 10h,0
	push di
	push si
	mov eax,[bp+12h]
	mov dx,[bp+14h]
	mov [bp-4],eax
	mov cx,[bp+6]
	mov bx,[bp+8]
	mov di,cx
	mov [bp-6],bx
	or dx,ax
	jnz short rwkr_body
	mov bx,20h
	jmp short rwkr_start
rwkr_body:
	xor bx,bx
rwkr_start:
	mov eax,[bp+0Eh]
	add eax,[bp+12h]
	mov [bp-10h],eax
rwkr_page:
	add di,bx
	sub cx,cx
	add [bp-4],bx
	adc [bp-2],cx
	mov eax,[bp-4]
	mov dx,[bp-2]
	cmp [bp-10h],eax
	jbe short rwkr_done
	push dx
	push ax
	call RegKeyOffsetToIndex
	and ah,3
	shl ax,4
	add ax,[bp+0Ah]
	mov dx,[bp+0Ch]
	mov si,ax
	mov [bp-0Ah],dx
rwkr_next:
	mov eax,[bp-4]
	mov dx,[bp-2]
	cmp [bp-10h],eax
	jbe short rwkr_boundary
	and ax,0F000h
	or dx,ax
	jz short rwkr_call
rwkr_boundary:
	mov eax,[bp-4]
	add	eax,dword ptr 1Ch
	xor eax,[bp-4]
	and ax,0F000h
	or eax,eax
	jnz short rwkr_skip
rwkr_call:
	push word ptr [bp-0Ah]
	push si
	push word ptr [bp-6]
	push di
	call word ptr [bp+4]
	or ax,ax
	jnz short rwkr_done
	add word ptr [bp-4],1Ch
	adc [bp-2],ax
	add di,1Ch
	add si,10h
	jmp short rwkr_next
rwkr_skip:
	mov bx,1000h
	mov ax,[bp-4]
	and ah,0Fh
	sub bx,ax
	jmp rwkr_page
rwkr_done:
	pop si
	pop di
	leave
	ret 12h
RegWalkKeyRecords endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegLoadKeyCache
RegLoadKeyCache proc near
	enter 14h,0
	push di
	push si
	mov di,[bp+0Ch]
	mov ax,[bp+8]
	mov dx,[bp+0Ah]
	mov cl,10
	call __aFulshr
	mov si,ax
	mov es,word ptr [bp+0Eh]
	cmp si,es:[di+8]
	jbe short rlkc_entry
	mov ax,3F1h
	jmp rlkc_done
rlkc_entry:
	mov ax,es:[di+4]
	mov dx,es:[di+6]
	imul cx,si,6
	add ax,cx
	mov [bp-14h],ax
	mov [bp-12h],dx
	mov bx,ax
	mov es,dx
	db 66h
	mov ax,es:[bx]
	mov [bp-6],eax
	or eax,eax
	jnz rlkc_pin
	push 4000h
	call RegAllocate
	mov [bp-6],ax
	mov [bp-4],dx
	or dx,ax
	jnz short rlkc_extent
	mov ax,0Eh
	jmp rlkc_done
rlkc_extent:
	mov es,word ptr [bp+0Eh]
	mov al,es:[di+56h]
	and ax,8
	cmp ax,1
	sbb ax,ax
	and ax,3000h
	add ah,40h
	mov [bp-0Eh],ax
	mul si
	mov [bp-0Ah],ax
	mov [bp-8],dx
	cmp dx,es:[di+3Ch]
	ja rlkc_install
	jb short rlkc_remaining
	cmp ax,es:[di+3Ah]
	jae rlkc_install
rlkc_remaining:
	mov ax,es:[di+3Ah]
	mov dx,es:[di+3Ch]
	sub ax,[bp-0Ah]
	sbb dx,[bp-8]
	mov cx,[bp-0Eh]
	sub bx,bx
	cmp dx,bx
	jb short rlkc_count
	ja short rlkc_limit
	cmp ax,cx
	jbe short rlkc_count
rlkc_limit:
	mov ax,cx
rlkc_count:
	mov [bp-0Ch],ax
	lea ax,[di+58h]
	push es
	push ax
	push bx
	call RegDosOpen
	mov [bp-2],ax
	inc ax
	jz short rlkc_error
	mov es,word ptr [bp+0Eh]
	test byte ptr es:[di+56h],8
	jz short rlkc_decode
	push word ptr [bp-2]
	mov ax,[bp-0Ah]
	mov dx,[bp-8]
	add ah,10h
	adc dx,0
	push dx
	push ax
	call RegDosSeek
	or ax,ax
	jz short rlkc_error
	push dword ptr [bp-4]
	push word ptr [bp-6]
	push word ptr [bp-0Ch]
	call RegDosRead
	or ax,ax
	jnz short rlkc_close
rlkc_error:
	mov word ptr [bp-8],3F8h
	push dword ptr [bp-6]
	call RegDosFree
	cmp word ptr [bp-2],-1
	jz short rlkc_failed
	push word ptr [bp-2]
	call RegDosClose
rlkc_failed:
	mov ax,3F8h
	jmp rlkc_done
rlkc_decode:
	push word ptr [bp-2]
	mov eax,[bp-0Ah]
	add	eax,dword ptr 20h
	push eax
	call RegDosSeek
	or ax,ax
	jz short rlkc_error
	push word ptr [bp-2]
	mov eax,RegTransferBuffer
	mov [bp-10h],eax
	push eax
	push word ptr [bp-0Ch]
	call RegDosRead
	or ax,ax
	jz short rlkc_error
	push dword ptr [bp-0Ah]
	push 0
	push word ptr [bp-0Ch]
	push dword ptr [bp-6]
	push dword ptr [bp-10h]
	push offset CGROUP:RegDecodeKeyRecord
	call RegWalkKeyRecords
rlkc_close:
	push word ptr [bp-2]
	call RegDosClose
rlkc_install:
	mov eax,[bp-6]
	les bx,[bp-14h]
	db 66h
	mov es:[bx],ax
	xor al,al
	mov es:[bx+4],al
	mov es:[bx+5],al
rlkc_pin:
	mov ax,[bp+8]
	and ah,3
	shl ax,4
	add ax,[bp-6]
	mov dx,[bp-4]
	les bx,[bp+4]
	mov es:[bx],ax
	mov es:[bx+2],dx
	les bx,[bp-14h]
	or byte ptr es:[bx+4],1
	inc byte ptr es:[bx+5]
	xor ax,ax
rlkc_done:
	pop si
	pop di
	leave
	ret 0Ch
RegLoadKeyCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFetchKeyRecord
RegFetchKeyRecord proc near
	push bp
	mov bp,sp
	push di
	push si
	mov di,[bp+4]
	push dword ptr [bp+0Ch]
	push dword ptr [bp+8]
	push word ptr [bp+6]
	push di
	call RegLoadKeyCache
	mov si,ax
	or si,ax
	jnz short rfkr_done
	mov es,word ptr [bp+6]
	les bx,es:[di]
	test word ptr es:[bx+2],100h
	jnz short rfkr_done
	push dword ptr [bp+0Ch]
	push dword ptr [bp+8]
	push 0
	call RegUnlockKeyCache
	mov si,3F1h
rfkr_done:
	mov ax,si
	pop si
	pop di
	leave
	ret 0Ch
RegFetchKeyRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegUnlockKeyCache
RegUnlockKeyCache proc near
	enter 4,0
	push di
	push si
	mov si,[bp+0Ah]
	mov ax,[bp+6]
	mov dx,[bp+8]
	mov cl,10
	call __aFulshr
	imul ax,ax,6
	mov es,word ptr [bp+0Ch]
	add ax,es:[si+4]
	mov dx,es:[si+6]
	mov di,ax
	mov [bp-2],dx
	mov bx,ax
	mov es,dx
	dec byte ptr es:[bx+5]
	cmp word ptr [bp+4],0
	jz short rukc_done
	mov es,word ptr [bp-2]
	or byte ptr es:[di+4],2
	mov es,word ptr [bp+0Ch]
	or byte ptr es:[si+56h],3
rukc_done:
	pop si
	pop di
	leave
	ret 0Ah
RegUnlockKeyCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegAllocateKeyRecord
RegAllocateKeyRecord proc near
	enter 1Ch,0
	push di
	push si
	mov si,[bp+0Ch]
	mov es,[bp+0Eh]
	db 66h
	mov ax,es:[si+042h]
	mov [bp-8],eax
	mov dx,[bp-6]
	cmp eax,0FFFFFFh
	jc near ptr rakr_load_existing
	test byte ptr es:[si+056h],8
	jz short rakr_packed
	mov ax,es:[si+0Ch]
	mov dx,es:[si+0Eh]
	add ax,0FFFh
	adc dx,0
	and ax,0F00Fh
	mov cl,4
	call __aFulshr
	mov [bp-8],ax
	mov [bp-6],dx
	mov word ptr [bp-0Eh],01000h
	xor di,di
	jmp short rakr_block
rakr_packed:
	db 66h
	cmp word ptr es:[si+0Ch],020h
	jnz short rakr_align
	mov dword ptr [bp-4],020h
	mov word ptr [bp-0Eh],0FC0h
	jmp short rakr_zero_gap
rakr_align:
	mov ax,es:[si+0Ch]
	mov dx,es:[si+0Eh]
	mov cx,ax
	add ax,0FFFh
	adc dx,0
	and ax,0F000h
	mov [bp-4],ax
	mov [bp-2],dx
	mov word ptr [bp-0Eh],01000h
	mov di,ax
	sub di,cx
	cmp di,01Ch
	ja short rakr_extend
	cmp ax,01000h
	jnz short rakr_convert
	or dx,dx
	jnz short rakr_convert
rakr_extend:
	lea ax,[di+01000h]
	mov [bp-0Eh],ax
	db 66h
	mov ax,es:[si+0Ch]
	mov [bp-4],eax
rakr_zero_gap:
	xor di,di
rakr_convert:
	push dword ptr [bp-4]
	call RegKeyOffsetToIndex
	mov [bp-8],ax
	mov [bp-6],dx
rakr_block:
	mov [bp-010h],di
	mov cl,0Ah
	call __aFulshr
	mov [bp-2],ax
	mov es,[bp+0Eh]
	cmp ax,es:[si+0Ah]
	jc short rakr_cache_count
	db 66h
	push word ptr es:[si+4]
	add ax,4
	mov [bp-4],ax
	imul ax,ax,6
	push ax
	call RegReallocRetry
	mov [bp-0Ch],ax
	mov [bp-0Ah],dx
	or dx,ax
	jnz short rakr_grow_table
	mov ax,0Eh
	jmp near ptr rakr_done
rakr_grow_table:
	mov di,[bp-4]
	mov es,[bp+0Eh]
	imul ax,es:[si+0Ah],6
	add ax,[bp-0Ch]
	mov dx,[bp-0Ah]
	push dx
	push ax
	mov ax,di
	sub di,es:[si+0Ah]
	imul cx,di,6
	push cx
	mov di,ax
	call RegZeroMemory
	mov eax,[bp-0Ch]
	mov es,[bp+0Eh]
	db 66h
	mov es:[si+4],ax
	mov es:[si+0Ah],di
rakr_cache_count:
	mov ax,[bp-2]
	mov es,[bp+0Eh]
	cmp es:[si+8],ax
	jna short rakr_load_new
	mov ax,[bp-010h]
	add ax,[bp-0Eh]
	sub dx,dx
	add es:[si+0Ch],ax
	adc es:[si+0Eh],dx
	or byte ptr es:[si+056h],4
	mov eax,[bp-8]
	db 66h
	mov es:[si+042h],ax
rakr_load_new:
	push word ptr [bp+0Eh]
	push si
	push dword ptr [bp-8]
	lea ax,[bp-014h]
	push ss
	push ax
	call RegLoadKeyCache
	mov di,ax
	or di,ax
	jz short rakr_install_new
rakr_load_error:
	mov ax,di
	jmp near ptr rakr_done
rakr_install_new:
	mov cx,[bp-2]
	mov bx,[bp-0Eh]
	mov es,[bp+0Eh]
	cmp es:[si+8],cx
	ja short rakr_init_free
	mov ax,cx
	inc ax
	mov es:[si+8],ax
	mov bx,[bp-0Eh]
	mov ax,[bp-010h]
	add ax,bx
	sub dx,dx
	add es:[si+0Ch],ax
	adc es:[si+0Eh],dx
	or byte ptr es:[si+056h],4
	mov eax,[bp-8]
	db 66h
	mov es:[si+042h],ax
rakr_init_free:
	les di,[bp-014h]
	; OR DWORD PTR ES:[DI],00FFFFFFh, operand prefix first.
	db 66h,26h,81h,0Dh
	dd 0FFFFFFh
	les di,[bp-014h]
	mov byte ptr es:[di+3],0
	les di,[bp-014h]
	mov es:[di+8],bx
	mov word ptr es:[di+0Ah],0
	jmp short rakr_have
rakr_load_existing:
	push es
	push si
	push dx
	push ax
	lea ax,[bp-014h]
	push ss
	push ax
	call RegLoadKeyCache
	mov di,ax
	or di,ax
	jnz short rakr_load_error
rakr_have:
	les bx,[bp-014h]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	sub dh,dh
	mov [bp-4],ax
	mov [bp-2],dx
	mov es,[bp+0Eh]
	mov al,es:[si+056h]
	and ax,8
	cmp ax,1
	sbb ax,ax
	and ax,0Ch
	add ax,010h
	mov di,ax
	add ax,ax
	sub dx,dx
	mov es,[bp-012h]
	cmp dx,es:[bx+0Ah]
	ja short rakr_finish
	jc short rakr_split
	cmp ax,es:[bx+8]
	ja short rakr_finish
rakr_split:
	push word ptr [bp+0Eh]
	push si
	mov eax,[bp-8]
	inc eax
	mov [bp-01Ch],eax
	push eax
	lea ax,[bp-018h]
	push ss
	push ax
	call RegLoadKeyCache
	or ax,ax
	jnz short rakr_finish
	les bx,[bp-018h]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	xor ax,[bp-4]
	xor dx,[bp-2]
	sub dh,dh
	xor es:[bx],ax
	xor es:[bx+2],dx
	les bx,[bp-018h]
	mov es:[bx+3],dh
	les bx,[bp-014h]
	mov ax,es:[bx+8]
	mov dx,es:[bx+0Ah]
	sub ax,di
	sbb dx,0
	les bx,[bp-018h]
	mov es:[bx+8],ax
	mov es:[bx+0Ah],dx
	mov eax,[bp-01Ch]
	mov dx,[bp-01Ah]
	mov [bp-4],eax
	push word ptr [bp+0Eh]
	push si
	push dx
	push ax
	push 1
	call RegUnlockKeyCache
	public RegFinishKeyAllocation
RegFinishKeyAllocation label near
rakr_finish:
	mov eax,[bp-4]
	mov es,[bp+0Eh]
	db 66h
	mov es:[si+042h],ax
	les bx,[bp-014h]
	or byte ptr es:[bx+3],1
	mov ax,[bp-8]
	mov dx,[bp-6]
	mov cl,0Ah
	call __aFulshr
	imul di,ax,6
	mov es,[bp+0Eh]
	les bx,es:[si+4]
	or byte ptr es:[bx+di+4],2
	mov es,[bp+0Eh]
	or byte ptr es:[si+056h],3
	mov eax,[bp-8]
	les bx,[bp+8]
	db 66h
	mov es:[bx],ax
	mov eax,[bp-014h]
	les bx,[bp+4]
	db 66h
	mov es:[bx],ax
	xor ax,ax
rakr_done:
	pop si
	pop di
	leave
	ret 0Ch
RegAllocateKeyRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFreeKeyRecord
RegFreeKeyRecord proc near
	enter 4,0
	push di
	push si
	mov si,[bp+8]
	push word ptr [bp+0Ah]
	push si
	push dword ptr [bp+4]
	lea ax,[bp-4]
	push ss
	push ax
	call RegLoadKeyCache
	mov di,ax
	or di,ax
	jnz short rfkr_free_done
	les bx,[bp-4]
	and byte ptr es:[bx+3],0F8h
	mov es,word ptr [bp+0Ah]
	mov ax,es:[si+42h]
	mov dx,es:[si+44h]
	les bx,[bp-4]
	xor ax,es:[bx]
	xor dx,es:[bx+2]
	sub dh,dh
	xor es:[bx],ax
	xor es:[bx+2],dx
	mov es,word ptr [bp+0Ah]
	mov al,es:[si+56h]
	and ax,8
	cmp ax,1
	sbb ax,ax
	and ax,0Ch
	add ax,10h
	les bx,[bp-4]
	mov es:[bx+8],ax
	mov word ptr es:[bx+0Ah],0
	mov eax,[bp+4]
	mov dx,[bp+6]
	mov es,word ptr [bp+0Ah]
	db 66h
	mov es:[si+42h],ax
	push es
	push si
	push dx
	push ax
	push 1
	call RegUnlockKeyCache
rfkr_free_done:
	mov ax,di
	pop si
	pop di
	leave
	ret 8
RegFreeKeyRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegKeyBlockExtent
RegKeyBlockExtent proc near
	enter 8,0
	push di
	push si
	mov di,[bp+10h]
	mov es,word ptr [bp+12h]
	test byte ptr es:[di+56h],8
	jz short rkbe_packed
	mov si,4000h
	mov eax,[bp+0Ch]
	shl eax,4
	mov [bp-4],eax
	mov dx,[bp-2]
	add ah,40h
	adc dx,0
	mov es,word ptr [bp+12h]
	cmp dx,es:[di+0Eh]
	jb short rkbe_linear
	ja short rkbe_last
	cmp ax,es:[di+0Ch]
	jbe short rkbe_linear
rkbe_last:
	mov si,es:[di+0Ch]
	sub si,[bp-4]
rkbe_linear:
	mov ax,[bp+0Ch]
	mov dx,[bp+0Eh]
	add ah,1
	adc dx,0
	mov cl,4
	call __aFlshl
	jmp short rkbe_store
rkbe_packed:
	mov si,7000h
	cmp dword ptr [bp+0Ch],0
	jnz short rkbe_offset
	push 0
	push 20h
	call RegKeyOffsetToIndex
	mov [bp+0Ch],ax
	mov [bp+0Eh],dx
	mov si,6FE0h
rkbe_offset:
	push dword ptr [bp+0Ch]
	call RegKeyIndexToOffset
	mov [bp-4],ax
	mov [bp-2],dx
	mov es,word ptr [bp+12h]
	mov ax,si
	sub dx,dx
	add ax,[bp-4]
	adc dx,[bp-2]
	cmp dx,es:[di+0Eh]
	jb short rkbe_position
	ja short rkbe_tail
	cmp ax,es:[di+0Ch]
	jbe short rkbe_position
rkbe_tail:
	mov si,es:[di+0Ch]
	sub si,[bp-4]
rkbe_position:
	mov ax,[bp-4]
	mov dx,[bp-2]
	add ax,20h
	adc dx,0
rkbe_store:
	mov [bp-8],ax
	mov [bp-6],dx
	les bx,[bp+8]
	mov es:[bx],si
	mov eax,[bp-8]
	les bx,[bp+4]
	db 66h
	mov es:[bx],ax
	pop si
	pop di
	leave
	ret 10h
RegKeyBlockExtent endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegWriteKeyBlock
RegWriteKeyBlock proc near
	enter 0Eh,0
	push di
	push si
	mov di,[bp+0Eh]
	push word ptr [bp+10h]
	push di
	push dword ptr [bp+0Ah]
	lea ax,[bp-0Ah]
	push ss
	push ax
	lea ax,[bp-0Eh]
	push ss
	push ax
	call RegKeyBlockExtent
	mov si,3F8h
	push word ptr [bp+8]
	push dword ptr [bp-0Eh]
	call RegDosSeek
	or ax,ax
	jz short rwkb_done
	mov es,word ptr [bp+10h]
	test byte ptr es:[di+56h],8
	jz short rwkb_encode
	push word ptr [bp+8]
	les bx,[bp+4]
	db 66h
	push word ptr es:[bx]
	jmp short rwkb_write
rwkb_encode:
	mov ax,word ptr RegTransferBuffer
	mov dx,word ptr RegTransferBuffer+2
	mov di,ax
	mov [bp-6],dx
	mov eax,[bp+0Ah]
	mov ecx,1Ch
	mul ecx
	push eax
	push 0
	push word ptr [bp-0Ah]
	les bx,[bp+4]
	db 66h
	push word ptr es:[bx]
	push RegTransferBuffer
	push offset CGROUP:RegEncodeKeyRecord
	call RegWalkKeyRecords
	mov ax,[bp-6]
	mov [bp-4],di
	mov [bp-2],ax
	cmp dword ptr [bp+0Ah],0
	jnz short rwkb_buffer
	add word ptr [bp-4],20h
rwkb_buffer:
	push word ptr [bp+8]
	push dword ptr [bp-4]
rwkb_write:
	push word ptr [bp-0Ah]
	call RegDosWrite
	or ax,ax
	jz short rwkb_done
	xor si,si
rwkb_done:
	mov ax,si
	pop si
	pop di
	leave
	ret 0Eh
RegWriteKeyBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegWriteKeyBlocks
RegWriteKeyBlocks proc near
	enter 12h,0
	push di
	push si
	cmp word ptr [bp+6],-1
	jnz short rwks_seek
	les bx,[bp+8]
	test byte ptr es:[bx+56h],2
	jz rwks_success
rwks_seek:
	push word ptr [bp+4]
	push 0
	push 20h
	call RegDosSeek
	or ax,ax
	jnz short rwks_header
rwks_error:
	mov ax,3F8h
	jmp rwks_done
rwks_header:
	mov si,[bp+8]
	mov es,word ptr [bp+0Ah]
	db 66h
	mov ax,es:[si+3Ah]
	mov [bp-4],eax
	db 66h
	mov ax,es:[si+3Eh]
	mov [bp-8],eax
	db 66h
	mov ax,es:[si+42h]
	mov [bp-0Ch],eax
	db 66h
	mov ax,es:[si+0Ch]
	db 66h
	mov es:[si+3Ah],ax
	test byte ptr es:[si+56h],8
	jnz short rwks_write_header
	mov es,word ptr [bp+0Ah]
	db 66h
	push word ptr es:[si+3Eh]
	call RegKeyIndexToOffset
	mov es,word ptr [bp+0Ah]
	mov es:[si+3Eh],ax
	mov es:[si+40h],dx
	db 66h
	push word ptr es:[si+42h]
	call RegKeyIndexToOffset
	mov es,word ptr [bp+0Ah]
	mov es:[si+42h],ax
	mov es:[si+44h],dx
rwks_write_header:
	push word ptr [bp+4]
	mov ax,si
	mov dx,[bp+0Ah]
	add ax,36h
	push dx
	push ax
	push 20h
	call RegDosWrite
	mov di,ax
	mov eax,[bp-4]
	mov es,word ptr [bp+0Ah]
	db 66h
	mov es:[si+3Ah],ax
	mov eax,[bp-8]
	db 66h
	mov es:[si+3Eh],ax
	mov eax,[bp-0Ch]
	db 66h
	mov es:[si+42h],ax
	or di,di
	jz rwks_error
	mov es,word ptr [bp+0Ah]
	db 66h
	mov ax,es:[si+4]
	mov [bp-4],eax
	mov word ptr [bp-0Ah],0
	cmp word ptr es:[si+8],0
	jz rwks_success
	mov word ptr [bp-0Ch],0
rwks_next:
	mov si,[bp+6]
	mov ax,[bp-0Ch]
	mov [bp-8],ax
	mov word ptr [bp-6],0
	les bx,[bp-4]
	db 66h
	cmp word ptr es:[bx],0
	jz short rwks_copy
	cmp si,-1
	jnz short rwks_cached
	test byte ptr es:[bx+4],2
	jz short rwks_skip
rwks_cached:
	push dword ptr [bp+8]
	push dword ptr [bp-8]
	push word ptr [bp+4]
	push es
	push bx
	call RegWriteKeyBlock
	or ax,ax
	jnz rwks_error
rwks_skip:
	jmp short rwks_advance
rwks_copy:
	mov di,si
	cmp di,-1
	jz short rwks_advance
	push dword ptr [bp+8]
	push dword ptr [bp-8]
	lea cx,[bp-0Eh]
	push ss
	push cx
	lea dx,[bp-12h]
	push ss
	push dx
	call RegKeyBlockExtent
	push di
	push dword ptr [bp-12h]
	push word ptr [bp+4]
	push dword ptr [bp-12h]
	push 0
	push word ptr [bp-0Eh]
	call RegCopyFileRange
	or ax,ax
	jnz rwks_error
rwks_advance:
	add byte ptr [bp-0Bh],4
	add word ptr [bp-4],6
	inc word ptr [bp-0Ah]
	mov ax,[bp-0Ah]
	les bx,[bp+8]
	cmp es:[bx+8],ax
	ja rwks_next
rwks_success:
	xor ax,ax
rwks_done:
	pop si
	pop di
	leave
	ret 8
RegWriteKeyBlocks endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCommitKeyCache
RegCommitKeyCache proc near
	enter 4,0
	push di
	mov di,[bp+4]
	mov es,word ptr [bp+6]
	and byte ptr es:[di+56h],0FDh
	db 66h
	mov ax,es:[di+0Ch]
	db 66h
	mov es:[di+3Ah],ax
	mov cx,es:[di+8]
	mov ax,es:[di+4]
	mov dx,es:[di+6]
	mov bx,ax
	mov [bp-2],dx
	cmp word ptr es:[di+8],0
	jz short rck_done
	mov es,word ptr [bp-2]
rck_next:
	and byte ptr es:[bx+4],0FDh
	add bx,6
	loop rck_next
rck_done:
	pop di
	leave
	ret 4
RegCommitKeyCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegTrimKeyCache
RegTrimKeyCache proc near
	enter 4,0
	push di
	push si
	mov cx,[bp+4]
	mov bx,cx
	mov es,word ptr [bp+6]
	mov di,es:[bx+8]
	mov ax,es:[bx+4]
	mov dx,es:[bx+6]
	mov si,ax
	mov [bp-2],dx
	cmp word ptr es:[bx+8],0
	jz short rtk_done
rtk_next:
	mov es,word ptr [bp-2]
	db 66h
	cmp word ptr es:[si],0
	jz short rtk_advance
	test byte ptr es:[si+4],3
	jnz short rtk_clear
	cmp byte ptr es:[si+5],0
	jnz short rtk_clear
	db 66h
	push word ptr es:[si]
	call RegDosFree
	mov es,word ptr [bp-2]
	db 66h
	mov word ptr es:[si],0
	dw 0
rtk_clear:
	mov es,word ptr [bp-2]
	and byte ptr es:[si+4],0FEh
rtk_advance:
	add si,6
	dec di
	jnz short rtk_next
rtk_done:
	pop si
	pop di
	leave
	ret 4
RegTrimKeyCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegInitKeyCache
RegInitKeyCache proc near
	enter 8,0
	push di
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	mov al,es:[si+56h]
	and ax,8
	cmp ax,1
	sbb ax,ax
	and ax,3000h
	add ah,40h
	sub dx,dx
	push dx
	push ax
	add ax,es:[si+3Ah]
	adc dx,es:[si+3Ch]
	sub ax,1
	sbb dx,0
	push dx
	push ax
	call __aFuldiv
	mov [bp-6],ax
	mov di,ax
	add di,4
	imul ax,di,6
	mov [bp-8],ax
	push ax
	call RegAllocate
	mov [bp-4],ax
	mov [bp-2],dx
	or dx,ax
	jnz short rikc_init
	mov ax,0Eh
	jmp short rikc_done
rikc_init:
	push word ptr [bp-2]
	push ax
	push word ptr [bp-8]
	call RegZeroMemory
	mov eax,[bp-4]
	mov es,word ptr [bp+6]
	db 66h
	mov es:[si+4],ax
	mov ax,[bp-6]
	mov es:[si+8],ax
	mov es:[si+0Ah],di
	and byte ptr es:[si+46h],0F8h
	test byte ptr es:[si+56h],8
	jnz short rikc_size
	mov es,word ptr [bp+6]
	db 66h
	push word ptr es:[si+3Eh]
	call RegKeyOffsetToIndex
	mov es,word ptr [bp+6]
	mov es:[si+3Eh],ax
	mov es:[si+40h],dx
	db 66h
	push word ptr es:[si+42h]
	call RegKeyOffsetToIndex
	mov es,word ptr [bp+6]
	mov es:[si+42h],ax
	mov es:[si+44h],dx
rikc_size:
	mov es,word ptr [bp+6]
	db 66h
	mov ax,es:[si+3Ah]
	db 66h
	mov es:[si+0Ch],ax
	xor ax,ax
rikc_done:
	pop si
	pop di
	leave
	ret 4
RegInitKeyCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegNewDataBlock
RegNewDataBlock proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	push word ptr es:[si+8]
	call RegAllocate
	mov es,word ptr [bp+6]
	mov es:[si],ax
	mov es:[si+2],dx
	mov ax,dx
	or ax,es:[si]
	jz short radc_error
	push 1FEh
	call RegAllocate
	mov es,word ptr [bp+6]
	mov es:[si+4],ax
	mov es:[si+6],dx
	mov ax,dx
	or ax,es:[si+4]
	jz short radc_release
	xor ax,ax
	jmp short radc_done
radc_release:
	push word ptr [bp+6]
	push si
	call RegFreeDataBlock
radc_error:
	mov ax,0Eh
radc_done:
	pop si
	leave
	ret 4
RegNewDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFreeDataBlock
RegFreeDataBlock proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	db 66h
	cmp word ptr es:[si],0
	jz short rrdb_second
	db 66h
	push word ptr es:[si]
	call RegDosFree
	mov es,word ptr [bp+6]
	db 66h
	mov word ptr es:[si],0
	dw 0
rrdb_second:
	mov es,word ptr [bp+6]
	db 66h
	cmp word ptr es:[si+4],0
	jz short rrdb_done
	db 66h
	push word ptr es:[si+4]
	call RegDosFree
	mov es,word ptr [bp+6]
	db 66h
	mov word ptr es:[si+4],0
	dw 0
rrdb_done:
	pop si
	leave
	ret 4
RegFreeDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegIndexBlock
RegIndexBlock proc near
	enter 10h,0
	push di
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	db 66h
	push word ptr es:[si+4]
	push 1FEh
	call RegZeroMemory
	mov es,word ptr [bp+6]
	db 66h
	mov ax,es:[si]
	mov [bp-10h],eax
	mov word ptr [bp-0Ah],20h
	mov di,es:[si+8]
	sub di,20h
	jz short ridc_success
	mov [bp-0Ch],di
	mov di,[bp-0Ah]
	mov cx,[bp-0Ch]
ridc_next:
	les si,[bp-10h]
	add si,di
	mov bx,si
	mov [bp-6],es
	mov ax,es:[si+4]
	mov dx,es:[si+6]
	mov [bp-4],ax
	db 66h
	cmp word ptr es:[si],0
	jz short ridc_error
	sub ax,ax
	cmp es:[bx+2],ax
	ja short ridc_error
	jb short ridc_number
	cmp es:[bx],cx
	ja short ridc_error
ridc_number:
	cmp word ptr [bp-4],-1
	jnz short ridc_limit
	cmp dx,-1
	jz short ridc_free
ridc_limit:
	cmp word ptr [bp-4],0FFh
	jae short ridc_error
ridc_free:
	cmp word ptr [bp-4],-1
	jnz short ridc_store
	cmp dx,-1
	jz short ridc_advance
ridc_store:
	mov ax,[bp-4]
	add ax,ax
	les si,[bp+4]
	les si,es:[si+4]
	add si,ax
	mov es:[si],di
ridc_advance:
	mov es,word ptr [bp-6]
	mov ax,es:[bx]
	add di,ax
	sub cx,ax
	jnz short ridc_next
	jmp short ridc_success
ridc_error:
	mov ax,3F1h
	jmp short ridc_done
ridc_success:
	xor ax,ax
ridc_done:
	pop si
	pop di
	leave
	ret 4
RegIndexBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegLoadDataBlock
RegLoadDataBlock proc near
	enter	8,0
	push	di
	push	si
	mov	bx,[bp+4]
	mov	word ptr [bp-4],0ffffh
	les	si,dword ptr [bp+6]
	cmp	es:[si+26h],bx
	ja	short rldc_entry
	mov	ax,3f1h
	jmp	near ptr rldc_done
rldc_entry:
	imul	ax,bx,DataBlockSize
	mov	di,si
	les	di,dword ptr es:[di+10h]
	add	di,ax
	mov	si,di
	mov	word ptr [bp-6],es
	test	byte ptr es:[di+12h],1
	jnz	near ptr rldc_pin
	test	byte ptr es:[si+12h],1
	jnz	near ptr rldc_pin
	push	es
	push	di
	call	RegNewDataBlock
	mov	[bp-2],ax
	or	ax,ax
	jnz	short rldc_error
	mov	eax,[bp+6]
	add	ax,58h
	push	eax
	push	0
	call	RegDosOpen
	mov	[bp-4],ax
	inc	ax
	jz	short rldc_ioerror
	push	word ptr [bp-4]
	mov	es,word ptr [bp-6]
	db 66h
	push	word ptr es:[si+0eh]
	call	RegDosSeek
	or	ax,ax
	jz	short rldc_ioerror
	push	word ptr [bp-4]
	mov	es,word ptr [bp-6]
	db 66h
	push	word ptr es:[si]
	push	word ptr es:[si+8]
	call	RegDosRead
	or	ax,ax
	jz	short rldc_ioerror
	mov	es,word ptr [bp-6]
	db 66h
	push	word ptr es:[si]
	call	RegValidateDataBlock
	or	ax,ax
	jnz	short rldc_index
	mov	word ptr [bp-2],3f1h
	jmp	short rldc_error
rldc_index:
	push	word ptr [bp-6]
	push	si
	call	RegIndexBlock
	mov	[bp-2],ax
	or	ax,ax
	jnz	short rldc_error
	push	word ptr [bp-4]
	call	RegDosClose
	mov	es,word ptr [bp-6]
	mov	al,es:[si+12h]
	and	al,1
	cmp	al,1
	jz	short rldc_pin
	or	byte ptr es:[si+12h],1
	jmp	short rldc_pin
rldc_ioerror:
	mov	word ptr [bp-2],3F8h
rldc_error:
	cmp	word ptr [bp-4],-1
	jz	short rldc_release
	push	word ptr [bp-4]
	call	RegDosClose
rldc_release:
	push	word ptr [bp-6]
	push	si
	call	RegFreeDataBlock
	mov	ax,[bp-2]
	jmp	short rldc_done
rldc_pin:
	mov	es,word ptr [bp-6]
	mov	al,es:[si+12h]
	and	al,2
	cmp	al,2
	jz	short rldc_pinned
	or	byte ptr es:[si+12h],2
rldc_pinned:
	mov	es,word ptr [bp-6]
	db 66h
	inc	word ptr es:[si+DataBlockLocks]
	xor	ax,ax
rldc_done:
	pop	si
	pop	di
	leave
	ret	6
RegLoadDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegUnlockDataCache
RegUnlockDataCache proc near
	enter	4,0
	push	di
	push	si
	mov	bx,[bp+8]
	mov	es,word ptr [bp+0ah]
	mov	ax,es:[bx+10h]
	mov	dx,es:[bx+12h]
	imul	cx,[bp+6],DataBlockSize
	add	ax,cx
	mov	di,ax
	mov	[bp-2],dx
	mov	si,ax
	mov	es,dx
	db 66h
	dec	word ptr es:[si+DataBlockLocks]
	cmp	word ptr [bp+4],0
	jz	short rudc_done
	mov	es,word ptr [bp-2]
	or	byte ptr es:[di+12h],4
	mov	es,word ptr [bp+0ah]
	or	byte ptr es:[bx+56h],1
rudc_done:
	pop	si
	pop	di
	leave
	ret	8
RegUnlockDataCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegFetchDataRecord
RegFetchDataRecord proc near
	enter 8,0
	push di
	push si
	push dword ptr [bp+0Ch]
	push word ptr [bp+0Ah]
	call RegLoadDataBlock
	mov di,ax
	mov [bp-2],ax
	or di,ax
	jnz short rfdr_done
	mov al,[bp+8]
	sub ah,ah
	add ax,ax
	mov [bp-8],ax
	imul cx,[bp+0Ah],DataBlockSize
	les bx,[bp+0Ch]
	les bx,es:[bx+10h]
	add bx,cx
	mov si,bx
	mov [bp-4],es
	les bx,es:[bx+4]
	add bx,ax
	cmp word ptr es:[bx],0
	jnz short rfdr_found
	push dword ptr [bp+0Ch]
	push word ptr [bp+0Ah]
	push 0
	call RegUnlockDataCache
	mov di,3F1h
	mov [bp-2],di
	jmp short rfdr_done
rfdr_found:
	mov [bp-2],di
	mov es,word ptr [bp-4]
	mov ax,es
	les bx,es:[si+4]
	mov di,[bp-8]
	mov cx,es:[bx+di]
	mov es,ax
	add cx,es:[si]
	mov ax,es:[si+2]
	les bx,[bp+4]
	mov es:[bx],cx
	mov es:[bx+2],ax
rfdr_done:
	mov ax,[bp-2]
	pop si
	pop di
	leave
	ret 0Ch
RegFetchDataRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegPackDataBlock
RegPackDataBlock proc near
	enter 18h,0
	push di
	push si
	mov cx,[bp+4]
	mov es,word ptr [bp+6]
	mov si,cx
	les si,es:[si]
	mov bx,si
	mov [bp-0Ah],es
	db 66h
	cmp word ptr es:[si+10h],-1
	jnz short rcdc_check
rcdc_none:
	xor ax,ax
	jmp rcdc_done
rcdc_check:
	mov ax,es:[bx+10h]
	mov dx,ax
	add ax,si
	mov di,ax
	mov [bp-2],es
	mov [bp-0Ch],si
	mov si,ax
	add dx,es:[si]
	mov si,cx
	mov es,word ptr [bp+6]
	cmp dx,es:[si+8]
	jb short rcdc_begin
	mov es,word ptr [bp-2]
	db 66h
	cmp word ptr es:[di+8],-1
	jz short rcdc_none
rcdc_begin:
	sub eax,eax
	mov [bp-14h],eax
	mov [bp-10h],eax
	mov bx,20h
	mov es,word ptr [bp+6]
	mov ax,es:[si+8]
	mov [bp-8],ax
	mov cx,ax
rcdc_scan:
	cmp cx,bx
	jbe rcdc_tail
	jmp short rcdc_locate
rcdc_test_free:
	mov es,word ptr [bp-2]
	db 66h
	cmp word ptr es:[di+4],-1
	jz short rcdc_free
	add bx,es:[di]
rcdc_locate:
	mov ax,[bp-0Ch]
	mov dx,[bp-0Ah]
	add ax,bx
	mov di,ax
	mov [bp-2],dx
	cmp cx,bx
	ja short rcdc_test_free
rcdc_free:
	mov [bp-4],ax
	mov [bp-6],bx
	mov si,[bp-14h]
	mov ax,[bp-12h]
	or ax,si
	jz short rcdc_destination
	push dword ptr [bp-10h]
	push word ptr [bp-12h]
	push si
	mov ax,si
	sub ax,[bp-4]
	neg ax
	push ax
	mov di,ax
	call RegMoveMemory
	add [bp-10h],di
rcdc_destination:
	cmp dword ptr [bp-10h],0
	jnz short rcdc_search
	mov eax,[bp-4]
	mov [bp-10h],eax
rcdc_search:
	mov ax,[bp-6]
	cmp [bp-8],ax
	jbe short rcdc_resume
	mov bx,ax
	mov cx,[bp-8]
rcdc_skip_free:
	les si,[bp-0Ch]
	add si,bx
	mov di,si
	mov [bp-2],es
	db 66h
	cmp word ptr es:[si+4],-1
	jnz short rcdc_found
	add bx,es:[di]
	cmp bx,cx
	jb short rcdc_skip_free
	jmp rcdc_scan
rcdc_resume:
	mov cx,[bp-8]
rcdc_resume_bx:
	mov bx,[bp-6]
	jmp rcdc_scan
rcdc_found:
	mov [bp-6],bx
	mov ax,[bp-2]
	mov [bp-14h],si
	mov [bp-12h],ax
	jmp short rcdc_resume_bx
rcdc_tail:
	mov di,[bp-10h]
	mov cx,[bp-0Eh]
	mov [bp-18h],di
	mov [bp-16h],cx
	sub di,[bp-0Ch]
	sbb cx,cx
	les bx,[bp-0Ch]
	mov es:[bx+10h],di
	mov es:[bx+12h],cx
	mov bx,[bp+4]
	mov es,word ptr [bp+6]
	mov ax,es:[bx+0Ah]
	mov cx,es
	les si,[bp-18h]
	mov es:[si],ax
	mov word ptr es:[si+2],0
	mov eax,-1
	db 66h
	mov es:[si+4],ax
	mov es:[si+8],ax
	mov es:[si+0Ah],ax
	push cx
	push bx
	call RegIndexBlock
	mov ax,1
rcdc_done:
	pop si
	pop di
	leave
	ret 4
RegPackDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegAppendDataBlock
RegAppendDataBlock proc near
	enter 0Ah,0
	push di
	push si
	mov si,[bp+6]
	mov es,word ptr [bp+8]
	mov di,es:[si+26h]
	cmp di,0FFFEh
	jb short rcdb_room
rcdb_error:
	mov ax,0Eh
	jmp rcdb_done
rcdb_room:
	mov [bp-0Ah],di
	cmp es:[si+14h],di
	ja short rcdb_entry
	db 66h
	push word ptr es:[si+10h]
	lea ax,[di+4]
	imul ax,ax,DataBlockSize
	push ax
	call RegReallocRetry
	mov [bp-8],ax
	mov [bp-6],dx
	or dx,ax
	jz short rcdb_error
	mov [bp-0Ah],di
	mov dx,[bp-6]
	mov es,word ptr [bp+8]
	mov es:[si+10h],ax
	mov es:[si+12h],dx
	add word ptr es:[si+14h],4
rcdb_entry:
	mov es,word ptr [bp+8]
	mov ax,es:[si+10h]
	mov dx,es:[si+12h]
	imul cx,[bp-0Ah],DataBlockSize
	add ax,cx
	mov di,ax
	mov [bp-6],dx
	mov es,dx
	mov bx,ax
	mov ax,[bp+4]
	add ax,101Fh
	and ax,0F000h
	mov [bp+4],ax
	mov es:[bx+8],ax
	push word ptr [bp-6]
	push di
	call RegNewDataBlock
	or ax,ax
	jnz short rcdb_error
	mov [bp-8],di
	mov ax,[bp+4]
	sub ax,20h
	les bx,[bp-8]
	mov es:[bx+0Ah],ax
	db 66h
	mov word ptr es:[bx+0Ch],0
	dw 0FFFFh
	mov word ptr es:[bx+10h],-1
	mov byte ptr es:[bx+12h],7
	db 66h
	mov word ptr es:[bx+DataBlockLocks],1
	dw 0
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	mov si,ax
	mov [bp-2],dx
	mov bx,ax
	mov es,dx
	db 66h
	mov word ptr es:[bx],4752h
	dw 4244h
	mov ax,[bp+4]
	mov es,word ptr [bp-2]
	mov es:[si+4],ax
	mov word ptr es:[si+6],0
	mov ax,es
	les bx,[bp-8]
	mov cx,es:[bx+0Ah]
	mov es,ax
	mov es:[si+8],cx
	db 66h
	mov word ptr es:[si+0Ah],0
	dw 8
	mov cx,[bp-0Ah]
	mov es:[si+0Eh],cx
	db 66h
	mov word ptr es:[si+10h],20h
	dw 0
	mov word ptr es:[si+14h],0
	les bx,[bp-8]
	mov cx,es:[bx+0Ah]
	mov es,ax
	mov es:[si+20h],cx
	mov word ptr es:[si+22h],0
	mov eax,-1
	lea bx,[si+20h]
	db 66h
	mov es:[bx+4],ax
	mov es:[bx+8],ax
	mov es:[bx+0Ah],ax
	les bx,[bp+6]
	inc word ptr es:[bx+26h]
	or word ptr es:[bx+28h],1
	or word ptr es:[bx+56h],5
	push dword ptr [bp-8]
	call RegIndexBlock
rcdb_done:
	pop si
	pop di
	leave
	ret 6
RegAppendDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegGrowDataBlock
RegGrowDataBlock proc near
	enter 10h,0
	push di
	push si
	mov ax,[bp+4]
	imul cx,[bp+6],DataBlockSize
	les bx,[bp+8]
	les bx,es:[bx+10h]
	add bx,cx
	mov si,bx
	mov [bp-2],es
	cmp es:[bx+0Ah],ax
	jae rgdc_success
	mov bx,ax
	mov ax,es:[si+8]
	sub ax,es:[si+0Ah]
	add ax,bx
	add ax,0FFFh
	and ax,0F000h
	sub dx,dx
	mov [bp-0Ch],ax
	cmp ax,0F000h
	jbe short rgdc_resize
rgdc_error:
	mov ax,0Eh
	jmp rgdc_done
rgdc_resize:
	db 66h
	push word ptr es:[si]
	push ax
	call RegReallocRetry
	mov di,ax
	mov [bp-0Eh],dx
	or dx,ax
	jz short rgdc_error
	mov ax,[bp-0Eh]
	mov es,word ptr [bp-2]
	mov es:[si],di
	mov es:[si+2],ax
	push es
	push si
	call RegPackDataBlock
	mov es,word ptr [bp-0Eh]
	db 66h
	cmp word ptr es:[di+10h],-1
	jnz short rgdc_existing
	mov ax,es
	mov es,word ptr [bp-2]
	mov dx,es:[si+8]
	sub bx,bx
	mov es,ax
	mov es:[di+10h],dx
	mov es:[di+12h],bx
	add dx,di
	mov cx,dx
	mov bx,dx
	mov [bp-6],es
	db 66h
	mov word ptr es:[bx+4],-1
	dw -1
	mov es,word ptr [bp-6]
	db 66h
	mov word ptr es:[bx+8],-1
	dw -1
	jmp short rgdc_tail
rgdc_existing:
	mov ax,es:[di+10h]
	add ax,di
	mov cx,ax
	mov [bp-6],es
rgdc_tail:
	mov ax,[bp-0Ch]
	mov es,word ptr [bp-2]
	sub ax,es:[si+8]
	add es:[si+0Ah],ax
	mov ax,es:[si+0Ah]
	mov bx,cx
	mov es,word ptr [bp-6]
	mov es:[bx],ax
	mov word ptr es:[bx+2],0
	mov ax,[bp-0Ch]
	mov es,word ptr [bp-2]
	mov es:[si+8],ax
	or byte ptr es:[si+12h],0Ch
	les bx,[bp+8]
	or byte ptr es:[bx+56h],5
rgdc_success:
	xor ax,ax
rgdc_done:
	pop si
	pop di
	leave
	ret 8
RegGrowDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegTakeDataExtent
RegTakeDataExtent proc near
	enter 0Eh,0
	push di
	push si
	mov ax,[bp+8]
	imul cx,[bp+0Ah],DataBlockSize
	les bx,[bp+0Ch]
	les bx,es:[bx+10h]
	add bx,cx
	mov si,bx
	mov [bp-2],es
	cmp es:[bx+0Ah],ax
	jae short rtde_compact
rtde_error:
	mov ax,0Eh
	jmp rtde_done
rtde_compact:
	mov di,ax
	push es
	push bx
	call RegPackDataBlock
	mov es,word ptr [bp-2]
	db 66h
	mov ax,es:[si]
	mov dx,es:[si+2]
	mov [bp-8],eax
	mov bx,ax
	mov es,dx
	add ax,es:[bx+10h]
	mov [bp-0Eh],ax
	mov bx,ax
	mov [bp-0Ch],dx
	mov ax,es:[bx]
	cmp ax,di
	jb short rtde_error
	mov [bp-4],si
	mov bx,ax
	sub bx,di
	cmp bx,22h
	jb short rtde_whole
	sub ax,ax
	mov si,[bp-8]
	add es:[si+10h],di
	adc es:[si+12h],ax
	mov cx,[bp-0Eh]
	mov si,cx
	mov es,word ptr [bp-0Ch]
	mov es:[si],di
	mov es:[si+2],ax
	db 66h
	mov ax,es:[si+8]
	add si,di
	db 66h
	mov es:[si+8],ax
	db 66h
	mov word ptr es:[si+4],-1
	dw -1
	mov es:[si],bx
	mov word ptr es:[si+2],0
	jmp short rtde_finish
rtde_whole:
	mov di,ax
	mov cx,[bp-0Eh]
	mov bx,cx
	mov es,word ptr [bp-0Ch]
	db 66h
	mov ax,es:[bx+8]
	les bx,[bp-8]
	db 66h
	mov es:[bx+10h],ax
rtde_finish:
	les bx,[bp-4]
	sub es:[bx+0Ah],di
	mov ax,[bp-0Ch]
	les bx,[bp+4]
	mov es:[bx],cx
	mov es:[bx+2],ax
	xor ax,ax
rtde_done:
	pop si
	pop di
	leave
	ret 0Ch
RegTakeDataExtent endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegNextDataIndex
RegNextDataIndex proc near
	enter 0Ch,0
	push di
	push si
	mov bx,[bp+4]
	mov es,word ptr [bp+6]
	mov ax,es:[bx]
	mov dx,es:[bx+2]
	mov di,ax
	mov [bp-6],dx
	mov cx,es:[bx+0Ch]
	mov [bp-0Ah],cx
	mov si,cx
	lea cx,[si+1]
	mov es,dx
	mov dx,si
	mov si,ax
	cmp es:[si+14h],dx
	jae short rndi_find
	mov es:[di+14h],dx
	jmp short rndi_save
rndi_find:
	mov es,word ptr [bp+6]
	db 66h
	mov ax,es:[bx+4]
	mov si,cx
	add si,cx
	add ax,si
	mov [bp-4],eax
	mov es,word ptr [bp-6]
	mov ax,es:[di+14h]
	mov [bp-0Ch],ax
	cmp ax,cx
	jb short rndi_save
	mov bx,[bp-4]
rndi_next:
	mov es,word ptr [bp-2]
	cmp word ptr es:[bx],0
	jz short rndi_save
	inc bx
	inc bx
	inc cx
	cmp [bp-0Ch],cx
	jae short rndi_next
rndi_save:
	les bx,[bp+4]
	mov es:[bx+0Ch],cx
	mov ax,[bp-0Ah]
	pop si
	pop di
	leave
	ret 4
RegNextDataIndex endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegAllocateDataRecord
RegAllocateDataRecord proc near
	enter 8,0
	push di
	push si
	mov bx,[bp+0Ah]
	mov es,word ptr [bp+0Ch]
	cmp word ptr es:[bx+26h],0
	jz radr_create
	mov word ptr [bp-8],0
radr_pass:
	mov es,word ptr [bp+0Ch]
	mov si,es:[bx+26h]
	imul ax,si,DataBlockSize
	add ax,es:[bx+10h]
	mov dx,es:[bx+12h]
	mov [bp-6],ax
	mov [bp-4],dx
	mov di,ax
radr_next:
	mov ax,si
	dec si
	or ax,ax
	jz radr_retry
	sub di,DataBlockSize
	mov es,word ptr [bp-4]
	cmp word ptr es:[di+0Ch],0FFh
	jae short radr_next
	cmp word ptr [bp-8],0
	jz short radr_free
	mov ax,es:[di+8]
	sub ax,es:[di+0Ah]
	sub dx,dx
	add ax,[bp+8]
	adc dx,dx
	or dx,dx
	jnz short radr_next
	cmp ax,0F000h
	jbe short radr_load
	jmp short radr_next
radr_free:
	mov ax,[bp+8]
	cmp es:[di+0Ah],ax
	jb short radr_next
radr_load:
	push dword ptr [bp+0Ah]
	push si
	call RegLoadDataBlock
	or ax,ax
	jnz short radr_next
	cmp [bp-8],ax
	jz short radr_take
	push dword ptr [bp+0Ah]
	push si
	push word ptr [bp+8]
	call RegGrowDataBlock
	or ax,ax
	jnz short radr_release
radr_take:
	mov [bp-6],di
	push dword ptr [bp+0Ah]
	push si
	push dword ptr [bp+6]
	push word ptr [bp+4]
	call RegTakeDataExtent
	or ax,ax
	jz short radr_index
radr_release:
	push dword ptr [bp+0Ah]
	push si
	push 0
	call RegUnlockDataCache
	jmp radr_next
radr_index:
	mov di,si
radr_index_entry:
	push dword ptr [bp-6]
	call RegNextDataIndex
	mov si,ax
	les bx,[bp+4]
	les bx,es:[bx]
	mov es:[bx+4],ax
	mov es:[bx+6],di
	les bx,[bp+4]
	mov ax,es:[bx]
	les bx,[bp-6]
	sub ax,es:[bx]
	les bx,es:[bx+4]
	add si,si
	mov es:[bx+si],ax
	xor ax,ax
	jmp short radr_done
radr_retry:
	cmp word ptr [bp-8],0
	jnz short radr_create
	mov word ptr [bp-8],1
	mov bx,[bp+0Ah]
	jmp radr_pass
radr_create:
	push dword ptr [bp+0Ah]
	push word ptr [bp+8]
	call RegAppendDataBlock
	or ax,ax
	jnz short radr_error
	les bx,[bp+0Ah]
	mov ax,es:[bx+26h]
	dec ax
	mov di,ax
	imul ax,ax,DataBlockSize
	add ax,es:[bx+10h]
	mov dx,es:[bx+12h]
	mov [bp-6],ax
	mov [bp-4],dx
	push es
	push bx
	push di
	push dword ptr [bp+6]
	push word ptr [bp+4]
	call RegTakeDataExtent
	or ax,ax
	jz short radr_index_entry
	push dword ptr [bp+0Ah]
	push di
	push 0
	call RegUnlockDataCache
radr_error:
	mov ax,0Eh
radr_done:
	pop si
	pop di
	leave
	ret 0Ah
RegAllocateDataRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Expand a record into the following free extent when it is large enough.
	public RegWriteDataBlock
RegWriteDataBlock proc near
	enter 0Eh,0
	push di
	push si
	mov bx,[bp+8]
	mov es,word ptr [bp+0Ah]
	mov ax,es:[bx+10h]
	mov dx,es:[bx+12h]
	mov si,ax
	mov [bp-0Ah],dx
	db 66h
	mov ax,es:[bx+1Eh]
	mov [bp-8],eax
	mov word ptr [bp-0Eh],0
	cmp word ptr es:[bx+26h],0
	jz rwdb_success
rwdb_next:
	mov es,word ptr [bp-0Ah]
	test byte ptr es:[si+12h],1
	jz short rwdb_copy
	cmp word ptr [bp+6],-1
	jnz short rwdb_cached
	test byte ptr es:[si+12h],4
	jz rwdb_advance
rwdb_cached:
	mov di,[bp+4]
	db 66h
	mov ax,es:[si]
	mov dx,es:[si+2]
	mov [bp-4],eax
	mov cx,es:[si+8]
	mov bx,ax
	mov es,dx
	mov es:[bx+4],cx
	mov word ptr es:[bx+6],0
	mov es,word ptr [bp-0Ah]
	mov ax,es:[si+0Ah]
	les bx,[bp-4]
	mov es:[bx+8],ax
	mov word ptr es:[bx+0Ah],0
	mov es,word ptr [bp-0Ah]
	mov ax,es:[si+0Ch]
	les bx,[bp-4]
	mov es:[bx+16h],ax
	and byte ptr es:[bx+0Ch],0FBh
	push di
	push dword ptr [bp-8]
	call RegDosSeek
	or ax,ax
	jz short rwdb_error
	push di
	push dword ptr [bp-4]
	mov es,word ptr [bp-0Ah]
	push word ptr es:[si+8]
	call RegDosWrite
	or ax,ax
	jnz short rwdb_advance
rwdb_error:
	mov ax,3F8h
	jmp short rwdb_done
rwdb_copy:
	cmp word ptr [bp+6],-1
	jz short rwdb_advance
	push word ptr [bp+6]
	db 66h
	push word ptr es:[si+0Eh]
	push word ptr [bp+4]
	push dword ptr [bp-8]
	push 0
	push word ptr es:[si+8]
	call RegCopyFileRange
	or ax,ax
	jnz short rwdb_error
rwdb_advance:
	mov es,word ptr [bp-0Ah]
	mov ax,es:[si+8]
	sub dx,dx
	add [bp-8],ax
	adc [bp-6],dx
	add si,DataBlockSize
	inc word ptr [bp-0Eh]
	mov ax,[bp-0Eh]
	les bx,[bp+8]
	cmp es:[bx+26h],ax
	ja rwdb_next
rwdb_success:
	xor ax,ax
rwdb_done:
	pop si
	pop di
	leave
	ret 8
RegWriteDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCommitDataCache
RegCommitDataCache proc near
	enter 8,0
	push di
	mov di,[bp+4]
	mov es,word ptr [bp+6]
	mov ax,es:[di+10h]
	mov dx,es:[di+12h]
	mov bx,ax
	mov [bp-6],dx
	db 66h
	mov ax,es:[di+1Eh]
	mov [bp-4],eax
	xor cx,cx
	cmp es:[di+26h],cx
	jz short rcd_done
rcd_next:
	mov es,word ptr [bp-6]
	and byte ptr es:[bx+12h],0FBh
	mov eax,[bp-4]
	db 66h
	mov es:[bx+0Eh],ax
	mov ax,es:[bx+8]
	sub dx,dx
	add [bp-4],ax
	adc [bp-2],dx
	add bx,DataBlockSize
	inc cx
	mov es,word ptr [bp+6]
	cmp es:[di+26h],cx
	ja short rcd_next
rcd_done:
	pop di
	leave
	ret 4
RegCommitDataCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegScanDataBlocks
RegScanDataBlocks proc near
	enter 4,0
	push di
	push si
	mov cx,[bp+4]
	mov bx,cx
	mov es,word ptr [bp+6]
	mov di,es:[bx+26h]
	mov ax,es:[bx+10h]
	mov dx,es:[bx+12h]
	mov si,ax
	mov [bp-2],dx
	cmp word ptr es:[bx+26h],0
	jz short rtd_done
rtd_next:
	mov es,word ptr [bp-2]
	mov al,es:[si+12h]
	and al,7
	dec al
	jnz short rtd_clear
	db 66h
	cmp word ptr es:[si+DataBlockLocks],0
	jnz short rtd_clear
	push es
	push si
	call RegFreeDataBlock
	mov es,word ptr [bp-2]
	mov byte ptr es:[si+12h],0
rtd_clear:
	mov es,word ptr [bp-2]
	and byte ptr es:[si+12h],0FDh
	add si,DataBlockSize
	dec di
	jnz short rtd_next
rtd_done:
	pop si
	pop di
	leave
	ret 4
RegScanDataBlocks endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegValidateDataBlock
RegValidateDataBlock proc near
	push bp
	mov bp,sp
	push si
	mov si,[bp+4]
	mov es,word ptr [bp+6]
	db 66h
	cmp word ptr es:[si],4752h
	dw 4244h
	jnz short rcdh_bad
	cmp word ptr es:[si+6],0
	jnz short rcdh_bad
	mov ax,1
	jmp short rcdh_done
rcdh_bad:
	xor ax,ax
rcdh_done:
	pop si
	leave
	ret 4
RegValidateDataBlock endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegInitDataCache
RegInitDataCache proc near
	enter 2Ch,0
	push di
	push si
	mov di,[bp+6]
	mov es,word ptr [bp+8]
	mov si,es:[di+26h]
	lea ax,[si+4]
	imul ax,ax,DataBlockSize
	push ax
	call RegAllocate
	mov [bp-8],ax
	mov [bp-6],dx
	or dx,ax
	jnz short rid_init
	mov ax,0Eh
	jmp rid_done
rid_init:
	push word ptr [bp-6]
	push ax
	imul ax,si,DataBlockSize
	push ax
	call RegZeroMemory
	mov eax,[bp-8]
	mov es,word ptr [bp+8]
	db 66h
	mov es:[di+10h],ax
	lea ax,[si+4]
	mov es:[di+14h],ax
	db 66h
	mov ax,es:[di+1Eh]
	mov [bp-4],eax
	mov word ptr [bp-0Ah],0
	or si,si
	jz short rid_success
	mov [bp-0Ch],si
	mov di,[bp+4]
	mov si,[bp-8]
rid_next:
	push di
	push dword ptr [bp-4]
	call RegDosSeek
	or ax,ax
	jz short rid_ioerror
	push di
	lea ax,[bp-2Ch]
	push ss
	push ax
	push 20h
	call RegDosRead
	or ax,ax
	jz short rid_ioerror
	lea ax,[bp-2Ch]
	push ss
	push ax
	call RegValidateDataBlock
	or ax,ax
	jz short rid_invalid
	mov eax,[bp-4]
	mov es,word ptr [bp-6]
	db 66h
	mov es:[si+0Eh],ax
	mov ax,[bp-28h]
	mov es:[si+8],ax
	mov ax,[bp-24h]
	mov es:[si+0Ah],ax
	mov ax,[bp-16h]
	mov es:[si+0Ch],ax
	mov ax,es:[si+8]
	sub dx,dx
	add [bp-4],ax
	adc [bp-2],dx
	add si,DataBlockSize
	mov ax,[bp-0Ch]
	inc word ptr [bp-0Ah]
	cmp [bp-0Ah],ax
	jb short rid_next
	jmp short rid_success
rid_ioerror:
	mov ax,3F8h
	jmp short rid_done
rid_invalid:
	mov ax,3F1h
	jmp short rid_done
rid_success:
	xor ax,ax
rid_done:
	pop si
	pop di
	leave
	ret 6
RegInitDataCache endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegNameChecksum
RegNameChecksum proc near
        enter 4,0
        push si
        mov si,[bp+4]
        mov dword ptr [bp-4],0
        or si,si
        jz short rncs_done
rncs_next:
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov cl,es:[bx]
        sub ch,ch
        cmp cx,80h
        jae short rncs_advance
        cmp cx,'a'
        jb short rncs_plain
        cmp cx,'z'
        ja short rncs_plain
        mov ax,cx
        sub ax,20h
        sub dx,dx
        add [bp-4],ax
        adc [bp-2],dx
        jmp short rncs_advance
rncs_plain:
        sub ax,ax
        add [bp-4],cx
        adc [bp-2],ax
rncs_advance:
        dec si
        jnz short rncs_next
rncs_done:
        mov ax,[bp-4]
        mov dx,[bp-2]
        pop si
        leave
        ret 6
RegNameChecksum endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCompareName
RegCompareName proc near
        enter 4,0
        push di
        push si
        cmp word ptr [bp+4],0
        jz short rcn_equal
        mov si,[bp+0Ah]
        mov di,[bp+6]
rcnm_next:
        mov es,word ptr [bp+0Ch]
        cmp byte ptr es:[si],'a'
        jl short rcn_second_raw
        cmp byte ptr es:[si],'z'
        jg short rcn_second_raw
        mov al,es:[si]
        cbw
        sub ax,20h
        jmp short rcn_second_done
rcn_second_raw:
        mov al,es:[si]
        cbw
rcn_second_done:
        mov [bp-2],ax
        mov es,word ptr [bp+8]
        cmp byte ptr es:[di],'a'
        jl short rcn_first_raw
        cmp byte ptr es:[di],'z'
        jg short rcn_first_raw
        mov al,es:[di]
        cbw
        mov cx,ax
        sub cx,20h
        jmp short rcn_difference
rcn_first_raw:
        mov al,es:[di]
        cbw
        mov cx,ax
rcn_difference:
        sub cx,[bp-2]
        neg cx
        or cx,cx
        jnz short rcn_unequal
        inc si
        inc di
        dec word ptr [bp+4]
        jnz short rcnm_next
        jmp short rcn_equal
rcn_unequal:
        mov ax,cx
        jmp short rcn_exit
rcn_equal:
        xor ax,ax
rcn_exit:
        pop si
        pop di
        leave
        ret 10
RegCompareName endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegCopyFileRange
RegCopyFileRange proc near
	enter 6,0
	push di
	push si
	mov word ptr [bp-6],3F8h
	mov ax,word ptr RegTransferBuffer
	mov dx,word ptr RegTransferBuffer+2
	mov di,ax
	mov [bp-2],dx
	push dword ptr [bp+10h]
	push word ptr [bp+0Eh]
	call RegDosSeek
	or ax,ax
	jz short rcfr_done
	push dword ptr [bp+0Ah]
	push word ptr [bp+8]
	call RegDosSeek
	or ax,ax
	jz short rcfr_done
	cmp dword ptr [bp+4],0
	jz short rcfr_success
rcfr_next:
	push word ptr [bp+12h]
	push word ptr [bp-2]
	push di
	mov eax,[bp+4]
	cmp eax,7000h
	jbe short rcfr_count
	mov ax,7000h
rcfr_count:
	mov si,ax
	push ax
	call RegDosRead
	or ax,ax
	jz short rcfr_done
	push word ptr [bp+0Ch]
	push word ptr [bp-2]
	push di
	push si
	call RegDosWrite
	or ax,ax
	jz short rcfr_done
	sub ax,ax
	sub [bp+4],si
	sbb [bp+6],ax
	cmp dword ptr [bp+4],0
	jnz short rcfr_next
rcfr_success:
	mov word ptr [bp-6],0
rcfr_done:
	mov ax,[bp-6]
	pop si
	pop di
	leave
	ret 10h
RegCopyFileRange endp
	if ($ - RegistryCode) and 1
	db 0
	endif

; Enumerate a registry key through its cached chain of value records.
; Return the name length and remember the last key visited on the handle.
; Return the last occurrence of a character in an ASCIIZ path.
	public RegLastPathSeparator
RegLastPathSeparator proc near
	enter	4,0
	push	di
	push	si
	mov	si,[bp+6]
	mov	ax,[bp+8]
	mov	dx,ax
	mov	di,si
	mov	es,ax
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	dec	cx
	add	cx,si
	mov	ax,dx
	mov	[bp-4],cx
	mov	[bp-2],ax
	cmp	cx,si
	jnc	short rlps_scan
	mov	bx,cx
	mov	di,si
	jmp	short rlps_found
rlps_scan:
	mov	cx,[bp+4]
	mov	bx,[bp-4]
	mov	di,si
rlps_next:
	mov	es,word ptr [bp-2]
	cmp	es:[bx],cl
	jz	short rlps_found
	dec	bx
	mov	ax,bx
	cmp	ax,di
	jnc	short rlps_next
rlps_found:
	mov	ax,bx
	cmp	ax,di
	jc	short rlps_missing
	mov	dx,[bp-2]
	jmp	short rlps_done
rlps_missing:
	xor	ax,ax
	cwd
rlps_done:
	pop	si
	pop	di
	leave
	ret	6
RegLastPathSeparator endp
	if ($ - RegistryCode) and 1
	db 0
	endif

	public RegEnumValueRecord
RegEnumValueRecord proc near
	enter	16h,0
	push	di
	push	si
	mov	cx,[bp+0eh]
	mov	bx,[bp+10h]
	mov	es,word ptr [bp+12h]
	db 66h
	mov	ax,es:[bx+0ah]
	mov	dx,es:[bx+0ch]
	mov	[bp-0ch],eax
	mov	si,cx
	mov	word ptr [bp-2],1
	test	byte ptr es:[bx+4],10h
	jz	short rev_first_key
	mov	ah,es:[bx+5]
	and	ax,200h
	cmp	ax,1
	sbb	ax,ax
	neg	ax
	mov	dl,[bp+4]
	and	dx,4
	cmp	dx,1
	sbb	dx,dx
	neg	dx
	cmp	ax,dx
	jnz	short rev_first_key
	cmp	es:[bx+22h],cx
	ja	short rev_first_key
	sub	si,es:[bx+22h]
	db 66h
	mov	ax,es:[bx+24h]
	mov	dx,es:[bx+26h]
	mov	[bp-8],eax
	mov	[bp-0eh],si
	jmp	short rev_check_key
rev_first_key:
	mov	[bp-0eh],si
	mov	es,word ptr [bp+12h]
	db 66h
	mov	ax,es:[bx+12h]
	mov	dx,es:[bx+14h]
	mov	[bp-8],eax
rev_check_key:
	cmp	dx,0ffh
	ja	near ptr rev_no_value
	jc	short rev_next_key
	cmp	ax,0ffffh
	jnc	near ptr rev_no_value
rev_next_key:
	mov	word ptr [bp-2],0
	mov	si,[bp-0ch]
rev_fetch_key:
	push	word ptr [bp-0ah]
	push	si
	push	dword ptr [bp-8]
	lea	ax,[bp-12h]
	push	ss
	push	ax
	call	RegFetchKeyRecord
	mov	di,ax
	or	di,ax
	jnz	near ptr rev_load_error
	les	bx,dword ptr [bp-12h]
	test	word ptr es:[bx+2],400h
	jnz	short rev_key_filtered
	mov	ax,1
	jmp	short rev_key_class
rev_key_filtered:
	xor	ax,ax
rev_key_class:
	mov	cl,[bp+4]
	and	cx,4
	cmp	cx,1
	sbb	cx,cx
	neg	cx
	cmp	ax,cx
	jnz	short rev_follow_link
	cmp	word ptr [bp-0eh],0
	jnz	short rev_follow_link
	push	word ptr [bp-0ah]
	push	si
	push	word ptr es:[bx+0ch]
	mov	al,es:[bx+0bh]
	sub	ah,ah
	push	ax
	lea	ax,[bp-16h]
	push	ss
	push	ax
	call	RegFetchDataRecord
	mov	di,ax
	or	di,ax
	jz	near ptr rev_copy_value
	mov	[bp-4],di
	cmp	word ptr [bp-2],0
	jnz	near ptr rev_unlock_key
	mov	word ptr [bp-2],1
	push	word ptr [bp-0ah]
	push	si
	push	dword ptr [bp-8]
	push	0
	call	RegUnlockKeyCache
	push	offset CGROUP:RegMaintainCache
	call	RegForEachFile
	push	offset CGROUP:RegMaintainCache
	call	RegForEachFile
	jmp	near ptr rev_fetch_key
rev_follow_link:
	mov	di,[bp-0ch]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	sub	dh,dh
	mov	[bp-4],ax
	mov	[bp-2],dx
	push	word ptr [bp-0ah]
	push	di
	push	dword ptr [bp-8]
	push	0
	call	RegUnlockKeyCache
	mov	eax,[bp-4]
	mov	[bp-8],eax
	les	bx,dword ptr [bp-12h]
	test	word ptr es:[bx+2],400h
	jnz	short rev_link_filtered
	mov	ax,1
	jmp	short rev_link_class
rev_link_filtered:
	xor	ax,ax
rev_link_class:
	mov	cl,[bp+4]
	and	cx,4
	cmp	cx,1
	sbb	cx,cx
	neg	cx
	cmp	ax,cx
	jnz	short rev_check_link
	dec	word ptr [bp-0eh]
rev_check_link:
	cmp	dword ptr [bp-8],0ffffffh
	jc	near ptr rev_next_key
rev_no_value:
	mov	word ptr [bp-4],103h
	jmp	near ptr rev_done
rev_copy_value:
	mov	[bp-4],di
	mov	si,[bp+0ah]
	mov	ax,[bp+0ch]
	or	ax,si
	jz	short rev_save_length
	les	bx,dword ptr [bp-16h]
	sub	dx,dx
	mov	ax,es:[bx+0ch]
	les	bx,dword ptr [bp+6]
	cmp	dx,es:[bx+2]
	jc	short rev_read_name
	ja	short rev_short_buffer
	cmp	ax,es:[bx]
	jc	short rev_read_name
rev_short_buffer:
	mov	word ptr [bp-4],0eah
	jmp	short rev_save_length
rev_read_name:
	push	word ptr [bp+0ch]
	push	si
	mov	eax,[bp-16h]
	add	ax,14h
	push	eax
	les	bx,dword ptr [bp-16h]
	push	word ptr es:[bx+0ch]
	call	RegMoveMemory
	mov	di,si
	les	bx,dword ptr [bp-16h]
	mov	bx,es:[bx+0ch]
	mov	es,word ptr [bp+0ch]
	mov	byte ptr es:[bx+di],0
rev_save_length:
	les	bx,dword ptr [bp-16h]
	mov	ax,es:[bx+0ch]
	les	bx,dword ptr [bp+6]
	mov	es:[bx],ax
	mov	word ptr es:[bx+2],0
	push	dword ptr [bp-0ch]
	les	bx,dword ptr [bp-12h]
	push	word ptr es:[bx+0ch]
	push	0
	call	RegUnlockDataCache
rev_unlock_key:
	push	dword ptr [bp-0ch]
	push	dword ptr [bp-8]
	push	0
	call	RegUnlockKeyCache
	mov	bx,[bp+10h]
	mov	ax,[bp+0eh]
	mov	es,word ptr [bp+12h]
	mov	es:[bx+22h],ax
	mov	eax,[bp-8]
	db 66h
	mov	es:[bx+24h],ax
	mov	al,es:[bx+4]
	and	al,10h
	cmp	al,10h
	jz	short rev_cache_index
	mov	es,word ptr [bp+12h]
	or	byte ptr es:[bx+4],10h
rev_cache_index:
	test	byte ptr [bp+4],4
	jz	short rev_cache_key
	mov	es,word ptr [bp+12h]
	mov	ah,es:[bx+5]
	and	ah,2
	cmp	ah,2
	jz	short rev_done
	or	byte ptr es:[bx+5],2
	jmp	short rev_done
rev_cache_key:
	mov	es,word ptr [bp+12h]
	test	byte ptr es:[bx+5],2
	jz	short rev_done
	and	byte ptr es:[bx+5],0fdh
	jmp	short rev_done
rev_load_error:
	mov	[bp-4],di
rev_done:
	mov	ax,[bp-4]
	pop	si
	pop	di
	leave
	ret	10h
RegEnumValueRecord endp
	if ($ - RegistryCode) and 1
	db 0
	endif

REGTEXT ends
	end
