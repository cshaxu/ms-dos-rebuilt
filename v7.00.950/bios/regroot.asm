;** REGROOT.ASM - Predefined registry roots and initialized state
;
; Each root uses the same 28h-byte record layout as a dynamic key.
; Initial links and file/key identities are invalid; reference count
; is zero. Flags are the observed initial policy/state bit combinations.
;
RootHandle macro rootid,rootflags
        dd 4E4B4752h            ; RGKN signature
        dd -1                   ; previous handle
        dd -1                   ; next handle
        dd -1                   ; file identity
        dd -1                   ; key identity
        dd 0                    ; reference count
        dd rootflags
        dd rootid
        dd -1                   ; auxiliary pointer
        dd -1                   ; auxiliary state
endm

_DATA segment word public 'DATA'
        public RegRootTable,RegRootTableEnd
RegRootTable label byte
        RootHandle 80000000h,00104000h
        RootHandle 80000001h,00104000h
        RootHandle 80000002h,00106000h
        RootHandle 80000003h,00106000h
        RootHandle 80000004h,00104000h
        RootHandle 80000005h,00104000h
        RootHandle 80000006h,00106000h
RegRootTableEnd label byte
; REGHANDLE state.
        public RegHandleList
RegHandleList dd -1
        dw 0                    ; Original trailing handle-list storage.
; REGALLOC state.
        public RegReserveSize,RegReserveBlock
RegReserveSize dd 0
RegReserveBlock dd 0
; REGCLASSES state.
        public RegClassesPath,RegDefaultUser
RegClassesPath db 'SOFTWARE\Classes',0
RegDefaultUser db '.Default',0
; REGWRITE state.
        public RegIOInhibit
RegIOInhibit dw 0
        dw 0                    ; Original high word; no direct references are known.
; REGVALID state.
        public RegCheckPolicy
RegCheckPolicy dw 0FFh
; REGOBJECT state.
        public RegFileList
RegFileList dd -1
        public RegDataEnd
RegDataEnd label byte
_DATA ends
        end
