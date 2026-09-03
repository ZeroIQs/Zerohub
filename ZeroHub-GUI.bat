@echo off
title ZeroHub Power Grimoire (Live Developer Console)
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ZeroHub-GUI.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ZeroHub GUI encountered an issue starting up.
    pause
)
