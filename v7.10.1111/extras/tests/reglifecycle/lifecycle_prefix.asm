        .386
TESTDATA segment word public use16 'DATA'
RegRootTable db 280 dup (0FFh)
RegVMEntry dd 0
RegReserveBlock dd 0
RegReserveSize dd 1234h
RegHandleList dd 0FFFFFFFFh
MountCalls dw 0
SavedSP dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
        db 1024 dup (?)
TESTSTACK ends
REGSTART segment word public use16 'CODE'
        assume cs:REGSTART,ds:DGROUP,ss:TESTSTACK
