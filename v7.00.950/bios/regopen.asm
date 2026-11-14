;** REGOPEN - Registry paths, values and record storage
;
; FAR C entries share the key cache and record allocation services below.
; Path and value-name operations use the common component buffer in DGROUP.
;
	.286
	extrn	RegFindAlias:far
	extrn	RegPathPart:far
	extrn	RegCompareN:far
	extrn	RegNameSum:far
	extrn	RegDirtyKeyBlock:far
	extrn	RegMaintainCache:far
	extrn	RegStringLength:far
	extrn	RegUpperCopy:far
	extrn	RegDirtyDataBlock:far
	extrn	RegInvalidBlock:far
	extrn	RegInvalidateKey:far
	extrn	RegCopyPart:far
	extrn	RegGrowKeyBlock:far
	extrn	RegCopyBytes:far
	extrn	RegPointerDifference:far
	extrn	RegLoadDataBlock:far
	extrn	RegAppendDataBlock:far
	extrn	RegGrowDataBlock:far
	extrn	RegPackDataBlock:far
	extrn	__aFulshr:far
	extrn	ConfigOpen:far,ConfigSeek:far,ConfigReadAll:far
	extrn	ConfigClose:far,ConfigFree:far
	extrn	RegAllocate:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGKEYS	segment	word public 'CODE'
REGKEYS	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegPathBuffer:byte
c_common	ends
REGKEYS	segment	word public 'CODE'
	assume	cs:REGKEYS,ds:DGROUP
	public	RegOpenPath

;** RegOpenPath - Resolve a path through ordinary keys and mounts
;
; ENTRY: [BP+6] = FAR file-reference address, [BP+0Ah] = FAR handle,
;        [BP+0Eh] = FAR path, [BP+12h] = FAR output address,
;        [BP+16h] = DWORD mode (1 searches; other values create).
;
RegOpenPath	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Ch
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	test	byte ptr es:[bx+019h],020h
	jnz	short regopen_open_loc_021
	jmp	regopen_open_loc_194
regopen_open_loc_021:
	cmp	word ptr es:[bx+024h],-1
	jnz	short regopen_open_loc_02F
	cmp	word ptr es:[bx+026h],-1
	jz	short regopen_open_loc_040
regopen_open_loc_02F:
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regopen_open_loc_040
	les	bx,[bp+0Eh]
	cmp	byte ptr es:[bx],00h
	jnz	short regopen_open_loc_043
regopen_open_loc_040:
	jmp	regopen_open_loc_194
regopen_open_loc_043:
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	es
	push	bx
	call	far ptr RegPathPart
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	cmp	ax,0FFFFh
	jnz	short regopen_open_loc_069
	cmp	dx,ax
	jnz	short regopen_open_loc_069
	mov	ax,03F2h
regopen_open_loc_064:
	xor	dx,dx
	jmp	regopen_open_loc_205
regopen_open_loc_069:
	cmp	word ptr [bp-04h],-1
	jnz	short regopen_open_loc_078
	cmp	word ptr [bp-02h],-1
	jnz	short regopen_open_loc_078
	jmp	regopen_open_loc_140
regopen_open_loc_078:
	les	bx,[bp+06h]
	les	bx,es:[bx]
	les	bx,es:[bx+024h]
	cmp	word ptr es:[bx],04752h
	jz	short regopen_open_loc_08C
	jmp	regopen_open_loc_112
regopen_open_loc_08C:
	cmp	word ptr es:[bx+02h],04E4Bh
	jnz	short regopen_open_loc_112
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	les	bx,[bp+06h]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegSearchPath
	add	sp,014h
	or	dx,ax
	jnz	short regopen_open_loc_112
	les	bx,[bp+012h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	les	bx,[bp+06h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	mov	cx,[bp-016h]
	mov	bx,[bp-018h]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	les	bx,[bp-08h]
	cmp	byte ptr es:[bx],00h
	jz	short regopen_open_loc_106
	inc	word ptr [bp-08h]
regopen_open_loc_106:
	mov	ax,[bp-08h]
	mov	[bp+0Eh],ax
	mov	word ptr [bp+010h],es
	jmp	regopen_open_loc_1AA
regopen_open_loc_112:
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegFindAlias
	add	sp,0Ch
	or	dx,ax
	jz	short regopen_open_loc_15C
	cmp	word ptr [bp+016h],02h
	jnz	short regopen_open_loc_13A
	cmp	word ptr [bp+018h],00h
	jz	short regopen_open_loc_1AA
regopen_open_loc_13A:
	mov	ax,03F3h
	jmp	regopen_open_loc_064
regopen_open_loc_140:
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegFindAlias
	add	sp,0Ch
	or	dx,ax
	jnz	short regopen_open_loc_13A
regopen_open_loc_15C:
	les	bx,[bp-08h]
	cmp	byte ptr es:[bx],00h
	jz	short regopen_open_loc_168
	inc	word ptr [bp-08h]
regopen_open_loc_168:
	mov	ax,[bp-08h]
	mov	[bp+0Eh],ax
	mov	word ptr [bp+010h],es
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	les	bx,[bp+06h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
regopen_open_loc_194:
	cmp	word ptr [bp-04h],-1
	jnz	short regopen_open_loc_1A0
	cmp	word ptr [bp-02h],-1
	jz	short regopen_open_loc_13A
regopen_open_loc_1A0:
	les	bx,[bp+06h]
	les	bx,es:[bx]
	les	bx,es:[bx+024h]
regopen_open_loc_1AA:
	cmp	word ptr [bp+016h],01h
	jnz	short regopen_open_loc_1DF
	cmp	word ptr [bp+018h],00h
	jnz	short regopen_open_loc_1DF
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	les	bx,[bp+06h]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegSearchPath
regopen_open_loc_1DA:
	add	sp,014h
	jmp	short regopen_open_loc_205
regopen_open_loc_1DF:
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	les	bx,[bp+06h]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegCreatePath
	jmp	short regopen_open_loc_1DA
regopen_open_loc_205:
	mov	sp,bp
	pop	bp
	ret
RegOpenPath	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegSearchPath

;** RegSearchPath - Find a key by path
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = DWORD parent key identity,
;        [BP+0Eh] = FAR path, [BP+12h] = FAR output address,
;        [BP+16h] = DWORD recursion depth.
; The shared component buffer and sibling order are used at each depth.
;
RegSearchPath	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Eh
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	mov	[bp-012h],ax
	mov	[bp-010h],dx
	mov	ax,[bp+016h]
	mov	dx,[bp+018h]
	add	word ptr [bp+016h],01h
	adc	word ptr [bp+018h],00h
	or	dx,dx
	jnz	short regsearch_search_loc_02E
	cmp	ax,020h
	jna	short regsearch_search_loc_036
regsearch_search_loc_02E:
	mov	ax,03F3h
regsearch_search_loc_031:
	xor	dx,dx
	jmp	regsearch_search_loc_209
regsearch_search_loc_036:
	cmp	word ptr [bp+0Ah],-1
	jnz	short regsearch_search_loc_051
	cmp	word ptr [bp+0Ch],-1
	jnz	short regsearch_search_loc_051
	push	es
	push	bx
	les	bx,[bp-012h]
	push	word ptr es:[bx+0Ah]
	push	word ptr es:[bx+08h]
	jmp	short regsearch_search_loc_059
regsearch_search_loc_051:
	push	es
	push	bx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
regsearch_search_loc_059:
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-01Ah],ax
	mov	[bp-018h],dx
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regsearch_search_loc_077
	les	bx,[bp+0Eh]
	cmp	byte ptr es:[bx],00h
	jnz	short regsearch_search_loc_08B
regsearch_search_loc_077:
	mov	ax,[bp-01Ah]
	mov	dx,[bp-018h]
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	xor	ax,ax
	jmp	short regsearch_search_loc_031
regsearch_search_loc_08B:
	les	bx,[bp-01Ah]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp+0Ah],ax
	mov	[bp+0Ch],dx
	cmp	ax,0FFFFh
	jnz	short regsearch_search_loc_0A5
	cmp	dx,ax
	jz	short regsearch_search_loc_02E
regsearch_search_loc_0A5:
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	cmp	es:[bx+06h],dx
	ja	short regsearch_search_loc_0C3
	jc	short regsearch_search_loc_0C0
	cmp	es:[bx+04h],ax
	ja	short regsearch_search_loc_0C3
regsearch_search_loc_0C0:
	jmp	regsearch_search_loc_02E
regsearch_search_loc_0C3:
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegPathPart
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	cmp	ax,0FFFFh
	jnz	short regsearch_search_loc_0EB
	cmp	dx,ax
	jnz	short regsearch_search_loc_0EB
	mov	ax,03F2h
	jmp	regsearch_search_loc_031
regsearch_search_loc_0EB:
	sub	ax,[bp+0Eh]
	mov	[bp-0Ah],ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegNameSum
	add	sp,04h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
regsearch_search_loc_104:
	cmp	word ptr [bp+0Ah],-1
	jnz	short regsearch_search_loc_110
	cmp	word ptr [bp+0Ch],-1
	jz	short regsearch_search_loc_11F
regsearch_search_loc_110:
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	les	bx,[bp-012h]
	cmp	es:[bx+06h],dx
	jnc	short regsearch_search_loc_122
regsearch_search_loc_11F:
	jmp	regsearch_search_loc_02E
regsearch_search_loc_122:
	ja	short regsearch_search_loc_12D
	cmp	es:[bx+04h],ax
	ja	short regsearch_search_loc_12D
	jmp	regsearch_search_loc_02E
regsearch_search_loc_12D:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	dx
	push	ax
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-01Ah],ax
	mov	[bp-018h],dx
	mov	es,dx
	mov	bx,ax
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	cmp	es:[bx+04h],ax
	jnz	short regsearch_search_loc_158
	cmp	es:[bx+06h],dx
	jz	short regsearch_search_loc_15B
regsearch_search_loc_158:
	jmp	regsearch_search_loc_1F5
regsearch_search_loc_15B:
	lea	ax,[bp-0Eh]
	push	ss
	push	ax
	push	es
	push	bx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-016h],ax
	mov	[bp-014h],dx
	cmp	ax,0Eh
	jnz	short regsearch_search_loc_181
	or	dx,dx
	jnz	short regsearch_search_loc_181
	jmp	regsearch_search_loc_209
regsearch_search_loc_181:
	mov	ax,dx
	or	ax,[bp-016h]
	jnz	short regsearch_search_loc_1F5
	mov	ax,[bp-0Ah]
	les	bx,[bp-0Eh]
	cmp	es:[bx+0Ch],ax
	jnz	short regsearch_search_loc_1F5
	push	ax
	lea	ax,[bx+014h]
	push	es
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegCompareN
	add	sp,0Ah
	or	ax,ax
	jnz	short regsearch_search_loc_1F5
	les	bx,[bp-08h]
	inc	word ptr [bp-08h]
	cmp	byte ptr es:[bx],00h
	jnz	short regsearch_search_loc_1BA
	jmp	regsearch_search_loc_077
regsearch_search_loc_1BA:
	les	bx,[bp-01Ah]
	cmp	word ptr es:[bx+010h],-1
	jnz	short regsearch_search_loc_1CE
	cmp	word ptr es:[bx+012h],-1
	jnz	short regsearch_search_loc_1CE
	jmp	regsearch_search_loc_02E
regsearch_search_loc_1CE:
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegSearchPath
	add	sp,014h
	jmp	short regsearch_search_loc_209
regsearch_search_loc_1F5:
	les	bx,[bp-01Ah]
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	mov	[bp+0Ah],ax
	mov	[bp+0Ch],dx
	jmp	regsearch_search_loc_104
regsearch_search_loc_209:
	mov	sp,bp
	pop	bp
	ret
RegSearchPath	endp
	even
	assume	cs:REGKEYS
	public	RegGetKeyRecord

;** RegGetKeyRecord - Resolve a key's data record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR key,
;        [BP+0Eh] = FAR output address.
; The root record is allocated on demand; cache maintenance permits a retry.
;
RegGetKeyRecord	proc	far
	push	bp
	mov	bp,sp
	sub	sp,010h
	push	si
	mov	byte ptr [bp-0Ch],00h
	les	bx,[bp+0Ah]
	cmp	word ptr es:[bx+018h],-1
	jnz	short regaccess_access_loc_086
	cmp	word ptr es:[bx+01Ah],-1
	jnz	short regaccess_access_loc_086
	les	bx,[bp+06h]
	push	es
	push	bx
	les	bx,es:[bx+024h]
	push	word ptr es:[bx+0Ah]
	push	word ptr es:[bx+08h]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	cmp	ax,[bp+0Ah]
	jz	short regaccess_access_loc_03C
	jmp	regaccess_access_loc_0FD
regaccess_access_loc_03C:
	cmp	dx,[bp+0Ch]
	jnz	short regaccess_access_loc_064
	lea	cx,[bp-010h]
	push	ss
	push	cx
	mov	dx,021h
	push	dx
	mov	dx,01h
	push	dx
	lea	dx,[bp-0Ch]
	push	ss
	push	dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegAllocateRecord
	add	sp,010h
	or	dx,ax
	jz	short regaccess_access_loc_067
regaccess_access_loc_064:
	jmp	regaccess_access_loc_0FD
regaccess_access_loc_067:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	les	bx,[bp+0Ah]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyKeyBlock
	add	sp,04h
regaccess_access_loc_086:
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+018h]
	mov	[bp-02h],ax
	lea	cx,[bp-06h]
	push	ss
	push	cx
	push	word ptr es:[bx+01Ah]
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	or	dx,ax
	jz	short regaccess_access_loc_103
	cmp	ax,0Eh
	jnz	short regaccess_access_loc_0F3
	cmp	word ptr [bp-08h],00h
	jnz	short regaccess_access_loc_0F3
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegMaintainCache
	add	sp,08h
	lea	ax,[bp-06h]
	push	ss
	push	ax
	les	bx,[bp+0Ah]
	push	word ptr es:[bx+01Ah]
	push	word ptr es:[bx+018h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
regaccess_access_loc_0F3:
	mov	ax,[bp-08h]
	or	ax,[bp-0Ah]
	jz	short regaccess_access_loc_103
	jmp	short regaccess_access_loc_12E
regaccess_access_loc_0FD:
	mov	ax,03F3h
	cwd
	jmp	short regaccess_access_loc_134
regaccess_access_loc_103:
	mov	ax,[bp-02h]
	les	bx,[bp-06h]
	cmp	es:[bx+014h],ax
	jc	short regaccess_access_loc_0FD
	les	bx,es:[bx+018h]
	mov	si,ax
	add	si,ax
	add	si,si
	mov	ax,es:[bx+si]
	mov	dx,es:[bx+si+02h]
	les	bx,[bp+0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	or	dx,ax
	jz	short regaccess_access_loc_0FD
regaccess_access_loc_12E:
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
regaccess_access_loc_134:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegGetKeyRecord	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegFindValue

;** RegFindValue - Find a named or default value
;
; ENTRY: [BP+6] = FAR key record, [BP+0Ah] = FAR value name.
; EXIT:  DX:AX = FAR value pointer, or -1 if not found.
;
RegFindValue	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	les	bx,[bp+06h]
	cmp	word ptr es:[bx+0Eh],00h
	jnz	short regvfind_vfind_loc_017
regvfind_vfind_loc_010:
	mov	ax,0FFFFh
	cwd
	jmp	regvfind_vfind_loc_0DC
regvfind_vfind_loc_017:
	mov	ax,[bp+0Ch]
	or	ax,[bp+0Ah]
	jnz	short regvfind_vfind_loc_026
	mov	word ptr [bp-02h],00h
	jmp	short regvfind_vfind_loc_04A
regvfind_vfind_loc_026:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp-02h],ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegUpperCopy
	add	sp,08h
regvfind_vfind_loc_04A:
	les	bx,[bp+06h]
	mov	ax,es:[bx+0Ch]
	add	ax,es:[bx+010h]
	sub	dx,dx
	mov	cx,es
	add	ax,bx
	adc	dx,cx
	add	ax,014h
	adc	dx,00h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	ax,es:[bx+0Eh]
	mov	[bp-04h],ax
	jmp	short regvfind_vfind_loc_0A6
regvfind_vfind_loc_072:
	cmp	word ptr es:[bx],01h
	jnz	short regvfind_vfind_loc_085
	cmp	word ptr es:[bx+02h],00h
	jnz	short regvfind_vfind_loc_085
	mov	ax,bx
	mov	dx,es
	jmp	short regvfind_vfind_loc_0DC
regvfind_vfind_loc_085:
	les	bx,[bp-08h]
	sub	dx,dx
	mov	ax,es:[bx+08h]
	add	ax,es:[bx+0Ah]
	adc	dx,dx
	lea	cx,[bx+0Ch]
	mov	bx,es
	add	ax,cx
	adc	dx,bx
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	dec	word ptr [bp-04h]
regvfind_vfind_loc_0A6:
	cmp	word ptr [bp-04h],00h
	jnz	short regvfind_vfind_loc_0AF
	jmp	regvfind_vfind_loc_010
regvfind_vfind_loc_0AF:
	mov	ax,[bp-02h]
	les	bx,[bp-08h]
	cmp	es:[bx+08h],ax
	jnz	short regvfind_vfind_loc_085
	or	ax,ax
	jz	short regvfind_vfind_loc_072
	push	ax
	lea	ax,[bx+0Ch]
	push	es
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegCompareN
	add	sp,0Ah
	or	ax,ax
	jnz	short regvfind_vfind_loc_085
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
regvfind_vfind_loc_0DC:
	mov	sp,bp
	pop	bp
	ret
RegFindValue	endp
	assume	cs:REGKEYS,ds:DGROUP
	public	RegRemoveValue

;** RegRemoveValue - Remove a value and close the gap in its record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR key record,
;        [BP+0Eh] = FAR value name.
;
RegRemoveValue	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Ch
	push	di
	push	si
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	cs
	call	near ptr RegFindValue
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regvdel_vdel_loc_02D
	cmp	dx,ax
	jnz	short regvdel_vdel_loc_02D
	jmp	regvdel_vdel_loc_0F7
regvdel_vdel_loc_02D:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	add	ax,es:[bx+0Ah]
	add	ax,0Ch
	sub	dx,dx
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,es
	mov	si,ax
	mov	di,dx
	add	bx,ax
	mov	[bp-08h],bx
	mov	word ptr [bp-06h],es
	mov	ax,bx
	les	bx,[bp+0Ah]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],cx
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	sub	ax,[bp-01Ch]
	sbb	dx,cx
	mov	cx,es
	add	ax,bx
	adc	dx,cx
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	sub	es:[bx+08h],si
	sbb	es:[bx+0Ah],di
	dec	word ptr es:[bx+0Eh]
	jz	short regvdel_vdel_loc_0B9
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	jmp	short regvdel_vdel_loc_099
regvdel_vdel_loc_091:
	sub	word ptr [bp-010h],01h
	sbb	word ptr [bp-0Eh],00h
regvdel_vdel_loc_099:
	cmp	word ptr [bp-0Eh],00h
	jnz	short regvdel_vdel_loc_0A5
	cmp	word ptr [bp-010h],00h
	jz	short regvdel_vdel_loc_0B9
regvdel_vdel_loc_0A5:
	les	bx,[bp-08h]
	inc	word ptr [bp-08h]
	mov	al,es:[bx]
	les	bx,[bp-0Ch]
	inc	word ptr [bp-0Ch]
	mov	es:[bx],al
	jmp	short regvdel_vdel_loc_091
regvdel_vdel_loc_0B9:
	lea	cx,[bp-018h]
	push	ss
	push	cx
	les	bx,[bp+0Ah]
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regvdel_vdel_loc_0F0
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
	jmp	short regvdel_vdel_loc_0F5
regvdel_vdel_loc_0F0:
	call	far ptr RegInvalidBlock
regvdel_vdel_loc_0F5:
	xor	ax,ax
regvdel_vdel_loc_0F7:
	cwd
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegRemoveValue	endp
	assume	cs:REGKEYS
	public	RegDeleteKeyTree

;** RegDeleteKeyTree - Release descendants, storage and key handles
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR key.
;
RegDeleteKeyTree	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Ch
regdelete_delete_loc_006:
	les	bx,[bp+0Ah]
	cmp	word ptr es:[bx+010h],-1
	jnz	short regdelete_delete_loc_017
	cmp	word ptr es:[bx+012h],-1
	jz	short regdelete_delete_loc_043
regdelete_delete_loc_017:
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	cmp	es:[bx+06h],dx
	ja	short regdelete_delete_loc_060
	jc	short regdelete_delete_loc_034
	cmp	es:[bx+04h],ax
	ja	short regdelete_delete_loc_060
regdelete_delete_loc_034:
	les	bx,[bp+0Ah]
	mov	word ptr es:[bx+010h],0FFFFh
	mov	word ptr es:[bx+012h],0FFFFh
regdelete_delete_loc_043:
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	es
	push	bx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jz	short regdelete_delete_loc_099
	mov	ax,01h
	jmp	short regdelete_delete_loc_09B
regdelete_delete_loc_060:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	les	bx,[bp+0Ah]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDeleteKeyTree
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regdelete_delete_loc_094
	jmp	regdelete_delete_loc_006
regdelete_delete_loc_094:
	mov	dx,[bp-02h]
	jmp	short regdelete_delete_loc_109
regdelete_delete_loc_099:
	xor	ax,ax
regdelete_delete_loc_09B:
	cwd
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regdelete_delete_loc_094
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegFreeRecord
	add	sp,08h
	les	bx,[bp+0Ah]
	mov	word ptr es:[bx+018h],0FFFFh
	mov	word ptr es:[bx+01Ah],0FFFFh
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	es
	push	bx
	push	cs
	call	near ptr RegFreeKeyNode
	add	sp,08h
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	mov	cx,[bp+0Ch]
	mov	bx,[bp+0Ah]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	call	far ptr RegInvalidateKey
	add	sp,08h
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyKeyBlock
	xor	ax,ax
	cwd
regdelete_delete_loc_109:
	mov	sp,bp
	pop	bp
	ret
RegDeleteKeyTree	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegCreatePath

;** RegCreatePath - Find or create successive path components
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = DWORD parent key identity,
;        [BP+0Eh] = FAR path, [BP+12h] = FAR output address,
;        [BP+16h] = DWORD recursion depth.
; Existing components use RegSearchPath; failed new subtrees are released.
;
RegCreatePath	proc	far
	push	bp
	mov	bp,sp
	sub	sp,044h
	push	si
	mov	word ptr [bp-02Ch],00h
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regcreate_create_loc_01D
	les	bx,[bp+0Eh]
	cmp	byte ptr es:[bx],00h
	jnz	short regcreate_create_loc_041
regcreate_create_loc_01D:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
regcreate_create_loc_030:
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
regcreate_create_loc_03A:
	xor	ax,ax
regcreate_create_loc_03C:
	xor	dx,dx
	jmp	regcreate_create_loc_51D
regcreate_create_loc_041:
	mov	ax,[bp+016h]
	mov	dx,[bp+018h]
	add	word ptr [bp+016h],01h
	adc	word ptr [bp+018h],00h
	or	dx,dx
	jnz	short regcreate_create_loc_058
	cmp	ax,020h
	jna	short regcreate_create_loc_05D
regcreate_create_loc_058:
	mov	ax,03F3h
	jmp	short regcreate_create_loc_03C
regcreate_create_loc_05D:
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	es
	push	bx
	call	far ptr RegPathPart
	add	sp,08h
	mov	[bp-020h],ax
	mov	[bp-01Eh],dx
	cmp	ax,0FFFFh
	jnz	short regcreate_create_loc_080
	cmp	dx,ax
	jnz	short regcreate_create_loc_080
	mov	ax,03F2h
	jmp	short regcreate_create_loc_03C
regcreate_create_loc_080:
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	lea	cx,[bp-08h]
	push	ss
	push	cx
	mov	dx,offset DGROUP:RegPathBuffer
	push	ds
	push	dx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegSearchPath
	add	sp,014h
	or	dx,ax
	jnz	short regcreate_create_loc_0FC
	les	bx,[bp-020h]
	inc	word ptr [bp-020h]
	cmp	byte ptr es:[bx],00h
	jz	short regcreate_create_loc_0F3
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	[bp-040h],ax
	mov	[bp-03Eh],dx
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	es
	push	word ptr [bp-020h]
	mov	cx,dx
	mov	bx,ax
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegCreatePath
	add	sp,014h
	jmp	regcreate_create_loc_51D
regcreate_create_loc_0F3:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	jmp	regcreate_create_loc_030
regcreate_create_loc_0FC:
	les	bx,[bp+06h]
	test	byte ptr es:[bx+011h],080h
	jz	short regcreate_create_loc_10C
	mov	ax,05h
	jmp	regcreate_create_loc_03C
regcreate_create_loc_10C:
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegCopyPart
	add	sp,08h
	lea	ax,[bp-018h]
	push	ss
	push	ax
	mov	ax,021h
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp-02Ah],ax
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegAllocateRecord
	add	sp,010h
	or	dx,ax
	jz	short regcreate_create_loc_152
	jmp	regcreate_create_loc_058
regcreate_create_loc_152:
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	mov	bx,ax
	mov	es,dx
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-028h],ax
	mov	[bp-026h],dx
	cmp	ax,0FFFFh
	jnz	short regcreate_create_loc_17E
	cmp	dx,ax
	jz	short regcreate_create_loc_1B2
regcreate_create_loc_17E:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp-026h]
	push	word ptr [bp-028h]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	les	bx,[bp-08h]
	cmp	word ptr es:[bx+06h],00h
	jnz	short regcreate_create_loc_1B2
	cmp	word ptr es:[bx+04h],01Ch
	jnc	short regcreate_create_loc_1B2
	mov	word ptr [bp-028h],0FFFFh
	mov	word ptr [bp-026h],0FFFFh
regcreate_create_loc_1B2:
	cmp	word ptr [bp-028h],-1
	jz	short regcreate_create_loc_1BB
	jmp	regcreate_create_loc_271
regcreate_create_loc_1BB:
	cmp	word ptr [bp-026h],-1
	jz	short regcreate_create_loc_1C4
	jmp	regcreate_create_loc_271
regcreate_create_loc_1C4:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegGrowKeyBlock
	add	sp,04h
	mov	[bp-024h],ax
	mov	[bp-022h],dx
	or	dx,ax
	jz	short regcreate_create_loc_245
	cmp	ax,0Eh
	jnz	short regcreate_create_loc_23C
	cmp	word ptr [bp-022h],00h
	jnz	short regcreate_create_loc_23C
	lea	cx,[bp-04h]
	push	ss
	push	cx
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regcreate_create_loc_23C
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegMaintainCache
	add	sp,08h
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegGrowKeyBlock
	add	sp,04h
	or	dx,ax
	jz	short regcreate_create_loc_245
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegFreeRecordId
regcreate_create_loc_239:
	add	sp,08h
regcreate_create_loc_23C:
	mov	ax,[bp-024h]
	mov	dx,[bp-022h]
	jmp	regcreate_create_loc_51D
regcreate_create_loc_245:
	les	bx,[bp+06h]
	push	es
	push	bx
	les	bx,es:[bx+024h]
	mov	[bp-01Ch],bx
	mov	word ptr [bp-01Ah],es
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-028h],ax
	mov	[bp-026h],dx
	push	dx
	push	ax
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
regcreate_create_loc_271:
	les	bx,[bp-08h]
	cmp	word ptr es:[bx+08h],-1
	jnz	short regcreate_create_loc_282
	cmp	word ptr es:[bx+0Ah],-1
	jz	short regcreate_create_loc_28D
regcreate_create_loc_282:
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	regcreate_create_loc_38B
regcreate_create_loc_28D:
	cmp	word ptr es:[bx+06h],00h
	jnz	short regcreate_create_loc_2D1
	cmp	word ptr es:[bx+04h],038h
	jnc	short regcreate_create_loc_2D1
	mov	ax,[bp-028h]
	add	ax,01Ch
	sub	dx,dx
	mov	[bp-024h],ax
	mov	[bp-022h],dx
	add	ax,01Ch
	adc	dx,dx
	cmp	dx,01h
	jnc	short regcreate_create_loc_2B6
	jmp	regcreate_create_loc_1C4
regcreate_create_loc_2B6:
	ja	short regcreate_create_loc_2BF
	or	ax,ax
	jnz	short regcreate_create_loc_2BF
	jmp	regcreate_create_loc_1C4
regcreate_create_loc_2BF:
	les	bx,[bp-01Ch]
	mov	word ptr es:[bx+0Ch],0FFFFh
	mov	word ptr es:[bx+0Eh],0FFFFh
	jmp	regcreate_create_loc_396
regcreate_create_loc_2D1:
	mov	dx,es
	mov	[bp-038h],bx
	mov	word ptr [bp-036h],es
	mov	cx,dx
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	add	ax,01Ch
	adc	dx,00h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	dx
	push	ax
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	les	bx,[bp-01Ch]
	cmp	es:[bx+06h],dx
	ja	short regcreate_create_loc_352
	jc	short regcreate_create_loc_323
	cmp	es:[bx+04h],ax
	ja	short regcreate_create_loc_352
regcreate_create_loc_323:
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	sub	ax,[bp-028h]
	sbb	dx,[bp-026h]
	les	bx,[bp-08h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	les	bx,[bp-01Ch]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
	jmp	regcreate_create_loc_1C4
regcreate_create_loc_352:
	les	bx,[bp-08h]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	sub	ax,01Ch
	sbb	dx,00h
	les	bx,[bp-0Ch]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	mov	word ptr es:[bx],00h
	mov	word ptr es:[bx+02h],08000h
	mov	word ptr es:[bx+08h],0FFFFh
	mov	word ptr es:[bx+0Ah],0FFFFh
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
regcreate_create_loc_38B:
	les	bx,[bp-01Ch]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
regcreate_create_loc_396:
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	les	bx,[bp-08h]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
	mov	word ptr es:[bx+010h],0FFFFh
	mov	word ptr es:[bx+012h],0FFFFh
	mov	word ptr es:[bx+014h],0FFFFh
	mov	word ptr es:[bx+016h],0FFFFh
	mov	cx,[bp-018h]
	mov	si,bx
	mov	bx,[bp-016h]
	mov	es:[si+018h],cx
	mov	es:[si+01Ah],bx
	mov	bx,si
	mov	word ptr es:[bx+08h],0FFFFh
	mov	word ptr es:[bx+0Ah],0FFFFh
	sub	cx,cx
	mov	es:[bx+02h],cx
	mov	es:[bx],cx
	mov	cx,offset DGROUP:RegPathBuffer
	push	ds
	push	cx
	call	far ptr RegNameSum
	add	sp,04h
	les	bx,[bp-08h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	es,dx
	mov	bx,ax
	cmp	word ptr es:[bx+010h],-1
	jnz	short regcreate_create_loc_429
	cmp	word ptr es:[bx+012h],-1
	jz	short regcreate_create_loc_449
regcreate_create_loc_429:
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp-014h]
	cmp	es:[bx+012h],dx
	jc	short regcreate_create_loc_459
	ja	short regcreate_create_loc_449
	cmp	es:[bx+010h],ax
	jc	short regcreate_create_loc_459
regcreate_create_loc_449:
	mov	ax,[bp-028h]
	mov	dx,[bp-026h]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	jmp	short regcreate_create_loc_4BD
regcreate_create_loc_459:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
regcreate_create_loc_467:
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	les	bx,[bp-014h]
	cmp	word ptr es:[bx+014h],-1
	jnz	short regcreate_create_loc_485
	cmp	word ptr es:[bx+016h],-1
	jz	short regcreate_create_loc_4AC
regcreate_create_loc_485:
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	cmp	es:[bx+06h],dx
	jc	short regcreate_create_loc_4AC
	ja	short regcreate_create_loc_4A2
	cmp	es:[bx+04h],ax
	jna	short regcreate_create_loc_4AC
regcreate_create_loc_4A2:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	dx
	push	ax
	jmp	short regcreate_create_loc_467
regcreate_create_loc_4AC:
	mov	ax,[bp-028h]
	mov	dx,[bp-026h]
	les	bx,[bp-014h]
	mov	es:[bx+014h],ax
	mov	es:[bx+016h],dx
regcreate_create_loc_4BD:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyKeyBlock
	add	sp,04h
	les	bx,[bp-020h]
	inc	word ptr [bp-020h]
	cmp	byte ptr es:[bx],00h
	jnz	short regcreate_create_loc_4DA
	jmp	regcreate_create_loc_0F3
regcreate_create_loc_4DA:
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	es
	push	word ptr [bp-020h]
	push	word ptr [bp-026h]
	push	word ptr [bp-028h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegCreatePath
	add	sp,014h
	mov	[bp-024h],ax
	mov	[bp-022h],dx
	or	dx,ax
	jnz	short regcreate_create_loc_50A
	jmp	regcreate_create_loc_03A
regcreate_create_loc_50A:
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDeleteKeyTree
	jmp	regcreate_create_loc_239
regcreate_create_loc_51D:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegCreatePath	endp
	assume	cs:REGKEYS,ds:DGROUP
	public	RegSetValue

;** RegSetValue - Insert or replace a value in a key record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR key,
;        [BP+0Eh] = FAR name, [BP+12h] = FAR data,
;        [BP+16h] = DWORD type, [BP+1Ah] = DWORD data size.
; Equal data needs no write. Growth moves trailing values backwards;
; shrinking moves them forwards. Both paths share the final value write.
;
RegSetValue	proc	far
	push	bp
	mov	bp,sp
	sub	sp,03Ah
	push	di
	push	si
	mov	word ptr [bp-02h],00h
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regvset_vset_loc_026
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp-02h],ax
regvset_vset_loc_026:
	cmp	word ptr [bp-02h],00h
	jnz	short regvset_vset_loc_040
	cmp	word ptr [bp+016h],01h
	jnz	short regvset_vset_loc_038
	cmp	word ptr [bp+018h],00h
	jz	short regvset_vset_loc_040
regvset_vset_loc_038:
	mov	ax,057h
regvset_vset_loc_03B:
	xor	dx,dx
	jmp	regvset_vset_loc_415
regvset_vset_loc_040:
	mov	ax,[bp-02h]
	add	ax,0Ch
	sub	dx,dx
	add	ax,[bp+01Ah]
	adc	dx,[bp+01Ch]
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	or	dx,dx
	jnz	short regvset_vset_loc_038
	cmp	ax,04000h
	ja	short regvset_vset_loc_038
	lea	ax,[bp-06h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-01Ah],ax
	mov	[bp-018h],dx
	or	dx,ax
	jz	short regvset_vset_loc_085
	mov	dx,[bp-018h]
	jmp	regvset_vset_loc_415
regvset_vset_loc_085:
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	push	cs
	call	near ptr RegFindValue
	add	sp,08h
	mov	[bp-0Eh],ax
	mov	[bp-0Ch],dx
	cmp	ax,0FFFFh
	jnz	short regvset_vset_loc_0AA
	cmp	dx,ax
	jnz	short regvset_vset_loc_0AA
	jmp	regvset_vset_loc_2FE
regvset_vset_loc_0AA:
	mov	es,dx
	mov	bx,ax
	mov	cx,[bp+016h]
	mov	si,[bp+018h]
	cmp	es:[bx],cx
	jnz	short regvset_vset_loc_12B
	cmp	es:[bx+02h],si
	jnz	short regvset_vset_loc_12B
	mov	cx,es:[bx+0Ah]
	sub	si,si
	cmp	cx,[bp+01Ah]
	jnz	short regvset_vset_loc_12B
	cmp	si,[bp+01Ch]
	jnz	short regvset_vset_loc_12B
	mov	cx,[bp+012h]
	mov	si,[bp+014h]
	mov	[bp-02Ah],cx
	mov	[bp-028h],si
	add	ax,es:[bx+08h]
	add	ax,0Ch
	mov	[bp-02Eh],ax
	mov	[bp-02Ch],dx
	mov	ax,[bp+01Ah]
	mov	dx,[bp+01Ch]
	mov	[bp-032h],ax
	mov	[bp-030h],dx
	jmp	short regvset_vset_loc_0FE
regvset_vset_loc_0F6:
	sub	word ptr [bp-032h],01h
	sbb	word ptr [bp-030h],00h
regvset_vset_loc_0FE:
	cmp	word ptr [bp-030h],00h
	jl	short regvset_vset_loc_120
	jg	short regvset_vset_loc_10C
	cmp	word ptr [bp-032h],00h
	jz	short regvset_vset_loc_120
regvset_vset_loc_10C:
	les	bx,[bp-02Ah]
	inc	word ptr [bp-02Ah]
	mov	al,es:[bx]
	les	bx,[bp-02Eh]
	inc	word ptr [bp-02Eh]
	cmp	es:[bx],al
	jz	short regvset_vset_loc_0F6
regvset_vset_loc_120:
	mov	ax,[bp-030h]
	or	ax,[bp-032h]
	jnz	short regvset_vset_loc_12B
	jmp	regvset_vset_loc_410
regvset_vset_loc_12B:
	les	bx,[bp-0Eh]
	mov	ax,es:[bx+08h]
	add	ax,es:[bx+0Ah]
	add	ax,0Ch
	sub	dx,dx
	mov	[bp-022h],ax
	mov	[bp-020h],dx
	cmp	ax,[bp-0Ah]
	jnz	short regvset_vset_loc_14E
	cmp	dx,[bp-08h]
	jnz	short regvset_vset_loc_14E
	jmp	regvset_vset_loc_36B
regvset_vset_loc_14E:
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	cmp	[bp-020h],dx
	jna	short regvset_vset_loc_15C
	jmp	regvset_vset_loc_272
regvset_vset_loc_15C:
	jc	short regvset_vset_loc_166
	cmp	[bp-022h],ax
	jc	short regvset_vset_loc_166
	jmp	regvset_vset_loc_272
regvset_vset_loc_166:
	sub	ax,[bp-022h]
	sbb	dx,[bp-020h]
	les	bx,[bp-06h]
	mov	cx,es:[bx]
	mov	si,es:[bx+02h]
	sub	cx,es:[bx+08h]
	sbb	si,es:[bx+0Ah]
	cmp	si,dx
	ja	short regvset_vset_loc_1D8
	jc	short regvset_vset_loc_188
	cmp	cx,ax
	jnc	short regvset_vset_loc_1D8
regvset_vset_loc_188:
	push	dx
	push	ax
	push	es
	push	bx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegResizeRecord
	add	sp,010h
	mov	[bp-06h],ax
	mov	[bp-04h],dx
	cmp	ax,0FFFFh
	jnz	short regvset_vset_loc_1B4
	cmp	dx,ax
	jnz	short regvset_vset_loc_1B4
regvset_vset_loc_1AE:
	mov	ax,0Eh
	jmp	regvset_vset_loc_03B
regvset_vset_loc_1B4:
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	dx
	push	ax
	push	cs
	call	near ptr RegFindValue
	add	sp,08h
	mov	[bp-0Eh],ax
	mov	[bp-0Ch],dx
	cmp	ax,0FFFFh
	jnz	short regvset_vset_loc_1D8
	cmp	dx,ax
	jnz	short regvset_vset_loc_1D8
	mov	ax,03F1h
	jmp	regvset_vset_loc_03B
regvset_vset_loc_1D8:
	mov	ax,[bp-022h]
	mov	dx,[bp-020h]
	mov	bx,[bp-0Eh]
	mov	si,[bp-0Ch]
	add	ax,bx
	adc	dx,00h
	mov	cx,0Ch
	shl	dx,cl
	add	dx,si
	mov	[bp-012h],ax
	mov	[bp-010h],dx
	mov	cx,ax
	mov	di,dx
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	mov	[bp-03Ah],cx
	mov	[bp-038h],di
	add	ax,bx
	adc	dx,00h
	mov	cx,0Ch
	shl	dx,cl
	add	dx,si
	mov	[bp-016h],ax
	mov	[bp-014h],dx
	push	di
	push	word ptr [bp-03Ah]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	call	far ptr RegPointerDifference
	les	bx,[bp-06h]
	add	ax,es:[bx+08h]
	adc	dx,es:[bx+0Ah]
	mov	[bp-026h],ax
	mov	[bp-024h],dx
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	sub	ax,[bp-022h]
	sbb	dx,[bp-020h]
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
regvset_vset_loc_24C:
	mov	ax,[bp-026h]
	mov	dx,[bp-024h]
	sub	word ptr [bp-026h],01h
	sbb	word ptr [bp-024h],00h
	or	dx,ax
	jnz	short regvset_vset_loc_261
	jmp	regvset_vset_loc_36B
regvset_vset_loc_261:
	mov	bx,[bp-026h]
	les	si,[bp-012h]
	mov	al,es:[bx+si]
	les	si,[bp-016h]
	mov	es:[bx+si],al
	jmp	short regvset_vset_loc_24C
regvset_vset_loc_272:
	mov	ax,[bp-022h]
	mov	dx,[bp-020h]
	mov	si,es
	add	ax,bx
	adc	dx,00h
	mov	cx,0Ch
	shl	dx,cl
	add	dx,si
	mov	[bp-012h],ax
	mov	[bp-010h],dx
	mov	cx,ax
	mov	di,dx
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	mov	[bp-03Ah],cx
	mov	[bp-038h],di
	add	ax,bx
	adc	dx,00h
	mov	cx,0Ch
	shl	dx,cl
	add	dx,si
	mov	[bp-016h],ax
	mov	[bp-014h],dx
	push	di
	push	word ptr [bp-03Ah]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	mov	si,ax
	mov	di,dx
	call	far ptr RegPointerDifference
	les	bx,[bp-06h]
	add	ax,es:[bx+08h]
	adc	dx,es:[bx+0Ah]
	mov	[bp-026h],ax
	mov	[bp-024h],dx
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	sub	ax,[bp-022h]
	sbb	dx,[bp-020h]
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
	push	word ptr [bp-024h]
	push	word ptr [bp-026h]
	push	word ptr [bp-038h]
	push	word ptr [bp-03Ah]
	push	di
	push	si
	call	far ptr RegCopyBytes
	add	sp,0Ch
	jmp	short regvset_vset_loc_36B
regvset_vset_loc_2FE:
	les	bx,[bp-06h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	sub	ax,es:[bx+08h]
	sbb	dx,es:[bx+0Ah]
	cmp	dx,[bp-08h]
	ja	short regvset_vset_loc_349
	jc	short regvset_vset_loc_31C
	cmp	ax,[bp-0Ah]
	jnc	short regvset_vset_loc_349
regvset_vset_loc_31C:
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	es
	push	bx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegResizeRecord
	add	sp,010h
	mov	[bp-06h],ax
	mov	[bp-04h],dx
	cmp	ax,0FFFFh
	jnz	short regvset_vset_loc_349
	cmp	dx,ax
	jnz	short regvset_vset_loc_349
	jmp	regvset_vset_loc_1AE
regvset_vset_loc_349:
	les	bx,[bp-06h]
	add	bx,es:[bx+08h]
	mov	[bp-0Eh],bx
	mov	word ptr [bp-0Ch],es
	mov	ax,[bp-0Ah]
	mov	dx,[bp-08h]
	mov	bx,[bp-06h]
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
	inc	word ptr es:[bx+0Eh]
regvset_vset_loc_36B:
	mov	ax,[bp+016h]
	mov	dx,[bp+018h]
	les	bx,[bp-0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	sub	ax,ax
	mov	es:[bx+06h],ax
	mov	es:[bx+04h],ax
	mov	ax,[bp-02h]
	mov	es:[bx+08h],ax
	mov	ax,[bp+01Ah]
	mov	es:[bx+0Ah],ax
	lea	ax,[bx+0Ch]
	mov	[bp-012h],ax
	mov	word ptr [bp-010h],es
	jmp	short regvset_vset_loc_3B0
regvset_vset_loc_39E:
	les	bx,[bp+0Eh]
	inc	word ptr [bp+0Eh]
	mov	al,es:[bx]
	les	bx,[bp-012h]
	inc	word ptr [bp-012h]
	mov	es:[bx],al
regvset_vset_loc_3B0:
	mov	ax,[bp-02h]
	dec	word ptr [bp-02h]
	or	ax,ax
	jnz	short regvset_vset_loc_39E
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp-010h]
	push	word ptr [bp-012h]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	lea	cx,[bp-01Eh]
	push	ss
	push	cx
	les	bx,[bp-06h]
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regvset_vset_loc_40B
	push	word ptr [bp-01Ch]
	push	word ptr [bp-01Eh]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
	jmp	short regvset_vset_loc_410
regvset_vset_loc_40B:
	call	far ptr RegInvalidBlock
regvset_vset_loc_410:
	xor	ax,ax
	jmp	regvset_vset_loc_03B
regvset_vset_loc_415:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegSetValue	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegEnumerateKey

;** RegEnumerateKey - Enumerate stored children and mounted names
;
; ENTRY: [BP+6] = FAR handle, [BP+0Ah] = DWORD index,
;        [BP+0Eh] = FAR name buffer, [BP+12h] = FAR length address.
;
RegEnumerateKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,024h
	push	si
	mov	word ptr [bp-04h],0FFFFh
	mov	word ptr [bp-02h],0FFFFh
	les	bx,[bp+06h]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	cmp	ax,0FFFFh
	jnz	short regkenum_kenum_loc_02E
	cmp	dx,ax
	jnz	short regkenum_kenum_loc_02E
	jmp	regkenum_kenum_loc_1BD
regkenum_kenum_loc_02E:
	mov	cx,es:[bx+0Ch]
	mov	si,es:[bx+0Eh]
	mov	[bp-0Ch],cx
	mov	[bp-0Ah],si
	mov	es,si
	mov	bx,cx
	les	bx,es:[bx+024h]
	mov	[bp-024h],ax
	mov	[bp-022h],dx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-020h],ax
	mov	[bp-01Eh],dx
	cmp	dx,[bp-022h]
	jnc	short regkenum_kenum_loc_060
	jmp	regkenum_kenum_loc_1AE
regkenum_kenum_loc_060:
	ja	short regkenum_kenum_loc_06A
	cmp	ax,[bp-024h]
	ja	short regkenum_kenum_loc_06A
	jmp	regkenum_kenum_loc_1AE
regkenum_kenum_loc_06A:
	push	si
	push	cx
	push	word ptr [bp-022h]
	push	word ptr [bp-024h]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	bx,ax
	mov	es,dx
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	cmp	ax,0FFFFh
	jnz	short regkenum_kenum_loc_094
	cmp	dx,ax
	jz	short regkenum_kenum_loc_0D2
regkenum_kenum_loc_094:
	mov	ax,[bp-01Ch]
	mov	dx,[bp-01Ah]
	cmp	[bp-01Eh],dx
	jna	short regkenum_kenum_loc_0A2
	jmp	regkenum_kenum_loc_15D
regkenum_kenum_loc_0A2:
	jc	short regkenum_kenum_loc_0AC
	cmp	[bp-020h],ax
	jna	short regkenum_kenum_loc_0AC
	jmp	regkenum_kenum_loc_15D
regkenum_kenum_loc_0AC:
	push	si
	push	word ptr [bp-0Ch]
	les	bx,[bp+06h]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	bx,ax
	mov	es,dx
	mov	word ptr es:[bx+010h],0FFFFh
	mov	word ptr es:[bx+012h],0FFFFh
regkenum_kenum_loc_0D2:
	les	bx,[bp+06h]
	test	byte ptr es:[bx+019h],020h
	jz	short regkenum_kenum_loc_12D
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	cmp	ax,0FFFFh
	jnz	short regkenum_kenum_loc_0F3
	cmp	dx,ax
	jz	short regkenum_kenum_loc_12D
regkenum_kenum_loc_0F3:
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	sub	word ptr [bp+0Ah],01h
	sbb	word ptr [bp+0Ch],00h
	or	dx,dx
	jnz	short regkenum_kenum_loc_109
	or	ax,ax
	jz	short regkenum_kenum_loc_11B
regkenum_kenum_loc_109:
	cmp	word ptr [bp-08h],-1
	jz	short regkenum_kenum_loc_112
	jmp	regkenum_kenum_loc_256
regkenum_kenum_loc_112:
	cmp	word ptr [bp-06h],-1
	jz	short regkenum_kenum_loc_11B
	jmp	regkenum_kenum_loc_256
regkenum_kenum_loc_11B:
	cmp	word ptr [bp-08h],-1
	jz	short regkenum_kenum_loc_124
	jmp	regkenum_kenum_loc_26A
regkenum_kenum_loc_124:
	cmp	word ptr [bp-06h],-1
	jz	short regkenum_kenum_loc_12D
	jmp	regkenum_kenum_loc_26A
regkenum_kenum_loc_12D:
	mov	ax,0103h
	jmp	regkenum_kenum_loc_211
regkenum_kenum_loc_133:
	mov	ax,[bp-01Ch]
	mov	dx,[bp-01Ah]
	cmp	[bp-01Eh],dx
	ja	short regkenum_kenum_loc_15D
	jc	short regkenum_kenum_loc_145
	cmp	[bp-020h],ax
	ja	short regkenum_kenum_loc_15D
regkenum_kenum_loc_145:
	mov	word ptr es:[bx+014h],0FFFFh
	mov	word ptr es:[bx+016h],0FFFFh
	mov	word ptr [bp-04h],0FFFFh
	mov	word ptr [bp-02h],0FFFFh
	jmp	short regkenum_kenum_loc_1BD
regkenum_kenum_loc_15D:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp-01Ah]
	push	word ptr [bp-01Ch]
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	sub	word ptr [bp+0Ah],01h
	sbb	word ptr [bp+0Ch],00h
	or	dx,dx
	jnz	short regkenum_kenum_loc_18C
	or	ax,ax
	jz	short regkenum_kenum_loc_1BD
regkenum_kenum_loc_18C:
	les	bx,[bp-04h]
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	cmp	ax,0FFFFh
	jnz	short regkenum_kenum_loc_133
	cmp	dx,ax
	jnz	short regkenum_kenum_loc_133
	mov	[bp-04h],ax
	mov	[bp-02h],ax
	jmp	short regkenum_kenum_loc_1BD
regkenum_kenum_loc_1AE:
	les	bx,[bp+06h]
	mov	word ptr es:[bx+010h],0FFFFh
	mov	word ptr es:[bx+012h],0FFFFh
regkenum_kenum_loc_1BD:
	cmp	word ptr [bp-04h],-1
	jnz	short regkenum_kenum_loc_1CC
	cmp	word ptr [bp-02h],-1
	jnz	short regkenum_kenum_loc_1CC
	jmp	regkenum_kenum_loc_0D2
regkenum_kenum_loc_1CC:
	lea	cx,[bp-010h]
	push	ss
	push	cx
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jnz	short regkenum_kenum_loc_24D
	les	bx,[bp+012h]
	mov	ax,es:[bx]
	les	bx,[bp-010h]
	cmp	es:[bx+0Ch],ax
	jc	short regkenum_kenum_loc_216
	mov	ax,es:[bx+0Ch]
	inc	ax
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	word ptr es:[bx+02h],00h
regkenum_kenum_loc_20E:
	mov	ax,0EAh
regkenum_kenum_loc_211:
	xor	dx,dx
	jmp	regkenum_kenum_loc_2DC
regkenum_kenum_loc_216:
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regkenum_kenum_loc_24D
	sub	dx,dx
	mov	ax,es:[bx+0Ch]
	push	dx
	push	ax
	lea	ax,[bx+014h]
	push	es
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	les	bx,[bp-010h]
	mov	ax,es:[bx+0Ch]
	add	[bp+0Eh],ax
	les	bx,[bp+0Eh]
	mov	byte ptr es:[bx],00h
	jmp	regkenum_kenum_loc_2D7
regkenum_kenum_loc_24D:
	mov	ax,[bp-018h]
	mov	dx,[bp-016h]
	jmp	regkenum_kenum_loc_2DC
regkenum_kenum_loc_256:
	les	bx,[bp-08h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	jmp	regkenum_kenum_loc_0F3
regkenum_kenum_loc_26A:
	les	bx,[bp-08h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr RegStringLength
	add	sp,04h
	inc	ax
	sub	dx,dx
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	les	bx,[bp+012h]
	cmp	dx,es:[bx+02h]
	jc	short regkenum_kenum_loc_2A0
	ja	short regkenum_kenum_loc_296
	cmp	ax,es:[bx]
	jna	short regkenum_kenum_loc_2A0
regkenum_kenum_loc_296:
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	jmp	regkenum_kenum_loc_20E
regkenum_kenum_loc_2A0:
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short regkenum_kenum_loc_2C7
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	les	bx,[bp-08h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegCopyBytes
	add	sp,0Ch
regkenum_kenum_loc_2C7:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
regkenum_kenum_loc_2D7:
	xor	ax,ax
	jmp	regkenum_kenum_loc_211
regkenum_kenum_loc_2DC:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegEnumerateKey	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegValueAtIndex

;** RegValueAtIndex - Locate a value by its position in the record
;
; ENTRY: [BP+6] = FAR key record, [BP+0Ah] = DWORD index.
; EXIT:  DX:AX = FAR value pointer, or -1 when the index is out of range.
;
RegValueAtIndex	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	les	bx,[bp+06h]
	sub	dx,dx
	mov	ax,es:[bx+0Eh]
	cmp	dx,[bp+0Ch]
	ja	short regvenum_venum_loc_021
	jc	short regvenum_venum_loc_01B
	cmp	ax,[bp+0Ah]
	ja	short regvenum_venum_loc_021
regvenum_venum_loc_01B:
	mov	ax,0FFFFh
	cwd
	jmp	short regvenum_venum_loc_071
regvenum_venum_loc_021:
	mov	ax,es:[bx+0Ch]
	add	ax,es:[bx+010h]
	mov	cx,es
	add	ax,bx
	adc	dx,cx
	add	ax,014h
	adc	dx,00h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	jmp	short regvenum_venum_loc_045
regvenum_venum_loc_03D:
	sub	word ptr [bp+0Ah],01h
	sbb	word ptr [bp+0Ch],00h
regvenum_venum_loc_045:
	cmp	word ptr [bp+0Ch],00h
	jnz	short regvenum_venum_loc_051
	cmp	word ptr [bp+0Ah],00h
	jz	short regvenum_venum_loc_071
regvenum_venum_loc_051:
	les	bx,[bp-08h]
	sub	dx,dx
	mov	ax,es:[bx+08h]
	add	ax,es:[bx+0Ah]
	adc	dx,dx
	lea	cx,[bx+0Ch]
	mov	bx,es
	add	ax,cx
	adc	dx,bx
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	jmp	short regvenum_venum_loc_03D
regvenum_venum_loc_071:
	mov	sp,bp
	pop	bp
	ret
RegValueAtIndex	endp
	even
	assume	cs:REGKEYS
	public	RegFreeRecordId

;** RegFreeRecordId - Validate an indexed identity and release its record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = DWORD record identity.
;
RegFreeRecordId	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ah
	push	si
	mov	ax,[bp+0Ah]
	mov	[bp-02h],ax
	lea	ax,[bp-06h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regfreeid_freeid_loc_074
	mov	ax,[bp-02h]
	les	bx,[bp-06h]
	cmp	es:[bx+014h],ax
	jc	short regfreeid_freeid_loc_074
	les	bx,es:[bx+018h]
	mov	si,ax
	add	si,ax
	add	si,si
	mov	ax,es:[bx+si]
	mov	dx,es:[bx+si+02h]
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	or	dx,ax
	jz	short regfreeid_freeid_loc_074
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	les	bx,[bp-0Ah]
	cmp	es:[bx+04h],ax
	jnz	short regfreeid_freeid_loc_074
	cmp	es:[bx+06h],dx
	jnz	short regfreeid_freeid_loc_074
	push	es
	push	bx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegFreeRecord
	add	sp,08h
regfreeid_freeid_loc_074:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegFreeRecordId	endp
	even
	assume	cs:REGKEYS
	public	RegFreeRecord

;** RegFreeRecord - Return a data extent and clear its index entry
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR record.
;
RegFreeRecord	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ah
	push	si
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+04h]
	mov	[bp-06h],ax
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	lea	ax,[bp-0Ah]
	push	ss
	push	ax
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jz	short regfree_free_loc_03F
	jmp	regfree_free_loc_0CC
regfree_free_loc_03F:
	les	bx,[bp+0Ah]
	mov	word ptr es:[bx+04h],0FFFFh
	mov	word ptr es:[bx+06h],0FFFFh
	les	bx,[bp-0Ah]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	les	bx,[bp+0Ah]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	mov	ax,es
	sub	bx,[bp-0Ah]
	sbb	ax,[bp-08h]
	les	si,[bp-0Ah]
	mov	es:[si+010h],bx
	mov	es:[si+012h],ax
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	bx,si
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
	mov	ax,[bp-06h]
	cmp	es:[bx+014h],ax
	jnz	short regfree_free_loc_09B
	cmp	word ptr es:[bx+014h],00h
	jz	short regfree_free_loc_09B
	dec	word ptr es:[bx+014h]
regfree_free_loc_09B:
	cmp	es:[bx+016h],ax
	jna	short regfree_free_loc_0A5
	mov	es:[bx+016h],ax
regfree_free_loc_0A5:
	les	bx,es:[bx+018h]
	mov	si,ax
	add	si,ax
	add	si,si
	sub	ax,ax
	mov	es:[bx+si+02h],ax
	mov	es:[bx+si],ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
regfree_free_loc_0CC:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegFreeRecord	endp
	even
	assume	cs:REGKEYS
	public	RegFreeKeyNode

;** RegFreeKeyNode - Unlink a key and return its node to the free list
;
; ENTRY: [BP+6] = FAR key, [BP+0Ah] = FAR file.
;
RegFreeKeyNode	proc	far
	push	bp
	mov	bp,sp
	sub	sp,024h
	push	si
	les	bx,[bp+06h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	cmp	ax,0FFFFh
	jnz	short regkeyfree_keyfree_loc_01E
	cmp	dx,ax
	jnz	short regkeyfree_keyfree_loc_01E
	jmp	regkeyfree_keyfree_loc_162
regkeyfree_keyfree_loc_01E:
	les	si,[bp+0Ah]
	les	si,es:[si+024h]
	cmp	es:[si+06h],dx
	ja	short regkeyfree_keyfree_loc_039
	jnc	short regkeyfree_keyfree_loc_030
	jmp	regkeyfree_keyfree_loc_162
regkeyfree_keyfree_loc_030:
	cmp	es:[si+04h],ax
	ja	short regkeyfree_keyfree_loc_039
	jmp	regkeyfree_keyfree_loc_162
regkeyfree_keyfree_loc_039:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	dx
	push	ax
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	cx,[bp+08h]
	mov	bx,[bp+06h]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	les	bx,[bp-04h]
	cmp	es:[bx+010h],ax
	jnz	short regkeyfree_keyfree_loc_091
	cmp	es:[bx+012h],dx
	jnz	short regkeyfree_keyfree_loc_091
	les	bx,[bp+06h]
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	les	bx,[bp-04h]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	jmp	short regkeyfree_keyfree_loc_110
regkeyfree_keyfree_loc_091:
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
regkeyfree_keyfree_loc_099:
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	cmp	ax,0FFFFh
	jnz	short regkeyfree_keyfree_loc_0A8
	cmp	dx,ax
	jz	short regkeyfree_keyfree_loc_110
regkeyfree_keyfree_loc_0A8:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	les	bx,[bp+0Ah]
	les	bx,es:[bx+024h]
	cmp	es:[bx+06h],dx
	jc	short regkeyfree_keyfree_loc_110
	ja	short regkeyfree_keyfree_loc_0C3
	cmp	es:[bx+04h],ax
	jna	short regkeyfree_keyfree_loc_110
regkeyfree_keyfree_loc_0C3:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	dx
	push	ax
	push	cs
	call	near ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	es,dx
	mov	bx,ax
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	cmp	es:[bx+014h],ax
	jnz	short regkeyfree_keyfree_loc_106
	cmp	es:[bx+016h],dx
	jnz	short regkeyfree_keyfree_loc_106
	les	bx,[bp+06h]
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	les	bx,[bp-08h]
	mov	es:[bx+014h],ax
	mov	es:[bx+016h],dx
	jmp	short regkeyfree_keyfree_loc_110
regkeyfree_keyfree_loc_106:
	mov	ax,es:[bx+014h]
	mov	dx,es:[bx+016h]
	jmp	short regkeyfree_keyfree_loc_099
regkeyfree_keyfree_loc_110:
	les	bx,[bp+0Ah]
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	les	bx,[bp+06h]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	mov	word ptr es:[bx+04h],01Ch
	mov	word ptr es:[bx+06h],00h
	mov	word ptr es:[bx],00h
	mov	word ptr es:[bx+02h],08000h
	mov	cx,es
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp+0Ah]
	les	bx,es:[bx+024h]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
regkeyfree_keyfree_loc_162:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegFreeKeyNode	endp
	even
	assume	cs:REGKEYS
	public	RegGetDataBlock

;** RegGetDataBlock - Locate or load the block containing a record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = DWORD record identity,
;        [BP+0Eh] = FAR output address.
;
RegGetDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	push	si
	sub	ax,ax
	mov	[bp-06h],ax
	mov	[bp-08h],ax
	mov	ax,[bp+0Ch]
	mov	[bp-02h],ax
	les	bx,[bp+06h]
	cmp	ax,es:[bx+0Eh]
	jc	short regget_get_loc_029
	call	far ptr RegInvalidBlock
	mov	ax,03F7h
	cwd
	jmp	short regget_get_loc_08B
regget_get_loc_029:
	mov	ax,0Ch
	mul	word ptr [bp-02h]
	mov	si,ax
	les	bx,es:[bx+028h]
	cmp	word ptr es:[bx+si],-1
	jnz	short regget_get_loc_05D
	cmp	word ptr es:[bx+si+02h],-1
	jnz	short regget_get_loc_05D
	mov	ax,0FFFFh
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegLoadDataBlock
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
regget_get_loc_05D:
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jnz	short regget_get_loc_085
	mov	ax,0Ch
	mul	word ptr [bp-02h]
	mov	si,ax
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	ax,es:[bx+si]
	mov	dx,es:[bx+si+02h]
	les	bx,[bp+0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
regget_get_loc_085:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
regget_get_loc_08B:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegGetDataBlock	endp
	assume	cs:REGKEYS
	public	RegAllocateRecord

;** RegAllocateRecord - Allocate indexed record storage and copy its name
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR name data,
;        [BP+0Eh] = WORD name size, [BP+10h] = WORD extra size,
;        [BP+12h] = FAR output identity address.
;
RegAllocateRecord	proc	far
	push	bp
	mov	bp,sp
	sub	sp,018h
	push	si
	mov	ax,0FFFFh
	mov	[bp-06h],ax
	mov	[bp-08h],ax
	mov	word ptr [bp-0Ch],00h
	mov	[bp-014h],ax
	mov	[bp-012h],ax
	sub	ax,ax
	mov	[bp-016h],ax
	mov	[bp-018h],ax
	mov	ax,[bp+010h]
	add	ax,[bp+0Eh]
	sub	dx,dx
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0EFE0h
	ja	short regrecord_record_loc_039
	jmp	regrecord_record_loc_154
regrecord_record_loc_039:
	mov	ax,057h
regrecord_record_loc_03C:
	xor	dx,dx
	jmp	regrecord_record_loc_2B5
regrecord_record_loc_041:
	cmp	word ptr [bp-018h],0Eh
	jz	short regrecord_record_loc_04A
	jmp	regrecord_record_loc_12D
regrecord_record_loc_04A:
	cmp	word ptr [bp-016h],00h
	jnz	short regrecord_record_loc_097
	mov	ax,[bp-06h]
	cmp	[bp-08h],ax
	jz	short regrecord_record_loc_097
	mov	[bp-08h],ax
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegMaintainCache
	add	sp,08h
regrecord_record_loc_06F:
	lea	ax,[bp-010h]
	push	ss
	push	ax
	mov	dx,[bp-06h]
	sub	cx,cx
	push	dx
	push	cx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regrecord_record_loc_097
	les	bx,[bp-010h]
	cmp	word ptr es:[bx+016h],0FFh
	jc	short regrecord_record_loc_09A
regrecord_record_loc_097:
	jmp	regrecord_record_loc_12D
regrecord_record_loc_09A:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	cmp	es:[bx+0Ah],dx
	jc	short regrecord_record_loc_0CA
	ja	short regrecord_record_loc_0AE
	cmp	es:[bx+08h],ax
	jc	short regrecord_record_loc_0CA
regrecord_record_loc_0AE:
	push	ax
	push	es
	push	bx
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	cmp	ax,0FFFFh
	jnz	short regrecord_record_loc_0C7
	cmp	dx,ax
	jz	short regrecord_record_loc_0CA
regrecord_record_loc_0C7:
	jmp	regrecord_record_loc_14B
regrecord_record_loc_0CA:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegGrowDataBlock
	add	sp,0Ah
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jz	short regrecord_record_loc_0EE
	jmp	regrecord_record_loc_041
regrecord_record_loc_0EE:
	lea	cx,[bp-010h]
	push	ss
	push	cx
	mov	dx,[bp-06h]
	sub	bx,bx
	push	dx
	push	bx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jz	short regrecord_record_loc_10E
	jmp	regrecord_record_loc_041
regrecord_record_loc_10E:
	push	word ptr [bp-04h]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	cmp	ax,0FFFFh
	jnz	short regrecord_record_loc_14B
	cmp	dx,ax
	jnz	short regrecord_record_loc_14B
regrecord_record_loc_12D:
	push	word ptr [bp-0Ch]
	push	word ptr [bp-06h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegNextDataBlock
	add	sp,08h
	mov	[bp-06h],ax
	cmp	ax,0FFFFh
	jz	short regrecord_record_loc_14B
	jmp	regrecord_record_loc_06F
regrecord_record_loc_14B:
	cmp	word ptr [bp-06h],-1
	jnz	short regrecord_record_loc_15A
	inc	word ptr [bp-0Ch]
regrecord_record_loc_154:
	cmp	word ptr [bp-0Ch],02h
	jc	short regrecord_record_loc_12D
regrecord_record_loc_15A:
	cmp	word ptr [bp-014h],-1
	jnz	short regrecord_record_loc_166
	cmp	word ptr [bp-012h],-1
	jz	short regrecord_record_loc_169
regrecord_record_loc_166:
	jmp	regrecord_record_loc_210
regrecord_record_loc_169:
	push	word ptr [bp-04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegAppendDataBlock
	add	sp,06h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jz	short regrecord_record_loc_1C4
	cmp	ax,0Eh
	jnz	short regrecord_record_loc_18F
	cmp	word ptr [bp-016h],00h
	jz	short regrecord_record_loc_195
regrecord_record_loc_18F:
	mov	dx,[bp-016h]
	jmp	regrecord_record_loc_2B5
regrecord_record_loc_195:
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegMaintainCache
	add	sp,08h
	push	word ptr [bp-04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegAppendDataBlock
	add	sp,06h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jnz	short regrecord_record_loc_18F
regrecord_record_loc_1C4:
	lea	ax,[bp-010h]
	push	ss
	push	ax
	les	bx,[bp+06h]
	mov	ax,es:[bx+0Eh]
	dec	ax
	mov	[bp-06h],ax
	sub	cx,cx
	push	ax
	push	cx
	push	es
	push	bx
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jnz	short regrecord_record_loc_18F
	push	word ptr [bp-04h]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	cmp	ax,0FFFFh
	jnz	short regrecord_record_loc_210
	cmp	dx,ax
	jnz	short regrecord_record_loc_210
	mov	ax,0Eh
	jmp	regrecord_record_loc_03C
regrecord_record_loc_210:
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	cs
	call	near ptr RegAssignRecordId
	add	sp,04h
	mov	[bp-0Ah],ax
	mov	cx,[bp-06h]
	les	bx,[bp-014h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],cx
	mov	cx,[bp+0Eh]
	mov	es:[bx+0Ch],cx
	xor	dx,dx
	mov	es:[bx+0Eh],dx
	mov	es:[bx+010h],dx
	mov	es:[bx+012h],dx
	push	dx
	push	cx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	lea	cx,[bx+014h]
	push	es
	push	cx
	call	far ptr RegCopyBytes
	add	sp,0Ch
	mov	ax,[bp+0Eh]
	add	ax,014h
	les	bx,[bp-014h]
	mov	es:[bx+08h],ax
	mov	word ptr es:[bx+0Ah],00h
	mov	bx,[bp-0Ah]
	add	bx,bx
	add	bx,bx
	les	si,[bp-010h]
	les	si,es:[si+018h]
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	mov	es:[bx+si],ax
	mov	es:[bx+si+02h],dx
	mov	bx,ax
	mov	es,dx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
	xor	ax,ax
	jmp	regrecord_record_loc_03C
regrecord_record_loc_2B5:
	pop	si
	mov	sp,bp
	pop	bp
	ret
	nop
RegAllocateRecord	endp
	even
	assume	cs:REGKEYS
	public	RegAssignRecordId

;** RegAssignRecordId - Assign a free record index
;
; ENTRY: [BP+6] = FAR data block.
; EXIT:  AX = assigned index; the next-free index is advanced.
;
RegAssignRecordId	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ah
	les	bx,[bp+06h]
	mov	ax,es:[bx+016h]
	mov	[bp-02h],ax
	cmp	ax,es:[bx+014h]
	jna	short regid_id_loc_020
	mov	es:[bx+014h],ax
	inc	ax
	mov	[bp-04h],ax
	jmp	short regid_id_loc_05D
regid_id_loc_020:
	mov	ax,[bp-02h]
	inc	ax
	mov	[bp-04h],ax
	add	ax,ax
	add	ax,ax
	add	ax,es:[bx+018h]
	mov	dx,es:[bx+01Ah]
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	mov	ax,es:[bx+014h]
	mov	[bp-06h],ax
	jmp	short regid_id_loc_055
regid_id_loc_042:
	les	bx,[bp-0Ah]
	mov	ax,es:[bx+02h]
	or	ax,es:[bx]
	jz	short regid_id_loc_05D
	add	word ptr [bp-0Ah],04h
	inc	word ptr [bp-04h]
regid_id_loc_055:
	mov	ax,[bp-04h]
	cmp	[bp-06h],ax
	jnc	short regid_id_loc_042
regid_id_loc_05D:
	mov	ax,[bp-04h]
	les	bx,[bp+06h]
	mov	es:[bx+016h],ax
	mov	ax,[bp-02h]
	mov	sp,bp
	pop	bp
	ret
RegAssignRecordId	endp
	assume	cs:REGKEYS
	public	RegNextDataBlock

;** RegNextDataBlock - Find the next block available for allocation
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = WORD previous block index,
;        [BP+0Ch] = WORD load flag.
; EXIT:  AX = block index, or -1 if no block is available.
;
RegNextDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	mov	word ptr [bp-08h],0FFFFh
	inc	word ptr [bp+0Ah]
	mov	ax,[bp+0Ah]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	ja	short regnext_next_loc_01F
	mov	ax,0FFFFh
	jmp	short regnext_next_loc_08E
regnext_next_loc_01F:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	cx,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	add	cx,ax
	mov	[bp-04h],cx
	mov	[bp-02h],dx
	mov	ax,es:[bx+0Eh]
	dec	ax
	mov	[bp-06h],ax
	jmp	short regnext_next_loc_051
regnext_next_loc_03F:
	cmp	word ptr [bp+0Ch],00h
	jnz	short regnext_next_loc_04A
regnext_next_loc_045:
	mov	[bp-08h],ax
	jmp	short regnext_next_loc_08B
regnext_next_loc_04A:
	inc	word ptr [bp+0Ah]
	add	word ptr [bp-04h],0Ch
regnext_next_loc_051:
	mov	ax,[bp+0Ah]
	cmp	[bp-06h],ax
	jc	short regnext_next_loc_08B
	les	bx,[bp-04h]
	cmp	word ptr es:[bx],-1
	jnz	short regnext_next_loc_03F
	cmp	word ptr es:[bx+02h],-1
	jnz	short regnext_next_loc_03F
	cmp	word ptr [bp+0Ch],00h
	jz	short regnext_next_loc_04A
	mov	cx,0FFFFh
	push	cx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegLoadDataBlock
	add	sp,08h
	or	dx,ax
	jnz	short regnext_next_loc_08B
	mov	ax,[bp+0Ah]
	jmp	short regnext_next_loc_045
regnext_next_loc_08B:
	mov	ax,[bp-08h]
regnext_next_loc_08E:
	mov	sp,bp
	pop	bp
	ret
	nop
RegNextDataBlock	endp
	even
	assume	cs:REGKEYS
	public	RegTakeFreeSpace

;** RegTakeFreeSpace - Remove or split an available data extent
;
; ENTRY: [BP+6] = FAR data block, [BP+0Ah] = WORD requested size.
; EXIT:  DX:AX = FAR extent pointer, or -1 if no extent is suitable.
;
RegTakeFreeSpace	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	push	di
	push	si
	les	bx,[bp+06h]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	word ptr [bp-0Ch],0FFFFh
	mov	word ptr [bp-0Ah],0FFFFh
regspace_space_loc_023:
	cmp	word ptr [bp-04h],-1
	jnz	short regspace_space_loc_032
	cmp	word ptr [bp-02h],-1
	jnz	short regspace_space_loc_032
	jmp	regspace_space_loc_146
regspace_space_loc_032:
	mov	cx,[bp-02h]
	mov	bx,[bp-04h]
	mov	ax,[bp+06h]
	mov	dx,[bp+08h]
	add	bx,ax
	adc	cx,dx
	mov	es,cx
	mov	[bp-04h],bx
	mov	word ptr [bp-02h],es
	mov	cx,es:[bx]
	mov	si,es:[bx+02h]
	mov	[bp-010h],cx
	mov	[bp-0Eh],si
	mov	di,[bp+0Ah]
	sub	dx,dx
	cmp	si,dx
	jnc	short regspace_space_loc_063
	jmp	regspace_space_loc_12F
regspace_space_loc_063:
	ja	short regspace_space_loc_06C
	cmp	cx,di
	ja	short regspace_space_loc_06C
	jmp	regspace_space_loc_12F
regspace_space_loc_06C:
	mov	[bp-014h],di
	mov	[bp-012h],dx
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	sub	cx,di
	sbb	si,[bp-012h]
	or	si,si
	jnz	short regspace_space_loc_08E
	cmp	cx,02Ah
	jna	short regspace_space_loc_0D9
regspace_space_loc_08E:
	mov	di,es
	add	bx,[bp-014h]
	adc	di,[bp-012h]
	mov	es,di
	mov	es:[bx],cx
	mov	es:[bx+02h],si
	mov	word ptr es:[bx+04h],0FFFFh
	mov	word ptr es:[bx+06h],0FFFFh
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	mov	ax,di
	les	si,[bp-04h]
	mov	cx,[bp-014h]
	mov	dx,[bp-012h]
	mov	es:[si],cx
	mov	es:[si+02h],dx
	sub	bx,[bp+06h]
	sbb	ax,[bp+08h]
	mov	[bp-08h],bx
	mov	[bp-06h],ax
	mov	[bp-010h],cx
	mov	[bp-0Eh],dx
	jmp	short regspace_space_loc_0E6
regspace_space_loc_0D9:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
regspace_space_loc_0E6:
	cmp	word ptr [bp-0Ch],-1
	jnz	short regspace_space_loc_105
	cmp	word ptr [bp-0Ah],-1
	jnz	short regspace_space_loc_105
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp+06h]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	jmp	short regspace_space_loc_116
regspace_space_loc_105:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-0Ch]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
regspace_space_loc_116:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	les	bx,[bp+06h]
	sub	es:[bx+08h],ax
	sbb	es:[bx+0Ah],dx
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	jmp	short regspace_space_loc_14A
regspace_space_loc_12F:
	mov	[bp-0Ch],bx
	mov	word ptr [bp-0Ah],es
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	jmp	regspace_space_loc_023
regspace_space_loc_146:
	mov	ax,0FFFFh
	cwd
regspace_space_loc_14A:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegTakeFreeSpace	endp
	assume	cs:REGKEYS,ds:DGROUP
	public	RegResizeRecord

;** RegResizeRecord - Extend or relocate a key's data record
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR key,
;        [BP+0Eh] = FAR record, [BP+12h] = DWORD additional size.
; Try adjacent space, local free space, packing and growth before moving
; to another block. EXIT: DX:AX = FAR record pointer, or -1 on failure.
;
RegResizeRecord	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Eh
	push	si
	les	bx,[bp+0Eh]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	add	ax,[bp+012h]
	adc	dx,[bp+014h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,dx
	jnz	short regresize_resize_loc_027
	cmp	ax,0EFE0h
	jna	short regresize_resize_loc_02E
regresize_resize_loc_027:
	mov	ax,0FFFFh
	cwd
	jmp	regresize_resize_loc_39A
regresize_resize_loc_02E:
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	[bp-012h],dx
	mov	ax,[bp-04h]
	sub	ax,es:[bx]
	mov	[bp-016h],ax
	lea	ax,[bp-01Ah]
	push	ss
	push	ax
	push	dx
	push	word ptr es:[bx+04h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regresize_resize_loc_027
	les	bx,[bp+0Eh]
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx]
	adc	ax,es:[bx+02h]
	mov	[bp-0Ch],cx
	mov	[bp-0Ah],ax
	les	bx,[bp-01Ah]
	mov	ax,cx
	mov	dx,[bp-0Ah]
	mov	cx,es
	sub	ax,bx
	sbb	dx,cx
	cmp	dx,es:[bx+06h]
	ja	short regresize_resize_loc_0F4
	jc	short regresize_resize_loc_093
	cmp	ax,es:[bx+04h]
	jnc	short regresize_resize_loc_0F4
regresize_resize_loc_093:
	les	si,[bp-0Ch]
	cmp	word ptr es:[si+04h],-1
	jnz	short regresize_resize_loc_0F4
	cmp	word ptr es:[si+06h],-1
	jnz	short regresize_resize_loc_0F4
	mov	ax,es:[si]
	mov	dx,es:[si+02h]
	les	si,[bp+0Eh]
	add	ax,es:[si]
	adc	dx,es:[si+02h]
	cmp	dx,[bp-02h]
	jc	short regresize_resize_loc_0F4
	ja	short regresize_resize_loc_0C1
	cmp	ax,[bp-04h]
	jc	short regresize_resize_loc_0F4
regresize_resize_loc_0C1:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	es
	push	si
	push	cx
	push	bx
	push	cs
	call	near ptr RegExtendRecord
	add	sp,010h
	push	word ptr [bp-018h]
	push	word ptr [bp-01Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
	mov	ax,si
	mov	dx,[bp+010h]
	jmp	regresize_resize_loc_39A
regresize_resize_loc_0F4:
	mov	ax,[bp-04h]
	push	ax
	push	word ptr [bp-018h]
	push	word ptr [bp-01Ah]
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jz	short regresize_resize_loc_113
	jmp	regresize_resize_loc_2E7
regresize_resize_loc_113:
	cmp	dx,ax
	jz	short regresize_resize_loc_11A
	jmp	regresize_resize_loc_2E7
regresize_resize_loc_11A:
	les	bx,[bp-01Ah]
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	es
	push	bx
	call	far ptr RegPackDataBlock
	add	sp,08h
	or	ax,ax
	jz	short regresize_resize_loc_155
	push	word ptr [bp-04h]
	push	word ptr [bp-018h]
	push	word ptr [bp-01Ah]
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jnz	short regresize_resize_loc_152
	cmp	dx,ax
	jz	short regresize_resize_loc_155
regresize_resize_loc_152:
	jmp	regresize_resize_loc_2C8
regresize_resize_loc_155:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-012h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegGrowDataBlock
	add	sp,0Ah
	or	dx,ax
	jnz	short regresize_resize_loc_173
	jmp	regresize_resize_loc_287
regresize_resize_loc_173:
	lea	ax,[bp+0Eh]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jnz	short regresize_resize_loc_1B9
	lea	ax,[bp-08h]
	push	ss
	push	ax
	mov	ax,[bp-04h]
	les	bx,[bp+0Eh]
	sub	ax,es:[bx+0Ch]
	push	ax
	push	word ptr es:[bx+0Ch]
	lea	ax,[bx+014h]
	push	es
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegAllocateRecord
	add	sp,010h
	or	dx,ax
	jz	short regresize_resize_loc_1BC
regresize_resize_loc_1B9:
	jmp	regresize_resize_loc_027
regresize_resize_loc_1BC:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp+0Ah]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyKeyBlock
	add	sp,04h
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jz	short regresize_resize_loc_210
regresize_resize_loc_1F7:
	les	bx,[bp+0Eh]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp+0Ah]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	jmp	regresize_resize_loc_027
regresize_resize_loc_210:
	lea	ax,[bp-01Eh]
	push	ss
	push	ax
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jnz	short regresize_resize_loc_1F7
	les	bx,[bp+0Eh]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	sub	ax,08h
	sbb	dx,00h
	push	dx
	push	ax
	lea	ax,[bx+08h]
	push	es
	push	ax
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	add	ax,08h
	push	dx
	push	ax
	call	far ptr RegCopyBytes
	add	sp,0Ch
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegFreeRecord
	add	sp,08h
	push	word ptr [bp-01Ch]
	push	word ptr [bp-01Eh]
regresize_resize_loc_270:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegDirtyDataBlock
	add	sp,08h
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	jmp	regresize_resize_loc_39A
regresize_resize_loc_287:
	lea	ax,[bp-01Ah]
	push	ss
	push	ax
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetDataBlock
	add	sp,0Ch
	or	dx,ax
	jz	short regresize_resize_loc_2A6
	jmp	regresize_resize_loc_027
regresize_resize_loc_2A6:
	push	word ptr [bp-04h]
	push	word ptr [bp-018h]
	push	word ptr [bp-01Ah]
	push	cs
	call	near ptr RegTakeFreeSpace
	add	sp,06h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jnz	short regresize_resize_loc_2C8
	cmp	dx,ax
	jnz	short regresize_resize_loc_2C8
	jmp	regresize_resize_loc_027
regresize_resize_loc_2C8:
	lea	ax,[bp+0Eh]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jz	short regresize_resize_loc_2E7
	jmp	regresize_resize_loc_027
regresize_resize_loc_2E7:
	les	bx,[bp+0Eh]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	sub	ax,04h
	sbb	dx,00h
	push	dx
	push	ax
	lea	ax,[bx+04h]
	push	es
	push	ax
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	add	ax,04h
	push	dx
	push	ax
	call	far ptr RegCopyBytes
	add	sp,0Ch
	les	bx,[bp+0Eh]
	mov	word ptr es:[bx+04h],0FFFFh
	mov	word ptr es:[bx+06h],0FFFFh
	les	bx,[bp-01Ah]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	les	bx,[bp+0Eh]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	mov	ax,bx
	mov	dx,es
	sub	ax,[bp-01Ah]
	sbb	dx,[bp-018h]
	les	bx,[bp-01Ah]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	les	bx,[bp+0Eh]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	les	bx,[bp-01Ah]
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+04h]
	mov	[bp-014h],ax
	add	ax,ax
	add	ax,ax
	les	bx,[bp-01Ah]
	add	ax,es:[bx+018h]
	mov	dx,es:[bx+01Ah]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	es,dx
	mov	bx,ax
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	push	word ptr [bp-018h]
	push	word ptr [bp-01Ah]
	jmp	regresize_resize_loc_270
regresize_resize_loc_39A:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegResizeRecord	endp
	even
	assume	cs:REGKEYS,ds:DGROUP
	public	RegExtendRecord

;** RegExtendRecord - Extend a record into its adjacent free extent
;
; ENTRY: [BP+6] = FAR block, [BP+0Ah] = FAR record,
;        [BP+0Eh] = FAR free extent, [BP+12h] = DWORD new size.
;
RegExtendRecord	proc	far
	push	bp
	mov	bp,sp
	sub	sp,018h
	push	di
	push	si
	mov	word ptr [bp-014h],0FFFFh
	mov	word ptr [bp-012h],0FFFFh
	les	bx,[bp+0Eh]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	cx,[bp+012h]
	mov	si,[bp+014h]
	les	bx,[bp+0Ah]
	sub	cx,es:[bx]
	sbb	si,es:[bx+02h]
	mov	[bp-018h],cx
	mov	[bp-016h],si
	add	cx,02Ah
	adc	si,00h
	cmp	si,dx
	ja	short regextend_extend_loc_094
	jc	short regextend_extend_loc_048
	cmp	cx,ax
	jnc	short regextend_extend_loc_094
regextend_extend_loc_048:
	les	bx,[bp+0Eh]
	mov	cx,es:[bx+08h]
	mov	si,es:[bx+0Ah]
	mov	di,es
	add	bx,[bp-018h]
	adc	di,[bp-016h]
	mov	es,di
	mov	es:[bx+08h],cx
	mov	es:[bx+0Ah],si
	mov	word ptr es:[bx+04h],0FFFFh
	mov	word ptr es:[bx+06h],0FFFFh
	sub	ax,[bp-018h]
	sbb	dx,[bp-016h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	ax,di
	sub	bx,[bp+06h]
	sbb	ax,[bp+08h]
	mov	[bp-014h],bx
	mov	[bp-012h],ax
	mov	ax,[bp-018h]
	mov	dx,[bp-016h]
	jmp	short regextend_extend_loc_0AB
regextend_extend_loc_094:
	les	bx,[bp+0Eh]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
regextend_extend_loc_0AB:
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	les	bx,[bp+06h]
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx+010h]
	adc	ax,es:[bx+012h]
	cmp	cx,[bp+0Eh]
	jnz	short regextend_extend_loc_0E4
	cmp	ax,[bp+010h]
	jnz	short regextend_extend_loc_0E4
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	mov	word ptr [bp-014h],0FFFFh
	mov	word ptr [bp-012h],0FFFFh
	jmp	short regextend_extend_loc_14D
regextend_extend_loc_0E4:
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx+010h]
	adc	ax,es:[bx+012h]
	mov	[bp-04h],cx
	mov	[bp-02h],ax
	mov	cx,[bp+0Eh]
	mov	dx,[bp+010h]
	mov	si,es
	sub	cx,bx
	sbb	dx,si
	mov	[bp+0Eh],cx
	mov	[bp+010h],dx
regextend_extend_loc_108:
	mov	ax,[bp+0Eh]
	mov	dx,[bp+010h]
	les	bx,[bp-04h]
	cmp	es:[bx+08h],ax
	jnz	short regextend_extend_loc_11D
	cmp	es:[bx+0Ah],dx
	jz	short regextend_extend_loc_133
regextend_extend_loc_11D:
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	add	ax,[bp+06h]
	adc	dx,[bp+08h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	jmp	short regextend_extend_loc_108
regextend_extend_loc_133:
	cmp	es:[bx+08h],ax
	jnz	short regextend_extend_loc_14D
	cmp	es:[bx+0Ah],dx
	jnz	short regextend_extend_loc_14D
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
regextend_extend_loc_14D:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	les	bx,[bp+0Ah]
	add	es:[bx],ax
	adc	es:[bx+02h],dx
	les	bx,[bp+06h]
	sub	es:[bx+08h],ax
	sbb	es:[bx+0Ah],dx
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegExtendRecord	endp
	assume	cs:REGKEYS
	public	RegLoadKey

;** RegLoadKey - Find or load a cached key node
;
; ENTRY: [BP+6] = DWORD key offset, [BP+0Ah] = FAR file.
; A cache miss allocates and reads one node. Handles opened here are
; closed here; failed allocations are released. EXIT: DX:AX = FAR key
; payload pointer, or -1 on failure.
;
RegLoadKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,1Ch
	push	di
	push	si
	sub	ax,ax
	mov	[bp-6],ax
	mov	[bp-8],ax
	les	bx,[bp+10]
	mov	ax,es:[bx+24h]
	mov	dx,es:[bx+26h]
	mov	[bp-16],ax
	mov	[bp-14],dx
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	mov	cl,4
	call	far ptr __aFulshr
	sub	ah,ah
	add	ax,ax
	add	ax,ax
	add	ax,[bp-16]
	mov	dx,[bp-14]
	add	ax,20h
	mov	[bp-12],ax
	mov	[bp-10],dx
	les	bx,[bp-12]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
regcache_rl_test:
	mov	[bp-4],ax
	mov	[bp-2],dx
	mov	ax,dx
	or	ax,[bp-4]
	jz	short regcache_rl_found
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	mov	cx,[bp-2]
	mov	bx,[bp-4]
	mov	es,cx
	cmp	es:[bx+4],ax
	jnz	short regcache_rl_next
	cmp	es:[bx+6],dx
	jz	short regcache_rl_found
regcache_rl_next:
	mov	ax,es:[bx+8]
	mov	dx,es:[bx+10]
	jmp	short regcache_rl_test
regcache_rl_found:
	mov	ax,[bp-2]
	or	ax,[bp-4]
	jz	short regcache_rl_allocate
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	mov	[bp-8],ax
	mov	[bp-6],dx
	jmp	regcache_rl_return
regcache_rl_allocate:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,2Ch
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,8
	mov	[bp-4],ax
	mov	[bp-2],dx
	or	dx,ax
	jnz	short regcache_rl_open
	jmp	regcache_rl_return
regcache_rl_open:
	les	bx,[bp+10]
	mov	ax,es:[bx+2Ch]
	cwd
	mov	[bp-26],ax
	mov	[bp-24],dx
	mov	cx,es:[bx+2Eh]
	mov	[bp-22],cx
	or	dx,ax
	jnz	short regcache_rl_handle
	lea	ax,[bp-28]
	push	ss
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-24]
	push	word ptr [bp-26]
	push	word ptr es:[bx+22]
	push	word ptr es:[bx+20]
	call	far ptr ConfigOpen
	add	sp,16
	mov	[bp-22],ax
regcache_rl_handle:
	cmp	word ptr [bp-22],-1
	jnz	short regcache_rl_read
	jmp	regcache_rl_cleanup
regcache_rl_read:
	push	word ptr [bp-24]
	push	word ptr [bp-26]
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	add	ax,20h
	adc	dx,0
	push	dx
	push	ax
	push	word ptr [bp-22]
	call	far ptr ConfigSeek
	add	sp,14
	push	word ptr [bp-24]
	push	word ptr [bp-26]
	mov	ax,1Ch
	cwd
	push	dx
	push	ax
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	mov	cx,ax
	add	ax,10h
	push	dx
	push	ax
	push	word ptr [bp-22]
	mov	si,cx
	mov	di,dx
	call	far ptr ConfigReadAll
	add	sp,14
	cmp	ax,-1
	jnz	short regcache_rl_insert
	cmp	dx,ax
	jz	short regcache_rl_close
regcache_rl_insert:
	mov	dx,di
	mov	[bp-8],si
	mov	[bp-6],di
	mov	cx,[bp+6]
	mov	bx,[bp+8]
	mov	es,dx
	mov	es:[si+4],cx
	mov	es:[si+6],bx
	les	bx,[bp-12]
	mov	cx,es:[bx]
	mov	ax,es:[bx+2]
	mov	es,dx
	mov	es:[si+8],cx
	mov	es:[si+10],ax
	mov	es,word ptr [bp-10]
	mov	es:[bx],si
	mov	es:[bx+2],di
regcache_rl_close:
	mov	ax,[bp-24]
	or	ax,[bp-26]
	jnz	short regcache_rl_cleanup
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-24]
	push	word ptr [bp-26]
	push	word ptr [bp-22]
	les	bx,[bp+10]
	push	word ptr es:[bx+22]
	push	word ptr es:[bx+20]
	call	far ptr ConfigClose
	add	sp,14
regcache_rl_cleanup:
	mov	ax,[bp-6]
	or	ax,[bp-8]
	jnz	short regcache_rl_return
	push	word ptr [bp-2]
	push	word ptr [bp-4]
	call	far ptr ConfigFree
	add	sp,4
regcache_rl_return:
	mov	ax,[bp-6]
	or	ax,[bp-8]
	jz	short regcache_rl_fail
	mov	ax,[bp-8]
	mov	dx,[bp-6]
	add	ax,10h
	jmp	short regcache_rl_exit
regcache_rl_fail:
	mov	ax,-1
	cwd
regcache_rl_exit:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegLoadKey	endp
	even
REGKEYS	ends
	end
