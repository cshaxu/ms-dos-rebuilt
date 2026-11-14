
RegQueryValueCore proc far
	inc CoreCalls
	mov ax,1234h
	xor dx,dx
	ret
RegQueryValueCore endp
RegVMQueryValueEx proc far
	inc ProviderCalls
	mov ax,4321h
	xor dx,dx
	ret
RegVMQueryValueEx endp
RunQuery macro dataseg,dataoff,sizeseg,sizeoff
	mov SavedSP,sp
	push sizeseg
	push sizeoff
	push dataseg
	push dataoff
	push 0
	push 0
	push 0
	push 0
	push 0
	push 0
	push 0
	push 0
	mov ax,TESTSTACK
	mov ds,ax
	call RegQueryValueEx
	push ax
	mov ax,ds
	mov bx,TESTSTACK
	cmp ax,bx
	jne failed
	mov ax,TESTDATA
	mov ds,ax
	pop ax
	add sp,24
	cmp sp,SavedSP
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	RunQuery ds,DataOff,0,0
	cmp ax,57h
	jne failed
	or dx,dx
	jnz failed
	cmp CoreCalls,0
	jne failed
	RunQuery 0,0,0,0
	cmp ax,1234h
	jne failed
	cmp CoreCalls,1
	jne failed
	RunQuery ds,DataOff,ds,SizeOff
	cmp ax,1234h
	jne failed
	cmp CoreCalls,2
	jne failed
	RunQuery 0,0,ds,SizeOff
	cmp ax,1234h
	jne failed
	cmp CoreCalls,3
	jne failed
	mov word ptr RegVMEntry,1
	RunQuery ds,DataOff,0,0
	cmp ax,57h
	jne failed
	cmp ProviderCalls,0
	jne failed
	cmp CoreCalls,3
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGWRAP ends
 end start
