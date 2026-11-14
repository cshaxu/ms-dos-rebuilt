	.386
TESTDATA segment word public use16 'DATA'
RegPathBuffer db 256 dup (0)
FileState db 40 dup (0)
KeyBlock db 32 dup (0)
RootKey db 32 dup (0)
KeyOne db 32 dup (0)
KeyTwo db 32 dup (0)
RecordOne db 32 dup (0)
RecordTwo db 32 dup (0)
PathOne db 'aBc',0
PathTwo db 'abC\dEf',0
PathBad db 'abD',0
PathInvalid db 'a',1,'b',0
PathHigh db 'a',80h,'c',0
Result dd 0
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
