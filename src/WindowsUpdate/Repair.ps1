function Clear-WinUpdateCache {
    if (-not $isAdmin) {
        $msg = "Please run as Administrator to clear Windows Update cache."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($BtnCleanWuCache) {
        $BtnCleanWuCache.IsEnabled = $false
        $BtnCleanWuCache.Content = "⏳ Cleaning WU Cache..."
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = "Stopping services and clearing SoftwareDistribution\Download cache in background..."
    Add-HubLog "Beginning Windows Update cache purge in background..." "INFO"

    $asyncScript = {
        $freedMB = 0
        try {
            Stop-Service -Name "wuauserv", "bits", "cryptsvc" -Force -ErrorAction SilentlyContinue
            $swPath = "$env:SystemRoot\SoftwareDistribution\Download"
            if (Test-Path $swPath) {
                $items = Get-ChildItem -Path $swPath -Recurse -Force -ErrorAction SilentlyContinue
                $freedBytes = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$swPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                if ($freedBytes) { $freedMB = [math]::Round(($freedBytes / 1MB), 2) }
            }
        } finally {
            # finally, not the tail of the try: this block stops Windows Update, BITS and CryptSvc.
            # If anything above throws or the pipeline is stopped, the services must still come back
            # up, otherwise the machine is left with update and certificate services down.
            Start-Service -Name "wuauserv", "bits", "cryptsvc" -ErrorAction SilentlyContinue
        }
        return $freedMB
    }

    $Script:WuCachePs = [powershell]::Create()
    $Script:WuCachePs.AddScript($asyncScript) | Out-Null
    $Script:WuCacheHandle = $Script:WuCachePs.BeginInvoke()
    $Script:WuCacheTicks = 0

    $Script:WuCacheTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuCacheTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    # 200 ms x 900 = 180 s. The old budget was 30 ticks, six seconds, which a real
    # SoftwareDistribution purge almost never meets. Worse, on timeout the old code disposed the
    # still-running pipeline (Dispose stops it) and then printed the success message regardless, so
    # the run could be cut off between "Stop-Service wuauserv, bits, cryptsvc" and the restart while
    # the UI claimed it had worked. Wait properly, and never claim a result we did not read back.
    $Script:WuCacheTimer.add_Tick({
        $Script:WuCacheTicks++
        $timedOut = $Script:WuCacheTicks -ge 900
        if ($Script:WuCacheHandle.IsCompleted -or $timedOut) {
            $Script:WuCacheTimer.Stop()

            if ($BtnCleanWuCache) {
                $BtnCleanWuCache.IsEnabled = $true
                $BtnCleanWuCache.Content = "🧹 Clean WU Cache"
            }

            if (-not $Script:WuCacheHandle.IsCompleted) {
                # Deliberately not disposed: the pipeline still owns the stopped services and its
                # finally block is what brings them back. Killing it here is what broke machines.
                $warn = "Windows Update cache purge is still running after 180s. It has not finished yet."
                $StatusIcon.Text = "⏳"
                $StatusText.Text = $warn
                Add-HubLog "Windows Update cache purge still running after 180s. Not reporting a result, and leaving it to finish so the services get restarted." "WARN"
                return
            }

            $freedMB = 0
            $ok = $false
            try {
                $res = $Script:WuCachePs.EndInvoke($Script:WuCacheHandle)
                if ($res) { $freedMB = [double]$res[0] }
                $ok = $true
            } catch {
                Add-HubLog "Windows Update cache purge failed: $($_.Exception.Message)" "ERROR"
            }
            try { $Script:WuCachePs.Dispose() } catch {}

            if (-not $ok) {
                $StatusIcon.Text = "❌"
                $StatusText.Text = "Windows Update cache purge failed. See the Activity Log."
                return
            }

            $msg = "Cleaned Windows Update cache successfully! Freed $freedMB MB."
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Add-HubLog "Windows Update cache purged: $freedMB MB freed." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub" $msg
            Update-DriveInfo
        }
    })
    $Script:WuCacheTimer.Start()
}

$Script:WuResetPs     = $null
$Script:WuResetHandle = $null
$Script:WuResetTimer  = $null
$Script:WuResetTicks  = 0

function Reset-WinUpdateComponents {
    if (-not $isAdmin) {
        $msg = "Please run as Administrator to reset Windows Update."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # This does more than "repair update DLLs". netsh winsock reset rewrites the Winsock catalog,
    # which drops third-party LSPs and needs a reboot before networking is reliable again. That was
    # never stated anywhere in the UI or the README, so say it here and let the user decline.
    $resetPrompt = "ZeroHub will:`n`n  - stop the wuauserv, BITS and CryptSvc services temporarily`n  - re-register 18 Windows Update DLLs`n  - run netsh winsock reset`n`nWarning: the Winsock reset removes third-party network layer providers (VPN and security software hook in there) and needs a REBOOT before networking is reliable again.`n`nContinue?"
    $resetTitle = "ZeroHub - Confirm Component Reset"
    $resetConfirm = [System.Windows.MessageBox]::Show(
        $resetPrompt, $resetTitle,
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning,
        [System.Windows.MessageBoxResult]::No)
    if ($resetConfirm -ne [System.Windows.MessageBoxResult]::Yes) {
        Add-HubLog "Windows Update component reset declined by user. Nothing was changed." "INFO"
        return
    }

    if ($BtnResetWuComponents) {
        $BtnResetWuComponents.IsEnabled = $false
        $BtnResetWuComponents.Content = "⏳ Repairing Components & Network..."
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = "Re-registering update DLLs and resetting network & update components in background..."
    Add-HubLog "Starting fast background Windows Update component reset & DLL re-registration..." "INFO"

    $asyncScript = {
        try {
            Stop-Service -Name "wuauserv", "bits", "cryptsvc" -Force -ErrorAction SilentlyContinue
            $dllList = "wuapi.dll wuaueng.dll wups.dll wups2.dll qmgr.dll atl.dll urlmon.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll dssenh.dll rsaenh.dll cryptdlg.dll oleaut32.dll ole32.dll shell32.dll"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c for %d in ($dllList) do @if exist `"%SystemRoot%\System32\%d`" regsvr32.exe /s `"%SystemRoot%\System32\%d`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            return $true
        } catch {
            return $false
        } finally {
            # Same reasoning as the cache purge: these services are stopped above, so restarting
            # them belongs in finally. A throw or a stopped pipeline must not leave them down.
            Start-Service -Name "cryptsvc", "bits", "wuauserv" -ErrorAction SilentlyContinue
        }
    }

    $Script:WuResetPs = [powershell]::Create()
    $Script:WuResetPs.AddScript($asyncScript) | Out-Null
    $Script:WuResetHandle = $Script:WuResetPs.BeginInvoke()
    $Script:WuResetTicks = 0

    $Script:WuResetTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuResetTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    # Same 180 s budget and the same rule as the cache purge: 18 regsvr32 calls plus a winsock reset
    # do not finish in six seconds, and a timeout is not a success.
    $Script:WuResetTimer.add_Tick({
        $Script:WuResetTicks++
        $timedOut = $Script:WuResetTicks -ge 900
        if ($Script:WuResetHandle.IsCompleted -or $timedOut) {
            $Script:WuResetTimer.Stop()

            if ($BtnResetWuComponents) {
                $BtnResetWuComponents.IsEnabled = $true
                $BtnResetWuComponents.Content = "🔧 Reset Components"
            }

            if (-not $Script:WuResetHandle.IsCompleted) {
                # Left running on purpose so its finally block restarts the services it stopped.
                $warn = "Component reset is still running after 180s. It has not finished yet."
                $StatusIcon.Text = "⏳"
                $StatusText.Text = $warn
                Add-HubLog "Windows Update component reset still running after 180s. Not reporting a result, and leaving it to finish so the services get restarted." "WARN"
                return
            }

            $ok = $false
            try {
                $res = $Script:WuResetPs.EndInvoke($Script:WuResetHandle)
                $ok = [bool]($res -and $res[0])
            } catch {
                Add-HubLog "Windows Update component reset failed: $($_.Exception.Message)" "ERROR"
            }
            try { $Script:WuResetPs.Dispose() } catch {}

            if (-not $ok) {
                $StatusIcon.Text = "❌"
                $StatusText.Text = "Component reset failed. See the Activity Log."
                Add-HubLog "Windows Update component reset did not complete successfully." "ERROR"
                Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
                return
            }

            $msg = "Windows Update components reset. Reboot to complete the Winsock reset."
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Add-HubLog "Windows Update components and DLLs reset. A reboot is required to finish the Winsock reset." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub" $msg
            Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
        }
    })
    $Script:WuResetTimer.Start()
}

function Open-WinUpdateSettings {
    Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue
}

if ($BtnToggleWinUpdate) {
    $BtnToggleWinUpdate.add_Click({ Set-WindowsUpdatesState })
}
if ($BtnCleanWuCache) {
    $BtnCleanWuCache.add_Click({ Clear-WinUpdateCache })
}
if ($BtnResetWuComponents) {
    $BtnResetWuComponents.add_Click({ Reset-WinUpdateComponents })
}
if ($BtnOpenWuSettings) {
    $BtnOpenWuSettings.add_Click({ Open-WinUpdateSettings })
}

