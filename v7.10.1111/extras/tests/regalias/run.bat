@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 rgnew.asm,rgnew.obj,rgnew.lst; > rgnew.log
if errorlevel 1 goto failed
masm /Mx /t /W1 altest.asm,altest.obj,altest.lst; > altest.log
if errorlevel 1 goto failed
masm /Mx /t /W1 configio.asm,configio.obj,configio.lst; > configio.log
if errorlevel 1 goto failed
link /MAP altest.obj+rgnew.obj+configio.obj,altest.exe,altest.map; > allink.log
if errorlevel 1 goto failed
altest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
