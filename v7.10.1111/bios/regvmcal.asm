;** REGIO.ASM - Registry calls through the Windows service entry
;
; Preserve original FAR entry argument cleanup and AX service numbers.
_DATA segment word public 'DATA'
_DATA ends
c_common segment word public 'BSS'
        extrn RegVMEntry:dword
c_common ends
DGROUP group _DATA,c_common
REGIO segment word public 'CODE'
        assume cs:REGIO,ds:DGROUP
        public RegVMOpenKey
RegVMOpenKey proc far
        push bp
        mov bp,sp
        mov ax,0100h
        call dword ptr RegVMEntry
        pop bp
        ret 12
RegVMOpenKey endp

        public RegVMCloseKey
RegVMCloseKey proc far
        push bp
        mov bp,sp
        mov ax,0102h
        call dword ptr RegVMEntry
        pop bp
        ret 4
RegVMCloseKey endp

        public RegVMQueryValue
RegVMQueryValue proc far
        push bp
        mov bp,sp
        mov ax,0105h
        call dword ptr RegVMEntry
        pop bp
        ret 16
RegVMQueryValue endp

        public RegVMQueryValueEx
RegVMQueryValueEx proc far
        push bp
        mov bp,sp
        mov ax,0109h
        call dword ptr RegVMEntry
        pop bp
        ret 24
RegVMQueryValueEx endp

        public RegVMCreateKey
RegVMCreateKey proc far
        push bp
        mov bp,sp
        mov ax,0101h
        call dword ptr RegVMEntry
        pop bp
        ret 12
RegVMCreateKey endp

        public RegVMDeleteKey
RegVMDeleteKey proc far
        push bp
        mov bp,sp
        mov ax,0103h
        call dword ptr RegVMEntry
        pop bp
        ret 8
RegVMDeleteKey endp

        public RegVMDeleteValue
RegVMDeleteValue proc far
        push bp
        mov bp,sp
        mov ax,0107h
        call dword ptr RegVMEntry
        pop bp
        ret 8
RegVMDeleteValue endp

        public RegVMSetValue
RegVMSetValue proc far
        push bp
        mov bp,sp
        mov ax,0104h
        call dword ptr RegVMEntry
        pop bp
        ret 20
RegVMSetValue endp

        public RegVMSetValueEx
RegVMSetValueEx proc far
        push bp
        mov bp,sp
        mov ax,010Ah
        call dword ptr RegVMEntry
        pop bp
        ret 24
RegVMSetValueEx endp

        public RegVMEnumKey
RegVMEnumKey proc far
        push bp
        mov bp,sp
        mov ax,0106h
        call dword ptr RegVMEntry
        pop bp
        ret 16
RegVMEnumKey endp

        public RegVMEnumValue
RegVMEnumValue proc far
        push bp
        mov bp,sp
        mov ax,0108h
        call dword ptr RegVMEntry
        pop bp
        ret 32
RegVMEnumValue endp

        public RegVMFlushKey
RegVMFlushKey proc far
        push bp
        mov bp,sp
        mov ax,010Bh
        call dword ptr RegVMEntry
        pop bp
        ret 4
RegVMFlushKey endp

        public RegVMRemapKey
RegVMRemapKey proc far
        push bp
        mov bp,sp
        mov ax,0110h
        call dword ptr RegVMEntry
        pop bp
        ret 8
RegVMRemapKey endp

        public RegVMLoadKey
RegVMLoadKey proc far
        push bp
        mov bp,sp
        mov ax,010Ch
        call dword ptr RegVMEntry
        pop bp
        ret 12
RegVMLoadKey endp

        public RegVMUnloadKey
RegVMUnloadKey proc far
        push bp
        mov bp,sp
        mov ax,010Dh
        call dword ptr RegVMEntry
        pop bp
        ret 8
RegVMUnloadKey endp

        public RegVMSaveKey
RegVMSaveKey proc far
        push bp
        mov bp,sp
        mov ax,010Eh
        call dword ptr RegVMEntry
        pop bp
        ret 12
RegVMSaveKey endp

        public RegInvalidBlock,RegNotifyLoad
RegInvalidBlock proc far
        int 3
        ret
RegInvalidBlock endp
RegNotifyLoad proc far
        ret
RegNotifyLoad endp
REGIO ends
        end
