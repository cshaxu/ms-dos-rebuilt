DOS7_CONFIG equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 3b88h
pararound proc near
 ret
pararound endp
 org 66d4h
DevLoadEnd dw 0
 org 66dah
DevBrkAddr dd 0
 org 81fdh
low_memory_error: ret
 org 8207h
RoundBreakAddr	proc	near

		assume	ds:nothing, es:nothing

		mov	ax, word ptr DevBrkAddr
		call	pararound
		add	word ptr DevBrkAddr+2, ax
		mov	word ptr DevBrkAddr, 0
		mov	ax, DevLoadEnd
		cmp	word ptr DevBrkAddr+2, ax
		jbe	rba_ok
IFDEF DOS7_CONFIG
		jmp	low_memory_error
ELSE
		jmp	mem_err
ENDIF
rba_ok:
		ret
RoundBreakAddr	endp
sysinitseg ends
end
