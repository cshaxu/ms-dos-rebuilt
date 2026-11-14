@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 cptest.asm,cptest.obj,cptest.lst; > cptest.log
if errorlevel 1 goto failed
link /MAP cptest.obj,cptest.exe,cptest.map; > cplink.log
if errorlevel 1 goto failed
cptest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
