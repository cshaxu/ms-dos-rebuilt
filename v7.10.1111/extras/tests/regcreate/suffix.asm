
RegLoadKey proc far
	push bp
	mov bp,sp
	cmp AllocSuccess,0
	je short load_existing
	mov ax,[bp+6]
	cmp ax,20h
	je short load_free
	cmp ax,3Ch
	je short load_next
	mov ax,offset ParentNode
	jmp short load_done
load_free:
	mov ax,offset FreeNode
	jmp short load_done
load_next:
	mov ax,offset NextNode
	jmp short load_done
load_existing:
	mov ax,offset KeyNode
load_done:
	mov dx,ds
	pop bp
	ret
RegLoadKey endp
RegSearchPath proc far
	push bp
	mov bp,sp
	inc SearchCalls
	cmp SearchFail,0
	jne short search_missing
	les bx,[bp+12h]
	mov word ptr es:[bx],offset KeyNode
	mov es:[bx+2],ds
	xor ax,ax
	xor dx,dx
	pop bp
	ret
search_missing:
	mov ax,3F3h
	xor dx,dx
	pop bp
	ret
RegSearchPath endp
RegAllocateRecord proc far
	inc AllocCalls
	cmp AllocSuccess,0
	je short alloc_fail
	push bp
	mov bp,sp
	les bx,[bp+12h]
	mov word ptr es:[bx],1
	mov word ptr es:[bx+2],0
	xor ax,ax
	xor dx,dx
	pop bp
	ret
alloc_fail:
	mov ax,0Eh
	xor dx,dx
	ret
RegAllocateRecord endp
RegGetDataBlock proc far
	inc UnexpectedCalls
	ret
RegGetDataBlock endp
RegFreeRecordId proc far
	inc UnexpectedCalls
	ret
RegFreeRecordId endp
RegDeleteKeyTree proc far
	inc UnexpectedCalls
	ret
RegDeleteKeyTree endp
RegGrowKeyBlock proc far
	inc UnexpectedCalls
	ret
RegGrowKeyBlock endp
RegMaintainCache proc far
	inc UnexpectedCalls
	ret
RegMaintainCache endp
RegDirtyKeyBlock proc far
	inc DirtyCalls
	xor ax,ax
	xor dx,dx
	ret
RegDirtyKeyBlock endp
RunCreate macro path
	mov SavedSP,sp
	mov si,0BEEFh
	push 0
	push 0
	push ds
	push offset Result
	push ds
	push offset path
	push 0
	push 0
	push ds
	push offset FileState
	call RegCreatePath
	add sp,20
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr KeyNode-12,1
	mov word ptr KeyNode-10,0
	RunCreate PathEmpty
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyNode
	jne failed
	cmp SearchCalls,0
	jne failed
	RunCreate PathOne
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyNode
	jne failed
	cmp SearchCalls,1
	jne failed
	RunCreate PathNested
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyNode
	jne failed
	cmp SearchCalls,3
	jne failed
	mov SearchFail,1
	mov byte ptr FileState+11h,80h
	RunCreate PathOne
	cmp ax,5
	jne failed
	or dx,dx
	jnz failed
	cmp AllocCalls,0
	jne failed
	mov byte ptr FileState+11h,0
	RunCreate PathOne
	cmp ax,3F3h
	jne failed
	or dx,dx
	jnz failed
	cmp AllocCalls,1
	jne failed
	mov AllocSuccess,1
	mov word ptr FileState+24h,offset KeyBlock
	mov ax,ds
	mov word ptr FileState+26h,ax
	mov word ptr KeyBlock+4,100h
	mov word ptr KeyBlock+6,0
	mov word ptr KeyBlock+0Ch,20h
	mov word ptr KeyBlock+0Eh,0
	mov word ptr FreeNode-12,20h
	mov word ptr FreeNode-10,0
	mov word ptr FreeNode+4,38h
	mov word ptr FreeNode+6,0
	mov word ptr FreeNode+8,-1
	mov word ptr FreeNode+0Ah,-1
	mov word ptr ParentNode+10h,-1
	mov word ptr ParentNode+12h,-1
	RunCreate PathOne
	or dx,ax
	jnz failed
	cmp word ptr Result,offset FreeNode
	jne failed
	cmp word ptr FreeNode+4,198
	jne failed
	cmp word ptr FreeNode+6,0
	jne failed
	cmp word ptr ParentNode+10h,20h
	jne failed
	cmp DirtyCalls,1
	jne failed
	cmp UnexpectedCalls,0
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
