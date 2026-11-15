@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "COMPONENT="
set "SOURCE_DIRS="
if /i "%~1"=="kernel" (
    set "COMPONENT=kernel"
    set "SOURCE_DIRS=dos inc lang"
)
if /i "%~1"=="bios" (
    set "COMPONENT=bios"
    set "SOURCE_DIRS=bios dev inc lang"
)
pushd "%~dp0..\.."
if errorlevel 1 goto entry_failed
if not exist extras\build mkdir extras\build
mkdir extras\build\io-baseline.lock 2>nul
if errorlevel 1 (
    echo ERROR: Build lock exists. Check for a running build before removing it.
    popd
    goto entry_failed
)
call :build
set "RESULT=%errorlevel%"
rmdir extras\build\io-baseline.lock
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
set "STAGE=%ROOT%\extras\build\io-%RANDOM%-%RANDOM%"
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
set "CRTLIB=O:\repos.external\OpenNT\public\sdk\lib16\llibce.lib"
echo Build directory: %STAGE%
echo [1/7] Extracting the frozen source and checking historical tools...
git -C "%ROOT%\.." archive --format=tar --output="%STAGE%\base.tar" %BASE_COMMIT% v7.10.1998/bios v7.10.1998/dos v7.10.1998/inc v7.10.1998/lang v7.10.1998/extras/tools v7.10.1998/extras/resources v7.10.2222/bios v7.10.2222/inc v7.10.2222/lang
if errorlevel 1 goto failed
tar -xf "%STAGE%\base.tar" -C "%STAGE%"
if errorlevel 1 goto failed
call "%SUPPORT%\host-tools.cmd"
if errorlevel 1 goto failed
call :check "%DOSBOX%" "%DOSBOX_SHA256%"
if errorlevel 1 goto failed
call :check "%CRTLIB%" "6dd7fdf103a71d0cec3433aa3bd7d05b73f90c3e9f24e667c29d5f3c0f9a9389"
if errorlevel 1 goto failed
call :check "%TARGETS%\IO.SYS" "e587b10cb2239ce76675a79b7ee25daf44435a0feff2bd51fc962d865eb959b3"
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
for %%N in (ioimage crtlib omforder) do (
    echo [tools] Compiling %%N...
    gcc -O2 -Wall -Wextra -Werror "%BASE%\extras\tools\%%N.c" -o "%STAGE%\%%N.exe" >> "%STAGE%\gcc.log" 2>&1
    if errorlevel 1 goto failed
)
gcc -O2 -Wall -Wextra -Werror "%ROOT%\extras\tools\cmdecode.c" -o "%STAGE%\cmdecode.exe" >> "%STAGE%\gcc.log" 2>&1
if errorlevel 1 goto failed
echo [tools] Compiling cmencode...
gcc -O2 -Wall -Wextra -Werror "%ROOT%\extras\tools\cmencode.c" -o "%STAGE%\cmencode.exe" >> "%STAGE%\gcc.log" 2>&1
if errorlevel 1 goto failed
echo [2/7] Snapshotting and staging source inputs...
call :snapshot "%STAGE%\inputs-before.txt"
if errorlevel 1 goto failed
for %%D in (bios dos inc lang) do (
    xcopy "%BASE%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
    if errorlevel 1 goto failed
    if exist "%SE%\%%D\" (
        xcopy "%SE%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
        if errorlevel 1 goto failed
    )
)
for %%N in (tools.ini nosrv.bat) do copy /b "%SUPPORT%\%%N" "%STAGE%\tools\%%N" >nul
mkdir "%STAGE%\messages" "%STAGE%\crtlib" "%STAGE%\crt" "%STAGE%\out"
if errorlevel 1 goto failed
if defined COMPONENT (
    echo Staging the 3000 %COMPONENT% source overlay...
    for %%D in (%SOURCE_DIRS%) do (
        if exist "%ROOT%\%%D\" (
            xcopy "%ROOT%\%%D" "%STAGE%\%%D\" /E /I /Q /Y >nul
            if errorlevel 1 goto failed
        )
    )
)
copy /b "%STAGE%\lang\usa\messages\usa-ms-dos.msg" "%STAGE%\messages\USA.MSG" >nul
if errorlevel 1 goto failed
if defined COMPONENT goto component_only
echo [3/7] Building BIOS, loader and DOS kernel...
call :phase bios
if errorlevel 1 goto failed
call :phase kernel
if errorlevel 1 goto failed
echo [4/7] Building configuration, registry and original CRT...
"%STAGE%\crtlib.exe" "%CRTLIB%" "%STAGE%\crtlib"
if errorlevel 1 goto failed
call :phase crtlib
if errorlevel 1 goto failed
"%STAGE%\crtlib.exe" "%STAGE%\crtlib\crtfix.lib" "%STAGE%\crt"
if errorlevel 1 goto failed
call :phase cfgasm
if errorlevel 1 goto failed
for %%N in (crtprint crtsprnt crtflush crtclose crtcomit cfgpub regstart regopen regfind) do (
    call :order %%N
    if errorlevel 1 goto failed
)
call :order cfgmain --data ConfigSetError _main
if errorlevel 1 goto failed
for %%N in (cfgline cfgmenu) do (
    call :order %%N --whole
    if errorlevel 1 goto failed
)
call :order regread --procedures RegFinishKeyAllocation
if errorlevel 1 goto failed
call :order regroot --data RegTransferBuffer
if errorlevel 1 goto failed
call :order cfginit --data ConfigWindowsPath ConfigArgPaths
if errorlevel 1 goto failed
call :order cfgtail --data PnPProbeTable
if errorlevel 1 goto failed
call :phase cfglinkraw "%ROOT%\extras\tools"
if errorlevel 1 goto failed
call :phase cfglink
if errorlevel 1 goto failed
echo [5/7] Packaging linked 2222 IO components...
"%STAGE%\ioimage.exe" "%STAGE%\bios\msload.exe" "%STAGE%\bios\msbio.bin" "%STAGE%\dos\msdos.sys" "%STAGE%\bios\config.exe" "%BASE%\extras\resources\boot-logo\logo.mrc" "%STAGE%\bios\msbio.map" 4616 "%STAGE%\out\IO.SYS"
if errorlevel 1 goto failed
call :check "%STAGE%\out\IO.SYS" "2db8f238742c374f264ead1c44f87d69af42c24688a3a80f7d9657bc952d5d20"
if errorlevel 1 goto failed
echo [6/7] Decoding the 3000 target payload...
"%STAGE%\cmdecode.exe" "%TARGETS%\IO.SYS" "%STAGE%\out\3000-payload.bin" > "%STAGE%\cm-layout.tsv"
if errorlevel 1 goto failed
call :check "%STAGE%\out\3000-payload.bin" "0d6ebe0add967e12d2974c636636bc2b2da00602e26bdafb2312fea118abf3bb"
if errorlevel 1 goto failed
echo Re-encoding the frozen 3000 payload for byte comparison...
"%STAGE%\cmencode.exe" "%STAGE%\out\3000-payload.bin" "%STAGE%\out\3000-cm.bin" "%TARGETS%\IO.SYS" > "%STAGE%\cm-compare.log"
if errorlevel 1 (
    type "%STAGE%\cm-compare.log"
    goto failed
)
type "%STAGE%\cm-compare.log"
echo [7/7] Checking unchanged input snapshots...
call :snapshot "%STAGE%\inputs-after.txt"
if errorlevel 1 goto failed
fc /b "%STAGE%\inputs-before.txt" "%STAGE%\inputs-after.txt" > "%STAGE%\inputs-compare.log"
if errorlevel 1 goto failed
echo PASS: 2222 IO.SYS, 3000 decoded payload and exact CM stream verified. > "%STAGE%\result.txt"
echo Verified IO baseline and target payload: %STAGE%
exit /b 0

:component_only
echo Linking the 3000 %COMPONENT%...
set "COMPONENT_SUPPORT=%SUPPORT%"
if /i "%COMPONENT%"=="bios" set "COMPONENT_SUPPORT=%ROOT%\extras\tools"
call :phase %COMPONENT% "%COMPONENT_SUPPORT%"
if errorlevel 1 goto failed
call :snapshot "%STAGE%\inputs-after.txt"
if errorlevel 1 goto failed
fc /b "%STAGE%\inputs-before.txt" "%STAGE%\inputs-after.txt" > "%STAGE%\inputs-compare.log"
if errorlevel 1 goto failed
echo PASS: %COMPONENT% linked with unchanged inputs. > "%STAGE%\result.txt"
echo %COMPONENT% build directory: %STAGE%
exit /b 0

:phase
set "PHASE_DIR=%SUPPORT%"
if not "%~2"=="" set "PHASE_DIR=%~2"
copy /b /y "%PHASE_DIR%\%~1.bat" "%STAGE%\build.bat" >nul
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
:snapshot
set "SNAPSHOT=%~1"
type nul > "%SNAPSHOT%"
for %%F in ("%STAGE%\base.tar" "%TARGETS%\IO.SYS" "%ROOT%\extras\tools\cmdecode.c" "%ROOT%\extras\tools\cmencode.c" "%ROOT%\extras\tools\cfglinkraw.bat" "%~f0") do (
    call :record "%%~fF"
    if errorlevel 1 exit /b 1
)
if /i "%COMPONENT%"=="bios" (
    call :record "%ROOT%\extras\tools\bios.bat"
    if errorlevel 1 exit /b 1
)
if defined COMPONENT (
    for %%D in (%SOURCE_DIRS%) do (
        if exist "%ROOT%\%%D\" (
            call :record_tree "%ROOT%\%%D"
            if errorlevel 1 exit /b 1
        )
    )
)
exit /b 0
:record_tree
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
:failed
echo FAIL: inspect logs in this directory. > "%STAGE%\result.txt"
echo ERROR: Build failed. Logs: %STAGE%
exit /b 1
