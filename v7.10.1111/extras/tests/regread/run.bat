@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 rdtest.asm,rdtest.obj,rdtest.lst; > rdtest.log
if errorlevel 1 goto failed
link /MAP rdtest.obj,rdtest.exe,rdtest.map; > rdlink.log
if errorlevel 1 goto failed
rdtest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
