;** CRTEND.ASM - End of C runtime uninitialized storage
; Link this contribution after all other BSS contributions.
c_common segment word public 'BSS'
        public __end
__end label byte
c_common ends
DGROUP group c_common
        end
