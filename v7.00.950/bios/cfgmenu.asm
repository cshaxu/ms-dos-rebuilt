;** CFGMENU.ASM - Hardware profile selection.
;
	.286
	extrn	ConfigGetMessage:far
	extrn	_printf:far
	extrn	RegCloseKey:far
	extrn	RegOpenKey:far
	extrn	RegQueryValueEx:far
_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
CFGPNP	segment	word public 'CODE'
CFGPNP	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	__iob:byte
	extrn	ConfigMenuSpace:byte
	extrn	ConfigMenuEntry:byte
	extrn	ConfigMenuNewSpace:byte
	extrn	ConfigMenuNewEntry:byte
	extrn	ConfigDatabasePath:byte
	extrn	ConfigDatabaseMap:byte
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	ConfigUIState:word,ConfigHardwareHigh:word
	extrn	ConfigSystemID:word,ConfigSystemHigh:word
	extrn	ConfigBootOption:word,ConfigSelectedProfile:word
	extrn	ConfigSelectedName:byte,ConfigStoredProfiles:byte
c_common	ends
CFGPNP	segment	word public 'CODE'
	assume	cs:CFGPNP,ds:DGROUP
	public	ConfigSelectProfile
	extrn	ConfigChooseProfileName:far
	extrn	ConfigReadLine:far
	extrn	ConfigReadProfileName:far
;	Select an existing profile or choose a name for a new profile.
;	Use the only matching profile directly; otherwise prompt for a selection.
;
ConfigSelectProfile	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0ACh
	push	di
	push	si
	les	di,[bp+06h]
	mov	ax,[bp+0Eh]
	mov	dx,[bp+010h]
	mov	cx,ax
	mov	[bp-08h],dx
	mov	ax,es:[di+012h]
	or	ax,ax
	jnz	short cfgmenu_cfgmenu_022
	jmp	near ptr cfgmenu_cfgmenu_18A
cfgmenu_cfgmenu_022:
	dec	ax
	jnz	short cfgmenu_cfgmenu_028
	jmp	near ptr cfgmenu_cfgmenu_19E
cfgmenu_cfgmenu_028:
	mov	[bp-0Ah],cx
	cmp	word ptr es:[di+012h],08h
	jnl	short cfgmenu_cfgmenu_038
	mov	ax,01h
	jmp	short cfgmenu_cfgmenu_03A
	nop
cfgmenu_cfgmenu_038:
	xor	ax,ax
cfgmenu_cfgmenu_03A:
	mov	[bp-06h],ax
cfgmenu_cfgmenu_03D:
	mov	ax,02h
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	push	dx
	push	ax
	call	far ptr _printf
	add	sp,04h
	xor	si,si
	les	bx,[bp+06h]
	cmp	es:[bx+012h],si
	jng	short cfgmenu_cfgmenu_0BA
	mov	di,bx
	mov	word ptr [bp-02h],es
cfgmenu_cfgmenu_063:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	lea	ax,[bp-05Ah]
	push	ss
	push	ax
	mov	es,word ptr [bp-02h]
	push	word ptr es:[di]
	push	cs
	call	near ptr ConfigReadProfileName
	add	sp,0Ah
	lea	ax,[si+01h]
	mov	[bp-0ACh],ax
	cmp	ax,0Ah
	jnl	short cfgmenu_cfgmenu_094
	mov	ax,offset DGROUP:ConfigMenuSpace
	push	ds
	push	ax
	call	far ptr _printf
	add	sp,04h
cfgmenu_cfgmenu_094:
	lea	ax,[bp-05Ah]
	push	ss
	push	ax
	push	word ptr [bp-0ACh]
	mov	ax,offset DGROUP:ConfigMenuEntry
	push	ds
	push	ax
	call	far ptr _printf
	add	sp,0Ah
	add	di,02h
	mov	si,[bp-0ACh]
	les	bx,[bp+06h]
	cmp	es:[bx+012h],si
	jg	short cfgmenu_cfgmenu_063
cfgmenu_cfgmenu_0BA:
	cmp	word ptr [bp-06h],00h
	jz	short cfgmenu_cfgmenu_0FB
	lea	ax,[si+01h]
	mov	[bp-0ACh],ax
	cmp	ax,0Ah
	jnl	short cfgmenu_cfgmenu_0D9
	mov	ax,offset DGROUP:ConfigMenuNewSpace
	push	ds
	push	ax
	call	far ptr _printf
	add	sp,04h
cfgmenu_cfgmenu_0D9:
	xor	ax,ax
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	push	dx
	push	ax
	push	word ptr [bp-0ACh]
	mov	ax,offset DGROUP:ConfigMenuNewEntry
	push	ds
	push	ax
	call	far ptr _printf
	add	sp,0Ah
	mov	si,[bp-0ACh]
cfgmenu_cfgmenu_0FB:
	mov	ax,01h
	push	ax
	call	far ptr ConfigGetMessage
	add	sp,02h
	push	dx
	push	ax
	call	far ptr _printf
	add	sp,04h
	mov	ax,050h
	push	ax
	lea	ax,[bp-0AAh]
	push	ss
	push	ax
	mov	cx,offset DGROUP:__iob
	push	ds
	push	cx
	push	cs
	call	near ptr ConfigReadLine
	add	sp,0Ah
	mov	al,[bp-0AAh]
	cbw
	mov	di,ax
	sub	di,031h
	jns	short cfgmenu_cfgmenu_136
	jmp	near ptr cfgmenu_cfgmenu_03D
cfgmenu_cfgmenu_136:
	cmp	di,si
	jl	short cfgmenu_cfgmenu_13D
	jmp	near ptr cfgmenu_cfgmenu_03D
cfgmenu_cfgmenu_13D:
	mov	[bp-02h],di
	cmp	word ptr [bp-06h],00h
	jz	short cfgmenu_cfgmenu_172
	lea	ax,[si-01h]
	cmp	ax,di
	jg	short cfgmenu_cfgmenu_172
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
cfgmenu_cfgmenu_159:
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	cs
	call	near ptr ConfigChooseProfileName
	add	sp,010h
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
cfgmenu_cfgmenu_172:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	mov	bx,di
	add	bx,di
	les	si,[bp+06h]
	mov	ax,es:[bx+si]
	jmp	short cfgmenu_cfgmenu_1A9
cfgmenu_cfgmenu_18A:
	les	bx,[bp+0Ah]
	mov	word ptr es:[bx],00h
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp-08h]
	push	cx
	jmp	short cfgmenu_cfgmenu_159
cfgmenu_cfgmenu_19E:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	dx
	push	cx
	mov	ax,es:[di]
cfgmenu_cfgmenu_1A9:
	les	bx,[bp+0Ah]
	mov	es:[bx],ax
	push	ax
	push	cs
	call	near ptr ConfigReadProfileName
	add	sp,0Ah
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
	nop
ConfigSelectProfile	endp
	assume	cs:CFGPNP,ds:DGROUP
	public	ConfigUI
	extrn	ConfigGetCapabilities:far
	extrn	ConfigMatchProfiles:far
	extrn	ConfigZeroOption:far
;	Read hardware capabilities and stored profiles, then select a profile.
;	Far C arguments: output data pointer, output size pointer.
;
ConfigUI	proc	far
	push	bp
	mov	bp,sp
	sub	sp,01Eh
	push	di
	push	si
	mov	si,[bp+0Ah]
	mov	es,word ptr [bp+0Ch]
	xor	ax,ax
	mov	es:[si],ax
	mov	bx,offset DGROUP:ConfigUIState
	mov	cx,065h
	mov	di,bx
	push	ds
	pop	es
	rep	stosw
	mov	cx,offset DGROUP:ConfigSystemID
	push	ds
	push	cx
	push	ds
	push	bx
	push	cs
	call	near ptr ConfigGetCapabilities
	add	sp,08h
	push	cs
	call	near ptr ConfigZeroOption
	mov	ConfigBootOption,ax
	xor	ax,ax
	mov	ConfigSelectedName,al
	mov	[bp-0Ch],ax
	mov	[bp-0Ah],ax
	mov	ConfigStoredProfiles,ax
	lea	ax,[bp-04h]
	push	ss
	push	ax
	mov	ax,offset DGROUP:ConfigDatabasePath
	push	ds
	push	ax
	mov	ax,02h
	mov	dx,08000h
	push	dx
	push	ax
	call	far ptr RegOpenKey
	add	sp,0Ch
	or	dx,ax
	jnz	short cfgui_cfgui_0C4
	mov	word ptr [bp-08h],06Eh
	mov	word ptr [bp-06h],00h
	lea	ax,[bp-08h]
	push	ss
	push	ax
	mov	ax,offset DGROUP:ConfigStoredProfiles
	push	ds
	push	ax
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,offset DGROUP:ConfigDatabaseMap
	push	ds
	push	ax
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegQueryValueEx
	add	sp,018h
	or	dx,ax
	jnz	short cfgui_cfgui_0CC
	cmp	word ptr [bp-08h],06Eh
	jnz	short cfgui_cfgui_0CC
	cmp	word ptr [bp-06h],00h
	jnz	short cfgui_cfgui_0CC
	push	word ptr ConfigBootOption
	push	word ptr ConfigSystemHigh
	push	word ptr ConfigSystemID
	push	word ptr ConfigHardwareHigh
	push	word ptr ConfigUIState
	mov	ax,offset DGROUP:ConfigStoredProfiles
	push	ds
	push	ax
	lea	ax,[bp-01Eh]
	push	ss
	push	ax
	push	cs
	call	near ptr ConfigMatchProfiles
	add	sp,012h
	jmp	short cfgui_cfgui_0CC
cfgui_cfgui_0C4:
	sub	ax,ax
	mov	[bp-02h],ax
	mov	[bp-04h],ax
cfgui_cfgui_0CC:
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	push	word ptr ConfigSystemHigh
	push	word ptr ConfigSystemID
	push	word ptr ConfigHardwareHigh
	push	word ptr ConfigUIState
	mov	ax,offset DGROUP:ConfigSelectedName
	push	ds
	push	ax
	mov	ax,offset DGROUP:ConfigSelectedProfile
	push	ds
	push	ax
	lea	ax,[bp-01Eh]
	push	ss
	push	ax
	push	cs
	call	near ptr ConfigSelectProfile
	add	sp,018h
	mov	ax,[bp-02h]
	or	ax,[bp-04h]
	jz	short cfgui_cfgui_10E
	push	word ptr [bp-02h]
	push	word ptr [bp-04h]
	call	far ptr RegCloseKey
	add	sp,04h
cfgui_cfgui_10E:
	mov	ax,offset DGROUP:ConfigUIState
	les	bx,[bp+06h]
	mov	es:[bx],ax
	mov	word ptr es:[bx+02h],ds
	mov	es,word ptr [bp+0Ch]
	mov	word ptr es:[si],05Ch
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
	nop
ConfigUI	endp
CFGPNP	ends
	end
