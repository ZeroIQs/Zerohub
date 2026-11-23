# Wire Preset Buttons with active visual feedback
$BtnPresetRecommended.add_Click({ Set-CleanerPresetActive $BtnPresetRecommended; Set-RecommendedSelection })
$BtnPresetAll.add_Click({ Set-CleanerPresetActive $BtnPresetAll; Set-AllSelections $true })
$BtnPresetBrowsers.add_Click({ Set-CleanerPresetActive $BtnPresetBrowsers; Set-CategorySelection "Browser" })
$BtnPresetDev.add_Click({ Set-CleanerPresetActive $BtnPresetDev; Set-CategorySelection "Dev" })
$BtnPresetGaming.add_Click({ Set-CleanerPresetActive $BtnPresetGaming; Set-CategorySelection "Gaming" })
$BtnPresetClear.add_Click({ Set-CleanerPresetActive $BtnPresetClear; Set-AllSelections $false })

# Wire Action Buttons
$BtnScanAll.add_Click({ Invoke-ScanSpace $false })
$BtnCleanSelected.add_Click({ Invoke-ExecuteClean $false })

# Wire Auto-Close Tip Banner Controls
if ($BtnDismissAutoCloseTip) {
    $BtnDismissAutoCloseTip.add_Click({
        $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Collapsed
    })
}
if ($BtnToggleAutoCloseTip) {
    $BtnToggleAutoCloseTip.add_Click({
        if ($Banner_AutoCloseTip.Visibility -eq [System.Windows.Visibility]::Visible) {
            $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Collapsed
        } else {
            $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Visible
        }
    })
}
if ($ChkAutoCloseApps) {
    $ChkAutoCloseApps.add_Checked({
        if ($Banner_AutoCloseTip) { $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Visible }
        $StatusText.Text = "Auto-Close enabled: Running apps will be closed before cleanup to unlock 100% of files."
    })
    $ChkAutoCloseApps.add_Unchecked({
        $StatusText.Text = "Auto-Close disabled: Running apps will be safely skipped during cleanup."
    })
}


# Wire Process Guard Tab
$BtnRefreshProcesses.add_Click({ Update-ProcessGuardList })
$BtnCloseAllGuards.add_Click({
    $prompt = "Close all running browsers, game launchers, and chat apps holding file locks?"
    $res = [System.Windows.MessageBox]::Show($prompt, "ZeroHub Process Guard", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Stop-ActiveGuardedProcesses $false
    }
})

# Wire Log Console Buttons
$BtnCopyLogs.add_Click({
    try {
        $textRange = New-Object System.Windows.Documents.TextRange($TxtLogConsole.Document.ContentStart, $TxtLogConsole.Document.ContentEnd)
        if (-not [string]::IsNullOrWhiteSpace($textRange.Text)) {
            [System.Windows.Clipboard]::SetText($textRange.Text.Trim())
            $copiedMsg = "Logs copied to clipboard!"
            [System.Windows.MessageBox]::Show($copiedMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    } catch {}
})
$BtnClearLogs.add_Click({
    try { $TxtLogConsole.Document.Blocks.Clear() } catch {}
})

