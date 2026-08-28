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

$script = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/ZeroCleaner-GUI.ps1" -UseBasicParsing
Invoke-Expression $script
