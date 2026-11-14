;** REGINIT - Registry block initialization, mounts and tree export
;
; FAR C entries use caller-supplied buffers and handles. Mount and
; export services use DGROUP; block initializers use their buffer only.
;
	.286
	extrn	RegCompareN:far
	extrn	RegNameSum:far
	extrn	RegPathPart:far
	extrn	RegStringLength:far
	extrn	RegAllocate:far
	extrn	RegCopyBytes:far
	extrn	ConfigClose:far
	extrn	ConfigCreate:far
	extrn	ConfigDelete:far
	extrn	ConfigFree:far
	extrn	ConfigSeek:far
	extrn	ConfigWriteAll:far
	extrn	RegGetKeyRecord:far
	extrn	RegLoadKey:far
	extrn	RegValidateKeyHandle:far
	extrn	RegCloseKey:far
	extrn	RegCreateKey:far
	extrn	RegEnumKey:far
	extrn	RegEnumValue:far
	extrn	RegOpenKey:far
	extrn	RegSetValueCore:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGFILE	segment	word public 'CODE'
REGFILE	ends
REGFINAL	segment	word public 'CODE'
REGFINAL	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	RegIOInhibit:word
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegPathBuffer:byte
c_common	ends
REGFILE	segment	word public 'CODE'
	extrn	RegValidateHeader:near
REGFILE	ends
REGFINAL	segment	word public 'CODE'
	assume	cs:REGFINAL
	public	RegInitHeader

;** RegInitHeader - Initialize and validate a CREG header
;
; ENTRY: [BP+6] = FAR destination buffer, [BP+10] = WORD header option.
;
RegInitHeader	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	mov	word ptr es:[bx],5243h       ; CREG signature
	mov	word ptr es:[bx+2],4745h
	mov	word ptr es:[bx+4],0
	mov	word ptr es:[bx+6],1
	mov	word ptr es:[bx+8],1000h
	mov	word ptr es:[bx+10],0
	sub	ax,ax
	mov	es:[bx+14],ax
	mov	es:[bx+12],ax
	mov	word ptr es:[bx+16],1
	mov	es:[bx+20],ax
	mov	es:[bx+18],ax
	mov	ax,[bp+10]
	mov	es:[bx+22],ax
	xor	al,al
	mov	es:[bx+26],al
	mov	es:[bx+25],al
	mov	es:[bx+24],al
	push	es
	push	bx
	call	far ptr RegValidateHeader
	mov	sp,bp
	pop	bp
	ret
RegInitHeader	endp
	even
	assume	cs:REGFINAL
	public	RegInitKeyBlock,RegInitKeyRecords,RegInitDataBlock

;** RegInitKeyBlock - Initialize an RGKN block header
;
; ENTRY: [BP+6] = FAR destination buffer, allocated by the caller.
;
RegInitKeyBlock	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	mov	word ptr es:[bx],4752h       ; RGKN signature
	mov	word ptr es:[bx+2],4E4Bh
	mov	word ptr es:[bx+4],0FE0h
	mov	word ptr es:[bx+6],0
	mov	word ptr es:[bx+8],20h
	mov	word ptr es:[bx+10],0
	mov	word ptr es:[bx+12],3Ch
	mov	word ptr es:[bx+14],0
	mov	word ptr es:[bx+16],8
	mov	word ptr es:[bx+18],0
	pop	bp
	ret
RegInitKeyBlock	endp
	even

;** RegInitKeyRecords - Initialize a key and its following free record
;
; ENTRY: [BP+6] = FAR destination buffer.
; Advance the stack argument by 1Ch, adjusting its segment by 1000h
; paragraphs when the offset crosses a 64K boundary.
;
RegInitKeyRecords	proc	far
	push	bp
	mov	bp,sp
	les	bx,[bp+6]
	sub	ax,ax
	mov	es:[bx+2],ax
	mov	es:[bx],ax
	mov	es:[bx+6],ax
	mov	es:[bx+4],ax
	mov	es:[bx+10],ax
	mov	es:[bx+8],ax
	mov	ax,-1
	cwd
	mov	es:[bx+12],ax
	mov	es:[bx+14],dx
	mov	es:[bx+16],ax
	mov	es:[bx+18],ax
	mov	es:[bx+20],ax
	mov	es:[bx+22],dx
	mov	es:[bx+24],ax
	mov	es:[bx+26],ax
	add	word ptr [bp+6],1Ch
	sbb	cx,cx
	and	cx,1000h
	add	[bp+8],cx
	mov	bx,[bp+6]
	mov	cx,[bp+8]
	mov	es,cx
	mov	es:[bx],ax
	mov	es:[bx+2],ax
	mov	word ptr es:[bx+4],0FA4h
	mov	word ptr es:[bx+6],0
	mov	es:[bx+8],ax
	mov	es:[bx+10],ax
	pop	bp
	ret
RegInitKeyRecords	endp
	even

;** RegInitDataBlock - Initialize a 4K RGDB block and its free record
;
; ENTRY: [BP+6] = FAR destination buffer, allocated by the caller.
;
RegInitDataBlock	proc	far
	push	bp
	mov	bp,sp
	sub	sp,4
	push	si
	les	bx,[bp+6]
	mov	word ptr es:[bx],4752h       ; RGDB signature
	mov	word ptr es:[bx+2],4244h
	mov	word ptr es:[bx+4],1000h
	mov	word ptr es:[bx+6],0
	sub	ax,ax
	mov	es:[bx+14],ax
	mov	es:[bx+12],ax
	mov	word ptr es:[bx+16],20h
	mov	es:[bx+18],ax
	mov	es:[bx+20],ax
	mov	es:[bx+22],ax
	mov	ax,es
	add	bx,20h
	adc	ax,0
	mov	cx,0FE0h
	mov	si,[bp+6]
	xor	dx,dx
	mov	es:[si+8],cx
	mov	es:[si+10],dx
	mov	es,ax
	mov	es:[bx],cx
	mov	es:[bx+2],dx
	mov	dx,-1
	mov	es:[bx+4],dx
	mov	es:[bx+6],dx
	mov	es:[bx+8],dx
	mov	es:[bx+10],dx
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegInitDataBlock	endp

	assume	cs:REGFINAL,ds:DGROUP
	public	RegFindAlias

;** RegFindAlias - Find a mount by component hash and name
;
; ENTRY: [BP+6] = FAR parent, [BP+0Ah] = FAR name,
;        [BP+0Eh] = FAR address receiving the mount pointer.
; EXIT:  DX:AX = status; zero indicates a match.
; Uses the shared RegPathBuffer; the name must be a single component.
;
RegFindAlias	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Eh
	les	bx,[bp+06h]
	test	byte ptr es:[bx+019h],020h
	jnz	short regalias_alias_loc_018
regalias_alias_loc_010:
	mov	ax,03F3h
regalias_alias_loc_013:
	xor	dx,dx
	jmp	regalias_alias_loc_0D8
regalias_alias_loc_018:
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegPathPart
	add	sp,08h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	cmp	ax,0FFFFh
	jnz	short regalias_alias_loc_03F
	cmp	dx,ax
	jnz	short regalias_alias_loc_03F
regalias_alias_loc_03A:
	mov	ax,03F2h
	jmp	short regalias_alias_loc_013
regalias_alias_loc_03F:
	les	bx,[bp-0Ch]
	cmp	byte ptr es:[bx],00h
	jnz	short regalias_alias_loc_03A
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegNameSum
	add	sp,04h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp-0Eh],ax
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
regalias_alias_loc_076:
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regalias_alias_loc_085
	cmp	dx,ax
	jz	short regalias_alias_loc_010
regalias_alias_loc_085:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-04h]
	cmp	es:[bx+018h],ax
	jnz	short regalias_alias_loc_0CB
	cmp	es:[bx+01Ah],dx
	jnz	short regalias_alias_loc_0CB
	push	word ptr [bp-0Eh]
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	mov	ax,offset DGROUP:RegPathBuffer
	push	ds
	push	ax
	call	far ptr RegCompareN
	add	sp,0Ah
	or	ax,ax
	jnz	short regalias_alias_loc_0CB
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,[bp+0Eh]
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	xor	ax,ax
	jmp	regalias_alias_loc_013
regalias_alias_loc_0CB:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regalias_alias_loc_076
regalias_alias_loc_0D8:
	mov	sp,bp
	pop	bp
	ret
RegFindAlias	endp
	assume	cs:REGFINAL,ds:DGROUP
	public	RegAddMount

;** RegAddMount - Link a mounted file to its parent
;
; ENTRY: [BP+6] = FAR parent, [BP+0Ah] = FAR name,
;        [BP+0Eh] = FAR mount record, [BP+12h] = FAR file record.
; EXIT:  DX:AX = status; zero indicates success.
; Allocates the name copy. The caller supplies the mount and file records.
;
RegAddMount	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	push	di
	les	bx,[bp+0Eh]
	mov	ax,[bp+012h]
	mov	dx,[bp+014h]
	mov	es:[bx+0Ch],ax
	mov	es:[bx+0Eh],dx
	mov	es,dx
	mov	bx,ax
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	les	bx,[bp+0Eh]
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegStringLength
	add	sp,04h
	inc	ax
	sub	dx,dx
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,08h
	mov	[bp-06h],dx
	or	dx,ax
	jnz	short regmntad_mntad_loc_067
	mov	ax,0Eh
regmntad_mntad_loc_062:
	xor	dx,dx
	jmp	regmntad_mntad_loc_110
regmntad_mntad_loc_067:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	mov	dx,[bp-06h]
	les	bx,[bp+0Eh]
	mov	es:[bx+014h],ax
	mov	es:[bx+016h],dx
	push	dx
	push	ax
	call	far ptr RegCopyBytes
	add	sp,0Ch
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegNameSum
	add	sp,04h
	les	bx,[bp+0Eh]
	mov	es:[bx+018h],ax
	mov	es:[bx+01Ah],dx
	mov	word ptr es:[bx+04h],0FFFFh
	mov	word ptr es:[bx+06h],0FFFFh
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	les	bx,[bp+0Eh]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	cmp	ax,0FFFFh
	jnz	short regmntad_mntad_loc_0CF
	cmp	dx,ax
	jz	short regmntad_mntad_loc_0E1
regmntad_mntad_loc_0CF:
	mov	es,dx
	mov	bx,ax
	mov	di,[bp+0Eh]
	mov	cx,[bp+010h]
	mov	es:[bx+04h],di
	mov	es:[bx+06h],cx
regmntad_mntad_loc_0E1:
	mov	ax,[bp+0Eh]
	mov	dx,[bp+010h]
	les	bx,[bp+06h]
	mov	es:[bx+024h],ax
	mov	es:[bx+026h],dx
	cmp	word ptr es:[bx+01Ch],06h
	jnz	short regmntad_mntad_loc_10B
	cmp	word ptr es:[bx+01Eh],08000h
	jnz	short regmntad_mntad_loc_10B
	and	byte ptr es:[bx+019h],0EFh
	and	byte ptr es:[bx+01Ah],0EFh
regmntad_mntad_loc_10B:
	xor	ax,ax
	jmp	regmntad_mntad_loc_062
regmntad_mntad_loc_110:
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegAddMount	endp
	even
	assume	cs:REGFINAL,ds:DGROUP
	public	RegUnlinkMount

;** RegUnlinkMount - Remove a mount from its parent's list
;
; ENTRY: [BP+6] = FAR parent, [BP+0Ah] = FAR mount record.
; Updates the list links and head without freeing the record or its name.
;
RegUnlinkMount	proc	far
	push	bp
	mov	bp,sp
	sub	sp,04h
	push	si
	les	bx,[bp+0Ah]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regmntun_mntun_loc_021
	cmp	dx,ax
	jz	short regmntun_mntun_loc_035
regmntun_mntun_loc_021:
	mov	cx,es:[bx+04h]
	mov	si,es:[bx+06h]
	mov	bx,ax
	mov	es,dx
	mov	es:[bx+04h],cx
	mov	es:[bx+06h],si
regmntun_mntun_loc_035:
	les	bx,[bp+0Ah]
	cmp	word ptr es:[bx+04h],-1
	jnz	short regmntun_mntun_loc_046
	cmp	word ptr es:[bx+06h],-1
	jz	short regmntun_mntun_loc_05A
regmntun_mntun_loc_046:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	les	bx,es:[bx+04h]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	jmp	short regmntun_mntun_loc_07B
regmntun_mntun_loc_05A:
	mov	ax,bx
	mov	dx,es
	les	bx,[bp+06h]
	cmp	es:[bx+024h],ax
	jnz	short regmntun_mntun_loc_07B
	cmp	es:[bx+026h],dx
	jnz	short regmntun_mntun_loc_07B
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	es:[bx+024h],ax
	mov	es:[bx+026h],dx
regmntun_mntun_loc_07B:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegUnlinkMount	endp
	assume	cs:REGFINAL,ds:DGROUP
	public	RegPrepareSaveFile

;** RegPrepareSaveFile - Create the initial registry export file
;
; ENTRY: [BP+6] = key handle, [BP+0Ah] = FAR file name.
; EXIT:  DX:AX = status.
; Allocates and releases a 4K work buffer. Closes the file on exit;
; deletes an incomplete file on the error cleanup path.
;
RegPrepareSaveFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,02Ch
	push	di
	push	si
	mov	word ptr [bp-01Ah],0FFFFh
	cmp	word ptr RegIOInhibit,00h
	jz	short regprep_prep_loc_01C
	mov	ax,03F8h
regprep_prep_loc_017:
	xor	dx,dx
	jmp	regprep_prep_loc_2F0
regprep_prep_loc_01C:
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	or	dx,ax
	jz	short regprep_prep_loc_042
regprep_prep_loc_039:
	mov	ax,[bp-010h]
	mov	dx,[bp-0Eh]
	jmp	regprep_prep_loc_2F0
regprep_prep_loc_042:
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,01000h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,08h
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	cmp	ax,0FFFFh
	jnz	short regprep_prep_loc_068
	cmp	dx,ax
	jnz	short regprep_prep_loc_068
	mov	ax,0Eh
	jmp	short regprep_prep_loc_017
regprep_prep_loc_068:
	lea	ax,[bp-08h]
	push	ss
	push	ax
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	call	far ptr RegLoadKey
	add	sp,08h
	push	dx
	push	ax
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegGetKeyRecord
	add	sp,0Ch
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	or	dx,ax
	jz	short regprep_prep_loc_0AA
	jmp	regprep_prep_loc_2AC
regprep_prep_loc_0AA:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	add	ax,014h
	push	dx
	push	ax
	call	far ptr RegNameSum
	add	sp,04h
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigCreate
	add	sp,08h
	mov	[bp-01Ah],ax
	cmp	ax,0FFFFh
	jnz	short regprep_prep_loc_0EA
regprep_prep_loc_0DD:
	mov	word ptr [bp-010h],03F8h
	mov	word ptr [bp-0Eh],00h
	jmp	regprep_prep_loc_2AC
regprep_prep_loc_0EA:
	mov	ax,080h
	push	ax
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	cs
	call	near ptr RegInitHeader
	add	sp,06h
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	word ptr [bp-01Ah]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regprep_prep_loc_11F
	cmp	dx,ax
	jz	short regprep_prep_loc_0DD
regprep_prep_loc_11F:
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	cs
	call	near ptr RegInitKeyBlock
	add	sp,04h
	mov	ax,[bp-014h]
	mov	dx,[bp-012h]
	add	ax,020h
	mov	[bp-01Eh],ax
	mov	[bp-01Ch],dx
	push	dx
	push	ax
	mov	di,ax
	mov	[bp-02Ch],ax
	mov	[bp-02Ah],dx
	mov	si,dx
	push	cs
	call	near ptr RegInitKeyRecords
	add	sp,04h
	mov	bx,[bp-02Ch]
	mov	es,si
	sub	ax,ax
	mov	es:[bx+01Ah],ax
	mov	es:[bx+018h],ax
	mov	ax,[bp-018h]
	mov	dx,[bp-016h]
	mov	es:[bx+04h],ax
	mov	es:[bx+06h],dx
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,058h
	cwd
	push	dx
	push	ax
	push	si
	push	word ptr [bp-014h]
	push	word ptr [bp-01Ah]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,01000h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-01Ah]
	call	far ptr ConfigSeek
	add	sp,0Eh
	push	si
	push	word ptr [bp-014h]
	push	cs
	call	near ptr RegInitDataBlock
	add	sp,04h
	mov	[bp-0Ch],di
	mov	[bp-0Ah],si
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	add	ax,014h
	push	dx
	push	ax
	call	far ptr RegStringLength
	add	sp,04h
	mov	[bp-024h],ax
	mov	es,si
	sub	ax,ax
	mov	es:[di+06h],ax
	mov	es:[di+04h],ax
	mov	ax,[bp-024h]
	mov	es:[di+0Ch],ax
	xor	cx,cx
	mov	es:[di+0Eh],cx
	mov	es:[di+010h],cx
	mov	es:[di+012h],cx
	sub	dx,dx
	push	dx
	push	ax
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	add	ax,014h
	push	dx
	push	ax
	lea	ax,[di+014h]
	push	si
	push	ax
	call	far ptr RegCopyBytes
	add	sp,0Ch
	mov	es,si
	mov	ax,[bp-024h]
	add	ax,014h
	sub	dx,dx
	mov	es:[di+08h],ax
	mov	es:[di+0Ah],dx
	mov	[bp-022h],ax
	mov	[bp-020h],dx
	mov	es:[di],ax
	mov	es:[di+02h],dx
	mov	bx,[bp-014h]
	mov	cx,ax
	mov	word ptr es:[bx+016h],01h
	mov	si,dx
	add	ax,020h
	adc	dx,dx
	mov	es:[bx+010h],ax
	mov	es:[bx+012h],dx
	mov	di,es
	add	ax,bx
	adc	dx,di
	mov	[bp-028h],ax
	mov	[bp-026h],dx
	mov	es,dx
	mov	bx,ax
	mov	dx,0FFFFh
	mov	di,dx
	mov	es:[bx+04h],dx
	mov	es:[bx+06h],dx
	mov	es:[bx+08h],dx
	mov	es:[bx+0Ah],dx
	mov	ax,0FE0h
	cwd
	sub	ax,cx
	sbb	dx,si
	mov	es:[bx],ax
	mov	es:[bx+02h],dx
	les	bx,[bp-014h]
	mov	es:[bx+08h],ax
	mov	es:[bx+0Ah],dx
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,01000h
	cwd
	push	dx
	push	ax
	push	es
	push	bx
	push	word ptr [bp-01Ah]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	mov	ax,01h
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-01Ah]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigClose
	add	sp,0Eh
	mov	[bp-01Ah],di
regprep_prep_loc_2AC:
	cmp	word ptr [bp-01Ah],-1
	jz	short regprep_prep_loc_2DF
	mov	ax,01h
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-01Ah]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigClose
	add	sp,0Eh
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigDelete
	add	sp,08h
regprep_prep_loc_2DF:
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	call	far ptr ConfigFree
	add	sp,04h
	jmp	regprep_prep_loc_039
regprep_prep_loc_2F0:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
RegPrepareSaveFile	endp
	assume	cs:REGFINAL,ds:DGROUP
	public	RegCopyKeyTree

;** RegCopyKeyTree - Copy values and subkeys recursively
;
; ENTRY: [BP+6] = source key, [BP+0Ah] = destination key,
;        [BP+0Eh] = FAR name buffer (100h bytes),
;        [BP+12h] = FAR data buffer (4000h bytes).
; Recursive calls share the caller's buffers. Opened subkeys are closed
; after each recursive copy.
;
RegCopyKeyTree	proc	far
	push	bp
	mov	bp,sp
	sub	sp,018h
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
	jmp	short regcopy_copy_loc_042
regcopy_copy_loc_010:
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp-016h]
	push	word ptr [bp-018h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegSetValueCore
	add	sp,018h
	add	word ptr [bp-014h],01h
	adc	word ptr [bp-012h],00h
regcopy_copy_loc_042:
	mov	word ptr [bp-04h],0100h
	mov	word ptr [bp-02h],00h
	mov	word ptr [bp-08h],04000h
	mov	word ptr [bp-06h],00h
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	lea	ax,[bp-018h]
	push	ss
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-04h]
	push	ss
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegEnumValue
	add	sp,020h
	or	dx,ax
	jz	short regcopy_copy_loc_010
	sub	ax,ax
	mov	[bp-012h],ax
	mov	[bp-014h],ax
	jmp	short regcopy_copy_loc_09F
regcopy_copy_loc_097:
	add	word ptr [bp-014h],01h
	adc	word ptr [bp-012h],00h
regcopy_copy_loc_09F:
	mov	ax,0100h
	cwd
	push	dx
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-012h]
	push	word ptr [bp-014h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegEnumKey
	add	sp,010h
	or	dx,ax
	jnz	short regcopy_copy_loc_133
	lea	cx,[bp-0Ch]
	push	ss
	push	cx
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegOpenKey
	add	sp,0Ch
	lea	ax,[bp-010h]
	push	ss
	push	ax
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegCreateKey
	add	sp,0Ch
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	cs
	call	near ptr RegCopyKeyTree
	add	sp,010h
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	call	far ptr RegCloseKey
	add	sp,04h
	push	word ptr [bp-0Eh]
	push	word ptr [bp-010h]
	call	far ptr RegCloseKey
	add	sp,04h
	jmp	regcopy_copy_loc_097
regcopy_copy_loc_133:
	mov	sp,bp
	pop	bp
	ret
RegCopyKeyTree	endp
	even
REGFINAL	ends
	end
