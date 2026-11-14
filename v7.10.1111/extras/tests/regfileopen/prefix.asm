	.386
TESTDATA segment word public use16 'DATA'
RegReserveBlock dd 1
RegReserveSize dd 0
AllocCount dw 0
ReadCount dw 0
CloseCount dw 0
ReleaseCount dw 0
SeekMode dw 0
ReadFail dw 0
BadDataSize dw 0
HeaderMode dw 0
KeyValid dw 1
OpenFail dw 0
SavedSP dw 0
PathName db 'R',0
PathBuf db 32 dup (0)
HeadBuf db 32 dup (0)
KeyBuf db 1056 dup (0)
CacheBuf db 24 dup (0)
TestFile db 80 dup (0)
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 4096 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
