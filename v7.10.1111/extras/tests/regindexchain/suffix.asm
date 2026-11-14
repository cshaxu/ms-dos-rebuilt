
RegGetDataBlock proc far
	push bp
	mov bp,sp
	les bx,[bp+0Eh]
	mov word ptr es:[bx],offset TestBlock
	mov word ptr es:[bx+2],ds
	xor ax,ax
	xor dx,dx
	pop bp
	ret
RegGetDataBlock endp
RegLoadKey proc far
	mov ax,4C01h
	int 21h
RegLoadKey endp
RegAllocateRecord proc far
	mov ax,4C01h
	int 21h
RegAllocateRecord endp
RegDirtyKeyBlock proc far
	mov ax,4C01h
	int 21h
RegDirtyKeyBlock endp
RegMaintainCache proc far
	mov ax,4C01h
	int 21h
RegMaintainCache endp
RegDirtyDataBlock proc far
	inc DirtyCount
	ret
RegDirtyDataBlock endp
CheckSP macro
	cmp sp,SavedSP
	jne failed
endm
RunIndex macro
	mov SavedSP,sp
	push ds
	mov ax,offset TestIndex
	push ax
	push ds
	mov ax,offset TestBlock
	push ax
	call RegIndexBlock
	add sp,8
	CheckSP
endm
RunGet macro
	mov SavedSP,sp
	push ds
	mov ax,offset Result
	push ax
	push ds
	mov ax,offset TestKey
	push ax
	push ds
	mov ax,offset TestFile
	push ax
	call RegGetKeyRecord
	add sp,12
	CheckSP
endm
RunFree macro
	mov SavedSP,sp
	push 0
	push 2
	push ds
	mov ax,offset TestFile
	push ax
	call RegFreeRecordId
	add sp,8
	CheckSP
endm
RunAssign macro
	mov SavedSP,sp
	push ds
	mov ax,offset TestBlock
	push ax
	call RegAssignRecordId
	add sp,4
	CheckSP
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr TestBlock+4,2Ch
	mov word ptr TestBlock+6,0
	mov word ptr TestBlock+14h,2
	mov word ptr TestBlock+16h,2
	mov word ptr TestBlock+18h,offset TestIndex
	mov word ptr TestBlock+1Ah,ax
	mov word ptr TestBlock+20h,0Ch
	mov word ptr TestBlock+22h,0
	mov word ptr TestBlock+24h,2
	mov word ptr TestBlock+26h,0
	mov word ptr TestKey+18h,2
	mov word ptr TestKey+1Ah,0
	RunIndex
	cmp ax,1
	jne failed
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	RunGet
	or dx,ax
	jnz failed
	mov ax,offset TestBlock+20h
	cmp word ptr Result,ax
	jne failed
	mov ax,ds
	cmp word ptr Result+2,ax
	jne failed
	mov word ptr TestIndex+4,0
	RunGet
	cmp ax,3F3h
	jne failed
	or dx,dx
	jnz failed
	cmp word ptr Result,0
	jne failed
	cmp word ptr Result+2,0
	jne failed
	mov word ptr TestIndex+2,20h
	mov word ptr TestIndex+4,20h
	mov word ptr TestBlock+14h,3
	mov word ptr TestBlock+16h,0
	RunAssign
	or ax,ax
	jnz failed
	cmp word ptr TestBlock+16h,3
	jne failed
	mov word ptr TestBlock+14h,2
	mov word ptr TestBlock+16h,2
	RunFree
	cmp word ptr TestIndex+4,0
	jne failed
	cmp word ptr TestIndex+2,20h
	jne failed
	cmp word ptr TestBlock+24h,-1
	jne failed
	cmp word ptr TestBlock+26h,-1
	jne failed
	cmp DirtyCount,1
	jne failed
	RunFree
	cmp DirtyCount,1
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
