@echo off
set PATH=C:\tools
cd \crtlib
echo Rebuilding original CRT library > C:\progress.txt
lib @make.rsp > lib.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
