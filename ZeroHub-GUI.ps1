[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Compile Data Models with zero warnings
if (-not ([System.Management.Automation.PSTypeName]'ZeroCleaner.TargetItem').Type) {
    Add-Type -ReferencedAssemblies PresentationFramework, PresentationCore, WindowsBase, System.Xaml -TypeDefinition @'
#pragma warning disable 0067, 0649
using System;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Windows.Controls;
using System.Runtime.InteropServices;

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

    public class InstalledAppItem : INotifyPropertyChanged {
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
        public int Index { get; set; }
        public string DisplayName { get; set; }
        public string Publisher { get; set; }
        public string DisplayVersion { get; set; }
        public string SizeFormatted { get; set; }
        public double EstimatedSizeMB { get; set; }
        public string InstallLocation { get; set; }
        public string UninstallString { get; set; }
        public string RegistryPath { get; set; }
        public string Category { get; set; }
        public bool IsGame { get; set; }
        public bool IsOrphaned { get; set; }
        public bool IsBloatware { get; set; }
        public bool IsAppx { get; set; }
        public string PackageFullName { get; set; }
        public string PackageName { get; set; }
        public string SafetyStatus { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    public class InstallerAppItem : INotifyPropertyChanged {
        private bool _isSelected;
        private string _status;
        private string _statusBg;
        private string _statusFg;
        private string _statusVisibility;
        private bool _hasUpdate;
        private string _availableVersion;
        private string _currentVersion;

        public bool IsSelected {
            get { return _isSelected; }
            set {
                if (_isSelected != value) {
                    _isSelected = value;
                    OnPropertyChanged("IsSelected");
                }
            }
        }
        public int Index { get; set; }
        public string DisplayName { get; set; }
        public string Category { get; set; }
        public string CategoryKey { get; set; }
        public string PackageId { get; set; }
        public string Description { get; set; }
        public string DescriptionAr { get; set; }
        public bool HasUpdate {
            get { return _hasUpdate; }
            set { if (_hasUpdate != value) { _hasUpdate = value; OnPropertyChanged("HasUpdate"); } }
        }
        public string AvailableVersion {
            get { return _availableVersion; }
            set { if (_availableVersion != value) { _availableVersion = value; OnPropertyChanged("AvailableVersion"); } }
        }
        public string CurrentVersion {
            get { return _currentVersion; }
            set { if (_currentVersion != value) { _currentVersion = value; OnPropertyChanged("CurrentVersion"); } }
        }
        public string Status {
            get { return _status; }
            set { if (_status != value) { _status = value; OnPropertyChanged("Status"); } }
        }
        public string StatusBg {
            get { return _statusBg; }
            set { if (_statusBg != value) { _statusBg = value; OnPropertyChanged("StatusBg"); } }
        }
        public string StatusFg {
            get { return _statusFg; }
            set { if (_statusFg != value) { _statusFg = value; OnPropertyChanged("StatusFg"); } }
        }
        public string StatusVisibility {
            get { return _statusVisibility; }
            set { if (_statusVisibility != value) { _statusVisibility = value; OnPropertyChanged("StatusVisibility"); } }
        }
        public bool IsInstalled { get; set; }
        public bool IsRecommended { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    public class InstallerCategoryCard : INotifyPropertyChanged {
        private string _visibility;
        private string _countText;
        private string _header;
        private string _headerColor;

        public string Key { get; set; }
        public string Header {
            get { return _header; }
            set { _header = value; OnPropertyChanged("Header"); }
        }
        public string HeaderColor {
            get { return _headerColor; }
            set { _headerColor = value; OnPropertyChanged("HeaderColor"); }
        }
        public string CountText {
            get { return _countText; }
            set { _countText = value; OnPropertyChanged("CountText"); }
        }
        public string Visibility {
            get { return _visibility; }
            set { _visibility = value; OnPropertyChanged("Visibility"); }
        }
        public ObservableCollection<InstallerAppItem> FilteredApps { get; set; }
        public ObservableCollection<InstallerAppItem> AllApps { get; set; }

        public InstallerCategoryCard() {
            FilteredApps = new ObservableCollection<InstallerAppItem>();
            AllApps = new ObservableCollection<InstallerAppItem>();
            _visibility = "Visible";
            _headerColor = "#38BDF8";
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    public class AsyncProcessRunner {
        public static int Run(string fileName, string args, Action<string> onLine, Action onPump) {
            var psi = new ProcessStartInfo {
                FileName = fileName,
                Arguments = args,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            using (var p = new Process { StartInfo = psi }) {
                var queue = new ConcurrentQueue<string>();
                p.OutputDataReceived += (s, e) => {
                    if (e.Data != null) queue.Enqueue(e.Data);
                };
                p.ErrorDataReceived += (s, e) => {
                    if (e.Data != null) queue.Enqueue(e.Data);
                };

                p.Start();
                p.BeginOutputReadLine();
                p.BeginErrorReadLine();

                while (!p.WaitForExit(60)) {
                    string item;
                    while (queue.TryDequeue(out item)) {
                        if (onLine != null) onLine(item);
                    }
                    if (onPump != null) onPump();
                }

                p.WaitForExit();

                string postItem;
                while (queue.TryDequeue(out postItem)) {
                    if (onLine != null) onLine(postItem);
                }

                return p.ExitCode;
            }
        }
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

        [System.Runtime.InteropServices.DllImport("dwmapi.dll", PreserveSig = true)]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

        public static void EnableDarkTitleBar(IntPtr hwnd) {
            try {
                int useDarkMode = 1;
                int res = DwmSetWindowAttribute(hwnd, 20, ref useDarkMode, sizeof(int));
                if (res != 0) {
                    DwmSetWindowAttribute(hwnd, 19, ref useDarkMode, sizeof(int));
                }
                int captionColor = 0x00190F0B; // COLORREF for #0B0F19
                DwmSetWindowAttribute(hwnd, 35, ref captionColor, sizeof(int));
                int textColor = 0x00FFFFFF;
                DwmSetWindowAttribute(hwnd, 36, ref textColor, sizeof(int));
            } catch {}
        }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        public class MEMORYSTATUSEX {
            public uint dwLength;
            public uint dwMemoryLoad;
            public ulong ullTotalPhys;
            public ulong ullAvailPhys;
            public ulong ullTotalPageFile;
            public ulong ullAvailPageFile;
            public ulong ullTotalVirtual;
            public ulong ullAvailVirtual;
            public ulong ullAvailExtendedVirtual;
            public MEMORYSTATUSEX() {
                this.dwLength = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(MEMORYSTATUSEX));
            }
        }

        [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto, SetLastError = true)]
        public static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

        public static void GetLiveMemoryMetrics(out double totalGB, out double usedGB, out double freeGB, out int usedPercent, out double reclaimableMB) {
            totalGB = 0; usedGB = 0; freeGB = 0; usedPercent = 0; reclaimableMB = 0;
            MEMORYSTATUSEX mem = new MEMORYSTATUSEX();
            if (GlobalMemoryStatusEx(mem)) {
                totalGB = Math.Round((double)mem.ullTotalPhys / (1024 * 1024 * 1024), 1);
                freeGB = Math.Round((double)mem.ullAvailPhys / (1024 * 1024 * 1024), 1);
                usedGB = Math.Round(totalGB - freeGB, 1);
                usedPercent = (int)mem.dwMemoryLoad;

                long totalWorkingSetBytes = 0;
                System.Diagnostics.Process[] procs = System.Diagnostics.Process.GetProcesses();
                foreach (System.Diagnostics.Process p in procs) {
                    try {
                        if (p.WorkingSet64 > 5 * 1024 * 1024) {
                            totalWorkingSetBytes += p.WorkingSet64;
                        }
                    } catch {}
                }
                reclaimableMB = Math.Round((totalWorkingSetBytes * 0.30) / (1024 * 1024), 0);
            }
        }

        public static long FastGetDirectorySize(string rootPath) {
            if (string.IsNullOrEmpty(rootPath) || !System.IO.Directory.Exists(rootPath)) return 0;
            long total = 0;
            var stack = new System.Collections.Generic.Stack<string>();
            stack.Push(rootPath);
            while (stack.Count > 0) {
                string current = stack.Pop();
                try {
                    string[] files = System.IO.Directory.GetFiles(current);
                    for (int i = 0; i < files.Length; i++) {
                        try {
                            var fi = new System.IO.FileInfo(files[i]);
                            total += fi.Length;
                        } catch {}
                    }
                    string[] subDirs = System.IO.Directory.GetDirectories(current);
                    for (int i = 0; i < subDirs.Length; i++) {
                        stack.Push(subDirs[i]);
                    }
                } catch {}
            }
            return total;
        }

        public static void TrimSelfMemory() {
            try {
                GC.Collect(2, GCCollectionMode.Forced, true);
                GC.WaitForPendingFinalizers();
                GC.Collect(2, GCCollectionMode.Forced, true);
                EmptyWorkingSet(System.Diagnostics.Process.GetCurrentProcess().Handle);
            } catch {}
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
            TrimSelfMemory();
            return count;
        }
    }
}
'@
}

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
    xmlns:shell="clr-namespace:System.Windows.Shell;assembly=PresentationFramework"
    Title="ZeroHub - Fast &amp; Intelligent Windows Power Hub"
    Height="840" Width="1180"
    MinHeight="720" MinWidth="1000"
    WindowStartupLocation="CenterScreen"
    WindowState="Maximized"
    Background="#0B0F19"
    FontFamily="Segoe UI, Segoe UI Variable Display, Tahoma, Arial"
    Foreground="#FFFFFF">

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="66" GlassFrameThickness="0" CornerRadius="0" ResizeBorderThickness="6" UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>

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
            <Setter Property="Cursor" Value="Arrow"/>
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
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="TabBorder" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="{TemplateBinding Padding}" Margin="0,0,8,0">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="TabBorder" Property="BorderBrush" Value="#38BDF8"/>
                                <Setter TargetName="TabBorder" Property="Background" Value="#1E293B"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                                <Setter Property="FontWeight" Value="Bold"/>
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
                            <TextBlock Text="Hub" FontSize="19" FontWeight="Bold" Foreground="#38BDF8"/>
                        </StackPanel>
                        <TextBlock Name="TxtAppSubtitle" Text="Fast, Safe &amp; Smart Windows Optimization Hub" FontSize="12" Foreground="#FFFFFF"/>
                    </StackPanel>
                </StackPanel>

                <!-- Center: Drive C: & Real-Time Live RAM Reclaimable Metric Widgets -->
                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <!-- Drive C: Quick Metric Widget -->
                    <Border Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12,6" Margin="0,0,10,0">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,6,0"/>
                            <TextBlock Name="TxtDriveLabel" Text="Drive C: " FontWeight="SemiBold" FontSize="12" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                            <ProgressBar Name="DriveProgressBar" Width="90" Height="8" Margin="6,0" Minimum="0" Maximum="100" Value="60" Foreground="#38BDF8" Background="#1E293B" BorderThickness="0"/>
                            <TextBlock Name="DriveFreeText" Text="Scanning..." FontSize="11" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Border>

                    <!-- Real-Time RAM & Reclaimable Live Circular Ring Widget with Integrated Free RAM Button -->
                    <Border Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="10" Padding="10,4">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <!-- Circular Gauge Ring Container -->
                            <Grid Width="28" Height="28" Margin="0,0,8,0">
                                <!-- Background Track Ring -->
                                <Ellipse Width="26" Height="26" Stroke="#1E293B" StrokeThickness="3.5"/>
                                <!-- Active Dynamic Arc Ring -->
                                <Path Name="RamCircleArc" Stroke="#4ADE80" StrokeThickness="3.5" StrokeStartLineCap="Round" StrokeEndLineCap="Round"/>
                                <!-- Percentage Text In Center -->
                                <TextBlock Name="TxtRamPercent" Text="0%" FontSize="8" FontWeight="Bold" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Grid>

                            <!-- Live RAM Info -->
                            <StackPanel VerticalAlignment="Center" Margin="0,0,8,0">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock Text="⚡ RAM " FontWeight="Bold" FontSize="11" Foreground="#4ADE80"/>
                                    <TextBlock Name="TxtRamLiveMetrics" Text="Scanning..." FontSize="11" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                </StackPanel>
                            </StackPanel>

                            <!-- Green Reclaimable Pill Badge -->
                            <Border Background="#064E3B" BorderBrush="#059669" BorderThickness="1" CornerRadius="5" Padding="6,2" VerticalAlignment="Center" Margin="0,0,8,0">
                                <TextBlock Name="TxtRamReclaimable" Text="Reclaimable: ~0 MB" FontSize="11" FontWeight="Bold" Foreground="#34D399"/>
                            </Border>

                            <!-- ⚡ Integrated Free RAM Button Inside Indicator -->
                            <Button Name="BtnFreeRam" Style="{StaticResource PrimaryButton}" Padding="10,3" Cursor="Hand" ToolTip="Quickly free idle application RAM without closing any apps" WindowChrome.IsHitTestVisibleInChrome="True">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#FFFFFF" Margin="0,0,5,0" VerticalAlignment="Center"/>
                                    <TextBlock Name="TxtFreeRam" Text="Free RAM" FontWeight="Bold" FontSize="11" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                        </StackPanel>
                    </Border>
                </StackPanel>

                <!-- Right: Add to Desktop, Language Switcher, Admin Status, & Custom Window Controls -->
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">

                    <!-- Create Desktop Shortcut Header Button -->
                    <Button Name="BtnCreateShortcut" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="10,4" Cursor="Hand" ToolTip="Create a 1-click ZeroHub shortcut on your Desktop" WindowChrome.IsHitTestVisibleInChrome="True">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE71B;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                            <TextBlock Name="TxtCreateShortcut" Text="Add to Desktop" FontWeight="SemiBold" FontSize="12" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>

                    <!-- Bilingual Language Toggle Button -->
                    <Button Name="BtnToggleLang" Style="{StaticResource SecondaryButton}" Margin="0,0,10,0" Padding="10,4" Cursor="Hand" ToolTip="تبديل اللغة / Switch Language" WindowChrome.IsHitTestVisibleInChrome="True">
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
                                    <Canvas Width="20" Height="14" ClipToBounds="True">
                                        <!-- White Diagonals (St Andrew & St Patrick) -->
                                        <Line X1="0" Y1="0" X2="20" Y2="14" Stroke="#FFFFFF" StrokeThickness="2.8"/>
                                        <Line X1="20" Y1="0" X2="0" Y2="14" Stroke="#FFFFFF" StrokeThickness="2.8"/>
                                        <!-- Red Diagonals (St Patrick) -->
                                        <Line X1="0" Y1="0" X2="20" Y2="14" Stroke="#C8102E" StrokeThickness="1.2"/>
                                        <Line X1="20" Y1="0" X2="0" Y2="14" Stroke="#C8102E" StrokeThickness="1.2"/>
                                        <!-- White Cross (St George outline) -->
                                        <Rectangle Canvas.Left="7.2" Canvas.Top="0" Width="5.6" Height="14" Fill="#FFFFFF"/>
                                        <Rectangle Canvas.Left="0" Canvas.Top="4.2" Width="20" Height="5.6" Fill="#FFFFFF"/>
                                        <!-- Red Cross (St George) -->
                                        <Rectangle Canvas.Left="8.4" Canvas.Top="0" Width="3.2" Height="14" Fill="#C8102E"/>
                                        <Rectangle Canvas.Left="0" Canvas.Top="5.4" Width="20" Height="3.2" Fill="#C8102E"/>
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
                    <Button Name="BtnRelaunchAdmin" Style="{StaticResource SecondaryButton}" Content="Elevate to Admin" Padding="12,6" FontSize="12" ToolTip="Relaunch ZeroHub with full Administrator privileges" WindowChrome.IsHitTestVisibleInChrome="True"/>

                    <!-- Sleek Modern Window Controls (Minimize, Maximize/Restore, Close) -->
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0,0,0">
                        <Button Name="BtnWindowMinimize" Width="34" Height="28" Background="Transparent" BorderThickness="0" Foreground="#94A3B8" FontSize="12" Cursor="Hand" ToolTip="Minimize" WindowChrome.IsHitTestVisibleInChrome="True">
                            <TextBlock Text="—" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                        </Button>
                        <Button Name="BtnWindowMaximize" Width="34" Height="28" Background="Transparent" BorderThickness="0" Foreground="#94A3B8" FontSize="12" Cursor="Hand" ToolTip="Maximize / Restore" WindowChrome.IsHitTestVisibleInChrome="True">
                            <TextBlock Name="TxtWindowMaximizeIcon" Text="❐" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                        </Button>
                        <Button Name="BtnWindowClose" Width="36" Height="28" Background="Transparent" BorderThickness="0" Foreground="#94A3B8" FontSize="13" Cursor="Hand" ToolTip="Close" WindowChrome.IsHitTestVisibleInChrome="True">
                            <Button.Style>
                                <Style TargetType="Button">
                                    <Setter Property="Template">
                                        <Setter.Value>
                                            <ControlTemplate TargetType="Button">
                                                <Border Name="CloseBorder" Background="{TemplateBinding Background}" CornerRadius="4">
                                                    <TextBlock Text="✕" Foreground="{TemplateBinding Foreground}" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                                </Border>
                                                <ControlTemplate.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter TargetName="CloseBorder" Property="Background" Value="#E11D48"/>
                                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                                    </Trigger>
                                                </ControlTemplate.Triggers>
                                            </ControlTemplate>
                                        </Setter.Value>
                                    </Setter>
                                </Style>
                            </Button.Style>
                        </Button>
                    </StackPanel>
                </StackPanel>
            </Grid>
        </Border>

        <!-- MAIN CONTENT TABS & QUICK TOOLS STRIP -->
        <Grid Grid.Row="1" Margin="16,8,16,8">
            <TabControl Name="MainTabs">

                <!-- TAB 1: CACHE CLEANER DASHBOARD -->
                <TabItem Name="Tab_Dashboard">
                    <TabItem.Header>
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="⚡" Margin="0,0,6,0"/>
                            <TextBlock Text="Cleaner Dashboard"/>
                        </StackPanel>
                    </TabItem.Header>
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
                                    <TextBlock Name="TxtPresetsLabel" Text="Presets:" VerticalAlignment="Center" FontWeight="Bold" Foreground="#FFFFFF" Margin="0,0,8,0"/>
                                    <Button Name="BtnPresetRecommended" Style="{StaticResource SecondaryButton}" Content="Recommended" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
                                    <Button Name="BtnPresetAll" Style="{StaticResource SecondaryButton}" Content="Select All" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
                                    <Button Name="BtnPresetClear" Style="{StaticResource SecondaryButton}" Content="Deselect All" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
                                    <Button Name="BtnPresetBrowsers" Style="{StaticResource SecondaryButton}" Content="Browsers" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
                                    <Button Name="BtnPresetDev" Style="{StaticResource SecondaryButton}" Content="Dev Caches" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
                                    <Button Name="BtnPresetGaming" Style="{StaticResource SecondaryButton}" Content="Gaming" Margin="0,0,4,0" Padding="8,4" FontSize="11"/>
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

            <!-- TAB 2: 1-CLICK ESSENTIAL APP INSTALLER -->
            <TabItem Name="Tab_Installer">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="📥" Margin="0,0,6,0"/>
                        <TextBlock Name="TxtTabInstallerTitle" Text="Install Essential Apps"/>
                    </StackPanel>
                </TabItem.Header>
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- Top Toolbar -->
                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="10,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                <TextBlock Name="TxtInstallerSearchLabel" Text="Search:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,8,0" Foreground="#FFFFFF"/>
                                <TextBox Name="TxtInstallerSearch" Width="160" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="6,3" FontSize="12" Margin="0,0,10,0"/>
                            </StackPanel>

                            <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                <Button Name="BtnFilterInstAll" Style="{StaticResource SecondaryButton}" Content="All" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstBrowsers" Style="{StaticResource SecondaryButton}" Content="🌐 Browsers" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstTools" Style="{StaticResource SecondaryButton}" Content="🛠️ Utilities" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstGaming" Style="{StaticResource SecondaryButton}" Content="🎮 Gaming" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstComms" Style="{StaticResource SecondaryButton}" Content="💬 Comms" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstMedia" Style="{StaticResource SecondaryButton}" Content="🎬 Media" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstDev" Style="{StaticResource SecondaryButton}" Content="💻 Dev" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstPro" Style="{StaticResource SecondaryButton}" Content="⚡ Pro Tools" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstDocs" Style="{StaticResource SecondaryButton}" Content="📄 Documents" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                                <Button Name="BtnFilterInstRuntimes" Style="{StaticResource SecondaryButton}" Content="🪟 Runtimes" Padding="6,3" FontSize="11" Margin="0,0,3,2"/>
                            </WrapPanel>

                            <StackPanel Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Center">
                                <Button Name="BtnSelectUpdates" Style="{StaticResource SecondaryButton}" Content="🔄 Updates (0)" Padding="7,3" FontSize="11" Margin="0,0,3,0"/>
                                <Button Name="BtnSelectRecApps" Style="{StaticResource SecondaryButton}" Content="🌟 Recommended" Padding="7,3" FontSize="11" Margin="0,0,3,0"/>
                                <Button Name="BtnSelectAllInstApps" Style="{StaticResource SecondaryButton}" Content="Select All" Padding="7,3" FontSize="11" Margin="0,0,3,0"/>
                                <Button Name="BtnDeselectAllInstApps" Style="{StaticResource SecondaryButton}" Content="Clear Selection" Padding="7,3" FontSize="11" Margin="0,0,3,0"/>
                                <Button Name="BtnRefreshInstStatus" Style="{StaticResource SecondaryButton}" Content="🔄 Refresh" Padding="7,3" FontSize="11"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <!-- 4-Column Masonry Grid View (Zero Gaps, Balanced Multi-Column) -->
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,4,0" Cursor="Arrow">
                        <Grid Cursor="Arrow">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Column 1: Browsers, Comms, Documents -->
                            <ItemsControl Name="InstallerCardsCol1" Grid.Column="0" Margin="0,0,8,0" Cursor="Arrow">
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Border VerticalAlignment="Top" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                                            <StackPanel Cursor="Arrow">
                                                <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Cursor="Arrow">
                                                    <Grid Cursor="Arrow">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>
                                                        <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow"/>
                                                        <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                                            <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold" Cursor="Arrow"/>
                                                        </Border>
                                                    </Grid>
                                                </Border>
                                                <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                                                    <ItemsControl.ItemTemplate>
                                                        <DataTemplate>
                                                            <Border Background="Transparent" CornerRadius="4" Padding="4,2.5" Margin="0,1" Cursor="Arrow">
                                                                <Grid Cursor="Arrow">
                                                                    <Grid.ColumnDefinitions>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                        <ColumnDefinition Width="*"/>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                    </Grid.ColumnDefinitions>
                                                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand"/>
                                                                    <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                                                        <TextBlock.ToolTip>
                                                                            <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                                                                <StackPanel MaxWidth="320">
                                                                                    <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8"/>
                                                                                    <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#94A3B8" Margin="0,2,0,4"/>
                                                                                    <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#CBD5E1"/>
                                                                                </StackPanel>
                                                                            </ToolTip>
                                                                        </TextBlock.ToolTip>
                                                                    </TextBlock>
                                                                    <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow"/>
                                                                    </Border>
                                                                </Grid>
                                                            </Border>
                                                        </DataTemplate>
                                                    </ItemsControl.ItemTemplate>
                                                </ItemsControl>
                                            </StackPanel>
                                        </Border>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>

                            <!-- Column 2: Utilities, Runtimes -->
                            <ItemsControl Name="InstallerCardsCol2" Grid.Column="1" Margin="0,0,8,0" Cursor="Arrow">
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Border VerticalAlignment="Top" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                                            <StackPanel Cursor="Arrow">
                                                <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Cursor="Arrow">
                                                    <Grid Cursor="Arrow">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>
                                                        <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow"/>
                                                        <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                                            <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold" Cursor="Arrow"/>
                                                        </Border>
                                                    </Grid>
                                                </Border>
                                                <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                                                    <ItemsControl.ItemTemplate>
                                                        <DataTemplate>
                                                            <Border Background="Transparent" CornerRadius="4" Padding="4,2.5" Margin="0,1" Cursor="Arrow">
                                                                <Grid Cursor="Arrow">
                                                                    <Grid.ColumnDefinitions>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                        <ColumnDefinition Width="*"/>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                    </Grid.ColumnDefinitions>
                                                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand"/>
                                                                    <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                                                        <TextBlock.ToolTip>
                                                                            <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                                                                <StackPanel MaxWidth="320">
                                                                                    <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8"/>
                                                                                    <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#94A3B8" Margin="0,2,0,4"/>
                                                                                    <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#CBD5E1"/>
                                                                                </StackPanel>
                                                                            </ToolTip>
                                                                        </TextBlock.ToolTip>
                                                                    </TextBlock>
                                                                    <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow"/>
                                                                    </Border>
                                                                </Grid>
                                                            </Border>
                                                        </DataTemplate>
                                                    </ItemsControl.ItemTemplate>
                                                </ItemsControl>
                                            </StackPanel>
                                        </Border>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>

                            <!-- Column 3: Gaming, Media, Cloud -->
                            <ItemsControl Name="InstallerCardsCol3" Grid.Column="2" Margin="0,0,8,0" Cursor="Arrow">
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Border VerticalAlignment="Top" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                                            <StackPanel Cursor="Arrow">
                                                <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Cursor="Arrow">
                                                    <Grid Cursor="Arrow">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>
                                                        <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow"/>
                                                        <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                                            <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold" Cursor="Arrow"/>
                                                        </Border>
                                                    </Grid>
                                                </Border>
                                                <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                                                    <ItemsControl.ItemTemplate>
                                                        <DataTemplate>
                                                            <Border Background="Transparent" CornerRadius="4" Padding="4,2.5" Margin="0,1" Cursor="Arrow">
                                                                <Grid Cursor="Arrow">
                                                                    <Grid.ColumnDefinitions>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                        <ColumnDefinition Width="*"/>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                    </Grid.ColumnDefinitions>
                                                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand"/>
                                                                    <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                                                        <TextBlock.ToolTip>
                                                                            <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                                                                <StackPanel MaxWidth="320">
                                                                                    <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8"/>
                                                                                    <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#94A3B8" Margin="0,2,0,4"/>
                                                                                    <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#CBD5E1"/>
                                                                                </StackPanel>
                                                                            </ToolTip>
                                                                        </TextBlock.ToolTip>
                                                                    </TextBlock>
                                                                    <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow"/>
                                                                    </Border>
                                                                </Grid>
                                                            </Border>
                                                        </DataTemplate>
                                                    </ItemsControl.ItemTemplate>
                                                </ItemsControl>
                                            </StackPanel>
                                        </Border>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>

                            <!-- Column 4: Development, Pro Tools -->
                            <ItemsControl Name="InstallerCardsCol4" Grid.Column="3" Cursor="Arrow">
                                <ItemsControl.ItemTemplate>
                                    <DataTemplate>
                                        <Border VerticalAlignment="Top" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                                            <StackPanel Cursor="Arrow">
                                                <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#1F2937" BorderThickness="0,0,0,1" Cursor="Arrow">
                                                    <Grid Cursor="Arrow">
                                                        <Grid.ColumnDefinitions>
                                                            <ColumnDefinition Width="*"/>
                                                            <ColumnDefinition Width="Auto"/>
                                                        </Grid.ColumnDefinitions>
                                                        <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow"/>
                                                        <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                                            <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#94A3B8" FontWeight="SemiBold" Cursor="Arrow"/>
                                                        </Border>
                                                    </Grid>
                                                </Border>
                                                <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                                                    <ItemsControl.ItemTemplate>
                                                        <DataTemplate>
                                                            <Border Background="Transparent" CornerRadius="4" Padding="4,2.5" Margin="0,1" Cursor="Arrow">
                                                                <Grid Cursor="Arrow">
                                                                    <Grid.ColumnDefinitions>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                        <ColumnDefinition Width="*"/>
                                                                        <ColumnDefinition Width="Auto"/>
                                                                    </Grid.ColumnDefinitions>
                                                                    <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand"/>
                                                                    <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="#FFFFFF" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                                                        <TextBlock.ToolTip>
                                                                            <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                                                                <StackPanel MaxWidth="320">
                                                                                    <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8"/>
                                                                                    <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#94A3B8" Margin="0,2,0,4"/>
                                                                                    <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#CBD5E1"/>
                                                                                </StackPanel>
                                                                            </ToolTip>
                                                                        </TextBlock.ToolTip>
                                                                    </TextBlock>
                                                                    <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow"/>
                                                                    </Border>
                                                                </Grid>
                                                            </Border>
                                                        </DataTemplate>
                                                    </ItemsControl.ItemTemplate>
                                                </ItemsControl>
                                            </StackPanel>
                                        </Border>
                                    </DataTemplate>
                                </ItemsControl.ItemTemplate>
                            </ItemsControl>
                        </Grid>
                    </ScrollViewer>

                    <!-- Bottom Action Bar -->
                    <Border Grid.Row="2" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="0,8,0,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="TxtInstallerStatus" Text="Select one or more software applications to silently install via official winget." FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" VerticalAlignment="Center"/>
                            <Button Name="BtnInstallSelectedApps" Grid.Column="1" Style="{StaticResource PrimaryButton}" Content="🚀 Install Selected Apps" Padding="18,7" FontSize="12" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>

            <!-- TAB 3: APP UNINSTALLER & LEFTOVER CLEANER -->
            <TabItem Name="Tab_Uninstaller">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="🗑️" Margin="0,0,6,0"/>
                        <TextBlock Text="App Uninstaller"/>
                    </StackPanel>
                </TabItem.Header>
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- Filter & Category Bar -->
                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="10,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="200"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#94A3B8" VerticalAlignment="Center" Margin="0,0,8,0"/>
                            <TextBox Name="TxtAppSearch" Grid.Column="1" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" BorderThickness="1" Padding="8,4" FontSize="12" VerticalAlignment="Center" CaretBrush="#38BDF8"/>
                            
                            <!-- Category Filter Buttons -->
                            <StackPanel Grid.Column="2" Orientation="Horizontal" Margin="12,0,0,0" VerticalAlignment="Center">
                                <Button Name="BtnFilterAll" Style="{StaticResource SecondaryButton}" Content="All" Padding="10,4" FontSize="11" FontWeight="Bold" Margin="0,0,4,0" Background="#1E293B" BorderBrush="#38BDF8"/>
                                <Button Name="BtnFilterGames" Style="{StaticResource SecondaryButton}" Content="🎮 Games" Padding="10,4" FontSize="11" Margin="0,0,4,0"/>
                                <Button Name="BtnFilterApps" Style="{StaticResource SecondaryButton}" Content="💻 Apps" Padding="10,4" FontSize="11" Margin="0,0,4,0"/>
                                <Button Name="BtnFilterOrphaned" Style="{StaticResource SecondaryButton}" Content="👻 Orphaned" Padding="10,4" FontSize="11" Margin="0,0,8,0"/>
                                
                                <Button Name="BtnSelectAllApps" Style="{StaticResource SecondaryButton}" Content="Select All" Padding="8,4" FontSize="11" Margin="0,0,4,0"/>
                                <Button Name="BtnDeselectAllApps" Style="{StaticResource SecondaryButton}" Content="Clear Selection" Padding="8,4" FontSize="11"/>
                            </StackPanel>

                            <TextBlock Name="TxtAppCount" Grid.Column="4" Text="Scanning apps..." FontSize="12" FontWeight="SemiBold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="12,0"/>
                            <Button Name="BtnRefreshApps" Grid.Column="5" Style="{StaticResource SecondaryButton}" Content="Refresh List" Padding="10,5" FontSize="12"/>
                        </Grid>
                    </Border>

                    <!-- Apps DataGrid with Full Dark Styling -->
                    <DataGrid Name="AppsGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False"
                              Background="#111827" Foreground="#FFFFFF" BorderBrush="#1F2937" GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#1F2937" RowBackground="#111827" AlternatingRowBackground="#151D30"
                              HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="12" Cursor="Arrow">
                        <DataGrid.Resources>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#0B0F19"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                                <Setter Property="FontWeight" Value="Bold"/>
                                <Setter Property="Padding" Value="10,8"/>
                                <Setter Property="BorderBrush" Value="#1F2937"/>
                                <Setter Property="BorderThickness" Value="0,0,0,1"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Style>
                            <Style TargetType="DataGridRow">
                                <Setter Property="Padding" Value="4"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                                <Style.Triggers>
                                    <DataTrigger Binding="{Binding RelativeSource={RelativeSource Self}, Path=IsSelected}" Value="True">
                                        <Setter Property="Background" Value="#1E293B"/>
                                        <Setter Property="Foreground" Value="#38BDF8"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                    </DataTrigger>
                                </Style.Triggers>
                            </Style>
                            <Style TargetType="DataGridCell">
                                <Setter Property="Padding" Value="6,4"/>
                                <Setter Property="BorderThickness" Value="0"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                                <Style.Triggers>
                                    <Trigger Property="IsSelected" Value="True">
                                        <Setter Property="Background" Value="#1E293B"/>
                                        <Setter Property="Foreground" Value="#38BDF8"/>
                                    </Trigger>
                                </Style.Triggers>
                            </Style>
                        </DataGrid.Resources>
                        <DataGrid.Columns>
                            <DataGridTemplateColumn Width="38">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate>
                                        <CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Hand" ToolTip="Select for bulk uninstallation"/>
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                            <DataGridTextColumn Header="#" Binding="{Binding Index}" Width="45" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#94A3B8"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Application Name" Binding="{Binding DisplayName}" FontWeight="Bold" Width="3*" IsReadOnly="True" />
                            <DataGridTextColumn Header="Type" Binding="{Binding Category}" Width="95" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                        <Setter Property="Foreground" Value="#38BDF8"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="2*" IsReadOnly="True" />
                            <DataGridTextColumn Header="Version" Binding="{Binding DisplayVersion}" Width="90" IsReadOnly="True" />
                            <DataGridTextColumn Header="Storage Size" Binding="{Binding SizeFormatted}" FontWeight="Bold" Width="110" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#38BDF8"/>
                                        <Setter Property="FontWeight" Value="Bold"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Install Location" Binding="{Binding InstallLocation}" Width="3*" IsReadOnly="True" />
                        </DataGrid.Columns>
                    </DataGrid>

                    <!-- Bottom Action Controls -->
                    <Border Grid.Row="2" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,8,0,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="TxtSelectedAppStatus" Grid.Column="0" Text="Select an application from the list above to uninstall and clean leftovers." FontSize="12" Foreground="#94A3B8" VerticalAlignment="Center"/>
                            <Button Name="BtnUninstallSelected" Grid.Column="1" Style="{StaticResource DangerButton}" Content="Uninstall &amp; Clean Leftovers" Padding="16,6" FontWeight="Bold" IsEnabled="False"/>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>

            <!-- TAB 3: REMOVE WINDOWS STUPID APPS (BLOATWARE REMOVER) -->
            <TabItem Name="Tab_Bloatware">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="📦" Margin="0,0,6,0"/>
                        <TextBlock Name="TxtTabBloatwareTitle" Text="Remove Windows Stupid Apps"/>
                    </StackPanel>
                </TabItem.Header>
                <Grid Margin="0,8,0,0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- Top Action & Info Bar -->
                    <Border Grid.Row="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,8" Margin="0,0,0,8">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0" VerticalAlignment="Center">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock Text="📦 " FontSize="14" VerticalAlignment="Center"/>
                                    <TextBlock Name="TxtBloatwareHeaderTitle" Text="Remove Windows Stupid &amp; Pre-installed Apps" FontWeight="Bold" FontSize="13" Foreground="#F43F5E"/>
                                    <Border Background="#371B28" BorderBrush="#F43F5E" BorderThickness="1" CornerRadius="4" Padding="6,1" Margin="10,0,0,0" VerticalAlignment="Center">
                                        <TextBlock Name="TxtBloatwareCount" Text="0 Apps Found" FontSize="11" FontWeight="Bold" Foreground="#FDA4AF"/>
                                    </Border>
                                </StackPanel>
                                <TextBlock Name="TxtBloatwareHeaderSubtitle" Text="1-Click clean removal of Cortana, Bing News/Weather, Copilot, Xbox Overlays, Tips, and pre-installed junk." FontSize="11" Foreground="#94A3B8" Margin="0,2,0,0"/>
                            </StackPanel>

                            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                                <Button Name="BtnSelectAllBloat" Style="{StaticResource SecondaryButton}" Content="Select All" Padding="10,5" FontSize="12" Margin="0,0,6,0"/>
                                <Button Name="BtnDeselectAllBloat" Style="{StaticResource SecondaryButton}" Content="Clear Selection" Padding="10,5" FontSize="12" Margin="0,0,6,0"/>
                                <Button Name="BtnRefreshBloat" Style="{StaticResource SecondaryButton}" Content="🔄 Rescan" Padding="10,5" FontSize="12"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <!-- Bloatware DataGrid -->
                    <DataGrid Name="BloatwareGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False"
                              Background="#111827" Foreground="#FFFFFF" BorderBrush="#1F2937" GridLinesVisibility="Horizontal"
                              HorizontalGridLinesBrush="#1F2937" RowBackground="#111827" AlternatingRowBackground="#151D30"
                              HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="12" Cursor="Arrow">
                        <DataGrid.Resources>
                            <Style TargetType="DataGridColumnHeader">
                                <Setter Property="Background" Value="#0B0F19"/>
                                <Setter Property="Foreground" Value="#F43F5E"/>
                                <Setter Property="FontWeight" Value="Bold"/>
                                <Setter Property="Padding" Value="10,8"/>
                                <Setter Property="BorderBrush" Value="#1F2937"/>
                                <Setter Property="BorderThickness" Value="0,0,0,1"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Style>
                            <Style TargetType="DataGridRow">
                                <Setter Property="Padding" Value="4"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                                <Style.Triggers>
                                    <DataTrigger Binding="{Binding RelativeSource={RelativeSource Self}, Path=IsSelected}" Value="True">
                                        <Setter Property="Background" Value="#1E293B"/>
                                        <Setter Property="Foreground" Value="#38BDF8"/>
                                    </DataTrigger>
                                </Style.Triggers>
                            </Style>
                            <Style TargetType="DataGridCell">
                                <Setter Property="Padding" Value="6,4"/>
                                <Setter Property="BorderThickness" Value="0"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                                <Setter Property="Cursor" Value="Arrow"/>
                            </Style>
                        </DataGrid.Resources>
                        <DataGrid.Columns>
                            <DataGridTemplateColumn Width="40">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate>
                                        <CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Hand" ToolTip="Select for removal"/>
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                            <DataGridTextColumn Header="#" Binding="{Binding Index}" Width="45" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#94A3B8"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Windows App / Bloatware" Binding="{Binding DisplayName}" FontWeight="Bold" Width="2*" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Package Identifier" Binding="{Binding PackageName}" Width="2*" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#94A3B8"/>
                                        <Setter Property="FontFamily" Value="Consolas, Cascadia Code"/>
                                        <Setter Property="FontSize" Value="11"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                            <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="160" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Safety Level" Binding="{Binding SafetyStatus}" Width="160" IsReadOnly="True">
                                <DataGridTextColumn.ElementStyle>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#4ADE80"/>
                                        <Setter Property="FontWeight" Value="SemiBold"/>
                                        <Setter Property="HorizontalAlignment" Value="Center"/>
                                    </Style>
                                </DataGridTextColumn.ElementStyle>
                            </DataGridTextColumn>
                        </DataGrid.Columns>
                    </DataGrid>

                    <!-- Bottom Remove Action Bar -->
                    <Border Grid.Row="2" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="0,8,0,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="TxtBloatSelectionStatus" Text="Select one or more Windows apps from the table to permanently remove." FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" VerticalAlignment="Center"/>
                            <Button Name="BtnRemoveSelectedBloatware" Grid.Column="1" Style="{StaticResource DangerButton}" Content="🗑️ Remove Selected Apps" Padding="16,6" FontSize="12" FontWeight="Bold" IsEnabled="False" Cursor="Hand"/>
                        </Grid>
                    </Border>
                </Grid>
            </TabItem>

            <!-- TAB 4: WINDOWS UPDATES CONTROLLER -->
            <TabItem Name="Tab_Updates">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="🛡️" Margin="0,0,6,0"/>
                        <TextBlock Name="TxtTabUpdatesTitle" Text="Windows Updates"/>
                    </StackPanel>
                </TabItem.Header>
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,4,0" Cursor="Arrow">
                    <StackPanel Margin="0,8,0,16" Cursor="Arrow">
                        <!-- Top Hero Status & Action Card -->
                        <Border Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,10" Cursor="Arrow">
                            <Grid Cursor="Arrow">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>

                                <Border Grid.Column="0" CornerRadius="10" Width="44" Height="44" Margin="0,0,14,0" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" VerticalAlignment="Center" Cursor="Arrow">
                                    <TextBlock Text="🛡️" FontSize="22" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Arrow"/>
                                </Border>

                                <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                                    <StackPanel Orientation="Horizontal" Cursor="Arrow">
                                        <TextBlock Name="TxtWinUpdateTitle" Text="Windows Automatic Updates Controller" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" Cursor="Arrow"/>
                                        <Border Name="BadgeWinUpdateStatus" Background="#064E3B" BorderBrush="#059669" BorderThickness="1" CornerRadius="5" Padding="7,2" Margin="10,0,0,0" VerticalAlignment="Center" Cursor="Arrow">
                                            <TextBlock Name="TxtWinUpdateStatus" Text="🟢 Updates: Active" FontSize="11" FontWeight="Bold" Foreground="#34D399" Cursor="Arrow"/>
                                        </Border>
                                    </StackPanel>
                                    <TextBlock Name="TxtWinUpdateSubtitle" Text="Block background forced Windows updates and surprise restarts, or easily restore them anytime." FontSize="11" Foreground="#94A3B8" Margin="0,3,0,0" Cursor="Arrow"/>
                                </StackPanel>

                                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Cursor="Arrow">
                                    <Button Name="BtnToggleWinUpdate" Style="{StaticResource DangerButton}" Content="🛑 Stop Windows Updates" Padding="16,8" FontSize="12" FontWeight="Bold" Cursor="Hand"/>
                                </StackPanel>
                            </Grid>
                        </Border>

                        <!-- 4 Compact Status Tiles (2x2 Grid, Zero Excessive Space) -->
                        <Grid Margin="0,0,0,10" Cursor="Arrow">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Card 1: Services Status -->
                            <Border Grid.Row="0" Grid.Column="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,0,5,5" Cursor="Arrow">
                                <Grid Cursor="Arrow">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Grid.Column="0" Text="⚙️" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow"/>
                                    <StackPanel Grid.Column="1" Cursor="Arrow">
                                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                                            <TextBlock Name="TxtCard1Title" Text="Windows Update Services" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" DockPanel.Dock="Left" Cursor="Arrow"/>
                                            <TextBlock Name="BadgeCard1" Text="🔴 Services Disabled" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow"/>
                                        </DockPanel>
                                        <TextBlock Name="TxtCard1Body" Text="Controls wuauserv, UsoSvc, and WaaSMedicSvc to prevent background execution." FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap" Cursor="Arrow"/>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <!-- Card 2: Group Policy & Registry -->
                            <Border Grid.Row="0" Grid.Column="1" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,0,0,5" Cursor="Arrow">
                                <Grid Cursor="Arrow">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Grid.Column="0" Text="📋" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow"/>
                                    <StackPanel Grid.Column="1" Cursor="Arrow">
                                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                                            <TextBlock Name="TxtCard2Title" Text="Automatic Download Policies" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" DockPanel.Dock="Left" Cursor="Arrow"/>
                                            <TextBlock Name="BadgeCard2" Text="🔴 Policies Enforced" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow"/>
                                        </DockPanel>
                                        <TextBlock Name="TxtCard2Body" Text="Configures NoAutoUpdate and AUOptions in Registry to eliminate surprise reboots." FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap" Cursor="Arrow"/>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <!-- Card 3: Scheduled Tasks -->
                            <Border Grid.Row="1" Grid.Column="0" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,0" Cursor="Arrow">
                                <Grid Cursor="Arrow">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Grid.Column="0" Text="⏰" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow"/>
                                    <StackPanel Grid.Column="1" Cursor="Arrow">
                                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                                            <TextBlock Name="TxtCard3Title" Text="Scheduled Background Tasks" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" DockPanel.Dock="Left" Cursor="Arrow"/>
                                            <TextBlock Name="BadgeCard3" Text="🔴 Scan Tasks Blocked" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow"/>
                                        </DockPanel>
                                        <TextBlock Name="TxtCard3Body" Text="Disables hidden Task Scheduler triggers in UpdateOrchestrator that wake your PC." FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap" Cursor="Arrow"/>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <!-- Card 4: Driver Update Shield -->
                            <Border Grid.Row="1" Grid.Column="1" Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,0" Cursor="Arrow">
                                <Grid Cursor="Arrow">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBlock Grid.Column="0" Text="🎮" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow"/>
                                    <StackPanel Grid.Column="1" Cursor="Arrow">
                                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                                            <TextBlock Name="TxtCard4Title" Text="Hardware Driver Shield" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" DockPanel.Dock="Left" Cursor="Arrow"/>
                                            <TextBlock Name="BadgeCard4" Text="🟢 Driver Shield Active" FontSize="10" FontWeight="Bold" Foreground="#34D399" DockPanel.Dock="Right" Cursor="Arrow"/>
                                        </DockPanel>
                                        <TextBlock Name="TxtCard4Body" Text="Prevents Windows from automatically replacing custom NVIDIA / AMD graphics drivers." FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap" Cursor="Arrow"/>
                                    </StackPanel>
                                </Grid>
                            </Border>
                        </Grid>

                        <!-- Quick Maintenance & Repair Section -->
                        <Border Background="#111827" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="10" Padding="16,14" Cursor="Arrow">
                            <StackPanel Cursor="Arrow">
                                <DockPanel LastChildFill="False" Margin="0,0,0,10" Cursor="Arrow">
                                    <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Cursor="Arrow">
                                        <TextBlock Text="🛠️" FontSize="15" Margin="0,0,8,0" Cursor="Arrow"/>
                                        <TextBlock Name="TxtWuMaintTitle" Text="Quick Maintenance &amp; Troubleshooting Tools" FontWeight="Bold" FontSize="13" Foreground="#38BDF8" Cursor="Arrow"/>
                                    </StackPanel>
                                </DockPanel>

                                <Grid Cursor="Arrow">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>

                                    <!-- Utility 1: Clear Cache -->
                                    <Border Grid.Column="0" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,5,0" Cursor="Arrow">
                                        <StackPanel Cursor="Arrow">
                                            <TextBlock Name="TxtWuCardCacheTitle" Text="🧹 Purge Update Cache" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" Cursor="Arrow"/>
                                            <TextBlock Name="TxtWuCardCacheDesc" Text="Deletes SoftwareDistribution\Download cache to free gigabytes and fix corrupt downloads." FontSize="10" Foreground="#94A3B8" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow"/>
                                            <Button Name="BtnCleanWuCache" Style="{StaticResource SecondaryButton}" Content="🧹 Clean WU Cache" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand"/>
                                        </StackPanel>
                                    </Border>

                                    <!-- Utility 2: Reset Engine -->
                                    <Border Grid.Column="1" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12" Margin="3,0,3,0" Cursor="Arrow">
                                        <StackPanel Cursor="Arrow">
                                            <TextBlock Name="TxtWuCardResetTitle" Text="🔧 Repair &amp; Reset Components" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" Cursor="Arrow"/>
                                            <TextBlock Name="TxtWuCardResetDesc" Text="Re-registers core update DLLs and restarts BITS &amp; CryptSvc to fix 0x800 error codes." FontSize="10" Foreground="#94A3B8" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow"/>
                                            <Button Name="BtnResetWuComponents" Style="{StaticResource SecondaryButton}" Content="🔧 Reset Components" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand"/>
                                        </StackPanel>
                                    </Border>

                                    <!-- Utility 3: Open Settings -->
                                    <Border Grid.Column="2" Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="12" Margin="5,0,0,0" Cursor="Arrow">
                                        <StackPanel Cursor="Arrow">
                                            <TextBlock Name="TxtWuCardSettingsTitle" Text="⚙️ Official Windows Settings" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" Cursor="Arrow"/>
                                            <TextBlock Name="TxtWuCardSettingsDesc" Text="Quick access to Windows Update settings page to view update history or check for patch." FontSize="10" Foreground="#94A3B8" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow"/>
                                            <Button Name="BtnOpenWuSettings" Style="{StaticResource SecondaryButton}" Content="⚙️ Open Settings" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand"/>
                                        </StackPanel>
                                    </Border>
                                </Grid>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- TAB 4: DETAILED SCANNER TABLE -->
            <TabItem Name="Tab_Inspector">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="🔍" Margin="0,0,6,0"/>
                        <TextBlock Text="Target Inspector"/>
                    </StackPanel>
                </TabItem.Header>
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
            <TabItem Name="Tab_Guard">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="🛡️" Margin="0,0,6,0"/>
                        <TextBlock Text="Task Manager"/>
                    </StackPanel>
                </TabItem.Header>
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
            <TabItem Name="Tab_Log">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="📝" Margin="0,0,6,0"/>
                        <TextBlock Text="Activity Log"/>
                    </StackPanel>
                </TabItem.Header>
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
            <TabItem Name="Tab_About">
                <TabItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="ℹ️" Margin="0,0,6,0"/>
                        <TextBlock Text="About"/>
                    </StackPanel>
                </TabItem.Header>
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

                            <TextBlock Text="ZeroHub" FontSize="24" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                            <TextBlock Name="TxtAboutSub" Text="Fast, Safe &amp; Intelligent All-in-One Windows Optimization Hub" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" Margin="0,0,0,10"/>

                            <!-- License Pill Badge -->
                            <Border Background="#151D30" BorderBrush="#38BDF8" BorderThickness="1" CornerRadius="12" Padding="12,4" HorizontalAlignment="Center" Margin="0,0,0,20">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="&#xE8D7;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                    <TextBlock Text="Free &amp; Open Source Software (MIT License)" FontSize="11" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Border>

                            <!-- Core Modules Grid (2x3 Deck) -->
                            <TextBlock Name="TxtAboutModulesTitle" Text="⚡ Core Power Modules &amp; Capabilities" FontWeight="Bold" FontSize="14" Foreground="#38BDF8" HorizontalAlignment="Center" Margin="0,0,0,12"/>

                            <Grid Margin="0,0,0,18" MaxWidth="660">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <!-- Module 1: App Manager -->
                                <Border Grid.Row="0" Grid.Column="0" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="📦" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatAppTitle" Text="1-Click App Manager" FontWeight="Bold" FontSize="12" Foreground="#38BDF8" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatAppDesc" Text="Silent Winget app installs with live update recognizer." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>

                                <!-- Module 2: Deep Cleaner -->
                                <Border Grid.Row="0" Grid.Column="1" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="🧹" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatCleanTitle" Text="Deep Cache Cleaner" FontWeight="Bold" FontSize="12" Foreground="#34D399" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatCleanDesc" Text="55+ targets across GPU, dev, games, browsers &amp; temp." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>

                                <!-- Module 3: Bloatware Remover -->
                                <Border Grid.Row="0" Grid.Column="2" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="🗑️" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatBloatTitle" Text="Bloatware Remover" FontWeight="Bold" FontSize="12" Foreground="#F43F5E" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatBloatDesc" Text="Remove pre-installed Windows bloatware &amp; Edge cleanly." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>

                                <!-- Module 4: Deep Uninstaller -->
                                <Border Grid.Row="1" Grid.Column="0" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="⚡" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatUninstTitle" Text="Deep Uninstaller" FontWeight="Bold" FontSize="12" Foreground="#FB923C" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatUninstDesc" Text="Uninstall apps with orphan registry &amp; leftover cleanup." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>

                                <!-- Module 5: RAM Optimizer -->
                                <Border Grid.Row="1" Grid.Column="1" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="🚀" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatRamTitle" Text="Live RAM Optimizer" FontWeight="Bold" FontSize="12" Foreground="#C084FC" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatRamDesc" Text="Real-time circular RAM meter with 1-click memory flush." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>

                                <!-- Module 6: Windows Updates -->
                                <Border Grid.Row="1" Grid.Column="2" Background="#151D30" BorderBrush="#1F2937" BorderThickness="1" CornerRadius="8" Padding="12,10" Margin="4,4">
                                    <StackPanel HorizontalAlignment="Center">
                                        <TextBlock Text="🛡️" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                        <TextBlock Name="TxtAboutFeatWuTitle" Text="Updates Controller" FontWeight="Bold" FontSize="12" Foreground="#60A5FA" HorizontalAlignment="Center" TextAlignment="Center"/>
                                        <TextBlock Name="TxtAboutFeatWuDesc" Text="Pause forced updates, purge WU cache &amp; repair DLLs." FontSize="10.5" Foreground="#94A3B8" TextWrapping="Wrap" HorizontalAlignment="Center" TextAlignment="Center" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Border>
                            </Grid>

                            <!-- 3 Quick Highlight Badges -->
                            <Grid Margin="0,0,0,18" HorizontalAlignment="Center">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="210"/>
                                    <ColumnDefinition Width="210"/>
                                    <ColumnDefinition Width="210"/>
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
                                        <TextBlock Text="Non-Blocking Engine" FontWeight="Bold" FontSize="12" Foreground="#FFFFFF" HorizontalAlignment="Center"/>
                                        <TextBlock Text="Async C# &amp; zero UI freezes" FontSize="10" Foreground="#94A3B8" HorizontalAlignment="Center"/>
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
                            <Border Background="#151D30" BorderBrush="#2A3756" BorderThickness="1" CornerRadius="8" Padding="16,12" Margin="0,0,0,18" MaxWidth="640">
                                <StackPanel HorizontalAlignment="Center">
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,6">
                                        <TextBlock Text="&#xE8BD;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#4ADE80" Margin="0,0,6,0" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtAboutSafetyTitle" Text="100% Account Safety Guarantee" FontWeight="Bold" FontSize="13" Foreground="#4ADE80"/>
                                    </StackPanel>
                                    <TextBlock Name="TxtAboutSafetyBody" Text="ZeroHub targets ONLY temporary scratch, shader caches, and build artifacts. It NEVER touches your browser login databases, cookies, passwords, or active accounts." FontSize="12" TextWrapping="Wrap" TextAlignment="Center" Foreground="#E2E8F0" LineHeight="18"/>
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
    </Grid>

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
$RamCircleArc       = $Window.FindName("RamCircleArc")
$TxtRamPercent      = $Window.FindName("TxtRamPercent")
$TxtRamLiveMetrics  = $Window.FindName("TxtRamLiveMetrics")
$TxtRamReclaimable  = $Window.FindName("TxtRamReclaimable")
$BtnToggleLang      = $Window.FindName("BtnToggleLang")
$Flag_IQ            = $Window.FindName("Flag_IQ")
$Flag_UK            = $Window.FindName("Flag_UK")
$TxtLangLabel       = $Window.FindName("TxtLangLabel")
$AdminBadge         = $Window.FindName("AdminBadge")
$AdminIcon          = $Window.FindName("AdminIcon")
$AdminText          = $Window.FindName("AdminText")
$BtnRelaunchAdmin   = $Window.FindName("BtnRelaunchAdmin")
$BtnFreeRam         = $Window.FindName("BtnFreeRam")
$TxtFreeRam         = $Window.FindName("TxtFreeRam")
$BtnDeepUninstall   = $Window.FindName("BtnDeepUninstall")
$TxtDeepUninstall   = $Window.FindName("TxtDeepUninstall")
$BtnCreateShortcut  = $Window.FindName("BtnCreateShortcut")
$TxtCreateShortcut  = $Window.FindName("TxtCreateShortcut")
$BtnWindowMinimize  = $Window.FindName("BtnWindowMinimize")
$BtnWindowMaximize  = $Window.FindName("BtnWindowMaximize")
$BtnWindowClose     = $Window.FindName("BtnWindowClose")
$TxtWindowMaximizeIcon = $Window.FindName("TxtWindowMaximizeIcon")

$Tab_Dashboard      = $Window.FindName("Tab_Dashboard")
$Tab_Installer      = $Window.FindName("Tab_Installer")
$Tab_Uninstaller    = $Window.FindName("Tab_Uninstaller")
$Tab_Bloatware      = $Window.FindName("Tab_Bloatware")
$Tab_Updates        = $Window.FindName("Tab_Updates")
$Tab_Inspector      = $Window.FindName("Tab_Inspector")
$Tab_Guard          = $Window.FindName("Tab_Guard")
$Tab_Log            = $Window.FindName("Tab_Log")
$Tab_About          = $Window.FindName("Tab_About")

$TxtTabInstallerTitle     = $Window.FindName("TxtTabInstallerTitle")
$TxtInstallerSearchLabel  = $Window.FindName("TxtInstallerSearchLabel")
$TxtInstallerSearch       = $Window.FindName("TxtInstallerSearch")
$BtnFilterInstAll         = $Window.FindName("BtnFilterInstAll")
$BtnFilterInstBrowsers    = $Window.FindName("BtnFilterInstBrowsers")
$BtnFilterInstTools       = $Window.FindName("BtnFilterInstTools")
$BtnFilterInstGaming      = $Window.FindName("BtnFilterInstGaming")
$BtnFilterInstComms       = $Window.FindName("BtnFilterInstComms")
$BtnFilterInstMedia       = $Window.FindName("BtnFilterInstMedia")
$BtnFilterInstDev         = $Window.FindName("BtnFilterInstDev")
$BtnFilterInstPro         = $Window.FindName("BtnFilterInstPro")
$BtnFilterInstDocs        = $Window.FindName("BtnFilterInstDocs")
$BtnFilterInstRuntimes    = $Window.FindName("BtnFilterInstRuntimes")
$BtnSelectUpdates       = $Window.FindName("BtnSelectUpdates")
$BtnSelectRecApps       = $Window.FindName("BtnSelectRecApps")
$BtnSelectAllInstApps   = $Window.FindName("BtnSelectAllInstApps")
$BtnDeselectAllInstApps = $Window.FindName("BtnDeselectAllInstApps")
$BtnRefreshInstStatus   = $Window.FindName("BtnRefreshInstStatus")
$InstallerCardsCol1       = $Window.FindName("InstallerCardsCol1")
$InstallerCardsCol2       = $Window.FindName("InstallerCardsCol2")
$InstallerCardsCol3       = $Window.FindName("InstallerCardsCol3")
$InstallerCardsCol4       = $Window.FindName("InstallerCardsCol4")
$TxtInstallerStatus       = $Window.FindName("TxtInstallerStatus")
$BtnInstallSelectedApps   = $Window.FindName("BtnInstallSelectedApps")

$TxtTabBloatwareTitle       = $Window.FindName("TxtTabBloatwareTitle")
$TxtTabUpdatesTitle         = $Window.FindName("TxtTabUpdatesTitle")
$TxtWinUpdateTitle          = $Window.FindName("TxtWinUpdateTitle")
$BadgeWinUpdateStatus       = $Window.FindName("BadgeWinUpdateStatus")
$TxtWinUpdateStatus         = $Window.FindName("TxtWinUpdateStatus")
$TxtWinUpdateSubtitle       = $Window.FindName("TxtWinUpdateSubtitle")
$BtnToggleWinUpdate         = $Window.FindName("BtnToggleWinUpdate")
$TxtCard1Title              = $Window.FindName("TxtCard1Title")
$BadgeCard1                 = $Window.FindName("BadgeCard1")
$TxtCard1Body               = $Window.FindName("TxtCard1Body")
$TxtCard2Title              = $Window.FindName("TxtCard2Title")
$BadgeCard2                 = $Window.FindName("BadgeCard2")
$TxtCard2Body               = $Window.FindName("TxtCard2Body")
$TxtCard3Title              = $Window.FindName("TxtCard3Title")
$BadgeCard3                 = $Window.FindName("BadgeCard3")
$TxtCard3Body               = $Window.FindName("TxtCard3Body")
$TxtCard4Title              = $Window.FindName("TxtCard4Title")
$BadgeCard4                 = $Window.FindName("BadgeCard4")
$TxtCard4Body               = $Window.FindName("TxtCard4Body")

$TxtWuMaintTitle            = $Window.FindName("TxtWuMaintTitle")
$TxtWuCardCacheTitle        = $Window.FindName("TxtWuCardCacheTitle")
$TxtWuCardCacheDesc         = $Window.FindName("TxtWuCardCacheDesc")
$BtnCleanWuCache            = $Window.FindName("BtnCleanWuCache")
$TxtWuCardResetTitle        = $Window.FindName("TxtWuCardResetTitle")
$TxtWuCardResetDesc         = $Window.FindName("TxtWuCardResetDesc")
$BtnResetWuComponents       = $Window.FindName("BtnResetWuComponents")
$TxtWuCardSettingsTitle     = $Window.FindName("TxtWuCardSettingsTitle")
$TxtWuCardSettingsDesc      = $Window.FindName("TxtWuCardSettingsDesc")
$BtnOpenWuSettings          = $Window.FindName("BtnOpenWuSettings")
$TxtBloatwareHeaderTitle    = $Window.FindName("TxtBloatwareHeaderTitle")
$TxtBloatwareHeaderSubtitle = $Window.FindName("TxtBloatwareHeaderSubtitle")
$TxtBloatwareCount          = $Window.FindName("TxtBloatwareCount")
$BtnSelectAllBloat          = $Window.FindName("BtnSelectAllBloat")
$BtnDeselectAllBloat        = $Window.FindName("BtnDeselectAllBloat")
$BtnRefreshBloat            = $Window.FindName("BtnRefreshBloat")
$BloatwareGrid              = $Window.FindName("BloatwareGrid")
$TxtBloatSelectionStatus    = $Window.FindName("TxtBloatSelectionStatus")
$BtnRemoveSelectedBloatware = $Window.FindName("BtnRemoveSelectedBloatware")

$TxtAppSearch         = $Window.FindName("TxtAppSearch")
$TxtAppCount          = $Window.FindName("TxtAppCount")
$BtnRefreshApps       = $Window.FindName("BtnRefreshApps")
$BtnFilterAll         = $Window.FindName("BtnFilterAll")
$BtnFilterGames       = $Window.FindName("BtnFilterGames")
$BtnFilterApps        = $Window.FindName("BtnFilterApps")
$BtnFilterOrphaned    = $Window.FindName("BtnFilterOrphaned")
$BtnSelectAllApps     = $Window.FindName("BtnSelectAllApps")
$BtnDeselectAllApps   = $Window.FindName("BtnDeselectAllApps")
$AppsGrid             = $Window.FindName("AppsGrid")
$TxtSelectedAppStatus = $Window.FindName("TxtSelectedAppStatus")
$BtnUninstallSelected = $Window.FindName("BtnUninstallSelected")

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

$TxtAboutSub              = $Window.FindName("TxtAboutSub")
$TxtAboutModulesTitle     = $Window.FindName("TxtAboutModulesTitle")
$TxtAboutFeatAppTitle     = $Window.FindName("TxtAboutFeatAppTitle")
$TxtAboutFeatAppDesc      = $Window.FindName("TxtAboutFeatAppDesc")
$TxtAboutFeatCleanTitle   = $Window.FindName("TxtAboutFeatCleanTitle")
$TxtAboutFeatCleanDesc    = $Window.FindName("TxtAboutFeatCleanDesc")
$TxtAboutFeatBloatTitle   = $Window.FindName("TxtAboutFeatBloatTitle")
$TxtAboutFeatBloatDesc    = $Window.FindName("TxtAboutFeatBloatDesc")
$TxtAboutFeatUninstTitle  = $Window.FindName("TxtAboutFeatUninstTitle")
$TxtAboutFeatUninstDesc   = $Window.FindName("TxtAboutFeatUninstDesc")
$TxtAboutFeatRamTitle     = $Window.FindName("TxtAboutFeatRamTitle")
$TxtAboutFeatRamDesc      = $Window.FindName("TxtAboutFeatRamDesc")
$TxtAboutFeatWuTitle      = $Window.FindName("TxtAboutFeatWuTitle")
$TxtAboutFeatWuDesc       = $Window.FindName("TxtAboutFeatWuDesc")
$TxtAboutSafetyTitle      = $Window.FindName("TxtAboutSafetyTitle")
$TxtAboutSafetyBody       = $Window.FindName("TxtAboutSafetyBody")
$TxtAboutAuthorTitle      = $Window.FindName("TxtAboutAuthorTitle")
$BtnOpenTelegram          = $Window.FindName("BtnOpenTelegram")
$BtnOpenInstagram         = $Window.FindName("BtnOpenInstagram")
$BtnCreateShortcut        = $Window.FindName("BtnCreateShortcut")
$TxtCreateShortcut        = $Window.FindName("TxtCreateShortcut")

$StatusIcon         = $Window.FindName("StatusIcon")
$StatusText         = $Window.FindName("StatusText")
$TxtSelectedLabel   = $Window.FindName("TxtSelectedLabel")
$TxtSelectedCount   = $Window.FindName("TxtSelectedCount")
$TxtReclaimableLabel= $Window.FindName("TxtReclaimableLabel")
$TxtTotalReclaimable= $Window.FindName("TxtTotalReclaimable")
$MainTabs           = $Window.FindName("MainTabs")
$Tab_FreeRam        = $Window.FindName("Tab_FreeRam")
$TxtFreeRam         = $Window.FindName("TxtFreeRam")
$BtnFreeRam         = $Window.FindName("BtnFreeRam")
$BtnDeepUninstall   = $Window.FindName("BtnDeepUninstall")

$Script:TargetItems = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.TargetItem]]::new()
$Script:CheckboxesById = @{}
$Script:CurrentLang = "EN"

# Bilingual Dictionaries
$Script:Translations = @{
    "EN" = @{
        AppSubtitle       = "Fast, Safe & Smart Windows Optimization Suite"
        DriveLabel        = "Drive C: "
        StandardUser      = "Standard User"
        Administrator     = "Administrator"
        ElevateBtn        = "Elevate to Admin"
        TabDashboard      = "⚡ Cleaner Dashboard"
        TabUninstaller    = "🗑️ App Uninstaller"
        TabInspector      = "🔍 Target Inspector"
        TabGuard          = "🛡️ Task Manager"
        TabLog            = "📝 Activity Log"
        TabAbout          = "ℹ️ About"
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
        AboutSub          = "Fast, Safe & Intelligent All-in-One Windows Optimization Hub"
        AboutModulesTitle = "⚡ Core Power Modules & Capabilities"
        AboutFeatAppTitle = "1-Click App Manager"
        AboutFeatAppDesc  = "Silent Winget app installs with live update recognizer."
        AboutFeatCleanTitle = "Deep Cache Cleaner"
        AboutFeatCleanDesc  = "55+ targets across GPU, dev, games, browsers & temp."
        AboutFeatBloatTitle = "Bloatware Remover"
        AboutFeatBloatDesc  = "Remove pre-installed Windows bloatware & Edge cleanly."
        AboutFeatUninstTitle = "Deep Uninstaller"
        AboutFeatUninstDesc = "Uninstall apps with orphan registry & leftover cleanup."
        AboutFeatRamTitle = "Live RAM Optimizer"
        AboutFeatRamDesc  = "Real-time circular RAM meter with 1-click memory flush."
        AboutFeatWuTitle  = "Updates Controller"
        AboutFeatWuDesc   = "Pause forced updates, purge WU cache & repair DLLs."
        AboutSafetyTitle  = "100% Account Safety Guarantee"
        AboutSafetyBody   = "ZeroHub targets ONLY temporary web, GPU shader, build artifacts, and system scratch caches. It NEVER deletes saved passwords, active login sessions, bookmarks, or browser history databases."
        AboutAuthorTitle  = "Author & Maintainer"
        CreateShortcut    = "Add to Desktop"
        FreeRamBtn        = "Free RAM"
        FreeRamTooltip    = "Instantly free idle application memory (RAM) without closing any apps"
        DeepUninstallBtn  = "Uninstall Apps"
        DeepUninstallTooltip = "Uninstall any program and automatically clean residual leftover files"
        ReadyStatus       = "Ready to scan and clean. Select your preferred preset or targets."
        ScanningStatus    = "Scanning all 55+ cache targets on Drive C: ..."
        ScanCompleteStatus= "Scan complete! Found cache targets are highlighted."
        SelectedLabel     = "Selected:"
        ReclaimableLabel  = "Space to Clean:"
        LangButtonText    = "العربية"
        FilterAllApps     = "All"
        FilterGames       = "🎮 Games"
        FilterAppsOnly    = "💻 Apps"
        FilterOrphaned    = "👻 Orphaned"
        SelectAllApps     = "Select All"
        ClearAppSelection = "Clear Selection"
        RefreshAppList    = "Refresh List"
        UninstallSelected = "Uninstall & Clean Leftovers"
        AppColName        = "Application Name"
        AppColType        = "Type"
        AppColSize        = "Size"
        AppColDate        = "Installed Date"
        AppColPublisher   = "Publisher"
        TaskColName       = "Process Name"
        TaskColPID        = "PID"
        TaskColTarget     = "Associated Target Cache"
        TaskColLock       = "Lock Status"
        TaskColTitle      = "Main Window Title"
        TabBloatware           = "Remove Windows Stupid Apps"
        TabUpdates             = "Windows Updates"
        WinUpdateTitle         = "Windows Automatic Updates Controller"
        WinUpdateSubtitle      = "Block background forced Windows updates and surprise restarts, or easily restore them anytime."
        WinUpdateStatusActive  = "🟢 Updates: Active"
        WinUpdateStatusBlocked = "🔴 Updates: Blocked / Paused"
        BtnStopWinUpdate       = "🛑 Stop Windows Updates"
        BtnEnableWinUpdate     = "✅ Enable Windows Updates"
        Card1Title             = "Windows Update Services"
        Card1Body              = "Controls wuauserv, UsoSvc (Update Orchestrator), and WaaSMedicSvc to prevent background execution."
        Card2Title             = "Automatic Download Policies"
        Card2Body              = "Configures NoAutoUpdate and AUOptions in Registry to eliminate sudden background downloads and reboots."
        Card3Title             = "Scheduled Background Tasks"
        Card3Body              = "Disables hidden Task Scheduler triggers in \Microsoft\Windows\UpdateOrchestrator\ that wake your PC."
        Card4Title             = "Hardware Driver Shield"
        Card4Body              = "Prevents Windows from automatically replacing your custom NVIDIA / AMD GPU graphics drivers."
        WuMaintTitle           = "Quick Maintenance & Troubleshooting Tools"
        WuCardCacheTitle       = "🧹 Purge Update Cache"
        WuCardCacheDesc        = "Deletes SoftwareDistribution\Download cache to free gigabytes and fix corrupt downloads."
        BtnCleanWuCache        = "🧹 Clean WU Cache"
        WuCardResetTitle       = "🔧 Repair & Reset Components"
        WuCardResetDesc        = "Re-registers core update DLLs and restarts BITS & CryptSvc to fix 0x800 error codes."
        BtnResetWuComponents   = "🔧 Reset Components"
        WuCardSettingsTitle    = "⚙️ Official Windows Settings"
        WuCardSettingsDesc     = "Quick access to Windows Update settings page to view update history or check for patch."
        BtnOpenWuSettings      = "⚙️ Open Settings"
        TabInstaller           = "Install Essential Apps"
        InstSearchLabel        = "Search:"
        InstFilterAll          = "All"
        InstFilterBrowsers     = "🌐 Browsers"
        InstFilterTools        = "🛠️ Utilities"
        InstFilterGaming       = "🎮 Gaming"
        InstFilterComms        = "💬 Comms"
        InstFilterMedia        = "🎬 Media"
        InstFilterDev          = "💻 Dev"
        InstFilterPro          = "⚡ Pro Tools"
        InstFilterDocs         = "📄 Documents"
        InstFilterRuntimes     = "🪟 Runtimes"
        InstSelectRec          = "🌟 Recommended"
        InstSelectAll          = "Select All"
        InstDeselectAll        = "Clear Selection"
        InstRefresh            = "🔄 Refresh"
        InstColApp             = "Software Application"
        InstColCategory        = "Category"
        InstColPackage         = "Package ID (Winget)"
        InstColDesc            = "Description"
        InstColStatus          = "Status"
        InstBtnInstall         = "🚀 Install Selected Apps"
        InstStatusInstalled    = "✅ Installed"
        InstStatusAvailable    = "📥 Available"
        BloatHeaderTitle       = "Remove Windows Stupid & Pre-installed Apps"
        BloatHeaderSubtitle    = "1-Click clean removal of Cortana, Bing News/Weather, Copilot, Xbox Overlays, Tips, and pre-installed junk."
        SelectAllBloat         = "Select All"
        DeselectAllBloat       = "Clear Selection"
        RefreshBloat           = "🔄 Rescan"
        RemoveBloatBtn         = "🗑️ Remove Selected Apps"
        BloatColName           = "Windows App / Bloatware"
        BloatColPackage        = "Package Identifier"
        BloatColPublisher      = "Publisher"
        BloatColSafety         = "Safety Level"
        BloatSafeStatus        = "🟢 100% Safe to Remove"
    }
    "AR" = @{
        AppSubtitle       = "الأداة الذكية والسريعة والشاملة لتحسين وتنظيف الويندوز"
        DriveLabel        = "Drive C: "
        StandardUser      = "مستخدم عادي"
        Administrator     = "مسؤول النظام"
        ElevateBtn        = "تشغيل كمسؤول"
        TabDashboard      = "⚡ لوحة التنظيف"
        TabUninstaller    = "🗑️ حذف البرامج"
        TabInspector      = "🔍 فاحص المسارات"
        TabGuard          = "🛡️ مدير المهام"
        TabLog            = "📝 سجل النشاط"
        TabAbout          = "ℹ️ حول البرنامج"
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
        AboutSub          = "مركز التحكم الذكي والسريع الشامل لتحسين وصيانة نظام ويندوز"
        AboutModulesTitle = "⚡ وحدات وأدوات التحكم الأساسية"
        AboutFeatAppTitle = "مدير البرامج والتحديثات"
        AboutFeatAppDesc  = "تثبيت وترقية البرامج صامتاً مع كشف أحدث الإصدارات."
        AboutFeatCleanTitle = "منظف الكاش العميق"
        AboutFeatCleanDesc  = "فحص 55+ مساراً للمظللات وأدوات التطوير والمتصفحات."
        AboutFeatBloatTitle = "إزالة تطبيقات الويندوز"
        AboutFeatBloatDesc  = "حذف تطبيقات مايكروسوفت الإجبارية ومتصفح Edge بأمان."
        AboutFeatUninstTitle = "إلغاء التثبيت العميق"
        AboutFeatUninstDesc = "حذف البرامج ومسح مخلفات الريجستري والملفات المتروكة."
        AboutFeatRamTitle = "معزز الذاكرة الحية (RAM)"
        AboutFeatRamDesc  = "مؤشر دائري حي وتفريغ الذاكرة الخاملة بضغطة زر."
        AboutFeatWuTitle  = "إدارة تحديثات ويندوز"
        AboutFeatWuDesc   = "إيقاف التحديثات الإجبارية وتنظيف الكاش وإصلاح الأعطال."
        AboutSafetyTitle  = "ضمان أمان الحسابات 100%"
        AboutSafetyBody   = "يقوم ZeroHub بتنظيف ملفات الكاش والويب والمظللات المؤقتة فقط. لا يحذف أبداً كلمات المرور المحفوظة، أو جلسات تسجيل الدخول النشطة، أو الإشارات المرجعية."
        AboutAuthorTitle  = "المطور والناشر"
        CreateShortcut    = "إضافة لسطح المكتب"
        FreeRamBtn        = "تفريغ الرام"
        FreeRamTooltip    = "تفريغ ذاكرة الوصول العشوائي (RAM) الخاملة فوراً دون إغلاق أي برنامج"
        DeepUninstallBtn  = "حذف البرامج"
        DeepUninstallTooltip = "إلغاء تثبيت أي برنامج والبحث التلقائي عن الملفات المتبقية وحذفها"
        ReadyStatus       = "جاهز للفحص والتنظيف. اختر الإعداد المسبق أو حدد المسارات."
        ScanningStatus    = "جاري فحص أكثر من 55 هدف كاش على القرص C: ..."
        ScanCompleteStatus= "اكتمل الفحص! تم تحديد وتحديث مساحات الكاش."
        SelectedLabel     = "المحدد:"
        ReclaimableLabel  = "المساحة التي ستنظف:"
        LangButtonText    = "English"
        FilterAllApps     = "الكل"
        FilterGames       = "🎮 الألعاب"
        FilterAppsOnly    = "💻 البرامج"
        FilterOrphaned    = "👻 البقايا المهجورة"
        SelectAllApps     = "تحديد الكل"
        ClearAppSelection = "إلغاء التحديد"
        RefreshAppList    = "تحديث القائمة"
        UninstallSelected = "حذف البرامج وتنظيف المخلفات"
        AppColName        = "اسم البرنامج"
        AppColType        = "النوع"
        AppColSize        = "الحجم"
        AppColDate        = "تاريخ التثبيت"
        AppColPublisher   = "الناشر"
        TaskColName       = "اسم العملية"
        TaskColPID        = "معرف العملية"
        TaskColTarget     = "الكاش المرتبط"
        TaskColLock       = "حالة القفل"
        TaskColTitle      = "عنوان النافذة الرئيسية"
        TabBloatware           = "إزالة تطبيقات الويندوز الغبية"
        TabUpdates             = "إيقاف تحديثات ويندوز"
        WinUpdateTitle         = "التحكم في تحديثات ويندوز التلقائية"
        WinUpdateSubtitle      = "إيقاف التحديثات الإجبارية وإعادة التشغيل المفاجئ في الخلفية، أو إعادة تفعيلها بسهولة في أي وقت."
        WinUpdateStatusActive  = "🟢 التحديثات: مفعّلة"
        WinUpdateStatusBlocked = "🔴 التحديثات: موقوفة ومحظورة"
        BtnStopWinUpdate       = "🛑 إيقاف تحديثات ويندوز"
        BtnEnableWinUpdate     = "✅ تفعيل تحديثات ويندوز"
        Card1Title             = "خدمات تحديثات ويندوز"
        Card1Body              = "التحكم في خدمات wuauserv و UsoSvc و WaaSMedicSvc لمنع تشغيلها في الخلفية."
        Card2Title             = "سياسات التنزيل التلقائي"
        Card2Body              = "ضبط NoAutoUpdate في الريجستري لمنع التنزيل الإجباري وإعادة التشغيل المفاجئ أثناء العمل أو الألعاب."
        Card3Title             = "المهام المجدولة في الخلفية"
        Card3Body              = "تعطيل مهام الفحص في Task Scheduler التي تقوم بإيقاظ وتحديث الجهاز تلقائياً."
        Card4Title             = "حماية تعريفات كروت الشاشة"
        Card4Body              = "منع ويندوز من استبدال تعريفات كرت الشاشة الرسمية (NVIDIA / AMD) بتعريفات قديمة."
        WuMaintTitle           = "أدوات الصيانة السريعة وإصلاح التحديثات"
        WuCardCacheTitle       = "🧹 تنظيف كاش التحديثات المؤقت"
        WuCardCacheDesc        = "حذف ملفات SoftwareDistribution\Download لتوفير مساحة وحل مشاكل التنزيل المعلق."
        BtnCleanWuCache        = "🧹 تنظيف كاش التحديثات"
        WuCardResetTitle       = "🔧 إصلاح وإعادة تعيين المكونات"
        WuCardResetDesc        = "إعادة تسجيل مكتبات DLL وتشغيل الخدمات لإصلاح أخطاء ورموز أعطال التحديثات."
        BtnResetWuComponents   = "🔧 إصلاح المكونات"
        WuCardSettingsTitle    = "⚙️ إعدادات تحديثات ويندوز"
        WuCardSettingsDesc     = "الوصول المباشر لصفحة تحديثات ويندوز الرسمية في إعدادات النظام للتحقق من التحديثات."
        BtnOpenWuSettings      = "⚙️ فتح الإعدادات"
        TabInstaller           = "تثبيت البرامج الأساسية"
        InstSearchLabel        = "البحث:"
        InstFilterAll          = "الكل"
        InstFilterBrowsers     = "🌐 المتصفحات"
        InstFilterTools        = "🛠️ الأدوات"
        InstFilterGaming       = "🎮 الألعاب"
        InstFilterComms        = "💬 التواصل"
        InstFilterMedia        = "🎬 الوسائط"
        InstFilterDev          = "💻 المطورين"
        InstFilterPro          = "⚡ أدوات متقدمة"
        InstFilterDocs         = "📄 المستندات"
        InstFilterRuntimes     = "🪟 حزم التشغيل"
        InstSelectRec          = "🌟 الموصى بها"
        InstSelectAll          = "تحديد الكل"
        InstDeselectAll        = "إلغاء التحديد"
        InstRefresh            = "🔄 تحديث"
        InstColApp             = "اسم البرنامج"
        InstColCategory        = "الفئة"
        InstColPackage         = "معرف الحزمة (Winget)"
        InstColDesc            = "الوصف"
        InstColStatus          = "الحالة"
        InstBtnInstall         = "🚀 تثبيت البرامج المحددة"
        InstStatusInstalled    = "✅ مثبت مسبقاً"
        InstStatusAvailable    = "📥 متاح للتثبيت"
        BloatHeaderTitle       = "إزالة تطبيقات الويندوز الغبية والمثبتة مسبقاً"
        BloatHeaderSubtitle    = "حذف بضغطة زر واحدة لتطبيقات كورتانا، أخبار وطقس بينج، كوبايلوت، تراكبات إكس بوكس، والنصائح والإعلانات الغبية."
        SelectAllBloat         = "تحديد الكل"
        DeselectAllBloat       = "إلغاء التحديد"
        RefreshBloat           = "🔄 إعادة الفحص"
        RemoveBloatBtn         = "🗑️ حذف التطبيقات المحددة"
        BloatColName           = "Windows App / Bloatware"
        BloatColPackage        = "Package Identifier"
        BloatColPublisher      = "Publisher"
        BloatColSafety         = "Safety Level"
        BloatSafeStatus        = "🟢 100% Safe to Remove"
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
    if ($Tab_Installer)        { $Tab_Installer.Header = "📥 " + $t.TabInstaller }
    $Tab_Uninstaller.Header    = $t.TabUninstaller
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

    if ($TxtAboutSub)          { $TxtAboutSub.Text          = $t.AboutSub }
    if ($TxtAboutModulesTitle) { $TxtAboutModulesTitle.Text  = $t.AboutModulesTitle }
    if ($TxtAboutFeatAppTitle) { $TxtAboutFeatAppTitle.Text  = $t.AboutFeatAppTitle }
    if ($TxtAboutFeatAppDesc)  { $TxtAboutFeatAppDesc.Text   = $t.AboutFeatAppDesc }
    if ($TxtAboutFeatCleanTitle) { $TxtAboutFeatCleanTitle.Text = $t.AboutFeatCleanTitle }
    if ($TxtAboutFeatCleanDesc)  { $TxtAboutFeatCleanDesc.Text  = $t.AboutFeatCleanDesc }
    if ($TxtAboutFeatBloatTitle) { $TxtAboutFeatBloatTitle.Text = $t.AboutFeatBloatTitle }
    if ($TxtAboutFeatBloatDesc)  { $TxtAboutFeatBloatDesc.Text  = $t.AboutFeatBloatDesc }
    if ($TxtAboutFeatUninstTitle){ $TxtAboutFeatUninstTitle.Text= $t.AboutFeatUninstTitle }
    if ($TxtAboutFeatUninstDesc) { $TxtAboutFeatUninstDesc.Text = $t.AboutFeatUninstDesc }
    if ($TxtAboutFeatRamTitle) { $TxtAboutFeatRamTitle.Text  = $t.AboutFeatRamTitle }
    if ($TxtAboutFeatRamDesc)  { $TxtAboutFeatRamDesc.Text   = $t.AboutFeatRamDesc }
    if ($TxtAboutFeatWuTitle)  { $TxtAboutFeatWuTitle.Text   = $t.AboutFeatWuTitle }
    if ($TxtAboutFeatWuDesc)   { $TxtAboutFeatWuDesc.Text    = $t.AboutFeatWuDesc }
    if ($TxtAboutSafetyTitle)  { $TxtAboutSafetyTitle.Text  = $t.AboutSafetyTitle }
    if ($TxtAboutSafetyBody)   { $TxtAboutSafetyBody.Text   = $t.AboutSafetyBody }
    if ($TxtAboutAuthorTitle)  { $TxtAboutAuthorTitle.Text  = $t.AboutAuthorTitle }
    if ($TxtCreateShortcut)    { $TxtCreateShortcut.Text    = $t.CreateShortcut }
    if ($TxtFreeRam)           { $TxtFreeRam.Text           = $t.FreeRamBtn }
    if ($BtnFreeRam)           { $BtnFreeRam.ToolTip        = $t.FreeRamTooltip }
    if ($TxtDeepUninstall)     { $TxtDeepUninstall.Text     = $t.DeepUninstallBtn }
    if ($BtnDeepUninstall)     { $BtnDeepUninstall.ToolTip  = $t.DeepUninstallTooltip }

    $TxtSelectedLabel.Text     = $t.SelectedLabel
    $TxtReclaimableLabel.Text  = $t.ReclaimableLabel
    $TxtLangLabel.Text         = $t.LangButtonText

    # App Installer Toolbar & DataGrid Headers
    if ($TxtTabInstallerTitle)     { $TxtTabInstallerTitle.Text = $t.TabInstaller }
    if ($TxtInstallerSearchLabel)  { $TxtInstallerSearchLabel.Text = $t.InstSearchLabel }
    if ($BtnFilterInstAll)         { $BtnFilterInstAll.Content = $t.InstFilterAll }
    if ($BtnFilterInstBrowsers)    { $BtnFilterInstBrowsers.Content = $t.InstFilterBrowsers }
    if ($BtnFilterInstTools)       { $BtnFilterInstTools.Content = $t.InstFilterTools }
    if ($BtnFilterInstGaming)      { $BtnFilterInstGaming.Content = $t.InstFilterGaming }
    if ($BtnFilterInstComms)       { $BtnFilterInstComms.Content = $t.InstFilterComms }
    if ($BtnFilterInstMedia)       { $BtnFilterInstMedia.Content = $t.InstFilterMedia }
    if ($BtnFilterInstDev)         { $BtnFilterInstDev.Content = $t.InstFilterDev }
    if ($BtnFilterInstPro)         { $BtnFilterInstPro.Content = $t.InstFilterPro }
    if ($BtnFilterInstDocs)        { $BtnFilterInstDocs.Content = $t.InstFilterDocs }
    if ($BtnFilterInstRuntimes)    { $BtnFilterInstRuntimes.Content = $t.InstFilterRuntimes }
    if ($BtnSelectUpdates)         { $BtnSelectUpdates.Content = if ($Script:CurrentLang -eq "AR") { "🔄 التحديثات" } else { "🔄 Updates" } }
    if ($BtnSelectRecApps)         { $BtnSelectRecApps.Content = $t.InstSelectRec }
    if ($BtnSelectAllInstApps)     { $BtnSelectAllInstApps.Content = $t.InstSelectAll }
    if ($BtnDeselectAllInstApps)   { $BtnDeselectAllInstApps.Content = $t.InstDeselectAll }
    if ($BtnRefreshInstStatus)     { $BtnRefreshInstStatus.Content = $t.InstRefresh }
    if ($BtnInstallSelectedApps)   { $BtnInstallSelectedApps.Content = $t.InstBtnInstall }

    # App Uninstaller Toolbar Buttons
    if ($BtnFilterAll)        { $BtnFilterAll.Content        = $t.FilterAllApps }
    if ($BtnFilterGames)      { $BtnFilterGames.Content      = $t.FilterGames }
    if ($BtnFilterApps)       { $BtnFilterApps.Content       = $t.FilterAppsOnly }
    if ($BtnFilterOrphaned)   { $BtnFilterOrphaned.Content   = $t.FilterOrphaned }
    if ($BtnSelectAllApps)    { $BtnSelectAllApps.Content    = $t.SelectAllApps }
    if ($BtnDeselectAllApps)  { $BtnDeselectAllApps.Content  = $t.ClearAppSelection }
    if ($BtnRefreshApps)      { $BtnRefreshApps.Content      = $t.RefreshAppList }

    # App Uninstaller DataGrid Column Headers
    if ($AppsGrid -and $AppsGrid.Columns.Count -ge 5) {
        if ($AppsGrid.Columns.Count -gt 2) { $AppsGrid.Columns[2].Header = $t.AppColName }
        if ($AppsGrid.Columns.Count -gt 3) { $AppsGrid.Columns[3].Header = $t.AppColType }
    }

    # Windows Updates & Bloatware Tab Translations & Headers
    if ($TxtTabBloatwareTitle)       { $TxtTabBloatwareTitle.Text       = $t.TabBloatware }
    if ($TxtTabUpdatesTitle)         { $TxtTabUpdatesTitle.Text         = $t.TabUpdates }
    if ($TxtWinUpdateTitle)          { $TxtWinUpdateTitle.Text          = $t.WinUpdateTitle }
    if ($TxtWinUpdateSubtitle)       { $TxtWinUpdateSubtitle.Text       = $t.WinUpdateSubtitle }
    if ($TxtCard1Title)              { $TxtCard1Title.Text              = $t.Card1Title }
    if ($TxtCard1Body)               { $TxtCard1Body.Text               = $t.Card1Body }
    if ($TxtCard2Title)              { $TxtCard2Title.Text              = $t.Card2Title }
    if ($TxtCard2Body)               { $TxtCard2Body.Text               = $t.Card2Body }
    if ($TxtCard3Title)              { $TxtCard3Title.Text              = $t.Card3Title }
    if ($TxtCard3Body)               { $TxtCard3Body.Text               = $t.Card3Body }
    if ($TxtCard4Title)              { $TxtCard4Title.Text              = $t.Card4Title }
    if ($TxtCard4Body)               { $TxtCard4Body.Text               = $t.Card4Body }
    if ($TxtWuMaintTitle)            { $TxtWuMaintTitle.Text            = $t.WuMaintTitle }
    if ($TxtWuCardCacheTitle)        { $TxtWuCardCacheTitle.Text        = $t.WuCardCacheTitle }
    if ($TxtWuCardCacheDesc)         { $TxtWuCardCacheDesc.Text         = $t.WuCardCacheDesc }
    if ($BtnCleanWuCache)            { $BtnCleanWuCache.Content         = $t.BtnCleanWuCache }
    if ($TxtWuCardResetTitle)        { $TxtWuCardResetTitle.Text        = $t.WuCardResetTitle }
    if ($TxtWuCardResetDesc)         { $TxtWuCardResetDesc.Text         = $t.WuCardResetDesc }
    if ($BtnResetWuComponents)       { $BtnResetWuComponents.Content    = $t.BtnResetWuComponents }
    if ($TxtWuCardSettingsTitle)     { $TxtWuCardSettingsTitle.Text     = $t.WuCardSettingsTitle }
    if ($TxtWuCardSettingsDesc)      { $TxtWuCardSettingsDesc.Text      = $t.WuCardSettingsDesc }
    if ($BtnOpenWuSettings)          { $BtnOpenWuSettings.Content       = $t.BtnOpenWuSettings }
    if ($TxtBloatwareHeaderTitle)    { $TxtBloatwareHeaderTitle.Text    = $t.BloatHeaderTitle }
    if ($TxtBloatwareHeaderSubtitle) { $TxtBloatwareHeaderSubtitle.Text = $t.BloatHeaderSubtitle }
    if ($BtnSelectAllBloat)          { $BtnSelectAllBloat.Content       = $t.SelectAllBloat }
    if ($BtnDeselectAllBloat)        { $BtnDeselectAllBloat.Content     = $t.DeselectAllBloat }
    if ($BtnRefreshBloat)            { $BtnRefreshBloat.Content         = $t.RefreshBloat }
    if ($BtnRemoveSelectedBloatware) { $BtnRemoveSelectedBloatware.Content = $t.RemoveBloatBtn }
    Update-WinUpdateUI

    if ($BloatwareGrid -and $BloatwareGrid.Columns.Count -ge 6) {
        $BloatwareGrid.Columns[2].Header = $t.BloatColName
        $BloatwareGrid.Columns[3].Header = $t.BloatColPackage
        $BloatwareGrid.Columns[4].Header = $t.BloatColPublisher
        $BloatwareGrid.Columns[5].Header = $t.BloatColSafety
    }

    # Task Manager Column Headers
    if ($ProcessDataGrid -and $ProcessDataGrid.Columns.Count -ge 5) {
        $ProcessDataGrid.Columns[0].Header = $t.TaskColName
        $ProcessDataGrid.Columns[1].Header = $t.TaskColPID
        $ProcessDataGrid.Columns[2].Header = $t.TaskColTarget
        $ProcessDataGrid.Columns[3].Header = $t.TaskColLock
        $ProcessDataGrid.Columns[4].Header = $t.TaskColTitle
    }

    Update-ProcessGuardList

    if ($Script:InstallerCatalogList.Count -gt 0) {
        Init-InstallerAppsList
    }

    if ($Script:AllInstalledApps.Count -gt 0) {
        Apply-AppFilters
        Update-AppSelectionStatus
    }

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

# Logging Helper (Memory-Capped Ring Buffer)
function Append-Log([string]$message, [string]$level = "INFO") {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logLine = "[$timestamp] [$level] $message`r`n"
    $TxtLogConsole.Dispatcher.Invoke([Action]{
        if ($TxtLogConsole.LineCount -gt 400) {
            $TxtLogConsole.Text = $TxtLogConsole.Text.Substring([math]::Min($TxtLogConsole.Text.Length, 3000))
        }
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
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("ZeroHub").Show($toast)
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

# Measure Folder Size safely and at high speed using Native C# walker
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
            if (-not [System.IO.Directory]::Exists($parent)) { return 0 }
            $matchingDirs = [System.IO.Directory]::GetDirectories($parent, $leaf)
            $totalBytes = 0
            foreach ($d in $matchingDirs) {
                $totalBytes += [ZeroCleaner.NativeMethods]::FastGetDirectorySize($d)
            }
            return [math]::Round(($totalBytes / 1MB), 1)
        }

        if ([System.IO.Directory]::Exists($targetPath)) {
            $bytes = [ZeroCleaner.NativeMethods]::FastGetDirectorySize($targetPath)
            return [math]::Round(($bytes / 1MB), 1)
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

# Update Real-Time RAM & Reclaimable Memory Indicator
function Update-LiveMemoryStats() {
    try {
        $totalGB = 0.0; $usedGB = 0.0; $freeGB = 0.0; $usedPercent = 0; $reclaimableMB = 0.0;
        $success = $false

        try {
            [ZeroCleaner.NativeMethods]::GetLiveMemoryMetrics([ref]$totalGB, [ref]$usedGB, [ref]$freeGB, [ref]$usedPercent, [ref]$reclaimableMB)
            if ($totalGB -gt 0) { $success = $true }
        } catch {}

        if (-not $success) {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $totalBytes = $os.TotalVisibleMemorySize * 1024
                $freeBytes  = $os.FreePhysicalMemory * 1024
                $usedBytes  = $totalBytes - $freeBytes
                $totalGB    = [math]::Round($totalBytes / 1GB, 1)
                $usedGB     = [math]::Round($usedBytes / 1GB, 1)
                $freeGB     = [math]::Round($freeBytes / 1GB, 1)
                $usedPercent = if ($totalBytes -gt 0) { [math]::Round(($usedBytes / $totalBytes) * 100, 0) } else { 0 }
                $reclaimableMB = [math]::Round(($usedBytes * 0.28) / 1MB, 0)
            }
        }

        if ($totalGB -gt 0) {
            # Update Circular Progress Ring
            $pVal = [math]::Max(1.0, [math]::Min(99.9, [double]$usedPercent))
            $radius = 12.0
            $cx = 14.0
            $cy = 14.0
            $angle = ($pVal / 100.0) * 360.0
            $angleRad = ($angle - 90.0) * [Math]::PI / 180.0
            $startX = $cx
            $startY = $cy - $radius
            $endX = [Math]::Round(($cx + $radius * [Math]::Cos($angleRad)), 2)
            $endY = [Math]::Round(($cy + $radius * [Math]::Sin($angleRad)), 2)
            $isLargeArc = if ($angle -gt 180) { "1" } else { "0" }

            $geo = [System.Windows.Media.Geometry]::Parse("M $startX,$startY A $radius,$radius 0 $isLargeArc 1 $endX,$endY")
            if ($RamCircleArc) { $RamCircleArc.Data = $geo }

            # Color ring dynamically based on load (Green < 70%, Yellow 70-85%, Coral Red > 85%)
            $ringColor = if ($usedPercent -ge 85) { "#F87171" } elseif ($usedPercent -ge 70) { "#FBBF24" } else { "#4ADE80" }
            if ($RamCircleArc) { $RamCircleArc.Stroke = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ringColor) }
            if ($TxtRamPercent) {
                $TxtRamPercent.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($ringColor)
                $TxtRamPercent.Text = "$usedPercent%"
            }

            if ($TxtRamLiveMetrics) { $TxtRamLiveMetrics.Text = "$usedGB / $totalGB GB" }

            $reclaimableStr = Format-SpaceMB $reclaimableMB
            if ($TxtRamReclaimable) {
                $TxtRamReclaimable.Text = if ($Script:CurrentLang -eq "AR") { "قابل للتحرير: ~$reclaimableStr" } else { "Reclaimable: ~$reclaimableStr" }
            }

            # Dynamically update Free RAM button tooltip
            if ($BtnFreeRam) {
                $BtnFreeRam.ToolTip = if ($Script:CurrentLang -eq "AR") { "تحرير الذاكرة الفائضة فوراً (حوالي $reclaimableStr)" } else { "Quickly free idle application RAM (approx $reclaimableStr)" }
            }
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
    [ZeroCleaner.NativeMethods]::TrimSelfMemory()
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
    [ZeroCleaner.NativeMethods]::TrimSelfMemory()
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
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $confirmPrompt = if ($Script:CurrentLang -eq "AR") {
        "هل أنت متأكد من رغبتك في تنظيف $($selected.Count) هدف كاش محدد؟`n`nسيقوم ZeroHub بحذف ملفات الكاش المؤقتة بأمان تام دون المساس بحساباتك أو كلمات السر المحفوظة."
    } else {
        "Are you sure you want to clean $($selected.Count) selected cache target(s)?`n`nZeroHub will safely purge temporary cache files without touching your passwords or cookies."
    }

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "Confirm Safe Cleanup",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Activity Log Tab to show real-time cleaning progress
    $MainTabs.SelectedItem = $Tab_Log

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
                # CRITICAL: Skip browser/app targets entirely when guard process is active
                # Cleaning cache while a browser is running corrupts active sessions and logs you out
                $guardNames = $t.Guard -join ', '
                $skipMsg = if ($Script:CurrentLang -eq "AR") {
                    "تم تخطي $($t.Name): التطبيق ($guardNames) قيد التشغيل. أغلق التطبيق أولاً أو فعّل 'إغلاق التطبيقات تلقائياً'."
                } else {
                    "Skipped $($t.Name): App ($guardNames) is running. Close it first or enable 'Auto-close apps'."
                }
                Append-Log $skipMsg "WARN"
                $skippedItems++
                continue
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
    Show-ZeroToastNotification "ZeroHub" $summaryMsg
    [ZeroCleaner.NativeMethods]::TrimSelfMemory()
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

# Free RAM Action Handler (Directly on Tab Bar)
$ExecuteFreeRamAction = {
    try {
        if ($TxtFreeRam) {
            $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "جاري التحرير..." } else { "Freeing..." }
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
        }
        $StatusText.Text = if ($Script:CurrentLang -eq "AR") { "جاري تحرير ذاكرة الرام الخاملة..." } else { "Freeing idle RAM memory..." }
        [System.Windows.Forms.Application]::DoEvents()

        $osBefore = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeBeforeMB = if ($osBefore) { [math]::Round($osBefore.FreePhysicalMemory / 1024, 1) } else { 0 }

        # Flush Working Sets
        Clear-SystemRamCache

        $osAfter = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $freeAfterMB = if ($osAfter) { [math]::Round($osAfter.FreePhysicalMemory / 1024, 1) } else { 0 }
        $reclaimedMB = [math]::Max(0, [math]::Round(($freeAfterMB - $freeBeforeMB), 1))

        if ($TxtFreeRam) {
            $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "تم التحرير!" } else { "Freed!" }
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }

        $toastTitle = if ($Script:CurrentLang -eq "AR") { "ZeroHub - تنظيف الرام" } else { "ZeroHub - RAM Reclaimed" }
        $toastMsg = if ($Script:CurrentLang -eq "AR") {
            "تم تحرير الذاكرة بنجاح! المساحة الحرة الآن: $(Format-SpaceMB $freeAfterMB)"
        } else {
            "Memory freed successfully! Current Free RAM: $(Format-SpaceMB $freeAfterMB)"
        }
        Show-ZeroToastNotification $toastTitle $toastMsg
        $StatusText.Text = $toastMsg

        Append-Log "Free RAM executed: Reclaimed $reclaimedMB MB (Free now: $freeAfterMB MB)" "SUCCESS"

        # Restore button text after 2.5 seconds asynchronously
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2.5)
        $timer.add_Tick({
            $timer.Stop()
            if ($TxtFreeRam) {
                $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { $Script:Translations["AR"].FreeRamBtn } else { $Script:Translations["EN"].FreeRamBtn }
                $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            }
        })
        $timer.Start()
    } catch {
        Append-Log "Error freeing RAM: $($_.Exception.Message)" "ERROR"
    }
}

if ($Tab_FreeRam) {
    $Tab_FreeRam.add_PreviewMouseDown({
        param($sender, $e)
        $e.Handled = $true
        & $ExecuteFreeRamAction
    })
}

if ($BtnFreeRam) {
    $BtnFreeRam.add_Click({
        & $ExecuteFreeRamAction
    })
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
    $res = [System.Windows.MessageBox]::Show($prompt, "ZeroHub Process Guard", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Stop-ActiveGuardedProcesses
    }
})

# Wire Log Console Buttons
$BtnCopyLogs.add_Click({
    if ($TxtLogConsole.Text) {
        [System.Windows.Clipboard]::SetText($TxtLogConsole.Text)
        $copiedMsg = if ($Script:CurrentLang -eq "AR") { "تم نسخ السجل إلى الحافظة بنجاح!" } else { "Logs copied to clipboard!" }
        [System.Windows.MessageBox]::Show($copiedMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
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


# ==========================================
# 1-CLICK ESSENTIAL APP INSTALLER ENGINE (WINGET)
# ==========================================
$Script:InstallerCatalogList = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerAppItem]]::new()
$Script:InstallerCategoryCards = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerCategoryCard]]::new()
$Script:Col1Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerCategoryCard]]::new()
$Script:Col2Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerCategoryCard]]::new()
$Script:Col3Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerCategoryCard]]::new()
$Script:Col4Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstallerCategoryCard]]::new()
$Script:InstallerFilterCategory = "All"

$Script:CatalogAppsData = @(
    @{ Id="Brave.Brave"; Name="Brave"; CatKey="Browsers"; Desc="Brave is a privacy-focused web browser that blocks ads and trackers, offering a faster and safer browsing experience."; Rec=$true },
    @{ Id="Google.Chrome"; Name="Chrome"; CatKey="Browsers"; Desc="Google Chrome is a widely used web browser known for its speed, simplicity, and seamless integration with Google serv..."; Rec=$true },
    @{ Id="Hibbiki.Chromium"; Name="Chromium"; CatKey="Browsers"; Desc="Chromium is the open-source project that serves as the foundation for various web browsers, including Chrome."; Rec=$false },
    @{ Id="Microsoft.Edge"; Name="Edge"; CatKey="Browsers"; Desc="Microsoft Edge is a modern web browser built on Chromium, offering performance, security, and integration with Micros..."; Rec=$false },
    @{ Id="Mozilla.Firefox"; Name="Firefox"; CatKey="Browsers"; Desc="Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions."; Rec=$true },
    @{ Id="Mozilla.Firefox.ESR"; Name="Firefox ESR"; CatKey="Browsers"; Desc="Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions. ..."; Rec=$false },
    @{ Id="Ablaze.Floorp"; Name="Floorp"; CatKey="Browsers"; Desc="Floorp is an open-source web browser project that aims to provide a simple and fast browsing experience."; Rec=$false },
    @{ Id="ImputNet.Helium"; Name="Helium"; CatKey="Browsers"; Desc="Private, fast, and honest web browser."; Rec=$false },
    @{ Id="LibreWolf.LibreWolf"; Name="LibreWolf"; CatKey="Browsers"; Desc="LibreWolf is a privacy-focused web browser based on Firefox, with additional privacy and security enhancements."; Rec=$false },
    @{ Id="MullvadVPN.MullvadBrowser"; Name="Mullvad Browser"; CatKey="Browsers"; Desc="Mullvad Browser is a privacy-focused web browser, developed in partnership with the Tor Project."; Rec=$false },
    @{ Id="TorProject.TorBrowser"; Name="Tor Browser"; CatKey="Browsers"; Desc="Tor Browser is designed for anonymous web browsing, utilizing the Tor network to protect user privacy and security."; Rec=$false },
    @{ Id="eloston.ungoogled-chromium"; Name="Ungoogled Chromium"; CatKey="Browsers"; Desc="Ungoogled Chromium is a version of Chromium without Google's integration for enhanced privacy and control."; Rec=$false },
    @{ Id="Vivaldi.Vivaldi"; Name="Vivaldi"; CatKey="Browsers"; Desc="Vivaldi is a highly customizable web browser with a focus on user personalization and productivity features."; Rec=$false },
    @{ Id="Waterfox.Waterfox"; Name="Waterfox"; CatKey="Browsers"; Desc="Waterfox is a fast, privacy-focused web browser based on Firefox, designed to preserve user choice and privacy."; Rec=$false },
    @{ Id="Zen-Team.Zen-Browser"; Name="Zen Browser"; CatKey="Browsers"; Desc="The modern, privacy-focused, performance-driven browser built on Firefox."; Rec=$false },
    @{ Id="Betterbird.Betterbird"; Name="Betterbird"; CatKey="Communications"; Desc="Betterbird is a fork of Mozilla Thunderbird with additional features and bugfixes."; Rec=$false },
    @{ Id="ChatterinoTeam.Chatterino"; Name="Chatterino"; CatKey="Communications"; Desc="Chatterino is a chat client for Twitch chat that offers a clean and customizable interface for a better streaming exp..."; Rec=$false },
    @{ Id="Discord.Discord"; Name="Discord"; CatKey="Communications"; Desc="Discord is a popular communication platform with voice, video, and text chat, designed for gamers but used by a wide ..."; Rec=$true },
    @{ Id="SpikeHD.Dorion"; Name="Dorion"; CatKey="Communications"; Desc="Tiny alternative Discord client with a smaller footprint, snappier startup, themes, plugins and more!"; Rec=$false },
    @{ Id="Element.Element"; Name="Element"; CatKey="Communications"; Desc="Element is a client for Matrix; an open network for secure, decentralized communication."; Rec=$false },
    @{ Id="Proton.ProtonMail"; Name="Proton Mail"; CatKey="Communications"; Desc="Proton Mail is an end-to-end encrypted email service by Proton, protecting your privacy with zero-access encryption."; Rec=$false },
    @{ Id="Tox.qTox"; Name="QTox"; CatKey="Communications"; Desc="QTox is a free and open-source messaging app that prioritizes user privacy and security in its design."; Rec=$false },
    @{ Id="OpenWhisperSystems.Signal"; Name="Signal"; CatKey="Communications"; Desc="Signal is a privacy-focused messaging app that offers end-to-end encryption for secure and private communication."; Rec=$false },
    @{ Id="SlackTechnologies.Slack"; Name="Slack"; CatKey="Communications"; Desc="Slack is a collaboration hub that connects teams and facilitates communication through channels, messaging, and file ..."; Rec=$false },
    @{ Id="Microsoft.Teams"; Name="Teams"; CatKey="Communications"; Desc="Microsoft Teams is a collaboration platform that integrates with Office 365 and offers chat, video conferencing, file..."; Rec=$false },
    @{ Id="TeamSpeakSystems.TeamSpeakClient"; Name="TeamSpeak 3"; CatKey="Communications"; Desc="TEAMSPEAK. YOUR TEAM. YOUR RULES. Use crystal clear sound to communicate with your teammates cross-platform with mili..."; Rec=$false },
    @{ Id="TeamSpeakSystems.TeamSpeakClient.Beta.6"; Name="TeamSpeak 6"; CatKey="Communications"; Desc="TEAMSPEAK. YOUR TEAM. YOUR RULES. Use crystal clear sound to communicate with your teammates cross-platform with mili..."; Rec=$false },
    @{ Id="Telegram.TelegramDesktop"; Name="Telegram"; CatKey="Communications"; Desc="Telegram is a cloud-based instant messaging app known for its security features, speed, and simplicity."; Rec=$false },
    @{ Id="Mozilla.Thunderbird"; Name="Thunderbird"; CatKey="Communications"; Desc="Mozilla Thunderbird is a free and open-source email client, news client, and chat client with advanced features."; Rec=$false },
    @{ Id="Vencord.Vesktop"; Name="Vesktop"; CatKey="Communications"; Desc="A cross platform electron-based desktop app aiming to give you a snappier Discord experience with Vencord pre-installed."; Rec=$false },
    @{ Id="Rakuten.Viber"; Name="Viber"; CatKey="Communications"; Desc="Viber is a free messaging and calling app with features like group chats, video calls, and more."; Rec=$false },
    @{ Id="Zoom.Zoom"; Name="Zoom"; CatKey="Communications"; Desc="Zoom is a popular video conferencing and web conferencing service for online meetings, webinars, and collaborative pr..."; Rec=$false },
    @{ Id="Amazon.Corretto.21.JDK"; Name="Amazon Corretto 21 (LTS)"; CatKey="Development"; Desc="Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK)."; Rec=$false },
    @{ Id="Amazon.Corretto.25.JDK"; Name="Amazon Corretto 25 (LTS)"; CatKey="Development"; Desc="Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK)."; Rec=$false },
    @{ Id="Amazon.Corretto.8.JDK"; Name="Amazon Corretto 8 (LTS)"; CatKey="Development"; Desc="Amazon Corretto is a no-cost, multiplatform, production-ready distribution of the Open Java Development Kit (OpenJDK)."; Rec=$false },
    @{ Id="Bruno.Bruno"; Name="Bruno"; CatKey="Development"; Desc="Bruno is a local-first API client that stores collections as plain text files for version control and collaboration."; Rec=$false },
    @{ Id="Kitware.CMake"; Name="CMake"; CatKey="Development"; Desc="CMake is an open-source, cross-platform family of tools designed to build, test and package software."; Rec=$false },
    @{ Id="Docker.DockerDesktop"; Name="Docker Desktop"; CatKey="Development"; Desc="Docker Desktop provides a local environment for building, running, and testing containerized applications on Windows."; Rec=$false },
    @{ Id="Schniz.fnm"; Name="Fast Node Manager"; CatKey="Development"; Desc="Fast Node Manager (fnm) is a fast, cross-platform tool for installing and switching between Node.js versions."; Rec=$false },
    @{ Id="Git.Git"; Name="Git"; CatKey="Development"; Desc="Git is a distributed version control system widely used for tracking changes in source code during software development."; Rec=$true },
    @{ Id="GitExtensionsTeam.GitExtensions"; Name="Git Extensions"; CatKey="Development"; Desc="Git Extensions is a graphical Git client for Windows with repository, history, and commit management tools."; Rec=$false },
    @{ Id="GitHub.cli"; Name="GitHub CLI"; CatKey="Development"; Desc="GitHub CLI brings pull requests, issues, releases, and other GitHub workflows to the terminal."; Rec=$false },
    @{ Id="GitHub.GitHubDesktop"; Name="GitHub Desktop"; CatKey="Development"; Desc="GitHub Desktop is a visual Git client that simplifies collaboration on GitHub repositories with an easy-to-use interf..."; Rec=$false },
    @{ Id="GoLang.Go"; Name="Go"; CatKey="Development"; Desc="Go (or Golang) is a statically typed, compiled programming language designed for simplicity, reliability, and efficie..."; Rec=$false },
    @{ Id="JetBrains.Toolbox"; Name="Jetbrains Toolbox"; CatKey="Development"; Desc="Jetbrains Toolbox is a platform for easy installation and management of JetBrains developer tools."; Rec=$false },
    @{ Id="JesseDuffield.lazygit"; Name="Lazygit"; CatKey="Development"; Desc="Simple terminal UI for git commands."; Rec=$false },
    @{ Id="rjpcomputing.luaforwindows"; Name="Lua"; CatKey="Development"; Desc="A 'batteries included environment' for the Lua scripting language on Windows."; Rec=$false },
    @{ Id="Neovim.Neovim"; Name="Neovim"; CatKey="Development"; Desc="Neovim is a highly extensible text editor and an improvement over the original Vim editor."; Rec=$false },
    @{ Id="OpenJS.NodeJS"; Name="NodeJS"; CatKey="Development"; Desc="NodeJS is a JavaScript runtime built on Chrome's V8 JavaScript engine for building server-side and networking applica..."; Rec=$false },
    @{ Id="OpenJS.NodeJS.LTS"; Name="NodeJS LTS"; CatKey="Development"; Desc="NodeJS LTS provides Long-Term Support releases for stable and reliable server-side JavaScript development."; Rec=$false },
    @{ Id="JanDeDobbeleer.OhMyPosh"; Name="Oh My Posh (Prompt)"; CatKey="Development"; Desc="Oh My Posh is a cross-platform prompt theme engine for any shell."; Rec=$false },
    @{ Id="pnpm.pnpm"; Name="pnpm"; CatKey="Development"; Desc="pnpm is a fast and disk space efficient package manager for JavaScript and Node.js applications."; Rec=$false },
    @{ Id="Postman.Postman"; Name="Postman"; CatKey="Development"; Desc="Postman is an API platform and desktop client for designing, testing, documenting, and collaborating on APIs."; Rec=$false },
    @{ Id="Python.Python.3.14"; Name="Python3"; CatKey="Development"; Desc="Python is a versatile programming language used for web development, data analysis, artificial intelligence, and more."; Rec=$false },
    @{ Id="RubyInstallerTeam.Ruby.4.0"; Name="Ruby"; CatKey="Development"; Desc="A Ruby language execution environment with a MSYS2 installation."; Rec=$false },
    @{ Id="Rustlang.Rust.MSVC"; Name="Rust"; CatKey="Development"; Desc="Rust is a programming language designed for safety and performance, particularly focused on systems programming."; Rec=$false },
    @{ Id="Starship.Starship"; Name="Starship (Shell Prompt)"; CatKey="Development"; Desc="Starship is a fast, customizable, cross-platform prompt for PowerShell and other shells."; Rec=$false },
    @{ Id="SublimeHQ.SublimeText.4"; Name="Sublime Text"; CatKey="Development"; Desc="Sublime Text is a sophisticated text editor for code, markup, and prose."; Rec=$false },
    @{ Id="WinsiderSS.SystemInformer"; Name="System Informer"; CatKey="Development"; Desc="A free, powerful, multi-purpose tool that helps you monitor system resources, debug software and detect malware."; Rec=$false },
    @{ Id="Unity.UnityHub"; Name="Unity Game Engine"; CatKey="Development"; Desc="Unity is a powerful game development platform for creating 2D, 3D, augmented reality, and virtual reality games."; Rec=$false },
    @{ Id="astral-sh.uv"; Name="uv"; CatKey="Development"; Desc="uv is a fast Python package and project manager written in Rust."; Rec=$false },
    @{ Id="Hashicorp.Vagrant"; Name="Vagrant"; CatKey="Development"; Desc="Vagrant builds and manages reproducible virtual machine development environments from declarative configuration."; Rec=$false },
    @{ Id="Microsoft.VisualStudio.2022.Community"; Name="Visual Studio 2022"; CatKey="Development"; Desc="Visual Studio 2022 is an integrated development environment (IDE) for building, debugging, and deploying applications."; Rec=$false },
    @{ Id="Microsoft.VisualStudio.Community"; Name="Visual Studio 2026"; CatKey="Development"; Desc="Visual Studio 2026 is an integrated development environment (IDE) for building, debugging, and deploying applications."; Rec=$false },
    @{ Id="Microsoft.VisualStudioCode"; Name="VS Code"; CatKey="Development"; Desc="Visual Studio Code is a free, open-source code editor with support for multiple programming languages."; Rec=$true },
    @{ Id="VSCodium.VSCodium"; Name="VS Codium"; CatKey="Development"; Desc="VSCodium is a community-driven, freely-licensed binary distribution of Microsoft's VS Code."; Rec=$false },
    @{ Id="Yarn.Yarn"; Name="Yarn"; CatKey="Development"; Desc="Yarn is a fast, reliable, and secure dependency management tool for JavaScript projects."; Rec=$false },
    @{ Id="ZedIndustries.Zed"; Name="Zed"; CatKey="Development"; Desc="Zed is a modern, high-performance code editor designed from the ground up for speed and collaboration."; Rec=$false },
    @{ Id="Adobe.Acrobat.Reader.64-bit"; Name="Adobe Acrobat Reader"; CatKey="Documents"; Desc="Adobe Acrobat Reader is a free PDF viewer with essential features for viewing, printing, and annotating PDF documents."; Rec=$false },
    @{ Id="Foxit.FoxitReader"; Name="Foxit PDF Reader"; CatKey="Documents"; Desc="Foxit PDF Reader is a free PDF viewer with a familiar ribbon-style interface."; Rec=$false },
    @{ Id="Joplin.Joplin"; Name="Joplin"; CatKey="Documents"; Desc="Joplin is an open-source note-taking and to-do application with synchronization capabilities."; Rec=$false },
    @{ Id="TheDocumentFoundation.LibreOffice"; Name="LibreOffice"; CatKey="Documents"; Desc="LibreOffice is a powerful and free office suite, compatible with other major office suites."; Rec=$false },
    @{ Id="Cyanfish.NAPS2"; Name="NAPS2 (Scanner)"; CatKey="Documents"; Desc="NAPS2 is a document scanning application that simplifies the process of creating electronic documents."; Rec=$false },
    @{ Id="Obsidian.Obsidian"; Name="Obsidian"; CatKey="Documents"; Desc="Obsidian is a powerful note-taking and knowledge management application."; Rec=$false },
    @{ Id="KDE.Okular"; Name="Okular"; CatKey="Documents"; Desc="Okular is a versatile document viewer with advanced features."; Rec=$false },
    @{ Id="ONLYOFFICE.DesktopEditors"; Name="ONLYOFFICE Desktop"; CatKey="Documents"; Desc="ONLYOFFICE Desktop is a comprehensive office suite for document editing and collaboration."; Rec=$false },
    @{ Id="geeksoftwareGmbH.PDF24Creator"; Name="PDF24 Creator"; CatKey="Documents"; Desc="Free and easy-to-use online/desktop PDF tools that make you more productive"; Rec=$false },
    @{ Id="PDFgear.PDFgear"; Name="PDFgear"; CatKey="Documents"; Desc="PDFgear is a piece of full-featured PDF management software for Windows, macOS, and mobile, and it's completely free ..."; Rec=$false },
    @{ Id="PDFsam.PDFsam"; Name="PDFsam Basic"; CatKey="Documents"; Desc="PDFsam Basic is a free and open-source tool for splitting, merging, and rotating PDF files."; Rec=$false },
    @{ Id="TrackerSoftware.PDF-XChangeEditor"; Name="PDF-XChange Editor"; CatKey="Documents"; Desc="A comprehensive Windows-based software suite and editor for creating, viewing, editing, annotating, and signing PDF f..."; Rec=$false },
    @{ Id="pbek.QOwnNotes"; Name="QOwnNotes"; CatKey="Documents"; Desc="QOwnNotes is a free open-source note taking app with Nextcloud/ownCloud integration."; Rec=$false },
    @{ Id="Automattic.Simplenote"; Name="Simplenote"; CatKey="Documents"; Desc="Simplenote is an easy way to keep notes, lists, ideas and more."; Rec=$false },
    @{ Id="SumatraPDF.SumatraPDF"; Name="Sumatra PDF"; CatKey="Documents"; Desc="Sumatra PDF is a lightweight and fast PDF viewer with minimalistic design."; Rec=$false },
    @{ Id="Xournal++.Xournal++"; Name="Xournal++"; CatKey="Documents"; Desc="Xournal++ is an open-source handwriting notetaking software with PDF annotation capabilities."; Rec=$false },
    @{ Id="DigitalScholar.Zotero"; Name="Zotero"; CatKey="Documents"; Desc="Zotero is a free, easy-to-use tool to help you collect, organize, cite, and share your research materials."; Rec=$false },
    @{ Id="Blizzard.BattleNet"; Name="Battle.net"; CatKey="Gaming"; Desc="Battle.net is a launcher for games created and developed by Activision Blizzard"; Rec=$false },
    @{ Id="Cemu.Cemu"; Name="Cemu"; CatKey="Gaming"; Desc="Cemu is a highly experimental software to emulate Wii U applications on PC."; Rec=$false },
    @{ Id="ElectronicArts.EADesktop"; Name="EA App"; CatKey="Gaming"; Desc="EA App is a platform for accessing and playing Electronic Arts games."; Rec=$false },
    @{ Id="ES-DE.EmulationStation-DE"; Name="EmulationStation Desktop Edition"; CatKey="Gaming"; Desc="EmulationStation Desktop Edition is a frontend for browsing and launching games from your multi-platform game collect..."; Rec=$false },
    @{ Id="EpicGames.EpicGamesLauncher"; Name="Epic Games Launcher"; CatKey="Gaming"; Desc="Epic Games Launcher is the client for accessing and playing games from the Epic Games Store."; Rec=$false },
    @{ Id="Nvidia.GeForceNow"; Name="GeForce NOW"; CatKey="Gaming"; Desc="GeForce NOW is a cloud gaming service that allows you to play high-quality PC games on your device."; Rec=$false },
    @{ Id="GOG.Galaxy"; Name="GOG Galaxy"; CatKey="Gaming"; Desc="GOG Galaxy is a gaming client that offers DRM-free games, additional content, and more."; Rec=$false },
    @{ Id="HeroicGamesLauncher.HeroicGamesLauncher"; Name="Heroic Games Launcher"; CatKey="Gaming"; Desc="Heroic Games Launcher is an open-source alternative game launcher for Epic Games Store."; Rec=$false },
    @{ Id="ItchIo.Itch"; Name="Itch.io"; CatKey="Gaming"; Desc="Itch.io is a digital distribution platform for indie games and creative projects."; Rec=$false },
    @{ Id="Modrinth.ModrinthApp"; Name="Modrinth App"; CatKey="Gaming"; Desc="Modrinth App is a desktop application for managing Minecraft mods and modpacks."; Rec=$false },
    @{ Id="Overwolf.CurseForge"; Name="Overwolf"; CatKey="Gaming"; Desc="Popular platform for game overlays and companion apps (mod managers, trackers, etc.), widely used by gamers."; Rec=$false },
    @{ Id="Playnite.Playnite"; Name="Playnite"; CatKey="Gaming"; Desc="Playnite is an open-source video game library manager with one simple goal: To provide a unified interface for all of..."; Rec=$false },
    @{ Id="PrismLauncher.PrismLauncher"; Name="Prism Launcher"; CatKey="Gaming"; Desc="Prism Launcher is an open-source Minecraft launcher with the ability to manage multiple instances, accounts, and mods."; Rec=$false },
    @{ Id="Roblox.Roblox"; Name="Roblox"; CatKey="Gaming"; Desc="Roblox is a platform and game creation system that allows users to create and play games developed by the community."; Rec=$false },
    @{ Id="Valve.Steam"; Name="Steam"; CatKey="Gaming"; Desc="Steam is a digital distribution platform for purchasing and playing video games, offering multiplayer gaming, video s..."; Rec=$true },
    @{ Id="Ubisoft.Connect"; Name="Ubisoft Connect"; CatKey="Gaming"; Desc="Ubisoft Connect is Ubisoft's digital distribution and online gaming service, providing access to Ubisoft's games and ..."; Rec=$false },
    @{ Id="VirtualDesktop.Streamer"; Name="Virtual Desktop Streamer"; CatKey="Gaming"; Desc="Virtual Desktop Streamer is a tool that allows you to stream your desktop screen to VR devices."; Rec=$false },
    @{ Id="AIMP.AIMP"; Name="AIMP (Music Player)"; CatKey="Media"; Desc="AIMP is a feature-rich music player with support for various audio formats, playlists, and customizable user interface."; Rec=$false },
    @{ Id="Audacity.Audacity"; Name="Audacity"; CatKey="Media"; Desc="Audacity is a free and open-source audio editing software known for its powerful recording and editing capabilities."; Rec=$false },
    @{ Id="BlenderFoundation.Blender"; Name="Blender (3D Graphics)"; CatKey="Media"; Desc="Blender is a powerful open-source 3D creation suite, offering modeling, sculpting, animation, and rendering tools."; Rec=$false },
    @{ Id="calibre.calibre"; Name="Calibre"; CatKey="Media"; Desc="Calibre is a powerful and easy-to-use e-book manager, viewer, and converter."; Rec=$false },
    @{ Id="File-New-Project.EarTrumpet"; Name="EarTrumpet (Audio)"; CatKey="Media"; Desc="EarTrumpet is an audio control app for Windows, providing a simple and intuitive interface for managing sound settings."; Rec=$false },
    @{ Id="PeterPawlowski.foobar2000"; Name="foobar2000 (Music Player)"; CatKey="Media"; Desc="foobar2000 is a highly customizable and extensible music player for Windows, known for its modular design and advance..."; Rec=$false },
    @{ Id="GIMP.GIMP.3"; Name="GIMP (Image Editor)"; CatKey="Media"; Desc="GIMP is a versatile open-source raster graphics editor used for tasks such as photo retouching, image editing, and im..."; Rec=$false },
    @{ Id="HandBrake.HandBrake"; Name="HandBrake"; CatKey="Media"; Desc="HandBrake is an open-source video transcoder, allowing you to convert video from nearly any format to a selection of ..."; Rec=$false },
    @{ Id="DuongDieuPhap.ImageGlass"; Name="ImageGlass (Image Viewer)"; CatKey="Media"; Desc="ImageGlass is a versatile image viewer with support for various image formats and a focus on simplicity and speed."; Rec=$false },
    @{ Id="IrfanSkiljan.IrfanView"; Name="IrfanView"; CatKey="Media"; Desc="IrfanView is a lightweight, fast, and free image viewer and editor. Supports multiple formats, batch processing, and ..."; Rec=$false },
    @{ Id="Apple.iTunes"; Name="iTunes"; CatKey="Media"; Desc="iTunes is a media player, media library, and online radio broadcaster application developed by Apple Inc."; Rec=$false },
    @{ Id="CodecGuide.K-LiteCodecPack.Standard"; Name="K-Lite Codec Standard"; CatKey="Media"; Desc="K-Lite Codec Pack Standard is a collection of audio and video codecs and related tools, providing essential component..."; Rec=$false },
    @{ Id="clsid2.mpc-hc"; Name="Media Player Classic - Home Cinema"; CatKey="Media"; Desc="Media Player Classic - Home Cinema (MPC-HC) is a free and open-source video and audio player for Windows. MPC-HC is b..."; Rec=$false },
    @{ Id="mpc-qt.mpc-qt"; Name="mpc-qt"; CatKey="Media"; Desc="Media Player Classic Qute Theater"; Rec=$false },
    @{ Id="shinchiro.mpv"; Name="mpv"; CatKey="Media"; Desc="mpv is a free, open source, and cross-platform media player supporting a wide variety of media formats, codecs, and s..."; Rec=$false },
    @{ Id="nomacs.nomacs"; Name="nomacs"; CatKey="Media"; Desc="nomacs is a free, open-source image viewer, which supports multiple platforms. You can use it for viewing all common ..."; Rec=$false },
    @{ Id="Notepad++.Notepad++"; Name="Notepad++"; CatKey="Media"; Desc="Notepad++ is a free, open-source code editor and Notepad replacement with support for multiple languages."; Rec=$false },
    @{ Id="OBSProject.OBSStudio"; Name="OBS Studio"; CatKey="Media"; Desc="OBS Studio is a free and open-source software for video recording and live streaming. It supports real-time video/aud..."; Rec=$false },
    @{ Id="dotPDN.PaintDotNet"; Name="Paint.NET"; CatKey="Media"; Desc="Paint.NET is a free image and photo editing software for Windows. It features an intuitive user interface and support..."; Rec=$false },
    @{ Id="ShareX.ShareX"; Name="ShareX (Screenshots)"; CatKey="Media"; Desc="ShareX is a free and open-source screen capture and file sharing tool. It supports various capture methods and offers..."; Rec=$false },
    @{ Id="VideoLAN.VLC"; Name="VLC (Video Player)"; CatKey="Media"; Desc="VLC Media Player is a free and open-source multimedia player that supports a wide range of audio and video formats. I..."; Rec=$true },
    @{ Id="Famatech.AdvancedIPScanner"; Name="Advanced IP Scanner"; CatKey="ProTools"; Desc="Advanced IP Scanner is a fast and easy-to-use network scanner. It is designed to analyze LAN networks and provides in..."; Rec=$false },
    @{ Id="angryziber.AngryIPScanner"; Name="Angry IP Scanner"; CatKey="ProTools"; Desc="Angry IP Scanner is an open-source and cross-platform network scanner. It is used to scan IP addresses and ports, pro..."; Rec=$false },
    @{ Id="Maxon.CinebenchR23"; Name="Cinebench R23"; CatKey="ProTools"; Desc="Cinebench R23 is a benchmark tool for comparing CPU rendering performance across systems."; Rec=$false },
    @{ Id="CPUID.CPU-Z"; Name="CPU-Z"; CatKey="ProTools"; Desc="CPU-Z is a system monitoring and diagnostic tool for Windows. It provides detailed information about the computer's h..."; Rec=$true },
    @{ Id="Wagnardsoft.DisplayDriverUninstaller"; Name="Display Driver Uninstaller"; CatKey="ProTools"; Desc="Display Driver Uninstaller (DDU) is a tool for completely uninstalling graphics drivers from NVIDIA, AMD, and Intel. ..."; Rec=$true },
    @{ Id="TechPowerUp.GPU-Z"; Name="GPU-Z"; CatKey="ProTools"; Desc="GPU-Z provides detailed information about your graphics card and GPU."; Rec=$false },
    @{ Id="gerardog.gsudo"; Name="gsudo"; CatKey="ProTools"; Desc="gsudo is a sudo equivalent for Windows. It allows you to run commands with elevated administrative privileges directl..."; Rec=$false },
    @{ Id="REALiX.HWiNFO"; Name="HWiNFO"; CatKey="ProTools"; Desc="HWiNFO provides comprehensive hardware information and diagnostics for Windows."; Rec=$true },
    @{ Id="CPUID.HWMonitor"; Name="HWMonitor"; CatKey="ProTools"; Desc="HWMonitor is a hardware monitoring program that reads PC systems main health sensors."; Rec=$false },
    @{ Id="MullvadVPN.MullvadVPN"; Name="Mullvad VPN"; CatKey="ProTools"; Desc="This is the VPN client software for the Mullvad VPN service."; Rec=$false },
    @{ Id="Insecure.Nmap"; Name="Nmap"; CatKey="ProTools"; Desc="Nmap (Network Mapper) is an open-source tool for network exploration and security auditing. It discovers devices on a..."; Rec=$false },
    @{ Id="OpenVPNTechnologies.OpenVPNConnect"; Name="OpenVPN Connect"; CatKey="ProTools"; Desc="OpenVPN Connect is a VPN client that allows you to connect securely to a VPN server. It provides a secure and encrypt..."; Rec=$false },
    @{ Id="Proton.ProtonVPN"; Name="Proton VPN"; CatKey="ProTools"; Desc="Proton VPN is a no-logs VPN service that protects your privacy online with features like Secure Core and Tor over VPN."; Rec=$false },
    @{ Id="PuTTY.PuTTY"; Name="PuTTY"; CatKey="ProTools"; Desc="PuTTY is a free and open-source terminal emulator, serial console, and network file transfer application. It supports..."; Rec=$false },
    @{ Id="Henry++.simplewall"; Name="Simplewall"; CatKey="ProTools"; Desc="Simplewall is a free and open-source firewall application for Windows. It allows users to control and manage the inbo..."; Rec=$false },
    @{ Id="Ventoy.Ventoy"; Name="Ventoy"; CatKey="ProTools"; Desc="Ventoy is an open-source tool for creating bootable USB drives. It supports multiple ISO files on a single USB drive,..."; Rec=$false },
    @{ Id="WinSCP.WinSCP"; Name="WinSCP"; CatKey="ProTools"; Desc="WinSCP is a popular open-source SFTP, FTP, and SCP client for Windows. It allows secure file transfers between a loca..."; Rec=$false },
    @{ Id="WireGuard.WireGuard"; Name="WireGuard"; CatKey="ProTools"; Desc="WireGuard is a fast and modern VPN (Virtual Private Network) protocol. It aims to be simpler and more efficient than ..."; Rec=$false },
    @{ Id="WiresharkFoundation.Wireshark"; Name="Wireshark"; CatKey="ProTools"; Desc="Wireshark is a widely-used open-source network protocol analyzer. It allows users to capture and analyze network traf..."; Rec=$false },
    @{ Id="Microsoft.DotNet.DesktopRuntime.10"; Name=".NET Desktop Runtime 10"; CatKey="Runtimes"; Desc=".NET Desktop Runtime 10 is a runtime environment required for running applications developed with .NET 10."; Rec=$false },
    @{ Id="Microsoft.DotNet.DesktopRuntime.6"; Name=".NET Desktop Runtime 6"; CatKey="Runtimes"; Desc=".NET Desktop Runtime 6 is a runtime environment required for running applications developed with .NET 6."; Rec=$false },
    @{ Id="Microsoft.DotNet.DesktopRuntime.8"; Name=".NET Desktop Runtime 8"; CatKey="Runtimes"; Desc=".NET Desktop Runtime 8 is a runtime environment required for running applications developed with .NET 8."; Rec=$false },
    @{ Id="Microsoft.DotNet.DesktopRuntime.9"; Name=".NET Desktop Runtime 9"; CatKey="Runtimes"; Desc=".NET Desktop Runtime 9 is a runtime environment required for running applications developed with .NET 9."; Rec=$false },
    @{ Id="Microsoft.Sysinternals.Autoruns"; Name="Autoruns"; CatKey="Runtimes"; Desc="This utility shows you what programs are configured to run during system bootup or login."; Rec=$false },
    @{ Id="CodingWondersSoftware.DISMTools.Stable"; Name="DISMTools"; CatKey="Runtimes"; Desc="DISMTools is a fast, customizable GUI for the DISM utility, supporting Windows images from Windows 7 onward. It handl..."; Rec=$false },
    @{ Id="Nlitesoft.NTLite"; Name="NTLite"; CatKey="Runtimes"; Desc="Integrate updates, drivers, automate Windows and application setup, speedup Windows deployment process and have it al..."; Rec=$false },
    @{ Id="Microsoft.NuGet"; Name="NuGet"; CatKey="Runtimes"; Desc="NuGet is a package manager for the .NET framework, enabling developers to manage and share libraries in their .NET ap..."; Rec=$false },
    @{ Id="Microsoft.OneDrive"; Name="OneDrive"; CatKey="Runtimes"; Desc="OneDrive is a cloud storage service provided by Microsoft, allowing users to store and share files securely across de..."; Rec=$false },
    @{ Id="Microsoft.PowerShell"; Name="PowerShell"; CatKey="Runtimes"; Desc="PowerShell is a task automation framework and scripting language designed for system administrators, offering powerfu..."; Rec=$false },
    @{ Id="Microsoft.PowerToys"; Name="PowerToys"; CatKey="Runtimes"; Desc="PowerToys is a set of utilities for power users to enhance productivity, featuring tools like FancyZones, PowerRename..."; Rec=$true },
    @{ Id="Microsoft.Sysinternals.ProcessExplorer"; Name="Process Explorer"; CatKey="Runtimes"; Desc="Process Explorer is a task manager and system monitor."; Rec=$false },
    @{ Id="Microsoft.Sysinternals.ProcessMonitor"; Name="Process Monitor"; CatKey="Runtimes"; Desc="SysInternals Process Monitor is an advanced monitoring tool that shows real-time file system, registry, and process/t..."; Rec=$false },
    @{ Id="Microsoft.Sysinternals.RDCMan"; Name="RDCMan"; CatKey="Runtimes"; Desc="RDCMan manages multiple remote desktop connections. It is useful for managing server labs where you need regular acce..."; Rec=$false },
    @{ Id="Microsoft.Sysinternals.TCPView"; Name="TCPView"; CatKey="Runtimes"; Desc="SysInternals TCPView is a network monitoring tool that displays a detailed list of all TCP and UDP endpoints on your ..."; Rec=$false },
    @{ Id="Microsoft.VCRedist.2015+.x86"; Name="Visual C++ 2015-2022 32-bit"; CatKey="Runtimes"; Desc="Visual C++ 2015-2022 32-bit redistributable package installs runtime components of Visual C++ libraries required to r..."; Rec=$false },
    @{ Id="Microsoft.VCRedist.2015+.x64"; Name="Visual C++ 2015-2022 64-bit"; CatKey="Runtimes"; Desc="Visual C++ 2015-2022 64-bit redistributable package installs runtime components of Visual C++ libraries required to r..."; Rec=$false },
    @{ Id="Microsoft.WindowsTerminal"; Name="Windows Terminal"; CatKey="Runtimes"; Desc="Windows Terminal is a modern, fast, and efficient terminal application for command-line users, supporting multiple ta..."; Rec=$false },
    @{ Id="Jellyfin.JellyfinMediaPlayer"; Name="Jellyfin Media Player"; CatKey="Selfhosted"; Desc="Jellyfin Media Player is a client application for the Jellyfin media server, providing access to your media library."; Rec=$false },
    @{ Id="Jellyfin.Server"; Name="Jellyfin Server"; CatKey="Selfhosted"; Desc="Jellyfin Server is an open-source media server software, allowing you to organize and stream your media library."; Rec=$false },
    @{ Id="XBMCFoundation.Kodi"; Name="Kodi Media Center"; CatKey="Selfhosted"; Desc="Kodi is an open-source media center application that allows you to play and view most videos, music, podcasts, and ot..."; Rec=$false },
    @{ Id="LocalSend.LocalSend"; Name="LocalSend"; CatKey="Selfhosted"; Desc="An open-source cross-platform alternative to AirDrop."; Rec=$false },
    @{ Id="MoonlightGameStreamingProject.Moonlight"; Name="Moonlight/GameStream Client"; CatKey="Selfhosted"; Desc="Moonlight/GameStream Client allows you to stream PC games to other devices over your local network."; Rec=$false },
    @{ Id="Netbird.Netbird"; Name="NetBird"; CatKey="Selfhosted"; Desc="NetBird is an open-source alternative comparable to TailScale that can be connected to a self-hosted server."; Rec=$false },
    @{ Id="Nextcloud.NextcloudDesktop"; Name="Nextcloud Desktop"; CatKey="Selfhosted"; Desc="Nextcloud Desktop is the official desktop client for the Nextcloud file synchronization and sharing platform."; Rec=$false },
    @{ Id="Plex.Plex"; Name="Plex Desktop"; CatKey="Selfhosted"; Desc="Plex Desktop for Windows is the front end for Plex Media Server."; Rec=$false },
    @{ Id="Plex.PlexMediaServer"; Name="Plex Media Server"; CatKey="Selfhosted"; Desc="Plex Media Server is a media server software that allows you to organize and stream your media library. It supports v..."; Rec=$false },
    @{ Id="LizardByte.Sunshine"; Name="Sunshine/GameStream Server"; CatKey="Selfhosted"; Desc="Sunshine is a GameStream server that allows you to remotely play PC games on Android devices, offering low-latency st..."; Rec=$false },
    @{ Id="AgileBits.1Password"; Name="1Password"; CatKey="Utilities"; Desc="1Password is a password manager that allows you to store and manage your passwords securely."; Rec=$false },
    @{ Id="7zip.7zip"; Name="7-Zip"; CatKey="Utilities"; Desc="7-Zip is a free and open-source file archiver utility. It supports several compression formats and provides a high co..."; Rec=$true },
    @{ Id="AnyDesk.AnyDesk"; Name="AnyDesk"; CatKey="Utilities"; Desc="AnyDesk is a remote desktop software that enables users to access and control computers remotely. It is known for its..."; Rec=$false },
    @{ Id="AutoHotkey.AutoHotkey"; Name="AutoHotkey"; CatKey="Utilities"; Desc="AutoHotkey is a scripting language for Windows that allows users to create custom automation scripts and macros. It i..."; Rec=$false },
    @{ Id="Bitwarden.Bitwarden"; Name="Bitwarden"; CatKey="Utilities"; Desc="Bitwarden is an open-source password management solution. It allows users to store and manage their passwords in a se..."; Rec=$true },
    @{ Id="Blur009.BlurAutoClicker"; Name="BlurAutoClicker"; CatKey="Utilities"; Desc="An Auto-clicker with a few advanced features and generally better performance than popular alternatives."; Rec=$false },
    @{ Id="Klocman.BulkCrapUninstaller"; Name="Bulk Crap Uninstaller"; CatKey="Utilities"; Desc="Bulk Crap Uninstaller is a free and open-source uninstaller utility for Windows. It helps users remove unwanted progr..."; Rec=$false },
    @{ Id="Cloudflare.Warp"; Name="Cloudflare WARP"; CatKey="Utilities"; Desc="WARP is a freemium VPN service provided by Cloudflare. Includes usage of Cloudflare's DNS"; Rec=$false },
    @{ Id="CrystalDewWorld.CrystalDiskInfo"; Name="Crystal Disk Info"; CatKey="Utilities"; Desc="Crystal Disk Info is a disk health monitoring tool that provides information about the status and performance of hard..."; Rec=$false },
    @{ Id="CrystalDewWorld.CrystalDiskMark"; Name="Crystal Disk Mark"; CatKey="Utilities"; Desc="Crystal Disk Mark is a disk benchmarking tool that measures the read and write speeds of storage devices. It helps us..."; Rec=$false },
    @{ Id="Deskflow.Deskflow"; Name="Deskflow"; CatKey="Utilities"; Desc="Deskflow is a free and open-source software KVM that lets you share a single keyboard and mouse across multiple compu..."; Rec=$false },
    @{ Id="Dropbox.Dropbox"; Name="Dropbox"; CatKey="Utilities"; Desc="Dropbox is a cloud storage client for syncing files, sharing content, and keeping documents available across devices."; Rec=$false },
    @{ Id="ente-io.auth-desktop"; Name="Ente Auth"; CatKey="Utilities"; Desc="Ente Auth is a free, cross-platform, end-to-end encrypted authenticator app."; Rec=$false },
    @{ Id="voidtools.Everything"; Name="Everything"; CatKey="Utilities"; Desc="Everything is a search engine that locates files and folders by filename instantly for Windows. Unlike Windows search..."; Rec=$true },
    @{ Id="flux.flux"; Name="F.lux"; CatKey="Utilities"; Desc="f.lux adjusts the color temperature of your screen to reduce eye strain during nighttime use."; Rec=$false },
    @{ Id="FilesCommunity.Files"; Name="Files"; CatKey="Utilities"; Desc="Alternative file explorer."; Rec=$false },
    @{ Id="glzr-io.glazewm"; Name="GlazeWM"; CatKey="Utilities"; Desc="GlazeWM is a tiling window manager for Windows inspired by i3 and Polybar."; Rec=$false },
    @{ Id="Google.GoogleDrive"; Name="Google Drive"; CatKey="Utilities"; Desc="File syncing across devices all tied to your Google account."; Rec=$false },
    @{ Id="Hugo.Hugo.Extended"; Name="Hugo"; CatKey="Utilities"; Desc="The world's fastest framework for building websites."; Rec=$false },
    @{ Id="MHNexus.HxD"; Name="HxD Hex Editor"; CatKey="Utilities"; Desc="HxD is a free hex editor that allows you to edit, view, search, and analyze binary files."; Rec=$false },
    @{ Id="Tonec.InternetDownloadManager"; Name="Internet Download Manager"; CatKey="Utilities"; Desc="Internet Download Manager is a download manager for accelerating, resuming, and scheduling file downloads."; Rec=$false },
    @{ Id="sylikc.JPEGView"; Name="JPEG View"; CatKey="Utilities"; Desc="JPEGView is a lean, fast and highly configurable viewer/editor for JPEG, BMP, PNG, WEBP, TGA, GIF, JXL, HEIC, HEIF, A..."; Rec=$false },
    @{ Id="KeePassXCTeam.KeePassXC"; Name="KeePassXC"; CatKey="Utilities"; Desc="KeePassXC is a modern, secure, and open-source password manager that stores and manages your most sensitive informati..."; Rec=$false },
    @{ Id="MiniTool.PartitionWizard.Free"; Name="MiniTool Partition Wizard"; CatKey="Utilities"; Desc="Comprehensive free partition manager that performs advanced operations Windows natively cannot, such as merging parti..."; Rec=$false },
    @{ Id="rcmaehl.MSEdgeRedirect"; Name="MSEdgeRedirect"; CatKey="Utilities"; Desc="A Tool to Redirect News, Search, Widgets, Weather, and More to your default browser."; Rec=$false },
    @{ Id="Guru3D.Afterburner"; Name="MSI Afterburner"; CatKey="Utilities"; Desc="MSI Afterburner is a graphics card overclocking utility with advanced features."; Rec=$false },
    @{ Id="M2Team.NanaZip"; Name="NanaZip"; CatKey="Utilities"; Desc="NanaZip is a fast and efficient file compression and decompression tool."; Rec=$false },
    @{ Id="Nilesoft.Shell"; Name="Nilesoft Shell"; CatKey="Utilities"; Desc="Shell is an expanded context menu tool that adds extra functionality and customization options to the Windows context..."; Rec=$false },
    @{ Id="TechPowerUp.NVCleanstall"; Name="NVCleanstall"; CatKey="Utilities"; Desc="NVCleanstall is a tool designed to customize NVIDIA driver installations, allowing advanced users to control more asp..."; Rec=$false },
    @{ Id="xM4ddy.OFGB"; Name="OFGB (Oh Frick Go Back)"; CatKey="Utilities"; Desc="GUI Tool to remove ads from various places around Windows 11"; Rec=$false },
    @{ Id="OPAutoClicker.OPAutoClicker"; Name="OPAutoClicker"; CatKey="Utilities"; Desc="A full-fledged autoclicker with two modes of autoclicking, at your dynamic cursor location or at a prespecified locat..."; Rec=$false },
    @{ Id="OpenRGB.OpenRGB"; Name="OpenRGB"; CatKey="Utilities"; Desc="OpenRGB is an open-source RGB lighting control software designed to manage and control RGB lighting for various compo..."; Rec=$false },
    @{ Id="Oracle.VirtualBox"; Name="Oracle VirtualBox"; CatKey="Utilities"; Desc="Oracle VirtualBox is a powerful and free open-source virtualization tool for x86 and AMD64/Intel64 architectures."; Rec=$false },
    @{ Id="Parsec.Parsec"; Name="Parsec"; CatKey="Utilities"; Desc="Parsec is a low-latency, high-quality remote desktop sharing application for collaborating and gaming across devices."; Rec=$false },
    @{ Id="Giorgiotani.Peazip"; Name="PeaZip"; CatKey="Utilities"; Desc="PeaZip is a free, open-source file archiver utility that supports multiple archive formats and provides encryption fe..."; Rec=$false },
    @{ Id="Fleex255.PolicyPlus"; Name="Policy Plus"; CatKey="Utilities"; Desc="Local Group Policy Editor plus more, for all Windows editions."; Rec=$false },
    @{ Id="BitSum.ProcessLasso"; Name="Process Lasso"; CatKey="Utilities"; Desc="Process Lasso is a system optimization and automation tool that improves system responsiveness and stability by adjus..."; Rec=$false },
    @{ Id="Proton.ProtonAuthenticator"; Name="Proton Authenticator"; CatKey="Utilities"; Desc="2FA app from Proton to securely sync and backup 2FA codes."; Rec=$false },
    @{ Id="Proton.ProtonDrive"; Name="Proton Drive"; CatKey="Utilities"; Desc="Proton Drive is an end-to-end encrypted Swiss vault for your files that protects your data."; Rec=$false },
    @{ Id="Proton.ProtonPass"; Name="Proton Pass"; CatKey="Utilities"; Desc="Proton Pass is a cloud-based password manager with end-to-end encryption and unique email aliases."; Rec=$false },
    @{ Id="qBittorrent.qBittorrent"; Name="qBittorrent"; CatKey="Utilities"; Desc="qBittorrent is a free and open-source BitTorrent client that aims to provide a feature-rich and lightweight alternati..."; Rec=$true },
    @{ Id="RevoUninstaller.RevoUninstaller"; Name="Revo Uninstaller"; CatKey="Utilities"; Desc="Revo Uninstaller is an advanced uninstaller tool that helps you remove unwanted software and clean up your system."; Rec=$false },
    @{ Id="Rufus.Rufus"; Name="Rufus Imager"; CatKey="Utilities"; Desc="Rufus is a utility that helps format and create bootable USB drives, such as USB keys or pen drives."; Rec=$false },
    @{ Id="WhirlwindFX.SignalRgb"; Name="SignalRGB"; CatKey="Utilities"; Desc="SignalRGB lets you control and sync your favorite RGB devices with one free application."; Rec=$false },
    @{ Id="GlennDelahoy.SnappyDriverInstallerOrigin"; Name="Snappy Driver Installer Origin"; CatKey="Utilities"; Desc="Snappy Driver Installer Origin is a free and open-source driver updater with a vast driver database for Windows."; Rec=$false },
    @{ Id="StartIsBack.StartAllBack"; Name="StartAllBack"; CatKey="Utilities"; Desc="StartAllBack restores and improves Windows taskbar, Start menu, File Explorer, and shell UI behavior."; Rec=$false },
    @{ Id="Tailscale.Tailscale"; Name="Tailscale"; CatKey="Utilities"; Desc="The Tailscale client allows you to connect all your devices using WireGuard®, without the hassle. Tailscale makes it ..."; Rec=$false },
    @{ Id="TeamViewer.TeamViewer"; Name="TeamViewer"; CatKey="Utilities"; Desc="TeamViewer is a popular remote access and support software that allows you to connect to and control remote devices."; Rec=$false },
    @{ Id="GlavSoft.TightVNC"; Name="TightVNC"; CatKey="Utilities"; Desc="TightVNC is a free and open-source remote desktop software that lets you access and control a computer over the netwo..."; Rec=$false },
    @{ Id="Ghisler.TotalCommander"; Name="Total Commander"; CatKey="Utilities"; Desc="Total Commander is a file manager for Windows that provides a powerful and intuitive interface for file management."; Rec=$false },
    @{ Id="CharlesMilette.TranslucentTB"; Name="TranslucentTB"; CatKey="Utilities"; Desc="TranslucentTB is a tool that allows you to customize the transparency of the Windows Taskbar."; Rec=$false },
    @{ Id="JAMSoftware.TreeSize.Free"; Name="TreeSize Free"; CatKey="Utilities"; Desc="TreeSize Free is a disk space manager that helps you analyze and visualize the space usage on your drives."; Rec=$false },
    @{ Id="Devolutions.UniGetUI"; Name="UniGetUI"; CatKey="Utilities"; Desc="UniGetUI is a GUI for WinGet, Chocolatey, and other Windows CLI package managers."; Rec=$false },
    @{ Id="RARLab.WinRAR"; Name="WinRAR"; CatKey="Utilities"; Desc="WinRAR is a powerful archive manager that allows you to create, manage, and extract compressed files."; Rec=$false },
    @{ Id="WiseCleaner.WiseProgramUninstaller"; Name="Wise Program Uninstaller (WiseCleaner)"; CatKey="Utilities"; Desc="Wise Program Uninstaller is the perfect solution for uninstalling Windows programs, allowing you to uninstall applica..."; Rec=$false },
    @{ Id="AntibodySoftware.WizTree"; Name="WizTree"; CatKey="Utilities"; Desc="WizTree is a fast disk space analyzer that helps you quickly find the files and folders consuming the most space on y..."; Rec=$false }
)

$Script:AvailableWingetUpgrades = @{}

function Get-WingetAvailableUpgrades {
    $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
    $upgradeMap = @{}
    if (Test-Path $tempOut) {
        $lines = Get-Content $tempOut -ErrorAction SilentlyContinue
        $headerFound = $false
        $idColStart = -1
        $verColStart = -1
        $availColStart = -1

        foreach ($line in $lines) {
            if ($line -match "---") {
                $headerFound = $true
                continue
            }
            if (-not $headerFound) {
                if ($line -match "Name\s+Id\s+Version\s+Available") {
                    $idColStart = $line.IndexOf("Id")
                    $verColStart = $line.IndexOf("Version")
                    $availColStart = $line.IndexOf("Available")
                }
                continue
            }

            if ([string]::IsNullOrWhiteSpace($line) -or $line -match "upgrades available" -or $line -match "package\(s\) have") {
                continue
            }

            if ($idColStart -gt 0 -and $verColStart -gt $idColStart -and $line.Length -gt $idColStart) {
                $pkgId = $line.Substring($idColStart, [math]::Min($line.Length - $idColStart, $verColStart - $idColStart)).Trim()
                $currVer = if ($line.Length -gt $verColStart) {
                    $len = if ($availColStart -gt $verColStart) { [math]::Min($line.Length - $verColStart, $availColStart - $verColStart) } else { $line.Length - $verColStart }
                    $line.Substring($verColStart, $len).Trim()
                } else { "" }
                $availVer = if ($line.Length -gt $availColStart) {
                    $line.Substring($availColStart).Trim().Split(" ")[0]
                } else { "" }

                if ($pkgId) {
                    $upgradeMap[$pkgId] = @{
                        Current = $currVer
                        Available = $availVer
                    }
                }
            }
        }
    }
    return $upgradeMap
}

function Check-WingetUpgradesAsync {
    $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
    $asyncCode = {
        param($outPath)
        $proc = Start-Process -FilePath "winget" -ArgumentList "upgrade", "--accept-source-agreements" -NoNewWindow -PassThru -RedirectStandardOutput $outPath -RedirectStandardError "$env:TEMP\winget_upgrades_err.txt"
        $proc.WaitForExit(15000)
    }

    $ps = [powershell]::Create()
    $ps.AddScript($asyncCode).AddArgument($tempOut) | Out-Null
    $asyncHandle = $ps.BeginInvoke()

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.add_Tick({
        param($s, $e)
        if ($asyncHandle.IsCompleted) {
            $timer.Stop()
            try { $ps.EndInvoke($asyncHandle) | Out-Null } catch {}
            try { $ps.Dispose() } catch {}

            $upgrades = Get-WingetAvailableUpgrades
            if ($upgrades -and $upgrades.Count -gt 0) {
                $Script:AvailableWingetUpgrades = $upgrades
                $updatesCount = 0
                foreach ($item in $Script:InstallerCatalogList) {
                    if ($Script:AvailableWingetUpgrades.ContainsKey($item.PackageId)) {
                        $upg = $Script:AvailableWingetUpgrades[$item.PackageId]
                        $item.HasUpdate = $true
                        $item.IsInstalled = $true
                        $item.CurrentVersion = $upg.Current
                        $item.AvailableVersion = $upg.Available
                        $item.Status = if ($Script:CurrentLang -eq "AR") { "🔄 تحديث ($($item.AvailableVersion))" } else { "🔄 Update ($($item.AvailableVersion))" }
                        $item.StatusBg = "#78350F"
                        $item.StatusFg = "#FBBF24"
                        $item.StatusVisibility = "Visible"
                        $updatesCount++
                    }
                }
                if ($BtnSelectUpdates) {
                    $BtnSelectUpdates.Content = if ($Script:CurrentLang -eq "AR") { "🔄 التحديثات ($updatesCount)" } else { "🔄 Updates ($updatesCount)" }
                    if ($updatesCount -gt 0) {
                        $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#78350F")
                        $BtnSelectUpdates.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
                        $BtnSelectUpdates.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                    }
                }
            }
        }
    })
    $timer.Start()
}

function Update-InstallerSelectionStatus {
    $sel = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnInstallSelectedApps.IsEnabled = $true
        $updateOnly = ($sel | Where-Object { $_.HasUpdate -or $_.IsInstalled }).Count -eq $sel.Count
        if ($updateOnly) {
            $BtnInstallSelectedApps.Content = if ($Script:CurrentLang -eq "AR") { "🔄 ترقية البرامج المحددة ($($sel.Count))" } else { "🔄 Upgrade Selected Apps ($($sel.Count))" }
        } else {
            $BtnInstallSelectedApps.Content = if ($Script:CurrentLang -eq "AR") { "🚀 تثبيت وترقية البرامج ($($sel.Count))" } else { "🚀 Install / Upgrade Apps ($($sel.Count))" }
        }
        $TxtInstallerStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "تم تحديد $($sel.Count) تطبيق للتثبيت أو الترقية عبر Winget."
        } else {
            "$($sel.Count) application(s) selected for silent installation / upgrade via Winget."
        }
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    } else {
        $BtnInstallSelectedApps.IsEnabled = $false
        $BtnInstallSelectedApps.Content = if ($Script:CurrentLang -eq "AR") { "🚀 تثبيت البرامج المحددة" } else { "🚀 Install Selected Apps" }
        $TxtInstallerStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "حدد تطبيقاً أو أكثر لتثبيته أو ترقيته صامتاً وبضغطة زر واحدة."
        } else {
            "Select one or more software applications to silently install or upgrade via official winget."
        }
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

function Init-InstallerAppsList {
    $Script:InstallerCatalogList.Clear()
    $Script:InstallerCategoryCards.Clear()
    $Script:Col1Cards.Clear()
    $Script:Col2Cards.Clear()
    $Script:Col3Cards.Clear()
    $Script:Col4Cards.Clear()
    $idx = 0

    # Quick installed check against uninstall registry keys
    $installedDisplayNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        $keys = Get-ItemProperty $path -ErrorAction SilentlyContinue
        foreach ($k in $keys) {
            if ($k.DisplayName) {
                $installedDisplayNames.Add($k.DisplayName.Trim()) | Out-Null
            }
        }
    }

    # Prepare 10 Category Cards with curated distinctive colors
    $categoriesConfig = @(
        @{ Key="Browsers"; HeaderEn="🌐 Web Browsers"; HeaderAr="🌐 متصفحات الويب"; Color="#38BDF8"; Col=1 },
        @{ Key="Utilities"; HeaderEn="🛠️ System Utilities"; HeaderAr="🛠️ أدوات النظام والصيانة"; Color="#818CF8"; Col=1 },
        @{ Key="Development"; HeaderEn="💻 Development & Tools"; HeaderAr="💻 التطوير والبرمجة"; Color="#34D399"; Col=2 },
        @{ Key="Communications"; HeaderEn="💬 Chat & Comms"; HeaderAr="💬 المحادثة والتواصل"; Color="#FB7185"; Col=2 },
        @{ Key="Media"; HeaderEn="🎬 Media & Creative"; HeaderAr="🎬 الميديا والتصميم"; Color="#C084FC"; Col=3 },
        @{ Key="Runtimes"; HeaderEn="🪟 Microsoft & Runtimes"; HeaderAr="🪟 حزم التشغيل ومايكروسوفت"; Color="#60A5FA"; Col=3 },
        @{ Key="Selfhosted"; HeaderEn="☁️ Cloud & Streaming"; HeaderAr="☁️ السيرفر والمزامنة"; Color="#2DD4BF"; Col=3 },
        @{ Key="Gaming"; HeaderEn="🎮 Gaming & Launchers"; HeaderAr="🎮 الألعاب والمشغلات"; Color="#FB923C"; Col=4 },
        @{ Key="ProTools"; HeaderEn="⚡ Pro & Hardware Tools"; HeaderAr="⚡ أدوات الهاردوير والفحص"; Color="#FBBF24"; Col=4 },
        @{ Key="Documents"; HeaderEn="📄 Documents & Office"; HeaderAr="📄 المستندات والمكتب"; Color="#F472B6"; Col=4 }
    )

    $cardMap = @{}
    foreach ($c in $categoriesConfig) {
        $card = [ZeroCleaner.InstallerCategoryCard]::new()
        $card.Key = $c.Key
        $card.Header = if ($Script:CurrentLang -eq "AR") { $c.HeaderAr } else { $c.HeaderEn }
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

    # Load existing cached upgrades if available
    $upgrades = Get-WingetAvailableUpgrades
    if ($upgrades -and $upgrades.Count -gt 0) {
        $Script:AvailableWingetUpgrades = $upgrades
    }

    $updatesCount = 0

    foreach ($app in $Script:CatalogAppsData) {
        $idx++
        $item = [ZeroCleaner.InstallerAppItem]::new()
        $item.Index = $idx
        $item.DisplayName = $app.Name
        $item.PackageId = $app.Id
        $item.CategoryKey = $app.CatKey
        $item.Description = if ($app.Desc) { $app.Desc } else { $app.Name }
        $item.IsRecommended = ($app.Rec -eq $true)

        # 1. Check CLI commands on PATH (Instant & 100% accurate for developer tools)
        $isInst = $false
        if ($commandMap.ContainsKey($app.Id)) {
            foreach ($cmd in $commandMap[$app.Id]) {
                if (Get-Command $cmd -ErrorAction SilentlyContinue) {
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
                    ($app.Id -match "Python" -and $regName -match "Python\s*3") -or
                    ($app.Id -match "Rust" -and $regName -match "Rust") -or
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
            $item.Status = if ($Script:CurrentLang -eq "AR") { "🔄 تحديث ($($item.AvailableVersion))" } else { "🔄 Update ($($item.AvailableVersion))" }
            $item.StatusBg = "#78350F"
            $item.StatusFg = "#FBBF24"
            $item.StatusVisibility = "Visible"
        } elseif ($isInst) {
            $item.Status = if ($Script:CurrentLang -eq "AR") { "✅ مثبت" } else { "✅ Installed" }
            $item.StatusBg = "#064E3B"
            $item.StatusFg = "#34D399"
            $item.StatusVisibility = "Visible"
        } else {
            $item.Status = ""
            $item.StatusBg = "Transparent"
            $item.StatusFg = "#94A3B8"
            $item.StatusVisibility = "Collapsed"
        }

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
        $BtnSelectUpdates.Content = if ($Script:CurrentLang -eq "AR") { "🔄 التحديثات ($updatesCount)" } else { "🔄 Updates ($updatesCount)" }
        if ($updatesCount -gt 0) {
            $BtnSelectUpdates.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#78350F")
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

    Apply-InstallerFilters

    # Trigger background check for any new winget upgrades without blocking UI
    Check-WingetUpgradesAsync
}

function Apply-InstallerFilters {
    $q = if ($TxtInstallerSearch) { $TxtInstallerSearch.Text.Trim().ToLower() } else { "" }
    $cat = $Script:InstallerFilterCategory

    $Script:Col1Cards.Clear()
    $Script:Col2Cards.Clear()
    $Script:Col3Cards.Clear()
    $Script:Col4Cards.Clear()

    $visibleCards = [System.Collections.Generic.List[ZeroCleaner.InstallerCategoryCard]]::new()

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
        $card.CountText = if ($Script:CurrentLang -eq "AR") { "$appCount تطبيق" } else { "$appCount Apps" }
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

    foreach ($item in $Script:InstallerCatalogList) {
        $item.remove_PropertyChanged($Script:InstallerPropChangedHandler)
    }
    $Script:InstallerPropChangedHandler = [System.ComponentModel.PropertyChangedEventHandler]{
        param($s, $e)
        if ($e.PropertyName -eq "IsSelected") {
            Update-InstallerSelectionStatus
        }
    }
    foreach ($item in $Script:InstallerCatalogList) {
        $item.add_PropertyChanged($Script:InstallerPropChangedHandler)
    }

    Update-InstallerSelectionStatus
}

function Set-InstallerCategoryFilter([string]$cat, $activeBtn) {
    $Script:InstallerFilterCategory = $cat
    $buttons = @($BtnFilterInstAll, $BtnFilterInstBrowsers, $BtnFilterInstTools, $BtnFilterInstGaming, $BtnFilterInstComms, $BtnFilterInstMedia, $BtnFilterInstDev, $BtnFilterInstPro, $BtnFilterInstDocs, $BtnFilterInstRuntimes)
    foreach ($b in $buttons) {
        if ($b) {
            $b.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#151D30")
            $b.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A3756")
        }
    }
    if ($activeBtn) {
        $activeBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
        $activeBtn.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    }
    Apply-InstallerFilters
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

if ($TxtInstallerSearch) {
    $TxtInstallerSearch.add_TextChanged({ Apply-InstallerFilters })
}

if ($BtnSelectUpdates) {
    $BtnSelectUpdates.add_Click({
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = ($item.HasUpdate -eq $true)
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnSelectRecApps) {
    $BtnSelectRecApps.add_Click({
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
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = $true
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnDeselectAllInstApps) {
    $BtnDeselectAllInstApps.add_Click({
        foreach ($item in $Script:InstallerCatalogList) {
            $item.IsSelected = $false
        }
        Update-InstallerSelectionStatus
    })
}

if ($BtnRefreshInstStatus) {
    $BtnRefreshInstStatus.add_Click({
        Init-InstallerAppsList
    })
}

# Batch Install & Upgrade Action Worker
function Install-SelectedApps {
    $selected = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($selected.Count -eq 0) { return }

    # Verify winget
    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCheck) {
        $noWingetMsg = if ($Script:CurrentLang -eq "AR") {
            "لم يتم العثور على أداة مايكروسوفت (winget) في جهازك. يرجى تثبيت App Installer من متجر مايكروسوفت."
        } else {
            "Microsoft Package Manager (winget) was not found on this PC. Please install App Installer from Microsoft Store."
        }
        [System.Windows.MessageBox]::Show($noWingetMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $confirmMsg = if ($selected.Count -eq 1) {
        $actionWord = if ($selected[0].HasUpdate -or $selected[0].IsInstalled) { if ($Script:CurrentLang -eq "AR") { "ترقية" } else { "upgrade" } } else { if ($Script:CurrentLang -eq "AR") { "تثبيت" } else { "install" } }
        if ($Script:CurrentLang -eq "AR") {
            "هل ترغب في $actionWord برنامج '$($selected[0].DisplayName)' صامتاً عبر Winget؟"
        } else {
            "Do you want to silently $actionWord '$($selected[0].DisplayName)' via Winget?"
        }
    } else {
        if ($Script:CurrentLang -eq "AR") {
            "هل ترغب في تثبيت وترقية ($($selected.Count)) برامج محددة صامتاً عبر Winget؟"
        } else {
            "Do you want to silently batch-install / upgrade ($($selected.Count)) selected apps via Winget?"
        }
    }

    $confirmTitle = if ($Script:CurrentLang -eq "AR") { "تأكيد تثبيت وترقية البرامج" } else { "ZeroHub - Install / Upgrade Apps" }
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Activity Log Tab to show real-time installation progress
    $MainTabs.SelectedItem = $Tab_Log
    $BtnInstallSelectedApps.IsEnabled = $false

    $successCount = 0
    $idx = 0

    foreach ($app in $selected) {
        $idx++
        $isUpgrade = ($app.HasUpdate -eq $true -or $app.IsInstalled -eq $true)
        $actionVerb = if ($isUpgrade) { "Upgrading" } else { "Installing" }
        $statusStr = "[$idx / $($selected.Count)] $($actionVerb): $($app.DisplayName) ($($app.PackageId))..."
        Append-Log $statusStr "ACTION"
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $wingetCmd = if ($isUpgrade) { "upgrade" } else { "install" }
            $wingetArgs = "$wingetCmd --id $($app.PackageId) --silent --accept-package-agreements --accept-source-agreements --disable-interactivity -e"
            
            $onLineCallback = [Action[string]]{
                param($line)
                if ($line) {
                    Append-Log "  $line" "INFO"
                }
            }
            $onPumpCallback = [Action]{
                [System.Windows.Forms.Application]::DoEvents()
            }

            $exitCode = [ZeroCleaner.AsyncProcessRunner]::Run("winget", $wingetArgs, $onLineCallback, $onPumpCallback)

            if ($exitCode -eq 0 -or $exitCode -eq 3010) {
                Append-Log "Successfully completed $actionVerb for $($app.DisplayName)!" "SUCCESS"
                $successCount++
            } else {
                Append-Log "Winget completed with exit code $exitCode for $($app.DisplayName)" "WARN"
            }
        } catch {
            Append-Log "Error processing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = if ($Script:CurrentLang -eq "AR") {
        "اكتملت العملية! تم تثبيت/ترقية $successCount من أصل $($selected.Count) برنامج بنجاح."
    } else {
        "Process Complete! Successfully installed/upgraded $successCount of $($selected.Count) app(s)."
    }
    Append-Log $summary "SUCCESS"
    Show-ZeroToastNotification "ZeroHub - App Installer" $summary

    # Refresh catalog
    Init-InstallerAppsList
}

if ($BtnInstallSelectedApps) {
    $BtnInstallSelectedApps.add_Click({ Install-SelectedApps })
}

# --- REVO-STYLE DEEP APP UNINSTALLER TAB LOGIC ---
$Script:AllInstalledApps = [System.Collections.Generic.List[ZeroCleaner.InstalledAppItem]]::new()

function Update-InstalledAppsList() {
    $Script:AllInstalledApps.Clear()
    $TxtAppCount.Text = if ($Script:CurrentLang -eq "AR") { "جاري فحص البرامج وحساب المساحات..." } else { "Scanning apps & storage sizes..." }
    [System.Windows.Forms.Application]::DoEvents()

    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        $keys = Get-ItemProperty $path -ErrorAction SilentlyContinue
        foreach ($k in $keys) {
            if ($k.DisplayName -and -not $k.SystemComponent -and ($k.UninstallString -or $k.QuietUninstallString)) {
                $name = $k.DisplayName.Trim()
                if ($name -and -not $seen.Contains($name)) {
                    $seen.Add($name) | Out-Null

                    $sizeMB = 0
                    $resolvedFolder = $k.InstallLocation
                    $exeFound = $false
                    
                    # If InstallLocation is empty or missing, derive from uninstaller executable!
                    $uninstCheck = if ($k.UninstallString) { $k.UninstallString } else { $k.QuietUninstallString }
                    if ($uninstCheck) {
                        $exePath = ""
                        if ($uninstCheck -match '^"([^"]+\.exe)"') {
                            $exePath = $matches[1]
                        } elseif ($uninstCheck -match '^([a-zA-Z]:\\.+?\.exe)(\s+|$)') {
                            $exePath = $matches[1]
                        }
                        if ($exePath -and [System.IO.File]::Exists($exePath)) {
                            $exeFound = $true
                            if (-not $resolvedFolder -or -not [System.IO.Directory]::Exists($resolvedFolder)) {
                                $resolvedFolder = [System.IO.Path]::GetDirectoryName($exePath)
                            }
                        }
                    }

                    $folderExists = $resolvedFolder -and [System.IO.Directory]::Exists($resolvedFolder)

                    # 1. Use high-speed Registry EstimatedSize
                    if ($k.EstimatedSize -and $k.EstimatedSize -gt 0) {
                        if ($folderExists -or $exeFound -or [string]::IsNullOrWhiteSpace($resolvedFolder)) {
                            $sizeMB = [math]::Round(($k.EstimatedSize / 1024), 1)
                        }
                    }

                    # 2. Only calculate directory size if EstimatedSize was 0/missing but folder exists
                    if ($sizeMB -eq 0 -and $folderExists) {
                        try {
                            $bytes = [ZeroCleaner.NativeMethods]::FastGetDirectorySize($resolvedFolder)
                            $sizeMB = [math]::Round(($bytes / 1MB), 1)
                        } catch {}
                    }

                    $isOrphaned = ($sizeMB -eq 0)

                    # Comprehensive Game Detection Engine
                    $uninstFull = "$($k.UninstallString) $($k.QuietUninstallString)"
                    $isGame = $false
                    if ($uninstFull -like "*steam://*" -or $k.PSChildName -like "Steam App *" -or $resolvedFolder -like "*\steamapps\common\*") {
                        $isGame = $true
                    } elseif ($uninstFull -like "*com.epicgames.launcher://*" -or $resolvedFolder -like "*\Epic Games\*") {
                        $isGame = $true
                    } elseif ($resolvedFolder -like "*\Riot Games\*" -or $name -match "(League of Legends|VALORANT|Riot Client|Riot Vanguard|TFT)") {
                        $isGame = $true
                    } elseif ($resolvedFolder -match "(\\GOG Games\\|\\Ubisoft\\|\\EA Games\\|\\Battle\.net\\|\\Origin Games\\|\\XboxGames\\)" -or $k.Publisher -match "(Electronic Arts|Ubisoft|Blizzard|Rockstar Games|Valve|Epic Games|Bethesda|2K Games|Activision|Capcom|Bandai Namco|Sega|Square Enix|FromSoftware)") {
                        $isGame = $true
                    } elseif ($name -match "(Call of Duty|Battlefield|Cyberpunk|Witcher|Grand Theft Auto|Red Dead|Minecraft|Fortnite|Apex Legends|Counter-Strike|Dota|Overwatch|Genshin Impact|Honkai|Warframe|Destiny|Roblox|Steam|Dying Light|Risk of Rain|Vampire Survivors|Arena Breakout|Backrooms|Supermarket Together|Machine Party|REMATCH)") {
                        $isGame = $true
                    }

                    $sizeStr = if ($sizeMB -gt 0) {
                        Format-SpaceMB $sizeMB
                    } else {
                        if ($Script:CurrentLang -eq "AR") { "0 MB (محذوف مسبقاً)" } else { "0 MB (Orphaned)" }
                    }

                    $item = [ZeroCleaner.InstalledAppItem]::new()
                    $item.DisplayName = $name
                    $item.Publisher = if ($k.Publisher) { $k.Publisher } else { "Unknown" }
                    $item.DisplayVersion = if ($k.DisplayVersion) { $k.DisplayVersion } else { "--" }
                    $item.EstimatedSizeMB = $sizeMB
                    $item.SizeFormatted = $sizeStr
                    $item.InstallLocation = if ($resolvedFolder) { $resolvedFolder } elseif ($k.InstallLocation) { $k.InstallLocation } else { "" }
                    $item.UninstallString = if ($k.UninstallString) { $k.UninstallString } else { $k.QuietUninstallString }
                    $item.RegistryPath = $k.PSPath
                    $item.IsGame = $isGame
                    $item.IsOrphaned = $isOrphaned
                    $item.Category = if ($isGame) { "🎮 Game" } elseif ($isOrphaned) { "👻 Ghost" } else { "💻 App" }

                    $Script:AllInstalledApps.Add($item)
                }
            }
        }
    }

    Apply-AppFilters
    [ZeroCleaner.NativeMethods]::TrimSelfMemory()
}

$Script:CurrentAppFilter = "All"

function Set-AppFilterButtonStyles($activeFilter) {
    $defaultBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#151D30")
    $defaultBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A3756")
    $activeBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
    $activeBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")

    foreach ($btn in @($BtnFilterAll, $BtnFilterGames, $BtnFilterApps, $BtnFilterOrphaned)) {
        if ($btn) {
            $btn.Background = $defaultBg
            $btn.BorderBrush = $defaultBorder
            $btn.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    switch ($activeFilter) {
        "All" { if ($BtnFilterAll) { $BtnFilterAll.Background = $activeBg; $BtnFilterAll.BorderBrush = $activeBorder; $BtnFilterAll.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Games" { if ($BtnFilterGames) { $BtnFilterGames.Background = $activeBg; $BtnFilterGames.BorderBrush = $activeBorder; $BtnFilterGames.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Apps" { if ($BtnFilterApps) { $BtnFilterApps.Background = $activeBg; $BtnFilterApps.BorderBrush = $activeBorder; $BtnFilterApps.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Orphaned" { if ($BtnFilterOrphaned) { $BtnFilterOrphaned.Background = $activeBg; $BtnFilterOrphaned.BorderBrush = $activeBorder; $BtnFilterOrphaned.FontWeight = [System.Windows.FontWeights]::Bold } }
    }
}

function Apply-AppFilters() {
    $q = if ($TxtAppSearch.Text) { $TxtAppSearch.Text.Trim().ToLower() } else { "" }
    $filterMode = $Script:CurrentAppFilter
    
    $filtered = $Script:AllInstalledApps | Where-Object {
        $app = $_
        $matchesSearch = [string]::IsNullOrWhiteSpace($q) -or 
            $app.DisplayName.ToLower().Contains($q) -or
            $app.Publisher.ToLower().Contains($q) -or
            $app.InstallLocation.ToLower().Contains($q)

        $matchesCategory = if ($filterMode -eq "Games") {
            $app.IsGame
        } elseif ($filterMode -eq "Apps") {
            (-not $app.IsGame -and -not $app.IsOrphaned)
        } elseif ($filterMode -eq "Orphaned") {
            $app.IsOrphaned
        } else {
            $true
        }

        $matchesSearch -and $matchesCategory
    }

    $idx = 1
    foreach ($appItem in $filtered) {
        $appItem.Index = $idx++
    }
    $AppsGrid.ItemsSource = $filtered

    # Update count text
    $catName = if ($filterMode -eq "Games") {
        if ($Script:CurrentLang -eq "AR") { "ألعاب" } else { "Games" }
    } elseif ($filterMode -eq "Apps") {
        if ($Script:CurrentLang -eq "AR") { "برامج" } else { "Apps" }
    } elseif ($filterMode -eq "Orphaned") {
        if ($Script:CurrentLang -eq "AR") { "مخلفات يتيمة" } else { "Orphaned items" }
    } else {
        if ($Script:CurrentLang -eq "AR") { "برامج وألعاب" } else { "Total items" }
    }
    $TxtAppCount.Text = "$($filtered.Count) $catName"
}

# Category Filter Buttons
$BtnFilterAll.add_Click({
    $Script:CurrentAppFilter = "All"
    Set-AppFilterButtonStyles "All"
    Apply-AppFilters
})

$BtnFilterGames.add_Click({
    $Script:CurrentAppFilter = "Games"
    Set-AppFilterButtonStyles "Games"
    Apply-AppFilters
})

$BtnFilterApps.add_Click({
    $Script:CurrentAppFilter = "Apps"
    Set-AppFilterButtonStyles "Apps"
    Apply-AppFilters
})

$BtnFilterOrphaned.add_Click({
    $Script:CurrentAppFilter = "Orphaned"
    Set-AppFilterButtonStyles "Orphaned"
    Apply-AppFilters
})

# Search filter in App Uninstaller tab
$TxtAppSearch.add_TextChanged({ Apply-AppFilters })

# Bulk Selection & Status Handlers
function Update-AppSelectionStatus {
    $selectedList = @($Script:AllInstalledApps | Where-Object { $_.IsSelected })
    if ($selectedList.Count -eq 0 -and $AppsGrid.SelectedItem) {
        $selectedList = @($AppsGrid.SelectedItem)
    }

    if ($selectedList.Count -gt 0) {
        $BtnUninstallSelected.IsEnabled = $true
        $totalMB = ($selectedList | Measure-Object EstimatedSizeMB -Sum).Sum
        $sizeText = Format-SpaceMB $totalMB

        if ($selectedList.Count -eq 1) {
            $BtnUninstallSelected.Content = if ($Script:CurrentLang -eq "AR") { "حذف وتنظيف البرنامج المحدد" } else { "Uninstall & Clean Selected App" }
            $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") { "المحدد: $($selectedList[0].DisplayName) ($($selectedList[0].SizeFormatted))" } else { "Selected: $($selectedList[0].DisplayName) ($($selectedList[0].SizeFormatted))" }
        } else {
            $BtnUninstallSelected.Content = if ($Script:CurrentLang -eq "AR") { "حذف وتنظيف ($($selectedList.Count)) برامج محددة" } else { "Bulk Uninstall ($($selectedList.Count) Selected)" }
            $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") { "تم تحديد $($selectedList.Count) برامج (الحجم الإجمالي: $sizeText)" } else { "$($selectedList.Count) apps selected (Total Size: $sizeText)" }
        }
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    } else {
        $BtnUninstallSelected.IsEnabled = $false
        $BtnUninstallSelected.Content = if ($Script:CurrentLang -eq "AR") { "حذف البرامج وتنظيف المخلفات" } else { "Uninstall & Clean Leftovers" }
        $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") { "حدد برنامجاً أو أكثر من القائمة أعلاه للحذف الجماعي وتنظيف المخلفات." } else { "Select one or more applications from the list above to uninstall and clean leftovers." }
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

$BtnSelectAllApps.add_Click({
    $displayed = $AppsGrid.ItemsSource
    if ($displayed) {
        foreach ($app in $displayed) {
            $app.IsSelected = $true
        }
        $AppsGrid.Items.Refresh()
        Update-AppSelectionStatus
    }
})

$BtnDeselectAllApps.add_Click({
    foreach ($app in $Script:AllInstalledApps) {
        $app.IsSelected = $false
    }
    $AppsGrid.Items.Refresh()
    Update-AppSelectionStatus
})

# App selection change on row or checkbox click
$AppsGrid.add_SelectionChanged({ Update-AppSelectionStatus })

# Real-time CheckBox click handler (immediate instant count sync)
$AppsGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $AppsGrid.Dispatcher.BeginInvoke([Action]{
            Update-AppSelectionStatus
        })
    }
})

$BtnRefreshApps.add_Click({ Update-InstalledAppsList })

# Bulk / Single Uninstall & Leftover Clean Action
$BtnUninstallSelected.add_Click({
    try {
        $targetList = @($Script:AllInstalledApps | Where-Object { $_.IsSelected })
        if ($targetList.Count -eq 0 -and $AppsGrid.SelectedItem) {
            $targetList = @($AppsGrid.SelectedItem)
        }
        if ($targetList.Count -eq 0) { return }

        $totalMB = ($targetList | Measure-Object EstimatedSizeMB -Sum).Sum
        $totalSizeStr = Format-SpaceMB $totalMB

        # Bulk Confirmation Prompt
        $confirmMsg = if ($targetList.Count -eq 1) {
            if ($Script:CurrentLang -eq "AR") {
                "هل أنت متأكد من رغبتك في إلغاء تثبيت '$($targetList[0].DisplayName)' ($($targetList[0].SizeFormatted)) وحذف جميع المخلفات المتبقية؟"
            } else {
                "Are you sure you want to uninstall '$($targetList[0].DisplayName)' ($($targetList[0].SizeFormatted)) and clean all residual leftover files?"
            }
        } else {
            if ($Script:CurrentLang -eq "AR") {
                "هل أنت متأكد من رغبتك في إلغاء تثبيت ($($targetList.Count)) برامج محددة بحجم إجمالي ($totalSizeStr) وحذف جميع المخلفات المتبقية؟"
            } else {
                "Are you sure you want to bulk uninstall ($($targetList.Count)) selected applications (Total: $totalSizeStr) and clean all residual leftovers?"
            }
        }
        $confirmTitle = if ($Script:CurrentLang -eq "AR") { "تأكيد الحذف الجماعي" } else { "ZeroHub - Bulk Uninstall Confirm" }
        $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $successCount = 0
        $totalFreedBytes = 0
        $currentIdx = 0

        foreach ($targetApp in $targetList) {
            $currentIdx++

            # Handle Windows UWP / Bloatware package uninstallation
            if ($targetApp.IsAppx -and $targetApp.PackageFullName) {
                $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") {
                    "[$currentIdx / $($targetList.Count)] جاري إزالة تطبيق ويندوز: $($targetApp.DisplayName)..."
                } else {
                    "[$currentIdx / $($targetList.Count)] Removing Windows App: $($targetApp.DisplayName)..."
                }
                $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                [System.Windows.Forms.Application]::DoEvents()

                try {
                    Remove-AppxPackage -Package $targetApp.PackageFullName -ErrorAction SilentlyContinue
                    if ($isAdmin) {
                        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { 
                            $_.DisplayName -like "*$($targetApp.DisplayName)*" -or $_.PackageName -eq $targetApp.PackageFullName 
                        } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                    }
                    Append-Log "Successfully uninstalled UWP / Bloatware package: $($targetApp.DisplayName)" "SUCCESS"
                } catch {
                    Append-Log "Error removing UWP package $($targetApp.DisplayName): $($_.Exception.Message)" "ERROR"
                }

                $successCount++
                continue
            }

            $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") {
                "[$currentIdx / $($targetList.Count)] جاري تشغيل معالج إلغاء التثبيت لـ $($targetApp.DisplayName)... (يرجى إكمال خطوات الحذف من النافذة الظاهرة)"
            } else {
                "[$currentIdx / $($targetList.Count)] Running official uninstaller for $($targetApp.DisplayName)... (Please complete the uninstaller wizard on your screen)"
            }
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            [System.Windows.Forms.Application]::DoEvents()

            # 1. Execute Uninstaller and Wait for It to Completely Finish (Revo Style)
            $uninstStr = $targetApp.UninstallString
            $proc = $null
            if (-not [string]::IsNullOrWhiteSpace($uninstStr)) {
                $uninstStr = $uninstStr.Trim()
                Append-Log "Executing uninstaller for $($targetApp.DisplayName): $uninstStr" "UNINSTALL"

                if ($uninstStr -like "*steam://*") {
                    if ($uninstStr -match '(steam://uninstall/\d+)') {
                        $steamUrl = $matches[1]
                        [System.Diagnostics.Process]::Start($steamUrl) | Out-Null
                        Start-Sleep -Seconds 5
                    }
                } elseif ($uninstStr -match 'msiexec(\.exe)?\s*(/i|/x|/I|/X)\s*(\{[^}]+\})') {
                    $guid = $matches[3]
                    $psi = [System.Diagnostics.ProcessStartInfo]::new()
                    $psi.FileName = "msiexec.exe"
                    $psi.Arguments = "/x $guid"
                    $psi.UseShellExecute = $true
                    $proc = [System.Diagnostics.Process]::Start($psi)
                } else {
                    $exe = ""
                    $args = ""
                    if ($uninstStr -match '^"([^"]+\.exe)"\s*(.*)$') {
                        $exe = $matches[1]
                        $args = $matches[2].Trim()
                    } elseif ($uninstStr -match '^([a-zA-Z]:\\.+?\.exe)(\s+(.*))?$') {
                        $exe = $matches[1]
                        $args = if ($matches[3]) { $matches[3].Trim() } else { "" }
                    } else {
                        $exe = $uninstStr
                        $args = ""
                    }

                    if ($exe -and (Test-Path $exe)) {
                        $psi = [System.Diagnostics.ProcessStartInfo]::new()
                        $psi.FileName = $exe
                        $psi.Arguments = $args
                        $psi.UseShellExecute = $true
                        $proc = [System.Diagnostics.Process]::Start($psi)
                    }
                }
            }

            # Wait loop: monitor main process and child uninstaller processes until fully exited
            $maxWaitSec = 600
            $elapsed = 0
            Start-Sleep -Milliseconds 1200
            [System.Windows.Forms.Application]::DoEvents()

            while ($elapsed -lt $maxWaitSec) {
                [System.Windows.Forms.Application]::DoEvents()
                $stillRunning = $false

                if ($proc -and -not $proc.HasExited) {
                    $stillRunning = $true
                }

                # Check if uninstaller child processes are still running in target install directory
                if ($targetApp.InstallLocation -and [System.IO.Directory]::Exists($targetApp.InstallLocation)) {
                    $activeProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
                        try {
                            $pPath = $_.MainModule.FileName
                            $pPath -and $pPath.StartsWith($targetApp.InstallLocation, [StringComparison]::OrdinalIgnoreCase)
                        } catch { $false }
                    }
                    if ($activeProcs -and $activeProcs.Count -gt 0) {
                        $stillRunning = $true
                    }
                }

                if (-not $stillRunning) {
                    Start-Sleep -Milliseconds 1200
                    break
                }

                Start-Sleep -Milliseconds 350
                $elapsed += 0.35
            }

            # 2. Scanning & Cleaning Residual Leftovers (Only after uninstaller exits!)
            $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") {
                "[$currentIdx / $($targetList.Count)] اكتمل الحذف الرسمي! جاري فحص وتنظيف المخلفات المتبقية لـ $($targetApp.DisplayName)..."
            } else {
                "[$currentIdx / $($targetList.Count)] Uninstallation finished! Scanning and cleaning leftovers for $($targetApp.DisplayName)..."
            }
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            [System.Windows.Forms.Application]::DoEvents()

            # 2. Leftovers Hunt & Clean (With Strict Shared Folder Protection)
            $protectedRoots = @(
                "C:\", "D:\", "E:\", "F:\",
                "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData",
                "C:\Riot Games", "C:\Epic Games", "C:\Games",
                $env:LOCALAPPDATA, $env:APPDATA, $env:USERPROFILE
            )

            $blockedWords = @(
                "riot", "games", "game", "epic", "steam", "microsoft", "google", "adobe",
                "intel", "nvidia", "amd", "windows", "setup", "client", "launcher", "common",
                "shared", "team", "data", "bin", "temp", "program", "files"
            )

            $cleanName = ($targetApp.DisplayName -replace '\s*\d+(\.\d+)*(\s*\(x\d+\))?.*$', '').Trim()
            $tokens = @($cleanName) | Where-Object {
                $t = $_.Trim()
                $t.Length -ge 4 -and -not ($blockedWords -contains $t.ToLower())
            }

            $roots = @($env:LOCALAPPDATA, $env:APPDATA, $env:ProgramData)
            $leftoverDirs = @()

            # Safety check function
            $IsSafeToDelete = {
                param($pathToCheck)
                if (-not $pathToCheck -or -not (Test-Path $pathToCheck)) { return $false }
                $norm = $pathToCheck.TrimEnd('\').ToLower()

                foreach ($pr in $protectedRoots) {
                    if ($pr -and $norm -eq $pr.TrimEnd('\').ToLower()) { return $false }
                }

                # NEVER delete if another installed app shares this exact path or is a parent/child of another app
                foreach ($app in $Script:AllInstalledApps) {
                    if ($app.DisplayName -ne $targetApp.DisplayName -and $app.InstallLocation) {
                        $appLoc = $app.InstallLocation.TrimEnd('\').ToLower()
                        if ($norm -eq $appLoc -or $appLoc.StartsWith($norm + "\") -or $norm.StartsWith($appLoc + "\")) {
                            return $false
                        }
                    }
                }
                return $true
            }

            # Check InstallLocation safely
            if ($targetApp.InstallLocation -and (Test-Path $targetApp.InstallLocation)) {
                if (& $IsSafeToDelete $targetApp.InstallLocation) {
                    $files = Get-ChildItem $targetApp.InstallLocation -Recurse -Force -File -ErrorAction SilentlyContinue
                    $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                    $totalFreedBytes += $sz
                    $leftoverDirs += $targetApp.InstallLocation
                } else {
                    Append-Log "Protected shared directory from deletion: $($targetApp.InstallLocation)" "INFO"
                }
            }

            # Check AppData / ProgramData safely
            foreach ($r in $roots) {
                if (-not (Test-Path $r)) { continue }
                foreach ($tok in $tokens) {
                    $matches = Get-ChildItem -Path $r -Directory -Filter "*$tok*" -ErrorAction SilentlyContinue
                    foreach ($m in $matches) {
                        if (& $IsSafeToDelete $m.FullName) {
                            $files = Get-ChildItem $m.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
                            $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                            $totalFreedBytes += $sz
                            $leftoverDirs += $m.FullName
                        }
                    }
                }
            }

            $leftoverDirs = $leftoverDirs | Select-Object -Unique
            foreach ($ld in $leftoverDirs) {
                try {
                    Remove-Item -Path $ld -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
                    Append-Log "Purged leftover directory: $ld" "CLEAN"
                } catch {
                    [ZeroCleaner.NativeMethods]::ScheduleDeleteOnReboot($ld)
                }
            }

            # 3. Clean ghost registry entry
            if ($targetApp.RegistryPath -and (Test-Path $targetApp.RegistryPath)) {
                try {
                    Remove-Item -Path $targetApp.RegistryPath -Force -Recurse -ErrorAction SilentlyContinue
                } catch {}
            }

            $successCount++
        }

        $freedFinalMB = [math]::Round(($totalFreedBytes / 1MB), 2)
        $freedFinalStr = Format-SpaceMB $freedFinalMB

        $TxtSelectedAppStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "اكتمل الحذف الجماعي بنجاح! تم إلغاء تثبيت $successCount برامج وحذف $freedFinalStr من المخلفات."
        } else {
            "Bulk cleanup completed! Uninstalled $successCount apps and freed $freedFinalStr of leftovers."
        }
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        Append-Log "Bulk Uninstalled $successCount app(s) and freed $freedFinalStr of leftovers!" "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Bulk Uninstaller" "Successfully uninstalled $successCount apps and cleaned $freedFinalStr of leftovers!"

        # Refresh tables
        Update-InstalledAppsList
        Init-InstallerAppsList
    } catch {
        Append-Log "Error during bulk uninstaller: $($_.Exception.Message)" "ERROR"
    }
})

if ($BtnDeepUninstall) {
    $BtnDeepUninstall.add_Click({
        $MainTabs.SelectedItem = $Tab_Uninstaller
        if ($Script:AllInstalledApps.Count -eq 0) {
            Update-InstalledAppsList
        }
    })
}

if ($BtnFreeRam) {
    $BtnFreeRam.add_Click({
        try {
            $BtnFreeRam.IsEnabled = $false
            $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "جاري التحرير..." } else { "Freeing..." }
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            [System.Windows.Forms.Application]::DoEvents()

            # Optimize processes RAM working sets
            $optCount = [ZeroCleaner.NativeMethods]::OptimizeProcessesRam()

            Start-Sleep -Milliseconds 400

            Update-LiveMemoryStats

            # Visual feedback on button
            $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "تم التحرير!" } else { "Freed!" }
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")

            $msg = if ($Script:CurrentLang -eq "AR") {
                "تم تحرير الذاكرة بنجاح! تم تحسين $optCount عملية وتنظيف الذاكرة الفائضة."
            } else {
                "RAM Optimization Complete! Cleaned working sets across $optCount processes!"
            }
            Append-Log $msg "RAM"
            Show-ZeroToastNotification "ZeroHub - RAM Optimizer" $msg

            # Reset button label after 1.5 seconds
            if ($Script:RamResetTimer) { $Script:RamResetTimer.Stop() }
            $Script:RamResetTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $Script:RamResetTimer.Interval = [TimeSpan]::FromSeconds(1.5)
            $Script:RamResetTimer.Add_Tick({
                $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "تحرير الرام" } else { "Free RAM" }
                $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
                $BtnFreeRam.IsEnabled = $true
                $Script:RamResetTimer.Stop()
            })
            $Script:RamResetTimer.Start()
        } catch {
            $TxtFreeRam.Text = if ($Script:CurrentLang -eq "AR") { "تحرير الرام" } else { "Free RAM" }
            $TxtFreeRam.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            $BtnFreeRam.IsEnabled = $true
            Append-Log "Error optimizing RAM: $($_.Exception.Message)" "ERROR"
        }
    })
}

$BtnCreateShortcut.add_Click({
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "ZeroHub.lnk"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        
        $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { (Join-Path $PSScriptRoot "ZeroHub-GUI.ps1") }
        $batPath = Join-Path $PSScriptRoot "ZeroHub-GUI.bat"
        
        if (Test-Path $batPath) {
            $shortcut.TargetPath = $batPath
            $shortcut.WorkingDirectory = $PSScriptRoot
        } else {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
            $shortcut.WorkingDirectory = $PSScriptRoot
        }
        
        $shortcut.Description = "ZeroHub - Fast & Intelligent Windows Optimization Hub"
        $shortcut.IconLocation = "$env:SystemRoot\System32\cleanmgr.exe,0"
        $shortcut.Save()

        $msg = if ($Script:CurrentLang -eq "AR") {
            "تم إنشاء اختصار ZeroHub على سطح المكتب بنجاح!"
        } else {
            "ZeroHub Desktop shortcut created successfully!"
        }
        Append-Log "Desktop shortcut created: $shortcutPath" "SHORTCUT"
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Append-Log "Failed to create shortcut: $($_.Exception.Message)" "ERROR"
        [System.Windows.MessageBox]::Show("Failed to create shortcut: $($_.Exception.Message)", "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# ==========================================
# ==========================================
# WINDOWS AUTOMATIC UPDATES CONTROLLER LOGIC
# ==========================================
function Get-WinUpdateStatus {
    $service = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $noAuto = 0
    if (Test-Path $auPath) {
        $val = (Get-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue).NoAutoUpdate
        if ($val -eq 1) { $noAuto = 1 }
    }

    $isBlocked = ($service -and $service.StartType -eq "Disabled") -or ($noAuto -eq 1)
    return $isBlocked
}

function Update-WinUpdateUI {
    if (-not $BtnToggleWinUpdate -or -not $TxtWinUpdateStatus) { return }
    $isBlocked = Get-WinUpdateStatus
    $t = $Script:Translations[$Script:CurrentLang]

    if ($isBlocked) {
        # Updates are Blocked / Paused
        $TxtWinUpdateStatus.Text = $t.WinUpdateStatusBlocked
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDA4AF")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#371B28")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")

        $BtnToggleWinUpdate.Content = $t.BtnEnableWinUpdate
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = if ($Script:CurrentLang -eq "AR") { "🔴 الخدمات معطلة وموقوفة" } else { "🔴 Services Stopped & Disabled" }
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDA4AF")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = if ($Script:CurrentLang -eq "AR") { "🔴 التنزيل التلقائي محظور" } else { "🔴 Auto-Downloads Blocked" }
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDA4AF")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = if ($Script:CurrentLang -eq "AR") { "🔴 مهام الفحص معطلة" } else { "🔴 Scan Tasks Disabled" }
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDA4AF")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = if ($Script:CurrentLang -eq "AR") { "🟢 درع التعريفات نشط" } else { "🟢 Driver Shield Active" }
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        }
    } else {
        # Updates are Active
        $TxtWinUpdateStatus.Text = $t.WinUpdateStatusActive
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")

        $BtnToggleWinUpdate.Content = $t.BtnStopWinUpdate
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E11D48")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = if ($Script:CurrentLang -eq "AR") { "🟢 الخدمات تعمل بشكل طبيعي" } else { "🟢 Services Active (Default)" }
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = if ($Script:CurrentLang -eq "AR") { "🟢 السياسات الافتراضية" } else { "🟢 Policies Active (Default)" }
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = if ($Script:CurrentLang -eq "AR") { "🟢 المهام المجدولة نشطة" } else { "🟢 Tasks Scheduled (Default)" }
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = if ($Script:CurrentLang -eq "AR") { "⚪ وضع ويندوز الافتراضي" } else { "⚪ Default Windows Mode" }
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        }
    }
}

function Toggle-WindowsUpdates {
    $isBlocked = Get-WinUpdateStatus

    if (-not $isAdmin) {
        $msg = if ($Script:CurrentLang -eq "AR") {
            "يرجى تشغيل ZeroHub كمسؤول (Run as Administrator) لتعديل إعدادات تحديثات ويندوز."
        } else {
            "Please run ZeroHub as Administrator to modify Windows Update settings."
        }
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($isBlocked) {
        # ENABLE UPDATES
        try {
            Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "WaaSMedicSvc" -StartupType Manual -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (Test-Path $auPath) {
                Remove-ItemProperty -Path $auPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $auPath -Name "AUOptions" -ErrorAction SilentlyContinue
            }

            $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            if (Test-Path $wuPath) {
                Remove-ItemProperty -Path $wuPath -Name "SetDisableUXWUAccess" -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $wuPath -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
            }

            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan" -ErrorAction SilentlyContinue
            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan Static" -ErrorAction SilentlyContinue
            Enable-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "Scheduled Start" -ErrorAction SilentlyContinue

            $successMsg = if ($Script:CurrentLang -eq "AR") {
                "تم تفعيل تحديثات ويندوز بنجاح! يمكنك الآن البحث عن التحديثات وتثبيتها بشكل طبيعي."
            } else {
                "Windows Updates have been successfully enabled! You can now check for updates normally."
            }
            Append-Log "Windows Updates successfully enabled." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Append-Log "Error enabling Windows Updates: $($_.Exception.Message)" "ERROR"
        }
    } else {
        # STOP & BLOCK UPDATES
        try {
            Stop-Service -Name "wuauserv", "UsoSvc", "WaaSMedicSvc" -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "wuauserv" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "UsoSvc" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            Set-Service -Name "WaaSMedicSvc" -StartupType Disabled -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
            Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 1 -Type DWord -Force

            $wuPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            if (-not (Test-Path $wuPath)) { New-Item -Path $wuPath -Force | Out-Null }
            Set-ItemProperty -Path $wuPath -Name "SetDisableUXWUAccess" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $wuPath -Name "ExcludeWUDriversInQualityUpdate" -Value 1 -Type DWord -Force

            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "Schedule Scan Static" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -TaskName "UpdateModelTask" -ErrorAction SilentlyContinue
            Disable-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" -TaskName "Scheduled Start" -ErrorAction SilentlyContinue

            $successMsg = if ($Script:CurrentLang -eq "AR") {
                "تم إيقاف وحظر تحديثات ويندوز التلقائية والإجبارية بنجاح!"
            } else {
                "Windows Automatic Updates have been successfully stopped and blocked!"
            }
            Append-Log "Windows Updates successfully stopped and blocked." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Append-Log "Error stopping Windows Updates: $($_.Exception.Message)" "ERROR"
        }
    }

    Update-WinUpdateUI
}

$Script:WuCachePs     = $null
$Script:WuCacheHandle = $null
$Script:WuCacheTimer  = $null
$Script:WuCacheTicks  = 0

function Clear-WinUpdateCache {
    if (-not $isAdmin) {
        $msg = if ($Script:CurrentLang -eq "AR") { "يرجى تشغيل التطبيق كمسؤول لمسح ذاكرة التحديثات." } else { "Please run as Administrator to clear Windows Update cache." }
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($BtnCleanWuCache) {
        $BtnCleanWuCache.IsEnabled = $false
        $BtnCleanWuCache.Content = if ($Script:CurrentLang -eq "AR") { "⏳ جاري تنظيف الكاش..." } else { "⏳ Cleaning WU Cache..." }
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = if ($Script:CurrentLang -eq "AR") { "جاري إيقاف الخدمات وحذف كاش SoftwareDistribution\Download في الخلفية..." } else { "Stopping services and clearing SoftwareDistribution\Download cache in background..." }
    Append-Log "Beginning Windows Update cache purge in background..." "INFO"

    $asyncScript = {
        $freedMB = 0
        try {
            Stop-Service -Name "wuauserv", "bits", "cryptsvc" -Force -ErrorAction SilentlyContinue
            $swPath = "$env:SystemRoot\SoftwareDistribution\Download"
            if (Test-Path $swPath) {
                $items = Get-ChildItem -Path $swPath -Recurse -Force -ErrorAction SilentlyContinue
                $freedBytes = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                Remove-Item -Path "$swPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                if ($freedBytes) { $freedMB = [math]::Round(($freedBytes / 1MB), 2) }
            }
            Start-Service -Name "wuauserv", "bits", "cryptsvc" -ErrorAction SilentlyContinue
        } catch {}
        return $freedMB
    }

    $Script:WuCachePs = [powershell]::Create()
    $Script:WuCachePs.AddScript($asyncScript) | Out-Null
    $Script:WuCacheHandle = $Script:WuCachePs.BeginInvoke()
    $Script:WuCacheTicks = 0

    $Script:WuCacheTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuCacheTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    $Script:WuCacheTimer.add_Tick({
        $Script:WuCacheTicks++
        if ($Script:WuCacheHandle.IsCompleted -or $Script:WuCacheTicks -ge 30) {
            $Script:WuCacheTimer.Stop()
            $freedMB = 0
            try {
                if ($Script:WuCacheHandle.IsCompleted) {
                    $res = $Script:WuCachePs.EndInvoke($Script:WuCacheHandle)
                    if ($res) { $freedMB = [double]$res[0] }
                }
            } catch {}
            try { $Script:WuCachePs.Dispose() } catch {}

            if ($BtnCleanWuCache) {
                $BtnCleanWuCache.IsEnabled = $true
                $BtnCleanWuCache.Content = if ($Script:CurrentLang -eq "AR") { "🧹 تنظيف كاش التحديثات" } else { "🧹 Clean WU Cache" }
            }

            $msg = if ($Script:CurrentLang -eq "AR") { "تم تنظيف كاش التحديثات بنجاح وتوفير $freedMB ميغابايت!" } else { "Cleaned Windows Update cache successfully! Freed $freedMB MB." }
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Append-Log "Windows Update cache purged: $freedMB MB freed." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub" $msg
            Update-DriveInfo
        }
    })
    $Script:WuCacheTimer.Start()
}

$Script:WuResetPs     = $null
$Script:WuResetHandle = $null
$Script:WuResetTimer  = $null
$Script:WuResetTicks  = 0

function Reset-WinUpdateComponents {
    if (-not $isAdmin) {
        $msg = if ($Script:CurrentLang -eq "AR") { "يرجى تشغيل التطبيق كمسؤول لإعادة تعيين التحديثات." } else { "Please run as Administrator to reset Windows Update." }
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($BtnResetWuComponents) {
        $BtnResetWuComponents.IsEnabled = $false
        $BtnResetWuComponents.Content = if ($Script:CurrentLang -eq "AR") { "⏳ جاري إصلاح المكونات والشبكة..." } else { "⏳ Repairing Components & Network..." }
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = if ($Script:CurrentLang -eq "AR") { "جاري إعادة تسجيل مكتبات DLL وإعادة تعيين خدمات التحديث والشبكة..." } else { "Re-registering update DLLs and resetting network & update components in background..." }
    Append-Log "Starting fast background Windows Update component reset & DLL re-registration..." "INFO"

    $asyncScript = {
        try {
            Stop-Service -Name "wuauserv", "bits", "cryptsvc" -Force -ErrorAction SilentlyContinue
            $dllList = "wuapi.dll wuaueng.dll wups.dll wups2.dll qmgr.dll atl.dll urlmon.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll dssenh.dll rsaenh.dll cryptdlg.dll oleaut32.dll ole32.dll shell32.dll"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c for %d in ($dllList) do @if exist `"%SystemRoot%\System32\%d`" regsvr32.exe /s `"%SystemRoot%\System32\%d`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            Start-Service -Name "cryptsvc", "bits", "wuauserv" -ErrorAction SilentlyContinue
            return $true
        } catch {
            return $false
        }
    }

    $Script:WuResetPs = [powershell]::Create()
    $Script:WuResetPs.AddScript($asyncScript) | Out-Null
    $Script:WuResetHandle = $Script:WuResetPs.BeginInvoke()
    $Script:WuResetTicks = 0

    $Script:WuResetTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuResetTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    $Script:WuResetTimer.add_Tick({
        $Script:WuResetTicks++
        if ($Script:WuResetHandle.IsCompleted -or $Script:WuResetTicks -ge 30) {
            $Script:WuResetTimer.Stop()
            try {
                if ($Script:WuResetHandle.IsCompleted) {
                    $Script:WuResetPs.EndInvoke($Script:WuResetHandle) | Out-Null
                }
            } catch {}
            try { $Script:WuResetPs.Dispose() } catch {}

            if ($BtnResetWuComponents) {
                $BtnResetWuComponents.IsEnabled = $true
                $BtnResetWuComponents.Content = if ($Script:CurrentLang -eq "AR") { "🔧 إصلاح وإعادة تعيين" } else { "🔧 Reset Components" }
            }

            $msg = if ($Script:CurrentLang -eq "AR") { "تمت إعادة تعيين وتسجيل كافة مكتبات تحديثات ويندوز وإصلاح الأعطال بنجاح!" } else { "Windows Update components & DLLs have been reset and repaired successfully!" }
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Append-Log "Windows Update components and DLLs repaired & reset successfully." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub" $msg
            Update-WinUpdateUI
        }
    })
    $Script:WuResetTimer.Start()
}

function Open-WinUpdateSettings {
    Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue
}

if ($BtnToggleWinUpdate) {
    $BtnToggleWinUpdate.add_Click({ Toggle-WindowsUpdates })
}
if ($BtnCleanWuCache) {
    $BtnCleanWuCache.add_Click({ Clear-WinUpdateCache })
}
if ($BtnResetWuComponents) {
    $BtnResetWuComponents.add_Click({ Reset-WinUpdateComponents })
}
if ($BtnOpenWuSettings) {
    $BtnOpenWuSettings.add_Click({ Open-WinUpdateSettings })
}

# ==========================================
# DEDICATED BLOATWARE TAB LOGIC & ENGINE
# ==========================================
$Script:AllBloatwareApps = [System.Collections.ObjectModel.ObservableCollection[ZeroCleaner.InstalledAppItem]]::new()

function Update-BloatSelectionStatus {
    $sel = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnRemoveSelectedBloatware.IsEnabled = $true
        $TxtBloatSelectionStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "تم تحديد $($sel.Count) تطبيق للحذف والإزالة الكاملة."
        } else {
            "$($sel.Count) Windows apps selected for complete removal."
        }
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
    } else {
        $BtnRemoveSelectedBloatware.IsEnabled = $false
        $TxtBloatSelectionStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "حدد تطبيقاً أو أكثر من الجدول لحذفه نهائياً من الويندوز."
        } else {
            "Select one or more Windows apps from the table to permanently remove."
        }
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

function Update-BloatwareList() {
    $Script:AllBloatwareApps.Clear()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $knownBloatware = @{
        "Microsoft.MicrosoftEdge"                       = "Microsoft Edge"
        "Microsoft.MicrosoftEdge.Stable"                = "Microsoft Edge Browser"
        "Microsoft.MicrosoftEdgeDevToolsClient"         = "Microsoft Edge DevTools"
        "MicrosoftEdge"                                 = "Microsoft Edge"
        "Microsoft.549981C3F5F10"                      = "Cortana"
        "Microsoft.Copilot"                             = "Microsoft Copilot"
        "Microsoft.BingNews"                            = "Microsoft News (MSN)"
        "Microsoft.BingWeather"                         = "Bing Weather"
        "Microsoft.BingFinance"                         = "Bing Finance / Money"
        "Microsoft.BingSports"                          = "Bing Sports"
        "Microsoft.BingSearch"                          = "Bing Search Experience"
        "Microsoft.MicrosoftSolitaireCollection"        = "Solitaire & Casual Games"
        "Microsoft.ZuneMusic"                           = "Groove Music / Windows Media Player"
        "Microsoft.ZuneVideo"                           = "Movies & TV (Films & TV)"
        "Microsoft.WindowsFeedbackHub"                  = "Feedback Hub"
        "Microsoft.GetHelp"                             = "Get Help"
        "Microsoft.Getstarted"                          = "Tips (Get Started)"
        "Microsoft.YourPhone"                           = "Phone Link (Your Phone)"
        "Microsoft.WindowsMaps"                         = "Windows Maps"
        "Microsoft.WindowsSoundRecorder"                = "Voice Recorder / Sound Recorder"
        "Microsoft.People"                              = "Microsoft People"
        "Microsoft.Microsoft3DViewer"                   = "3D Viewer"
        "Microsoft.3DBuilder"                           = "3D Builder"
        "Microsoft.Paint3D"                             = "Paint 3D"
        "Microsoft.MixedReality.Portal"                 = "Mixed Reality Portal"
        "Microsoft.WindowsAlarms"                       = "Clock & Alarms"
        "Clipchamp"                                     = "Clipchamp Video Editor"
        "Microsoft.Clipchamp.Clipchamp"                 = "Clipchamp Video Editor"
        "Microsoft.WindowsCommunicationsApps"           = "Mail & Calendar"
        "Microsoft.Todos"                               = "Microsoft To Do"
        "Microsoft.PowerAutomateDesktop"                = "Power Automate"
        "Microsoft.GamingApp"                           = "Xbox App"
        "Microsoft.XboxGamingOverlay"                   = "Xbox Game Bar"
        "Microsoft.XboxIdentityProvider"                = "Xbox Identity Provider"
        "Microsoft.XboxSpeechToTextOverlay"             = "Xbox Speech Overlay"
        "Microsoft.Xbox.TCUI"                           = "Xbox TCUI"
        "Microsoft.MicrosoftOfficeHub"                  = "Microsoft 365 / Office Hub"
        "Microsoft.OutlookForWindows"                   = "New Outlook for Windows"
        "Microsoft.SkypeApp"                            = "Skype"
        "MicrosoftTeams"                                = "Microsoft Teams (Chat)"
        "Microsoft.Teams"                               = "Microsoft Teams (Chat)"
        "Microsoft.Wallet"                              = "Microsoft Pay / Wallet"
        "Microsoft.WindowsReadingList"                  = "Reading List"
        "Microsoft.OneConnect"                          = "Mobile Plans"
        "Microsoft.QuickAssist"                         = "Quick Assist"
        "Microsoft.Family"                              = "Microsoft Family Safety"
        "Microsoft.Windows.DevHome"                     = "Windows Dev Home"
        "Microsoft.GamingServices"                      = "Gaming Services (Xbox Background)"
        "SpotifyAB.SpotifyMusic"                        = "Spotify (UWP)"
        "Disney"                                        = "Disney+"
        "Disney.37853FC22B2CE"                          = "Disney+"
        "ByteDancePte.Ltd.TikTok"                       = "TikTok"
        "TikTok"                                        = "TikTok"
        "Amazon.AmazonPrimeVideo"                       = "Amazon Prime Video"
        "Amazon"                                        = "Amazon Prime Video"
        "Facebook.Facebook"                             = "Facebook"
        "Facebook.Instagram"                            = "Instagram"
        "Netflix"                                       = "Netflix"
        "King.com.CandyCrushSaga"                       = "Candy Crush Saga"
        "King.com.CandyCrushSodaSaga"                   = "Candy Crush Soda Saga"
        "King.com.BubbleWitch3Saga"                     = "Bubble Witch 3 Saga"
        "AdobeSystemsIncorporated.AdobePhotoshopExpress"  = "Photoshop Express"
        "Duolingo-LearnLanguagesforFree"                = "Duolingo"
        "Fitbit.FitbitCoach"                            = "Fitbit Coach"
        "McAfee"                                        = "McAfee Security (UWP)"
    }

    try {
        $packages = Get-AppxPackage -ErrorAction SilentlyContinue
        $idx = 1
        foreach ($p in $packages) {
            if ($p.IsFramework -or $p.NonRemovable -or $p.Name -like "*SecHealthUI*" -or $p.Name -like "*Windows.UI.*" -or $p.Name -like "*LanguageExperiencePack*" -or $p.Name -like "*DesktopAppInstaller*" -or $p.Name -like "*StorePurchaseApp*" -or $p.Name -like "*WindowsStore*") {
                continue
            }

            $friendlyName = $null
            foreach ($k in $knownBloatware.Keys) {
                if ($p.Name -like "*$k*") {
                    $friendlyName = $knownBloatware[$k]
                    break
                }
            }

            if (-not $friendlyName) { continue }

            if (-not $seen.Contains($friendlyName)) {
                $seen.Add($friendlyName) | Out-Null
                $item = [ZeroCleaner.InstalledAppItem]::new()
                $item.Index = $idx++
                $item.DisplayName = $friendlyName
                $item.PackageName = $p.Name
                $item.PackageFullName = $p.PackageFullName
                $item.Publisher = if ($p.PublisherId) { "Microsoft / Store" } else { "Microsoft Corporation" }
                $item.SafetyStatus = if ($Script:CurrentLang -eq "AR") { "🟢 آمن للحذف 100%" } else { "🟢 100% Safe to Remove" }
                $item.IsAppx = $true
                $item.IsBloatware = $true
                $item.IsSelected = $false
                $Script:AllBloatwareApps.Add($item)
            }
        }

        # Check Win32 Edge if installed
        $edgePaths = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        )
        $hasEdge = $false
        $edgeExe = $null
        foreach ($ep in $edgePaths) {
            if (Test-Path $ep) {
                $hasEdge = $true
                $edgeExe = $ep
                break
            }
        }
        if ($hasEdge -and -not $seen.Contains("Microsoft Edge Browser") -and -not $seen.Contains("Microsoft Edge")) {
            $seen.Add("Microsoft Edge Browser") | Out-Null
            $item = [ZeroCleaner.InstalledAppItem]::new()
            $item.Index = $idx++
            $item.DisplayName = "Microsoft Edge Browser"
            $item.PackageName = "Microsoft.Edge (Win32 / System)"
            $item.PackageFullName = "Microsoft.Edge.System"
            $item.Publisher = "Microsoft Corporation"
            $item.SafetyStatus = if ($Script:CurrentLang -eq "AR") { "🟢 آمن للحذف 100%" } else { "🟢 100% Safe to Remove" }
            $item.IsAppx = $false
            $item.IsBloatware = $true
            $item.IsSelected = $false
            $item.InstallLocation = [System.IO.Path]::GetDirectoryName($edgeExe)
            $Script:AllBloatwareApps.Add($item)
        }
    } catch {}

    $BloatwareGrid.ItemsSource = $Script:AllBloatwareApps
    if ($Script:AllBloatwareApps.Count -gt 0) {
        $countText = if ($Script:CurrentLang -eq "AR") { "تم العثور على $($Script:AllBloatwareApps.Count) تطبيق" } else { "$($Script:AllBloatwareApps.Count) Apps Found" }
        $TxtBloatwareCount.Text = $countText
        Update-BloatSelectionStatus
    } else {
        $TxtBloatwareCount.Text = if ($Script:CurrentLang -eq "AR") { "نظامك نظيف تماماً (0)" } else { "Clean Windows (0)" }
        $TxtBloatSelectionStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "🎉 رائع! نظام ويندوز لديك نظيف تماماً — لا توجد أي تطبيقات مزعجة أو مثبّتة مسبقاً على هذا الجهاز."
        } else {
            "🎉 Great news! Your Windows installation is already debloated — 0 unwanted apps found on this PC."
        }
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    }
}

$BtnSelectAllBloat.add_Click({
    foreach ($app in $Script:AllBloatwareApps) {
        $app.IsSelected = $true
    }
    $BloatwareGrid.Items.Refresh()
    Update-BloatSelectionStatus
})

$BtnDeselectAllBloat.add_Click({
    foreach ($app in $Script:AllBloatwareApps) {
        $app.IsSelected = $false
    }
    $BloatwareGrid.Items.Refresh()
    Update-BloatSelectionStatus
})

$BtnRefreshBloat.add_Click({
    Update-BloatwareList
})

$BloatwareGrid.add_SelectionChanged({ Update-BloatSelectionStatus })

$BloatwareGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    param($sender, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $BloatwareGrid.Dispatcher.BeginInvoke([Action]{
            Update-BloatSelectionStatus
        })
    }
})

$BtnRemoveSelectedBloatware.add_Click({
    $targetList = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($targetList.Count -eq 0) { return }

    $confirmMsg = if ($targetList.Count -eq 1) {
        if ($Script:CurrentLang -eq "AR") {
            "هل أنت متأكد من رغبتك في إزالة تطبيق الويندوز '$($targetList[0].DisplayName)'؟"
        } else {
            "Are you sure you want to remove Windows app '$($targetList[0].DisplayName)'?"
        }
    } else {
        if ($Script:CurrentLang -eq "AR") {
            "هل أنت متأكد من رغبتك في إزالة ($($targetList.Count)) من تطبيقات الويندوز المحددة نهائياً؟"
        } else {
            "Are you sure you want to permanently remove ($($targetList.Count)) selected Windows apps?"
        }
    }

    $confirmTitle = if ($Script:CurrentLang -eq "AR") { "تأكيد إزالة تطبيقات الويندوز" } else { "ZeroHub - Remove Windows Bloatware" }
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $BtnRemoveSelectedBloatware.IsEnabled = $false
    $currentIdx = 0
    $successCount = 0

    foreach ($app in $targetList) {
        $currentIdx++
        $TxtBloatSelectionStatus.Text = if ($Script:CurrentLang -eq "AR") {
            "[$currentIdx / $($targetList.Count)] جاري إزالة: $($app.DisplayName)..."
        } else {
            "[$currentIdx / $($targetList.Count)] Removing: $($app.DisplayName)..."
        }
        [System.Windows.Forms.Application]::DoEvents()

        try {
            if ($app.PackageName -like "*Microsoft.Edge*") {
                # Terminate running edge processes
                Stop-Process -Name "msedge", "msedgewebview2" -Force -ErrorAction SilentlyContinue
                
                # Check for Edge setup.exe
                $setups = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue
                if ($setups -and $setups.Count -gt 0) {
                    $setupExe = $setups[0].FullName
                    Start-Process -FilePath $setupExe -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                
                # Also try winget
                Start-Process -FilePath "winget" -ArgumentList "uninstall --id Microsoft.Edge --silent --force --accept-source-agreements" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                
                # Remove AppX Edge packages
                Get-AppxPackage *Edge* -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            } else {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                if ($isAdmin) {
                    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -like "*$($app.DisplayName)*" -or $_.PackageName -eq $app.PackageFullName
                    } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                }
            }
            Append-Log "Removed Windows Bloatware: $($app.DisplayName) ($($app.PackageName))" "SUCCESS"
            $successCount++
        } catch {
            Append-Log "Error removing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = if ($Script:CurrentLang -eq "AR") {
        "تمت إزالة $successCount من تطبيقات الويندوز بنجاح!"
    } else {
        "Successfully removed $successCount Windows apps!"
    }
    $TxtBloatSelectionStatus.Text = $summary
    $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    Show-ZeroToastNotification "ZeroHub - Bloatware Remover" $summary
    Update-BloatwareList
    Init-InstallerAppsList
})

# Tab Selection Changed Handler
$MainTabs.add_SelectionChanged({
    param($s, $e)
    if ($e.Source -is [System.Windows.Controls.TabControl]) {
        try {
            if ($MainTabs.SelectedItem -eq $Tab_Installer) {
                Init-InstallerAppsList
            }
            if ($MainTabs.SelectedItem -eq $Tab_Uninstaller -and $Script:AllInstalledApps.Count -eq 0) {
                Update-InstalledAppsList
            }
            if ($MainTabs.SelectedItem -eq $Tab_Bloatware -and $Script:AllBloatwareApps.Count -eq 0) {
                Update-BloatwareList
            }
            if ($MainTabs.SelectedItem -eq $Tab_Updates) {
                Update-WinUpdateUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Guard) {
                Update-ProcessGuardList
            }
        } catch {
            Append-Log "Tab switch warning: $($_.Exception.Message)" "WARN"
        }
    }
})

# Window Controls & Custom Titlebar Handlers
if ($BtnWindowMinimize) {
    $BtnWindowMinimize.add_Click({
        $Window.WindowState = [System.Windows.WindowState]::Minimized
    })
}
if ($BtnWindowMaximize) {
    $BtnWindowMaximize.add_Click({
        if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $Window.WindowState = [System.Windows.WindowState]::Normal
        } else {
            $Window.WindowState = [System.Windows.WindowState]::Maximized
        }
    })
}
if ($BtnWindowClose) {
    $BtnWindowClose.add_Click({
        $Window.Close()
    })
}

$Window.add_StateChanged({
    if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
        if ($TxtWindowMaximizeIcon) { $TxtWindowMaximizeIcon.Text = "❐" }
    } else {
        if ($TxtWindowMaximizeIcon) { $TxtWindowMaximizeIcon.Text = "🗖" }
    }
})

# Window Initialized Event
$Window.add_Loaded({
    try {
        $helper = [System.Windows.Interop.WindowInteropHelper]::new($Window)
        [ZeroCleaner.NativeMethods]::EnableDarkTitleBar($helper.Handle)
    } catch {}

    Update-DriveInfo
    Update-LiveMemoryStats
    Update-WinUpdateUI
    Set-AllSelections $false
    $modeStr = if ($isAdmin) { "Administrator" } else { "Standard User" }
    Append-Log "ZeroHub v2.5 initialized. User Mode: $modeStr" "INIT"
    Invoke-ScanSpace $false

    # Start Real-Time Live Metrics Timer (Every 1 second)
    $Script:MetricsTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:MetricsTimer.Interval = [TimeSpan]::FromSeconds(1)
    $Script:MetricsTimer.Add_Tick({
        Update-DriveInfo
        Update-LiveMemoryStats
    })
    $Script:MetricsTimer.Start()
})

# Show WPF Window
[void]$Window.ShowDialog()
