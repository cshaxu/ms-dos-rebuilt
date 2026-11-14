@echo off
set PATH=C:\tools
set TEMP=C:\tools
cd \cmd\command
echo Building COMMAND indexed messages > C:\progress.txt
nmake res0.exe > resmake.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
