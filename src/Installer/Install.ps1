# Batch Install & Upgrade Action Worker
function Install-SelectedApps {
    $selected = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($selected.Count -eq 0) { return }

    # Verify winget
    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCheck) {
        $noWingetMsg = "Microsoft Package Manager (winget) was not found on this PC. Please install App Installer from Microsoft Store."
        [System.Windows.MessageBox]::Show($noWingetMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $confirmMsg = if ($selected.Count -eq 1) {
        $actionWord = if ($selected[0].HasUpdate -or $selected[0].IsInstalled) { "upgrade" } else { "install" }
        "Do you want to silently $actionWord '$($selected[0].DisplayName)' via Winget?"
    } else {
        "Do you want to silently batch-install / upgrade ($($selected.Count)) selected apps via Winget?"
    }

    $confirmTitle = "ZeroHub - Install / Upgrade Apps"
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Activity Log Tab to show real-time installation progress
    $MainTabs.SelectedItem = $Tab_Log
    $BtnInstallSelectedApps.IsEnabled = $false

    $successCount = 0
    $idx = 0

    # Auto-close running app processes mapping to prevent file lock errors
    $appProcessMap = @{
        "OBSProject.OBSStudio"          = @("obs64", "obs32", "obs")
        "Microsoft.VisualStudioCode"    = @("Code")
        "Brave.Brave"                   = @("brave")
        "Google.Chrome"                 = @("chrome")
        "Mozilla.Firefox"               = @("firefox")
        "Discord.Discord"               = @("Discord")
        "Valve.Steam"                   = @("steam")
        "Spotify.Spotify"               = @("Spotify")
        "AutoHotkey.AutoHotkey"         = @("AutoHotkey", "AutoHotkey64", "AutoHotkey32", "AutoHotkeyUX")
        "Telegram.TelegramDesktop"      = @("Telegram")
        "VideoLAN.VLC"                  = @("vlc")
        "Notepad++.Notepad++"           = @("notepad++")
        "Git.Git"                       = @("git", "git-bash")
        "Docker.DockerDesktop"          = @("Docker Desktop")
        "ElectronicArts.EADesktop"      = @("EADesktop", "EALocalHostSvc", "EABackgroundService")
        "EpicGames.EpicGamesLauncher"   = @("EpicGamesLauncher")
        "Ubisoft.Connect"               = @("upc", "UbisoftConnect")
    }

    foreach ($app in $selected) {
        $idx++
        $isUpgrade = ($app.HasUpdate -eq $true -or $app.IsInstalled -eq $true)
        $actionVerb = if ($isUpgrade) { "Upgrading" } else { "Installing" }
        $statusStr = "[$idx / $($selected.Count)] $($actionVerb): $($app.DisplayName) ($($app.PackageId))..."
        Add-HubLog $statusStr "ACTION"
        Set-HubLogProgress $app.DisplayName 10 "🔎 Resolving package manifest..."
        [System.Windows.Forms.Application]::DoEvents()

        # Gracefully release locked files if application is currently open
        if ($appProcessMap.ContainsKey($app.PackageId)) {
            foreach ($pName in $appProcessMap[$app.PackageId]) {
                try {
                    $running = Get-Process -Name $pName -ErrorAction SilentlyContinue
                    if ($running) {
                        Add-HubLog "Closing running instance of $($app.DisplayName) ($pName) to release locked files..." "INFO"
                        $running | Stop-Process -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 400
                    }
                } catch {}
            }
        }

        try {
            $wingetCmd = if ($isUpgrade) { "upgrade" } else { "install" }
            $wingetArgs = "$wingetCmd --id $($app.PackageId) --silent --force --accept-package-agreements --accept-source-agreements -e"
            
            $currentStage = "⬇️ Downloading package binaries..."
            $currentPct = 15

            $onLineCallback = [Action[string]]{
                param($line)
                if ($line) {
                    if ($line -match '(?i)Found\s+(.+?)\s+\[') {
                        $currentStage = "🔎 Found $($Matches[1])"
                        $currentPct = 25
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Downloading\s+(.+)') {
                        $url = $Matches[1]
                        $fileName = [System.IO.Path]::GetFileName($url)
                        if (-not $fileName) { $fileName = "installer package" }
                        $currentStage = "⬇️ Downloading: $fileName"
                        $currentPct = 40
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Successfully verified|Verifying|Hash') {
                        $currentStage = "📦 Verifying SHA-256 Hash & Extracting..."
                        $currentPct = 78
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Starting package install|Installing') {
                        $currentStage = "⚙️ Executing Silent Installer..."
                        $currentPct = 88
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Successfully installed|Successfully upgraded') {
                        $currentStage = "✅ Successfully $actionVerb!"
                        $currentPct = 100
                        Complete-HubLogProgress $app.DisplayName $currentStage
                    } else {
                        Add-HubLog "  $line" "INFO"
                    }
                }
            }
            $onProgressCallback = [Action[int, string]]{
                param($pct, $msg)
                if ($pct -gt $currentPct) { $currentPct = $pct }
                Set-HubLogProgress $app.DisplayName $currentPct $currentStage
            }
            $onPumpCallback = [Action]{
                [System.Windows.Forms.Application]::DoEvents()
            }

            # Pre-clean orphaned update client registry tags that block newer versions
            if ($app.PackageId -eq "Brave.Brave") {
                Remove-Item "HKLM:\SOFTWARE\WOW6432Node\BraveSoftware\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "HKCU:\Software\BraveSoftware\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
            } elseif ($app.PackageId -eq "Google.Chrome") {
                Remove-Item "HKLM:\SOFTWARE\WOW6432Node\Google\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
            }

            $exitCode = [ZeroHub.AsyncProcessRunner]::Run("winget", $wingetArgs, $onLineCallback, $onPumpCallback, $onProgressCallback)

            # Resilient Direct Vendor Fallback if Winget repository is behind or blocked
            if ($exitCode -ne 0 -and $exitCode -ne 3010) {
                Add-HubLog "Winget reported code $exitCode. Attempting Direct Smart Install for $($app.DisplayName)..." "WARN"
                $directUrl = switch ($app.PackageId) {
                    "Brave.Brave"     { "https://laptop-updates.brave.com/latest/winx64" }
                    "Google.Chrome"   { "https://dl.google.com/chrome/install/standalonesetup64.exe" }
                    "Mozilla.Firefox" { "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" }
                    default           { $null }
                }

                if ($directUrl) {
                    try {
                        $tempSetup = "$env:TEMP\ZeroHub_$($app.PackageId)_setup.exe"
                        Set-HubLogProgress $app.DisplayName 45 "⬇️ Downloading official vendor package..."
                        [System.Windows.Forms.Application]::DoEvents()
                        (New-Object System.Net.WebClient).DownloadFile($directUrl, $tempSetup)
                        if (Test-Path $tempSetup) {
                            Set-HubLogProgress $app.DisplayName 85 "⚙️ Executing standalone vendor installer..."
                            [System.Windows.Forms.Application]::DoEvents()
                            $directProc = Start-Process -FilePath $tempSetup -ArgumentList "/silent /install" -PassThru -Wait -ErrorAction SilentlyContinue
                            if ($directProc -and ($directProc.ExitCode -eq 0 -or $null -eq $directProc.ExitCode)) {
                                $exitCode = 0
                            }
                        }
                    } catch {
                        Add-HubLog "Direct fallback note: $($_.Exception.Message)" "WARN"
                    }
                }
            }

            if ($exitCode -eq 0 -or $exitCode -eq 3010) {
                Complete-HubLogProgress $app.DisplayName "✅ Completed $actionVerb successfully!"
                Add-HubLog "Successfully completed $actionVerb for $($app.DisplayName)!" "SUCCESS"
                $successCount++
                if ($Script:AvailableWingetUpgrades -and $Script:AvailableWingetUpgrades.ContainsKey($app.PackageId)) {
                    [void]$Script:AvailableWingetUpgrades.Remove($app.PackageId)
                }
                [void]$Script:DismissedUpgradeIds.Add($app.PackageId)
                # Directly clear update state on in-memory object
                $targetItem = @($Script:InstallerCatalogList | Where-Object { $_.PackageId -eq $app.PackageId })
                foreach ($tItem in $targetItem) {
                    $tItem.HasUpdate = $false
                    $tItem.IsInstalled = $true
                    $tItem.IsSelected = $false
                    $tItem.Status = "✅ Installed"
                    $tItem.StatusBg = "#064E3B"
                    $tItem.StatusFg = "#34D399"
                    $tItem.StatusVisibility = "Visible"
                    $tItem.NameFg = "#34D399"
                }
                Remove-Item "$env:TEMP\winget_upgrades_raw.txt" -Force -ErrorAction SilentlyContinue
            } else {
                Complete-HubLogProgress $app.DisplayName "⚠️ Finished with exit code $exitCode"
                Add-HubLog "Winget completed with exit code $exitCode for $($app.DisplayName)" "WARN"
            }
        } catch {
            Add-HubLog "Error processing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = "Process Complete! Successfully installed/upgraded $successCount of $($selected.Count) app(s)."
    Add-HubLog $summary "SUCCESS"
    Show-ZeroToastNotification "ZeroHub - App Installer" $summary

    # Invalidate cache and refresh immediately in background
    Clear-DataCacheStamp "installer"
    Initialize-InstallerCatalogList
    Set-InstallerFilters
    $BtnInstallSelectedApps.IsEnabled = $true
    Get-WingetUpgradesAsync
}

if ($BtnInstallSelectedApps) {
    $BtnInstallSelectedApps.add_Click({ Install-SelectedApps })
}

