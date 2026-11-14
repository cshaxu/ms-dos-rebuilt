	.386
TESTDATA segment word public use16 'DATA'
SeekMode dw 0
SeekCount dw 0
SavedSP dw 0
TestFile db 80 dup (0)
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
OpenSeek proc far
	push bp
	mov bp,sp
	sub sp,60h
	mov word ptr [bp-056h],1234h
	mov word ptr [bp-054h],12h
	mov word ptr [bp-058h],5
