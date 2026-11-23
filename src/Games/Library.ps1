function Update-GameHubList { Update-GameLibraryList }

function Update-GameLibraryList {
    try {
        $Script:AllGames.Clear()
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $rawGames = [System.Collections.Generic.List[ZeroHub.GameItem]]::new()

        # 1. STEAM DETECTION (multi-library - fast manifest reads)
        $steamPath = ""
        try {
            $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
            if ($steamPath -and (Test-Path $steamPath)) {
                $vdfPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
                $libPaths = @($steamPath)
                if (Test-Path $vdfPath) {
                    $vdfContent = Get-Content $vdfPath -Raw -Encoding UTF8
                    $vdfMatches = [regex]::Matches($vdfContent, '"path"\s+"([^"]+)"')
                    foreach ($m in $vdfMatches) {
                        $p = $m.Groups[1].Value.Replace('\\', '\')
                        if (Test-Path $p) { $libPaths += $p }
                    }
                }
                $libPaths = $libPaths | Select-Object -Unique
                foreach ($lib in $libPaths) {
                    $steamAppsDir = Join-Path $lib "steamapps"
                    if (Test-Path $steamAppsDir) {
                        $manifests = Get-ChildItem -Path $steamAppsDir -Filter "appmanifest_*.acf" -File -ErrorAction SilentlyContinue
                        foreach ($mf in $manifests) {
                            $content = Get-Content $mf.FullName -Raw -Encoding UTF8
                            $nameMatch = [regex]::Match($content, '"name"\s+"([^"]+)"')
                            $idMatch = [regex]::Match($content, '"appid"\s+"([^"]+)"')
                            $dirMatch = [regex]::Match($content, '"installdir"\s+"([^"]+)"')
                            $sizeMatch = [regex]::Match($content, '"SizeOnDisk"\s+"([^"]+)"')
                            if ($nameMatch.Success -and $idMatch.Success -and $dirMatch.Success) {
                                $appId = $idMatch.Groups[1].Value
                                $name = $nameMatch.Groups[1].Value
                                $installDir = Join-Path $steamAppsDir ("common\" + $dirMatch.Groups[1].Value)
                                
                                # Fast check
                                if ((Test-Path $installDir) -and ($name -notmatch 'Steamworks|Proton|Steam Linux|Redistributable|SteamVR')) {
                                    if ($seen.Add("Steam_$appId")) {
                                        $szStr = ""
                                        if ($sizeMatch.Success) {
                                            $bytes = [int64]$sizeMatch.Groups[1].Value
                                            $szGb = [math]::Round($bytes / 1GB, 1)
                                            if ($szGb -gt 0) { $szStr = "$szGb GB" }
                                        }
                                        $item = [ZeroHub.GameItem]::new()
                                        $item.Name = $name
                                        $item.Platform = "Steam"
                                        $item.PlatformColor = "#38BDF8"
                                        $item.PlatformBg = "#0C4A6E"
                                        $item.PlatformBorder = "#0284C7"
                                        $item.InstallDir = $installDir
                                        $item.LaunchUri = "steam://rungameid/$appId"
                                        $item.AppId = $appId
                                        $item.BannerUrl = Get-GameCoverArt "Steam" $appId $name $installDir $steamPath
                                        $item.DisplaySize = $szStr
                                        $item.IsCustom = $false
                                        $rawGames.Add($item)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {}

        # 2. EPIC GAMES DETECTION (fast manifest read)
        try {
            $epicManifestDir = "C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
            if (Test-Path $epicManifestDir) {
                $items = Get-ChildItem -Path $epicManifestDir -Filter "*.item" -File -ErrorAction SilentlyContinue
                foreach ($itemFile in $items) {
                    $json = Get-Content $itemFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($json -and $json.DisplayName -and $json.AppName -and $json.InstallLocation) {
                        if ((Test-Path [string]$json.InstallLocation) -and $seen.Add("Epic_$($json.AppName)")) {
                            $item = [ZeroHub.GameItem]::new()
                            $item.Name = [string]$json.DisplayName
                            $item.Platform = "Epic Games"
                            $item.PlatformColor = "#C084FC"
                            $item.PlatformBg = "#3B0764"
                            $item.PlatformBorder = "#7E22CE"
                            $item.InstallDir = [string]$json.InstallLocation
                            $item.LaunchUri = "com.epicgames.launcher://apps/$($json.AppName)?action=launch&silent=true"
                            $item.AppId = [string]$json.AppName
                            $item.BannerUrl = Get-GameCoverArt "Epic Games" [string]$json.AppName [string]$json.DisplayName [string]$json.InstallLocation ""
                            $item.IsCustom = $false
                            $rawGames.Add($item)
                        }
                    }
                }
            }
        } catch {}

        # 3. RIOT GAMES DETECTION (Actual games only)
        try {
            $valPaths = @("C:\Riot Games\VALORANT", "D:\Riot Games\VALORANT", "D:\Games\Riot Games\VALORANT", "E:\Riot Games\VALORANT")
            foreach ($vp in $valPaths) {
                if ((Test-Path $vp) -and (Test-Path "$vp\live\VALORANT.exe" -ErrorAction SilentlyContinue -or Test-Path "$vp\VALORANT.exe" -ErrorAction SilentlyContinue)) {
                    if ($seen.Add("Riot_VALORANT")) {
                        $item = [ZeroHub.GameItem]::new()
                        $item.Name = "VALORANT"
                        $item.Platform = "Riot Games"
                        $item.PlatformColor = "#FB7185"
                        $item.PlatformBg = "#4C0519"
                        $item.PlatformBorder = "#E11D48"
                        $item.InstallDir = $vp
                        $item.LaunchUri = "riotclient://launch?product=valorant&patchline=live"
                        $item.AppId = "valorant"
                        $item.BannerUrl = Get-GameCoverArt "Riot Games" "valorant" "VALORANT" $vp ""
                        $item.IsCustom = $false
                        $rawGames.Add($item)
                    }
                    break
                }
            }
            $lolPaths = @("C:\Riot Games\League of Legends", "D:\Riot Games\League of Legends", "D:\Games\Riot Games\League of Legends", "E:\Riot Games\League of Legends")
            foreach ($lp in $lolPaths) {
                if ((Test-Path $lp) -and (Test-Path "$lp\LeagueClient.exe" -ErrorAction SilentlyContinue -or Test-Path "$lp\Game\League of Legends.exe" -ErrorAction SilentlyContinue)) {
                    if ($seen.Add("Riot_LoL")) {
                        $item = [ZeroHub.GameItem]::new()
                        $item.Name = "League of Legends"
                        $item.Platform = "Riot Games"
                        $item.PlatformColor = "#FB7185"
                        $item.PlatformBg = "#4C0519"
                        $item.PlatformBorder = "#E11D48"
                        $item.InstallDir = $lp
                        $item.LaunchUri = "riotclient://launch?product=league_of_legends&patchline=live"
                        $item.AppId = "league_of_legends"
                        $item.BannerUrl = Get-GameCoverArt "Riot Games" "league_of_legends" "League of Legends" $lp ""
                        $item.IsCustom = $false
                        $rawGames.Add($item)
                    }
                    break
                }
            }
        } catch {}

        # 4. BATTLE.NET DETECTION
        try {
            $bnetUninstall = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            if (Test-Path $bnetUninstall) {
                $bnetKeys = Get-ChildItem -Path $bnetUninstall -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^(Overwatch|Diablo|Hero|Pro|StarCraft|Warcraft|WoW)' }
                foreach ($k in $bnetKeys) {
                    $prop = Get-ItemProperty -Path $k.PSPath -ErrorAction SilentlyContinue
                    if ($prop.DisplayName -and $prop.InstallLocation -and (Test-Path [string]$prop.InstallLocation)) {
                        if ($seen.Add("Bnet_$($prop.DisplayName)")) {
                            $item = [ZeroHub.GameItem]::new()
                            $item.Name = [string]$prop.DisplayName
                            $item.Platform = "Battle.net"
                            $item.PlatformColor = "#38BDF8"
                            $item.PlatformBg = "#0369A1"
                            $item.PlatformBorder = "#0284C7"
                            $item.InstallDir = [string]$prop.InstallLocation
                            $item.LaunchUri = if ($prop.DisplayIcon) { [string]$prop.DisplayIcon } else { "battlenet://" }
                            $item.AppId = $k.PSChildName
                            $item.BannerUrl = Get-GameCoverArt "Battle.net" $k.PSChildName [string]$prop.DisplayName [string]$prop.InstallLocation ""
                            $item.IsCustom = $false
                            $rawGames.Add($item)
                        }
                    }
                }
            }
        } catch {}

        # 5. XBOX GAME PASS / MS STORE GAMES
        try {
            $xboxApps = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { 
                $_.Name -match 'Microsoft\.Minecraft|Microsoft\.FlightSimulator|Microsoft\.Forza|Microsoft\.Halo|Bethesda' -and 
                $_.NonRemovable -ne $true 
            }
            foreach ($xa in $xboxApps) {
                if ($xa.InstallLocation -and (Test-Path $xa.InstallLocation)) {
                    $name = ($xa.Name -replace 'Microsoft\.', '' -replace 'UWP', '' -replace '\.', ' ').Trim()
                    if ($seen.Add("Xbox_$($xa.PackageFamilyName)")) {
                        $appId = "App"
                        $manifestPath = Join-Path $xa.InstallLocation "AppxManifest.xml"
                        if (Test-Path $manifestPath) {
                            try {
                                $xml = [xml](Get-Content $manifestPath -Raw -Encoding UTF8)
                                if ($xml.Package.Applications.Application.Id) {
                                    $appId = ($xml.Package.Applications.Application.Id | Select-Object -First 1)
                                }
                            } catch {}
                        }

                        $launchUri = "shell:AppsFolder\$($xa.PackageFamilyName)!$appId"
                        $item = [ZeroHub.GameItem]::new()
                        $item.Name = $name
                        $item.Platform = "Xbox Game Pass"
                        $item.PlatformColor = "#4ADE80"
                        $item.PlatformBg = "#064E3B"
                        $item.PlatformBorder = "#059669"
                        $item.InstallDir = $xa.InstallLocation
                        $item.LaunchUri = $launchUri
                        $item.AppId = $xa.PackageFamilyName
                        $item.BannerUrl = Get-GameCoverArt "Xbox" $xa.PackageFamilyName $name $xa.InstallLocation ""
                        $item.IsCustom = $false
                        $rawGames.Add($item)
                    }
                }
            }
        } catch {}

        # 6. STANDALONE & REPACK GAMES (Ultra-fast non-blocking scan)
        $nonGameRegex = '(?i)cpuid|cpu-z|cpuz|gpu-z|hwinfo|hwmonitor|aida64|virtualbox|vbox|vmware|qemu|ubisoft\s*connect|ubisoft\s*game\s*launcher|riot\s*client|battle\.net|vlc|obs\s*studio|obs64|streamlabs|handbrake|audacity|blender|gimp|photoshop|premiere|illustrator|chrome|brave|firefox|edge|tor|opera|vivaldi|waterfox|discord|telegram|whatsapp|slack|zoom|teams|skype|visual\s*studio|vs\s*code|vscode|code|antigravity|cursor|pycharm|clion|intellij|7-zip|winrar|winzip|peazip|anydesk|teamviewer|rustdesk|tightvnc|bitwarden|1password|keepass|proton|wisecleaner|ccleaner|bleachbit|revo\s*uninstaller|rufus|node|python|git|docker|notepad|sublime|postman|snappy\s*driver|everything|wiztree|treesize|afterburner|rtss|rivatuner|nvidia|armoury\s*crate|synapse|ghub|icue|signalrgb|translucenttb|system32|syswow64|powershell|cmd\.exe|windowsapps\\microsoft\.gaming|windowsapps\\microsoft\.xboxapp'
        try {
            $gameRoots = @("C:\Games", "D:\Games", "E:\Games", "F:\Games")
            foreach ($drive in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
                $r = Join-Path $drive.Root "Games"
                if (Test-Path $r) { $gameRoots += $r }
            }
            $gameRoots = $gameRoots | Select-Object -Unique

            foreach ($gr in $gameRoots) {
                if (Test-Path $gr) {
                    $subDirs = Get-ChildItem -Path $gr -Directory -ErrorAction SilentlyContinue
                    foreach ($sd in $subDirs) {
                        if ($sd.Name -match '(?i)Riot Games|Riot Client|Steam|Epic|Microsoft|Ubisoft|Launcher' -or $sd.Name -match $nonGameRegex) { continue }
                        
                        $mainExe = Find-GameMainExe $sd.FullName $sd.Name
                        if ($mainExe -and $seen.Add("Standalone_$($sd.FullName)")) {
                            $repackSource = Detect-RepackSource $sd.FullName $sd.Name
                            $style = Get-RepackPlatformStyle $repackSource

                            $item = [ZeroHub.GameItem]::new()
                            $item.Name = $sd.Name
                            $item.Platform = $style.Name
                            $item.PlatformColor = $style.Color
                            $item.PlatformBg = $style.Bg
                            $item.PlatformBorder = $style.Border
                            $item.InstallDir = $sd.FullName
                            $item.LaunchUri = $mainExe
                            $item.AppId = $sd.Name
                            $item.DisplaySize = ""
                            $item.BannerUrl = Get-GameCoverArt $style.Name "" $sd.Name $sd.FullName ""
                            $item.IsCustom = $false
                            $rawGames.Add($item)
                        }
                    }
                }
            }

            # Desktop Shortcuts (Fast check)
            $desktopPaths = @([Environment]::GetFolderPath("Desktop"), "C:\Users\Public\Desktop")
            $wsh = New-Object -ComObject WScript.Shell
            foreach ($dp in $desktopPaths) {
                if (Test-Path $dp) {
                    $lnks = Get-ChildItem -Path $dp -Filter "*.lnk" -ErrorAction SilentlyContinue
                    foreach ($l in $lnks) {
                        try {
                            $sh = $wsh.CreateShortcut($l.FullName)
                            $target = $sh.TargetPath
                            $gName = [System.IO.Path]::GetFileNameWithoutExtension($l.Name)
                            if ($target -and (Test-Path $target) -and $target.EndsWith(".exe")) {
                                $parent = [System.IO.Path]::GetDirectoryName($target)
                                if ($gName -match $nonGameRegex -or $target -match $nonGameRegex) { continue }

                                $isGameFolder = ($parent -match '(?i)games|steamapps|epic|repack|gog|fitgirl|dodi') -or 
                                    (Test-Path (Join-Path $parent "steam_api64.dll")) -or
                                    (Test-Path (Join-Path $parent "steam_api.dll")) -or
                                    (Test-Path (Join-Path $parent "UnityPlayer.dll"))

                                if ($isGameFolder -and $seen.Add("Standalone_$parent")) {
                                    $repackSource = Detect-RepackSource $parent $gName
                                    $style = Get-RepackPlatformStyle $repackSource

                                    $item = [ZeroHub.GameItem]::new()
                                    $item.Name = $gName
                                    $item.Platform = $style.Name
                                    $item.PlatformColor = $style.Color
                                    $item.PlatformBg = $style.Bg
                                    $item.PlatformBorder = $style.Border
                                    $item.InstallDir = $parent
                                    $item.LaunchUri = $target
                                    $item.AppId = $gName
                                    $item.BannerUrl = Get-GameCoverArt $style.Name "" $gName $parent ""
                                    $item.IsCustom = $false
                                    $rawGames.Add($item)
                                }
                            }
                        } catch {}
                    }
                }
            }
        } catch {}

        # 7. CUSTOM ADDED GAMES
        try {
            if (Test-Path $Script:CustomGamesFilePath) {
                $customJson = Get-Content $Script:CustomGamesFilePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($customJson) {
                    foreach ($cg in $customJson) {
                        if ($cg.Name -and $cg.LaunchUri) {
                            if ($seen.Add("Custom_$($cg.Name)")) {
                                $item = [ZeroHub.GameItem]::new()
                                $item.Name = [string]$cg.Name
                                $item.Platform = if ($cg.Platform) { [string]$cg.Platform } else { "Custom" }
                                $item.PlatformColor = "#FBBF24"
                                $item.PlatformBg = "#1E293B"
                                $item.PlatformBorder = "#D97706"
                                $item.InstallDir = [string]$cg.InstallDir
                                $item.LaunchUri = [string]$cg.LaunchUri
                                $item.BannerUrl = Get-GameCoverArt "Custom" "" [string]$cg.Name [string]$cg.InstallDir ""
                                $item.IsCustom = $true
                                $rawGames.Add($item)
                            }
                        }
                    }
                }
            }
        } catch {}

        # Sort Alphabetically
        $sorted = $rawGames | Sort-Object Name
        foreach ($g in $sorted) {
            $Script:AllGames.Add($g)
        }

        Update-GameSearchFilter
        Add-HubLog "Game Hub: Discovered $($Script:AllGames.Count) games across all platforms." "GAMEHUB"
    } catch {
        Add-HubLog "Error updating game library: $($_.Exception.Message)" "ERROR"
    }
}

