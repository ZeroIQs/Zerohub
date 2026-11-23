# Refresh / Scan Function
# Shimmer: a pending row pulses its size label instead of sitting on a stale number. Cheap enough to
# run on 68 rows because it is a single animated DP per label, composited off the UI thread by WPF.
$Script:ShimmerBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
function Start-RowShimmer($label) {
    if (-not $label) { return }
    $anim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $anim.From = 0.30
    $anim.To = 1.0
    $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(650))
    $anim.AutoReverse = $true
    $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $label.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
}
function Stop-RowShimmer($label) {
    if (-not $label) { return }
    # Passing $null clears the animation and hands the property back to the local value.
    $label.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $label.Opacity = 1.0
}

# The scan walks 68 directory trees recursively. It used to do that inline on the UI thread, so the
# whole window locked up for the duration and the Cleaner dashboard froze while it totalled sizes.
# It now runs in its own runspace and streams one result per target back through a ConcurrentQueue,
# which a DispatcherTimer drains: rows, category badges and the running total all fill in live.
$Script:ScanPs = $null
$Script:ScanHandle = $null
$Script:ScanTimer = $null
$Script:ScanQueue = $null
$Script:ScanTotalMB = 0.0
$Script:ScanDone = 0
$Script:ScanExpected = 0
$Script:ScanAutoSelect = $false

function Invoke-ScanSpace([bool]$autoSelectFound = $false) {
    if ($Script:ScanPs) { return }   # a scan is already in flight

    $BtnScanAll.IsEnabled = $false
    $BtnCleanSelected.IsEnabled = $false
    $StatusIcon.Text = [char]0xE72C
    $StatusText.Text = "Scanning over 55 cache targets across Drive C: ..."
    Add-HubLog "Beginning full drive C: cache analysis in the background..." "SCAN"

    # One process enumeration for the whole scan instead of one per guard per target.
    $Script:RunningProcessNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) { [void]$Script:RunningProcessNames.Add($p.ProcessName) }

    $Script:ScanTotalMB = 0.0
    $Script:ScanDone = 0
    $Script:ScanAutoSelect = $autoSelectFound
    $Script:ScanQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    # Plain data only: strings cross the runspace boundary, WPF objects must not.
    $work = [System.Collections.ArrayList]::new()
    foreach ($item in $Script:TargetItems) {
        [void]$work.Add([pscustomobject]@{ Id = $item.Id; Path = $item.Path })
        $item.SizeLabel.Text = "Scanning..."
        $item.SizeLabel.Foreground = $Script:ShimmerBrush
        $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Normal
        Start-RowShimmer $item.SizeLabel
    }
    $Script:ScanExpected = $work.Count

    # STA because the recycle-bin branch of the sizer talks to the Shell.Application COM object,
    # which is not callable from an MTA thread.
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()

    $Script:ScanPs = [powershell]::Create()
    $Script:ScanPs.Runspace = $rs
    [void]$Script:ScanPs.AddScript({
        param($work, $queue, $sizerText)
        $sizer = [scriptblock]::Create($sizerText)
        foreach ($w in $work) {
            $mb = 0.0
            try { $mb = [double](& $sizer $w.Path) } catch { $mb = 0.0 }
            $queue.Enqueue([pscustomobject]@{ Id = $w.Id; SizeMB = $mb })
        }
    }).AddArgument($work).AddArgument($Script:ScanQueue).AddArgument($Script:FolderSizerText)

    $Script:ScanHandle = $Script:ScanPs.BeginInvoke()

    $Script:ScanTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:ScanTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $Script:ScanTimer.add_Tick({ Update-ScanProgress })
    $Script:ScanTimer.Start()
}

function Update-ScanProgress {
    $item = $null
    $result = $null
    while ($Script:ScanQueue.TryDequeue([ref]$result)) {
        $item = $Script:TargetItems | Where-Object { $_.Id -eq $result.Id } | Select-Object -First 1
        if (-not $item) { continue }

        $sz = [double]$result.SizeMB
        $item.SizeMB = $sz
        $item.SizeFormatted = Format-SpaceMB $sz
        $Script:ScanDone++

        if ($item.IsAdmin -and -not $isAdmin) {
            $item.Status = "Requires Admin"
        } elseif ($item.Guard.Length -gt 0 -and (Test-ProcessRunning $item.Guard)) {
            $item.Status = "Locked (" + ($item.Guard -join ', ') + " running)"
        } elseif ($sz -gt 0) {
            $item.Status = "Ready to Clean"
            $Script:ScanTotalMB += $sz
        } else {
            $item.Status = "Clean / Empty"
        }

        Stop-RowShimmer $item.SizeLabel
        if ($sz -gt 0) {
            $item.SizeLabel.Text = $item.SizeFormatted
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Bold
            if ($Script:ScanAutoSelect -and ($isAdmin -or -not $item.IsAdmin)) {
                $item.CheckBoxControl.IsChecked = $true
            }
        } else {
            $item.SizeLabel.Text = "0 MB"
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    # Live feedback while the rest is still being walked.
    if ($Script:ScanDone -lt $Script:ScanExpected) {
        Update-CategoryBadges
        $StatusText.Text = "Scanning... $($Script:ScanDone) / $($Script:ScanExpected) targets ($(Format-SpaceMB $Script:ScanTotalMB) found)"
    }

    if (-not $Script:ScanHandle.IsCompleted) { return }
    if ($Script:ScanDone -lt $Script:ScanExpected -and $Script:ScanQueue.Count -gt 0) { return }

    if ($Script:ScanTimer) { $Script:ScanTimer.Stop() }
    try { $Script:ScanPs.EndInvoke($Script:ScanHandle) | Out-Null } catch {
        Add-HubLog "Background scan reported an error: $($_.Exception.Message)" "ERROR"
    }
    try { $Script:ScanPs.Runspace.Close() } catch {}
    try { $Script:ScanPs.Dispose() } catch {}
    $Script:ScanPs = $null
    $Script:ScanHandle = $null

    # Any row that never produced a result must not be left shimmering forever.
    foreach ($t in $Script:TargetItems) { Stop-RowShimmer $t.SizeLabel }

    Update-DriveInfo
    Update-CategoryBadges
    Update-SelectedSummary
    if ($TargetsDataGrid) { $TargetsDataGrid.Items.Refresh() }

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E
    $StatusText.Text = "Scan complete! Found cache targets are highlighted."
    Add-HubLog "Cache analysis complete: $(Format-SpaceMB $Script:ScanTotalMB) detected across targets ($($TxtTotalReclaimable.Text) selected)." "SCAN"
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

