# ==========================================
# SMART PROCESS MANAGER MODULE
# ==========================================
$Script:AllSmartProcesses = [System.Collections.Generic.List[ZeroHub.SmartProcessItem]]::new()
$Script:CurrentProcFilter = "ALL"

function Update-SmartProcessList {
    if (-not $ProcManagerDataGrid) { return }
    
    try {
        $Script:AllSmartProcesses = [ZeroHub.ProcessManagerEngine]::GetAllProcesses()
    } catch {
        $Script:AllSmartProcesses = [System.Collections.Generic.List[ZeroHub.SmartProcessItem]]::new()
    }

    Filter-SmartProcessList
}

function Filter-SmartProcessList {
    if (-not $ProcManagerDataGrid) { return }
    $query = if ($TxtProcSearch -and $TxtProcSearch.Text) { $TxtProcSearch.Text } else { "" }
    $filter = $Script:CurrentProcFilter

    $totalCount = 0
    $safeCount = 0
    $safeMemMB = 0.0
    $filtered = [ZeroHub.ProcessManagerEngine]::FilterProcesses($Script:AllSmartProcesses, $query, $filter, [ref]$totalCount, [ref]$safeCount, [ref]$safeMemMB)

    $ProcManagerDataGrid.ItemsSource = $filtered

    if ($TxtProcStatsInfo) {
        $TxtProcStatsInfo.Text = "$totalCount Running • $safeCount Safe to Stop ($([Math]::Round($safeMemMB, 1)) MB RAM)"
    }
    if ($TxtProcSafeReclaimable) {
        $TxtProcSafeReclaimable.Text = "Safe RAM to reclaim: $([Math]::Round($safeMemMB, 1)) MB"
    }
}

function Set-ProcFilterStyle($activeBtn) {
    $defaultBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
    $activeBg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
    $activeFg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    $fgMap = @{
        $BtnFilterProcAll       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8");
        $BtnFilterProcSafe      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80");
        $BtnFilterProcWork      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24");
        $BtnFilterProcService   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C084FC");
        $BtnFilterProcHeavy     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8");
        $BtnFilterProcProtected = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171");
    }

    $buttons = @($BtnFilterProcAll, $BtnFilterProcSafe, $BtnFilterProcWork, $BtnFilterProcService, $BtnFilterProcHeavy, $BtnFilterProcProtected)
    foreach ($btn in $buttons) {
        if ($btn) {
            if ($btn -eq $activeBtn) {
                $btn.Background = $activeBg
                $btn.Foreground = $activeFg
                $btn.FontWeight = [System.Windows.FontWeights]::Bold
            } else {
                $btn.Background = $defaultBg
                $btn.Foreground = if ($fgMap.ContainsKey($btn)) { $fgMap[$btn] } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8") }
                $btn.FontWeight = [System.Windows.FontWeights]::SemiBold
            }
        }
    }
}

function Invoke-PurgeAllSafeProcesses {
    if (-not $Script:AllSmartProcesses) { return }
    $safeProcs = $Script:AllSmartProcesses | Where-Object { $_.SafetyTier -eq "Safe" -and $_.CanEnd }
    if (-not $safeProcs -or $safeProcs.Count -eq 0) {
        Show-ZeroToastNotification "Task Manager" "No safe background tasks found to purge."
        return
    }

    if ($BtnPurgeSafeProcs) {
        $BtnPurgeSafeProcs.IsEnabled = $false
        $BtnPurgeSafeProcs.Content = "⏳ Purging..."
    }

    $killed = 0
    $freedMB = 0.0
    foreach ($p in $safeProcs) {
        $ok = [ZeroHub.ProcessManagerEngine]::KillProcess($p.Id)
        if ($ok) {
            $killed++
            $freedMB += $p.MemoryMB
        }
    }

    Add-HubLog "Task Manager: Purged $killed safe background tasks, reclaimed $([Math]::Round($freedMB, 1)) MB RAM" "SUCCESS"
    Show-ZeroToastNotification "Process Purged" "Closed $killed background tasks, reclaimed $([Math]::Round($freedMB, 1)) MB RAM!"

    if ($BtnPurgeSafeProcs) {
        $BtnPurgeSafeProcs.IsEnabled = $true
        $BtnPurgeSafeProcs.Content = "🧹 Purge Safe Background Tasks"
    }

    Start-Sleep -Milliseconds 150
    Update-SmartProcessList
    Update-LiveMemoryStats
}

function Invoke-EndSelectedProcess([ZeroHub.SmartProcessItem]$selected) {
    if (-not $selected) { return }
    if (-not $selected.CanEnd -or $selected.SafetyTier -eq "Critical") {
        Show-ZeroToastNotification "Process Protected" "$($selected.Name) is a critical Windows system process and cannot be terminated."
        return
    }

    if ($selected.SafetyTier -eq "Caution" -or $selected.SafetyTier -eq "CautionWork") {
        $msg = "Closing '$($selected.Name)' may cause unsaved work to be lost. Are you sure you want to end this task?"
        $res = [System.Windows.MessageBox]::Show($msg, "End Task Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
    } elseif ($selected.SafetyTier -eq "CautionService") {
        $msg = "'$($selected.Name)' is a background Windows service. Ending it may affect related background tasks until restarted. Are you sure you want to end it?"
        $res = [System.Windows.MessageBox]::Show($msg, "End Service Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    # Instantly drop the process from local collection so the UI row vanishes immediately
    if ($Script:AllSmartProcesses) {
        $targetId = $selected.Id
        $Script:AllSmartProcesses.RemoveAll([Predicate[ZeroHub.SmartProcessItem]]{ param($item) $item.Id -eq $targetId }) | Out-Null
        Filter-SmartProcessList
    }

    $ok = [ZeroHub.ProcessManagerEngine]::KillProcess($selected.Id)
    if ($ok) {
        Add-HubLog "Task Manager: Terminated $($selected.Name) (PID: $($selected.Id))" "SUCCESS"
        Show-ZeroToastNotification "Process Terminated" "Successfully closed $($selected.Name)."
        Start-Sleep -Milliseconds 150
        Update-SmartProcessList
        Update-LiveMemoryStats
    } else {
        Add-HubLog "Task Manager: Failed to terminate $($selected.Name) (PID: $($selected.Id))" "WARN"
        Update-SmartProcessList
    }
}

# Process Guard Monitor Refresh
function Update-ProcessGuardList() {
    $activeGuards = [System.Collections.ArrayList]::new()
    $runningProcesses = Get-Process -ErrorAction SilentlyContinue

    foreach ($t in $Script:TargetItems) {
        if ($t.Guard.Length -gt 0) {
            foreach ($g in $t.Guard) {
                $matching = $runningProcesses | Where-Object { $_.ProcessName -ieq $g }
                foreach ($p in $matching) {
                    $pItem = [ZeroHub.ProcessItem]::new()
                    $pItem.Name = $p.ProcessName
                    $pItem.Id = $p.Id
                    $pItem.TargetName = $t.Name
                    $pItem.Status = "In Use (Blocking Clean)"
                    $pItem.MainWindowTitle = if ($p.MainWindowTitle) { $p.MainWindowTitle } else { "(Background Process)" }
                    $activeGuards.Add($pItem) | Out-Null
                }
            }
        }
    }

    $ProcessDataGrid.ItemsSource = $activeGuards
    Add-HubLog "Process Guard checked: $($activeGuards.Count) active processes detected." "GUARD"
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

# Close Guarded Processes
function Stop-ActiveGuardedProcesses([bool]$onlySelected = $false) {
    if ($BtnCloseAllGuards) {
        $BtnCloseAllGuards.IsEnabled = $false
        $BtnCloseAllGuards.Content = "⏳ Closing..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Closing active guarded applications holding file locks..."
    [System.Windows.Forms.Application]::DoEvents()

    $closedCount = 0
    $seenPids = [System.Collections.Generic.HashSet[int]]::new()
    
    # 1. Directly terminate all PIDs currently shown in the Process Guard grid if not $onlySelected
    if (-not $onlySelected -and $ProcessDataGrid -and $ProcessDataGrid.ItemsSource) {
        foreach ($item in $ProcessDataGrid.ItemsSource) {
            if ($item.Id -and $seenPids.Add([int]$item.Id)) {
                $pidToKill = [int]$item.Id
                try {
                    Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
                    $closedCount++
                    Add-HubLog "Closed guarded process: $($item.Name) (PID: $pidToKill)" "PROCESS"
                } catch {
                    try {
                        Start-Process -FilePath "taskkill.exe" -ArgumentList "/F /PID $pidToKill /T" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                        $closedCount++
                    } catch {}
                }
            }
        }
    }

    # 2. Collect all guard process names across targets
    $guardNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $Script:TargetItems) {
        if ((-not $onlySelected -or $t.IsSelected) -and $t.Guard -and $t.Guard.Length -gt 0) {
            foreach ($g in $t.Guard) {
                if ($g) { [void]$guardNames.Add($g) }
            }
        }
    }

    $runningProcesses = Get-Process -ErrorAction SilentlyContinue
    foreach ($p in $runningProcesses) {
        if ($guardNames.Contains($p.ProcessName) -and $seenPids.Add($p.Id)) {
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                Add-HubLog "Closed guarded process: $($p.ProcessName) (PID: $($p.Id))" "PROCESS"
                $closedCount++
            } catch {
                try {
                    Start-Process -FilePath "taskkill.exe" -ArgumentList "/F /PID $($p.Id) /T" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                    $closedCount++
                } catch {}
            }
        }
    }

    Start-Sleep -Milliseconds 500
    Update-ProcessGuardList

    $msg = "Successfully closed $closedCount guarded application process(es)."
    $StatusIcon.Text = [char]0xE73E
    $StatusText.Text = $msg
    Add-HubLog $msg "SUCCESS"
    Show-ZeroToastNotification "ZeroHub Process Guard" $msg

    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($BtnCloseAllGuards) {
        $BtnCloseAllGuards.Content = "✅ Closed $closedCount Apps!"
        $timer = [System.Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [TimeSpan]::FromSeconds(3)
        $timer.add_Tick({
            param($s, $e)
            $s.Stop()
            if ($BtnCloseAllGuards) {
                $BtnCloseAllGuards.IsEnabled = $true
                $BtnCloseAllGuards.Content = "Close All Guarded Apps"
            }
        })
        $timer.Start()
    }

    return $closedCount
}

