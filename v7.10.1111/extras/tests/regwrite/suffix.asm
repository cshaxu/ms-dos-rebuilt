
RegValidateDataBlock proc near
	mov ax,ValidateOK
	ret 4
RegValidateDataBlock endp
ConfigSeek proc far
	inc SeekCount
	cmp SeekMode,1
	je seek_failed
	cmp SeekMode,2
	je seek_wrong
	xor ax,ax
	xor dx,dx
	ret
seek_failed:
	stc
	ret
seek_wrong:
	mov ax,1
	xor dx,dx
	ret
ConfigSeek endp
ConfigWriteAll proc far
	push bp
	mov bp,sp
	les bx,[bp+8]
	mov al,es:[bx+0Ch]
	mov SeenFlags,al
	cmp WriteFail,0
	jne write_failed
	xor ax,ax
	xor dx,dx
	jmp short write_exit
write_failed:
	mov ax,-1
	mov dx,ax
write_exit:
	pop bp
	ret
ConfigWriteAll endp
RunWrite macro seekflag
	push ds
	mov ax,offset TestFile
	push ax
	push seekflag
	push ds
	mov ax,offset TestCache
	push ax
	push 1
	call RegWriteDataBlock
	add sp,12
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	mov TestCache+2,ax
	mov byte ptr TestBlock[0Ch],7
	RunWrite 0
	or dx,ax
	jnz failed
	cmp SeenFlags,3
	jne failed
	cmp byte ptr TestBlock[0Ch],0
	jne failed
	mov byte ptr TestBlock[0Ch],7
	mov WriteFail,1
	RunWrite 1
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp SeenFlags,3
	jne failed
	cmp byte ptr TestBlock[0Ch],3
	jne failed
	cmp SeekCount,1
	jne failed
	mov WriteFail,0
	mov SeekMode,1
	mov SeenFlags,0FFh
	mov byte ptr TestBlock[0Ch],7
	RunWrite 1
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp SeenFlags,0FFh
	jne failed
	cmp byte ptr TestBlock[0Ch],3
	jne failed
	mov SeekMode,2
	mov byte ptr TestBlock[0Ch],7
	RunWrite 1
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp SeenFlags,0FFh
	jne failed
	cmp byte ptr TestBlock[0Ch],3
	jne failed
	mov SeekMode,0
	mov ValidateOK,0
	mov SeenFlags,0FFh
	RunWrite 0
	cmp ax,3F1h
	jne failed
	cmp SeenFlags,0FFh
	jne failed
	mov RegIOInhibit,1
	RunWrite 0
	cmp ax,0A7h
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGFILE ends
 end start
