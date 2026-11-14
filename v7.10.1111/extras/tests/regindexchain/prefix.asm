	.386
TESTDATA segment word public use16 'DATA'
TestBlock db 64 dup (0)
TestIndex dw 255 dup (0)
IndexGuard dw 0A55Ah
TestKey db 40 dup (0)
TestFile db 80 dup (0)
Result dd 0
DirtyCount dw 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 4096 dup (?)
TESTSTACK ends
REGKEYS segment word public use16 'CODE'
 assume cs:REGKEYS,ds:DGROUP,ss:TESTSTACK
