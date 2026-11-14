	.386
TESTDATA segment word public use16 'DATA'
TypeOut dd 0AABBCCDDh
SizeOut dd 12345678h
ValidateCalls dw 0
UnexpectedCalls dw 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
REGAPI segment word public use16 'CODE'
 assume cs:REGAPI,ds:DGROUP,ss:TESTSTACK
