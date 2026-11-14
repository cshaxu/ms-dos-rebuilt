@echo off
set PATH=C:\tools
set INIT=C:\tools
set TEMP=C:\tools
cd \bios
masm /Mx /t /W1 rgcmp.asm,rgcmp.obj,rgcmp.lst; > rgcmp.log
if errorlevel 1 goto failed
masm /Mx /t /W1 cmptest.asm,cmptest.obj,cmptest.lst; > cmptest.log
if errorlevel 1 goto failed
masm /Mx /t /W1 configio.asm,configio.obj,configio.lst; > configio.log
if errorlevel 1 goto failed
link /MAP cmptest.obj+rgcmp.obj+configio.obj,cmptest.exe,cmptest.map; > cmplink.log
if errorlevel 1 goto failed
cmptest.exe
if errorlevel 1 goto failed
echo PASS > C:\BUILD.OK
goto done
:failed
echo FAIL > C:\BUILD.OK
:done
exit
