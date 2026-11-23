function Initialize-InstallerCatalogList {
    Set-DataCacheStamp "installer"
    $Script:InstallerCatalogList.Clear()
    $Script:InstallerCategoryCards.Clear()
    $Script:Col1Cards.Clear()
    $Script:Col2Cards.Clear()
    $Script:Col3Cards.Clear()
    $Script:Col4Cards.Clear()
    $idx = 0

    # Quick installed check against uninstall registry keys (Fast .NET API: ~6ms)
    $installedDisplayNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($hive in @([Microsoft.Win32.Registry]::LocalMachine, [Microsoft.Win32.Registry]::CurrentUser)) {
        foreach ($sub in @('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')) {
            try {
                $key = $hive.OpenSubKey($sub)
                if ($key) {
                    foreach ($name in $key.GetSubKeyNames()) {
                        try {
                            $sk = $key.OpenSubKey($name)
                            if ($sk) {
                                $dn = $sk.GetValue('DisplayName')
                                if ($dn) { [void]$installedDisplayNames.Add($dn.ToString().Trim()) }
                                $sk.Close()
                            }
                        } catch {}
                    }
                    $key.Close()
                }
            } catch {}
        }
    }

    # Prepare 10 Category Cards with curated distinctive colors
    $categoriesConfig = @(
        @{ Key="Browsers"; HeaderEn="🌐 Web Browsers"; Color="#38BDF8"; Col=1 },
        @{ Key="Utilities"; HeaderEn="🛠️ System Utilities"; Color="#818CF8"; Col=1 },
        @{ Key="Development"; HeaderEn="💻 Development & Tools"; Color="#34D399"; Col=2 },
        @{ Key="Communications"; HeaderEn="💬 Chat & Comms"; Color="#FB7185"; Col=2 },
        @{ Key="Media"; HeaderEn="🎬 Media & Creative"; Color="#C084FC"; Col=3 },
        @{ Key="Runtimes"; HeaderEn="🪟 Microsoft & Runtimes"; Color="#60A5FA"; Col=3 },
        @{ Key="Selfhosted"; HeaderEn="☁️ Cloud & Streaming"; Color="#2DD4BF"; Col=3 },
        @{ Key="Gaming"; HeaderEn="🎮 Gaming & Launchers"; Color="#FB923C"; Col=4 },
        @{ Key="ProTools"; HeaderEn="⚡ Pro & Hardware Tools"; Color="#FBBF24"; Col=4 },
        @{ Key="Documents"; HeaderEn="📄 Documents & Office"; Color="#F472B6"; Col=4 }
    )

    $cardMap = @{}
    foreach ($c in $categoriesConfig) {
        $card = [ZeroHub.InstallerCategoryCard]::new()
        $card.Key = $c.Key
        $card.Header = $c.HeaderEn
        $card.HeaderColor = $c.Color
        $Script:InstallerCategoryCards.Add($card)
        $cardMap[$c.Key] = $card
    }

    # Build CLI command map for developer tools detection
    $commandMap = @{
        "OpenJS.NodeJS"              = @("node", "npm")
        "OpenJS.NodeJS.LTS"          = @("node", "npm")
        "Git.Git"                    = @("git")
        "Python.Python.3.14"         = @("python", "py")
        "Rustlang.Rust.MSVC"         = @("rustc", "cargo")
        "GoLang.Go"                  = @("go")
        "Microsoft.VisualStudioCode" = @("code")
        "Docker.DockerDesktop"       = @("docker")
        "pnpm.pnpm"                  = @("pnpm")
        "Yarn.Yarn"                  = @("yarn")
        "Schniz.fnm"                 = @("fnm")
        "astral-sh.uv"               = @("uv")
        "GitHub.cli"                 = @("gh")
        "Neovim.Neovim"              = @("nvim")
        "JesseDuffield.lazygit"      = @("lazygit")
        "Starship.Starship"          = @("starship")
        "JanDeDobbeleer.OhMyPosh"    = @("oh-my-posh")
        "Kitware.CMake"              = @("cmake")
    }

    # Pre-index PATH executables for instant O(1) CLI tool detection
    $pathCmds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in ($env:PATH -split ';')) {
        if ($p -and (Test-Path $p)) {
            try {
                foreach ($f in [System.IO.Directory]::GetFiles($p)) {
                    $ext = [System.IO.Path]::GetExtension($f)
                    if ($ext -in '.exe', '.cmd', '.bat', '.ps1') {
                        [void]$pathCmds.Add([System.IO.Path]::GetFileNameWithoutExtension($f))
                        [void]$pathCmds.Add([System.IO.Path]::GetFileName($f))
                    }
                }
            } catch {}
        }
    }

    # Load all available upgrades from disk / cache (skipping any dismissed this session)
    $upgrades = Get-WingetAvailableUpgrades
    if ($upgrades) {
        foreach ($k in $upgrades.Keys) {
            if (-not $Script:DismissedUpgradeIds.Contains($k)) {
                $Script:AvailableWingetUpgrades[$k] = $upgrades[$k]
            }
        }
    }

    $updatesCount = 0

    foreach ($app in $Script:CatalogAppsData) {
        $idx++
        $item = [ZeroHub.InstallerAppItem]::new()
        $item.Index = $idx
        $item.DisplayName = $app.Name
        $item.PackageId = $app.Id
        $item.CategoryKey = $app.CatKey
        $item.Description = if ($app.Desc) { $app.Desc } else { $app.Name }
        $item.IsRecommended = ($app.Rec -eq $true)

        # 1. Check CLI commands on PATH (Instant O(1) memory lookup)
        $isInst = $false
        if ($commandMap.ContainsKey($app.Id)) {
            foreach ($cmd in $commandMap[$app.Id]) {
                if ($pathCmds.Contains($cmd) -or (Get-Command $cmd -ErrorAction SilentlyContinue)) {
                    $isInst = $true
                    break
                }
            }
        }

        # 2. Check Registry with Precise Word & Pattern Match
        if (-not $isInst) {
            $appName = $app.Name
            foreach ($regName in $installedDisplayNames) {
                if ($regName -eq $appName -or
                    ($appName.Length -gt 3 -and $regName -like "*$appName*") -or
                    ($appName.Length -le 3 -and $regName -match "\b$([regex]::Escape($appName))\b") -or
                    ($app.Id -eq "OpenJS.NodeJS" -and $regName -match "Node\.js") -or
                    ($app.Id -eq "OpenJS.NodeJS.LTS" -and $regName -match "Node\.js") -or
                    ($app.Id -eq "Microsoft.VisualStudioCode" -and $regName -match "Visual Studio Code") -or
                    ($app.Id -match "^Python\." -and $regName -match "Python\s*3") -or
                    ($app.Id -eq "Rustlang.Rust.MSVC" -and $regName -match "Rust") -or
                    ($app.Id -eq "Cloudflare.Warp" -and $regName -match "Cloudflare|WARP") -or
                    ($app.Id -eq "ElectronicArts.EADesktop" -and $regName -match "EA Desktop|EA app")) {
                    
                    $isInst = $true
                    break
                }
            }
        }

        # 3. Known executable path fallback
        if (-not $isInst) {
            $pf = $env:ProgramFiles
            $pf86 = ${env:ProgramFiles(x86)}
            $la = $env:LocalAppData
            switch ($app.Id) {
                "Cloudflare.Warp" {
                    if ((Test-Path "$pf\Cloudflare\Cloudflare WARP\Cloudflare WARP.exe") -or (Get-Service -Name "CloudflareWARP" -ErrorAction SilentlyContinue)) {
                        $isInst = $true
                    }
                }
                "ElectronicArts.EADesktop" {
                    if (Test-Path "$pf\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe") { $isInst = $true }
                }
                "Google.Chrome" {
                    if ((Test-Path "$pf\Google\Chrome\Application\chrome.exe") -or (Test-Path "$pf86\Google\Chrome\Application\chrome.exe")) { $isInst = $true }
                }
                "Brave.Brave" {
                    if ((Test-Path "$pf\BraveSoftware\Brave-Browser\Application\brave.exe") -or (Test-Path "$la\BraveSoftware\Brave-Browser\Application\brave.exe")) { $isInst = $true }
                }
                "Valve.Steam" {
                    if ((Test-Path "$pf86\Steam\steam.exe") -or (Test-Path "$pf\Steam\steam.exe")) { $isInst = $true }
                }
            }
        }

        # Check if update available via winget
        $hasUpdate = $false
        if ($Script:AvailableWingetUpgrades -and $Script:AvailableWingetUpgrades.ContainsKey($app.Id)) {
            $hasUpdate = $true
            $isInst = $true
            $updatesCount++
            $upgInfo = $Script:AvailableWingetUpgrades[$app.Id]
            $item.HasUpdate = $true
            $item.CurrentVersion = $upgInfo.Current
            $item.AvailableVersion = $upgInfo.Available
            $item.Description = "$($item.Description)`n`n[🔄 Update Available: $($upgInfo.Current) -> $($upgInfo.Available)]"
        }

        $item.IsInstalled = $isInst

        if ($hasUpdate) {
            $item.Status = "🔄 Update ($($item.AvailableVersion))"
            $item.StatusBg = "#1E293B"
            $item.StatusFg = "#FBBF24"
            $item.StatusVisibility = "Visible"
            $item.NameFg = "#FBBF24"
        } elseif ($isInst) {
            $item.Status = "✅ Installed"
            $item.StatusBg = "#064E3B"
            $item.StatusFg = "#34D399"
            $item.StatusVisibility = "Visible"
            $item.NameFg = "#34D399"
        } else {
            $item.Status = ""
            $item.StatusBg = "Transparent"
            $item.StatusFg = "#94A3B8"
            $item.StatusVisibility = "Collapsed"
            $item.NameFg = "#FFFFFF"
        }

        if (-not $Script:InstallerPropChangedHandler) {
            $Script:InstallerPropChangedHandler = [System.ComponentModel.PropertyChangedEventHandler]{
                param($s, $e)
                if ($e.PropertyName -eq "IsSelected") {
                    Update-InstallerSelectionStatus
                }
            }
        }
        $item.add_PropertyChanged($Script:InstallerPropChangedHandler)
        $Script:InstallerCatalogList.Add($item)

        if ($cardMap.ContainsKey($app.CatKey)) {
            $targetCard = $cardMap[$app.CatKey]
            $targetCard.AllApps.Add($item)
        } else {
            $targetCard = $cardMap["Utilities"]
            $targetCard.AllApps.Add($item)
        }
    }

    if ($BtnSelectUpdates) {
        $BtnSelectUpdates.Content = "🔄 Updates ($updatesCount)"
        if ($updatesCount -gt 0) {
            $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
            $BtnSelectUpdates.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
            $BtnSelectUpdates.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        } else {
            $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
            $BtnSelectUpdates.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#334155")
            $BtnSelectUpdates.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        }
    }

    if ($InstallerCardsCol1) { $InstallerCardsCol1.ItemsSource = $Script:Col1Cards }
    if ($InstallerCardsCol2) { $InstallerCardsCol2.ItemsSource = $Script:Col2Cards }
    if ($InstallerCardsCol3) { $InstallerCardsCol3.ItemsSource = $Script:Col3Cards }
    if ($InstallerCardsCol4) { $InstallerCardsCol4.ItemsSource = $Script:Col4Cards }

    Set-InstallerFilters

    # Trigger background check for any new winget upgrades without blocking UI if not already running
    if (-not $Script:IsWingetScanRunning -and ($Script:AvailableWingetUpgrades.Count -eq 0)) {
        Get-WingetUpgradesAsync
    }
}

