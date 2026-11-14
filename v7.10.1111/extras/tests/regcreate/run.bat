@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 rgnew.asm,rgnew.obj,rgnew.lst; > rgnew.log
if errorlevel 1 goto failed
masm /Mx /t /W1 configio.asm,configio.obj,configio.lst; > configio.log
if errorlevel 1 goto failed
masm /Mx /t /W1 createt.asm,createt.obj,createt.lst; > createt.log
if errorlevel 1 goto failed
link /MAP createt.obj+rgnew.obj+configio.obj,createt.exe,createt.map; > createln.log
if errorlevel 1 goto failed
createt.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
