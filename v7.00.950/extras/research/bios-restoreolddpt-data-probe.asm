; Disk format data and RestoreOldDpt, isolated target-layout experiment.
BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
        ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
DskAdr = 1Eh * 4
        ORG 1796h
tempdpt                 dd      -1
formt_eot               db      8
hdnum                   db      0
trknum                  dw      0
gap_patch               db      50h
xfer_seg                dw      0
mediatype               db      0
media_set_for_format    db      0
had_format_error        db      0
sectorspertrack         dw      36
        ORG 1D14h
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
