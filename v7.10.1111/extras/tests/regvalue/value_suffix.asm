
RunValue macro name
	mov SavedSP,sp
	mov di,0BEEFh
	push ds
	push offset name
	push ds
	push offset KeyRecord
	call RegFindValue
	add sp,8
	cmp sp,SavedSP
	jne failed
	cmp di,0BEEFh
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr KeyRecord+0Eh,3
	RunValue NameGood
	cmp ax,offset NamedValue
	jne failed
	mov bx,ds
	cmp dx,bx
	jne failed
	cmp byte ptr RegPathBuffer,055h
	jne failed
	RunValue NameThird
	cmp ax,offset ThirdValue
	jne failed
	RunValue NameBad
	cmp ax,-1
	jne failed
	cmp dx,-1
	jne failed
	RunValue NameEmpty
	cmp ax,offset DefaultValue
	jne failed
	mov word ptr DefaultValue,4
	RunValue NameEmpty
	cmp ax,offset DefaultValue
	jne failed
	xor ax,ax
	push ax
	push ax
	push ds
	push offset KeyRecord
	call RegFindValue
	add sp,8
	cmp ax,offset DefaultValue
	jne failed
	mov byte ptr NamedValue+0Dh,80h
	RunValue NameHigh
	cmp ax,offset NamedValue
	jne failed
	mov word ptr KeyRecord+0Eh,0
	RunValue NameGood
	cmp ax,-1
	jne failed
	cmp dx,-1
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
