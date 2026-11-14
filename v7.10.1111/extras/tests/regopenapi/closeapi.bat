@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 closeapi.asm,closeapi.obj,closeapi.lst; > closeapi.log
if errorlevel 1 goto failed
link /MAP closeapi.obj,closeapi.exe,closeapi.map; > closelnk.log
if errorlevel 1 goto failed
closeapi.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
