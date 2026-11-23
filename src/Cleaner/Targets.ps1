# Define Targets List (100% Login-Safe & Profile-Protected)
$TargetsData = @(
    # GPU Shaders
    @{ Id="gpu_nv_dx"; Name="NVIDIA shader cache (DXCache)"; Path="$env:LOCALAPPDATA\NVIDIA\DXCache"; Guard=@(); Cat="GPU"; Description="DirectX compiled shader cache for NVIDIA GPUs"; IsAdmin=$false }
    @{ Id="gpu_nv_gl"; Name="NVIDIA shader cache (GLCache)"; Path="$env:LOCALAPPDATA\NVIDIA\GLCache"; Guard=@(); Cat="GPU"; Description="OpenGL compiled shader cache for NVIDIA GPUs"; IsAdmin=$false }
    @{ Id="gpu_amd_dx"; Name="AMD shader cache (DxCache)"; Path="$env:LOCALAPPDATA\AMD\DxCache"; Guard=@(); Cat="GPU"; Description="DirectX compiled shader cache for AMD Radeon GPUs"; IsAdmin=$false }
    @{ Id="gpu_amd_gl"; Name="AMD shader cache (GLCache)"; Path="$env:LOCALAPPDATA\AMD\GLCache"; Guard=@(); Cat="GPU"; Description="OpenGL compiled shader cache for AMD Radeon GPUs"; IsAdmin=$false }
    @{ Id="gpu_intel"; Name="Intel GPU shader cache"; Path="$env:LOCALAPPDATA\Intel\ShaderCache"; Guard=@(); Cat="GPU"; Description="Intel Arc & Iris Xe compiled GPU shader cache"; IsAdmin=$false }
    @{ Id="gpu_d3d"; Name="DirectX D3D shader cache"; Path="$env:LOCALAPPDATA\D3DSCache"; Guard=@(); Cat="GPU"; Description="Direct3D global runtime shader cache"; IsAdmin=$false }

    # Developer & Build
    @{ Id="dev_npm"; Name="npm cache"; Path="$env:LOCALAPPDATA\npm-cache"; Guard=@('node'); Cat="Dev"; Description="Node Package Manager downloaded packages cache"; IsAdmin=$false }
    @{ Id="dev_pip"; Name="pip cache"; Path="$env:LOCALAPPDATA\pip\Cache"; Guard=@('python'); Cat="Dev"; Description="Python pip package wheels and tarballs cache"; IsAdmin=$false }
    @{ Id="dev_yarn"; Name="Yarn cache"; Path="$env:LOCALAPPDATA\Yarn\Cache"; Guard=@('yarn'); Cat="Dev"; Description="Yarn package manager global archive cache"; IsAdmin=$false }
    @{ Id="dev_pnpm"; Name="pnpm package cache"; Path="$env:LOCALAPPDATA\pnpm-cache"; Guard=@('pnpm'); Cat="Dev"; Description="pnpm global package cache"; IsAdmin=$false }
    @{ Id="dev_nuget"; Name="NuGet package cache"; Path="$env:LOCALAPPDATA\NuGet\v3-cache"; Guard=@(); Cat="Dev"; Description="Downloaded .NET & C# package archives"; IsAdmin=$false }
    @{ Id="dev_gradle"; Name="Gradle build cache"; Path="$env:USERPROFILE\.gradle\caches"; Guard=@('java'); Cat="Dev"; Description="Gradle build and dependency caches"; IsAdmin=$false }
    @{ Id="dev_maven"; Name="Maven repository cache"; Path="$env:USERPROFILE\.m2\repository\.cache"; Guard=@('java'); Cat="Dev"; Description="Maven dependency archive cache"; IsAdmin=$false }
    @{ Id="dev_android"; Name="Android build cache"; Path="$env:USERPROFILE\.android\build-cache"; Guard=@('adb'); Cat="Dev"; Description="Android SDK intermediate build cache"; IsAdmin=$false }
    @{ Id="dev_go"; Name="Go build cache"; Path="$env:LOCALAPPDATA\go-build"; Guard=@('go'); Cat="Dev"; Description="Golang compilation objects and dependency cache"; IsAdmin=$false }
    @{ Id="dev_cargo"; Name="Cargo / Rust registry cache"; Path="$env:USERPROFILE\.cargo\registry\cache"; Guard=@('cargo'); Cat="Dev"; Description="Rust crates.io package cache archives"; IsAdmin=$false }
    @{ Id="dev_vscode"; Name="VS Code cached data"; Path="$env:APPDATA\Code\CachedData"; Guard=@('Code'); Cat="Dev"; Description="Visual Studio Code UI cache and v8 bytecodes"; IsAdmin=$false }
    @{ Id="dev_jetbrains"; Name="JetBrains IDE caches"; Path="$env:LOCALAPPDATA\JetBrains\*\caches"; Guard=@(); Cat="Dev"; Description="IntelliJ, PyCharm, WebStorm, Rider index caches"; IsAdmin=$false }

    # Web Browsers
    @{ Id="br_chrome_cache"; Name="Google Chrome cache"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Guard=@('chrome'); Cat="Browser"; Description="Temporary images, web files (Keeps logins & cookies safe!)"; IsAdmin=$false }
    @{ Id="br_chrome_code"; Name="Google Chrome code cache"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"; Guard=@('chrome'); Cat="Browser"; Description="V8 Javascript compiled code cache"; IsAdmin=$false }
    @{ Id="br_chrome_gpu"; Name="Google Chrome GPU cache"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"; Guard=@('chrome'); Cat="Browser"; Description="Chromium GPU canvas and raster caches"; IsAdmin=$false }
    @{ Id="br_edge_cache"; Name="Microsoft Edge cache"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Guard=@('msedge'); Cat="Browser"; Description="Edge web cache (Keeps logins & cookies safe!)"; IsAdmin=$false }
    @{ Id="br_edge_code"; Name="Microsoft Edge code cache"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"; Guard=@('msedge'); Cat="Browser"; Description="Edge V8 Javascript compiled code cache"; IsAdmin=$false }
    @{ Id="br_brave_cache"; Name="Brave browser cache"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"; Guard=@('brave'); Cat="Browser"; Description="Brave temporary web cache"; IsAdmin=$false }
    @{ Id="br_brave_code"; Name="Brave code cache"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"; Guard=@('brave'); Cat="Browser"; Description="Brave V8 Javascript code cache"; IsAdmin=$false }
    @{ Id="br_arc"; Name="Arc browser cache"; Path="$env:LOCALAPPDATA\Arc\User Data\Default\Cache"; Guard=@('Arc'); Cat="Browser"; Description="Arc browser temporary web cache"; IsAdmin=$false }
    @{ Id="br_firefox"; Name="Mozilla Firefox cache"; Path="$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"; Guard=@('firefox'); Cat="Browser"; Description="Firefox web and media cache"; IsAdmin=$false }
    @{ Id="br_opera"; Name="Opera browser cache"; Path="$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache"; Guard=@('opera'); Cat="Browser"; Description="Opera web cache"; IsAdmin=$false }
    @{ Id="br_operagx"; Name="Opera GX browser cache"; Path="$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache"; Guard=@('opera'); Cat="Browser"; Description="Opera GX gaming browser cache"; IsAdmin=$false }
    @{ Id="br_vivaldi"; Name="Vivaldi browser cache"; Path="$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache"; Guard=@('vivaldi'); Cat="Browser"; Description="Vivaldi web cache"; IsAdmin=$false }
    @{ Id="br_chromium"; Name="Chromium browser cache"; Path="$env:LOCALAPPDATA\Chromium\User Data\Default\Cache"; Guard=@('chromium'); Cat="Browser"; Description="Chromium web cache"; IsAdmin=$false }
    @{ Id="br_chromium_code"; Name="Chromium code cache"; Path="$env:LOCALAPPDATA\Chromium\User Data\Default\Code Cache"; Guard=@('chromium'); Cat="Browser"; Description="Chromium code cache"; IsAdmin=$false }

    # Gaming & Launchers
    @{ Id="game_steam"; Name="Steam web cache"; Path="$env:LOCALAPPDATA\Steam\htmlcache"; Guard=@('steam'); Cat="Gaming"; Description="Steam store and community HTML web cache"; IsAdmin=$false }
    @{ Id="game_epic"; Name="Epic Games Launcher webcache"; Path="$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Guard=@('EpicGamesLauncher'); Cat="Gaming"; Description="Epic Games Launcher UI and store cache"; IsAdmin=$false }
    @{ Id="game_ea"; Name="EA Desktop app cache"; Path="$env:LOCALAPPDATA\Electronic Arts\EA Desktop\cache"; Guard=@('EADesktop'); Cat="Gaming"; Description="EA app downloads and thumbnail cache"; IsAdmin=$false }
    @{ Id="game_ubisoft"; Name="Ubisoft Connect cache"; Path="$env:LOCALAPPDATA\Ubisoft Game Launcher\cache"; Guard=@('upc'); Cat="Gaming"; Description="Ubisoft Connect launcher cache"; IsAdmin=$false }
    @{ Id="game_battlenet"; Name="Battle.net webcache"; Path="$env:LOCALAPPDATA\Battle.net\Cache"; Guard=@('Battle.net'); Cat="Gaming"; Description="Blizzard Battle.net store UI cache (Keeps logins safe)"; IsAdmin=$false }
    @{ Id="game_riot"; Name="Riot Games cache"; Path="$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Caches"; Guard=@('RiotClientServices'); Cat="Gaming"; Description="Riot Client / VALORANT / LoL webcache"; IsAdmin=$false }
    @{ Id="game_gog"; Name="GOG Galaxy webcache"; Path="$env:LOCALAPPDATA\GOG.com\Galaxy\webcache"; Guard=@('GalaxyClient'); Cat="Gaming"; Description="GOG Galaxy store and library webcache"; IsAdmin=$false }
    @{ Id="game_roblox"; Name="Roblox downloads & cache"; Path="$env:LOCALAPPDATA\Roblox\Downloads"; Guard=@('RobloxPlayerBeta'); Cat="Gaming"; Description="Roblox temporary texture assets and downloads"; IsAdmin=$false }

    # Social, Creative & Productivity
    @{ Id="soc_telegram"; Name="Telegram media cache"; Path="$env:APPDATA\Telegram Desktop\tdata\user_data\cache"; Guard=@('Telegram'); Cat="Social"; Description="Telegram cached media, stickers, videos"; IsAdmin=$false }
    @{ Id="soc_discord"; Name="Discord app cache"; Path="$env:APPDATA\discord\Cache"; Guard=@('Discord'); Cat="Social"; Description="Discord temporary images and voice attachments"; IsAdmin=$false }
    @{ Id="soc_discord_code"; Name="Discord code cache"; Path="$env:APPDATA\discord\Code Cache"; Guard=@('Discord'); Cat="Social"; Description="Discord Electron Javascript code cache"; IsAdmin=$false }
    @{ Id="soc_discord_canary"; Name="Discord Canary cache"; Path="$env:APPDATA\discordcanary\Cache"; Guard=@('DiscordCanary'); Cat="Social"; Description="Discord Canary test client cache"; IsAdmin=$false }
    @{ Id="soc_discord_ptb"; Name="Discord PTB cache"; Path="$env:APPDATA\discordptb\Cache"; Guard=@('DiscordPTB'); Cat="Social"; Description="Discord Public Test Build cache"; IsAdmin=$false }
    @{ Id="soc_slack"; Name="Slack cache"; Path="$env:APPDATA\Slack\Cache"; Guard=@('slack'); Cat="Social"; Description="Slack messaging app image/file cache"; IsAdmin=$false }
    @{ Id="soc_teams"; Name="Microsoft Teams cache"; Path="$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache"; Guard=@('ms-teams'); Cat="Social"; Description="New Microsoft Teams temporary local cache"; IsAdmin=$false }
    @{ Id="soc_notion"; Name="Notion app cache"; Path="$env:APPDATA\Notion\Cache"; Guard=@('Notion'); Cat="Social"; Description="Notion desktop local workspace cache"; IsAdmin=$false }
    @{ Id="soc_figma"; Name="Figma app cache"; Path="$env:APPDATA\Figma\Cache"; Guard=@('Figma'); Cat="Social"; Description="Figma desktop canvas asset cache"; IsAdmin=$false }
    @{ Id="soc_obsidian"; Name="Obsidian app cache"; Path="$env:APPDATA\Obsidian\Cache"; Guard=@('Obsidian'); Cat="Social"; Description="Obsidian Markdown editor cache"; IsAdmin=$false }
    @{ Id="soc_postman"; Name="Postman app cache"; Path="$env:APPDATA\Postman\Cache"; Guard=@('Postman'); Cat="Social"; Description="Postman API client internal cache"; IsAdmin=$false }
    @{ Id="soc_spotify"; Name="Spotify audio storage"; Path="$env:LOCALAPPDATA\Spotify\Storage"; Guard=@('Spotify'); Cat="Social"; Description="Spotify streamed songs offline storage cache"; IsAdmin=$false }
    @{ Id="soc_adobe"; Name="Adobe Media cache"; Path="$env:APPDATA\Adobe\Common\Media Cache Files"; Guard=@(); Cat="Social"; Description="Adobe Premiere / After Effects peak and render files"; IsAdmin=$false }
    @{ Id="soc_davinci"; Name="DaVinci Resolve cache"; Path="$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Cache"; Guard=@('Resolve'); Cat="Social"; Description="Temporary video waveform peaks & proxy renders"; IsAdmin=$false }
    @{ Id="soc_blender"; Name="Blender render cache"; Path="$env:LOCALAPPDATA\Blender Foundation\Blender\Cache"; Guard=@('blender'); Cat="Social"; Description="Blender temporary rendering cache files"; IsAdmin=$false }
    @{ Id="soc_obs"; Name="OBS Studio browser cache"; Path="$env:APPDATA\obs-studio\plugin_config\obs-browser"; Guard=@('obs64'); Cat="Social"; Description="OBS Studio browser source overlay cache"; IsAdmin=$false }
    @{ Id="soc_vlc"; Name="VLC media art cache"; Path="$env:APPDATA\vlc\art"; Guard=@('vlc'); Cat="Social"; Description="VLC album artwork and thumbnail cache"; IsAdmin=$false }

    # System & Temp (User level)
    @{ Id="sys_recycle_bin"; Name="Windows Recycle Bin"; Path="VIRTUAL:RECYCLEBIN"; Guard=@(); Cat="System"; Description="Empties deleted files from Windows Recycle Bin across all drives"; IsAdmin=$false }
    @{ Id="sys_dns_cache"; Name="DNS Resolver Cache (Flush DNS)"; Path="VIRTUAL:DNSCACHE"; Guard=@(); Cat="System"; Description="Flushes stale domain name lookup cache to fix network and browsing"; IsAdmin=$false }
    @{ Id="sys_user_temp"; Name="Windows user temp (%TEMP%)"; Path="$env:LOCALAPPDATA\Temp"; Guard=@(); Cat="System"; Description="User application temporary files and session junk"; IsAdmin=$false }
    @{ Id="adm_cryptnet"; Name="Cryptnet SSL URL cache"; Path="$env:LOCALAPPDATA\Microsoft\CryptnetUrlCache\Content"; Guard=@(); Cat="System"; Description="Windows expired certificate revocation cache"; IsAdmin=$false }

    # System & Admin Targets
    @{ Id="adm_win_upd"; Name="Windows Update installer downloads"; Path="C:\Windows\SoftwareDistribution\Download"; Guard=@(); Cat="System"; Description="Downloaded Windows Update installer CAB and ESD files"; IsAdmin=$true }
    @{ Id="adm_deliv_opt"; Name="Delivery Optimization update cache"; Path="C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"; Guard=@(); Cat="System"; Description="P2P Windows update delivery cache files"; IsAdmin=$true }
    @{ Id="adm_wer_logs"; Name="Windows Error Reporting crash logs"; Path="C:\ProgramData\Microsoft\Windows\WER\ReportArchive"; Guard=@(); Cat="System"; Description="Archived Windows error and crash dump reports"; IsAdmin=$true }
    @{ Id="adm_minidump"; Name="Windows BSOD crash memory dumps"; Path="C:\Windows\Minidump"; Guard=@(); Cat="System"; Description="Archived Blue Screen of Death memory dumps"; IsAdmin=$true }
    @{ Id="adm_nvidia_app"; Name="NVIDIA App update leftovers"; Path="C:\ProgramData\NVIDIA Corporation\NVIDIA App\UpdateFramework\ota-artifacts"; Guard=@(); Cat="System"; Description="NVIDIA App downloaded driver packages and updates"; IsAdmin=$true }
    @{ Id="adm_driver_booster"; Name="Old driver backups (Driver Booster)"; Path="C:\ProgramData\IObitDriverBooster\Drivers"; Guard=@(); Cat="System"; Description="Legacy driver installation packages"; IsAdmin=$true }
    @{ Id="adm_sys_temp"; Name="Windows system temp (C:\Windows\Temp)"; Path="C:\Windows\Temp"; Guard=@(); Cat="System"; Description="System-level temporary files and installer artifacts"; IsAdmin=$true }
)

