;** CFGDATA.ASM - Configuration program near communal storage
;
; Preserve the storage order established by target data references and
; the CRT clearing boundary. Names describe reconstructed ownership.
; Unresolved ranges retain original storage; their purpose is unknown.
;
c_common segment word public 'BSS'
        public RegPathBuffer,RegPathBufferEnd,RegVMEntry
        public ConfigUIState,ConfigHardwareHigh,ConfigSystemID
        public ConfigSystemHigh,ConfigBootOption,ConfigSelectedProfile
        public ConfigSelectedName,ConfigStoredProfiles,ConfigInfoData
        public ConfigPathBuffer,ConfigNameBuffer,ConfigCommonEnd
RegPathBuffer db 100h dup (?)
RegPathBufferEnd label byte
        dw 1 dup (?)                    ; Original storage; purpose unresolved.
RegVMEntry dd 1 dup (?)
ConfigUIState dw 1 dup (?)
ConfigHardwareHigh dw 1 dup (?)
ConfigSystemID dw 1 dup (?)
ConfigSystemHigh dw 1 dup (?)
ConfigBootOption dw 1 dup (?)
ConfigSelectedProfile dw 1 dup (?)
ConfigSelectedName db 80 dup (?)
ConfigStoredProfiles db 110 dup (?)
ConfigInfoData dd 1 dup (?)
        db 2D0h dup (?)          ; Original storage; purpose unresolved.
ConfigPathBuffer db 40h dup (?)
        db 1C4h dup (?)          ; Original storage; purpose unresolved.
ConfigNameBuffer db 1000h dup (?)
        db 8 dup (?)             ; Original storage; purpose unresolved.
ConfigCommonEnd label byte
c_common ends
DGROUP group c_common
        end
