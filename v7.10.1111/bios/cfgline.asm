;** CFGLINE.ASM - Configuration profile names and input lines.
;
	.286
	extrn	_sprintf:far
	extrn	RegQueryValueEx:far
	extrn	_strncpy:far
	extrn	__stricmp:far
	extrn	__filbuf:far
	extrn	ConfigGetMessage:far
_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
CFGPNP	segment	word public 'CODE'
CFGPNP	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	ConfigUnnamed:byte
	extrn	ConfigNameKey:byte
	extrn	ConfigNameFormat:byte
	extrn	ConfigFindKey:byte
	extrn	ConfigFindFormat:byte
	extrn	ConfigNameSuffix:byte
	extrn	ConfigNamePattern:byte
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	ConfigNameBuffer:byte
c_common	ends
CFGPNP	segment	word public 'CODE'
	assume	cs:CFGPNP,ds:DGROUP
	public	ConfigReadProfileName

;	Read a profile name from the registry.
;	Far C arguments: profile number, destination buffer, registry key.
;
ConfigReadProfileName	proc	far
	push	bp
	mov	bp,sp
	sub	sp,04Ah
	push	di
	push	si
	mov	word ptr [bp-04h],0FFEh
	mov	word ptr [bp-02h],00h
	mov	si,offset DGROUP:ConfigUnnamed
	les	di,[bp+08h]
	mov	cx,08h
	rep	movsw
	mov	ax,[bp+0Eh]
	or	ax,[bp+0Ch]
	jnz	short cfgname_cfgname_028
	jmp	near ptr cfgname_cfgname_0C2
cfgname_cfgname_028:
	lea	di,[bp-04Ah]
	mov	si,offset DGROUP:ConfigNameKey
	mov	ax,ss
	mov	es,ax
	mov	cx,06h
	rep	movsw
	movsb
	push	word ptr [bp+06h]
	mov	ax,offset DGROUP:ConfigNameFormat
	push	ds
	push	ax
	lea	cx,[bp-0Ah]
	push	ss
	push	cx
	call	far ptr _sprintf
	add	sp,0Ah
	lea	di,[bp-0Ah]
	lea	si,[bp-04Ah]
	mov	cx,ss
	mov	es,cx
	push	ds
	mov	cx,0FFFFh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	mov	bx,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	mov	cx,0FFFFh
	repne	scasb
	dec	di
	mov	cx,bx
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	lea	ax,[bp-04h]
	push	ss
	push	ax
	mov	ax,offset DGROUP:ConfigNameBuffer
	push	ds
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	lea	ax,[bp-04Ah]
	push	ss
	push	ax
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	call	far ptr RegQueryValueEx
	add	sp,018h
	or	dx,ax
	jnz	short cfgname_cfgname_0C2
	mov	ax,04Fh
	push	ax
	mov	ax,offset DGROUP:ConfigNameBuffer
	push	ds
	push	ax
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	call	far ptr _strncpy
	add	sp,0Ah
	les	bx,[bp+08h]
	mov	byte ptr es:[bx+04Fh],00h
cfgname_cfgname_0C2:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
ConfigReadProfileName	endp
	assume	cs:CFGPNP,ds:DGROUP
	public	ConfigProfileNameExists

;	Check whether a profile name is already present.
;	Far C arguments: name, registry key.  AX is nonzero if found.
;
ConfigProfileNameExists	proc	far
	push	bp
	mov	bp,sp
	sub	sp,09Ah
	push	di
	push	si
	mov	word ptr [bp-06h],00h
	mov	ax,[bp+0Ch]
	or	ax,[bp+0Ah]
	jnz	short cfgsame_cfgsame_01E
	xor	ax,ax
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
cfgsame_cfgsame_01E:
	lea	di,[bp-04Ah]
	mov	si,offset DGROUP:ConfigFindKey
	mov	ax,ss
	mov	es,ax
	mov	cx,06h
	rep	movsw
	movsb
	lea	di,[bp-04Ah]
	mov	cx,0FFFFh
	xor	ax,ax
	repne	scasb
	not	cx
	dec	cx
	mov	[bp-04h],cx
	mov	[bp-02h],ax
	mov	si,ax
	mov	di,[bp-06h]
cfgsame_cfgsame_046:
	or	di,di
	jnz	short cfgsame_cfgsame_0B3
	push	si
	mov	ax,offset DGROUP:ConfigFindFormat
	push	ds
	push	ax
	mov	ax,[bp-04h]
	lea	cx,[bp-04Ah]
	add	ax,cx
	push	ss
	push	ax
	call	far ptr _sprintf
	add	sp,0Ah
	mov	word ptr [bp-0Ah],050h
	mov	[bp-08h],di
	lea	ax,[bp-0Ah]
	push	ss
	push	ax
	lea	ax,[bp-09Ah]
	push	ss
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	lea	ax,[bp-04Ah]
	push	ss
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	call	far ptr RegQueryValueEx
	add	sp,018h
	or	dx,ax
	jnz	short cfgsame_cfgsame_0AD
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	lea	ax,[bp-09Ah]
	push	ss
	push	ax
	call	far ptr __stricmp
	add	sp,08h
	or	ax,ax
	jnz	short cfgsame_cfgsame_0AD
	mov	di,01h
cfgsame_cfgsame_0AD:
	inc	si
	cmp	si,09h
	jc	short cfgsame_cfgsame_046
cfgsame_cfgsame_0B3:
	mov	ax,di
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
	nop
ConfigProfileNameExists	endp
	assume	cs:CFGPNP
	public	ConfigReadLine

;	Read a bounded input line.
;	Far C arguments: stream, destination, capacity.
;	AX = 1 for a line, 0 for end of input without characters.
;
ConfigReadLine	proc	far
	push	bp
	mov	bp,sp
	sub	sp,04h
	push	di
	push	si
	mov	di,[bp+06h]
	mov	ax,[bp+0Ah]
	mov	dx,[bp+0Ch]
	mov	[bp-04h],ax
	mov	[bp-02h],dx
cfgline_line_017:
	mov	es,word ptr [bp+08h]
	dec	word ptr es:[di+04h]
	js	short cfgline_line_038
	mov	es,word ptr [bp+08h]
	mov	ax,es:[di]
	mov	dx,es:[di+02h]
	inc	word ptr es:[di]
	mov	bx,ax
	mov	es,dx
	mov	al,es:[bx]
	sub	ah,ah
	jmp	short cfgline_line_044
cfgline_line_038:
	push	word ptr [bp+08h]
	push	di
	call	far ptr __filbuf
	add	sp,04h
cfgline_line_044:
	mov	si,ax
	cmp	si,-1
	jz	short cfgline_line_064
	cmp	si,0Ah
	jz	short cfgline_line_064
	dec	word ptr [bp+0Eh]
	cmp	word ptr [bp+0Eh],00h
	jng	short cfgline_line_064
	les	bx,[bp-04h]
	inc	word ptr [bp-04h]
	mov	es:[bx],al
	jmp	short cfgline_line_017
cfgline_line_064:
	les	bx,[bp-04h]
	mov	byte ptr es:[bx],00h
	mov	ax,es
	cmp	bx,[bp+0Ah]
	jnz	short cfgline_line_084
	cmp	ax,[bp+0Ch]
	jnz	short cfgline_line_084
	cmp	si,0Ah
	jz	short cfgline_line_084
	xor	ax,ax
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
cfgline_line_084:
	mov	ax,01h
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
ConfigReadLine	endp
	even
	assume	cs:CFGPNP,ds:DGROUP
	public	ConfigChooseProfileName

;	Choose an unused configuration profile name.
;
ConfigChooseProfileName	proc	far
	push	bp
	mov	bp,sp
	sub	sp,010h
	push	di
	push	si
	mov	word ptr [bp-04h],01h
	mov	word ptr [bp-02h],00h
	mov	ax,[bp+08h]
	or	ax,[bp+06h]
	jnz	short cfgpick_cfgpick_056
	mov	ax,[bp+0Ch]
	or	ax,[bp+0Ah]
	jnz	short cfgpick_cfgpick_056
	mov	ax,03h
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	mov	di,ax
	mov	es,dx
	push	ds
	lds	si,[bp+0Eh]
	mov	cx,0FFFFh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	dx
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
cfgpick_cfgpick_056:
	mov	ax,[bp+08h]
	or	ax,[bp+06h]
	jz	short cfgpick_cfgpick_061
	jmp	near ptr cfgpick_cfgpick_134
cfgpick_cfgpick_061:
	cmp	word ptr [bp+0Ah],01h
	jz	short cfgpick_cfgpick_06A
	jmp	near ptr cfgpick_cfgpick_134
cfgpick_cfgpick_06A:
	cmp	word ptr [bp+0Ch],00h
	jz	short cfgpick_cfgpick_073
	jmp	near ptr cfgpick_cfgpick_134
cfgpick_cfgpick_073:
	mov	ax,04h
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	mov	di,ax
	mov	es,dx
	push	ds
	lds	si,[bp+0Eh]
	mov	cx,0FFFFh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	dx
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	les	di,[bp+0Eh]
	mov	cx,0FFFFh
	repne	scasb
	not	cx
	dec	cx
	mov	[bp-06h],cx
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	es
	push	word ptr [bp+0Eh]
	push	cs
	call	near ptr ConfigProfileNameExists
	add	sp,08h
	or	ax,ax
	jnz	short cfgpick_cfgpick_0C7
	jmp	near ptr cfgpick_cfgpick_179
cfgpick_cfgpick_0C7:
	add	word ptr [bp-04h],01h
	adc	word ptr [bp-02h],00h
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	mov	ax,offset DGROUP:ConfigNameSuffix
	push	ds
	push	ax
	lea	ax,[bp-010h]
	push	ss
	push	ax
	call	far ptr _sprintf
	add	sp,0Ch
	mov	bx,[bp+0Eh]
	mov	cx,[bp+010h]
	add	bx,[bp-06h]
	mov	dx,cx
	push	ds
	lea	di,[bp-010h]
	mov	si,bx
	mov	cx,ss
	mov	es,cx
	mov	ds,dx
	mov	cx,0FFFFh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	dx
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	dx
	push	word ptr [bp+0Eh]
	push	cs
	call	near ptr ConfigProfileNameExists
	add	sp,08h
	or	ax,ax
	jnz	short cfgpick_cfgpick_0C7
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
	nop
cfgpick_cfgpick_134:
	mov	si,[bp+0Eh]
cfgpick_cfgpick_137:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	add	word ptr [bp-04h],01h
	adc	word ptr [bp-02h],00h
	mov	ax,05h
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	push	dx
	push	ax
	mov	ax,offset DGROUP:ConfigNamePattern
	push	ds
	push	ax
	push	word ptr [bp+010h]
	push	si
	call	far ptr _sprintf
	add	sp,010h
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	si
	push	cs
	call	near ptr ConfigProfileNameExists
	add	sp,08h
	or	ax,ax
	jnz	short cfgpick_cfgpick_137
cfgpick_cfgpick_179:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
	nop
ConfigChooseProfileName	endp
CFGPNP	ends
	end
