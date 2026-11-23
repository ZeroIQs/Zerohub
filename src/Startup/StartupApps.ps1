# ==========================================
# STARTUP APPLICATIONS ENGINE
# ==========================================
$Script:AllStartupApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.StartupAppItem]]::new()
$Script:FilteredStartupApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.StartupAppItem]]::new()

$StartupAppsDataGrid.ItemsSource = $Script:FilteredStartupApps

function Update-StartupSearchFilter {
    $q = if ($TxtStartupSearch -and $TxtStartupSearch.Text) { $TxtStartupSearch.Text.Trim().ToLower() } else { "" }
    
    $Script:FilteredStartupApps.Clear()
    foreach ($app in $Script:AllStartupApps) {
        if ([string]::IsNullOrWhiteSpace($q) -or 
            ($app.Name -and $app.Name.ToLower().Contains($q)) -or 
            ($app.Publisher -and $app.Publisher.ToLower().Contains($q)) -or
            ($app.Command -and $app.Command.ToLower().Contains($q)) -or
            ($app.SourceType -and $app.SourceType.ToLower().Contains($q))) {
            $Script:FilteredStartupApps.Add($app)
        }
    }

    if ($TxtStartupCountInfo) {
        $runCount = @($Script:AllStartupApps | Where-Object { $_.IsRunning }).Count
        $totCount = $Script:AllStartupApps.Count
        $TxtStartupCountInfo.Text = "$runCount Running Now • $totCount Total Startup Apps"
    }
}

if ($TxtStartupSearch) {
    $TxtStartupSearch.add_TextChanged({ Update-StartupSearchFilter })
}

function Set-StartupAppStatus([ZeroHub.StartupAppItem]$app, [bool]$enabled) {
    try {
        if ($app.RegistryPath -and $app.ApprovedPath) {
            if (-not (Test-Path $app.ApprovedPath)) {
                New-Item -Path $app.ApprovedPath -Force | Out-Null
            }
            $byteVal = if ($enabled) { 0x02 } else { 0x03 }
            $bytes = [byte[]]@($byteVal, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            Set-ItemProperty -Path $app.ApprovedPath -Name $app.Name -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue
            Add-HubLog "Configured startup app '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        } elseif ($app.FilePath) {
            $dir = [System.IO.Path]::GetDirectoryName($app.FilePath)
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($app.FilePath)
            if ($enabled) {
                if ($app.FilePath.EndsWith(".disabled")) {
                    $newPath = Join-Path $dir "$baseName.lnk"
                    Rename-Item -Path $app.FilePath -NewName "$baseName.lnk" -Force -ErrorAction SilentlyContinue
                    $app.FilePath = $newPath
                }
            } else {
                if ($app.FilePath.EndsWith(".lnk")) {
                    $newPath = Join-Path $dir "$baseName.disabled"
                    Rename-Item -Path $app.FilePath -NewName "$baseName.disabled" -Force -ErrorAction SilentlyContinue
                    $app.FilePath = $newPath
                }
            }
            Add-HubLog "Configured startup shortcut '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        } elseif ($app.TaskName) {
            if ($enabled) {
                Enable-ScheduledTask -TaskName $app.TaskName -ErrorAction SilentlyContinue | Out-Null
            } else {
                Disable-ScheduledTask -TaskName $app.TaskName -ErrorAction SilentlyContinue | Out-Null
            }
            Add-HubLog "Configured startup task '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        }
    } catch {
        Add-HubLog "Error setting startup state for $($app.Name): $($_.Exception.Message)" "ERROR"
    }
}

function Get-StartupAppImpact([string]$name, [string]$cmd) {
    $highImpact = @("Discord", "Steam", "Spotify", "EpicGamesLauncher", "RiotClient", "CurseForge", "Battle.net", "Adobe", "Teams", "Zoom", "Chrome", "Brave")
    $mediumImpact = @("OneDrive", "Dropbox", "Slack", "Telegram", "Viber", "Skype", "iCUE", "Razer", "Logitech", "SteelSeries")
    
    foreach ($h in $highImpact) {
        if (($name -like "*$h*") -or ($cmd -like "*$h*")) { return @{ Impact = "⚡ High"; Color = "#F43F5E" } }
    }
    foreach ($m in $mediumImpact) {
        if (($name -like "*$m*") -or ($cmd -like "*$m*")) { return @{ Impact = "⚠️ Medium"; Color = "#FBBF24" } }
    }
    return @{ Impact = "● Low"; Color = "#4ADE80" }
}

function Update-StartupAppsList {
    try {
        $Script:AllStartupApps.Clear()
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $rawList = [System.Collections.Generic.List[ZeroHub.StartupAppItem]]::new()

        # Fast .NET process enumeration (0ms)
        $runningProcs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($p in [System.Diagnostics.Process]::GetProcesses()) {
            if ($p.ProcessName) { [void]$runningProcs.Add($p.ProcessName) }
        }

        # 1. Registry Hives (User, System, 32-bit Wow6432Node)
        $regLocations = @(
            @{ Hive = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; Source = "Registry (User)" },
            @{ Hive = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; Source = "Registry (System)" },
            @{ Hive = "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"; Source = "Registry 32-bit (User)" },
            @{ Hive = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"; Source = "Registry 32-bit (System)" }
        )

        foreach ($loc in $regLocations) {
            if (Test-Path $loc.Hive) {
                $props = (Get-Item -Path $loc.Hive).Property
                foreach ($p in $props) {
                    if ($seen.Add("REG_$p")) {
                        $cmd = (Get-ItemProperty -Path $loc.Hive -Name $p -ErrorAction SilentlyContinue).$p
                        $isEnabled = $true
                        if (Test-Path $loc.Appr) {
                            $bin = (Get-ItemProperty -Path $loc.Appr -Name $p -ErrorAction SilentlyContinue).$p
                            if ($null -ne $bin -and $bin.Length -gt 0) {
                                if ($bin[0] -eq 3 -or $bin[0] -eq 1) { $isEnabled = $false }
                            }
                        }

                        $exeName = ""
                        if ($cmd -match '([^\\]+?)\.exe') { $exeName = $Matches[1] }
                        elseif ($p) { $exeName = $p }
                        $isRunning = ($exeName -and $runningProcs.Contains($exeName)) -or ($p -and $runningProcs.Contains($p))

                        $imp = Get-StartupAppImpact $p $cmd
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $p
                        $item.Command = [string]$cmd
                        $item.SourceType = $loc.Source
                        $item.RegistryPath = $loc.Hive
                        $item.ApprovedPath = $loc.Appr
                        $item.Publisher = if ($loc.Source.Contains("User")) { "User Application" } else { "System Software" }
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 2. StartupApproved registered apps
        foreach ($loc in $regLocations) {
            if (Test-Path $loc.Appr) {
                $apprProps = (Get-Item -Path $loc.Appr).Property
                foreach ($p in $apprProps) {
                    if ($seen.Add("REG_$p")) {
                        $bin = (Get-ItemProperty -Path $loc.Appr -Name $p -ErrorAction SilentlyContinue).$p
                        $isEnabled = ($null -eq $bin -or $bin.Length -eq 0 -or ($bin[0] -ne 3 -and $bin[0] -ne 1))
                        $isRunning = ($p -and $runningProcs.Contains($p))
                        $imp = Get-StartupAppImpact $p ""
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $p
                        $item.Command = "StartupApproved Registration ($p)"
                        $item.SourceType = $loc.Source
                        $item.RegistryPath = $loc.Hive
                        $item.ApprovedPath = $loc.Appr
                        $item.Publisher = "Registered Application"
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 3. User & Common Startup Folders
        $folders = @(
            @{ Path = [Environment]::GetFolderPath("Startup"); Source = "Startup Folder (User)" },
            @{ Path = [Environment]::GetFolderPath("CommonStartup"); Source = "Startup Folder (All Users)" }
        )
        foreach ($fld in $folders) {
            if (Test-Path $fld.Path) {
                $files = Get-ChildItem -Path $fld.Path -File -ErrorAction SilentlyContinue
                foreach ($f in $files) {
                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
                    if ($seen.Add("FLD_$baseName")) {
                        $isEnabled = (-not $f.Name.EndsWith(".disabled"))
                        $isRunning = ($runningProcs.Contains($baseName))
                        $imp = Get-StartupAppImpact $baseName $f.FullName
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $baseName
                        $item.Command = $f.FullName
                        $item.FilePath = $f.FullName
                        $item.SourceType = $fld.Source
                        $item.Publisher = "Startup Shortcut"
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 4. User Startup Scheduled Tasks (Ultra-fast COM API, 0ms latency)
        try {
            $sched = New-Object -ComObject "Schedule.Service"
            $sched.Connect()
            $rootFolder = $sched.GetFolder("\")
            $tasks = $rootFolder.GetTasks(0)
            foreach ($t in $tasks) {
                if (-not $t.Enabled) { continue }
                $defn = $t.Definition
                $actions = $defn.Actions
                $execPath = $null
                foreach ($act in $actions) {
                    if ($act.Type -eq 0 -and $act.Path) { # 0 = TASK_ACTION_EXEC
                        $execPath = $act.Path
                        break
                    }
                }
                if (-not $execPath) { continue }
                $taskName = $t.Name
                $cleanTaskName = $taskName
                if ($cleanTaskName.Length -gt 35) { $cleanTaskName = $cleanTaskName.Substring(0, 32) + "..." }
                if ($seen.Add("TSK_$taskName")) {
                    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($execPath)
                    $isRunning = ($exeName -and $runningProcs.Contains($exeName))
                    $imp = Get-StartupAppImpact $cleanTaskName $execPath
                    $item = [ZeroHub.StartupAppItem]::new()
                    $item.Name = $cleanTaskName
                    $item.Command = [string]$execPath
                    $item.SourceType = "Scheduled Task"
                    $item.TaskName = $taskName
                    $item.Publisher = "Task Trigger"
                    $item.Impact = $imp.Impact
                    $item.ImpactColor = $imp.Color
                    $item.IsEnabled = [bool]$t.Enabled
                    $item.IsRunning = $isRunning

                    $item.add_PropertyChanged({
                        param($s, $e)
                        if ($e.PropertyName -eq "IsEnabled") {
                            Set-StartupAppStatus $s $s.IsEnabled
                        }
                    })
                    $rawList.Add($item)
                }
            }
        } catch {}

        # Separation sort: 1st Running Apps (at the top), then Startup Impact / Alphabetical
        $sorted = $rawList | Sort-Object @{ Expression = { if ($_.IsRunning) { 0 } else { 1 } } }, @{ Expression = { if ($_.Impact -like "*High*") { 0 } elseif ($_.Impact -like "*Med*") { 1 } else { 2 } } }, Name
        foreach ($app in $sorted) {
            $Script:AllStartupApps.Add($app)
        }

        Update-StartupSearchFilter
    } catch {
        Add-HubLog "Error updating startup apps list: $($_.Exception.Message)" "ERROR"
    }
}

function Optimize-StartupBoot {
    try {
        $disabledCount = 0
        foreach ($app in $Script:AllStartupApps) {
            if ($app.IsEnabled -and ($app.Impact -like "*High*" -or $app.Impact -like "*Med*")) {
                $app.IsEnabled = $false
                $disabledCount++
            }
        }
        $msg = "Fast Boot Optimization complete! Disabled $disabledCount heavy startup apps."
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub - Boot Optimizer" $msg
    } catch {
        Add-HubLog "Error running fast boot optimization: $($_.Exception.Message)" "ERROR"
    }
}

if ($BtnRefreshStartup) {
    $BtnRefreshStartup.add_Click({
        Update-StartupAppsList
    })
}
if ($BtnOptimizeStartup) {
    $BtnOptimizeStartup.add_Click({
        Optimize-StartupBoot
    })
}

