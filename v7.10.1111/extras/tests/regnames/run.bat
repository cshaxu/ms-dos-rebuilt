@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 rgnew.asm,rgnew.obj,rgnew.lst; > rgnew.log
if errorlevel 1 goto failed
masm /Mx /t /W1 rgold.asm,rgold.obj,rgold.lst; > rgold.log
if errorlevel 1 goto failed
masm /Mx /t /W1 nmtest.asm,nmtest.obj,nmtest.lst; > nmtest.log
if errorlevel 1 goto failed
masm /Mx /t /W1 configio.asm,configio.obj,configio.lst; > configio.log
if errorlevel 1 goto failed
link /MAP nmtest.obj+rgnew.obj+configio.obj+rgold.obj,nmtest.exe,nmtest.map; > nmlink.log
if errorlevel 1 goto failed
nmtest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
