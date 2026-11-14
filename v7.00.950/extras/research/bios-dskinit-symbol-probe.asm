BIOS_DATA SEGMENT
        ORG 0068h
drvmax db 0
BIOS_DATA ENDS
SYSINITSEG SEGMENT
        ORG 0EAEh
dskdrvs dw 0
SYSINITSEG ENDS
BIOS_CODE SEGMENT
ASSUME CS:BIOS_CODE,DS:BIOS_DATA,ES:NOTHING
        ORG 0E65h
dsk_init PROC NEAR
        mov ah,byte ptr drvmax
        mov es,cs:config_init_segment
        mov di,offset dskdrvs
        jmp setptrsav
dsk_init ENDP
        ORG 0F6Bh
setptrsav: ret
        ORG 2B4Eh
config_init_segment dw 0
BIOS_CODE ENDS
END
