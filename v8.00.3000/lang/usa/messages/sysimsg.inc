; SYSINIT message offsets and text.
; Offsets are relative to sysinit_msg_base.

	public	sysinit_msg_table,sysinit_msg_base


sysinit_msg_table label word
	dw	offset sysinit_msg_00 - offset sysinit_msg_base
	dw	offset sysinit_msg_01 - offset sysinit_msg_base
	dw	offset sysinit_msg_02 - offset sysinit_msg_base
	dw	offset sysinit_msg_03 - offset sysinit_msg_base
	dw	offset sysinit_msg_04 - offset sysinit_msg_base
	public	sysinit_crlf_index
sysinit_crlf_index label word
	dw	offset sysinit_msg_05 - offset sysinit_msg_base
	dw	offset sysinit_msg_06 - offset sysinit_msg_base
	dw	offset sysinit_msg_07 - offset sysinit_msg_base
	public	sysinit_badld_index
sysinit_badld_index label word
	dw	offset sysinit_msg_08 - offset sysinit_msg_base
	public	sysinit_win_index
sysinit_win_index label word
	dw	offset sysinit_msg_09 - offset sysinit_msg_base
	public	sysinit_command_index
sysinit_command_index label word
	dw	offset sysinit_msg_10 - offset sysinit_msg_base
	dw	offset sysinit_msg_11 - offset sysinit_msg_base
	dw	offset sysinit_msg_12 - offset sysinit_msg_base
	dw	offset country_setting_msg - offset sysinit_msg_base
	dw	offset country_file_msg - offset sysinit_msg_base
	dw	offset codepage_error_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_13 - offset sysinit_msg_base
	dw	offset sysinit_msg_14 - offset sysinit_msg_base
	dw	offset sysinit_msg_15 - offset sysinit_msg_base
	dw	offset sysinit_msg_16 - offset sysinit_msg_base
	dw	offset sysinit_msg_17 - offset sysinit_msg_base
	dw	offset sysinit_msg_18 - offset sysinit_msg_base
	dw	offset preparing_startup_msg - offset sysinit_msg_base
	dw	offset emergency_start_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_19 - offset sysinit_msg_base
	dw	offset sysinit_msg_20 - offset sysinit_msg_base
	dw	offset sysinit_msg_21 - offset sysinit_msg_base
	dw	offset safe_mode_status_msg - offset sysinit_msg_base
	public	sysinit_prompt_index
sysinit_prompt_index label word
	dw	offset sysinit_msg_22 - offset sysinit_msg_base
	dw	offset sysinit_msg_23 - offset sysinit_msg_base
	dw	offset sysinit_msg_24 - offset sysinit_msg_base
	dw	offset sysinit_msg_25 - offset sysinit_msg_base
	dw	offset windows_path_msg - offset sysinit_msg_base
	dw	offset windows_path_again_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_26 - offset sysinit_msg_base
	dw	offset sysinit_msg_27 - offset sysinit_msg_base
	dw	offset sysinit_msg_28 - offset sysinit_msg_base
	dw	offset sysinit_msg_29 - offset sysinit_msg_base
	dw	offset sysinit_msg_30 - offset sysinit_msg_base
	dw	offset sysinit_msg_31 - offset sysinit_msg_base
	dw	offset sysinit_msg_32 - offset sysinit_msg_base
	dw	offset sysinit_msg_33 - offset sysinit_msg_base
	dw	offset sysinit_msg_34 - offset sysinit_msg_base
	dw	offset sysinit_msg_35 - offset sysinit_msg_base
	dw	offset smartdrv_msg - offset sysinit_msg_base
	dw	offset country_start_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_36 - offset sysinit_msg_base
	dw	offset sysinit_msg_37 - offset sysinit_msg_base
	dw	offset sysinit_msg_38 - offset sysinit_msg_base
	dw	offset sysinit_msg_39 - offset sysinit_msg_base
	dw	offset sysinit_msg_40 - offset sysinit_msg_base
	dw	offset sysinit_msg_41 - offset sysinit_msg_base
	dw	offset sysinit_msg_42 - offset sysinit_msg_base
	dw	offset sysinit_msg_43 - offset sysinit_msg_base
	dw	offset sysinit_msg_reserved_1 - offset sysinit_msg_base
	dw	offset sysinit_msg_reserved_2 - offset sysinit_msg_base
	dw	offset sysinit_msg_reserved_3 - offset sysinit_msg_base
	dw	offset sysinit_msg_reserved_4 - offset sysinit_msg_base
	dw	offset sysinit_msg_reserved_5 - offset sysinit_msg_base
	dw	offset sysinit_msg_44 - offset sysinit_msg_base
	dw	offset sysinit_msg_45 - offset sysinit_msg_base
	dw	offset sysinit_msg_46 - offset sysinit_msg_base
	dw	offset sysinit_msg_47 - offset sysinit_msg_base
	dw	offset sysinit_msg_48 - offset sysinit_msg_base
	dw	offset sysinit_msg_49 - offset sysinit_msg_base
	dw	offset sysinit_msg_50 - offset sysinit_msg_base
	dw	offset sysinit_msg_52 - offset sysinit_msg_base
	dw	offset startup_memory_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_53 - offset sysinit_msg_base
	dw	offset sysinit_msg_54 - offset sysinit_msg_base
	dw	offset sysinit_msg_55 - offset sysinit_msg_base
	dw	offset sysinit_msg_56 - offset sysinit_msg_base
	dw	offset sysinit_msg_57 - offset sysinit_msg_base
	dw	offset sysinit_msg_58 - offset sysinit_msg_base
	dw	offset sysinit_msg_59 - offset sysinit_msg_base
	dw	offset sysinit_msg_60 - offset sysinit_msg_base
	public	sysinit_stack_msg_index
sysinit_stack_msg_index label word
	dw	offset sysinit_msg_63 - offset sysinit_msg_base
	dw	offset wininit_error_msg - offset sysinit_msg_base
	dw	offset windows_drivers_msg - offset sysinit_msg_base
	public	xms_driver_index
xms_driver_index label word
	dw	offset xms_driver_msg - offset sysinit_msg_base
	public	xms_memory_index
xms_memory_index label word
	dw	offset xms_memory_msg - offset sysinit_msg_base
	public	xms_hma_index
xms_hma_index label word
	dw	offset xms_hma_msg - offset sysinit_msg_base
	public	resume_cr_index
resume_cr_index label word
	dw	offset resume_cr_msg - offset sysinit_msg_base
	public	resume_error_index
resume_error_index label word
	dw	offset resume_error_msg - offset sysinit_msg_base
	public	resume_return_index
resume_return_index label word
	dw	offset resume_return_msg - offset sysinit_msg_base
	public	resume_progress_index
resume_progress_index label word
	dw	offset resume_progress_msg - offset sysinit_msg_base
	public	resume_prompt_index
resume_prompt_index label word
	dw	offset resume_prompt_msg - offset sysinit_msg_base
	dw	offset ifshlp_start_msg - offset sysinit_msg_base
	dw	offset ifshlp_done_msg - offset sysinit_msg_base
	dw	offset sysinit_msg_end - offset sysinit_msg_base

sysinit_msg_base label byte
	public	StartMsg
StartMsg label byte
sysinit_msg_00 label byte
	db	"Starting Windows Millennium...",13,10,13,10,"$",0
sysinit_msg_01 label byte
	db	"Windows Millennium is now starting your MS-DOS-based prog","ram.",13
	db	10,13,10,"$",0
sysinit_msg_02 label byte
	db	"Windows Millennium is now restarting...",13,10,13,10,"$",0
sysinit_msg_03 label byte
	db	"Press Esc now to cancel MS-DOS mode and restart Windows M"
	db	"illennium...$",0
	public	badopm
badopm label byte
sysinit_msg_04 label byte
	db	13,10,"There is an unrecognized command in your CONFIG.SYS file.",13,10,"$",0
	public	crlfm
crlfm label byte
sysinit_msg_05 label byte
	db	13,10,"$",0
	public	badparm
badparm label byte
sysinit_msg_06 label byte
	db	13,10,"The following command in your CONFIG.SYS file is incorrect:",13,10,"$",0
	public	badsiz_pre
badsiz_pre label byte
sysinit_msg_07 label byte
	db	13,10,"The sector size specified in this file is too large: $",0
	public	badld_pre
badld_pre label byte
sysinit_msg_08 label byte
	db	13,10,"The following file is missing or corrupted: $",0
sysinit_msg_09 label byte
	db	"WIN.COM",0
sysinit_msg_10 label byte
	db	"COMMAND.COM",0
	public	badcountry
badcountry label byte
sysinit_msg_11 label byte
	db	13,10,"There is an invalid country code or code page in your CONFIG",".SYS file.",13,10
	db	"$",0
	public	badcountrycom
badcountrycom label byte
sysinit_msg_12 label byte
	db	13,10,"There is an error in the COUNTRY command in your CONFIG.SYS ","file.",13,10,"$",0
country_setting_msg label byte
	db	13,10,"There is an invalid country setting in your registry.",13,10,"$"
	db	0
country_file_msg label byte
	db	13,10,"Cannot find the COUNTRY.SYS file.",13,10,"$",0
codepage_error_msg label byte
	db	13,10,"Cannot set the code page(s) in DISPLAY.SYS.",13,10,"$",0
	public	insufmemory
insufmemory label byte
sysinit_msg_13 label byte
	db	13,10,"There is not enough memory for the COUNTRY.SYS file.",13,10
	db	"Remove some drivers from your CONFIG.SYS file, and then try ","again.",13,10,"$",0
	public	badmem
badmem label byte
sysinit_msg_14 label byte
	db	13,10,"The configuration specified in your CONFIG.SYS file is too l","arge for memory."
	db	13,10,"Remove some drivers, and then try again.",13,10,"$",0
	public	badblock
badblock label byte
sysinit_msg_15 label byte
	db	13,10,"You have too many block devices specified in your CONFIG.SYS"," file.",13,10
	db	"Remove some disk drivers from your CONFIG.SYS file, and then"," try again.",13,10,"$",0
	public	badstack
badstack label byte
sysinit_msg_16 label byte
	db	13,10,"The STACKS setting(s) in your CONFIG.SYS file are incorrect.",13,10
	db	"Default stack settings will be used instead.",13,10,"$",0
	public	errorcmd
errorcmd label byte
sysinit_msg_17 label byte
	db	"There is an error in your CONFIG.SYS file on line $",0
	public	toomanydrivesmsg
toomanydrivesmsg label byte
sysinit_msg_18 label byte
	db	"Warning: Logical drives past Z exist and will be ignored.",13,10,"$",0
preparing_startup_msg label byte
	db	"Now preparing to start your new computer...",13,10,13,10,"$",0
emergency_start_msg label byte
	db	"Starting Windows Millennium Emergency Boot...",13,10,13,10,"$",0
	public	$MenuHeader
$MenuHeader label byte
sysinit_msg_19 label byte
	db	13,10,"  Microsoft Windows Millennium Startup Menu",13,10,"  "
	db	34 dup (205),13,10,"$",0
	public	$MenuPrmpt
$MenuPrmpt label byte
sysinit_msg_20 label byte
	db	"  Enter a choice: $",0
	public	$StatusLine
$StatusLine label byte
sysinit_msg_21 label byte
	db	"  F5=Safe mode  Shift+F5=Command prompt  Shift+F8=Step-by-st","ep confirmation [ ]$",0
safe_mode_status_msg label byte
	db	"  F5=Safe mode  Shift+F8=Step-by-step confirmation [ ]$",0
	public	$InterPrmpt
$InterPrmpt label byte
sysinit_msg_22 label byte
	db	" [Enter=Y,Esc=N]?$",0
	public	$NO
	public	$YES
sysinit_msg_23 label byte
$YES	db	'Y'
$NO	db	'NAyna',0
	public	$TimeOut
$TimeOut label byte
sysinit_msg_24 label byte
	db	"Time remaining: $",0
	public	BadComPrmpt
BadComPrmpt label byte
sysinit_msg_25 label byte
	db	"Type the name of the Command Interpreter (e.g., C:\WINDOWS\C","OMMAND.COM)",13,10,"$",0
windows_path_msg label byte
	db	"Type the name of the Windows loader (e.g., C:\WINDOWS\SYS"
	db	"TEM\VMM32.VXD)",13,10,"$",0
windows_path_again_msg label byte
	db	"Type the name of the Windows loader (e.g., C:\WINDOWS\WIN",".COM)",13
	db	10,"$",0
	public	$PauseMsg
$PauseMsg label byte
sysinit_msg_26 label byte
	db	"Press any key to continue . . .",13,10,"$",0
	public	$CleanMsg
$CleanMsg label byte
sysinit_msg_27 label byte
	db	"Windows is bypassing your startup files.",13,10,13,10,"$",0
sysinit_msg_28 label byte
	db	"Windows is bypassing your startup files.",13,10
	db	"Minimal network support will be loaded if available.",13,10,13,10,"$",0
sysinit_msg_29 label byte
	db	"Windows is starting the command prompt only.",13,10,13,10,"$",0
	public	$InterMsg
$InterMsg label byte
sysinit_msg_30 label byte
	db	"Windows will prompt you to confirm each startup command.",13,10,13,10,"$",0
sysinit_msg_31 label byte
	db	"Load DoubleSpace driver [Enter=Y,Esc=N]?$",0
sysinit_msg_32 label byte
	db	"Load DriveSpace driver [Enter=Y,Esc=N]?$",0
sysinit_msg_33 label byte
	db	"The compression driver cannot be set up correctly.",13,10
	db	"Get a version from your vendor that is compatible with this ","version of Windows.",13
	db	10,"$",0
sysinit_msg_34 label byte
	db	"Process the system registry [Enter=Y,Esc=N]?$",0
sysinit_msg_35 label byte
	db	"Create a startup log file (BOOTLOG.TXT) [Enter=Y,Esc=N]?$",0
smartdrv_msg label byte
	db	"Enable SMARTDRV disk cache [Enter=Y,Esc=N]?$",0
country_start_msg label byte
	db	"Load and initialize country and code page settings [Enter"
	db	"=Y,Esc=N]?$",0
sysinit_msg_36 label byte
	db	"Process your startup device drivers (CONFIG.SYS) [Enter=Y,Es","c=N]?$",0
sysinit_msg_37 label byte
	db	"Process your startup command file (AUTOEXEC.BAT) [Enter=Y,Es","c=N]?$",0
sysinit_msg_38 label byte
	db	"Load the Windows graphical user interface [Enter=Y,Esc=N]?$",0
sysinit_msg_39 label byte
	db	"  Warning: Windows has detected a registry/configuration ","error.",13
	db	10,"  Use SCANREG to correct this error.",13,10,"$",0
sysinit_msg_40 label byte
	db	"  Warning: Windows has detected a compressed drive access er","ror.",13,10
	db	"  Choose Safe mode command prompt only, to help you identify"," the problem.",13,10,"$"
	db	0
sysinit_msg_41 label byte
	db	"  Warning: Windows did not finish loading on the previous at","tempt.",13,10
	db	"  Choose Safe mode, to start Windows with a minimal set of d","rivers.",13,10,"$",0
sysinit_msg_42 label byte
	db	"Warning: Windows multi-boot may not function correctly.",13,10
	db	"Check for system files in your root directory with conflicti","ng extensions.",13,10,"$"
	db	0
sysinit_msg_43 label byte
	db	"Warning: the system configuration manager failed to run.",13,10
	db	"Some of your real-mode device drivers may not initialize pro","perly.",13,10,"$",0
sysinit_msg_reserved_1 label byte
	db	173 dup (" "),"$",0
sysinit_msg_reserved_2 label byte
	db	72 dup (" "),"$",0
sysinit_msg_reserved_3 label byte
	db	34 dup (" "),"$",0
sysinit_msg_reserved_4 label byte
	db	"   $   $   $   $   $   $   $   $   $   $   $   $",0
sysinit_msg_reserved_5 label byte
	db	125 dup (" "),"$",0
sysinit_msg_44 label byte
	db	"Normal",0,0
sysinit_msg_45 label byte
	db	"Logged (\BOOTLOG.TXT)",0,0
sysinit_msg_46 label byte
	db	"Safe mode",0,0
sysinit_msg_47 label byte
	db	"Safe mode with network support",0,0
sysinit_msg_48 label byte
	db	"Step-by-step confirmation",0,0
sysinit_msg_49 label byte
	db	"Command prompt only",0,0
sysinit_msg_50 label byte
	db	"Safe mode command prompt only",0,0
sysinit_msg_52 label byte
	db	13,10,"The BUFFERS setting(s) in your CONFIG.SYS file are too large",".",13,10
	db	"Default buffer settings will be used instead.",13,10,"$",0
startup_memory_msg label byte
	db	13,10,"A memory allocation error occurred during startup.",13,10
	db	"Restart your computer and select Minimal boot.",13,10,"$",0
sysinit_msg_53 label byte
	db	13,10,"A memory allocation error occurred during startup.",13,10
	db	"Restart your computer and select Interactive Start to identi","fy the problem.",13,10
	db	"$",0
sysinit_msg_54 label byte
	db	13,10,"Warning: the high memory area (HMA) is not available.",13,10
	db	"Additional low memory (below 640K) will be used instead.",13,10,"$",0
sysinit_msg_55 label byte
	db	"There is not enough memory for Windows.",13,10
	db	"Remove some drivers from your CONFIG.SYS file, and then try ","again.",13,10,"$",0
sysinit_msg_56 label byte
	db	"Your previous MS-DOS files were not found.  $",0
sysinit_msg_57 label byte
	db	"Your previous MS-DOS version is not supported.  $",0
sysinit_msg_58 label byte
	db	"MS-DOS startup failed.",13,10,13,10,"$",0
sysinit_msg_59 label byte
	db	"Now loading your previous version of MS-DOS, please wait.",13,10,13,10,"$",0
sysinit_msg_60 label byte
	db	"Invalid setting in the MSDOS.SYS file: $",0
sysinit_msg_63 label byte
	db	13,10,7,13,10,"An internal stack overflow has caused this session to be hal","ted.",13,10
	db	"Change the STACKS setting in your CONFIG.SYS file, and then ","try again.",13,10,0,0
wininit_error_msg label byte
	db	"WININIT.EXE: Missing/unable to load.",13,10,"$",0
windows_drivers_msg label byte
	db	"Load all Windows drivers [Enter=Y,Esc=N]?$",0
xms_driver_msg label byte
	db	7,"       XMS Driver not installed. Serious hardware problem, halting boot.",13,10,"$",0
xms_memory_msg label byte
	db	"ERROR: No available extended memory was found.",13,10,"$",0
xms_hma_msg label byte
	db	"ERROR: The High Memory Area (HMA) is unavailable.",13,10,"$",0
resume_cr_msg label byte
	db	13,"$",0
resume_error_msg label byte
	db	13,10,13,10,"Failed to resume from hibernate.",13,10,"$",0
resume_return_msg label byte
	db	13,25 dup (10),25 dup (" "),"Returning to Windows ...",13,10,"  $",0
resume_progress_msg label byte
	db	0dbh,"$",0
resume_prompt_msg label byte
	db	13,10,"Previous resume from hibernate failed.",13,10
	db	"  Would you like to try again [Enter=Y,Esc=N]?$",0
ifshlp_start_msg label byte
	db	"Loading and initializing IFSHLP.SYS driver...$",0
ifshlp_done_msg label byte
	db	"    Complete.",13,10,"$",0
sysinit_msg_end label byte
