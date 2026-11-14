@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 openapi.asm,openapi.obj,openapi.lst; > openapi.log
if errorlevel 1 goto failed
link /MAP openapi.obj,openapi.exe,openapi.map; > openlnk.log
if errorlevel 1 goto failed
openapi.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
