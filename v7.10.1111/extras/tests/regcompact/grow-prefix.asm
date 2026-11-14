 .386
TESTDATA segment word public use16 'DATA'
 guard0 dw 0A55Ah
 block db 1000h dup (0)
 guard1 dw 05AA5h
 idx dw 255 dup (0CCCCh)
 guard2 dw 01234h
 fileinfo db 3Ch dup (0)
 cache dw offset block,0,0,0,0A0h,0
 allocations dw 0
 allocfail dw 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
