
RunIndex macro expected
	mov SavedSP,sp
	mov si,0BEEFh
	push ds
	mov ax,offset TestIndex
	push ax
	push ds
	mov ax,offset TestBlock
	push ax
	call RegIndexBlock
	add sp,8
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
	cmp ax,expected
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr TestBlock+4,2Ch
	mov word ptr TestBlock+6,0
	mov word ptr TestBlock+20h,0Ch
	mov word ptr TestBlock+22h,0
	mov word ptr TestBlock+24h,2
	mov word ptr TestBlock+26h,0
	RunIndex 1
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	mov word ptr TestBlock+4,38h
	mov word ptr TestBlock+2Ch,0Ch
	mov word ptr TestBlock+2Eh,0
	mov word ptr TestBlock+30h,3
	mov word ptr TestBlock+32h,0
	RunIndex 1
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp word ptr TestIndex+6,2Ch
	jne failed
	mov word ptr TestBlock+4,2Ch
	mov word ptr TestIndex+4,0
	mov word ptr TestIndex+2,7777h
	mov word ptr TestBlock+20h,0
	RunIndex 0
	cmp word ptr TestBlock+20h,0
	jne failed
	cmp word ptr TestBlock+4,2Ch
	jne failed
	cmp word ptr TestIndex+4,0
	jne failed
	cmp word ptr TestIndex+2,0
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	mov word ptr TestBlock+20h,0Dh
	RunIndex 0
	cmp word ptr TestBlock+20h,0Dh
	jne failed
	mov word ptr TestBlock+20h,0Ch
	mov word ptr TestBlock+22h,1
	RunIndex 0
	cmp word ptr TestBlock+22h,1
	jne failed
	mov word ptr TestBlock+22h,0
	mov word ptr TestBlock+24h,0FEh
	RunIndex 1
	cmp word ptr TestIndex+1FCh,20h
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	mov word ptr TestBlock+24h,0FFh
	RunIndex 0
	cmp word ptr TestBlock+24h,0FFh
	jne failed
	mov word ptr TestBlock+24h,-1
	mov word ptr TestBlock+26h,-1
	RunIndex 1
	cmp word ptr TestIndex+4,0
	jne failed
	mov word ptr TestBlock+4,20h
	mov word ptr TestIndex+2,7777h
	RunIndex 1
	cmp word ptr TestIndex+2,0
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGFILE ends
 end start
