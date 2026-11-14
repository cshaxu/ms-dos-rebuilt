;** CFGMAIN.ASM - Real-mode configuration program entry.
;
	.286
	extrn	RegCloseKey:far,RegCreateKey:far,RegSetValueCore:far
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
	extrn	AsdRunOnceKey:byte,AsdWizardValue:byte,AsdWizardCommand:byte
	extrn	AsdHexDigits:byte,AsdGuidFormat:byte,AsdValueName:word
	extrn	AsdFileName:byte,AsdProblemsKey:byte
	extrn	__psp:word
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	ConfigInfoData:dword,ConfigPathBuffer:byte
	extrn	AsdPath:byte,AsdRecord:byte
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

; Queue ASD Wizard in the existing RunOnce registry key.
	public AsdScheduleWizard
AsdScheduleWizard proc far
	push bp
	mov bp,sp
	sub sp,4
	lea ax,[bp-4]
	push ss
	push ax
	mov ax,offset DGROUP:AsdRunOnceKey
	push ds
	push ax
	mov ax,2
	mov dx,08000h
	push dx
	push ax
	call far ptr RegCreateKey
	add sp,0Ch
	or dx,ax
	jnz short asdschedulewizard_done
	mov ax,0Bh
	cwd
	push dx
	push ax
	mov ax,offset DGROUP:AsdWizardCommand
	push ds
	push ax
	mov ax,1
	cwd
	push dx
	push ax
	sub ax,ax
	push ax
	push ax
	mov ax,offset DGROUP:AsdWizardValue
	push ds
	push ax
	push word ptr [bp-2]
	push word ptr [bp-4]
	call far ptr RegSetValueCore
	add sp,018h
	push word ptr [bp-2]
	push word ptr [bp-4]
	call far ptr RegCloseKey
asdschedulewizard_done:
	mov sp,bp
	pop bp
	retf
AsdScheduleWizard endp
	even

; Write the specified number of hexadecimal digits.
	public AsdFormatHex
AsdFormatHex proc far
	push bp
	mov bp,sp
	push di
	push si
	mov di,[bp+0Ah]
	mov ax,[bp+6]
	mov dx,[bp+8]
	add ax,di
	dec ax
	mov si,ax
	mov es,dx
	or di,di
	jz short asdformathex_done
asdformathex_digit:
	mov bl,[bp+0Ch]
	and bx,0Fh
	mov al,AsdHexDigits[bx]
	mov es:[si],al
	dec si
	mov ax,[bp+0Ch]
	mov dx,[bp+0Eh]
	shr dx,1
	rcr ax,1
	shr dx,1
	rcr ax,1
	shr dx,1
	rcr ax,1
	shr dx,1
	rcr ax,1
	mov [bp+0Ch],ax
	mov [bp+0Eh],dx
	dec di
	jnz short asdformathex_digit
asdformathex_done:
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
AsdFormatHex endp
	even

; Format a byte sequence as hexadecimal digits.
	public AsdFormatBytes
AsdFormatBytes proc far
	push bp
	mov bp,sp
	sub sp,0Ch
	push di
	push si
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
	sub dx,dx
	push dx
	push ax
	mov ax,2
	push ax
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
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
AsdFormatBytes endp
	even

; Join the directory and the final path component.
	public AsdJoinPath
AsdJoinPath proc far
	push bp
	mov bp,sp
	sub sp,4
	push di
	push si
	les di,[bp+0Ah]
	push ds
	lds si,[bp+6]
	mov cx,0FFFFh
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
	les di,[bp+6]
	mov cx,0FFFFh
	repne scasb
	not cx
	dec cx
	add cx,[bp+6]
	mov [bp-4],cx
	mov word ptr [bp-2],es
	cmp cx,[bp+6]
	jna short asdjoinpath_append
	mov bx,cx
	cmp byte ptr es:[bx-1],05Ch
	jz short asdjoinpath_append
	mov byte ptr es:[bx],05Ch
	inc word ptr [bp-4]
asdjoinpath_append:
	les di,[bp+0Eh]
	push ds
	lds si,[bp-4]
	mov cx,0FFFFh
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
	mov ax,[bp+6]
	mov dx,[bp+8]
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
AsdJoinPath endp
	even

; Create the problem key named by the ASD record.
	public AsdOpenProblem
AsdOpenProblem proc far
	push bp
	mov bp,sp
	sub sp,0100h
	push di
	push si
	mov si,[bp+0Eh]
	mov ax,[bp+010h]
	or ax,si
	jnz short asdopenproblem_format_guid
	jmp near ptr asdopenproblem_copy_name
asdopenproblem_format_guid:
	mov es,[bp+010h]
	push word ptr es:[si+2]
	push word ptr es:[si]
	mov ax,8
	push ax
	mov cx,offset DGROUP:AsdGuidFormat+1
	push ds
	push cx
	push cs
	call near ptr AsdFormatHex
	add sp,0Ah
	mov es,[bp+010h]
	mov ax,es:[si+4]
	sub dx,dx
	push dx
	push ax
	mov ax,4
	push ax
	mov cx,offset DGROUP:AsdGuidFormat+10
	push ds
	push cx
	push cs
	call near ptr AsdFormatHex
	add sp,0Ah
	mov es,[bp+010h]
	mov ax,es:[si+6]
	sub dx,dx
	push dx
	push ax
	mov ax,4
	push ax
	mov ax,offset DGROUP:AsdGuidFormat+15
	push ds
	push ax
	push cs
	call near ptr AsdFormatHex
	add sp,0Ah
	mov ax,2
	cwd
	push dx
	push ax
	mov ax,si
	mov dx,[bp+010h]
	add ax,8
	push dx
	push ax
	mov ax,offset DGROUP:AsdGuidFormat+20
	push ds
	push ax
	push cs
	call near ptr AsdFormatBytes
	add sp,0Ch
	mov ax,6
	cwd
	push dx
	push ax
	mov ax,si
	mov dx,[bp+010h]
	add ax,0Ah
	push dx
	push ax
	mov ax,offset DGROUP:AsdGuidFormat+25
	push ds
	push ax
	push cs
	call near ptr AsdFormatBytes
	add sp,0Ch
	mov ax,offset DGROUP:AsdGuidFormat
	push ds
	push ax
	push word ptr [bp+0Ch]
	push word ptr [bp+0Ah]
	lea ax,[bp-0100h]
	push ss
	push ax
	push cs
	call near ptr AsdJoinPath
	add sp,0Ch
	jmp short asdopenproblem_create
asdopenproblem_copy_name:
	lea si,[bp-100h]
	push ds
	les di,[bp+0Ah]
	mov cx,0FFFFh
	xor ax,ax
	repne scasb
	not cx
	sub di,cx
	xchg di,si
	push ds
	push es
	pop ds
	pop es
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	pop ds
asdopenproblem_create:
	push word ptr [bp+8]
	push word ptr [bp+6]
	lea ax,[bp-0100h]
	push ss
	push ax
	mov ax,2
	mov dx,08000h
	push dx
	push ax
	call far ptr RegCreateKey
	add sp,0Ch
	or dx,ax
	jz short asdopenproblem_created
	les bx,[bp+6]
	sub ax,ax
	mov es:[bx+2],ax
	mov es:[bx],ax
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
asdopenproblem_created:
	mov ax,1
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
AsdOpenProblem endp
	even

; Import the ASD boot record and remove the file after processing.
	public AsdImport
AsdImport proc far
	push bp
	mov bp,sp
	sub sp,010Ch
	push di
	push si
	mov word ptr [bp-8],0FFFFh
	mov byte ptr [bp-0Ah],0
	mov ax,AsdValueName
	mov [bp-010Ah],ax
	xor ax,ax
	mov cx,07Fh
	lea di,[bp-0108h]
	push ss
	pop es
	rep stosw
	mov ax,offset DGROUP:AsdFileName
	push ds
	push ax
	push word ptr ConfigWindowsPath+2
	push word ptr ConfigWindowsPath
	mov ax,offset DGROUP:AsdPath
	push ds
	push ax
	push cs
	call near ptr AsdJoinPath
	add sp,0Ch
	and byte ptr AsdPath,07Fh
	push si
	mov si,offset DGROUP:AsdPath
	mov bx,010h
	mov dx,1
	mov ax,06C00h
	mov cx,6
	push bp
	int 021h
	pop bp
	jc short asdimport_opened
	mov [bp-8],ax
asdimport_opened:
	pop si
	cmp word ptr [bp-8],-1
	jnz short asdimport_check_handle
	jmp near ptr asdimport_done
asdimport_check_handle:
	mov ah,03Fh
	mov bx,[bp-8]
	mov cx,0118h
	mov dx,offset DGROUP:AsdRecord
	push bp
	int 021h
	pop bp
	jc short asdimport_read
	cmp ax,0118h
	jz short asdimport_read
	stc
asdimport_read:
	pushf
	mov ax,03E00h
	mov bx,[bp-8]
	push bp
	int 021h
	pop bp
	popf
	jc short asdimport_close_file
	mov byte ptr [bp-0Ah],1
asdimport_close_file:
	cmp byte ptr [bp-0Ah],0
	jnz short asdimport_read_result
	jmp near ptr asdimport_done
asdimport_read_result:
	mov ax,offset DGROUP:AsdRecord
	push ds
	push ax
	mov ax,offset DGROUP:AsdProblemsKey
	push ds
	push ax
	lea ax,[bp-4]
	push ss
	push ax
	push cs
	call near ptr AsdOpenProblem
	add sp,0Ch
	or ax,ax
	jnz short asdimport_create_key
	jmp near ptr asdimport_remove_file
asdimport_create_key:
	mov ax,word ptr AsdRecord+20
	mov dx,word ptr AsdRecord+22
	or dx,dx
	jnz short asdimport_write_value
	cmp ax,0100h
	jna short asdimport_limit_length
asdimport_write_value:
	mov ax,0100h
asdimport_limit_length:
	mov [bp-010Ch],ax
	mov cx,ax
	lea di,[bp-010Ah]
	mov si,offset DGROUP:AsdRecord+24
	mov ax,ss
	mov es,ax
	shr cx,1
	rep movsw
	adc cx,cx
	rep movsb
	mov ax,word ptr AsdRecord+20
	or dx,dx
	jnz short asdimport_copy_data
	cmp ax,0100h
	jna short asdimport_limit_name
asdimport_copy_data:
	xor dx,dx
	mov ax,0100h
asdimport_limit_name:
	mov si,ax
	mov byte ptr [bp+si-010Ah],0
	cmp word ptr AsdRecord+22,0
	jnz short asdimport_end_name
	cmp word ptr AsdRecord+20,0100h
	jna short asdimport_set_value
asdimport_end_name:
	mov byte ptr [bp-010h],02Dh
	mov ax,word ptr AsdRecord+278
	sub dx,dx
	push dx
	push ax
	mov ax,4
	push ax
	lea ax,[bp-0Eh]
	push ss
	push ax
	push cs
	call near ptr AsdFormatHex
	add sp,0Ah
asdimport_set_value:
	mov byte ptr [bp-6],2
	mov ax,1
	cwd
	push dx
	push ax
	lea ax,[bp-6]
	push ss
	push ax
	mov ax,3
	cwd
	push dx
	push ax
	sub ax,ax
	push ax
	push ax
	lea ax,[bp-010Ah]
	push ss
	push ax
	push word ptr [bp-2]
	push word ptr [bp-4]
	call far ptr RegSetValueCore
	add sp,018h
	push word ptr [bp-2]
	push word ptr [bp-4]
	call far ptr RegCloseKey
	add sp,4
	push cs
	call near ptr AsdScheduleWizard
asdimport_remove_file:
	mov ah,041h
	mov dx,offset DGROUP:AsdPath
	push bp
	int 021h
	pop bp
	mov ax,2
	push ax
	push cs
	call near ptr ConfigSetError
	add sp,2
asdimport_done:
	pop si
	pop di
	mov sp,bp
	pop bp
	retf
AsdImport endp
	even

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
	cmp	word ptr ConfigReturnCode,0
	jnz	short cfgmain_terminate
	push	cs
	call	near ptr AsdImport
cfgmain_terminate:
	call	far ptr RegTerminate
	call	far ptr ConfigPublishData
	mov	ax,ConfigReturnCode
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	ret
_main	endp
	nop
CFGMAIN	ends
	end
