;
;       Microsoft Confidential
;       Copyright (C) Microsoft Corporation 1981-1991
;       All Rights Reserved.
;
;       Internal CONFIG.SYS constants, structures, etc.
;

CONFIG_BEGIN        =   '['
IFDEF DOS7_CONFIG
CONFIG_ACCDATE      =   'a'
ENDIF
CONFIG_BREAK        =   'C'
CONFIG_BUFFERS      =   'B'
IFDEF DOS7_CONFIG
CONFIG_BUFFERSHIGH  =   'b'
ENDIF
CONFIG_COMMENT      =   'Y'
CONFIG_COUNTRY      =   'Q'
CONFIG_DEVICE       =   'D'
CONFIG_DEVICEHIGH   =   'U'
CONFIG_DOS          =   'H'
CONFIG_DRIVPARM     =   'P'
CONFIG_FCBS         =   'X'
IFDEF DOS7_CONFIG
CONFIG_FCBSHIGH     =   'x'
ENDIF
CONFIG_FILES        =   'F'
IFDEF DOS7_CONFIG
CONFIG_FILESHIGH    =   'f'
ENDIF
CONFIG_INCLUDE      =   'J'
CONFIG_INSTALL      =   'I'
CONFIG_INSTALLHIGH  =   'W'
CONFIG_LASTDRIVE    =   'L'
IFDEF DOS7_CONFIG
CONFIG_LASTDRIVEHIGH =  'l'
ENDIF
CONFIG_MENUCOLOR    =   'R'
CONFIG_MENUDEFAULT  =   'A'
CONFIG_MENUITEM     =   'E'
CONFIG_MULTITRACK   =   'M'
CONFIG_NUMLOCK      =   'N'
CONFIG_REM          =   '0'
CONFIG_SEMICOLON    =   ';'
CONFIG_SET          =   'V'
CONFIG_SHELL        =   'S'
CONFIG_STACKS       =   'K'
IFDEF DOS7_CONFIG
CONFIG_STACKSHIGH   =   'k'
ENDIF
CONFIG_SUBMENU      =   'O'
CONFIG_SWITCHES     =   '1'

CONFIG_UNKNOWN      =   'Z'

CONFIG_OPTION_QUERY =   80h
