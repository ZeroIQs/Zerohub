@echo off
title ZeroHub GUI Launcher
cd /d "%~dp0"
powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0ZeroHub-GUI.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ZeroHub GUI encountered an issue starting up.
    pause
)
