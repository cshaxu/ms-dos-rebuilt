@echo off
set PATH=C:\tools
cd \bios
echo Linking and packing configuration > C:\progress.txt
link /EXEPACK /STACK:8192 /MAP @config.lnk > cfg-link.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
