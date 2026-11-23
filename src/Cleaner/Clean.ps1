# Clean Cache Asynchronous Engine (Background Runspace + Thread-safe Queue)
# Offloads heavy recursive file deletions and disk I/O from the WPF UI thread to eliminate UI freezes,
# streaming live log entries, status updates, and auto-refreshing the Cleaner dashboard when finished.
$Script:CleanPs = $null
$Script:CleanHandle = $null
$Script:CleanTimer = $null
$Script:CleanQueue = $null

function Update-CleanProgress {
    $result = $null
    $doneObj = $null
    while ($Script:CleanQueue.TryDequeue([ref]$result)) {
        if (-not $result) { continue }
        if ($result.Type -eq "LOG") {
            Add-HubLog $result.Message $result.Level
        } elseif ($result.Type -eq "STATUS") {
            $StatusText.Text = $result.Text
        } elseif ($result.Type -eq "DONE") {
            $doneObj = $result
        }
    }

    if (-not $Script:CleanHandle -or -not $Script:CleanHandle.IsCompleted) { return }
    if ($Script:CleanQueue.Count -gt 0) { return }

    if ($Script:CleanTimer) { $Script:CleanTimer.Stop() }
    try { $Script:CleanPs.EndInvoke($Script:CleanHandle) | Out-Null } catch {
        Add-HubLog "Background cleanup reported an error: $($_.Exception.Message)" "ERROR"
    }
    try { $Script:CleanPs.Runspace.Close() } catch {}
    try { $Script:CleanPs.Dispose() } catch {}
    $Script:CleanPs = $null
    $Script:CleanHandle = $null

    # Play chime
    try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}

    Update-DriveInfo

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E

    $freedTotalMB      = if ($doneObj) { [double]$doneObj.FreedTotalMB } else { 0.0 }
    $totalFilesDeleted = if ($doneObj) { [int]$doneObj.TotalFilesDeleted } else { 0 }
    $totalFilesLocked  = if ($doneObj) { [int]$doneObj.TotalFilesLocked } else { 0 }
    $totalLockedBytes  = if ($doneObj) { [long]$doneObj.TotalLockedBytes } else { 0 }
    $cleanedItems      = if ($doneObj) { [int]$doneObj.CleanedItems } else { 0 }
    $elapsedSec        = if ($doneObj) { [double]$doneObj.ElapsedSec } else { 0.0 }
    $freedFormatted    = Format-SpaceMB $freedTotalMB

    if ($freedTotalMB -gt 0.05) {
        if ($totalFilesLocked -gt 0) {
            $lockedMB = [math]::Round(($totalLockedBytes / 1MB), 1)
            $summaryMsg = "Cleanup Finished! Deleted $totalFilesDeleted files and freed $freedFormatted ($totalFilesLocked file(s) totaling $(Format-SpaceMB $lockedMB) were locked by running apps)."
        } else {
            $summaryMsg = "Cleanup Complete! Deleted $totalFilesDeleted files and freed $freedFormatted across $cleanedItems target(s) in ${elapsedSec}s."
        }
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "DONE"
    } elseif ($totalFilesLocked -gt 0) {
        $lockedMB = [math]::Round(($totalLockedBytes / 1MB), 1)
        $summaryMsg = "Warning: 0 MB freed! Selected files ($(Format-SpaceMB $lockedMB) across $totalFilesLocked file(s)) are actively locked by running applications. Close open apps or reboot to finish cleaning."
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "WARN"
    } else {
        $summaryMsg = "Cleanup Complete in ${elapsedSec}s! Selected cache targets were already clean (0 MB)."
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "DONE"
    }

    # Pop up native Windows Toast Notification with sound
    Show-ZeroToastNotification "ZeroHub" $summaryMsg
    [ZeroHub.NativeMethods]::TrimSelfMemory()

    # Automatically trigger scan to refresh all sizes and cleaner badges upon completion
    Invoke-ScanSpace $false
}

# Execute Cache Deletion
function Invoke-ExecuteClean([bool]$dryRun = $false) {
    if ($Script:CleanPs) { return } # A clean operation is already running

    # Force-sync IsSelected from UI checkboxes and build selected list directly
    $work = [System.Collections.ArrayList]::new()
    foreach ($item in $Script:TargetItems) {
        $isChecked = $false
        if ($item.CheckBoxControl -and $item.CheckBoxControl.IsChecked -eq $true) {
            $isChecked = $true
        }
        if ($isChecked -or $item.IsSelected) {
            if (-not $item.IsSelected) { $item.IsSelected = $true }
            [void]$work.Add([pscustomobject]@{
                Id      = [string]$item.Id
                Name    = [string]$item.Name
                Path    = [string]$item.Path
                IsAdmin = [bool]$item.IsAdmin
                Guard   = @($item.Guard)
            })
        }
    }
    Add-HubLog "Selection sync complete: $($work.Count) of $($Script:TargetItems.Count) targets selected for cleaning." "DEBUG"
    if ($work.Count -eq 0) {
        $msg = "Please select at least one cache target to clean."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $confirmPrompt = "Are you sure you want to clean $($work.Count) selected cache target(s)?`n`nZeroHub will safely purge temporary cache files without touching your passwords or cookies."

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "Confirm Safe Cleanup",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Activity Log Tab to show real-time cleaning progress
    $MainTabs.SelectedItem = $Tab_Log

    $BtnScanAll.IsEnabled = $false
    $BtnCleanSelected.IsEnabled = $false
    $StatusIcon.Text = [char]0xE7E8
    $StatusText.Text = "Cleaning selected caches in background..."

    $autoClose = $ChkAutoCloseApps.IsChecked -eq $true
    if ($autoClose) {
        Add-HubLog "Auto-close enabled. Terminating guarded applications holding locks..." "ACTION"
        Stop-ActiveGuardedProcesses $true
    }

    $Script:CleanQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    # STA Runspace for safe Shell.Application COM interop (Recycle bin) and isolated background thread execution
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()

    $Script:CleanPs = [powershell]::Create()
    $Script:CleanPs.Runspace = $rs
    [void]$Script:CleanPs.AddScript({
        param($targets, $queue, [bool]$userIsAdmin, [bool]$autoCloseApps, $sizerText)

        function Send-Log([string]$msg, [string]$lvl = "INFO") {
            $queue.Enqueue([pscustomobject]@{ Type = "LOG"; Message = $msg; Level = $lvl })
        }
        function Send-Status([string]$txt) {
            $queue.Enqueue([pscustomobject]@{ Type = "STATUS"; Text = $txt })
        }
        function Format-MB([double]$mb) {
            if ($mb -ge 1024) { return ("{0:N2} GB" -f ($mb / 1024)) }
            return ("{0:N1} MB" -f $mb)
        }

        $sizer = [scriptblock]::Create($sizerText)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $freedTotalMB = 0.0
        $totalFilesDeleted = 0
        $totalFilesLocked = 0
        $totalLockedBytes = [long]0
        $cleanedItems = 0
        $skippedItems = 0

        # One process enumeration for guard checks across targets
        $runningProcesses = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) { [void]$runningProcesses.Add($p.ProcessName) }

        foreach ($t in $targets) {
            Send-Log "Processing target: $($t.Name)" "INFO"
            Send-Status "Cleaning $($t.Name)..."

            if ($t.IsAdmin -and -not $userIsAdmin) {
                Send-Log "Skipped $($t.Name): Requires Administrator privileges." "WARN"
                $skippedItems++
                continue
            }

            if ($t.Guard -and $t.Guard.Length -gt 0) {
                $isGuarded = $false
                foreach ($g in $t.Guard) {
                    if ($g -and $runningProcesses.Contains($g)) { $isGuarded = $true; break }
                }
                if ($isGuarded) {
                    if (-not $autoCloseApps) {
                        $guardNames = ($t.Guard | Where-Object { $_ }) -join ', '
                        Send-Log "Skipped $($t.Name): App ($guardNames) is running. Close it first or enable 'Auto-close apps'." "WARN"
                        $skippedItems++
                        continue
                    }
                }
            }

            if ($t.Id -eq "sys_recycle_bin") {
                try {
                    $beforeBin = 0.0
                    try { $beforeBin = [double](& $sizer "VIRTUAL:RECYCLEBIN") } catch { $beforeBin = 0.0 }
                    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
                    $afterBin = 0.0
                    try { $afterBin = [double](& $sizer "VIRTUAL:RECYCLEBIN") } catch { $afterBin = 0.0 }
                    $freedBin = [math]::Max(0, [math]::Round(($beforeBin - $afterBin), 2))
                    $freedTotalMB += $freedBin
                    if ($freedBin -gt 0) {
                        Send-Log "Emptied Windows Recycle Bin (freed $(Format-MB $freedBin))!" "SUCCESS"
                    } else {
                        Send-Log "Windows Recycle Bin is already empty." "SUCCESS"
                    }
                    $cleanedItems++
                } catch {
                    Send-Log "Error emptying Recycle Bin: $($_.Exception.Message)" "ERROR"
                }
                continue
            }

            if ($t.Id -eq "sys_dns_cache") {
                try {
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    ipconfig /flushdns 2>$null | Out-Null
                    Send-Log "Flushed Windows DNS Resolver Cache successfully!" "SUCCESS"
                    $cleanedItems++
                } catch {
                    Send-Log "Error flushing DNS cache: $($_.Exception.Message)" "ERROR"
                }
                continue
            }

            $targetDeletedBytes = [long]0
            $targetDeletedFiles = 0
            $targetLockedBytes  = [long]0
            $targetLockedFiles  = 0

            try {
                $dirsToClean = @()
                if ($t.Path.Contains("*")) {
                    $parent = Split-Path $t.Path -Parent
                    $leaf = Split-Path $t.Path -Leaf
                    if ([System.IO.Directory]::Exists($parent)) {
                        $dirsToClean = @([System.IO.Directory]::GetDirectories($parent, $leaf))
                    }
                } elseif ([System.IO.Directory]::Exists($t.Path)) {
                    $dirsToClean = @($t.Path)
                }

                if ($dirsToClean.Count -gt 0) {
                    foreach ($dir in $dirsToClean) {
                        # 1. Delete individual files safely
                        $allFiles = [ZeroHub.NativeMethods]::SafeListFiles($dir)
                        if ($allFiles -and $allFiles.Count -gt 0) {
                            $batchCounter = 0
                            foreach ($fPath in $allFiles) {
                                try {
                                    $len = [long]0
                                    try { $len = (New-Object System.IO.FileInfo $fPath).Length } catch {}
                                    [System.IO.File]::Delete($fPath)
                                    $targetDeletedBytes += $len
                                    $targetDeletedFiles++
                                    $batchCounter++
                                    if ($batchCounter % 100 -eq 0) {
                                        Send-Status "Cleaning $($t.Name)... ($targetDeletedFiles files)"
                                    }
                                } catch {
                                    $targetLockedFiles++
                                    try { $targetLockedBytes += (New-Object System.IO.FileInfo $fPath).Length } catch {}
                                    [ZeroHub.NativeMethods]::ScheduleDeleteOnReboot($fPath) | Out-Null
                                }
                            }
                        }
                        # 2. Remove empty subfolders
                        foreach ($dPath in [ZeroHub.NativeMethods]::SafeListDirs($dir)) {
                            try { [System.IO.Directory]::Delete($dPath, $false) } catch {}
                        }
                    }

                    $reclaimedMB = [math]::Round(($targetDeletedBytes / 1MB), 2)
                    $totalFilesDeleted += $targetDeletedFiles
                    $totalFilesLocked += $targetLockedFiles
                    $totalLockedBytes += $targetLockedBytes
                    $freedTotalMB += $reclaimedMB

                    if ($targetDeletedFiles -gt 0) {
                        if ($targetLockedFiles -gt 0) {
                            $lockedMB = [math]::Round(($targetLockedBytes / 1MB), 1)
                            if ($reclaimedMB -le 0.05) {
                                $warnMsg = "Warning: $($t.Name): Cleaned only $targetDeletedFiles file(s) ($($reclaimedMB) MB). $targetLockedFiles file(s) ($(Format-MB $lockedMB)) are locked & in-use by active running apps! (Scheduled for deletion on next reboot)."
                                Send-Log $warnMsg "WARN"
                            } else {
                                $cleanMsg = "Cleaned $targetDeletedFiles file(s) ($(Format-MB $reclaimedMB)) from $($t.Name)! ($targetLockedFiles file(s) locked; scheduled for deletion on next reboot)"
                                Send-Log $cleanMsg "SUCCESS"
                            }
                        } else {
                            $cleanMsg = "Cleaned $targetDeletedFiles file(s) ($(Format-MB $reclaimedMB)) from $($t.Name)!"
                            Send-Log $cleanMsg "SUCCESS"
                        }
                        $cleanedItems++
                    } elseif ($targetLockedFiles -gt 0) {
                        $lockedMB = [math]::Round(($targetLockedBytes / 1MB), 1)
                        $lockMsg = "Warning: $($t.Name): 0 MB deleted! $targetLockedFiles file(s) ($(Format-MB $lockedMB)) are actively locked and in-use by running apps. Close open programs or reboot to delete."
                        Send-Log $lockMsg "WARN"
                    } else {
                        Send-Log "Target $($t.Name) checked: 0 files needed cleaning (already clean)." "SUCCESS"
                        $cleanedItems++
                    }
                } else {
                    Send-Log "Target $($t.Name) path is not present or already empty." "INFO"
                }
            } catch {
                Send-Log "Error cleaning $($t.Name): $($_.Exception.Message)" "ERROR"
            }
    }

    $sw.Stop()
    $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

    $queue.Enqueue([pscustomobject]@{
        Type               = "DONE"
        FreedTotalMB       = $freedTotalMB
        TotalFilesDeleted  = $totalFilesDeleted
        TotalFilesLocked   = $totalFilesLocked
        TotalLockedBytes   = $totalLockedBytes
        CleanedItems       = $cleanedItems
        ElapsedSec         = $elapsedSec
    })
}).AddArgument($work).AddArgument($Script:CleanQueue).AddArgument($isAdmin).AddArgument($autoClose).AddArgument($Script:FolderSizerText)

    $Script:CleanHandle = $Script:CleanPs.BeginInvoke()

    $Script:CleanTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:CleanTimer.Interval = [TimeSpan]::FromMilliseconds(80)
    $Script:CleanTimer.add_Tick({ Update-CleanProgress })
    $Script:CleanTimer.Start()
}

