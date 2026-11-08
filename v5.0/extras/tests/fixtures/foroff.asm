; Research reconstruction, MS-DOS 5.00 target; not original DOS 5 source.
; ForOff instruction sequence derived from OpenNT v86/cmd/command/tfor.asm.
; Only this routine is reconstructed; the rest of TFOR is still pending.
; ResSeg, ForPtr and ForFlag must be supplied by the surrounding layout.

TRANCODE SEGMENT PUBLIC BYTE
ASSUME CS:TRANCODE
PUBLIC ForOff
ForOff:
        push    ax
        push    es
        mov     es,cs:ResSeg
        mov     ax,es:ForPtr
        or      ax,ax
        jz      FreeDone
        push    es
        mov     es,ax
        mov     ah,49h
        int     21h
        pop     es
FreeDone:
        mov     es:ForPtr,0
        mov     es:ForFlag,0
        pop     es
        pop     ax
        ret
TRANCODE ENDS
