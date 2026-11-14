;** CFGMAIN.ASM - Real-mode configuration program entry.
;
	.286
	extrn	RegCloseKey:far
	extrn	RegOpenKey:far
	extrn	RegQueryValueEx:far

	extrn	ConfigPreparePath:far,RegInitialize:far,RegTerminate:far
	extrn	ConfigUI:far,ConfigPublishData:far
_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
CFGMAIN	segment	word public 'CODE'
CFGMAIN	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	ConfigInitialState:byte
	extrn	ConfigInfoSize:word
	extrn	ConfigReturnCode:word
	extrn	ConfigArgPaths:dword
	extrn	ConfigArgValues:dword
	extrn	ConfigArgPath0:byte
	extrn	ConfigArgPath1:byte
	extrn	ConfigArgPath2:byte
	extrn	ConfigArgPath3:byte
	extrn	ConfigArgPath4:byte
	extrn	ConfigArgPath5:byte
	extrn	ConfigArgValue0:byte
	extrn	ConfigArgValue1:byte
	extrn	ConfigArgValue2:byte
	extrn	ConfigArgValue3:byte
	extrn	ConfigArgValue4:byte
	extrn	ConfigArgValue5:byte
	extrn	ConfigArgValue6:byte
	extrn	__psp:word
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	ConfigInfoData:dword,ConfigPathBuffer:byte
c_common	ends
CFGMAIN	segment	word public 'CODE'
	assume	cs:CFGMAIN,ds:DGROUP
	public	ConfigSetError

;	Save the first nonzero configuration error.
;	Far C argument: error code.
;
ConfigSetError	proc	far
	push	bp
	mov	bp,sp
	cmp	word ptr ConfigReturnCode,00h
	jnz	short cfgerror_error_loc_010
	mov	ax,[bp+06h]
	mov	ConfigReturnCode,ax
cfgerror_error_loc_010:
	pop	bp
	ret
ConfigSetError	endp
	assume	cs:CFGMAIN,ds:DGROUP
	public	ConfigReadArguments

;	Read up to seven bootstrap values from the DOS command tail.
;	Far C argument: command-tail pointer.
;
ConfigReadArguments	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Ch
	push	di
	push	si
	les	bx,[bp+06h]
	inc	word ptr [bp+06h]
	mov	al,es:[bx]
	cbw
	mov	di,ax
	cmp	di,08h
	jnl	short cfgargs_args_loc_01C
	jmp	cfgargs_args_loc_0E7
cfgargs_args_loc_01C:
	mov	bx,[bp+06h]
	inc	word ptr [bp+06h]
	cmp	byte ptr es:[bx],0FFh
	jz	short cfgargs_args_loc_02B
	jmp	cfgargs_args_loc_0E7
cfgargs_args_loc_02B:
	sub	di,02h
	mov	word ptr [bp-02h],00h
	mov	bx,[bp+06h]
	inc	word ptr [bp+06h]
	mov	al,es:[bx]
	cbw
	sub	ax,07h
	sbb	dx,dx
	and	ax,dx
	add	ax,07h
	mov	cx,ax
	or	cx,ax
	jg	short cfgargs_args_loc_050
	jmp	cfgargs_args_loc_0E7
cfgargs_args_loc_050:
	mov	[bp-04h],cx
	xor	si,si
cfgargs_args_loc_055:
	cmp	di,06h
	jnl	short cfgargs_args_loc_05D
	jmp	cfgargs_args_loc_0E7
cfgargs_args_loc_05D:
	lea	ax,[bp-08h]
	push	ss
	push	ax
	push	word ptr ConfigArgPaths[si+2]
	push	word ptr ConfigArgPaths[si]
	mov	ax,02h
	mov	dx,08000h
	push	dx
	push	ax
	call	far ptr RegOpenKey
	add	sp,0Ch
	or	dx,ax
	jz	short cfgargs_args_loc_084
	add	word ptr [bp+06h],06h
	jmp	short cfgargs_args_loc_0D3
cfgargs_args_loc_084:
	les	bx,[bp+06h]
	add	word ptr [bp+06h],02h
	mov	ax,es:[bx]
	mov	[bp-0Ch],ax
	mov	word ptr [bp-0Ah],00h
	lea	ax,[bp-0Ch]
	push	ss
	push	ax
	mov	bx,[bp+06h]
	add	word ptr [bp+06h],04h
	push	word ptr es:[bx+02h]
	push	word ptr es:[bx]
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	word ptr ConfigArgValues[si+2]
	push	word ptr ConfigArgValues[si]
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegQueryValueEx
	add	sp,018h
	push	word ptr [bp-06h]
	push	word ptr [bp-08h]
	call	far ptr RegCloseKey
	add	sp,04h
cfgargs_args_loc_0D3:
	add	si,04h
	sub	di,06h
	mov	ax,[bp-04h]
	inc	word ptr [bp-02h]
	cmp	[bp-02h],ax
	jnl	short cfgargs_args_loc_0E7
	jmp	cfgargs_args_loc_055
cfgargs_args_loc_0E7:
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
ConfigReadArguments	endp
	even
	assume	cs:CFGMAIN

	public	__setargv,__setenvp

;	The program reads the PSP command tail directly; no C argv is built.
;
__setargv	proc	far
	ret
__setargv	endp
	even

;	The configuration program does not require a C environment table.
;
__setenvp	proc	far
	ret
__setenvp	endp
	even

	assume	cs:CFGMAIN,ds:DGROUP
	public	_main

;	Save the command tail, open the registry and select a hardware profile.
;	Publish the resulting data through CONFIG$ and return the error code.
;
_main	proc	far
	push	bp
	mov	bp,sp
	sub	sp,84h
	push	di
	push	si
	mov	ax,__psp
	mov	[bp-2],ax
	mov	word ptr [bp-4],80h
	mov	ax,[bp-4]
	mov	dx,[bp-2]
	push	ds
	lea	di,[bp-84h]
	mov	si,ax
	push	ss
	pop	es
	mov	ds,dx
	mov	cx,40h
	rep	movsw
	pop	ds
	mov	ax,offset DGROUP:ConfigPathBuffer
	push	ds
	push	ax
	call	far ptr ConfigPreparePath
	add	sp,4
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	mov	ax,offset DGROUP:ConfigPathBuffer
	push	ds
	push	ax
	call	far ptr RegInitialize
	add	sp,12
	or	dx,ax
	jz	short cfgmain_main_arguments
	mov	ax,1
	push	ax
	push	cs
	call	near ptr ConfigSetError
	add	sp,2
cfgmain_main_arguments:
	lea	ax,[bp-84h]
	push	ss
	push	ax
	push	cs
	call	near ptr ConfigReadArguments
	add	sp,4
	mov	ax,offset DGROUP:ConfigInfoSize
	push	ds
	push	ax
	mov	ax,offset DGROUP:ConfigInfoData
	push	ds
	push	ax
	call	far ptr ConfigUI
	add	sp,8
	call	far ptr RegTerminate
	call	far ptr ConfigPublishData
	mov	ax,ConfigReturnCode
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
_main	endp
CFGMAIN	ends
	end
