function Invoke-ClearDefenderProtectionHistory {
    if ($BtnClearProtHistory) {
        $BtnClearProtHistory.IsEnabled = $false
        $BtnClearProtHistory.Content = "⏳ Clearing History..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Purging Windows Defender DetectionHistory cache files..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $histPath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory"
        $storePath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Store"

        if (Test-Path $histPath) {
            Remove-Item -Path "$histPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $storePath) {
            Remove-Item -Path "$storePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 400

        $msg = "Windows Defender Protection History purged successfully! Stuck threat notifications cleared."
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
    } catch {
        Add-HubLog "Error clearing protection history: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnClearProtHistory) {
            $BtnClearProtHistory.Content = "✅ Protection History Cleared!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnClearProtHistory) {
                    $BtnClearProtHistory.IsEnabled = $true
                    $BtnClearProtHistory.Content = "🧹 Clear Protection History"
                }
            })
            $timer.Start()
        }
    }
}

function Invoke-DefenderQuickScan {
    if ($BtnDefenderQuickScan) {
        $BtnDefenderQuickScan.IsEnabled = $false
        $BtnDefenderQuickScan.Content = "⏳ Quick Scanning..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Launching Windows Defender background Quick Scan..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -Command Start-MpScan -ScanType QuickScan" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        $msg = "Windows Defender Quick Scan started in the background!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
    } catch {
        Add-HubLog "Error launching quick scan: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnDefenderQuickScan) {
            $BtnDefenderQuickScan.Content = "✅ Scan Launched!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnDefenderQuickScan) {
                    $BtnDefenderQuickScan.IsEnabled = $true
                    $BtnDefenderQuickScan.Content = "⚡ Quick Scan"
                }
            })
            $timer.Start()
        }
    }
}

function Invoke-UpdateDefenderSignatures {
    if ($BtnUpdateSignatures) {
        $BtnUpdateSignatures.IsEnabled = $false
        $BtnUpdateSignatures.Content = "⏳ Updating in background..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Downloading latest Windows Defender definitions in background..."

    # Launch background process asynchronously so WPF UI never freezes
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command Update-MpSignature" -NoNewWindow -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue

    $pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $pollTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $pollTimer.add_Tick({
        param($s, $e)
        if (-not $proc -or $proc.HasExited) {
            $s.Stop()
            if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
            $msg = "Windows Defender signatures updated successfully!"
            $StatusIcon.Text = [char]0xE73E
            $StatusText.Text = $msg
            Add-HubLog $msg "SUCCESS"
            Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
            Update-DefenderUI

            if ($BtnUpdateSignatures) {
                $BtnUpdateSignatures.Content = "✅ Updated!"
                $resetTimer = [System.Windows.Threading.DispatcherTimer]::new()
                $resetTimer.Interval = [TimeSpan]::FromSeconds(3)
                $resetTimer.add_Tick({
                    param($ts, $te)
                    $ts.Stop()
                    if ($BtnUpdateSignatures) {
                        $BtnUpdateSignatures.IsEnabled = $true
                        $BtnUpdateSignatures.Content = "🔄 Update Signatures"
                    }
                })
                $resetTimer.Start()
            }
        }
    })
    $pollTimer.Start()
}

function Update-DefenderUI {
    if (-not $Tab_Defender) { return }

    # 1. Antivirus Live Status
    $status = Get-DefenderLiveStatus
    if ($BadgeDefenderStatus -and $TxtDefenderStatus) {
        if ($status.RealTime -and $status.AntivirusEnabled) {
            $BadgeDefenderStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
            $BadgeDefenderStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
            $TxtDefenderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            $TxtDefenderStatus.Text = "● Real-Time Antivirus Active (v$($status.SignatureVersion))"
        } else {
            $BadgeDefenderStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
            $BadgeDefenderStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
            $TxtDefenderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            $TxtDefenderStatus.Text = "● Protection Inactive / Managed Externally"
        }
    }



    # 3. Active Exclusions List
    $exclusions = Get-DefenderExclusionsList
    if ($ListDefenderExclusions) {
        $ListDefenderExclusions.ItemsSource = @($exclusions)
    }
    if ($TxtExclusionCountInfo) {
        $TxtExclusionCountInfo.Text = "$($exclusions.Count) Excluded Folders"
    }
}

# Wire Defender Buttons
if ($BtnDefenderQuickScan) {
    $BtnDefenderQuickScan.add_Click({ Invoke-DefenderQuickScan })
}
if ($BtnUpdateSignatures) {
    $BtnUpdateSignatures.add_Click({ Invoke-UpdateDefenderSignatures })
}
if ($BtnOpenWinSecurity) {
    $BtnOpenWinSecurity.add_Click({
        try {
            Start-Process "windowsdefender://" -ErrorAction SilentlyContinue
        } catch {
            Start-Process "ms-settings:windowsdefender" -ErrorAction SilentlyContinue
        }
    })
}
if ($BtnAddDetectedGames) {
    $BtnAddDetectedGames.add_Click({ Add-AllDetectedGameExclusions })
}
if ($BtnAddCustomExclusion) {
    $BtnAddCustomExclusion.add_Click({ Add-CustomDefenderExclusionDialog })
}
if ($BtnRefreshExclusions) {
    $BtnRefreshExclusions.add_Click({ Update-DefenderUI })
}
if ($BtnClearProtHistory) {
    $BtnClearProtHistory.add_Click({ Invoke-ClearDefenderProtectionHistory })
}

