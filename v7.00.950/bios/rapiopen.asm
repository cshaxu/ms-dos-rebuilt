; Registry API entry points.
;
; Far C entry points use stack arguments and DS = DGROUP.
; Status results are returned in DX:AX. API entries with a RegVMEntry
; check forward to Windows when that service is installed; the query
; and set-value core routines perform the local file operations.
;
	.286
	extrn	RegFileAddRef:far
	extrn	RegFileReleaseRef:far
	extrn	RegFindOrCreate:far
	extrn	RegOpenPath:far
	extrn	RegVMOpenKey:far
	extrn	RegValidateKeyHandle:far
	extrn	RegKeyDestroy:far
	extrn	RegSaveFile:far
	extrn	RegVMCloseKey:far
	extrn	RegCopyBytes:far
	extrn	RegFindValue:far
	extrn	RegGetKeyRecord:far
	extrn	RegVMCreateKey:far
	extrn	RegDeleteKeyTree:far
	extrn	RegDirtyKeyBlock:far
	extrn	RegFindAlias:far
	extrn	RegVMDeleteKey:far
	extrn	RegLoadKey:far
	extrn	RegRemoveValue:far
	extrn	RegVMDeleteValue:far
	extrn	RegSetValue:far
	extrn	RegStringLength:far
	extrn	RegEnumerateKey:far
	extrn	RegVMEnumKey:far
	extrn	RegVMEnumValue:far
	extrn	RegValueAtIndex:far
	extrn	RegVMFlushKey:far
	extrn	RegInvalidateOwner:far
	extrn	RegVMRemapKey:far
	extrn	RegAddMount:far
	extrn	RegFileCreate:far
	extrn	RegFileUnlink:far
	extrn	RegHVCreate:far
	extrn	RegHVUnlink:far
	extrn	RegReadFile:far
	extrn	RegVMLoadKey:far
	extrn	ConfigFree:far
	extrn	RegInitUserRoot:far
	extrn	RegInvalidateFile:far
	extrn	RegReleaseFileBuffers:far
	extrn	RegUnlinkMount:far
	extrn	RegVMUnloadKey:far
	extrn	ConfigDelete:far
	extrn	RegAllocate:far
	extrn	RegCopyKeyTree:far
	extrn	RegPrepareSaveFile:far
	extrn	RegVMSaveKey:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGAPI	segment	word public 'CODE'
REGAPI	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	RegIOInhibit:word
	extrn	RegRootTable:byte
	extrn	RegSaveName:byte
	extrn	RegSaveSequence:byte
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegVMEntry:dword
c_common	ends
REGAPI	segment	word public 'CODE'
	assume	cs:REGAPI,ds:DGROUP
	public	RegOpenKey

;----------------------------------------------------------------------------
; RegOpenKey - Open a subkey and return a referenced key handle.
;
; Stack arguments: key, subkey pointer, result-handle pointer.
;----------------------------------------------------------------------------
RegOpenKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiopen_iopen_loc_029
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegVMOpenKey
	jmp	rapiopen_iopen_loc_116
rapiopen_iopen_loc_029:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jz	short rapiopen_iopen_loc_049
	jmp	rapiopen_iopen_loc_110
rapiopen_iopen_loc_049:
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	ax,01h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-08h]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jz	short rapiopen_iopen_loc_08B
	jmp	rapiopen_iopen_loc_110
rapiopen_iopen_loc_08B:
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegFileAddRef
	add	sp,04h
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegFindOrCreate
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	cmp	ax,0FFFFh
	jnz	short rapiopen_iopen_loc_0D6
	cmp	dx,ax
	jnz	short rapiopen_iopen_loc_0D6
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegFileReleaseRef
	add	sp,04h
	mov	word ptr [bp-014h],0Eh
	mov	word ptr [bp-012h],00h
	jmp	short rapiopen_iopen_loc_110
rapiopen_iopen_loc_0D6:
	les	bx,[bp+0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	bx,ax
	mov	cx,dx
	mov	es,dx
	add	word ptr es:[bx+014h],01h
	adc	word ptr es:[bx+016h],00h
	les	bx,[bp-04h]
	mov	ax,es:[bx+01Ch]
	mov	dx,es:[bx+01Eh]
	mov	bx,[bp-010h]
	mov	es,cx
	mov	es:[bx+01Ch],ax
	mov	es:[bx+01Eh],dx
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
rapiopen_iopen_loc_110:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
rapiopen_iopen_loc_116:
	mov	sp,bp
	pop	bp
	ret
RegOpenKey	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegCloseKey

;----------------------------------------------------------------------------
; RegCloseKey - Release a key reference and save its file when required.
;
; Stack arguments: key.
;----------------------------------------------------------------------------
RegCloseKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiclos_iclos_loc_01D
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegVMCloseKey
	jmp	rapiclos_iclos_loc_0C1
rapiclos_iclos_loc_01D:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	or	dx,ax
	jz	short rapiclos_iclos_loc_047
	cmp	ax,03FAh
	jnz	short rapiclos_iclos_loc_045
	cmp	word ptr [bp-06h],00h
	jz	short rapiclos_iclos_loc_047
rapiclos_iclos_loc_045:
	jmp	short rapiclos_iclos_loc_0BE
rapiclos_iclos_loc_047:
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegFileReleaseRef
	add	sp,04h
	cmp	word ptr [bp-08h],03FAh
	jnz	short rapiclos_iclos_loc_067
	cmp	word ptr [bp-06h],00h
	jz	short rapiclos_iclos_loc_091
rapiclos_iclos_loc_067:
	les	bx,[bp-04h]
	les	bx,es:[bx+0Ch]
	mov	ax,es:[bx+01Eh]
	or	ax,es:[bx+01Ch]
	jnz	short rapiclos_iclos_loc_091
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegSaveFile
	add	sp,04h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
rapiclos_iclos_loc_091:
	les	bx,[bp-04h]
	test	byte ptr es:[bx+019h],040h
	jnz	short rapiclos_iclos_loc_0B6
	sub	word ptr es:[bx+014h],01h
	sbb	word ptr es:[bx+016h],00h
	mov	ax,es:[bx+016h]
	or	ax,es:[bx+014h]
	jnz	short rapiclos_iclos_loc_0B6
	push	es
	push	bx
	call	far ptr RegKeyDestroy
rapiclos_iclos_loc_0B6:
	sub	ax,ax
	mov	[bp-06h],ax
	mov	[bp-08h],ax
rapiclos_iclos_loc_0BE:
	mov	dx,[bp-06h]
rapiclos_iclos_loc_0C1:
	mov	sp,bp
	pop	bp
	ret
RegCloseKey	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegQueryValueCore

;----------------------------------------------------------------------------
; RegQueryValueCore - Read a value, reporting its type and required buffer length.
;
; Stack arguments: key, subkey pointer, value-name pointer, type pointer,
;                  data pointer, data-length pointer.
;----------------------------------------------------------------------------
RegQueryValueCore	proc	far
	push	bp
	mov	bp,sp
	sub	sp,020h
	push	si
	sub	ax,ax
	mov	[bp-01Eh],ax
	mov	[bp-020h],ax
	mov	ax,[bp+01Ch]
	or	ax,[bp+01Ah]
	jnz	short rapiqry_iqry_loc_021
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
	jmp	short rapiqry_iqry_loc_031
rapiqry_iqry_loc_021:
	les	bx,[bp+01Ah]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
rapiqry_iqry_loc_031:
	mov	ax,[bp+014h]
	or	ax,[bp+012h]
	jz	short rapiqry_iqry_loc_045
	les	bx,[bp+012h]
	sub	ax,ax
	mov	es:[bx+02h],ax
	mov	es:[bx],ax
rapiqry_iqry_loc_045:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jnz	short rapiqry_iqry_loc_0C4
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	mov	ax,01h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-01Ch]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jnz	short rapiqry_iqry_loc_0C4
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp-01Ah]
	push	word ptr [bp-01Ch]
	call	far ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jz	short rapiqry_iqry_loc_0C7
rapiqry_iqry_loc_0C4:
	jmp	rapiqry_iqry_loc_1EC
rapiqry_iqry_loc_0C7:
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	call	far ptr RegFindValue
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	cmp	ax,0FFFFh
	jnz	short rapiqry_iqry_loc_143
	cmp	dx,ax
	jnz	short rapiqry_iqry_loc_143
	mov	ax,[bp+010h]
	or	ax,[bp+0Eh]
	jz	short rapiqry_iqry_loc_0FB
	les	bx,[bp+0Eh]
	cmp	byte ptr es:[bx],00h
	jnz	short rapiqry_iqry_loc_136
rapiqry_iqry_loc_0FB:
	mov	ax,[bp+018h]
	or	ax,[bp+016h]
	jz	short rapiqry_iqry_loc_112
	mov	ax,[bp-012h]
	or	ax,[bp-014h]
	jz	short rapiqry_iqry_loc_112
	les	bx,[bp+016h]
	mov	byte ptr es:[bx],00h
rapiqry_iqry_loc_112:
	add	word ptr [bp-020h],01h
	adc	word ptr [bp-01Eh],00h
	mov	ax,[bp+014h]
	or	ax,[bp+012h]
	jnz	short rapiqry_iqry_loc_125
	jmp	rapiqry_iqry_loc_1E4
rapiqry_iqry_loc_125:
	les	bx,[bp+012h]
	mov	word ptr es:[bx],01h
	mov	word ptr es:[bx+02h],00h
	jmp	rapiqry_iqry_loc_1E4
rapiqry_iqry_loc_136:
	mov	word ptr [bp-018h],03F4h
rapiqry_iqry_loc_13B:
	mov	word ptr [bp-016h],00h
	jmp	rapiqry_iqry_loc_1EC
rapiqry_iqry_loc_143:
	mov	ax,[bp+014h]
	or	ax,[bp+012h]
	jz	short rapiqry_iqry_loc_15F
	les	bx,[bp-010h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
rapiqry_iqry_loc_15F:
	les	bx,[bp-010h]
	cmp	word ptr es:[bx],01h
	jnz	short rapiqry_iqry_loc_177
	cmp	word ptr es:[bx+02h],00h
	jnz	short rapiqry_iqry_loc_177
	add	word ptr [bp-020h],01h
	adc	word ptr [bp-01Eh],00h
rapiqry_iqry_loc_177:
	sub	dx,dx
	mov	ax,es:[bx+0Ah]
	add	[bp-020h],ax
	adc	[bp-01Eh],dx
	mov	ax,[bp+018h]
	or	ax,[bp+016h]
	jz	short rapiqry_iqry_loc_1E4
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	cmp	[bp-01Eh],dx
	jc	short rapiqry_iqry_loc_1A4
	ja	short rapiqry_iqry_loc_19D
	cmp	[bp-020h],ax
	jna	short rapiqry_iqry_loc_1A4
rapiqry_iqry_loc_19D:
	mov	word ptr [bp-018h],0EAh
	jmp	short rapiqry_iqry_loc_13B
rapiqry_iqry_loc_1A4:
	sub	dx,dx
	mov	ax,es:[bx+0Ah]
	push	dx
	push	ax
	mov	ax,es:[bx+08h]
	lea	cx,[bx+0Ch]
	mov	si,es
	add	ax,cx
	adc	dx,si
	push	dx
	push	ax
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	les	bx,[bp-010h]
	cmp	word ptr es:[bx],01h
	jnz	short rapiqry_iqry_loc_1E4
	cmp	word ptr es:[bx+02h],00h
	jnz	short rapiqry_iqry_loc_1E4
	mov	bx,es:[bx+0Ah]
	les	si,[bp+016h]
	mov	byte ptr es:[bx+si],00h
rapiqry_iqry_loc_1E4:
	sub	ax,ax
	mov	[bp-016h],ax
	mov	[bp-018h],ax
rapiqry_iqry_loc_1EC:
	mov	ax,[bp+01Ch]
	or	ax,[bp+01Ah]
	jz	short rapiqry_iqry_loc_219
	mov	ax,[bp-016h]
	or	ax,[bp-018h]
	jz	short rapiqry_iqry_loc_209
	cmp	word ptr [bp-018h],0EAh
	jnz	short rapiqry_iqry_loc_219
	cmp	word ptr [bp-016h],00h
	jnz	short rapiqry_iqry_loc_219
rapiqry_iqry_loc_209:
	mov	ax,[bp-020h]
	mov	dx,[bp-01Eh]
	les	bx,[bp+01Ah]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
rapiqry_iqry_loc_219:
	mov	ax,[bp-018h]
	mov	dx,[bp-016h]
	pop	si
	mov	sp,bp
	pop	bp
	ret
	nop
RegQueryValueCore	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegCreateKey

;----------------------------------------------------------------------------
; RegCreateKey - Create or open a subkey and return a referenced key handle.
;
; Stack arguments: key, subkey pointer, result-handle pointer.
;----------------------------------------------------------------------------
RegCreateKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapicrea_icrea_loc_029
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegVMCreateKey
	jmp	rapicrea_icrea_loc_12E
rapicrea_icrea_loc_029:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jz	short rapicrea_icrea_loc_049
	jmp	rapicrea_icrea_loc_128
rapicrea_icrea_loc_049:
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],06h
	jnz	short rapicrea_icrea_loc_068
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short rapicrea_icrea_loc_068
	mov	word ptr [bp-014h],05h
rapicrea_icrea_loc_060:
	mov	word ptr [bp-012h],00h
	jmp	rapicrea_icrea_loc_128
rapicrea_icrea_loc_068:
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	ax,02h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-010h]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jz	short rapicrea_icrea_loc_0A7
	jmp	rapicrea_icrea_loc_128
rapicrea_icrea_loc_0A7:
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegFileAddRef
	add	sp,04h
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegFindOrCreate
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jnz	short rapicrea_icrea_loc_0EE
	cmp	dx,ax
	jnz	short rapicrea_icrea_loc_0EE
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegFileReleaseRef
	add	sp,04h
	mov	word ptr [bp-014h],0Eh
	jmp	rapicrea_icrea_loc_060
rapicrea_icrea_loc_0EE:
	les	bx,[bp+0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	mov	bx,ax
	mov	cx,dx
	mov	es,dx
	add	word ptr es:[bx+014h],01h
	adc	word ptr es:[bx+016h],00h
	les	bx,[bp-04h]
	mov	ax,es:[bx+01Ch]
	mov	dx,es:[bx+01Eh]
	mov	bx,[bp-0Ch]
	mov	es,cx
	mov	es:[bx+01Ch],ax
	mov	es:[bx+01Eh],dx
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
rapicrea_icrea_loc_128:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
rapicrea_icrea_loc_12E:
	mov	sp,bp
	pop	bp
	ret
RegCreateKey	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegDeleteKey

;----------------------------------------------------------------------------
; RegDeleteKey - Validate and remove a subkey tree.
;
; Stack arguments: key, subkey pointer.
;----------------------------------------------------------------------------
RegDeleteKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapidelk_idelk_loc_023
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegVMDeleteKey
	jmp	rapidelk_idelk_loc_147
rapidelk_idelk_loc_023:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jz	short rapidelk_idelk_loc_043
	jmp	rapidelk_idelk_loc_141
rapidelk_idelk_loc_043:
	mov	ax,[bp+0Ch]
	or	ax,[bp+0Ah]
	jnz	short rapidelk_idelk_loc_058
	mov	word ptr [bp-0Ch],057h
rapidelk_idelk_loc_050:
	mov	word ptr [bp-0Ah],00h
	jmp	rapidelk_idelk_loc_141
rapidelk_idelk_loc_058:
	les	bx,[bp+0Ah]
	cmp	byte ptr es:[bx],00h
	jnz	short rapidelk_idelk_loc_084
	mov	ax,offset DGROUP:RegRootTable+3*28h
	mov	cx,ds
	cmp	[bp-04h],ax
	jnz	short rapidelk_idelk_loc_070
	cmp	[bp-02h],cx
	jz	short rapidelk_idelk_loc_07D
rapidelk_idelk_loc_070:
	mov	ax,offset DGROUP:RegRootTable+2*28h
	cmp	[bp-04h],ax
	jnz	short rapidelk_idelk_loc_084
	cmp	[bp-02h],cx
	jnz	short rapidelk_idelk_loc_084
rapidelk_idelk_loc_07D:
	mov	word ptr [bp-0Ch],05h
	jmp	short rapidelk_idelk_loc_050
rapidelk_idelk_loc_084:
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	ax,01h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-010h]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short rapidelk_idelk_loc_141
	lea	ax,[bp-014h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	mov	ax,028h
	les	bx,[bp-04h]
	mul	word ptr es:[bx+01Ch]
	add	ax,offset DGROUP:RegRootTable
	push	ds
	push	ax
	call	far ptr RegFindAlias
	add	sp,0Ch
	or	dx,ax
	jz	short rapidelk_idelk_loc_119
	les	bx,[bp-010h]
	test	byte ptr es:[bx+011h],080h
	jnz	short rapidelk_idelk_loc_119
	lea	ax,[bp-014h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	mov	ax,028h
	les	bx,[bp-04h]
	mul	word ptr es:[bx+01Ch]
	add	ax,offset DGROUP:RegRootTable
	push	ds
	push	ax
	call	far ptr RegFindAlias
	add	sp,0Ch
	or	dx,ax
	jnz	short rapidelk_idelk_loc_11C
rapidelk_idelk_loc_119:
	jmp	rapidelk_idelk_loc_07D
rapidelk_idelk_loc_11C:
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegDeleteKeyTree
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegDirtyKeyBlock
rapidelk_idelk_loc_141:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
rapidelk_idelk_loc_147:
	mov	sp,bp
	pop	bp
	ret
RegDeleteKey	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegDeleteValue

;----------------------------------------------------------------------------
; RegDeleteValue - Remove a named value from a writable key.
;
; Stack arguments: key, value-name pointer.
;----------------------------------------------------------------------------
RegDeleteValue	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapidelv_idelv_loc_023
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegVMDeleteValue
	jmp	rapidelv_idelv_loc_0F2
rapidelv_idelv_loc_023:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jz	short rapidelv_idelv_loc_043
	jmp	rapidelv_idelv_loc_0EC
rapidelv_idelv_loc_043:
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	les	bx,[bp-04h]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	push	dx
	push	ax
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	or	dx,ax
	jnz	short rapidelv_idelv_loc_0EC
	les	bx,[bp-010h]
	test	byte ptr es:[bx+011h],080h
	jnz	short rapidelv_idelv_loc_0AE
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],06h
	jnz	short rapidelv_idelv_loc_0BA
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short rapidelv_idelv_loc_0BA
rapidelv_idelv_loc_0AE:
	mov	word ptr [bp-014h],05h
rapidelv_idelv_loc_0B3:
	mov	word ptr [bp-012h],00h
	jmp	short rapidelv_idelv_loc_0EC
rapidelv_idelv_loc_0BA:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegRemoveValue
	add	sp,0Ch
	cmp	ax,0FFFFh
	jnz	short rapidelv_idelv_loc_0E4
	cmp	dx,ax
	jnz	short rapidelv_idelv_loc_0E4
	mov	word ptr [bp-014h],02h
	jmp	short rapidelv_idelv_loc_0B3
rapidelv_idelv_loc_0E4:
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
rapidelv_idelv_loc_0EC:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
rapidelv_idelv_loc_0F2:
	mov	sp,bp
	pop	bp
	ret
RegDeleteValue	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegSetValueCore

;----------------------------------------------------------------------------
; RegSetValueCore - Set a value after resolving its key and checking write access.
;
; Stack arguments: key, subkey pointer, value-name pointer, type,
;                  data pointer, data length.
;----------------------------------------------------------------------------
RegSetValueCore	proc	far
	push	bp
	mov	bp,sp
	sub	sp,010h
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short rapiset_iset_loc_062
	les	bx,[bp-04h]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	ax,02h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	lea	ax,[bp-010h]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jz	short rapiset_iset_loc_064
rapiset_iset_loc_062:
	jmp	short rapiset_iset_loc_0DD
rapiset_iset_loc_064:
	les	bx,[bp-010h]
	test	byte ptr es:[bx+011h],080h
	jnz	short rapiset_iset_loc_080
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],06h
	jnz	short rapiset_iset_loc_08C
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short rapiset_iset_loc_08C
rapiset_iset_loc_080:
	mov	word ptr [bp-0Ch],05h
	mov	word ptr [bp-0Ah],00h
	jmp	short rapiset_iset_loc_0DD
rapiset_iset_loc_08C:
	cmp	word ptr [bp+012h],01h
	jnz	short rapiset_iset_loc_0AE
	cmp	word ptr [bp+014h],00h
	jnz	short rapiset_iset_loc_0AE
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp+01Ah],ax
	mov	word ptr [bp+01Ch],00h
rapiset_iset_loc_0AE:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegSetValue
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
rapiset_iset_loc_0DD:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	mov	sp,bp
	pop	bp
	ret
RegSetValueCore	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegEnumKey

;----------------------------------------------------------------------------
; RegEnumKey - Return a subkey name at the requested index.
;
; Stack arguments: key, index, name-buffer pointer, buffer length.
;----------------------------------------------------------------------------
RegEnumKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,010h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapienmk_ienmk_loc_02E
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	call	far ptr RegVMEnumKey
	jmp	short rapienmk_ienmk_loc_09D
rapienmk_ienmk_loc_02E:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short rapienmk_ienmk_loc_09A
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	ax,[bp+012h]
	mov	dx,[bp+014h]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	lea	ax,[bp-010h]
	push	ss
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegEnumerateKey
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
rapienmk_ienmk_loc_09A:
	mov	dx,[bp-0Ah]
rapienmk_ienmk_loc_09D:
	mov	sp,bp
	pop	bp
	ret
RegEnumKey	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegEnumValue

;----------------------------------------------------------------------------
; RegEnumValue - Return a value name, type and data at the requested index.
;
; Stack arguments: key, index, name-buffer pointer, name-length pointer,
;                  reserved, type pointer, data pointer, data-length pointer.
;----------------------------------------------------------------------------
RegEnumValue	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Ch
	push	si
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapienmv_ienmv_loc_050
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+020h]
	push	word ptr [bp+01Eh]
	push	word ptr [bp+024h]
	push	word ptr [bp+022h]
	call	far ptr RegVMEnumValue
	jmp	rapienmv_ienmv_loc_24E
rapienmv_ienmv_loc_050:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	or	dx,ax
	jz	short rapienmv_ienmv_loc_070
	jmp	rapienmv_ienmv_loc_248
rapienmv_ienmv_loc_070:
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegGetKeyRecord
	add	sp,0Ch
	or	dx,ax
	jz	short rapienmv_ienmv_loc_0C0
rapienmv_ienmv_loc_0B3:
	mov	word ptr [bp-018h],0103h
rapienmv_ienmv_loc_0B8:
	mov	word ptr [bp-016h],00h
	jmp	rapienmv_ienmv_loc_248
rapienmv_ienmv_loc_0C0:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	call	far ptr RegValueAtIndex
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	cmp	ax,0FFFFh
	jnz	short rapienmv_ienmv_loc_0E3
	cmp	dx,ax
	jz	short rapienmv_ienmv_loc_0B3
rapienmv_ienmv_loc_0E3:
	mov	ax,[bp+01Ch]
	or	ax,[bp+01Ah]
	jz	short rapienmv_ienmv_loc_0FF
	les	bx,[bp-010h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	les	bx,[bp+01Ah]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
rapienmv_ienmv_loc_0FF:
	mov	ax,[bp+024h]
	or	ax,[bp+022h]
	jz	short rapienmv_ienmv_loc_148
	les	bx,[bp+022h]
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	les	bx,[bp-010h]
	sub	dx,dx
	mov	ax,es:[bx+0Ah]
	les	bx,[bp+022h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	les	bx,[bp-010h]
	cmp	word ptr es:[bx],01h
	jnz	short rapienmv_ienmv_loc_148
	cmp	es:[bx+02h],dx
	jnz	short rapienmv_ienmv_loc_148
	add	ax,01h
	adc	dx,dx
	les	bx,[bp+022h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
rapienmv_ienmv_loc_148:
	mov	ax,[bp+020h]
	or	ax,[bp+01Eh]
	jz	short rapienmv_ienmv_loc_1C4
	mov	ax,[bp+024h]
	or	ax,[bp+022h]
	jnz	short rapienmv_ienmv_loc_160
	mov	word ptr [bp-018h],057h
	jmp	rapienmv_ienmv_loc_0B8
rapienmv_ienmv_loc_160:
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	les	bx,[bp+022h]
	cmp	es:[bx+02h],dx
	jc	short rapienmv_ienmv_loc_17E
	ja	short rapienmv_ienmv_loc_176
	cmp	es:[bx],ax
	jna	short rapienmv_ienmv_loc_17E
rapienmv_ienmv_loc_176:
	mov	word ptr [bp-018h],0EAh
	jmp	rapienmv_ienmv_loc_0B8
rapienmv_ienmv_loc_17E:
	les	bx,[bp-010h]
	sub	dx,dx
	mov	ax,es:[bx+0Ah]
	push	dx
	push	ax
	mov	ax,es:[bx+08h]
	lea	cx,[bx+0Ch]
	mov	si,es
	add	ax,cx
	adc	dx,si
	push	dx
	push	ax
	push	word ptr [bp+020h]
	push	word ptr [bp+01Eh]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	les	bx,[bp-010h]
	cmp	word ptr es:[bx],01h
	jnz	short rapienmv_ienmv_loc_1C4
	cmp	word ptr es:[bx+02h],00h
	jnz	short rapienmv_ienmv_loc_1C4
	mov	ax,es:[bx+0Ah]
	add	[bp+01Eh],ax
	les	bx,[bp+01Eh]
	mov	byte ptr es:[bx],00h
rapienmv_ienmv_loc_1C4:
	sub	ax,ax
	mov	[bp-016h],ax
	mov	[bp-018h],ax
	les	bx,[bp-010h]
	mov	ax,es:[bx+08h]
	inc	ax
	sub	dx,dx
	les	bx,[bp+012h]
	cmp	dx,es:[bx+02h]
	jc	short rapienmv_ienmv_loc_206
	ja	short rapienmv_ienmv_loc_1E6
	cmp	ax,es:[bx]
	jna	short rapienmv_ienmv_loc_206
rapienmv_ienmv_loc_1E6:
	mov	word ptr [bp-018h],0EAh
	mov	[bp-016h],dx
	mov	ax,es:[bx+02h]
	or	ax,es:[bx]
	jz	short rapienmv_ienmv_loc_248
	mov	ax,es:[bx]
	mov	dx,es:[bx+02h]
	sub	ax,01h
	sbb	dx,00h
	jmp	short rapienmv_ienmv_loc_20D
rapienmv_ienmv_loc_206:
	les	bx,[bp-010h]
	mov	ax,es:[bx+08h]
rapienmv_ienmv_loc_20D:
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	push	dx
	push	ax
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	add	ax,0Ch
	push	dx
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegCopyBytes
	add	sp,0Ch
	mov	ax,[bp-01Ch]
	add	[bp+0Eh],ax
	les	bx,[bp+0Eh]
	mov	byte ptr es:[bx],00h
	mov	dx,[bp-01Ah]
	les	bx,[bp+012h]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
rapienmv_ienmv_loc_248:
	mov	ax,[bp-018h]
	mov	dx,[bp-016h]
rapienmv_ienmv_loc_24E:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegEnumValue	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegUnsupportedOperation

;----------------------------------------------------------------------------
; RegUnsupportedOperation - Return status 03F2h for an unsupported operation.
;
; Stack arguments: none used.
;----------------------------------------------------------------------------
RegUnsupportedOperation	proc	far
	mov	ax,03F2h
	cwd
	ret
RegUnsupportedOperation	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegFlushKey

;----------------------------------------------------------------------------
; RegFlushKey - Save the file owning a key, or set the I/O-inhibit control.
;
; Stack arguments: key or control value.
;----------------------------------------------------------------------------
RegFlushKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiflus_iflus_loc_01C
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegVMFlushKey
	jmp	short rapiflus_iflus_loc_06C
rapiflus_iflus_loc_01C:
	cmp	word ptr [bp+06h],0574Dh
	jnz	short rapiflus_iflus_loc_036
	cmp	word ptr [bp+08h],0484Ah
	jnz	short rapiflus_iflus_loc_036
	mov	word ptr RegIOInhibit,01h
	xor	ax,ax
	xor	dx,dx
	jmp	short rapiflus_iflus_loc_06C
rapiflus_iflus_loc_036:
	lea	cx,[bp-04h]
	push	ss
	push	cx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	or	dx,ax
	jnz	short rapiflus_iflus_loc_069
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegSaveFile
	mov	[bp-08h],ax
	mov	[bp-06h],dx
rapiflus_iflus_loc_069:
	mov	dx,[bp-06h]
rapiflus_iflus_loc_06C:
	mov	sp,bp
	pop	bp
	ret
RegFlushKey	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegRemapKey

;----------------------------------------------------------------------------
; RegRemapKey - Replace a supported root mapping and invalidate its old handles.
;
; Stack arguments: key, destination root.
;----------------------------------------------------------------------------
RegRemapKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	mov	word ptr [bp-08h],03F2h
	mov	word ptr [bp-06h],00h
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiremp_iremp_loc_02D
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegVMRemapKey
	jmp	rapiremp_iremp_loc_1A1
rapiremp_iremp_loc_02D:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	or	dx,ax
	jz	short rapiremp_iremp_loc_04D
	jmp	rapiremp_iremp_loc_19B
rapiremp_iremp_loc_04D:
	cmp	word ptr [bp+0Ah],01h
	jnz	short rapiremp_iremp_loc_0BE
	cmp	word ptr [bp+0Ch],08000h
	jnz	short rapiremp_iremp_loc_0BE
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],03h
	jz	short rapiremp_iremp_loc_067
	jmp	rapiremp_iremp_loc_19B
rapiremp_iremp_loc_067:
	cmp	word ptr es:[bx+01Eh],08000h
	jz	short rapiremp_iremp_loc_072
	jmp	rapiremp_iremp_loc_19B
rapiremp_iremp_loc_072:
	mov	ax,01h
	mov	dx,08000h
	push	dx
	push	ax
	call	far ptr RegInvalidateOwner
	add	sp,04h
	les	bx,[bp-04h]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	word ptr RegRootTable+038h,ax
	mov	word ptr RegRootTable+03Ah,dx
	mov	word ptr RegRootTable+03Ch,01h
	mov	word ptr RegRootTable+03Eh,00h
	mov	word ptr RegRootTable+040h,04000h
	mov	word ptr RegRootTable+042h,00h
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	word ptr RegRootTable+034h,ax
	mov	word ptr RegRootTable+036h,dx
	jmp	rapiremp_iremp_loc_193
rapiremp_iremp_loc_0BE:
	cmp	word ptr [bp+0Ah],05h
	jnz	short rapiremp_iremp_loc_12E
	cmp	word ptr [bp+0Ch],08000h
	jnz	short rapiremp_iremp_loc_12E
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],02h
	jz	short rapiremp_iremp_loc_0D8
	jmp	rapiremp_iremp_loc_19B
rapiremp_iremp_loc_0D8:
	cmp	word ptr es:[bx+01Eh],08000h
	jz	short rapiremp_iremp_loc_0E3
	jmp	rapiremp_iremp_loc_19B
rapiremp_iremp_loc_0E3:
	mov	ax,05h
	mov	dx,08000h
	push	dx
	push	ax
	call	far ptr RegInvalidateOwner
	add	sp,04h
	les	bx,[bp-04h]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	word ptr RegRootTable+0D8h,ax
	mov	word ptr RegRootTable+0DAh,dx
	mov	word ptr RegRootTable+0DCh,01h
	mov	word ptr RegRootTable+0DEh,00h
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	word ptr RegRootTable+0D4h,ax
	mov	word ptr RegRootTable+0D6h,dx
	mov	word ptr RegRootTable+0E0h,04000h
	mov	word ptr RegRootTable+0E2h,00h
	jmp	short rapiremp_iremp_loc_193
rapiremp_iremp_loc_12E:
	cmp	word ptr [bp+0Ah],06h
	jnz	short rapiremp_iremp_loc_19B
	cmp	word ptr [bp+0Ch],08000h
	jnz	short rapiremp_iremp_loc_19B
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+01Ch],06h
	jnz	short rapiremp_iremp_loc_19B
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short rapiremp_iremp_loc_19B
	mov	ax,06h
	mov	dx,08000h
	push	dx
	push	ax
	call	far ptr RegInvalidateOwner
	les	bx,[bp-04h]
	mov	ax,es:[bx+010h]
	mov	dx,es:[bx+012h]
	mov	word ptr RegRootTable+0100h,ax
	mov	word ptr RegRootTable+0102h,dx
	mov	word ptr RegRootTable+0104h,01h
	mov	word ptr RegRootTable+0106h,00h
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	word ptr RegRootTable+0FCh,ax
	mov	word ptr RegRootTable+0FEh,dx
	mov	word ptr RegRootTable+0108h,04000h
	mov	word ptr RegRootTable+010Ah,00h
rapiremp_iremp_loc_193:
	sub	ax,ax
	mov	[bp-06h],ax
	mov	[bp-08h],ax
rapiremp_iremp_loc_19B:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
rapiremp_iremp_loc_1A1:
	mov	sp,bp
	pop	bp
	ret
RegRemapKey	endp
	even
	assume	cs:REGAPI,ds:DGROUP
	public	RegLoadKeyAPI

;----------------------------------------------------------------------------
; RegLoadKeyAPI - Load a registry file and mount it under a supported root.
;
; Stack arguments: root, subkey pointer, file-name pointer.
;----------------------------------------------------------------------------
RegLoadKeyAPI	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	sub	ax,ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiload_iload_loc_031
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegVMLoadKey
	jmp	rapiload_iload_loc_172
rapiload_iload_loc_031:
	cmp	word ptr [bp+06h],02h
	jnz	short rapiload_iload_loc_03E
	cmp	word ptr [bp+08h],08000h
	jz	short rapiload_iload_loc_060
rapiload_iload_loc_03E:
	cmp	word ptr [bp+06h],03h
	jnz	short rapiload_iload_loc_04B
	cmp	word ptr [bp+08h],08000h
	jz	short rapiload_iload_loc_060
rapiload_iload_loc_04B:
	cmp	word ptr [bp+06h],06h
	jnz	short rapiload_iload_loc_058
	cmp	word ptr [bp+08h],08000h
	jz	short rapiload_iload_loc_060
rapiload_iload_loc_058:
	mov	ax,03F2h
	xor	dx,dx
	jmp	rapiload_iload_loc_172
rapiload_iload_loc_060:
	cmp	word ptr [bp+06h],06h
	jnz	short rapiload_iload_loc_074
	cmp	word ptr [bp+08h],08000h
	jnz	short rapiload_iload_loc_074
	mov	word ptr [bp-010h],offset DGROUP:RegRootTable+6*28h
	jmp	short rapiload_iload_loc_094
rapiload_iload_loc_074:
	cmp	word ptr [bp+06h],02h
	jnz	short rapiload_iload_loc_086
	cmp	word ptr [bp+08h],08000h
	jnz	short rapiload_iload_loc_086
	mov	ax,02h
	jmp	short rapiload_iload_loc_089
rapiload_iload_loc_086:
	mov	ax,03h
rapiload_iload_loc_089:
	mov	cx,028h
	imul	cx
	add	ax,offset DGROUP:RegRootTable
	mov	[bp-010h],ax
rapiload_iload_loc_094:
	mov	word ptr [bp-0Eh],ds
	les	bx,[bp-010h]
	test	byte ptr es:[bx+019h],020h
	jz	short rapiload_iload_loc_058
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	mov	ax,01h
	cwd
	push	dx
	push	ax
	lea	ax,[bp-014h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	es
	push	bx
	lea	ax,[bp-04h]
	push	ss
	push	ax
	call	far ptr RegOpenPath
	add	sp,014h
	or	dx,ax
	jnz	short rapiload_iload_loc_0E0
	mov	word ptr [bp-0Ch],03F2h
	mov	word ptr [bp-0Ah],00h
	jmp	rapiload_iload_loc_16C
rapiload_iload_loc_0E0:
	call	far ptr RegHVCreate
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	call	far ptr RegFileCreate
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	word ptr [bp+06h],06h
	jnz	short rapiload_iload_loc_10B
	cmp	word ptr [bp+08h],08000h
	jnz	short rapiload_iload_loc_10B
	les	bx,[bp-04h]
	or	byte ptr es:[bx+011h],01h
rapiload_iload_loc_10B:
	push	dx
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegReadFile
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	or	dx,ax
	jnz	short rapiload_iload_loc_14B
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegAddMount
	add	sp,010h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
rapiload_iload_loc_14B:
	mov	ax,[bp-0Ah]
	or	ax,[bp-0Ch]
	jz	short rapiload_iload_loc_16C
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegFileUnlink
	add	sp,04h
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegHVUnlink
rapiload_iload_loc_16C:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
rapiload_iload_loc_172:
	mov	sp,bp
	pop	bp
	ret
RegLoadKeyAPI	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegUnloadKey

;----------------------------------------------------------------------------
; RegUnloadKey - Unlink a mounted file and release its buffers and handles.
;
; Stack arguments: root, subkey pointer.
;----------------------------------------------------------------------------
RegUnloadKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	sub	ax,ax
	mov	[bp-0Ah],ax
	mov	[bp-0Ch],ax
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapiunld_iunld_loc_02B
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegVMUnloadKey
	jmp	rapiunld_iunld_loc_138
rapiunld_iunld_loc_02B:
	cmp	word ptr [bp+06h],02h
	jnz	short rapiunld_iunld_loc_038
	cmp	word ptr [bp+08h],08000h
	jz	short rapiunld_iunld_loc_04D
rapiunld_iunld_loc_038:
	cmp	word ptr [bp+06h],03h
	jnz	short rapiunld_iunld_loc_045
	cmp	word ptr [bp+08h],08000h
	jz	short rapiunld_iunld_loc_04D
rapiunld_iunld_loc_045:
	mov	ax,03F2h
	xor	dx,dx
	jmp	rapiunld_iunld_loc_138
rapiunld_iunld_loc_04D:
	cmp	word ptr [bp+06h],02h
	jnz	short rapiunld_iunld_loc_05F
	cmp	word ptr [bp+08h],08000h
	jnz	short rapiunld_iunld_loc_05F
	mov	ax,02h
	jmp	short rapiunld_iunld_loc_062
rapiunld_iunld_loc_05F:
	mov	ax,03h
rapiunld_iunld_loc_062:
	mov	cx,028h
	imul	cx
	mov	bx,ax
	add	bx,offset DGROUP:RegRootTable
	mov	[bp-08h],bx
	mov	word ptr [bp-06h],ds
	test	byte ptr [bx+019h],020h
	jz	short rapiunld_iunld_loc_045
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegFindAlias
	add	sp,0Ch
	or	dx,ax
	jz	short rapiunld_iunld_loc_0A3
	mov	word ptr [bp-0Ch],03F2h
	mov	word ptr [bp-0Ah],00h
	jmp	rapiunld_iunld_loc_132
rapiunld_iunld_loc_0A3:
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegInvalidateFile
	add	sp,04h
	mov	ax,word ptr RegRootTable+034h
	mov	dx,word ptr RegRootTable+036h
	les	bx,[bp-04h]
	cmp	es:[bx+0Ch],ax
	jnz	short rapiunld_iunld_loc_0DA
	cmp	es:[bx+0Eh],dx
	jnz	short rapiunld_iunld_loc_0DA
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	call	far ptr RegInitUserRoot
	add	sp,04h
rapiunld_iunld_loc_0DA:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegUnlinkMount
	add	sp,08h
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegReleaseFileBuffers
	add	sp,04h
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegFileUnlink
	add	sp,04h
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr ConfigFree
	add	sp,04h
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
rapiunld_iunld_loc_132:
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
rapiunld_iunld_loc_138:
	mov	sp,bp
	pop	bp
	ret
RegUnloadKey	endp
	assume	cs:REGAPI,ds:DGROUP
	public	RegSaveKey

;----------------------------------------------------------------------------
; RegSaveKey - Save a key tree through a temporary mount, then release resources.
;
; Stack arguments: key, file-name pointer, options passed to Windows.
;----------------------------------------------------------------------------
RegSaveKey	proc	far
	push	bp
	mov	bp,sp
	sub	sp,022h
	push	di
	push	si
	sub	ax,ax
	mov	[bp-02h],ax
	mov	[bp-04h],ax
	mov	ax,0FFFFh
	cwd
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	lea	di,[bp-01Ah]
	mov	si,offset DGROUP:RegSaveName
	push	ss
	pop	es
	mov	cx,05h
	rep	movsw
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rapisave_isave_loc_050
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	call	far ptr RegVMSaveKey
	jmp	rapisave_isave_loc_208
rapisave_isave_loc_050:
	lea	ax,[bp-022h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short rapisave_isave_loc_070
	jmp	rapisave_isave_loc_1CE
rapisave_isave_loc_070:
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegPrepareSaveFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short rapisave_isave_loc_091
	jmp	rapisave_isave_loc_1CE
rapisave_isave_loc_091:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,0100h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jnz	short rapisave_isave_loc_0B2
	cmp	dx,ax
	jz	short rapisave_isave_loc_0D3
rapisave_isave_loc_0B2:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,04000h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	cmp	ax,0FFFFh
	jnz	short rapisave_isave_loc_0E0
	cmp	dx,ax
	jnz	short rapisave_isave_loc_0E0
rapisave_isave_loc_0D3:
	mov	word ptr [bp-04h],0Eh
	mov	word ptr [bp-02h],00h
	jmp	rapisave_isave_loc_16B
rapisave_isave_loc_0E0:
	mov	al,RegSaveSequence
	mov	[bp-012h],al
	inc	byte ptr RegSaveSequence
	cmp	byte ptr RegSaveSequence,039h
	jna	short rapisave_isave_loc_0F6
	mov	byte ptr RegSaveSequence,030h
rapisave_isave_loc_0F6:
	les	bx,[bp-022h]
	cmp	word ptr es:[bx+01Ch],03h
	jnz	short rapisave_isave_loc_108
	cmp	word ptr es:[bx+01Eh],08000h
	jz	short rapisave_isave_loc_117
rapisave_isave_loc_108:
	cmp	word ptr es:[bx+01Ch],01h
	jnz	short rapisave_isave_loc_11E
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short rapisave_isave_loc_11E
rapisave_isave_loc_117:
	mov	word ptr [bp-01Eh],02h
	jmp	short rapisave_isave_loc_123
rapisave_isave_loc_11E:
	mov	word ptr [bp-01Eh],03h
rapisave_isave_loc_123:
	mov	word ptr [bp-01Ch],08000h
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	lea	cx,[bp-01Ah]
	push	ss
	push	cx
	push	word ptr [bp-01Ch]
	push	word ptr [bp-01Eh]
	push	cs
	call	near ptr RegLoadKeyAPI
	add	sp,0Ch
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short rapisave_isave_loc_16B
	lea	ax,[bp-08h]
	push	ss
	push	ax
	lea	ax,[bp-01Ah]
	push	ss
	push	ax
	push	word ptr [bp-01Ch]
	push	word ptr [bp-01Eh]
	push	cs
	call	near ptr RegOpenKey
	add	sp,0Ch
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short rapisave_isave_loc_17C
rapisave_isave_loc_16B:
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigDelete
	jmp	short rapisave_isave_loc_1CB
rapisave_isave_loc_17C:
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegCopyKeyTree
	add	sp,010h
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	cs
	call	near ptr RegFlushKey
	add	sp,04h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	cs
	call	near ptr RegCloseKey
	add	sp,04h
	lea	ax,[bp-01Ah]
	push	ss
	push	ax
	push	word ptr [bp-01Ch]
	push	word ptr [bp-01Eh]
	push	cs
	call	near ptr RegUnloadKey
rapisave_isave_loc_1CB:
	add	sp,08h
rapisave_isave_loc_1CE:
	cmp	word ptr [bp-0Ch],-1
	jnz	short rapisave_isave_loc_1DA
	cmp	word ptr [bp-0Ah],-1
	jz	short rapisave_isave_loc_1E8
rapisave_isave_loc_1DA:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	call	far ptr ConfigFree
	add	sp,04h
rapisave_isave_loc_1E8:
	cmp	word ptr [bp-010h],-1
	jnz	short rapisave_isave_loc_1F4
	cmp	word ptr [bp-0Eh],-1
	jz	short rapisave_isave_loc_202
rapisave_isave_loc_1F4:
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr ConfigFree
	add	sp,04h
rapisave_isave_loc_202:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
rapisave_isave_loc_208:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegSaveKey	endp
REGAPI	ends
	end
