
RegLoadKey proc far
	push bp
	mov bp,sp
	mov ax,[bp+6]
	cmp ax,0
	jne short load_one
	mov ax,offset RootKey
	jmp short load_done
load_one:
	cmp ax,1
	jne short load_two
	mov ax,offset KeyOne
	jmp short load_done
load_two:
	mov ax,offset KeyTwo
load_done:
	mov dx,ds
	pop bp
	ret
RegLoadKey endp
RegGetKeyRecord proc far
	push bp
	mov bp,sp
	les bx,[bp+0Eh]
	mov ax,[bp+0Ah]
	cmp ax,offset KeyOne
	jne short get_two
	mov ax,offset RecordOne
	jmp short get_done
get_two:
	mov ax,offset RecordTwo
get_done:
	mov es:[bx],ax
	mov ax,ds
	mov es:[bx+2],ax
	xor ax,ax
	xor dx,dx
	pop bp
	ret
RegGetKeyRecord endp
RunSearch macro path
	mov SavedSP,sp
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
	call RegSearchPath
	add sp,20
	cmp sp,SavedSP
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr FileState+24h,offset KeyBlock
	mov word ptr FileState+26h,ax
	mov word ptr KeyBlock+4,3
	mov word ptr KeyBlock+6,0
	mov word ptr RootKey+10h,1
	mov word ptr RootKey+12h,0
	mov word ptr KeyOne+4,198
	mov word ptr KeyOne+6,0
	mov word ptr KeyOne+10h,2
	mov word ptr KeyOne+12h,0
	mov word ptr KeyOne+14h,-1
	mov word ptr KeyOne+16h,-1
	mov word ptr KeyTwo+4,207
	mov word ptr KeyTwo+6,0
	mov word ptr KeyTwo+10h,-1
	mov word ptr KeyTwo+12h,-1
	mov word ptr KeyTwo+14h,-1
	mov word ptr KeyTwo+16h,-1
	mov word ptr RecordOne+0Ch,3
	mov byte ptr RecordOne+14h,'A'
	mov byte ptr RecordOne+15h,'b'
	mov byte ptr RecordOne+16h,'C'
	mov word ptr RecordTwo+0Ch,3
	mov byte ptr RecordTwo+14h,'D'
	mov byte ptr RecordTwo+15h,'e'
	mov byte ptr RecordTwo+16h,'F'
	RunSearch PathOne
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyOne
	jne failed
	RunSearch PathTwo
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyTwo
	jne failed
	RunSearch PathBad
	cmp ax,3F3h
	jne failed
	or dx,dx
	jnz failed
	RunSearch PathInvalid
	cmp ax,3F2h
	jne failed
	or dx,dx
	jnz failed
	mov word ptr KeyOne+4,132
	mov byte ptr RecordOne+15h,80h
	RunSearch PathHigh
	or dx,ax
	jnz failed
	cmp word ptr Result,offset KeyOne
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
_TEXT ends
 end start
