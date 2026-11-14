;** CRTSTDIO.ASM - Initial standard streams and DOS swap callbacks
;
; Stream entries contain current pointer, count, base pointer, flags
; and handle. The auxiliary stream uses its single-byte reserve.
        public __aDBdoswp
__aDBdoswp equ 0D6D6h
_DATA segment word public 'DATA'
        public __iob,__iob2,__lastiob,__cflush
        public ___aDBswpflg,___aDBswpchk,___aDBrterr,___aDBexit
__iob label byte
        dw 0,0,0,0,0
        db 1,0
        dw 0,0,0,0,0
        db 2,1
        dw 0,0,0,0,0
        db 2,2
        dw offset __iob2+37,seg __iob2,0
        dw offset __iob2+37,seg __iob2
        db 84h,3
        dw 0,0,0,0,0
        db 2,4
        db 180 dup (0)
__iob2 db 36 dup (0)
        db 0,0                 ; Flags and single-byte reserve
        dw 1                   ; Auxiliary stream buffer size
        db 200 dup (0)
__lastiob dw offset __iob+228,seg __iob
__cflush dw 0
___aDBswpflg dw 0
___aDBswpchk dw offset CRTSwapReturn
___aDBrterr dw offset CRTSwapReturn
___aDBexit dw offset CRTSwapReturn
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        public CRTSwapReturn
CRTSwapReturn proc near
        ret
CRTSwapReturn endp
_TEXT ends
        end
