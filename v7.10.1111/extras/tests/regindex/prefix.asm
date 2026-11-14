	.386
TESTDATA segment word public use16 'DATA'
TestBlock db 64 dup (0)
TestIndex dw 255 dup (0)
IndexGuard dw 0A55Ah
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
