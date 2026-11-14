include biosseg.inc
Bios_Data segment
 assume cs:Bios_Data
 public ttticks,inHMA,int19sem,multrk_flag,multitrk_format_flag
 public Win386_SI,SI_Version,SI_Next,NextStack,IT_StackLoc,IT_StackSize,IsWin386,V86_Crit_SetFocus
 public FreeHMAPtr,MoveDOSIntoHMA,SysinitPresent
 public t_switch,havecmosclock,bintobcd,daycnttoday,int6c_ret_addr,dsktnum,disksector,feb29,re_init,zeroseg,prevoper,number_of_sec,fhave96,single,fhavek09,fsetowner
 ttticks dd 0
 inHMA db 0
 int19sem db 0
 t_switch db 0
 havecmosclock db 0
 bintobcd dd 0
 daycnttoday dd 0
 int6c_ret_addr dd 0
 dsktnum db 1
 disksector db 512 dup (0)
 feb29 db 0
 zeroseg dw 0
 re_init proc far
 ret
 re_init endp
 Win386_SI label byte
 SI_Version db 3,0
 SI_Next dd 0
 NextStack dd 0
 IT_StackLoc dd 0
 IT_StackSize dw 0
 IsWin386 db 0
 V86_Crit_SetFocus proc far
 ret
 V86_Crit_SetFocus endp
 FreeHMAPtr dw 0ffffh
 MoveDOSIntoHMA dd 0
 SysinitPresent db 0
 prevoper dw 0
 number_of_sec db 0
 fhave96 db 0
 single db 0
 fhavek09 db 0
 fsetowner db 0
 multrk_flag dw 0
 multitrk_format_flag db 0
Bios_Data ends
Bios_Code segment
 assume cs:Bios_Code
public bios_msg_base,bios_msg_1,bios_msg_2,bios_msg_3,exec_bios_word,read_real_date,read_real_time,auxnum,auxbuf,printdev,start_sec_h,sysinit_seg,seg_reinit
public wait_count,base_century,base_year,month_tab,bin_date_time,month_table
public errin,errout,lsterr,numerr,fat_12_id,fat_16_id,vol_no_name
public sm92,accesscount,tim_drv,set_id_flag,step_drv
public vretry_cnt,soft_ecc_cnt,ec35_flag
public medbyt,wrtverify,rflag,seccnt,spsav
public dpt,cursec,curhd,curtrk,temp_h,saved_word
public motorstartup,settlecurrent,settleslow,save_eot,eot
public save_head_sttl
public nul_vid,tmp_vid
bios_msg_1 dw 0
bios_msg_2 dw 0
bios_msg_3 dw 0
bios_msg_base db 0
exec_bios_word dw 0
auxnum dw 0
auxbuf db 4 dup (0)
wait_count dw 4 dup (50h)
base_century db 19
base_year db 80
month_tab db 31,28,31,30,31,30,31,31,30,31,30,31
bin_date_time db 4 dup (0)
month_table dw 0,31,59,90,120,151,181,212,243,273,304,334
errin db 0cch,80h,40h,10h,8,6,4,3
lsterr db 0
errout db 10,2,6,4,4,15,8,0,12
numerr = errout-errin
fat_12_id db 'FAT12   ',0
fat_16_id db 'FAT16   ',0
vol_no_name db 'NO NAME    ',0
sm92 db 3,9,70h,0a0h,05h,2,2
accesscount db 0
tim_drv db -1
step_drv db -2
vretry_cnt dw 0
soft_ecc_cnt dw 0
ec35_flag db 0
set_id_flag db 0
medbyt db 0
wrtverify label word
rflag db 2
verify db 0
seccnt dw 0
spsav dw 0
dpt dd 0
cursec db 0
curhd db 0
curtrk dw 0
temp_h dw 0
saved_word dw 0
motorstartup db 0
settlecurrent db 0
settleslow db 0
save_eot db 0
eot db 9
save_head_sttl db 0
nul_vid db 'NO NAME    ',0
tmp_vid db 'NO NAME    ',0
printdev dw 0
start_sec_h dw 0
sysinit_seg dw 0
read_real_date proc near
 ret
read_real_date endp
read_real_time proc near
 ret
read_real_time endp
seg_reinit proc far
 ret
seg_reinit endp
Bios_Code ends
sysinitseg segment
 assume cs:sysinitseg
 public bios_data_segment,move_myself,exec_windows_path,exec_boot_state
 exec_windows_path db 64 dup (0)
 exec_boot_state db 0
 bios_data_segment dw Bios_Data
move_myself proc near
 ret
move_myself endp
sysinitseg ends
end
