@echo off
setlocal EnableExtensions DisableDelayedExpansion
pushd "%~dp0.."
if errorlevel 1 (
    pause
    exit /b 1
)
if not exist "extras\build\" mkdir "extras\build"
if errorlevel 1 goto entry_failed
mkdir "extras\build\manual-build.lock" 2>nul
if errorlevel 1 (
    echo ERROR: Another build is running, or a previous build was interrupted.
    echo If no build is running, remove extras\build\manual-build.lock and retry.
    goto entry_failed
)
call :build
set "RESULT=%errorlevel%"
rmdir "extras\build\manual-build.lock"
popd
echo Build finished with exit code %RESULT%. Review the output above.
pause
exit /b %RESULT%
:entry_failed
popd
pause
exit /b 1

:build
@echo off
setlocal EnableExtensions DisableDelayedExpansion
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "BUILD=%ROOT%\extras\build"
set "ASSETS=%ROOT%\extras\assets"
set "TARGETS=%ROOT%\extras\baselines\targets"
set "SUPPORT=%ROOT%\extras\tools\dosbuild"
if not exist "%BUILD%\" mkdir "%BUILD%"
if errorlevel 1 exit /b 1
set "RUNID=cmd-%RANDOM%-%RANDOM%"
set "STAGE=%BUILD%\%RUNID%"
mkdir "%STAGE%" 2>nul
if errorlevel 1 exit /b 1
set "TEMP=%STAGE%"
set "TMP=%STAGE%"
set "HASHLOG=%STAGE%\hash.tmp"
set "HASH_COUNT=0"
echo Build directory: %STAGE%
echo [1/6] Checking targets and compiler tools...
call "%SUPPORT%\host-tools.cmd"
if errorlevel 1 goto failed
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    call :target "%%N"
    if errorlevel 1 goto failed
)
call :check "%DOSBOX%" "%DOSBOX_SHA256%"
if errorlevel 1 goto failed
call :check "%ROOT%\extras\tools\isolated_tool_runner.c" "%RUNNER_SOURCE_SHA256%"
if errorlevel 1 goto failed
set "RUNNER=%BUILD%\isolated-tool-runner.exe"
if not exist "%RUNNER%" goto build_runner
call :check "%RUNNER%" "%RUNNER_SHA256%" >nul 2>&1
if not errorlevel 1 goto runner_ready
:build_runner
echo [tools] Compiling native isolated launcher...
set "SOURCE_DATE_EPOCH=%RUNNER_EPOCH%"
gcc -O2 "%ROOT%\extras\tools\isolated_tool_runner.c" -o "%STAGE%\runner.exe" -luser32 > "%STAGE%\gcc.log" 2>&1
if errorlevel 1 goto failed
call :check "%STAGE%\runner.exe" "%RUNNER_SHA256%"
if errorlevel 1 goto failed
copy /b /y "%STAGE%\runner.exe" "%RUNNER%" >nul
if errorlevel 1 goto failed
:runner_ready
call :check "%RUNNER%" "%RUNNER_SHA256%"
if errorlevel 1 goto failed
mkdir "%STAGE%\tools"
if errorlevel 1 goto failed
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("%SUPPORT%\tools.lst") do (
    call :tool "%%A" "%%B" "%%C"
    if errorlevel 1 goto failed
)
echo [2/6] Checking source inputs before compilation...
call :snapshot "%STAGE%\inputs-before.txt"
if errorlevel 1 goto failed
for %%D in (bios dos inc cmd lang) do (
    xcopy "%ROOT%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
    if errorlevel 1 goto failed
)
for %%N in (tools.ini nosrv.bat) do (
    copy /b "%SUPPORT%\%%N" "%STAGE%\tools\%%N" >nul
    if errorlevel 1 goto failed
)
copy /b "%SUPPORT%\build.bat" "%STAGE%\build.bat" >nul
if errorlevel 1 goto failed
mkdir "%STAGE%\messages" "%STAGE%\cmdmsg"
if errorlevel 1 goto failed
copy /b "%ROOT%\lang\usa\messages\usa-ms-dos.msg" "%STAGE%\messages\USA.MSG" >nul
if errorlevel 1 goto failed
copy /b "%ROOT%\lang\usa\messages\usa-ms-command.msg" "%STAGE%\cmdmsg\USA.MSG" >nul
if errorlevel 1 goto failed
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
echo [3/6] Compiling on isolated desktop; current phase shown every 5 seconds...
"%RUNNER%" "%DOSBOX%" "%STAGE%" "\"%DOSBOX%\" -noconsole -conf \"%STAGE%\build.conf\""
if errorlevel 1 goto failed
findstr /x /c:"PASS " /c:"PASS" "%STAGE%\BUILD.OK" >nul 2>&1
if errorlevel 1 goto failed
echo [4/6] Checking source inputs after compilation...
call :snapshot "%STAGE%\inputs-after.txt"
if errorlevel 1 goto failed
fc /b "%STAGE%\inputs-before.txt" "%STAGE%\inputs-after.txt" > "%STAGE%\inputs-compare.log"
if errorlevel 1 goto failed
echo [5/6] Comparing compiled outputs with original targets...
call :compare "IO.SYS" "bios\io.sys"
if errorlevel 1 goto failed
call :compare "MSDOS.SYS" "dos\msdos.sys"
if errorlevel 1 goto failed
call :compare "COMMAND.COM" "cmd\command\command.com"
if errorlevel 1 goto failed
rem All three outputs must pass before any published file is changed.
echo [6/6] Publishing all three verified outputs...
mkdir "%STAGE%\previous-assets"
if errorlevel 1 goto failed
if not exist "%ASSETS%\" mkdir "%ASSETS%"
if errorlevel 1 goto failed
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do (
    call :backup "%%N"
    if errorlevel 1 goto failed
)
call :publish "IO.SYS" "bios\io.sys"
if errorlevel 1 goto rollback
call :publish "MSDOS.SYS" "dos\msdos.sys"
if errorlevel 1 goto rollback
call :publish "COMMAND.COM" "cmd\command\command.com"
if errorlevel 1 goto rollback
> "%STAGE%\result.txt" echo PASS: built, byte-compared and published all three core files.
echo Published: %ASSETS%
echo Result: %STAGE%\result.txt
exit /b 0

:target
set "EXPECTED="
for /f "usebackq tokens=1,2" %%A in ("%SUPPORT%\targets.sha256") do if /i "%%B"=="%~1" set "EXPECTED=%%A"
if not defined EXPECTED exit /b 1
call :check "%TARGETS%\%~1" "%EXPECTED%"
exit /b %errorlevel%

:tool
call :check "%~2" "%~3"
if errorlevel 1 exit /b 1
copy /b "%~2" "%STAGE%\tools\%~1" >nul
exit /b %errorlevel%

:hash
set /a HASH_COUNT+=1 >nul
set /a "HASH_STEP=HASH_COUNT%%25" >nul
if %HASH_STEP%==0 echo [check %HASH_COUNT%] %~1
set "DIGEST="
certutil -hashfile "%~1" SHA256 > "%HASHLOG%" 2>&1
if errorlevel 1 (
    type "%HASHLOG%"
    exit /b 1
)
for /f "usebackq skip=1 delims=" %%H in ("%HASHLOG%") do if not defined DIGEST set "DIGEST=%%H"
if not defined DIGEST exit /b 1
set "DIGEST=%DIGEST: =%"
exit /b 0

:check
call :hash "%~1"
if errorlevel 1 exit /b 1
if /i "%DIGEST%"=="%~2" exit /b 0
echo ERROR: SHA256 mismatch: %~1
exit /b 1

:snapshot
set "SNAPSHOT=%~1"
type nul > "%SNAPSHOT%"
for %%D in (bios dos inc cmd lang) do (
    call :tree "%ROOT%\%%D"
    if errorlevel 1 exit /b 1
)
for /r "%SUPPORT%" %%F in (*) do (
    call :record "%%~fF"
    if errorlevel 1 exit /b 1
)
for %%F in ("%~f0" "%ROOT%\extras\tools\isolated_tool_runner.c") do (
    call :record "%%~fF"
    if errorlevel 1 exit /b 1
)
exit /b 0

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
call :target "%~1"
if errorlevel 1 exit /b 1
fc /b "%STAGE%\%~2" "%TARGETS%\%~1" > "%STAGE%\%~1.compare.log"
if errorlevel 1 exit /b 1
call :hash "%STAGE%\%~2"
if errorlevel 1 exit /b 1
>> "%STAGE%\outputs.sha256" echo %DIGEST%  %~1
echo %~1: MATCH
exit /b 0

:backup
if exist "%ASSETS%\%~1\" exit /b 1
if not exist "%ASSETS%\%~1" exit /b 0
copy /b "%ASSETS%\%~1" "%STAGE%\previous-assets\%~1" >nul
exit /b %errorlevel%

:publish
copy /b "%STAGE%\%~2" "%ASSETS%\.%~1.%RUNID%.new" >nul
if errorlevel 1 exit /b 1
move /y "%ASSETS%\.%~1.%RUNID%.new" "%ASSETS%\%~1" >nul
if errorlevel 1 exit /b 1
fc /b "%STAGE%\%~2" "%ASSETS%\%~1" >nul
exit /b %errorlevel%

:rollback
echo ERROR: Publication failed; restoring previous assets.
for %%N in (IO.SYS MSDOS.SYS COMMAND.COM) do call :restore "%%N"
goto failed

:restore
if exist "%ASSETS%\.%~1.%RUNID%.new" del /q "%ASSETS%\.%~1.%RUNID%.new"
if exist "%STAGE%\previous-assets\%~1" (
    copy /b /y "%STAGE%\previous-assets\%~1" "%ASSETS%\%~1" >nul
    if errorlevel 1 echo ERROR: Restore failed for %~1; backup is in %STAGE%\previous-assets
    exit /b
)
if exist "%ASSETS%\%~1" del /q "%ASSETS%\%~1"
exit /b

:failed
> "%STAGE%\result.txt" echo FAIL: inspect logs in this directory.
echo ERROR: Build or publication failed. Logs: %STAGE%
if exist "%STAGE%\progress.txt" type "%STAGE%\progress.txt"
if exist "%STAGE%\host.log" echo Host log: %STAGE%\host.log
for %%D in (bios dos cmd\command) do if exist "%STAGE%\%%D\make.log" echo Compiler log: %STAGE%\%%D\make.log
if exist "%STAGE%\gcc.log" echo Native compiler log: %STAGE%\gcc.log
exit /b 1
