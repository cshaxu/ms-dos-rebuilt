@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 wrtest.asm,wrtest.obj,wrtest.lst; > wrtest.log
if errorlevel 1 goto failed
link /MAP wrtest.obj,wrtest.exe,wrtest.map; > wrlink.log
if errorlevel 1 goto failed
wrtest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
