# ==========================================
# GITHUB LIVE AUTO-UPDATE ENGINE
# ==========================================
$Script:CurrentAppVersion = "1.3.6"
$Script:GitHubRepo        = "ZeroIQs/Zerohub"
$Script:HasAvailableUpdate = $false
$Script:LatestUpdateTag   = ""
$Script:UpdateResetTimer  = $null

function Set-SidebarUpdateButtonVisuals([string]$mode, [string]$tag = "") {
    if (-not $BorderSidebarUpdate -or -not $TxtSidebarUpdate) { return }

    $brushConv = [System.Windows.Media.BrushConverter]::new()

    if ($mode -eq "UPDATE_AVAILABLE") {
        # Vibrant Crimson Red Styling for Available Update
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#E11D48")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#FB7185")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE896 # Download glyph
            $IconSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        }
        $TxtSidebarUpdate.Text       = "Update $tag Available!"
        $TxtSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = [System.Windows.Media.Brushes]::White
        }
    }
    elseif ($mode -eq "UP_TO_DATE") {
        # Green Checkmark state: User has the latest version
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#064E3B")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#059669")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE73E # Checkmark glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#4ADE80")
        }
        $TxtSidebarUpdate.Text       = "You are using the latest version"
        $TxtSidebarUpdate.Foreground = $brushConv.ConvertFromString("#4ADE80")
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#4ADE80")
        }
    }
    elseif ($mode -eq "CHECKING") {
        # Checking state
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#111827")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#0284C7")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE72C # Sync glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
        $TxtSidebarUpdate.Text       = "Checking..."
        $TxtSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
    }
    else {
        # Normal Idle State
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#111827")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#1F2937")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE72C # Sync glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
        $TxtSidebarUpdate.Text       = "Check for Updates"
        $TxtSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#64748B")
        }
    }
}

$Script:IsManualUpdateCheck = $false

function Check-GitHubAppUpdateAsync([bool]$isManual = $false) {
    $Script:IsManualUpdateCheck = $isManual

    if ($isManual) {
        if ($BtnManualCheckUpdates) {
            $BtnManualCheckUpdates.IsEnabled = $false
            $BtnManualCheckUpdates.Content = "⏳ Checking for Updates..."
        }
        if ($TxtAboutUpdateStatus) {
            $TxtAboutUpdateStatus.Text = "Checking for new releases on GitHub..."
            $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
        }
        Set-SidebarUpdateButtonVisuals "CHECKING"
    }

    # Instant offline check: If no network adapter is online, skip in 0ms!
    $isOnline = $false
    try {
        $isOnline = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
    } catch {}

    if (-not $isOnline) {
        if ($Script:IsManualUpdateCheck) {
            if ($TxtAboutUpdateStatus) {
                $TxtAboutUpdateStatus.Text = "Offline Mode (No Internet Connection)"
                $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
            }
            Set-SidebarUpdateButtonVisuals "NORMAL"
            if ($BtnManualCheckUpdates) {
                $BtnManualCheckUpdates.IsEnabled = $true
                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
            }
        }
        return
    }

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

        $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $rawUrl = "https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.ps1?nocache=$ts"

        $Script:UpdateWebClient = New-Object System.Net.WebClient
        $Script:UpdateWebClient.Headers.Add("User-Agent", "ZeroHub-UpdateChecker")
        $Script:UpdateWebClient.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")

        $Script:UpdateWebClient.add_DownloadStringCompleted({
            param($srcClient, $e)
            if (-not $Window) { return }

            $Window.Dispatcher.Invoke([Action]{
                $wasManual = $Script:IsManualUpdateCheck
                try {
                    $hasErr = $e.Error -or [string]::IsNullOrWhiteSpace($e.Result)
                    if ($hasErr) {
                        if ($TxtAboutUpdateStatus) {
                            $TxtAboutUpdateStatus.Text = "You are using the latest version (v$($Script:CurrentAppVersion))"
                            $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                        }
                        if ($wasManual) {
                            Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                            }
                            Show-ZeroToastNotification "ZeroHub is Up to Date" "You are using the latest version (v$($Script:CurrentAppVersion))."

                            if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                            $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                            $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                            $Script:UpdateResetTimer.Add_Tick({
                                $Script:UpdateResetTimer.Stop()
                                if (-not $Script:HasAvailableUpdate) {
                                    Set-SidebarUpdateButtonVisuals "NORMAL"
                                    if ($BtnManualCheckUpdates) {
                                        $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                    }
                                }
                            })
                            $Script:UpdateResetTimer.Start()
                        } else {
                            Set-SidebarUpdateButtonVisuals "NORMAL"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                            }
                        }
                        return
                    }

                    $rawText = $e.Result
                    $cleanTag = $null
                    if ($rawText -match '\$Script:CurrentAppVersion\s*=\s*["'']([^"'']+)["'']') {
                        $cleanTag = $Matches[1].Trim().TrimStart('v', 'V')
                    }

                    if (-not [string]::IsNullOrWhiteSpace($cleanTag)) {
                        $curVer = [System.Version]::Parse($Script:CurrentAppVersion)
                        $latVer = [System.Version]::Parse($cleanTag)

                        if ($latVer -gt $curVer) {
                            # Newer release found on GitHub -> Highlight RED button!
                            $Script:HasAvailableUpdate = $true
                            $Script:LatestUpdateTag   = $cleanTag

                            Set-SidebarUpdateButtonVisuals "UPDATE_AVAILABLE" "v$cleanTag"

                            if ($BtnAppUpdate) {
                                $BtnAppUpdate.Visibility = [System.Windows.Visibility]::Visible
                                $TxtAppUpdate.Text = "🚀 Update v$cleanTag Available!"
                            }
                            if ($TxtAppUpdateStatus) {
                                $TxtAppUpdateStatus.Text = "New version available on GitHub: v$cleanTag"
                                $TxtAppUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FB7185")
                            }
                            if ($BtnAppUpdateTab) {
                                $BtnAppUpdateTab.Visibility = [System.Windows.Visibility]::Visible
                                $BtnAppUpdateTab.Content = "🚀 Install v$cleanTag"
                            }
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Re-check GitHub"
                            }
                            Add-HubLog "New ZeroHub release detected on GitHub: v$cleanTag (Current: v$($Script:CurrentAppVersion))." "INFO"

                            if (-not $wasManual) {
                                Show-ZeroToastNotification "ZeroHub: New Update Available! (v$cleanTag)" "Version v$cleanTag is available on GitHub with new performance improvements. Click Updates in the sidebar to install."
                            }
                        } else {
                            # Up to date
                            $Script:HasAvailableUpdate = $false
                            if ($TxtAppUpdateStatus) {
                                $TxtAppUpdateStatus.Text = "You are using the latest version (v$($Script:CurrentAppVersion))"
                                $TxtAppUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                            }
                            if ($BtnAppUpdateTab) {
                                $BtnAppUpdateTab.Visibility = [System.Windows.Visibility]::Collapsed
                            }

                            if ($wasManual) {
                                Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                                if ($BtnManualCheckUpdates) {
                                    $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                                }
                                Show-ZeroToastNotification "ZeroHub is Up to Date" "You are using the latest version (v$($Script:CurrentAppVersion))."

                                if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                                $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                                $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                                $Script:UpdateResetTimer.Add_Tick({
                                    $Script:UpdateResetTimer.Stop()
                                    if (-not $Script:HasAvailableUpdate) {
                                        Set-SidebarUpdateButtonVisuals "NORMAL"
                                        if ($BtnManualCheckUpdates) {
                                            $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                        }
                                    }
                                })
                                $Script:UpdateResetTimer.Start()
                            } else {
                                Set-SidebarUpdateButtonVisuals "NORMAL"
                                if ($BtnManualCheckUpdates) {
                                    $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                }
                            }
                        }
                    } else {
                        if ($wasManual) {
                            Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                            }
                            if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                            $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                            $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                            $Script:UpdateResetTimer.Add_Tick({
                                $Script:UpdateResetTimer.Stop()
                                if (-not $Script:HasAvailableUpdate) {
                                    Set-SidebarUpdateButtonVisuals "NORMAL"
                                    if ($BtnManualCheckUpdates) {
                                        $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                    }
                                }
                            })
                            $Script:UpdateResetTimer.Start()
                        } else {
                            Set-SidebarUpdateButtonVisuals "NORMAL"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                            }
                        }
                    }
                } finally {
                    if ($BtnManualCheckUpdates) {
                        $BtnManualCheckUpdates.IsEnabled = $true
                    }
                    try { $srcClient.Dispose() } catch {}
                }
            })
        })

        $Script:UpdateWebClient.DownloadStringAsync([Uri]::new($rawUrl))
    } catch {
        if ($Script:IsManualUpdateCheck) {
            Set-SidebarUpdateButtonVisuals "NORMAL"
            if ($BtnManualCheckUpdates) {
                $BtnManualCheckUpdates.IsEnabled = $true
                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
            }
        }
    }
}

function Invoke-PerformSelfAppUpdate {
    if (-not $Script:HasAvailableUpdate) {
        Check-GitHubAppUpdateAsync $true
        return
    }

    $confirmMsg = "Download and install ZeroHub ($($Script:LatestUpdateTag)) from GitHub now? The application will update in-place wherever it is stored and automatically restart."
    $res = [System.Windows.MessageBox]::Show($confirmMsg, "ZeroHub Auto-Updater", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        try {
            # 1. Retrieve the exact running script path stored at startup
            $targetPs1 = $Script:RunningScriptPath
            if (-not $targetPs1 -or -not (Test-Path $targetPs1)) {
                if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
                    $targetPs1 = $PSCommandPath
                } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"))) {
                    $targetPs1 = Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"
                } elseif (Test-Path (Join-Path (Get-Location).Path "ZeroHub-GUI.ps1")) {
                    $targetPs1 = Join-Path (Get-Location).Path "ZeroHub-GUI.ps1"
                } else {
                    $targetPs1 = Join-Path $env:LOCALAPPDATA "ZeroHub\ZeroHub-GUI.ps1"
                }
            }

            $targetDir = Split-Path -Path $targetPs1 -Parent
            $targetBat = Join-Path $targetDir "ZeroHub-GUI.bat"

            # 2. Download newest release files to TEMP
            $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $tempPs1 = Join-Path $env:TEMP "ZeroHub_Update_$ts.ps1"
            $tempBat = Join-Path $env:TEMP "ZeroHub_Update_$ts.bat"

            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "ZeroHub-AutoUpdater")
            $wc.DownloadFile("https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.ps1?nocache=$ts", $tempPs1)
            try {
                $wc.DownloadFile("https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.bat?nocache=$ts", $tempBat)
            } catch {}

            # 3. Integrity Verification (> 100 KB)
            if ((Test-Path $tempPs1) -and ((Get-Item $tempPs1).Length -gt 100000)) {
                # In-place overwrite in user's current folder
                Copy-Item -Path $tempPs1 -Destination $targetPs1 -Force
                if (Test-Path $tempBat) {
                    try { Copy-Item -Path $tempBat -Destination $targetBat -Force } catch {}
                }

                # Also synchronize %LOCALAPPDATA%\ZeroHub cache if it exists
                $appDataDir = Join-Path $env:LOCALAPPDATA "ZeroHub"
                if (Test-Path $appDataDir) {
                    try {
                        Copy-Item -Path $tempPs1 -Destination (Join-Path $appDataDir "ZeroHub-GUI.ps1") -Force
                        if (Test-Path $tempBat) {
                            Copy-Item -Path $tempBat -Destination (Join-Path $appDataDir "ZeroHub-GUI.bat") -Force
                        }
                    } catch {}
                }

                # Clean temporary downloaded files
                try { Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue } catch {}
                try { Remove-Item $tempBat -Force -ErrorAction SilentlyContinue } catch {}

                # 4. Seamlessly relaunch the updated ZeroHub instance
                $launchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$targetPs1`""
                Start-Process "powershell.exe" -ArgumentList $launchArgs -WorkingDirectory $targetDir
                $Window.Close()
            } else {
                throw "Downloaded update file was incomplete. Please check your internet connection."
            }
        } catch {
            [System.Windows.MessageBox]::Show("Update failed: $($_.Exception.Message)", "ZeroHub Update Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
}

# Wire Update Checker & Auto-Updater Click Handlers
if ($BtnAppUpdateTab) {
    $BtnAppUpdateTab.add_Click({
        Invoke-PerformSelfAppUpdate
    })
}
if ($BtnSidebarUpdate) {
    $BtnSidebarUpdate.add_Click({
        $MainTabs.SelectedItem = $Tab_AppUpdate
        if ($Script:HasAvailableUpdate) {
            Invoke-PerformSelfAppUpdate
        } else {
            Check-GitHubAppUpdateAsync $true
        }
    })
}
if ($BtnManualCheckUpdates) {
    $BtnManualCheckUpdates.add_Click({
        Check-GitHubAppUpdateAsync $true
    })
}

if ($BtnToggleNotifications) {
    $BtnToggleNotifications.add_Click({
        $Script:AppNotificationsEnabled = -not $Script:AppNotificationsEnabled
        Update-NotificationToggleUI
        Save-ZeroHubSettings
        if ($Script:AppNotificationsEnabled) {
            Add-HubLog "Windows toast notifications enabled for ZeroHub." "INFO"
            Show-ZeroToastNotification "ZeroHub Notifications" "Notifications are now active."
        } else {
            Add-HubLog "Windows toast notifications turned OFF for ZeroHub." "INFO"
        }
    })
}



