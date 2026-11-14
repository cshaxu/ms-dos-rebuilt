;** REGVMCAL - Registry calls through the Windows service entry
;
; Preserve original FAR entry argument cleanup and AX service numbers.
; All service entries use the same frame; service and argument size vary.
;
RegVMCall macro entry,service,argbytes
        public entry
entry proc far
        push bp
        mov bp,sp
        mov ax,service
        call dword ptr RegVMEntry
        pop bp
        ret argbytes
entry endp
endm

_DATA segment word public 'DATA'
_DATA ends
c_common segment word public 'BSS'
        extrn RegVMEntry:dword
c_common ends
DGROUP group _DATA,c_common
REGIO segment word public 'CODE'
        assume cs:REGIO,ds:DGROUP
        RegVMCall RegVMOpenKey,0100h,12

        RegVMCall RegVMCloseKey,0102h,4

        RegVMCall RegVMQueryValue,0105h,16

        RegVMCall RegVMQueryValueEx,0109h,24

        RegVMCall RegVMCreateKey,0101h,12

        RegVMCall RegVMDeleteKey,0103h,8

        RegVMCall RegVMDeleteValue,0107h,8

        RegVMCall RegVMSetValue,0104h,20

        RegVMCall RegVMSetValueEx,010Ah,24

        RegVMCall RegVMEnumKey,0106h,16

        RegVMCall RegVMEnumValue,0108h,32

        RegVMCall RegVMFlushKey,010Bh,4

        RegVMCall RegVMRemapKey,0110h,8

        RegVMCall RegVMLoadKey,010Ch,12

        RegVMCall RegVMUnloadKey,010Dh,8

        RegVMCall RegVMSaveKey,010Eh,12

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
