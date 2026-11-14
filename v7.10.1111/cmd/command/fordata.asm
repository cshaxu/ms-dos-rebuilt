;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */
;	SCCSID = @(#)fordata.asm	1.1 85/05/14
;	SCCSID = @(#)fordata.asm	1.1 85/05/14
; Data structure definitions included by tfor.asm
; The fixed argument header contains argv[] and five words.
; Dynamic argument strings follow for_info.

for_info        STRUC
    for_args        DB          (ARGMAX * SIZE argv_ele + 10) DUP (?) ; argv[] structure
    FOR_COM_START   DB          (?)                     ; beginning of <command>
    FOR_EXPAND      DW          (?)                     ; * or ? item in <list>?
    FOR_MINARG      DW          (?)                     ; beginning of <list>
    FOR_MAXARG      DW          (?)                     ; end of <list>
    forbuf          DB          260 DUP (?)             ; temporary pathname
    fordma          DB          (44+260+14) DUP (?)     ; FindFirst/Next buffer
    FOR_FIND_HANDLE DW          (?)                     ; long filename search
    FOR_VAR         DB          (?)                     ; loop control variable
for_info        ENDS

; empty segment done for bogus addressing
for_segment     segment
f       LABEL   BYTE
for_segment     ends
