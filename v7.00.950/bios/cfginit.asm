;** CFGINIT.ASM - Configuration program initialized data
;
; Keep original data order independent of function object link order.
; FAR tables use actual code and data symbols.
;
; Static CRT storage precedes exit tables and near communal storage.
_BSS segment word public 'BSS'
_BSS ends
XOB segment word public 'BSS'
XOB ends
XO segment word public 'BSS'
XO ends
XOE segment word public 'BSS'
XOE ends
XOFB segment word public 'BSS'
XOFB ends
XOF segment word public 'BSS'
XOF ends
XOFE segment word public 'BSS'
XOFE ends
c_common segment para public 'BSS'
c_common ends

; Original front-end code order.
CFGMAIN segment word public 'CODE'
CFGMAIN ends
CFGPUB segment word public 'CODE'
CFGPUB ends
CFGIOCTL segment word public 'CODE'
CFGIOCTL ends
CFGPNP segment word public 'CODE'
CFGPNP ends
CFGMSGS segment word public 'CODE'
CFGMSGS ends
CFGMSGT segment word public 'CODE'
CFGMSGT ends
CFGMSG segment word public 'CODE'
CFGMSG ends
PNPCPQ segment word public 'CODE'
PNPCPQ ends
PNPTOSH segment word public 'CODE'
PNPTOSH ends
PNPLF segment word public 'CODE'
PNPLF ends
PNPTI segment word public 'CODE'
PNPTI ends
PNPIBM segment word public 'CODE'
PNPIBM ends
CONFIGPATH segment para public 'CODE'
CONFIGPATH ends
REGAPI segment word public 'CODE'
REGAPI ends
REGIO segment para public 'CODE'
REGIO ends
REGWRAP segment word public 'CODE'
REGWRAP ends
REGSTART segment word public 'CODE'
REGSTART ends
REGKEYS segment word public 'CODE'
REGKEYS ends
REGSTR segment word public 'CODE'
REGSTR ends
REGFILE segment word public 'CODE'
REGFILE ends
REGHANDLE segment word public 'CODE'
REGHANDLE ends
REGFINAL segment word public 'CODE'
REGFINAL ends

        extrn ConfigProbeCompaq:far,ConfigProbeToshiba:far
        extrn ConfigProbeLF:far,ConfigProbeTI:far,ConfigProbeIBM:far
_DATA segment word public 'DATA'
ifndef CFGINIT_TAIL
        public ConfigInitStart
ConfigInitStart label byte
; CFGERROR data.
        public ConfigInitialState,ConfigInfoSize,ConfigReturnCode
; Retain the original bootstrap data; no direct code references are known.
ConfigInitialState label byte
        dw 1
        dd 0
        dd 200h
ConfigInfoSize dw 0
ConfigReturnCode dw 0
; CFGARGS data.
        public ConfigArgPaths,ConfigArgValues
        public ConfigArgPath0
ConfigArgPath0 db 'Software\Microsoft\Windows\CurrentVersion',0
        even
        public ConfigArgPath1
ConfigArgPath1 db 'Software\Microsoft\Windows\CurrentVersion\Setup',0
        even
        public ConfigArgPath2
ConfigArgPath2 db 'System\CurrentControlSet\Control\WinBoot',0
        even
        public ConfigArgPath3
ConfigArgPath3 db 'System\CurrentControlSet\Control\FileSystem',0
        even
        public ConfigArgPath4
ConfigArgPath4 db 'Software\Microsoft\Windows\CurrentVersion\Network\Real Mode Net',0
        even
        public ConfigArgPath5
ConfigArgPath5 db 'Software\Microsoft\Windows\CurrentVersion\Network',0
        even
ConfigArgPaths label dword
        dw offset DGROUP:ConfigArgPath0,DGROUP
        dw offset DGROUP:ConfigArgPath0,DGROUP
        dw offset DGROUP:ConfigArgPath1,DGROUP
        dw offset DGROUP:ConfigArgPath2,DGROUP
        dw offset DGROUP:ConfigArgPath3,DGROUP
        dw offset DGROUP:ConfigArgPath4,DGROUP
        dw offset DGROUP:ConfigArgPath5,DGROUP
        public ConfigArgValue0
ConfigArgValue0 db 'SystemRoot',0
        public ConfigArgValue1
ConfigArgValue1 db 'BootCount',0
        public ConfigArgValue2
ConfigArgValue2 db 'LASTDRIVE',0
        public ConfigArgValue3
ConfigArgValue3 db 'DoubleBuffer',0
        public ConfigArgValue4
ConfigArgValue4 db 'Win31FileSystem',0
        public ConfigArgValue5
ConfigArgValue5 db 'SetupN',0
        public ConfigArgValue6
ConfigArgValue6 db 'INSTALLED',0
        even
ConfigArgValues label dword
        dw offset DGROUP:ConfigArgValue0,DGROUP
        dw offset DGROUP:ConfigArgValue1,DGROUP
        dw offset DGROUP:ConfigArgValue2,DGROUP
        dw offset DGROUP:ConfigArgValue3,DGROUP
        dw offset DGROUP:ConfigArgValue4,DGROUP
        dw offset DGROUP:ConfigArgValue5,DGROUP
        dw offset DGROUP:ConfigArgValue6,DGROUP
; CFGPUB data.
        public ConfigRecordHead,ConfigRecordCount,ConfigDeviceName
ConfigRecordHead dd 0
        dd 0                    ; Original reserved record-list storage.
ConfigRecordCount dw 0
ConfigDeviceName db 'CONFIG$',0
endif
ifndef CFGINIT_HEAD
; PNPCAPS data.
        public PnPProbeTable
PnPProbeTable label dword
        dd ConfigProbeCompaq
        dd ConfigProbeToshiba
        dd ConfigProbeLF
        dd ConfigProbeTI
        dd ConfigProbeIBM
        dd 0
; PNPCHECK data.
; No registry state dependencies.
; BIOS entry instruction fingerprints, compared as data.
        public PnPBadEntry1,PnPBadEntry2
PnPBadEntry1 db 55h,8Bh,0ECh,9Ch,0FAh,66h,53h,66h,50h,83h,0C5h,06h
PnPBadEntry2 db 50h,66h,50h,66h,0Fh,02h,46h,00h
; CFGNAME data.
        public ConfigUnnamed
ConfigUnnamed db '<Noname Config>',0
        public ConfigNameKey
ConfigNameKey db 'FriendlyName',0
        public ConfigNameFormat
ConfigNameFormat db '%04X',0
; CFGSAME data.
        public ConfigFindKey
ConfigFindKey db 'FriendlyName',0
        public ConfigFindFormat
ConfigFindFormat db '%04X',0
; CFGPICK data.
        public ConfigNameSuffix
ConfigNameSuffix db ' %ld',0
        public ConfigNamePattern
ConfigNamePattern db '%s %ld',0
; CFGMENU data.
        public ConfigMenuSpace
ConfigMenuSpace db ' ',0
        public ConfigMenuEntry
ConfigMenuEntry db '%d. %.70s',10,0
        public ConfigMenuNewSpace
ConfigMenuNewSpace db ' ',0
        public ConfigMenuNewEntry
ConfigMenuNewEntry db '%d. %.70s',10,10,0
; CFGUI data.
        public ConfigDatabasePath
ConfigDatabasePath db 'System\CurrentControlSet\Control\IDConfigDB',0
        public ConfigDatabaseMap
ConfigDatabaseMap db 'Map',0
        even
; PNPCPQ data.
; No registry state dependencies.
        public PnPCompaqName
PnPCompaqName db 'COMPAQ',0,0
; PNPTOSH data.
        public PnPToshibaName
PnPToshibaName db 'TOSHIBA',0
; RAPISAVE data.
        public RegSaveName,RegSaveSequence
RegSaveName db '$SAVEKEY0',0
RegSaveSequence db '0'
        even
        public ConfigInitEnd
ConfigInitEnd label byte
endif
_DATA ends
DGROUP group _DATA
        end
