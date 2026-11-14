	.386
TESTDATA segment word public use16 'DATA'
RegIOInhibit dw 0
ValidateOK dw 1
WriteFail dw 0
SeenFlags db 0
SeekCount dw 0
SeekMode dw 0
TestBlock db 32 dup (0)
TestCache dw offset TestBlock,0,0,0,32,0
TestFile db 64 dup (0)
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 1024 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
