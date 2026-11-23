# Process Manager Event Wiring
if ($TxtProcSearch) {
    $TxtProcSearch.add_TextChanged({ Filter-SmartProcessList })
}
if ($BtnRefreshProcList) {
    $BtnRefreshProcList.add_Click({ Update-SmartProcessList })
}
if ($BtnPurgeSafeProcs) {
    $BtnPurgeSafeProcs.add_Click({ Invoke-PurgeAllSafeProcesses })
}
if ($BtnFilterProcAll) {
    $BtnFilterProcAll.add_Click({
        $Script:CurrentProcFilter = "ALL"
        Set-ProcFilterStyle $BtnFilterProcAll
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcSafe) {
    $BtnFilterProcSafe.add_Click({
        $Script:CurrentProcFilter = "SAFE"
        Set-ProcFilterStyle $BtnFilterProcSafe
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcWork) {
    $BtnFilterProcWork.add_Click({
        $Script:CurrentProcFilter = "WORK"
        Set-ProcFilterStyle $BtnFilterProcWork
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcService) {
    $BtnFilterProcService.add_Click({
        $Script:CurrentProcFilter = "SERVICE"
        Set-ProcFilterStyle $BtnFilterProcService
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcHeavy) {
    $BtnFilterProcHeavy.add_Click({
        $Script:CurrentProcFilter = "HEAVY"
        Set-ProcFilterStyle $BtnFilterProcHeavy
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcProtected) {
    $BtnFilterProcProtected.add_Click({
        $Script:CurrentProcFilter = "PROTECTED"
        Set-ProcFilterStyle $BtnFilterProcProtected
        Filter-SmartProcessList
    })
}

if ($ProcManagerDataGrid) {
    $ProcManagerDataGrid.add_MouseDoubleClick({
        param($s, $e)
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Path -and [System.IO.File]::Exists($selected.Path)) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.Path)`""
        }
    })

    $procContextMenu = New-Object System.Windows.Controls.ContextMenu

    $menuEndProc = New-Object System.Windows.Controls.MenuItem
    $menuEndProc.Header = "End Process / Task"
    $iconEnd = New-Object System.Windows.Controls.TextBlock
    $iconEnd.Text = "❌"
    $iconEnd.FontSize = 11.5
    $iconEnd.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    $menuEndProc.Icon = $iconEnd
    $menuEndProc.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    $menuEndProc.FontWeight = [System.Windows.FontWeights]::Bold
    $menuEndProc.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected) { Invoke-EndSelectedProcess $selected }
    })
    $procContextMenu.Items.Add($menuEndProc) | Out-Null

    $procContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuProcFolder = New-Object System.Windows.Controls.MenuItem
    $menuProcFolder.Header = "Open File Location"
    $iconFolder = New-Object System.Windows.Controls.TextBlock
    $iconFolder.Text = "📁"
    $iconFolder.FontSize = 11.5
    $menuProcFolder.Icon = $iconFolder
    
    $menuProcFolder.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Path -and [System.IO.File]::Exists($selected.Path)) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.Path)`""
        } elseif ($selected) {
            Show-ZeroToastNotification "Process Manager" "Path not accessible for $($selected.Name) (PID: $($selected.Id))"
        }
    })
    $procContextMenu.Items.Add($menuProcFolder) | Out-Null

    $menuGoogleProc = New-Object System.Windows.Controls.MenuItem
    $menuGoogleProc.Header = "Search Process Online"
    $iconSearch = New-Object System.Windows.Controls.TextBlock
    $iconSearch.Text = "🔍"
    $iconSearch.FontSize = 11.5
    $iconSearch.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $menuGoogleProc.Icon = $iconSearch
    
    $menuGoogleProc.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Name) {
            $searchUrl = "https://www.google.com/search?q=what+is+process+$([Uri]::EscapeDataString($selected.Name))"
            Open-SafeBrowserUrl $searchUrl
        }
    })
    $procContextMenu.Items.Add($menuGoogleProc) | Out-Null

    $procContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuCopyProcName = New-Object System.Windows.Controls.MenuItem
    $menuCopyProcName.Header = "Copy Process Name & PID"
    $iconCopy = New-Object System.Windows.Controls.TextBlock
    $iconCopy.Text = "📋"
    $iconCopy.FontSize = 11.5
    $menuCopyProcName.Icon = $iconCopy
    
    $menuCopyProcName.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected) {
            [System.Windows.Clipboard]::SetText("$($selected.Name) (PID: $($selected.Id))")
            Show-ZeroToastNotification "Process Manager" "Copied '$($selected.Name)' to clipboard."
        }
    })
    $procContextMenu.Items.Add($menuCopyProcName) | Out-Null

    $ProcManagerDataGrid.ContextMenu = $procContextMenu
}


