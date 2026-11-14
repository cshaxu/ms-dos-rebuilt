;** CFGZERO.ASM - No arguments. Return the target default option value.
;
; FAR C entry: No arguments. Return the target default option value.
; Preserve profile bounds and original data segment restoration.
; Local instruction flow follows the target; final layout is linked.
;
_DATA segment word public 'DATA'
; No private data dependencies.
_DATA ends
DGROUP group _DATA
CFGPNP segment word public 'CODE'
        assume cs:CFGPNP,ds:DGROUP
        public ConfigZeroOption

ConfigZeroOption proc far
        xor ax,ax
        ret
ConfigZeroOption endp
        even
CFGPNP ends
        end
