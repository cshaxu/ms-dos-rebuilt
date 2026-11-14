
regread_read_loc_46E:
	xor ax,ax
	jmp short open_done
regread_read_loc_297:
	mov ax,[bp-04Ch]
open_done:
	xor dx,dx
	mov sp,bp
	pop bp
	ret
OpenSeek endp
ConfigSeek proc far
	inc SeekCount
	cmp SeekMode,1
	je seek_fail
	mov ax,1234h
	mov dx,12h
	cmp SeekMode,2
	jne check_high
	inc ax
check_high:
	cmp SeekMode,3
	jne seek_success
	inc dx
seek_success:
	clc
	ret
seek_fail:
	stc
	ret
ConfigSeek endp
RunTest macro mode,flag,expected,calls
	mov SeekMode,mode
	mov SeekCount,0
	mov byte ptr TestFile+11h,flag
	mov SavedSP,sp
	push ds
	mov ax,offset TestFile
	push ax
	push 0
	push 0
	call OpenSeek
	add sp,8
	cmp sp,SavedSP
	jne failed
	cmp ax,expected
	jne failed
	or dx,dx
	jnz failed
	cmp SeekCount,calls
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	RunTest 0,0,0,1
	RunTest 1,0,3F8h,1
	RunTest 2,0,3F8h,1
	RunTest 3,0,3F8h,1
	RunTest 1,1,0,0
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGFILE ends
 end start
