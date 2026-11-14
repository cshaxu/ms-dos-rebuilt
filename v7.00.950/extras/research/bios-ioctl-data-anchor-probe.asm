; Disk format and IOCTL data, target-layout experiment.
BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
        ASSUME CS:BIOS_CODE
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
        ORG 18C0h
start:  mov     CS:mediatype,AL
        ORG 18FDh
        mov     CS:sectorspertrack,CX
        ORG 1980h
        mov     CS:trknum,AX
        mov     BYTE PTR CS:hdnum,CL
BIOS_CODE ENDS
        END start
