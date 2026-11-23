# Bulk / Single Uninstall & Leftover Clean Action
$BtnUninstallSelected.add_Click({
    try {
        $targetList = @($Script:AllInstalledApps | Where-Object { $_.IsSelected })
        if ($targetList.Count -eq 0 -and $AppsGrid.SelectedItem) {
            $targetList = @($AppsGrid.SelectedItem)
        }
        if ($targetList.Count -eq 0) { return }

        $totalMB = ($targetList | Measure-Object EstimatedSizeMB -Sum).Sum
        $totalSizeStr = Format-SpaceMB $totalMB

        # Bulk Confirmation Prompt
        $confirmMsg = if ($targetList.Count -eq 1) {
            "Are you sure you want to uninstall '$($targetList[0].DisplayName)' ($($targetList[0].SizeFormatted)) and clean all residual leftover files?"
        } else {
            "Are you sure you want to bulk uninstall ($($targetList.Count)) selected applications (Total: $totalSizeStr) and clean all residual leftovers?"
        }
        $confirmTitle = "ZeroHub - Bulk Uninstall Confirm"
        $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $successCount = 0
        $totalFreedBytes = 0
        $currentIdx = 0

        foreach ($targetApp in $targetList) {
            $currentIdx++

            # Handle Windows UWP / Bloatware package uninstallation
            if ($targetApp.IsAppx -and $targetApp.PackageFullName) {
                $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Removing Windows App: $($targetApp.DisplayName)..."
                $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                [System.Windows.Forms.Application]::DoEvents()

                try {
                    Remove-AppxPackage -Package $targetApp.PackageFullName -ErrorAction SilentlyContinue
                    if ($isAdmin) {
                        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { 
                            $_.DisplayName -like "*$($targetApp.DisplayName)*" -or $_.PackageName -eq $targetApp.PackageFullName 
                        } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                    }
                    Add-HubLog "Successfully uninstalled UWP / Bloatware package: $($targetApp.DisplayName)" "SUCCESS"
                } catch {
                    Add-HubLog "Error removing UWP package $($targetApp.DisplayName): $($_.Exception.Message)" "ERROR"
                }

                $successCount++
                continue
            }

            $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Running official uninstaller for $($targetApp.DisplayName)... (Please complete the uninstaller wizard on your screen)"
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            [System.Windows.Forms.Application]::DoEvents()

            # 1. Execute Uninstaller and Wait for It to Completely Finish (Revo Style)
            $uninstStr = $targetApp.UninstallString
            $proc = $null
            if (-not [string]::IsNullOrWhiteSpace($uninstStr)) {
                $uninstStr = $uninstStr.Trim()
                Add-HubLog "Executing uninstaller for $($targetApp.DisplayName): $uninstStr" "UNINSTALL"

                if ($uninstStr -like "*steam://*") {
                    if ($uninstStr -match '(steam://uninstall/\d+)') {
                        $steamUrl = $matches[1]
                        [System.Diagnostics.Process]::Start($steamUrl) | Out-Null
                        Start-Sleep -Seconds 5
                    }
                } elseif ($uninstStr -match 'msiexec(\.exe)?\s*(/i|/x|/I|/X)\s*(\{[^}]+\})') {
                    $guid = $matches[3]
                    $psi = [System.Diagnostics.ProcessStartInfo]::new()
                    $psi.FileName = "msiexec.exe"
                    $psi.Arguments = "/x $guid"
                    $psi.UseShellExecute = $true
                    $proc = [System.Diagnostics.Process]::Start($psi)
                } else {
                    $exe = ""
                    $uninstArgs = ""
                    if ($uninstStr -match '^"([^"]+\.exe)"\s*(.*)$') {
                        $exe = $matches[1]
                        $uninstArgs = $matches[2].Trim()
                    } elseif ($uninstStr -match '^([a-zA-Z]:\\.+?\.exe)(\s+(.*))?$') {
                        $exe = $matches[1]
                        $uninstArgs = if ($matches[3]) { $matches[3].Trim() } else { "" }
                    } else {
                        $exe = $uninstStr
                        $uninstArgs = ""
                    }

                    if ($exe -and (Test-Path $exe)) {
                        $psi = [System.Diagnostics.ProcessStartInfo]::new()
                        $psi.FileName = $exe
                        $psi.Arguments = $uninstArgs
                        $psi.UseShellExecute = $true
                        $proc = [System.Diagnostics.Process]::Start($psi)
                    }
                }
            }

            # Wait loop: monitor main process and child uninstaller processes until fully exited
            $maxWaitSec = 600
            $elapsed = 0
            Start-Sleep -Milliseconds 1200
            [System.Windows.Forms.Application]::DoEvents()

            while ($elapsed -lt $maxWaitSec) {
                [System.Windows.Forms.Application]::DoEvents()
                $stillRunning = $false

                if ($proc -and -not $proc.HasExited) {
                    $stillRunning = $true
                }

                # Check if uninstaller child processes are still running in target install directory
                if ($targetApp.InstallLocation -and [System.IO.Directory]::Exists($targetApp.InstallLocation)) {
                    $activeProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                        try {
                            $pPath = $_.MainModule.FileName
                            $pPath -and $pPath.StartsWith($targetApp.InstallLocation, [StringComparison]::OrdinalIgnoreCase)
                        } catch { $false }
                    }
                    if ($activeProcs -and $activeProcs.Count -gt 0) {
                        $stillRunning = $true
                    }
                }

                if (-not $stillRunning) {
                    Start-Sleep -Milliseconds 1200
                    break
                }

                Start-Sleep -Milliseconds 350
                $elapsed += 0.35
            }

            # 2. Scanning & Cleaning Residual Leftovers (Only after uninstaller exits!)
            $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Uninstallation finished! Scanning and cleaning leftovers for $($targetApp.DisplayName)..."
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
            [System.Windows.Forms.Application]::DoEvents()

            # 2. Leftovers Hunt & Clean (With Strict Shared Folder Protection)
            $protectedRoots = @(
                "C:\", "D:\", "E:\", "F:\",
                "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData",
                "C:\Riot Games", "C:\Epic Games", "C:\Games",
                $env:LOCALAPPDATA, $env:APPDATA, $env:USERPROFILE
            )

            $blockedWords = @(
                "riot", "games", "game", "epic", "steam", "microsoft", "google", "adobe",
                "intel", "nvidia", "amd", "windows", "setup", "client", "launcher", "common",
                "shared", "team", "data", "bin", "temp", "program", "files"
            )

            # Folders that are never an app leftover no matter what the display name matches.
            $personalFolders = @(
                "documents", "desktop", "downloads", "pictures", "videos", "music", "favorites",
                "links", "saved games", "contacts", "searches", "onedrive", "appdata", "local",
                "locallow", "roaming", "public", "default", "startmenu", "start menu"
            )

            $cleanName = ($targetApp.DisplayName -replace '\s*\d+(\.\d+)*(\s*\(x\d+\))?.*$', '').Trim()

            # $blockedWords used to be compared against the WHOLE display name with -contains, so it
            # only ever fired on a single-word name: "Steam" was blocked, "Steam Client Bootstrapper"
            # went straight through and matched every directory containing "steam". The list read
            # like a strong safety net and was very nearly a no-op. Filter word by word instead.
            $words = @($cleanName -split '[^\w\+\#\.]+' | Where-Object { $_ })
            $meaningful = @($words | Where-Object { $blockedWords -notcontains $_.ToLower() })
            $tokens = @()
            if ($meaningful.Count -gt 0) {
                $candidate = ($meaningful -join ' ').Trim()
                if ($candidate.Length -ge 4) { $tokens = @($candidate) }
            }
            if ($tokens.Count -eq 0 -and $cleanName) {
                Add-HubLog "Leftover scan skipped for '$($targetApp.DisplayName)': name is too generic to match safely." "INFO"
            }

            $roots = @($env:LOCALAPPDATA, $env:APPDATA, $env:ProgramData)
            $leftoverDirs = @()

            # Safety check function
            $IsSafeToDelete = {
                param($pathToCheck)
                if (-not $pathToCheck -or -not (Test-Path $pathToCheck)) { return $false }
                $norm = $pathToCheck.TrimEnd('\').ToLower()

                # Reparse points (junctions, symlinks) are never followed. On Windows PowerShell 5.1
                # Remove-Item -Recurse on a junction deletes the contents of the TARGET, so a stray
                # junction inside an app folder could take out an unrelated directory tree.
                try {
                    $fsItem = Get-Item -LiteralPath $pathToCheck -Force -ErrorAction Stop
                    if ($fsItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { return $false }
                } catch { return $false }

                # Exact match on a protected root, AND any ancestor of one. The old check was
                # equality only, so it refused to delete C:\Program Files but was happy to take
                # C:\Program Files\Common Files, or anything under the user profile.
                foreach ($pr in $protectedRoots) {
                    if (-not $pr) { continue }
                    $p = $pr.TrimEnd('\').ToLower()
                    if ($norm -eq $p) { return $false }
                    if ($p.StartsWith($norm + "\")) { return $false }
                }

                # Never touch the well-known personal folders, whatever the app is called.
                $leaf = Split-Path $norm -Leaf
                if ($personalFolders -contains $leaf) { return $false }
                $userRoot = $env:USERPROFILE.TrimEnd('\').ToLower()
                if ($norm.StartsWith($userRoot + "\")) {
                    $rel = $norm.Substring($userRoot.Length + 1)
                    $firstSeg = ($rel -split '\\')[0]
                    if ($personalFolders -contains $firstSeg) { return $false }
                }

                # NEVER delete if another installed app shares this exact path or is a parent/child of another app
                foreach ($app in $Script:AllInstalledApps) {
                    if ($app.DisplayName -ne $targetApp.DisplayName -and $app.InstallLocation) {
                        $appLoc = $app.InstallLocation.TrimEnd('\').ToLower()
                        if ($norm -eq $appLoc -or $appLoc.StartsWith($norm + "\") -or $norm.StartsWith($appLoc + "\")) {
                            return $false
                        }
                    }
                }
                return $true
            }

            # Sizes are collected per candidate and only counted as freed AFTER the user approves the
            # list, so declining does not inflate the "freed" total in the summary.
            $candidateSizes = @{}

            # Check InstallLocation safely
            if ($targetApp.InstallLocation -and (Test-Path $targetApp.InstallLocation)) {
                if (& $IsSafeToDelete $targetApp.InstallLocation) {
                    $files = Get-ChildItem $targetApp.InstallLocation -Recurse -Force -File -ErrorAction SilentlyContinue
                    $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                    $candidateSizes[$targetApp.InstallLocation] = $sz
                    $leftoverDirs += $targetApp.InstallLocation
                } else {
                    Add-HubLog "Protected shared directory from deletion: $($targetApp.InstallLocation)" "INFO"
                }
            }

            # Check AppData / ProgramData safely
            foreach ($r in $roots) {
                if (-not (Test-Path $r)) { continue }
                foreach ($tok in $tokens) {
                    $dirMatches = Get-ChildItem -Path $r -Directory -Filter "*$tok*" -ErrorAction SilentlyContinue
                    foreach ($m in $dirMatches) {
                        if (& $IsSafeToDelete $m.FullName) {
                            $files = Get-ChildItem $m.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
                            $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                            $candidateSizes[$m.FullName] = $sz
                            $leftoverDirs += $m.FullName
                        }
                    }
                }
            }

            $leftoverDirs = @($leftoverDirs | Select-Object -Unique)

            # The matcher is a substring wildcard over three roots, so it can and does pull in
            # directories belonging to a different app whose name contains this one. Deleting those
            # recursively, as admin, with nothing shown to the user was the single most destructive
            # thing in this script: the old confirmation said "clean all residual leftovers" and
            # never named a path, and paths were logged only after they were already gone. Show the
            # exact list, default to No, and log each path before touching it.
            if ($leftoverDirs.Count -gt 0) {
                $listedBytes = ($leftoverDirs | ForEach-Object { [int64]$candidateSizes[$_] } | Measure-Object -Sum).Sum
                $listedStr = Format-SpaceMB ([math]::Round($listedBytes / 1MB, 2))
                $shown = $leftoverDirs | Select-Object -First 15
                $listText = ($shown | ForEach-Object { "    $_  ($(Format-SpaceMB ([math]::Round([int64]$candidateSizes[$_] / 1MB, 2))))" }) -join "`n"
                if ($leftoverDirs.Count -gt 15) { $listText += "`n    ... and $($leftoverDirs.Count - 15) more" }

                $leftoverPrompt = "Found $($leftoverDirs.Count) leftover folder(s) for '$($targetApp.DisplayName)', $listedStr total.`n`nThese will be permanently deleted:`n$listText`n`nRead the list before answering. Delete them?"
                $leftoverTitle = "ZeroHub - Confirm Leftover Deletion"

                foreach ($ld in $leftoverDirs) { Add-HubLog "Leftover candidate for $($targetApp.DisplayName): $ld" "SCAN" }

                $leftoverConfirm = [System.Windows.MessageBox]::Show(
                    $leftoverPrompt, $leftoverTitle,
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning,
                    [System.Windows.MessageBoxResult]::No)

                if ($leftoverConfirm -eq [System.Windows.MessageBoxResult]::Yes) {
                    foreach ($ld in $leftoverDirs) {
                        Add-HubLog "Deleting leftover directory: $ld" "CLEAN"
                        try {
                            Remove-Item -LiteralPath $ld -Recurse -Force -Confirm:$false -ErrorAction Stop
                            $totalFreedBytes += [int64]$candidateSizes[$ld]
                        } catch {
                            Add-HubLog "Locked, scheduled for deletion on next reboot: $ld" "WARN"
                            [ZeroHub.NativeMethods]::ScheduleDeleteOnReboot($ld) | Out-Null
                        }
                    }
                } else {
                    Add-HubLog "Leftover deletion declined by user for $($targetApp.DisplayName). Nothing was removed." "INFO"
                }
            }

            # 3. Clean ghost registry entry
            if ($targetApp.RegistryPath -and (Test-Path $targetApp.RegistryPath)) {
                try {
                    Remove-Item -Path $targetApp.RegistryPath -Force -Recurse -ErrorAction SilentlyContinue
                } catch {}
            }

            $successCount++
        }

        $freedFinalMB = [math]::Round(($totalFreedBytes / 1MB), 2)
        $freedFinalStr = Format-SpaceMB $freedFinalMB

        $TxtSelectedAppStatus.Text = "Bulk cleanup completed! Uninstalled $successCount apps and freed $freedFinalStr of leftovers."
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        Add-HubLog "Bulk Uninstalled $successCount app(s) and freed $freedFinalStr of leftovers!" "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Bulk Uninstaller" "Successfully uninstalled $successCount apps and cleaned $freedFinalStr of leftovers!"

        # Refresh tables
        Update-InstalledAppsList
        Initialize-InstallerCatalogList
    } catch {
        Add-HubLog "Error during bulk uninstaller: $($_.Exception.Message)" "ERROR"
    }
})

if ($BtnDeepUninstall) {
    $BtnDeepUninstall.add_Click({
        $MainTabs.SelectedItem = $Tab_Uninstaller
        if ($Script:AllInstalledApps.Count -eq 0) {
            Update-InstalledAppsList
        }
    })
}

