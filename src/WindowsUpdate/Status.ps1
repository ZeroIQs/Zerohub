# ==========================================
# ==========================================
# WINDOWS AUTOMATIC UPDATES CONTROLLER LOGIC
# ==========================================
function Get-WinUpdateStatus {
    $service = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $noAuto = 0
    if (Test-Path $auPath) {
        $val = (Get-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate
        if ($val -eq 1) { $noAuto = 1 }
    }

    $isBlocked = ($service -and $service.StartType -eq "Disabled") -or ($noAuto -eq 1)
    return $isBlocked
}

function Update-WinUpdateUI {
    if (-not $BtnToggleWinUpdate -or -not $TxtWinUpdateStatus) { return }
    $isBlocked = Get-WinUpdateStatus

    if ($isBlocked) {
        # Updates are Blocked / Paused
        $TxtWinUpdateStatus.Text = "● Updates: Blocked / Paused"
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#371B28")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")

        $BtnToggleWinUpdate.Content = "Enable Windows Updates"
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = "● Services Stopped & Disabled"
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = "● Auto-Downloads Blocked"
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = "● Scan Tasks Disabled"
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = "● Driver Shield Active"
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
    } else {
        # Updates are Active
        $TxtWinUpdateStatus.Text = "● Updates: Active & Enabled"
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")

        $BtnToggleWinUpdate.Content = "Block Windows Updates"
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = "● Services Active (Default)"
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = "● Policies Active (Default)"
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = "● Tasks Scheduled (Default)"
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = "● Default Windows Mode"
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        }
    }
}

function Set-WindowsUpdatesState {
    $isBlocked = Get-WinUpdateStatus

    if (-not $isAdmin) {
        $msg = "Please run ZeroHub as Administrator to modify Windows Update settings."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($isBlocked) {
        # ENABLE UPDATES
        try {
            Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "WaaSMedicSvc" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (Test-Path $auPath) {
                Remove-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $auPath -Name "AUOptions" -ErrorAction SilentlyContinue
            }

            $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            if (Test-Path $wuPath) {
                Remove-ItemProperty -Path $wuPath -Name "SetDisableUXWUAccess" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $wuPath -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
            }

            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan" -ErrorAction SilentlyContinue
            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan Static" -ErrorAction SilentlyContinue
            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "Scheduled Start" -ErrorAction SilentlyContinue

            $successMsg = "Windows Updates have been successfully enabled! You can now check for updates normally."
            Add-HubLog "Windows Updates successfully enabled." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Add-HubLog "Error enabling Windows Updates: $($_.Exception.Message)" "ERROR"
        }
    } else {
        # STOP & BLOCK UPDATES
        try {
            Stop-Service -Name "wuauserv", "UsoSvc", "WaaSMedicSvc" -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "WaaSMedicSvc" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
            Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 1 -Type DWord -Force

            $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
            Set-ItemProperty -Path $wuPath -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $wuPath -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force

            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan Static" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "UpdateModelTask" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "Scheduled Start" -ErrorAction SilentlyContinue

            $successMsg = "Windows Automatic Updates have been successfully stopped and blocked!"
            Add-HubLog "Windows Updates successfully stopped and blocked." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Add-HubLog "Error stopping Windows Updates: $($_.Exception.Message)" "ERROR"
        }
    }

    Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
}

$Script:WuCachePs     = $null
$Script:WuCacheHandle = $null
$Script:WuCacheTimer  = $null
$Script:WuCacheTicks  = 0

