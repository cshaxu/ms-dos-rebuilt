;** CFGINIT.ASM - Configuration program initialized data
;
; FAR tables use actual code and data symbols.
;
_DATA segment word public 'RESUME_DATA'
        public ConfigInitStart
ConfigInitStart label byte
; CFGERROR data.
        public ConfigInitialState,ConfigInfoSize,ConfigReturnCode,ConfigRecordCount
ConfigInitialState label byte
        dd 200h
ConfigInfoSize dw 0
ConfigReturnCode dw 0
; Default directory when the command tail has no path record.
        public ConfigWindowsPath
ConfigWindowsDir db 'C:\WINDOWS',0
        even
ConfigWindowsPath dw offset DGROUP:ConfigWindowsDir,DGROUP
        public AsdWizardValue,AsdWizardCommand
AsdWizardValue db 'ASD_Wizard',0
        even
AsdWizardCommand db 'ASD.EXE /w',0
        even
ConfigRecordCount dw 0
; CFGARGS data.
        public ConfigArgPaths,ConfigArgValues
        public ConfigArgPath0,ConfigArgPath1,ConfigArgPath2,ConfigArgPath3
        public ConfigArgPath4,ConfigArgPath5,ConfigArgPath6,ConfigArgPath7
ConfigArgPath0 db 'Software\Microsoft\Windows\CurrentVersion',0
ConfigArgPath1 db 'Software\Microsoft\Windows\CurrentVersion\Setup',0
ConfigArgPath2 db 'System\CurrentControlSet\Control\WinBoot',0
        even
ConfigArgPath3 db 'System\CurrentControlSet\Control\FileSystem',0
ConfigArgPath4 db 'Software\Microsoft\Windows\CurrentVersion\Network\Real Mode Net',0
ConfigArgPath5 db 'Software\Microsoft\Windows\CurrentVersion\Network',0
        even
ConfigArgPath6 db 'System\CurrentControlSet\Control\Nls\Codepage',0
        even
ConfigArgPath7 db 'System\CurrentControlSet\Control\SessionManager\Environment',0
        even
ConfigArgPaths label dword
        dw offset DGROUP:ConfigArgPath0,DGROUP
        dw offset DGROUP:ConfigArgPath0,DGROUP
        dw offset DGROUP:ConfigArgPath1,DGROUP
        dw offset DGROUP:ConfigArgPath2,DGROUP
        dw offset DGROUP:ConfigArgPath3,DGROUP
        dw offset DGROUP:ConfigArgPath4,DGROUP
        dw offset DGROUP:ConfigArgPath5,DGROUP
        dw offset DGROUP:ConfigArgPath3,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath6,DGROUP
        dw offset DGROUP:ConfigArgPath7,DGROUP
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
        public ConfigArgValue7
ConfigArgValue7 db 'GetDevParmsIoctl',0
ConfigArgValue8 db 'DOSCP',0
ConfigArgValue9 db 'OEMCC',0
ConfigArgValue10 db 'KYBTYPE',0
ConfigArgValue11 db 'KYBLAYOUT',0
ConfigArgValue12 db 'LANGID',0
ConfigArgValue13 db 'COUNTRYFNAME',0
ConfigArgValue14 db 'CODEPAGEFNAME',0
ConfigArgValue15 db 'KYBFNAME',0
ConfigArgValue16 db 0
ConfigArgValues label dword
        dw offset DGROUP:ConfigArgValue0,DGROUP
        dw offset DGROUP:ConfigArgValue1,DGROUP
        dw offset DGROUP:ConfigArgValue2,DGROUP
        dw offset DGROUP:ConfigArgValue3,DGROUP
        dw offset DGROUP:ConfigArgValue4,DGROUP
        dw offset DGROUP:ConfigArgValue5,DGROUP
        dw offset DGROUP:ConfigArgValue6,DGROUP
        dw offset DGROUP:ConfigArgValue7,DGROUP
        dw offset DGROUP:ConfigArgValue8,DGROUP
        dw offset DGROUP:ConfigArgValue9,DGROUP
        dw offset DGROUP:ConfigArgValue10,DGROUP
        dw offset DGROUP:ConfigArgValue11,DGROUP
        dw offset DGROUP:ConfigArgValue12,DGROUP
        dw offset DGROUP:ConfigArgValue13,DGROUP
        dw offset DGROUP:ConfigArgValue14,DGROUP
        dw offset DGROUP:ConfigArgValue15,DGROUP
        dw offset DGROUP:ConfigArgValue16,DGROUP
ConfigArgValuesEnd label dword
        public ConfigArgValuesEnd
        public AsdRunOnceKey,AsdHexDigits,AsdGuidFormat
        public AsdValueName,AsdFileName,AsdProblemsKey
AsdHexDigits db '0123456789ABCDEF',0
        even
AsdGuidFormat db '{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}',0
AsdValueName dw 'P'
AsdFileName db 'ASD.dat',0
AsdProblemsKey db 'System\CurrentControlSet\Control\ASD\Prob',0
AsdRunOnceKey db 'Software\Microsoft\Windows\CurrentVersion\RunOnce',0
        even
; Resume filename and XMS file transfer state.
        public HiberFileName
HiberFileName db 'VMMHIBER.W9X',0
        even
        public ConfigFileOffset,ConfigXmsMove
ConfigFileOffset dd 0
ConfigXmsMove label byte
        dd 0                    ; transfer length
        dw 0                    ; source XMS handle
        dd 0                    ; source offset
        dw 0                    ; destination XMS handle
        dd 0                    ; destination offset
        public ConfigXmsHandle,ConfigXmsDriver,ConfigFileLength,ConfigXmsSize
ConfigXmsHandle dw -1
ConfigXmsDriver dd 0
ConfigFileLength dd 0
ConfigXmsSize dw 0
        dw 0
_DATA ends
; The work area follows the initialized resume data.
RESWORK segment word public 'RESUME_BSS'
        db 16 dup (?)
        public ConfigPathBuffer,AsdRecord,AsdOutputRecord
ConfigPathBuffer db 200h dup (?)
AsdRecord db 118h dup (?)
AsdOutputRecord db 21Ch dup (?)
RESWORK ends
DGROUP group _DATA,RESWORK
        end
