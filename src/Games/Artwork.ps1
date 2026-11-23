function Load-GameArtCache {
    try {
        if (Test-Path $Script:GameArtCacheFilePath) {
            $json = Get-Content $Script:GameArtCacheFilePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($json) {
                foreach ($prop in $json.PSObject.Properties) {
                    $Script:GameArtCache[$prop.Name] = [string]$prop.Value
                }
            }
        }
    } catch {}
}

function Save-GameArtCache {
    try {
        $dir = [System.IO.Path]::GetDirectoryName($Script:GameArtCacheFilePath)
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        $Script:GameArtCache | ConvertTo-Json -Compress | Set-Content $Script:GameArtCacheFilePath -Encoding UTF8 -Force
    } catch {}
}

Load-GameArtCache

function Get-CleanGameTitle([string]$name) {
    if (-not $name) { return "" }
    $clean = $name -replace '\[.*?\]|\(.*?\)', ' '
    $clean = $clean -replace '(?i)fitgirl|dodi|repack|codex|skidrow|flt|rune|cpx|goldberg|empress|elamigos', ''
    $clean = $clean -replace '(?i)v\d+(\.\d+)*|build\s*\d+|patch\s*\d+|update\s*\d+', ''
    $clean = $clean -replace '(?i)deluxe edition|definitive edition|complete edition|goty edition|game of the year|standard edition', ''
    $clean = $clean -replace '(?i)\.exe|\.lnk', ''
    $clean = $clean -replace '[\._\-]', ' '
    $clean = $clean -replace '\s+', ' '
    return $clean.Trim()
}

function Extract-GameExeIcon([string]$exePath, [string]$gameName) {
    try {
        if (-not (Test-Path $exePath)) { return "" }
        $iconDir = Join-Path $env:LOCALAPPDATA "ZeroHub\GameIcons"
        if (-not (Test-Path $iconDir)) { New-Item -Path $iconDir -ItemType Directory -Force | Out-Null }
        
        $safeName = ($gameName -replace '[^a-zA-Z0-9_\-]', '')
        $targetPng = Join-Path $iconDir "$safeName.png"
        if (Test-Path $targetPng) { return $targetPng }
        
        Add-Type -AssemblyName System.Drawing
        $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
        if ($icon) {
            $bmp = $icon.ToBitmap()
            $bmp.Save($targetPng, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
            $icon.Dispose()
            return $targetPng
        }
    } catch {}
    return ""
}

function Find-GameMainExe([string]$folderPath, [string]$gameName) {
    if (-not (Test-Path $folderPath)) { return "" }
    try {
        # Check root folder first (fastest)
        $rootExes = Get-ChildItem -Path $folderPath -Filter "*.exe" -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -notmatch '(?i)_Redist|unins|setup|dxwebsetup|QuickSFV|NoDVD|crash|report|support|dotnet|vcredist|DirectX' }
        
        $cleanGame = ($gameName -replace '[^a-zA-Z0-9]', '')
        if ($rootExes) {
            foreach ($exe in $rootExes) {
                $cleanExe = ($exe.BaseName -replace '[^a-zA-Z0-9]', '')
                if ($cleanExe -and ($cleanExe -match $cleanGame -or $cleanGame -match $cleanExe)) {
                    return $exe.FullName
                }
            }
            return ($rootExes | Sort-Object Length -Descending | Select-Object -First 1).FullName
        }

        # Check subfolders (Depth 1 only, no deep traversal)
        $subExes = Get-ChildItem -Path $folderPath -Filter "*.exe" -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -notmatch '(?i)_Redist|unins|setup|dxwebsetup|QuickSFV|NoDVD|crash|report|support|dotnet|vcredist|DirectX' }
        
        if ($subExes) {
            foreach ($exe in $subExes) {
                $cleanExe = ($exe.BaseName -replace '[^a-zA-Z0-9]', '')
                if ($cleanExe -and ($cleanExe -match $cleanGame -or $cleanGame -match $cleanExe)) {
                    return $exe.FullName
                }
            }
            return ($subExes | Sort-Object Length -Descending | Select-Object -First 1).FullName
        }
    } catch {}
    return ""
}

function Detect-RepackSource([string]$folderPath, [string]$gameName) {
    if (-not (Test-Path $folderPath)) { return "PC Game" }
    try {
        # 1. FitGirl Signatures (Fast O(1) checks)
        if ((Test-Path (Join-Path $folderPath "_Redist\QuickSFV.EXE")) -or 
            (Test-Path (Join-Path $folderPath "fitgirl-repacks.site")) -or 
            (Test-Path (Join-Path $folderPath "_Redist\QuickSFV.ini"))) {
            return "FitGirl Repack"
        }

        # 2. DODI Signatures (Fast O(1) check)
        if (Test-Path (Join-Path $folderPath "dodi-repacks.site")) {
            return "DODI Repack"
        }

        # 3. GOG Signatures
        $gog = Get-ChildItem -Path $folderPath -Filter "goggame-*.info" -ErrorAction SilentlyContinue
        if ($gog) { return "GOG" }
    } catch {}
    return "PC Game"
}

function Get-RepackPlatformStyle([string]$source) {
    switch ($source) {
        "FitGirl Repack" {
            return @{
                Name = "FitGirl Repack"
                Color = "#F472B6"
                Bg = "#500724"
                Border = "#DB2777"
            }
        }
        "DODI Repack" {
            return @{
                Name = "DODI Repack"
                Color = "#FB923C"
                Bg = "#431407"
                Border = "#EA580C"
            }
        }
        "GOG" {
            return @{
                Name = "GOG Galaxy"
                Color = "#C084FC"
                Bg = "#3B0764"
                Border = "#9333EA"
            }
        }
        default {
            return @{
                Name = "PC Game"
                Color = "#FBBF24"
                Bg = "#451A03"
                Border = "#D97706"
            }
        }
    }
}

function Find-FolderSteamAppId([string]$dir) {
    if (-not $dir -or -not (Test-Path $dir)) { return "" }
    try {
        # 1. Direct steam_appid.txt (Root & Depth 1 only)
        $txtFiles = Get-ChildItem -Path $dir -Filter "steam_appid.txt" -Depth 1 -ErrorAction SilentlyContinue
        foreach ($tf in $txtFiles) {
            $val = (Get-Content $tf.FullName -ErrorAction SilentlyContinue | Select-Object -First 1).Trim()
            if ($val -match '^\d+$') { return $val }
        }

        # 2. INI files (Root & Depth 1 only)
        $iniFiles = Get-ChildItem -Path $dir -Filter "*.ini" -Depth 1 -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '(?i)steam|tenoke|rune|codex|goldberg|flt|hlm|ali213|settings'
        }
        foreach ($inf in $iniFiles) {
            $lines = Get-Content $inf.FullName -ErrorAction SilentlyContinue | Select-Object -First 30
            foreach ($line in $lines) {
                if ($line -match '^\s*(?:AppId|id|appid|GameAppId)\s*=\s*(\d+)') {
                    return $Matches[1]
                }
            }
        }
    } catch {}
    return ""
}

function Get-GameCoverArt([string]$platform, [string]$appId, [string]$name, [string]$installDir, [string]$steamPath) {
    try {
        # 1. Direct franchise matching for 100% reliable art
        if ($name -like "*Call of Duty*" -or $name -like "*Modern Warfare*" -or $name -like "*Warzone*" -or $name -like "*Black Ops*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1938090/header.jpg"
        }
        if ($name -like "*Minecraft*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1672970/header.jpg"
        }
        if ($name -like "*VALORANT*") {
            return "https://images.contentstack.io/v3/assets/blt0eb2a2986b796d20/blt01c25556cdb9ec38/63914a1e94cf4d6df141df90/VALORANT_Header.jpg"
        }
        if ($name -like "*League of Legends*" -or $name -like "*LoL*") {
            return "https://images.contentstack.io/v3/assets/blt0eb2a2986b796d20/blt8ff3c69466c1f198/63c5e50bf781bc13e4b78c66/LOL_Header.jpg"
        }
        if ($name -like "*Counter-Strike*" -or $name -like "*CS:GO*" -or $name -like "*CS2*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg"
        }
        if ($name -like "*Dota*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/570/header.jpg"
        }
        if ($name -like "*Apex*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1172470/header.jpg"
        }
        if ($name -like "*PUBG*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/578080/header.jpg"
        }
        if ($name -like "*Grand Theft Auto*" -or $name -like "*GTA*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/271590/header.jpg"
        }
        if ($name -like "*Cyberpunk*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1091500/header.jpg"
        }
        if ($name -like "*Rust*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/252490/header.jpg"
        }
        if ($name -like "*Rainbow Six*" -or $name -like "*Siege*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/359550/header.jpg"
        }
        if ($name -like "*Destiny*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1085660/header.jpg"
        }
        if ($name -like "*Elden Ring*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1245620/header.jpg"
        }
        if ($name -like "*Helldivers*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/553850/header.jpg"
        }
        if ($name -like "*Baldur*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1086940/header.jpg"
        }
        if ($name -like "*Fortnite*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1086940/header.jpg"
        }
        if ($name -like "*Overwatch*") {
            return "https://images.blz-contentstack.com/v3/assets/blt9c12f249ac15c7ec/blte3bc4c40aaef1dc6/62b489a2632ff40eb76fa2e7/OW2_LaunchHero_1920x1080.jpg"
        }
        if ($name -like "*Diablo*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/2344520/header.jpg"
        }
        if ($name -like "*Forza*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/1551360/header.jpg"
        }
        if ($name -like "*Rocket League*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/252950/header.jpg"
        }
        if ($name -like "*Dying Light*") {
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/534380/header.jpg"
        }

        # 2. Local Steam cache or Steam CDN (Official Steam App)
        if ($platform -eq "Steam" -and $appId) {
            if ($steamPath) {
                $localHero = Join-Path $steamPath "appcache\librarycache\$appId\header.jpg"
                if (Test-Path $localHero) { return $localHero }
            }
            return "https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg"
        }

        # 3. Direct AppId Detection from Game Folder (FitGirl / Repacks / Standalone Steam Emulators)
        if ($installDir -and (Test-Path $installDir)) {
            $detectedSteamId = Find-FolderSteamAppId $installDir
            if ($detectedSteamId) {
                return "https://cdn.cloudflare.steamstatic.com/steam/apps/$detectedSteamId/header.jpg"
            }
        }

        # 4. Local Game Folder Cover Art (FitGirl / Repacks / Standalone)
        if ($installDir -and (Test-Path $installDir)) {
            $coverNames = @("cover.jpg", "cover.png", "header.jpg", "header.png", "poster.jpg", "poster.png", "background.jpg", "background.png")
            foreach ($cn in $coverNames) {
                $localArt = Join-Path $installDir $cn
                if (Test-Path $localArt) { return $localArt }
            }
        }
    } catch {}

    # 5. Ambient high quality default game banner
    return "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&auto=format&fit=crop&q=80"
}

