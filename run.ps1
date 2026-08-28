<#
.SYNOPSIS
    ZeroCleaner - Fast 1-Line Web Runner
.DESCRIPTION
    Downloads and executes the latest ZeroCleaner GUI directly from GitHub memory with Administrator elevation.
.EXAMPLE
    irm https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/run.ps1 | iex
#>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Self-Elevate to Administrator if not already elevated
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', 'irm https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/run.ps1 | iex')
    exit
}

# Fetch and execute ZeroCleaner-GUI.ps1
$url = 'https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/ZeroCleaner-GUI.ps1'
$script = (Invoke-RestMethod -Uri $url -UseBasicParsing)
Invoke-Expression $script
