sysinitseg segment para public 'code'
MAX_MULTI_CONFIG equ 9
shell_opt_flags db      0
bMenuColor      db      07h ;1Fh        ; default fgnd/bgnd color
bMenuPage       db      0               ; menu video page (KEEP AFTER bMenuColor)
                db      5               ; video page function # (KEEP AFTER bMenuPage)
bLastCol        db      ?               ; ending column on status line
bLastRow        db      24              ; row # of status line (KEEP AFTER bLastCol)
bDisableUI      db      0               ; 1=disable clean/interactive
                                        ; 2=disable default 2-second delay
IFDEF DOS7_CONFIG
boot_config_flags db     1
boot_runtime_flags db   80h
ENDIF
bCRTPage        db      ?               ; value saved from BIOS data area
wCRTStart       dw      ?               ; value saved from BIOS data area
bQueryOpt       db      0               ; 0=off, 1=prompt all, 2=prompt none, 4=skip all
IFDEF DOS7_CONFIG
query_mode_flags db     0
query_display_flags db  0
ENDIF
bDefBlock       db      1               ; default block #
bMaxBlock       db      ?               ; maxmimum block #
offDefBlock     dw      0               ; offset of name of default block (if any)
secTimeOut      db      -1              ; # of seconds for timeout (-1 == indefinite)
secElapsed      db      0               ; # of seconds elapsed so far (KEEP AFTER secTimeOut)
abBlockType     db  MAX_MULTI_CONFIG+1 dup(?)   ; array of block types
aoffBlockName   dw  MAX_MULTI_CONFIG+1 dup(?)   ; array of offsets of block names
aoffBlockDesc   dw  MAX_MULTI_CONFIG+1 dup(?)   ; array of offsets of block descriptions

IFDEF DOS7_CONFIG
query_result    db      0
ENDIF
szBoot          db      "CONFIG=",0
szMenu          db      "MENU",0
szCommon        db      "COMMON",0

sysinitseg ends
end
