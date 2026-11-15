;** CPATH.ASM - Configuration path preparation
;
; FAR C entry: caller supplies a FAR pointer to a 64-byte path buffer.
; Query INT 2Fh/1613h, check the returned path, and empty it on failure.
;
SysResume segment byte public 'RESUME_CODE'
	assume cs:SysResume
	public ConfigPreparePath

ConfigPreparePath	proc	far
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	si
	push	di
	push	bx
	les	di,[bp+6]
	mov	cx,40h
	mov	ax,1613h
	int	2Fh
	or	ax,ax
	jnz	short cp_fail
	mov	cx,7
	push	ds
	lds	dx,[bp+6]
	mov	ah,4Eh
	int	21h
	pop	ds
	jnc	short cp_exit
cp_fail:
	les	di,[bp+6]
	mov	byte ptr es:[di],0
cp_exit:
	pop	bx
	pop	di
	pop	si
	pop	es
	pop	ds
	pop	bp
	retf
ConfigPreparePath	endp
	db 0

SysResume ends

; Link the startup image between resume code and initialized data.
IMAGE001 segment para public 'IMAGE'
IMAGE001 ends
	end
