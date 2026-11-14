@echo off
set PATH=C:\tools
set INIT=C:\tools
set COUNTRY=USA
set TEMP=C:\tools
cd \messages
buildidx USA.MSG > idx.log
if errorlevel 1 goto failed
cd \bios
echo Building BIOS and loader > C:\progress.txt
nmake all > make.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
