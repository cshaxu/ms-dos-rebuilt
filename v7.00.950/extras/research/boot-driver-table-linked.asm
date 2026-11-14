sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
boot_check_xms equ 01a65h
boot_check_aspi equ 04c01h
boot_double_provider equ 04bd6h
boot_check_ifshlp equ 04c0eh
boot_check_setver equ 04c13h
boot_check_umb_manager equ 04ac0h
aspi2hlp_name equ 04250h
 org 4229h
boot_himem_name db '\HIMEM.SYS',0,'/TESTMEM:ON',0dh
 org 425eh
boot_dblbuff_name db '\DBLBUFF.SYS',0,'/D+',0dh
boot_ifshlp_driver db '\IFSHLP.SYS',0
boot_setver_driver db '\SETVER.EXE',0
 org 42abh
; Startup driver records: check procedure, name, length and flags.
boot_autoexec_name db '\AUTOEXEC.BAT',0
boot_driver_table label word
        dw      offset boot_check_xms,offset boot_himem_name
        db      17h,81h
        dw      offset boot_check_aspi,offset aspi2hlp_name
        db      0eh,0
        dw      offset boot_double_provider,offset boot_dblbuff_name
boot_driver_entry1 db 11h,81h
        dw      offset boot_check_ifshlp,offset boot_ifshlp_driver
        db      0ch,1
        dw      offset boot_check_setver,offset boot_setver_driver
        db      0ch,0
        dw      0
boot_umb_driver_record label word
        dw      offset boot_check_umb_manager,offset boot_dblbuff_name
boot_driver_entry2 db 11h,80h
boot_driver_depth db 0ffh
sysinitseg ends
end
