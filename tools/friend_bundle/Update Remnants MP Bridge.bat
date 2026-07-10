@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\update_bridge.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Update did not complete. Your existing installation was preserved where possible.
if "%RESULT%"=="0" echo Update check completed successfully.
echo.
pause
exit /b %RESULT%
