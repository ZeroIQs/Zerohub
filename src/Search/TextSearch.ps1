# ==========================================
# FAST TEXT FINDER LOGIC & EVENT HANDLERS
# ==========================================
if ($TxtSearchFolder) {
    $TxtSearchFolder.Text = (Get-Location).Path
}

if ($BtnBrowseSearchFolder) {
    $BtnBrowseSearchFolder.add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select Target Folder to Search Content"
        $dialog.ShowNewFolderButton = $false
        if ([System.IO.Directory]::Exists($TxtSearchFolder.Text)) {
            $dialog.SelectedPath = $TxtSearchFolder.Text
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $TxtSearchFolder.Text = $dialog.SelectedPath
        }
    })
}




# Mode Explanation dynamic switch
if ($RadioSearchContent) {
    $RadioSearchContent.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "📄 Inside Content Mode: Opens each file (.ini, .txt, .log, code, configs) and searches for exact text matches inside lines."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

if ($RadioSearchNames) {
    $RadioSearchNames.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "📁 Name Search Mode: Instant 0.01s search for file and folder names across the directory tree (Everything-style)."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

if ($RadioSearchBoth) {
    $RadioSearchBoth.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "⚡ All (Both) Mode: Finds matching file and folder names PLUS reads inside all text files for text matches."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

function Invoke-PerformTextSearch {
    $folder = $TxtSearchFolder.Text.Trim()
    $query = $TxtSearchQuery.Text.Trim()
    $exts = $TxtSearchExtensions.Text.Trim()
    $recursive = [bool]$ChkSearchRecursive.IsChecked
    $matchCase = [bool]$ChkSearchMatchCase.IsChecked
    $useRegex = [bool]$ChkSearchUseRegex.IsChecked

    $searchMode = "Both"
    if ($RadioSearchNames -and $RadioSearchNames.IsChecked) { $searchMode = "Names" }
    elseif ($RadioSearchContent -and $RadioSearchContent.IsChecked) { $searchMode = "Content" }

    if ([string]::IsNullOrWhiteSpace($folder) -or -not ([System.IO.Directory]::Exists($folder))) {
        [System.Windows.MessageBox]::Show("Please enter or browse a valid target folder path.", "Invalid Folder", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ([string]::IsNullOrWhiteSpace($query)) {
        [System.Windows.MessageBox]::Show("Please enter a search query or filename.", "Empty Search", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $BtnStartTextSearch.IsEnabled = $false
    $BtnStartTextSearch.Content = "⏳ Searching..."
    $TxtSearchStatus.Text = "Searching files, folders & content in parallel using C# engine..."
    $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    try {
        $stats = $null
        $results = [ZeroHub.FileContentSearcher]::Search(
            $folder,
            $query,
            $exts,
            $searchMode,
            $recursive,
            $matchCase,
            $useRegex,
            3000,
            [ref]$stats
        )

        $SearchDataGrid.ItemsSource = $results

        if ($stats) {
            $msg = "✓ Found $($stats.MatchedCount) match(es)"
            if ($stats.FoldersMatched -gt 0) { $msg += " ($($stats.FoldersMatched) folders" }
            if ($stats.FilesMatched -gt 0) { 
                if ($stats.FoldersMatched -gt 0) { $msg += ", $($stats.FilesMatched) files)" }
                else { $msg += " ($($stats.FilesMatched) files)" }
            } elseif ($stats.FoldersMatched -gt 0) { $msg += ")" }
            $msg += " (Scanned $($stats.FilesScanned) files in $($stats.ElapsedSeconds)s)"

            $TxtSearchStatus.Text = $msg
            $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            Add-HubLog "Omni search for '$query' ($searchMode) completed: $($stats.MatchedCount) match(es) in $($stats.ElapsedSeconds)s." "INFO"
        }
    } catch {
        $TxtSearchStatus.Text = "Error during search: $($_.Exception.Message)"
        $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        Add-HubLog "Error during search: $($_.Exception.Message)" "ERROR"
    } finally {
        $BtnStartTextSearch.IsEnabled = $true
        $BtnStartTextSearch.Content = "⚡ Start Search"
    }
}

if ($BtnStartTextSearch) {
    $BtnStartTextSearch.add_Click({
        Invoke-PerformTextSearch
    })
}

if ($TxtSearchQuery) {
    $TxtSearchQuery.add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Enter) {
            Invoke-PerformTextSearch
        }
    })
}

if ($BtnClearSearchResults) {
    $BtnClearSearchResults.add_Click({
        $SearchDataGrid.ItemsSource = $null
        $TxtSearchQuery.Text = ""
        $TxtSearchStatus.Text = "Ready to search. Select a folder and enter search keywords."
        $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    })
}

# Context Menu & Row Double Click Handlers
if ($SearchDataGrid) {
    $SearchDataGrid.add_MouseDoubleClick({
        param($s, $e)
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            if ($selected.IsDirectory) {
                Start-Process "explorer.exe" -ArgumentList "`"$($selected.FilePath)`""
            } else {
                Start-Process $selected.FilePath
            }
        }
    })

    $searchContextMenu = New-Object System.Windows.Controls.ContextMenu

    $menuOpen = New-Object System.Windows.Controls.MenuItem
    $menuOpen.Header = "Open File in Default Editor"
    $iconOpenFile = New-Object System.Windows.Controls.TextBlock
    $iconOpenFile.Text = "📄"
    $iconOpenFile.FontSize = 11.5
    $menuOpen.Icon = $iconOpenFile
    
    $menuOpen.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            Start-Process $selected.FilePath
        }
    })
    $searchContextMenu.Items.Add($menuOpen) | Out-Null

    $menuFolder = New-Object System.Windows.Controls.MenuItem
    $menuFolder.Header = "Open Containing Folder"
    $iconOpenFolder = New-Object System.Windows.Controls.TextBlock
    $iconOpenFolder.Text = "📁"
    $iconOpenFolder.FontSize = 11.5
    $menuFolder.Icon = $iconOpenFolder
    
    $menuFolder.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.FilePath)`""
        }
    })
    $searchContextMenu.Items.Add($menuFolder) | Out-Null

    $searchContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuCopyPath = New-Object System.Windows.Controls.MenuItem
    $menuCopyPath.Header = "Copy Full Path"
    $iconCopyP = New-Object System.Windows.Controls.TextBlock
    $iconCopyP.Text = "📋"
    $iconCopyP.FontSize = 11.5
    $menuCopyPath.Icon = $iconCopyP
    
    $menuCopyPath.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath) {
            [System.Windows.Clipboard]::SetText($selected.FilePath)
            Show-ZeroToastNotification "ZeroHub" "Copied path to clipboard: $($selected.FilePath)"
        }
    })
    $searchContextMenu.Items.Add($menuCopyPath) | Out-Null

    $menuCopyLine = New-Object System.Windows.Controls.MenuItem
    $menuCopyLine.Header = "Copy Matched Line Text"
    $iconCopyL = New-Object System.Windows.Controls.TextBlock
    $iconCopyL.Text = "📋"
    $iconCopyL.FontSize = 11.5
    $menuCopyLine.Icon = $iconCopyL
    
    $menuCopyLine.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.LineText) {
            [System.Windows.Clipboard]::SetText($selected.LineText)
            Show-ZeroToastNotification "ZeroHub" "Copied matched line to clipboard."
        }
    })
    $searchContextMenu.Items.Add($menuCopyLine) | Out-Null

    $SearchDataGrid.ContextMenu = $searchContextMenu
}

