        .386
TESTDATA segment word public use16 'DATA'
RegVMEntry dd 1
KeyHandle db 40 dup (0)
FileObject db 64 dup (0)
Mode dw 0
ReleaseCount dw 0
SaveCount dw 0
DestroyCount dw 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
        db 1024 dup (?)
TESTSTACK ends
REGAPI segment word public use16 'CODE'
        assume cs:REGAPI,ds:DGROUP,ss:TESTSTACK
