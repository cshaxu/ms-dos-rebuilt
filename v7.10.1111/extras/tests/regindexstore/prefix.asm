	.386
TESTDATA segment word public use16 'DATA'
TestBlock db 64 dup (0)
TestIndex dw 255 dup (0)
IndexGuard dw 0A55Ah
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
REGKEYS segment word public use16 'CODE'
 assume cs:REGKEYS,ds:DGROUP,ss:TESTSTACK
