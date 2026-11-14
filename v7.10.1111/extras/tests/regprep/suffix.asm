
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
RegAllocate proc far
	mov ax,offset WorkBuffer
	mov dx,ds
	ret
RegAllocate endp
RegLoadKey proc far
	mov ax,offset KeyNode
	mov dx,ds
	ret
RegLoadKey endp
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
ConfigCreate proc far
	cmp CreateFail,0
	jne short create_fail
	mov ax,5
	xor dx,dx
	ret
create_fail:
	mov ax,-1
	cwd
	ret
ConfigCreate endp
ConfigWriteAll proc far
	push bp
	mov bp,sp
	inc WriteCalls
	cmp WriteCalls,2
	jne short write_done
	les bx,[bp+8]
	mov ax,es:[bx+24h]
	mov word ptr SavedHash,ax
	mov ax,es:[bx+26h]
	mov word ptr SavedHash+2,ax
write_done:
	xor ax,ax
	xor dx,dx
	pop bp
	ret
ConfigWriteAll endp
ConfigSeek proc far
	xor ax,ax
	xor dx,dx
	ret
ConfigSeek endp
ConfigClose proc far
	inc CloseCalls
	xor ax,ax
	xor dx,dx
	ret
ConfigClose endp
ConfigDelete proc far
	inc DeleteCalls
	xor ax,ax
	xor dx,dx
	ret
ConfigDelete endp
ConfigFree proc far
	inc FreeCalls
	xor ax,ax
	xor dx,dx
	ret
ConfigFree endp
RunPrep macro
	mov SavedSP,sp
	mov si,0BEEFh
	mov di,0CAFEh
	push ds
	push offset FileName
	push 0
	push 0
	call RegPrepareSaveFile
	add sp,8
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
	cmp di,0CAFEh
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov word ptr Handle+0Ch,offset FileState
	mov word ptr Handle+0Eh,ax
	mov word ptr KeyRecord+0Ch,3
	RunPrep
	or dx,ax
	jnz failed
	cmp WriteCalls,3
	jne failed
	cmp CloseCalls,1
	jne failed
	cmp DeleteCalls,0
	jne failed
	cmp FreeCalls,1
	jne failed
	cmp word ptr SavedHash,198
	jne failed
	cmp word ptr SavedHash+2,0
	jne failed
	mov RegIOInhibit,1
	RunPrep
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	mov RegIOInhibit,0
	mov CreateFail,1
	RunPrep
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp FreeCalls,2
	jne failed
	cmp WriteCalls,3
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGFINAL ends
 end start
