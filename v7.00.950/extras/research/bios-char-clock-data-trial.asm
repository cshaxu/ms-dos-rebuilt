; Character and clock data, isolated target-layout experiment.
Bios_Code segment word public 'Bios_Code'
        org     072Eh
printdev        dw      0
wait_count      dw      4 dup (50h)
auxnum          dw      0
auxbuf          db      4 dup (0)
base_century    db      19
base_year       db      80
month_tab       db      31,28,31,30,31,30,31,31,30,31,30,31
bin_date_time   db      4 dup (0)
month_table     dw      0,31,59,90,120,151,181,212,243,273,304,334
Bios_Code ends
        end
