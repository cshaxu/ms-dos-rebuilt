include biosseg.inc
Bios_Code segment
 assume cs:Bios_Code
 public bin_to_bcd_near,daycnt_to_day_near
bin_to_bcd_near proc near
 ret
bin_to_bcd_near endp
daycnt_to_day_near proc near
 ret
daycnt_to_day_near endp
Bios_Code ends
end
