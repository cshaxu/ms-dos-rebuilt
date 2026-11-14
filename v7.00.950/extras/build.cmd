@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0.."
if errorlevel 1 goto entry_failed
if not exist extras\build mkdir extras\build
mkdir extras\build\manual-build.lock 2>nul
if errorlevel 1 (
    echo ERROR: Build lock exists. Check for a running build before removing it.
    popd
    goto entry_failed
)
call :build
set "RESULT=%errorlevel%"
rmdir extras\build\manual-build.lock
popd
echo Build finished with exit code %RESULT%. Review the output above.
pause
exit /b %RESULT%
:entry_failed
pause
exit /b 1

:build
set "ROOT=%CD%"
set "SUPPORT=%ROOT%\extras\tools\dosbuild"
set "TARGETS=%ROOT%\extras\baselines\targets"
set "ASSETS=%ROOT%\extras\assets"
set "STAGE=%ROOT%\extras\build\cmd-%RANDOM%-%RANDOM%"
mkdir "%STAGE%"
if errorlevel 1 exit /b 1
set "TEMP=%STAGE%"
set "TMP=%STAGE%"
set "HASHLOG=%STAGE%\hash.tmp"
set "HASH_COUNT=0"
set "C6=O:\repos.hobby\ms-dos-archaeology\v6.0\c6ers\tools6"
set "CRTLIB=O:\repos.external\OpenNT\public\sdk\lib16\llibce.lib"
echo Build directory: %STAGE%
echo [1/8] Checking historical tools and compiling native support...
call "%SUPPORT%\host-tools.cmd"
if errorlevel 1 goto failed
call :check "%DOSBOX%" "%DOSBOX_SHA256%"
if errorlevel 1 goto failed
call :check "%CRTLIB%" "6dd7fdf103a71d0cec3433aa3bd7d05b73f90c3e9f24e667c29d5f3c0f9a9389"
if errorlevel 1 goto failed
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    call :target %%N
    if errorlevel 1 goto failed
)
mkdir "%STAGE%\tools" "%STAGE%\include" "%STAGE%\lib"
if errorlevel 1 goto failed
xcopy "%C6%\include" "%STAGE%\include\" /E /I /Q /Y >nul
if errorlevel 1 goto failed
copy /b "%C6%\lib\slibce.lib" "%STAGE%\lib\slibce.lib" >nul
if errorlevel 1 goto failed
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%SUPPORT%\tools.lst") do (
    call :tool "%%A" "%%B" "%%C"
    if errorlevel 1 goto failed
)
set "SOURCE_DATE_EPOCH=%RUNNER_EPOCH%"
gcc -O2 "%ROOT%\extras\tools\isolated_tool_runner.c" -o "%STAGE%\runner.exe" -luser32 > "%STAGE%\gcc.log" 2>&1
if errorlevel 1 goto failed
call :check "%STAGE%\runner.exe" "%RUNNER_SHA256%"
if errorlevel 1 goto failed
for %%N in (msgindex cmdimage ioimage crtlib omforder) do (
    echo [tools] Compiling %%N...
    gcc -O2 -Wall -Wextra -Werror "%ROOT%\extras\tools\%%N.c" -o "%STAGE%\%%N.exe" >> "%STAGE%\gcc.log" 2>&1
    if errorlevel 1 goto failed
)
echo [2/8] Snapshotting and staging source inputs...
call :snapshot "%STAGE%\inputs-before.txt"
if errorlevel 1 goto failed
for %%D in (bios dos inc cmd lang) do (
    xcopy "%ROOT%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
    if errorlevel 1 goto failed
)
for %%N in (tools.ini nosrv.bat) do copy /b "%SUPPORT%\%%N" "%STAGE%\tools\%%N" >nul
mkdir "%STAGE%\messages" "%STAGE%\crtlib" "%STAGE%\crt" "%STAGE%\out"
if errorlevel 1 goto failed
copy /b "%ROOT%\lang\usa\messages\usa-ms-dos.msg" "%STAGE%\messages\USA.MSG" >nul
if errorlevel 1 goto failed
copy /b "%ROOT%\lang\usa\messages\usa-ms-command.msg" "%STAGE%\cmd\command\USA-MS.MSG" >nul
if errorlevel 1 goto failed
echo [3/8] Building BIOS, loader and DOS kernel...
call :phase bios
if errorlevel 1 goto failed
call :phase kernel
if errorlevel 1 goto failed
echo [4/8] Building COMMAND and message resources...
call :phase command
if errorlevel 1 goto failed
"%STAGE%\msgindex.exe" "%STAGE%\cmd\command\COMMAND.CL1" "%STAGE%\cmd\command\COMMAND.CL2" "%STAGE%\cmd\command\COMMAND.CLF" "%STAGE%\cmd\command\res0.asm"
if errorlevel 1 goto failed
call :phase cmdres
if errorlevel 1 goto failed
"%STAGE%\cmdimage.exe" "%STAGE%\cmd\command\command.exe" "%STAGE%\cmd\command\command.map" "%STAGE%\cmd\command\res0.exe" "%STAGE%\cmd\command\iniclass.exe" "%STAGE%\cmd\command\iniclass.map" "%STAGE%\cmd\command\resclass.exe" "%STAGE%\cmd\command\resclass.map" "%STAGE%\out\COMMAND.COM"
if errorlevel 1 goto failed
echo [5/8] Building configuration, registry and original CRT...
"%STAGE%\crtlib.exe" "%CRTLIB%" "%STAGE%\crtlib"
if errorlevel 1 goto failed
call :phase crtlib
if errorlevel 1 goto failed
"%STAGE%\crtlib.exe" "%STAGE%\crtlib\crtfix.lib" "%STAGE%\crt" --dos-startup
if errorlevel 1 goto failed
call :phase cfgasm
if errorlevel 1 goto failed
for %%N in (crtprint crtsprnt crtflush crtclose crtcomit cfgpub) do (
    call :order %%N
    if errorlevel 1 goto failed
)
for %%N in (cfgmain cfgline cfgmenu rqvalue) do (
    call :order %%N --whole
    if errorlevel 1 goto failed
)
call :order cfginit --data ConfigArgPaths ConfigArgValues
if errorlevel 1 goto failed
call :order cfgtail --data PnPProbeTable
if errorlevel 1 goto failed
call :layout rapiopen regapi
if errorlevel 1 goto failed
call :layout regstart regstart
if errorlevel 1 goto failed
call :layout regopen regkeys
if errorlevel 1 goto failed
call :layout regread regfile
if errorlevel 1 goto failed
call :layout regfind reghandl
if errorlevel 1 goto failed
call :layout reginit regfinal
if errorlevel 1 goto failed
call :phase cfglink
if errorlevel 1 goto failed
echo [6/8] Packaging linked IO components...
"%STAGE%\ioimage.exe" "%STAGE%\bios\msload.exe" "%STAGE%\bios\msbio.bin" "%STAGE%\dos\msdos.sys" "%STAGE%\bios\config.exe" "%ROOT%\extras\resources\boot-logo\logo.mrc" "%STAGE%\bios\msbio.map" 4168 "%STAGE%\out\IO.SYS"
if errorlevel 1 goto failed
copy /b "%ROOT%\dos\msdos.cfg" "%STAGE%\out\MSDOS.SYS" >nul
if errorlevel 1 goto failed
echo [7/8] Verifying unchanged inputs and exact target bytes...
call :snapshot "%STAGE%\inputs-after.txt"
if errorlevel 1 goto failed
fc /b "%STAGE%\inputs-before.txt" "%STAGE%\inputs-after.txt" > "%STAGE%\inputs-compare.log"
if errorlevel 1 goto failed
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    call :compare %%N
    if errorlevel 1 goto failed
)
echo [8/8] Publishing all three verified outputs...
if not exist "%ASSETS%" mkdir "%ASSETS%"
mkdir "%STAGE%\previous-assets"
if errorlevel 1 goto failed
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    if exist "%ASSETS%\%%N\" goto failed
    if exist "%ASSETS%\%%N" copy /b "%ASSETS%\%%N" "%STAGE%\previous-assets\%%N" >nul
    if errorlevel 1 goto failed
)
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    copy /b /y "%STAGE%\out\%%N" "%ASSETS%\%%N" >nul
    if errorlevel 1 goto rollback
    fc /b "%STAGE%\out\%%N" "%ASSETS%\%%N" >nul
    if errorlevel 1 goto rollback
)
echo PASS: built, byte-compared and published all three core files. > "%STAGE%\result.txt"
echo Published: %ASSETS%
exit /b 0

:phase
copy /b /y "%SUPPORT%\%~1.bat" "%STAGE%\build.bat" >nul
if errorlevel 1 exit /b 1
if exist "%STAGE%\BUILD.OK" del /q "%STAGE%\BUILD.OK"
if exist "%STAGE%\BUILD.OK" exit /b 1
> "%STAGE%\build.conf" (
    echo [sdl]
    echo fullscreen=false
    echo [dosbox]
    echo memsize=16
    echo [cpu]
    echo cycles=max
    echo [autoexec]
    echo mount c "%STAGE%"
    echo c:
    echo build.bat
)
> "%STAGE%\progress.txt" echo Starting %~1
"%STAGE%\runner.exe" "%DOSBOX%" "%STAGE%" "\"%DOSBOX%\" -noconsole -conf \"%STAGE%\build.conf\""
if errorlevel 1 exit /b 1
copy /y "%STAGE%\host.log" "%STAGE%\%~1-host.log" >nul
findstr /x /c:"PASS " /c:"PASS" "%STAGE%\BUILD.OK" >nul 2>&1
exit /b %errorlevel%

:order
"%STAGE%\omforder.exe" "%STAGE%\bios\%~1.obj" "%STAGE%\bios\%~1.new" "%STAGE%\bios\%~1.lst" %2 %3 %4
if errorlevel 1 exit /b 1
move /y "%STAGE%\bios\%~1.new" "%STAGE%\bios\%~1.obj" >nul
exit /b %errorlevel%

:layout
"%STAGE%\omforder.exe" "%STAGE%\bios\%~1.obj" "%STAGE%\bios\%~1.new" --layout "%SUPPORT%\%~2.omf"
if errorlevel 1 exit /b 1
move /y "%STAGE%\bios\%~1.new" "%STAGE%\bios\%~1.obj" >nul
exit /b %errorlevel%

:hash
set /a HASH_COUNT+=1 >nul
set /a "HASH_STEP=HASH_COUNT%%25" >nul
if %HASH_STEP%==0 echo [check %HASH_COUNT%] %~1
set "DIGEST="
certutil -hashfile "%~1" SHA256 > "%HASHLOG%" 2>&1
if errorlevel 1 exit /b 1
for /f "usebackq skip=1 delims=" %%H in ("%HASHLOG%") do if not defined DIGEST set "DIGEST=%%H"
if not defined DIGEST exit /b 1
set "DIGEST=%DIGEST: =%"
exit /b 0
:check
call :hash "%~1"
if errorlevel 1 exit /b 1
if /i "%DIGEST%"=="%~2" exit /b 0
echo ERROR: Hash mismatch: %~1
exit /b 1
:tool
call :check "%~2" "%~3"
if errorlevel 1 exit /b 1
copy /b "%~2" "%STAGE%\tools\%~1" >nul
exit /b %errorlevel%
:target
if /i "%~1"=="IO.SYS" set "EXPECTED=477eb53a2b3b81cefe58bcad409c682044e4ee4bf35dad678f80e1c5afbf35a5"
if /i "%~1"=="MSDOS.SYS" set "EXPECTED=d28c3a421236bb61081f706193f51f32b9f8b957598d94b6b3b143ae52b1ea03"
if /i "%~1"=="COMMAND.COM" set "EXPECTED=a74c700063cd6b1c91523952bfc80e9393c125d39ada0164d48b5098089fcef3"
call :check "%TARGETS%\%~1" "%EXPECTED%"
exit /b %errorlevel%
:snapshot
set "SNAPSHOT=%~1"
type nul > "%SNAPSHOT%"
for %%D in (bios dos inc cmd lang extras\tools extras\resources) do (
    call :tree "%ROOT%\%%D"
    if errorlevel 1 exit /b 1
)
call :record "%~f0"
exit /b %errorlevel%
:tree
for /r "%~1" %%F in (*) do (
    call :record "%%~fF"
    if errorlevel 1 exit /b 1
)
exit /b 0
:record
call :hash "%~1"
if errorlevel 1 exit /b 1
>> "%SNAPSHOT%" echo %DIGEST%  "%~1"
exit /b %errorlevel%
:compare
call :target %1
if errorlevel 1 exit /b 1
fc /b "%STAGE%\out\%~1" "%TARGETS%\%~1" > "%STAGE%\%~1.compare.log"
if errorlevel 1 exit /b 1
call :hash "%STAGE%\out\%~1"
if errorlevel 1 exit /b 1
>> "%STAGE%\outputs.sha256" echo %DIGEST%  %~1
echo %~1: MATCH
exit /b 0
:rollback
echo ERROR: Restoring previous assets after publication failure.
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    if exist "%STAGE%\previous-assets\%%N" (copy /b /y "%STAGE%\previous-assets\%%N" "%ASSETS%\%%N" >nul) else (if exist "%ASSETS%\%%N" del /q "%ASSETS%\%%N")
)
:failed
echo FAIL: inspect logs in this directory. > "%STAGE%\result.txt"
echo ERROR: Build failed. Logs: %STAGE%
exit /b 1
