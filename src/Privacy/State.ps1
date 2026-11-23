# ==========================================
# DEDICATED PRIVACY & ANTI-TELEMETRY ENGINE
# ==========================================

function Get-PrivacyDiagnosticsState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "DiagBlocked" -ErrorAction SilentlyContinue).DiagBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $diagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
        $regTelemetry = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue).AllowTelemetry
        return (($null -ne $regTelemetry -and $regTelemetry -eq 0) -or ($null -ne $diagTrack -and $diagTrack.StartType -eq "Disabled"))
    } catch { return $false }
}

function Get-PrivacyAdsState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "AdsBlocked" -ErrorAction SilentlyContinue).AdsBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $adInfo = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
        $adPolicy = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue).DisabledByGroupPolicy
        return (($null -ne $adInfo -and $adInfo -eq 0) -or ($null -ne $adPolicy -and $adPolicy -eq 1))
    } catch { return $false }
}

function Get-PrivacySearchState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "SearchBlocked" -ErrorAction SilentlyContinue).SearchBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $bingCU = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -ErrorAction SilentlyContinue).BingSearchEnabled
        $ink    = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -ErrorAction SilentlyContinue).RestrictImplicitInkCollection
        return (($null -ne $bingCU -and $bingCU -eq 0) -or ($null -ne $ink -and $ink -eq 1))
    } catch { return $false }
}

function Get-PrivacyTasksState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "TasksBlocked" -ErrorAction SilentlyContinue).TasksBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $ceip = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator" -ErrorAction SilentlyContinue
        return ($null -ne $ceip -and $ceip.State -eq "Disabled")
    } catch { return $false }
}

function Get-PrivacyAIState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "AIBlocked" -ErrorAction SilentlyContinue).AIBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $copilot = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue).TurnOffWindowsCopilot
        $recall  = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Recall" -Name "DisableRecall" -ErrorAction SilentlyContinue).DisableRecall
        return (($null -ne $copilot -and $copilot -eq 1) -or ($null -ne $recall -and $recall -eq 1))
    } catch { return $false }
}

function Get-PrivacyHostsState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "HostsBlocked" -ErrorAction SilentlyContinue).HostsBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        if (Test-Path $hostsPath) {
            $content = Get-Content -Path $hostsPath -Raw -ErrorAction SilentlyContinue
            return ($null -ne $content -and $content.Contains("v10.events.data.microsoft.com"))
        }
        return $false
    } catch { return $false }
}

function Get-PrivacyEdgeState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "EdgeBlocked" -ErrorAction SilentlyContinue).EdgeBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $edgeMetrics = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled" -ErrorAction SilentlyContinue).MetricsReportingEnabled
        return ($null -ne $edgeMetrics -and $edgeMetrics -eq 0)
    } catch { return $false }
}

function Get-PrivacyWERState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "WERBlocked" -ErrorAction SilentlyContinue).WERBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $werLM = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -ErrorAction SilentlyContinue).Disabled
        return ($null -ne $werLM -and $werLM -eq 1)
    } catch { return $false }
}

function Get-PrivacyNudgesState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "NudgesBlocked" -ErrorAction SilentlyContinue).NudgesBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $cdm = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -ErrorAction SilentlyContinue
        if ($cdm -and $cdm."SystemPaneSuggestionsEnabled" -eq 0 -and $cdm."SubscribedContent-338388Enabled" -eq 0) { return $true }
        return $false
    } catch { return $false }
}

function Get-PrivacyWUDOState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "WUDOBlocked" -ErrorAction SilentlyContinue).WUDOBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $doLM = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode
        if ($null -ne $doLM -and ($doLM -eq 0 -or $doLM -eq 99)) { return $true }
        return $false
    } catch { return $false }
}

function Get-PrivacyClipboardState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "ClipboardBlocked" -ErrorAction SilentlyContinue).ClipboardBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $clipSys = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowCrossDeviceClipboard" -ErrorAction SilentlyContinue).AllowCrossDeviceClipboard
        if ($null -ne $clipSys -and $clipSys -eq 0) { return $true }
        return $false
    } catch { return $false }
}

function Get-PrivacySensorsState {
    try {
        $userPref = (Get-ItemProperty -Path "HKCU:\SOFTWARE\ZeroHub\Privacy" -Name "SensorsBlocked" -ErrorAction SilentlyContinue).SensorsBlocked
        if ($null -ne $userPref) { return ($userPref -eq 1) }

        $loc = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -ErrorAction SilentlyContinue).DisableLocation
        if ($null -ne $loc -and $loc -eq 1) { return $true }
        return $false
    } catch { return $false }
}

function Get-ClassicContextMenuState {
    try {
        $key = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        if (Test-Path $key) { return $true }
        return $false
    } catch { return $false }
}

function Set-PrivacyLoadingState([bool]$loading, [string]$statusMsg = "") {
    if ($FooterProgressBar) {
        $FooterProgressBar.Visibility = if ($loading) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
    }
    $allBtns = @($BtnApplyMaxPrivacy, $BtnRestorePrivacyDefaults, $BtnTogglePrivDiag, $BtnTogglePrivAds, $BtnTogglePrivSearch, $BtnTogglePrivTasks, $BtnTogglePrivAI, $BtnTogglePrivHosts, $BtnTogglePrivEdge, $BtnTogglePrivWER, $BtnTogglePrivNudges, $BtnTogglePrivWUDO, $BtnTogglePrivClipboard, $BtnTogglePrivSensors, $BtnTogglePrivClassicMenu)
    foreach ($b in $allBtns) {
        if ($b) { $b.IsEnabled = (-not $loading) }
    }
    if ($loading) {
        $StatusIcon.Text = [char]0xE895 # Segoe MDL2 Sync/Progress
        $StatusText.Text = if ($statusMsg) { $statusMsg } else { "Applying Windows privacy & system tweaks..." }
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-PrivacyUI {
    if (-not $Tab_Privacy) { return }

    $diagBlocked        = Get-PrivacyDiagnosticsState
    $adsBlocked         = Get-PrivacyAdsState
    $searchBlocked      = Get-PrivacySearchState
    $tasksBlocked       = Get-PrivacyTasksState
    $aiBlocked          = Get-PrivacyAIState
    $hostsBlocked       = Get-PrivacyHostsState
    $edgeBlocked        = Get-PrivacyEdgeState
    $werBlocked         = Get-PrivacyWERState
    $nudgesBlocked      = Get-PrivacyNudgesState
    $wudoBlocked        = Get-PrivacyWUDOState
    $clipboardBlocked   = Get-PrivacyClipboardState
    $sensorsBlocked     = Get-PrivacySensorsState
    $classicMenuEnabled = Get-ClassicContextMenuState

    $cProtBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
    $cProtBd = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B6B48")
    $cProtFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
    $cActBg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#331410")
    $cActBd  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5C2016")
    $cActFg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E68A75")

    $cBtnGreenBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
    $cBtnGreenFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
    $cBtnRedBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $cBtnRedFg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    # Helper scriptblock to update each card
    $updateCard = {
        param($border, $badge, $btn, $isBlocked)
        if ($border -and $badge) {
            if ($isBlocked) {
                $border.Background = $cProtBg
                $border.BorderBrush = $cProtBd
                $badge.Foreground = $cProtFg
                $badge.Text = "● Protected"
                if ($btn) { 
                    $btn.Content = "Disable Protection" 
                    $btn.Background = $cBtnRedBg
                    $btn.Foreground = $cBtnRedFg
                }
            } else {
                $border.Background = $cActBg
                $border.BorderBrush = $cActBd
                $badge.Foreground = $cActFg
                $badge.Text = "● Active (Exposed)"
                if ($btn) { 
                    $btn.Content = "Enable Protection" 
                    $btn.Background = $cBtnGreenBg
                    $btn.Foreground = $cBtnGreenFg
                }
            }
        }
    }

    & $updateCard $Border_BadgePrivCard1  $BadgePrivCard1  $BtnTogglePrivDiag      $diagBlocked
    & $updateCard $Border_BadgePrivCard2  $BadgePrivCard2  $BtnTogglePrivAds       $adsBlocked
    & $updateCard $Border_BadgePrivCard3  $BadgePrivCard3  $BtnTogglePrivSearch    $searchBlocked
    & $updateCard $Border_BadgePrivCard4  $BadgePrivCard4  $BtnTogglePrivTasks     $tasksBlocked
    & $updateCard $Border_BadgePrivCard5  $BadgePrivCard5  $BtnTogglePrivAI        $aiBlocked
    & $updateCard $Border_BadgePrivCard6  $BadgePrivCard6  $BtnTogglePrivHosts     $hostsBlocked
    & $updateCard $Border_BadgePrivCard7  $BadgePrivCard7  $BtnTogglePrivEdge      $edgeBlocked
    & $updateCard $Border_BadgePrivCard8  $BadgePrivCard8  $BtnTogglePrivWER       $werBlocked
    & $updateCard $Border_BadgePrivCard9  $BadgePrivCard9  $BtnTogglePrivNudges    $nudgesBlocked
    & $updateCard $Border_BadgePrivCard10 $BadgePrivCard10 $BtnTogglePrivWUDO      $wudoBlocked
    & $updateCard $Border_BadgePrivCard11 $BadgePrivCard11 $BtnTogglePrivClipboard $clipboardBlocked
    & $updateCard $Border_BadgePrivCard12 $BadgePrivCard12 $BtnTogglePrivSensors   $sensorsBlocked

    # Card 13: Classic Context Menu
    if ($Border_BadgePrivCard13 -and $BadgePrivCard13) {
        if ($classicMenuEnabled) {
            $Border_BadgePrivCard13.Background = $cProtBg
            $Border_BadgePrivCard13.BorderBrush = $cProtBd
            $BadgePrivCard13.Foreground = $cProtFg
            $BadgePrivCard13.Text = "● Classic Active"
            if ($BtnTogglePrivClassicMenu) { 
                $BtnTogglePrivClassicMenu.Content = "Restore Win11 Menu" 
                $BtnTogglePrivClassicMenu.Background = $cBtnRedBg
                $BtnTogglePrivClassicMenu.Foreground = $cBtnRedFg
            }
        } else {
            $Border_BadgePrivCard13.Background = $cActBg
            $Border_BadgePrivCard13.BorderBrush = $cActBd
            $BadgePrivCard13.Foreground = $cActFg
            $BadgePrivCard13.Text = "● Win11 Modern"
            if ($BtnTogglePrivClassicMenu) { 
                $BtnTogglePrivClassicMenu.Content = "Enable Classic Menu" 
                $BtnTogglePrivClassicMenu.Background = $cBtnGreenBg
                $BtnTogglePrivClassicMenu.Foreground = $cBtnGreenFg
            }
        }
    }

    # Master Hero Badge (Score out of 12 telemetry vectors)
    $score = 0
    if ($diagBlocked)      { $score++ }
    if ($adsBlocked)       { $score++ }
    if ($searchBlocked)    { $score++ }
    if ($tasksBlocked)     { $score++ }
    if ($aiBlocked)        { $score++ }
    if ($hostsBlocked)     { $score++ }
    if ($edgeBlocked)      { $score++ }
    if ($werBlocked)       { $score++ }
    if ($nudgesBlocked)    { $score++ }
    if ($wudoBlocked)      { $score++ }
    if ($clipboardBlocked) { $score++ }
    if ($sensorsBlocked)   { $score++ }

    if ($BadgePrivacyMasterStatus -and $TxtPrivacyMasterStatus) {
        if ($score -eq 12) {
            $BadgePrivacyMasterStatus.Background = $cProtBg
            $BadgePrivacyMasterStatus.BorderBrush = $cProtBd
            $TxtPrivacyMasterStatus.Foreground = $cProtFg
            $TxtPrivacyMasterStatus.Text = "● Telemetry Blocked (Protected 12/12)"
        } elseif ($score -gt 0) {
            $BadgePrivacyMasterStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
            $BadgePrivacyMasterStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
            $TxtPrivacyMasterStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            $TxtPrivacyMasterStatus.Text = "● Partially Protected ($score/12)"
        } else {
            $BadgePrivacyMasterStatus.Background = $cActBg
            $BadgePrivacyMasterStatus.BorderBrush = $cActBd
            $TxtPrivacyMasterStatus.Foreground = $cActFg
            $TxtPrivacyMasterStatus.Text = "● Telemetry Active (Data Sending)"
        }
    }
}

