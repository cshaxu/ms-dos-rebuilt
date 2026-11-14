	.386
TESTDATA segment word public use16 'DATA'
RegVMEntry dd 0
DataBuffer db 4 dup (0)
DataSize dd 4
CoreCalls dw 0
ProviderCalls dw 0
SavedSP dw 0
DataOff equ offset DataBuffer
SizeOff equ offset DataSize
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
REGWRAP segment word public use16 'CODE'
 assume cs:REGWRAP,ds:DGROUP,ss:TESTSTACK
