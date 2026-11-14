	mov sp,bp
	pop bp
	ret
ResizeStore endp
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr TestBlock+18h,offset TestIndex
	mov word ptr TestBlock+1Ah,ax
	mov word ptr TestBlock+24h,2
	mov word ptr TestIndex+2,4444h
	call AllocStore
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp word ptr TestIndex+2,4444h
	jne failed
	mov word ptr TestIndex+4,0
	call ResizeStore
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp word ptr TestIndex+2,4444h
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGKEYS ends
 end start
