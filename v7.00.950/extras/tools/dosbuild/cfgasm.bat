@echo off
set PATH=C:\tools
set TEMP=C:\tools
cd \bios
echo Building configuration and registry > C:\progress.txt
nmake /f config.mak all > config.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
