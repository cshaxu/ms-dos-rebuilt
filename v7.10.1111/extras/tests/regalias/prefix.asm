	.386
TESTDATA segment word public use16 'DATA'
RegPathBuffer db 256 dup (0)
Parent db 40 dup (0)
Mount db 40 dup (0)
MountName db 'ABC',0
NameGood db 'aBc',0
NameBad db 'abD',0
NameSlash db 'a\b',0
Result dd 0
Parent2 db 40 dup (0)
Mount2 db 40 dup (0)
File2 db 40 dup (0)
KeyBlock2 db 32 dup (0)
NameNew db 'eFg',0
AllocatedName db 256 dup (0)
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegPathPart:far
 extrn RegNameChecksum:near,RegCompareName:near
 extrn RegStringLength:far,RegCopyBytes:far
