	.386
TESTDATA segment word public use16 'DATA'
Handle db 32 dup (0)
FileState db 48 dup (0)
Key db 32 dup (0)
KeyRecord db 14h dup (0)
Value dw 2,0,0,0,3,2
 db 'AbC','X','Y',0
OverlapOff equ offset Value+10h
NameGood db 'aBc',0
NameBad db 'abD',0
NameEmpty db 0
TypeOut dd 0
SizeOut dd 0
Buffer db 8 dup (055h)
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegCopyBytes:far,RegCompareName:near
