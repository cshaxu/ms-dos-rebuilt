; Temporary unresolved initialization symbols for diagnostic link only.
include biosseg.inc
Bios_Data segment
 public bios_a20_msg,bios_cpu_msg
bios_a20_msg dw 0
bios_cpu_msg dw 0
Bios_Data ends
SysInitSeg segment
 public boot_load_segment,boot_data_high,boot_data_low
 public no_floppy_report,sys_model_byte,sys_scnd_model_byte
 public rpl_memory_size,boot_copy_buffer,boot_reloc_segment
 public sysinit_bios_start,sysinit_bios_paras
 public sysinit_reserve_count,sysinit_reserve_size
boot_load_segment dw 0
boot_data_high dw 0
boot_data_low dw 0
no_floppy_report db 0
sys_model_byte db 0
sys_scnd_model_byte db 0
rpl_memory_size dw 0
boot_copy_buffer db 0
boot_reloc_segment dw 0
sysinit_bios_start dw 0
sysinit_bios_paras dw 0
sysinit_reserve_count dw 0
sysinit_reserve_size db 0
SysInitSeg ends
end
