
RegAllocate proc far
	inc AllocCount
	mov ax,offset PathBuf
	cmp AllocCount,1
	je alloc_done
	mov ax,offset HeadBuf
	cmp AllocCount,2
	je alloc_done
	mov ax,offset KeyBuf
	cmp AllocCount,3
	je alloc_done
	mov ax,offset CacheBuf
alloc_done:
	mov dx,ds
	ret
RegAllocate endp
RegStringLength proc far
	mov ax,1
	ret
RegStringLength endp
RegCopyBytes proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	lds si,[bp+10]
	les di,[bp+6]
	mov cx,[bp+14]
	cld
	rep movsb
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret
RegCopyBytes endp
ConfigOpen proc far
	cmp OpenFail,0
	jne open_failed
	push bp
	mov bp,sp
	les bx,[bp+18]
	mov word ptr es:[bx],0
	pop bp
	mov ax,5
	ret
open_failed:
	mov ax,-1
	ret
ConfigOpen endp
ConfigReadAll proc far
	push bp
	mov bp,sp
	inc ReadCount
	mov ax,ReadCount
	cmp ax,ReadFail
	je read_fail
	les bx,[bp+8]
	push di
	mov di,bx
	xor ax,ax
	mov cx,16
	cld
	rep stosw
	pop di
	cmp ReadCount,1
	jne read_key
	mov word ptr es:[bx],5243h
	mov word ptr es:[bx+2],4745h
	mov word ptr es:[bx+6],1
	mov word ptr es:[bx+8],1234h
	mov word ptr es:[bx+0Ah],12h
	mov word ptr es:[bx+10h],1
	cmp HeaderMode,1
	jne check_version
	mov word ptr es:[bx],0
check_version:
	cmp HeaderMode,2
	jne check_checksum
	mov word ptr es:[bx+6],3
check_checksum:
	cmp HeaderMode,3
	jb read_ok
	mov byte ptr es:[bx+12h],4
	mov word ptr es:[bx+0Ch],09B88h
	mov word ptr es:[bx+0Eh],0B8A3h
	cmp HeaderMode,4
	jne read_ok
	inc word ptr es:[bx+0Ch]
	jmp short read_ok
read_key:
	cmp ReadCount,2
	jne read_data
	mov word ptr es:[bx],4752h
	mov word ptr es:[bx+2],4E4Bh
	mov word ptr es:[bx+10h],8
	cmp KeyValid,0
	jne read_ok
	mov word ptr es:[bx],0
	jmp short read_ok
read_data:
	mov word ptr es:[bx],4752h
	mov word ptr es:[bx+2],4244h
	mov word ptr es:[bx+4],32
	mov ax,BadDataSize
	cmp ax,2
	jne data_size
	mov word ptr es:[bx],0
	xor ax,ax
data_size:
	mov es:[bx+6],ax
read_ok:
	xor ax,ax
	xor dx,dx
	pop bp
	ret
read_fail:
	mov ax,-1
	mov dx,ax
	pop bp
	ret
ConfigReadAll endp
ConfigSeek proc far
	cmp SeekMode,1
	je seek_fail
	mov ax,1234h
	mov dx,12h
	cmp SeekMode,2
	jne seek_high
	inc ax
seek_high:
	cmp SeekMode,3
	jne seek_ok
	inc dx
seek_ok:
	clc
	ret
seek_fail:
	stc
	ret
ConfigSeek endp
ConfigClose proc far
	inc CloseCount
	ret
ConfigClose endp
RegReleaseFileBuffers proc far
	inc ReleaseCount
	ret
RegReleaseFileBuffers endp
RegInvalidBlock proc far
	mov ax,4C01h
	int 21h
RegInvalidBlock endp
ConfigAlloc proc far
	mov ax,4C01h
	int 21h
ConfigAlloc endp
RegInitHeader proc far
	ret
RegInitHeader endp
RegNotifyLoad proc far
	ret
RegNotifyLoad endp
RegInitKeyBlock proc far
	ret
RegInitKeyBlock endp
RegInitDataBlock proc far
	ret
RegInitDataBlock endp
RegIndexBlock proc far
	ret
RegIndexBlock endp
RegRebuildNameHashes proc far
	ret
RegRebuildNameHashes endp
RunOpen macro seek,readmode,badsize
	mov SeekMode,seek
	mov ReadFail,readmode
	mov BadDataSize,badsize
	mov AllocCount,0
	mov ReadCount,0
	mov CloseCount,0
	mov ReleaseCount,0
	push es
	push ds
	pop es
	mov di,offset TestFile
	mov cx,80
	xor ax,ax
	cld
	rep stosb
	pop es
	mov SavedSP,sp
	mov si,0BEEFh
	push ds
	mov ax,offset TestFile
	push ax
	push ds
	mov ax,offset PathName
	push ax
	call RegReadFile
	add sp,8
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
endm
CheckError macro expected,reads
	cmp ax,expected
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,reads
	jne failed
	cmp CloseCount,1
	jne failed
	cmp ReleaseCount,1
	jne failed
endm
start:
	mov ax,TESTDATA
	mov ds,ax
	RunOpen 0,0,0
	or dx,ax
	jnz failed
	cmp ReadCount,3
	jne failed
	cmp CloseCount,1
	jne failed
	cmp ReleaseCount,0
	jne failed
	RunOpen 0,1,0
	CheckError 3F8h,1
	RunOpen 0,2,0
	CheckError 3F8h,2
	RunOpen 0,3,0
	CheckError 3F8h,3
	RunOpen 1,0,0
	CheckError 3F8h,2
	RunOpen 2,0,0
	CheckError 3F8h,2
	RunOpen 3,0,0
	CheckError 3F8h,2
	RunOpen 0,0,1
	CheckError 3F1h,3
	RunOpen 0,0,2
	CheckError 3F1h,3
	mov HeaderMode,1
	RunOpen 0,0,0
	CheckError 3F1h,1
	mov HeaderMode,2
	RunOpen 0,0,0
	CheckError 3F1h,1
	mov HeaderMode,3
	RunOpen 0,0,0
	or dx,ax
	jnz failed
	cmp ReadCount,3
	jne failed
	mov HeaderMode,4
	RunOpen 0,0,0
	CheckError 3F1h,1
	mov HeaderMode,0
	mov KeyValid,0
	RunOpen 0,0,0
	CheckError 3F1h,2
	mov KeyValid,1
	mov OpenFail,1
	RunOpen 0,0,0
	cmp ax,3F8h
	jne failed
	or dx,dx
	jnz failed
	cmp ReadCount,0
	jne failed
	cmp CloseCount,0
	jne failed
	cmp ReleaseCount,1
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
REGFILE ends
 end start
