# --- REVO-STYLE DEEP APP UNINSTALLER TAB LOGIC ---
$Script:AllInstalledApps = [System.Collections.Generic.List[ZeroHub.InstalledAppItem]]::new()
$Script:CurrentAppFilter = "All"

function Update-InstalledAppsList() {
    if (-not $AppsGrid) { return }
    Set-DataCacheStamp "installedapps"

    try {
        $Script:AllInstalledApps = [ZeroHub.UninstallerEngine]::GetInstalledApps()
    } catch {
        $Script:AllInstalledApps = [System.Collections.Generic.List[ZeroHub.InstalledAppItem]]::new()
    }

    Set-AppFilters
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

function Set-AppFilterButtonStyles($activeFilter) {
    $defaultBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
    $defaultBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
    $defaultFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    $activeBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $activeBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $activeFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    foreach ($btn in @($BtnFilterAll, $BtnFilterGames, $BtnFilterApps, $BtnFilterOrphaned)) {
        if ($btn) {
            $btn.Background = $defaultBg
            $btn.BorderBrush = $defaultBorder
            $btn.Foreground = $defaultFg
            $btn.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    switch ($activeFilter) {
        "All" { if ($BtnFilterAll) { $BtnFilterAll.Background = $activeBg; $BtnFilterAll.BorderBrush = $activeBorder; $BtnFilterAll.Foreground = $activeFg; $BtnFilterAll.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Games" { if ($BtnFilterGames) { $BtnFilterGames.Background = $activeBg; $BtnFilterGames.BorderBrush = $activeBorder; $BtnFilterGames.Foreground = $activeFg; $BtnFilterGames.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Apps" { if ($BtnFilterApps) { $BtnFilterApps.Background = $activeBg; $BtnFilterApps.BorderBrush = $activeBorder; $BtnFilterApps.Foreground = $activeFg; $BtnFilterApps.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Orphaned" { if ($BtnFilterOrphaned) { $BtnFilterOrphaned.Background = $activeBg; $BtnFilterOrphaned.BorderBrush = $activeBorder; $BtnFilterOrphaned.Foreground = $activeFg; $BtnFilterOrphaned.FontWeight = [System.Windows.FontWeights]::Bold } }
    }
}

function Set-AppFilters() {
    if (-not $AppsGrid) { return }
    $q = if ($TxtAppSearch -and $TxtAppSearch.Text) { $TxtAppSearch.Text } else { "" }
    $filterMode = $Script:CurrentAppFilter

    $filtered = [ZeroHub.UninstallerEngine]::FilterInstalledApps($Script:AllInstalledApps, $q, $filterMode)
    $AppsGrid.ItemsSource = $filtered

    # Update count text
    $catName = if ($filterMode -eq "Games") {
        "Games"
    } elseif ($filterMode -eq "Apps") {
        "Apps"
    } elseif ($filterMode -eq "Orphaned") {
        "Orphaned items"
    } else {
        "Total items"
    }
    if ($TxtAppCount) {
        $TxtAppCount.Text = "$($filtered.Count) $catName"
    }
}

# Category Filter Buttons
$BtnFilterAll.add_Click({
    $Script:CurrentAppFilter = "All"
    Set-AppFilterButtonStyles "All"
    Set-AppFilters
})

$BtnFilterGames.add_Click({
    $Script:CurrentAppFilter = "Games"
    Set-AppFilterButtonStyles "Games"
    Set-AppFilters
})

$BtnFilterApps.add_Click({
    $Script:CurrentAppFilter = "Apps"
    Set-AppFilterButtonStyles "Apps"
    Set-AppFilters
})

$BtnFilterOrphaned.add_Click({
    $Script:CurrentAppFilter = "Orphaned"
    Set-AppFilterButtonStyles "Orphaned"
    Set-AppFilters
})

# Search filter in App Uninstaller tab
$TxtAppSearch.add_TextChanged({ Set-AppFilters })

# Bulk Selection & Status Handlers
function Update-AppSelectionStatus {
    $selectedList = @($Script:AllInstalledApps | Where-Object { $_.IsSelected })
    if ($selectedList.Count -eq 0 -and $AppsGrid.SelectedItem) {
        $selectedList = @($AppsGrid.SelectedItem)
    }

    if ($selectedList.Count -gt 0) {
        $BtnUninstallSelected.IsEnabled = $true
        $totalMB = ($selectedList | Measure-Object EstimatedSizeMB -Sum).Sum
        $sizeText = Format-SpaceMB $totalMB

        if ($selectedList.Count -eq 1) {
            $BtnUninstallSelected.Content = "Uninstall & Clean Selected App"
            $TxtSelectedAppStatus.Text = "Selected: $($selectedList[0].DisplayName) ($($selectedList[0].SizeFormatted))"
        } else {
            $BtnUninstallSelected.Content = "Bulk Uninstall ($($selectedList.Count) Selected)"
            $TxtSelectedAppStatus.Text = "$($selectedList.Count) apps selected (Total Size: $sizeText)"
        }
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    } else {
        $BtnUninstallSelected.IsEnabled = $false
        $BtnUninstallSelected.Content = "Uninstall & Clean Leftovers"
        $TxtSelectedAppStatus.Text = "Select one or more applications from the list above to uninstall and clean leftovers."
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

$BtnSelectAllApps.add_Click({
    $displayed = $AppsGrid.ItemsSource
    if ($displayed) {
        foreach ($app in $displayed) {
            $app.IsSelected = $true
        }
        $AppsGrid.Items.Refresh()
        Update-AppSelectionStatus
    }
})

$BtnDeselectAllApps.add_Click({
    foreach ($app in $Script:AllInstalledApps) {
        $app.IsSelected = $false
    }
    $AppsGrid.Items.Refresh()
    Update-AppSelectionStatus
})

# App selection change on row or checkbox click
$AppsGrid.add_SelectionChanged({ Update-AppSelectionStatus })

# Real-time CheckBox click handler (immediate instant count sync)
$Script:AppsClickHandler = [System.Windows.RoutedEventHandler]{
    param($s, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $AppsGrid.Dispatcher.BeginInvoke([System.Action]{
            Update-AppSelectionStatus
        })
    }
}
$AppsGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $Script:AppsClickHandler)

# Double-click app row to open containing folder
$AppsGrid.add_MouseDoubleClick({
    param($s, $e)
    $selected = $AppsGrid.SelectedItem
    if (-not $selected) { return }

    $targetFolder = ""
    if ($selected.InstallLocation -and [System.IO.Directory]::Exists($selected.InstallLocation)) {
        $targetFolder = $selected.InstallLocation
    } elseif ($selected.UninstallString) {
        $u = $selected.UninstallString.Trim()
        $exe = ""
        if ($u -match '^"([^"]+)"') { $exe = $matches[1] }
        elseif ($u -match '^([a-zA-Z]:\\[^\s]+\.exe)') { $exe = $matches[1] }
        else { $exe = $u.Split(' ')[0] }

        if ($exe -and [System.IO.File]::Exists($exe)) {
            $targetFolder = [System.IO.Path]::GetDirectoryName($exe)
        }
    }

    if ($targetFolder -and [System.IO.Directory]::Exists($targetFolder)) {
        Start-Process "explorer.exe" -ArgumentList "`"$targetFolder`""
    }
})

