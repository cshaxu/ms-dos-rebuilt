;** CFGMAIN.ASM - Real-mode configuration program entry
;
	.386
_DATA segment word public use16 'RESUME_DATA'
	extrn ConfigReturnCode:word,AsdHexDigits:byte
_DATA ends
DGROUP group _DATA
SysResume segment byte public use16 'RESUME_CODE'
	assume cs:SysResume,ds:DGROUP
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

SysResume ends
	end
