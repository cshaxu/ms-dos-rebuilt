;** CFGMAIN.ASM - Real-mode configuration program entry
;
	.386
HKEY_LOCAL_MACHINE equ 80000002h
_DATA segment word public use16 'RESUME_DATA'
	extrn ConfigReturnCode:word,AsdHexDigits:byte
	extrn ConfigWindowsPath:dword,ConfigArgPaths:dword,ConfigArgValues:dword
	extrn ConfigRecordCount:word
	extrn AsdGuidFormat:byte,AsdValueName:word,AsdFileName:byte
	extrn AsdProblemsKey:byte,AsdRunOnceKey:byte
	extrn AsdWizardCommand:byte,AsdWizardValue:byte
_DATA ends
RESWORK segment word public use16 'RESUME_BSS'
	extrn ConfigPathBuffer:byte,AsdRecord:byte,AsdOutputRecord:byte
RESWORK ends
DGROUP group _DATA,RESWORK
SysResume segment byte public use16 'RESUME_CODE'
	assume cs:SysResume,ds:DGROUP
	extrn RegOpenKey:far,RegCloseKey:far,RegQueryValueEx:far
	extrn RegQueryInfoKey:far,RegEnumValue:far
	extrn RegInitialize:far,RegMountRoot:far,RegTerminate:far
	extrn ConfigPreparePath:far,ConfigBeginRecordFile:far,ConfigWriteRecord:far
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

; Build the ASD problem key from the identifier and root path.
	public AsdOpenProblem
AsdOpenProblem proc far
	enter	100h,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	si,[bp+0eh]
	mov	ax,[bp+10h]
	or	ax,si
	jz	near ptr asdproblem_base
	mov	es,word ptr [bp+10h]
	db 66h
	push	word ptr es:[si]
	push	8
	push	ds
	push	offset DGROUP:AsdGuidFormat+1
	push	cs
	call	near ptr AsdFormatHex
	add	sp,0ah
	mov	es,word ptr [bp+10h]
	push	0
	push	word ptr es:[si+4]
	push	4
	push	ds
	push	offset DGROUP:AsdGuidFormat+0Ah
	push	cs
	call	near ptr AsdFormatHex
	add	sp,0ah
	mov	es,word ptr [bp+10h]
	push	0
	push	word ptr es:[si+6]
	push	4
	push	ds
	push	offset DGROUP:AsdGuidFormat+0Fh
	push	cs
	call	near ptr AsdFormatHex
	add	sp,0ah
	db 66h
	push 2
	mov	ax,si
	mov	dx,[bp+10h]
	add	ax,8
	push	dx
	push	ax
	push	ds
	push	offset DGROUP:AsdGuidFormat+14h
	push	cs
	call	near ptr AsdFormatBytes
	add	sp,0ch
	db 66h
	push 6
	mov	ax,si
	mov	dx,[bp+10h]
	add	ax,0ah
	push	dx
	push	ax
	push	ds
	push	offset DGROUP:AsdGuidFormat+19h
	push	cs
	call	near ptr AsdFormatBytes
	add	sp,0ch
	push	ds
	push	offset DGROUP:AsdGuidFormat
	push	dword ptr [bp+0ah]
	lea	ax,[bp-100h]
	push	ss
	push	ax
	call	far ptr AsdJoinPath
	add	sp,0ch
	jmp	short asdproblem_result
asdproblem_base:
	push	ds
	lea	si,[bp-100h]
	mov	cx,ss
	mov	ds,cx
	les	di,dword ptr [bp+0ah]
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
asdproblem_result:
	lea	ax,[bp-100h]
	push	ss
	push	ax
	push	dword ptr [bp+6]
	push	cs
	call	near ptr AsdCopyString
	add	sp,8
	mov	ax,1
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
AsdOpenProblem endp

; Import a pending ASD boot record into the XMS update area.
	public AsdImport
AsdImport proc far
	enter	10ah,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	word ptr [bp-4],0ffffh
	mov	byte ptr [bp-6],0
	mov	ax,[AsdValueName]
	mov	[bp-106h],ax
	xor	eax,eax
	mov	ecx,3fh
	lea	di,[bp-104h]
	push	ss
	pop	es
	rep	stosd
	stosw
	push	ds
	push	offset DGROUP:AsdFileName
	push	dword ptr [ConfigWindowsPath]
	push	ds
	push	offset DGROUP:ConfigPathBuffer
	call	far ptr AsdJoinPath
	add	sp,0ch
	and	byte ptr [ConfigPathBuffer],7fh
	push	si
	mov	si,offset DGROUP:ConfigPathBuffer
	mov	bx,10h
	mov	dx,1
	mov	ax,6c00h
	mov	cx,6
	push	bp
	int	21h
	pop	bp
	jc	short asdimport_opened
	mov	[bp-4],ax
asdimport_opened:
	pop	si
	cmp	word ptr [bp-4],-1
	jz	near ptr asdimport_done
	mov	ah,3fh
	mov	bx,[bp-4]
	mov	cx,118h
	mov	dx,offset DGROUP:AsdRecord
	push	bp
	int	21h
	pop	bp
	jc	short asdimport_read
	cmp	ax,118h
	jz	short asdimport_read
	stc
asdimport_read:
	pushf
	mov	ax,3e00h
	mov	bx,[bp-4]
	push	bp
	int	21h
	pop	bp
	popf
	jc	short asdimport_close_file
	mov	byte ptr [bp-6],1
asdimport_close_file:
	cmp	byte ptr [bp-6],0
	jz	near ptr asdimport_done
	push	ds
	push	offset DGROUP:AsdRecord
	push	ds
	push	offset DGROUP:AsdProblemsKey
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr AsdOpenProblem
	add	sp,0ch
	or	ax,ax
	jz	near ptr asdimport_remove_file
	mov	eax,dword ptr [AsdRecord+14h]
	mov	dx,word ptr [AsdRecord+16h]
	cmp	eax,100h
	jna	short asdimport_limit_length
	mov	ax,100h
asdimport_limit_length:
	mov	[bp-108h],ax
	mov	cx,ax
	lea	di,[bp-106h]
	mov	si,offset DGROUP:AsdRecord+18h
	mov	ax,ss
	mov	es,ax
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	mov	ax,word ptr [AsdRecord+14h]
	or	dx,dx
	jnz	short asdimport_limit_name
	cmp	ax,100h
	jna	short asdimport_end_name
asdimport_limit_name:
	xor	dx,dx
	mov	ax,100h
asdimport_end_name:
	mov	si,ax
	mov	byte ptr [bp+si-106h],0
	cmp	dword ptr [AsdRecord+14h],100h
	jna	short asdimport_publish
	mov	byte ptr [bp-0ch],2dh
	push	0
	push	word ptr [AsdRecord+116h]
	push	4
	lea	ax,[bp-0ah]
	push	ss
	push	ax
	push	cs
	call	near ptr AsdFormatHex
	add	sp,0ah
asdimport_publish:
	mov	byte ptr [bp-2],2
	db 66h
	push 1
	lea	ax,[bp-2]
	push	ss
	push	ax
	db 66h
	push 3
	lea	ax,[bp-106h]
	push	ss
	push	ax
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr AsdSetRecord
	add	sp,14h
	db 66h,68h		; PUSH dword immediate
	dd 21ch
	mov	ax,[ConfigRecordCount]
	inc	word ptr [ConfigRecordCount]
	imul	ax,ax,21ch
	add	ax,2
	push	0
	push	ax
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr ConfigWriteRecords
	add	sp,0ch
	push	ds
	push	offset DGROUP:AsdRunOnceKey
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr AsdCopyString
	add	sp,8
	db 66h
	push 11
	push	ds
	push	offset DGROUP:AsdWizardCommand
	db 66h
	push 1
	push	ds
	push	offset DGROUP:AsdWizardValue
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr AsdSetRecord
	add	sp,14h
	db 66h,68h		; PUSH dword immediate
	dd 21ch
	mov	ax,[ConfigRecordCount]
	inc	word ptr [ConfigRecordCount]
	imul	ax,ax,21ch
	add	ax,2
	push	0
	push	ax
	push	ds
	push	offset DGROUP:AsdOutputRecord
	push	cs
	call	near ptr ConfigWriteRecords
	add	sp,0ch
asdimport_remove_file:
	mov	ah,41h
	mov	dx,offset DGROUP:ConfigPathBuffer
	push	bp
	int	21h
	pop	bp
	push	2
	push	cs
	call	near ptr ConfigSetError
	add	sp,2
asdimport_done:
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
AsdImport endp

; Load boot configuration from the system registry.
	public BootConfig
BootConfig proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	di,[bp+6]
	push	1
	push	word ptr [bp+8]
	push	di
	push	cs
	call	near ptr ConfigReadArguments
	add	sp,6
	push	ds
	push	offset DGROUP:ConfigPathBuffer
	call	far ptr ConfigPreparePath
	add	sp,4
	db 66h,68h		; PUSH dword immediate
	dd 43ah
	push	ds
	push	offset DGROUP:ConfigPathBuffer
	call	far ptr ConfigBeginRecordFile
	add	sp,8
	mov	si,ax
	or	si,ax
	jz	short cfgboot_mount
	push	1
	push	cs
	call	near ptr ConfigSetError
	add	sp,2
cfgboot_mount:
	or	si,si
	jnz	short cfgboot_read
	push	si
	call	far ptr RegInitialize
	add	sp,2
	or	dx,ax
	jnz	short cfgboot_error
	push	si
	push	ds
	push	offset DGROUP:ConfigPathBuffer
	db 66h,68h		; PUSH dword immediate
	dd 80000002h
	call	far ptr RegMountRoot
	add	sp,0ah
	or	dx,ax
	jz	short cfgboot_read
cfgboot_error:
	push	1
	push	cs
	call	near ptr ConfigSetError
	add	sp,2
cfgboot_read:
	push	0
	push	word ptr [bp+8]
	push	di
	push	cs
	call	near ptr ConfigReadArguments
	add	sp,6
	cmp	word ptr [ConfigReturnCode],0
	jnz	short cfgboot_publish
	push	cs
	call	near ptr AsdImport
cfgboot_publish:
	db 66h
	push 2
	db 66h
	push 0
	push	ds
	push	offset DGROUP:ConfigRecordCount
	push	cs
	call	near ptr ConfigWriteRecords
	add	sp,0ch
	call	far ptr RegTerminate
	mov	ax,[ConfigReturnCode]
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
BootConfig endp

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

; Copy an ASCIIZ string between far buffers.
	public AsdCopyString
AsdCopyString proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	les	di,dword ptr [bp+0ah]
	push	ax
	lds	si,dword ptr [bp+6]
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
AsdCopyString endp

; Fill the name, type and data fields in an ASD update record.
	public AsdSetRecord
AsdSetRecord proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	bx,[bp+6]
	mov	cx,[bp+8]
	add	bh,1
	push	ax
	mov	si,bx
	mov	ds,cx
	les	di,dword ptr [bp+0ah]
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	mov	eax,[bp+0eh]
	les	bx,dword ptr [bp+6]
	db 66h
	mov	es:[bx+200h],ax
	mov	eax,[bp+16h]
	db 66h
	mov	es:[bx+204h],ax
	mov	si,[bp+12h]
	mov	di,[bp+14h]
	les	bx,dword ptr [bp+6]
	mov	ecx,[bp+16h]
	cmp	ecx,14h
	jna	short asdrecord_copy
	mov	cx,14h
asdrecord_copy:
	push	ds
	push	di
	lea	di,[bx+208h]
	pop	ds
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	pop	ds
	pop	si
	pop	di
	leave
	retf
AsdSetRecord endp

; Publish a record within the allocated update area.
	public ConfigWriteRecords
ConfigWriteRecords proc far
	push	bp
	mov	bp,sp
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	mov	eax,[bp+0eh]
	add	eax,[bp+0ah]
	cmp	eax,43ah
	ja	short cfgpublish_done
	push	dword ptr [bp+0eh]
	push	dword ptr [bp+0ah]
	push	dword ptr [bp+6]
	call	far ptr ConfigWriteRecord
	add	sp,0ch
cfgpublish_done:
	pop	ds
	leave
	retf
ConfigWriteRecords endp

; Append a filename to the configuration directory.
	public AsdJoinPath
AsdJoinPath proc far
	enter	4,0
	push	di
	push	si
	push	ds
	mov	ax,DGROUP
	mov	ds,ax
	les	di,dword ptr [bp+0ah]
	push	ax
	lds	si,dword ptr [bp+6]
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	mov	bx,ax
	mov	di,ax
	mov	es,dx
	mov	cx,0ffffh
	xor	ax,ax
	repne	scasb
	not	cx
	dec	cx
	add	bx,cx
	mov	[bp-4],bx
	mov	ds,dx
	cmp	bx,[bp+6]
	jna	short asdjoinpath_append
	cmp	byte ptr [bx-1],5ch
	jz	short asdjoinpath_append
	mov	byte ptr [bx],5ch
	inc	word ptr [bp-4]
asdjoinpath_append:
	mov	bx,[bp-4]
	push	ds
	mov	si,bx
	les	di,dword ptr [bp+0eh]
	mov	cx,0ffffh
	repne	scasb
	not	cx
	sub	di,cx
	xchg	di,si
	push	ds
	push	es
	pop	ds
	pop	es
	shr	cx,1
	rep	movsw
	adc	cx,cx
	rep	movsb
	pop	ds
	mov	ax,[bp+6]
	mov	dx,[bp+8]
	pop	ds
	pop	si
	pop	di
	leave
	retf
	nop
AsdJoinPath endp

SysResume ends
	end
