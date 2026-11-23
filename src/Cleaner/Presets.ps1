# --- PRESET HANDLERS ---
function Set-AllSelections([bool]$value) {
    foreach ($item in $Script:TargetItems) {
        if ($item.CheckBoxControl.IsEnabled) {
            $item.CheckBoxControl.IsChecked = $value
            $item.IsSelected = $value
            if ($value) {
                $item.CheckBoxControl.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
                $item.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::SemiBold
            } else {
                $item.CheckBoxControl.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }
                $item.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::Normal
            }
        }
    }
    Update-SelectedSummary
}

function Set-CategorySelection([string]$catName) {
    Set-AllSelections $false
    foreach ($item in $Script:TargetItems) {
        if ($item.Cat -eq $catName -and $item.CheckBoxControl.IsEnabled) {
            $item.CheckBoxControl.IsChecked = $true
            $item.IsSelected = $true
            $item.CheckBoxControl.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
            $item.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    Update-SelectedSummary
}

function Set-RecommendedSelection() {
    Set-AllSelections $false
    # Recommended: 100% Login-Safe GPU shaders, Browsers, Dev caches, Gaming caches, User temp (Recycle Bin excluded for safety)
    $recIds = @(
        "gpu_nv_dx", "gpu_nv_gl", "gpu_amd_dx", "gpu_amd_gl", "gpu_intel", "gpu_d3d",
        "br_chrome_cache", "br_chrome_code", "br_chrome_gpu", "br_edge_cache", "br_edge_code", "br_brave_cache", "br_arc", "br_firefox", "br_opera", "br_operagx",
        "dev_npm", "dev_pip", "dev_yarn", "dev_pnpm", "dev_nuget", "dev_gradle", "dev_cargo", "dev_vscode",
        "game_steam", "game_epic", "game_battlenet", "game_riot", "game_gog", "game_roblox",
        "soc_telegram", "soc_discord", "soc_slack", "soc_spotify", "soc_davinci", "soc_blender", "soc_obs", "soc_vlc",
        "sys_user_temp", "sys_dns_cache", "adm_cryptnet"
    )
    foreach ($item in $Script:TargetItems) {
        if ($recIds -contains $item.Id -and $item.CheckBoxControl.IsEnabled) {
            $item.CheckBoxControl.IsChecked = $true
            $item.IsSelected = $true
            $item.CheckBoxControl.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
            $item.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    Update-SelectedSummary
}

# Free RAM Action Handler (Directly on Tab Bar)
$ExecuteFreeRamAction = {
    try {
        if ($BtnFreeRam) { $BtnFreeRam.IsEnabled = $false }
        if ($TxtFreeRam) {
            $TxtFreeRam.Text = "Freeing..."
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        }
        $StatusText.Text = "Freeing idle RAM memory..."
        [System.Windows.Forms.Application]::DoEvents()

        $osBefore = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeBeforeMB = if ($osBefore) { [math]::Round($osBefore.FreePhysicalMemory / 1024, 1) } else { 0 }

        # Flush Working Sets
        $optCount = [ZeroHub.NativeMethods]::OptimizeProcessesRam()
        Add-HubLog "Working sets flushed across $optCount processes." "RAM"

        Start-Sleep -Milliseconds 300
        Update-LiveMemoryStats

        $osAfter = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeAfterMB = if ($osAfter) { [math]::Round($osAfter.FreePhysicalMemory / 1024, 1) } else { 0 }
        $reclaimedMB = [math]::Max(0, [math]::Round(($freeAfterMB - $freeBeforeMB), 1))

        if ($TxtFreeRam) {
            $TxtFreeRam.Text = "Freed!"
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }

        $toastTitle = "ZeroHub - RAM Reclaimed"
        $toastMsg = "Memory freed successfully! Current Free RAM: $(Format-SpaceMB $freeAfterMB)"
        Show-ZeroToastNotification $toastTitle $toastMsg
        $StatusText.Text = $toastMsg

        Add-HubLog "Free RAM executed: Reclaimed $reclaimedMB MB (Free now: $freeAfterMB MB)" "SUCCESS"

        # Restore button text after 2.5 seconds asynchronously
        if ($Script:FreeRamTimer) {
            try { $Script:FreeRamTimer.Stop() } catch {}
        }
        $Script:FreeRamTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $Script:FreeRamTimer.Interval = [TimeSpan]::FromSeconds(2.5)
        $Script:FreeRamTimer.add_Tick({
            param($s, $e)
            if ($s) { try { $s.Stop() } catch {} }
            if ($Script:FreeRamTimer) { try { $Script:FreeRamTimer.Stop() } catch {} }
            if ($TxtFreeRam) {
                $TxtFreeRam.Text = "Free RAM"
                $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
            }
            if ($BtnFreeRam) { $BtnFreeRam.IsEnabled = $true }
        }.GetNewClosure())
        $Script:FreeRamTimer.Start()
    } catch {
        if ($TxtFreeRam) {
            $TxtFreeRam.Text = "Free RAM"
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
        }
        if ($BtnFreeRam) { $BtnFreeRam.IsEnabled = $true }
        Add-HubLog "Error freeing RAM: $($_.Exception.Message)" "ERROR"
    }
}

if ($Tab_FreeRam) {
    $Tab_FreeRam.add_PreviewMouseDown({
        param($s, $e)
        $e.Handled = $true
        & $ExecuteFreeRamAction
    })
}

if ($BtnFreeRam) {
    $BtnFreeRam.add_Click({
        & $ExecuteFreeRamAction
    })
}

function Set-CleanerPresetActive($activeBtn) {
    $presets = @($BtnPresetRecommended, $BtnPresetAll, $BtnPresetBrowsers, $BtnPresetDev, $BtnPresetGaming, $BtnPresetClear)
    $inactiveBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
    $inactiveFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $activeBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
    $activeFg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    foreach ($p in $presets) {
        if ($p) {
            $p.Background = $inactiveBg
            $p.Foreground = $inactiveFg
            $p.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    if ($activeBtn) {
        $activeBtn.Background = $activeBg
        $activeBtn.Foreground = $activeFg
        $activeBtn.FontWeight = [System.Windows.FontWeights]::Bold
    }
}

