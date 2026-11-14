
RegValidateKeyHandle proc far
	push bp
	mov bp,sp
	les bx,[bp+0Ah]
	mov word ptr es:[bx],offset Handle
	mov es:[bx+2],ds
	xor ax,ax
	xor dx,dx
	pop bp
	ret
RegValidateKeyHandle endp
RegOpenPath proc far
	push bp
	mov bp,sp
	les bx,[bp+12h]
	mov word ptr es:[bx],offset Key
	mov es:[bx+2],ds
	xor ax,ax
	xor dx,dx
	pop bp
	ret
RegOpenPath endp
RegGetKeyRecord proc far
	push bp
	mov bp,sp
	les bx,[bp+0Eh]
	mov word ptr es:[bx],offset KeyRecord
	mov es:[bx+2],ds
	xor ax,ax
	xor dx,dx
	pop bp
	ret
RegGetKeyRecord endp
RunQuery macro name,dataseg,dataoff
	mov SavedSP,sp
	push ds
	push offset SizeOut
	push dataseg
	push dataoff
	push ds
	push offset TypeOut
	push ds
	push offset name
	push 0
	push 0
	push 0
	push 0
	call RegQueryValueCore
	add sp,24
	cmp sp,SavedSP
	jne failed
endm
BufferOff equ offset Buffer
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr Handle+0Ch,offset FileState
	mov word ptr Handle+0Eh,ax
	mov word ptr KeyRecord+0Eh,1
	mov word ptr SizeOut,1
	mov word ptr SizeOut+2,0
	RunQuery NameGood,ds,BufferOff
	cmp ax,0EAh
	jne failed
	or dx,dx
	jnz failed
	cmp word ptr TypeOut,2
	jne failed
	cmp word ptr SizeOut,2
	jne failed
	cmp byte ptr Buffer,055h
	jne failed
	mov word ptr SizeOut,2
	RunQuery NameGood,ds,BufferOff
	or dx,ax
	jnz failed
	cmp byte ptr Buffer,'X'
	jne failed
	cmp byte ptr Buffer+1,'Y'
	jne failed
	cmp word ptr SizeOut,2
	jne failed
	mov word ptr Value,1
	mov word ptr SizeOut,3
	mov byte ptr Buffer+2,055h
	RunQuery NameGood,ds,BufferOff
	or dx,ax
	jnz failed
	cmp byte ptr Buffer+2,0
	jne failed
	cmp word ptr SizeOut,3
	jne failed
	mov word ptr TypeOut,0CCDDh
	mov word ptr TypeOut+2,0AABBh
	mov word ptr SizeOut,8
	RunQuery NameBad,ds,BufferOff
	cmp ax,3F4h
	jne failed
	cmp word ptr TypeOut,0CCDDh
	jne failed
	cmp word ptr TypeOut+2,0AABBh
	jne failed
	mov word ptr SizeOut,0
	RunQuery NameGood,0,0
	or dx,ax
	jnz failed
	cmp word ptr SizeOut,3
	jne failed
	mov word ptr TypeOut,0
	mov word ptr SizeOut,8
	mov byte ptr Buffer,055h
	RunQuery NameEmpty,ds,BufferOff
	or dx,ax
	jnz failed
	cmp word ptr TypeOut,1
	jne failed
	cmp word ptr SizeOut,1
	jne failed
	cmp byte ptr Buffer,0
	jne failed
	mov word ptr Value,2
	mov byte ptr Value+0Fh,'X'
	mov byte ptr Value+10h,'Y'
	mov word ptr SizeOut,2
	RunQuery NameGood,ds,OverlapOff
	or dx,ax
	jnz failed
	cmp byte ptr Value+10h,'X'
	jne failed
	cmp byte ptr Value+11h,'Y'
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
