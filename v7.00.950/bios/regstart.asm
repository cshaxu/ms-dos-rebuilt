;** REGSTART - Registry root initialization and lifetime
;
; FAR C entries initialize predefined roots and release their storage.
; Windows-provider paths and local registry files share the root table.
;
	.286
	extrn	ConfigDelete:far
	extrn	ConfigGetAttr:far
	extrn	RegFileCreate:far
	extrn	RegGetVMEntry:far
	extrn	RegIsWindowsPath:far
	extrn	RegReadFile:far
	extrn	RegRecoverFile:far
	extrn	RegCreatePath:far
	extrn	RegLoadKey:far
	extrn	RegOpenPath:far
	extrn	RegValidateKeyHandle:far
	extrn	ConfigFree:far
	extrn	RegFileUnlink:far
	extrn	ConfigClose:far
	extrn	ConfigCreate:far
	extrn	ConfigSeek:far
	extrn	ConfigWriteAll:far
	extrn	RegAllocate:far
	extrn	RegInitDataBlock:far
	extrn	RegInitHeader:far
	extrn	RegInitKeyBlock:far
	extrn	RegInitKeyRecords:far
	extrn	RegSaveFile:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGSTART	segment	word public 'CODE'
REGSTART	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	RegRootTable:byte
	extrn	RegHandleList:dword
	extrn	RegClassesPath:byte
	extrn	RegDefaultUser:byte
	extrn	RegReserveSize:dword,RegReserveBlock:dword
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegVMEntry:dword
c_common	ends
REGSTART	segment	word public 'CODE'
	assume	cs:REGSTART,ds:DGROUP
	public	RegInitialize

;** RegInitialize - Initialize system and user roots
;
; ENTRY: [BP+6] = FAR system path, [BP+0Ah] = FAR user path,
;        [BP+0Eh] = load flags.
; Recover and load local files, or obtain the Windows registry provider.
; Load flags control empty-file recovery. EXIT: DX:AX = status.
;
RegInitialize	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	sub	ax,ax
	mov	[bp-02h],ax
	mov	[bp-04h],ax
	mov	word ptr [bp-0Ch],0FFFFh
	mov	word ptr [bp-0Ah],0FFFFh
	mov	ax,[bp+0Ch]
	or	ax,[bp+0Ah]
	jnz	short regstart_start_loc_023
	jmp	regstart_start_loc_249
regstart_start_loc_023:
	cmp	word ptr RegRootTable+084h,-1
	jnz	short regstart_start_loc_031
	cmp	word ptr RegRootTable+086h,-1
	jz	short regstart_start_loc_040
regstart_start_loc_031:
	push	word ptr RegRootTable+086h
	push	word ptr RegRootTable+084h
	push	cs
	call	near ptr RegReleaseFileBuffers
	add	sp,04h
regstart_start_loc_040:
	mov	ax,[bp+08h]
	or	ax,[bp+06h]
	jz	short regstart_start_loc_09B
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegIsWindowsPath
	add	sp,04h
	or	dx,ax
	jz	short regstart_start_loc_093
	cmp	word ptr RegRootTable+05Ch,-1
	jnz	short regstart_start_loc_068
	cmp	word ptr RegRootTable+05Eh,-1
	jz	short regstart_start_loc_077
regstart_start_loc_068:
	push	word ptr RegRootTable+05Eh
	push	word ptr RegRootTable+05Ch
regstart_start_loc_070:
	push	cs
	call	near ptr RegReleaseFileBuffers
	add	sp,04h
regstart_start_loc_077:
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jnz	short regstart_start_loc_08C
	call	far ptr RegGetVMEntry
	or	dx,ax
	jnz	short regstart_start_loc_08C
	jmp	regstart_start_loc_257
regstart_start_loc_08C:
	xor	ax,ax
regstart_start_loc_08E:
	xor	dx,dx
	jmp	regstart_start_loc_39B
regstart_start_loc_093:
	sub	ax,ax
	mov	word ptr RegVMEntry+2,ax
	mov	word ptr RegVMEntry,ax
regstart_start_loc_09B:
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jnz	short regstart_start_loc_08C
	cmp	word ptr RegRootTable+084h,-1
	jnz	short regstart_start_loc_0BE
	cmp	word ptr RegRootTable+086h,-1
	jnz	short regstart_start_loc_0BE
	call	far ptr RegFileCreate
	mov	word ptr RegRootTable+084h,ax
	mov	word ptr RegRootTable+086h,dx
regstart_start_loc_0BE:
	mov	ax,word ptr RegRootTable+084h
	mov	dx,word ptr RegRootTable+086h
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegRecoverFile
	add	sp,04h
	or	dx,ax
	jz	short regstart_start_loc_0E5
	les	bx,[bp-0Ch]
	or	byte ptr es:[bx+011h],02h
regstart_start_loc_0E5:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegReadFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short regstart_start_loc_109
	test	byte ptr [bp+0Eh],05h
	jnz	short regstart_start_loc_10C
regstart_start_loc_109:
	jmp	regstart_start_loc_19C
regstart_start_loc_10C:
	cmp	ax,0Eh
	jnz	short regstart_start_loc_11A
	cmp	word ptr [bp-02h],00h
	jnz	short regstart_start_loc_11A
	jmp	regstart_start_loc_19C
regstart_start_loc_11A:
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+010h]
	and	ax,0228h
	mov	[bp-08h],ax
	mov	word ptr [bp-06h],00h
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigGetAttr
	add	sp,08h
	or	dx,ax
	jz	short regstart_start_loc_154
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr ConfigDelete
	add	sp,08h
regstart_start_loc_154:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	cs
	call	near ptr RegCreateEmptyFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regstart_start_loc_18B
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegReadFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
regstart_start_loc_18B:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-0Ch]
	or	es:[bx+010h],ax
	or	es:[bx+012h],dx
regstart_start_loc_19C:
	mov	ax,[bp-02h]
	or	ax,[bp-04h]
	jnz	short regstart_start_loc_1EB
	les	bx,[bp-0Ch]
	cmp	word ptr es:[bx+024h],-1
	jnz	short regstart_start_loc_1B5
	cmp	word ptr es:[bx+026h],-1
	jz	short regstart_start_loc_1EB
regstart_start_loc_1B5:
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	word ptr RegRootTable+088h,ax
	mov	word ptr RegRootTable+08Ah,dx
	mov	word ptr RegRootTable+08Ch,01h
	mov	word ptr RegRootTable+08Eh,00h
	and	byte ptr RegRootTable+091h,0EFh
	and	byte ptr RegRootTable+092h,0EFh
	mov	ax,0FFFFh
	cwd
	push	dx
	push	ax
	push	cs
	call	near ptr RegInitUserRoot
	add	sp,04h
regstart_start_loc_1EB:
	mov	ax,[bp+08h]
	or	ax,[bp+06h]
	jz	short regstart_start_loc_1FB
	mov	ax,[bp-02h]
	or	ax,[bp-04h]
	jz	short regstart_start_loc_1FE
regstart_start_loc_1FB:
	jmp	regstart_start_loc_395
regstart_start_loc_1FE:
	cmp	word ptr RegRootTable+05Ch,-1
	jnz	short regstart_start_loc_20C
	cmp	word ptr RegRootTable+05Eh,-1
	jz	short regstart_start_loc_21B
regstart_start_loc_20C:
	push	word ptr RegRootTable+05Eh
	push	word ptr RegRootTable+05Ch
	push	cs
	call	near ptr RegReleaseFileBuffers
	add	sp,04h
regstart_start_loc_21B:
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegIsWindowsPath
	add	sp,04h
	or	dx,ax
	jz	short regstart_start_loc_25D
	cmp	word ptr RegRootTable+084h,-1
	jnz	short regstart_start_loc_23E
	cmp	word ptr RegRootTable+086h,-1
	jnz	short regstart_start_loc_23E
	jmp	regstart_start_loc_077
regstart_start_loc_23E:
	push	word ptr RegRootTable+086h
	push	word ptr RegRootTable+084h
	jmp	regstart_start_loc_070
regstart_start_loc_249:
	mov	ax,[bp+08h]
	or	ax,[bp+06h]
	jnz	short regstart_start_loc_1EB
	mov	ax,057h
	jmp	regstart_start_loc_08E
regstart_start_loc_257:
	mov	ax,03F3h
	jmp	regstart_start_loc_08E
regstart_start_loc_25D:
	sub	ax,ax
	mov	word ptr RegVMEntry+2,ax
	mov	word ptr RegVMEntry,ax
	cmp	word ptr RegRootTable+05Ch,-1
	jnz	short regstart_start_loc_27F
	cmp	word ptr RegRootTable+05Eh,-1
	jnz	short regstart_start_loc_27F
	call	far ptr RegFileCreate
	mov	word ptr RegRootTable+05Ch,ax
	mov	word ptr RegRootTable+05Eh,dx
regstart_start_loc_27F:
	mov	ax,word ptr RegRootTable+05Ch
	mov	dx,word ptr RegRootTable+05Eh
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegRecoverFile
	add	sp,04h
	or	dx,ax
	jz	short regstart_start_loc_2A6
	les	bx,[bp-0Ch]
	or	byte ptr es:[bx+011h],02h
regstart_start_loc_2A6:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegReadFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jz	short regstart_start_loc_2CA
	test	byte ptr [bp+0Eh],05h
	jnz	short regstart_start_loc_2CD
regstart_start_loc_2CA:
	jmp	regstart_start_loc_34F
regstart_start_loc_2CD:
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+010h]
	and	ax,0228h
	mov	[bp-08h],ax
	mov	word ptr [bp-06h],00h
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigGetAttr
	add	sp,08h
	or	dx,ax
	jz	short regstart_start_loc_307
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigDelete
	add	sp,08h
regstart_start_loc_307:
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	cs
	call	near ptr RegCreateEmptyFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	or	dx,ax
	jnz	short regstart_start_loc_33E
	push	word ptr [bp-0Ah]
	push	word ptr [bp-0Ch]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegReadFile
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
regstart_start_loc_33E:
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	les	bx,[bp-0Ch]
	or	es:[bx+010h],ax
	or	es:[bx+012h],dx
regstart_start_loc_34F:
	mov	ax,[bp-02h]
	or	ax,[bp-04h]
	jnz	short regstart_start_loc_395
	les	bx,[bp-0Ch]
	cmp	word ptr es:[bx+024h],-1
	jnz	short regstart_start_loc_368
	cmp	word ptr es:[bx+026h],-1
	jz	short regstart_start_loc_395
regstart_start_loc_368:
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	word ptr RegRootTable+060h,ax
	mov	word ptr RegRootTable+062h,dx
	mov	word ptr RegRootTable+064h,01h
	mov	word ptr RegRootTable+066h,00h
	and	byte ptr RegRootTable+069h,0EFh
	and	byte ptr RegRootTable+06Ah,0EFh
	push	cs
	call	near ptr RegInitClassesRoot
regstart_start_loc_395:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
regstart_start_loc_39B:
	mov	sp,bp
	pop	bp
	ret
RegInitialize	endp
	even
	assume	cs:REGSTART,ds:DGROUP
	public	RegReloadSystem

;** RegReloadSystem - Reload the system root from its provider
;
; ENTRY: No arguments.
; Use the existing system file descriptor and an empty pathname.
; Refresh root identity when key storage is available.
;
RegReloadSystem	proc	far
	push	bp
	mov	bp,sp
	sub	sp,06h
	mov	ax,word ptr RegRootTable+05Ch
	mov	dx,word ptr RegRootTable+05Eh
	mov	[bp-06h],ax
	mov	[bp-04h],dx
	cmp	ax,0FFFFh
	jnz	short regreload_reload_loc_01C
	cmp	dx,ax
	jz	short regreload_reload_loc_027
regreload_reload_loc_01C:
	mov	es,dx
	mov	bx,ax
	cmp	word ptr es:[bx+02Ch],00h
	jnz	short regreload_reload_loc_02C
regreload_reload_loc_027:
	xor	ax,ax
	cwd
	jmp	short regreload_reload_loc_07F
regreload_reload_loc_02C:
	mov	byte ptr [bp-02h],00h
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	lea	ax,[bp-02h]
	push	ss
	push	ax
	call	far ptr RegReadFile
	add	sp,08h
	les	bx,[bp-06h]
	cmp	word ptr es:[bx+024h],-1
	jnz	short regreload_reload_loc_054
	cmp	word ptr es:[bx+026h],-1
	jz	short regreload_reload_loc_027
regreload_reload_loc_054:
	les	bx,es:[bx+024h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	word ptr RegRootTable+060h,ax
	mov	word ptr RegRootTable+062h,dx
	mov	word ptr RegRootTable+064h,01h
	mov	word ptr RegRootTable+066h,00h
	and	byte ptr RegRootTable+069h,0EFh
	and	byte ptr RegRootTable+06Ah,0EFh
	jmp	short regreload_reload_loc_027
regreload_reload_loc_07F:
	mov	sp,bp
	pop	bp
	ret
RegReloadSystem	endp
	even
	assume	cs:REGSTART,ds:DGROUP
	public	RegInitClassesRoot

;** RegInitClassesRoot - Establish the predefined classes root
;
; ENTRY: No arguments.
; Create or find RegClassesPath under the system root.
; EXIT: DX:AX = status; mark the root unavailable on failure.
;
RegInitClassesRoot	proc	far
	push	bp
	mov	bp,sp
	sub	sp,014h
	les	bx,dword ptr RegRootTable+05Ch
	cmp	word ptr es:[bx+024h],-1
	jnz	short regclasses_classes_loc_01B
	cmp	word ptr es:[bx+026h],-1
	jnz	short regclasses_classes_loc_01B
	jmp	regclasses_classes_loc_0A1
regclasses_classes_loc_01B:
	sub	ax,ax
	push	ax
	push	ax
	lea	ax,[bp-04h]
	push	ss
	push	ax
	mov	ax,offset DGROUP:RegClassesPath
	push	ds
	push	ax
	push	word ptr RegRootTable+062h
	push	word ptr RegRootTable+060h
	push	es
	push	bx
	call	far ptr RegCreatePath
	add	sp,014h
	or	dx,ax
	jnz	short regclasses_classes_loc_0A1
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	[bp-010h],ax
	mov	[bp-0Eh],dx
	mov	ax,word ptr RegRootTable+05Ch
	mov	dx,word ptr RegRootTable+05Eh
	mov	[bp-014h],ax
	mov	[bp-012h],dx
	mov	cx,[bp-0Eh]
	mov	bx,[bp-010h]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	word ptr RegRootTable+010h,ax
	mov	word ptr RegRootTable+012h,dx
	mov	word ptr RegRootTable+014h,01h
	mov	word ptr RegRootTable+016h,00h
	mov	word ptr RegRootTable+018h,04000h
	mov	word ptr RegRootTable+01Ah,00h
	mov	ax,word ptr RegRootTable+05Ch
	mov	dx,word ptr RegRootTable+05Eh
	mov	word ptr RegRootTable+0Ch,ax
	mov	word ptr RegRootTable+0Eh,dx
	xor	ax,ax
regclasses_classes_loc_09D:
	xor	dx,dx
	jmp	short regclasses_classes_loc_0C4
regclasses_classes_loc_0A1:
	mov	word ptr RegRootTable+010h,0FFFFh
	mov	word ptr RegRootTable+012h,0FFFFh
	sub	ax,ax
	mov	word ptr RegRootTable+016h,ax
	mov	word ptr RegRootTable+014h,ax
	or	byte ptr RegRootTable+019h,010h
	or	byte ptr RegRootTable+01Ah,010h
	mov	ax,03F3h
	jmp	short regclasses_classes_loc_09D
regclasses_classes_loc_0C4:
	mov	sp,bp
	pop	bp
	ret
RegInitClassesRoot	endp
	assume	cs:REGSTART,ds:DGROUP
	public	RegInitUserRoot

;** RegInitUserRoot - Establish the predefined current-user root
;
; ENTRY: [BP+6] = DWORD handle, or -1 for the default user.
; Resolve the supplied handle or RegDefaultUser and update the root.
; EXIT: DX:AX = status.
;
RegInitUserRoot	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Ch
	cmp	word ptr [bp+06h],-1
	jnz	short reguserroot_userroot_loc_012
	cmp	word ptr [bp+08h],-1
	jz	short reguserroot_userroot_loc_069
reguserroot_userroot_loc_012:
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegValidateKeyHandle
	add	sp,08h
	or	dx,ax
	jz	short reguserroot_userroot_loc_031
reguserroot_userroot_loc_029:
	mov	ax,03F3h
reguserroot_userroot_loc_02C:
	xor	dx,dx
	jmp	reguserroot_userroot_loc_132
reguserroot_userroot_loc_031:
	les	bx,[bp-0Ch]
	mov	ax,es:[bx+0Ch]
	mov	dx,es:[bx+0Eh]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	cmp	ax,0FFFFh
	jnz	short reguserroot_userroot_loc_04B
	cmp	dx,ax
	jz	short reguserroot_userroot_loc_09C
reguserroot_userroot_loc_04B:
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	push	word ptr es:[bx+012h]
	push	word ptr es:[bx+010h]
	call	far ptr RegLoadKey
	add	sp,08h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	jmp	short reguserroot_userroot_loc_0A6
reguserroot_userroot_loc_069:
	mov	ax,word ptr RegRootTable+084h
	mov	dx,word ptr RegRootTable+086h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	mov	ax,02h
	cwd
	push	dx
	push	ax
	lea	cx,[bp-04h]
	push	ss
	push	cx
	mov	dx,offset DGROUP:RegDefaultUser
	push	ds
	push	dx
	mov	dx,offset DGROUP:RegRootTable+78h
	push	ds
	push	dx
	lea	dx,[bp-08h]
	push	ss
	push	dx
	call	far ptr RegOpenPath
	add	sp,014h
	or	dx,ax
	jz	short reguserroot_userroot_loc_0A6
reguserroot_userroot_loc_09C:
	mov	word ptr [bp-04h],0FFFFh
	mov	word ptr [bp-02h],0FFFFh
reguserroot_userroot_loc_0A6:
	cmp	word ptr [bp-04h],-1
	jnz	short reguserroot_userroot_loc_0B2
	cmp	word ptr [bp-02h],-1
	jz	short reguserroot_userroot_loc_111
reguserroot_userroot_loc_0B2:
	mov	ax,[bp-04h]
	mov	dx,[bp-02h]
	mov	[bp-018h],ax
	mov	[bp-016h],dx
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	[bp-01Ch],ax
	mov	[bp-01Ah],dx
	mov	cx,[bp-016h]
	mov	bx,[bp-018h]
	sub	bx,00h
	sbb	cx,01h
	mov	es,cx
	mov	ax,es:[bx+04h]
	mov	dx,es:[bx+06h]
	mov	word ptr RegRootTable+038h,ax
	mov	word ptr RegRootTable+03Ah,dx
	mov	word ptr RegRootTable+03Ch,01h
	mov	word ptr RegRootTable+03Eh,00h
	mov	word ptr RegRootTable+040h,04000h
	mov	word ptr RegRootTable+042h,00h
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	mov	word ptr RegRootTable+034h,ax
	mov	word ptr RegRootTable+036h,dx
	xor	ax,ax
	jmp	reguserroot_userroot_loc_02C
reguserroot_userroot_loc_111:
	mov	word ptr RegRootTable+038h,0FFFFh
	mov	word ptr RegRootTable+03Ah,0FFFFh
	sub	ax,ax
	mov	word ptr RegRootTable+03Eh,ax
	mov	word ptr RegRootTable+03Ch,ax
	or	byte ptr RegRootTable+041h,010h
	or	byte ptr RegRootTable+042h,010h
	jmp	reguserroot_userroot_loc_029
reguserroot_userroot_loc_132:
	mov	sp,bp
	pop	bp
	ret
RegInitUserRoot	endp
	assume	cs:REGSTART,ds:DGROUP
	public	RegReleaseFileBuffers

;** RegReleaseFileBuffers - Release storage owned by a registry file
;
; ENTRY: [BP+6] = FAR file descriptor.
; Release the pathname, header, cached key nodes, data-block indexes
; and cache table. Keep the file descriptor for reuse.
;
RegReleaseFileBuffers	proc	far
	push	bp
	mov	bp,sp
	sub	sp,016h
	push	si
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
	mov	[bp-0Eh],ax
	mov	[bp-0Ch],dx
	mov	ax,es
	cmp	bx,-1
	jnz	short regclean_clean_loc_026
	cmp	ax,bx
	jnz	short regclean_clean_loc_026
	jmp	regclean_clean_loc_1A1
regclean_clean_loc_026:
	cmp	word ptr es:[bx],04752h
	jnz	short regclean_clean_loc_035
	cmp	word ptr es:[bx+02h],05346h
	jz	short regclean_clean_loc_038
regclean_clean_loc_035:
	jmp	regclean_clean_loc_1A1
regclean_clean_loc_038:
	mov	ax,es:[bx+016h]
	or	ax,es:[bx+014h]
	jz	short regclean_clean_loc_05F
	push	word ptr es:[bx+016h]
	push	word ptr es:[bx+014h]
	call	far ptr ConfigFree
	add	sp,04h
	les	bx,[bp+06h]
	sub	ax,ax
	mov	es:[bx+016h],ax
	mov	es:[bx+014h],ax
regclean_clean_loc_05F:
	cmp	word ptr es:[bx+020h],-1
	jnz	short regclean_clean_loc_06D
	cmp	word ptr es:[bx+022h],-1
	jz	short regclean_clean_loc_08C
regclean_clean_loc_06D:
	push	word ptr es:[bx+022h]
	push	word ptr es:[bx+020h]
	call	far ptr ConfigFree
	add	sp,04h
	les	bx,[bp+06h]
	mov	word ptr es:[bx+020h],0FFFFh
	mov	word ptr es:[bx+022h],0FFFFh
regclean_clean_loc_08C:
	cmp	word ptr [bp-0Eh],-1
	jnz	short regclean_clean_loc_098
	cmp	word ptr [bp-0Ch],-1
	jz	short regclean_clean_loc_10E
regclean_clean_loc_098:
	mov	word ptr [bp-02h],00h
	jmp	short regclean_clean_loc_0A2
regclean_clean_loc_09F:
	inc	word ptr [bp-02h]
regclean_clean_loc_0A2:
	cmp	word ptr [bp-02h],0100h
	jnl	short regclean_clean_loc_0EC
	mov	si,[bp-02h]
	add	si,si
	add	si,si
	les	bx,[bp-0Eh]
	mov	ax,es:[bx+si+020h]
	mov	dx,es:[bx+si+022h]
regclean_clean_loc_0BB:
	mov	[bp-012h],ax
	mov	ax,dx
	or	ax,[bp-012h]
	jz	short regclean_clean_loc_09F
	mov	cx,dx
	mov	bx,[bp-012h]
	mov	es,dx
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-016h],ax
	mov	[bp-014h],dx
	push	cx
	push	bx
	call	far ptr ConfigFree
	add	sp,04h
	mov	ax,[bp-016h]
	mov	dx,[bp-014h]
	jmp	short regclean_clean_loc_0BB
regclean_clean_loc_0EC:
	les	bx,[bp+06h]
	push	word ptr es:[bx+026h]
	push	word ptr es:[bx+024h]
	call	far ptr ConfigFree
	add	sp,04h
	les	bx,[bp+06h]
	mov	word ptr es:[bx+024h],0FFFFh
	mov	word ptr es:[bx+026h],0FFFFh
regclean_clean_loc_10E:
	mov	ax,es:[bx+028h]
	mov	dx,es:[bx+02Ah]
	mov	[bp-06h],ax
	mov	[bp-04h],dx
	cmp	ax,0FFFFh
	jnz	short regclean_clean_loc_125
	cmp	dx,ax
	jz	short regclean_clean_loc_1A1
regclean_clean_loc_125:
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	mov	ax,es:[bx+0Eh]
	mov	[bp-02h],ax
	jmp	short regclean_clean_loc_17E
regclean_clean_loc_134:
	les	bx,[bp-0Ah]
	cmp	word ptr es:[bx],-1
	jnz	short regclean_clean_loc_144
	cmp	word ptr es:[bx+02h],-1
	jz	short regclean_clean_loc_177
regclean_clean_loc_144:
	les	bx,es:[bx]
	cmp	word ptr es:[bx+018h],-1
	jnz	short regclean_clean_loc_155
	cmp	word ptr es:[bx+01Ah],-1
	jz	short regclean_clean_loc_165
regclean_clean_loc_155:
	push	word ptr es:[bx+01Ah]
	push	word ptr es:[bx+018h]
	call	far ptr ConfigFree
	add	sp,04h
regclean_clean_loc_165:
	les	bx,[bp-0Ah]
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	call	far ptr ConfigFree
	add	sp,04h
regclean_clean_loc_177:
	add	word ptr [bp-0Ah],0Ch
	dec	word ptr [bp-02h]
regclean_clean_loc_17E:
	cmp	word ptr [bp-02h],00h
	jnz	short regclean_clean_loc_134
	push	word ptr [bp-04h]
	push	word ptr [bp-06h]
	call	far ptr ConfigFree
	add	sp,04h
	les	bx,[bp+06h]
	mov	word ptr es:[bx+028h],0FFFFh
	mov	word ptr es:[bx+02Ah],0FFFFh
regclean_clean_loc_1A1:
	pop	si
	mov	sp,bp
	pop	bp
	ret
RegReleaseFileBuffers	endp
	assume	cs:REGSTART,ds:DGROUP
	public	RegReleaseMounts

;** RegReleaseMounts - Release files and records mounted under a root
;
; ENTRY: [BP+6] = FAR root.
; Release each file's buffers, unlink and free its descriptor, then
; free the mount record. Reset the root's mount-list head.
;
RegReleaseMounts	proc	far
	push	bp
	mov	bp,sp
	sub	sp,08h
	les	bx,[bp+06h]
	mov	ax,es:[bx+024h]
	mov	dx,es:[bx+026h]
regmount_mount_loc_011:
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regmount_mount_loc_020
	cmp	dx,ax
	jz	short regmount_mount_loc_089
regmount_mount_loc_020:
	les	bx,[bp-04h]
	cmp	word ptr es:[bx+0Ch],-1
	jnz	short regmount_mount_loc_031
	cmp	word ptr es:[bx+0Eh],-1
	jz	short regmount_mount_loc_066
regmount_mount_loc_031:
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	push	cs
	call	near ptr RegReleaseFileBuffers
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
regmount_mount_loc_066:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	push	es
	push	bx
	call	far ptr ConfigFree
	add	sp,04h
	mov	ax,[bp-08h]
	mov	dx,[bp-06h]
	jmp	short regmount_mount_loc_011
regmount_mount_loc_089:
	les	bx,[bp+06h]
	mov	word ptr es:[bx+024h],0FFFFh
	mov	word ptr es:[bx+026h],0FFFFh
	mov	sp,bp
	pop	bp
	ret
RegReleaseMounts	endp
	assume	cs:REGSTART,ds:DGROUP
	public	RegTerminate

;** RegTerminate - Release registry roots, mounts and handles
;
; ENTRY: No arguments.
; Release the memory reserve and root-owned files before walking
; the handle list. Reset released root references and list heads.
;
RegTerminate	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	mov	ax,word ptr RegReserveBlock+2
	or	ax,word ptr RegReserveBlock
	jz	short regterm_term_loc_01F
	push	word ptr RegReserveBlock+2
	push	word ptr RegReserveBlock
	call	far ptr ConfigFree
	add	sp,04h
regterm_term_loc_01F:
	sub	ax,ax
	mov	word ptr RegReserveBlock+2,ax
	mov	word ptr RegReserveBlock,ax
	mov	word ptr RegReserveSize+2,ax
	mov	word ptr RegReserveSize,ax
	mov	ax,word ptr RegRootTable+05Ch
	mov	dx,word ptr RegRootTable+05Eh
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regterm_term_loc_043
	cmp	dx,ax
	jz	short regterm_term_loc_090
regterm_term_loc_043:
	push	dx
	push	ax
	push	cs
	call	near ptr RegReleaseFileBuffers
	add	sp,04h
	mov	ax,0FFFFh
	cwd
	mov	word ptr RegRootTable+05Ch,ax
	mov	word ptr RegRootTable+05Eh,dx
	mov	word ptr RegRootTable+0Ch,ax
	mov	word ptr RegRootTable+0Eh,dx
	mov	word ptr RegRootTable+0D4h,ax
	mov	word ptr RegRootTable+0D6h,dx
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegFileUnlink
	add	sp,04h
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
	add	sp,04h
	or	byte ptr RegRootTable+06Ah,010h
	or	byte ptr RegRootTable+01Ah,010h
	or	byte ptr RegRootTable+0E2h,010h
regterm_term_loc_090:
	mov	ax,offset DGROUP:RegRootTable+50h
	push	ds
	push	ax
	push	cs
	call	near ptr RegReleaseMounts
	add	sp,04h
	mov	ax,word ptr RegRootTable+084h
	mov	dx,word ptr RegRootTable+086h
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regterm_term_loc_0B2
	cmp	dx,ax
	jz	short regterm_term_loc_0F3
regterm_term_loc_0B2:
	push	dx
	push	ax
	push	cs
	call	near ptr RegReleaseFileBuffers
	add	sp,04h
	mov	ax,0FFFFh
	cwd
	mov	word ptr RegRootTable+084h,ax
	mov	word ptr RegRootTable+086h,dx
	mov	word ptr RegRootTable+034h,ax
	mov	word ptr RegRootTable+036h,dx
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegFileUnlink
	add	sp,04h
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr ConfigFree
	add	sp,04h
	or	byte ptr RegRootTable+092h,010h
	or	byte ptr RegRootTable+042h,010h
regterm_term_loc_0F3:
	mov	ax,offset DGROUP:RegRootTable+78h
	push	ds
	push	ax
	push	cs
	call	near ptr RegReleaseMounts
	add	sp,04h
	mov	ax,word ptr RegHandleList
	mov	dx,word ptr RegHandleList+2
regterm_term_loc_106:
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	cmp	ax,0FFFFh
	jnz	short regterm_term_loc_115
	cmp	dx,ax
	jz	short regterm_term_loc_138
regterm_term_loc_115:
	les	bx,[bp-08h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],dx
	push	es
	push	bx
	call	far ptr ConfigFree
	add	sp,04h
	mov	ax,[bp-0Ch]
	mov	dx,[bp-0Ah]
	jmp	short regterm_term_loc_106
regterm_term_loc_138:
	mov	word ptr RegHandleList,0FFFFh
	mov	word ptr RegHandleList+2,0FFFFh
	mov	sp,bp
	pop	bp
	ret
RegTerminate	endp
	assume	cs:REGSTART,ds:DGROUP
	public	RegCreateEmptyFile

;** RegCreateEmptyFile - Create initial registry headers and records
;
; ENTRY: [BP+6] = FAR pathname.
; Use a 60h work buffer and the shared block initializers.
; Write initial records, extend the file to 2000h and close it.
; EXIT: DX:AX = status.
;
RegCreateEmptyFile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ah
	sub	ax,ax
	mov	[bp-04h],ax
	mov	[bp-06h],ax
	push	ax
	push	ax
	mov	ax,060h
	cwd
	push	dx
	push	ax
	call	far ptr RegAllocate
	add	sp,08h
	mov	[bp-0Ah],ax
	mov	[bp-08h],dx
	or	dx,ax
	jnz	short regempty_empty_loc_030
	mov	ax,0Eh
regempty_empty_loc_02B:
	xor	dx,dx
	jmp	regempty_empty_loc_1C7
regempty_empty_loc_030:
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigCreate
	add	sp,08h
	mov	[bp-02h],ax
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_04F
	mov	ax,03F8h
	jmp	short regempty_empty_loc_02B
regempty_empty_loc_04F:
	mov	ax,01h
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegInitHeader
	add	sp,06h
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-02h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_08F
	cmp	dx,ax
	jnz	short regempty_empty_loc_08F
	mov	word ptr [bp-06h],03F8h
	mov	word ptr [bp-04h],00h
regempty_empty_loc_08F:
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegInitKeyBlock
	add	sp,04h
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,020h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-02h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_0CB
	cmp	dx,ax
	jnz	short regempty_empty_loc_0CB
	mov	word ptr [bp-06h],03F8h
	mov	word ptr [bp-04h],00h
regempty_empty_loc_0CB:
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegInitKeyRecords
	add	sp,04h
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,038h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-02h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_107
	cmp	dx,ax
	jnz	short regempty_empty_loc_107
	mov	word ptr [bp-06h],03F8h
	mov	word ptr [bp-04h],00h
regempty_empty_loc_107:
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,01000h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-02h]
	call	far ptr ConfigSeek
	add	sp,0Eh
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegInitDataBlock
	add	sp,04h
	sub	ax,ax
	push	ax
	push	ax
	mov	ax,02Ch
	cwd
	push	dx
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-02h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_15A
	cmp	dx,ax
	jnz	short regempty_empty_loc_15A
	mov	word ptr [bp-06h],03F8h
	mov	word ptr [bp-04h],00h
regempty_empty_loc_15A:
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,02000h
	cwd
	push	dx
	push	ax
	push	word ptr [bp-02h]
	call	far ptr ConfigSeek
	add	sp,0Eh
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	push	word ptr [bp-02h]
	call	far ptr ConfigWriteAll
	add	sp,0Eh
	cmp	ax,0FFFFh
	jnz	short regempty_empty_loc_19B
	cmp	dx,ax
	jnz	short regempty_empty_loc_19B
	mov	word ptr [bp-06h],03F8h
	mov	word ptr [bp-04h],00h
regempty_empty_loc_19B:
	mov	ax,01h
	cwd
	push	dx
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr ConfigClose
	add	sp,0Eh
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr ConfigFree
	mov	ax,[bp-06h]
	mov	dx,[bp-04h]
regempty_empty_loc_1C7:
	mov	sp,bp
	pop	bp
	ret
RegCreateEmptyFile	endp
	even
	assume	cs:REGSTART,ds:DGROUP
	public	RegFlushAll

;** RegFlushAll - Save the roots and their mounted files
;
; ENTRY: No arguments.
; Attempt both roots and both mount lists, retaining the first error.
; EXIT: AX = 1 if all saves succeed, zero otherwise.
;
RegFlushAll	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	push	word ptr RegRootTable+05Eh
	push	word ptr RegRootTable+05Ch
	call	far ptr RegSaveFile
	add	sp,04h
	mov	[bp-08h],ax
	mov	[bp-06h],dx
	push	word ptr RegRootTable+086h
	push	word ptr RegRootTable+084h
	call	far ptr RegSaveFile
	add	sp,04h
	mov	[bp-0Ch],ax
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jnz	short regall_all_loc_040
	mov	ax,[bp-0Ch]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
regall_all_loc_040:
	mov	ax,word ptr RegRootTable+09Ch
	mov	dx,word ptr RegRootTable+09Eh
regall_all_loc_047:
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regall_all_loc_056
	cmp	dx,ax
	jz	short regall_all_loc_08A
regall_all_loc_056:
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegSaveFile
	add	sp,04h
	mov	[bp-0Ch],ax
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jnz	short regall_all_loc_07D
	mov	ax,[bp-0Ch]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
regall_all_loc_07D:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regall_all_loc_047
regall_all_loc_08A:
	mov	ax,word ptr RegRootTable+074h
	mov	dx,word ptr RegRootTable+076h
regall_all_loc_091:
	mov	[bp-04h],ax
	mov	[bp-02h],dx
	cmp	ax,0FFFFh
	jnz	short regall_all_loc_0A0
	cmp	dx,ax
	jz	short regall_all_loc_0D4
regall_all_loc_0A0:
	les	bx,[bp-04h]
	push	word ptr es:[bx+0Eh]
	push	word ptr es:[bx+0Ch]
	call	far ptr RegSaveFile
	add	sp,04h
	mov	[bp-0Ch],ax
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jnz	short regall_all_loc_0C7
	mov	ax,[bp-0Ch]
	mov	[bp-08h],ax
	mov	[bp-06h],dx
regall_all_loc_0C7:
	les	bx,[bp-04h]
	mov	ax,es:[bx+08h]
	mov	dx,es:[bx+0Ah]
	jmp	short regall_all_loc_091
regall_all_loc_0D4:
	mov	ax,[bp-06h]
	or	ax,[bp-08h]
	jnz	short regall_all_loc_0E1
	mov	ax,01h
	jmp	short regall_all_loc_0E3
regall_all_loc_0E1:
	xor	ax,ax
regall_all_loc_0E3:
	mov	sp,bp
	pop	bp
	ret
RegFlushAll	endp
	even
REGSTART	ends
	end
