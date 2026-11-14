
ConfigAlloc proc far
	inc AllocCount
	mov ax,offset TestBlock
	cmp AllocCount,1
	je alloc_done
	mov ax,offset TestIndex
alloc_done:
	mov dx,ds
	ret
ConfigAlloc endp
ConfigFree proc far
	inc FreeCount
	ret
ConfigFree endp
ConfigSeek proc far
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
ConfigReadAll proc far
	inc ReadCount
	cmp ReadFail,0
	jne read_fail
	mov word ptr TestBlock,4752h
	mov word ptr TestBlock+2,4244h
	mov word ptr TestBlock+4,44
	mov word ptr TestBlock+6,0
	mov word ptr TestBlock+20h,12
	mov word ptr TestBlock+22h,0
	mov word ptr TestBlock+24h,2
	mov word ptr TestBlock+26h,0
	cmp IndexValid,0
	jne read_check_header
	mov word ptr TestBlock+20h,0
read_check_header:
	cmp ValidateOK,0
	jne read_success
	mov word ptr TestBlock,0
read_success:
	xor ax,ax
	xor dx,dx
	ret
read_fail:
	mov ax,-1
	mov dx,ax
	ret
ConfigReadAll endp
ConfigOpen proc far
	xor ax,ax
	ret
ConfigOpen endp
ConfigClose proc far
	ret
ConfigClose endp
RegNotifyLoad proc far
	ret
RegNotifyLoad endp
RegInvalidBlock proc far
	mov ax,4C01h
	int 21h
RegInvalidBlock endp
RegMaintainCache proc far
	ret
RegMaintainCache endp
RunRead macro mode
	mov SeekMode,mode
	mov AllocCount,0
	mov ReadCount,0
	mov FreeCount,0
	mov word ptr TestCache,-1
	mov word ptr TestCache+2,-1
	mov byte ptr TestFile+10h,0
	mov SavedSP,sp
	mov si,0BEEFh
	mov di,0CAFEh
	push 5
	push 0
	push ds
	mov ax,offset TestFile
	push ax
	call RegLoadDataBlock
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
	mov TestFile+2Ah,ax
	mov word ptr TestFile+28h,offset TestCache
	mov word ptr TestFile+0Eh,1
	mov word ptr TestBlock+4,44
	RunRead 0
	or dx,ax
	jnz failed
	cmp ReadCount,1
	jne failed
	cmp FreeCount,0
	jne failed
	cmp word ptr TestCache,offset TestBlock
	jne failed
	cmp word ptr TestIndex+4,20h
	jne failed
	cmp IndexGuard,0A55Ah
	jne failed
	RunRead 1
	call CheckFailure
	RunRead 2
	call CheckFailure
	RunRead 3
	call CheckFailure
	mov ReadFail,1
	RunRead 0
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,1
	jne failed
	cmp FreeCount,2
	jne failed
	mov ReadFail,0
	mov IndexValid,0
	RunRead 0
	cmp ax,3F1h
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,1
	jne failed
	cmp FreeCount,2
	jne failed
	test byte ptr TestFile+10h,8
	jz failed
	mov IndexValid,1
	mov ValidateOK,0
	RunRead 0
	cmp ax,3F1h
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,1
	jne failed
	cmp FreeCount,2
	jne failed
	test byte ptr TestFile+10h,8
	jz failed
	mov ValidateOK,1
	mov word ptr TestFile+0Eh,0
	RunRead 0
	cmp ax,3F1h
	jne failed
	cmp ReadCount,0
	jne failed
	cmp FreeCount,0
	jne failed
	mov ax,4C00h
	int 21h
CheckFailure proc near
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,0
	jne failed
	cmp FreeCount,2
	jne failed
	test byte ptr TestFile+10h,20h
	jz failed
	ret
CheckFailure endp
failed:
	mov ax,4C01h
	int 21h
REGFILE ends
 end start
