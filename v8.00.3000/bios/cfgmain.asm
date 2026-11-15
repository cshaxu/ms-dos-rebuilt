;** CFGMAIN.ASM - Real-mode configuration program entry
;
	.386
HKEY_LOCAL_MACHINE equ 80000002h
_DATA segment word public use16 'RESUME_DATA'
	extrn ConfigReturnCode:word,AsdHexDigits:byte
	extrn ConfigWindowsPath:dword,ConfigArgPaths:dword,ConfigArgValues:dword
_DATA ends
DGROUP group _DATA
SysResume segment byte public use16 'RESUME_CODE'
	assume cs:SysResume,ds:DGROUP
	extrn RegOpenKey:far,RegCloseKey:far,RegQueryValueEx:far
	extrn RegQueryInfoKey:far,RegEnumValue:far
	public	ConfigSetError

;	Save the first nonzero configuration error.
;	Far C argument: error code.
;
ConfigSetError	proc	far
	push	bp
	mov	bp,sp
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	cmp	word ptr ConfigReturnCode,00h
	jnz	short cfgerror_error_loc_010
	mov	ax,[bp+06h]
	mov	ConfigReturnCode,ax
cfgerror_error_loc_010:
	pop	ds
	leave
	retf
ConfigSetError	endp
	nop

; Read the configuration records requested by the caller.
	public ConfigReadArguments
ConfigReadArguments proc far
	enter	26h,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	les	bx,dword ptr [bp+6]
	inc	word ptr [bp+6]
	mov	al,es:[bx]
	cbw
	mov	cx,ax
	cmp	cx,8
	jl	near ptr cfgargs_done
	mov	bx,[bp+6]
	inc	word ptr [bp+6]
	cmp	byte ptr es:[bx],0ffh
	jnz	near ptr cfgargs_done
	sub	cx,2
	mov	[bp-8],cx
	mov	bx,[bp+6]
	inc	word ptr [bp+6]
	mov	al,es:[bx]
	cbw
	sub	ax,11h
	sbb	dx,dx
	and	ax,dx
	add	ax,11h
	mov	si,ax
	or	si,ax
	jz	short cfgargs_stage
	cmp	cx,6
	jl	short cfgargs_stage
	mov	bx,[bp+6]
	db 66h
	mov	ax,es:[bx+2]
	mov	[ConfigWindowsPath],eax
cfgargs_stage:
	cmp	word ptr [bp+0ah],0
	jnz	near ptr cfgargs_done
	xor	di,di
	or	si,si
	jng	near ptr cfgargs_done
	mov	[bp-0ah],si
	xor	dx,dx
	mov	[bp-6],dx
	mov	si,dx
cfgargs_next:
	cmp	word ptr [bp-8],6
	jl	near ptr cfgargs_done
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	push	dword ptr [si+ConfigArgPaths]
	db 66h,68h		; PUSH dword immediate
	dd HKEY_LOCAL_MACHINE
	call	far ptr RegOpenKey
	add	sp,0ch
	or	dx,ax
	jz	short cfgargs_query
	add	word ptr [bp+6],6
	jmp	near ptr cfgargs_advance
	nop
cfgargs_query:
	les	bx,dword ptr [bp+6]
	add	word ptr [bp+6],2
	mov	ax,es:[bx]
	mov	[bp-16h],ax
	mov	word ptr [bp-14h],0
	mov	bx,[bp+6]
	add	word ptr [bp+6],4
	db 66h
	mov	ax,es:[bx]
	mov	[bp-4],eax
	mov	ax,di
	cmp	ax,10h
	jz	near ptr cfgargs_environment
	ja	short cfgargs_read
	sub	al,8
	jl	short cfgargs_read
	sub	al,3
	jng	short cfgargs_number
	dec	al
	jz	short cfgargs_language
cfgargs_read:
	lea	ax,[bp-16h]
	push	ss
	push	ax
	push	dword ptr [bp-4]
	db 66h
	push 0
	db 66h
	push 0
	push	dword ptr [si+ConfigArgValues]
	push	dword ptr [bp-0eh]
	call	far ptr RegQueryValueEx
	add	sp,18h
	jmp	near ptr cfgargs_close
	nop
cfgargs_number:
	mov	dword ptr [bp-12h],10h
	lea	ax,[bp-12h]
	push	ss
	push	ax
	lea	ax,[bp-26h]
	push	ss
	push	ax
	db 66h
	push 0
	db 66h
	push 0
	push	dword ptr [si+ConfigArgValues]
	push	dword ptr [bp-0eh]
	call	far ptr RegQueryValueEx
	add	sp,18h
	or	dx,ax
	jnz	short cfgargs_close
	cmp	byte ptr [bp-26h],0
	jnz	short cfgargs_convert
	les	bx,dword ptr [bp-4]
	mov	word ptr es:[bx],0
	jmp	short cfgargs_close
	nop
cfgargs_convert:
	lea	ax,[bp-26h]
	push	ss
	push	ax
	push	cs
	call	near ptr ConfigParseNumber
	add	sp,4
	les	bx,dword ptr [bp-4]
	mov	es:[bx],ax
	jmp	short cfgargs_close
cfgargs_language:
	mov	dword ptr [bp-12h],10h
	lea	ax,[bp-12h]
	push	ss
	push	ax
	lea	ax,[bp-26h]
	push	ss
	push	ax
	db 66h
	push 0
	db 66h
	push 0
	push	dword ptr [si+ConfigArgValues]
	push	dword ptr [bp-0eh]
	call	far ptr RegQueryValueEx
	add	sp,18h
	or	dx,ax
	jnz	short cfgargs_close
	mov	al,[bp-26h]
	les	bx,dword ptr [bp-4]
	mov	es:[bx],al
	mov	al,[bp-25h]
	mov	es:[bx+1],al
	jmp	short cfgargs_close
	nop
cfgargs_environment:
	lea	ax,[bp-16h]
	push	ss
	push	ax
	push	dword ptr [bp-4]
	push	dword ptr [bp-0eh]
	push	cs
	call	near ptr ConfigReadEnvironment
	add	sp,0ch
cfgargs_close:
	push	dword ptr [bp-0eh]
	call	far ptr RegCloseKey
	add	sp,4
cfgargs_advance:
	add	si,4
	sub	word ptr [bp-8],6
	inc	di
	cmp	[bp-0ah],di
	jg	near ptr cfgargs_next
cfgargs_done:
	pop	ds
	pop	si
	pop	di
	leave
	retf
ConfigReadArguments endp

; Convert a decimal registry value to a word.
	public ConfigParseNumber
ConfigParseNumber proc far
	enter	8,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	ds,word ptr [bp+8]
	mov	si,[bp+6]
	sub	eax,eax
	mov	[bp-4],eax
	cmp	[si],al
	jz	short cpn_result
cpn_digit:
	cmp	byte ptr [si],30h
	jl	short cpn_invalid
	cmp	byte ptr [si],39h
	jg	short cpn_invalid
	cmp	dword ptr [bp-4],10000h
	ja	short cpn_invalid
	mov	al,[si]
	cbw
	sub	ax,30h
	cwd
	mov	cx,[bp-4]
	mov	bx,[bp-2]
	mov	[bp-6],dx
	mov	di,cx
	mov	dx,bx
	add	cx,cx
	adc	bx,bx
	add	cx,cx
	adc	bx,bx
	add	cx,di
	adc	bx,dx
	add	cx,cx
	adc	bx,bx
	add	cx,ax
	adc	bx,[bp-6]
	mov	[bp-4],cx
	mov	[bp-2],bx
	inc	si
	cmp	byte ptr [si],0
	jnz	short cpn_digit
	jmp	short cpn_result
cpn_invalid:
	mov	dword ptr [bp-4],0
cpn_result:
	mov	ax,[bp-4]
	pop	ds
	pop	si
	pop	di
	leave
	retf
ConfigParseNumber endp

; Format a long value in hexadecimal.
	public AsdFormatHex
AsdFormatHex proc far
	enter 4,0
	push di
	push si
	push ds
	mov ax,DGROUP
	mov ds,ax
	mov di,[bp+0Ah]
	mov ax,[bp+6]
	mov dx,[bp+8]
	add ax,di
	dec ax
	mov si,ax
	mov [bp-2],dx
	or di,di
	jz short asdformathex_done
	mov es,word ptr [bp-2]
asdformathex_digit:
	mov bl,[bp+0Ch]
	and bx,0Fh
	mov al,AsdHexDigits[bx]
	mov bx,si
	dec si
	mov es:[bx],al
	mov eax,[bp+0Ch]
	shr eax,4
	mov [bp+0Ch],eax
	dec di
	jnz short asdformathex_digit
asdformathex_done:
	pop ds
	pop si
	pop di
	leave
	retf
AsdFormatHex endp

; Format a byte array as consecutive hexadecimal pairs.
	public AsdFormatBytes
AsdFormatBytes proc far
	enter 0Ch,0
	push di
	push si
	push ds
	mov ax,DGROUP
	mov ds,ax
	sub ax,ax
	cmp [bp+010h],ax
	jnz short asdformatbytes_setup
	cmp [bp+0Eh],ax
	jz short asdformatbytes_done
asdformatbytes_setup:
	mov ax,[bp+0Eh]
	mov [bp-6],ax
	mov ax,[bp+010h]
	mov [bp-8],ax
	neg word ptr [bp-6]
	neg word ptr [bp-6]
	adc word ptr [bp-8],-1
	mov si,[bp+0Ah]
	mov di,[bp+6]
asdformatbytes_next:
	mov es,[bp+0Ch]
	mov al,es:[si]
	sub ah,ah
	push 0
	push ax
	push 2
	push word ptr [bp+8]
	push di
	push cs
	call near ptr AsdFormatHex
	add sp,0Ah
	add di,2
	inc si
	dec word ptr [bp-6]
	jnz short asdformatbytes_next
	dec word ptr [bp-8]
	jns short asdformatbytes_next
asdformatbytes_done:
	pop ds
	pop si
	pop di
	leave
	retf
AsdFormatBytes endp
	nop

; Read registry environment values into the caller's ASCIIZ table.
	public ConfigReadEnvironment
ConfigReadEnvironment proc far
	enter	22h,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	si,[bp+0ah]
	mov	dword ptr [bp-1ah],0
	mov	word ptr [bp-0ah],1
	mov	ax,[bp+0ch]
	or	ax,si
	jz	near ptr cenv_invalid
	mov	di,[bp+0eh]
	mov	ax,[bp+10h]
	or	ax,di
	jz	near ptr cenv_invalid
	mov	es,word ptr [bp+10h]
	db 66h
	cmp	word ptr es:[di],2
	jc	near ptr cenv_invalid
	xor	al,al
	mov	es,word ptr [bp+0ch]
	mov	es:[si],al
	mov	es:[si+1],al
	sub	eax,eax
	mov	[bp-8],eax
	push	ax
	push	ax
	push	ax
	push	ax
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	lea	ax,[bp-1eh]
	push	ss
	push	ax
	lea	ax,[bp-1ah]
	push	ss
	push	ax
	db 66h
	push 0
	db 66h
	push 0
	db 66h
	push 0
	db 66h
	push 0
	db 66h
	push 0
	db 66h
	push 0
	push	dword ptr [bp+6]
	call	far ptr RegQueryInfoKey
	add	sp,30h
	or	dx,ax
	jnz	short cenv_adjust_size
	mov	es,word ptr [bp+10h]
	mov	eax,[bp-0eh]
	add	eax,[bp-1eh]
	db 66h,05h		; ADD EAX with a full-width immediate
	dd 3
	db 66h
	cmp	ax,es:[di]
	jna	short cenv_init
	xor	cx,cx
	jmp	near ptr cenv_length
	nop
cenv_adjust_size:
	mov	cx,[bp-0ah]
	jmp	near ptr cenv_length
cenv_init:
	sub	eax,eax
	mov	[bp-4],eax
	cmp	[bp-18h],ax
	jnz	short cenv_value
	cmp	[bp-1ah],ax
	jz	near ptr cenv_finish
cenv_value:
	mov	es,word ptr [bp+10h]
	db 66h
	mov	ax,es:[di]
	sub	eax,[bp-8]
	mov	[bp-0eh],eax
	mov	[bp-1eh],eax
	mov	[bp-12h],eax
	mov	[bp-16h],eax
	lea	ax,[bp-12h]
	push	ss
	push	ax
	mov	ax,si
	mov	dx,[bp+0ch]
	add	ax,[bp-8]
	push	dx
	push	ax
	lea	cx,[bp-22h]
	push	ss
	push	cx
	db 66h
	push 0
	lea	cx,[bp-16h]
	push	ss
	push	cx
	push	dx
	push	ax
	push	dword ptr [bp-4]
	push	dword ptr [bp+6]
	call	far ptr RegEnumValue
	add	sp,20h
	or	dx,ax
	jnz	near ptr cenv_terminate
	cmp	dword ptr [bp-22h],1
	jnz	near ptr cenv_advance
	mov	es,word ptr [bp+10h]
	mov	eax,[bp-12h]
	add	eax,[bp-16h]
	db 66h,05h		; ADD EAX with a full-width immediate
	dd 3
	db 66h
	cmp	ax,es:[di]
	ja	near ptr cenv_terminate
	lea	ax,[bp-0eh]
	push	ss
	push	ax
	mov	ax,[bp-8]
	add	ax,[bp-16h]
	mov	cx,[bp+0ch]
	add	ax,si
	inc	ax
	push	cx
	push	ax
	lea	ax,[bp-22h]
	push	ss
	push	ax
	db 66h
	push 0
	lea	ax,[bp-1eh]
	push	ss
	push	ax
	mov	ax,[bp-8]
	add	ax,si
	push	cx
	push	ax
	push	dword ptr [bp-4]
	push	dword ptr [bp+6]
	call	far ptr RegEnumValue
	add	sp,20h
	or	dx,ax
	jnz	near ptr cenv_append
	mov	eax,[bp-16h]
	add	[bp-8],eax
	mov	eax,[bp-8]
	mov	bx,ax
	mov	cx,[bp+0ch]
	add	bx,si
	mov	es,cx
	mov	byte ptr es:[bx],3dh
	add	eax,[bp-12h]
	mov	[bp-8],eax
	mov	dx,[bp-6]
	mov	bx,ax
	add	bx,si
	add	ax,1
	mov	byte ptr es:[bx],0
	adc	dx,0
	mov	[bp-8],ax
	mov	[bp-6],dx
	mov	bx,ax
	add	bx,si
	mov	byte ptr es:[bx],0
cenv_advance:
	mov	eax,[bp-1ah]
	inc	dword ptr [bp-4]
	cmp	[bp-4],eax
	jc	near ptr cenv_value
cenv_finish:
	mov	cx,[bp-0ah]
	jmp	short cenv_empty
	nop
	nop
cenv_terminate:
	mov	ds,word ptr [bp+10h]
	mov	eax,[di]
	cmp	[bp-8],eax
	jnc	short cenv_double_nul
	mov	bx,[bp-8]
	mov	ax,[bp+0ch]
	add	bx,si
	mov	es,ax
	mov	byte ptr es:[bx],0
	mov	ax,[bp-8]
	mov	dx,[bp-6]
	add	ax,1
	adc	dx,0
	cmp	dx,[di+2]
	ja	short cenv_double_nul
	jc	short cenv_single_nul
	cmp	ax,[di]
	jmp	short cenv_end_entry
	nop
cenv_append:
	mov	eax,[bp-8]
	mov	es,word ptr [bp+10h]
	db 66h
	cmp	es:[di],ax
	jna	short cenv_double_nul
	mov	bx,ax
	mov	ax,[bp+0ch]
	add	bx,si
	mov	es,ax
	mov	byte ptr es:[bx],0
	mov	es,word ptr [bp+10h]
	mov	ax,[bp-8]
	mov	dx,[bp-6]
	add	ax,1
	adc	dx,0
	cmp	dx,es:[di+2]
	ja	short cenv_double_nul
	jc	short cenv_single_nul
	cmp	ax,es:[di]
cenv_end_entry:
	jnc	short cenv_double_nul
cenv_single_nul:
	mov	bx,[bp-8]
	mov	ax,[bp+0ch]
	add	bx,si
	mov	es,ax
	mov	byte ptr es:[bx+1],0
cenv_double_nul:
	xor	cx,cx
cenv_empty:
	mov	bx,[bp-8]
	mov	ax,[bp+0ch]
	add	bx,si
	mov	es,ax
	mov	byte ptr es:[bx],0
	inc	dword ptr [bp-8]
cenv_length:
	mov	eax,[bp-8]
	mov	es,word ptr [bp+10h]
	db 66h
	mov	es:[di],ax
	mov	ax,cx
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
cenv_invalid:
	xor	ax,ax
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
ConfigReadEnvironment endp

SysResume ends
	end
