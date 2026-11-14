
RegLoadKey proc far
	mov ax,offset KeyNode
	mov dx,ds
	ret
RegLoadKey endp
RegGetKeyRecord proc far
	push bp
	mov bp,sp
	les bx,[bp+0Eh]
	mov word ptr es:[bx],offset KeyRecord
	mov es:[bx+2],ds
	mov ax,GetStatus
	xor dx,dx
	pop bp
	ret
RegGetKeyRecord endp
RegDirtyKeyBlock proc far
	inc DirtyCalls
	xor ax,ax
	xor dx,dx
	ret
RegDirtyKeyBlock endp
__aFulshr proc far
	movzx eax,ax
	movzx edx,dx
	shl edx,16
	or eax,edx
	shr eax,cl
	mov edx,eax
	shr edx,16
	ret
__aFulshr endp
__aFlshl proc far
	movzx eax,ax
	movzx edx,dx
	shl edx,16
	or eax,edx
	shl eax,cl
	mov edx,eax
	shr edx,16
	ret
__aFlshl endp
RunHash macro
	mov SavedSP,sp
	mov si,0BEEFh
	mov di,0CAFEh
	push ds
	push offset FileState
	call RegRebuildNameHashes
	add sp,4
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
	cmp di,0CAFEh
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr FileState+24h,offset KeyBlock
	mov word ptr FileState+26h,ax
	mov word ptr KeyBlock+4,3Ch
	mov word ptr KeyBlock+6,0
	mov word ptr KeyNode+18h,1
	mov word ptr KeyNode+1Ah,0
	mov word ptr KeyRecord+0Ch,3
	RunHash
	cmp word ptr KeyNode+4,198
	jne failed
	cmp word ptr KeyNode+6,0
	jne failed
	cmp byte ptr RegPathBuffer,055h
	jne failed
	cmp DirtyCalls,1
	jne failed
	mov byte ptr KeyRecord+15h,80h
	RunHash
	cmp word ptr KeyNode+4,132
	jne failed
	mov word ptr GetStatus,1
	mov word ptr KeyNode+4,0ABCDh
	RunHash
	cmp word ptr KeyNode+4,0ABCDh
	jne failed
	cmp DirtyCalls,3
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
