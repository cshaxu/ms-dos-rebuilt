	.386
TESTDATA segment word public use16 'DATA'
Buffer db 'ABCDEFGH'
SavedSP dw 0
TESTDATA ends
TESTOTHER segment word public use16 'DATA'
OtherBuffer db 8 dup (0)
TESTOTHER ends
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
TESTCODE segment word public use16 'CODE'
 assume cs:TESTCODE,ds:TESTDATA,ss:TESTSTACK
 extrn RegCopyBytes:far
CopyTest macro destseg,destoff,srcseg,srcoff,n
	mov SavedSP,sp
	mov si,0BEEFh
	push 0
	push n
	push srcseg
	push srcoff
	push destseg
	push destoff
	mov cx,0CAFEh
	call RegCopyBytes
	add sp,12
	cmp sp,SavedSP
	jne failed
	cmp si,0BEEFh
	jne failed
	cmp cx,0CAFEh
	jne failed
endm
Buf equ offset Buffer
Other equ offset OtherBuffer
start:
	mov ax,TESTDATA
	mov ds,ax
	CopyTest ds,Buf+1,ds,Buf,5
	cmp byte ptr Buffer+1,'A'
	jne failed
	cmp byte ptr Buffer+5,'E'
	jne failed
	CopyTest ds,Buf,ds,Buf+1,5
	cmp byte ptr Buffer,'A'
	jne failed
	cmp byte ptr Buffer+4,'E'
	jne failed
	CopyTest ds,Buf+1,ds,Buf,0
	cmp byte ptr Buffer+1,'B'
	jne failed
	mov ax,TESTOTHER
	CopyTest ax,Other,ds,Buf,5
	mov ax,TESTOTHER
	mov es,ax
	cmp byte ptr es:OtherBuffer,'A'
	jne failed
	cmp byte ptr es:OtherBuffer+4,'E'
	jne failed
	mov ax,4C00h
	int 21h
failed:
	mov ax,4C01h
	int 21h
TESTCODE ends
 end start
