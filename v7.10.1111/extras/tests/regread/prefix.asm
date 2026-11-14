	.386
TESTDATA segment word public use16 'DATA'
RegIOInhibit dw 0
SeekMode dw 0
ValidateOK dw 1
ReadFail dw 0
IndexValid dw 1
AllocCount dw 0
ReadCount dw 0
FreeCount dw 0
SavedSP dw 0
TestBlock db 64 dup (0)
TestIndex db 510 dup (0)
IndexGuard dw 0A55Ah
TestCache dw -1,-1,1234h,12h,44,0
TestFile db 80 dup (0)
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
