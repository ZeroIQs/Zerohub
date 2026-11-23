function Set-MaxPrivacyMode {
    $confirmPrompt = "Max Privacy Mode will apply comprehensive privacy hardening across all 12 vectors:`n`n - Stop DiagTrack & diagsvc telemetry background services`n - Disable Advertising ID & Activity Timeline cloud uploads`n - Block keystroke/ink harvesting & Bing web search integration`n - Disable CEIP & Compatibility Appraiser background tasks`n - Block Windows Recall snapshots & Copilot background processes`n - Null-route Microsoft telemetry hostnames in the hosts file`n - Disable Edge background telemetry & startup boost`n - Block Windows Error Reporting (WER) memory dump uploads`n - Block Windows nudges, tips & File Explorer promo ads`n - Disable Delivery Optimization (WUDO) P2P upload bandwidth seeding`n - Block Cloud Clipboard synchronization while keeping local history`n - Disable location tracking, sensor telemetry & feedback nags`n`nCore Windows features (Microsoft Store, Xbox, DirectX, Games) remain 100% functional. Continue?"

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "ZeroHub - Max Privacy Mode",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $loadingMsg = "Applying Max Privacy Mode & disabling all 13 telemetry vectors..."
    Set-PrivacyLoadingState $true $loadingMsg

    try {
        Set-PrivacyDiagnostics $true $true
        Set-PrivacyAdsAndActivity $true $true
        Set-PrivacyTypingAndSearch $true $true
        Set-PrivacyTasks $true $true
        Set-PrivacyAI $true $true
        Set-PrivacyHosts $true $true
        Set-PrivacyEdge $true $true
        Set-PrivacyWER $true $true
        Set-PrivacyNudges $true $true
        Set-PrivacyWUDO $true $true
        Set-PrivacyClipboard $true $true
        Set-PrivacySensors $true $true

        $msg = "Max Privacy Mode Applied! All 12 Windows telemetry and tracking vectors are now blocked."
        $StatusIcon.Text = [char]0xE73E # Checkmark
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Privacy Shield" $msg
    } finally {
        Set-PrivacyLoadingState $false
        Update-PrivacyUI
    }
}

function Restore-DefaultPrivacyMode {
    $confirmPrompt = "Do you want to restore default Windows privacy and telemetry configurations for all 12 vectors?"

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "ZeroHub - Restore Privacy Defaults",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $restoreMsg = "Restoring Windows default privacy and telemetry settings..."
    Set-PrivacyLoadingState $true $restoreMsg

    try {
        Set-PrivacyDiagnostics $false $true
        Set-PrivacyAdsAndActivity $false $true
        Set-PrivacyTypingAndSearch $false $true
        Set-PrivacyTasks $false $true
        Set-PrivacyAI $false $true
        Set-PrivacyHosts $false $true
        Set-PrivacyEdge $false $true
        Set-PrivacyWER $false $true
        Set-PrivacyNudges $false $true
        Set-PrivacyWUDO $false $true
        Set-PrivacyClipboard $false $true
        Set-PrivacySensors $false $true

        $msg = "Windows default privacy & telemetry settings restored."
        $StatusIcon.Text = [char]0xE73E # Checkmark
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Privacy Shield" $msg
    } finally {
        Set-PrivacyLoadingState $false
        Update-PrivacyUI
    }
}

# Wire Privacy Tab Action Buttons
if ($BtnApplyMaxPrivacy) {
    $BtnApplyMaxPrivacy.add_Click({ Set-MaxPrivacyMode })
}
if ($BtnRestorePrivacyDefaults) {
    $BtnRestorePrivacyDefaults.add_Click({ Restore-DefaultPrivacyMode })
}
if ($BtnTogglePrivDiag) {
    $BtnTogglePrivDiag.add_Click({
        $curr = Get-PrivacyDiagnosticsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyDiagnostics (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivAds) {
    $BtnTogglePrivAds.add_Click({
        $curr = Get-PrivacyAdsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyAdsAndActivity (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivSearch) {
    $BtnTogglePrivSearch.add_Click({
        $curr = Get-PrivacySearchState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyTypingAndSearch (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivTasks) {
    $BtnTogglePrivTasks.add_Click({
        $curr = Get-PrivacyTasksState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyTasks (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivAI) {
    $BtnTogglePrivAI.add_Click({
        $curr = Get-PrivacyAIState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyAI (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivHosts) {
    $BtnTogglePrivHosts.add_Click({
        $curr = Get-PrivacyHostsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyHosts (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivEdge) {
    $BtnTogglePrivEdge.add_Click({
        $curr = Get-PrivacyEdgeState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyEdge (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivWER) {
    $BtnTogglePrivWER.add_Click({
        $curr = Get-PrivacyWERState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyWER (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivNudges) {
    $BtnTogglePrivNudges.add_Click({
        $curr = Get-PrivacyNudgesState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyNudges (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivWUDO) {
    $BtnTogglePrivWUDO.add_Click({
        $curr = Get-PrivacyWUDOState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyWUDO (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivClipboard) {
    $BtnTogglePrivClipboard.add_Click({
        $curr = Get-PrivacyClipboardState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyClipboard (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivSensors) {
    $BtnTogglePrivSensors.add_Click({
        $curr = Get-PrivacySensorsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacySensors (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivClassicMenu) {
    $BtnTogglePrivClassicMenu.add_Click({
        $curr = Get-ClassicContextMenuState
        Set-PrivacyLoadingState $true "Configuring Windows Context Menu..."
        try { Set-ClassicContextMenu (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}




