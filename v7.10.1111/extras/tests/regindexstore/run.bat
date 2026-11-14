@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 istest.asm,istest.obj,istest.lst; > istest.log
if errorlevel 1 goto failed
link /MAP istest.obj,istest.exe,istest.map; > islink.log
if errorlevel 1 goto failed
istest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
