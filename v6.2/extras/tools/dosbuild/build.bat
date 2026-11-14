@echo off
set PATH=C:\tools
if errorlevel 1 goto failed
set INIT=C:\tools
if errorlevel 1 goto failed
set COUNTRY=USA
if errorlevel 1 goto failed
set TEMP=C:\tools
if errorlevel 1 goto failed
echo Preparing system messages > C:\progress.txt
cd \messages
if errorlevel 1 goto failed
buildidx USA.MSG > idx.log
if errorlevel 1 goto failed
echo Building IO.SYS > C:\progress.txt
cd \bios
if errorlevel 1 goto failed
nmake io.sys > make.log
if errorlevel 1 goto failed
echo Building MSDOS.SYS > C:\progress.txt
cd \dos
if errorlevel 1 goto failed
nmake msdos.sys > make.log
if errorlevel 1 goto failed
echo Preparing COMMAND messages > C:\progress.txt
cd \cmdmsg
if errorlevel 1 goto failed
buildidx USA.MSG > idx.log
if errorlevel 1 goto failed
echo Building COMMAND.COM > C:\progress.txt
cd \cmd\command
if errorlevel 1 goto failed
buildmsg ..\..\cmdmsg\USA command.skl > msg.log
if errorlevel 1 goto failed
nmake command.com msg=..\..\cmdmsg LANG_SRC=..\..\lang > make.log
if errorlevel 1 goto failed
echo Compilation complete > C:\progress.txt
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
