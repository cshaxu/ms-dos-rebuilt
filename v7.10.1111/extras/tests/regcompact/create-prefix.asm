 .386
TESTDATA segment word public use16 'DATA'
 guard0 dw 0A55Ah
 block db 1000h dup (0CCh)
 guard1 dw 05AA5h
 idx dw 255 dup (0CCCCh)
 guard2 dw 1234h
 fileinfo db 3Ch dup (0)
 header db 20h dup (0)
 cache db 18h dup (0)
 allocs dw 0
 frees dw 0
 failat dw 0
 result dd 0
TESTDATA ends
DGROUP group TESTDATA
TESTSTACK segment para stack use16 'STACK'
 db 2048 dup (?)
TESTSTACK ends
REGFILE segment word public use16 'CODE'
 assume cs:REGFILE,ds:DGROUP,ss:TESTSTACK
