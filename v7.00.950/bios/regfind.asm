; Registry key handles and file descriptor lists.
;
; Far C entry points use stack arguments and DS = DGROUP.
; Pointer results and status values are returned in DX:AX where specified.
;
	.286
	extrn	RegInitClassesRoot:far
	extrn	RegInitUserRoot:far
	extrn	RegAllocate:far,ConfigFree:far
; Invalidate a matching predefined root and clear its cached reference count.
; BP+6 = key identity, BP+10 = file identity.
;
InvalidateRoot	macro	rootindex,nextroot
	mov	ax,word ptr RegRootTable+rootindex*28h+16
	mov	dx,word ptr RegRootTable+rootindex*28h+18
	cmp	[bp+6],ax
	jnz	short nextroot
	cmp	[bp+8],dx
	jnz	short nextroot
	mov	ax,word ptr RegRootTable+rootindex*28h+12
	mov	dx,word ptr RegRootTable+rootindex*28h+14
	cmp	[bp+10],ax
	jnz	short nextroot
	cmp	[bp+12],dx
	jnz	short nextroot
	or	byte ptr RegRootTable+rootindex*28h+25,10h
	mov	word ptr RegRootTable+rootindex*28h+16,-1
	mov	word ptr RegRootTable+rootindex*28h+18,-1
	sub	ax,ax
	mov	word ptr RegRootTable+rootindex*28h+22,ax
	mov	word ptr RegRootTable+rootindex*28h+20,ax
	endm

_DATA	segment	word public 'DATA'
_DATA	ends
REGHANDLE	segment	word public 'CODE'
REGHANDLE	ends
DGROUP	group	_DATA
_DATA	segment	word public 'DATA'
	extrn	RegRootTable:byte,RegHandleList:dword
	extrn	RegClassesPath:byte,RegDefaultUser:byte
	extrn	RegFileList:dword
_DATA	ends
REGHANDLE	segment	word public 'CODE'
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegFindKey,RegFindOrCreate

;----------------------------------------------------------------------------
; RegFindKey - Find a key in predefined roots and then the dynamic handle list.
;
; Stack arguments: file identity, far key pointer.
; DX:AX = handle, or -1 if no match.
;----------------------------------------------------------------------------
RegFindKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,1Ah
	mov	cx,[bp+12]
	mov	bx,[bp+10]
	sub	bx,0
	sbb	cx,1
	mov	es,cx
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	mov	[bp-10],ax
	mov	[bp-8],dx
	mov	word ptr [bp-6],0
	jmp	short regfind_rf_test
regfind_rf_next:
	inc	word ptr [bp-6]
regfind_rf_test:
	cmp	word ptr [bp-6],7
	jnc	short regfind_rf_list
	mov	ax,28h
	mul	word ptr [bp-6]
	mov	bx,ax
	mov	ax,[bp-10]
	mov	dx,[bp-8]
	cmp	word ptr RegRootTable[bx+16],ax
	jnz	short regfind_rf_next
	cmp	word ptr RegRootTable[bx+18],dx
	jnz	short regfind_rf_next
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	cmp	word ptr RegRootTable[bx+12],ax
	jnz	short regfind_rf_next
	cmp	word ptr RegRootTable[bx+14],dx
	jnz	short regfind_rf_next
	mov	ax,bx
	add	ax,offset DGROUP:RegRootTable
	mov	dx,ds
	jmp	short regfind_rf_exit
regfind_rf_list:
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
regfind_rf_list_test:
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short regfind_rf_match
	cmp	dx,ax
	jz	short regfind_rf_missing
regfind_rf_match:
	mov	ax,[bp-10]
	mov	dx,[bp-8]
	les	bx,[bp-4]
	cmp	es:[bx+16],ax
	jnz	short regfind_rf_list_next
	cmp	es:[bx+18],dx
	jnz	short regfind_rf_list_next
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	cmp	es:[bx+12],ax
	jnz	short regfind_rf_list_next
	cmp	es:[bx+14],dx
	jnz	short regfind_rf_list_next
	mov	ax,es:[bx+24]
	mov	dx,es:[bx+26]
	and	ax,1000h
	and	dx,10h
	or	dx,ax
	jnz	short regfind_rf_list_next
	mov	ax,bx
	mov	dx,es
	jmp	short regfind_rf_exit
regfind_rf_list_next:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	jmp	short regfind_rf_list_test
regfind_rf_missing:
	mov	ax,-1
	cwd
regfind_rf_exit:
	mov	sp,bp
	pop	bp
	ret
RegFindKey	endp

;----------------------------------------------------------------------------
; RegFindOrCreate - Find a key handle, allocating one if it is not already present.
;
; Stack arguments: file identity, far key pointer.
; DX:AX = handle, or -1 if allocation fails.
;----------------------------------------------------------------------------
RegFindOrCreate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	push	word ptr [bp+12]
	push	word ptr [bp+10]
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	cs
	call	near ptr RegFindKey
	add	sp,8
	cmp	ax,-1
	jnz	short regfind_rfc_exit
	cmp	dx,ax
	jnz	short regfind_rfc_exit
	push	word ptr [bp+12]
	push	word ptr [bp+10]
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	cs
	call	near ptr RegKeyCreate
regfind_rfc_exit:
	mov	sp,bp
	pop	bp
	ret
RegFindOrCreate	endp
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegValidateKeyHandle

;----------------------------------------------------------------------------
; RegValidateKeyHandle - Resolve a handle and initialize a lazy predefined root when needed.
;
; Stack arguments: handle, far output pointer.
; DX:AX = status; output receives the resolved handle or -1.
;----------------------------------------------------------------------------
RegValidateKeyHandle	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	push	si
	mov	word ptr [bp-08h],0FFFFh
	mov	word ptr [bp-06h],0FFFFh
	cmp	word ptr [bp+08h],08000h
	jc	short regvalidate_root_address
	ja	short regvalidate_root_address
	jc	short regvalidate_root_index
	cmp	word ptr [bp+06h],07h
	jnc	short regvalidate_root_address
regvalidate_root_index:
	mov	ax,028h
	mul	word ptr [bp+06h]
	add	ax,offset DGROUP:RegRootTable
	mov	[bp-08h],ax
	mov	word ptr [bp-06h],ds
regvalidate_root_address:
	cmp	word ptr [bp-08h],-1
	jnz	short regvalidate_dynamic
	cmp	word ptr [bp-06h],-1
	jnz	short regvalidate_dynamic
	sub	ax,ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
	jmp	short regvalidate_root_loop
regvalidate_next_root:
	add	word ptr [bp-0Ch],01h
	adc	word ptr [bp-0Ah],00h
regvalidate_root_loop:
	cmp	word ptr [bp-0Ah],00h
	jnz	short regvalidate_dynamic
	cmp	word ptr [bp-0Ch],07h
	jnc	short regvalidate_dynamic
	mov	ax,028h
	mul	word ptr [bp-0Ch]
	add	ax,offset DGROUP:RegRootTable
	mov	cx,ds
	cmp	ax,[bp+06h]
	jnz	short regvalidate_next_root
	cmp	cx,[bp+08h]
	jnz	short regvalidate_next_root
	mov	[bp-08h],ax
	mov	word ptr [bp-06h],ds
regvalidate_dynamic:
	cmp	word ptr [bp-08h],-1
	jnz	short regvalidate_root_state
	cmp	word ptr [bp-06h],-1
	jnz	short regvalidate_root_state
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
regvalidate_handle_loop:
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regvalidate_handle_match
	cmp	dx,ax
	jnz	short regvalidate_handle_match
	jmp	regvalidate_output
regvalidate_handle_match:
	mov	ax,[bp+06h]
	mov	dx,[bp+08h]
	cmp	[bp-04h],ax
	jnz	short regvalidate_next_handle
	cmp	[bp-02h],dx
	jnz	short regvalidate_next_handle
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	jmp	short regvalidate_output
regvalidate_next_handle:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regvalidate_handle_loop
regvalidate_root_state:
	les	bx,[bp+0Ah]
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	bx,ax
	mov	es,dx
	mov	cx,es:[bx+018h]
	mov	dx,es:[bx+01Ah]
	and	cx,01000h
	and	dx,010h
	or	dx,cx
	jz	short regvalidate_output
	cmp	word ptr es:[bx+01Ch],01h
	jnz	short regvalidate_classes_root
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short regvalidate_classes_root
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	call	far ptr RegInitUserRoot
	add	sp,04h
	or	dx,ax
	jnz	short regvalidate_output
regvalidate_key_deleted:
	mov	ax,03FAh
regvalidate_status:
	xor	dx,dx
	jmp	short regvalidate_return
regvalidate_classes_root:
	cmp	word ptr es:[bx+01Ch],00h
	jnz	short regvalidate_key_deleted
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short regvalidate_key_deleted
	call	far ptr RegInitClassesRoot
	or	dx,ax
	jz	short regvalidate_key_deleted
regvalidate_output:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp+0Ah]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	cmp	ax,0FFFFh
	jnz	short regvalidate_handle_state
	cmp	dx,ax
	jz	short regvalidate_bad_key
regvalidate_handle_state:
	mov	bx,ax
	mov	es,dx
	mov	cx,es:[bx+018h]
	mov	si,es:[bx+01Ah]
	and	cx,01000h
	and	si,010h
	or	si,cx
	jnz	short regvalidate_key_deleted
	xor	ax,ax
	jmp	short regvalidate_status
regvalidate_bad_key:
	mov	ax,03F2h
	jmp	short regvalidate_status
regvalidate_return:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegValidateKeyHandle	endp
	even
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegKeyCreate,RegKeyDestroy

;----------------------------------------------------------------------------
; RegKeyCreate - Allocate and link a 28h-byte key handle.
;
; Stack arguments: file identity, far key pointer.
; DX:AX = handle, or -1 if allocation fails.
;----------------------------------------------------------------------------
RegKeyCreate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	les	bx,[bp+6]
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,28h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,8
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jnz	short regkey_rkc_init
	mov	ax,-1
	cwd
	jmp	regkey_rkc_exit
regkey_rkc_init:
	les	bx,[bp-4]
	mov	word ptr es:[bx],4752h
	mov	word ptr es:[bx+2],4E4Bh
	mov	word ptr es:[bx+4],-1
	mov	word ptr es:[bx+6],-1
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
	mov	[bp-8],ax
	mov	[bp-6],dx
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
	mov	cx,[bp+12]
	mov	bx,[bp+10]
	sub	bx,0
	sbb	cx,1
	mov	es,cx
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	les	bx,[bp-4]
	mov	es:[bx+16],ax
	mov	es:[bx+18],dx
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	mov	es:[bx+12],ax
	mov	es:[bx+14],dx
	sub	ax,ax
	mov	es:[bx+26],ax
	mov	es:[bx+24],ax
	mov	es:[bx+22],ax
	mov	es:[bx+20],ax
	mov	word ptr RegHandleList,bx
	mov	word ptr RegHandleList+2,es
	cmp	word ptr [bp-8],-1
	jnz	short regkey_rkc_link
	cmp	word ptr [bp-6],-1
	jz	short regkey_rkc_return
regkey_rkc_link:
	les	bx,[bp-8]
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	mov	es:[bx+4],ax
	mov	es:[bx+6],dx
regkey_rkc_return:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
regkey_rkc_exit:
	mov	sp,bp
	pop	bp
	ret
RegKeyCreate	endp
	even

;----------------------------------------------------------------------------
; RegKeyDestroy - Unlink a key handle and release its owned storage.
;
; Stack arguments: far key handle.
;----------------------------------------------------------------------------
RegKeyDestroy	proc	far
	push	bp
	mov	bp,sp
	sub	sp,8
	push	si
	les	bx,[bp+6]
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	mov	[bp-4],ax
	mov	[bp-2],dx
	mov	cx,es:[bx+8]
	mov	si,es:[bx+10]
	mov	[bp-8],cx
	mov	[bp-6],si
	cmp	ax,-1
	jnz	short regkey_rkd_prev
	cmp	dx,ax
	jz	short regkey_rkd_next
regkey_rkd_prev:
	mov	bx,ax
	mov	es,dx
	mov	es:[bx+8],cx
	mov	es:[bx+10],si
regkey_rkd_next:
	cmp	word ptr [bp-8],-1
	jnz	short regkey_rkd_next_link
	cmp	word ptr [bp-6],-1
	jz	short regkey_rkd_head
regkey_rkd_next_link:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	les	bx,[bp-8]
	mov	es:[bx+4],ax
	mov	es:[bx+6],dx
regkey_rkd_head:
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
	cmp	[bp+6],ax
	jnz	short regkey_rkd_extra
	cmp	[bp+8],dx
	jnz	short regkey_rkd_extra
	mov	ax,[bp-8]
	mov	dx,[bp-6]
	mov	word ptr RegHandleList,ax
	mov	word ptr RegHandleList+2,dx
regkey_rkd_extra:
	les	bx,[bp+6]
	cmp	word ptr es:[bx+28],6
	jnz	short regkey_rkd_free
	cmp	word ptr es:[bx+30],8000h
	jnz	short regkey_rkd_free
	push	word ptr es:[bx+34]
	push	word ptr es:[bx+32]
	call	far ptr ConfigFree
	add	sp,4
regkey_rkd_free:
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	call	far ptr ConfigFree
	add	sp,4
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegKeyDestroy	endp
	even
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegInvalidateKey

;----------------------------------------------------------------------------
; RegInvalidateKey - Invalidate handles matching both key and file identities.
;
; Stack arguments: key identity, file identity.
; Matching roots also lose their cached key and reference count.
;----------------------------------------------------------------------------
RegInvalidateKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
reginval_ri_test:
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short reginval_ri_match
	cmp	dx,ax
	jz	short reginval_ri_roots
reginval_ri_match:
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	les	bx,[bp-4]
	cmp	es:[bx+16],ax
	jnz	short reginval_ri_next
	cmp	es:[bx+18],dx
	jnz	short reginval_ri_next
	mov	ax,[bp+10]
	mov	dx,[bp+12]
	cmp	es:[bx+12],ax
	jnz	short reginval_ri_next
	cmp	es:[bx+14],dx
	jnz	short reginval_ri_next
	or	byte ptr es:[bx+25],10h
reginval_ri_next:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	jmp	short reginval_ri_test
reginval_ri_roots:
	InvalidateRoot	1,reginval_ri_root0
reginval_ri_root0:
	InvalidateRoot	0,reginval_ri_root5
reginval_ri_root5:
	InvalidateRoot	5,reginval_ri_exit
reginval_ri_exit:
	mov	sp,bp
	pop	bp
	ret
RegInvalidateKey	endp
	even
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegFileAddRef,RegFileReleaseRef,RegFileCreate,RegFileUnlink

;----------------------------------------------------------------------------
; RegFileAddRef - Increment a file descriptor's reference count.
;
; Stack arguments: far file descriptor.
;----------------------------------------------------------------------------
RegFileAddRef	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	add	word ptr es:[bx+1Ch],1
	adc	word ptr es:[bx+1Eh],0
	pop	bp
	ret
RegFileAddRef	endp

;----------------------------------------------------------------------------
; RegFileReleaseRef - Decrement a file descriptor's reference count.
;
; Stack arguments: far file descriptor.
; Storage is not released here.
;----------------------------------------------------------------------------
RegFileReleaseRef	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	sub	word ptr es:[bx+1Ch],1
	sbb	word ptr es:[bx+1Eh],0
	pop	bp
	ret
RegFileReleaseRef	endp

;----------------------------------------------------------------------------
; RegFileCreate - Allocate and link a 3Ch-byte file descriptor.
;
; Stack arguments: none.
; DX:AX = descriptor, or -1 if allocation fails.
;----------------------------------------------------------------------------
RegFileCreate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	push	si
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,3Ch
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,8
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jnz	short regobject_rf_init
	mov	ax,-1
	cwd
	jmp	regobject_rf_exit
regobject_rf_init:
	les	bx,[bp-4]
	mov	word ptr es:[bx],4752h       ; RGSF signature
	mov	word ptr es:[bx+2],5346h
	mov	word ptr es:[bx+12],1
	mov	word ptr es:[bx+14],0
	sub	ax,ax
	mov	es:[bx+18],ax
	mov	es:[bx+16],ax
	mov	es:[bx+22],ax
	mov	es:[bx+20],ax
	mov	es:[bx+30],ax
	mov	es:[bx+28],ax
	mov	ax,-1
	cwd
	mov	es:[bx+32],ax
	mov	es:[bx+34],dx
	mov	es:[bx+36],ax
	mov	es:[bx+38],dx
	mov	es:[bx+40],ax
	mov	es:[bx+42],ax
	mov	word ptr es:[bx+44],0
	cmp	word ptr RegFileList,ax
	jnz	short regobject_rf_link
	cmp	word ptr RegFileList+2,ax
	jz	short regobject_rf_first
regobject_rf_link:
	les	bx,RegFileList
	mov	cx,[bp-4]
	mov	si,[bp-2]
	mov	es:[bx+4],cx
	mov	es:[bx+6],si
	mov	es,si
	mov	bx,cx
	mov	cx,word ptr RegFileList
	mov	si,word ptr RegFileList+2
	mov	es:[bx+8],cx
	mov	es:[bx+10],si
	jmp	short regobject_rf_head
regobject_rf_first:
	mov	es:[bx+8],ax
	mov	es:[bx+10],ax
regobject_rf_head:
	mov	es:[bx+4],ax
	mov	es:[bx+6],ax
	mov	word ptr RegFileList,bx
	mov	word ptr RegFileList+2,es
	mov	ax,bx
	mov	dx,es
regobject_rf_exit:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegFileCreate	endp
	even

;----------------------------------------------------------------------------
; RegFileUnlink - Unlink a file descriptor, updating RegFileList if it is the head.
;
; Stack arguments: far file descriptor.
; DX:AX = status. Allocation is not released.
;----------------------------------------------------------------------------
RegFileUnlink	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	push	si
	les	bx,[bp+6]
	cmp	word ptr es:[bx],4752h
	jnz	short regobject_ru_bad
	cmp	word ptr es:[bx+2],5346h
	jz	short regobject_ru_links
regobject_ru_bad:
	mov	ax,57h
regobject_ru_result:
	xor	dx,dx
	jmp	short regobject_ru_exit
regobject_ru_links:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short regobject_ru_prev
	cmp	dx,ax
	jz	short regobject_ru_next
regobject_ru_prev:
	mov	cx,es:[bx+4]
	mov	si,es:[bx+6]
	mov	bx,ax
	mov	es,dx
	mov	es:[bx+4],cx
	mov	es:[bx+6],si
regobject_ru_next:
	les	bx,[bp+6]
	cmp	word ptr es:[bx+4],-1
	jnz	short regobject_ru_next_link
	cmp	word ptr es:[bx+6],-1
	jz	short regobject_ru_head
regobject_ru_next_link:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	les	bx,es:[bx+4]
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
regobject_ru_head:
	mov	ax,word ptr RegFileList
	mov	dx,word ptr RegFileList+2
	cmp	[bp+6],ax
	jnz	short regobject_ru_good
	cmp	[bp+8],dx
	jnz	short regobject_ru_good
	les	bx,[bp+6]
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	mov	word ptr RegFileList,ax
	mov	word ptr RegFileList+2,dx
regobject_ru_good:
	xor	ax,ax
	jmp	short regobject_ru_result
regobject_ru_exit:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegFileUnlink	endp
	nop	; align following entries
	nop
	assume	cs:REGHANDLE,ds:DGROUP
	public	RegInvalidateOwner,RegInvalidateFile,RegHVCreate,RegHVUnlink

;----------------------------------------------------------------------------
; RegInvalidateOwner - Mark dynamic handles belonging to an owner invalid.
;
; Stack arguments: owner identity.
;----------------------------------------------------------------------------
RegInvalidateOwner	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
reghandle_rio_test:
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short reghandle_rio_match
	cmp	dx,ax
	jz	short reghandle_rio_exit
reghandle_rio_match:
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	les	bx,[bp-4]
	cmp	es:[bx+28],ax
	jnz	short reghandle_rio_next
	cmp	es:[bx+30],dx
	jnz	short reghandle_rio_next
	or	byte ptr es:[bx+26],10h
reghandle_rio_next:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	jmp	short reghandle_rio_test
reghandle_rio_exit:
	mov	sp,bp
	pop	bp
	ret
RegInvalidateOwner	endp

;----------------------------------------------------------------------------
; RegInvalidateFile - Mark dynamic handles referring to a file invalid.
;
; Stack arguments: file identity.
;----------------------------------------------------------------------------
RegInvalidateFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
reghandle_rif_test:
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short reghandle_rif_match
	cmp	dx,ax
	jz	short reghandle_rif_exit
reghandle_rif_match:
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	les	bx,[bp-4]
	cmp	es:[bx+12],ax
	jnz	short reghandle_rif_next
	cmp	es:[bx+14],dx
	jnz	short reghandle_rif_next
	or	byte ptr es:[bx+26],10h
reghandle_rif_next:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	jmp	short reghandle_rif_test
reghandle_rif_exit:
	mov	sp,bp
	pop	bp
	ret
RegInvalidateFile	endp

;----------------------------------------------------------------------------
; RegHVCreate - Allocate and initialize a 20h-byte RGHV record.
;
; Stack arguments: none.
; DX:AX = record, or -1 if allocation fails.
;----------------------------------------------------------------------------
RegHVCreate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,20h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,8
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jnz	short reghandle_rhv_init
	mov	ax,-1
	cwd
	jmp	short reghandle_rhv_exit
reghandle_rhv_init:
	les	bx,[bp-4]
	mov	word ptr es:[bx],4752h       ; RGHV signature
	mov	word ptr es:[bx+2],5648h
	mov	ax,-1
	mov	es:[bx+16],ax
	mov	es:[bx+18],ax
	cwd
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
	mov	es:[bx+4],ax
	mov	es:[bx+6],dx
	mov	es:[bx+12],ax
	mov	es:[bx+14],dx
	mov	es:[bx+20],ax
	mov	es:[bx+22],ax
	sub	ax,ax
	mov	es:[bx+30],ax
	mov	es:[bx+28],ax
	mov	es:[bx+26],ax
	mov	es:[bx+24],ax
	mov	ax,bx
	mov	dx,es
reghandle_rhv_exit:
	mov	sp,bp
	pop	bp
	ret
RegHVCreate	endp

;----------------------------------------------------------------------------
; RegHVUnlink - Remove an RGHV record from its neighbours.
;
; Stack arguments: far RGHV record.
; DX:AX = status. Allocation is not released.
;----------------------------------------------------------------------------
RegHVUnlink	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	push	si
	les	bx,[bp+6]
	cmp	word ptr es:[bx],4752h
	jnz	short reghandle_rhu_bad
	cmp	word ptr es:[bx+2],5648h
	jz	short reghandle_rhu_links
reghandle_rhu_bad:
	mov	ax,57h
reghandle_rhu_result:
	xor	dx,dx
	jmp	short reghandle_rhu_exit
reghandle_rhu_links:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short reghandle_rhu_prev
	cmp	dx,ax
	jz	short reghandle_rhu_next
reghandle_rhu_prev:
	mov	cx,es:[bx+4]
	mov	si,es:[bx+6]
	mov	bx,ax
	mov	es,dx
	mov	es:[bx+4],cx
	mov	es:[bx+6],si
reghandle_rhu_next:
	les	bx,[bp+6]
	cmp	word ptr es:[bx+4],-1
	jnz	short reghandle_rhu_next_link
	cmp	word ptr es:[bx+6],-1
	jz	short reghandle_rhu_good
reghandle_rhu_next_link:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	les	bx,es:[bx+4]
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
reghandle_rhu_good:
	xor	ax,ax
	jmp	short reghandle_rhu_result
reghandle_rhu_exit:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegHVUnlink	endp
	even
REGHANDLE	ends
	end
