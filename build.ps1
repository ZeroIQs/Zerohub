<#
  Builds the single-file ZeroHub-GUI.ps1 that users download from src/.
  run.ps1, ZeroHub-GUI.bat and the in-app updater all expect one file, so edit src/ and rebuild.

  .\build.ps1           rebuild ZeroHub-GUI.ps1
  .\build.ps1 -Check    rebuild in memory and fail if it differs from the committed ZeroHub-GUI.ps1
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Run,
    [string]$OutFile
)

$ErrorActionPreference = 'Stop'
# $PSScriptRoot is empty inside param() defaults on Windows PowerShell 5.1, so resolve it here.
if (-not $OutFile) { $OutFile = Join-Path $PSScriptRoot 'ZeroHub-GUI.ps1' }
$srcDir = Join-Path $PSScriptRoot 'src'
$orderFile = Join-Path $srcDir 'build-order.txt'
$includePattern = '^#ZH-INCLUDE\s+(\S+)\s*$'

function Read-SourceLines([string]$relPath) {
    $path = Join-Path $srcDir $relPath
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing source file: src/$relPath" }
    # ReadAllText strips the BOM; dropping CR keeps the output LF even if an editor saved CRLF.
    $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8).Replace("`r", '')
    if ($text.EndsWith("`n")) { $text = $text.Substring(0, $text.Length - 1) }
    return , $text.Split("`n")
}

function Expand-Source([string]$relPath, [System.Collections.Generic.List[string]]$into, [string[]]$stack) {
    if ($stack -contains $relPath) { throw "Include cycle: $(($stack + $relPath) -join ' -> ')" }
    foreach ($line in (Read-SourceLines $relPath)) {
        if ($line -match $includePattern) {
            Expand-Source $Matches[1] $into ($stack + $relPath)
        } else {
            $into.Add($line)
        }
    }
}

$order = Get-Content -LiteralPath $orderFile | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('#') }
$output = New-Object System.Collections.Generic.List[string]
foreach ($rel in $order) { Expand-Source $rel.Trim() $output @() }
$built = ($output -join "`n") + "`n"

$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseInput($built, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) {
    $parseErrors | Select-Object -First 10 | ForEach-Object { Write-Host "Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Red }
    throw "Build output has $($parseErrors.Count) parse error(s); nothing written."
}

if ($Check) {
    $current = if (Test-Path -LiteralPath $OutFile) { [IO.File]::ReadAllText($OutFile, [Text.Encoding]::UTF8) } else { '' }
    if ($current -ne $built) {
        Write-Host "ZeroHub-GUI.ps1 is out of date with src/. Run .\build.ps1" -ForegroundColor Red
        exit 1
    }
    Write-Host "ZeroHub-GUI.ps1 matches src/ ($($output.Count) lines from $($order.Count) files)." -ForegroundColor Green
    exit 0
}

# Windows PowerShell 5.1 needs the BOM to read the non-ASCII text in the script correctly.
[IO.File]::WriteAllText($OutFile, $built, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "Built $OutFile ($($output.Count) lines from $($order.Count) files)." -ForegroundColor Green

if ($Run) {
    Write-Host "Launching $OutFile..." -ForegroundColor Cyan
    & $OutFile
}
