;*** Initialization message storage and resource source.
IFDEF INIT_MSG_BUFFER
; Initialization messages are loaded from the executable at startup.
InitMsgClass    db 0
InitMsgCount    db 0
InitMsgTable    label word
InitMsg11       label word
    dw 0,0
InitMsg12       label word
    dw 0,0
InitMsg13       label word
    dw 0,0
InitMsg14       label word
    dw 0,0
InitMsg15       label word
    dw 0,0
HelpMsgs        label word
InitMsg16       label word
    dw 0,0
InitMsg17       label word
    dw 0,0
InitMsg18       label word
    dw 0,0
InitMsg19       label word
    dw 0,0
InitMsg20       label word
    dw 0,0
InitMsg21       label word
    dw 0,0
InitMsg22       label word
    dw 0,0
InitMsg23       label word
    dw 0,0
InitMsg24       label word
    dw 0,0
InitMsg25       label word
    dw 0,0
InitMsg26       label word
    dw 0,0
InitMsg27       label word
    dw 0,0
InitMsg28       label word
    dw 0,0
InitMsg29       label word
    dw 0,0
InitMsg30       label word
    dw 0,0
InitMsg31       label word
    dw 0,0
    db 800h dup (0)     ; message-text workspace
    public InitMsgClass,InitMsgCount,InitMsgTable,HelpMsgs
ELSE
; BEGIN INITIALIZATION RESOURCE CLASS
;   Command.com initialization messages.
;
;   See resmsg.equ for macro definition.

;   Initialization class: message number and record-relative text offset.
InitMsgClass    db 5
InitMsgCount    db 21
InitMsgTable    label word
InitMsg11       label word
    dw 11,BadVerMsg-InitMsg11
InitMsg12       label word
    dw 12,OutEnvMsg-InitMsg12
InitMsg13       label word
    dw 13,CopyrightMsg-InitMsg13
InitMsg14       label word
    dw 14,BadComLkMsg-InitMsg14
InitMsg15       label word
    dw 15,BadComAccMsg-InitMsg15
HelpMsgs        label word
InitMsg16       label word
    dw 16,Help1Msg-InitMsg16
InitMsg17       label word
    dw 17,Help2Msg-InitMsg17
InitMsg18       label word
    dw 18,Help3Msg-InitMsg18
InitMsg19       label word
    dw 19,Help4Msg-InitMsg19
InitMsg20       label word
    dw 20,Help5Msg-InitMsg20
InitMsg21       label word
    dw 21,Help6Msg-InitMsg21
InitMsg22       label word
    dw 22,Help7Msg-InitMsg22
InitMsg23       label word
    dw 23,Help8Msg-InitMsg23
InitMsg24       label word
    dw 24,Help9Msg-InitMsg24
InitMsg25       label word
    dw 25,Help10Msg-InitMsg25
InitMsg26       label word
    dw 26,Help11Msg-InitMsg26
InitMsg27       label word
    dw 27,Help12Msg-InitMsg27
InitMsg28       label word
    dw 28,Help13Msg-InitMsg28
InitMsg29       label word
    dw 29,Help14Msg-InitMsg29
InitMsg30       label word
    dw 30,Help15Msg-InitMsg30
InitMsg31       label word
    dw 31,Help16Msg-InitMsg31

    msg BadVerMsg, <"Incorrect MS-DOS version",CR,LF>
    msg OutEnvMsg, <"Out of environment space",CR,LF>
    msg CopyrightMsg, <CR,LF,CR,LF,"Microsoft(R) Windows 95",CR,LF,"   (C)Copyright Microsoft Corp 1981-1995.",CR,LF>
    msg BadComLkMsg, <"Specified COMMAND search directory bad",CR,LF>
    msg BadComAccMsg, <"Specified COMMAND search directory bad, access denied",CR,LF>
    msg Help1Msg, <"Starts a new copy of the Windows Command Interpreter.",CR,LF,CR,LF>
    msg Help2Msg, <"COMMAND [[drive:]path] [device] [/E:nnnnn] [/L:nnnn] [/U:nnn] [/P] [/MSG]",CR,LF,"                       [/LOW] [/Y [/[C|K] command]]",CR,LF>
    msg Help3Msg, <"  [drive:]path    Specifies the directory containing COMMAND.COM.",CR,LF>
    msg Help4Msg, <"  device          Specifies the device to use for command input and output.",CR,LF>
    msg Help5Msg, <"  /E:nnnnn        Sets the initial environment size to nnnnn bytes.",CR,LF>
    msg Help6Msg, <"                  (nnnnn should be between 256 and 32,768).",CR,LF>
    msg Help7Msg, <"  /L:nnnn         Specifies internal buffers length (requires /P as well).",CR,LF>
    msg Help8Msg, <"                  (nnnn should be between 128 and 1,024).",CR,LF>
    msg Help9Msg, <"  /U:nnn          Specifies the input buffer length (requires /P as well).",CR,LF>
    msg Help10Msg, <"                  (nnn should be between 128 and 255).",CR,LF>
    msg Help11Msg, <"  /P              Makes the new Command Interpreter permanent (can't exit).",CR,LF>
    msg Help12Msg, <"  /MSG            Stores all error messages in memory (requires /P as well).",CR,LF>
    msg Help13Msg, <"  /LOW            Forces COMMAND to keep its resident data in low memory.",CR,LF>
    msg Help14Msg, <"  /Y              Steps through the batch program specified by /C or /K.",CR,LF>
    msg Help15Msg, <"  /C command      Executes the specified command and returns.",CR,LF>
    msg Help16Msg, <"  /K command      Executes the specified command and continues running.",CR,LF>

    public InitMsgClass,InitMsgCount,InitMsgTable,HelpMsgs

; END INITIALIZATION RESOURCE CLASS
ENDIF
