function Invoke-BoostAndLaunchGame([ZeroHub.GameItem]$game, [bool]$boost) {
    try {
        if ($null -eq $game) { return }

        $freedMb = 0
        if ($boost) {
            # 1. Purge Standby & Process RAM
            try {
                $before = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
                [ZeroHub.NativeMethods]::EmptyWorkingSet(-1) | Out-Null
                $after = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
                $freedMb = [math]::Max(0, [math]::Round(($after - $before) / 1024, 0))
            } catch {}

            # 2. Pause Windows Updates & BITS temporarily
            try {
                Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue | Out-Null
                Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue | Out-Null
            } catch {}

            # 3. High Performance Power Scheme
            try {
                powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
            } catch {}

            Add-HubLog "🚀 Game Booster: Cleaned ${freedMb}MB RAM, paused background updates for $($game.Name)." "BOOST"
        }

        # Launch Game (Protocol, Shell App, or Direct Exe)
        if ($game.LaunchUri -match '^[a-zA-Z0-9_\-\.]+://' -or $game.LaunchUri.StartsWith("shell:")) {
            Start-Process $game.LaunchUri
        } elseif (Test-Path $game.LaunchUri) {
            Start-Process -FilePath $game.LaunchUri -WorkingDirectory ([System.IO.Path]::GetDirectoryName($game.LaunchUri))
        } else {
            Start-Process "cmd.exe" -ArgumentList "/c start `"`" `"$($game.LaunchUri)`"" -WindowStyle Hidden
        }

        $msg = if ($boost) {
            "🚀 Boost & Launch: $($game.Name) is now running! Freed ${freedMb}MB RAM with High CPU Priority."
        } else {
            "▶️ Launching $($game.Name)..."
        }

        Show-ZeroToastNotification "ZeroHub - Game Booster" $msg
        Add-HubLog $msg "SUCCESS"

        # Background Priority Booster Watcher (up to 15 seconds)
        if ($boost) {
            $Script:GameBoostTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $Script:GameBoostTimer.Interval = [TimeSpan]::FromSeconds(2)
            $Script:BoostAttempts = 0
            $Script:GameBoostTimer.Add_Tick({
                $Script:BoostAttempts++
                $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
                    $_.ProcessName -match ($game.Name -replace '[^a-zA-Z0-9]', '') -or 
                    ($game.InstallDir -and $_.Path -and $_.Path.StartsWith($game.InstallDir)) 
                }
                foreach ($p in $procs) {
                    try {
                        $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                        Add-HubLog "Set CPU Priority to HIGH for game process $($p.ProcessName) (PID: $($p.Id))." "BOOST"
                        $Script:GameBoostTimer.Stop()
                        return
                    } catch {}
                }
                if ($Script:BoostAttempts -ge 7) {
                    $Script:GameBoostTimer.Stop()
                }
            })
            $Script:GameBoostTimer.Start()
        }
    } catch {
        Add-HubLog "Error launching game $($game.Name): $($_.Exception.Message)" "ERROR"
    }
}

function Show-AddCustomGameDialog {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $ofd = [System.Windows.Forms.OpenFileDialog]::new()
        $ofd.Filter = "Game Executable (*.exe;*.lnk)|*.exe;*.lnk|All Files (*.*)|*.*"
        $ofd.Title = "Select Game Executable or Shortcut"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedPath = $ofd.FileName
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($selectedPath)
            
            $customDir = [System.IO.Path]::GetDirectoryName($Script:CustomGamesFilePath)
            if (-not (Test-Path $customDir)) { New-Item -Path $customDir -ItemType Directory -Force | Out-Null }
            
            $existing = @()
            if (Test-Path $Script:CustomGamesFilePath) {
                $existing = @(Get-Content $Script:CustomGamesFilePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue)
            }
            $newEntry = @{
                Name = $baseName
                Platform = "Custom"
                InstallDir = [System.IO.Path]::GetDirectoryName($selectedPath)
                LaunchUri = $selectedPath
            }
            $existing += $newEntry
            $existing | ConvertTo-Json -Depth 4 | Set-Content -Path $Script:CustomGamesFilePath -Encoding UTF8
            Add-HubLog "Added custom game '$baseName' to Game Hub." "GAMEHUB"
            Update-GameLibraryList
        }
    } catch {
        Add-HubLog "Error adding custom game: $($_.Exception.Message)" "ERROR"
    }
}

if ($BtnAddCustomGame) {
    $BtnAddCustomGame.add_Click({ Show-AddCustomGameDialog })
}
if ($BtnRefreshGames) {
    $BtnRefreshGames.add_Click({ Update-GameLibraryList })
}

# Attach Card Button Click Router
$GameCardsContainer.AddHandler(
    [System.Windows.Controls.Primitives.ButtonBase]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        param($src, $e)
        $btn = $e.OriginalSource
        if ($btn -is [System.Windows.Controls.Button]) {
            $game = $btn.Tag
            if ($game -is [ZeroHub.GameItem]) {
                if ($btn.Name -eq "BtnBoostAndLaunch") {
                    Invoke-BoostAndLaunchGame $game $true
                } elseif ($btn.Name -eq "BtnQuickPlay") {
                    Invoke-BoostAndLaunchGame $game $false
                }
            }
        }
    }
)

