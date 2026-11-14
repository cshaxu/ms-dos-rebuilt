@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 ixtest.asm,ixtest.obj,ixtest.lst; > ixtest.log
if errorlevel 1 goto failed
link /MAP ixtest.obj,ixtest.exe,ixtest.map; > ixlink.log
if errorlevel 1 goto failed
ixtest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
