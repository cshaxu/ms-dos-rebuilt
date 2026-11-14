	TITLE CRIT - Critical Section Routines
	NAME  CRIT

;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;**	CRIT.ASM - Critical Section Routines
;
;	Critical section handlers
;
;	Modification history:
;
;	    Created: ARR 30 March 1983

	.xlist
	.xcref
	include version.inc
	include dosseg.inc
	INCLUDE DOSSYM.INC
	include int2a.inc
	include vector.inc
	include bugtyp.inc
	.cref
	.list

        i_need  NlsBuffer,BYTE
	I_need  User_In_AX,WORD
	i_need  CurrentPDB,WORD

;
;SR; This variable is set when the redir installs itself
;
	I_need 	redir_patch,BYTE

DOSCODE SEGMENT
	ASSUME  SS:NOTHING,CS:DOSCODE

	allow_getdseg

	Break	<Critical section handlers>

;
;   Each handler must leave everything untouched; including flags!
;
;   Sleaze for time savings:  first instruction is a return.  This is patched
;   by the sharer to be a PUSH AX to complete the correct routines.


; DOS 7 critical-section state uses the shared buffer and far callback.
; Preserve AX and flags on every return, including the callback path.
Procedure EcritDisk,near
        PUBLIC EcritMem,EcritSFT
EcritMem LABEL NEAR
EcritSFT LABEL NEAR
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_enter_local
        cmp     ss:[redir_patch],al
        jz      crit_enter_return
        mov     ax,8000h+critDisk
        int     int_ibm
crit_enter_return:
        pop     ax
        popf
        ret
crit_enter_local:
        cli
        cmp     BYTE PTR ss:[NlsBuffer+2],ah
        jns     crit_enter_check
        int     3
crit_enter_check:
        jnz     crit_enter_callback
        inc     BYTE PTR ss:[NlsBuffer]
crit_enter_done:
        pop     ax
        popf
        ret
crit_enter_callback:
        mov     al,3
        call    DWORD PTR ss:[NlsBuffer+16]
        jmp     short crit_enter_done
EndProc EcritDisk

; Console devices bypass the local disk nesting path.
Procedure EcritConsole,near
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_enter_done
        jmp     short crit_enter_device
EndProc EcritConsole

Procedure EcritDevice,near
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_enter_local
crit_enter_device:
        cmp     ss:[redir_patch],al
        jz      crit_enter_device_done
        mov     ax,8000h+critDevice
        int     int_ibm
crit_enter_device_done:
        pop     ax
        popf
        ret
EndProc EcritDevice

Procedure LcritDisk,near
        PUBLIC LcritMem,LcritSFT
LcritMem LABEL NEAR
LcritSFT LABEL NEAR
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_leave_local
        cmp     ss:[redir_patch],al
        jz      crit_leave_return
        mov     ax,8100h+critDisk
        int     int_ibm
crit_leave_return:
        pop     ax
        popf
        ret
crit_leave_local:
        cli
        cmp     BYTE PTR ss:[NlsBuffer+2],al
        jns     crit_leave_check
        int     3
crit_leave_check:
        jnz     crit_leave_done
        cmp     BYTE PTR ss:[NlsBuffer],al
        jz      crit_leave_done
        dec     BYTE PTR ss:[NlsBuffer]
crit_leave_done:
        pop     ax
        popf
        ret
EndProc LcritDisk

Procedure LcritConsole,near
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_leave_done
        jmp     short crit_leave_device
EndProc LcritConsole

Procedure LcritDevice,near
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_leave_local
crit_leave_device:
        cmp     ss:[redir_patch],al
        jz      crit_leave_device_done
        mov     ax,8100h+critDevice
        int     int_ibm
crit_leave_device_done:
        pop     ax
        popf
        ret
EndProc LcritDevice

crit_clear_local:
        cli
        cmp     BYTE PTR ss:[NlsBuffer+2],al
        jns     crit_clear_check
        int     3
crit_clear_check:
        jnz     crit_clear_done
        mov     BYTE PTR ss:[NlsBuffer],al
crit_clear_done:
        pop     ax
        popf
        ret

Procedure LcritAll,near
        pushf
        push    ax
        xor     ax,ax
        cmp     WORD PTR ss:[NlsBuffer+18],ax
        jnz     crit_clear_local
        mov     ah,82h
        int     int_ibm
        pop     ax
        popf
        ret
EndProc LcritAll

DOSCODE ENDS
        END
