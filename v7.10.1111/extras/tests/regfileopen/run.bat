@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 fotest.asm,fotest.obj,fotest.lst; > fotest.log
if errorlevel 1 goto failed
link /MAP fotest.obj,fotest.exe,fotest.map; > folink.log
if errorlevel 1 goto failed
fotest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
