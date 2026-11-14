; Clock entry placement experiment; not a production provider.
Bios_Code segment byte public 'Bios_Code'
        assume cs:Bios_Code
        extrn read_real_date:near,read_real_time:near
        public clock_entry_trial,clock_update_trial
clock_entry_trial proc far
        call clock_update_trial
        ret 2
clock_entry_trial endp
clock_update_trial proc near
        call read_real_date
        call read_real_time
        mov ah,1
        int 1Ah
        ret
clock_update_trial endp
Bios_Code ends
        end
