@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 ictest.asm,ictest.obj,ictest.lst; > ictest.log
if errorlevel 1 goto failed
link /MAP ictest.obj,ictest.exe,ictest.map; > iclink.log
if errorlevel 1 goto failed
ictest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
