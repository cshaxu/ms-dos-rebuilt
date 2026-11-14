DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 devmark_size equ 3
 org 0feah
memhi dw 0
 org 5ad5h
multdeviceflag db 0
 org 66d2h
DevLoadAddr dw 0
 org 66dah
DevBrkAddr dd 0
 org 66e5h
DevUMBFree dw 0
 org 66efh
DeviceHi db 0
 org 81efh
check_low_memory proc near
 ret
check_low_memory endp
 org 8207h
RoundBreakAddr proc near
 ret
RoundBreakAddr endp
 org 8228h
DevSetBreak	proc	near

		assume	ds:nothing, es:nothing

		push	ax

		mov	ax,word ptr [DevBrkAddr+2]  ;remove the init code
		cmp	multdeviceflag, 0
		jne	set_break_continue	    ;do not check it.
		cmp	ax, DevLoadAddr
		jne	set_break_continue	    ;if not same, then o.k.

		cmp	word ptr [DevBrkAddr],0
		je	break_failed		;[DevBrkAddr+2]=[memhi] & [DevBrkAddr]=0

set_break_continue:
		call	RoundBreakAddr
		pop	ax
		clc
		ret
break_failed:
		pop	ax
		stc
		ret
DevSetBreak	endp
DevBreak	proc	near

		assume	ds:nothing, es:nothing

		push	ds
		mov	ax, DevLoadAddr
		mov	bx, word ptr [DevBrkAddr+2]
		dec	ax			; seg of sub-arena
		mov	ds, ax
		inc	ax			; Back to Device segment
		sub	ax, bx
		neg	ax			; size of device in paras
		mov	ds:[devmark_size], ax	; store it in sub-arena
		cmp	DeviceHi, 0
		je	db_lo
		mov	DevUMBFree, bx		; update Free ptr in UMB
		jmp	short db_exit
db_lo:
		mov	memhi, bx
IFDEF DOS7_CONFIG
		call	check_low_memory
ELSE
		mov	memlo, 0
ENDIF
db_exit:
		pop	ds
		ret
DevBreak	endp
sysinitseg ends
end
