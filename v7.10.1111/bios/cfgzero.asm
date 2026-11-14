;** CFGZERO.ASM - Return the default configuration option.
;
; FAR C entry; no arguments. Returns AX = 0.
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
