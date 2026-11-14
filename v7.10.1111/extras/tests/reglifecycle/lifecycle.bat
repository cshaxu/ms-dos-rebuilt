@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 lifetst.asm,lifetst.obj,lifetst.lst; > lifetst.log
if errorlevel 1 goto failed
link /MAP lifetst.obj,lifetst.exe,lifetst.map; > lifelnk.log
if errorlevel 1 goto failed
lifetst.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
