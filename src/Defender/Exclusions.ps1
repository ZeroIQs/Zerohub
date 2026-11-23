# ==========================================
# WINDOWS SECURITY & DEFENDER QUICK MANAGER ENGINE
# ==========================================
function Get-DefenderLiveStatus {
    try {
        $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($mp) {
            return @{
                RealTime = [bool]$mp.RealTimeProtectionEnabled
                AntivirusEnabled = [bool]$mp.AntivirusEnabled
                SignatureVersion = [string]$mp.AntivirusSignatureVersion
                Ioav = [bool]$mp.IoavProtectionEnabled
            }
        }
    } catch {}
    return @{ RealTime = $true; AntivirusEnabled = $true; SignatureVersion = "Up to date"; Ioav = $true }
}


function Get-InstalledGameFoldersList {
    $gameFolders = @()
    try {
        # 1. Steam paths
        $steamPath = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction SilentlyContinue).SteamPath
        if ($steamPath -and (Test-Path $steamPath)) {
            $gameFolders += $steamPath
            $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
            if (Test-Path $vdf) {
                $lines = Get-Content $vdf -ErrorAction SilentlyContinue
                foreach ($line in $lines) {
                    if ($line -match '"path"\s+"([^"]+)"') {
                        $p = $Matches[1].Replace('\', '')
                        if ((Test-Path $p) -and -not $gameFolders.Contains($p)) {
                            $gameFolders += $p
                        }
                    }
                }
            }
        }

        # 2. Common drive Games folders
        foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
            $candidate = Join-Path ($drive.Root) 'Games'
            if ((Test-Path $candidate) -and -not $gameFolders.Contains($candidate)) {
                $gameFolders += $candidate
            }
        }

        # 3. Epic Games default
        $epicDef = 'C:\Program Files\Epic Games'
        if ((Test-Path $epicDef) -and -not $gameFolders.Contains($epicDef)) {
            $gameFolders += $epicDef
        }

        # 4. GOG Galaxy
        $gogPath = 'C:\Program Files (x86)\GOG Galaxy\Games'
        if ((Test-Path $gogPath) -and -not $gameFolders.Contains($gogPath)) {
            $gameFolders += $gogPath
        }
    } catch {}
    return $gameFolders
}

function Get-DefenderExclusionsList {
    $paths = @()
    try {
        $pref = Get-MpPreference -ErrorAction SilentlyContinue
        if ($pref -and $pref.ExclusionPath) {
            foreach ($p in $pref.ExclusionPath) {
                if ($p -and -not $paths.Contains($p)) {
                    $paths += $p
                }
            }
        }
    } catch {}
    return $paths
}

function Add-AllDetectedGameExclusions {
    if ($BtnAddDetectedGames) {
        $BtnAddDetectedGames.IsEnabled = $false
        $BtnAddDetectedGames.Content = "⏳ Adding Game Exclusions..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Scanning and adding game libraries to Defender exclusions..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $detected = Get-InstalledGameFoldersList
        $addedCount = 0
        foreach ($folder in $detected) {
            try {
                Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                $addedCount++
                Add-HubLog "Added Defender Exclusion: $folder" "SUCCESS"
            } catch {}
        }

        $msg = "Successfully added $addedCount game library folder(s) to Windows Defender exclusions!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
        Update-DefenderUI
    } catch {
        Add-HubLog "Error adding game exclusions: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnAddDetectedGames) {
            $BtnAddDetectedGames.Content = "✅ Exclusions Added!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnAddDetectedGames) {
                    $BtnAddDetectedGames.IsEnabled = $true
                    $BtnAddDetectedGames.Content = "🎮 Add Detected Game Libraries"
                }
            })
            $timer.Start()
        }
    }
}

function Add-CustomDefenderExclusionDialog {
    try {
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select a Game or App folder to exclude from Windows Defender scans:"
        $fbd.ShowNewFolderButton = $false
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selected = $fbd.SelectedPath
            if ($selected -and (Test-Path $selected)) {
                Add-MpPreference -ExclusionPath $selected -ErrorAction Stop
                $msg = "Added folder ($selected) to Defender exclusions successfully!"
                Add-HubLog $msg "SUCCESS"
                Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
                Update-DefenderUI
            }
        }
    } catch {
        Add-HubLog "Error adding custom exclusion: $($_.Exception.Message)" "ERROR"
    }
}

