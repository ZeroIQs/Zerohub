function Get-WingetAvailableUpgrades {
    $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
    $upgradeMap = @{}
    if (Test-Path $tempOut) {
        $lines = Get-Content $tempOut -ErrorAction SilentlyContinue
        $headerFound = $false
        $idColStart = -1
        $verColStart = -1
        $availColStart = -1

        foreach ($line in $lines) {
            if ($line -match "---") {
                $headerFound = $true
                continue
            }
            if (-not $headerFound) {
                if ($line -match "Name\s+Id\s+Version\s+Available" -or $line -match "Id\s+Version\s+Available") {
                    $idColStart = $line.IndexOf("Id")
                    $verColStart = $line.IndexOf("Version")
                    $availColStart = $line.IndexOf("Available")
                }
                continue
            }

            if ([string]::IsNullOrWhiteSpace($line) -or $line -match "upgrades available" -or $line -match "package\(s\) have") {
                continue
            }

            if ($idColStart -ge 0 -and $verColStart -gt $idColStart -and $line.Length -gt $idColStart) {
                $pkgId = $line.Substring($idColStart, [math]::Min($line.Length - $idColStart, $verColStart - $idColStart)).Trim()
                $currVer = if ($line.Length -gt $verColStart) {
                    $len = if ($availColStart -gt $verColStart) { [math]::Min($line.Length - $verColStart, $availColStart - $verColStart) } else { $line.Length - $verColStart }
                    $line.Substring($verColStart, $len).Trim()
                } else { "" }
                $availVer = if ($line.Length -gt $availColStart) {
                    $line.Substring($availColStart).Trim().Split(" ")[0]
                } else { "" }

                if ($pkgId -and -not $Script:DismissedUpgradeIds.Contains($pkgId)) {
                    $upgradeMap[$pkgId] = @{
                        Current = $currVer
                        Available = $availVer
                    }
                }
            }
        }
    }
    return $upgradeMap
}

$Script:IsWingetScanRunning = $false
$Script:WingetAsyncTimer = $null
$Script:WingetAsyncPs = $null

function Get-WingetUpgradesAsync {
    if ($Script:IsWingetScanRunning) { return }
    $Script:IsWingetScanRunning = $true

    if ($Script:WingetAsyncTimer) {
        try { $Script:WingetAsyncTimer.Stop() } catch {}
        $Script:WingetAsyncTimer = $null
    }
    if ($Script:WingetAsyncPs) {
        try { $Script:WingetAsyncPs.Dispose() } catch {}
        $Script:WingetAsyncPs = $null
    }

    $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
    $asyncCode = {
        param($outPath)
        $proc = Start-Process -FilePath "winget" -ArgumentList "upgrade", "--accept-source-agreements" -NoNewWindow -PassThru -RedirectStandardOutput $outPath -RedirectStandardError "$env:TEMP\winget_upgrades_err.txt"
        $proc.WaitForExit(15000)
    }

    $Script:WingetAsyncPs = [powershell]::Create()
    $Script:WingetAsyncPs.AddScript($asyncCode).AddArgument($tempOut) | Out-Null
    $asyncHandle = $Script:WingetAsyncPs.BeginInvoke()

    $Script:WingetAsyncTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WingetAsyncTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $Script:WingetAsyncTimer.add_Tick({
        param($s, $e)
        if ($asyncHandle.IsCompleted) {
            if ($s) { try { $s.Stop() } catch {} }
            try { $Script:WingetAsyncPs.EndInvoke($asyncHandle) | Out-Null } catch {}
            try { $Script:WingetAsyncPs.Dispose() } catch {}
            $Script:WingetAsyncPs = $null
            $Script:WingetAsyncTimer = $null
            $Script:IsWingetScanRunning = $false

            $upgrades = Get-WingetAvailableUpgrades
            if ($upgrades) {
                foreach ($k in $upgrades.Keys) {
                    if (-not $Script:DismissedUpgradeIds.Contains($k)) {
                        $Script:AvailableWingetUpgrades[$k] = $upgrades[$k]
                    }
                }
            }

            # Rebuild catalog and refresh UI filters
            Clear-DataCacheStamp "installer"
            Initialize-InstallerCatalogList
            Set-InstallerFilters
        }
    })
    $Script:WingetAsyncTimer.Start()
}

function Update-InstallerSelectionStatus {
    $sel = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnInstallSelectedApps.IsEnabled = $true
        $updateOnly = ($sel | Where-Object { $_.HasUpdate -or $_.IsInstalled }).Count -eq $sel.Count
        if ($updateOnly) {
            $BtnInstallSelectedApps.Content = "🔄 Upgrade Selected Apps ($($sel.Count))"
        } else {
            $BtnInstallSelectedApps.Content = "🚀 Install / Upgrade Apps ($($sel.Count))"
        }
        $TxtInstallerStatus.Text = "$($sel.Count) application(s) selected for silent installation / upgrade via Winget."
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    } else {
        $BtnInstallSelectedApps.IsEnabled = $false
        $BtnInstallSelectedApps.Content = "🚀 Install Selected Apps"
        $TxtInstallerStatus.Text = "Select one or more software applications to silently install or upgrade via official winget."
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

