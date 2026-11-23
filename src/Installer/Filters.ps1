function Set-InstallerFilters {
    $q = if ($TxtInstallerSearch) { $TxtInstallerSearch.Text.Trim().ToLower() } else { "" }
    $cat = $Script:InstallerFilterCategory

    $Script:Col1Cards.Clear()
    $Script:Col2Cards.Clear()
    $Script:Col3Cards.Clear()
    $Script:Col4Cards.Clear()

    $visibleCards = [System.Collections.Generic.List[ZeroHub.InstallerCategoryCard]]::new()

    foreach ($card in $Script:InstallerCategoryCards) {
        $card.FilteredApps.Clear()
        if ($cat -ne "All" -and $card.Key -ne $cat) {
            $card.Visibility = "Collapsed"
            continue
        }

        foreach ($app in $card.AllApps) {
            $matchesQuery = [string]::IsNullOrWhiteSpace($q) -or 
                $app.DisplayName.ToLower().Contains($q) -or 
                $app.PackageId.ToLower().Contains($q) -or 
                $app.Description.ToLower().Contains($q)

            if ($matchesQuery) {
                $card.FilteredApps.Add($app)
            }
        }

        $appCount = $card.FilteredApps.Count
        $card.CountText = "$appCount Apps"
        if ($appCount -gt 0) {
            $card.Visibility = "Visible"
            $visibleCards.Add($card)
        } else {
            $card.Visibility = "Collapsed"
        }
    }

    # Dynamically place cards into columns
    if ($cat -ne "All" -or $visibleCards.Count -le 2) {
        for ($i = 0; $i -lt $visibleCards.Count; $i++) {
            switch ($i % 4) {
                0 { $Script:Col1Cards.Add($visibleCards[$i]) }
                1 { $Script:Col2Cards.Add($visibleCards[$i]) }
                2 { $Script:Col3Cards.Add($visibleCards[$i]) }
                3 { $Script:Col4Cards.Add($visibleCards[$i]) }
            }
        }
    } else {
        foreach ($card in $visibleCards) {
            switch ($card.Key) {
                "Browsers"      { $Script:Col1Cards.Add($card) }
                "Utilities"     { $Script:Col1Cards.Add($card) }
                "Development"   { $Script:Col2Cards.Add($card) }
                "Communications"{ $Script:Col2Cards.Add($card) }
                "Media"         { $Script:Col3Cards.Add($card) }
                "Runtimes"      { $Script:Col3Cards.Add($card) }
                "Selfhosted"    { $Script:Col3Cards.Add($card) }
                "Gaming"        { $Script:Col4Cards.Add($card) }
                "ProTools"      { $Script:Col4Cards.Add($card) }
                "Documents"     { $Script:Col4Cards.Add($card) }
                default         { $Script:Col1Cards.Add($card) }
            }
        }
    }

    $realUpdatesCount = 0
    foreach ($item in $Script:InstallerCatalogList) {
        if ($item.HasUpdate) { $realUpdatesCount++ }
    }
    if ($BtnSelectUpdates) {
        $BtnSelectUpdates.Content = "🔄 Updates ($realUpdatesCount)"
        if ($realUpdatesCount -gt 0) {
            $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
            $BtnSelectUpdates.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
            $BtnSelectUpdates.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        } else {
            $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
            $BtnSelectUpdates.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
            $BtnSelectUpdates.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        }
    }

    Update-InstallerSelectionStatus
}

function Set-InstallerCategoryFilter([string]$cat, $activeBtn) {
    $Script:InstallerFilterCategory = $cat
    $buttons = @($BtnFilterInstAll, $BtnFilterInstBrowsers, $BtnFilterInstTools, $BtnFilterInstGaming, $BtnFilterInstComms, $BtnFilterInstMedia, $BtnFilterInstDev, $BtnFilterInstPro, $BtnFilterInstDocs, $BtnFilterInstRuntimes)
    $inactiveBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
    $inactiveFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
    $activeBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
    $activeFg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")

    foreach ($b in $buttons) {
        if ($b) {
            $b.Background = $inactiveBg
            $b.Foreground = $inactiveFg
            $b.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    if ($activeBtn) {
        $activeBtn.Background = $activeBg
        $activeBtn.Foreground = $activeFg
        $activeBtn.FontWeight = [System.Windows.FontWeights]::Bold
    }
    Set-InstallerFilters
}

# Connect Filter buttons
if ($BtnFilterInstAll)      { $BtnFilterInstAll.add_Click({ Set-InstallerCategoryFilter "All" $BtnFilterInstAll }) }
if ($BtnFilterInstBrowsers) { $BtnFilterInstBrowsers.add_Click({ Set-InstallerCategoryFilter "Browsers" $BtnFilterInstBrowsers }) }
if ($BtnFilterInstTools)    { $BtnFilterInstTools.add_Click({ Set-InstallerCategoryFilter "Utilities" $BtnFilterInstTools }) }
if ($BtnFilterInstGaming)   { $BtnFilterInstGaming.add_Click({ Set-InstallerCategoryFilter "Gaming" $BtnFilterInstGaming }) }
if ($BtnFilterInstComms)    { $BtnFilterInstComms.add_Click({ Set-InstallerCategoryFilter "Communications" $BtnFilterInstComms }) }
if ($BtnFilterInstMedia)    { $BtnFilterInstMedia.add_Click({ Set-InstallerCategoryFilter "Media" $BtnFilterInstMedia }) }
if ($BtnFilterInstDev)      { $BtnFilterInstDev.add_Click({ Set-InstallerCategoryFilter "Development" $BtnFilterInstDev }) }
if ($BtnFilterInstPro)      { $BtnFilterInstPro.add_Click({ Set-InstallerCategoryFilter "ProTools" $BtnFilterInstPro }) }
if ($BtnFilterInstDocs)     { $BtnFilterInstDocs.add_Click({ Set-InstallerCategoryFilter "Documents" $BtnFilterInstDocs }) }
if ($BtnFilterInstRuntimes) { $BtnFilterInstRuntimes.add_Click({ Set-InstallerCategoryFilter "Runtimes" $BtnFilterInstRuntimes }) }

# Initialize Top Category Bar Colors on Startup
if ($BtnFilterInstAll) {
    Set-InstallerCategoryFilter "All" $BtnFilterInstAll
}

if ($TxtInstallerSearch) {
    $TxtInstallerSearch.add_TextChanged({ Set-InstallerFilters })
}

function Set-InstallerActionActive($activeBtn) {
    $actionBtns = @($BtnSelectUpdates, $BtnSelectRecApps, $BtnSelectAllInstApps, $BtnDeselectAllInstApps)
    $inactiveBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
    $inactiveFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $recActiveBg= [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
    $updActiveBg= [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $whiteFg    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    foreach ($b in $actionBtns) {
        if ($b) {
            $b.Background = $inactiveBg
            $b.Foreground = $inactiveFg
            $b.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
    }
    if ($activeBtn -eq $BtnSelectRecApps) {
        $activeBtn.Background = $recActiveBg
        $activeBtn.Foreground = $whiteFg
        $activeBtn.FontWeight = [System.Windows.FontWeights]::Bold
    } elseif ($activeBtn -eq $BtnSelectUpdates) {
        $activeBtn.Background = $updActiveBg
        $activeBtn.Foreground = $whiteFg
        $activeBtn.FontWeight = [System.Windows.FontWeights]::Bold
    } elseif ($activeBtn) {
        $activeBtn.Background = $recActiveBg
        $activeBtn.Foreground = $whiteFg
        $activeBtn.FontWeight = [System.Windows.FontWeights]::Bold
    }
}

if ($BtnSelectUpdates) {
    $BtnSelectUpdates.add_Click({
        Set-InstallerActionActive $BtnSelectUpdates
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = ($item.HasUpdate -eq $true)
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnSelectRecApps) {
    $BtnSelectRecApps.add_Click({
        Set-InstallerActionActive $BtnSelectRecApps
        foreach ($item in $Script:InstallerCatalogList) {
            if ($item.IsRecommended -and -not $item.IsInstalled) {
                $item.IsSelected = $true
            } else {
                $item.IsSelected = $false
            }
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnSelectAllInstApps) {
    $BtnSelectAllInstApps.add_Click({
        Set-InstallerActionActive $BtnSelectAllInstApps
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = $true
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnDeselectAllInstApps) {
    $BtnDeselectAllInstApps.add_Click({
        Set-InstallerActionActive $BtnDeselectAllInstApps
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = $false
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnRefreshInstStatus) {
    $BtnRefreshInstStatus.add_Click({
        $BtnRefreshInstStatus.IsEnabled = $false
        $origContent = $BtnRefreshInstStatus.Content
        $BtnRefreshInstStatus.Content = "⏳ Scanning..."
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
            $proc = Start-Process -FilePath "winget" -ArgumentList "upgrade", "--accept-source-agreements" -NoNewWindow -PassThru -RedirectStandardOutput $tempOut -RedirectStandardError "$env:TEMP\winget_upgrades_err.txt"
            $proc.WaitForExit(12000)

            $upgrades = Get-WingetAvailableUpgrades
            $Script:AvailableWingetUpgrades.Clear()
            if ($upgrades) {
                foreach ($k in $upgrades.Keys) {
                    if (-not $Script:DismissedUpgradeIds.Contains($k)) {
                        $Script:AvailableWingetUpgrades[$k] = $upgrades[$k]
                    }
                }
            }

            Clear-DataCacheStamp "installer"
            Initialize-InstallerCatalogList
            Set-InstallerFilters
        } finally {
            $BtnRefreshInstStatus.Content = $origContent
            $BtnRefreshInstStatus.IsEnabled = $true
        }
    })
}

