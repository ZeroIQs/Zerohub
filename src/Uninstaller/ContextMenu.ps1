# Right-click Context Menu for AppsGrid
$appsContextMenu = New-Object System.Windows.Controls.ContextMenu

# 1. Open / View Containing Folder
$menuAppFolder = New-Object System.Windows.Controls.MenuItem
$menuAppFolder.Header = "View Containing Folder"
$iconFolder = New-Object System.Windows.Controls.TextBlock
$iconFolder.Text = [char]0xE838
$iconFolder.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconFolder.FontSize = 11.5
$iconFolder.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
$menuAppFolder.Icon = $iconFolder

$menuAppFolder.FontWeight = [System.Windows.FontWeights]::SemiBold
$menuAppFolder.add_Click({
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
        Show-ZeroToastNotification "App Uninstaller" "Opened folder: $targetFolder"
    } else {
        Show-ZeroToastNotification "App Uninstaller" "Containing folder not found on disk for '$($selected.DisplayName)'"
    }
})
$appsContextMenu.Items.Add($menuAppFolder) | Out-Null

$appsContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

# 2. Copy Install Path
$menuCopyInstallPath = New-Object System.Windows.Controls.MenuItem
$menuCopyInstallPath.Header = "Copy Install Location Path"
$iconCopyPath = New-Object System.Windows.Controls.TextBlock
$iconCopyPath.Text = [char]0xE8C8
$iconCopyPath.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconCopyPath.FontSize = 11.5
$iconCopyPath.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
$menuCopyInstallPath.Icon = $iconCopyPath

$menuCopyInstallPath.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.InstallLocation) {
        [System.Windows.Clipboard]::SetText($selected.InstallLocation)
        Show-ZeroToastNotification "App Uninstaller" "Copied install path: $($selected.InstallLocation)"
    } elseif ($selected) {
        Show-ZeroToastNotification "App Uninstaller" "No install location path recorded in registry."
    }
})
$appsContextMenu.Items.Add($menuCopyInstallPath) | Out-Null

# 3. Copy Registry Path
$menuCopyRegPath = New-Object System.Windows.Controls.MenuItem
$menuCopyRegPath.Header = "Copy Registry Key Path"
$iconCopyReg = New-Object System.Windows.Controls.TextBlock
$iconCopyReg.Text = [char]0xE8D7
$iconCopyReg.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconCopyReg.FontSize = 11.5
$iconCopyReg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
$menuCopyRegPath.Icon = $iconCopyReg

$menuCopyRegPath.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.RegistryPath) {
        [System.Windows.Clipboard]::SetText($selected.RegistryPath)
        Show-ZeroToastNotification "App Uninstaller" "Copied registry path: $($selected.RegistryPath)"
    }
})
$appsContextMenu.Items.Add($menuCopyRegPath) | Out-Null

$appsContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

# 4. Search Online
$menuSearchAppOnline = New-Object System.Windows.Controls.MenuItem
$menuSearchAppOnline.Header = "Search Software Online"
$iconSearch = New-Object System.Windows.Controls.TextBlock
$iconSearch.Text = [char]0xE721
$iconSearch.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconSearch.FontSize = 11.5
$iconSearch.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
$menuSearchAppOnline.Icon = $iconSearch

$menuSearchAppOnline.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.DisplayName) {
        $searchUrl = "https://www.google.com/search?q=$([Uri]::EscapeDataString($selected.DisplayName))"
        Open-SafeBrowserUrl $searchUrl
    }
})
$appsContextMenu.Items.Add($menuSearchAppOnline) | Out-Null

$AppsGrid.ContextMenu = $appsContextMenu

$BtnRefreshApps.add_Click({
    $BtnRefreshApps.Content = "⏳ Scanning..."
    $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    [System.Windows.Forms.Application]::DoEvents()

    Update-InstalledAppsList

    $BtnRefreshApps.Content = "✅ Refreshed!"
    $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#22C55E")
    $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(1000)
    $timer.add_Tick({
        param($s, $e)
        $s.Stop()
        $BtnRefreshApps.Content = "🔄 Refresh List"
        $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A3756")
        $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
    })
    $timer.Start()
})

