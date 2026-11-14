;** RQVALUE - Registry value API wrappers and check policy
;
; FAR C entries dispatch to the Windows registry provider when present,
; otherwise to the local core. Provider calls use their own argument order.
;
	.286
	extrn	RegQueryValueCore:far
	extrn	RegVMQueryValue:far
	extrn	RegVMQueryValueEx:far
	extrn	RegSetValueCore:far
	extrn	RegVMSetValue:far
	extrn	RegVMSetValueEx:far

_DATA	segment	word public 'DATA'
_DATA	ends
c_common	segment	word public 'BSS'
c_common	ends
REGWRAP	segment	word public 'CODE'
REGWRAP	ends
DGROUP	group	_DATA,c_common
_DATA	segment	word public 'DATA'
	extrn	RegCheckPolicy:word
_DATA	ends
c_common	segment	word public 'BSS'
	extrn	RegVMEntry:dword
c_common	ends
REGWRAP	segment	word public 'CODE'
	assume	cs:REGWRAP,ds:DGROUP
	public	RegQueryValue

;** RegQueryValue - Query a subkey's default value
;
; ENTRY: [BP+6] = key, [BP+0Ah] = FAR subkey name,
;        [BP+0Eh] = FAR data buffer, [BP+12h] = FAR size address.
; EXIT:  DX:AX = status from the selected provider.
;
RegQueryValue	proc	far
	push	bp
	mov	bp,sp
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rqvalue_alue_loc_02B
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	call	far ptr RegVMQueryValue
	jmp	short rqvalue_alue_loc_04E
rqvalue_alue_loc_02B:
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	sub	ax,ax
	push	ax
	push	ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegQueryValueCore
rqvalue_alue_loc_04E:
	mov	sp,bp
	pop	bp
	ret
RegQueryValue	endp
	assume	cs:REGWRAP,ds:DGROUP
	public	RegQueryValueEx

;** RegQueryValueEx - Query a named value
;
; ENTRY: [BP+6] = key, [BP+0Ah] = FAR value name,
;        [BP+0Eh] = reserved, [BP+12h] = FAR type address,
;        [BP+16h] = FAR data buffer, [BP+1Ah] = FAR size address.
; EXIT:  DX:AX = status from the selected provider.
;
RegQueryValueEx	proc	far
	push	bp
	mov	bp,sp
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rqvalex_alex_loc_037
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	call	far ptr RegVMQueryValueEx
	jmp	short rqvalex_alex_loc_05E
rqvalex_alex_loc_037:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegQueryValueCore
rqvalex_alex_loc_05E:
	mov	sp,bp
	pop	bp
	ret
RegQueryValueEx	endp
	assume	cs:REGWRAP,ds:DGROUP
	public	RegSetValueAPI

;** RegSetValueAPI - Set a subkey's default value
;
; ENTRY: [BP+6] = key, [BP+0Ah] = FAR subkey name,
;        [BP+0Eh] = DWORD type, [BP+12h] = FAR data,
;        [BP+16h] = DWORD data size.
; EXIT:  DX:AX = status from the selected provider.
;
RegSetValueAPI	proc	far
	push	bp
	mov	bp,sp
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rsvalue_alue_loc_031
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	call	far ptr RegVMSetValue
	jmp	short rsvalue_alue_loc_058
rsvalue_alue_loc_031:
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegSetValueCore
rsvalue_alue_loc_058:
	mov	sp,bp
	pop	bp
	ret
RegSetValueAPI	endp
	assume	cs:REGWRAP,ds:DGROUP
	public	RegSetValueEx

;** RegSetValueEx - Set a named value
;
; ENTRY: [BP+6] = key, [BP+0Ah] = FAR value name,
;        [BP+0Eh] = reserved, [BP+12h] = DWORD type,
;        [BP+16h] = FAR data, [BP+1Ah] = DWORD data size.
; EXIT:  DX:AX = status from the selected provider.
;
RegSetValueEx	proc	far
	push	bp
	mov	bp,sp
	mov	ax,word ptr RegVMEntry+2
	or	ax,word ptr RegVMEntry
	jz	short rsvalex_alex_loc_037
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	push	word ptr [bp+010h]
	push	word ptr [bp+0Eh]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	call	far ptr RegVMSetValueEx
	jmp	short rsvalex_alex_loc_05E
rsvalex_alex_loc_037:
	push	word ptr [bp+01Ch]
	push	word ptr [bp+01Ah]
	push	word ptr [bp+018h]
	push	word ptr [bp+016h]
	push	word ptr [bp+014h]
	push	word ptr [bp+012h]
	push	word ptr [bp+0Ch]
	push	word ptr [bp+0Ah]
	sub	ax,ax
	push	ax
	push	ax
	push	word ptr [bp+08h]
	push	word ptr [bp+06h]
	call	far ptr RegSetValueCore
rsvalex_alex_loc_05E:
	mov	sp,bp
	pop	bp
	ret
RegSetValueEx	endp
	assume	cs:REGWRAP,ds:DGROUP
	public	RegSetCheckPolicy

;** RegSetCheckPolicy - Set the registry block checking policy
;
; ENTRY: [BP+6] = WORD policy.
; EXIT:  AX = previous policy.
;
RegSetCheckPolicy	proc	far
	push	bp
	mov	bp,sp
	sub	sp,02h
	mov	ax,RegCheckPolicy
	mov	[bp-02h],ax
	mov	ax,[bp+06h]
	mov	RegCheckPolicy,ax
	mov	ax,[bp-02h]
	mov	sp,bp
	pop	bp
	ret
RegSetCheckPolicy	endp
	even
REGWRAP	ends
	end
