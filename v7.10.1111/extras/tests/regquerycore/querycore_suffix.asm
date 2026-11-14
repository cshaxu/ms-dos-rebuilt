
RegValidateKeyHandle proc far
	inc ValidateCalls
	mov ax,6
	xor dx,dx
	ret
RegValidateKeyHandle endp
RegOpenPath proc far
	inc UnexpectedCalls
	ret
RegOpenPath endp
RegGetKeyRecord proc far
	inc UnexpectedCalls
	ret
RegGetKeyRecord endp
RegFindValue proc far
	inc UnexpectedCalls
	ret
RegFindValue endp
RegCopyBytes proc far
	inc UnexpectedCalls
	ret
RegCopyBytes endp
start:
	mov ax,TESTDATA
	mov ds,ax
	mov SavedSP,sp
	push ds
	push offset SizeOut
	push 0
	push 0
	push ds
	push offset TypeOut
	push 0
	push 0
	push 0
	push 0
	push 0
	push 0
	call RegQueryValueCore
	add sp,24
	cmp sp,SavedSP
	jne failed
	cmp ax,6
	jne failed
	or dx,dx
	jnz failed
	cmp word ptr TypeOut,0CCDDh
	jne failed
	cmp word ptr TypeOut+2,0AABBh
	jne failed
	cmp word ptr SizeOut,5678h
	jne failed
	cmp word ptr SizeOut+2,1234h
	jne failed
	cmp ValidateCalls,1
	jne failed
	cmp UnexpectedCalls,0
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGAPI ends
 end start
