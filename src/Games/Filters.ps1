# ==========================================
# ALL-IN-ONE GAME HUB & GAME BOOSTER ENGINE
# ==========================================
$Script:AllGames = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.GameItem]]::new()
$Script:FilteredGames = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.GameItem]]::new()
$Script:CurrentGamePlatformFilter = "All"
$Script:CustomGamesFilePath = Join-Path $env:APPDATA "ZeroHub\custom_games.json"

$GameCardsContainer.ItemsSource = $Script:FilteredGames

function Update-GameSearchFilter {
    $q = if ($TxtGameSearch -and $TxtGameSearch.Text) { $TxtGameSearch.Text.Trim().ToLower() } else { "" }
    $plat = $Script:CurrentGamePlatformFilter

    $Script:FilteredGames.Clear()
    foreach ($g in $Script:AllGames) {
        $matchesPlat = ($plat -eq "All") -or 
                       ($plat -eq "Steam" -and $g.Platform -eq "Steam") -or
                       ($plat -eq "Epic" -and $g.Platform -eq "Epic Games") -or
                       ($plat -eq "Riot" -and $g.Platform -eq "Riot Games") -or
                       ($plat -eq "Battlenet" -and $g.Platform -eq "Battle.net") -or
                       ($plat -eq "Xbox" -and $g.Platform -like "*Xbox*") -or
                       ($plat -eq "FitGirl" -and $g.Platform -like "*FitGirl*") -or
                       ($plat -eq "DODI" -and $g.Platform -like "*DODI*") -or
                       ($plat -eq "GOG" -and $g.Platform -like "*GOG*") -or
                       ($plat -eq "Standalone" -and ($g.Platform -eq "PC Game" -or $g.Platform -match 'FitGirl|DODI|GOG|Standalone')) -or
                       ($plat -eq "Custom" -and $g.IsCustom)

        if ($matchesPlat) {
            if ([string]::IsNullOrWhiteSpace($q) -or 
                ($g.Name -and $g.Name.ToLower().Contains($q)) -or 
                ($g.Platform -and $g.Platform.ToLower().Contains($q)) -or
                ($g.InstallDir -and $g.InstallDir.ToLower().Contains($q))) {
                $Script:FilteredGames.Add($g)
            }
        }
    }

    if ($TxtGameHubStats) {
        $count = $Script:AllGames.Count
        $freeMemGb = 0
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) { $freeMemGb = [math]::Round($os.FreePhysicalMemory / 1024 / 1024, 1) }
        } catch {}
        $TxtGameHubStats.Text = "🎮 $count Games Ready • $freeMemGb GB Available RAM"
    }
    Update-GameCardsResponsiveLayout
}

function Update-GameCardsResponsiveLayout {
    try {
        if (-not $ScrollGameCards -or -not $GameCardsContainer) { return }
        $avail = $ScrollGameCards.ActualWidth - 20
        if ($avail -gt 250) {
            $cols = [math]::Max(1, [math]::Floor($avail / 290))
            $totalGaps = ($cols - 1) * 14
            $targetWidth = [math]::Floor(($avail - $totalGaps) / $cols)
            if ($targetWidth -ge 220) {
                $GameCardsContainer.Tag = [double]$targetWidth
            }
        }
    } catch {}
}

if ($ScrollGameCards) {
    $ScrollGameCards.add_SizeChanged({ Update-GameCardsResponsiveLayout })
}

if ($TxtGameSearch) {
    $TxtGameSearch.add_TextChanged({ Update-GameSearchFilter })
}

function Set-GamePlatformFilter([string]$plat) {
    $Script:CurrentGamePlatformFilter = $plat
    $buttons = @(
        @{ Btn = $BtnFilterGameAll; Tag = "All" },
        @{ Btn = $BtnFilterGameSteam; Tag = "Steam" },
        @{ Btn = $BtnFilterGameEpic; Tag = "Epic" },
        @{ Btn = $BtnFilterGameRiot; Tag = "Riot" },
        @{ Btn = $BtnFilterGameBattlenet; Tag = "Battlenet" },
        @{ Btn = $BtnFilterGameXbox; Tag = "Xbox" },
        @{ Btn = $BtnFilterGameFitGirl; Tag = "FitGirl" },
        @{ Btn = $BtnFilterGameDODI; Tag = "DODI" },
        @{ Btn = $BtnFilterGameGOG; Tag = "GOG" },
        @{ Btn = $BtnFilterGameStandalone; Tag = "Standalone" },
        @{ Btn = $BtnFilterGameCustom; Tag = "Custom" }
    )
    foreach ($b in $buttons) {
        if ($b.Btn) {
            if ($b.Tag -eq $plat) {
                $b.Btn.Style = $Window.FindResource("PrimaryButton")
            } else {
                $b.Btn.Style = $Window.FindResource("SecondaryButton")
            }
        }
    }
    Update-GameSearchFilter
}

if ($BtnFilterGameAll)        { $BtnFilterGameAll.add_Click({ Set-GamePlatformFilter "All" }) }
if ($BtnFilterGameSteam)      { $BtnFilterGameSteam.add_Click({ Set-GamePlatformFilter "Steam" }) }
if ($BtnFilterGameEpic)       { $BtnFilterGameEpic.add_Click({ Set-GamePlatformFilter "Epic" }) }
if ($BtnFilterGameRiot)       { $BtnFilterGameRiot.add_Click({ Set-GamePlatformFilter "Riot" }) }
if ($BtnFilterGameBattlenet)  { $BtnFilterGameBattlenet.add_Click({ Set-GamePlatformFilter "Battlenet" }) }
if ($BtnFilterGameXbox)       { $BtnFilterGameXbox.add_Click({ Set-GamePlatformFilter "Xbox" }) }
if ($BtnFilterGameFitGirl)    { $BtnFilterGameFitGirl.add_Click({ Set-GamePlatformFilter "FitGirl" }) }
if ($BtnFilterGameDODI)       { $BtnFilterGameDODI.add_Click({ Set-GamePlatformFilter "DODI" }) }
if ($BtnFilterGameGOG)        { $BtnFilterGameGOG.add_Click({ Set-GamePlatformFilter "GOG" }) }
if ($BtnFilterGameStandalone) { $BtnFilterGameStandalone.add_Click({ Set-GamePlatformFilter "Standalone" }) }
if ($BtnFilterGameCustom)     { $BtnFilterGameCustom.add_Click({ Set-GamePlatformFilter "Custom" }) }

$Script:GameArtCacheFilePath = Join-Path $env:LOCALAPPDATA "ZeroHub\game_art_cache.json"
$Script:GameArtCache = @{}

