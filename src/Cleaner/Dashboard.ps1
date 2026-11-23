# Update Drive C: Info
function Update-DriveInfo() {
    try {
        $cDrive = [System.IO.DriveInfo]::new("C")
        if ($cDrive.IsReady) {
            $totalBytes = $cDrive.TotalSize
            $freeBytes  = $cDrive.AvailableFreeSpace
            $usedBytes  = $totalBytes - $freeBytes
            $totalGB    = [math]::Round($totalBytes / 1GB, 1)
            $freeGB     = [math]::Round($freeBytes / 1GB, 1)
            $percent    = if ($totalBytes -gt 0) { [math]::Round(($usedBytes / $totalBytes) * 100, 0) } else { 0 }

            if ($DriveProgressBar) { $DriveProgressBar.Value = $percent }
            if ($DriveFreeText)    { $DriveFreeText.Text = "$freeGB GB free of $totalGB GB" }
        }
    } catch {}
}

# Update Real-Time RAM & Reclaimable Memory Indicator
function Update-LiveMemoryStats() {
    try {
        $totalGB = 0.0; $usedGB = 0.0; $freeGB = 0.0; $usedPercent = 0; $reclaimableMB = 0.0;
        $success = $false

        try {
            [ZeroHub.NativeMethods]::GetLiveMemoryMetrics([ref]$totalGB, [ref]$usedGB, [ref]$freeGB, [ref]$usedPercent, [ref]$reclaimableMB)
            if ($totalGB -gt 0) { $success = $true }
        } catch {}

        if (-not $success) {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $totalBytes = $os.TotalVisibleMemorySize * 1024
                $freeBytes  = $os.FreePhysicalMemory * 1024
                $usedBytes  = $totalBytes - $freeBytes
                $totalGB    = [math]::Round($totalBytes / 1GB, 1)
                $usedGB     = [math]::Round($usedBytes / 1GB, 1)
                $freeGB     = [math]::Round($freeBytes / 1GB, 1)
                $usedPercent = if ($totalBytes -gt 0) { [math]::Round(($usedBytes / $totalBytes) * 100, 0) } else { 0 }
                # See the note in GetLiveMemoryMetrics: this 0.28 is the fallback twin of the 0.30
                # there. Left as written, raised in that comment rather than changed here.
                $reclaimableMB = [math]::Round(($usedBytes * 0.28) / 1MB, 0)
            }
        }

        if ($totalGB -gt 0) {
            # Update Circular Progress Ring
            $pVal = [math]::Max(0.5, [math]::Min(99.9, [double]$usedPercent))
            $radius = 10.2
            $cx = 14.0
            $cy = 14.0
            $angle = ($pVal / 100.0) * 360.0
            $angleRad = ($angle - 90.0) * [Math]::PI / 180.0
            $startX = $cx
            $startY = [Math]::Round(($cy - $radius), 2)
            $endX = [Math]::Round(($cx + $radius * [Math]::Cos($angleRad)), 2)
            $endY = [Math]::Round(($cy + $radius * [Math]::Sin($angleRad)), 2)
            $isLargeArc = if ($angle -gt 180) { "1" } else { "0" }

            $geo = [System.Windows.Media.Geometry]::Parse("M $startX,$startY A $radius,$radius 0 $isLargeArc 1 $endX,$endY")
            if ($RamCircleArc) { $RamCircleArc.Data = $geo }

            # Color ring dynamically based on load (Green < 70%, Yellow 70-85%, Coral Red > 85%)
            $ringColor = if ($usedPercent -ge 85) { "#F87171" } elseif ($usedPercent -ge 70) { "#FBBF24" } else { "#4ADE80" }
            if ($RamCircleArc) { $RamCircleArc.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ringColor) }
            if ($TxtRamPercent) {
                $TxtRamPercent.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ringColor)
                $TxtRamPercent.Text = "$usedPercent%"
            }

            if ($TxtRamLiveMetrics) { $TxtRamLiveMetrics.Text = "$usedGB / $totalGB GB" }

            $reclaimableStr = Format-SpaceMB $reclaimableMB
            if ($TxtRamReclaimable) {
                $TxtRamReclaimable.Text = "Reclaimable: ~$reclaimableStr"
            }

            # Dynamically update Free RAM button tooltip
            if ($BtnFreeRam) {
                $BtnFreeRam.ToolTip = "Quickly free idle application RAM (approx $reclaimableStr)"
            }
        }
    } catch {}
}

# Update Selected Totals and Count
function Update-SelectedSummary() {
    $count = 0
    $totalMB = 0
    foreach ($item in $Script:TargetItems) {
        if ($item.CheckBoxControl.IsChecked -eq $true -or $item.IsSelected) {
            $count++
            $totalMB += $item.SizeMB
        }
    }
    $suffix = "items"
    $TxtSelectedCount.Text = "$count $suffix"
    $TxtTotalReclaimable.Text = Format-SpaceMB $totalMB
}

# Update Category Badges
function Update-CategoryBadges() {
    $catSums = @{ "GPU"=0; "Browser"=0; "Dev"=0; "Gaming"=0; "Social"=0; "System"=0 }
    foreach ($item in $Script:TargetItems) {
        if ($catSums.ContainsKey($item.Cat)) {
            $catSums[$item.Cat] += $item.SizeMB
        }
    }
    $Badge_GPU.Text     = Format-SpaceMB $catSums["GPU"]
    $Badge_Browser.Text = Format-SpaceMB $catSums["Browser"]
    $Badge_Dev.Text     = Format-SpaceMB $catSums["Dev"]
    $Badge_Gaming.Text  = Format-SpaceMB $catSums["Gaming"]
    $Badge_Social.Text  = Format-SpaceMB $catSums["Social"]
    $Badge_System.Text  = Format-SpaceMB $catSums["System"]
}

# Setup UI Admin State
if ($isAdmin) {
    $AdminText.Text = "Administrator"
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $AdminIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $BtnRelaunchAdmin.Visibility = [System.Windows.Visibility]::Collapsed
} else {
    $AdminText.Text = "Standard User"
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $AdminIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $BtnRelaunchAdmin.add_Click({
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
        $Window.Close()
    })
}

$BrushSelected   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
$BrushUnselected = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
$BrushDisabled   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
$BrushRecycleRed = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")

# Row hover and checkbox styles reuse resources rather than traversing the visual tree 68 times.
$BrushRowHover       = $Window.FindResource("CardHover")
$StyleModernCheckBox = $Window.FindResource("ModernCheckBox")
$BrushRowNormal      = [System.Windows.Media.Brushes]::Transparent
$BrushRecycleRedChecked = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")

# Populate Target Items & Build Category Checkboxes
foreach ($t in $TargetsData) {
    $item = [ZeroHub.TargetItem]::new()
    $item.Id            = $t.Id
    $item.Name          = $t.Name
        $item.Path          = $t.Path
    $item.Cat           = $t.Cat
    $item.Description   = $t.Description
        $item.Guard         = [string[]]$t.Guard
    $item.IsAdmin       = [bool]$t.IsAdmin

    # Target Row in Card
    $rowGrid = New-Object System.Windows.Controls.Grid
    $rowGrid.Margin = New-Object System.Windows.Thickness(0, 2.5, 0, 2.5)

    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::Auto
    $rowGrid.ColumnDefinitions.Add($col1)
    $rowGrid.ColumnDefinitions.Add($col2)

    $chk = New-Object System.Windows.Controls.CheckBox
    if ($StyleModernCheckBox) { $chk.Style = $StyleModernCheckBox }
    $chk.Content = $item.Name
    $chk.ToolTip = $item.Description
    $chk.Tag = $item
    $chk.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }

    # Disable system targets if not admin
    if ($item.IsAdmin -and -not $isAdmin) {
        $chk.IsEnabled = $false
        $chk.ToolTip = "[Requires Admin Elevation] " + $item.Description
        $chk.Foreground = $BrushDisabled
    }

    $lblSize = New-Object System.Windows.Controls.TextBlock
    $lblSize.Text = "--"
    $lblSize.FontSize = 11
    $lblSize.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
    $lblSize.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $lblSize.Margin = New-Object System.Windows.Thickness(6, 0, 0, 0)
    [System.Windows.Controls.Grid]::SetColumn($lblSize, 1)

    $rowGrid.Children.Add($chk) | Out-Null
    $rowGrid.Children.Add($lblSize) | Out-Null

    # Hover affordance. The row Grid had no Background at all, which means WPF does not hit-test it,
    # so there was no way to tell which row the pointer was over before clicking a checkbox. A
    # Transparent background makes the full row width hit-testable without drawing anything, and the
    # hover state is the existing CardHover token, so no new colour and no layout change.
    # Disabled rows are left out on purpose: highlighting a row the user cannot click is a lie.
    $rowGrid.Background = $BrushRowNormal
    if ($chk.IsEnabled) {
        $rowGrid.Add_MouseEnter({ param($s, $e) $s.Background = $BrushRowHover })
        $rowGrid.Add_MouseLeave({ param($s, $e) $s.Background = $BrushRowNormal })
    }

    $item.CheckBoxControl = $chk
    $item.SizeLabel = $lblSize

    # Wire Checkbox Events
    $chk.add_Checked({
        param($s, $e)
        $s.Foreground = if ($s.Tag.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
        $s.FontWeight = [System.Windows.FontWeights]::SemiBold
        $target = $s.Tag
        if (-not $target.IsSelected) {
            $target.IsSelected = $true
        }
        Update-SelectedSummary
    })
    $chk.add_Unchecked({
        param($s, $e)
        $s.Foreground = if ($s.Tag.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }
        $s.FontWeight = [System.Windows.FontWeights]::Normal
        $target = $s.Tag
        if ($target.IsSelected) {
            $target.IsSelected = $false
        }
        Update-SelectedSummary
    })

    # Two-Way Sync from DataGrid or Code to UI Checkbox
    $item.add_PropertyChanged({
        param($s, $e)
        if ($e.PropertyName -eq "IsSelected") {
            if ($s.CheckBoxControl -and $s.CheckBoxControl.IsChecked -ne $s.IsSelected) {
                $s.CheckBoxControl.IsChecked = $s.IsSelected
            }
            if ($s.CheckBoxControl) {
                if ($s.IsSelected) {
                    $s.CheckBoxControl.Foreground = if ($s.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
                    $s.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::SemiBold
                } else {
                    $s.CheckBoxControl.Foreground = if ($s.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }
                    $s.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::Normal
                }
            }
        }
    })

    $Script:CheckboxesById[$item.Id] = $chk
    $Script:TargetItems.Add($item)

    # Attach to category panel
    switch ($item.Cat) {
        "GPU"     { $Panel_GPU.Children.Add($rowGrid) | Out-Null }
        "Browser" { $Panel_Browser.Children.Add($rowGrid) | Out-Null }
        "Dev"     { $Panel_Dev.Children.Add($rowGrid) | Out-Null }
        "Gaming"  { $Panel_Gaming.Children.Add($rowGrid) | Out-Null }
        "Social"  { $Panel_Social.Children.Add($rowGrid) | Out-Null }
        "System"  { $Panel_System.Children.Add($rowGrid) | Out-Null }
    }
}

# Bind Target Inspector DataGrid
if ($TargetsDataGrid) { $TargetsDataGrid.ItemsSource = $Script:TargetItems }

