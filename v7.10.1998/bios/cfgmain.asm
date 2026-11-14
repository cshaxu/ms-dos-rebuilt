;** CFGMAIN.ASM - Real-mode configuration program entry.
;
	.286
	extrn	RegCloseKey:far
	extrn	RegOpenKey:far
	extrn	RegQueryValueEx:far

	extrn	ConfigPreparePath:far,RegInitialize:far,RegTerminate:far
	extrn	RegMountRoot:far
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
	extrn	ConfigWindowsPath:dword
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

;	Read up to eight bootstrap values from the DOS command tail.
;	Far C argument: command-tail pointer.
;	The first record can also supply the Windows directory.
ConfigReadArguments	proc	far
	push	bp
	mov	bp,sp
	sub	sp,0Eh
	push	di
	push	si
	les	bx,[bp+06h]
	inc	word ptr [bp+06h]
	mov	al,es:[bx]
	cbw
	mov	cx,ax
	cmp	cx,8
	jnl	short cfgargs_marker
	jmp	near ptr cfgargs_done
cfgargs_marker:
	mov	bx,[bp+06h]
	inc	word ptr [bp+06h]
	cmp	byte ptr es:[bx],0FFh
	jz	short cfgargs_count
	jmp	near ptr cfgargs_done
cfgargs_count:
	sub	cx,2
	mov	[bp-04h],cx
	mov	bx,[bp+06h]
	inc	word ptr [bp+06h]
	mov	al,es:[bx]
	cbw
	sub	ax,8
	sbb	dx,dx
	and	ax,dx
	add	ax,8
	mov	si,ax
	or	si,ax
	jz	short cfgargs_begin
	cmp	cx,6
	jl	short cfgargs_begin
	mov	bx,[bp+06h]
	mov	ax,es:[bx+2]
	mov	dx,es:[bx+4]
	mov	word ptr ConfigWindowsPath,ax
	mov	word ptr ConfigWindowsPath+2,dx
cfgargs_begin:
	xor	di,di
	or	si,si
	jg	short cfgargs_setup
	jmp	near ptr cfgargs_done
cfgargs_setup:
	mov	[bp-06h],si
	xor	dx,dx
	mov	[bp-02h],dx
	mov	si,dx
cfgargs_next:
	cmp	word ptr [bp-04h],6
	jnl	short cfgargs_open
	jmp	near ptr cfgargs_done
cfgargs_open:
	lea	ax,[bp-0Ah]
	push	ss
	push	ax
	push	word ptr ConfigArgPaths[si+2]
	push	word ptr ConfigArgPaths[si]
	mov	ax,2
	mov	dx,8000h
	push	dx
	push	ax
	call	far ptr RegOpenKey
	add	sp,0Ch
	or	dx,ax
	jz	short cfgargs_query
	add	word ptr [bp+06h],6
	jmp	short cfgargs_advance
	even
cfgargs_query:
	les	bx,[bp+06h]
	add	word ptr [bp+06h],2
	mov	ax,es:[bx]
	mov	[bp-0Eh],ax
	mov	word ptr [bp-0Ch],0
	lea	ax,[bp-0Eh]
	push	ss
	push	ax
	mov	bx,[bp+06h]
	add	word ptr [bp+06h],4
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	word ptr ConfigArgValues[si+2]
	push	word ptr ConfigArgValues[si]
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegQueryValueEx
	add	sp,18h
	push	word ptr [bp-08h]
	push	word ptr [bp-0Ah]
	call	far ptr RegCloseKey
	add	sp,4
cfgargs_advance:
	add	si,4
	sub	word ptr [bp-04h],6
	inc	di
	cmp	di,[bp-06h]
	jnl	short cfgargs_done
	jmp	near ptr cfgargs_next
cfgargs_done:
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
	xor	ax,ax
	push	ax
	call	far ptr RegInitialize
	add	sp,2
	or	dx,ax
	jnz	short cfgmain_main_error
	xor	ax,ax
	push	ax
	mov	ax,offset DGROUP:ConfigPathBuffer
	push	ds
	push	ax
	mov	ax,2
	mov	dx,8000h
	push	dx
	push	ax
	call	far ptr RegMountRoot
	add	sp,10
	or	dx,ax
	jz	short cfgmain_main_arguments
cfgmain_main_error:
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
