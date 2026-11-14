@echo off
setlocal
cd /d %~dp0
copy /b /y compact.bat build.bat >nul
if exist BUILD.OK del BUILD.OK
runner.exe "C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe" "%CD%" "DOSBox.exe -noconsole -conf build.conf"
if errorlevel 1 exit /b 1
type BUILD.OK
findstr /b PASS BUILD.OK >nul
exit /b %errorlevel%
