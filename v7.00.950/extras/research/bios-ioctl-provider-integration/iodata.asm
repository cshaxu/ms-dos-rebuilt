; Disk format data and RestoreOldDpt, isolated target-layout experiment.
BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
        ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
DskAdr = 1Eh * 4
        PUBLIC tempdpt,formt_eot,hdnum,trknum,gap_patch,xfer_seg
        PUBLIC mediatype,media_set_for_format,had_format_error,sectorspertrack
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
BIOS_CODE ENDS
        END
