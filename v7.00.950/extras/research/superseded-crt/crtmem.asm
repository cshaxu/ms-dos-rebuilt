;** CRTMEM.ASM - C runtime startup state used by the far heap
;
; Startup fills these words before heap services execute.
; Final runtime integration owns their original DGROUP placement.
_DATA segment word public 'DATA'
        public __aseghi,__aseglo,__psp
__aseghi dw 0
__aseglo dw 0
__psp dw 0
_DATA ends
DGROUP group _DATA
        end
