; Disk controller data.
BIOS_CODE SEGMENT
        ORG 0DD6h
step_drv        db      -2
accesscount     db      0
tim_drv         db      -1
medbyt          db      ?
wrtverify       label   word
rflag           db      2
verify          db      0
seccnt          dw      0
motorstartup    db      ?
settlecurrent   db      ?
settleslow      db      ?
save_head_sttl  db      ?
save_eot        db      ?
eot             db      9
dpt             dd      ?
cursec          db      0
curhd           db      0
curtrk          dw      0
spsav           dw      0
temp_h          dw      0
start_sec_h     dw      0
saved_word      dw      0
vretry_cnt      dw      0
soft_ecc_cnt    dw      0
set_id_flag     db      0
fat_12_id       db      "FAT12   ",0
fat_16_id       db      "FAT16   ",0
vol_no_name     db      "NO NAME    ",0
BIOS_CODE ENDS
END
