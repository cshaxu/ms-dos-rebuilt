	mov sp,bp
	pop bp
	ret
AllocStore endp
ResizeStore proc near
	push bp
	mov bp,sp
	sub sp,20h
	mov word ptr [bp-0Ch],offset TestBlock+20h
	mov word ptr [bp-0Ah],ds
	mov word ptr [bp-01Ah],offset TestBlock
	mov word ptr [bp-018h],ds
