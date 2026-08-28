@echo off
title ZeroCleaner GUI Launcher
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ZeroCleaner-GUI.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ZeroCleaner GUI encountered an issue starting up.
    pause
)
