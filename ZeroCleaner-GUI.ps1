[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Compile Data Models with zero warnings
Add-Type -ReferencedAssemblies PresentationFramework, PresentationCore, WindowsBase, System.Xaml -TypeDefinition @'
#pragma warning disable 0067, 0649
using System;
using System.ComponentModel;
using System.Windows.Controls;

namespace ZeroCleaner {
    public class TargetItem : INotifyPropertyChanged {
        public string Id { get; set; }
        public string Name { get; set; }
        public string NameAr { get; set; }
        public string Path { get; set; }
        public string Cat { get; set; }
        public string Description { get; set; }
        public string DescriptionAr { get; set; }
        public string[] Guard { get; set; }
        public bool IsAdmin { get; set; }
        
        private bool _isSelected;
        public bool IsSelected {
            get { return _isSelected; }
            set {
                if (_isSelected != value) {
                    _isSelected = value;
                    OnPropertyChanged("IsSelected");
                }
            }
        }

        private double _sizeMB;
        public double SizeMB {
            get { return _sizeMB; }
            set {
                _sizeMB = value;
                OnPropertyChanged("SizeMB");
            }
        }

        private string _sizeFormatted;
        public string SizeFormatted {
            get { return _sizeFormatted; }
            set {
                _sizeFormatted = value;
                OnPropertyChanged("SizeFormatted");
            }
        }

        private string _status;
        public string Status {
            get { return _status; }
            set {
                _status = value;
                OnPropertyChanged("Status");
            }
        }

        public CheckBox CheckBoxControl { get; set; }
        public TextBlock SizeLabel { get; set; }

        public TargetItem() {
            _sizeMB = 0;
            _sizeFormatted = "Not Scanned";
            _status = "Pending Scan";
            _isSelected = false;
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    public class ProcessItem {
        public string Name { get; set; }
        public int Id { get; set; }
        public string TargetName { get; set; }
        public string Status { get; set; }
        public string MainWindowTitle { get; set; }
    }

    public static class NativeMethods {
        [System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        public static extern bool MoveFileEx(string lpExistingFileName, string lpNewFileName, int dwFlags);
        public const int MOVEFILE_DELAY_UNTIL_REBOOT = 0x00000004;

        [System.Runtime.InteropServices.DllImport("psapi.dll")]
        public static extern int EmptyWorkingSet(IntPtr hwProc);

        public static bool ScheduleDeleteOnReboot(string path) {
            try {
                return MoveFileEx(path, null, MOVEFILE_DELAY_UNTIL_REBOOT);
            } catch {
                return false;
            }
        }

        public static int OptimizeProcessesRam() {
            int count = 0;
            System.Diagnostics.Process[] procs = System.Diagnostics.Process.GetProcesses();
            foreach (System.Diagnostics.Process p in procs) {
                try {
                    if (!p.HasExited && p.Id != 0 && p.Id != 4) {
                        EmptyWorkingSet(p.Handle);
                        count++;
                    }
                } catch {}
            }
            try {
                GC.Collect();
                GC.WaitForPendingFinalizers();
            } catch {}
            return count;
        }
    }
}
'@

# Auto-Elevate to Administrator (Chris Titus Tech WinUtil Style)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "powershell.exe"
        $processInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $processInfo.Verb = "runas"
        $proc = [System.Diagnostics.Process]::Start($processInfo)
        if ($proc) { exit }
    } catch {
        # User clicked 'No' on UAC prompt - continue gracefully in Standard User mode
    }
}

# Define Targets List (100% Login-Safe & Profile-Protected)
$TargetsData = @(
    # GPU Shaders
    @{ Id="gpu_nv_dx"; Name="NVIDIA shader cache (DXCache)"; NameAr="كاش مظللات NVIDIA (DirectX)"; Path="$env:LOCALAPPDATA\NVIDIA\DXCache"; Guard=@(); Cat="GPU"; Description="DirectX compiled shader cache for NVIDIA GPUs"; DescriptionAr="كاش المظللات المترجمة لـ DirectX لكروت نفيديا"; IsAdmin=$false }
    @{ Id="gpu_nv_gl"; Name="NVIDIA shader cache (GLCache)"; NameAr="كاش مظللات NVIDIA (OpenGL)"; Path="$env:LOCALAPPDATA\NVIDIA\GLCache"; Guard=@(); Cat="GPU"; Description="OpenGL compiled shader cache for NVIDIA GPUs"; DescriptionAr="كاش المظللات المترجمة لـ OpenGL لكروت نفيديا"; IsAdmin=$false }
    @{ Id="gpu_amd_dx"; Name="AMD shader cache (DxCache)"; NameAr="كاش مظللات AMD (DirectX)"; Path="$env:LOCALAPPDATA\AMD\DxCache"; Guard=@(); Cat="GPU"; Description="DirectX compiled shader cache for AMD Radeon GPUs"; DescriptionAr="كاش المظللات المترجمة لـ DirectX لكروت AMD"; IsAdmin=$false }
    @{ Id="gpu_amd_gl"; Name="AMD shader cache (GLCache)"; NameAr="كاش مظللات AMD (OpenGL)"; Path="$env:LOCALAPPDATA\AMD\GLCache"; Guard=@(); Cat="GPU"; Description="OpenGL compiled shader cache for AMD Radeon GPUs"; DescriptionAr="كاش المظللات المترجمة لـ OpenGL لكروت AMD"; IsAdmin=$false }
    @{ Id="gpu_intel"; Name="Intel GPU shader cache"; NameAr="كاش مظللات كروت Intel"; Path="$env:LOCALAPPDATA\Intel\ShaderCache"; Guard=@(); Cat="GPU"; Description="Intel Arc & Iris Xe compiled GPU shader cache"; DescriptionAr="كاش المظللات لكروت شاشة Intel Arc و Iris"; IsAdmin=$false }
    @{ Id="gpu_d3d"; Name="DirectX D3D shader cache"; NameAr="كاش مظللات DirectX العام"; Path="$env:LOCALAPPDATA\D3DSCache"; Guard=@(); Cat="GPU"; Description="Direct3D global runtime shader cache"; DescriptionAr="كاش المظللات العام لنظام DirectX D3D"; IsAdmin=$false }

    # Developer & Build
    @{ Id="dev_npm"; Name="npm cache"; NameAr="كاش حزم npm"; Path="$env:LOCALAPPDATA\npm-cache"; Guard=@('node'); Cat="Dev"; Description="Node Package Manager downloaded packages cache"; DescriptionAr="أرشيف الحزم المحملة لـ Node.js"; IsAdmin=$false }
    @{ Id="dev_pip"; Name="pip cache"; NameAr="كاش حزم Python pip"; Path="$env:LOCALAPPDATA\pip\Cache"; Guard=@('python'); Cat="Dev"; Description="Python pip package wheels and tarballs cache"; DescriptionAr="أرشيف حزم بايثون المحملة عبر pip"; IsAdmin=$false }
    @{ Id="dev_yarn"; Name="Yarn cache"; NameAr="كاش حزم Yarn"; Path="$env:LOCALAPPDATA\Yarn\Cache"; Guard=@('yarn'); Cat="Dev"; Description="Yarn package manager global archive cache"; DescriptionAr="أرشيف حزم مدير الحزم Yarn"; IsAdmin=$false }
    @{ Id="dev_pnpm"; Name="pnpm package cache"; NameAr="كاش حزم pnpm"; Path="$env:LOCALAPPDATA\pnpm-cache"; Guard=@('pnpm'); Cat="Dev"; Description="pnpm global package cache"; DescriptionAr="أرشيف التخزين العام لمدير حزم pnpm"; IsAdmin=$false }
    @{ Id="dev_nuget"; Name="NuGet package cache"; NameAr="كاش حزم NuGet (.NET)"; Path="$env:LOCALAPPDATA\NuGet\v3-cache"; Guard=@(); Cat="Dev"; Description="Downloaded .NET & C# package archives"; DescriptionAr="أرشيف حزم دوت نت و C# المحملة"; IsAdmin=$false }
    @{ Id="dev_gradle"; Name="Gradle build cache"; NameAr="كاش بناء Gradle (Android/Java)"; Path="$env:USERPROFILE\.gradle\caches"; Guard=@('java'); Cat="Dev"; Description="Gradle build and dependency caches"; DescriptionAr="كاش تبعيات وبناء مشاريع جافا وأندرويد"; IsAdmin=$false }
    @{ Id="dev_maven"; Name="Maven repository cache"; NameAr="كاش مستودع Maven"; Path="$env:USERPROFILE\.m2\repository\.cache"; Guard=@('java'); Cat="Dev"; Description="Maven dependency archive cache"; DescriptionAr="كاش التبعيات لمستودع ميفن المحلي"; IsAdmin=$false }
    @{ Id="dev_android"; Name="Android build cache"; NameAr="كاش بناء أندرويد SDK"; Path="$env:USERPROFILE\.android\build-cache"; Guard=@('adb'); Cat="Dev"; Description="Android SDK intermediate build cache"; DescriptionAr="الملفات الوسيطة لبناء تطبيقات أندرويد"; IsAdmin=$false }
    @{ Id="dev_go"; Name="Go build cache"; NameAr="كاش بناء لغة Go"; Path="$env:LOCALAPPDATA\go-build"; Guard=@('go'); Cat="Dev"; Description="Golang compilation objects and dependency cache"; DescriptionAr="ملفات تصريف لغة غولانغ المؤقتة"; IsAdmin=$false }
    @{ Id="dev_cargo"; Name="Cargo / Rust registry cache"; NameAr="كاش حزم Rust / Cargo"; Path="$env:USERPROFILE\.cargo\registry\cache"; Guard=@('cargo'); Cat="Dev"; Description="Rust crates.io package cache archives"; DescriptionAr="أرشيف حزم لغة رست crates.io"; IsAdmin=$false }
    @{ Id="dev_vscode"; Name="VS Code cached data"; NameAr="كاش بيانات VS Code"; Path="$env:APPDATA\Code\CachedData"; Guard=@('Code'); Cat="Dev"; Description="Visual Studio Code UI cache and v8 bytecodes"; DescriptionAr="كاش واجهة وتصريف محرر فيجوال ستوديو كود"; IsAdmin=$false }
    @{ Id="dev_jetbrains"; Name="JetBrains IDE caches"; NameAr="كاش بيئات JetBrains"; Path="$env:LOCALAPPDATA\JetBrains\*\caches"; Guard=@(); Cat="Dev"; Description="IntelliJ, PyCharm, WebStorm, Rider index caches"; DescriptionAr="كاش الفهرسة لبرامج بايتشارم وإنتيليج ورايدر"; IsAdmin=$false }

    # Web Browsers
    @{ Id="br_chrome_cache"; Name="Google Chrome cache"; NameAr="كاش متصفح Google Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Guard=@('chrome'); Cat="Browser"; Description="Temporary images, web files (Keeps logins & cookies safe!)"; DescriptionAr="الصور وملفات الويب المؤقتة (الحسابات وكلمات السر محمية!)"; IsAdmin=$false }
    @{ Id="br_chrome_code"; Name="Google Chrome code cache"; NameAr="كاش كود Chrome (V8)"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"; Guard=@('chrome'); Cat="Browser"; Description="V8 Javascript compiled code cache"; DescriptionAr="كاش كود الجافاسكربت المترجم في كروم"; IsAdmin=$false }
    @{ Id="br_chrome_gpu"; Name="Google Chrome GPU cache"; NameAr="كاش كرت الشاشة لـ Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache"; Guard=@('chrome'); Cat="Browser"; Description="Chromium GPU canvas and raster caches"; DescriptionAr="كاش تسريع الرسوميات لمتصفح كروم"; IsAdmin=$false }
    @{ Id="br_edge_cache"; Name="Microsoft Edge cache"; NameAr="كاش متصفح Microsoft Edge"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"; Guard=@('msedge'); Cat="Browser"; Description="Edge web cache (Keeps logins & cookies safe!)"; DescriptionAr="كاش صفحات الويب لمتصفح إيدج (الحسابات محمية!)"; IsAdmin=$false }
    @{ Id="br_edge_code"; Name="Microsoft Edge code cache"; NameAr="كاش كود Edge (V8)"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"; Guard=@('msedge'); Cat="Browser"; Description="Edge V8 Javascript compiled code cache"; DescriptionAr="كاش كود الجافاسكربت المترجم في إيدج"; IsAdmin=$false }
    @{ Id="br_brave_cache"; Name="Brave browser cache"; NameAr="كاش متصفح Brave"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"; Guard=@('brave'); Cat="Browser"; Description="Brave temporary web cache"; DescriptionAr="كاش صفحات الويب المؤقتة لمتصفح بريف"; IsAdmin=$false }
    @{ Id="br_brave_code"; Name="Brave code cache"; NameAr="كاش كود Brave (V8)"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"; Guard=@('brave'); Cat="Browser"; Description="Brave V8 Javascript code cache"; DescriptionAr="كاش كود الجافاسكربت لمتصفح بريف"; IsAdmin=$false }
    @{ Id="br_arc"; Name="Arc browser cache"; NameAr="كاش متصفح Arc"; Path="$env:LOCALAPPDATA\Arc\User Data\Default\Cache"; Guard=@('Arc'); Cat="Browser"; Description="Arc browser temporary web cache"; DescriptionAr="كاش صفحات الويب المؤقتة لمتصفح آرك"; IsAdmin=$false }
    @{ Id="br_firefox"; Name="Mozilla Firefox cache"; NameAr="كاش متصفح Mozilla Firefox"; Path="$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"; Guard=@('firefox'); Cat="Browser"; Description="Firefox web and media cache"; DescriptionAr="كاش الويب والوسائط لمتصفح فايرفوكس"; IsAdmin=$false }
    @{ Id="br_opera"; Name="Opera browser cache"; NameAr="كاش متصفح Opera"; Path="$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache"; Guard=@('opera'); Cat="Browser"; Description="Opera web cache"; DescriptionAr="كاش صفحات الويب لمتصفح أوبرا"; IsAdmin=$false }
    @{ Id="br_operagx"; Name="Opera GX browser cache"; NameAr="كاش متصفح Opera GX للألعاب"; Path="$env:LOCALAPPDATA\Opera Software\Opera GX Stable\Cache"; Guard=@('opera'); Cat="Browser"; Description="Opera GX gaming browser cache"; DescriptionAr="كاش صفحات الويب لمتصفح أوبرا جي إكس"; IsAdmin=$false }
    @{ Id="br_vivaldi"; Name="Vivaldi browser cache"; NameAr="كاش متصفح Vivaldi"; Path="$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache"; Guard=@('vivaldi'); Cat="Browser"; Description="Vivaldi web cache"; DescriptionAr="كاش الويب المؤقت لمتصفح فيفالدي"; IsAdmin=$false }
    @{ Id="br_chromium"; Name="Chromium browser cache"; NameAr="كاش متصفح Chromium"; Path="$env:LOCALAPPDATA\Chromium\User Data\Default\Cache"; Guard=@('chromium'); Cat="Browser"; Description="Chromium web cache"; DescriptionAr="كاش صفحات الويب لمتصفح كروميوم"; IsAdmin=$false }
    @{ Id="br_chromium_code"; Name="Chromium code cache"; NameAr="كاش كود Chromium"; Path="$env:LOCALAPPDATA\Chromium\User Data\Default\Code Cache"; Guard=@('chromium'); Cat="Browser"; Description="Chromium code cache"; DescriptionAr="كاش كود الجافاسكربت لكروميوم"; IsAdmin=$false }

    # Gaming & Launchers
    @{ Id="game_steam"; Name="Steam web cache"; NameAr="كاش متصفح متجر Steam"; Path="$env:LOCALAPPDATA\Steam\htmlcache"; Guard=@('steam'); Cat="Gaming"; Description="Steam store and community HTML web cache"; DescriptionAr="كاش صفحات متجر ومجتمع ستيم"; IsAdmin=$false }
    @{ Id="game_epic"; Name="Epic Games Launcher webcache"; NameAr="كاش مشغل Epic Games"; Path="$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"; Guard=@('EpicGamesLauncher'); Cat="Gaming"; Description="Epic Games Launcher UI and store cache"; DescriptionAr="كاش واجهة ومتجر إيبك غيمز"; IsAdmin=$false }
    @{ Id="game_ea"; Name="EA Desktop app cache"; NameAr="كاش تطبيق EA Desktop"; Path="$env:LOCALAPPDATA\Electronic Arts\EA Desktop\cache"; Guard=@('EADesktop'); Cat="Gaming"; Description="EA app downloads and thumbnail cache"; DescriptionAr="كاش الصور المصغرة والتحميلات لبرنامج EA"; IsAdmin=$false }
    @{ Id="game_ubisoft"; Name="Ubisoft Connect cache"; NameAr="كاش مشغل Ubisoft Connect"; Path="$env:LOCALAPPDATA\Ubisoft Game Launcher\cache"; Guard=@('upc'); Cat="Gaming"; Description="Ubisoft Connect launcher cache"; DescriptionAr="كاش مشغل ألعاب يوبيسوفت"; IsAdmin=$false }
    @{ Id="game_battlenet"; Name="Battle.net webcache"; NameAr="كاش مشغل Battle.net (Blizzard)"; Path="$env:LOCALAPPDATA\Battle.net\Cache"; Guard=@('Battle.net'); Cat="Gaming"; Description="Blizzard Battle.net store UI cache (Keeps logins safe)"; DescriptionAr="كاش واجهة متجر بليزارد باتل نت (الحسابات محمية)"; IsAdmin=$false }
    @{ Id="game_riot"; Name="Riot Games cache"; NameAr="كاش مشغل Riot Games / LoL / VALORANT"; Path="$env:LOCALAPPDATA\Riot Games\Riot Client\Data\Caches"; Guard=@('RiotClientServices'); Cat="Gaming"; Description="Riot Client / VALORANT / LoL webcache"; DescriptionAr="كاش مشغل رايوت غيمز وفالورانت وليغ أوف ليجندز"; IsAdmin=$false }
    @{ Id="game_gog"; Name="GOG Galaxy webcache"; NameAr="كاش مشغل GOG Galaxy"; Path="$env:LOCALAPPDATA\GOG.com\Galaxy\webcache"; Guard=@('GalaxyClient'); Cat="Gaming"; Description="GOG Galaxy store and library webcache"; DescriptionAr="كاش متجر ومكتبة ألعاب GOG غالاكسي"; IsAdmin=$false }
    @{ Id="game_roblox"; Name="Roblox downloads & cache"; NameAr="كاش وتحميلات Roblox"; Path="$env:LOCALAPPDATA\Roblox\Downloads"; Guard=@('RobloxPlayerBeta'); Cat="Gaming"; Description="Roblox temporary texture assets and downloads"; DescriptionAr="الملفات المؤقتة والخامات المحملة للعبة روبلوكس"; IsAdmin=$false }

    # Social, Creative & Productivity
    @{ Id="soc_telegram"; Name="Telegram media cache"; NameAr="كاش وسائط Telegram"; Path="$env:APPDATA\Telegram Desktop\tdata\user_data\cache"; Guard=@('Telegram'); Cat="Social"; Description="Telegram cached media, stickers, videos"; DescriptionAr="الملفات المؤقتة والملصقات والفيديوهات المحملة في تيليجرام"; IsAdmin=$false }
    @{ Id="soc_discord"; Name="Discord app cache"; NameAr="كاش صور ومرفقات Discord"; Path="$env:APPDATA\discord\Cache"; Guard=@('Discord'); Cat="Social"; Description="Discord temporary images and voice attachments"; DescriptionAr="الصور والمرفقات المؤقتة لتطبيق ديسكورد"; IsAdmin=$false }
    @{ Id="soc_discord_code"; Name="Discord code cache"; NameAr="كاش كود Discord"; Path="$env:APPDATA\discord\Code Cache"; Guard=@('Discord'); Cat="Social"; Description="Discord Electron Javascript code cache"; DescriptionAr="كاش كود جافاسكربت المشغل لديسكورد"; IsAdmin=$false }
    @{ Id="soc_discord_canary"; Name="Discord Canary cache"; NameAr="كاش Discord Canary التجريبي"; Path="$env:APPDATA\discordcanary\Cache"; Guard=@('DiscordCanary'); Cat="Social"; Description="Discord Canary test client cache"; DescriptionAr="كاش النسخة التجريبية لديسكورد كاناري"; IsAdmin=$false }
    @{ Id="soc_discord_ptb"; Name="Discord PTB cache"; NameAr="كاش Discord PTB"; Path="$env:APPDATA\discordptb\Cache"; Guard=@('DiscordPTB'); Cat="Social"; Description="Discord Public Test Build cache"; DescriptionAr="كاش نسخة الاختبار العامة لديسكورد PTB"; IsAdmin=$false }
    @{ Id="soc_slack"; Name="Slack cache"; NameAr="كاش تطبيق Slack"; Path="$env:APPDATA\Slack\Cache"; Guard=@('slack'); Cat="Social"; Description="Slack messaging app image/file cache"; DescriptionAr="كاش الصور والملفات المؤقتة لتطبيق سلاك"; IsAdmin=$false }
    @{ Id="soc_teams"; Name="Microsoft Teams cache"; NameAr="كاش Microsoft Teams"; Path="$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache"; Guard=@('ms-teams'); Cat="Social"; Description="New Microsoft Teams temporary local cache"; DescriptionAr="كاش تطبيق مايكروسوفت تيمز المحلي"; IsAdmin=$false }
    @{ Id="soc_notion"; Name="Notion app cache"; NameAr="كاش تطبيق Notion"; Path="$env:APPDATA\Notion\Cache"; Guard=@('Notion'); Cat="Social"; Description="Notion desktop local workspace cache"; DescriptionAr="كاش مساحات العمل المحلية لبرنامج نوشن"; IsAdmin=$false }
    @{ Id="soc_figma"; Name="Figma app cache"; NameAr="كاش تطبيق Figma"; Path="$env:APPDATA\Figma\Cache"; Guard=@('Figma'); Cat="Social"; Description="Figma desktop canvas asset cache"; DescriptionAr="كاش خامات وتصاميم فيجما المؤقتة"; IsAdmin=$false }
    @{ Id="soc_obsidian"; Name="Obsidian app cache"; NameAr="كاش محرر Obsidian"; Path="$env:APPDATA\Obsidian\Cache"; Guard=@('Obsidian'); Cat="Social"; Description="Obsidian Markdown editor cache"; DescriptionAr="كاش محرر الملاحظات أوبسيديان"; IsAdmin=$false }
    @{ Id="soc_postman"; Name="Postman app cache"; NameAr="كاش تطبيق Postman"; Path="$env:APPDATA\Postman\Cache"; Guard=@('Postman'); Cat="Social"; Description="Postman API client internal cache"; DescriptionAr="الكاش الداخلي لبرنامج اختبار الـ API بوستمان"; IsAdmin=$false }
    @{ Id="soc_spotify"; Name="Spotify audio storage"; NameAr="تخزين أغاني Spotify المؤقت"; Path="$env:LOCALAPPDATA\Spotify\Storage"; Guard=@('Spotify'); Cat="Social"; Description="Spotify streamed songs offline storage cache"; DescriptionAr="كاش الأغاني والمقاطع المسموعة بدون إنترنت لسبوتيفاي"; IsAdmin=$false }
    @{ Id="soc_adobe"; Name="Adobe Media cache"; NameAr="كاش وسائط Adobe (Premiere/AE)"; Path="$env:APPDATA\Adobe\Common\Media Cache Files"; Guard=@(); Cat="Social"; Description="Adobe Premiere / After Effects peak and render files"; DescriptionAr="ملفات الريندر والمعاينة لبرامج أدوبي بريمير وأفتر إفكتس"; IsAdmin=$false }
    @{ Id="soc_davinci"; Name="DaVinci Resolve cache"; NameAr="كاش ريندر DaVinci Resolve"; Path="$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Cache"; Guard=@('Resolve'); Cat="Social"; Description="Temporary video waveform peaks & proxy renders"; DescriptionAr="ملفات البروكسي وريندر الفيديو لبرنامج دافينشي ريزولف"; IsAdmin=$false }
    @{ Id="soc_blender"; Name="Blender render cache"; NameAr="كاش ريندر Blender"; Path="$env:LOCALAPPDATA\Blender Foundation\Blender\Cache"; Guard=@('blender'); Cat="Social"; Description="Blender temporary rendering cache files"; DescriptionAr="ملفات الريندر المؤقتة لبرنامج التصميم ثلاثي الأبعاد بلندر"; IsAdmin=$false }
    @{ Id="soc_obs"; Name="OBS Studio browser cache"; NameAr="كاش مصادر الويب لـ OBS Studio"; Path="$env:APPDATA\obs-studio\plugin_config\obs-browser"; Guard=@('obs64'); Cat="Social"; Description="OBS Studio browser source overlay cache"; DescriptionAr="كاش تراكبات الويب ومصادر المتصفح لبرنامج البث OBS"; IsAdmin=$false }
    @{ Id="soc_vlc"; Name="VLC media art cache"; NameAr="كاش أغلفة وصور VLC"; Path="$env:APPDATA\vlc\art"; Guard=@('vlc'); Cat="Social"; Description="VLC album artwork and thumbnail cache"; DescriptionAr="الصور المصغرة وأغلفة الألبومات لمشغل الوسائط VLC"; IsAdmin=$false }

    # System & Temp (User level)
    @{ Id="sys_recycle_bin"; Name="Windows Recycle Bin"; NameAr="سلة محذوفات ويندوز (Recycle Bin)"; Path="VIRTUAL:RECYCLEBIN"; Guard=@(); Cat="System"; Description="Empties deleted files from Windows Recycle Bin across all drives"; DescriptionAr="تفريغ سلة المحذوفات وحذف الملفات المهملة نهائياً"; IsAdmin=$false }
    @{ Id="sys_dns_cache"; Name="DNS Resolver Cache (Flush DNS)"; NameAr="كاش خادم الأسماء DNS (Flush DNS)"; Path="VIRTUAL:DNSCACHE"; Guard=@(); Cat="System"; Description="Flushes stale domain name lookup cache to fix network and browsing"; DescriptionAr="تفريغ كاش عناوين النطاقات وتسريع استجابة التصفح"; IsAdmin=$false }
    @{ Id="sys_user_temp"; Name="Windows user temp (%TEMP%)"; NameAr="الملفات المؤقتة للمستخدم (%TEMP%)"; Path="$env:LOCALAPPDATA\Temp"; Guard=@('nvcontainer'); Cat="System"; Description="User application temporary files and session junk"; DescriptionAr="الملفات المؤقتة وبقايا البرامج في مجلد المستخدم"; IsAdmin=$false }
    @{ Id="adm_cryptnet"; Name="Cryptnet SSL URL cache"; NameAr="كاش شهادات الأمان Cryptnet SSL"; Path="$env:LOCALAPPDATA\Microsoft\CryptnetUrlCache\Content"; Guard=@(); Cat="System"; Description="Windows expired certificate revocation cache"; DescriptionAr="كاش فحص إلغاء شهادات الأمان المنتهية في ويندوز"; IsAdmin=$false }

    # System & Admin Targets
    @{ Id="adm_win_upd"; Name="Windows Update installer downloads"; NameAr="تحميلات تحديثات ويندوز (SoftwareDistribution)"; Path="C:\Windows\SoftwareDistribution\Download"; Guard=@(); Cat="System"; Description="Downloaded Windows Update installer CAB and ESD files"; DescriptionAr="ملفات حزم تحديثات ويندوز المحملة بعد التثبيت"; IsAdmin=$true }
    @{ Id="adm_deliv_opt"; Name="Delivery Optimization update cache"; NameAr="كاش تحسين تسليم التحديثات (P2P)"; Path="C:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache"; Guard=@(); Cat="System"; Description="P2P Windows update delivery cache files"; DescriptionAr="كاش مشاركة التحديثات عبر الشبكة المحلية"; IsAdmin=$true }
    @{ Id="adm_wer_logs"; Name="Windows Error Reporting crash logs"; NameAr="تقارير أخطاء وانهيار ويندوز (WER)"; Path="C:\ProgramData\Microsoft\Windows\WER\ReportArchive"; Guard=@(); Cat="System"; Description="Archived Windows error and crash dump reports"; DescriptionAr="أرشيف تقارير ومخلفات الأخطاء المسجلة في النظام"; IsAdmin=$true }
    @{ Id="adm_minidump"; Name="Windows BSOD crash memory dumps"; NameAr="تفريغ ذاكرة الشاشة الزرقاء (Minidump)"; Path="C:\Windows\Minidump"; Guard=@(); Cat="System"; Description="Archived Blue Screen of Death memory dumps"; DescriptionAr="ملفات تفريغ الذاكرة المحفوظة بعد انهيار النظام والشاشة الزرقاء"; IsAdmin=$true }
    @{ Id="adm_nvidia_app"; Name="NVIDIA App update leftovers"; NameAr="بقايا تحديثات تطبيق NVIDIA App"; Path="C:\ProgramData\NVIDIA Corporation\NVIDIA App\UpdateFramework\ota-artifacts"; Guard=@(); Cat="System"; Description="NVIDIA App downloaded driver packages and updates"; DescriptionAr="حزم تعاريف كروت نفيديا المحملة عبر تطبيق NVIDIA App"; IsAdmin=$true }
    @{ Id="adm_driver_booster"; Name="Old driver backups (Driver Booster)"; NameAr="النسخ الاحتياطية القديمة للتعاريف"; Path="C:\ProgramData\IObitDriverBooster\Drivers"; Guard=@(); Cat="System"; Description="Legacy driver installation packages"; DescriptionAr="حزم تنصيب التعاريف القديمة في مجلدات الصيانة"; IsAdmin=$true }
    @{ Id="adm_sys_temp"; Name="Windows system temp (C:\Windows\Temp)"; NameAr="ملفات النظام المؤقتة (C:\Windows\Temp)"; Path="C:\Windows\Temp"; Guard=@(); Cat="System"; Description="System-level temporary files and installer artifacts"; DescriptionAr="الملفات المؤقتة على مستوى النظام ومثبتات البرامج"; IsAdmin=$true }
)

# Build XAML UI definition with high-contrast crisp white typography, Segoe MDL2 Assets, and Iraqi Flag Language Switcher
[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="ZeroCleaner - Safe and Fast Windows Cache Cleaner"
    Height="840" Width="1180"
    MinHeight="720" MinWidth="1000"
    WindowStartupLocation="CenterScreen"
    Background="#0B0F19"
    FontFamily="Segoe UI, Segoe UI Variable Display, Tahoma, Arial"
    Foreground="#FFFFFF">

    <Window.Resources>
        <!-- Color Palette (High-Contrast Fluent Dark / CTT Style) -->
        <SolidColorBrush x:Key="BaseBackground" Color="#0B0F19"/>
        <SolidColorBrush x:Key="HeaderBackground" Color="#111827"/>
        <SolidColorBrush x:Key="CardBackground" Color="#151D30"/>
        <SolidColorBrush x:Key="CardHover" Color="#1E293B"/>
        <SolidColorBrush x:Key="BorderColor" Color="#2A3756"/>
        <SolidColorBrush x:Key="AccentCyan" Color="#38BDF8"/>
        <SolidColorBrush x:Key="AccentBlue" Color="#60A5FA"/>
        <SolidColorBrush x:Key="AccentPurple" Color="#C084FC"/>
        <SolidColorBrush x:Key="AccentGreen" Color="#4ADE80"/>
        <SolidColorBrush x:Key="AccentRed" Color="#F87171"/>
        <SolidColorBrush x:Key="AccentYellow" Color="#FBBF24"/>
        <SolidColorBrush x:Key="AccentCoral" Color="#DA7756"/>
        <SolidColorBrush x:Key="TextBright" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="TextSub" Color="#E2E8F0"/>
        <SolidColorBrush x:Key="TextMuted" Color="#94A3B8"/>

        <!-- Custom Card Style -->
        <Style x:Key="CardPanel" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource CardBackground}"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderColor}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="14,12"/>
            <Setter Property="Margin" Value="5"/>
        </Style>

        <!-- Primary Modern Button -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#2563EB"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#3B82F6"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#1D4ED8"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#334155"/>
                                <Setter Property="Foreground" Value="#94A3B8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Success Green Button -->
        <Style x:Key="SuccessButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
            <Setter Property="Background" Value="#059669"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#10B981"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#047857"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#334155"/>
                                <Setter Property="Foreground" Value="#94A3B8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button -->
        <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
            <Setter Property="Background" Value="#1E293B"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#334155"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#475569"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#0F172A"/>
                                <Setter Property="Foreground" Value="#64748B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Danger Button -->
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
            <Setter Property="Background" Value="#DC2626"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#EF4444"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter Property="Background" Value="#B91C1C"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter Property="Background" Value="#334155"/>
                                <Setter Property="Foreground" Value="#94A3B8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Modern CheckBox Style -->
        <Style x:Key="ModernCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="Margin" Value="0,2.5"/>
            <Style.Triggers>
                <Trigger Property="IsChecked" Value="True">
                    <Setter Property="Foreground" Value="#DA7756"/>
                    <Setter Property="FontWeight" Value="SemiBold"/>
                </Trigger>
                <Trigger Property="IsChecked" Value="False">
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                    <Setter Property="FontWeight" Value="Normal"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="#64748B"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Modern Sleek Fluent Dark ScrollBar -->
        <Style x:Key="ModernScrollThumb" TargetType="{x:Type Thumb}">
            <Setter Property="OverridesDefaultStyle" Value="true"/>
            <Setter Property="IsTabStop" Value="false"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Thumb}">
                        <Border Background="#334155" CornerRadius="4" Margin="1,2,1,2"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="true">
                                <Setter Property="Background" Value="#64748B"/>
                            </Trigger>
                            <Trigger Property="IsDragging" Value="true">
                                <Setter Property="Background" Value="#DA7756"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="MinWidth" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid Background="Transparent">
                            <Track Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ModernScrollThumb}"/>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="Orientation" Value="Horizontal">
                    <Setter Property="Width" Value="Auto"/>
                    <Setter Property="Height" Value="8"/>
                    <Setter Property="MinHeight" Value="8"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="{x:Type ScrollBar}">
                                <Grid Background="Transparent">
                                    <Track Name="PART_Track" IsDirectionReversed="false">
                                        <Track.Thumb>
                                            <Thumb Style="{StaticResource ModernScrollThumb}"/>
                                        </Track.Thumb>
                                    </Track>
                                </Grid>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Modern TabControl -->
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="#E2E8F0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="TabBorder" Background="Transparent" BorderBrush="Transparent" BorderThickness="0,0,0,3" Padding="{TemplateBinding Padding}" Margin="0,0,6,0">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="TabBorder" Property="BorderBrush" Value="#38BDF8"/>
                                <Setter TargetName="TabBorder" Property="Background" Value="#1E293B"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Name="RootGrid">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- TOP HEADER BAR -->
        <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Padding="20,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <!-- Modern Clean Vector SVG Logo & Brand -->
                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border CornerRadius="10" Width="38" Height="38" Margin="0,0,12,0" BorderBrush="#38BDF8" BorderThickness="1.5">
                        <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                <GradientStop Color="#6366F1" Offset="0.0"/>
                                <GradientStop Color="#0EA5E9" Offset="1.0"/>
                            </LinearGradientBrush>
                        </Border.Background>
                        <Viewbox Width="20" Height="20" HorizontalAlignment="Center" VerticalAlignment="Center">
                            <Canvas Width="24" Height="24">
                                <Path Fill="#FFFFFF" Data="M13,1.5 L4.5,13 L11,13 L9.5,22.5 L19.5,10 L13,10 Z"/>
                            </Canvas>
                        </Viewbox>
                    </Border>
                    <StackPanel VerticalAlignment="Center">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="Zero" FontSize="19" FontWeight="Bold" Foreground="#C084FC"/>
                            <TextBlock Text="Cleaner" FontSize="19" FontWeight="Bold" Foreground="#38BDF8"/>
                        </StackPanel>
                        <TextBlock Name="TxtAppSubtitle" Text="Fast, Safe &amp; Smart Windows C: Drive Cleaner" FontSize="12" Foreground="#FFFFFF"/>
                    </StackPanel>
                </StackPanel>

                <!-- Center: Drive C: Quick Metric Widget -->
                <Border Grid.Column="1" HorizontalAlignment="Center" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="14,6" Margin="15,0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,6,0"/>
                        <TextBlock Name="TxtDriveLabel" Text="Drive C: " FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                        <ProgressBar Name="DriveProgressBar" Width="140" Height="10" Margin="8,0" Minimum="0" Maximum="100" Value="60" Foreground="#38BDF8" Background="#1E293B" BorderThickness="0"/>
                        <TextBlock Name="DriveFreeText" Text="Scanning..." FontSize="12" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                    </StackPanel>
                </Border>

                <!-- Right: Free RAM, Shortcut, Language Switcher, Admin Status & Actions -->
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">

                    <!-- ⚡ Free RAM Header Button -->
                    <Button Name="BtnFreeRam" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="10,4" Cursor="Hand" ToolTip="Quickly free idle application RAM without closing any apps">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                            <TextBlock Name="TxtFreeRam" Text="Free RAM" FontWeight="SemiBold" FontSize="12" Foreground="#38BDF8" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>

                    <!-- Create Desktop Shortcut Header Button -->
                    <Button Name="BtnCreateShortcut" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="10,4" Cursor="Hand" ToolTip="Create a 1-click ZeroCleaner shortcut on your Desktop">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE71B;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                            <TextBlock Name="TxtCreateShortcut" Text="Add to Desktop" FontWeight="SemiBold" FontSize="12" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>

                    <!-- Bilingual Language Toggle Button -->
                    <Button Name="BtnToggleLang" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="10,4" Cursor="Hand" ToolTip="تبديل اللغة / Switch Language">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <!-- Crisp Vector Iraqi Flag 🇮🇶 -->
                            <Grid Name="Flag_IQ" Width="20" Height="14" Margin="0,0,6,0" Visibility="Visible">
                                <Border CornerRadius="2" ClipToBounds="True" BorderBrush="#475569" BorderThickness="0.5">
                                    <Grid>
                                        <Grid.RowDefinitions>
                                            <RowDefinition Height="*"/>
                                            <RowDefinition Height="*"/>
                                            <RowDefinition Height="*"/>
                                        </Grid.RowDefinitions>
                                        <Border Grid.Row="0" Background="#CE1126"/>
                                        <Border Grid.Row="1" Background="#FFFFFF">
                                            <TextBlock Text="الله أكبر" FontSize="5" FontWeight="Bold" Foreground="#007A3D" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-1,0,0"/>
                                        </Border>
                                        <Border Grid.Row="2" Background="#000000"/>
                                    </Grid>
                                </Border>
                            </Grid>

                            <!-- Crisp Vector British Flag (Union Jack 🇬🇧) -->
                            <Grid Name="Flag_UK" Width="20" Height="14" Margin="0,0,6,0" Visibility="Collapsed">
                                <Border Background="#012169" CornerRadius="2" ClipToBounds="True" BorderBrush="#475569" BorderThickness="0.5">
                                    <Canvas Width="20" Height="14">
                                        <Line X1="0" Y1="0" X2="20" Y2="14" Stroke="#FFFFFF" StrokeThickness="2.5"/>
                                        <Line X1="20" Y1="0" X2="0" Y2="14" Stroke="#FFFFFF" StrokeThickness="2.5"/>
                                        <Line X1="0" Y1="0" X2="20" Y2="14" Stroke="#C8102E" StrokeThickness="1"/>
                                        <Line X1="20" Y1="0" X2="0" Y2="14" Stroke="#C8102E" StrokeThickness="1"/>
                                        <Rectangle Canvas.Left="7.5" Canvas.Top="0" Width="5" Height="14" Fill="#FFFFFF"/>
                                        <Rectangle Canvas.Left="0" Canvas.Top="4.5" Width="20" Height="5" Fill="#FFFFFF"/>
                                        <Rectangle Canvas.Left="8.5" Canvas.Top="0" Width="3" Height="14" Fill="#C8102E"/>
                                        <Rectangle Canvas.Left="0" Canvas.Top="5.5" Width="20" Height="3" Fill="#C8102E"/>
                                    </Canvas>
                                </Border>
                            </Grid>

                            <TextBlock Name="TxtLangLabel" Text="العربية" FontSize="12" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>

                    <Border Name="AdminBadge" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="6" Padding="10,5" Margin="0,0,10,0">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Name="AdminIcon" Text="&#xEA18;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#FBBF24" Margin="0,0,6,0" VerticalAlignment="Center"/>
                            <TextBlock Name="AdminText" Text="Standard User" FontWeight="Bold" FontSize="12" Foreground="#FBBF24" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>
                    <Button Name="BtnRelaunchAdmin" Style="{StaticResource SecondaryButton}" Content="Elevate to Admin" Padding="12,6" FontSize="12" ToolTip="Relaunch ZeroCleaner with full Administrator privileges"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- MAIN CONTENT TABS -->
        <TabControl Grid.Row="1" Margin="16,8,16,8" Name="MainTabs">

            <!-- TAB 1: CACHE CLEANER DASHBOARD -->
            <TabItem Name="Tab_Dashboard" Header="Cleaner Dashboard">
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <!-- Action Bar & Presets -->
                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <!-- Presets -->
                            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                <TextBlock Name="TxtPresetsLabel" Text="Presets:" VerticalAlignment="Center" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,10,0"/>
                                <Button Name="BtnPresetRecommended" Style="{StaticResource SecondaryButton}" Content="Recommended" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                                <Button Name="BtnPresetAll" Style="{StaticResource SecondaryButton}" Content="Select All" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                                <Button Name="BtnPresetClear" Style="{StaticResource SecondaryButton}" Content="Deselect All" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                                <Button Name="BtnPresetBrowsers" Style="{StaticResource SecondaryButton}" Content="Browsers" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                                <Button Name="BtnPresetDev" Style="{StaticResource SecondaryButton}" Content="Dev Caches" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                                <Button Name="BtnPresetGaming" Style="{StaticResource SecondaryButton}" Content="Gaming" Margin="0,0,6,0" Padding="10,5" FontSize="12"/>
                            </StackPanel>

                            <!-- Quick Action Controls -->
                            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                <CheckBox Name="ChkAutoCloseApps" Style="{StaticResource ModernCheckBox}" Content="Auto-close running apps" Margin="0,0,16,0" FontWeight="SemiBold" ToolTip="Automatically terminates guarded apps (Chrome, Discord, Steam) for 100% clean space"/>
                                <Button Name="BtnScanAll" Style="{StaticResource SecondaryButton}" Content="Scan Space" Margin="0,0,8,0" Padding="14,6"/>
                                <Button Name="BtnCleanSelected" Style="{StaticResource SuccessButton}" Content="Clean Selected Caches" Padding="18,6" FontWeight="Bold"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <!-- Scrollable Category Cards Grid -->
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                        <Grid Margin="0,0,4,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- CARD 1: GPU SHADERS -->
                            <Border Grid.Column="0" Grid.Row="0" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE7F4;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_GPU" Text="GPU Shaders" FontWeight="Bold" FontSize="14" Foreground="#38BDF8"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_GPU" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_GPU" Text="NVIDIA, AMD, Intel &amp; DirectX Shader Caches" FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_GPU"/>
                                </StackPanel>
                            </Border>

                            <!-- CARD 2: WEB BROWSERS -->
                            <Border Grid.Column="1" Grid.Row="0" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#60A5FA" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_Browser" Text="Web Browsers" FontWeight="Bold" FontSize="14" Foreground="#60A5FA"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_Browser" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_Browser" Text="Chrome, Edge, Brave, Arc, Firefox, Opera, etc." FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_Browser"/>
                                </StackPanel>
                            </Border>

                            <!-- CARD 3: DEVELOPER CACHES -->
                            <Border Grid.Column="2" Grid.Row="0" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE943;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#C084FC" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_Dev" Text="Developer Tools" FontWeight="Bold" FontSize="14" Foreground="#C084FC"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_Dev" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_Dev" Text="npm, pip, Yarn, pnpm, NuGet, Gradle, VS Code" FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_Dev"/>
                                </StackPanel>
                            </Border>

                            <!-- CARD 4: GAMING LAUNCHERS -->
                            <Border Grid.Column="0" Grid.Row="1" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE7FC;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#FBBF24" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_Gaming" Text="Gaming Launchers" FontWeight="Bold" FontSize="14" Foreground="#FBBF24"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_Gaming" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_Gaming" Text="Steam, Epic Games, Battle.net, Riot, GOG, Roblox" FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_Gaming"/>
                                </StackPanel>
                            </Border>

                            <!-- CARD 5: SOCIAL, CREATIVE & APPS -->
                            <Border Grid.Column="1" Grid.Row="1" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE8BD;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#F472B6" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_Social" Text="Chat &amp; Creative" FontWeight="Bold" FontSize="14" Foreground="#F472B6"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_Social" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_Social" Text="Discord, Telegram, Slack, DaVinci, Blender, OBS, VLC" FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_Social"/>
                                </StackPanel>
                            </Border>

                            <!-- CARD 6: SYSTEM & ADMIN -->
                            <Border Grid.Column="2" Grid.Row="1" Style="{StaticResource CardPanel}">
                                <StackPanel>
                                    <Grid Margin="0,0,0,6">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#F87171" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                            <TextBlock Name="TxtTitle_System" Text="System &amp; Admin" FontWeight="Bold" FontSize="14" Foreground="#F87171"/>
                                        </StackPanel>
                                        <TextBlock Name="Badge_System" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80"/>
                                    </Grid>
                                    <TextBlock Name="TxtSub_System" Text="User Temp, Cryptnet, Win Updates, WER, BSOD Dumps" FontSize="11" Foreground="#E2E8F0" Margin="0,0,0,6"/>
                                    <Separator Background="#2A3756" Margin="0,0,0,6"/>
                                    <StackPanel Name="Panel_System"/>
                                </StackPanel>
                            </Border>

                        </Grid>
                    </ScrollViewer>
                </Grid>
            </TabItem>

            <!-- TAB 2: DETAILED SCANNER TABLE -->
            <TabItem Name="Tab_Inspector" Header="Target Inspector">
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" Orientation="Horizontal">
                                <TextBlock Name="TxtFilterLabel" Text="Search / Filter Targets:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,10,0" Foreground="#FFFFFF"/>
                                <TextBox Name="TxtFilterSearch" Width="260" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="8,4" FontSize="12"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnTableRefresh" Style="{StaticResource SecondaryButton}" Content="Rescan Table" Margin="0,0,8,0" Padding="12,5"/>
                                <Button Name="BtnSelectFoundOnly" Style="{StaticResource SecondaryButton}" Content="Select Found Only" Padding="12,5"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <DataGrid Name="TargetsDataGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False"
                              Background="#111827" Foreground="#FFFFFF" BorderBrush="#1F2937" GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#1F2937" RowBackground="#111827" AlternatingRowBackground="#151D30"
                              HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="12">
                        <DataGrid.Resources>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#0B0F19"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                                <Setter Property="FontWeight" Value="Bold"/>
                                <Setter Property="Padding" Value="10,8"/>
                                <Setter Property="BorderBrush" Value="#1F2937"/>
                                <Setter Property="BorderThickness" Value="0,0,0,1"/>
                            </Style>
                            <Style TargetType="DataGridRow">
                                <Setter Property="Padding" Value="4"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                                <Style.Triggers>
                                    <DataTrigger Binding="{Binding IsSelected}" Value="True">
                                        <Setter Property="Foreground" Value="#DA7756"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                    </DataTrigger>
                                </Style.Triggers>
                            </Style>
                        </DataGrid.Resources>
                        <DataGrid.Columns>
                            <DataGridCheckBoxColumn Header="Clean" Binding="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" Width="55"/>
                            <DataGridTextColumn Header="Target Name" Binding="{Binding Name}" FontWeight="Bold" Width="240" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Category" Binding="{Binding Cat}" Width="90" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Size Reclaimable" Binding="{Binding SizeFormatted}" Width="120" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Status / Guard" Binding="{Binding Status}" Width="160" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Path / Location" Binding="{Binding Path}" Width="*" IsReadOnly="True"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>

            <!-- TAB 3: TASK MANAGER & PROCESS GUARD -->
            <TabItem Name="Tab_Guard" Header="Task Manager">
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="TxtGuardTitle" Text="Active Applications Holding Cache Locks" VerticalAlignment="Center" FontWeight="Bold" FontSize="14" Foreground="#FBBF24"/>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnRefreshProcesses" Style="{StaticResource SecondaryButton}" Content="Check Processes" Margin="0,0,8,0" Padding="12,5"/>
                                <Button Name="BtnCloseAllGuards" Style="{StaticResource DangerButton}" Content="Close All Guarded Apps" Padding="14,5"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <DataGrid Name="ProcessDataGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False"
                              Background="#111827" Foreground="#FFFFFF" BorderBrush="#1F2937" GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#1F2937" RowBackground="#111827" AlternatingRowBackground="#151D30"
                              HeadersVisibility="Column" SelectionMode="Single" FontSize="12">
                        <DataGrid.Resources>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#0B0F19"/>
                                <Setter Property="Foreground" Value="#FBBF24"/>
                                <Setter Property="FontWeight" Value="Bold"/>
                                <Setter Property="Padding" Value="10,8"/>
                                <Setter Property="BorderBrush" Value="#1F2937"/>
                                <Setter Property="BorderThickness" Value="0,0,0,1"/>
                            </Style>
                            <Style TargetType="DataGridRow">
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Style>
                        </DataGrid.Resources>
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Process Name" Binding="{Binding Name}" FontWeight="Bold" Width="180" IsReadOnly="True"/>
                            <DataGridTextColumn Header="PID" Binding="{Binding Id}" Width="80" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Associated Target Cache" Binding="{Binding TargetName}" Width="260" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Lock Status" Binding="{Binding Status}" Width="150" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Main Window Title" Binding="{Binding MainWindowTitle}" Width="*" IsReadOnly="True"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>

            <!-- TAB 4: LIVE CONSOLE & LOGS -->
            <TabItem Name="Tab_Log" Header="Activity Log">
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="TxtLogTitle" Text="Real-Time Execution &amp; Deletion Output" VerticalAlignment="Center" FontWeight="Bold" FontSize="14" Foreground="#4ADE80"/>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnCopyLogs" Style="{StaticResource SecondaryButton}" Content="Copy All Logs" Margin="0,0,8,0" Padding="12,5"/>
                                <Button Name="BtnClearLogs" Style="{StaticResource SecondaryButton}" Content="Clear Console" Padding="12,5"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <Border Grid.Row="1" Background="#030712" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="10">
                        <TextBox Name="TxtLogConsole" Background="Transparent" Foreground="#4ADE80" BorderThickness="0"
                                 FontFamily="Consolas, Cascadia Code, Courier New" FontSize="12"
                                 IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                                 TextWrapping="Wrap"/>
                    </Border>
                </Grid>
            </TabItem>

            <!-- TAB 5: ABOUT & CREDITS -->
            <TabItem Name="Tab_About" Header="About">
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,10,0,10">
                    <Border Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="12" Padding="32,24" MaxWidth="720" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,10,0,20">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">

                            <!-- Hero Badge & Title -->
                            <Border CornerRadius="16" Width="64" Height="64" Margin="0,0,0,12" BorderBrush="#38BDF8" BorderThickness="2" HorizontalAlignment="Center">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="#6366F1" Offset="0.0"/>
                                        <GradientStop Color="#0EA5E9" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Viewbox Width="34" Height="34" HorizontalAlignment="Center" VerticalAlignment="Center">
                                    <Canvas Width="24" Height="24">
                                        <Path Fill="#FFFFFF" Data="M13,1.5 L4.5,13 L11,13 L9.5,22.5 L19.5,10 L13,10 Z"/>
                                    </Canvas>
                                </Viewbox>
                            </Border>

                            <TextBlock Text="ZeroCleaner" FontSize="24" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                            <TextBlock Name="TxtAboutSub" Text="Fast, Safe &amp; Intelligent Cache Cleaner for Windows Drive C:" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" Margin="0,0,0,10"/>

                            <!-- License Pill Badge -->
                            <Border Background="#151D30" BorderBrush="#38BDF8" BorderThickness="1" CornerRadius="12" Padding="12,4" HorizontalAlignment="Center" Margin="0,0,0,20">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="&#xE8D7;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                    <TextBlock Text="Free &amp; Open Source Software (MIT License)" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Border>

                            <!-- 3 Quick Highlight Cards -->
                            <Grid Margin="0,0,0,20" HorizontalAlignment="Center">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="200"/>
                                    <ColumnDefinition Width="200"/>
                                    <ColumnDefinition Width="200"/>
                                </Grid.ColumnDefinitions>

                                <!-- Badge 1 -->
                                <Border Grid.Column="0" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,0">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#4ADE80" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Text="100% Login Safe" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" HorizontalAlignment="Center"/>
                                        <TextBlock Text="Zero cookie or session loss" FontSize="10" Foreground="#94A3B8" HorizontalAlignment="Center"/>
                                    </StackPanel>
                                </Border>

                                <!-- Badge 2 -->
                                <Border Grid.Column="1" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,0">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="&#xE7E8;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#38BDF8" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Text="55+ Cache Targets" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" HorizontalAlignment="Center"/>
                                        <TextBlock Text="GPU, Dev, Gaming, Browsers" FontSize="10" Foreground="#94A3B8" HorizontalAlignment="Center"/>
                                    </StackPanel>
                                </Border>

                                <!-- Badge 3 -->
                                <Border Grid.Column="2" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,0">
                                    <StackPanel HorizontalAlignment="Center">
                                        <!-- Crisp Iraqi Flag 🇮🇶 -->
                                        <Border Width="20" Height="14" CornerRadius="2" Margin="0,2,0,5" BorderBrush="#475569" BorderThickness="0.5" ClipToBounds="True" HorizontalAlignment="Center">
                                            <Grid>
                                                <Grid.RowDefinitions>
                                                    <RowDefinition Height="*"/>
                                                    <RowDefinition Height="*"/>
                                                    <RowDefinition Height="*"/>
                                                </Grid.RowDefinitions>
                                                <Border Grid.Row="0" Background="#CE1126"/>
                                                <Border Grid.Row="1" Background="#FFFFFF">
                                                    <TextBlock Text="الله أكبر" FontSize="5" FontWeight="Bold" Foreground="#007A3D" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-1,0,0"/>
                                                </Border>
                                                <Border Grid.Row="2" Background="#000000"/>
                                            </Grid>
                                        </Border>
                                        <TextBlock Text="Made in Iraq" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" HorizontalAlignment="Center"/>
                                        <TextBlock Text="Crafted by Amir Ali" FontSize="10" Foreground="#94A3B8" HorizontalAlignment="Center"/>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <!-- Safety Statement Card -->
                            <Border Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="16,12" Margin="0,0,0,20" MaxWidth="620">
                                <StackPanel HorizontalAlignment="Center">
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,6">
                                        <TextBlock Text="&#xE8BD;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#4ADE80" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtAboutSafetyTitle" Text="100% Account Safety Guarantee" FontWeight="Bold" FontSize="13" Foreground="#4ADE80"/>
                                    </StackPanel>
                                    <TextBlock Name="TxtAboutSafetyBody" Text="ZeroCleaner targets ONLY temporary scratch, shader caches, and build artifacts. It NEVER touches your browser login databases, cookies, passwords, or active accounts." FontSize="12" TextWrapping="Wrap" TextAlignment="Center" Foreground="#E2E8F0" LineHeight="18"/>
                                </StackPanel>
                            </Border>

                            <!-- Social Links & Maintainer -->
                            <TextBlock Name="TxtAboutAuthorTitle" Text="Author &amp; Contact" FontWeight="Bold" FontSize="14" Foreground="#38BDF8" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                            
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,16">
                                <!-- Telegram Button -->
                                <Button Name="BtnOpenTelegram" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="14,6" Cursor="Hand" ToolTip="Open Telegram @sytus">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <TextBlock Text="&#xE715;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                        <TextBlock Text="Telegram: @sytus" FontWeight="SemiBold" FontSize="12" Foreground="#FFFFFF"/>
                                    </StackPanel>
                                </Button>

                                <!-- Instagram Button -->
                                <Button Name="BtnOpenInstagram" Style="{StaticResource SecondaryButton}" Padding="14,6" Cursor="Hand" ToolTip="Open Instagram @lnetl">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <TextBlock Text="&#xE722;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#F472B6" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                        <TextBlock Text="Instagram: @lnetl" FontWeight="SemiBold" FontSize="12" Foreground="#FFFFFF"/>
                                    </StackPanel>
                                </Button>
                            </StackPanel>

                            <!-- Footer -->
                            <Separator Background="#2A3756" Margin="0,0,0,12"/>
                            <TextBlock Text="Released under the MIT License &#x2022; Copyright &#xA9; 2026 Amir Ali &#x2022; All Rights Reserved" FontSize="11" Foreground="#475569" HorizontalAlignment="Center"/>

                        </StackPanel>
                    </Border>
                </ScrollViewer>
            </TabItem>

        </TabControl>

        <!-- BOTTOM STATUS BAR -->
        <Border Grid.Row="2" Background="#111827" BorderBrush="#1F2937" BorderThickness="0,1,0,0" Padding="20,8">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="StatusIcon" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Center"/>
                    <TextBlock Name="StatusText" Text="Ready to scan and clean. Select your preferred preset or targets." FontSize="13" FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TxtSelectedLabel" Text="Selected:" FontSize="13" FontWeight="SemiBold" Foreground="#FFFFFF" Margin="0,0,5,0"/>
                    <TextBlock Name="TxtSelectedCount" Text="0 items" FontWeight="Bold" FontSize="13" Foreground="#DA7756" Margin="0,0,15,0"/>
                    <TextBlock Name="TxtReclaimableLabel" Text="Space to Clean:" FontSize="13" FontWeight="SemiBold" Foreground="#FFFFFF" Margin="0,0,5,0"/>
                    <TextBlock Name="TxtTotalReclaimable" Text="0.00 MB" FontWeight="Bold" FontSize="13" Foreground="#4ADE80"/>
                </StackPanel>
            </Grid>
        </Border>

    </Grid>
</Window>
'@

# Read and Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

# Map UI Elements
$RootGrid           = $Window.FindName("RootGrid")
$TxtAppSubtitle     = $Window.FindName("TxtAppSubtitle")
$TxtDriveLabel      = $Window.FindName("TxtDriveLabel")
$DriveProgressBar   = $Window.FindName("DriveProgressBar")
$DriveFreeText      = $Window.FindName("DriveFreeText")
$BtnToggleLang      = $Window.FindName("BtnToggleLang")
$Flag_IQ            = $Window.FindName("Flag_IQ")
$Flag_UK            = $Window.FindName("Flag_UK")
$TxtLangLabel       = $Window.FindName("TxtLangLabel")
$AdminBadge         = $Window.FindName("AdminBadge")
$AdminIcon          = $Window.FindName("AdminIcon")
$AdminText          = $Window.FindName("AdminText")
$BtnRelaunchAdmin   = $Window.FindName("BtnRelaunchAdmin")

$Tab_Dashboard      = $Window.FindName("Tab_Dashboard")
$Tab_Inspector      = $Window.FindName("Tab_Inspector")
$Tab_Guard          = $Window.FindName("Tab_Guard")
$Tab_Log            = $Window.FindName("Tab_Log")
$Tab_About          = $Window.FindName("Tab_About")

$TxtPresetsLabel      = $Window.FindName("TxtPresetsLabel")
$BtnPresetRecommended = $Window.FindName("BtnPresetRecommended")
$BtnPresetAll         = $Window.FindName("BtnPresetAll")
$BtnPresetBrowsers    = $Window.FindName("BtnPresetBrowsers")
$BtnPresetDev         = $Window.FindName("BtnPresetDev")
$BtnPresetGaming      = $Window.FindName("BtnPresetGaming")
$BtnPresetClear       = $Window.FindName("BtnPresetClear")

$ChkAutoCloseApps   = $Window.FindName("ChkAutoCloseApps")
$BtnScanAll         = $Window.FindName("BtnScanAll")
$BtnCleanSelected   = $Window.FindName("BtnCleanSelected")

$TxtTitle_GPU       = $Window.FindName("TxtTitle_GPU")
$TxtSub_GPU         = $Window.FindName("TxtSub_GPU")
$TxtTitle_Browser   = $Window.FindName("TxtTitle_Browser")
$TxtSub_Browser     = $Window.FindName("TxtSub_Browser")
$TxtTitle_Dev       = $Window.FindName("TxtTitle_Dev")
$TxtSub_Dev         = $Window.FindName("TxtSub_Dev")
$TxtTitle_Gaming    = $Window.FindName("TxtTitle_Gaming")
$TxtSub_Gaming      = $Window.FindName("TxtSub_Gaming")
$TxtTitle_Social    = $Window.FindName("TxtTitle_Social")
$TxtSub_Social      = $Window.FindName("TxtSub_Social")
$TxtTitle_System    = $Window.FindName("TxtTitle_System")
$TxtSub_System      = $Window.FindName("TxtSub_System")

$Panel_GPU          = $Window.FindName("Panel_GPU")
$Panel_Browser      = $Window.FindName("Panel_Browser")
$Panel_Dev          = $Window.FindName("Panel_Dev")
$Panel_Gaming       = $Window.FindName("Panel_Gaming")
$Panel_Social       = $Window.FindName("Panel_Social")
$Panel_System       = $Window.FindName("Panel_System")

$Badge_GPU          = $Window.FindName("Badge_GPU")
$Badge_Browser      = $Window.FindName("Badge_Browser")
$Badge_Dev          = $Window.FindName("Badge_Dev")
$Badge_Gaming       = $Window.FindName("Badge_Gaming")
$Badge_Social       = $Window.FindName("Badge_Social")
$Badge_System       = $Window.FindName("Badge_System")

$TxtFilterLabel     = $Window.FindName("TxtFilterLabel")
$TxtFilterSearch    = $Window.FindName("TxtFilterSearch")
$BtnTableRefresh    = $Window.FindName("BtnTableRefresh")
$BtnSelectFoundOnly = $Window.FindName("BtnSelectFoundOnly")
$TargetsDataGrid    = $Window.FindName("TargetsDataGrid")

$TxtGuardTitle       = $Window.FindName("TxtGuardTitle")
$BtnRefreshProcesses = $Window.FindName("BtnRefreshProcesses")
$BtnCloseAllGuards   = $Window.FindName("BtnCloseAllGuards")
$ProcessDataGrid     = $Window.FindName("ProcessDataGrid")

$TxtLogTitle        = $Window.FindName("TxtLogTitle")
$BtnCopyLogs        = $Window.FindName("BtnCopyLogs")
$BtnClearLogs       = $Window.FindName("BtnClearLogs")
$TxtLogConsole      = $Window.FindName("TxtLogConsole")

$TxtAboutSub        = $Window.FindName("TxtAboutSub")
$TxtAboutSafetyTitle= $Window.FindName("TxtAboutSafetyTitle")
$TxtAboutSafetyBody = $Window.FindName("TxtAboutSafetyBody")
$TxtAboutAuthorTitle= $Window.FindName("TxtAboutAuthorTitle")
$BtnOpenTelegram    = $Window.FindName("BtnOpenTelegram")
$BtnOpenInstagram   = $Window.FindName("BtnOpenInstagram")
$BtnCreateShortcut  = $Window.FindName("BtnCreateShortcut")
$TxtCreateShortcut  = $Window.FindName("TxtCreateShortcut")

$StatusIcon         = $Window.FindName("StatusIcon")
$StatusText         = $Window.FindName("StatusText")
$TxtSelectedLabel   = $Window.FindName("TxtSelectedLabel")
$TxtSelectedCount   = $Window.FindName("TxtSelectedCount")
$TxtReclaimableLabel= $Window.FindName("TxtReclaimableLabel")
$TxtTotalReclaimable= $Window.FindName("TxtTotalReclaimable")
$MainTabs           = $Window.FindName("MainTabs")

$Script:TargetItems = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.TargetItem]]::new()
$Script:CheckboxesById = @{}
$Script:CurrentLang = "EN"

# Bilingual Dictionaries
$Script:Translations = @{
    "EN" = @{
        AppSubtitle       = "Fast, Safe & Smart Windows C: Drive Cleaner"
        DriveLabel        = "Drive C: "
        StandardUser      = "Standard User"
        Administrator     = "Administrator"
        ElevateBtn        = "Elevate to Admin"
        TabDashboard      = "Cleaner Dashboard"
        TabInspector      = "Target Inspector"
        TabGuard          = "Task Manager"
        TabLog            = "Activity Log"
        TabAbout          = "About"
        PresetsLabel      = "Presets:"
        BtnRec            = "Recommended"
        BtnAll            = "Select All"
        BtnClear          = "Deselect All"
        BtnBrowsers       = "Browsers"
        BtnDev            = "Dev Caches"
        BtnGaming         = "Gaming"
        AutoCloseApps     = "Auto-close running apps"
        ScanSpace         = "Scan Space"
        CleanSelected     = "Clean Selected Caches"
        Title_GPU         = "GPU Shaders"
        Sub_GPU           = "NVIDIA, AMD, Intel & DirectX Shader Caches"
        Title_Browser     = "Web Browsers"
        Sub_Browser       = "Chrome, Edge, Brave, Arc, Firefox, Opera, etc."
        Title_Dev         = "Developer Tools"
        Sub_Dev           = "npm, pip, Yarn, pnpm, NuGet, Gradle, VS Code"
        Title_Gaming      = "Gaming Launchers"
        Sub_Gaming        = "Steam, Epic Games, Battle.net, Riot, GOG, Roblox"
        Title_Social      = "Chat & Creative"
        Sub_Social        = "Discord, Telegram, Slack, DaVinci, Blender, OBS, VLC"
        Title_System      = "System & Admin"
        Sub_System        = "User Temp, Cryptnet, Win Updates, WER, BSOD Dumps"
        StorageBreakdownTitle = "Storage Breakdown by Category"
        TotalDetectedLabel    = "Total Found Cache:"
        LegGPU                = "GPU Shaders:"
        LegBrowser            = "Browsers:"
        LegDev                = "Dev Tools:"
        LegGaming             = "Gaming:"
        LegSocial             = "Chat & Apps:"
        LegSystem             = "System Temp:"
        FilterLabel       = "Search / Filter Targets:"
        RescanTable       = "Rescan Table"
        SelectFound       = "Select Found Only"
        GuardTitle        = "Active Applications Holding Cache Locks"
        CheckProcesses    = "Check Processes"
        CloseGuards       = "Close All Guarded Apps"
        LogTitle          = "Real-Time Execution & Deletion Output"
        CopyLogs          = "Copy All Logs"
        ClearConsole      = "Clear Console"
        AboutSub          = "Intelligent Windows Cache & Storage Reclamation Engine"
        AboutSafetyTitle  = "100% Account Safety Guarantee"
        AboutSafetyBody   = "ZeroCleaner targets ONLY temporary web, GPU shader, build artifacts, and system scratch caches. It NEVER deletes saved passwords, active login sessions, bookmarks, or browser history databases."
        AboutAuthorTitle  = "Author & Maintainer"
        CreateShortcut    = "Add to Desktop"
        FreeRamBtn        = "Free RAM"
        FreeRamTooltip    = "Instantly free idle application memory (RAM) without closing any apps"
        ReadyStatus       = "Ready to scan and clean. Select your preferred preset or targets."
        ScanningStatus    = "Scanning all 55+ cache targets on Drive C: ..."
        ScanCompleteStatus= "Scan complete! Found cache targets are highlighted."
        SelectedLabel     = "Selected:"
        ReclaimableLabel  = "Space to Clean:"
        LangButtonText    = "العربية"
    }
    "AR" = @{
        AppSubtitle       = "منظف الكاش الذكي والسريع والآمن للقرص C:"
        DriveLabel        = "Drive C: "
        StandardUser      = "مستخدم عادي"
        Administrator     = "مسؤول النظام"
        ElevateBtn        = "تشغيل كمسؤول"
        TabDashboard      = "لوحة التنظيف"
        TabInspector      = "فاحص المسارات"
        TabGuard          = "مدير المهام"
        TabLog            = "سجل النشاط"
        TabAbout          = "حول البرنامج"
        PresetsLabel      = "التحديد السريع:"
        BtnRec            = "الموصى به"
        BtnAll            = "تحديد الكل"
        BtnBrowsers       = "المتصفحات"
        BtnDev            = "المطورين"
        BtnGaming         = "الألعاب"
        BtnClear          = "إلغاء التحديد"
        AutoCloseApps     = "إغلاق التطبيقات المفتوحة تلقائياً"
        ScanSpace         = "فحص المساحة"
        CleanSelected     = "تنظيف الكاش المحدد"
        Title_GPU         = "GPU Shaders"
        Sub_GPU           = "NVIDIA, AMD, Intel & DirectX Shader Caches"
        Title_Browser     = "Web Browsers"
        Sub_Browser       = "Chrome, Edge, Brave, Arc, Firefox, Opera (Logins Safe)"
        Title_Dev         = "Developer Tools"
        Sub_Dev           = "npm, pip, Yarn, pnpm, NuGet, Gradle, VS Code"
        Title_Gaming      = "Gaming Launchers"
        Sub_Gaming        = "Steam, Epic Games, Battle.net, Riot, GOG, Roblox"
        Title_Social      = "Chat & Creative"
        Sub_Social        = "Discord, Telegram, Slack, DaVinci, Blender, OBS, VLC"
        Title_System      = "System & Admin"
        Sub_System        = "User Temp, Cryptnet, Win Updates, WER, BSOD Dumps"
        StorageBreakdownTitle = "توزيع مساحة الكاش حسب الفئات"
        TotalDetectedLabel    = "إجمالي الكاش المكتشف:"
        LegGPU                = "مظللات GPU:"
        LegBrowser            = "المتصفحات:"
        LegDev                = "أدوات التطوير:"
        LegGaming             = "الألعاب:"
        LegSocial             = "المحادثة والبرامج:"
        LegSystem             = "ملفات النظام المؤقتة:"
        FilterLabel       = "البحث وتصفية المسارات:"
        RescanTable       = "إعادة فحص الجدول"
        SelectFound       = "تحديد المكتشف فقط"
        GuardTitle        = "البرامج والمهام النشطة التي تقفل ملفات الكاش"
        CheckProcesses    = "تحديث مدير المهام"
        CloseGuards       = "إغلاق جميع البرامج المقفلة"
        LogTitle          = "مخرجات التنظيف والحذف المباشرة"
        CopyLogs          = "نسخ السجل"
        ClearConsole      = "مسح الشاشة"
        AboutSub          = "محرك استرداد مساحة التخزين وتنظيف الكاش في ويندوز"
        AboutSafetyTitle  = "ضمان أمان الحسابات وكلمات السر 100%"
        AboutSafetyBody   = "يقوم ZeroCleaner بتنظيف ملفات الكاش والويب والمظللات المؤقتة فقط. لا يحذف أبداً كلمات المرور المحفوظة، أو جلسات تسجيل الدخول النشطة، أو الإشارات المرجعية."
        AboutAuthorTitle  = "المطور والناشر"
        CreateShortcut    = "إضافة لسطح المكتب"
        FreeRamBtn        = "تفريغ الرام"
        FreeRamTooltip    = "تفريغ ذاكرة الوصول العشوائي (RAM) الخاملة فوراً دون إغلاق أي برنامج"
        ReadyStatus       = "جاهز للفحص والتنظيف. اختر الإعداد المسبق أو حدد المسارات."
        ScanningStatus    = "جاري فحص أكثر من 55 هدف كاش على القرص C: ..."
        ScanCompleteStatus= "اكتمل الفحص! تم تحديد وتحديث مساحات الكاش."
        SelectedLabel     = "المحدد:"
        ReclaimableLabel  = "المساحة التي ستنظف:"
        LangButtonText    = "English"
    }
}

# Switch Language Function
function Apply-Language([string]$lang) {
    $Script:CurrentLang = $lang
    $t = $Script:Translations[$lang]

    $TxtAppSubtitle.Text       = $t.AppSubtitle
    $TxtDriveLabel.Text        = $t.DriveLabel
    $BtnRelaunchAdmin.Content  = $t.ElevateBtn
    $AdminText.Text            = if ($isAdmin) { $t.Administrator } else { $t.StandardUser }

    $Tab_Dashboard.Header      = $t.TabDashboard
    $Tab_Inspector.Header      = $t.TabInspector
    $Tab_Guard.Header          = $t.TabGuard
    $Tab_Log.Header            = $t.TabLog
    $Tab_About.Header          = $t.TabAbout

    $TxtPresetsLabel.Text      = $t.PresetsLabel
    $BtnPresetRecommended.Content = $t.BtnRec
    $BtnPresetAll.Content      = $t.BtnAll
    $BtnPresetBrowsers.Content = $t.BtnBrowsers
    $BtnPresetDev.Content      = $t.BtnDev
    $BtnPresetGaming.Content   = $t.BtnGaming
    $BtnPresetClear.Content    = $t.BtnClear

    $ChkAutoCloseApps.Content  = $t.AutoCloseApps
    $BtnScanAll.Content        = $t.ScanSpace
    $BtnCleanSelected.Content  = $t.CleanSelected

    $TxtTitle_GPU.Text         = $t.Title_GPU
    $TxtSub_GPU.Text           = $t.Sub_GPU
    $TxtTitle_Browser.Text     = $t.Title_Browser
    $TxtSub_Browser.Text       = $t.Sub_Browser
    $TxtTitle_Dev.Text         = $t.Title_Dev
    $TxtSub_Dev.Text           = $t.Sub_Dev
    $TxtTitle_Gaming.Text      = $t.Title_Gaming
    $TxtSub_Gaming.Text        = $t.Sub_Gaming
    $TxtTitle_Social.Text      = $t.Title_Social
    $TxtSub_Social.Text        = $t.Sub_Social
    $TxtTitle_System.Text      = $t.Title_System
    $TxtSub_System.Text        = $t.Sub_System

    $TxtFilterLabel.Text       = $t.FilterLabel
    $BtnTableRefresh.Content   = $t.RescanTable
    $BtnSelectFoundOnly.Content= $t.SelectFound

    $TxtGuardTitle.Text        = $t.GuardTitle
    $BtnRefreshProcesses.Content = $t.CheckProcesses
    $BtnCloseAllGuards.Content = $t.CloseGuards

    $TxtLogTitle.Text          = $t.LogTitle
    $BtnCopyLogs.Content       = $t.CopyLogs
    $BtnClearLogs.Content      = $t.ClearConsole

    $TxtAboutSub.Text          = $t.AboutSub
    $TxtAboutSafetyTitle.Text  = $t.AboutSafetyTitle
    $TxtAboutSafetyBody.Text   = $t.AboutSafetyBody
    $TxtAboutAuthorTitle.Text  = $t.AboutAuthorTitle
    $TxtCreateShortcut.Text    = $t.CreateShortcut
    $TxtFreeRam.Text           = $t.FreeRamBtn
    $BtnFreeRam.ToolTip        = $t.FreeRamTooltip

    $TxtSelectedLabel.Text     = $t.SelectedLabel
    $TxtReclaimableLabel.Text  = $t.ReclaimableLabel
    $TxtLangLabel.Text         = $t.LangButtonText

    if ($lang -eq "AR") {
        $Flag_IQ.Visibility = [System.Windows.Visibility]::Collapsed
        $Flag_UK.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $Flag_IQ.Visibility = [System.Windows.Visibility]::Visible
        $Flag_UK.Visibility = [System.Windows.Visibility]::Collapsed
    }

    # Always keep target checkbox names in clean English
    foreach ($item in $Script:TargetItems) {
        $item.CheckBoxControl.Content = $item.Name
        if ($lang -eq "AR" -and $item.DescriptionAr) {
            $item.CheckBoxControl.ToolTip = $item.DescriptionAr
        } else {
            $item.CheckBoxControl.ToolTip = $item.Description
        }
    }

    Update-DriveInfo
}

# Logging Helper
function Append-Log([string]$message, [string]$level = "INFO") {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logLine = "[$timestamp] [$level] $message`r`n"
    $TxtLogConsole.Dispatcher.Invoke([Action]{
        $TxtLogConsole.AppendText($logLine)
        $TxtLogConsole.ScrollToEnd()
    })
}

# Native Windows 10/11 Toast Notification with Sound
function Show-ZeroToastNotification([string]$title, [string]$message) {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $escapedTitle = [System.Security.SecurityElement]::Escape($title)
        $escapedMessage = [System.Security.SecurityElement]::Escape($message)

        $template = @"
<toast duration="short">
    <visual>
        <binding template="ToastGeneric">
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)

        $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        try {
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        } catch {
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("ZeroCleaner").Show($toast)
        }
    } catch {
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
    }
}

# Helper: Format Bytes / Megabytes
function Format-SpaceMB([double]$MB) {
    if ($MB -ge 1024) {
        return ("{0:N2} GB" -f ($MB / 1024))
    } elseif ($MB -gt 0) {
        return ("{0:N1} MB" -f $MB)
    } else {
        return "0 MB"
    }
}

# Measure Folder Size safely
function Get-FolderSizeMBQuick([string]$targetPath) {
    if ([string]::IsNullOrWhiteSpace($targetPath)) { return 0 }
    try {
        if ($targetPath -eq "VIRTUAL:RECYCLEBIN") {
            try {
                $shell = New-Object -ComObject Shell.Application
                $bin = $shell.Namespace(10)
                $totalBytes = 0
                if ($bin) {
                    foreach ($item in $bin.Items()) { $totalBytes += $item.Size }
                }
                return [math]::Round(($totalBytes / 1MB), 2)
            } catch { return 0 }
        }
        if ($targetPath -eq "VIRTUAL:DNSCACHE") {
            try {
                $dnsEntries = Get-DnsClientCache -ErrorAction SilentlyContinue
                if ($dnsEntries -and $dnsEntries.Count -gt 0) {
                    return [math]::Round(($dnsEntries.Count * 0.005), 1)
                }
            } catch {}
            return 0
        }

        if ($targetPath.Contains("*")) {
            $parent = Split-Path $targetPath -Parent
            $leaf = Split-Path $targetPath -Leaf
            if (-not (Test-Path $parent)) { return 0 }
            $matchingDirs = Get-ChildItem -Path $parent -Directory -Filter $leaf -ErrorAction SilentlyContinue
            $total = 0
            foreach ($d in $matchingDirs) {
                $files = Get-ChildItem $d.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
                if ($files) {
                    $sub = ($files | Measure-Object Length -Sum).Sum
                    if ($sub) { $total += $sub }
                }
            }
            return [math]::Round(($total / 1MB), 1)
        }

        if (Test-Path $targetPath) {
            $files = Get-ChildItem $targetPath -Recurse -Force -File -ErrorAction SilentlyContinue
            if ($files) {
                $sum = ($files | Measure-Object Length -Sum).Sum
                if ($sum) {
                    return [math]::Round(($sum / 1MB), 1)
                }
            }
        }
    } catch {}
    return 0
}

# Process Check Helper
function Test-ProcessRunning([string[]]$Names) {
    if ($null -eq $Names -or $Names.Length -eq 0) { return $false }
    foreach ($n in $Names) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

# Update Drive C: Info
function Update-DriveInfo() {
    try {
        $cDrive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($cDrive) {
            $totalGB = [math]::Round(($cDrive.Used + $cDrive.Free) / 1GB, 1)
            $usedGB  = [math]::Round($cDrive.Used / 1GB, 1)
            $freeGB  = [math]::Round($cDrive.Free / 1GB, 1)
            $percent = [math]::Round(($cDrive.Used / ($cDrive.Used + $cDrive.Free)) * 100, 0)

            $DriveProgressBar.Value = $percent
            $DriveFreeText.Text = "$freeGB GB free of $totalGB GB"
        }
    } catch {}
}

# Update Selected Totals and Count
function Update-SelectedSummary() {
    $count = 0
    $totalMB = 0
    foreach ($item in $Script:TargetItems) {
        if ($item.CheckBoxControl.IsChecked -eq $true -or $item.IsSelected) {
            $count++
            $totalMB += $item.SizeMB
        }
    }
    $suffix = if ($Script:CurrentLang -eq "AR") { "عنصر" } else { "items" }
    $TxtSelectedCount.Text = "$count $suffix"
    $TxtTotalReclaimable.Text = Format-SpaceMB $totalMB
}

# Update Category Badges
function Update-CategoryBadges() {
    $catSums = @{ "GPU"=0; "Browser"=0; "Dev"=0; "Gaming"=0; "Social"=0; "System"=0 }
    foreach ($item in $Script:TargetItems) {
        if ($catSums.ContainsKey($item.Cat)) {
            $catSums[$item.Cat] += $item.SizeMB
        }
    }
    $Badge_GPU.Text     = Format-SpaceMB $catSums["GPU"]
    $Badge_Browser.Text = Format-SpaceMB $catSums["Browser"]
    $Badge_Dev.Text     = Format-SpaceMB $catSums["Dev"]
    $Badge_Gaming.Text  = Format-SpaceMB $catSums["Gaming"]
    $Badge_Social.Text  = Format-SpaceMB $catSums["Social"]
    $Badge_System.Text  = Format-SpaceMB $catSums["System"]
}

# Setup UI Admin State
if ($isAdmin) {
    $AdminText.Text = "Administrator"
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    $AdminIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    $BtnRelaunchAdmin.Visibility = [System.Windows.Visibility]::Collapsed
} else {
    $AdminText.Text = "Standard User"
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
    $BtnRelaunchAdmin.add_Click({
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
        $Window.Close()
    })
}

$BrushSelected   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DA7756")
$BrushUnselected = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
$BrushDisabled   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
$BrushRecycleRed = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
$BrushRecycleRedChecked = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")

# Populate Target Items & Build Category Checkboxes
foreach ($t in $TargetsData) {
    $item = [ZeroCleaner.TargetItem]::new()
    $item.Id            = $t.Id
    $item.Name          = $t.Name
    $item.NameAr        = $t.NameAr
    $item.Path          = $t.Path
    $item.Cat           = $t.Cat
    $item.Description   = $t.Description
    $item.DescriptionAr = $t.DescriptionAr
    $item.Guard         = [string[]]$t.Guard
    $item.IsAdmin       = [bool]$t.IsAdmin

    # Target Row in Card
    $rowGrid = New-Object System.Windows.Controls.Grid
    $rowGrid.Margin = New-Object System.Windows.Thickness(0, 2.5, 0, 2.5)

    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::Auto
    $rowGrid.ColumnDefinitions.Add($col1)
    $rowGrid.ColumnDefinitions.Add($col2)

    $chk = New-Object System.Windows.Controls.CheckBox
    $chk.Style = $Window.FindName("ModernCheckBox")
    $chk.Content = $item.Name
    $chk.ToolTip = $item.Description
    $chk.Tag = $item
    $chk.Foreground = if ($item.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }

    # Disable system targets if not admin
    if ($item.IsAdmin -and -not $isAdmin) {
        $chk.IsEnabled = $false
        $chk.ToolTip = "[Requires Admin Elevation] " + $item.Description
        $chk.Foreground = $BrushDisabled
    }

    $lblSize = New-Object System.Windows.Controls.TextBlock
    $lblSize.Text = "--"
    $lblSize.FontSize = 11
    $lblSize.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E2E8F0")
    $lblSize.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $lblSize.Margin = New-Object System.Windows.Thickness(6, 0, 0, 0)
    [System.Windows.Controls.Grid]::SetColumn($lblSize, 1)

    $rowGrid.Children.Add($chk) | Out-Null
    $rowGrid.Children.Add($lblSize) | Out-Null

    $item.CheckBoxControl = $chk
    $item.SizeLabel = $lblSize

    # Wire Checkbox Events
    $chk.add_Checked({
        param($s, $e)
        $s.Foreground = if ($s.Tag.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
        $s.FontWeight = [System.Windows.FontWeights]::SemiBold
        $target = $s.Tag
        if (-not $target.IsSelected) {
            $target.IsSelected = $true
        }
        Update-SelectedSummary
    })
    $chk.add_Unchecked({
        param($s, $e)
        $s.Foreground = if ($s.Tag.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }
        $s.FontWeight = [System.Windows.FontWeights]::Normal
        $target = $s.Tag
        if ($target.IsSelected) {
            $target.IsSelected = $false
        }
        Update-SelectedSummary
    })

    # Two-Way Sync from DataGrid or Code to UI Checkbox
    $item.add_PropertyChanged({
        param($s, $e)
        if ($e.PropertyName -eq "IsSelected") {
            if ($s.CheckBoxControl -and $s.CheckBoxControl.IsChecked -ne $s.IsSelected) {
                $s.CheckBoxControl.IsChecked = $s.IsSelected
            }
            if ($s.CheckBoxControl) {
                if ($s.IsSelected) {
                    $s.CheckBoxControl.Foreground = if ($s.Id -eq "sys_recycle_bin") { $BrushRecycleRedChecked } else { $BrushSelected }
                    $s.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::SemiBold
                } else {
                    $s.CheckBoxControl.Foreground = if ($s.Id -eq "sys_recycle_bin") { $BrushRecycleRed } else { $BrushUnselected }
                    $s.CheckBoxControl.FontWeight = [System.Windows.FontWeights]::Normal
                }
            }
        }
    })

    $Script:CheckboxesById[$item.Id] = $chk
    $Script:TargetItems.Add($item)

    # Attach to category panel
    switch ($item.Cat) {
        "GPU"     { $Panel_GPU.Children.Add($rowGrid) | Out-Null }
        "Browser" { $Panel_Browser.Children.Add($rowGrid) | Out-Null }
        "Dev"     { $Panel_Dev.Children.Add($rowGrid) | Out-Null }
        "Gaming"  { $Panel_Gaming.Children.Add($rowGrid) | Out-Null }
        "Social"  { $Panel_Social.Children.Add($rowGrid) | Out-Null }
        "System"  { $Panel_System.Children.Add($rowGrid) | Out-Null }
    }
}

# Bind Target Inspector DataGrid
$TargetsDataGrid.ItemsSource = $Script:TargetItems

# Refresh / Scan Function
function Invoke-ScanSpace([bool]$autoSelectFound = $false) {
    $BtnScanAll.IsEnabled = $false
    $BtnCleanSelected.IsEnabled = $false
    $StatusIcon.Text = [char]0xE72C
    $StatusText.Text = $Script:Translations[$Script:CurrentLang].ScanningStatus
    Append-Log "Beginning full drive C: cache analysis..." "SCAN"

    $totalFoundMB = 0
    foreach ($item in $Script:TargetItems) {
        $sz = Get-FolderSizeMBQuick $item.Path
        $item.SizeMB = $sz
        $item.SizeFormatted = Format-SpaceMB $sz

        if ($item.IsAdmin -and -not $Script:isAdmin) {
            $item.Status = if ($Script:CurrentLang -eq "AR") { "يتطلب صلاحيات مسؤول" } else { "Requires Admin" }
        } elseif ($item.Guard.Length -gt 0 -and (Test-ProcessRunning $item.Guard)) {
            $item.Status = if ($Script:CurrentLang -eq "AR") { "مقفل (" + ($item.Guard -join ', ') + " يعمل)" } else { "Locked (" + ($item.Guard -join ', ') + " running)" }
        } elseif ($sz -gt 0) {
            $item.Status = if ($Script:CurrentLang -eq "AR") { "جاهز للتنظيف" } else { "Ready to Clean" }
            $totalFoundMB += $sz
        } else {
            $item.Status = if ($Script:CurrentLang -eq "AR") { "نظيف / فارغ" } else { "Clean / Empty" }
        }

        # Update UI Controls directly
        if ($sz -gt 0) {
            $item.SizeLabel.Text = $item.SizeFormatted
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Bold
            if ($autoSelectFound -and ($isAdmin -or -not $item.IsAdmin)) {
                $item.CheckBoxControl.IsChecked = $true
            }
        } else {
            $item.SizeLabel.Text = "0 MB"
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    Update-DriveInfo
    Update-CategoryBadges
    Update-SelectedSummary
    $TargetsDataGrid.Items.Refresh()

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E
    $StatusText.Text = $Script:Translations[$Script:CurrentLang].ScanCompleteStatus
    Append-Log "Scan finished successfully. Found $(Format-SpaceMB $totalFoundMB) in caches. Reclaimable selected: $($TxtTotalReclaimable.Text)" "SUCCESS"
}

# Process Guard Monitor Refresh
function Update-ProcessGuardList() {
    $activeGuards = [System.Collections.ArrayList]::new()
    $runningProcesses = Get-Process -ErrorAction SilentlyContinue

    foreach ($t in $Script:TargetItems) {
        if ($t.Guard.Length -gt 0) {
            foreach ($g in $t.Guard) {
                $matching = $runningProcesses | Where-Object { $_.ProcessName -ieq $g }
                foreach ($p in $matching) {
                    $pItem = [ZeroCleaner.ProcessItem]::new()
                    $pItem.Name = $p.ProcessName
                    $pItem.Id = $p.Id
                    $pItem.TargetName = if ($Script:CurrentLang -eq "AR" -and $t.NameAr) { $t.NameAr } else { $t.Name }
                    $pItem.Status = if ($Script:CurrentLang -eq "AR") { "نشط (يقفل الملفات)" } else { "In Use (Blocking Clean)" }
                    $pItem.MainWindowTitle = if ($p.MainWindowTitle) { $p.MainWindowTitle } else { "(Background Process)" }
                    $activeGuards.Add($pItem) | Out-Null
                }
            }
        }
    }

    $ProcessDataGrid.ItemsSource = $activeGuards
    Append-Log "Process Guard checked: $($activeGuards.Count) active processes detected." "GUARD"
}

# Close Guarded Processes
function Stop-ActiveGuardedProcesses() {
    $closedCount = 0
    foreach ($t in $Script:TargetItems) {
        if ($t.IsSelected -and $t.Guard.Length -gt 0) {
            foreach ($g in $t.Guard) {
                $procs = Get-Process -Name $g -ErrorAction SilentlyContinue
                foreach ($p in $procs) {
                    try {
                        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                        Append-Log "Closed running application process: $($p.ProcessName) (PID: $($p.Id))" "PROCESS"
                        $closedCount++
                    } catch {}
                }
            }
        }
    }
    Start-Sleep -Milliseconds 400
    Update-ProcessGuardList
    return $closedCount
}

# Execute Cache Deletion
function Invoke-ExecuteClean([bool]$dryRun = $false) {
    # Force-sync IsSelected from UI checkboxes and build selected list directly
    $selected = [System.Collections.ArrayList]::new()
    foreach ($item in $Script:TargetItems) {
        $isChecked = $false
        if ($item.CheckBoxControl -and $item.CheckBoxControl.IsChecked -eq $true) {
            $isChecked = $true
        }
        if ($isChecked -or $item.IsSelected) {
            if (-not $item.IsSelected) { $item.IsSelected = $true }
            $selected.Add($item) | Out-Null
        }
    }
    Append-Log "Selection sync complete: $($selected.Count) of $($Script:TargetItems.Count) targets selected for cleaning." "DEBUG"
    if ($selected.Count -eq 0) {
        $msg = if ($Script:CurrentLang -eq "AR") { "يرجى تحديد هدف كاش واحد على الأقل للتنظيف." } else { "Please select at least one cache target to clean." }
        [System.Windows.MessageBox]::Show($msg, "ZeroCleaner", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $confirmPrompt = if ($Script:CurrentLang -eq "AR") {
        "هل أنت متأكد من رغبتك في تنظيف $($selected.Count) هدف كاش محدد؟`n`nسيقوم ZeroCleaner بحذف ملفات الكاش المؤقتة بأمان تام دون المساس بحساباتك أو كلمات السر المحفوظة."
    } else {
        "Are you sure you want to clean $($selected.Count) selected cache target(s)?`n`nZeroCleaner will safely purge temporary cache files without touching your passwords or cookies."
    }

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "Confirm Safe Cleanup",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Live Console Tab to show real-time progress
    $MainTabs.SelectedIndex = 3

    $BtnScanAll.IsEnabled = $false
    $BtnCleanSelected.IsEnabled = $false
    $StatusIcon.Text = [char]0xE7E8
    $StatusText.Text = if ($Script:CurrentLang -eq "AR") { "جاري تنظيف الكاش المحدد..." } else { "Cleaning selected caches..." }

    [System.Windows.Forms.Application]::DoEvents()

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $autoClose = $ChkAutoCloseApps.IsChecked -eq $true
    if ($autoClose) {
        Append-Log "Auto-close enabled. Terminating guarded applications holding locks..." "ACTION"
        Stop-ActiveGuardedProcesses
    }

    $freedTotalMB = 0.0
    $totalFilesDeleted = 0
    $cleanedItems = 0
    $skippedItems = 0

    foreach ($t in $selected) {
        Append-Log "Processing target: $($t.Name)" "INFO"

        if ($t.IsAdmin -and -not $isAdmin) {
            Append-Log "Skipped $($t.Name): Requires Administrator privileges." "WARN"
            $skippedItems++
            continue
        }

        if ($t.Guard.Length -gt 0 -and (Test-ProcessRunning $t.Guard)) {
            if (-not $autoClose) {
                Append-Log "Target $($t.Name): Guarded process ($($t.Guard -join ', ')) is active. Purging all unlocked files..." "INFO"
            }
        }

        if ($t.Id -eq "sys_recycle_bin") {
            try {
                $beforeBin = Get-FolderSizeMBQuick "VIRTUAL:RECYCLEBIN"
                Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
                $afterBin = Get-FolderSizeMBQuick "VIRTUAL:RECYCLEBIN"
                $freedBin = [math]::Max(0, [math]::Round(($beforeBin - $afterBin), 2))
                $freedTotalMB += $freedBin
                if ($freedBin -gt 0) {
                    Append-Log "Emptied Windows Recycle Bin (freed $(Format-SpaceMB $freedBin))!" "SUCCESS"
                    $cleanedItems++
                } else {
                    Append-Log "Windows Recycle Bin is already empty." "SUCCESS"
                    $cleanedItems++
                }
            } catch {
                Append-Log "Error emptying Recycle Bin: $($_.Exception.Message)" "ERROR"
            }
            [System.Windows.Forms.Application]::DoEvents()
            continue
        }

        if ($t.Id -eq "sys_dns_cache") {
            try {
                Clear-DnsClientCache -ErrorAction SilentlyContinue
                ipconfig /flushdns 2>$null | Out-Null
                Append-Log "Flushed Windows DNS Resolver Cache successfully!" "SUCCESS"
                $cleanedItems++
            } catch {
                Append-Log "Error flushing DNS cache: $($_.Exception.Message)" "ERROR"
            }
            [System.Windows.Forms.Application]::DoEvents()
            continue
        }

        $targetDeletedBytes = 0
        $targetDeletedFiles = 0
        $targetLockedBytes  = 0
        $targetLockedFiles  = 0

        try {
            $dirsToClean = @()
            if ($t.Path.Contains("*")) {
                $parent = Split-Path $t.Path -Parent
                $leaf = Split-Path $t.Path -Leaf
                if (Test-Path $parent) {
                    $dirsToClean = @(Get-ChildItem -Path $parent -Directory -Filter $leaf -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
                }
            } elseif (Test-Path $t.Path) {
                $dirsToClean = @($t.Path)
            }

            if ($dirsToClean.Count -gt 0) {
                foreach ($dir in $dirsToClean) {
                    # 1. Delete all individual files safely
                    $allFiles = Get-ChildItem -Path $dir -Recurse -Force -File -ErrorAction SilentlyContinue
                    if ($allFiles) {
                        $batchCounter = 0
                        foreach ($f in $allFiles) {
                            try {
                                $len = $f.Length
                                Remove-Item -LiteralPath $f.FullName -Force -Confirm:$false -ErrorAction Stop
                                $targetDeletedBytes += $len
                                $targetDeletedFiles++
                                $batchCounter++
                                # Keep UI alive every 50 files
                                if ($batchCounter % 50 -eq 0) {
                                    $StatusText.Text = if ($Script:CurrentLang -eq "AR") { "جاري التنظيف... $($t.Name) ($targetDeletedFiles ملف)" } else { "Cleaning $($t.Name)... ($targetDeletedFiles files)" }
                                    [System.Windows.Forms.Application]::DoEvents()
                                }
                            } catch {
                                $targetLockedFiles++
                                if ($f.Length) { $targetLockedBytes += $f.Length }
                                [ZeroCleaner.NativeMethods]::ScheduleDeleteOnReboot($f.FullName) | Out-Null
                            }
                        }
                    }
                    # 2. Delete empty subfolders (bottom-up)
                    Get-ChildItem -Path $dir -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Descending | ForEach-Object {
                        try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue } catch {}
                    }
                }

                $reclaimedMB = [math]::Round(($targetDeletedBytes / 1MB), 2)
                $totalFilesDeleted += $targetDeletedFiles
                $freedTotalMB += $reclaimedMB

                if ($targetDeletedFiles -gt 0) {
                    $cleanMsg = "Cleaned $targetDeletedFiles file(s) ($(Format-SpaceMB $reclaimedMB)) from $($t.Name)!"
                    if ($targetLockedFiles -gt 0) {
                        $cleanMsg += " ($targetLockedFiles file(s) locked; scheduled for deletion on next reboot)"
                    }
                    Append-Log $cleanMsg "SUCCESS"
                    $cleanedItems++
                } elseif ($targetLockedFiles -gt 0) {
                    $lockedMB = [math]::Round(($targetLockedBytes / 1MB), 1)
                    $lockMsg = if ($Script:CurrentLang -eq "AR") {
                        "الهدف $($t.Name): تم جدولة $targetLockedFiles ملف مقفل ($(Format-SpaceMB $lockedMB)) للحذف التلقائي عند إعادة التشغيل القادمة (MoveFileEx)."
                    } else {
                        "Target $($t.Name): $targetLockedFiles file(s) ($(Format-SpaceMB $lockedMB)) are in-use; scheduled for deletion on next reboot (MoveFileEx)."
                    }
                    Append-Log $lockMsg "INFO"
                    $cleanedItems++
                } else {
                    Append-Log "Target $($t.Name) checked: 0 files needed cleaning (already clean)." "SUCCESS"
                    $cleanedItems++
                }
            } else {
                Append-Log "Target $($t.Name) path is not present or already empty." "INFO"
            }
        } catch {
            Append-Log "Error cleaning $($t.Name): $($_.Exception.Message)" "ERROR"
        }

        [System.Windows.Forms.Application]::DoEvents()
    }

    $sw.Stop()
    $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

    # Play chime
    try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}

    Update-DriveInfo
    Invoke-ScanSpace $false

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E

    $freedFormatted = Format-SpaceMB $freedTotalMB

    if ($totalFilesDeleted -gt 0 -or $freedTotalMB -gt 0) {
        $summaryMsg = if ($Script:CurrentLang -eq "AR") {
            "اكتمل التنظيف بنجاح! تم حذف $totalFilesDeleted ملف وتحرير $freedFormatted عبر $cleanedItems هدف في $elapsedSec ثانية."
        } else {
            "Cleanup Complete! Deleted $totalFilesDeleted files and freed $freedFormatted across $cleanedItems target(s) in $elapsedSec s."
        }
    } else {
        $summaryMsg = if ($Script:CurrentLang -eq "AR") {
            "اكتمل الفحص والتنظيف في $elapsedSec ثانية! جميع الكاشات المحددة نظيفة بالفعل (0 MB)."
        } else {
            "Cleanup Complete in ${elapsedSec}s! Selected cache targets were already clean (0 MB)."
        }
    }

    $StatusText.Text = $summaryMsg
    Append-Log $summaryMsg "DONE"

    # Pop up native Windows Toast Notification with sound
    Show-ZeroToastNotification "ZeroCleaner" $summaryMsg
}

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
    # Recommended: 100% Login-Safe GPU shaders, Browsers, Dev caches, Gaming caches, User temp
    $recIds = @(
        "gpu_nv_dx", "gpu_nv_gl", "gpu_amd_dx", "gpu_amd_gl", "gpu_intel", "gpu_d3d",
        "br_chrome_cache", "br_chrome_code", "br_chrome_gpu", "br_edge_cache", "br_edge_code", "br_brave_cache", "br_arc", "br_firefox", "br_opera", "br_operagx",
        "dev_npm", "dev_pip", "dev_yarn", "dev_pnpm", "dev_nuget", "dev_gradle", "dev_cargo", "dev_vscode",
        "game_steam", "game_epic", "game_battlenet", "game_riot", "game_gog", "game_roblox",
        "soc_telegram", "soc_discord", "soc_slack", "soc_spotify", "soc_davinci", "soc_blender", "soc_obs", "soc_vlc",
        "sys_user_temp", "sys_recycle_bin", "sys_dns_cache", "adm_cryptnet"
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

# Wire Preset Buttons
$BtnPresetRecommended.add_Click({ Set-RecommendedSelection })
$BtnPresetAll.add_Click({ Set-AllSelections $true })
$BtnPresetBrowsers.add_Click({ Set-CategorySelection "Browser" })
$BtnPresetDev.add_Click({ Set-CategorySelection "Dev" })
$BtnPresetGaming.add_Click({ Set-CategorySelection "Gaming" })
$BtnPresetClear.add_Click({ Set-AllSelections $false })

# Wire Action Buttons
$BtnScanAll.add_Click({ Invoke-ScanSpace $false })
$BtnCleanSelected.add_Click({ Invoke-ExecuteClean $false })

# Wire Language Toggle Button
$BtnToggleLang.add_Click({
    if ($Script:CurrentLang -eq "EN") {
        Apply-Language "AR"
        Append-Log "تم تغيير لغة الواجهة إلى العربية (العراق 🇮🇶)" "LANG"
    } else {
        Apply-Language "EN"
        Append-Log "Interface language changed to English." "LANG"
    }
})

# Wire Target Inspector Search & Controls
$TxtFilterSearch.add_TextChanged({
    $query = $TxtFilterSearch.Text.Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($query)) {
        $TargetsDataGrid.ItemsSource = $Script:TargetItems
    } else {
        $filtered = $Script:TargetItems | Where-Object {
            $_.Name.ToLower().Contains($query) -or
            ($_.NameAr -and $_.NameAr.ToLower().Contains($query)) -or
            $_.Cat.ToLower().Contains($query) -or
            $_.Path.ToLower().Contains($query) -or
            $_.Description.ToLower().Contains($query)
        }
        $TargetsDataGrid.ItemsSource = $filtered
    }
})

$BtnTableRefresh.add_Click({ Invoke-ScanSpace $false })
$BtnSelectFoundOnly.add_Click({
    foreach ($item in $Script:TargetItems) {
        if ($item.SizeMB -gt 0 -and $item.CheckBoxControl.IsEnabled) {
            $item.CheckBoxControl.IsChecked = $true
        }
    }
})

# Wire Process Guard Tab
$BtnRefreshProcesses.add_Click({ Update-ProcessGuardList })
$BtnCloseAllGuards.add_Click({
    $prompt = if ($Script:CurrentLang -eq "AR") {
        "هل تريد إغلاق جميع المتصفحات ومشغلات الألعاب وبرامج المحادثة المفتوحة لتحرير ملفات الكاش؟"
    } else {
        "Close all running browsers, game launchers, and chat apps holding file locks?"
    }
    $res = [System.Windows.MessageBox]::Show($prompt, "ZeroCleaner Process Guard", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Stop-ActiveGuardedProcesses
    }
})

# Wire Log Console Buttons
$BtnCopyLogs.add_Click({
    if ($TxtLogConsole.Text) {
        [System.Windows.Clipboard]::SetText($TxtLogConsole.Text)
        $copiedMsg = if ($Script:CurrentLang -eq "AR") { "تم نسخ السجل إلى الحافظة بنجاح!" } else { "Logs copied to clipboard!" }
        [System.Windows.MessageBox]::Show($copiedMsg, "ZeroCleaner", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})
$BtnClearLogs.add_Click({
    $TxtLogConsole.Clear()
})

# Wire About Buttons
$BtnOpenTelegram.add_Click({
    try { [System.Diagnostics.Process]::Start("https://t.me/sytus") } catch {}
})
$BtnOpenInstagram.add_Click({
    try { [System.Diagnostics.Process]::Start("https://instagram.com/lnetl") } catch {}
})
# Free RAM Top Bar Button Handler
$BtnFreeRam.add_Click({
    try {
        $BtnFreeRam.IsEnabled = $false
        $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "جاري التحرير..." } else { "Freeing..." }
        [System.Windows.Forms.Application]::DoEvents()

        $osBefore = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeBeforeMB = if ($osBefore) { [math]::Round($osBefore.FreePhysicalMemory / 1024, 1) } else { 0 }

        $procsCount = [ZeroCleaner.NativeMethods]::OptimizeProcessesRam()

        $osAfter = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeAfterMB = if ($osAfter) { [math]::Round($osAfter.FreePhysicalMemory / 1024, 1) } else { 0 }
        $freedRamMB = [math]::Max(0, [math]::Round(($freeAfterMB - $freeBeforeMB), 1))
        $freedRamStr = Format-SpaceMB $freedRamMB

        $logMsg = if ($Script:CurrentLang -eq "AR") {
            "اكتمل تفريغ الرام بنجاح! تم تحرير $freedRamStr من الذاكرة الخاملة عبر $procsCount عملية نشطة."
        } else {
            "RAM Optimization Complete! Freed $freedRamStr of idle working set memory across $procsCount active process(es)."
        }

        Append-Log $logMsg "SUCCESS"
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
        Show-ZeroToastNotification "ZeroCleaner - RAM Freed" $logMsg

        $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "تم التحرير!" } else { "RAM Freed!" }
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 700
    } catch {
        Append-Log "Error optimizing RAM: $($_.Exception.Message)" "ERROR"
    } finally {
        $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { $Script:Translations["AR"].FreeRamBtn } else { $Script:Translations["EN"].FreeRamBtn }
        $BtnFreeRam.IsEnabled = $true
    }
})

$BtnCreateShortcut.add_Click({
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "ZeroCleaner.lnk"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        
        $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { (Join-Path $PSScriptRoot "ZeroCleaner-GUI.ps1") }
        $batPath = Join-Path $PSScriptRoot "ZeroCleaner-GUI.bat"
        
        if (Test-Path $batPath) {
            $shortcut.TargetPath = $batPath
            $shortcut.WorkingDirectory = $PSScriptRoot
        } else {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            $shortcut.WorkingDirectory = $PSScriptRoot
        }
        
        $shortcut.Description = "ZeroCleaner - Safe & Fast Windows Cache Cleaner"
        $shortcut.IconLocation = "$env:SystemRoot\System32\cleanmgr.exe,0"
        $shortcut.Save()

        $msg = if ($Script:CurrentLang -eq "AR") {
            "تم إنشاء اختصار ZeroCleaner على سطح المكتب بنجاح!"
        } else {
            "ZeroCleaner Desktop shortcut created successfully!"
        }
        Append-Log "Desktop shortcut created: $shortcutPath" "SHORTCUT"
        [System.Windows.MessageBox]::Show($msg, "ZeroCleaner", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Append-Log "Failed to create shortcut: $($_.Exception.Message)" "ERROR"
        [System.Windows.MessageBox]::Show("Failed to create shortcut: $($_.Exception.Message)", "ZeroCleaner", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# Tab Selection Changed Handler
$MainTabs.add_SelectionChanged({
    param($s, $e)
    if ($e.Source -is [System.Windows.Controls.TabControl]) {
        if ($MainTabs.SelectedIndex -eq 2) {
            Update-ProcessGuardList
        }
    }
})

# Window Initialized Event
$Window.add_Loaded({
    Update-DriveInfo
    Set-AllSelections $false
    $modeStr = if ($isAdmin) { "Administrator" } else { "Standard User" }
    Append-Log "ZeroCleaner v2.5 initialized. User Mode: $modeStr" "INIT"
    Invoke-ScanSpace $false
})

# Show WPF Window
[void]$Window.ShowDialog()
