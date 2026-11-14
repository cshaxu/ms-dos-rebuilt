	.386
TESTDATA segment word public use16 'DATA'
FileState db 40 dup (0)
KeyBlock db 32 dup (0)
KeyNode db 32 dup (0)
KeyRecord db 14h dup (0)
 db 'aBc'
RegPathBuffer db 256 dup (055h)
GetStatus dw 0
DirtyCalls dw 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegNameChecksum:near
