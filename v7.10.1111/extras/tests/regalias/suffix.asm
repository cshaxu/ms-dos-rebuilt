
RegAllocate proc far
	mov ax,offset AllocatedName
	mov dx,ds
	ret
RegAllocate endp
RunAlias macro name
	mov SavedSP,sp
	push ds
	mov ax,offset Result
	push ax
	push ds
	mov ax,offset name
	push ax
	push ds
	mov ax,offset Parent
	push ax
	call RegFindAlias
	add sp,12
	cmp sp,SavedSP
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov byte ptr Parent+19h,20h
	mov word ptr Parent+24h,offset Mount
	mov word ptr Parent+26h,ax
	mov word ptr Mount+8,-1
	mov word ptr Mount+0Ah,-1
	mov word ptr Mount+14h,offset MountName
	mov word ptr Mount+16h,ax
	mov word ptr Mount+18h,198
	mov word ptr Mount+1Ah,0
	RunAlias NameGood
	or dx,ax
	jnz failed
	mov ax,offset Mount
	cmp word ptr Result,ax
	jne failed
	mov ax,ds
	cmp word ptr Result+2,ax
	jne failed
	RunAlias NameBad
	cmp ax,3F3h
	jne failed
	or dx,dx
	jnz failed
	RunAlias NameSlash
	cmp ax,3F2h
	jne failed
	or dx,dx
	jnz failed
	mov byte ptr Parent2+19h,20h
	mov word ptr Parent2+24h,-1
	mov word ptr Parent2+26h,-1
	mov word ptr File2+24h,offset KeyBlock2
	mov ax,ds
	mov word ptr File2+26h,ax
	push ds
	mov ax,offset File2
	push ax
	push ds
	mov ax,offset Mount2
	push ax
	push ds
	mov ax,offset NameNew
	push ax
	push ds
	mov ax,offset Parent2
	push ax
	call RegAddMount
	add sp,16
	or dx,ax
	jnz failed
	cmp word ptr Mount2+18h,210
	jne failed
	cmp word ptr Mount2+1Ah,0
	jne failed
	cmp byte ptr AllocatedName,'e'
	jne failed
	cmp byte ptr AllocatedName+1,'F'
	jne failed
	cmp byte ptr AllocatedName+2,'g'
	jne failed
	cmp byte ptr AllocatedName+3,0
	jne failed
	push ds
	mov ax,offset Result
	push ax
	push ds
	mov ax,offset NameNew
	push ax
	push ds
	mov ax,offset Parent2
	push ax
	call RegFindAlias
	add sp,12
	or dx,ax
	jnz failed
	mov ax,offset Mount2
	cmp word ptr Result,ax
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
