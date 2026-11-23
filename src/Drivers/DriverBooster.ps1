# ==========================================
# DRIVER UPDATER & HARDWARE ENGINE
# ==========================================
$Script:DriverBoosterDir = Join-Path $env:ProgramData "IObitDriverBooster"
$Script:DriverBoosterExe = Join-Path $Script:DriverBoosterDir "DriverBoosterPortable.exe"
$Script:DriverBoosterUrl = "https://pub-1ee8671c91af4dad984d75dc4d3f80a9.r2.dev/DB.zip"
$Script:DriverBoosterTimer = $null
$Script:DriverBoosterPs    = $null
$Script:DriverBoosterAsync = $null

function Test-DriverBoosterInstalled {
    $portExe = Join-Path $Script:DriverBoosterDir "DriverBoosterPortable.exe"
    $innerExe = Join-Path $Script:DriverBoosterDir "App\DriverBooster\DriverBooster.exe"
    return (Test-Path $portExe) -and (Test-Path $innerExe)
}

function Update-DriverUpdaterUI {
    if (-not $Tab_DriverUpdater) { return }
    $isInstalled = Test-DriverBoosterInstalled

    # If installation is actively running in background, preserve Installing state
    if ($Script:DriverBoosterPs -and $Script:DriverBoosterAsync -and (-not $Script:DriverBoosterAsync.IsCompleted)) {
        return
    }

    if ($ProgressDriverBooster) {
        $ProgressDriverBooster.Visibility = [System.Windows.Visibility]::Collapsed
    }

    $brushConv = [System.Windows.Media.BrushConverter]::new()
    if ($BadgeDriverStatus -and $TxtDriverStatus) {
        if ($isInstalled) {
            $BadgeDriverStatus.Background = $brushConv.ConvertFromString("#064E3B")
            $BadgeDriverStatus.BorderBrush = $brushConv.ConvertFromString("#059669")
            $TxtDriverStatus.Foreground = $brushConv.ConvertFromString("#4ADE80")
            $TxtDriverStatus.Text = [char]0x25CF + " Driver Booster Pro Installed"
        } else {
            $BadgeDriverStatus.Background = $brushConv.ConvertFromString("#1E1B4B")
            $BadgeDriverStatus.BorderBrush = $brushConv.ConvertFromString("#6366F1")
            $TxtDriverStatus.Foreground = $brushConv.ConvertFromString("#818CF8")
            $TxtDriverStatus.Text = [char]0x25CB + " Ready to Install"
        }
    }

    if ($TxtDriverBoosterStatus) {
        if ($isInstalled) {
            $TxtDriverBoosterStatus.Text = "Status: Installed and ready to use in $Script:DriverBoosterDir"
            $TxtDriverBoosterStatus.Foreground = $brushConv.ConvertFromString("#4ADE80")
        } else {
            $TxtDriverBoosterStatus.Text = "Status: Not installed. Click 'Install Driver Booster Pro' to install."
            $TxtDriverBoosterStatus.Foreground = $brushConv.ConvertFromString("#E2E8F0")
        }
    }

    if ($BtnUninstallDriverBooster) {
        $BtnUninstallDriverBooster.Visibility = if ($isInstalled) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
    if ($BtnInstallDriverBooster) {
        $BtnInstallDriverBooster.IsEnabled = $true
        if ($isInstalled) {
            $BtnInstallDriverBooster.Content = [char]0xD83D + [char]0xDE80 + " Launch Driver Booster"
        } else {
            $BtnInstallDriverBooster.Content = [char]0xD83D + [char]0xDCE5 + " Install Driver Booster Pro"
        }
    }
}

function Invoke-LaunchDriverBooster {
    $dir = $Script:DriverBoosterDir
    $lnk = Join-Path $dir "Driver Booster.lnk"
    $desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) "Driver Booster.lnk"
    $portExe = Join-Path $dir "DriverBoosterPortable.exe"

    # 1. Prefer launching the official desktop / folder shortcut via shell
    $targetLnk = if (Test-Path $desktopLnk) { $desktopLnk } elseif (Test-Path $lnk) { $lnk } else { $null }
    if ($targetLnk) {
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $targetLnk
            $psi.UseShellExecute = $true
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            Add-HubLog "Driver Booster: Launched successfully" "SUCCESS"
            return
        } catch {
            Add-HubLog "Shortcut launch note: $($_.Exception.Message)" "INFO"
        }
    }

    # 2. Launch portable launcher executable with WorkingDirectory and elevation
    if (Test-Path $portExe) {
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $portExe
            $psi.WorkingDirectory = $dir
            $psi.UseShellExecute = $true
            $psi.Verb = "runas"
            [System.Diagnostics.Process]::Start($psi) | Out-Null
            Add-HubLog "Driver Booster: Launched application" "SUCCESS"
            return
        } catch {
            Add-HubLog "Driver Booster launch failed: $($_.Exception.Message)" "ERROR"
        }
    }

    Add-HubLog "Driver Booster executable not found in $dir" "WARN"
}

function Invoke-InstallDriverBooster {
    if (Test-DriverBoosterInstalled) {
        Update-DriverUpdaterUI
        Invoke-LaunchDriverBooster
        return
    }

    if ($BtnInstallDriverBooster) {
        $BtnInstallDriverBooster.IsEnabled = $false
        $BtnInstallDriverBooster.Content = "Installing..."
    }
    if ($ProgressDriverBooster) {
        $ProgressDriverBooster.Visibility = [System.Windows.Visibility]::Visible
    }
    if ($TxtDriverBoosterStatus) {
        $TxtDriverBoosterStatus.Text = "Status: Downloading package and installing in background..."
        $TxtDriverBoosterStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    }

    Add-HubLog "Driver Booster: Downloading and installing package..." "INFO"

    if ($Script:DriverBoosterTimer) {
        try { $Script:DriverBoosterTimer.Stop() } catch {}
    }
    if ($Script:DriverBoosterPs) {
        try { $Script:DriverBoosterPs.Dispose() } catch {}
    }

    $Script:DriverBoosterPs = [powershell]::Create().AddScript({
        param($url, $destDir)
        $tempZip = Join-Path $env:TEMP "ZeroHub_DB.zip"
        try {
            if (Test-Path $tempZip) { Remove-Item $tempZip -Force -ErrorAction SilentlyContinue }
            (New-Object System.Net.WebClient).DownloadFile($url, $tempZip)
            
            if (-not (Test-Path $tempZip)) {
                return @{ Success = $false; Error = "Download did not complete." }
            }

            Expand-Archive -Path $tempZip -DestinationPath $destDir -Force
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue

            $desktopDir = [Environment]::GetFolderPath('Desktop')
            $lnk = Join-Path $destDir "IObitDriverBooster\Driver Booster.lnk"
            if (Test-Path $lnk) {
                Copy-Item $lnk (Join-Path $desktopDir "Driver Booster.lnk") -Force -ErrorAction SilentlyContinue
            }

            $portExe = Join-Path $destDir "IObitDriverBooster\DriverBoosterPortable.exe"
            $innerExe = Join-Path $destDir "IObitDriverBooster\App\DriverBooster\DriverBooster.exe"
            if ((Test-Path $portExe) -and (Test-Path $innerExe)) {
                return @{ Success = $true; Error = $null }
            } else {
                return @{ Success = $false; Error = "Files extracted but core components missing." }
            }
        } catch {
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }).AddArgument($Script:DriverBoosterUrl).AddArgument($env:ProgramData)

    $Script:DriverBoosterAsync = $Script:DriverBoosterPs.BeginInvoke()

    $Script:DriverBoosterTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:DriverBoosterTimer.Interval = [TimeSpan]::FromMilliseconds(400)
    $Script:DriverBoosterTimer.Add_Tick({
        if ($Script:DriverBoosterAsync.IsCompleted) {
            $Script:DriverBoosterTimer.Stop()
            $result = $null
            try {
                $raw = $Script:DriverBoosterPs.EndInvoke($Script:DriverBoosterAsync)
                if ($raw -and $raw.Count -gt 0) { $result = $raw[0] }
            } catch {
                $result = @{ Success = $false; Error = $_.Exception.Message }
            }
            try { $Script:DriverBoosterPs.Dispose() } catch {}
            $Script:DriverBoosterPs = $null
            $Script:DriverBoosterAsync = $null

            if ($result -and $result.Success) {
                Add-HubLog "Driver Booster: Installation verified and ready!" "SUCCESS"
                Update-DriverUpdaterUI
                Invoke-LaunchDriverBooster
            } else {
                $err = if ($result -and $result.Error) { $result.Error } else { "Installation was interrupted." }
                Add-HubLog "Driver Booster installation failed: $err" "ERROR"
                if ($TxtDriverBoosterStatus) {
                    $TxtDriverBoosterStatus.Text = "Status: Installation failed - $err"
                    $TxtDriverBoosterStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
                }
                if ($ProgressDriverBooster) {
                    $ProgressDriverBooster.Visibility = [System.Windows.Visibility]::Collapsed
                }
                if ($BtnInstallDriverBooster) {
                    $BtnInstallDriverBooster.IsEnabled = $true
                    $BtnInstallDriverBooster.Content = [char]0xD83D + [char]0xDCE5 + " Install Driver Booster Pro"
                }
            }
        }
    })
    $Script:DriverBoosterTimer.Start()
}

function Invoke-UninstallDriverBooster {
    try {
        if (Test-Path $Script:DriverBoosterDir) {
            Remove-Item $Script:DriverBoosterDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        $desktopLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) "Driver Booster.lnk"
        if (Test-Path $desktopLnk) {
            Remove-Item $desktopLnk -Force -ErrorAction SilentlyContinue
        }
        Add-HubLog "Driver Booster: Removed from ProgramData and Desktop" "INFO"
        Update-DriverUpdaterUI
    } catch {
        Add-HubLog "Failed to remove Driver Booster: $($_.Exception.Message)" "ERROR"
    }
}

if ($BtnInstallDriverBooster)   { $BtnInstallDriverBooster.add_Click({ Invoke-InstallDriverBooster }) }
if ($BtnLaunchDriverBooster)    { $BtnLaunchDriverBooster.add_Click({ Invoke-LaunchDriverBooster }) }
if ($BtnUninstallDriverBooster) { $BtnUninstallDriverBooster.add_Click({ Invoke-UninstallDriverBooster }) }
if ($BtnOpenDeviceManager)      { $BtnOpenDeviceManager.add_Click({ Start-Process "devmgmt.msc" -ErrorAction SilentlyContinue }) }
if ($BtnOpenDeviceManager2)     { $BtnOpenDeviceManager2.add_Click({ Start-Process "devmgmt.msc" -ErrorAction SilentlyContinue }) }
if ($BtnScanWinDrivers)         { $BtnScanWinDrivers.add_Click({ Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue }) }
if ($BtnOpenDxDiag)             { $BtnOpenDxDiag.add_Click({ Start-Process "dxdiag.exe" -ErrorAction SilentlyContinue }) }

