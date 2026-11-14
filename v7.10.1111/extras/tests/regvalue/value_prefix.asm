	.386
TESTDATA segment word public use16 'DATA'
RegPathBuffer db 256 dup (055h)
KeyRecord db 14h dup (0)
DefaultValue dw 1,0,0,0,0,0
NamedValue dw 2,0,0,0,3,2
 db 'AbC',0AAh,0BBh
ThirdValue dw 3,0,0,0,4,0
 db 'Wxyz'
NameGood db 'aBc',0
NameBad db 'aBd',0
NameEmpty db 0
NameHigh db 'a',80h,'c',0
NameThird db 'wXYZ',0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
_TEXT segment word public use16 'CODE'
 assume cs:_TEXT,ds:DGROUP,ss:TESTSTACK
 extrn RegCompareName:near
