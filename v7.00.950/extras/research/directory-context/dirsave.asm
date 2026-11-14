; Directory position saved while removing directory entries
DIRSAVE STRUC
        ds_count        dw      0
        ds_first        dw      0
        ds_sector       dd      0
        ds_cluster      dw      0
        ds_entry        dw      0
        ds_last         dw      0
DIRSAVE ENDS

DOSDATA SEGMENT
DirSave1        DIRSAVE <>
DirSave2        DIRSAVE <>
DirSave3        DIRSAVE <>
DOSDATA ENDS
END
