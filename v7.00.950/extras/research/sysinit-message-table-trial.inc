; SYSINIT message offsets and text.
; Offsets are relative to sysinit_msg_base.

	public	sysinit_msg_table,sysinit_msg_base
	public	sysinit_stack_msg_index

sysinit_msg_table label word
	dw	offset sysinit_msg_00 - offset sysinit_msg_base
	dw	offset sysinit_msg_01 - offset sysinit_msg_base
	dw	offset sysinit_msg_02 - offset sysinit_msg_base
	dw	offset sysinit_msg_03 - offset sysinit_msg_base
	dw	offset sysinit_msg_04 - offset sysinit_msg_base
	dw	offset sysinit_msg_05 - offset sysinit_msg_base
	dw	offset sysinit_msg_06 - offset sysinit_msg_base
	dw	offset sysinit_msg_07 - offset sysinit_msg_base
	dw	offset sysinit_msg_08 - offset sysinit_msg_base
	dw	offset sysinit_msg_09 - offset sysinit_msg_base
	dw	offset sysinit_msg_10 - offset sysinit_msg_base
	dw	offset sysinit_msg_11 - offset sysinit_msg_base
	dw	offset sysinit_msg_12 - offset sysinit_msg_base
	dw	offset sysinit_msg_13 - offset sysinit_msg_base
	dw	offset sysinit_msg_14 - offset sysinit_msg_base
	dw	offset sysinit_msg_15 - offset sysinit_msg_base
	dw	offset sysinit_msg_16 - offset sysinit_msg_base
	dw	offset sysinit_msg_17 - offset sysinit_msg_base
	dw	offset sysinit_msg_18 - offset sysinit_msg_base
	dw	offset sysinit_msg_19 - offset sysinit_msg_base
	dw	offset sysinit_msg_20 - offset sysinit_msg_base
	dw	offset sysinit_msg_21 - offset sysinit_msg_base
	dw	offset sysinit_msg_22 - offset sysinit_msg_base
	dw	offset sysinit_msg_23 - offset sysinit_msg_base
	dw	offset sysinit_msg_24 - offset sysinit_msg_base
	dw	offset sysinit_msg_25 - offset sysinit_msg_base
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
	dw	offset sysinit_msg_36 - offset sysinit_msg_base
	dw	offset sysinit_msg_37 - offset sysinit_msg_base
	dw	offset sysinit_msg_38 - offset sysinit_msg_base
	dw	offset sysinit_msg_39 - offset sysinit_msg_base
	dw	offset sysinit_msg_40 - offset sysinit_msg_base
	dw	offset sysinit_msg_41 - offset sysinit_msg_base
	dw	offset sysinit_msg_42 - offset sysinit_msg_base
	dw	offset sysinit_msg_43 - offset sysinit_msg_base
	dw	offset sysinit_msg_44 - offset sysinit_msg_base
	dw	offset sysinit_msg_45 - offset sysinit_msg_base
	dw	offset sysinit_msg_46 - offset sysinit_msg_base
	dw	offset sysinit_msg_47 - offset sysinit_msg_base
	dw	offset sysinit_msg_48 - offset sysinit_msg_base
	dw	offset sysinit_msg_49 - offset sysinit_msg_base
	dw	offset sysinit_msg_50 - offset sysinit_msg_base
	dw	offset sysinit_msg_51 - offset sysinit_msg_base
	dw	offset sysinit_msg_52 - offset sysinit_msg_base
	dw	offset sysinit_msg_53 - offset sysinit_msg_base
	dw	offset sysinit_msg_54 - offset sysinit_msg_base
	dw	offset sysinit_msg_55 - offset sysinit_msg_base
	dw	offset sysinit_msg_56 - offset sysinit_msg_base
	dw	offset sysinit_msg_57 - offset sysinit_msg_base
	dw	offset sysinit_msg_58 - offset sysinit_msg_base
	dw	offset sysinit_msg_59 - offset sysinit_msg_base
	dw	offset sysinit_msg_60 - offset sysinit_msg_base
	dw	offset sysinit_msg_61 - offset sysinit_msg_base
	dw	offset sysinit_msg_62 - offset sysinit_msg_base
sysinit_stack_msg_index label word
	dw	offset sysinit_msg_63 - offset sysinit_msg_base
	dw	offset sysinit_msg_end - offset sysinit_msg_base

sysinit_msg_base label byte
sysinit_msg_00 label byte
	db	"Starting Windows 95...",13,10,13,10,"$",0
sysinit_msg_01 label byte
	db	"Windows 95 is now starting your MS-DOS-based program.",13,10,13,10,"$",0
sysinit_msg_02 label byte
	db	"Windows 95 is now restarting...",13,10,13,10,"$",0
sysinit_msg_03 label byte
	db	"Press Esc now to cancel MS-DOS mode and restart Windows 95..",".$",0
sysinit_msg_04 label byte
	db	13,10,"There is an unrecognized command in your CONFIG.SYS file.",13,10,"$",0
sysinit_msg_05 label byte
	db	13,10,"$",0
sysinit_msg_06 label byte
	db	13,10,"The following command in your CONFIG.SYS file is incorrect:",13,10,"$",0
sysinit_msg_07 label byte
	db	13,10,"The sector size specified in this file is too large: $",0
sysinit_msg_08 label byte
	db	13,10,"The following file is missing or corrupted: $",0
sysinit_msg_09 label byte
	db	"WIN.COM",0
sysinit_msg_10 label byte
	db	"COMMAND.COM",0
sysinit_msg_11 label byte
	db	13,10,"There is an invalid country code or code page in your CONFIG",".SYS file.",13,10
	db	"$",0
sysinit_msg_12 label byte
	db	13,10,"There is an error in the COUNTRY command in your CONFIG.SYS ","file.",13,10,"$",0
sysinit_msg_13 label byte
	db	13,10,"There is not enough memory for the COUNTRY.SYS file.",13,10
	db	"Remove some drivers from your CONFIG.SYS file, and then try ","again.",13,10,"$",0
sysinit_msg_14 label byte
	db	13,10,"The configuration specified in your CONFIG.SYS file is too l","arge for memory."
	db	13,10,"Remove some drivers, and then try again.",13,10,"$",0
sysinit_msg_15 label byte
	db	13,10,"You have too many block devices specified in your CONFIG.SYS"," file.",13,10
	db	"Remove some disk drivers from your CONFIG.SYS file, and then"," try again.",13,10,"$",0
sysinit_msg_16 label byte
	db	13,10,"The STACKS setting(s) in your CONFIG.SYS file are incorrect.",13,10
	db	"Default stack settings will be used instead.",13,10,"$",0
sysinit_msg_17 label byte
	db	"There is an error in your CONFIG.SYS file on line $",0
sysinit_msg_18 label byte
	db	"Warning: Logical drives past Z exist and will be ignored.",13,10,"$",0
sysinit_msg_19 label byte
	db	13,10,"  Microsoft Windows 95 Startup Menu",13,10,"  ",205,205,205,205,205,205,205,205
	db	205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205,205
	db	205,205,205,205,13,10,"$",0
sysinit_msg_20 label byte
	db	"  Enter a choice: $",0
sysinit_msg_21 label byte
	db	"  F5=Safe mode  Shift+F5=Command prompt  Shift+F8=Step-by-st","ep confirmation [ ]$",0
sysinit_msg_22 label byte
	db	" [Enter=Y,Esc=N]?$",0
sysinit_msg_23 label byte
	db	"YNAyna",0
sysinit_msg_24 label byte
	db	"Time remaining: $",0
sysinit_msg_25 label byte
	db	"Type the name of the Command Interpreter (e.g., C:\WINDOWS\C","OMMAND.COM)",13,10,"$",0
sysinit_msg_26 label byte
	db	"Press any key to continue . . .",13,10,"$",0
sysinit_msg_27 label byte
	db	"Windows is bypassing your startup files.",13,10,13,10,"$",0
sysinit_msg_28 label byte
	db	"Windows is bypassing your startup files.",13,10
	db	"Minimal network support will be loaded if available.",13,10,13,10,"$",0
sysinit_msg_29 label byte
	db	"Windows is starting the command prompt only.",13,10,13,10,"$",0
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
sysinit_msg_36 label byte
	db	"Process your startup device drivers (CONFIG.SYS) [Enter=Y,Es","c=N]?$",0
sysinit_msg_37 label byte
	db	"Process your startup command file (AUTOEXEC.BAT) [Enter=Y,Es","c=N]?$",0
sysinit_msg_38 label byte
	db	"Load the Windows graphical user interface [Enter=Y,Esc=N]?$",0
sysinit_msg_39 label byte
	db	"  Warning: Windows has detected a registry/configuration err","or.",13,10
	db	"  Choose Safe mode, to start Windows with a minimal set of d","rivers.",13,10,"$",0
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
sysinit_msg_51 label byte
	db	"Previous version of MS-DOS",0,0
sysinit_msg_52 label byte
	db	13,10,"The BUFFERS setting(s) in your CONFIG.SYS file are too large",".",13,10
	db	"Default buffer settings will be used instead.",13,10,"$",0
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
sysinit_msg_61 label byte
	db	"This version of Windows requires a 386 or better processor.",13,10,"$",0
sysinit_msg_62 label byte
	db	13,10,"A20 hardware error.  Contact technical support to identify t","he problem.",13,10
	db	"$",0
sysinit_msg_63 label byte
	db	13,10,7,13,10,"An internal stack overflow has caused this session to be hal","ted.",13,10
	db	"Change the STACKS setting in your CONFIG.SYS file, and then ","try again.",13,10,0,0
sysinit_msg_end label byte
