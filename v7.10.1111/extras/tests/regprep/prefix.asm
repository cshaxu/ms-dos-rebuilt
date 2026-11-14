	.386
TESTDATA segment word public use16 'DATA'
RegIOInhibit dw 0
Handle db 32 dup (0)
FileState db 48 dup (0)
KeyNode db 32 dup (0)
KeyRecord db 14h dup (0)
 db 'aBc',0
FileName db 'TEST.DAT',0
WorkBuffer db 4096 dup (0)
CreateFail dw 0
WriteCalls dw 0
CloseCalls dw 0
DeleteCalls dw 0
FreeCalls dw 0
SavedHash dd 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegNameChecksum:near
 extrn RegCopyBytes:far,RegStringLength:far
