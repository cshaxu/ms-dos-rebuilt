@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 queryapi.asm,queryapi.obj,queryapi.lst; > queryapi.log
if errorlevel 1 goto failed
link /MAP queryapi.obj,queryapi.exe,queryapi.map; > querylnk.log
if errorlevel 1 goto failed
queryapi.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
