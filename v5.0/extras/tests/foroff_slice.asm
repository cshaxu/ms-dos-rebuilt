; Target addresses inferred from the uniquely matching target routine.
; This harness tests encoding only, not complete COMMAND memory layout.
ResSeg EQU WORD PTR 08D77h
ForPtr EQU WORD PTR 002B3h
ForFlag EQU BYTE PTR 002B2h
include extras/tests/fixtures/foroff.asm
end
