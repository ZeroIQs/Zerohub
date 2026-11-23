@echo off
title ZeroHub Power Grimoire
cd /d "%~dp0"

if not exist "%~dp0ZeroHub-GUI.ps1" (
    if exist "%~dp0build.ps1" (
        echo Compiling ZeroHub from source...
        powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1"
    )
)

if exist "%~dp0ZeroHub-GUI.ps1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0ZeroHub-GUI.ps1"
) else (
    echo.
    echo ZeroHub GUI encountered an issue starting up.
    pause
)
