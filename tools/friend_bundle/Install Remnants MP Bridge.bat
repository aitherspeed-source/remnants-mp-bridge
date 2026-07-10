@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\friend_install.ps1" -Mode Install
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Installation did not complete. Read the message above.
if "%RESULT%"=="0" echo Installation completed successfully.
echo.
pause
exit /b %RESULT%
