	.386
TESTDATA segment word public use16 'DATA'
RegPathBuffer db 256 dup (0)
FileState db 48 dup (0)
 db 16 dup (0)
KeyNode db 32 dup (0)
KeyBlock db 32 dup (0)
 db 16 dup (0)
FreeNode db 32 dup (0)
NextNode db 32 dup (0)
ParentNode db 32 dup (0)
PathEmpty db 0
PathOne db 'aBc',0
PathNested db 'AbC\DeF',0
Result dd 0
SavedSP dw 0
SearchFail dw 0
SearchCalls dw 0
AllocCalls dw 0
AllocSuccess dw 0
DirtyCalls dw 0
UnexpectedCalls dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegNameChecksum:near
 extrn RegPathPart:far,RegCopyPart:far,RegStringLength:far
