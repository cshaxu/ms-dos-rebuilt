@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 ostest.asm,ostest.obj,ostest.lst; > ostest.log
if errorlevel 1 goto failed
link /MAP ostest.obj,ostest.exe,ostest.map; > oslink.log
if errorlevel 1 goto failed
ostest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
