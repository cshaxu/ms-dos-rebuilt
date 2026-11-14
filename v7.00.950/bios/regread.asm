;** REGREAD - Registry file storage, cache and block validation
;
; FAR C entries share the file and block services in REGFILE.
; Load, save and cache maintenance use the same block index and validators.
;
	.286
	extrn	ConfigAlloc:far
	extrn	ConfigClose:far
	extrn	ConfigOpen:far
	extrn	ConfigReadAll:far
	extrn	ConfigSeek:far
	extrn	RegCopyBytes:far
	extrn	RegInitDataBlock:far
	extrn	RegInitHeader:far
	extrn	RegInitKeyBlock:far
	extrn	RegInvalidBlock:far
	extrn	RegNotifyLoad:far
	extrn	RegReleaseFileBuffers:far
	extrn	RegStringLength:far
	extrn	RegGetKeyRecord:far
	extrn	RegLoadKey:far
	extrn	RegNameSum:far
	extrn	__aFlshl:far
	extrn	__aFulshr:far
	extrn	ConfigCreate:far
	extrn	ConfigDelete:far
	extrn	ConfigGetAttr:far
	extrn	ConfigRename:far
	extrn	ConfigWriteAll:far
	extrn	ConfigFree:far
	extrn	ConfigRealloc:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGFINAL	segment	word public 'CODE'
REGFINAL	ends
REGFILE	segment	word public 'CODE'
REGFILE	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	RegCheckPolicy:word,RegReserveSize:dword,RegReserveBlock:dword
	extrn	RegIOInhibit:word
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegPathBuffer:byte
c_common	ends
REGFINAL	segment	word public 'CODE'
REGFINAL	ends
REGFILE	segment	word public 'CODE'
	assume	cs:REGFILE,ds:DGROUP
	public	RegReadFile

;** RegReadFile - Read a registry file and initialize its cache
;
; ENTRY: [BP+6] = FAR pathname, [BP+0Ah] = FAR file descriptor.
; Descriptor flags select file-backed or newly initialized storage.
;
RegReadFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,05Eh
	push	si
	sub	ax,ax
	mov	[bp-04Ah],ax
	mov	[bp-04Ch],ax
	mov	word ptr [bp-058h],0FFFFh
	les	bx,[bp+0Ah]
	mov	es:[bx+01Eh],ax
	mov	es:[bx+01Ch],ax
	mov	ax,0FFFFh
	cwd
	mov	es:[bx+020h],ax
	mov	es:[bx+022h],dx
	mov	es:[bx+024h],ax
	mov	es:[bx+026h],dx
	mov	es:[bx+028h],ax
	mov	es:[bx+02Ah],ax
	or	byte ptr es:[bx+011h],080h
	mov	ax,RegReserveBlock+2
	or	ax,RegReserveBlock
	jnz	short regread_read_loc_079
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,01900h
	cwd
	push	dx
	push	ax
	call	far ptr ConfigAlloc
	add	sp,08h
	mov	RegReserveBlock,ax
	mov	RegReserveBlock+2,dx
	mov	ax,dx
	or	ax,RegReserveBlock
	jz	short regread_read_loc_06F
	mov	ax,01900h
	jmp	short regread_read_loc_071
regread_read_loc_06F:
	xor	ax,ax
regread_read_loc_071:
	cwd
	mov	RegReserveSize,ax
	mov	RegReserveSize+2,dx
regread_read_loc_079:
	les	bx,[bp+0Ah]
	test	byte ptr es:[bx+011h],01h
	jnz	short regread_read_loc_0E6
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegStringLength
	add	sp,04h
	inc	ax
	mov	[bp-04Eh],ax
	sub	dx,dx
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regread_read_loc_0BA
regread_read_loc_0AE:
	call	far ptr RegInvalidBlock
	mov	ax,0Eh
	cwd
	jmp	regread_read_loc_579
regread_read_loc_0BA:
	mov	ax,[bp-04Eh]
	sub	dx,dx
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp+0Ah]
	mov	es:[bx+014h],ax
	mov	es:[bx+016h],dx
regread_read_loc_0E6:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short regread_read_loc_0AE
	mov	dx,[bp-02h]
	les	bx,[bp+0Ah]
	mov	es:[bx+020h],ax
	mov	es:[bx+022h],dx
	test	byte ptr es:[bx+011h],01h
	jz	short regread_read_loc_164
	mov	word ptr es:[bx+01Ch],01h
	mov	word ptr es:[bx+01Eh],00h
	mov	cx,01h
	push	cx
	push	dx
	push	ax
	call	far ptr RegInitHeader
	add	sp,06h
regread_read_loc_130:
	mov	ax,RegCheckPolicy
	mov	[bp-052h],ax
	mov	word ptr RegCheckPolicy,0FFh
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegValidateHeader
	add	sp,04h
	or	ax,ax
	jz	short regread_read_loc_150
	jmp	regread_read_loc_201
regread_read_loc_150:
	call	far ptr RegInvalidBlock
	les	bx,[bp+0Ah]
	mov	word ptr [bp-04Ch],03F1h
	or	byte ptr es:[bx+010h],08h
	jmp	short regread_read_loc_191
regread_read_loc_164:
	lea	ax,[bp-05Eh]
	push	ss
	push	ax
	mov	ax,02h
	cwd
	push	dx
	push	ax
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigOpen
	add	sp,010h
	mov	[bp-058h],ax
	cmp	ax,0FFFFh
	jnz	short regread_read_loc_199
regread_read_loc_18C:
	mov	word ptr [bp-04Ch],03F8h
regread_read_loc_191:
	mov	word ptr [bp-04Ah],00h
	jmp	regread_read_loc_532
regread_read_loc_199:
	cmp	word ptr [bp-05Eh],00h
	jz	short regread_read_loc_1A7
	les	bx,[bp+0Ah]
	or	byte ptr es:[bx+011h],080h
regread_read_loc_1A7:
	les	bx,[bp+0Ah]
	cmp	word ptr es:[bx+02Ch],00h
	jz	short regread_read_loc_1C5
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,es:[bx+02Eh]
	mov	[bp-058h],ax
	push	ax
	call	far ptr RegNotifyLoad
	add	sp,06h
regread_read_loc_1C5:
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-058h]
	call	far ptr ConfigReadAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regread_read_loc_1EF
	cmp	dx,ax
	jz	short regread_read_loc_1F2
regread_read_loc_1EF:
	jmp	regread_read_loc_130
regread_read_loc_1F2:
	call	far ptr RegInvalidBlock
	les	bx,[bp+0Ah]
	or	byte ptr es:[bx+010h],020h
	jmp	short regread_read_loc_18C
regread_read_loc_201:
	les	bx,[bp-04h]
	and	byte ptr es:[bx+012h],0FAh
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateHeader
	add	sp,04h
	les	bx,[bp-04h]
	mov	ax,es:[bx+010h]
	les	bx,[bp+0Ah]
	mov	es:[bx+0Eh],ax
	and	byte ptr es:[bx+010h],086h
	test	byte ptr es:[bx+011h],01h
	jz	short regread_read_loc_267
	lea	ax,[bp-044h]
	push	ss
	push	ax
	call	far ptr RegInitKeyBlock
	add	sp,04h
regread_read_loc_239:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,0420h
	cwd
	mov	[bp-048h],ax
	mov	[bp-046h],dx
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regread_read_loc_2A7
	call	far ptr RegInvalidBlock
regread_read_loc_25F:
	mov	word ptr [bp-04Ch],0Eh
	jmp	regread_read_loc_191
regread_read_loc_267:
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	lea	cx,[bp-044h]
	push	ss
	push	cx
	push	word ptr [bp-058h]
	call	far ptr ConfigReadAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regread_read_loc_239
	cmp	dx,ax
	jnz	short regread_read_loc_239
	call	far ptr RegInvalidBlock
	mov	word ptr [bp-04Ch],03F1h
regread_read_loc_297:
	mov	word ptr [bp-04Ah],00h
	les	bx,[bp+0Ah]
	or	byte ptr es:[bx+010h],020h
	jmp	regread_read_loc_532
regread_read_loc_2A7:
	mov	ax,020h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-044h]
	push	ss
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp+0Ah]
	mov	es:[bx+024h],ax
	mov	es:[bx+026h],dx
	mov	word ptr [bp-050h],00h
	mov	es,word ptr [bp-02h]
regread_read_loc_2D9:
	mov	si,[bp-050h]
	add	si,si
	add	si,si
	mov	bx,[bp-04h]
	sub	ax,ax
	mov	es:[bx+si+022h],ax
	mov	es:[bx+si+020h],ax
	inc	word ptr [bp-050h]
	cmp	word ptr [bp-050h],0100h
	jc	short regread_read_loc_2D9
	les	bx,[bp+0Ah]
	push	word ptr es:[bx+026h]
	push	word ptr es:[bx+024h]
	push	cs
	call	near ptr RegValidateKeyBlock
	add	sp,04h
	or	ax,ax
	jnz	short regread_read_loc_327
regread_read_loc_30D:
	call	far ptr RegInvalidBlock
	mov	word ptr [bp-04Ch],03F1h
	mov	word ptr [bp-04Ah],00h
	les	bx,[bp+0Ah]
	or	byte ptr es:[bx+010h],08h
	jmp	regread_read_loc_532
regread_read_loc_327:
	les	bx,[bp+0Ah]
	les	bx,es:[bx+024h]
	and	byte ptr es:[bx+010h],0F8h
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateKeyBlock
	add	sp,04h
	les	bx,[bp+0Ah]
	cmp	word ptr es:[bx+0Eh],00h
	jz	short regread_read_loc_39B
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,018h
	mul	word ptr es:[bx+0Eh]
	sub	dx,dx
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regread_read_loc_369
	jmp	regread_read_loc_25F
regread_read_loc_369:
	mov	dx,[bp-02h]
	mov	[bp-05Ch],ax
	mov	[bp-05Ah],dx
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+0Eh]
	mov	[bp-050h],ax
	jmp	short regread_read_loc_385
regread_read_loc_37E:
	dec	word ptr [bp-050h]
	add	word ptr [bp-05Ch],0Ch
regread_read_loc_385:
	cmp	word ptr [bp-050h],00h
	jz	short regread_read_loc_3A5
	les	bx,[bp-05Ch]
	mov	word ptr es:[bx],0FFFFh
	mov	word ptr es:[bx+02h],0FFFFh
	jmp	short regread_read_loc_37E
regread_read_loc_39B:
	mov	word ptr [bp-04h],0FFFFh
	mov	word ptr [bp-02h],0FFFFh
regread_read_loc_3A5:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp+0Ah]
	mov	es:[bx+028h],ax
	mov	es:[bx+02Ah],dx
	mov	[bp-05Ch],ax
	mov	[bp-05Ah],dx
	les	bx,es:[bx+020h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-056h],ax
	mov	[bp-054h],dx
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+0Eh]
	mov	[bp-050h],ax
	jmp	short regread_read_loc_43F
regread_read_loc_3DA:
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	lea	cx,[bp-044h]
	push	ss
	push	cx
	push	word ptr [bp-058h]
	call	far ptr ConfigReadAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regread_read_loc_40D
	cmp	dx,ax
	jnz	short regread_read_loc_40D
	call	far ptr RegInvalidBlock
	mov	word ptr [bp-04Ch],03F7h
	jmp	regread_read_loc_297
regread_read_loc_40D:
	cmp	word ptr [bp-044h],04752h
	jz	short regread_read_loc_417
	jmp	regread_read_loc_30D
regread_read_loc_417:
	cmp	word ptr [bp-042h],04244h
	jz	short regread_read_loc_421
	jmp	regread_read_loc_30D
regread_read_loc_421:
	mov	ax,[bp-040h]
	mov	dx,[bp-03Eh]
regread_read_loc_427:
	les	bx,[bp-05Ch]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	add	[bp-056h],ax
	adc	[bp-054h],dx
	dec	word ptr [bp-050h]
	add	word ptr [bp-05Ch],0Ch
regread_read_loc_43F:
	cmp	word ptr [bp-050h],00h
	jnz	short regread_read_loc_448
	jmp	regread_read_loc_517
regread_read_loc_448:
	les	bx,[bp+0Ah]
	test	byte ptr es:[bx+011h],01h
	jnz	short regread_read_loc_46E
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-054h]
	push	word ptr [bp-056h]
	push	word ptr [bp-058h]
	call	far ptr ConfigSeek
	add	sp,0Eh
regread_read_loc_46E:
	mov	ax,[bp-056h]
	mov	dx,[bp-054h]
	les	bx,[bp-05Ch]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	les	bx,[bp+0Ah]
	test	byte ptr es:[bx+011h],01h
	jnz	short regread_read_loc_48C
	jmp	regread_read_loc_3DA
regread_read_loc_48C:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,01000h
	cwd
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short regread_read_loc_4E0
	push	word ptr [bp-02h]
	push	ax
	call	far ptr RegInitDataBlock
	add	sp,04h
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp-05Ch]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	ax,01h
	cwd
	push	dx
	push	ax
	mov	ax,03FCh
	cwd
	push	dx
	push	ax
	push	cs
	call	near ptr RegAllocate
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regread_read_loc_4E3
regread_read_loc_4E0:
	jmp	regread_read_loc_25F
regread_read_loc_4E3:
	push	word ptr [bp-02h]
	push	ax
	les	bx,[bp-05Ch]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegIndexBlock
	add	sp,08h
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp-05Ch]
	les	bx,es:[bx]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	jmp	regread_read_loc_427
regread_read_loc_517:
	les	bx,[bp+0Ah]
	les	bx,es:[bx+024h]
	test	byte ptr es:[bx+010h],08h
	jnz	short regread_read_loc_532
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	cs
	call	near ptr RegRebuildNameHashes
	add	sp,04h
regread_read_loc_532:
	mov	ax,[bp-052h]
	mov	RegCheckPolicy,ax
	mov	ax,[bp-04Ah]
	or	ax,[bp-04Ch]
	jz	short regread_read_loc_54E
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegReleaseFileBuffers
	add	sp,04h
regread_read_loc_54E:
	cmp	word ptr [bp-058h],-1
	jz	short regread_read_loc_573
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	push	word ptr [bp-058h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigClose
	add	sp,0Eh
regread_read_loc_573:
	mov	ax,[bp-04Ch]
	mov	dx,[bp-04Ah]
regread_read_loc_579:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegReadFile	endp
	assume	cs:REGFILE,ds:DGROUP
	public	RegRebuildNameHashes

;** RegRebuildNameHashes - Rebuild loaded key name hashes
;
; ENTRY: [BP+6] = FAR file descriptor.
; Uses the shared path buffer; skips free key extents.
;
RegRebuildNameHashes	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	push	di
	push	si
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	bx,ax
	mov	es,dx
	or	byte ptr es:[bx+010h],08h
	and	byte ptr es:[bx+010h],0FAh
	mov	word ptr [bp-08h],020h
	mov	word ptr [bp-06h],00h
reghash_hash_loc_031:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-04h]
	cmp	es:[bx+06h],dx
	jnc	short reghash_hash_loc_043
	jmp	reghash_hash_loc_168
reghash_hash_loc_043:
	ja	short reghash_hash_loc_04E
	cmp	es:[bx+04h],ax
	ja	short reghash_hash_loc_04E
	jmp	reghash_hash_loc_168
reghash_hash_loc_04E:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	dx
	push	ax
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	mov	bx,ax
	mov	es,dx
	mov	cx,es:[bx+02h]
	or	cx,es:[bx]
	jnz	short reghash_hash_loc_0EE
	cmp	word ptr es:[bx+018h],-1
	jnz	short reghash_hash_loc_07F
	cmp	word ptr es:[bx+01Ah],-1
	jz	short reghash_hash_loc_0E4
reghash_hash_loc_07F:
	lea	si,[bp-010h]
	push	ss
	push	si
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	mov	di,bx
	mov	si,es
	call	far ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jnz	short reghash_hash_loc_0E4
	les	bx,[bp-010h]
	sub	dx,dx
	mov	ax,es:[bx+0Ch]
	push	dx
	push	ax
	lea	ax,[bx+014h]
	push	es
	push	ax
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegCopyBytes
	add	sp,0Ch
	les	bx,[bp-010h]
	mov	bx,es:[bx+0Ch]
	mov	byte ptr RegPathBuffer[bx],00h
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegNameSum
	add	sp,04h
	mov	es,si
	mov	es:[di+04h],ax
	mov	es:[di+06h],dx
	les	bx,[bp-04h]
	and	byte ptr es:[bx+010h],0FAh
reghash_hash_loc_0E4:
	add	word ptr [bp-08h],01Ch
	adc	word ptr [bp-06h],00h
	jmp	short reghash_hash_loc_10A
reghash_hash_loc_0EE:
	cmp	word ptr es:[bx],00h
	jnz	short reghash_hash_loc_168
	cmp	word ptr es:[bx+02h],08000h
	jnz	short reghash_hash_loc_168
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	add	[bp-08h],ax
	adc	[bp-06h],dx
reghash_hash_loc_10A:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	cl,0Ch
	call	far ptr __aFulshr
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,dx
	jnz	short reghash_hash_loc_125
	or	ax,ax
	jz	short reghash_hash_loc_142
reghash_hash_loc_125:
	mov	cl,0Ch
	mov	bx,ax
	mov	si,dx
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	add	ax,01Ch
	adc	dx,00h
	mov	di,bx
	call	far ptr __aFulshr
	cmp	si,dx
	jna	short reghash_hash_loc_145
reghash_hash_loc_142:
	jmp	reghash_hash_loc_031
reghash_hash_loc_145:
	jc	short reghash_hash_loc_14E
	cmp	di,ax
	jc	short reghash_hash_loc_14E
	jmp	reghash_hash_loc_031
reghash_hash_loc_14E:
	mov	ax,di
	mov	dx,si
	add	ax,01h
	adc	dx,00h
	mov	cl,0Ch
	call	far ptr __aFlshl
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	jmp	reghash_hash_loc_031
reghash_hash_loc_168:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyKeyBlock
	add	sp,04h
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegRebuildNameHashes	endp
	even
	assume	cs:REGFILE,ds:DGROUP
	public	RegSaveFile

;** RegSaveFile - Save changed registry storage
;
; ENTRY: [BP+6] = FAR file descriptor.
; Pending layout changes require a replacement file; otherwise write
; changed blocks in place. Both paths use the same block writer.
;
RegSaveFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0220h
	push	si
	mov	ax,0FFFFh
	mov	[bp-02h],ax
	mov	[bp-04h],ax
	sub	ax,ax
	mov	[bp-01Ah],ax
	mov	[bp-01Ch],ax
	cmp	RegIOInhibit,ax
	jz	short regsave_save_loc_026
regsave_save_loc_01F:
	xor	ax,ax
regsave_save_loc_021:
	xor	dx,dx
	jmp	regsave_save_loc_728
regsave_save_loc_026:
	les	bx,[bp+06h]
	test	byte ptr es:[bx+010h],01h
	jz	short regsave_save_loc_01F
	cmp	es:[bx+02Ch],ax
	jnz	short regsave_save_loc_01F
	test	byte ptr es:[bx+010h],038h
	jz	short regsave_save_loc_042
regsave_save_loc_03D:
	mov	ax,03F7h
	jmp	short regsave_save_loc_021
regsave_save_loc_042:
	push	word ptr es:[bx+022h]
	push	word ptr es:[bx+020h]
	push	cs
	call	near ptr RegValidateHeader
	add	sp,04h
	or	ax,ax
	jz	short regsave_save_loc_06B
	les	bx,[bp+06h]
	push	word ptr es:[bx+026h]
	push	word ptr es:[bx+024h]
	push	cs
	call	near ptr RegValidateKeyBlock
	add	sp,04h
	or	ax,ax
	jnz	short regsave_save_loc_075
regsave_save_loc_06B:
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],010h
	jmp	short regsave_save_loc_03D
regsave_save_loc_075:
	les	bx,[bp+06h]
	test	byte ptr es:[bx+011h],040h
	jnz	short regsave_save_loc_01F
	or	byte ptr es:[bx+011h],040h
	and	word ptr es:[bx+010h],0F79Fh
	push	es
	push	bx
	push	cs
	call	near ptr RegHasPendingState
	add	sp,04h
	mov	[bp-08h],ax
	lea	ax,[bp-021Eh]
	push	ss
	push	ax
	cmp	word ptr [bp-08h],01h
	sbb	ax,ax
	neg	ax
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigOpen
	add	sp,010h
	mov	[bp-02h],ax
	cmp	ax,0FFFFh
	jz	short regsave_save_loc_0C9
	jmp	regsave_save_loc_1E9
regsave_save_loc_0C9:
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],020h
regsave_save_loc_0D1:
	mov	word ptr [bp-01Ch],03F8h
regsave_save_loc_0D6:
	mov	word ptr [bp-01Ah],00h
regsave_save_loc_0DB:
	cmp	word ptr [bp-02h],-1
	jz	short regsave_save_loc_106
	cmp	word ptr [bp-08h],01h
	sbb	ax,ax
	neg	ax
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-02h]
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigClose
	add	sp,0Eh
regsave_save_loc_106:
	mov	ax,[bp-02h]
	cmp	[bp-04h],ax
	jz	short regsave_save_loc_12F
	cmp	word ptr [bp-04h],-1
	jz	short regsave_save_loc_12F
	mov	ax,01h
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-04h]
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigClose
	add	sp,0Eh
regsave_save_loc_12F:
	mov	ax,[bp-01Ah]
	or	ax,[bp-01Ch]
	jz	short regsave_save_loc_13A
	jmp	regsave_save_loc_62F
regsave_save_loc_13A:
	cmp	word ptr [bp-08h],00h
	jnz	short regsave_save_loc_143
	jmp	regsave_save_loc_649
regsave_save_loc_143:
	mov	al,073h
	push	ax
	lea	cx,[bp-021Ch]
	push	ss
	push	cx
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	push	cs
	call	near ptr RegMakeTempName
	add	sp,0Ah
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-021Ch]
	push	ss
	push	ax
	call	far ptr ConfigDelete
	add	sp,08h
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-021Ch]
	push	ss
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigRename
	add	sp,0Ch
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigRename
	add	sp,0Ch
	or	ax,ax
	jz	short regsave_save_loc_1B1
	jmp	regsave_save_loc_625
regsave_save_loc_1B1:
	push	ax
	push	ax
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigDelete
	add	sp,08h
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	lea	ax,[bp-021Ch]
	push	ss
	push	ax
	call	far ptr ConfigRename
	add	sp,0Ch
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],040h
	jmp	regsave_save_loc_649
regsave_save_loc_1E9:
	cmp	word ptr [bp-08h],00h
	jz	short regsave_save_loc_24F
	mov	al,07Eh
	push	ax
	lea	cx,[bp-011Ch]
	push	ss
	push	cx
	les	bx,[bp+06h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	push	cs
	call	near ptr RegMakeTempName
	add	sp,0Ah
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigGetAttr
	add	sp,08h
	or	dx,ax
	jz	short regsave_save_loc_232
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigDelete
	add	sp,08h
regsave_save_loc_232:
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-011Ch]
	push	ss
	push	ax
	call	far ptr ConfigCreate
	add	sp,08h
	mov	[bp-04h],ax
	cmp	ax,0FFFFh
	jnz	short regsave_save_loc_252
	jmp	regsave_save_loc_455
regsave_save_loc_24F:
	mov	[bp-04h],ax
regsave_save_loc_252:
	les	bx,[bp+06h]
	les	bx,es:[bx+020h]
	test	byte ptr es:[bx+012h],01h
	jnz	short regsave_save_loc_266
	cmp	word ptr [bp-08h],00h
	jz	short regsave_save_loc_292
regsave_save_loc_266:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+022h]
	push	word ptr es:[bx+020h]
	push	word ptr [bp-04h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regsave_save_loc_292
	cmp	dx,ax
	jnz	short regsave_save_loc_292
	jmp	regsave_save_loc_455
regsave_save_loc_292:
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	test	byte ptr es:[bx+010h],01h
	jnz	short regsave_save_loc_2A6
	cmp	word ptr [bp-08h],00h
	jz	short regsave_save_loc_2E9
regsave_save_loc_2A6:
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-04h]
	call	far ptr ConfigSeek
	add	sp,0Eh
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	push	word ptr es:[bx+06h]
	push	word ptr es:[bx+04h]
	push	es
	push	bx
	push	word ptr [bp-04h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regsave_save_loc_2E9
	cmp	dx,ax
	jnz	short regsave_save_loc_2E9
	jmp	regsave_save_loc_455
regsave_save_loc_2E9:
	les	bx,[bp+06h]
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,ax
	mov	ax,0Ch
	mov	si,dx
	mul	word ptr es:[bx+0Eh]
	add	cx,ax
	mov	[bp-010h],cx
	mov	[bp-0Eh],si
	mov	word ptr [bp-06h],00h
	jmp	short regsave_save_loc_349
regsave_save_loc_314:
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	add	ax,es:[bx+08h]
	adc	dx,es:[bx+0Ah]
regsave_save_loc_327:
	les	bx,[bp-010h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	inc	word ptr [bp-06h]
	add	word ptr [bp-014h],0Ch
	add	word ptr [bp-010h],0Ch
regsave_save_loc_349:
	mov	ax,[bp-06h]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	jna	short regsave_save_loc_394
	les	bx,[bp-014h]
	mov	cx,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	les	bx,[bp-010h]
	mov	es:[bx+08h],cx
	mov	es:[bx+0Ah],dx
	les	bx,[bp-014h]
	mov	cx,es:[bx]
	mov	dx,es:[bx+02h]
	les	bx,[bp-010h]
	mov	es:[bx],cx
	mov	es:[bx+02h],dx
	or	ax,ax
	jnz	short regsave_save_loc_314
	les	bx,[bp+06h]
	les	bx,es:[bx+020h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regsave_save_loc_327
regsave_save_loc_394:
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,ax
	mov	ax,0Ch
	mov	si,dx
	mul	word ptr es:[bx+0Eh]
	add	cx,ax
	mov	[bp-010h],cx
	mov	[bp-0Eh],si
	mov	word ptr [bp-06h],00h
	jmp	regsave_save_loc_46B
regsave_save_loc_3BD:
	les	bx,[bp-018h]
	mov	ax,es:[bx+0Ch]
	test	al,08h
	jz	short regsave_save_loc_3D4
	mov	ax,[bp-06h]
	cmp	es:[bx+0Eh],ax
	jz	short regsave_save_loc_3EE
	jmp	regsave_save_loc_4A0
regsave_save_loc_3D4:
	and	al,0FBh
	mov	es:[bx+0Ch],ax
	mov	word ptr es:[bx+0Eh],00h
	mov	ax,08h
	mov	dx,[bp-06h]
	or	es:[bx+0Ch],ax
	or	es:[bx+0Eh],dx
regsave_save_loc_3EE:
	les	bx,[bp-018h]
	test	byte ptr es:[bx+0Ch],01h
	jz	short regsave_save_loc_427
	les	bx,[bp-014h]
	push	word ptr es:[bx+0Ah]
	push	word ptr es:[bx+08h]
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	cs
	call	near ptr RegPackDataBlock
	add	sp,08h
	or	ax,ax
	jz	short regsave_save_loc_427
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyDataBlock
	add	sp,08h
regsave_save_loc_427:
	les	bx,[bp-018h]
	test	byte ptr es:[bx+0Ch],01h
	jnz	short regsave_save_loc_437
	cmp	word ptr [bp-08h],00h
	jz	short regsave_save_loc_460
regsave_save_loc_437:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	mov	ax,01h
	push	ax
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegWriteDataBlock
	add	sp,0Ch
	or	dx,ax
	jz	short regsave_save_loc_460
regsave_save_loc_455:
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],040h
	jmp	regsave_save_loc_0D1
regsave_save_loc_460:
	inc	word ptr [bp-06h]
	add	word ptr [bp-014h],0Ch
	add	word ptr [bp-010h],0Ch
regsave_save_loc_46B:
	mov	ax,[bp-06h]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	jna	short regsave_save_loc_4B5
	les	bx,[bp-010h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	cmp	ax,0FFFFh
	jnz	short regsave_save_loc_490
	cmp	dx,ax
	jz	short regsave_save_loc_460
regsave_save_loc_490:
	push	dx
	push	ax
	push	cs
	call	near ptr RegValidateDataBlock
	add	sp,04h
	or	ax,ax
	jz	short regsave_save_loc_4A0
	jmp	regsave_save_loc_3BD
regsave_save_loc_4A0:
	call	far ptr RegInvalidBlock
regsave_save_loc_4A5:
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],010h
	mov	word ptr [bp-01Ch],03F7h
	jmp	regsave_save_loc_0D6
regsave_save_loc_4B5:
	cmp	word ptr [bp-08h],00h
	jnz	short regsave_save_loc_4BE
	jmp	regsave_save_loc_0DB
regsave_save_loc_4BE:
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,ax
	mov	ax,0Ch
	mov	si,dx
	mul	word ptr es:[bx+0Eh]
	add	cx,ax
	mov	[bp-010h],cx
	mov	[bp-0Eh],si
	mov	word ptr [bp-06h],00h
	jmp	regsave_save_loc_5AA
regsave_save_loc_4E7:
	les	bx,[bp-0Ch]
	cmp	word ptr es:[bx],-1
	jnz	short regsave_save_loc_4F7
	cmp	word ptr es:[bx+02h],-1
	jz	short regsave_save_loc_52D
regsave_save_loc_4F7:
	les	bx,es:[bx]
	test	byte ptr es:[bx+0Ch],01h
	jnz	short regsave_save_loc_52D
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegFlushDataBlock
	add	sp,08h
	mov	ax,0Ch
	les	bx,[bp+06h]
	mul	word ptr es:[bx+0Eh]
	mov	si,ax
	les	bx,[bp-0Ch]
	sub	ax,ax
	mov	es:[bx+si+0Ah],ax
	mov	es:[bx+si+08h],ax
regsave_save_loc_52D:
	inc	word ptr [bp-0220h]
	add	word ptr [bp-0Ch],0Ch
regsave_save_loc_535:
	mov	ax,[bp-0220h]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	ja	short regsave_save_loc_4E7
	push	word ptr [bp-02h]
	push	word ptr [bp-06h]
	push	es
	push	bx
	push	cs
	call	near ptr RegLoadDataBlock
	add	sp,08h
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	or	dx,ax
	jz	short regsave_save_loc_55E
	jmp	regsave_save_loc_0DB
regsave_save_loc_55E:
	les	bx,[bp-014h]
	les	bx,es:[bx]
	mov	ax,es
	les	si,[bp-010h]
	mov	es:[si],bx
	mov	es:[si+02h],ax
	mov	es,ax
	mov	ax,[bp-06h]
	cmp	es:[bx+0Eh],ax
	jz	short regsave_save_loc_57E
	jmp	regsave_save_loc_4A5
regsave_save_loc_57E:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	mov	ax,01h
	push	ax
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegWriteDataBlock
	add	sp,0Ch
	or	dx,ax
	jz	short regsave_save_loc_59F
	jmp	regsave_save_loc_455
regsave_save_loc_59F:
	inc	word ptr [bp-06h]
	add	word ptr [bp-014h],0Ch
	add	word ptr [bp-010h],0Ch
regsave_save_loc_5AA:
	mov	ax,[bp-06h]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	ja	short regsave_save_loc_5B9
	jmp	regsave_save_loc_0DB
regsave_save_loc_5B9:
	les	bx,[bp-014h]
	mov	cx,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-018h],cx
	mov	[bp-016h],dx
	cmp	cx,-1
	jnz	short regsave_save_loc_59F
	cmp	dx,cx
	jnz	short regsave_save_loc_59F
	les	bx,[bp-010h]
	mov	cx,es:[bx+0Ah]
	or	cx,es:[bx+08h]
	jz	short regsave_save_loc_59F
	push	word ptr [bp-02h]
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegLoadDataBlock
	add	sp,08h
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	or	dx,ax
	jnz	short regsave_save_loc_5FD
	jmp	regsave_save_loc_55E
regsave_save_loc_5FD:
	cmp	ax,0Eh
	jnz	short regsave_save_loc_608
	cmp	word ptr [bp-01Ah],00h
	jz	short regsave_save_loc_60B
regsave_save_loc_608:
	jmp	regsave_save_loc_0DB
regsave_save_loc_60B:
	les	bx,[bp+06h]
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	mov	word ptr [bp-0220h],00h
	jmp	regsave_save_loc_535
regsave_save_loc_625:
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-021Ch]
	jmp	short regsave_save_loc_63F
regsave_save_loc_62F:
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],040h
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-011Ch]
regsave_save_loc_63F:
	push	ss
	push	ax
	call	far ptr ConfigDelete
	add	sp,08h
regsave_save_loc_649:
	mov	ax,[bp-01Ah]
	or	ax,[bp-01Ch]
	jz	short regsave_save_loc_654
	jmp	regsave_save_loc_71A
regsave_save_loc_654:
	les	bx,[bp+06h]
	and	byte ptr es:[bx+010h],0FEh
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,ax
	mov	ax,0Ch
	mov	si,dx
	mul	word ptr es:[bx+0Eh]
	add	cx,ax
	mov	[bp-010h],cx
	mov	[bp-0Eh],si
	mov	word ptr [bp-06h],00h
	jmp	short regsave_save_loc_6D5
regsave_save_loc_684:
	les	bx,[bp-010h]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp-014h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	cmp	ax,0FFFFh
	jnz	short regsave_save_loc_6B0
	cmp	dx,ax
	jz	short regsave_save_loc_6CA
regsave_save_loc_6B0:
	mov	bx,ax
	mov	es,dx
	and	byte ptr es:[bx+0Ch],0F8h
	les	bx,[bp-014h]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegValidateDataBlock
	add	sp,04h
regsave_save_loc_6CA:
	inc	word ptr [bp-06h]
	add	word ptr [bp-014h],0Ch
	add	word ptr [bp-010h],0Ch
regsave_save_loc_6D5:
	mov	ax,[bp-06h]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	ja	short regsave_save_loc_684
	les	bx,es:[bx+024h]
	and	byte ptr es:[bx+010h],0F8h
	les	bx,[bp+06h]
	push	word ptr es:[bx+026h]
	push	word ptr es:[bx+024h]
	push	cs
	call	near ptr RegValidateKeyBlock
	add	sp,04h
	les	bx,[bp+06h]
	les	bx,es:[bx+020h]
	and	byte ptr es:[bx+012h],0FAh
	les	bx,[bp+06h]
	push	word ptr es:[bx+022h]
	push	word ptr es:[bx+020h]
	push	cs
	call	near ptr RegValidateHeader
	add	sp,04h
regsave_save_loc_71A:
	les	bx,[bp+06h]
	and	byte ptr es:[bx+011h],0BFh
	mov	ax,[bp-01Ch]
	mov	dx,[bp-01Ah]
regsave_save_loc_728:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegSaveFile	endp
	even
	assume	cs:REGFILE,ds:DGROUP
	public	RegWriteDataBlock

;** RegWriteDataBlock - Validate and write one cached block
;
; ENTRY: [BP+6] = WORD file handle, [BP+8] = FAR cache entry,
;        [BP+0Ch] = WORD seek flag, [BP+0Eh] = FAR file descriptor.
; EXIT: DX:AX = status. Unless the file's save flag bypasses validation,
; validate before writing and refresh the checksum after clearing flags.
;
RegWriteDataBlock	proc	far
	push	bp
	mov	bp,sp
	cmp	RegIOInhibit,0
	jz	short regwrite_rw_validate
	mov	ax,0A7h
regwrite_rw_status:
	xor	dx,dx
	jmp	regwrite_rw_exit
regwrite_rw_validate:
	les	bx,[bp+14]
	test	byte ptr es:[bx+11h],40h
	jnz	short regwrite_rw_seek
	les	bx,[bp+8]
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	cs
	call	near ptr RegValidateDataBlock
	mov	sp,bp
	or	ax,ax
	jnz	short regwrite_rw_seek
	mov	ax,3F1h
	jmp	short regwrite_rw_status
regwrite_rw_seek:
	cmp	word ptr [bp+12],0
	jz	short regwrite_rw_write
	les	bx,[bp+14]
	mov	ax,es:[bx+2Ch]
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+8]
	push	word ptr es:[bx+6]
	push	word ptr es:[bx+4]
	push	word ptr [bp+6]
	call	far ptr ConfigSeek
	mov	sp,bp
regwrite_rw_write:
	les	bx,[bp+14]
	mov	ax,es:[bx+2Ch]
	cwd
	push	dx
	push	ax
	les	bx,[bp+8]
	push	word ptr es:[bx+10]
	push	word ptr es:[bx+8]
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	word ptr [bp+6]
	call	far ptr ConfigWriteAll
	mov	sp,bp
	cmp	ax,-1
	jnz	short regwrite_rw_update
	cmp	dx,ax
	jnz	short regwrite_rw_update
	mov	ax,3F8h
	jmp	regwrite_rw_status
regwrite_rw_update:
	les	bx,[bp+14]
	test	byte ptr es:[bx+11h],40h
	jnz	short regwrite_rw_ok
	les	bx,[bp+8]
	les	bx,es:[bx]
	and	byte ptr es:[bx+0Ch],0F8h
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateDataBlock
	mov	sp,bp
regwrite_rw_ok:
	xor	ax,ax
	jmp	regwrite_rw_status
regwrite_rw_exit:
	mov	sp,bp
	pop	bp
	ret
RegWriteDataBlock	endp
	even
	assume	cs:REGFILE,ds:DGROUP
	public	RegLoadDataBlock

;** RegLoadDataBlock - Read and index one data block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = WORD block index,
;        [BP+0Ch] = WORD handle (-1 opens the file here).
; EXIT: DX:AX = status. Restore the check policy, close locally opened
; files and release allocated buffers on the error cleanup path.
;
RegLoadDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Eh
	push	di
	push	si
	sub	ax,ax
	mov	[bp-02h],ax
	mov	[bp-04h],ax
	mov	[bp-06h],ax
	mov	[bp-08h],ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
	mov	[bp-018h],ax
	cmp	RegIOInhibit,ax
	jz	short regload_load_loc_02D
	mov	ax,0A7h
regload_load_loc_028:
	xor	dx,dx
	jmp	regload_load_loc_331
regload_load_loc_02D:
	mov	ax,[bp+0Ah]
	les	bx,[bp+06h]
	cmp	es:[bx+0Eh],ax
	ja	short regload_load_loc_04B
	call	far ptr RegInvalidBlock
	les	bx,[bp+06h]
	mov	ax,03F1h
	or	byte ptr es:[bx+010h],08h
	jmp	short regload_load_loc_028
regload_load_loc_04B:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	bx,ax
	mov	si,[bp+06h]
	les	si,es:[si+028h]
	mov	ax,es:[bx+si+08h]
	mov	dx,es:[bx+si+0Ah]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
regload_load_loc_068:
	mov	ax,[bp-018h]
	inc	word ptr [bp-018h]
	cmp	ax,01h
	jng	short regload_load_loc_076
	jmp	regload_load_loc_10F
regload_load_loc_076:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	si,ax
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	cmp	word ptr es:[bx+si],-1
	jnz	short regload_load_loc_092
	cmp	word ptr es:[bx+si+02h],-1
	jz	short regload_load_loc_096
regload_load_loc_092:
	xor	ax,ax
	jmp	short regload_load_loc_028
regload_load_loc_096:
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	call	far ptr ConfigAlloc
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regload_load_loc_0D1
regload_load_loc_0B2:
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegMaintainCache
	add	sp,08h
	mov	word ptr [bp-0Ch],0Eh
	mov	word ptr [bp-0Ah],00h
	jmp	short regload_load_loc_068
regload_load_loc_0D1:
	mov	ax,01h
	cwd
	push	dx
	push	ax
	mov	ax,03FCh
	cwd
	push	dx
	push	ax
	call	far ptr ConfigAlloc
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	or	dx,ax
	jnz	short regload_load_loc_107
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
	add	sp,04h
	sub	ax,ax
	mov	[bp-02h],ax
	mov	[bp-04h],ax
	jmp	short regload_load_loc_0B2
regload_load_loc_107:
	sub	ax,ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
regload_load_loc_10F:
	mov	ax,[bp+0Ch]
	mov	[bp-016h],ax
	cmp	ax,0FFFFh
	jnz	short regload_load_loc_15C
	lea	ax,[bp-01Ch]
	push	ss
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigOpen
	add	sp,010h
	mov	[bp-016h],ax
	cmp	ax,0FFFFh
	jnz	short regload_load_loc_15C
	call	far ptr RegInvalidBlock
	les	bx,[bp+06h]
	mov	word ptr [bp-0Ch],03F8h
	or	byte ptr es:[bx+010h],020h
	mov	word ptr [bp-0Ah],00h
regload_load_loc_15C:
	mov	ax,RegCheckPolicy
	mov	[bp-01Ah],ax
	mov	word ptr RegCheckPolicy,0FFh
	mov	ax,[bp-0Ah]
	or	ax,[bp-0Ch]
	jz	short regload_load_loc_173
	jmp	regload_load_loc_2C5
regload_load_loc_173:
	les	bx,[bp+06h]
	cmp	word ptr es:[bx+02Ch],00h
	jz	short regload_load_loc_191
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,es:[bx+02Eh]
	mov	[bp-016h],ax
	push	ax
	call	far ptr RegNotifyLoad
	add	sp,06h
regload_load_loc_191:
	les	bx,[bp+06h]
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	sub	cx,cx
	push	cx
	push	cx
	mov	cx,ax
	mov	ax,0Ch
	mov	si,dx
	mul	word ptr [bp+0Ah]
	mov	di,bx
	les	bx,es:[di+028h]
	mov	di,ax
	push	word ptr es:[bx+di+06h]
	push	word ptr es:[bx+di+04h]
	push	word ptr [bp-016h]
	mov	di,cx
	call	far ptr ConfigSeek
	add	sp,0Eh
	push	si
	push	di
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-016h]
	call	far ptr ConfigReadAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regload_load_loc_1FD
	cmp	dx,ax
	jnz	short regload_load_loc_1FD
	les	bx,[bp+06h]
	mov	word ptr [bp-0Ch],03F8h
	or	byte ptr es:[bx+010h],020h
regload_load_loc_1F5:
	mov	word ptr [bp-0Ah],00h
	jmp	regload_load_loc_2C5
regload_load_loc_1FD:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	les	bx,[bp-04h]
	mov	[bp-010h],bx
	mov	word ptr [bp-0Eh],es
	cmp	es:[bx+04h],ax
	jnz	short regload_load_loc_239
	cmp	es:[bx+06h],dx
	jnz	short regload_load_loc_239
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateDataBlock
	add	sp,04h
	or	ax,ax
	jz	short regload_load_loc_239
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	test	al,08h
	jz	short regload_load_loc_24D
	mov	ax,[bp+0Ah]
	cmp	es:[bx+0Eh],ax
	jz	short regload_load_loc_24D
regload_load_loc_239:
	call	far ptr RegInvalidBlock
	les	bx,[bp+06h]
	mov	word ptr [bp-0Ch],03F7h
	or	byte ptr es:[bx+010h],08h
	jmp	short regload_load_loc_1F5
regload_load_loc_24D:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-010h]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	push	dx
	push	ax
	push	es
	push	bx
	push	cs
	call	near ptr RegIndexBlock
	add	sp,08h
	or	ax,ax
	jnz	short regload_load_loc_275
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],08h
regload_load_loc_275:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	si,ax
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	mov	es:[bx+si],ax
	mov	es:[bx+si+02h],dx
	mov	bx,ax
	mov	es,dx
	mov	cx,es:[bx+0Ch]
	and	cl,0F8h
	mov	es:[bx+0Ch],cx
	mov	word ptr es:[bx+0Eh],00h
	mov	cx,08h
	mov	si,[bp+0Ah]
	or	es:[bx+0Ch],cx
	or	es:[bx+0Eh],si
	push	dx
	push	ax
	push	cs
	call	near ptr RegValidateDataBlock
	add	sp,04h
	sub	ax,ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
regload_load_loc_2C5:
	mov	ax,[bp-01Ah]
	mov	RegCheckPolicy,ax
	cmp	word ptr [bp+0Ch],-1
	jnz	short regload_load_loc_2F2
	sub	ax,ax
	push	ax
	push	ax
	les	bx,[bp+06h]
	mov	ax,es:[bx+02Ch]
	cwd
	push	dx
	push	ax
	push	word ptr [bp-016h]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigClose
	add	sp,0Eh
regload_load_loc_2F2:
	mov	ax,[bp-0Ah]
	or	ax,[bp-0Ch]
	jz	short regload_load_loc_32B
	call	far ptr RegInvalidBlock
	mov	ax,[bp-02h]
	or	ax,[bp-04h]
	jz	short regload_load_loc_315
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
	add	sp,04h
regload_load_loc_315:
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jz	short regload_load_loc_32B
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr ConfigFree
	add	sp,04h
regload_load_loc_32B:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
regload_load_loc_331:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegLoadDataBlock	endp
	even
	assume	cs:REGFILE,ds:DGROUP
	public	RegMaintainCache

;** RegMaintainCache - Maintain cached files in both list directions
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR block to retain.
; Save pending state before scanning eligible blocks.
;
RegMaintainCache	proc	far
	push	bp
	mov	bp,sp
	sub	sp,04h
	cmp	word ptr RegIOInhibit,00h
	jz	short regmaint_maint_loc_010
	jmp	regmaint_maint_loc_0CD
regmaint_maint_loc_010:
	mov	ax,[bp+06h]
	mov	dx,[bp+08h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	push	dx
	push	ax
	push	cs
	call	near ptr RegHasPendingState
	add	sp,04h
	or	ax,ax
	jz	short regmaint_maint_loc_036
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
regmaint_maint_loc_02F:
	push	cs
	call	near ptr RegSaveFile
	add	sp,04h
regmaint_maint_loc_036:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegScanDataBlocks
	add	sp,08h
	les	bx,[bp-04h]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regmaint_maint_loc_063
	cmp	dx,ax
	jz	short regmaint_maint_loc_078
regmaint_maint_loc_063:
	push	dx
	push	ax
	push	cs
	call	near ptr RegHasPendingState
	add	sp,04h
	or	ax,ax
	jz	short regmaint_maint_loc_036
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	jmp	short regmaint_maint_loc_02F
regmaint_maint_loc_078:
	mov	ax,[bp+06h]
	mov	dx,[bp+08h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
regmaint_maint_loc_084:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regmaint_maint_loc_09E
	cmp	dx,ax
	jz	short regmaint_maint_loc_0CD
regmaint_maint_loc_09E:
	push	dx
	push	ax
	push	cs
	call	near ptr RegHasPendingState
	add	sp,04h
	or	ax,ax
	jz	short regmaint_maint_loc_0B8
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegSaveFile
	add	sp,04h
regmaint_maint_loc_0B8:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	cs
	call	near ptr RegScanDataBlocks
	add	sp,08h
	jmp	short regmaint_maint_loc_084
regmaint_maint_loc_0CD:
	mov	sp,bp
	pop	bp
	ret
RegMaintainCache	endp
	even
	assume	cs:REGFILE
	public	RegScanDataBlocks

;** RegScanDataBlocks - Release eligible cached blocks
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR block to retain.
; Skip pending-state files, unused entries and the retained block.
; Compare each remaining block's reference word with its scan index.
;
RegScanDataBlocks	proc	far
	push	bp
	mov	bp,sp
	sub	sp,6
	les	bx,[bp+6]
	mov	ax,es:[bx+28h]
	mov	dx,es:[bx+2Ah]
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,-1
	jnz	short regscan_rc_state
	cmp	dx,ax
	jz	short regscan_rc_exit
regscan_rc_state:
	push	es
	push	bx
	push	cs
	call	near ptr RegHasPendingState
	add	sp,4
	or	ax,ax
	jnz	short regscan_rc_exit
	mov	[bp-6],ax
	jmp	short regscan_rc_test
regscan_rc_entry:
	les	bx,[bp-4]
	cmp	word ptr es:[bx],-1
	jnz	short regscan_rc_retained
	cmp	word ptr es:[bx+2],-1
	jz	short regscan_rc_next
regscan_rc_retained:
	mov	cx,[bp+10]
	mov	dx,[bp+12]
	cmp	es:[bx],cx
	jnz	short regscan_rc_refs
	cmp	es:[bx+2],dx
	jz	short regscan_rc_next
regscan_rc_refs:
	les	bx,es:[bx]
	cmp	es:[bx+0Eh],ax
	jnz	short regscan_rc_next
	push	word ptr [bp-2]
	push	word ptr [bp-4]
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	cs
	call	near ptr RegFlushDataBlock
	add	sp,8
regscan_rc_next:
	inc	word ptr [bp-6]
	add	word ptr [bp-4],12
regscan_rc_test:
	mov	ax,[bp-6]
	les	bx,[bp+6]
	cmp	es:[bx+0Eh],ax
	ja	short regscan_rc_entry
regscan_rc_exit:
	mov	sp,bp
	pop	bp
	ret
RegScanDataBlocks	endp
	assume	cs:REGFILE
	public	RegFlushDataBlock

;** RegFlushDataBlock - Write and release one cached block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR cache entry.
; Write dirty file-backed storage before releasing its index and block.
; Leave the entry allocated if opening or writing the file fails.
;
RegFlushDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,12
	les	bx,[bp+10]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	mov	[bp-10],ax
	mov	[bp-8],dx
	cmp	ax,-1
	jnz	short regflush_rf_check
	cmp	dx,ax
	jnz	short regflush_rf_check
	jmp	regflush_rf_exit
regflush_rf_check:
	les	bx,[bp-10]
	test	byte ptr es:[bx+0Ch],1
	jnz	short regflush_rf_dirty
	jmp	regflush_rf_release
regflush_rf_dirty:
	les	bx,[bp+6]
	cmp	word ptr es:[bx+2Ch],0
	jnz	short regflush_rf_release
	lea	ax,[bp-12]
	push	ss
	push	ax
	mov	ax,1
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr es:[bx+16h]
	push	word ptr es:[bx+14h]
	call	far ptr ConfigOpen
	add	sp,16
	mov	[bp-2],ax
	cmp	ax,-1
	jnz	short regflush_rf_write
regflush_rf_error:
	call	far ptr RegInvalidBlock
	jmp	regflush_rf_exit
regflush_rf_write:
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	mov	ax,1
	push	ax
	push	word ptr [bp+12]
	push	word ptr [bp+10]
	push	word ptr [bp-2]
	push	cs
	call	near ptr RegWriteDataBlock
	add	sp,12
	mov	[bp-6],ax
	mov	[bp-4],dx
	mov	ax,1
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-2]
	les	bx,[bp+6]
	push	word ptr es:[bx+16h]
	push	word ptr es:[bx+14h]
	call	far ptr ConfigClose
	add	sp,14
	mov	ax,[bp-4]
	or	ax,[bp-6]
	jnz	short regflush_rf_error
regflush_rf_release:
	les	bx,[bp-10]
	cmp	word ptr es:[bx+18h],-1
	jnz	short regflush_rf_aux
	cmp	word ptr es:[bx+1Ah],-1
	jz	short regflush_rf_block
regflush_rf_aux:
	push	word ptr es:[bx+1Ah]
	push	word ptr es:[bx+18h]
	call	far ptr ConfigFree
	add	sp,4
regflush_rf_block:
	push	word ptr [bp-8]
	push	word ptr [bp-10]
	call	far ptr ConfigFree
	les	bx,[bp+10]
	mov	word ptr es:[bx],-1
	mov	word ptr es:[bx+2],-1
regflush_rf_exit:
	mov	sp,bp
	pop	bp
	ret
RegFlushDataBlock	endp
	assume	cs:REGFILE
	public	RegAppendDataBlock

;** RegAppendDataBlock - Extend the cache table and append a block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = WORD minimum size.
; Uses RegNewDataBlock and updates the file header's block count.
;
RegAppendDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,010h
	push	si
	les	bx,[bp+06h]
	mov	ax,es:[bx+0Eh]
	mov	[bp-02h],ax
	mov	ax,[bp+0Ah]
	add	ax,04Dh
	and	al,0FCh
	mov	[bp-04h],ax
	mov	ax,0Ch
	mul	word ptr [bp-02h]
	sub	dx,dx
	push	dx
	push	ax
	mov	ax,[bp-02h]
	inc	ax
	mov	cx,018h
	mul	cx
	sub	dx,dx
	push	dx
	push	ax
	push	word ptr es:[bx+02Ah]
	push	word ptr es:[bx+028h]
	call	far ptr ConfigRealloc
	add	sp,0Ch
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short regappend_append_loc_054
	mov	ax,0Eh
	cwd
	jmp	regappend_append_loc_0FD
regappend_append_loc_054:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegNewDataBlock
	add	sp,0Ch
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	or	dx,ax
	jz	short regappend_append_loc_07E
regappend_append_loc_076:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	jmp	short regappend_append_loc_0FD
regappend_append_loc_07E:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	les	bx,[bp+06h]
	mov	es:[bx+028h],ax
	mov	es:[bx+02Ah],dx
	mov	ax,0Ch
	mul	word ptr [bp-02h]
	mov	bx,ax
	les	si,[bp-0Ch]
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	es:[bx+si],ax
	mov	es:[bx+si+02h],dx
	mov	ax,[bp-02h]
	dec	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	mov	si,bx
	push	cs
	call	near ptr RegBlockEndOffset
	add	sp,06h
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	es:[bx+si+04h],ax
	mov	es:[bx+si+06h],dx
	mov	ax,[bp-04h]
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	es:[bx+si+08h],ax
	mov	word ptr es:[bx+si+0Ah],00h
	les	bx,[bp+06h]
	inc	word ptr es:[bx+0Eh]
	les	bx,es:[bx+020h]
	inc	word ptr es:[bx+010h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyHeader
	add	sp,04h
	jmp	regappend_append_loc_076
regappend_append_loc_0FD:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegAppendDataBlock	endp
	assume	cs:REGFILE
	public	RegNewDataBlock

;** RegNewDataBlock - Allocate and initialize a variable-sized block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR output address,
;        [BP+0Eh] = WORD size, [BP+10h] = WORD block index.
; Allocate both the block and its 255-entry index; release the block
; if the index allocation fails.
;
RegNewDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	push	di
	push	si
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,[bp+0Eh]
	sub	dx,dx
	push	dx
	push	ax
	call	far ptr ConfigAlloc
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regnew_new_loc_02D
regnew_new_loc_025:
	mov	ax,0Eh
regnew_new_loc_028:
	xor	dx,dx
	jmp	regnew_new_loc_0FA
regnew_new_loc_02D:
	mov	ax,01h
	cwd
	push	dx
	push	ax
	mov	ax,03FCh
	cwd
	push	dx
	push	ax
	call	far ptr ConfigAlloc
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short regnew_new_loc_05B
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
	add	sp,04h
	jmp	short regnew_new_loc_025
regnew_new_loc_05B:
	les	bx,[bp+0Ah]
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	bx,ax
	mov	es,dx
	mov	word ptr es:[bx],04752h
	mov	word ptr es:[bx+02h],04244h
	mov	cx,[bp+0Eh]
	sub	cx,020h
	sub	dx,dx
	mov	es:[bx+08h],cx
	mov	es:[bx+0Ah],dx
	mov	si,[bp+0Eh]
	mov	es:[bx+04h],si
	xor	si,si
	mov	es:[bx+06h],dx
	mov	es:[bx+016h],si
	mov	es:[bx+014h],dx
	mov	si,[bp-0Ch]
	mov	di,[bp-0Ah]
	mov	es:[bx+018h],si
	mov	es:[bx+01Ah],di
	mov	word ptr es:[bx+010h],020h
	mov	es:[bx+012h],dx
	mov	si,es
	add	ax,020h
	adc	si,dx
	mov	bx,ax
	mov	es,si
	mov	es:[bx],cx
	mov	es:[bx+02h],dx
	mov	dx,0FFFFh
	mov	es:[bx+04h],dx
	mov	es:[bx+06h],dx
	mov	es:[bx+08h],dx
	mov	es:[bx+0Ah],dx
	mov	ax,[bp+010h]
	les	bx,[bp-04h]
	mov	word ptr es:[bx+0Ch],09h
	mov	es:[bx+0Eh],ax
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateDataBlock
	add	sp,04h
	xor	ax,ax
	jmp	regnew_new_loc_028
regnew_new_loc_0FA:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegNewDataBlock	endp
	assume	cs:REGFILE,ds:DGROUP
	public	RegFreeDataBlock

;** RegFreeDataBlock - Release a block and its index
;
; ENTRY: [BP+6] = FAR data block, or -1.
; The caller supplies a block with allocated index storage.
;
RegFreeDataBlock	proc	far
	push	bp
	mov	bp,sp
	cmp	word ptr [bp+06h],-1
	jnz	short regbfree_bfree_loc_00F
	cmp	word ptr [bp+08h],-1
	jz	short regbfree_bfree_loc_02C
regbfree_bfree_loc_00F:
	les	bx,[bp+06h]
	push	word ptr es:[bx+01Ah]
	push	word ptr es:[bx+018h]
	call	far ptr ConfigFree
	mov	sp,bp
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigFree
regbfree_bfree_loc_02C:
	mov	sp,bp
	pop	bp
	ret
RegFreeDataBlock	endp
	assume	cs:REGFILE
	public	RegBlockEndOffset

;** RegBlockEndOffset - Find the offset following a block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = WORD block index.
; EXIT: DX:AX = end offset. Index -1 selects the first data offset.
;
RegBlockEndOffset	proc	far
	push	bp
	mov	bp,sp
	sub	sp,04h
	cmp	word ptr [bp+0Ah],-1
	jnz	short regend_end_loc_01D
	les	bx,[bp+06h]
	les	bx,es:[bx+020h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regend_end_loc_03C
regend_end_loc_01D:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	add	bx,ax
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	add	ax,es:[bx+08h]
	adc	dx,es:[bx+0Ah]
regend_end_loc_03C:
	mov	sp,bp
	pop	bp
	ret
RegBlockEndOffset	endp
	assume	cs:REGFILE
	public	RegIndexBlock

;** RegIndexBlock - Build an index from data records
;
; ENTRY: [BP+6] = FAR block, [BP+0Ah] = FAR 255-entry index.
; EXIT: AX = 1 for an intact record walk. Malformed records trigger
; a diagnostic and free-chain repair, returning zero.
;
RegIndexBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,16h
	push	si
	les	bx,[bp+6]
	mov	cx,bx
	add	cx,es:[bx+4]
	mov	[bp-14],cx
	mov	cx,es
	add	bx,20h
	adc	cx,0
	mov	[bp-10],bx
	mov	[bp-8],cx
	mov	bx,[bp+6]
	mov	ax,es:[bx+4]
	mov	dx,es:[bx+6]
	sub	ax,20h
	sbb	dx,0
	mov	[bp-18],ax
	mov	[bp-16],dx
	sub	ax,ax
	mov	[bp-20],ax
	mov	[bp-22],ax
	jmp	regblock_rb_test
regblock_rb_record:
	les	bx,[bp-10]
	mov	ax,es:[bx+2]
	or	ax,es:[bx]
	jz	short regblock_rb_bad
	mov	ax,[bp-18]
	mov	dx,[bp-16]
	cmp	es:[bx+2],dx
	ja	short regblock_rb_bad
	jc	short regblock_rb_size
	cmp	es:[bx],ax
	ja	short regblock_rb_bad
regblock_rb_size:
	cmp	word ptr es:[bx+4],-1
	jnz	short regblock_rb_id
	cmp	word ptr es:[bx+6],-1
	jz	short regblock_rb_valid
regblock_rb_id:
	cmp	word ptr es:[bx+4],0FFh
	jnc	short regblock_rb_bad
regblock_rb_valid:
	jmp	regblock_rb_index
regblock_rb_bad:
	call	far ptr RegInvalidBlock
	mov	ax,[bp-10]
	mov	dx,[bp-8]
	mov	cx,ax
	mov	bx,dx
	add	ax,12
	adc	dx,0
	cmp	ax,[bp-14]
	jbe	short regblock_rb_free_tail
	sub	cx,[bp+6]
	sbb	bx,[bp+8]
	les	si,[bp+6]
	mov	es:[si+4],cx
	mov	es:[si+6],bx
	mov	ax,[bp-10]
	sub	ax,15h
	mov	[bp-14],ax
	sub	ax,ax
	mov	[bp-16],ax
	mov	[bp-18],ax
	jmp	short regblock_rb_rebuild
regblock_rb_free_tail:
	mov	ax,[bp-18]
	mov	dx,[bp-16]
	les	bx,[bp-10]
	mov	es:[bx],ax
	mov	es:[bx+2],dx
	mov	ax,-1
	cwd
	mov	es:[bx+4],ax
	mov	es:[bx+6],dx
	mov	es:[bx+8],ax
	mov	es:[bx+10],ax
regblock_rb_rebuild:
	mov	ax,[bp-22]
	mov	dx,[bp-20]
	add	ax,[bp-18]
	adc	dx,[bp-16]
	les	bx,[bp+6]
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
	mov	ax,es
	add	bx,20h
	adc	ax,0
	mov	[bp-10],bx
	mov	[bp-8],ax
	mov	word ptr [bp-6],-1
	mov	word ptr [bp-4],-1
	jmp	short regblock_rb_chain_test
regblock_rb_chain:
	les	bx,[bp-10]
	cmp	word ptr es:[bx+4],-1
	jnz	short regblock_rb_chain_next
	cmp	word ptr es:[bx+6],-1
	jnz	short regblock_rb_chain_next
	cmp	word ptr [bp-6],-1
	jnz	short regblock_rb_chain_link
	cmp	word ptr [bp-4],-1
	jnz	short regblock_rb_chain_link
	mov	ax,es
	sub	bx,[bp+6]
	sbb	ax,[bp+8]
	les	si,[bp+6]
	mov	es:[si+16],bx
	mov	es:[si+18],ax
	jmp	short regblock_rb_chain_save
regblock_rb_chain_link:
	mov	dx,es
	sub	ax,[bp+6]
	sbb	dx,[bp+8]
	les	bx,[bp-6]
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
regblock_rb_chain_save:
	mov	ax,[bp-10]
	mov	dx,[bp-8]
	mov	[bp-6],ax
	mov	[bp-4],dx
regblock_rb_chain_next:
	les	bx,[bp-10]
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx]
	adc	ax,es:[bx+2]
	mov	[bp-10],cx
	mov	[bp-8],ax
regblock_rb_chain_test:
	mov	ax,[bp-10]
	cmp	[bp-14],ax
	ja	short regblock_rb_chain
	cmp	word ptr [bp-6],-1
	jnz	short regblock_rb_chain_end
	cmp	word ptr [bp-4],-1
	jz	short regblock_rb_first_id
regblock_rb_chain_end:
	les	bx,[bp-6]
	mov	word ptr es:[bx+8],-1
	mov	word ptr es:[bx+10],-1
regblock_rb_first_id:
	xor	ax,ax
	les	bx,[bp+6]
	mov	[bp-2],ax
	mov	es:[bx+22],ax
	jmp	short regblock_rb_first_test
regblock_rb_first_next:
	inc	word ptr [bp-2]
regblock_rb_first_test:
	cmp	word ptr [bp-2],0FFh
	jnc	short regblock_rb_last_id
	mov	bx,[bp-2]
	add	bx,bx
	add	bx,bx
	les	si,[bp+10]
	mov	ax,es:[bx+si+2]
	or	ax,es:[bx+si]
	jnz	short regblock_rb_first_next
	mov	ax,[bp-2]
	les	bx,[bp+6]
	mov	es:[bx+22],ax
regblock_rb_last_id:
	les	bx,[bp+6]
	mov	word ptr [bp-2],0FEh
	mov	word ptr es:[bx+20],0
	jmp	short regblock_rb_last_test
regblock_rb_last_next:
	dec	word ptr [bp-2]
regblock_rb_last_test:
	cmp	word ptr [bp-2],0
	jz	short regblock_rb_repaired
	mov	bx,[bp-2]
	add	bx,bx
	add	bx,bx
	les	si,[bp+10]
	mov	ax,es:[bx+si+2]
	or	ax,es:[bx+si]
	jz	short regblock_rb_last_next
	mov	ax,[bp-2]
	les	bx,[bp+6]
	mov	es:[bx+20],ax
regblock_rb_repaired:
	xor	ax,ax
	jmp	short regblock_rb_exit
regblock_rb_index:
	cmp	word ptr es:[bx+4],-1
	jnz	short regblock_rb_used
	cmp	word ptr es:[bx+6],-1
	jz	short regblock_rb_free
regblock_rb_used:
	mov	bx,es:[bx+4]
	mov	[bp-2],bx
	add	bx,bx
	add	bx,bx
	les	si,[bp+10]
	mov	ax,[bp-10]
	mov	dx,[bp-8]
	mov	es:[bx+si],ax
	mov	es:[bx+si+2],dx
	jmp	short regblock_rb_advance
regblock_rb_free:
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	add	[bp-22],ax
	adc	[bp-20],dx
regblock_rb_advance:
	les	bx,[bp-10]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	sub	[bp-18],ax
	sbb	[bp-16],dx
	mov	cx,es
	add	ax,bx
	adc	dx,cx
	mov	[bp-10],ax
	mov	[bp-8],dx
regblock_rb_test:
	mov	ax,[bp-10]
	cmp	[bp-14],ax
	jbe	short regblock_rb_ok
	jmp	regblock_rb_record
regblock_rb_ok:
	mov	ax,1
regblock_rb_exit:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegIndexBlock	endp
	nop	; Original inter-function padding.
	nop
	assume	cs:REGFILE
	public	RegGrowDataBlock

;** RegGrowDataBlock - Enlarge and reindex a data block
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = WORD block index,
;        [BP+0Ch] = DWORD growth.
; Round growth to 4K, compact records and extend the free tail.
; Update the cache entry and index after reallocation.
;
RegGrowDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	push	di
	push	si
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	bx,ax
	les	si,[bp+06h]
	les	si,es:[si+028h]
	mov	ax,[bp+0Ch]
	mov	dx,[bp+0Eh]
	add	ax,0FFFh
	adc	dx,00h
	and	ax,0F000h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	add	ax,es:[bx+si+08h]
	adc	dx,es:[bx+si+0Ah]
	mov	[bp+0Ch],ax
	mov	[bp+0Eh],dx
	or	dx,dx
	jz	short reggrow_grow_loc_046
	mov	ax,0EAh
reggrow_grow_loc_041:
	xor	dx,dx
	jmp	reggrow_grow_loc_1A4
reggrow_grow_loc_046:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	add	bx,ax
	push	word ptr es:[bx+0Ah]
	push	word ptr es:[bx+08h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	call	far ptr ConfigRealloc
	add	sp,0Ch
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	or	dx,ax
	jnz	short reggrow_grow_loc_081
	mov	ax,0Eh
	jmp	short reggrow_grow_loc_041
reggrow_grow_loc_081:
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	bx,ax
	les	si,[bp+06h]
	les	si,es:[si+028h]
	push	word ptr es:[bx+si+0Ah]
	push	word ptr es:[bx+si+08h]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	cs
	call	near ptr RegPackDataBlock
	add	sp,08h
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	les	bx,[bp-08h]
	add	es:[bx+08h],ax
	adc	es:[bx+0Ah],dx
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short reggrow_grow_loc_10A
	cmp	dx,ax
	jnz	short reggrow_grow_loc_10A
	mov	cx,bx
	add	cx,es:[bx+04h]
	mov	[bp-04h],cx
	mov	word ptr [bp-02h],es
	mov	si,cx
	sub	ax,ax
	mov	es:[si+02h],ax
	mov	es:[si],ax
	mov	ax,0FFFFh
	cwd
	mov	es:[si+04h],ax
	mov	es:[si+06h],dx
	mov	es:[si+08h],ax
	mov	es:[si+0Ah],ax
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	jmp	short reggrow_grow_loc_11A
reggrow_grow_loc_10A:
	mov	ax,bx
	mov	dx,es
	add	ax,[bp-04h]
	adc	dx,[bp-02h]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
reggrow_grow_loc_11A:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	les	bx,[bp-04h]
	add	es:[bx],ax
	adc	es:[bx+02h],dx
	mov	ax,0Ch
	mul	word ptr [bp+0Ah]
	mov	si,ax
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	es:[bx+si],ax
	mov	es:[bx+si+02h],dx
	mov	es,dx
	mov	bx,ax
	mov	cx,[bp+0Ch]
	mov	di,[bp+0Eh]
	mov	es:[bx+04h],cx
	mov	es:[bx+06h],di
	les	bx,[bp+06h]
	les	bx,es:[bx+028h]
	mov	es:[bx+si+08h],cx
	mov	es:[bx+si+0Ah],di
	mov	es,dx
	mov	bx,ax
	push	word ptr es:[bx+01Ah]
	push	word ptr es:[bx+018h]
	push	dx
	push	ax
	push	cs
	call	near ptr RegIndexBlock
	add	sp,08h
	or	ax,ax
	jnz	short reggrow_grow_loc_188
	les	bx,[bp+06h]
	or	byte ptr es:[bx+010h],08h
reggrow_grow_loc_188:
	les	bx,[bp-08h]
	or	byte ptr es:[bx+0Ch],02h
	push	es
	push	bx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyDataBlock
	add	sp,08h
	xor	ax,ax
	jmp	reggrow_grow_loc_041
reggrow_grow_loc_1A4:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegGrowDataBlock	endp
	assume	cs:REGFILE
	public	RegGrowKeyBlock

;** RegGrowKeyBlock - Grow key storage and link its free extent
;
; ENTRY: [BP+6] = FAR file.
; Update the key header and data-start offset, then mark both dirty.
;
RegGrowKeyBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,028h
	push	di
	push	si
	les	bx,[bp+06h]
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	add	ah,018h
	adc	dx,00h
	and	ax,0F000h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	dx
	push	ax
	les	bx,[bp+06h]
	push	word ptr es:[bx+026h]
	push	word ptr es:[bx+024h]
	call	far ptr ConfigRealloc
	add	sp,0Ch
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short regkeygrow_keygrow_loc_059
	mov	ax,0Eh
regkeygrow_keygrow_loc_054:
	xor	dx,dx
	jmp	regkeygrow_keygrow_loc_198
regkeygrow_keygrow_loc_059:
	mov	dx,[bp-0Ah]
	les	bx,[bp+06h]
	mov	es:[bx+024h],ax
	mov	es:[bx+026h],dx
	mov	es,dx
	mov	bx,ax
	mov	cx,[bp-04h]
	mov	si,[bp-02h]
	mov	es:[bx+04h],cx
	mov	es:[bx+06h],si
	add	cx,020h
	adc	si,00h
	les	bx,[bp+06h]
	les	bx,es:[bx+020h]
	mov	es:[bx+08h],cx
	mov	es:[bx+0Ah],si
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyHeader
	add	sp,04h
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	mov	si,ax
	mov	di,dx
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	bx,ax
	mov	es,dx
	mov	word ptr es:[bx],0FFFFh
	mov	word ptr es:[bx+02h],0FFFFh
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	sub	ax,[bp-08h]
	sbb	dx,[bp-06h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	mov	word ptr es:[bx+08h],0FFFFh
	mov	word ptr es:[bx+0Ah],0FFFFh
	cmp	si,-1
	jnz	short regkeygrow_keygrow_loc_11B
	cmp	di,si
	jnz	short regkeygrow_keygrow_loc_11B
	mov	cx,es
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp-0Ch]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
	jmp	short regkeygrow_keygrow_loc_17E
regkeygrow_keygrow_loc_11B:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	di
	push	si
regkeygrow_keygrow_loc_123:
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-024h],ax
	mov	[bp-022h],dx
	les	bx,[bp-024h]
	cmp	word ptr es:[bx+08h],-1
	jnz	short regkeygrow_keygrow_loc_142
	cmp	word ptr es:[bx+0Ah],-1
	jz	short regkeygrow_keygrow_loc_152
regkeygrow_keygrow_loc_142:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr es:[bx+0Ah]
	push	word ptr es:[bx+08h]
	jmp	short regkeygrow_keygrow_loc_123
regkeygrow_keygrow_loc_152:
	mov	cx,[bp-0Eh]
	mov	bx,[bp-010h]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	les	bx,[bp-024h]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	mov	word ptr es:[bx],00h
	mov	word ptr es:[bx+02h],08000h
regkeygrow_keygrow_loc_17E:
	les	bx,[bp-0Ch]
	or	byte ptr es:[bx+010h],02h
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegDirtyKeyBlock
	add	sp,04h
	xor	ax,ax
	jmp	regkeygrow_keygrow_loc_054
regkeygrow_keygrow_loc_198:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegGrowKeyBlock	endp
	assume	cs:REGFILE
	public	RegPackDataBlock

;** RegPackDataBlock - Compact records and rebuild the free tail
;
; ENTRY: [BP+6] = FAR block, [BP+0Ah] = DWORD block size.
; Move occupied runs over holes and adjust their indexed pointers.
;
RegPackDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,18h
	push	di
	push	si
	mov	word ptr [bp-12],-1
	mov	word ptr [bp-10],-1
	mov	ax,[bp+10]
	mov	dx,[bp+12]
	mov	cx,[bp+6]
	mov	bx,[bp+8]
	add	ax,cx
	adc	dx,bx
	mov	[bp-8],ax
	mov	[bp-6],dx
	add	cx,20h
	adc	bx,0
	mov	[bp-4],cx
	mov	[bp-2],bx
	jmp	regpack_rp_test
regpack_rp_run:
	sub	ax,ax
	mov	[bp-18],ax
	mov	[bp-20],ax
regpack_rp_find_hole:
	les	bx,[bp-4]
	cmp	word ptr es:[bx+4],-1
	jnz	short regpack_rp_skip_used
	cmp	word ptr es:[bx+6],-1
	jz	short regpack_rp_hole
regpack_rp_skip_used:
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx]
	adc	ax,es:[bx+2]
	mov	[bp-4],cx
	mov	[bp-2],ax
	cmp	cx,[bp-8]
	jc	short regpack_rp_find_hole
	xor	ax,ax
	jmp	regpack_rp_exit
regpack_rp_hole:
	cmp	word ptr [bp-12],-1
	jnz	short regpack_rp_skip_hole
	cmp	word ptr [bp-10],-1
	jnz	short regpack_rp_skip_hole
	mov	[bp-12],bx
	mov	[bp-10],es
regpack_rp_skip_hole:
	les	bx,[bp-4]
	cmp	word ptr es:[bx+4],-1
	jnz	short regpack_rp_used
	cmp	word ptr es:[bx+6],-1
	jnz	short regpack_rp_used
	mov	ax,es
	mov	cx,bx
	add	cx,es:[bx]
	adc	ax,es:[bx+2]
	mov	[bp-4],cx
	mov	[bp-2],ax
	cmp	cx,[bp-8]
	jc	short regpack_rp_skip_hole
regpack_rp_used:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	mov	[bp-16],ax
	mov	[bp-14],dx
	cmp	ax,[bp-8]
	jc	short regpack_rp_count
	jmp	regpack_rp_tail
regpack_rp_count:
	les	bx,[bp-4]
	cmp	word ptr es:[bx+4],-1
	jnz	short regpack_rp_add
	cmp	word ptr es:[bx+6],-1
	jz	short regpack_rp_move
regpack_rp_add:
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	add	[bp-20],ax
	adc	[bp-18],dx
	mov	cx,es
	add	ax,bx
	adc	dx,cx
	mov	[bp-4],ax
	mov	[bp-2],dx
	cmp	ax,[bp-8]
	jc	short regpack_rp_count
regpack_rp_move:
	push	word ptr [bp-18]
	push	word ptr [bp-20]
	push	word ptr [bp-14]
	push	word ptr [bp-16]
	push	word ptr [bp-10]
	push	word ptr [bp-12]
	call	far ptr RegCopyBytes
	add	sp,12
	mov	ax,[bp-16]
	mov	dx,[bp-14]
	mov	cx,[bp-12]
	mov	bx,[bp-10]
	mov	si,ax
	mov	di,dx
	sub	ax,cx
	sbb	dx,bx
	add	cx,[bp-20]
	adc	bx,[bp-18]
	mov	[bp-12],cx
	mov	[bp-10],bx
	push	dx
	push	ax
	add	si,[bp-20]
	adc	di,[bp-18]
	push	di
	push	si
	push	word ptr [bp-14]
	push	word ptr [bp-16]
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	cs
	call	near ptr RegRelocateIndex
	add	sp,16
regpack_rp_test:
	mov	ax,[bp-4]
	cmp	[bp-8],ax
	jbe	short regpack_rp_tail
	jmp	regpack_rp_run
regpack_rp_tail:
	mov	ax,[bp-8]
	mov	dx,[bp-6]
	mov	cx,[bp-12]
	mov	bx,[bp-10]
	sub	ax,cx
	sbb	dx,bx
	mov	si,cx
	mov	es,bx
	mov	es:[si],ax
	mov	es:[si+2],dx
	mov	ax,-1
	cwd
	mov	es:[si+4],ax
	mov	es:[si+6],dx
	mov	es:[si+8],ax
	mov	es:[si+10],ax
	sub	cx,[bp+6]
	sbb	bx,[bp+8]
	les	si,[bp+6]
	mov	es:[si+16],cx
	mov	es:[si+18],bx
	les	bx,[bp-12]
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	les	bx,[bp+6]
	mov	es:[bx+8],ax
	mov	es:[bx+10],dx
	mov	ax,1
regpack_rp_exit:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegPackDataBlock	endp
	even
	assume	cs:REGFILE
	public	RegRelocateIndex

;** RegRelocateIndex - Adjust pointers moved during compaction
;
; ENTRY: [BP+6] = FAR block, [BP+0Ah] = FAR lower bound,
;        [BP+0Eh] = FAR upper bound, [BP+12h] = DWORD displacement.
; Compare pointer offsets against the bounds; subtract displacement
; from indexed pointers in the selected range.
;
RegRelocateIndex	proc	far
	push	bp
	mov	bp,sp
	sub	sp,6
	les	bx,[bp+6]
	mov	ax,es:[bx+18h]
	mov	dx,es:[bx+1Ah]
	mov	[bp-4],ax
	mov	[bp-2],dx
	mov	ax,es:[bx+14h]
	mov	[bp-6],ax
	jmp	short regreloc_rr_test
regreloc_rr_entry:
	les	bx,[bp-4]
	mov	ax,es:[bx]
	cmp	ax,[bp+10]
	jc	short regreloc_rr_next
	cmp	ax,[bp+14]
	jnc	short regreloc_rr_next
	mov	dx,es:[bx+2]
	sub	ax,[bp+18]
	sbb	dx,[bp+20]
	mov	es:[bx],ax
	mov	es:[bx+2],dx
regreloc_rr_next:
	dec	word ptr [bp-6]
	add	word ptr [bp-4],4
regreloc_rr_test:
	cmp	word ptr [bp-6],0
	jge	short regreloc_rr_entry
	mov	sp,bp
	pop	bp
	ret
RegRelocateIndex	endp
	assume	cs:REGFILE
	public	RegHasPendingState

;** RegHasPendingState - Test pending key and data-block state
;
; ENTRY: [BP+6] = FAR file.
; EXIT: AX = 1 if flag 02h is found, otherwise zero.
; The cached-block scan uses the signed count-minus-one bound.
;
RegHasPendingState	proc	far
	push	bp
	mov	bp,sp
	sub	sp,6
	les	bx,[bp+6]
	les	bx,es:[bx+24h]
	test	byte ptr es:[bx+10h],2
	jz	short regstate_rs_blocks
regstate_rs_set:
	mov	ax,1
	jmp	short regstate_rs_exit
regstate_rs_blocks:
	les	bx,[bp+6]
	mov	ax,es:[bx+28h]
	mov	dx,es:[bx+2Ah]
	mov	[bp-6],ax
	mov	[bp-4],dx
	mov	word ptr [bp-2],0
	jmp	short regstate_rs_test
regstate_rs_block:
	les	bx,[bp-6]
	cmp	word ptr es:[bx],-1
	jnz	short regstate_rs_flags
	cmp	word ptr es:[bx+2],-1
	jz	short regstate_rs_next
regstate_rs_flags:
	les	bx,es:[bx]
	test	byte ptr es:[bx+0Ch],2
	jnz	short regstate_rs_set
regstate_rs_next:
	inc	word ptr [bp-2]
	add	word ptr [bp-6],12
regstate_rs_test:
	les	bx,[bp+6]
	mov	ax,es:[bx+0Eh]
	dec	ax
	cmp	ax,[bp-2]
	jg	short regstate_rs_block
	xor	ax,ax
regstate_rs_exit:
	mov	sp,bp
	pop	bp
	ret
RegHasPendingState	endp
	even
	assume	cs:REGFILE
	public	RegMakeTempName

;** RegMakeTempName - Form a replacement file name
;
; ENTRY: [BP+6] = FAR source, [BP+0Ah] = FAR destination,
;        [BP+0Eh] = suffix byte.
; Replace the last three characters with ~~suffix.
; EXIT: DX:AX = destination. Caller supplies a valid name and buffer.
;
RegMakeTempName	proc	far
	push	bp
	mov	bp,sp
	sub	sp,6
	push	si
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	call	far ptr RegStringLength
	add	sp,4
	mov	[bp-2],ax
	inc	ax
	sub	dx,dx
	push	dx
	push	ax
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	push	word ptr [bp+12]
	push	word ptr [bp+10]
	call	far ptr RegCopyBytes
	add	sp,12
	mov	al,'~'
	les	bx,[bp+10]
	mov	si,[bp-2]
	mov	es:[bx+si-3],al
	add	si,bx
	sub	si,3
	mov	es:[si+1],al
	mov	al,[bp+14]
	lea	bx,[si+1]
	mov	es:[bx+1],al
	mov	ax,[bp+10]
	mov	dx,es
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegMakeTempName	endp
	assume	cs:REGFILE,ds:DGROUP
	public	RegRecoverFile

;** RegRecoverFile - Recover an interrupted file replacement
;
; ENTRY: [BP+6] = FAR pathname.
; Use the ~~r and ~~s names for replacement and rollback.
;
RegRecoverFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0CCh
	mov	al,072h
	push	ax
	lea	cx,[bp-068h]
	push	ss
	push	cx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegMakeTempName
	add	sp,0Ah
	mov	al,073h
	push	ax
	lea	ax,[bp-0CCh]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegMakeTempName
	add	sp,0Ah
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-068h]
	push	ss
	push	ax
	call	far ptr ConfigGetAttr
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	and	al,07h
	cmp	al,07h
	jz	short regrecov_recov_loc_052
	jmp	regrecov_recov_loc_0D2
regrecov_recov_loc_052:
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-0CCh]
	push	ss
	push	ax
	call	far ptr ConfigDelete
	add	sp,08h
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-0CCh]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigRename
	add	sp,0Ch
	or	ax,ax
	jnz	short regrecov_recov_loc_088
	mov	word ptr [bp-04h],03F8h
	mov	[bp-02h],ax
regrecov_recov_loc_088:
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	lea	ax,[bp-068h]
	push	ss
	push	ax
	call	far ptr ConfigRename
	add	sp,0Ch
	or	ax,ax
	jnz	short regrecov_recov_loc_0C3
	mov	word ptr [bp-04h],03F8h
	mov	[bp-02h],ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	lea	ax,[bp-0CCh]
	push	ss
	push	ax
	call	far ptr ConfigRename
	add	sp,0Ch
	jmp	short regrecov_recov_loc_0D2
regrecov_recov_loc_0C3:
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-0CCh]
	push	ss
	push	ax
	call	far ptr ConfigDelete
regrecov_recov_loc_0D2:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	sp,bp
	pop	bp
	ret
RegRecoverFile	endp
	assume	cs:REGFILE,ds:DGROUP
	public	RegValidateHeader,RegValidateKeyBlock,RegValidateDataBlock

;** RegValidateHeader - Validate a CREG header
;
; ENTRY: [BP+6] = FAR header.
; Check signature and version. Policy above two enables checksum
; checking or generation; other policies clear the checksum-valid bit.
; EXIT: AX = 1 if valid, zero after a diagnostic on failure.
;
RegValidateHeader	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	cmp	word ptr es:[bx],5243h
	jnz	short regvalid_rh_bad
	cmp	word ptr es:[bx+2],4745h
	jz	short regvalid_rh_version
regvalid_rh_bad:
	call	far ptr RegInvalidBlock
	xor	ax,ax
	jmp	short regvalid_rh_exit
regvalid_rh_version:
	cmp	word ptr es:[bx+4],0
	jnz	short regvalid_rh_bad
	cmp	word ptr es:[bx+6],1
	jnz	short regvalid_rh_bad
	cmp	RegCheckPolicy,2
	jbe	short regvalid_rh_disable
	test	byte ptr es:[bx+18],4
	jz	short regvalid_rh_generate
	mov	ax,20h
	cwd
	push	dx
	push	ax
	push	es
	push	bx
	push	cs
	call	near ptr RegChecksum
	mov	sp,bp
	or	dx,ax
	jz	short regvalid_rh_good
	jmp	short regvalid_rh_bad
regvalid_rh_generate:
	or	byte ptr es:[bx+18],4
	sub	ax,ax
	mov	es:[bx+14],ax
	mov	es:[bx+12],ax
	mov	ax,20h
	cwd
	push	dx
	push	ax
	push	es
	push	bx
	push	cs
	call	near ptr RegChecksum
	mov	sp,bp
	neg	ax
	adc	dx,0
	neg	dx
	les	bx,[bp+6]
	mov	es:[bx+12],ax
	mov	es:[bx+14],dx
	jmp	short regvalid_rh_good
regvalid_rh_disable:
	and	byte ptr es:[bx+18],0FBh
regvalid_rh_good:
	mov	ax,1
regvalid_rh_exit:
	mov	sp,bp
	pop	bp
	ret
RegValidateHeader	endp
	even

;** RegValidateKeyBlock - Validate an RGKN header
;
; ENTRY: [BP+6] = FAR key block.
; Check the signature and clear the checksum-valid bit.
; EXIT: AX = 1 if valid, zero after a diagnostic on failure.
;
RegValidateKeyBlock	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	cmp	word ptr es:[bx],4752h
	jnz	short regvalid_rk_bad
	cmp	word ptr es:[bx+2],4E4Bh
	jz	short regvalid_rk_good
regvalid_rk_bad:
	call	far ptr RegInvalidBlock
	xor	ax,ax
	jmp	short regvalid_rk_exit
regvalid_rk_good:
	and	byte ptr es:[bx+16],0FBh
	mov	ax,1
regvalid_rk_exit:
	mov	sp,bp
	pop	bp
	ret
RegValidateKeyBlock	endp

;** RegValidateDataBlock - Validate an RGDB block
;
; ENTRY: [BP+6] = FAR data block.
; Policy above two enables checksum checking or generation.
; EXIT: AX = 1 if valid, zero after a diagnostic on failure.
;
RegValidateDataBlock	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	cmp	word ptr es:[bx],4752h
	jnz	short regvalid_rd_bad
	cmp	word ptr es:[bx+2],4244h
	jz	short regvalid_rd_policy
regvalid_rd_bad:
	call	far ptr RegInvalidBlock
	xor	ax,ax
	jmp	short regvalid_rd_exit
regvalid_rd_policy:
	cmp	RegCheckPolicy,2
	jbe	short regvalid_rd_disable
	test	byte ptr es:[bx+12],4
	jz	short regvalid_rd_generate
	push	word ptr es:[bx+6]
	push	word ptr es:[bx+4]
	push	es
	push	bx
	push	cs
	call	near ptr RegChecksum
	mov	sp,bp
	or	dx,ax
	jz	short regvalid_rd_good
	jmp	short regvalid_rd_bad
regvalid_rd_generate:
	or	byte ptr es:[bx+12],4
	sub	ax,ax
	mov	es:[bx+30],ax
	mov	es:[bx+28],ax
	push	word ptr es:[bx+6]
	push	word ptr es:[bx+4]
	push	es
	push	bx
	push	cs
	call	near ptr RegChecksum
	mov	sp,bp
	neg	ax
	adc	dx,0
	neg	dx
	les	bx,[bp+6]
	mov	es:[bx+28],ax
	mov	es:[bx+30],dx
	jmp	short regvalid_rd_good
regvalid_rd_disable:
	and	byte ptr es:[bx+12],0FBh
regvalid_rd_good:
	mov	ax,1
regvalid_rd_exit:
	mov	sp,bp
	pop	bp
	ret
RegValidateDataBlock	endp
	even
	assume	cs:REGFILE
	public	RegChecksum

;** RegChecksum - Sum complete DWORDs in a buffer
;
; ENTRY: [BP+6] = FAR buffer, [BP+0Ah] = DWORD byte count.
; EXIT: DX:AX = sum. Ignore trailing bytes; advance across 64K
; boundaries with a 1000h paragraph adjustment.
;
RegChecksum	proc	far
	push	bp
	mov	bp,sp
	sub	sp,8
	sub	ax,ax
	mov	[bp-2],ax
	mov	[bp-4],ax
	mov	ax,[bp+10]
	mov	dx,[bp+12]
	mov	cl,2
	call	far ptr __aFulshr
	mov	[bp-8],ax
	mov	[bp-6],dx
	jmp	short regcheck_rc_test
regcheck_rc_next:
	sub	word ptr [bp-8],1
	sbb	word ptr [bp-6],0
regcheck_rc_test:
	mov	ax,[bp-6]
	or	ax,[bp-8]
	jz	short regcheck_rc_done
	les	bx,[bp+6]
	add	word ptr [bp+6],4
	jnc	short regcheck_rc_sum
	add	word ptr [bp+8],1000h
regcheck_rc_sum:
	mov	ax,es:[bx]
	mov	dx,es:[bx+2]
	add	[bp-4],ax
	adc	[bp-2],dx
	jmp	short regcheck_rc_next
regcheck_rc_done:
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	mov	sp,bp
	pop	bp
	ret
RegChecksum	endp

	assume	cs:REGFILE
	public	RegDirtyHeader,RegDirtyKeyBlock,RegDirtyDataBlock

;** RegDirtyHeader - Mark the file header changed
;
; ENTRY: [BP+6] = FAR file.
; Clear checksum validity, validate the header and mark the file dirty.
;
RegDirtyHeader	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	les	bx,es:[bx+20h]
	or	byte ptr es:[bx+12h],1
	and	byte ptr es:[bx+12h],0FBh
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateHeader
	les	bx,[bp+6]
	mov	sp,bp
	or	byte ptr es:[bx+10h],1
	pop	bp
	ret
RegDirtyHeader	endp

;** RegDirtyKeyBlock - Mark the key block changed
;
; ENTRY: [BP+6] = FAR file.
; Clear checksum validity, validate the key block and mark the file dirty.
;
RegDirtyKeyBlock	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	les	bx,es:[bx+24h]
	or	byte ptr es:[bx+10h],1
	and	byte ptr es:[bx+10h],0FBh
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateKeyBlock
	les	bx,[bp+6]
	mov	sp,bp
	or	byte ptr es:[bx+10h],1
	pop	bp
	ret
RegDirtyKeyBlock	endp

;** RegDirtyDataBlock - Mark a data block changed
;
; ENTRY: [BP+6] = FAR file, [BP+0Ah] = FAR data block.
; Clear checksum validity, validate the block and mark the file dirty.
;
RegDirtyDataBlock	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+10]
	or	byte ptr es:[bx+12],1
	and	byte ptr es:[bx+12],0FBh
	push	es
	push	bx
	push	cs
	call	near ptr RegValidateDataBlock
	les	bx,[bp+6]
	mov	sp,bp
	or	byte ptr es:[bx+16],1
	pop	bp
	ret
RegDirtyDataBlock	endp
	assume	cs:REGFILE,ds:DGROUP
	public	RegAllocate

;** RegAllocate - Allocate memory using a releasable reserve
;
; ENTRY: [BP+6] = DWORD byte count, [BP+0Ah] = DWORD options.
; EXIT: DX:AX = allocation pointer. On failure release the reserve,
; reduce it by 40h bytes and retry with the smaller reserve.
;
RegAllocate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
regalloc_ra_retry:
	push	word ptr [bp+12]
	push	word ptr [bp+10]
	push	word ptr [bp+8]
	push	word ptr [bp+6]
	call	far ptr ConfigAlloc
	add	sp,8
	mov	[bp-4],ax
	mov	ax,dx
	or	ax,[bp-4]
	jnz	short regalloc_ra_exit
	mov	ax,word ptr RegReserveBlock+2
	or	ax,word ptr RegReserveBlock
	jz	short regalloc_ra_exit
	push	word ptr RegReserveBlock+2
	push	word ptr RegReserveBlock
	call	far ptr ConfigFree
	add	sp,4
	sub	ax,ax
	mov	word ptr RegReserveBlock+2,ax
	mov	word ptr RegReserveBlock,ax
	sub	word ptr RegReserveSize,40h
	sbb	word ptr RegReserveSize+2,ax
	cmp	word ptr RegReserveSize+2,ax
	jnz	short regalloc_ra_reserve
	cmp	word ptr RegReserveSize,ax
	jz	short regalloc_ra_retry
regalloc_ra_reserve:
	push	ax
	push	ax
	push	word ptr RegReserveSize+2
	push	word ptr RegReserveSize
	call	far ptr ConfigAlloc
	add	sp,8
	mov	word ptr RegReserveBlock,ax
	mov	word ptr RegReserveBlock+2,dx
	mov	ax,dx
	or	ax,word ptr RegReserveBlock
	jnz	short regalloc_ra_retry
	sub	ax,ax
	mov	word ptr RegReserveSize+2,ax
	mov	word ptr RegReserveSize,ax
	jmp	short regalloc_ra_retry
regalloc_ra_exit:
	mov	ax,[bp-4]
	mov	sp,bp
	pop	bp
	ret
RegAllocate	endp
REGFILE	ends
	end
