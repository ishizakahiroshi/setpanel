@echo off
setlocal EnableExtensions

set "SCRIPT=%~dp0setpanel-menu.ps1"
if not exist "%SCRIPT%" (
    echo Error: setpanel-menu.ps1 not found in %~dp0
    pause
    exit /b 1
)

where pwsh.exe >nul 2>&1
if not errorlevel 1 (
    pwsh.exe -NoLogo -NoProfile -File "%SCRIPT%" %*
    exit /b %ERRORLEVEL%
)
powershell.exe -NoLogo -NoProfile -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
