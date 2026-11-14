;** REGROOT - Registry roots and shared storage state

KeyRoot macro rootid
        dw 4B48h,25h,0
        dd 0,-1,-1
        dw 0
        db 0,rootid
        dd 0,0,-1
        dw -1
endm
_DATA segment word public 'DATA'
        public RegTransferBuffer,RegActiveFiles,RegCurrentDirectory
RegTransferBuffer dd 0
RegActiveFiles dd 0
RegCurrentDirectory db '.\',0
        even
        public RegPathCursor
RegPathCursor dd 0
        public RegMachineRoot,RegUserRoot,RegPredefinedKeys
RegMachineRoot label byte
        KeyRoot 2
RegUserRoot label byte
        KeyRoot 3
RegPredefinedKeys label dword
        dd 0,0
        dw offset DGROUP:RegMachineRoot,DGROUP
        dw offset DGROUP:RegUserRoot,DGROUP
        dd 0,0
        public RegKeyPool,RegDynamicKeys
RegKeyPool dd 0
RegDynamicKeys dd 0
        public RegClassesPath,RegDefaultUser
RegClassesPath db 'SOFTWARE\CLASSES',0
        even
RegDefaultUser db '.DEFAULT',0
        even
        public RegDataEnd
RegDataEnd label byte
_DATA ends
DGROUP group _DATA
        end
