@echo off
set PATH=C:\tools
cd \bios
echo Linking the uncompressed configuration image > C:\progress.txt
link /STACK:8192 /MAP @config.lnk > cfg-raw.log
if errorlevel 1 goto failed
ren config.exe config-r.exe
if errorlevel 1 goto failed
ren config.map config-r.map
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
