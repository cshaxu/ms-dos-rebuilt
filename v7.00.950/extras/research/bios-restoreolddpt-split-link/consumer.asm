BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
        ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
DskAdr = 1Eh * 4
        EXTRN tempdpt:DWORD,media_set_for_format:BYTE,had_format_error:BYTE
        ORG 056Eh
RestoreOldDpt PROC NEAR
        push    AX
        xor     AL,AL
        mov     CS:[Had_Format_Error],AL
        xchg    CS:[Media_Set_For_Format],AL
        or      AL,AL
        jz      DontRestore
        push    SI
        push    DS
        push    ES
        lds     SI,CS:[TempDpt]
        sub     AX,AX
        mov     ES,AX
        mov     WORD PTR ES:[DskAdr],SI
        mov     WORD PTR ES:[DskAdr+2],DS
        pop     ES
        pop     DS
        pop     SI
DontRestore:
        pop     AX
        clc
        ret
RestoreOldDpt ENDP
BIOS_CODE ENDS
        END RestoreOldDpt
