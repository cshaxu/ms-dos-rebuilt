@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 qrycore.asm,qrycore.obj,qrycore.lst; > qrycore.log
if errorlevel 1 goto failed
link /MAP qrycore.obj,qrycore.exe,qrycore.map; > qrylnk.log
if errorlevel 1 goto failed
qrycore.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
