@echo off
if /i "%~1"=="io-baseline" goto io_baseline
if /i "%~1"=="io" goto io_image
if /i "%~1"=="io-core" goto io_core
if /i "%~1"=="io-kernel" goto io_core
if /i "%~1"=="io-bios" goto io_core
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
set "TARGETS=%ROOT%\extras\baselines\targets"
set "ASSETS=%ROOT%\extras\assets"
set "STAGE=%ROOT%\extras\build\cmd-%RANDOM%-%RANDOM%"
mkdir "%STAGE%"
if errorlevel 1 exit /b 1
set "TEMP=%STAGE%"
set "TMP=%STAGE%"
set "HASHLOG=%STAGE%\hash.tmp"
set "HASH_COUNT=0"
set "BASE_COMMIT=0e557eb928f84339d1718c82e15fbfe163526aa8"
set "BASE=%STAGE%\v7.10.1998"
set "SE=%STAGE%\v7.10.2222"
set "SUPPORT=%BASE%\extras\tools\dosbuild"
set "C6=O:\repos.hobby\ms-dos-archaeology\v6.0\c6ers\tools6"
echo Build directory: %STAGE%
echo [1/5] Extracting the frozen source and checking historical tools...
git -C "%ROOT%\.." archive --format=tar --output="%STAGE%\base.tar" %BASE_COMMIT% v7.10.1998/cmd v7.10.1998/inc v7.10.1998/lang v7.10.1998/extras/tools v7.10.2222/cmd v7.10.2222/inc v7.10.2222/lang
if errorlevel 1 goto failed
tar -xf "%STAGE%\base.tar" -C "%STAGE%"
if errorlevel 1 goto failed
call "%SUPPORT%\host-tools.cmd"
if errorlevel 1 goto failed
call :check "%DOSBOX%" "%DOSBOX_SHA256%"
if errorlevel 1 goto failed
call :target COMMAND.COM
if errorlevel 1 goto failed
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
gcc -O2 "%BASE%\extras\tools\isolated_tool_runner.c" -o "%STAGE%\runner.exe" -luser32 > "%STAGE%\gcc.log" 2>&1
if errorlevel 1 goto failed
call :check "%STAGE%\runner.exe" "%RUNNER_SHA256%"
if errorlevel 1 goto failed
for %%N in (msgindex cmdimage) do (
    echo [tools] Compiling %%N...
    gcc -O2 -Wall -Wextra -Werror "%BASE%\extras\tools\%%N.c" -o "%STAGE%\%%N.exe" >> "%STAGE%\gcc.log" 2>&1
    if errorlevel 1 goto failed
)
echo [2/5] Snapshotting and staging source inputs...
call :snapshot "%STAGE%\inputs-before.txt"
if errorlevel 1 goto failed
for %%D in (inc cmd lang) do (
    xcopy "%BASE%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
    if errorlevel 1 goto failed
    if exist "%SE%\%%D\" (
        xcopy "%SE%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
        if errorlevel 1 goto failed
    )
    if exist "%ROOT%\%%D\" (
        xcopy "%ROOT%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
        if errorlevel 1 goto failed
    )
)
for %%N in (tools.ini nosrv.bat) do copy /b "%SUPPORT%\%%N" "%STAGE%\tools\%%N" >nul
mkdir "%STAGE%\out"
if errorlevel 1 goto failed
copy /b "%STAGE%\lang\usa\messages\usa-ms-command.msg" "%STAGE%\cmd\command\USA-MS.MSG" >nul
if errorlevel 1 goto failed
echo [3/5] Building COMMAND and message resources...
call :phase command
if errorlevel 1 goto failed
"%STAGE%\msgindex.exe" "%STAGE%\cmd\command\COMMAND.CL1" "%STAGE%\cmd\command\COMMAND.CL2" "%STAGE%\cmd\command\COMMAND.CLF" "%STAGE%\cmd\command\res0.asm"
if errorlevel 1 goto failed
call :phase cmdres
if errorlevel 1 goto failed
"%STAGE%\cmdimage.exe" "%STAGE%\cmd\command\command.exe" "%STAGE%\cmd\command\command.map" "%STAGE%\cmd\command\res0.exe" "%STAGE%\cmd\command\iniclass.exe" "%STAGE%\cmd\command\iniclass.map" "%STAGE%\cmd\command\resclass.exe" "%STAGE%\cmd\command\resclass.map" "%STAGE%\out\COMMAND.COM"
if errorlevel 1 goto failed
echo [4/5] Verifying unchanged inputs and exact target bytes...
call :snapshot "%STAGE%\inputs-after.txt"
if errorlevel 1 goto failed
fc /b "%STAGE%\inputs-before.txt" "%STAGE%\inputs-after.txt" > "%STAGE%\inputs-compare.log"
if errorlevel 1 goto failed
call :compare COMMAND.COM
if errorlevel 1 goto failed
echo [5/5] Publishing verified COMMAND.COM...
if not exist "%ASSETS%" mkdir "%ASSETS%"
mkdir "%STAGE%\previous-assets"
if errorlevel 1 goto failed
for %%N in (COMMAND.COM) do (
    if exist "%ASSETS%\%%N\" goto failed
    if exist "%ASSETS%\%%N" copy /b "%ASSETS%\%%N" "%STAGE%\previous-assets\%%N" >nul
    if errorlevel 1 goto failed
)
for %%N in (COMMAND.COM) do (
    copy /b /y "%STAGE%\out\%%N" "%ASSETS%\%%N" >nul
    if errorlevel 1 goto rollback
    fc /b "%STAGE%\out\%%N" "%ASSETS%\%%N" >nul
    if errorlevel 1 goto rollback
)
echo PASS: built, byte-compared and published COMMAND.COM. > "%STAGE%\result.txt"
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
set "EXPECTED=1a098dd8a6b8d2bc288e199ad73da46a4cea1e23e5d2882691f277dd4abe0ece"
call :check "%TARGETS%\COMMAND.COM" "%EXPECTED%"
exit /b %errorlevel%
:snapshot
set "SNAPSHOT=%~1"
type nul > "%SNAPSHOT%"
call :record "%STAGE%\base.tar"
if errorlevel 1 exit /b 1
for %%D in (inc cmd lang) do (
    if exist "%ROOT%\%%D\" (
        call :tree "%ROOT%\%%D"
        if errorlevel 1 exit /b 1
    )
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
if errorlevel 1 (
    echo %~1: comparison did not pass; see %STAGE%\%~1.compare.log
    exit /b 1
)
call :hash "%STAGE%\out\%~1"
if errorlevel 1 exit /b 1
>> "%STAGE%\outputs.sha256" echo %DIGEST%  %~1
echo %~1: MATCH
exit /b 0
:rollback
echo ERROR: Restoring previous assets after publication failure.
for %%N in (COMMAND.COM) do (
    if exist "%STAGE%\previous-assets\%%N" (copy /b /y "%STAGE%\previous-assets\%%N" "%ASSETS%\%%N" >nul) else (if exist "%ASSETS%\%%N" del /q "%ASSETS%\%%N")
)
:failed
echo FAIL: inspect logs in this directory. > "%STAGE%\result.txt"
echo ERROR: Build failed. Logs: %STAGE%
exit /b 1

:io_baseline
call "%~dp0tools\iobase.cmd"
exit /b %errorlevel%

:io_core
call "%~dp0tools\iobase.cmd" core
exit /b %errorlevel%

:io_image
call "%~dp0tools\iobase.cmd" image
exit /b %errorlevel%
