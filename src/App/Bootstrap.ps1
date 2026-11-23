<#
================================================================================
  ZeroHub - Fast, Safe & Intelligent Windows Optimization Power Hub
  Copyright (C) 2026 Amir Ali <https://zeroiq.site/>
  Licensed under the GNU General Public License v3.0 (GPLv3).
  You may redistribute and/or modify it under the terms of the GNU GPLv3.
================================================================================
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
param()

$Script:RunningScriptPath = $MyInvocation.MyCommand.Path
if (-not $Script:RunningScriptPath) { $Script:RunningScriptPath = $PSCommandPath }
if (-not $Script:RunningScriptPath -and $PSScriptRoot) { $Script:RunningScriptPath = Join-Path $PSScriptRoot "ZeroHub-GUI.ps1" }
if (-not $Script:RunningScriptPath) { $Script:RunningScriptPath = Join-Path (Get-Location).Path "ZeroHub-GUI.ps1" }

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

