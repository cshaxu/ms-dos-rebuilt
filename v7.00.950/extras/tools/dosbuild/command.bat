@echo off
set PATH=C:\tools
set INCLUDE=C:\include
set LIB=C:\lib
set TEMP=C:\tools
cd \cmd\command
echo Building COMMAND message compiler > C:\progress.txt
nmake buildmsg.exe > msgbuild.log
if errorlevel 1 goto failed
buildidx usa-ms.msg > idx.log
if errorlevel 1 goto failed
buildmsg usa-ms command.skl > msg.log
if errorlevel 1 goto failed
echo Building COMMAND and message resources > C:\progress.txt
nmake all > make.log
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
