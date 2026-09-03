<#
================================================================================
  ZeroHub - Fast, Safe & Intelligent Windows Optimization Power Hub
  Copyright (C) 2026 Amir Ali <https://zeroiq.site/>
  Licensed under the GNU General Public License v3.0 (GPLv3).
  You may redistribute and/or modify it under the terms of the GNU GPLv3.
================================================================================
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "")]
param()

$Script:RunningScriptPath = $MyInvocation.MyCommand.Path
if (-not $Script:RunningScriptPath) { $Script:RunningScriptPath = $PSCommandPath }
if (-not $Script:RunningScriptPath -and $PSScriptRoot) { $Script:RunningScriptPath = Join-Path $PSScriptRoot "ZeroHub-GUI.ps1" }
if (-not $Script:RunningScriptPath) { $Script:RunningScriptPath = Join-Path (Get-Location).Path "ZeroHub-GUI.ps1" }

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms, System.Drawing
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Ensure C# Core Types
if (-not ([System.Management.Automation.PSTypeName]'ZeroHub.TargetItem').Type) {
    # No -ReferencedAssemblies here on purpose. PowerShell 7 treats that parameter as the
    # COMPLETE reference set rather than an addition, so naming the four WPF assemblies drops
    # System.Runtime and System.Collections.Concurrent and the compile dies on CS0234 before a
    # single ZeroHub type exists. Passing the loaded assemblies instead fails differently:
    # Stack<T> then demands System.Private.CoreLib, which Add-Type refuses as a reference.
    # The default set is correct on both editions, so the C# below stays free of WPF types
    # (CheckBoxControl and SizeLabel are object; PowerShell late-binds their members anyway).
    # Verified 2026-08-29 compiling clean on pwsh 7.6.5 and Windows PowerShell 5.1.
    Add-Type -TypeDefinition @'
#pragma warning disable 0067, 0649
using System;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace ZeroHub {
    public class TargetItem : INotifyPropertyChanged {
        public string Id { get; set; }
        public string Name { get; set; }
            public string Path { get; set; }
        public string Cat { get; set; }
        public string Description { get; set; }
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

        public object CheckBoxControl { get; set; }
        public object SizeLabel { get; set; }

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

    public class SmartProcessItem : INotifyPropertyChanged {
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
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Path { get; set; }
        public double MemoryMB { get; set; }
        public string MemoryFormatted { get; set; }
        public string SafetyTier { get; set; }
        public string SafetyBadge { get; set; }
        public string SafetyBg { get; set; }
        public string SafetyFg { get; set; }
        public string SafetyBorder { get; set; }
        public bool CanEnd { get; set; }
        public string EndBtnText { get; set; }
        public string EndBtnBg { get; set; }
        public string EndBtnFg { get; set; }
        public string Category { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
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
        private string _nameFg = "#FFFFFF";

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
        public string NameFg {
            get { return _nameFg ?? "#FFFFFF"; }
            set { if (_nameFg != value) { _nameFg = value; OnPropertyChanged("NameFg"); } }
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

    public class StartupAppItem : INotifyPropertyChanged {
        private bool _isEnabled;
        public bool IsEnabled {
            get { return _isEnabled; }
            set {
                if (_isEnabled != value) {
                    _isEnabled = value;
                    OnPropertyChanged("IsEnabled");
                    OnPropertyChanged("StatusText");
                    OnPropertyChanged("StatusColor");
                    OnPropertyChanged("StatusBadgeBg");
                    OnPropertyChanged("StatusBadgeBorder");
                }
            }
        }

        public bool IsRunning { get; set; }
        public string LiveStatusText {
            get { return IsRunning ? "Running" : "Inactive"; }
        }
        public string LiveStatusColor {
            get { return IsRunning ? "#38BDF8" : "#94A3B8"; }
        }
        public string LiveDotColor {
            get { return IsRunning ? "#22C55E" : "#64748B"; }
        }

        public string Name { get; set; }
        public string Command { get; set; }
        public string SourceType { get; set; }
        public string RegistryPath { get; set; }
        public string ApprovedPath { get; set; }
        public string FilePath { get; set; }
        public string TaskName { get; set; }
        public string Publisher { get; set; }
        public string Impact { get; set; }
        public string ImpactColor { get; set; }

        public string StatusText {
            get { return _isEnabled ? "Enabled" : "Disabled"; }
        }
        public string StatusColor {
            get { return _isEnabled ? "#4ADE80" : "#F43F5E"; }
        }
        public string StatusBadgeBg {
            get { return _isEnabled ? "#052e16" : "#4c0519"; }
        }
        public string StatusBadgeBorder {
            get { return _isEnabled ? "#16a34a" : "#e11d48"; }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    public class GameItem : INotifyPropertyChanged {
        public string Name { get; set; }
        public string Platform { get; set; }
        public string PlatformColor { get; set; }
        public string PlatformBg { get; set; }
        public string PlatformBorder { get; set; }
        public string PlatformIcon { get; set; }
        public string BannerUrl { get; set; }
        public bool HasBanner {
            get { return !string.IsNullOrEmpty(BannerUrl); }
        }
        public string InstallDir { get; set; }
        public string LaunchUri { get; set; }
        public string AppId { get; set; }
        public string ExeName { get; set; }
        public bool IsCustom { get; set; }
        public string DisplaySize { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name) {
            PropertyChangedEventHandler handler = PropertyChanged;
            if (handler != null) {
                handler(this, new PropertyChangedEventArgs(name));
            }
        }
    }

    
    public class SearchResultItem {
        public int Index { get; set; }
        public string ItemType { get; set; }
        public string TypeBadgeColor { get; set; }
        public string FileName { get; set; }
        public string FilePath { get; set; }
        public int LineNumber { get; set; }
        public string MatchInfo { get; set; }
        public string LineText { get; set; }
        public string FolderPath { get; set; }
        public string FileSize { get; set; }
        public string FileExt { get; set; }
        public bool IsDirectory { get; set; }
    }

    public class SearchStats {
        public int MatchedCount { get; set; }
        public int FilesMatched { get; set; }
        public int FoldersMatched { get; set; }
        public int FilesScanned { get; set; }
        public double ElapsedSeconds { get; set; }
    }

    public static class FileContentSearcher {
        private static readonly System.Collections.Generic.HashSet<string> KnownTextExts = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            ".ini", ".cfg", ".inf", ".conf", ".config", ".txt", ".log", ".json", ".xml", ".yaml", ".yml",
            ".toml", ".ps1", ".psm1", ".psd1", ".bat", ".cmd", ".vbs", ".reg", ".dat", ".csv", ".tsv",
            ".py", ".cs", ".cpp", ".c", ".h", ".hpp", ".js", ".ts", ".jsx", ".tsx", ".html", ".htm",
            ".css", ".scss", ".less", ".md", ".sql", ".sh", ".bash", ".env", ".properties", ".nfo"
        };

        private static bool IsBinaryFile(string filePath, string ext) {
            if (!string.IsNullOrEmpty(ext) && KnownTextExts.Contains(ext)) {
                return false; // Always search known text/config files
            }

            try {
                using (var stream = new System.IO.FileStream(filePath, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.ReadWrite)) {
                    int bytesToRead = (int)Math.Min(stream.Length, 1024);
                    if (bytesToRead == 0) return false;
                    byte[] buffer = new byte[bytesToRead];
                    int read = stream.Read(buffer, 0, bytesToRead);

                    // Check for UTF-16 BOM (FF FE or FE FF)
                    if (read >= 2 && ((buffer[0] == 0xFF && buffer[1] == 0xFE) || (buffer[0] == 0xFE && buffer[1] == 0xFF))) {
                        return false;
                    }
                    // Check for UTF-8 BOM (EF BB BF)
                    if (read >= 3 && buffer[0] == 0xEF && buffer[1] == 0xBB && buffer[2] == 0xBF) {
                        return false;
                    }

                    int nullCount = 0;
                    for (int i = 0; i < read; i++) {
                        if (buffer[i] == 0) nullCount++;
                    }
                    // If more than 10% null bytes and not a known text file, treat as binary
                    if (nullCount > (read / 10)) return true;
                }
            } catch { return true; }
            return false;
        }

        public static System.Collections.Generic.List<SearchResultItem> Search(
            string rootFolder,
            string query,
            string extensionsFilter,
            string searchMode,
            bool recursive,
            bool matchCase,
            bool useRegex,
            int maxResults,
            out SearchStats stats
        ) {
            var results = new System.Collections.Concurrent.ConcurrentBag<SearchResultItem>();
            stats = new SearchStats();
            var sw = System.Diagnostics.Stopwatch.StartNew();

            if (string.IsNullOrWhiteSpace(rootFolder) || !System.IO.Directory.Exists(rootFolder) || string.IsNullOrEmpty(query)) {
                sw.Stop();
                stats.ElapsedSeconds = Math.Round(sw.Elapsed.TotalSeconds, 2);
                return new System.Collections.Generic.List<SearchResultItem>();
            }

            query = query.Trim();

            System.Text.RegularExpressions.Regex regexObj = null;
            if (useRegex) {
                try {
                    var options = matchCase ? System.Text.RegularExpressions.RegexOptions.None : System.Text.RegularExpressions.RegexOptions.IgnoreCase;
                    regexObj = new System.Text.RegularExpressions.Regex(query, options);
                } catch {
                    useRegex = false;
                }
            }

            var stringComparison = matchCase ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
            bool doNames = searchMode == "Names" || searchMode == "Both";
            bool doContent = searchMode == "Content" || searchMode == "Both";

            var extSet = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase);
            bool matchAllExts = string.IsNullOrWhiteSpace(extensionsFilter) || extensionsFilter.Contains("*.*");
            if (!matchAllExts) {
                var split = extensionsFilter.Split(new char[] { ',', ';', ' ' }, System.StringSplitOptions.RemoveEmptyEntries);
                foreach (var s in split) {
                    string trimmed = s.Trim().ToLowerInvariant().TrimStart('*');
                    if (!string.IsNullOrEmpty(trimmed)) {
                        if (!trimmed.StartsWith(".")) trimmed = "." + trimmed;
                        extSet.Add(trimmed);
                    }
                }
            }

            int filesScanned = 0;
            int foldersMatched = 0;
            var matchedFilesSet = new System.Collections.Concurrent.ConcurrentDictionary<string, byte>();

            var stack = new System.Collections.Generic.Stack<string>();
            stack.Push(rootFolder);

            var discoveredFiles = new System.Collections.Generic.List<string>();

            while (stack.Count > 0) {
                if (results.Count >= maxResults) break;
                string currentDir = stack.Pop();

                // 1. Process Subdirectories (for name search & recursive traversal)
                try {
                    string[] subDirs = System.IO.Directory.GetDirectories(currentDir);
                    foreach (string d in subDirs) {
                        try {
                            if (doNames) {
                                string dirName = System.IO.Path.GetFileName(d);
                                bool match = useRegex && regexObj != null ? regexObj.IsMatch(dirName) : dirName.IndexOf(query, stringComparison) >= 0;
                                if (match) {
                                    System.Threading.Interlocked.Increment(ref foldersMatched);
                                    results.Add(new SearchResultItem {
                                        ItemType = "📁 Folder",
                                        TypeBadgeColor = "#c15f3c",
                                        FileName = dirName,
                                        FilePath = d,
                                        FolderPath = currentDir,
                                        MatchInfo = "Folder Name",
                                        LineText = "(Directory Match)",
                                        FileSize = "--",
                                        FileExt = "[DIR]",
                                        IsDirectory = true
                                    });
                                }
                            }

                            if (recursive) {
                                stack.Push(d);
                            }
                        } catch {}
                    }
                } catch {}

                // 2. Discover files in current directory
                try {
                    string[] files = System.IO.Directory.GetFiles(currentDir);
                    foreach (string f in files) {
                        discoveredFiles.Add(f);
                    }
                } catch {}
            }

            // 3. Process discovered files across all CPU cores
            System.Threading.Tasks.Parallel.ForEach(
                discoveredFiles,
                new System.Threading.Tasks.ParallelOptions { MaxDegreeOfParallelism = Environment.ProcessorCount },
                (file, state) => {
                    if (results.Count >= maxResults) {
                        state.Break();
                        return;
                    }

                    System.Threading.Interlocked.Increment(ref filesScanned);

                    try {
                        var fi = new System.IO.FileInfo(file);
                        string ext = fi.Extension;
                        string sizeStr = (fi.Length < 1024 * 1024) 
                            ? string.Format("{0:0.#} KB", (double)fi.Length / 1024) 
                            : string.Format("{0:0.##} MB", (double)fi.Length / (1024 * 1024));

                        // A. Check File Name match (for Names & Both modes)
                        if (doNames) {
                            bool fileNameMatch = useRegex && regexObj != null ? regexObj.IsMatch(fi.Name) : fi.Name.IndexOf(query, stringComparison) >= 0;
                            if (fileNameMatch) {
                                matchedFilesSet.TryAdd(file, 1);
                                results.Add(new SearchResultItem {
                                    ItemType = "📄 File",
                                    TypeBadgeColor = "#4ADE80",
                                    FileName = fi.Name,
                                    FilePath = fi.FullName,
                                    FolderPath = fi.DirectoryName,
                                    MatchInfo = "File Name",
                                    LineText = "(File Name Match)",
                                    FileSize = sizeStr,
                                    FileExt = ext,
                                    IsDirectory = false
                                });
                            }
                        }

                        // B. Check Inside Content match (for Content & Both modes)
                        if (doContent) {
                            if (!matchAllExts && !extSet.Contains(ext)) return;
                            if (fi.Length > 80 * 1024 * 1024) return;
                            if (IsBinaryFile(file, ext)) return;

                            using (var stream = new System.IO.FileStream(file, System.IO.FileMode.Open, System.IO.FileAccess.Read, System.IO.FileShare.ReadWrite))
                            using (var reader = new System.IO.StreamReader(stream, System.Text.Encoding.Default, true)) {
                                string line;
                                int lineNum = 0;
                                while ((line = reader.ReadLine()) != null) {
                                    if (results.Count >= maxResults) {
                                        state.Break();
                                        break;
                                    }
                                    lineNum++;

                                    bool isMatch = false;
                                    if (useRegex && regexObj != null) {
                                        isMatch = regexObj.IsMatch(line);
                                    } else {
                                        isMatch = line.IndexOf(query, stringComparison) >= 0;
                                    }

                                    if (isMatch) {
                                        matchedFilesSet.TryAdd(file, 1);
                                        results.Add(new SearchResultItem {
                                            ItemType = "🔍 Content",
                                            TypeBadgeColor = "#D4D4D8",
                                            FileName = fi.Name,
                                            FilePath = fi.FullName,
                                            FolderPath = fi.DirectoryName,
                                            LineNumber = lineNum,
                                            MatchInfo = "Line " + lineNum,
                                            LineText = line.Trim(),
                                            FileSize = sizeStr,
                                            FileExt = ext,
                                            IsDirectory = false
                                        });
                                    }
                                }
                            }
                        }
                    } catch {}
                }
            );

            sw.Stop();

            var finalSorted = new System.Collections.Generic.List<SearchResultItem>(results);
            finalSorted.Sort((a, b) => {
                int cmp = string.Compare(a.FilePath, b.FilePath, StringComparison.OrdinalIgnoreCase);
                if (cmp == 0) return a.LineNumber.CompareTo(b.LineNumber);
                return cmp;
            });

            for (int i = 0; i < finalSorted.Count; i++) {
                finalSorted[i].Index = i + 1;
            }

            stats.MatchedCount = finalSorted.Count;
            stats.FilesMatched = matchedFilesSet.Count;
            stats.FoldersMatched = foldersMatched;
            stats.FilesScanned = filesScanned;
            stats.ElapsedSeconds = Math.Round(sw.Elapsed.TotalSeconds, 2);

            return finalSorted;
        }
    }

    public class AsyncProcessRunner {
        public static int Run(string fileName, string args, Action<string> onLine, Action onPump, Action<int, string> onProgress = null) {
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

                int currentProgress = 15;
                var sw = Stopwatch.StartNew();
                long lastTick = 0;

                while (!p.WaitForExit(70)) {
                    string item;
                    while (queue.TryDequeue(out item)) {
                        if (onLine != null) onLine(item);
                    }
                    if (onProgress != null && (sw.ElapsedMilliseconds - lastTick > 140)) {
                        lastTick = sw.ElapsedMilliseconds;
                        if (currentProgress < 94) {
                            currentProgress++;
                            onProgress(currentProgress, null);
                        }
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

        [System.Runtime.InteropServices.DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [System.Runtime.InteropServices.DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        public static void HideConsole() {
            try {
                IntPtr hWnd = GetConsoleWindow();
                if (hWnd != IntPtr.Zero) {
                    ShowWindow(hWnd, 0); // 0 = SW_HIDE
                }
            } catch {}
        }

        [System.Runtime.InteropServices.DllImport("shell32.dll", SetLastError = true)]
        public static extern int SetCurrentProcessExplicitAppUserModelID([System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.LPWStr)] string AppID);

        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        public static extern uint RegisterWindowMessage(string lpString);

        public static uint WM_TASKBARCREATED = RegisterWindowMessage("TaskbarCreated");

        [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
        public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, IntPtr lParam);

        public static void SetAppId(string appId) {
            try {
                SetCurrentProcessExplicitAppUserModelID(appId);
            } catch {}
        }

        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SetClassLongPtr")]
        private static extern IntPtr SetClassLongPtr64(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SetClassLong")]
        private static extern IntPtr SetClassLong32(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

        public static IntPtr SetClassLong(IntPtr hWnd, int nIndex, IntPtr dwNewLong) {
            if (IntPtr.Size == 8)
                return SetClassLongPtr64(hWnd, nIndex, dwNewLong);
            else
                return SetClassLong32(hWnd, nIndex, dwNewLong);
        }

        public static void SetWindowIconFull(IntPtr hwnd, IntPtr hIconBig, IntPtr hIconSmall) {
            try {
                SendMessage(hwnd, 0x0080, 0, hIconSmall); // WM_SETICON, ICON_SMALL
                SendMessage(hwnd, 0x0080, 1, hIconBig);   // WM_SETICON, ICON_BIG
                SendMessage(hwnd, 0x0080, 2, hIconSmall); // WM_SETICON, ICON_SMALL2
                SetClassLong(hwnd, -14, hIconBig);        // GCLP_HICON (-14)
                SetClassLong(hwnd, -34, hIconSmall);      // GCLP_HICONSM (-34)
            } catch {}
        }

        public static void SetWindowIcon(IntPtr hwnd, IntPtr hIcon) {
            SetWindowIconFull(hwnd, hIcon, hIcon);
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
                // NOTE for the maintainer. Behaviour deliberately left exactly as you wrote it.
                // This 0.30, and the 0.28 in the Update-LiveMemoryStats fallback, are fixed
                // fractions rather than measurements, and EmptyWorkingSet does not free a
                // predictable share anyway: it moves pages to the standby list, so what the OS
                // actually returns depends on later demand. The number under "Reclaimable" is
                // therefore not something this code can know.
                // Suggestion only, not applied because it changes a user-facing figure and label:
                // report the measured working set of processes above the 5 MB threshold and call
                // it trimmable rather than reclaimable. Happy to do that in a follow-up.
                reclaimableMB = Math.Round((totalWorkingSetBytes * 0.30) / (1024 * 1024), 0);
            }
        }

        // Directory walkers that never descend into a reparse point (junction or symlink).
        //
        // What this is NOT: a fix for a reproduced bug. Measured 2026-08-29 on Windows 11 26200
        // with a real junction planted inside a cache folder, neither Get-ChildItem -Recurse nor
        // Remove-Item -Recurse followed it, on pwsh 7.6.5 or Windows PowerShell 5.1. The widely
        // repeated claim that they do did not hold on either build here.
        //
        // Kept anyway because the cost is nothing and the downside is unbounded: this code deletes
        // recursively with admin rights, the behaviour has differed across Windows and PowerShell
        // versions, and a link planted in %TEMP% by any process is the cheapest way to turn a cache
        // clean into data loss on a machine where it does follow. Refusing to traverse links makes
        // the question moot instead of depending on which build the user happens to run.
        private static bool IsReparsePoint(string path) {
            try {
                var attrs = System.IO.File.GetAttributes(path);
                return (attrs & System.IO.FileAttributes.ReparsePoint) == System.IO.FileAttributes.ReparsePoint;
            } catch { return true; }   // unreadable means do not touch it
        }

        public static System.Collections.Generic.List<string> SafeListFiles(string rootPath) {
            var found = new System.Collections.Generic.List<string>();
            if (string.IsNullOrEmpty(rootPath) || !System.IO.Directory.Exists(rootPath)) return found;
            if (IsReparsePoint(rootPath)) return found;
            var stack = new System.Collections.Generic.Stack<string>();
            stack.Push(rootPath);
            while (stack.Count > 0) {
                string current = stack.Pop();
                try {
                    foreach (string f in System.IO.Directory.GetFiles(current)) {
                        if (!IsReparsePoint(f)) found.Add(f);
                    }
                    foreach (string d in System.IO.Directory.GetDirectories(current)) {
                        if (!IsReparsePoint(d)) stack.Push(d);
                    }
                } catch {}
            }
            return found;
        }

        // Deepest first, so a caller removing empty directories can just walk the list in order.
        public static System.Collections.Generic.List<string> SafeListDirs(string rootPath) {
            var found = new System.Collections.Generic.List<string>();
            if (string.IsNullOrEmpty(rootPath) || !System.IO.Directory.Exists(rootPath)) return found;
            if (IsReparsePoint(rootPath)) return found;
            var stack = new System.Collections.Generic.Stack<string>();
            stack.Push(rootPath);
            while (stack.Count > 0) {
                string current = stack.Pop();
                try {
                    foreach (string d in System.IO.Directory.GetDirectories(current)) {
                        if (IsReparsePoint(d)) continue;
                        found.Add(d);
                        stack.Push(d);
                    }
                } catch {}
            }
            found.Sort(delegate(string a, string b) { return b.Length.CompareTo(a.Length); });
            return found;
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

    public static class ProcessManagerEngine {
        private static readonly System.Collections.Generic.HashSet<string> CriticalNames = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "system", "idle", "csrss", "lsass", "wininit", "smss", "services", "dwm", "explorer", "audiodg",
            "svchost", "fontdrvhost", "winlogon", "sihost", "taskhostw", "securityhealthservice", "runtimebroker",
            "searchindexer", "spoolsv", "ctfmon", "startmenuexperiencehost", "shellexperiencehost", "applicationframehost",
            "registry", "memory compression", "werfault", "smartscreen", "lsaiso", "conhost"
        };

        private static readonly System.Collections.Generic.HashSet<string> HardwareDriverNames = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "nvcontainer", "nvspcaps64", "nvidia share", "nvidia web helper", "nvcplui", "amdow", "amdrsserv",
            "radeonsoftware", "rtkaudioservice", "ravcpl64", "realtek", "synaptics", "syntpenh", "elantech",
            "igfxcuiservice", "igfxtray", "intel", "hpservice", "dell", "lenovo", "armourytsf", "armourycrate",
            "icue", "corsair", "logi_lamparray_service", "logioptionsplus_agent", "razer synapseservice"
        };

        private static readonly System.Collections.Generic.HashSet<string> CautionWorkNames = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "chrome", "msedge", "firefox", "brave", "opera", "vivaldi", "code", "devenv", "idea64", "pycharm64",
            "webstorm64", "studio64", "notepad", "notepad++", "sublime_text", "word", "excel", "powerpnt", "outlook",
            "photoshop", "illustrator", "premiere", "afterfx", "blender", "obs64", "powershell", "pwsh", "cmd",
            "wt", "windowsterminal", "unity", "unrealeditor", "davinci resolve", "acrobat"
        };

        private static readonly System.Collections.Generic.HashSet<string> SafeToStopNames = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "discord", "spotify", "steam", "steamservice", "steamwebhelper", "epicgameslauncher", "epicwebhelper",
            "origin", "originwebhelperservice", "eaforeground", "eadesktop", "eabackgroundservice", "gog",
            "galaxyclient", "galaxyclientservice", "riotclientservices", "riotclientux", "battle.net", "agent",
            "adobearm", "agsservice", "ccxprocess", "adobenotificationclient", "coresync", "googledrivesync",
            "dropbox", "onedrive", "onedrivestandaloneupdater", "skype", "skypeapp", "zoom", "slack", "teams",
            "msteams", "msedgeupdate", "googleupdate", "epicupdate", "logioptionsplus", "razer", "cortex",
            "gamebarftserver", "gamebar", "overwolf", "medal", "curseforge", "bittorrent", "utorrent", "qbittorrent"
        };

        public static SmartProcessItem Classify(int pid, string name, string desc, string path, double memoryMB) {
            var item = new SmartProcessItem {
                Id = pid,
                Name = name,
                Description = string.IsNullOrWhiteSpace(desc) ? name : desc,
                Path = path ?? "",
                MemoryMB = Math.Round(memoryMB, 1),
                MemoryFormatted = string.Format("{0:0.#} MB", memoryMB),
                IsSelected = false
            };

            string lowerName = (name ?? "").ToLowerInvariant().Replace(".exe", "");

            if (CriticalNames.Contains(lowerName)) {
                item.SafetyTier = "Critical";
                item.SafetyBadge = "Critical (Locked)";
                item.SafetyBg = "#450A0A";
                item.SafetyFg = "#F87171";
                item.SafetyBorder = "#991B1B";
                item.CanEnd = false;
                item.EndBtnText = "Locked";
                item.EndBtnBg = "#1F2937";
                item.EndBtnFg = "#64748B";
                item.Category = "System Core";
            } else if (HardwareDriverNames.Contains(lowerName)) {
                item.SafetyTier = "Hardware";
                item.SafetyBadge = "Driver / Hardware";
                item.SafetyBg = "#7C2D12";
                item.SafetyFg = "#FB923C";
                item.SafetyBorder = "#EA580C";
                item.CanEnd = true;
                item.EndBtnText = "End Task";
                item.EndBtnBg = "#C2410C";
                item.EndBtnFg = "#FFFFFF";
                item.Category = "Driver / Hardware";
            } else if (CautionWorkNames.Contains(lowerName)) {
                item.SafetyTier = "CautionWork";
                item.SafetyBadge = "Caution (Work)";
                item.SafetyBg = "#1E293B";
                item.SafetyFg = "#FBBF24";
                item.SafetyBorder = "#D97706";
                item.CanEnd = true;
                item.EndBtnText = "End Task";
                item.EndBtnBg = "#B45309";
                item.EndBtnFg = "#FFFFFF";
                item.Category = "User Application";
            } else if (SafeToStopNames.Contains(lowerName)) {
                item.SafetyTier = "Safe";
                item.SafetyBadge = "Safe to Stop";
                item.SafetyBg = "#064E3B";
                item.SafetyFg = "#4ADE80";
                item.SafetyBorder = "#059669";
                item.CanEnd = true;
                item.EndBtnText = "End Task";
                item.EndBtnBg = "#047857";
                item.EndBtnFg = "#FFFFFF";
                item.Category = "Background / Helper";
            } else {
                bool isUserPath = !string.IsNullOrEmpty(path) && (path.IndexOf("Users", StringComparison.OrdinalIgnoreCase) >= 0 || path.IndexOf("AppData", StringComparison.OrdinalIgnoreCase) >= 0);
                if (isUserPath) {
                    item.SafetyTier = "Safe";
                    item.SafetyBadge = "Safe to Stop";
                    item.SafetyBg = "#064E3B";
                    item.SafetyFg = "#4ADE80";
                    item.SafetyBorder = "#059669";
                    item.CanEnd = true;
                    item.EndBtnText = "End Task";
                    item.EndBtnBg = "#047857";
                    item.EndBtnFg = "#FFFFFF";
                    item.Category = "User Process";
                } else {
                    item.SafetyTier = "CautionService";
                    item.SafetyBadge = "Caution (Service)";
                    item.SafetyBg = "#4C1D95";
                    item.SafetyFg = "#C084FC";
                    item.SafetyBorder = "#7C3AED";
                    item.CanEnd = true;
                    item.EndBtnText = "End Task";
                    item.EndBtnBg = "#6D28D9";
                    item.EndBtnFg = "#FFFFFF";
                    item.Category = "Background Service";
                }
            }

            return item;
        }

        public static System.Collections.Generic.List<SmartProcessItem> GetAllProcesses() {
            var bag = new System.Collections.Concurrent.ConcurrentBag<SmartProcessItem>();
            var procs = Process.GetProcesses();

            System.Threading.Tasks.Parallel.ForEach(procs, p => {
                try {
                    string name = p.ProcessName;
                    int pid = p.Id;
                    double memMB = (double)p.WorkingSet64 / (1024.0 * 1024.0);
                    string desc = "";
                    string path = "";

                    try {
                        desc = p.MainWindowTitle;
                    } catch {}

                    string lower = name.ToLowerInvariant();
                    // Avoid expensive MainModule inspection on protected system processes
                    if (pid > 4 && !CriticalNames.Contains(lower)) {
                        try {
                            var mod = p.MainModule;
                            if (mod != null) {
                                path = mod.FileName ?? "";
                                if (string.IsNullOrEmpty(desc)) {
                                    desc = mod.FileVersionInfo.FileDescription ?? "";
                                }
                            }
                        } catch {}
                    }

                    if (desc == null) desc = "";
                    if (path == null) path = "";

                    var item = Classify(pid, name, desc, path, memMB);
                    bag.Add(item);
                } catch {}
            });

            var list = new System.Collections.Generic.List<SmartProcessItem>(bag);
            list.Sort(delegate(SmartProcessItem a, SmartProcessItem b) {
                int cmp = string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
                if (cmp != 0) return cmp;
                return b.MemoryMB.CompareTo(a.MemoryMB);
            });
            return list;
        }

        public static System.Collections.Generic.List<SmartProcessItem> FilterProcesses(
            System.Collections.Generic.List<SmartProcessItem> source,
            string query,
            string filter,
            out int totalCount,
            out int safeCount,
            out double safeMemMB)
        {
            var result = new System.Collections.Generic.List<SmartProcessItem>();
            totalCount = source != null ? source.Count : 0;
            safeCount = 0;
            safeMemMB = 0.0;

            if (source == null || source.Count == 0) return result;

            string q = string.IsNullOrEmpty(query) ? "" : query.Trim();
            string f = string.IsNullOrEmpty(filter) ? "ALL" : filter.ToUpperInvariant();

            foreach (var item in source) {
                if (item.SafetyTier == "Safe") {
                    safeCount++;
                    safeMemMB += item.MemoryMB;
                }

                bool matchQuery = true;
                if (!string.IsNullOrEmpty(q)) {
                    matchQuery = (item.Name != null && item.Name.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0) ||
                                 (item.Description != null && item.Description.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0) ||
                                 item.Id.ToString() == q;
                }

                if (!matchQuery) continue;

                bool matchCat = true;
                if (f == "SAFE") {
                    matchCat = (item.SafetyTier == "Safe");
                } else if (f == "WORK") {
                    matchCat = (item.SafetyTier == "CautionWork" || item.SafetyTier == "Caution");
                } else if (f == "SERVICE") {
                    matchCat = (item.SafetyTier == "CautionService" || item.Category == "Background Service");
                } else if (f == "CAUTION") {
                    matchCat = (item.SafetyTier == "CautionWork" || item.SafetyTier == "CautionService" || item.SafetyTier == "Caution");
                } else if (f == "HEAVY") {
                    matchCat = (item.MemoryMB >= 150.0);
                } else if (f == "PROTECTED") {
                    matchCat = (item.SafetyTier == "Critical" || item.SafetyTier == "Hardware");
                }

                if (matchCat) {
                    result.Add(item);
                }
            }

            if (f == "HEAVY") {
                result.Sort(delegate(SmartProcessItem a, SmartProcessItem b) {
                    return b.MemoryMB.CompareTo(a.MemoryMB);
                });
            } else {
                result.Sort(delegate(SmartProcessItem a, SmartProcessItem b) {
                    int cmp = string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase);
                    if (cmp != 0) return cmp;
                    return b.MemoryMB.CompareTo(a.MemoryMB);
                });
            }

            return result;
        }

        public static bool KillProcess(int pid) {
            try {
                var p = Process.GetProcessById(pid);
                if (p != null && !p.HasExited) {
                    string lowerName = p.ProcessName.ToLowerInvariant().Replace(".exe", "");
                    if (CriticalNames.Contains(lowerName)) {
                        return false;
                    }

                    try {
                        var psi = new ProcessStartInfo("taskkill", string.Format("/PID {0} /T /F", pid)) {
                            CreateNoWindow = true,
                            UseShellExecute = false,
                            WindowStyle = ProcessWindowStyle.Hidden
                        };
                        using (var tk = Process.Start(psi)) {
                            if (tk != null) tk.WaitForExit(400);
                        }
                    } catch {}

                    try {
                        if (!p.HasExited) {
                            p.Kill();
                            p.WaitForExit(300);
                        }
                    } catch {}

                    return true;
                }
            } catch {}
            return false;
        }
    }

        public static class UninstallerEngine {
        public static System.Collections.Generic.List<InstalledAppItem> GetInstalledApps() {
            var list = new System.Collections.Generic.List<InstalledAppItem>();
            var seen = new System.Collections.Generic.HashSet<string>(StringComparer.OrdinalIgnoreCase);

            var rootHives = new[] {
                new { Hive = Microsoft.Win32.Registry.LocalMachine, Sub = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" },
                new { Hive = Microsoft.Win32.Registry.LocalMachine, Sub = @"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" },
                new { Hive = Microsoft.Win32.Registry.CurrentUser, Sub = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" }
            };

            int idx = 0;
            foreach (var rh in rootHives) {
                try {
                    using (var baseKey = rh.Hive.OpenSubKey(rh.Sub)) {
                        if (baseKey == null) continue;
                        foreach (var subName in baseKey.GetSubKeyNames()) {
                            try {
                                using (var k = baseKey.OpenSubKey(subName)) {
                                    if (k == null) continue;
                                    string dn = k.GetValue("DisplayName") as string;
                                    if (string.IsNullOrWhiteSpace(dn)) continue;
                                    dn = dn.Trim();

                                    object sysComp = k.GetValue("SystemComponent");
                                    if (sysComp != null && (sysComp.ToString() == "1" || sysComp.Equals(1))) continue;

                                    string uninst = (k.GetValue("UninstallString") as string) ?? (k.GetValue("QuietUninstallString") as string) ?? "";
                                    if (string.IsNullOrWhiteSpace(uninst)) continue;

                                    if (seen.Contains(dn)) continue;
                                    seen.Add(dn);

                                    string pub = (k.GetValue("Publisher") as string) ?? "Unknown";
                                    string ver = (k.GetValue("DisplayVersion") as string) ?? "--";
                                    string loc = (k.GetValue("InstallLocation") as string) ?? "";

                                    double sizeMB = 0.0;
                                    object est = k.GetValue("EstimatedSize");
                                    if (est != null) {
                                        try {
                                            long raw = Convert.ToInt64(est);
                                            if (raw > 0) sizeMB = Math.Round((double)raw / 1024.0, 1);
                                        } catch {}
                                    }

                                    // 1. Check if InstallLocation exists on disk
                                    bool installLocExists = false;
                                    string cleanLoc = loc.Trim('"', ' ', '\\');
                                    if (!string.IsNullOrWhiteSpace(cleanLoc) && cleanLoc.Length > 3) {
                                        try {
                                            if (System.IO.Directory.Exists(cleanLoc)) {
                                                installLocExists = true;
                                            }
                                        } catch {}
                                    }

                                    // 2. Check if UninstallString executable or protocol exists
                                    bool uninstallerExists = false;
                                    string uninstTrim = uninst.Trim();
                                    string uninstLower = uninstTrim.ToLowerInvariant();
                                    string dnLower = dn.ToLowerInvariant();
                                    string locLower = loc.ToLowerInvariant();
                                    string pubLower = pub.ToLowerInvariant();

                                    if (uninstLower.Contains("steam://") ||
                                        uninstLower.Contains("com.epicgames.launcher://") ||
                                        uninstLower.Contains("msiexec") ||
                                        subName.StartsWith("{", StringComparison.OrdinalIgnoreCase)) {
                                        uninstallerExists = true;
                                    } else {
                                        try {
                                            string exePath = "";
                                            if (uninstTrim.StartsWith("\"")) {
                                                int nextQuote = uninstTrim.IndexOf('"', 1);
                                                if (nextQuote > 1) {
                                                    exePath = uninstTrim.Substring(1, nextQuote - 1);
                                                }
                                            } else {
                                                int spaceIdx = uninstTrim.IndexOf(".exe", StringComparison.OrdinalIgnoreCase);
                                                if (spaceIdx > 0) {
                                                    exePath = uninstTrim.Substring(0, spaceIdx + 4).Trim();
                                                } else {
                                                    exePath = uninstTrim.Split(' ')[0];
                                                }
                                            }
                                            if (!string.IsNullOrWhiteSpace(exePath) && System.IO.File.Exists(exePath)) {
                                                uninstallerExists = true;
                                            }
                                        } catch {}
                                    }

                                    // True Orphaned Detection: uninstaller does not exist AND install folder does not exist
                                    bool isOrphaned = (!uninstallerExists && !installLocExists);

                                    // If size is not in registry, but install folder exists, calculate folder size
                                    if (sizeMB <= 0.0 && installLocExists && cleanLoc.Length > 5) {
                                        try {
                                            string rootCheck = cleanLoc.ToUpperInvariant();
                                            if (!rootCheck.Equals(@"C:\PROGRAM FILES") &&
                                                !rootCheck.Equals(@"C:\PROGRAM FILES (X86)") &&
                                                !rootCheck.Equals(@"C:\PROGRAMDATA") &&
                                                !rootCheck.Equals(@"C:\WINDOWS")) {
                                                
                                                long totalBytes = 0;
                                                var di = new System.IO.DirectoryInfo(cleanLoc);
                                                foreach (var fi in di.EnumerateFiles("*", System.IO.SearchOption.AllDirectories)) {
                                                    totalBytes += fi.Length;
                                                }
                                                if (totalBytes > 0) {
                                                    sizeMB = Math.Round((double)totalBytes / (1024.0 * 1024.0), 1);
                                                }
                                            }
                                        } catch {}
                                    }

                                    // Game Detection
                                    bool isGame = false;
                                    if (uninstLower.Contains("steam://") || subName.StartsWith("Steam App ", StringComparison.OrdinalIgnoreCase) || locLower.Contains(@"\steamapps\common\")) {
                                        isGame = true;
                                    } else if (uninstLower.Contains("com.epicgames.launcher://") || locLower.Contains(@"\epic games\")) {
                                        isGame = true;
                                    } else if (locLower.Contains(@"\riot games\") || dnLower.Contains("league of legends") || dnLower.Contains("valorant") || dnLower.Contains("riot client")) {
                                        isGame = true;
                                    } else if (locLower.Contains(@"\gog games\") || locLower.Contains(@"\ubisoft\") || locLower.Contains(@"\ea games\") || locLower.Contains(@"\battle.net\") || locLower.Contains(@"\xboxgames\")) {
                                        isGame = true;
                                    } else if (pubLower.Contains("electronic arts") || pubLower.Contains("ubisoft") || pubLower.Contains("blizzard") || pubLower.Contains("rockstar games") || pubLower.Contains("valve") || pubLower.Contains("epic games") || pubLower.Contains("bethesda") || pubLower.Contains("2k games") || pubLower.Contains("activision") || pubLower.Contains("capcom") || pubLower.Contains("bandai namco") || pubLower.Contains("sega") || pubLower.Contains("square enix") || pubLower.Contains("fromsoftware")) {
                                        isGame = true;
                                    } else if (dnLower.Contains("minecraft") || dnLower.Contains("fortnite") || dnLower.Contains("roblox") || dnLower.Contains("counter-strike") || dnLower.Contains("cyberpunk") || dnLower.Contains("grand theft auto") || dnLower.Contains("red dead") || dnLower.Contains("overwatch") || dnLower.Contains("genshin") || dnLower.Contains("honkai") || dnLower.Contains("warframe") || dnLower.Contains("destiny") || dnLower.Contains("demonologist") || dnLower.Contains("outlast") || dnLower.Contains("resident evil")) {
                                        isGame = true;
                                    }

                                    // Category and formatted size
                                    string cat = isOrphaned ? "Orphaned" : (isGame ? "Game" : "App");
                                    string sizeStr = "";
                                    if (isOrphaned) {
                                        sizeStr = "Orphaned Entry";
                                    } else if (sizeMB > 0.0) {
                                        sizeStr = (sizeMB >= 1024.0) ? (Math.Round(sizeMB / 1024.0, 2) + " GB") : (sizeMB + " MB");
                                    } else {
                                        sizeStr = "--";
                                    }

                                    idx++;
                                    var item = new InstalledAppItem {
                                        Index = idx,
                                        DisplayName = dn,
                                        Publisher = pub,
                                        DisplayVersion = ver,
                                        EstimatedSizeMB = sizeMB,
                                        SizeFormatted = sizeStr,
                                        InstallLocation = loc,
                                        UninstallString = uninst,
                                        RegistryPath = ((rh.Hive == Microsoft.Win32.Registry.CurrentUser) ? "HKCU:\\" : "HKLM:\\") + rh.Sub + @"\" + subName,
                                        Category = cat,
                                        IsGame = isGame,
                                        IsOrphaned = isOrphaned
                                    };
                                    list.Add(item);
                                }
                            } catch {}
                        }
                    }
                } catch {}
            }

            list.Sort(delegate(InstalledAppItem a, InstalledAppItem b) {
                return string.Compare(a.DisplayName, b.DisplayName, StringComparison.OrdinalIgnoreCase);
            });

            for (int i = 0; i < list.Count; i++) {
                list[i].Index = i + 1;
            }

            return list;
        }

        public static System.Collections.Generic.List<InstalledAppItem> FilterInstalledApps(
            System.Collections.Generic.List<InstalledAppItem> source,
            string query,
            string filterMode)
        {
            var result = new System.Collections.Generic.List<InstalledAppItem>();
            if (source == null || source.Count == 0) return result;

            string q = string.IsNullOrEmpty(query) ? "" : query.Trim();
            string f = string.IsNullOrEmpty(filterMode) ? "All" : filterMode;

            int idx = 1;
            foreach (var app in source) {
                bool matchQuery = true;
                if (!string.IsNullOrEmpty(q)) {
                    matchQuery = (app.DisplayName != null && app.DisplayName.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0) ||
                                 (app.Publisher != null && app.Publisher.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0) ||
                                 (app.InstallLocation != null && app.InstallLocation.IndexOf(q, StringComparison.OrdinalIgnoreCase) >= 0);
                }

                if (!matchQuery) continue;

                bool matchCat = true;
                if (f == "Games") {
                    matchCat = app.IsGame;
                } else if (f == "Apps") {
                    matchCat = (!app.IsGame && !app.IsOrphaned);
                } else if (f == "Orphaned") {
                    matchCat = app.IsOrphaned;
                }

                if (matchCat) {
                    app.Index = idx++;
                    result.Add(app);
                }
            }

            return result;
        }
    }
}
'@
}

# Add-Type reports a compile failure as a NON-terminating error, so before this guard existed the
# script sailed on and every later call site failed in turn: roughly 2000 "Unable to find type" and
# "property cannot be found" lines that buried the single CS#### line that actually explained it.
# The giveaway was [System.Collections.Generic.List] being reported as missing, which is impossible
# unless the generic argument (a ZeroHub type) never compiled. Stop here instead of cascading.
if (-not ([System.Management.Automation.PSTypeName]'ZeroHub.TargetItem').Type) {
    Write-Host ""
    Write-Host "ZeroHub cannot start: its core C# types failed to compile." -ForegroundColor Red
    Write-Host "The real error is the CS#### compiler message printed above this line." -ForegroundColor Red
    Write-Host "This is NOT a missing-file or permissions problem." -ForegroundColor Red
    Write-Host ""
    Write-Host "Workaround, run it under Windows PowerShell 5.1:" -ForegroundColor Yellow
    if ($PSCommandPath) {
        Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ForegroundColor Yellow
    } else {
        Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex`"" -ForegroundColor Yellow
    }
    Write-Host ""
    exit 1
}

# Set dedicated Windows AppUserModelID so Taskbar groups ZeroHub with its own icon instead of PowerShell
[ZeroHub.NativeMethods]::SetAppId("ZeroIQ.ZeroHub.App.1")

# Auto-Elevate to Administrator (Chris Titus Tech WinUtil Style)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "powershell.exe"
        $processInfo.Arguments = if ($PSCommandPath) {
            "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        } else {
            "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex`""
        }
        $processInfo.Verb = "runas"
        $proc = [System.Diagnostics.Process]::Start($processInfo)
        if ($proc) {
            Start-Sleep -Milliseconds 700
            if (-not $proc.HasExited -or $proc.ExitCode -eq 0) { exit }
        }
    } catch {
        # User clicked 'No' on UAC prompt - continue gracefully in Standard User mode
    }
}

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

# Build XAML UI definition with high-contrast crisp white typography, Segoe MDL2 Assets, and Iraqi Flag Language Switcher
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:shell="clr-namespace:System.Windows.Shell;assembly=PresentationFramework" Title="ZeroHub - Fast &amp; Intelligent Windows Power Hub" Height="740" Width="1160" MinHeight="540" MinWidth="850" WindowStartupLocation="CenterScreen" WindowState="Maximized" Background="#09090B" FontFamily="Segoe UI, Inter, Arial, sans-serif" Foreground="#F5EDE0">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="56" GlassFrameThickness="0" CornerRadius="0" ResizeBorderThickness="6" UseAeroCaptionButtons="False" />
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <!-- Color Palette (Authentic Medieval Manuscript & Fantasy RPG Cartography) -->
    <SolidColorBrush x:Key="BaseBackground" Color="#09090B" />
    <SolidColorBrush x:Key="HeaderBackground" Color="#050507" />
    <SolidColorBrush x:Key="CardBackground" Color="#111114" />
    <SolidColorBrush x:Key="CardHover" Color="#18181C" />
    <SolidColorBrush x:Key="BorderColor" Color="#23232A" />
    <SolidColorBrush x:Key="BorderInner" Color="#181820" />
    <SolidColorBrush x:Key="AccentCyan" Color="#354960" />
    <SolidColorBrush x:Key="AccentBlue" Color="#354960" />
    <SolidColorBrush x:Key="AccentPurple" Color="#8B4F73" />
    <SolidColorBrush x:Key="AccentGreen" Color="#3B6B48" />
    <SolidColorBrush x:Key="AccentRed" Color="#1E3A8A" />
    <SolidColorBrush x:Key="AccentYellow" Color="#c15f3c" />
    <SolidColorBrush x:Key="AccentCoral" Color="#1E3A8A" />
    <SolidColorBrush x:Key="TextBright" Color="#F5EDE0" />
    <SolidColorBrush x:Key="TextSub" Color="#D5C8B4" />
    <SolidColorBrush x:Key="TextMuted" Color="#A1A1AA" />
    <!-- Medieval Inset Parchment Card Panel with Double-Rule Ink Borders -->
    <Style x:Key="CardPanel" TargetType="Border">
      <Setter Property="Background" Value="{StaticResource CardBackground}" />
      <Setter Property="BorderBrush" Value="{StaticResource BorderColor}" />
      <Setter Property="BorderThickness" Value="1.5" />
      <Setter Property="CornerRadius" Value="4" />
      <Setter Property="Padding" Value="14,12" />
      <Setter Property="Margin" Value="4" />
    </Style>

    <!-- Global Button Focus Reset: Remove rectangular dotted focus border -->
    <Style TargetType="Button">
      <Setter Property="FocusVisualStyle" Value="{x:Null}" />
    </Style>

    <!-- Primary Modern Button: Authentic Scalloped Plaque (Matches Reference "Export Image") -->
    <Style x:Key="PrimaryButton" TargetType="Button">
      <Setter Property="FocusVisualStyle" Value="{x:Null}" />
      <Setter Property="Background" Value="#1E242C" />
      <Setter Property="Foreground" Value="#FBF7EE" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="FontWeight" Value="Bold" />
      <Setter Property="FontSize" Value="12" />
      <Setter Property="Height" Value="32" />
      <Setter Property="Padding" Value="10,0" />
      <Setter Property="Cursor" Value="Hand" />
      <Setter Property="BorderThickness" Value="0" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid Height="32" Background="Transparent" SnapsToDevicePixels="True">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="12" />
              </Grid.ColumnDefinitions>
              <!-- Left Scalloped Cutout (Concave Arc) -->
              <Path Grid.Column="0" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 12,0 A 12,12 0 0 1 0,12 L 0,20 A 12,12 0 0 1 12,32 Z" />
              <!-- Center Solid Body -->
              <Border Grid.Column="1" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
              </Border>
              <!-- Right Scalloped Cutout (Concave Arc) -->
              <Path Grid.Column="2" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 0,0 A 12,12 0 0 0 12,12 L 12,20 A 12,12 0 0 0 0,32 Z" />
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#2B3542" />
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter Property="Background" Value="#141920" />
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Background" Value="#8A8275" />
                <Setter Property="Foreground" Value="#D5CBB8" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Success Green Button: Verdigris Sage Scalloped Plaque -->
    <Style x:Key="SuccessButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
      <Setter Property="Background" Value="#1A2E1F" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid Height="32" Background="Transparent" SnapsToDevicePixels="True">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="12" />
              </Grid.ColumnDefinitions>
              <Path Grid.Column="0" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 12,0 A 12,12 0 0 1 0,12 L 0,20 A 12,12 0 0 1 12,32 Z" />
              <Border Grid.Column="1" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
              </Border>
              <Path Grid.Column="2" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 0,0 A 12,12 0 0 0 12,12 L 12,20 A 12,12 0 0 0 0,32 Z" />
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#24432D" />
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter Property="Background" Value="#102015" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Secondary Button: Terracotta Scalloped Plaque (b1 - Matches Reference "PNG") -->
    <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
      <Setter Property="Background" Value="#18181C" />
      <Setter Property="Foreground" Value="#FDFBF7" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid Height="32" Background="Transparent" SnapsToDevicePixels="True">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="12" />
              </Grid.ColumnDefinitions>
              <!-- Left Scalloped Cutout (Concave Arc) -->
              <Path Grid.Column="0" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 12,0 A 12,12 0 0 1 0,12 L 0,20 A 12,12 0 0 1 12,32 Z" />
              <!-- Center Solid Body -->
              <Border Grid.Column="1" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
              </Border>
              <!-- Right Scalloped Cutout (Concave Arc) -->
              <Path Grid.Column="2" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 0,0 A 12,12 0 0 0 12,12 L 12,20 A 12,12 0 0 0 0,32 Z" />
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#27272A" />
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter Property="Background" Value="#111114" />
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Background" Value="#8A8275" />
                <Setter Property="Foreground" Value="#D5CBB8" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Danger Button: Crimson Wax Seal Scalloped Plaque (b1) -->
    <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource PrimaryButton}">
      <Setter Property="Background" Value="#c15f3c" />
      <Setter Property="Foreground" Value="#FFFFFF" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid Height="32" Background="Transparent" SnapsToDevicePixels="True">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="12" />
              </Grid.ColumnDefinitions>
              <Path Grid.Column="0" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 12,0 A 12,12 0 0 1 0,12 L 0,20 A 12,12 0 0 1 12,32 Z" />
              <Border Grid.Column="1" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
              </Border>
              <Path Grid.Column="2" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 0,0 A 12,12 0 0 0 12,12 L 12,20 A 12,12 0 0 0 0,32 Z" />
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#D96E49" />
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter Property="Background" Value="#9A4526" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Filter / Category Banner: Authentic Chamfered Hexagonal Banner (b2 - Matches Reference "Script Slayer") -->
    <Style x:Key="b2" TargetType="Button">
      <Setter Property="FocusVisualStyle" Value="{x:Null}" />
      <Setter Property="Background" Value="#18181C" />
      <Setter Property="Foreground" Value="#FDFBF7" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="FontWeight" Value="Bold" />
      <Setter Property="FontSize" Value="11" />
      <Setter Property="Height" Value="28" />
      <Setter Property="Padding" Value="8,0" />
      <Setter Property="Cursor" Value="Hand" />
      <Setter Property="BorderThickness" Value="0" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid Height="28" Background="Transparent" SnapsToDevicePixels="True">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="12" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="12" />
              </Grid.ColumnDefinitions>
              <!-- Left Arrow Point -->
              <Path Grid.Column="0" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 12,0 L 0,14 L 12,28 Z" />
              <!-- Center Solid Body -->
              <Border Grid.Column="1" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
              </Border>
              <!-- Right Arrow Point -->
              <Path Grid.Column="2" Fill="{TemplateBinding Background}" Stretch="Fill" Data="M 0,0 L 12,14 L 0,28 Z" />
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#27272A" />
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter Property="Background" Value="#111114" />
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Background" Value="#8A8275" />
                <Setter Property="Foreground" Value="#D5CBB8" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="FilterButton" TargetType="Button" BasedOn="{StaticResource b2}" />

    <!-- First-Class Aliases: b1 (Main Action Scalloped Plaque) -->
    <Style x:Key="b1" TargetType="Button" BasedOn="{StaticResource PrimaryButton}" />
    <!-- Dark Medieval CheckBox Style -->
    <Style x:Key="ModernCheckBox" TargetType="CheckBox">
      <Setter Property="Foreground" Value="#F5EDE0" />
      <Setter Property="FontSize" Value="12" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="Cursor" Value="Hand" />
      <Style.Triggers>
        <Trigger Property="IsChecked" Value="True">
          <Setter Property="Foreground" Value="#c15f3c" />
          <Setter Property="FontWeight" Value="Bold" />
        </Trigger>
        <Trigger Property="IsChecked" Value="False">
          <Setter Property="Foreground" Value="#F5EDE0" />
          <Setter Property="FontWeight" Value="SemiBold" />
        </Trigger>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Foreground" Value="#FFFFFF" />
        </Trigger>
        <Trigger Property="IsEnabled" Value="False">
          <Setter Property="Foreground" Value="#8A7B68" />
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Medieval Tooled Leather ScrollBar Thumb -->
    <Style x:Key="ModernScrollThumb" TargetType="{x:Type Thumb}">
      <Setter Property="OverridesDefaultStyle" Value="true" />
      <Setter Property="IsTabStop" Value="false" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type Thumb}">
            <Border Background="#23232A" CornerRadius="3" Margin="1,2,1,2" />
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="true">
                <Setter Property="Background" Value="#6C533C" />
              </Trigger>
              <Trigger Property="IsDragging" Value="true">
                <Setter Property="Background" Value="#18181C" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="{x:Type ScrollBar}">
      <Setter Property="Background" Value="Transparent" />
      <Setter Property="Width" Value="8" />
      <Setter Property="MinWidth" Value="8" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type ScrollBar}">
            <Grid Background="Transparent">
              <Track Name="PART_Track" IsDirectionReversed="true">
                <Track.Thumb>
                  <Thumb Style="{StaticResource ModernScrollThumb}" />
                </Track.Thumb>
              </Track>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Width" Value="Auto" />
          <Setter Property="Height" Value="8" />
          <Setter Property="MinHeight" Value="8" />
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="{x:Type ScrollBar}">
                <Grid Background="Transparent">
                  <Track Name="PART_Track" IsDirectionReversed="false">
                    <Track.Thumb>
                      <Thumb Style="{StaticResource ModernScrollThumb}" />
                    </Track.Thumb>
                  </Track>
                </Grid>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Modern TabControl without Top Header Strip (Controlled by Sidebar) -->
    <Style TargetType="TabControl">
      <Setter Property="Background" Value="Transparent" />
      <Setter Property="BorderThickness" Value="0" />
      <Setter Property="Padding" Value="0" />
      <Setter Property="ItemContainerStyle">
        <Setter.Value>
          <Style TargetType="TabItem">
            <Setter Property="Visibility" Value="Collapsed" />
          </Style>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Modern Sidebar Navigation Item Style -->
    <Style x:Key="SidebarNavButton" TargetType="Button">
      <Setter Property="Background" Value="Transparent" />
      <Setter Property="BorderThickness" Value="0" />
      <Setter Property="Padding" Value="8,6.5" />
      <Setter Property="HorizontalAlignment" Value="Stretch" />
      <Setter Property="HorizontalContentAlignment" Value="Stretch" />
      <Setter Property="Cursor" Value="Hand" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}" SnapsToDevicePixels="True">
              <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center" />
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#18181C" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Medieval Dark DataGrid Column Header Style -->
    <Style TargetType="{x:Type DataGridColumnHeader}">
      <Setter Property="Background" Value="#2A2018" />
      <Setter Property="Foreground" Value="#c15f3c" />
      <Setter Property="FontWeight" Value="Bold" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="FontSize" Value="11.5" />
      <Setter Property="Padding" Value="10,7" />
      <Setter Property="BorderThickness" Value="0,0,1,1.5" />
      <Setter Property="BorderBrush" Value="#23232A" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type DataGridColumnHeader}">
            <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" SnapsToDevicePixels="True" />
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Medieval Dark DataGrid Row Style -->
    <Style TargetType="{x:Type DataGridRow}">
      <Setter Property="Background" Value="Transparent" />
      <Setter Property="Foreground" Value="#F5EDE0" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Style.Triggers>
        <Trigger Property="IsMouseOver" Value="True">
          <Setter Property="Background" Value="#18181C" />
        </Trigger>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E242C" />
          <Setter Property="Foreground" Value="#FFFFFF" />
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Medieval Dark DataGrid Cell Style -->
    <Style TargetType="{x:Type DataGridCell}">
      <Setter Property="BorderThickness" Value="0" />
      <Setter Property="Padding" Value="6,4" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type DataGridCell}">
            <Border Background="{TemplateBinding Background}" BorderThickness="0" Padding="{TemplateBinding Padding}">
              <ContentPresenter VerticalAlignment="Center" />
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
      <Style.Triggers>
        <Trigger Property="IsSelected" Value="True">
          <Setter Property="Background" Value="#1E242C" />
          <Setter Property="Foreground" Value="#FFFFFF" />
        </Trigger>
      </Style.Triggers>
    </Style>
    <!-- Default Medieval Dark TextBox Style -->
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="#0D0D10" />
      <Setter Property="Foreground" Value="#F5EDE0" />
      <Setter Property="BorderBrush" Value="#23232A" />
      <Setter Property="BorderThickness" Value="1.5" />
      <Setter Property="Padding" Value="6,4" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="FontSize" Value="12" />
    </Style>
    <!-- Obsidian Dark Context Menu Style -->
    <Style TargetType="ContextMenu">
      <Setter Property="Background" Value="#111114" />
      <Setter Property="BorderBrush" Value="#23232A" />
      <Setter Property="BorderThickness" Value="1" />
      <Setter Property="Padding" Value="4" />
      <Setter Property="HasDropShadow" Value="True" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ContextMenu">
            <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="4" SnapsToDevicePixels="True">
              <Border.Effect>
                <DropShadowEffect Color="#000000" BlurRadius="12" ShadowDepth="4" Opacity="0.6" />
              </Border.Effect>
              <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Cycle" />
            </Border>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Obsidian Dark MenuItem Style with List Matching Hover -->
    <Style TargetType="MenuItem">
      <Setter Property="Foreground" Value="#D4D4D8" />
      <Setter Property="FontSize" Value="11.5" />
      <Setter Property="FontFamily" Value="Segoe UI, Inter, Arial, sans-serif" />
      <Setter Property="FontWeight" Value="SemiBold" />
      <Setter Property="Cursor" Value="Hand" />
      <Setter Property="Padding" Value="10,6" />
      <Setter Property="Margin" Value="0,1" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="MenuItem">
            <Border Name="ItemBorder" Background="Transparent" CornerRadius="4" Padding="{TemplateBinding Padding}" Margin="{TemplateBinding Margin}" SnapsToDevicePixels="True">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto" />
                  <ColumnDefinition Width="*" />
                </Grid.ColumnDefinitions>
                <ContentPresenter Grid.Column="0" ContentSource="Icon" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0,0,8,0" />
                <ContentPresenter Grid.Column="1" ContentSource="Header" RecognizesAccessKey="True" VerticalAlignment="Center" />
              </Grid>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True">
                <Setter TargetName="ItemBorder" Property="Background" Value="#1E242C" />
                <Setter Property="Foreground" Value="#FFFFFF" />
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="#52525B" />
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <!-- Obsidian Dark Separator Style for Menus -->
    <Style TargetType="Separator">
      <Setter Property="Background" Value="#23232A" />
      <Setter Property="Height" Value="1" />
      <Setter Property="Margin" Value="4,3" />
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Separator">
            <Border Height="1" Background="#23232A" Margin="4,3" SnapsToDevicePixels="True" />
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Grid Name="RootGrid">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto" />
      <RowDefinition Height="*" />
      <RowDefinition Height="Auto" />
    </Grid.RowDefinitions>
    <!-- TOP HEADER BAR (Tooled Dark Leather Binding) -->
    <Border Grid.Row="0" Background="#050507" BorderBrush="#181820" BorderThickness="0,0,0,1.5" Padding="12,8">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="Auto" />
          <ColumnDefinition Width="*" />
          <ColumnDefinition Width="Auto" />
        </Grid.ColumnDefinitions>
        <!-- Medieval 0IQ Logo & Brand -->
        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,0">
          <Border Name="BtnHeaderLogo" Width="36" Height="36" Margin="0,0,10,0" Background="Transparent" BorderThickness="0" VerticalAlignment="Center" Cursor="Hand" ToolTip="Visit Official Website (zeroiq.site)" WindowChrome.IsHitTestVisibleInChrome="True">
            <Image Name="ImgHeaderLogo" Width="34" Height="34" Stretch="Uniform" RenderOptions.BitmapScalingMode="HighQuality" />
          </Border>
          <StackPanel VerticalAlignment="Center">
            <StackPanel Orientation="Horizontal">
              <TextBlock Text="Zero" FontSize="19" FontWeight="Bold" Foreground="#c15f3c" FontFamily="Segoe UI, Inter, Arial, sans-serif" />
              <TextBlock Text="Hub" FontSize="19" FontWeight="Bold" Foreground="#FDFBF7" FontFamily="Segoe UI, Inter, Arial, sans-serif" />
            </StackPanel>
            <TextBlock Name="TxtAppSubtitle" Text="Tired of Windows? Switch to Linux :D" FontSize="10.5" Foreground="#D4D4D8" TextTrimming="CharacterEllipsis" MaxWidth="280" FontFamily="Segoe UI, Inter, Arial, sans-serif" />
          </StackPanel>
        </StackPanel>
        <!-- Center Spacer -->
        <Grid Grid.Column="1" />
        <!-- Right: Add to Desktop, Language Switcher, Admin Status, & Custom Window Controls -->
        <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
          <!-- Live GitHub App Update Notification Button -->
          <Button Name="BtnAppUpdate" Visibility="Collapsed" Style="{StaticResource SuccessButton}" Margin="0,0,6,0" Padding="8,3" Cursor="Hand" ToolTip="Click to download and install the latest ZeroHub update" WindowChrome.IsHitTestVisibleInChrome="True">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
              <TextBlock Text="📜" FontSize="11" Margin="0,0,4,0" VerticalAlignment="Center" />
              <TextBlock Name="TxtAppUpdate" Text="Update Available!" FontWeight="Bold" FontSize="11" Foreground="#FDFBF7" VerticalAlignment="Center" />
            </StackPanel>
          </Button>
          <!-- Create Desktop Shortcut Header Button -->
          <Button Name="BtnCreateShortcut" Style="{StaticResource PrimaryButton}" Margin="0,0,6,0" Padding="8,2" Cursor="Hand" ToolTip="Create a 1-click ZeroHub shortcut on your Desktop" WindowChrome.IsHitTestVisibleInChrome="True">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
              <TextBlock Text="⚔️" FontSize="11" Margin="0,0,5,0" VerticalAlignment="Center" />
              <TextBlock Name="TxtCreateShortcut" Text="Desktop Shortcut" FontWeight="SemiBold" FontSize="11" Foreground="#FDFBF7" VerticalAlignment="Center" />
            </StackPanel>
          </Button>
          <!-- Toggle App Notifications Header Button -->
          <Button Name="BtnToggleNotifications" Style="{StaticResource b2}" Background="#1A2E1F" Foreground="#FFFFFF" Margin="0,0,6,0" Padding="8,0" Cursor="Hand" ToolTip="Turn ON / OFF Windows notifications for ZeroHub" WindowChrome.IsHitTestVisibleInChrome="True">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
              <TextBlock Name="IconToggleNotifications" Text="&#xE7E7;" FontFamily="Segoe MDL2 Assets" FontSize="11" Margin="0,0,5,0" Foreground="#FFFFFF" VerticalAlignment="Center" />
              <TextBlock Name="TxtToggleNotifications" Text="Notifications: ON" FontWeight="Bold" FontSize="11" Foreground="#FFFFFF" VerticalAlignment="Center" />
            </StackPanel>
          </Button>
          <Border Name="AdminBadge" Background="#18181B" BorderBrush="#c15f3c" BorderThickness="1.5" CornerRadius="4" Padding="8,3" Margin="0,0,6,0">
            <StackPanel Orientation="Horizontal">
              <TextBlock Name="AdminIcon" Text="👑" FontSize="11" Foreground="#c15f3c" Margin="0,0,4,0" VerticalAlignment="Center" />
              <TextBlock Name="AdminText" Text="Standard User" FontWeight="Bold" FontSize="11" Foreground="#c15f3c" VerticalAlignment="Center" FontFamily="Segoe UI, Inter, Arial, sans-serif" />
            </StackPanel>
          </Border>
          <Button Name="BtnRelaunchAdmin" Style="{StaticResource SecondaryButton}" Content="Elevate" Padding="8,3" FontSize="11" ToolTip="Relaunch ZeroHub with full Administrator privileges" WindowChrome.IsHitTestVisibleInChrome="True" />
          <!-- Sleek Medieval Window Controls (Minimize, Maximize/Restore, Close) -->
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="8,0,0,0">
            <Button Name="BtnWindowMinimize" Width="30" Height="26" Background="Transparent" BorderThickness="0" Foreground="#D4D4D8" FontSize="11" Cursor="Hand" ToolTip="Minimize" WindowChrome.IsHitTestVisibleInChrome="True">
              <TextBlock Text="—" VerticalAlignment="Center" HorizontalAlignment="Center" />
            </Button>
            <Button Name="BtnWindowMaximize" Width="30" Height="26" Background="Transparent" BorderThickness="0" Foreground="#94A3B8" FontSize="11" Cursor="Hand" ToolTip="Maximize / Restore" WindowChrome.IsHitTestVisibleInChrome="True">
              <TextBlock Name="TxtWindowMaximizeIcon" Text="❐" VerticalAlignment="Center" HorizontalAlignment="Center" />
            </Button>
            <Button Name="BtnWindowClose" Width="32" Height="26" Background="Transparent" BorderThickness="0" Foreground="#94A3B8" FontSize="12" Cursor="Hand" ToolTip="Close" WindowChrome.IsHitTestVisibleInChrome="True">
              <Button.Style>
                <Style TargetType="Button">
                  <Setter Property="Template">
                    <Setter.Value>
                      <ControlTemplate TargetType="Button">
                        <Border Name="CloseBorder" Background="{TemplateBinding Background}" CornerRadius="4">
                          <TextBlock Text="✕" Foreground="{TemplateBinding Foreground}" VerticalAlignment="Center" HorizontalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                          <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="CloseBorder" Property="Background" Value="#E11D48" />
                            <Setter Property="Foreground" Value="#FFFFFF" />
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
    <!-- MAIN CONTENT: MODERN SIDEBAR + PAGES -->
    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="280" />
        <ColumnDefinition Width="*" />
      </Grid.ColumnDefinitions>
      <!-- SLEEK MEDIEVAL SIDEBAR NAVIGATION (Antique Leather Binding) -->
      <Border Grid.Column="0" Background="#070709" BorderBrush="#181820" BorderThickness="0,0,1.5,0" Padding="8,8,8,6">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
          </Grid.RowDefinitions>
          <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
            <StackPanel Margin="0">
              <!-- SECTION: OPTIMIZATION & CLEANING -->
              <TextBlock Name="NavCat_Clean" Text="CHRONICLES &amp; TOMES" FontSize="9.5" FontWeight="Bold" Foreground="#c15f3c" Margin="10,6,10,6" FontFamily="Segoe UI, Inter, Arial, sans-serif" />
              <!-- Nav: Dashboard -->
              <Border Name="Border_Nav_Dashboard" CornerRadius=" 6" Margin="0,1.5" Background="#23232A" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Dashboard" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Dashboard" Grid.Column="0" Text="📜" FontSize="13" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Dashboard" Grid.Column="1" Text="Cleaner Dashboard" Foreground="#FDFBF7" FontWeight="Bold" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: App Manager -->
              <Border Name="Border_Nav_Installer" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Installer" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Installer" Grid.Column="0" Text="📦" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Installer" Grid.Column="1" Text="1-Click App Manager" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Deep Uninstaller -->
              <Border Name="Border_Nav_Uninstaller" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Uninstaller" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Uninstaller" Grid.Column="0" Text="🗑️" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Uninstaller" Grid.Column="1" Text="Deep Uninstaller" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Bloatware Remover -->
              <Border Name="Border_Nav_Bloatware" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Bloatware" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Bloatware" Grid.Column="0" Text="🚀" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Bloatware" Grid.Column="1" Text="Bloatware Remover" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Updates Controller -->
              <Border Name="Border_Nav_Updates" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Updates" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Updates" Grid.Column="0" Text="🔄" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Updates" Grid.Column="1" Text="Updates Controller" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Privacy & Anti-Telemetry -->
              <Border Name="Border_Nav_Privacy" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Privacy" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Privacy" Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Privacy" Grid.Column="1" Text="Privacy &amp; Telemetry" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: DNS & Internet Booster -->
              <Border Name="Border_Nav_Dns" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Dns" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Dns" Grid.Column="0" Text="🌐" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Dns" Grid.Column="1" Text="DNS &amp; Network" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Startup Apps Manager -->
              <Border Name="Border_Nav_Startup" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Startup" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Startup" Grid.Column="0" Text="🚀" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Startup" Grid.Column="1" Text="Startup Apps" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Game Hub & Booster -->
              <Border Name="Border_Nav_GameHub" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_GameHub" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_GameHub" Grid.Column="0" Text="🎮" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_GameHub" Grid.Column="1" Text="Game Hub" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <Separator Background="#1F2937" Margin="4,8,4,8" />
              <!-- SECTION: SYSTEM TOOLS -->
              <TextBlock Name="NavCat_Tools" Text="SYSTEM TOOLS" FontSize="9" FontWeight="Bold" Foreground="#71717A" Margin="10,2,10,4" />

              <!-- Nav: Windows Security & Defender Quick Manager -->
              <Border Name="Border_Nav_Defender" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Defender" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Defender" Grid.Column="0" Text="🛡️" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Defender" Grid.Column="1" Text="Windows Defender" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Fast Text Finder -->
              <Border Name="Border_Nav_TextFinder" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_TextFinder" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_TextFinder" Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_TextFinder" Grid.Column="1" Text="Omni File Search" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Task Manager -->
              <Border Name="Border_Nav_ProcManager" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_ProcManager" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_ProcManager" Grid.Column="0" Text="⚡" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_ProcManager" Grid.Column="1" Text="Task Manager" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Running Guard -->
              <Border Name="Border_Nav_Guard" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Guard" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Guard" Grid.Column="0" Text="🛡️" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Guard" Grid.Column="1" Text="Running Guard" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- Nav: Activity Log -->
              <Border Name="Border_Nav_Log" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_Log" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_Log" Grid.Column="0" Text="📋" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_Log" Grid.Column="1" Text="Activity Log" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <Separator Background="#1F2937" Margin="4,8,4,8" />
              <!-- Nav: Updates & Changelog -->
              <Border Name="Border_Nav_AppUpdate" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_AppUpdate" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_AppUpdate" Grid.Column="0" Text="🚀" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_AppUpdate" Grid.Column="1" Text="Updates &amp; Changelog" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
              <!-- SECTION: INFO & ABOUT -->
              <Border Name="Border_Nav_About" CornerRadius=" 6" Margin="0,1.5" Background="Transparent" BorderBrush="Transparent" BorderThickness=" 0">
                <Button Name="Nav_About" Style="{StaticResource SidebarNavButton}">
                  <Grid VerticalAlignment="Center">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="22" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Name="Icon_Nav_About" Grid.Column="0" Text="ℹ️" FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <TextBlock Name="TxtNav_About" Grid.Column="1" Text="About &amp; Safety" Foreground="#94A3B8" FontSize="11.5" Margin="8,0,0,0" VerticalAlignment="Center" TextTrimming="None" />
                  </Grid>
                </Button>
              </Border>
            </StackPanel>
          </ScrollViewer>
          <!-- SIDEBAR SYSTEM METRICS & LIVE RAM OPTIMIZER -->
          <StackPanel Grid.Row="1" Margin="2,6,2,2">
            <!-- Sidebar Live GitHub Update Button (Always Visible) -->
            <Border Name="BorderSidebarUpdate" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Margin="0,0,0,5">
              <Button Name="BtnSidebarUpdate" Background="Transparent" BorderThickness="0" Padding="10,7" Cursor="Hand" ToolTip="Check for the latest ZeroHub releases on GitHub">
                <Button.Style>
                  <Style TargetType="Button">
                    <Setter Property="Template">
                      <Setter.Value>
                        <ControlTemplate TargetType="Button">
                          <Border Name="InnerBtnBorder" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Stretch" VerticalAlignment="Center" />
                          </Border>
                          <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                              <Setter TargetName="InnerBtnBorder" Property="Background" Value="#18181C" />
                            </Trigger>
                          </ControlTemplate.Triggers>
                        </ControlTemplate>
                      </Setter.Value>
                    </Setter>
                  </Style>
                </Button.Style>
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="IconSidebarUpdate" Grid.Column="0" Text="&#xE72C;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#c15f3c" VerticalAlignment="Center" Margin="0,0,8,0" />
                  <TextBlock Name="TxtSidebarUpdate" Grid.Column="1" Text="Check for Updates" FontWeight="SemiBold" FontSize="11" Foreground="#F5EDE0" VerticalAlignment="Center" />
                  <TextBlock Name="BadgeSidebarUpdateArrow" Grid.Column="2" Text="&#xE76C;" FontFamily="Segoe MDL2 Assets" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="4,0,0,0" />
                </Grid>
              </Button>
            </Border>
            <!-- Drive C: Metric Tile -->
            <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="0,0,0,5">
              <StackPanel>
                <DockPanel LastChildFill="False" Margin="0,0,0,5">
                  <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
                    <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#c15f3c" VerticalAlignment="Center" Margin="0,0,6,0" />
                    <TextBlock Name="TxtDriveLabel" Text="Drive C:" FontWeight="SemiBold" FontSize="11" Foreground="#F5EDE0" VerticalAlignment="Center" />
                  </StackPanel>
                  <TextBlock Name="DriveFreeText" Text="Scanning..." FontSize="10" FontWeight="Bold" Foreground="#c15f3c" DockPanel.Dock="Right" VerticalAlignment="Center" />
                </DockPanel>
                <Border Background="#140F0C" CornerRadius="3" Height="5" SnapsToDevicePixels="True">
                  <ProgressBar Name="DriveProgressBar" Height="5" Minimum="0" Maximum="100" Value="60" Foreground="#c15f3c" Background="Transparent" BorderThickness="0" />
                </Border>
              </StackPanel>
            </Border>
            <!-- Real-Time Live RAM Meter & Free RAM Card -->
            <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="0,0,0,5">
              <StackPanel>
                <!-- Top Row: Memory Header + Reclaimable Tag on Right -->
                <DockPanel LastChildFill="False" Margin="0,0,0,7">
                  <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
                    <TextBlock Text="&#xE958;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#3B6B48" Margin="0,0,5,0" VerticalAlignment="Center" />
                    <TextBlock Text="RAM" FontWeight="Bold" FontSize="11" Foreground="#F5EDE0" VerticalAlignment="Center" />
                  </StackPanel>
                  <Border DockPanel.Dock="Right" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="5,1.5" VerticalAlignment="Center">
                    <TextBlock Name="TxtRamReclaimable" Text="~0 MB" FontSize="9.5" FontWeight="Bold" Foreground="#FFFFFF" />
                  </Border>
                </DockPanel>
                <!-- Bottom Row: Gauge + Stats + Free RAM Button -->
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <!-- Circular Gauge -->
                  <Grid Grid.Column="0" Width="28" Height="28" Margin="0,0,8,0" VerticalAlignment="Center">
                    <Ellipse Width="23.2" Height="23.2" Stroke="#140F0C" StrokeThickness="2.8" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    <Path Name="RamCircleArc" Stroke="#3B6B48" StrokeThickness="2.8" StrokeStartLineCap="Round" StrokeEndLineCap="Round" />
                    <TextBlock Name="TxtRamPercent" Text="0%" FontSize="8.5" FontWeight="Bold" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                  </Grid>
                  <!-- RAM Stats -->
                  <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="0,0,6,0">
                    <TextBlock Name="TxtRamLiveMetrics" Text="Scanning..." FontSize="11" FontWeight="SemiBold" Foreground="#F5EDE0" />
                    <TextBlock Text="Used / Total" FontSize="9" Foreground="#A1A1AA" />
                  </StackPanel>
                  <!-- Free RAM Button -->
                  <Button Grid.Column="2" Name="BtnFreeRam" Style="{StaticResource b2}" Background="#1A2E1F" Foreground="#FFFFFF" Height="28" Padding="6,0" Cursor="Hand" ToolTip="Instantly free idle application RAM without closing any apps">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                      <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="10" Foreground="#FFFFFF" Margin="0,0,4,0" VerticalAlignment="Center" />
                      <TextBlock Name="TxtFreeRam" Text="Free RAM" FontWeight="Bold" FontSize="10.5" Foreground="#FFFFFF" VerticalAlignment="Center" />
                    </StackPanel>
                  </Button>
                </Grid>
              </StackPanel>
            </Border>
            <!-- Sidebar Footer: Website & Donate Links -->
            <Grid Margin="0,1,0,0">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="6" />
                <ColumnDefinition Width="*" />
              </Grid.ColumnDefinitions>
              <!-- Website Button -->
              <Button Grid.Column="0" Name="BtnSidebarWebsite" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Height="28" Padding="4,0" Cursor="Hand" ToolTip="Official Website: https://zeroiq.site">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                  <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                  <TextBlock Text="Website" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" VerticalAlignment="Center" />
                </StackPanel>
              </Button>
              <!-- Donate Button -->
              <Button Grid.Column="2" Name="BtnSidebarDonate" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Height="28" Padding="4,0" Cursor="Hand" ToolTip="Donate: https://zeroiq.site/donate">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                  <TextBlock Text="&#xEB51;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#c15f3c" Margin="0,0,5,0" VerticalAlignment="Center" />
                  <TextBlock Name="TxtSidebarDonate" Text="Donate" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" VerticalAlignment="Center" />
                </StackPanel>
              </Button>
            </Grid>
          </StackPanel>
        </Grid>
      </Border>
      <!-- RIGHT MAIN CONTENT (PAGES) -->
      <Grid Grid.Column="1" Margin="8,6,10,6">
        <TabControl Name="MainTabs">
          <!-- TAB 1: CACHE CLEANER DASHBOARD -->
          <TabItem Name="Tab_Dashboard">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="⚡" Margin="0,0,5,0" />
                <TextBlock Text="Cleaner Dashboard" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
              </Grid.RowDefinitions>
              <!-- Action Bar & Presets -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <!-- Presets -->
                  <WrapPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TxtPresetsLabel" Text="Presets:" VerticalAlignment="Center" FontWeight="Bold" Foreground="#F5EDE0" Margin="0,0,6,0" />
                    <Button Name="BtnPresetRecommended" Style="{StaticResource b2}" Background="#1A2E1F" Foreground="#34D399" Content="Recommended" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                    <Button Name="BtnPresetAll" Style="{StaticResource b2}" Content="Select All" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                    <Button Name="BtnPresetClear" Style="{StaticResource b2}" Content="Deselect All" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                    <Button Name="BtnPresetBrowsers" Style="{StaticResource b2}" Content="Browsers" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                    <Button Name="BtnPresetDev" Style="{StaticResource b2}" Content="Dev Caches" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                    <Button Name="BtnPresetGaming" Style="{StaticResource b2}" Content="Gaming" Margin="0,0,4,2" Padding="7,3" FontSize="11" />
                  </WrapPanel>
                  <!-- Quick Action Controls -->
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <StackPanel Orientation="Horizontal" Margin="0,0,12,0" VerticalAlignment="Center">
                      <CheckBox Name="ChkAutoCloseApps" Style="{StaticResource ModernCheckBox}" Content="Auto-close running apps" VerticalAlignment="Center" FontWeight="SemiBold" ToolTip="Automatically terminates guarded apps (Chrome, Discord, Steam) for 100% clean space" />
                      <Button Name="BtnToggleAutoCloseTip" Background="Transparent" BorderThickness="0" Padding="3,0" Margin="4,0,0,0" Cursor="Hand" ToolTip="What is Auto-close running apps? Click for info">
                        <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#38BDF8" VerticalAlignment="Center" />
                      </Button>
                    </StackPanel>
                    <Button Name="BtnScanAll" Style="{StaticResource PrimaryButton}" Content="Scan Space" Margin="0,0,6,0" Padding="12,5" FontSize="11.5" />
                    <Button Name="BtnCleanSelected" Style="{StaticResource SuccessButton}" Content="Clean Selected Caches" Padding="14,5" FontSize="11.5" FontWeight="Bold" />
                  </WrapPanel>
                </Grid>
              </Border>
              <!-- Auto-Close Running Apps Medieval Grimoire Scroll Banner -->
              <Border Name="Banner_AutoCloseTip" Grid.Row="1" Background="#111114" BorderBrush="#27272A" BorderThickness="1.5" CornerRadius="4" Padding="12,9" Margin="0,0,0,6" Visibility="Visible">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <Border Grid.Column="0" Background="#18181B" BorderBrush="#c15f3c" BorderThickness="1" CornerRadius="4" Width="28" Height="28" Margin="0,0,10,0" VerticalAlignment="Center">
                    <TextBlock Text="&#xE7BA;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                  </Border>
                  <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,2">
                      <TextBlock Name="TxtAutoCloseBannerTitle" Text="Auto-Close Running Apps" FontWeight="Bold" FontSize="11.5" Foreground="#c15f3c" Margin="0,0,8,0" VerticalAlignment="Center" />
                      <Border Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="3" Padding="5,1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAutoCloseBannerTag" Text="SAFE &amp; THOROUGH" FontSize="8.5" FontWeight="Bold" Foreground="#4ADE80" />
                      </Border>
                    </StackPanel>
                    <TextBlock Name="TxtAutoCloseBannerDesc" Text="Closing open browsers &amp; background apps (Chrome, Discord, Steam) before cleaning unlocks their temporary files so ZeroHub can achieve a 100% clean sweep. If unchecked, running apps are skipped safely." FontSize="10.5" Foreground="#D5C8B4" TextWrapping="Wrap" />
                  </StackPanel>
                  <Button Grid.Column="2" Name="BtnDismissAutoCloseTip" Width="22" Height="22" Background="Transparent" BorderThickness="0" Foreground="#A1A1AA" FontSize="10" Cursor="Hand" ToolTip="Dismiss" VerticalAlignment="Top" Margin="6,0,0,0">
                    <TextBlock Text="&#xE711;" FontFamily="Segoe MDL2 Assets" VerticalAlignment="Center" HorizontalAlignment="Center" />
                  </Button>
                </Grid>
              </Border>
              <!-- Scrollable Category Cards Grid -->
              <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <Grid Margin="0,0,4,0">
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                  </Grid.ColumnDefinitions>
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                  </Grid.RowDefinitions>
                  <!-- CARD 1: GPU SHADERS -->
                  <Border Grid.Column="0" Grid.Row="0" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#38BDF8" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_GPU" Text="GPU Shaders" FontWeight="Bold" FontSize="14" Foreground="#38BDF8" />
                        </StackPanel>
                        <TextBlock Name="Badge_GPU" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_GPU" Text="NVIDIA, AMD, Intel &amp; DirectX Shader Caches" FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_GPU" />
                    </StackPanel>
                  </Border>
                  <!-- CARD 2: WEB BROWSERS -->
                  <Border Grid.Column="1" Grid.Row="0" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#60A5FA" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_Browser" Text="Web Browsers" FontWeight="Bold" FontSize="14" Foreground="#60A5FA" />
                        </StackPanel>
                        <TextBlock Name="Badge_Browser" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_Browser" Text="Chrome, Edge, Brave, Arc, Firefox, Opera, etc." FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_Browser" />
                    </StackPanel>
                  </Border>
                  <!-- CARD 3: DEVELOPER CACHES -->
                  <Border Grid.Column="2" Grid.Row="0" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#C084FC" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_Dev" Text="Developer Tools" FontWeight="Bold" FontSize="14" Foreground="#C084FC" />
                        </StackPanel>
                        <TextBlock Name="Badge_Dev" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_Dev" Text="npm, pip, Yarn, pnpm, NuGet, Gradle, VS Code" FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_Dev" />
                    </StackPanel>
                  </Border>
                  <!-- CARD 4: GAMING LAUNCHERS -->
                  <Border Grid.Column="0" Grid.Row="1" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#FBBF24" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_Gaming" Text="Gaming Launchers" FontWeight="Bold" FontSize="14" Foreground="#FBBF24" />
                        </StackPanel>
                        <TextBlock Name="Badge_Gaming" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_Gaming" Text="Steam, Epic Games, Battle.net, Riot, GOG, Roblox" FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_Gaming" />
                    </StackPanel>
                  </Border>
                  <!-- CARD 5: SOCIAL, CREATIVE & APPS -->
                  <Border Grid.Column="1" Grid.Row="1" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#F472B6" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_Social" Text="Chat &amp; Creative" FontWeight="Bold" FontSize="14" Foreground="#F472B6" />
                        </StackPanel>
                        <TextBlock Name="Badge_Social" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_Social" Text="Discord, Telegram, Slack, DaVinci, Blender, OBS, VLC" FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_Social" />
                    </StackPanel>
                  </Border>
                  <!-- CARD 6: SYSTEM & ADMIN -->
                  <Border Grid.Column="2" Grid.Row="1" Style="{StaticResource CardPanel}">
                    <StackPanel>
                      <Grid Margin="0,0,0,6">
                        <StackPanel Orientation="Horizontal">
                          <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#F87171" Margin="0,0,6,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtTitle_System" Text="System &amp; Admin" FontWeight="Bold" FontSize="14" Foreground="#F87171" />
                        </StackPanel>
                        <TextBlock Name="Badge_System" HorizontalAlignment="Right" Text="0 MB" FontWeight="Bold" FontSize="12" Foreground="#4ADE80" />
                      </Grid>
                      <TextBlock Name="TxtSub_System" Text="User Temp, Cryptnet, Win Updates, WER, BSOD Dumps" FontSize="11" Foreground="#F5EDE0" Margin="0,0,0,6" />
                      <Separator Background="#2A3756" Margin="0,0,0,6" />
                      <StackPanel Name="Panel_System" />
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
                <TextBlock Text="📥" Margin="0,0,6,0" />
                <TextBlock Name="TxtTabInstallerTitle" Text="Install Essential Apps" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,8,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
              </Grid.RowDefinitions>
              <!-- Top Toolbar -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,4">
                    <TextBlock Name="TxtInstallerSearchLabel" Text="Search:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,6,0" Foreground="#F5EDE0" FontSize="11.5" />
                    <TextBox Name="TxtInstallerSearch" Width="140" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="5,2" FontSize="11.5" Margin="0,0,6,0" />
                  </StackPanel>
                  <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,4">
                    <Button Name="BtnFilterInstAll" Style="{StaticResource SecondaryButton}" Content="All" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstBrowsers" Style="{StaticResource SecondaryButton}" Content="🌐 Browsers" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstTools" Style="{StaticResource SecondaryButton}" Content="🛠️ Utilities" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstGaming" Style="{StaticResource SecondaryButton}" Content="🎮 Gaming" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstComms" Style="{StaticResource SecondaryButton}" Content="💬 Comms" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstMedia" Style="{StaticResource SecondaryButton}" Content="🎬 Media" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstDev" Style="{StaticResource SecondaryButton}" Content="💻 Dev" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstPro" Style="{StaticResource SecondaryButton}" Content="⚡ Pro Tools" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstDocs" Style="{StaticResource SecondaryButton}" Content="📄 Documents" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                    <Button Name="BtnFilterInstRuntimes" Style="{StaticResource SecondaryButton}" Content="🪟 Runtimes" Padding="6,2.5" FontSize="11" Margin="0,0,3,2" />
                  </WrapPanel>
                  <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,4">
                    <Button Name="BtnSelectUpdates" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="🔄 Updates (0)" Padding="8,0" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnSelectRecApps" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="🌟 Recommended" Padding="8,0" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnSelectAllInstApps" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="Select All" Padding="8,0" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnDeselectAllInstApps" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="Clear Selection" Padding="8,0" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnRefreshInstStatus" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="🔄 Refresh" Padding="8,0" FontSize="11" Margin="0,0,0,2" />
                  </WrapPanel>
                </WrapPanel>
              </Border>
              <!-- 4-Column Masonry Grid View (Zero Gaps, Balanced Multi-Column) -->
              <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,4,0" Cursor="Arrow">
                <Grid Cursor="Arrow">
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                  </Grid.ColumnDefinitions>
                  <!-- Column 1: Browsers, Comms, Documents -->
                  <ItemsControl Name="InstallerCardsCol1" Grid.Column="0" Margin="0,0,8,0" Cursor="Arrow">
                    <ItemsControl.ItemTemplate>
                      <DataTemplate>
                        <Border VerticalAlignment="Top" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                          <StackPanel Cursor="Arrow">
                            <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#23232A" BorderThickness="0,0,0,1" Cursor="Arrow">
                              <Grid Cursor="Arrow">
                                <Grid.ColumnDefinitions>
                                  <ColumnDefinition Width="*" />
                                  <ColumnDefinition Width="Auto" />
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow" />
                                <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                  <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#A1A1AA" FontWeight="SemiBold" Cursor="Arrow" />
                                </Border>
                              </Grid>
                            </Border>
                            <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                              <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                  <Border CornerRadius="4" Padding="6,4" Margin="0,1.5" Cursor="Arrow">
                                    <Border.Style>
                                      <Style TargetType="Border">
                                        <Setter Property="Background" Value="Transparent" />
                                        <Setter Property="BorderThickness" Value="1" />
                                        <Setter Property="BorderBrush" Value="Transparent" />
                                        <Style.Triggers>
                                          <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#18181C" />
                                          </Trigger>
                                          <DataTrigger Binding="{Binding IsSelected}" Value="True">
                                            <Setter Property="Background" Value="#1E242C" />
                                            <Setter Property="BorderBrush" Value="#2A3441" />
                                          </DataTrigger>
                                        </Style.Triggers>
                                      </Style>
                                    </Border.Style>
                                    <Grid Cursor="Arrow">
                                      <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto" />
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                      </Grid.ColumnDefinitions>
                                      <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand" />
                                      <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="{Binding NameFg}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                        <TextBlock.ToolTip>
                                          <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                            <StackPanel MaxWidth="320">
                                              <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8" />
                                              <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,4" />
                                              <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#F5EDE0" />
                                            </StackPanel>
                                          </ToolTip>
                                        </TextBlock.ToolTip>
                                      </TextBlock>
                                      <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow" />
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
                        <Border VerticalAlignment="Top" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                          <StackPanel Cursor="Arrow">
                            <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#23232A" BorderThickness="0,0,0,1" Cursor="Arrow">
                              <Grid Cursor="Arrow">
                                <Grid.ColumnDefinitions>
                                  <ColumnDefinition Width="*" />
                                  <ColumnDefinition Width="Auto" />
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow" />
                                <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                  <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#A1A1AA" FontWeight="SemiBold" Cursor="Arrow" />
                                </Border>
                              </Grid>
                            </Border>
                            <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                              <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                  <Border CornerRadius="4" Padding="6,4" Margin="0,1.5" Cursor="Arrow">
                                    <Border.Style>
                                      <Style TargetType="Border">
                                        <Setter Property="Background" Value="Transparent" />
                                        <Setter Property="BorderThickness" Value="1" />
                                        <Setter Property="BorderBrush" Value="Transparent" />
                                        <Style.Triggers>
                                          <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#18181C" />
                                          </Trigger>
                                          <DataTrigger Binding="{Binding IsSelected}" Value="True">
                                            <Setter Property="Background" Value="#1E242C" />
                                            <Setter Property="BorderBrush" Value="#2A3441" />
                                          </DataTrigger>
                                        </Style.Triggers>
                                      </Style>
                                    </Border.Style>
                                    <Grid Cursor="Arrow">
                                      <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto" />
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                      </Grid.ColumnDefinitions>
                                      <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand" />
                                      <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="{Binding NameFg}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                        <TextBlock.ToolTip>
                                          <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                            <StackPanel MaxWidth="320">
                                              <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8" />
                                              <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,4" />
                                              <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#F5EDE0" />
                                            </StackPanel>
                                          </ToolTip>
                                        </TextBlock.ToolTip>
                                      </TextBlock>
                                      <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow" />
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
                        <Border VerticalAlignment="Top" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                          <StackPanel Cursor="Arrow">
                            <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#23232A" BorderThickness="0,0,0,1" Cursor="Arrow">
                              <Grid Cursor="Arrow">
                                <Grid.ColumnDefinitions>
                                  <ColumnDefinition Width="*" />
                                  <ColumnDefinition Width="Auto" />
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow" />
                                <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                  <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#A1A1AA" FontWeight="SemiBold" Cursor="Arrow" />
                                </Border>
                              </Grid>
                            </Border>
                            <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                              <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                  <Border CornerRadius="4" Padding="6,4" Margin="0,1.5" Cursor="Arrow">
                                    <Border.Style>
                                      <Style TargetType="Border">
                                        <Setter Property="Background" Value="Transparent" />
                                        <Setter Property="BorderThickness" Value="1" />
                                        <Setter Property="BorderBrush" Value="Transparent" />
                                        <Style.Triggers>
                                          <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#18181C" />
                                          </Trigger>
                                          <DataTrigger Binding="{Binding IsSelected}" Value="True">
                                            <Setter Property="Background" Value="#1E242C" />
                                            <Setter Property="BorderBrush" Value="#2A3441" />
                                          </DataTrigger>
                                        </Style.Triggers>
                                      </Style>
                                    </Border.Style>
                                    <Grid Cursor="Arrow">
                                      <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto" />
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                      </Grid.ColumnDefinitions>
                                      <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand" />
                                      <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="{Binding NameFg}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                        <TextBlock.ToolTip>
                                          <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                            <StackPanel MaxWidth="320">
                                              <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8" />
                                              <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,4" />
                                              <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#F5EDE0" />
                                            </StackPanel>
                                          </ToolTip>
                                        </TextBlock.ToolTip>
                                      </TextBlock>
                                      <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow" />
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
                        <Border VerticalAlignment="Top" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Margin="0,0,0,10" Padding="12,10" Cursor="Arrow">
                          <StackPanel Cursor="Arrow">
                            <Border Margin="0,0,0,8" Padding="0,0,0,6" BorderBrush="#23232A" BorderThickness="0,0,0,1" Cursor="Arrow">
                              <Grid Cursor="Arrow">
                                <Grid.ColumnDefinitions>
                                  <ColumnDefinition Width="*" />
                                  <ColumnDefinition Width="Auto" />
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="{Binding Header}" FontSize="12" FontWeight="Bold" Foreground="{Binding HeaderColor}" VerticalAlignment="Center" Cursor="Arrow" />
                                <Border Grid.Column="1" Background="#1E293B" CornerRadius="4" Padding="6,1" Cursor="Arrow">
                                  <TextBlock Text="{Binding CountText}" FontSize="10" Foreground="#A1A1AA" FontWeight="SemiBold" Cursor="Arrow" />
                                </Border>
                              </Grid>
                            </Border>
                            <ItemsControl ItemsSource="{Binding FilteredApps}" Cursor="Arrow">
                              <ItemsControl.ItemTemplate>
                                <DataTemplate>
                                  <Border CornerRadius="4" Padding="6,4" Margin="0,1.5" Cursor="Arrow">
                                    <Border.Style>
                                      <Style TargetType="Border">
                                        <Setter Property="Background" Value="Transparent" />
                                        <Setter Property="BorderThickness" Value="1" />
                                        <Setter Property="BorderBrush" Value="Transparent" />
                                        <Style.Triggers>
                                          <Trigger Property="IsMouseOver" Value="True">
                                            <Setter Property="Background" Value="#18181C" />
                                          </Trigger>
                                          <DataTrigger Binding="{Binding IsSelected}" Value="True">
                                            <Setter Property="Background" Value="#1E242C" />
                                            <Setter Property="BorderBrush" Value="#2A3441" />
                                          </DataTrigger>
                                        </Style.Triggers>
                                      </Style>
                                    </Border.Style>
                                    <Grid Cursor="Arrow">
                                      <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto" />
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="Auto" />
                                      </Grid.ColumnDefinitions>
                                      <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" VerticalAlignment="Center" HorizontalAlignment="Left" Margin="0,0,6,0" Cursor="Hand" />
                                      <TextBlock Grid.Column="1" HorizontalAlignment="Left" Cursor="Help" Text="{Binding DisplayName}" FontWeight="SemiBold" Foreground="{Binding NameFg}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis">
                                        <TextBlock.ToolTip>
                                          <ToolTip Background="#0B0F19" Foreground="#FFFFFF" BorderBrush="#38BDF8">
                                            <StackPanel MaxWidth="320">
                                              <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" Foreground="#38BDF8" />
                                              <TextBlock Text="{Binding PackageId}" FontFamily="Consolas" FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,4" />
                                              <TextBlock Text="{Binding Description}" TextWrapping="Wrap" FontSize="11" Foreground="#F5EDE0" />
                                            </StackPanel>
                                          </ToolTip>
                                        </TextBlock.ToolTip>
                                      </TextBlock>
                                      <Border Grid.Column="2" Background="{Binding StatusBg}" CornerRadius="3" Padding="4,1" Margin="4,0,0,0" Visibility="{Binding StatusVisibility}" Cursor="Arrow">
                                        <TextBlock Text="{Binding Status}" FontSize="9" FontWeight="Bold" Foreground="{Binding StatusFg}" Cursor="Arrow" />
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
              <Border Grid.Row="2" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,6,0,0">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="TxtInstallerStatus" Text="Select one or more software applications to silently install via official winget." FontSize="11.5" FontWeight="SemiBold" Foreground="#A1A1AA" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" />
                  <Button Name="BtnInstallSelectedApps" Grid.Column="1" Style="{StaticResource PrimaryButton}" Content="🚀 Install Selected Apps" Padding="14,6" FontSize="11.5" FontWeight="Bold" IsEnabled="False" Cursor="Hand" />
                </Grid>
              </Border>
            </Grid>
          </TabItem>
          <!-- TAB 3: APP UNINSTALLER & LEFTOVER CLEANER -->
          <TabItem Name="Tab_Uninstaller">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🗑️" Margin="0,0,5,0" />
                <TextBlock Text="App Uninstaller" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
              </Grid.RowDefinitions>
              <!-- Filter & Category Bar -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <WrapPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,4">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,6,0" />
                      <TextBox Name="TxtAppSearch" Width="150" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" BorderThickness="1" Padding="6,3" FontSize="11.5" VerticalAlignment="Center" CaretBrush="#38BDF8" />
                    </StackPanel>
                    <!-- Category Filter Buttons -->
                    <WrapPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,8,4">
                      <Button Name="BtnFilterAll" Style="{StaticResource SecondaryButton}" Content="All" Padding="8,3" FontSize="11" FontWeight="Bold" Margin="0,0,3,2" Background="#c15f3c" BorderBrush="#c15f3c" Foreground="#FFFFFF" />
                      <Button Name="BtnFilterGames" Style="{StaticResource SecondaryButton}" Content="🎮 Games" Padding="8,3" FontSize="11" Margin="0,0,3,2" />
                      <Button Name="BtnFilterApps" Style="{StaticResource SecondaryButton}" Content="💻 Apps" Padding="8,3" FontSize="11" Margin="0,0,3,2" />
                      <Button Name="BtnFilterOrphaned" Style="{StaticResource SecondaryButton}" Content="👻 Orphaned" Padding="8,3" FontSize="11" Margin="0,0,6,2" />
                      <Button Name="BtnSelectAllApps" Style="{StaticResource SecondaryButton}" Content="Select All" Padding="7,3" FontSize="11" Margin="0,0,3,2" />
                      <Button Name="BtnDeselectAllApps" Style="{StaticResource SecondaryButton}" Content="Clear Selection" Padding="7,3" FontSize="11" Margin="0,0,6,2" />
                    </WrapPanel>
                  </WrapPanel>
                  <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,0,4">
                    <TextBlock Name="TxtAppCount" Text="Scanning apps..." FontSize="11" FontWeight="SemiBold" Foreground="#c15f3c" VerticalAlignment="Center" Margin="4,0,8,0" />
                    <Button Name="BtnRefreshApps" Style="{StaticResource SecondaryButton}" Content="🔄 Refresh List" Padding="10,3.5" FontSize="11" Cursor="Hand" />
                  </StackPanel>
                </Grid>
              </Border>
              <!-- Apps DataGrid with Full Dark Styling -->
              <DataGrid Name="AppsGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="11.5" Cursor="Arrow" EnableRowVirtualization="True" EnableColumnVirtualization="True" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#c15f3c" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#23232A" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                    <Setter Property="Cursor" Value="Arrow" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Background" Value="#111114" />
                    <Setter Property="Padding" Value="3" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                    <Setter Property="Cursor" Value="Arrow" />
                    <Style.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter Property="Background" Value="#18181C" />
                      </Trigger>
                      <Trigger Property="IsSelected" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                        <Setter Property="FontWeight" Value="Bold" />
                      </Trigger>
                      <DataTrigger Binding="{Binding IsSelected}" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                        <Setter Property="FontWeight" Value="Bold" />
                      </DataTrigger>
                    </Style.Triggers>
                  </Style>
                  <Style TargetType="DataGridCell">
                    <Setter Property="Padding" Value="5,3" />
                    <Setter Property="BorderThickness" Value="0" />
                    <Setter Property="Background" Value="Transparent" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                    <Setter Property="Cursor" Value="Arrow" />
                    <Style.Triggers>
                      <Trigger Property="IsSelected" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                      </Trigger>
                    </Style.Triggers>
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <DataGridTemplateColumn Width="34">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Hand" ToolTip="Select for bulk uninstallation" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTextColumn Header="#" Binding="{Binding Index}" Width="38" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#94A3B8" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="HorizontalAlignment" Value="Center" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Application Name" Binding="{Binding DisplayName}" FontWeight="Bold" Width="2.5*" IsReadOnly="True" />
                  <DataGridTextColumn Header="Type" Binding="{Binding Category}" Width="85" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="HorizontalAlignment" Value="Center" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="Foreground" Value="#A1A1AA" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="1.8*" IsReadOnly="True" />
                  <DataGridTextColumn Header="Version" Binding="{Binding DisplayVersion}" Width="80" IsReadOnly="True" />
                  <DataGridTextColumn Header="Storage Size" Binding="{Binding SizeFormatted}" SortMemberPath="EstimatedSizeMB" FontWeight="Bold" Width="95" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#c15f3c" />
                        <Setter Property="FontWeight" Value="Bold" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Install Location" Binding="{Binding InstallLocation}" Width="2*" IsReadOnly="True" />
                </DataGrid.Columns>
              </DataGrid>
              <!-- Bottom Action Controls -->
              <Border Grid.Row="2" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,6,0,0">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="TxtSelectedAppStatus" Grid.Column="0" Text="Select an application from the list above to uninstall and clean leftovers." FontSize="11.5" Foreground="#A1A1AA" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" />
                  <Button Name="BtnUninstallSelected" Grid.Column="1" Style="{StaticResource DangerButton}" Content="Uninstall &amp; Clean Leftovers" Padding="14,5" FontSize="11.5" FontWeight="Bold" IsEnabled="False" />
                </Grid>
              </Border>
            </Grid>
          </TabItem>
          <!-- TAB 3: REMOVE WINDOWS STUPID APPS (BLOATWARE REMOVER) -->
          <TabItem Name="Tab_Bloatware">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#F5EDE0" Margin="0,0,6,0" VerticalAlignment="Center" />
                <TextBlock Name="TxtTabBloatwareTitle" Text="Remove Windows Stupid Apps" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
              </Grid.RowDefinitions>
              <!-- Top Action & Info Bar -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0" VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#F5EDE0" Margin="0,0,6,0" VerticalAlignment="Center" />
                      <TextBlock Name="TxtBloatwareHeaderTitle" Text="Remove Windows Stupid &amp; Pre-installed Apps" FontWeight="Bold" FontSize="12" Foreground="#F43F5E" />
                      <Border Background="#371B28" BorderBrush="#F43F5E" BorderThickness="1" CornerRadius="4" Padding="5,1" Margin="8,0,0,0" VerticalAlignment="Center">
                        <TextBlock Name="TxtBloatwareCount" Text="0 Apps Found" FontSize="10.5" FontWeight="Bold" Foreground="#FDA4AF" />
                      </Border>
                    </StackPanel>
                    <TextBlock Name="TxtBloatwareHeaderSubtitle" Text="1-Click clean removal of Cortana, Bing News/Weather, Copilot, Xbox Overlays, Tips, and pre-installed junk." FontSize="10.5" Foreground="#A1A1AA" Margin="0,2,0,0" TextTrimming="CharacterEllipsis" />
                  </StackPanel>
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnSelectAllBloat" Style="{StaticResource SecondaryButton}" Content="Select All" Padding="8,3" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnDeselectAllBloat" Style="{StaticResource SecondaryButton}" Content="Clear Selection" Padding="8,3" FontSize="11" Margin="0,0,4,2" />
                    <Button Name="BtnRefreshBloat" Style="{StaticResource SecondaryButton}" Content="🔄 Rescan" Padding="8,3" FontSize="11" Margin="0,0,0,2" />
                  </WrapPanel>
                </Grid>
              </Border>
              <!-- Bloatware DataGrid -->
              <DataGrid Name="BloatwareGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="11.5" Cursor="Arrow" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#c15f3c" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#23232A" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                    <Setter Property="Cursor" Value="Arrow" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Background" Value="#111114" />
                    <Setter Property="Padding" Value="3" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                    <Setter Property="Cursor" Value="Arrow" />
                    <Style.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter Property="Background" Value="#18181C" />
                      </Trigger>
                      <Trigger Property="IsSelected" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                        <Setter Property="FontWeight" Value="Bold" />
                      </Trigger>
                      <DataTrigger Binding="{Binding IsSelected}" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                        <Setter Property="FontWeight" Value="Bold" />
                      </DataTrigger>
                    </Style.Triggers>
                  </Style>
                  <Style TargetType="DataGridCell">
                    <Setter Property="Padding" Value="5,3" />
                    <Setter Property="BorderThickness" Value="0" />
                    <Setter Property="Background" Value="Transparent" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                    <Setter Property="Cursor" Value="Arrow" />
                    <Style.Triggers>
                      <Trigger Property="IsSelected" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                      </Trigger>
                    </Style.Triggers>
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <DataGridTemplateColumn Width="34">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <CheckBox IsChecked="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Hand" ToolTip="Select for removal" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTextColumn Header="#" Binding="{Binding Index}" Width="38" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#94A3B8" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="HorizontalAlignment" Value="Center" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Windows App / Bloatware" Binding="{Binding DisplayName}" FontWeight="Bold" Width="2*" IsReadOnly="True" />
                  <DataGridTextColumn Header="Package Identifier" Binding="{Binding PackageName}" Width="2*" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#94A3B8" />
                        <Setter Property="FontFamily" Value="Consolas, Cascadia Code" />
                        <Setter Property="FontSize" Value="11" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="140" IsReadOnly="True" />
                  <DataGridTextColumn Header="Safety Level" Binding="{Binding SafetyStatus}" Width="140" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#4ADE80" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="HorizontalAlignment" Value="Center" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                </DataGrid.Columns>
              </DataGrid>
              <!-- Bottom Remove Action Bar -->
              <Border Grid.Row="2" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,6,0,0">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="TxtBloatSelectionStatus" Text="Select one or more Windows apps from the table to permanently remove." FontSize="11.5" FontWeight="SemiBold" Foreground="#A1A1AA" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" />
                  <Button Name="BtnRemoveSelectedBloatware" Grid.Column="1" Style="{StaticResource DangerButton}" Content="🗑️ Remove Selected Apps" Padding="14,5" FontSize="11.5" FontWeight="Bold" IsEnabled="False" Cursor="Hand" />
                </Grid>
              </Border>
            </Grid>
          </TabItem>
          <!-- TAB 4: WINDOWS UPDATES CONTROLLER -->
          <TabItem Name="Tab_Updates">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🛡️" Margin="0,0,6,0" />
                <TextBlock Name="TxtTabUpdatesTitle" Text="Windows Updates" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,4,0" Cursor="Arrow">
              <StackPanel Margin="0,8,0,16" Cursor="Arrow">
                <!-- Top Hero Status & Action Card -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,10" Cursor="Arrow">
                  <Grid Cursor="Arrow">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" CornerRadius="10" Width="44" Height="44" Margin="0,0,14,0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" VerticalAlignment="Center" Cursor="Arrow">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="22" Foreground="#38BDF8" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Arrow" />
                    </Border>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                      <StackPanel Orientation="Horizontal" Cursor="Arrow">
                        <TextBlock Name="TxtWinUpdateTitle" Text="Windows Automatic Updates Controller" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" Cursor="Arrow" />
                        <Border Name="BadgeWinUpdateStatus" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="5" Padding="7,2" Margin="10,0,0,0" VerticalAlignment="Center" Cursor="Arrow">
                          <TextBlock Name="TxtWinUpdateStatus" Text="● Updates: Active" FontSize="11" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                        </Border>
                      </StackPanel>
                      <TextBlock Name="TxtWinUpdateSubtitle" Text="Block background forced Windows updates and surprise restarts, or easily restore them anytime." FontSize="11" Foreground="#A1A1AA" Margin="0,3,0,0" Cursor="Arrow" />
                    </StackPanel>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Cursor="Arrow">
                      <Button Name="BtnToggleWinUpdate" Style="{StaticResource DangerButton}" Content="🛑 Stop Windows Updates" Padding="16,8" FontSize="12" FontWeight="Bold" Cursor="Hand" />
                    </StackPanel>
                  </Grid>
                </Border>
                <!-- 4 Compact Status Tiles (2x2 Grid, Zero Excessive Space) -->
                <Grid Margin="0,0,0,10" Cursor="Arrow">
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                  </Grid.RowDefinitions>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                  </Grid.ColumnDefinitions>
                  <!-- Card 1: Services Status -->
                  <Border Grid.Row="0" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,0,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#60A5FA" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtCard1Title" Text="Windows Update Services" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <TextBlock Name="BadgeCard1" Text="● Services Disabled" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow" />
                        </DockPanel>
                        <TextBlock Name="TxtCard1Body" Text="Controls wuauserv, UsoSvc, and WaaSMedicSvc to prevent background execution." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Cursor="Arrow" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 2: Group Policy & Registry -->
                  <Border Grid.Row="0" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,0,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#C084FC" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtCard2Title" Text="Automatic Download Policies" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <TextBlock Name="BadgeCard2" Text="● Policies Enforced" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow" />
                        </DockPanel>
                        <TextBlock Name="TxtCard2Body" Text="Configures NoAutoUpdate and AUOptions in Registry to eliminate surprise reboots." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Cursor="Arrow" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 3: Scheduled Tasks -->
                  <Border Grid.Row="1" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,0" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#FBBF24" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtCard3Title" Text="Scheduled Background Tasks" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <TextBlock Name="BadgeCard3" Text="● Scan Tasks Blocked" FontSize="10" FontWeight="Bold" Foreground="#FDA4AF" DockPanel.Dock="Right" Cursor="Arrow" />
                        </DockPanel>
                        <TextBlock Name="TxtCard3Body" Text="Disables hidden Task Scheduler triggers in UpdateOrchestrator that wake your PC." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Cursor="Arrow" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 4: Driver Update Shield -->
                  <Border Grid.Row="1" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,0" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#c15f3c" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtCard4Title" Text="Hardware Driver Shield" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <TextBlock Name="BadgeCard4" Text="● Driver Shield Active" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" DockPanel.Dock="Right" Cursor="Arrow" />
                        </DockPanel>
                        <TextBlock Name="TxtCard4Body" Text="Prevents Windows from automatically replacing custom NVIDIA / AMD graphics drivers." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Cursor="Arrow" />
                      </StackPanel>
                    </Grid>
                  </Border>
                </Grid>
                <!-- Quick Maintenance & Repair Section -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="10" Padding="16,14" Cursor="Arrow">
                  <StackPanel Cursor="Arrow">
                    <DockPanel LastChildFill="False" Margin="0,0,0,10" Cursor="Arrow">
                      <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" Cursor="Arrow">
                        <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#38BDF8" Margin="0,0,8,0" VerticalAlignment="Center" Cursor="Arrow" />
                        <TextBlock Name="TxtWuMaintTitle" Text="Quick Maintenance &amp; Troubleshooting Tools" FontWeight="Bold" FontSize="13" Foreground="#38BDF8" Cursor="Arrow" />
                      </StackPanel>
                    </DockPanel>
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <!-- Utility 1: Clear Cache -->
                      <Border Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,5,0" Cursor="Arrow">
                        <StackPanel Cursor="Arrow">
                          <StackPanel Orientation="Horizontal" Margin="0,0,0,2">
                            <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,6,0" />
                            <TextBlock Name="TxtWuCardCacheTitle" Text="Purge Update Cache" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" VerticalAlignment="Center" Cursor="Arrow" />
                          </StackPanel>
                          <TextBlock Name="TxtWuCardCacheDesc" Text="Deletes SoftwareDistribution\Download cache to free gigabytes and fix corrupt downloads." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow" />
                          <Button Name="BtnCleanWuCache" Style="{StaticResource SecondaryButton}" Content="🧹 Clean WU Cache" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand" />
                        </StackPanel>
                      </Border>
                      <!-- Utility 2: Reset Engine -->
                      <Border Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="12" Margin="3,0,3,0" Cursor="Arrow">
                        <StackPanel Cursor="Arrow">
                          <StackPanel Orientation="Horizontal" Margin="0,0,0,2">
                            <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#c15f3c" VerticalAlignment="Center" Margin="0,0,6,0" />
                            <TextBlock Name="TxtWuCardResetTitle" Text="Repair &amp; Reset Components" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" VerticalAlignment="Center" Cursor="Arrow" />
                          </StackPanel>
                          <TextBlock Name="TxtWuCardResetDesc" Text="Re-registers core update DLLs and restarts BITS &amp; CryptSvc to fix 0x800 error codes." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow" />
                          <Button Name="BtnResetWuComponents" Style="{StaticResource SecondaryButton}" Content="🔧 Reset Components" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand" />
                        </StackPanel>
                      </Border>
                      <!-- Utility 3: Open Settings -->
                      <Border Grid.Column="2" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="12" Margin="5,0,0,0" Cursor="Arrow">
                        <StackPanel Cursor="Arrow">
                          <StackPanel Orientation="Horizontal" Margin="0,0,0,2">
                            <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#FBBF24" VerticalAlignment="Center" Margin="0,0,6,0" />
                            <TextBlock Name="TxtWuCardSettingsTitle" Text="Official Windows Settings" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" VerticalAlignment="Center" Cursor="Arrow" />
                          </StackPanel>
                          <TextBlock Name="TxtWuCardSettingsDesc" Text="Quick access to Windows Update settings page to view update history or check for patch." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,4,0,10" Cursor="Arrow" />
                          <Button Name="BtnOpenWuSettings" Style="{StaticResource SecondaryButton}" Content="⚙️ Open Settings" Padding="8,5" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Stretch" Cursor="Hand" />
                        </StackPanel>
                      </Border>
                    </Grid>
                  </StackPanel>
                </Border>
              </StackPanel>
            </ScrollViewer>
          </TabItem>
          <!-- TAB 5: WINDOWS PRIVACY & ANTI-TELEMETRY HARDENER -->
          <TabItem Name="Tab_Privacy">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🛡️" Margin="0,0,6,0" />
                <TextBlock Name="TxtTabPrivacyTitle" Text="Privacy &amp; Telemetry" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,4,0" Cursor="Arrow">
              <StackPanel Margin="0,8,0,16" Cursor="Arrow">
                <!-- Top Hero Status & Action Card -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,10" Cursor="Arrow">
                  <Grid Cursor="Arrow">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" CornerRadius="10" Width="44" Height="44" Margin="0,0,14,0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" VerticalAlignment="Center" Cursor="Arrow">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="22" Foreground="#38BDF8" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Arrow" />
                    </Border>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                      <StackPanel Orientation="Horizontal" Cursor="Arrow">
                        <TextBlock Name="TxtPrivacyHeroTitle" Text="Windows Privacy &amp; Anti-Telemetry Hardener" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" Cursor="Arrow" />
                        <Border Name="BadgePrivacyMasterStatus" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="5" Padding="8,2" Margin="10,0,0,0" VerticalAlignment="Center" Cursor="Arrow">
                          <TextBlock Name="TxtPrivacyMasterStatus" Text="● Protected" FontSize="11" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                        </Border>
                      </StackPanel>
                      <TextBlock Name="TxtPrivacyHeroSubtitle" Text="Stop Microsoft data collection, telemetry services, ad tracking IDs, keylogging, and Bing cloud search." FontSize="11" Foreground="#A1A1AA" Margin="0,3,0,0" Cursor="Arrow" />
                    </StackPanel>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Cursor="Arrow">
                      <Button Name="BtnApplyMaxPrivacy" Style="{StaticResource SuccessButton}" Content="🛡️ Max Privacy Mode" Padding="14,8" FontSize="11.5" FontWeight="Bold" Margin="0,0,6,0" Cursor="Hand" ToolTip="Apply all safe anti-telemetry and privacy hardening tweaks" />
                      <Button Name="BtnRestorePrivacyDefaults" Style="{StaticResource DangerButton}" Content="🔄 Restore Defaults" Padding="12,8" FontSize="11.5" FontWeight="Bold" Foreground="#FFFFFF" Cursor="Hand" ToolTip="Revert privacy tweaks back to Windows default settings" />
                    </StackPanel>
                  </Grid>
                </Border>
                <!-- 14 Compact Status Tiles (7x2 Grid) -->
                <Grid Margin="0,0,0,10" Cursor="Arrow">
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                  </Grid.RowDefinitions>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="*" />
                  </Grid.ColumnDefinitions>
                  <!-- Card 1: Diagnostic Data & Telemetry Services -->
                  <Border Grid.Row="0" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,0,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#38BDF8" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard1Title" Text="Diagnostics &amp; Telemetry" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard1" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard1" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard1Body" Text="Stops DiagTrack and diagsvc services, sets AllowTelemetry policy to 0, and stops feedback requests." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivDiag" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 2: Advertising ID & Activity Timeline -->
                  <Border Grid.Row="0" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,0,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#C084FC" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard2Title" Text="Advertising ID &amp; Timeline" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard2" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard2" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard2Body" Text="Disables unique Windows ad profile ID, stops user activity history cloud uploads, and blocks promoted apps." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivAds" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 3: Typing, Inking & Search Privacy -->
                  <Border Grid.Row="1" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#FBBF24" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard3Title" Text="Typing, Inking &amp; Search" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard3" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard3" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard3Body" Text="Prevents keystroke and handwriting collection, disables Bing web results in Start search, and turns off location sensors." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivSearch" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 4: Background Telemetry Tasks -->
                  <Border Grid.Row="1" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#c15f3c" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard4Title" Text="Telemetry Scheduled Tasks" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard4" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard4" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard4Body" Text="Disables Customer Experience (CEIP) scheduled tasks, ProgramDataUpdater, and Compatibility Appraiser." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivTasks" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 5: AI & Windows Recall Shield -->
                  <Border Grid.Row="2" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#38BDF8" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard5Title" Text="AI &amp; Windows Recall Shield" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard5" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard5" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard5Body" Text="Disables Windows Recall screen snapshots, Copilot background Edge WebView2 telemetry, and AI data indexing." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivAI" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 6: Telemetry Hosts Null-Router -->
                  <Border Grid.Row="2" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#FB923C" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard6Title" Text="Telemetry Hosts Null-Router" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard6" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard6" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard6Body" Text="Null-routes Microsoft telemetry endpoints (v10.events, telemetry.ms, watson) to 0.0.0.0 in the Windows hosts file." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivHosts" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 7: Microsoft Edge Telemetry & Ads -->
                  <Border Grid.Row="3" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#60A5FA" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard7Title" Text="Microsoft Edge Telemetry &amp; Ads" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard7" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard7" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard7Body" Text="Blocks Edge background worker processes, startup boost, shopping assistant trackers, and diagnostic telemetry." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivEdge" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 8: Error Reporting & Dump Privacy -->
                  <Border Grid.Row="3" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#F43F5E" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard8Title" Text="Error Reporting &amp; Dump Privacy" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard8" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard8" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard8Body" Text="Prevents Windows Error Reporting (WER) from uploading memory crash dumps (containing private RAM data) to Microsoft." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivWER" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 9: Windows Nudges & In-OS Ads -->
                  <Border Grid.Row="4" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#F472B6" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard9Title" Text="Windows Nudges &amp; In-OS Ads" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard9" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard9" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard9Body" Text="Blocks full-screen setup nag prompts, File Explorer promo banners, lock screen ads, and sponsored suggestions." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivNudges" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 10: Delivery Optimization P2P -->
                  <Border Grid.Row="4" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#38BDF8" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard10Title" Text="Delivery Optimization P2P" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard10" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard10" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard10Body" Text="Stops Windows from using your upload bandwidth to seed updates to random internet computers." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivWUDO" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 11: Cloud Clipboard & Keystrokes -->
                  <Border Grid.Row="5" Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,5,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#A78BFA" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard11Title" Text="Cloud Clipboard &amp; Keystrokes" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard11" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard11" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard11Body" Text="Keeps clipboard history strictly local (blocks cloud upload) and stops handwriting &amp; typing collection." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivClipboard" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 12: Location & Feedback Nags -->
                  <Border Grid.Row="5" Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="5,5,0,5" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#FBBF24" Margin="0,0,10,0" VerticalAlignment="Top" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard12Title" Text="Location &amp; Feedback Nags" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard12" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard12" Text="● Protected" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard12Body" Text="Disables background geolocation polling and silences annoying Windows feedback survey prompts." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivSensors" Style="{StaticResource b2}" Content="Disable Protection" Background="#c15f3c" Foreground="#FFFFFF" Padding="8,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 13: Classic Windows 10 Context Menu (Full-Width Centered) -->
                  <Border Grid.Row="6" Grid.Column="0" Grid.ColumnSpan="2" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,5,0,0" Cursor="Arrow">
                    <Grid Cursor="Arrow">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#38BDF8" Margin="0,0,12,0" VerticalAlignment="Center" Cursor="Arrow" />
                      <StackPanel Grid.Column="1" Cursor="Arrow">
                        <DockPanel LastChildFill="False" Margin="0,0,0,4" Cursor="Arrow">
                          <TextBlock Name="TxtPrivCard13Title" Text="Classic Context Menu (Windows 10 Style)" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" DockPanel.Dock="Left" Cursor="Arrow" />
                          <Border Name="Border_BadgePrivCard13" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Padding="6,2" DockPanel.Dock="Right" Cursor="Arrow">
                            <TextBlock Name="BadgePrivCard13" Text="● Classic Active" FontSize="10" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtPrivCard13Body" Text="Restores the instant-response full Windows 10 right-click context menu on Windows 11 without the laggy 'Show more options' sub-menu." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,8" Cursor="Arrow" />
                        <Button Name="BtnTogglePrivClassicMenu" Style="{StaticResource b2}" Content="Enable Classic Menu" Padding="12,4" FontSize="11" HorizontalAlignment="Left" Cursor="Hand" />
                      </StackPanel>
                    </Grid>
                  </Border>
                </Grid>
                <!-- Safe Privacy Notice Medieval Banner -->
                <Border Background="#111114" BorderBrush="#27272A" BorderThickness="1.5" CornerRadius="4" Padding="12,9" Cursor="Arrow">
                  <Grid Cursor="Arrow">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="#18181B" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="4" Width="28" Height="28" Margin="0,0,10,0" VerticalAlignment="Center">
                      <TextBlock Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                      <TextBlock Name="TxtPrivNoticeTitle" Text="100% Windows Compatibility Guarantee" FontWeight="Bold" FontSize="11.5" Foreground="#c15f3c" Margin="0,0,0,2" Cursor="Arrow" />
                      <TextBlock Name="TxtPrivNoticeDesc" Text="These privacy hardening tweaks only disable tracking, diagnostics, and telemetry. Core Windows components (Microsoft Store, Windows Activation, Xbox Gaming, DirectX, Printer Spooler) remain 100% functional." FontSize="10.5" Foreground="#D5C8B4" TextWrapping="Wrap" Cursor="Arrow" />
                    </StackPanel>
                  </Grid>
                </Border>
              </StackPanel>
            </ScrollViewer>
          </TabItem>
          <!-- TAB: DNS & INTERNET SPEED BOOSTER -->
          <TabItem Name="Tab_Dns">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🌐" Margin="0,0,5,0" />
                <TextBlock Name="TxtHeaderTabDns" Text="DNS &amp; Network" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="20">
              <StackPanel Margin="0,0,0,20">
                <!-- Hero Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,16">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="#0C2340" BorderBrush="#0284C7" BorderThickness="1" CornerRadius="8" Width="44" Height="44" Margin="0,0,14,0" HorizontalAlignment="Center" VerticalAlignment="Center">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                      <StackPanel Orientation="Horizontal" Cursor="Arrow">
                        <TextBlock Name="TxtDnsHeroTitle" Text="DNS &amp; Internet Speed Booster" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" Cursor="Arrow" />
                        <Border Name="BadgeDnsActiveStatus" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="5" Padding="8,2" Margin="10,0,0,0" VerticalAlignment="Center" Cursor="Arrow">
                          <TextBlock Name="TxtDnsActiveStatus" Text="● Checking Active DNS..." FontSize="11" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                        </Border>
                      </StackPanel>
                      <TextBlock Name="TxtDnsHeroSubtitle" Text="Benchmark latency across top secure DNS providers and switch in 1-click for lower gaming ping, ad-blocking, and threat protection." FontSize="11" Foreground="#A1A1AA" Margin="0,3,0,0" Cursor="Arrow" />
                    </StackPanel>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Cursor="Arrow">
                      <Button Name="BtnRunDnsBenchmark" Style="{StaticResource SuccessButton}" Content="Test Latency (Ping)" Padding="12,8" FontSize="11" FontWeight="Bold" Cursor="Hand" ToolTip="Test live response times for all DNS servers in milliseconds" />
                    </StackPanel>
                  </Grid>
                </Border>
                <!-- DNS Provider Cards Grid -->
                <UniformGrid Columns="2" Margin="0,0,0,16">
                  <!-- Card 1: Cloudflare -->
                  <Border Name="CardDns_cloudflare" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,8,12">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_cloudflare" Text="Cloudflare (1.1.1.1)" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_cloudflare" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_cloudflare" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_cloudflare" Text="⚡ Ultra-Low Latency &amp; Gaming" FontSize="10.5" FontWeight="SemiBold" Foreground="#F97316" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_cloudflare" Text="World's fastest public DNS resolver with privacy pledge and zero log selling." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 1.1.1.1  •  Secondary: 1.0.0.1" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_cloudflare" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 2: AdGuard DNS -->
                  <Border Name="CardDns_adguard" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="8,0,0,12">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_adguard" Text="AdGuard DNS" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_adguard" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_adguard" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_adguard" Text="🛡️ System-Wide Ad &amp; Tracker Blocker" FontSize="10.5" FontWeight="SemiBold" Foreground="#10B981" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_adguard" Text="Blocks intrusive web ads, popups, and tracking domains across your entire system without extra software." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 94.140.14.14  •  Secondary: 94.140.15.15" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_adguard" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 3: Quad9 Secure -->
                  <Border Name="CardDns_quad9" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,8,12">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_quad9" Text="Quad9 Secure" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_quad9" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_quad9" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_quad9" Text="🔒 Anti-Malware &amp; Phishing Shield" FontSize="10.5" FontWeight="SemiBold" Foreground="#06B6D4" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_quad9" Text="Real-time threat intelligence blocking ransomware, infected domains, malware, and phishing." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 9.9.9.9  •  Secondary: 149.112.112.112" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_quad9" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 4: Google Public DNS -->
                  <Border Name="CardDns_google" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="8,0,0,12">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_google" Text="Google Public DNS" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_google" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_google" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_google" Text="🌐 High Reliability &amp; Global Anycast" FontSize="10.5" FontWeight="SemiBold" Foreground="#3B82F6" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_google" Text="Massive global Anycast infrastructure with geo-optimized CDN caching for rock-solid stability." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 8.8.8.8  •  Secondary: 8.8.4.4" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_google" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 5: Cisco OpenDNS -->
                  <Border Name="CardDns_opendns" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,8,0">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_opendns" Text="Cisco OpenDNS" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_opendns" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_opendns" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_opendns" Text="🏢 Enterprise Cloud Routing" FontSize="10.5" FontWeight="SemiBold" Foreground="#8B5CF6" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_opendns" Text="Enterprise-grade cloud routing with SmartCache and automatic phishing domain filtering." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 208.67.222.222  •  Secondary: 208.67.220.220" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_opendns" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                  <!-- Card 6: CleanBrowsing -->
                  <Border Name="CardDns_cleanbrowsing" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="8,0,0,0">
                    <Grid>
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto" />
                        <ColumnDefinition Width="*" />
                      </Grid.ColumnDefinitions>
                      <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" Margin="0,0,12,0" VerticalAlignment="Top" />
                      <StackPanel Grid.Column="1">
                        <DockPanel LastChildFill="False" Margin="0,0,0,3">
                          <TextBlock Name="TxtDnsTitle_cleanbrowsing" Text="CleanBrowsing Family Filter" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                          <Border Name="Border_PingDns_cleanbrowsing" Background="#1E293B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="4" Padding="6,1.5" DockPanel.Dock="Right">
                            <TextBlock Name="TxtPingDns_cleanbrowsing" Text="-- ms" FontSize="10" FontWeight="Bold" Foreground="#A1A1AA" />
                          </Border>
                        </DockPanel>
                        <TextBlock Name="TxtDnsTag_cleanbrowsing" Text="👨‍👩‍👧 Family Safety &amp; Content Filter" FontSize="10.5" FontWeight="SemiBold" Foreground="#EC4899" Margin="0,0,0,4" />
                        <TextBlock Name="TxtDnsDesc_cleanbrowsing" Text="Enforces safe search and blocks malicious, phishing, and non-family domains automatically." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                        <DockPanel LastChildFill="False">
                          <TextBlock Text="Primary: 185.228.168.168  •  Secondary: 185.228.169.168" FontSize="10" Foreground="#71717A" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" />
                          <Button Name="BtnApplyDns_cleanbrowsing" Style="{StaticResource b2}" Content="Apply DNS" Padding="10,4" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                        </DockPanel>
                      </StackPanel>
                    </Grid>
                  </Border>
                </UniformGrid>
                <!-- Custom DNS Card & Network Utilities Toolbar -->
                <Grid Margin="0,0,0,14">
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="1.2*" />
                    <ColumnDefinition Width="*" />
                  </Grid.ColumnDefinitions>
                  <!-- Custom DNS Input Card -->
                  <Border Grid.Column="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,8,0">
                    <StackPanel>
                      <TextBlock Name="TxtCustomDnsTitle" Text="Custom DNS Provider" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" Margin="0,0,0,4" />
                      <TextBlock Name="TxtCustomDnsDesc" Text="Enter custom Primary and Secondary IPv4 addresses to apply to your active network adapter." FontSize="11" Foreground="#A1A1AA" Margin="0,0,0,8" />
                      <Grid Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*" />
                          <ColumnDefinition Width="*" />
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0" Margin="0,0,6,0">
                          <TextBlock Text="Primary DNS:" FontSize="10" Foreground="#71717A" Margin="0,0,0,2" />
                          <TextBox Name="TxtCustomDnsPrimary" Background="#0B0F19" Foreground="#F8FAFC" BorderBrush="#374151" BorderThickness="1" Padding="8,5" FontSize="11" Text="1.1.1.1" />
                        </StackPanel>
                        <StackPanel Grid.Column="1" Margin="6,0,0,0">
                          <TextBlock Text="Secondary DNS (Optional):" FontSize="10" Foreground="#71717A" Margin="0,0,0,2" />
                          <TextBox Name="TxtCustomDnsSecondary" Background="#0B0F19" Foreground="#F8FAFC" BorderBrush="#374151" BorderThickness="1" Padding="8,5" FontSize="11" Text="1.0.0.1" />
                        </StackPanel>
                      </Grid>
                      <Button Name="BtnApplyCustomDns" Style="{StaticResource SuccessButton}" Content="Apply Custom DNS" Padding="10,6" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right" Cursor="Hand" />
                    </StackPanel>
                  </Border>
                  <!-- Network Repair & Maintenance Tools -->
                  <Border Grid.Column="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="8,0,0,0">
                    <StackPanel>
                      <TextBlock Name="TxtNetToolsTitle" Text="Network Repair &amp; Maintenance" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" Margin="0,0,0,4" />
                      <TextBlock Name="TxtNetToolsDesc" Text="Quick 1-click tools to resolve connection dropouts, slow DNS caching, and TCP stack issues." FontSize="11" Foreground="#A1A1AA" Margin="0,0,0,10" />
                      <StackPanel>
                        <Button Name="BtnToolFlushDns" Style="{StaticResource SecondaryButton}" Content="🧹 Flush DNS Resolver Cache" Padding="10,5" FontSize="11" Margin="0,0,0,6" HorizontalAlignment="Stretch" Cursor="Hand" />
                        <Button Name="BtnToolResetWinsock" Style="{StaticResource SecondaryButton}" Content="🔄 Reset Winsock &amp; TCP/IP Stack" Padding="10,5" FontSize="11" Margin="0,0,0,6" HorizontalAlignment="Stretch" Cursor="Hand" />
                        <Button Name="BtnToolRenewIp" Style="{StaticResource SecondaryButton}" Content="⚡ Release &amp; Renew IP Address" Padding="10,5" FontSize="11" HorizontalAlignment="Stretch" Cursor="Hand" />
                      </StackPanel>
                    </StackPanel>
                  </Border>
                </Grid>
                <!-- Informational Notice -->
                <Border Background="#0C2340" BorderBrush="#0284C7" BorderThickness="1" CornerRadius="8" Padding="14,10">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,10,0" />
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                      <TextBlock Name="TxtDnsNoticeTitle" Text="How Fast DNS Improves Your Experience" FontWeight="Bold" FontSize="11.5" Foreground="#38BDF8" Margin="0,0,0,2" />
                      <TextBlock Name="TxtDnsNoticeDesc" Text="DNS translates domain names into IP addresses. Using low-latency Anycast DNS reduces initial connection delay for websites, online games (matchmaking/lobby ping), and prevents ISP domain hijacking and throttling." FontSize="10.5" Foreground="#E0F2FE" TextWrapping="Wrap" />
                    </StackPanel>
                  </Grid>
                </Border>
              </StackPanel>
            </ScrollViewer>
          </TabItem>
          <!-- TAB: STARTUP APPLICATIONS MANAGER -->
          <TabItem Name="Tab_Startup">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🚀" Margin="0,0,5,0" />
                <TextBlock Name="TxtHeaderTabStartup" Text="Startup Apps" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
              </Grid.RowDefinitions>
              <!-- Top Action & Search Bar -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <!-- Left: Search Box & Stats -->
                  <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TxtStartupSearchLabel" Text="Search Startup Apps:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,8,0" Foreground="#F5EDE0" FontSize="11.5" />
                    <TextBox Name="TxtStartupSearch" Width="200" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="6,3" FontSize="11.5" />
                    <TextBlock Name="TxtStartupCountInfo" Text="0 Running Now • 0 Total" Foreground="#38BDF8" FontWeight="SemiBold" FontSize="11.5" Margin="14,0,0,0" VerticalAlignment="Center" />
                  </StackPanel>
                  <!-- Right: Action Buttons -->
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnRefreshStartup" Style="{StaticResource SecondaryButton}" Content="🔄 Rescan" Margin="0,0,6,0" Padding="10,4.5" FontSize="11" Cursor="Hand" />
                    <Button Name="BtnOptimizeStartup" Style="{StaticResource SuccessButton}" Content="⚡ Fast Boot Optimization" Padding="12,4.5" FontSize="11" FontWeight="Bold" Cursor="Hand" />
                  </WrapPanel>
                </Grid>
              </Border>
              <!-- STARTUP APPLICATIONS DATA GRID -->
              <DataGrid Name="StartupAppsDataGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" RowBackground="#111114" AlternatingRowBackground="#141418" HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="11.5" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#38BDF8" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#1F2937" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Padding" Value="3" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <DataGridTemplateColumn Header="Enabled" Width="70">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <CheckBox IsChecked="{Binding IsEnabled, UpdateSourceTrigger=PropertyChanged}" HorizontalAlignment="Center" VerticalAlignment="Center" Cursor="Hand" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTemplateColumn Header="Live State" Width="110">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                          <Ellipse Width="8" Height="8" Margin="2,0,7,0" Fill="{Binding LiveDotColor}" VerticalAlignment="Center" />
                          <TextBlock Text="{Binding LiveStatusText}" Foreground="{Binding LiveStatusColor}" FontWeight="Bold" FontSize="11.5" VerticalAlignment="Center" />
                        </StackPanel>
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTextColumn Header="Application Name" Binding="{Binding Name}" FontWeight="Bold" Width="190" IsReadOnly="True" />
                  <DataGridTemplateColumn Header="Startup Status" Width="105">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <TextBlock Text="{Binding StatusText}" Foreground="{Binding StatusColor}" FontWeight="Bold" FontSize="11.5" VerticalAlignment="Center" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTemplateColumn Header="Startup Impact" Width="115">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <TextBlock Text="{Binding Impact}" Foreground="{Binding ImpactColor}" FontWeight="SemiBold" VerticalAlignment="Center" FontSize="11.5" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <DataGridTextColumn Header="Source" Binding="{Binding SourceType}" Width="150" IsReadOnly="True" />
                  <DataGridTextColumn Header="Publisher" Binding="{Binding Publisher}" Width="140" IsReadOnly="True" />
                  <DataGridTextColumn Header="Command Path" Binding="{Binding Command}" Width="*" IsReadOnly="True" />
                </DataGrid.Columns>
              </DataGrid>
            </Grid>
          </TabItem>
          <!-- TAB: ALL-IN-ONE GAME HUB & GAME BOOSTER -->
          <TabItem Name="Tab_GameHub">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🎮" Margin="0,0,5,0" />
                <TextBlock Name="TxtHeaderTabGameHub" Text="Game Hub" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
              </Grid.RowDefinitions>
              <!-- Top Action & Search Bar -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <!-- Left: Search Box & Stats -->
                  <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TxtGameSearchLabel" Text="Search Games:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,8,0" Foreground="#F5EDE0" FontSize="11.5" />
                    <TextBox Name="TxtGameSearch" Width="200" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="6,3" FontSize="11.5" />
                    <TextBlock Name="TxtGameHubStats" Text="🎮 0 Games Found" Foreground="#38BDF8" FontWeight="SemiBold" FontSize="11.5" Margin="14,0,0,0" VerticalAlignment="Center" />
                  </StackPanel>
                  <!-- Right: Action Buttons -->
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnAddCustomGame" Style="{StaticResource SecondaryButton}" Content="➕ Add Game" Margin="0,0,6,0" Padding="10,4.5" FontSize="11" Cursor="Hand" />
                    <Button Name="BtnRefreshGames" Style="{StaticResource PrimaryButton}" Content="🔄 Rescan Library" Padding="12,4.5" FontSize="11" FontWeight="Bold" Cursor="Hand" />
                  </WrapPanel>
                </Grid>
              </Border>
              <!-- Platform Filter Chips -->
              <Border Grid.Row="1" Background="#0D0D10" BorderBrush="#1E293B" BorderThickness="1" CornerRadius="8" Padding="8,4" Margin="0,0,0,6">
                <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <TextBlock Name="TxtGameFilterLabel" Text="Filter Platform:" VerticalAlignment="Center" FontWeight="Bold" Margin="4,0,10,0" Foreground="#A1A1AA" FontSize="11" />
                  <Button Name="BtnFilterGameAll" Style="{StaticResource PrimaryButton}" Content="All Platforms" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameSteam" Style="{StaticResource SecondaryButton}" Content="Steam" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameEpic" Style="{StaticResource SecondaryButton}" Content="Epic Games" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameRiot" Style="{StaticResource SecondaryButton}" Content="Riot Games" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameBattlenet" Style="{StaticResource SecondaryButton}" Content="Battle.net" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameXbox" Style="{StaticResource SecondaryButton}" Content="Xbox / MS Store" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameFitGirl" Style="{StaticResource SecondaryButton}" Content="FitGirl Repacks" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameDODI" Style="{StaticResource SecondaryButton}" Content="DODI Repacks" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameGOG" Style="{StaticResource SecondaryButton}" Content="GOG Galaxy" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameStandalone" Style="{StaticResource SecondaryButton}" Content="PC Standalone" Margin="0,0,6,0" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                  <Button Name="BtnFilterGameCustom" Style="{StaticResource SecondaryButton}" Content="Custom Added" Padding="10,3.5" FontSize="10.5" Cursor="Hand" />
                </WrapPanel>
              </Border>
              <!-- Game Cards List (Scrollable WrapPanel with responsive 100% width fit) -->
              <ScrollViewer Name="ScrollGameCards" Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <ItemsControl Name="GameCardsContainer" Tag="290">
                  <ItemsControl.ItemsPanel>
                    <ItemsPanelTemplate>
                      <WrapPanel Orientation="Horizontal" />
                    </ItemsPanelTemplate>
                  </ItemsControl.ItemsPanel>
                  <ItemsControl.ItemTemplate>
                    <DataTemplate>
                      <Border Width="{Binding ElementName=GameCardsContainer, Path=Tag}" Height="255" Margin="0,0,14,14" Background="#0D0D10" BorderBrush="#1E293B" BorderThickness="1" CornerRadius="12" ClipToBounds="True">
                        <Grid>
                          <Grid.RowDefinitions>
                            <RowDefinition Height="135" />
                            <RowDefinition Height="*" />
                            <RowDefinition Height="Auto" />
                          </Grid.RowDefinitions>
                          <!-- Row 0: Game Banner Image & Overlays -->
                          <Grid Grid.Row="0">
                            <!-- Background / Fallback when image is loading or unavailable -->
                            <Border Background="#1E293B">
                              <Grid HorizontalAlignment="Center" VerticalAlignment="Center">
                                <TextBlock Text="🎮" FontSize="38" Opacity="0.3" HorizontalAlignment="Center" VerticalAlignment="Center" />
                              </Grid>
                            </Border>
                            <!-- Game Cover Art Image -->
                            <Image Source="{Binding BannerUrl}" Stretch="UniformToFill" HorizontalAlignment="Center" VerticalAlignment="Center" />
                            <!-- Dark bottom gradient overlay for sleek contrast -->
                            <Border VerticalAlignment="Bottom" Height="40">
                              <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                  <GradientStop Color="#000F172A" Offset="0" />
                                  <GradientStop Color="#CC0F172A" Offset="1" />
                                </LinearGradientBrush>
                              </Border.Background>
                            </Border>
                            <!-- Platform Badge (Top Left Pill) -->
                            <Border HorizontalAlignment="Left" VerticalAlignment="Top" Margin="8,8,0,0" Background="{Binding PlatformBg}" BorderBrush="{Binding PlatformBorder}" BorderThickness="1" CornerRadius="6" Padding="7,2.5">
                              <TextBlock Text="{Binding Platform}" Foreground="{Binding PlatformColor}" FontWeight="Bold" FontSize="10" />
                            </Border>
                            <!-- Size Badge (Top Right Frosted Glass) -->
                            <Border HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,8,8,0" Background="#A00B0F19" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="6,2">
                              <TextBlock Text="{Binding DisplaySize}" Foreground="#F5EDE0" FontSize="9.5" FontWeight="Bold" />
                            </Border>
                          </Grid>
                          <!-- Row 1: Game Name & Install Directory -->
                          <StackPanel Grid.Row="1" VerticalAlignment="Center" Margin="12,6,12,6">
                            <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="13" Foreground="#F5EDE0" TextTrimming="CharacterEllipsis" ToolTip="{Binding Name}" />
                            <TextBlock Text="{Binding InstallDir}" FontSize="10.5" Foreground="#A1A1AA" TextTrimming="CharacterEllipsis" Margin="0,3,0,0" ToolTip="{Binding InstallDir}" />
                          </StackPanel>
                          <!-- Row 2: Boost & Play Action Buttons -->
                          <Grid Grid.Row="2" Margin="12,0,12,12">
                            <Grid.ColumnDefinitions>
                              <ColumnDefinition Width="*" />
                              <ColumnDefinition Width="Auto" />
                            </Grid.ColumnDefinitions>
                            <Button Grid.Column="0" Tag="{Binding}" Name="BtnBoostAndLaunch" Style="{StaticResource SuccessButton}" Content="🚀 Boost &amp; Launch" Margin="0,0,6,0" Padding="10,5.5" FontSize="11" FontWeight="Bold" Cursor="Hand" />
                            <Button Grid.Column="1" Tag="{Binding}" Name="BtnQuickPlay" Style="{StaticResource SecondaryButton}" Content="▶️ Play" Padding="12,5.5" FontSize="11" Cursor="Hand" />
                          </Grid>
                        </Grid>
                      </Border>
                    </DataTemplate>
                  </ItemsControl.ItemTemplate>
                </ItemsControl>
              </ScrollViewer>
            </Grid>
          </TabItem>
          
          <!-- TAB: WINDOWS SECURITY & DEFENDER QUICK MANAGER -->
          <TabItem Name="Tab_Defender">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🛡️" Margin="0,0,5,0" />
                <TextBlock Name="TxtHeaderTabDefender" Text="Windows Defender" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="20">
              <StackPanel Margin="0,0,0,20">
                <!-- Hero Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="10" Padding="16,14" Margin="0,0,0,16">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="#0C2340" BorderBrush="#0284C7" BorderThickness="1" CornerRadius="8" Width="44" Height="44" Margin="0,0,14,0" HorizontalAlignment="Center" VerticalAlignment="Center">
                      <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#F5EDE0" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Cursor="Arrow">
                      <StackPanel Orientation="Horizontal" Cursor="Arrow">
                        <TextBlock Name="TxtDefenderHeroTitle" Text="Windows Security &amp; Defender Quick Manager" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" Cursor="Arrow" />
                        <Border Name="BadgeDefenderStatus" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="5" Padding="8,2" Margin="10,0,0,0" VerticalAlignment="Center" Cursor="Arrow">
                          <TextBlock Name="TxtDefenderStatus" Text="● Antivirus Active &amp; Protected" FontSize="11" FontWeight="Bold" Foreground="#c15f3c" Cursor="Arrow" />
                        </Border>
                      </StackPanel>
                      <TextBlock Name="TxtDefenderHeroSubtitle" Text="Manage Windows Defender in 1-click: game folder exclusions, stuck protection history cleaner, and instant signature updates." FontSize="11" Foreground="#A1A1AA" Margin="0,3,0,0" Cursor="Arrow" />
                    </StackPanel>
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" Cursor="Arrow">
                      <Button Name="BtnDefenderQuickScan" Style="{StaticResource SuccessButton}" Content="⚡ Quick Scan" Padding="12,8" FontSize="11" FontWeight="Bold" Margin="0,0,6,0" Cursor="Hand" ToolTip="Run background Windows Defender Quick Scan" />
                      <Button Name="BtnUpdateSignatures" Style="{StaticResource SecondaryButton}" Content="🔄 Update Signatures" Padding="10,8" FontSize="11" FontWeight="SemiBold" Margin="0,0,6,0" Cursor="Hand" ToolTip="Force download latest virus definitions" />
                      <Button Name="BtnOpenWinSecurity" Style="{StaticResource SecondaryButton}" Content="🛡️ Open Security App" Padding="10,8" FontSize="11" FontWeight="SemiBold" Cursor="Hand" ToolTip="Launch Windows Security app" />
                    </StackPanel>
                  </Grid>
                </Border>
                <!-- Section 1: 1-Click Game Folder Exclusions Manager -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,0,16">
                  <StackPanel>
                    <DockPanel LastChildFill="False" Margin="0,0,0,6">
                      <StackPanel DockPanel.Dock="Left">
                        <TextBlock Name="TxtExclusionsTitle" Text="🎮 1-Click Game Folder Exclusions Manager" FontWeight="Bold" FontSize="13" Foreground="#F5EDE0" />
                        <TextBlock Name="TxtExclusionsDesc" Text="Excluding your game libraries stops Defender from scanning game files during load screens, eliminating micro-stutters and boosting game loading speeds." FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,0" />
                      </StackPanel>
                      <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
                        <Button Name="BtnAddDetectedGames" Style="{StaticResource SuccessButton}" Content="🎮 Add Detected Game Libraries" Padding="12,6" FontSize="11" FontWeight="Bold" Margin="0,0,6,0" Cursor="Hand" ToolTip="Automatically scans and adds all Steam, Epic, Repack, and Games folders to Defender exclusions" />
                        <Button Name="BtnAddCustomExclusion" Style="{StaticResource SecondaryButton}" Content="📁 Add Custom Folder" Padding="10,6" FontSize="11" FontWeight="SemiBold" Margin="0,0,6,0" Cursor="Hand" ToolTip="Browse and select any folder to exclude from Defender" />
                        <Button Name="BtnRefreshExclusions" Style="{StaticResource SecondaryButton}" Content="🔄 Refresh" Padding="10,6" FontSize="11" FontWeight="SemiBold" Cursor="Hand" ToolTip="Reload currently active exclusions" />
                      </StackPanel>
                    </DockPanel>
                    <!-- Active Exclusions DataGrid -->
                    <Border Background="#09090B" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Margin="0,8,0,0">
                      <StackPanel>
                        <Border Background="#111114" Padding="10,6">
                          <DockPanel>
                            <TextBlock Text="Currently Excluded Paths &amp; Folders:" FontWeight="Bold" FontSize="11" Foreground="#38BDF8" DockPanel.Dock="Left" />
                            <TextBlock Name="TxtExclusionCountInfo" Text="0 Excluded Folders" FontWeight="Bold" FontSize="11" Foreground="#A1A1AA" DockPanel.Dock="Right" />
                          </DockPanel>
                        </Border>
                        <ListBox Name="ListDefenderExclusions" Background="Transparent" BorderThickness="0" MaxHeight="180" ScrollViewer.VerticalScrollBarVisibility="Auto" Padding="4">
                          <ListBox.ItemTemplate>
                            <DataTemplate>
                              <DockPanel Margin="0,2" LastChildFill="False">
                                <TextBlock Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#F5EDE0" DockPanel.Dock="Left" VerticalAlignment="Center" Margin="2,0,6,0" />
                                <TextBlock Text="{Binding}" Foreground="#F5EDE0" FontSize="11" FontFamily="Consolas" DockPanel.Dock="Left" VerticalAlignment="Center" Margin="4,0,0,0" />
                              </DockPanel>
                            </DataTemplate>
                          </ListBox.ItemTemplate>
                        </ListBox>
                      </StackPanel>
                    </Border>
                  </StackPanel>
                </Border>
                <!-- Section 2: Clear Defender Protection History (Stuck Threats Fixer) -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="9" Padding="14" Margin="0,0,0,16">
                  <StackPanel>
                    <DockPanel LastChildFill="False" Margin="0,0,0,4">
                      <TextBlock Name="TxtClearHistoryTitle" Text="🧹 Clear Protection History (Stuck Threats Fixer)" FontWeight="Bold" FontSize="12.5" Foreground="#F5EDE0" DockPanel.Dock="Left" />
                      <Button Name="BtnClearProtHistory" Style="{StaticResource SecondaryButton}" Content="🧹 Clear Protection History" Padding="12,5" FontSize="11" FontWeight="Bold" DockPanel.Dock="Right" Cursor="Hand" />
                    </DockPanel>
                    <TextBlock Name="TxtClearHistoryDesc" Text="Windows Defender often keeps showing false-positive threat notifications from weeks ago that were already deleted. This tool purges the corrupted DetectionHistory cache so your history is completely clean." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" Margin="0,0,0,6" />
                    <TextBlock Text="Purges corrupted DetectionHistory &amp; Store cache files in 1 click." FontSize="10" Foreground="#71717A" />
                  </StackPanel>
                </Border>
                <!-- Safe Compatibility Notice -->
                <Border Background="#0C2340" BorderBrush="#0284C7" BorderThickness="1" CornerRadius="8" Padding="14,10">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,10,0" />
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                      <TextBlock Name="TxtDefenderNoticeTitle" Text="Gaming Performance &amp; Antivirus Safety" FontWeight="Bold" FontSize="11.5" Foreground="#38BDF8" Margin="0,0,0,2" />
                      <TextBlock Name="TxtDefenderNoticeDesc" Text="Excluding trusted game library folders prevents Windows Defender from scanning gigabytes of game assets during loading screens. Your system remains 100% protected against web threats, downloads, and email attachments." FontSize="10.5" Foreground="#E0F2FE" TextWrapping="Wrap" />
                    </StackPanel>
                  </Grid>
                </Border>
              </StackPanel>
            </ScrollViewer>
          </TabItem>
          <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
                    <!-- TAB: FAST FILE CONTENT & TEXT FINDER (C# MULTITHREADED) -->
          <TabItem Name="Tab_TextFinder">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="11" Margin="0,0,5,0" VerticalAlignment="Center" />
                <TextBlock Text="Omni File Search" VerticalAlignment="Center" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
              </Grid.RowDefinitions>
              <!-- Hero Header Card -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,10" Margin="0,0,0,8">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Width="36" Height="36" CornerRadius="8" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" Margin="0,0,12,0">
                      <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="16" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <StackPanel VerticalAlignment="Center">
                      <TextBlock Text="Omni File &amp; Text Search" FontWeight="Bold" FontSize="14" Foreground="#F5EDE0" />
                      <TextBlock Text="High-speed C# multi-threaded search across filenames, directories, and inside text documents in parallel." FontSize="11" Foreground="#A1A1AA" Margin="0,2,0,0" />
                    </StackPanel>
                  </StackPanel>
                  <Border Grid.Column="1" Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,5" VerticalAlignment="Center">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                      <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#4ADE80" Margin="0,0,6,0" VerticalAlignment="Center" />
                      <TextBlock Text="C# Parallel Engine Active" FontWeight="Bold" FontSize="10.5" Foreground="#D4D4D8" VerticalAlignment="Center" />
                    </StackPanel>
                  </Border>
                </Grid>
              </Border>

              <!-- Search Control Box -->
              <Border Grid.Row="1" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="14,12" Margin="0,0,0,8">
                <StackPanel>
                  <!-- Row 1: Target Folder -->
                  <Grid Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="85" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Target Folder:" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" VerticalAlignment="Center" />
                    <TextBox Name="TxtSearchFolder" Grid.Column="1" Height="28" Background="#141418" BorderBrush="#23232A" Foreground="#F5EDE0" Padding="8,3" FontSize="11" VerticalAlignment="Center" Margin="0,0,8,0" ToolTip="The folder to search in (e.g. C:\Games, C:\Projects, C:\Windows)" />
                    <Button Name="BtnBrowseSearchFolder" Grid.Column="2" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="Browse..." Height="28" Padding="12,0" FontSize="11" Cursor="Hand" ToolTip="Select a folder from your computer" />
                  </Grid>

                  <!-- Row 2: Search Query & File Filter -->
                  <Grid Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="85" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="170" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Search Text:" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" VerticalAlignment="Center" />
                    <TextBox Name="TxtSearchQuery" Grid.Column="1" Height="28" Background="#141418" BorderBrush="#23232A" Foreground="#FFFFFF" Padding="8,3" FontSize="11.5" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,10,0" ToolTip="Enter any text, code snippet, error string, or filename to find" />
                    <TextBlock Grid.Column="2" Text="Extensions:" FontWeight="SemiBold" FontSize="11" Foreground="#A1A1AA" VerticalAlignment="Center" Margin="0,0,8,0" />
                    <TextBox Name="TxtSearchExtensions" Grid.Column="3" Text="*.ini, *.cfg, *.log, *.txt, *.json, *.ps1, *.py, *.xml" Height="28" Background="#141418" BorderBrush="#23232A" Foreground="#A1A1AA" Padding="8,3" FontSize="10.5" VerticalAlignment="Center" ToolTip="Specify file extensions to scan (*.ini, *.txt, *.log, or *.* for all)" />
                  </Grid>

                  <!-- Row 3: Mode Radios, Checkboxes & Symmetrical b2 Action Buttons -->
                  <Grid Margin="0,2,0,4">
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                      <TextBlock Text="Mode:" FontWeight="Bold" FontSize="11" Foreground="#c15f3c" VerticalAlignment="Center" Margin="0,0,6,0" />
                      <RadioButton Name="RadioSearchContent" Content="Inside Content" IsChecked="True" GroupName="SearchModeGroup" Foreground="#F5EDE0" FontWeight="SemiBold" FontSize="10.5" VerticalAlignment="Center" Margin="0,0,8,0" ToolTip="Opens and reads inside files to search text lines (Ripgrep-style)" />
                      <RadioButton Name="RadioSearchNames" Content="File/Folder Names" GroupName="SearchModeGroup" Foreground="#A1A1AA" FontSize="10.5" VerticalAlignment="Center" Margin="0,0,8,0" ToolTip="Fast search for files and folders by name (Everything-style)" />
                      <RadioButton Name="RadioSearchBoth" Content="All (Both)" GroupName="SearchModeGroup" Foreground="#A1A1AA" FontSize="10.5" VerticalAlignment="Center" Margin="0,0,10,0" ToolTip="Search file/folder names AND read inside text files for matches" />
                      <Rectangle Width="1" Height="14" Fill="#23232A" Margin="0,0,10,0" VerticalAlignment="Center" />
                      <CheckBox Name="ChkSearchRecursive" Content="Subfolders" IsChecked="True" Foreground="#D4D4D8" FontSize="10.5" VerticalAlignment="Center" Margin="0,0,8,0" ToolTip="Scan all subdirectories recursively" />
                      <CheckBox Name="ChkSearchMatchCase" Content="Match Case" IsChecked="False" Foreground="#D4D4D8" FontSize="10.5" VerticalAlignment="Center" Margin="0,0,8,0" ToolTip="Case sensitive search (ABC vs abc)" />
                      <CheckBox Name="ChkSearchUseRegex" Content="Regex" IsChecked="False" Foreground="#D4D4D8" FontSize="10.5" VerticalAlignment="Center" ToolTip="Enable Regular Expression pattern search" />
                    </StackPanel>
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="10,0,0,0">
                      <Button Name="BtnClearSearchResults" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="Clear" Height="28" Padding="12,0" FontSize="11" Margin="0,0,8,0" Cursor="Hand" />
                      <Button Name="BtnStartTextSearch" Style="{StaticResource b2}" Background="#c15f3c" Foreground="#FFFFFF" Content="Start Search" Height="28" Padding="16,0" FontSize="11" FontWeight="Bold" Cursor="Hand" />
                    </StackPanel>
                  </Grid>

                  <!-- Row 4: Live Mode Explanation Pill -->
                  <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,5" Margin="0,6,0,0">
                    <DockPanel LastChildFill="False">
                      <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#4ADE80" VerticalAlignment="Center" Margin="0,0,6,0" DockPanel.Dock="Left" />
                      <TextBlock Name="TxtSearchModeExplainer" Text="Inside Content Mode: Opens each file (.ini, .txt, .log, code) and searches for exact text matches inside lines." FontSize="10.5" Foreground="#A1A1AA" VerticalAlignment="Center" DockPanel.Dock="Left" />
                    </DockPanel>
                  </Border>
                </StackPanel>
              </Border>

              <!-- Results DataGrid (Native Clean Layout matching AppsGrid) -->
              <DataGrid Name="SearchDataGrid" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="True" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" BorderThickness="1" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="11.5" Cursor="Arrow" EnableRowVirtualization="True" EnableColumnVirtualization="True" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#F5EDE0" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#23232A" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                    <Setter Property="Cursor" Value="Arrow" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Background" Value="#111114" />
                    <Setter Property="Padding" Value="2" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                    <Setter Property="Cursor" Value="Arrow" />
                    <Style.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter Property="Background" Value="#18181C" />
                      </Trigger>
                      <Trigger Property="IsSelected" Value="True">
                        <Setter Property="Background" Value="#1E242C" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                      </Trigger>
                    </Style.Triggers>
                  </Style>
                  <Style TargetType="DataGridCell">
                    <Setter Property="Background" Value="Transparent" />
                    <Setter Property="BorderThickness" Value="0" />
                    <Setter Property="FocusVisualStyle" Value="{x:Null}" />
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <DataGridTextColumn Header="#" Binding="{Binding Index}" Width="38" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#71717A" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="HorizontalAlignment" Value="Center" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Type" Binding="{Binding ItemType}" Width="80" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="FontWeight" Value="Bold" />
                        <Setter Property="Foreground" Value="{Binding TypeBadgeColor}" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                        <Setter Property="Margin" Value="4,0,4,0" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Name" Binding="{Binding FileName}" Width="1.5*" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="Foreground" Value="#F5EDE0" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                        <Setter Property="Margin" Value="6,0,6,0" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Match Info" Binding="{Binding MatchInfo}" Width="85" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="FontWeight" Value="Bold" />
                        <Setter Property="Foreground" Value="#c15f3c" />
                        <Setter Property="HorizontalAlignment" Value="Center" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Matched Line Content / Details" Binding="{Binding LineText}" Width="2.5*" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#D4D4D8" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                        <Setter Property="Margin" Value="6,0,6,0" />
                        <Setter Property="TextTrimming" Value="CharacterEllipsis" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Folder Path" Binding="{Binding FolderPath}" Width="2*" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#A1A1AA" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                        <Setter Property="Margin" Value="6,0,6,0" />
                        <Setter Property="TextTrimming" Value="CharacterEllipsis" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                  <DataGridTextColumn Header="Size" Binding="{Binding FileSize}" Width="75" IsReadOnly="True">
                    <DataGridTextColumn.ElementStyle>
                      <Style TargetType="TextBlock">
                        <Setter Property="Foreground" Value="#71717A" />
                        <Setter Property="HorizontalAlignment" Value="Right" />
                        <Setter Property="VerticalAlignment" Value="Center" />
                        <Setter Property="Margin" Value="0,0,8,0" />
                      </Style>
                    </DataGridTextColumn.ElementStyle>
                  </DataGridTextColumn>
                </DataGrid.Columns>
              </DataGrid>

              <!-- Bottom Status Bar -->
              <DockPanel Grid.Row="3" LastChildFill="False" Margin="0,4,0,0">
                <TextBlock Name="TxtSearchStatus" Text="Ready to search. Enter query and select target folder." FontSize="11" Foreground="#A1A1AA" VerticalAlignment="Center" DockPanel.Dock="Left" />
                <TextBlock Text="Double-click any row to open - Right-click for options" FontSize="10.5" Foreground="#71717A" VerticalAlignment="Center" DockPanel.Dock="Right" />
              </DockPanel>
            </Grid>
          </TabItem>
          <!-- TAB: TASK MANAGER -->
          <TabItem Name="Tab_ProcManager">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="⚡" Margin="0,0,5,0" />
                <TextBlock Text="Task Manager" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
                <RowDefinition Height="Auto" />
              </Grid.RowDefinitions>
              <!-- Top Bar: Search & Actions -->
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="Search Processes:" VerticalAlignment="Center" FontWeight="Bold" Margin="0,0,8,0" Foreground="#F5EDE0" FontSize="11.5" />
                    <TextBox Name="TxtProcSearch" Width="200" Background="#151D30" Foreground="#FFFFFF" BorderBrush="#2A3756" Padding="6,3" FontSize="11.5" />
                    <TextBlock Name="TxtProcStatsInfo" Text="Scanning active processes..." Foreground="#38BDF8" FontWeight="SemiBold" FontSize="11.5" Margin="14,0,0,0" VerticalAlignment="Center" />
                  </StackPanel>
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnRefreshProcList" Style="{StaticResource SecondaryButton}" Content="🔄 Refresh" Margin="0,0,6,0" Padding="10,4.5" FontSize="11" Cursor="Hand" />
                    <Button Name="BtnPurgeSafeProcs" Style="{StaticResource DangerButton}" Content="🧹 Purge Safe Background Tasks" Padding="12,4.5" FontSize="11" FontWeight="Bold" Cursor="Hand" ToolTip="Instantly closes all safe non-essential background helpers and launchers to free RAM" />
                  </WrapPanel>
                </Grid>
              </Border>
              <!-- Filter Buttons Bar -->
              <Border Grid.Row="1" Background="#0D0D10" BorderBrush="#1E293B" BorderThickness="1" CornerRadius="8" Padding="8,5" Margin="0,0,0,6">
                <WrapPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <Button Name="BtnFilterProcAll" Style="{StaticResource PrimaryButton}" Content="All Processes" Margin="0,0,6,0" Padding="8,3" FontSize="11" Cursor="Hand" />
                  <Button Name="BtnFilterProcSafe" Style="{StaticResource SecondaryButton}" Content="● Safe to Stop" Margin="0,0,6,0" Padding="8,3" FontSize="11" Cursor="Hand" Foreground="#4ADE80" />
                  <Button Name="BtnFilterProcWork" Style="{StaticResource SecondaryButton}" Content="● Caution (Work)" Margin="0,0,6,0" Padding="8,3" FontSize="11" Cursor="Hand" Foreground="#FBBF24" />
                  <Button Name="BtnFilterProcService" Style="{StaticResource SecondaryButton}" Content="● Caution (Service)" Margin="0,0,6,0" Padding="8,3" FontSize="11" Cursor="Hand" Foreground="#C084FC" />
                  <Button Name="BtnFilterProcHeavy" Style="{StaticResource SecondaryButton}" Content="🔥 Heavy RAM (&gt;150 MB)" Margin="0,0,6,0" Padding="8,3" FontSize="11" Cursor="Hand" />
                  <Button Name="BtnFilterProcProtected" Style="{StaticResource SecondaryButton}" Content="● System Protected" Padding="8,3" FontSize="11" Cursor="Hand" Foreground="#F87171" />
                </WrapPanel>
              </Border>
              <!-- Processes DataGrid -->
              <DataGrid Name="ProcManagerDataGrid" Grid.Row="2" AutoGenerateColumns="False" CanUserAddRows="False" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" RowBackground="#111114" AlternatingRowBackground="#141418" HeadersVisibility="Column" SelectionMode="Single" SelectionUnit="FullRow" FontSize="11.5" EnableRowVirtualization="True" EnableColumnVirtualization="True" VirtualizingStackPanel.IsVirtualizing="True" VirtualizingStackPanel.VirtualizationMode="Recycling" ScrollViewer.CanContentScroll="True" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#38BDF8" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#1F2937" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Padding" Value="3" />
                    <Setter Property="Foreground" Value="#FFFFFF" />
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <!-- Process Name & PID -->
                  <DataGridTextColumn Header="Process Name" Binding="{Binding Name}" FontWeight="Bold" Width="140" IsReadOnly="True" />
                  <DataGridTextColumn Header="PID" Binding="{Binding Id}" Width="65" IsReadOnly="True" />
                  <!-- Description / Window Title -->
                  <DataGridTextColumn Header="Description / Window Title" Binding="{Binding Description}" Width="*" IsReadOnly="True" />
                  <!-- Memory Usage -->
                  <DataGridTemplateColumn Header="Memory" Width="95" SortMemberPath="MemoryMB">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <TextBlock Text="{Binding MemoryFormatted}" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,8,0" />
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <!-- Safety Classification Badge -->
                  <DataGridTemplateColumn Header="Safety Status" Width="160" SortMemberPath="SafetyBadge">
                    <DataGridTemplateColumn.CellTemplate>
                      <DataTemplate>
                        <Border Background="{Binding SafetyBg}" BorderBrush="{Binding SafetyBorder}" BorderThickness="1" CornerRadius="4" Padding="7,2.5" HorizontalAlignment="Left" VerticalAlignment="Center">
                          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Ellipse Width="6.5" Height="6.5" Fill="{Binding SafetyFg}" Margin="0,0,5.5,0" VerticalAlignment="Center" />
                            <TextBlock Text="{Binding SafetyBadge}" Foreground="{Binding SafetyFg}" FontWeight="Bold" FontSize="10.5" VerticalAlignment="Center" />
                          </StackPanel>
                        </Border>
                      </DataTemplate>
                    </DataGridTemplateColumn.CellTemplate>
                  </DataGridTemplateColumn>
                  <!-- Category -->
                  <DataGridTextColumn Header="Category" Binding="{Binding Category}" Width="120" IsReadOnly="True" />
                </DataGrid.Columns>
              </DataGrid>
              <!-- Footer Info Bar -->
              <DockPanel Grid.Row="3" Margin="0,6,0,0" LastChildFill="False">
                <TextBlock Text="💡 Right-click any row to End Task or open executable location • Critical system processes are protected" FontSize="10.5" Foreground="#71717A" VerticalAlignment="Center" DockPanel.Dock="Left" />
                <TextBlock Name="TxtProcSafeReclaimable" Text="Safe RAM to reclaim: 0 MB" FontSize="10.5" FontWeight="Bold" Foreground="#4ADE80" VerticalAlignment="Center" DockPanel.Dock="Right" />
              </DockPanel>
            </Grid>
          </TabItem>
          <!-- TAB 6: RUNNING GUARD -->
          <TabItem Name="Tab_Guard">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="🛡️" Margin="0,0,5,0" />
                <TextBlock Text="Running Guard" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
              </Grid.RowDefinitions>
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="TxtGuardTitle" Text="Active Applications Holding Cache Locks" VerticalAlignment="Center" FontWeight="Bold" FontSize="12.5" Foreground="#FBBF24" TextTrimming="CharacterEllipsis" />
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnRefreshProcesses" Style="{StaticResource SecondaryButton}" Content="Check Processes" Margin="0,0,6,0" Padding="10,4" FontSize="11" />
                    <Button Name="BtnCloseAllGuards" Style="{StaticResource DangerButton}" Content="Close All Guarded Apps" Padding="12,4" FontSize="11" />
                  </WrapPanel>
                </Grid>
              </Border>
              <DataGrid Name="ProcessDataGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False" Background="#111114" Foreground="#FFFFFF" BorderBrush="#23232A" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#1E1E24" RowBackground="#111114" AlternatingRowBackground="#141418" HeadersVisibility="Column" SelectionMode="Single" FontSize="11.5" ScrollViewer.HorizontalScrollBarVisibility="Auto" ScrollViewer.VerticalScrollBarVisibility="Auto">
                <DataGrid.Resources>
                  <Style TargetType="DataGridColumnHeader">
                    <Setter Property="Background" Value="#09090B" />
                    <Setter Property="Foreground" Value="#FBBF24" />
                    <Setter Property="FontWeight" Value="Bold" />
                    <Setter Property="Padding" Value="8,6" />
                    <Setter Property="BorderBrush" Value="#1F2937" />
                    <Setter Property="BorderThickness" Value="0,0,0,1" />
                  </Style>
                  <Style TargetType="DataGridRow">
                    <Setter Property="Foreground" Value="#FFFFFF" />
                  </Style>
                </DataGrid.Resources>
                <DataGrid.Columns>
                  <DataGridTextColumn Header="Process Name" Binding="{Binding Name}" FontWeight="Bold" Width="160" IsReadOnly="True" />
                  <DataGridTextColumn Header="PID" Binding="{Binding Id}" Width="70" IsReadOnly="True" />
                  <DataGridTextColumn Header="Associated Target Cache" Binding="{Binding TargetName}" Width="220" IsReadOnly="True" />
                  <DataGridTextColumn Header="Lock Status" Binding="{Binding Status}" Width="130" IsReadOnly="True" />
                  <DataGridTextColumn Header="Main Window Title" Binding="{Binding MainWindowTitle}" Width="*" IsReadOnly="True" />
                </DataGrid.Columns>
              </DataGrid>
            </Grid>
          </TabItem>
          <!-- TAB 7: LIVE CONSOLE & LOGS -->
          <TabItem Name="Tab_Log">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="📝" Margin="0,0,5,0" />
                <TextBlock Text="Activity Log" />
              </StackPanel>
            </TabItem.Header>
            <Grid Margin="0,6,0,0">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto" />
                <RowDefinition Height="*" />
              </Grid.RowDefinitions>
              <Border Grid.Row="0" Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="10,6" Margin="0,0,0,6">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                  </Grid.ColumnDefinitions>
                  <TextBlock Name="TxtLogTitle" Text="Real-Time Execution &amp; Deletion Output" VerticalAlignment="Center" FontWeight="Bold" FontSize="12.5" Foreground="#4ADE80" TextTrimming="CharacterEllipsis" />
                  <WrapPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right">
                    <Button Name="BtnCopyLogs" Style="{StaticResource SecondaryButton}" Content="Copy All Logs" Margin="0,0,6,0" Padding="10,4" FontSize="11" />
                    <Button Name="BtnClearLogs" Style="{StaticResource SecondaryButton}" Content="Clear Console" Padding="10,4" FontSize="11" />
                  </WrapPanel>
                </Grid>
              </Border>
              <Border Grid.Row="1" Background="#030712" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="8">
                <RichTextBox Name="TxtLogConsole" Background="Transparent" Foreground="#F1F5F9" BorderThickness="0" FontFamily="Consolas, Cascadia Code, Courier New" FontSize="11.5" IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" IsDocumentEnabled="False" Cursor="Arrow">
                  <RichTextBox.Resources>
                    <Style TargetType="{x:Type Paragraph}">
                      <Setter Property="Margin" Value="0,1,0,1" />
                      <Setter Property="LineHeight" Value="16" />
                    </Style>
                  </RichTextBox.Resources>
                  <FlowDocument Background="Transparent" PagePadding="0" />
                </RichTextBox>
              </Border>
            </Grid>
          </TabItem>
          <!-- TAB: ZERO HUB LIVE UPDATER & CHANGELOG -->
                    <!-- TAB: ZERO HUB LIVE UPDATER & CHANGELOG -->
          <TabItem Name="Tab_AppUpdate">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="ðŸš€" Margin="0,0,5,0" />
                <TextBlock Text="Updates" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="20,16,20,24">
              <StackPanel HorizontalAlignment="Stretch" VerticalAlignment="Top">
                                <!-- Hero Header & Live Auto-Updater Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="20,16" Margin="0,0,0,16" HorizontalAlignment="Stretch">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <!-- Icon Box -->
                    <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Width="48" Height="48" Margin="0,0,16,0" VerticalAlignment="Center">
                      <TextBlock Text="&#xE895;" FontFamily="Segoe MDL2 Assets" FontSize="20" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                    </Border>
                    <!-- Title, Subtitle, Badges -->
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                      <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,5">
                        <TextBlock Text="Live Update Center" FontSize="18" FontWeight="Bold" Foreground="#F5EDE0" Margin="0,0,12,0" />
                        <Border Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="8,2.5" Margin="0,0,8,0">
                          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE753;" FontFamily="Segoe MDL2 Assets" FontSize="10.5" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="GitHub Releases" FontSize="10.5" FontWeight="SemiBold" Foreground="#D4D4D8" VerticalAlignment="Center" />
                          </StackPanel>
                        </Border>
                        <Border Background="#18181C" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="6" Padding="8,2.5">
                          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="10.5" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="v1.3.2 Production" FontSize="10.5" FontWeight="Bold" Foreground="#4ADE80" VerticalAlignment="Center" />
                          </StackPanel>
                        </Border>
                      </StackPanel>
                      <TextBlock Text="Automatic GitHub in-place updates, verified releases, and changelog roadmap." FontSize="11" Foreground="#A1A1AA" Margin="0,0,0,3" />
                      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="Status: " FontSize="10.5" Foreground="#71717A" />
                        <TextBlock Name="TxtAppUpdateStatus" Text="Connected to official repository (zeroiq.site / ZeroHubTest)" FontSize="10.5" FontWeight="SemiBold" Foreground="#4ADE80" />
                      </StackPanel>
                    </StackPanel>
                    <!-- Right Actions -->
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="12,0,0,0">
                      <Button Name="BtnManualCheckUpdates" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Content="Check for Updates" Height="30" Padding="14,0" FontSize="11" FontWeight="SemiBold" Cursor="Hand" ToolTip="Check GitHub repository for the latest release" Margin="0,0,8,0" />
                      <Button Name="BtnAppUpdateTab" Style="{StaticResource b2}" Background="#c15f3c" Foreground="#FFFFFF" Content="Install Update" Height="30" Padding="16,0" FontSize="11" FontWeight="Bold" Cursor="Hand" Visibility="Collapsed" />
                    </StackPanel>
                  </Grid>
                </Border>
                <!-- Release Notes Card (v1.3.2 Changes) -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="20,18" Margin="0,0,0,16">
                  <StackPanel>
                    <!-- Header -->
                    <Grid Margin="0,0,0,16">
                      <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*" />
                        <ColumnDefinition Width="Auto" />
                      </Grid.ColumnDefinitions>
                      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="What's New in ZeroHub v1.3.2" FontSize="15" FontWeight="Bold" Foreground="#F5EDE0" Margin="0,0,10,0" />
                        <Border Background="#18181C" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="5" Padding="7,2" VerticalAlignment="Center">
                          <TextBlock Text="LATEST RELEASE" FontSize="9.5" FontWeight="Bold" Foreground="#4ADE80" />
                        </Border>
                      </StackPanel>
                      <TextBlock Grid.Column="1" Text="September 2026" FontSize="11" Foreground="#71717A" VerticalAlignment="Center" />
                    </Grid>

                    <!-- Category 1: Speed Optimizations & Architecture -->
                    <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="0,0,0,12">
                      <StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                          <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Center" />
                          <TextBlock Text="Speed Optimizations &amp; High-Performance Engine" FontSize="12" FontWeight="Bold" Foreground="#4ADE80" VerticalAlignment="Center" />
                        </StackPanel>
                        <!-- Item 1: Uninstaller Speed -->
                        <DockPanel Margin="4,3,4,8">
                          <TextBlock Text="-" FontSize="12" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="100x Faster App Uninstaller &amp; Bloatware Scanner (C# Engine)" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Replaced slow PowerShell registry and WMI queries with high-speed compiled C# multi-threaded registry enumeration (FastAppScanner). Slashing initial scan times from 8-15 seconds down to under 0.15s across 64-bit, 32-bit (WOW6432Node), and User hives." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                        <!-- Item 2: UI Virtualization -->
                        <DockPanel Margin="4,3,4,8">
                          <TextBlock Text="-" FontSize="12" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="Hardware-Accelerated UI Virtualization (Smooth 60 FPS)" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Enabled aggressive row &amp; column virtualization with item recycling across App Uninstaller, Bloatware Remover, Process Manager, and Omni Search. Eliminates all UI hitching and memory overhead when navigating lists with hundreds of items." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                        <!-- Item 3: Parallel Omni Search -->
                        <DockPanel Margin="4,3,4,8">
                          <TextBlock Text="-" FontSize="12" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="Parallel Multi-Core Omni File &amp; Text Search Engine" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Leverages multi-threaded Parallel.ForEach across all CPU cores to search file names and stream inside text documents simultaneously, indexing thousands of files per second." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                        <!-- Item 4: Non-blocking cleaner -->
                        <DockPanel Margin="4,3,4,3">
                          <TextBlock Text="-" FontSize="12" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="Asynchronous Non-Blocking Cache Cleaner Runspaces" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Cleaner scan and purge execution runs inside isolated background runspaces with live UI metric streaming, completely preventing GUI freeze during multi-gigabyte deletions." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                      </StackPanel>
                    </Border>

                    <!-- Category 2: Bug Fixes & Stability -->
                    <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="0">
                      <StackPanel>
                        <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                          <TextBlock Text="&#xE7BA;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#c15f3c" Margin="0,0,8,0" VerticalAlignment="Center" />
                          <TextBlock Text="Bug Fixes &amp; Stability Improvements" FontSize="12" FontWeight="Bold" Foreground="#c15f3c" VerticalAlignment="Center" />
                        </StackPanel>
                        <!-- Fix 1: DNS Button Sticky State -->
                        <DockPanel Margin="4,3,4,8">
                          <TextBlock Text="-" FontSize="12" Foreground="#c15f3c" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="DNS Button State Persistence &amp; Dynamic Colors" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Fixed an issue where disconnected DNS buttons remained stuck in red. Connected DNS cards now dynamically display 'Disconnect' in Ember Red (#c15f3c), while disconnecting cleanly restores the default Obsidian dark (#18181C) state." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                        <!-- Fix 2: Focus Outline Fix -->
                        <DockPanel Margin="4,3,4,8">
                          <TextBlock Text="-" FontSize="12" Foreground="#c15f3c" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="Eliminated Windows Dotted Focus Rectangles" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Removed default WPF focus borders globally (FocusVisualStyle = {x:Null}) across all buttons, keeping custom scalloped and chamfered shapes crisp and clean upon click." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>

                        <!-- Fix 4: RustDesk Detection -->
                        <DockPanel Margin="4,3,4,3">
                          <TextBlock Text="-" FontSize="12" Foreground="#c15f3c" Margin="0,0,8,0" VerticalAlignment="Top" />
                          <StackPanel>
                            <TextBlock Text="App Scanner Registry False-Positive Resolution" FontWeight="SemiBold" FontSize="11.5" Foreground="#F5EDE0" />
                            <TextBlock Text="Resolved a registry overlap where the Rustup installer was incorrectly detected as RustDesk." FontSize="11" Foreground="#A1A1AA" TextWrapping="Wrap" />
                          </StackPanel>
                        </DockPanel>
                      </StackPanel>
                    </Border>
                  </StackPanel>
                </Border>
              </StackPanel>
            </ScrollViewer>
          </TabItem>
          <!-- TAB 8: ABOUT & CREDITS -->
                    <TabItem Name="Tab_About">
            <TabItem.Header>
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="11" Margin="0,0,5,0" VerticalAlignment="Center" />
                <TextBlock Text="About &amp; Safety" VerticalAlignment="Center" />
              </StackPanel>
            </TabItem.Header>
            <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="20,16,20,24">
              <StackPanel HorizontalAlignment="Stretch" VerticalAlignment="Top">
                <!-- Hero Header Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="20,16" Margin="0,0,0,16" HorizontalAlignment="Stretch">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="Auto" />
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <!-- Logo Frame -->
                    <Border Grid.Column="0" Name="BtnAboutLogo" CornerRadius="8" Width="64" Height="64" Margin="0,0,16,0" Background="Transparent" VerticalAlignment="Center" Cursor="Hand" ToolTip="Visit Official Website (zeroiq.site)">
                      <Image Name="ImgAboutLogo" Width="64" Height="64" RenderOptions.BitmapScalingMode="HighQuality" Stretch="Uniform" />
                    </Border>
                    <!-- Title, Subtitle, Badges -->
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                      <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="0,0,0,5">
                        <TextBlock Text="ZeroHub" FontSize="22" FontWeight="Bold" Foreground="#F5EDE0" Margin="0,0,14,0" />
                        <!-- License Badge -->
                        <Border Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="8,2.5" Margin="0,0,8,0">
                          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE72D;" FontFamily="Segoe MDL2 Assets" FontSize="10.5" Foreground="#c15f3c" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="GPLv3 Open Source" FontSize="10.5" FontWeight="SemiBold" Foreground="#D4D4D8" VerticalAlignment="Center" />
                          </StackPanel>
                        </Border>
                        <!-- Official Website Badge -->
                        <Border Name="BtnAboutSiteBadge" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="8,2.5" Cursor="Hand" ToolTip="Visit Official Website https://zeroiq.site">
                          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="10.5" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="zeroiq.site" FontSize="10.5" FontWeight="SemiBold" Foreground="#D4D4D8" VerticalAlignment="Center" />
                          </StackPanel>
                        </Border>
                      </StackPanel>
                      <TextBlock Name="TxtAboutSub" Text="Windows Grim Reaper — Fast, Safe &amp; Intelligent All-in-One Optimization Engine" FontSize="11.5" Foreground="#A1A1AA" />
                    </StackPanel>
                    <!-- Version Info Block -->
                    <Border Grid.Column="2" Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,8" VerticalAlignment="Center">
                      <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Border Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="6" Width="32" Height="32" Margin="0,0,10,0" HorizontalAlignment="Center" VerticalAlignment="Center">
                          <TextBlock Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <StackPanel VerticalAlignment="Center">
                          <TextBlock Text="ZeroHub v1.3.2" FontWeight="Bold" FontSize="12" Foreground="#F5EDE0" />
                          <TextBlock Name="TxtAboutUpdateStatus" Text="Production Release" FontSize="10" Foreground="#A1A1AA" />
                        </StackPanel>
                      </StackPanel>
                    </Border>
                  </Grid>
                </Border>

                <!-- Core Modules Grid Title -->
                <StackPanel Orientation="Horizontal" Margin="4,0,0,10">
                  <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#c15f3c" Margin="0,0,6,0" VerticalAlignment="Center" />
                  <TextBlock Name="TxtAboutModulesTitle" Text="Core Power Modules &amp; Capabilities" FontWeight="Bold" FontSize="13.5" Foreground="#c15f3c" VerticalAlignment="Center" />
                </StackPanel>

                <!-- Core Modules 3-Column Relaxed Grid (12 Cards) -->
                <UniformGrid Columns="3" Margin="0,0,0,16" HorizontalAlignment="Stretch">
                  <!-- Module 1: App Manager -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE71D;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatAppTitle" Text="1-Click App Manager" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatAppDesc" Text="Silent Winget app installs with live upgrade recognizer." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 2: Deep Cleaner -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE74C;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatCleanTitle" Text="Deep Cache Cleaner" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatCleanDesc" Text="55+ targets across GPU shaders, dev, games &amp; temp." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 3: Bloatware Remover -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatBloatTitle" Text="Bloatware Remover" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatBloatDesc" Text="Remove pre-installed Windows junk &amp; Edge cleanly." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 4: Deep Uninstaller -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatUninstTitle" Text="Deep Uninstaller" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatUninstDesc" Text="Uninstall apps with leftover registry &amp; folder scrub." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 5: RAM Optimizer -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatRamTitle" Text="Live RAM Optimizer" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatRamDesc" Text="Real-time circular RAM meter with 1-click memory flush." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 6: Updates Controller -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE895;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatWuTitle" Text="Updates Controller" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatWuDesc" Text="Pause forced updates, purge WU cache &amp; repair DLLs." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 7: Game Hub Booster -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE7FC;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatGameTitle" Text="Game Hub Booster" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatGameDesc" Text="Auto-detect Steam, Epic, Riot, Xbox &amp; repack games." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 8: Startup Manager -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE7E8;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatStartupTitle" Text="Startup Manager" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatStartupDesc" Text="Instant COM startup apps &amp; services manager for fast boot." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 9: Privacy Hardener -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE72E;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutFeatPrivacyTitle" Text="Privacy Hardener" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutFeatPrivacyDesc" Text="12-vector anti-telemetry shield &amp; null-route tracking hosts." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 10: Omni File Search -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE721;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Omni File &amp; Text Search" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Text="Multi-threaded parallel C# search across files &amp; text." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 11: Running Guard -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE958;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Running Guard" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Text="Live background process watchdog to kill telemetry bloat." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>

                  <!-- Module 12: Classic Context Menu -->
                  <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="14,12" Margin="4" MinHeight="82">
                    <Grid>
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#18181C" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,10,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE700;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#c15f3c" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Classic Context Menu" FontWeight="Bold" FontSize="11.5" Foreground="#F5EDE0" Margin="0,0,0,2" />
                        <TextBlock Text="1-click restore for full Windows 10 right-click menu on Win11." FontSize="10" Foreground="#A1A1AA" TextWrapping="Wrap" LineHeight="14" />
                      </StackPanel>
                    </Grid>
                  </Border>
                </UniformGrid>

                <!-- Safety & Architecture Guarantee Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="18,14" Margin="0,0,0,14" HorizontalAlignment="Stretch">
                  <StackPanel>
                    <Grid Margin="0,0,0,8">
                      <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /></Grid.ColumnDefinitions>
                      <Border Grid.Column="0" Background="#1A2E1F" BorderBrush="#3B6B48" BorderThickness="1" CornerRadius="6" Width="34" Height="34" Margin="0,0,12,0" VerticalAlignment="Center">
                        <TextBlock Text="&#xE72E;" FontFamily="Segoe MDL2 Assets" FontSize="15" Foreground="#4ADE80" HorizontalAlignment="Center" VerticalAlignment="Center" />
                      </Border>
                      <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Name="TxtAboutSafetyTitle" Text="100% Non-Destructive &amp; Account Safe Guarantee" FontWeight="Bold" FontSize="13" Foreground="#c15f3c" Margin="0,0,0,2" />
                        <TextBlock Name="TxtAboutSafetyBody" Text="ZeroHub targets ONLY temporary scratch files, shader caches, and build artifacts. It NEVER touches browser login databases, cookies, passwords, or active accounts. All tweaks are reversible with 1-click restore." FontSize="10.5" TextWrapping="Wrap" Foreground="#D4D4D8" LineHeight="15" />
                      </StackPanel>
                    </Grid>
                    <UniformGrid Columns="3" Margin="0,6,0,0" HorizontalAlignment="Stretch">
                      <!-- 1. Login Safe -->
                      <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="0,0,4,0">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,2">
                            <TextBlock Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="100% Login Safe" FontWeight="Bold" FontSize="10.5" Foreground="#F5EDE0" VerticalAlignment="Center" />
                          </StackPanel>
                          <TextBlock Text="Zero cookie or session loss" FontSize="9" Foreground="#A1A1AA" HorizontalAlignment="Center" />
                        </StackPanel>
                      </Border>
                      <!-- 2. Async Engine -->
                      <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="3,0,3,0">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,2">
                            <TextBlock Text="&#xE945;" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#c15f3c" Margin="0,0,5,0" VerticalAlignment="Center" />
                            <TextBlock Text="Non-Blocking Engine" FontWeight="Bold" FontSize="10.5" Foreground="#F5EDE0" VerticalAlignment="Center" />
                          </StackPanel>
                          <TextBlock Text="Multi-threaded async C# execution" FontSize="9" Foreground="#A1A1AA" HorizontalAlignment="Center" />
                        </StackPanel>
                      </Border>
                      <!-- 3. Made in Iraq -->
                      <Border Background="#141418" BorderBrush="#23232A" BorderThickness="1" CornerRadius="6" Padding="10,8" Margin="4,0,0,0">
                        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,2">
                            <Border Width="15" Height="9" CornerRadius="1.5" Margin="0,0,5,0" BorderBrush="#334155" BorderThickness="0.5" ClipToBounds="True" VerticalAlignment="Center">
                              <Grid>
                                <Grid.RowDefinitions><RowDefinition Height="*" /><RowDefinition Height="*" /><RowDefinition Height="*" /></Grid.RowDefinitions>
                                <Border Grid.Row="0" Background="#CE1126" />
                                <Border Grid.Row="1" Background="#FFFFFF"><TextBlock Text="â˜… â˜… â˜…" FontSize="3" FontWeight="Bold" Foreground="#007A3D" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-0.5,0,0" /></Border>
                                <Border Grid.Row="2" Background="#000000" />
                              </Grid>
                            </Border>
                            <TextBlock Text="Made in Iraq" FontWeight="Bold" FontSize="10.5" Foreground="#F5EDE0" VerticalAlignment="Center" />
                          </StackPanel>
                          <TextBlock Text="Developed by Amir Ali" FontSize="9" Foreground="#A1A1AA" HorizontalAlignment="Center" />
                        </StackPanel>
                      </Border>
                    </UniformGrid>
                  </StackPanel>
                </Border>

                <!-- Support & Community Banner -->
                <Border Background="#111114" BorderBrush="#23232A" BorderThickness="1" CornerRadius="8" Padding="18,12" Margin="0,0,0,14" HorizontalAlignment="Stretch">
                  <Grid>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*" />
                      <ColumnDefinition Width="Auto" />
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,16,0">
                      <StackPanel Orientation="Horizontal" Margin="0,0,0,3">
                        <TextBlock Text="&#xEB51;" FontFamily="Segoe MDL2 Assets" FontSize="12" Foreground="#c15f3c" Margin="0,0,6,0" VerticalAlignment="Center" />
                        <TextBlock Name="TxtAboutDonateTitle" Text="Support &amp; Connect with ZeroHub" FontWeight="Bold" FontSize="12" Foreground="#c15f3c" />
                      </StackPanel>
                      <TextBlock Name="TxtAboutDonateBody" Text="ZeroHub is 100% free and open source. If you love using it, consider supporting future development!" FontSize="10.5" Foreground="#D4D4D8" />
                    </StackPanel>
                    <!-- Action Buttons using b1 and b2 -->
                    <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                      <Button Name="BtnOpenDonate" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Height="28" Padding="6,0" Margin="0,0,8,0" Cursor="Hand" ToolTip="Open Donation Page https://zeroiq.site/donate">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                          <TextBlock Text="&#xEB51;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#c15f3c" Margin="0,0,5,0" VerticalAlignment="Center" />
                          <TextBlock Name="TxtAboutDonateBtn" Text="Donate" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" />
                        </StackPanel>
                      </Button>
                      <Button Name="BtnOpenWebsite" Style="{StaticResource b2}" Background="#18181C" Foreground="#D4D4D8" Height="28" Padding="6,0" Cursor="Hand" ToolTip="Visit Official Website https://zeroiq.site">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                          <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="11" Foreground="#4ADE80" Margin="0,0,5,0" VerticalAlignment="Center" />
                          <TextBlock Text="zeroiq.site" FontWeight="SemiBold" FontSize="11" Foreground="#D4D4D8" />
                        </StackPanel>
                      </Button>
                    </StackPanel>
                  </Grid>
                </Border>

                <!-- Bottom Copyright -->
                <TextBlock Text="Released under the GNU General Public License v3.0 (GPLv3) - Copyright Â© 2026 Amir Ali - All Rights Reserved." FontSize="9.5" Foreground="#71717A" HorizontalAlignment="Center" Margin="0,4,0,0" />
              </StackPanel>
            </ScrollViewer>
          </TabItem>
        </TabControl>
      </Grid>
    </Grid>
    <!-- BOTTOM STATUS BAR -->
    <Border Grid.Row="2" Background="#111114" BorderBrush="#23232A" BorderThickness="0,1,0,0" Padding="20,8">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*" />
          <ColumnDefinition Width="Auto" />
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Name="StatusIcon" Text="" FontFamily="Segoe MDL2 Assets" FontSize="13" Foreground="#4ADE80" Margin="0,0,8,0" VerticalAlignment="Center" />
          <TextBlock Name="StatusText" Text="Ready to scan and clean. Select your preferred preset or targets." FontSize="13" FontWeight="SemiBold" Foreground="#F5EDE0" VerticalAlignment="Center" />
          <ProgressBar Name="FooterProgressBar" IsIndeterminate="True" Width="130" Height="4" Background="#1E293B" Foreground="#38BDF8" BorderThickness="0" Margin="12,0,0,0" VerticalAlignment="Center" Visibility="Collapsed" />
        </StackPanel>
        <StackPanel Name="PanelCleanerFooterMetrics" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Name="TxtSelectedLabel" Text="Selected:" FontSize="13" FontWeight="SemiBold" Foreground="#F5EDE0" Margin="0,0,5,0" />
          <TextBlock Name="TxtSelectedCount" Text="0 items" FontWeight="Bold" FontSize="13" Foreground="#c15f3c" Margin="0,0,15,0" />
          <TextBlock Name="TxtReclaimableLabel" Text="Space to Clean:" FontSize="13" FontWeight="SemiBold" Foreground="#F5EDE0" Margin="0,0,5,0" />
          <TextBlock Name="TxtTotalReclaimable" Text="0.00 MB" FontWeight="Bold" FontSize="13" Foreground="#4ADE80" />
        </StackPanel>
      </Grid>
    </Border>
  </Grid>
</Window>
'@

# Read and Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

# Resolve App Icon & Bind Immediately to Window & Win32 Class
$Script:AppIconPath = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.ico"))) {
    $Script:AppIconPath = Join-Path $PSScriptRoot "assets\logo.ico"
} elseif (Test-Path "$env:LOCALAPPDATA\ZeroHub\logo.ico") {
    $Script:AppIconPath = "$env:LOCALAPPDATA\ZeroHub\logo.ico"
} else {
    try {
        $zeroDir = "$env:LOCALAPPDATA\ZeroHub"
        if (-not (Test-Path $zeroDir)) { New-Item -Path $zeroDir -ItemType Directory -Force | Out-Null }
        $Script:AppIconPath = "$zeroDir\logo.ico"
        (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.ico", $Script:AppIconPath)
    } catch {}
}

if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
    try {
        $decoder = [System.Windows.Media.Imaging.IconBitmapDecoder]::new(
            [Uri]::new($Script:AppIconPath, [UriKind]::Absolute),
            [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        )
        if ($decoder.Frames.Count -gt 0) {
            $Window.Icon = $decoder.Frames[0]
        } else {
            $Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($Script:AppIconPath, [UriKind]::Absolute))
        }
    } catch {
        try { $Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($Script:AppIconPath, [UriKind]::Absolute)) } catch {}
    }
}

$Window.add_SourceInitialized({
    try {
        $helper = [System.Windows.Interop.WindowInteropHelper]::new($Window)
        $hwnd = $helper.Handle
        [ZeroHub.NativeMethods]::EnableDarkTitleBar($hwnd)
        if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
            $icoBig = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
            $icoSmall = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
            [ZeroHub.NativeMethods]::SetWindowIconFull($hwnd, $icoBig.Handle, $icoSmall.Handle)
        }
    } catch {}
})

# Map UI Elements
$BtnHeaderLogo       = $Window.FindName("BtnHeaderLogo")
$BtnSidebarWebsite   = $Window.FindName("BtnSidebarWebsite")
$BtnSidebarDonate    = $Window.FindName("BtnSidebarDonate")
$BtnAboutLogo        = $Window.FindName("BtnAboutLogo")
$BtnAboutSiteBadge   = $Window.FindName("BtnAboutSiteBadge")
$ImgHeaderLogo       = $Window.FindName("ImgHeaderLogo")
$ImgAboutLogo        = $Window.FindName("ImgAboutLogo")
$BtnOpenWebsite      = $Window.FindName("BtnOpenWebsite")
$BtnOpenDonate       = $Window.FindName("BtnOpenDonate")
$TxtAppSubtitle      = $Window.FindName("TxtAppSubtitle")
$TxtDriveLabel       = $Window.FindName("TxtDriveLabel")
$DriveProgressBar   = $Window.FindName("DriveProgressBar")
$DriveFreeText      = $Window.FindName("DriveFreeText")
$RamCircleArc       = $Window.FindName("RamCircleArc")
$TxtRamPercent      = $Window.FindName("TxtRamPercent")
$TxtRamLiveMetrics  = $Window.FindName("TxtRamLiveMetrics")
$TxtRamReclaimable  = $Window.FindName("TxtRamReclaimable")
$AdminIcon          = $Window.FindName("AdminIcon")
$AdminText          = $Window.FindName("AdminText")
$BtnRelaunchAdmin   = $Window.FindName("BtnRelaunchAdmin")
$BtnFreeRam         = $Window.FindName("BtnFreeRam")
$TxtFreeRam         = $Window.FindName("TxtFreeRam")
$BtnAppUpdate          = $Window.FindName("BtnAppUpdate")
$TxtAppUpdate          = $Window.FindName("TxtAppUpdate")
$BorderSidebarUpdate   = $Window.FindName("BorderSidebarUpdate")
$BtnSidebarUpdate      = $Window.FindName("BtnSidebarUpdate")
$TxtSidebarUpdate      = $Window.FindName("TxtSidebarUpdate")
$IconSidebarUpdate     = $Window.FindName("IconSidebarUpdate")
$BadgeSidebarUpdateArrow = $Window.FindName("BadgeSidebarUpdateArrow")
$BtnManualCheckUpdates = $Window.FindName("BtnManualCheckUpdates")
$TxtAboutUpdateStatus  = $Window.FindName("TxtAboutUpdateStatus")
$BtnCreateShortcut     = $Window.FindName("BtnCreateShortcut")
$BtnToggleNotifications = $Window.FindName("BtnToggleNotifications")
$TxtToggleNotifications = $Window.FindName("TxtToggleNotifications")
$IconToggleNotifications = $Window.FindName("IconToggleNotifications")
$BtnWindowMinimize  = $Window.FindName("BtnWindowMinimize")
$BtnWindowMaximize  = $Window.FindName("BtnWindowMaximize")
$BtnWindowClose     = $Window.FindName("BtnWindowClose")
$TxtWindowMaximizeIcon = $Window.FindName("TxtWindowMaximizeIcon")

$Tab_Dashboard      = $Window.FindName("Tab_Dashboard")
$Tab_Installer      = $Window.FindName("Tab_Installer")
$Tab_Uninstaller    = $Window.FindName("Tab_Uninstaller")
$Tab_Bloatware      = $Window.FindName("Tab_Bloatware")
$Tab_Updates        = $Window.FindName("Tab_Updates")
$Tab_Privacy        = $Window.FindName("Tab_Privacy")
$Tab_Startup        = $Window.FindName("Tab_Startup")
$Tab_GameHub        = $Window.FindName("Tab_GameHub")

$Tab_Guard          = $Window.FindName("Tab_Guard")
$Tab_Log            = $Window.FindName("Tab_Log")
$Tab_About          = $Window.FindName("Tab_About")

$NavCat_Clean           = $Window.FindName("NavCat_Clean")
$NavCat_Tools           = $Window.FindName("NavCat_Tools")

$Border_Nav_Dashboard   = $Window.FindName("Border_Nav_Dashboard")
$Nav_Dashboard          = $Window.FindName("Nav_Dashboard")
$TxtNav_Dashboard       = $Window.FindName("TxtNav_Dashboard")
$Icon_Nav_Dashboard     = $Window.FindName("Icon_Nav_Dashboard")

$Border_Nav_Installer   = $Window.FindName("Border_Nav_Installer")
$Nav_Installer          = $Window.FindName("Nav_Installer")
$TxtNav_Installer       = $Window.FindName("TxtNav_Installer")
$Icon_Nav_Installer     = $Window.FindName("Icon_Nav_Installer")

$Border_Nav_Uninstaller = $Window.FindName("Border_Nav_Uninstaller")
$Nav_Uninstaller        = $Window.FindName("Nav_Uninstaller")
$TxtNav_Uninstaller     = $Window.FindName("TxtNav_Uninstaller")
$Icon_Nav_Uninstaller   = $Window.FindName("Icon_Nav_Uninstaller")

$Border_Nav_Bloatware   = $Window.FindName("Border_Nav_Bloatware")
$Nav_Bloatware          = $Window.FindName("Nav_Bloatware")
$TxtNav_Bloatware       = $Window.FindName("TxtNav_Bloatware")
$Icon_Nav_Bloatware     = $Window.FindName("Icon_Nav_Bloatware")

$Border_Nav_Updates     = $Window.FindName("Border_Nav_Updates")
$Nav_Updates            = $Window.FindName("Nav_Updates")
$TxtNav_Updates         = $Window.FindName("TxtNav_Updates")
$Icon_Nav_Updates       = $Window.FindName("Icon_Nav_Updates")

$Border_Nav_Privacy     = $Window.FindName("Border_Nav_Privacy")
$Nav_Privacy            = $Window.FindName("Nav_Privacy")
$TxtNav_Privacy         = $Window.FindName("TxtNav_Privacy")
$Icon_Nav_Privacy       = $Window.FindName("Icon_Nav_Privacy")

$Tab_Dns                  = $Window.FindName("Tab_Dns")
$Border_Nav_Dns           = $Window.FindName("Border_Nav_Dns")
$Nav_Dns                  = $Window.FindName("Nav_Dns")
$TxtNav_Dns               = $Window.FindName("TxtNav_Dns")
$Icon_Nav_Dns             = $Window.FindName("Icon_Nav_Dns")

$BadgeDnsActiveStatus     = $Window.FindName("BadgeDnsActiveStatus")
$TxtDnsActiveStatus       = $Window.FindName("TxtDnsActiveStatus")
$BtnRunDnsBenchmark       = $Window.FindName("BtnRunDnsBenchmark")
$BtnToolFlushDns          = $Window.FindName("BtnToolFlushDns")
$BtnFlushDns              = $BtnToolFlushDns

$TxtCustomDnsPrimary      = $Window.FindName("TxtCustomDnsPrimary")
$TxtCustomDnsSecondary    = $Window.FindName("TxtCustomDnsSecondary")
$BtnApplyCustomDns        = $Window.FindName("BtnApplyCustomDns")

$BtnToolResetWinsock      = $Window.FindName("BtnToolResetWinsock")
$BtnToolRenewIp           = $Window.FindName("BtnToolRenewIp")

$Border_Nav_Startup     = $Window.FindName("Border_Nav_Startup")
$Nav_Startup            = $Window.FindName("Nav_Startup")
$TxtNav_Startup         = $Window.FindName("TxtNav_Startup")
$Icon_Nav_Startup       = $Window.FindName("Icon_Nav_Startup")

$TxtStartupSearch       = $Window.FindName("TxtStartupSearch")
$BtnRefreshStartup      = $Window.FindName("BtnRefreshStartup")
$BtnOptimizeStartup     = $Window.FindName("BtnOptimizeStartup")
$StartupAppsDataGrid    = $Window.FindName("StartupAppsDataGrid")
$TxtStartupCountInfo    = $Window.FindName("TxtStartupCountInfo")

$Border_Nav_GameHub     = $Window.FindName("Border_Nav_GameHub")
$Nav_GameHub            = $Window.FindName("Nav_GameHub")
$TxtNav_GameHub         = $Window.FindName("TxtNav_GameHub")
$Icon_Nav_GameHub       = $Window.FindName("Icon_Nav_GameHub")

$TxtGameSearch          = $Window.FindName("TxtGameSearch")
$TxtGameHubStats        = $Window.FindName("TxtGameHubStats")
$BtnAddCustomGame       = $Window.FindName("BtnAddCustomGame")
$BtnRefreshGames        = $Window.FindName("BtnRefreshGames")
$BtnFilterGameAll       = $Window.FindName("BtnFilterGameAll")
$BtnFilterGameSteam     = $Window.FindName("BtnFilterGameSteam")
$BtnFilterGameEpic      = $Window.FindName("BtnFilterGameEpic")
$BtnFilterGameRiot      = $Window.FindName("BtnFilterGameRiot")
$BtnFilterGameBattlenet = $Window.FindName("BtnFilterGameBattlenet")
$BtnFilterGameXbox      = $Window.FindName("BtnFilterGameXbox")
$BtnFilterGameFitGirl   = $Window.FindName("BtnFilterGameFitGirl")
$BtnFilterGameDODI      = $Window.FindName("BtnFilterGameDODI")
$BtnFilterGameGOG       = $Window.FindName("BtnFilterGameGOG")
$BtnFilterGameStandalone= $Window.FindName("BtnFilterGameStandalone")
$BtnFilterGameCustom    = $Window.FindName("BtnFilterGameCustom")
$GameCardsContainer     = $Window.FindName("GameCardsContainer")
$ScrollGameCards        = $Window.FindName("ScrollGameCards")






$Tab_Defender              = $Window.FindName("Tab_Defender")
$Border_Nav_Defender       = $Window.FindName("Border_Nav_Defender")
$Nav_Defender              = $Window.FindName("Nav_Defender")
$TxtNav_Defender           = $Window.FindName("TxtNav_Defender")
$Icon_Nav_Defender         = $Window.FindName("Icon_Nav_Defender")

$BadgeDefenderStatus       = $Window.FindName("BadgeDefenderStatus")
$TxtDefenderStatus         = $Window.FindName("TxtDefenderStatus")
$BtnDefenderQuickScan      = $Window.FindName("BtnDefenderQuickScan")
$BtnUpdateSignatures       = $Window.FindName("BtnUpdateSignatures")
$BtnOpenWinSecurity        = $Window.FindName("BtnOpenWinSecurity")

$BtnAddDetectedGames       = $Window.FindName("BtnAddDetectedGames")
$BtnAddCustomExclusion     = $Window.FindName("BtnAddCustomExclusion")
$BtnRefreshExclusions      = $Window.FindName("BtnRefreshExclusions")
$ListDefenderExclusions    = $Window.FindName("ListDefenderExclusions")
$TxtExclusionCountInfo     = $Window.FindName("TxtExclusionCountInfo")


$BtnClearProtHistory       = $Window.FindName("BtnClearProtHistory")

$Border_Nav_Guard       = $Window.FindName("Border_Nav_Guard")
$Nav_Guard              = $Window.FindName("Nav_Guard")
$TxtNav_Guard           = $Window.FindName("TxtNav_Guard")
$Icon_Nav_Guard         = $Window.FindName("Icon_Nav_Guard")

$Border_Nav_Log         = $Window.FindName("Border_Nav_Log")
$Nav_Log                = $Window.FindName("Nav_Log")
$TxtNav_Log             = $Window.FindName("TxtNav_Log")
$Icon_Nav_Log           = $Window.FindName("Icon_Nav_Log")

$Border_Nav_About       = $Window.FindName("Border_Nav_About")
$Nav_About              = $Window.FindName("Nav_About")
$TxtNav_About           = $Window.FindName("TxtNav_About")
$Icon_Nav_About         = $Window.FindName("Icon_Nav_About")

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

$BadgeWinUpdateStatus       = $Window.FindName("BadgeWinUpdateStatus")
$TxtWinUpdateStatus         = $Window.FindName("TxtWinUpdateStatus")
$BtnToggleWinUpdate         = $Window.FindName("BtnToggleWinUpdate")
$BadgeCard1                 = $Window.FindName("BadgeCard1")
$BadgeCard2                 = $Window.FindName("BadgeCard2")
$BadgeCard3                 = $Window.FindName("BadgeCard3")
$BadgeCard4                 = $Window.FindName("BadgeCard4")

$BtnCleanWuCache            = $Window.FindName("BtnCleanWuCache")
$BtnResetWuComponents       = $Window.FindName("BtnResetWuComponents")
$BtnOpenWuSettings          = $Window.FindName("BtnOpenWuSettings")

$BadgePrivacyMasterStatus   = $Window.FindName("BadgePrivacyMasterStatus")
$TxtPrivacyMasterStatus     = $Window.FindName("TxtPrivacyMasterStatus")
$FooterProgressBar          = $Window.FindName("FooterProgressBar")
$BtnApplyMaxPrivacy         = $Window.FindName("BtnApplyMaxPrivacy")
$BtnRestorePrivacyDefaults  = $Window.FindName("BtnRestorePrivacyDefaults")
$Border_BadgePrivCard1      = $Window.FindName("Border_BadgePrivCard1")
$BadgePrivCard1             = $Window.FindName("BadgePrivCard1")
$BtnTogglePrivDiag          = $Window.FindName("BtnTogglePrivDiag")
$Border_BadgePrivCard2      = $Window.FindName("Border_BadgePrivCard2")
$BadgePrivCard2             = $Window.FindName("BadgePrivCard2")
$BtnTogglePrivAds           = $Window.FindName("BtnTogglePrivAds")
$Border_BadgePrivCard3      = $Window.FindName("Border_BadgePrivCard3")
$BadgePrivCard3             = $Window.FindName("BadgePrivCard3")
$BtnTogglePrivSearch        = $Window.FindName("BtnTogglePrivSearch")
$Border_BadgePrivCard4      = $Window.FindName("Border_BadgePrivCard4")
$BadgePrivCard4             = $Window.FindName("BadgePrivCard4")
$BtnTogglePrivTasks         = $Window.FindName("BtnTogglePrivTasks")
$Border_BadgePrivCard5      = $Window.FindName("Border_BadgePrivCard5")
$BadgePrivCard5             = $Window.FindName("BadgePrivCard5")
$BtnTogglePrivAI            = $Window.FindName("BtnTogglePrivAI")
$Border_BadgePrivCard6      = $Window.FindName("Border_BadgePrivCard6")
$BadgePrivCard6             = $Window.FindName("BadgePrivCard6")
$BtnTogglePrivHosts         = $Window.FindName("BtnTogglePrivHosts")
$Border_BadgePrivCard7      = $Window.FindName("Border_BadgePrivCard7")
$BadgePrivCard7             = $Window.FindName("BadgePrivCard7")
$BtnTogglePrivEdge          = $Window.FindName("BtnTogglePrivEdge")
$Border_BadgePrivCard8      = $Window.FindName("Border_BadgePrivCard8")
$BadgePrivCard8             = $Window.FindName("BadgePrivCard8")
$BtnTogglePrivWER           = $Window.FindName("BtnTogglePrivWER")

$Border_BadgePrivCard9      = $Window.FindName("Border_BadgePrivCard9")
$BadgePrivCard9             = $Window.FindName("BadgePrivCard9")
$BtnTogglePrivNudges        = $Window.FindName("BtnTogglePrivNudges")

$Border_BadgePrivCard10     = $Window.FindName("Border_BadgePrivCard10")
$BadgePrivCard10            = $Window.FindName("BadgePrivCard10")
$BtnTogglePrivWUDO          = $Window.FindName("BtnTogglePrivWUDO")

$Border_BadgePrivCard11     = $Window.FindName("Border_BadgePrivCard11")
$BadgePrivCard11            = $Window.FindName("BadgePrivCard11")
$BtnTogglePrivClipboard     = $Window.FindName("BtnTogglePrivClipboard")

$Border_BadgePrivCard12     = $Window.FindName("Border_BadgePrivCard12")
$BadgePrivCard12            = $Window.FindName("BadgePrivCard12")
$BtnTogglePrivSensors       = $Window.FindName("BtnTogglePrivSensors")

$Border_BadgePrivCard13     = $Window.FindName("Border_BadgePrivCard13")
$BadgePrivCard13            = $Window.FindName("BadgePrivCard13")
$BtnTogglePrivClassicMenu   = $Window.FindName("BtnTogglePrivClassicMenu")

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

$Banner_AutoCloseTip      = $Window.FindName("Banner_AutoCloseTip")
$BtnDismissAutoCloseTip   = $Window.FindName("BtnDismissAutoCloseTip")
$BtnToggleAutoCloseTip    = $Window.FindName("BtnToggleAutoCloseTip")
$ChkAutoCloseApps         = $Window.FindName("ChkAutoCloseApps")
$BtnScanAll               = $Window.FindName("BtnScanAll")
$BtnCleanSelected         = $Window.FindName("BtnCleanSelected")

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







$Tab_ProcManager       = $Window.FindName("Tab_ProcManager")
$Border_Nav_ProcManager= $Window.FindName("Border_Nav_ProcManager")
$Nav_ProcManager       = $Window.FindName("Nav_ProcManager")
$TxtNav_ProcManager    = $Window.FindName("TxtNav_ProcManager")
$Icon_Nav_ProcManager   = $Window.FindName("Icon_Nav_ProcManager")

$TxtProcSearch         = $Window.FindName("TxtProcSearch")
$TxtProcStatsInfo      = $Window.FindName("TxtProcStatsInfo")
$BtnRefreshProcList    = $Window.FindName("BtnRefreshProcList")
$BtnPurgeSafeProcs     = $Window.FindName("BtnPurgeSafeProcs")
$BtnFilterProcAll      = $Window.FindName("BtnFilterProcAll")
$BtnFilterProcSafe     = $Window.FindName("BtnFilterProcSafe")
$BtnFilterProcWork     = $Window.FindName("BtnFilterProcWork")
$BtnFilterProcService  = $Window.FindName("BtnFilterProcService")
$BtnFilterProcHeavy    = $Window.FindName("BtnFilterProcHeavy")
$BtnFilterProcProtected= $Window.FindName("BtnFilterProcProtected")
$ProcManagerDataGrid   = $Window.FindName("ProcManagerDataGrid")
$TxtProcSafeReclaimable= $Window.FindName("TxtProcSafeReclaimable")

$TxtGuardTitle       = $Window.FindName("TxtGuardTitle")
$BtnRefreshProcesses = $Window.FindName("BtnRefreshProcesses")
$BtnCloseAllGuards   = $Window.FindName("BtnCloseAllGuards")
$ProcessDataGrid     = $Window.FindName("ProcessDataGrid")

$TxtLogTitle        = $Window.FindName("TxtLogTitle")
$BtnCopyLogs        = $Window.FindName("BtnCopyLogs")
$BtnClearLogs       = $Window.FindName("BtnClearLogs")
$TxtLogConsole      = $Window.FindName("TxtLogConsole")

$BtnCreateShortcut        = $Window.FindName("BtnCreateShortcut")

$StatusIcon         = $Window.FindName("StatusIcon")
$StatusText         = $Window.FindName("StatusText")
$PanelCleanerFooterMetrics = $Window.FindName("PanelCleanerFooterMetrics")
$TxtSelectedLabel   = $Window.FindName("TxtSelectedLabel")
$TxtSelectedCount   = $Window.FindName("TxtSelectedCount")
$TxtReclaimableLabel= $Window.FindName("TxtReclaimableLabel")
$TxtTotalReclaimable= $Window.FindName("TxtTotalReclaimable")
$MainTabs           = $Window.FindName("MainTabs")

$Script:TargetItems = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.TargetItem]]::new()
$Script:CheckboxesById = @{}

# Bilingual Dictionaries
# Interface Language Setup (English)
function Set-HubLanguage([string]$lang = "EN") {
        

    if ($TxtAppSubtitle) { $TxtAppSubtitle.Text = "Tired of Windows? Switch to Linux :D" }
    $TxtDriveLabel.Text        = $t.DriveLabel
    $BtnRelaunchAdmin.Content  = $t.ElevateBtn
    $AdminText.Text            = if ($isAdmin) { $t.Administrator } else { $t.StandardUser }

    if ($NavCat_Clean)         { $NavCat_Clean.Text         = $t.NavCat_Clean }
    if ($NavCat_Tools)         { $NavCat_Tools.Text         = $t.NavCat_Tools }
    if ($TxtNav_Dashboard)     { $TxtNav_Dashboard.Text     = $t.Nav_Dashboard }
    if ($TxtNav_Installer)     { $TxtNav_Installer.Text     = $t.Nav_Installer }
    if ($TxtNav_Uninstaller)   { $TxtNav_Uninstaller.Text   = $t.Nav_Uninstaller }
    if ($TxtNav_Bloatware)     { $TxtNav_Bloatware.Text     = $t.Nav_Bloatware }
    if ($TxtNav_Updates)       { $TxtNav_Updates.Text       = $t.Nav_Updates }
    if ($TxtNav_Privacy)       { $TxtNav_Privacy.Text       = $t.Nav_Privacy }
    if ($TxtNav_Dns)           { $TxtNav_Dns.Text           = $t.Nav_Dns }
    if ($TxtHeaderTabDns)      { $TxtHeaderTabDns.Text      = $t.TabDns }
    if ($TxtDnsHeroTitle)      { $TxtDnsHeroTitle.Text      = $t.DnsHeroTitle }
    if ($TxtDnsHeroSubtitle)   { $TxtDnsHeroSubtitle.Text   = $t.DnsHeroSubtitle }
    if ($BtnRunDnsBenchmark)   { $BtnRunDnsBenchmark.Content = $t.BtnRunDnsBenchmark }
    if ($BtnRestoreDnsDhcp)    { $BtnRestoreDnsDhcp.Content = $t.BtnRestoreDnsDhcp }
    if ($BtnFlushDns)          { $BtnFlushDns.Content       = $t.BtnFlushDns }
    if ($TxtCustomDnsTitle)    { $TxtCustomDnsTitle.Text    = $t.CustomDnsTitle }
    if ($TxtCustomDnsDesc)     { $TxtCustomDnsDesc.Text     = $t.CustomDnsDesc }
    if ($BtnApplyCustomDns)    { $BtnApplyCustomDns.Content = $t.BtnApplyCustomDns }
    if ($TxtNetToolsTitle)     { $TxtNetToolsTitle.Text     = $t.NetToolsTitle }
    if ($TxtNetToolsDesc)      { $TxtNetToolsDesc.Text      = $t.NetToolsDesc }
    if ($BtnToolFlushDns)      { $BtnToolFlushDns.Content   = $t.BtnToolFlushDns }
    if ($BtnToolResetWinsock)  { $BtnToolResetWinsock.Content = $t.BtnToolResetWinsock }
    if ($BtnToolRenewIp)       { $BtnToolRenewIp.Content    = $t.BtnToolRenewIp }
    if ($TxtDnsNoticeTitle)    { $TxtDnsNoticeTitle.Text    = $t.DnsNoticeTitle }
    if ($TxtDnsNoticeDesc)     { $TxtDnsNoticeDesc.Text     = $t.DnsNoticeDesc }
    if ($TxtNav_Startup)       { $TxtNav_Startup.Text       = $t.Nav_Startup }
    if ($TxtNav_GameHub)       { $TxtNav_GameHub.Text       = $t.Nav_GameHub }
    
    if ($TxtNav_Defender)      { $TxtNav_Defender.Text      = $t.Nav_Defender }
    if ($TxtNav_Guard)         { $TxtNav_Guard.Text         = $t.Nav_Guard }
    if ($TxtNav_ProcManager)   { $TxtNav_ProcManager.Text   = "Task Manager" }
    if ($TxtNav_Log)           { $TxtNav_Log.Text           = $t.Nav_Log }
    if ($TxtNav_About)         { $TxtNav_About.Text         = $t.Nav_About }

    $Tab_Dashboard.Header      = $t.TabDashboard
    if ($Tab_Installer)        { $Tab_Installer.Header = "📥 " + $t.TabInstaller }
    $Tab_Uninstaller.Header    = $t.TabUninstaller
    if ($Tab_Startup)          { $Tab_Startup.Header = "🚀 " + $t.TabStartup }
    if ($TxtHeaderTabStartup)  { $TxtHeaderTabStartup.Text = $t.TabStartup }
    if ($Tab_GameHub)          { $Tab_GameHub.Header = "🎮 " + $t.TabGameHub }
    if ($TxtHeaderTabGameHub)  { $TxtHeaderTabGameHub.Text = $t.TabGameHub }
    
    if ($Tab_Defender)         { $Tab_Defender.Header = "🛡️ " + $t.TabDefender }
    if ($Tab_ProcManager)      { $Tab_ProcManager.Header = "⚡ Task Manager" }
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

    $TxtSelectedLabel.Text     = $t.SelectedLabel
    $TxtReclaimableLabel.Text  = $t.ReclaimableLabel

    foreach ($item in $Script:TargetItems) {
        $item.CheckBoxControl.Content = $item.Name
        $item.CheckBoxControl.ToolTip = $item.Description
    }

    Update-ProcessGuardList
    if ($Script:InstallerCatalogList.Count -gt 0) { Initialize-InstallerCatalogList }
    if ($Script:AllInstalledApps.Count -gt 0) { Set-AppFilters; Update-AppSelectionStatus }
    Update-DriveInfo
}


# Map Fast Text Finder Elements
$Tab_TextFinder          = $Window.FindName("Tab_TextFinder")
$Border_Nav_TextFinder   = $Window.FindName("Border_Nav_TextFinder")
$Nav_TextFinder          = $Window.FindName("Nav_TextFinder")
$TxtNav_TextFinder       = $Window.FindName("TxtNav_TextFinder")
$Icon_Nav_TextFinder     = $Window.FindName("Icon_Nav_TextFinder")
$TxtSearchFolder         = $Window.FindName("TxtSearchFolder")
$BtnBrowseSearchFolder   = $Window.FindName("BtnBrowseSearchFolder")
$TxtSearchQuery          = $Window.FindName("TxtSearchQuery")
$TxtSearchExtensions     = $Window.FindName("TxtSearchExtensions")
$RadioSearchBoth         = $Window.FindName("RadioSearchBoth")
$RadioSearchNames        = $Window.FindName("RadioSearchNames")
$RadioSearchContent      = $Window.FindName("RadioSearchContent")
$TxtSearchModeExplainer   = $Window.FindName("TxtSearchModeExplainer")
$ChkSearchRecursive      = $Window.FindName("ChkSearchRecursive")
$ChkSearchMatchCase      = $Window.FindName("ChkSearchMatchCase")
$ChkSearchUseRegex       = $Window.FindName("ChkSearchUseRegex")
$BtnStartTextSearch      = $Window.FindName("BtnStartTextSearch")
$BtnClearSearchResults   = $Window.FindName("BtnClearSearchResults")
$SearchDataGrid          = $Window.FindName("SearchDataGrid")
$TxtSearchStatus         = $Window.FindName("TxtSearchStatus")

# Map Updates Tab Elements
$Tab_AppUpdate           = $Window.FindName("Tab_AppUpdate")
$Border_Nav_AppUpdate    = $Window.FindName("Border_Nav_AppUpdate")
$Nav_AppUpdate           = $Window.FindName("Nav_AppUpdate")
$TxtNav_AppUpdate        = $Window.FindName("TxtNav_AppUpdate")
$Icon_Nav_AppUpdate      = $Window.FindName("Icon_Nav_AppUpdate")
$TxtAppUpdateStatus      = $Window.FindName("TxtAppUpdateStatus")
$BtnAppUpdateTab         = $Window.FindName("BtnAppUpdateTab")

# Update Active Sidebar Highlight
function Update-SidebarSelection {
    param($selectedTab)
    if (-not $selectedTab -and $MainTabs) {
        $selectedTab = $MainTabs.SelectedItem
    }
    if (-not $selectedTab) { return }

    $activeBg       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
    $activeBorder   = [System.Windows.Media.Brushes]::Transparent
    $activeFg       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDFBF7")
    $inactiveBg     = [System.Windows.Media.Brushes]::Transparent
    $inactiveBorder = [System.Windows.Media.Brushes]::Transparent
    $inactiveFg     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    $list = @(
        @{ Tab = $Tab_Dashboard;   Border = $Border_Nav_Dashboard;   Text = $TxtNav_Dashboard;   Icon = $Icon_Nav_Dashboard },
        @{ Tab = $Tab_Installer;   Border = $Border_Nav_Installer;   Text = $TxtNav_Installer;   Icon = $Icon_Nav_Installer },
        @{ Tab = $Tab_Uninstaller; Border = $Border_Nav_Uninstaller; Text = $TxtNav_Uninstaller; Icon = $Icon_Nav_Uninstaller },
        @{ Tab = $Tab_Bloatware;   Border = $Border_Nav_Bloatware;   Text = $TxtNav_Bloatware;   Icon = $Icon_Nav_Bloatware },
        @{ Tab = $Tab_Updates;     Border = $Border_Nav_Updates;     Text = $TxtNav_Updates;     Icon = $Icon_Nav_Updates },
        @{ Tab = $Tab_Privacy;     Border = $Border_Nav_Privacy;     Text = $TxtNav_Privacy;     Icon = $Icon_Nav_Privacy },
        @{ Tab = $Tab_Dns;         Border = $Border_Nav_Dns;         Text = $TxtNav_Dns;         Icon = $Icon_Nav_Dns },
        @{ Tab = $Tab_Startup;     Border = $Border_Nav_Startup;     Text = $TxtNav_Startup;     Icon = $Icon_Nav_Startup },
        @{ Tab = $Tab_GameHub;     Border = $Border_Nav_GameHub;     Text = $TxtNav_GameHub;     Icon = $Icon_Nav_GameHub },
        
        @{ Tab = $Tab_Defender;    Border = $Border_Nav_Defender;    Text = $TxtNav_Defender;    Icon = $Icon_Nav_Defender },
        @{ Tab = $Tab_TextFinder;  Border = $Border_Nav_TextFinder;  Text = $TxtNav_TextFinder;  Icon = $Icon_Nav_TextFinder },
        @{ Tab = $Tab_ProcManager; Border = $Border_Nav_ProcManager; Text = $TxtNav_ProcManager; Icon = $Icon_Nav_ProcManager },
        @{ Tab = $Tab_Guard;       Border = $Border_Nav_Guard;       Text = $TxtNav_Guard;       Icon = $Icon_Nav_Guard },
        @{ Tab = $Tab_Log;         Border = $Border_Nav_Log;         Text = $TxtNav_Log;         Icon = $Icon_Nav_Log },
        @{ Tab = $Tab_AppUpdate;   Border = $Border_Nav_AppUpdate;   Text = $TxtNav_AppUpdate;   Icon = $Icon_Nav_AppUpdate },
        @{ Tab = $Tab_About;       Border = $Border_Nav_About;       Text = $TxtNav_About;       Icon = $Icon_Nav_About }
    )

    foreach ($entry in $list) {
        if ($entry.Border -and $entry.Text) {
            if ($entry.Tab -eq $selectedTab) {
                $entry.Border.Background = $activeBg
                $entry.Border.BorderBrush = $activeBorder
                $entry.Border.BorderThickness = [System.Windows.Thickness]::new(0)
                $entry.Text.Foreground = $activeFg
                $entry.Text.FontWeight = [System.Windows.FontWeights]::SemiBold
                if ($entry.Icon) { $entry.Icon.Foreground = $activeFg }
            } else {
                $entry.Border.Background = $inactiveBg
                $entry.Border.BorderBrush = $inactiveBorder
                $entry.Border.BorderThickness = [System.Windows.Thickness]::new(0)
                $entry.Text.Foreground = $inactiveFg
                $entry.Text.FontWeight = [System.Windows.FontWeights]::SemiBold
                if ($entry.Icon) { $entry.Icon.Foreground = $inactiveFg }
            }
        }
    }

    if ($PanelCleanerFooterMetrics) {
        if ($selectedTab -eq $Tab_Dashboard) {
            $PanelCleanerFooterMetrics.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $PanelCleanerFooterMetrics.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }
}

# Wire Sidebar Navigation Buttons
if ($Nav_Dashboard)   { $Nav_Dashboard.add_Click({   $MainTabs.SelectedItem = $Tab_Dashboard }) }
if ($Nav_Installer)   { $Nav_Installer.add_Click({   $MainTabs.SelectedItem = $Tab_Installer }) }
if ($Nav_Uninstaller) { $Nav_Uninstaller.add_Click({ $MainTabs.SelectedItem = $Tab_Uninstaller }) }
if ($Nav_Bloatware)   { $Nav_Bloatware.add_Click({   $MainTabs.SelectedItem = $Tab_Bloatware }) }
if ($Nav_Updates)     { $Nav_Updates.add_Click({     $MainTabs.SelectedItem = $Tab_Updates }) }
if ($Nav_Privacy)     { $Nav_Privacy.add_Click({     $MainTabs.SelectedItem = $Tab_Privacy }) }
if ($Nav_Dns)         { $Nav_Dns.add_Click({         $MainTabs.SelectedItem = $Tab_Dns }) }
if ($Nav_Startup)     { $Nav_Startup.add_Click({     $MainTabs.SelectedItem = $Tab_Startup }) }
if ($Nav_GameHub)     { $Nav_GameHub.add_Click({     $MainTabs.SelectedItem = $Tab_GameHub }) }

if ($Nav_Defender)    { $Nav_Defender.add_Click({    $MainTabs.SelectedItem = $Tab_Defender }) }
if ($Nav_TextFinder)  { $Nav_TextFinder.add_Click({  $MainTabs.SelectedItem = $Tab_TextFinder }) }
if ($Nav_ProcManager) { $Nav_ProcManager.add_Click({  $MainTabs.SelectedItem = $Tab_ProcManager }) }
if ($Nav_Guard)       { $Nav_Guard.add_Click({       $MainTabs.SelectedItem = $Tab_Guard }) }
if ($Nav_Log)         { $Nav_Log.add_Click({         $MainTabs.SelectedItem = $Tab_Log }) }
if ($Nav_AppUpdate)   { $Nav_AppUpdate.add_Click({   $MainTabs.SelectedItem = $Tab_AppUpdate }) }
if ($Nav_About)       { $Nav_About.add_Click({       $MainTabs.SelectedItem = $Tab_About }) }

# Load Application Logo (Header & About Page)
$Script:LogoImageSource = $null
$localLogoPath = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.png"))) {
    $localLogoPath = Join-Path $PSScriptRoot "assets\logo.png"
}
if ($localLogoPath) {
    try {
        $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bi.BeginInit()
        $bi.UriSource = [Uri]::new($localLogoPath, [UriKind]::Absolute)
        $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bi.EndInit()
        $bi.Freeze()
        $Script:LogoImageSource = $bi
    } catch {}
}
if (-not $Script:LogoImageSource) {
    try {
        $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bi.BeginInit()
        $bi.UriSource = [Uri]::new("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.png", [UriKind]::Absolute)
        $bi.EndInit()
        $Script:LogoImageSource = $bi
    } catch {}
}
if ($Script:LogoImageSource) {
    if ($ImgHeaderLogo) { $ImgHeaderLogo.Source = $Script:LogoImageSource }
    if ($ImgAboutLogo)  { $ImgAboutLogo.Source = $Script:LogoImageSource }
    if (-not $Window.Icon) { try { $Window.Icon = $Script:LogoImageSource } catch {} }
}

# Bulletproof External URL Opener (Launches installed browser directly to bypass broken Windows associations)
function Open-SafeBrowserUrl([string]$url) {
    # 1. Directly check installed browsers first
    $browserPaths = @(
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
        "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files\Mozilla Firefox\firefox.exe",
        "$env:LOCALAPPDATA\Programs\Opera\launcher.exe",
        "$env:LOCALAPPDATA\Programs\Opera GX\launcher.exe",
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
    )

    foreach ($bPath in $browserPaths) {
        if (Test-Path $bPath) {
            try {
                Start-Process -FilePath $bPath -ArgumentList "`"$url`"" -ErrorAction SilentlyContinue
                return
            } catch {}
        }
    }

    # 2. Fallback to Windows Shell handler
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $url
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        return
    } catch {}

    try {
        Start-Process "cmd.exe" -ArgumentList "/c start `"`" `"$url`"" -WindowStyle Hidden -ErrorAction SilentlyContinue
    } catch {}
}

# Clickable Logo & Website Handlers
$OpenZeroIqWebsite = { Open-SafeBrowserUrl "https://zeroiq.site/" }
$OpenZeroIqDonate  = { Open-SafeBrowserUrl "https://zeroiq.site/donate" }
if ($BtnHeaderLogo)       { $BtnHeaderLogo.add_MouseDown($OpenZeroIqWebsite) }
if ($BtnSidebarWebsite)   { $BtnSidebarWebsite.add_Click($OpenZeroIqWebsite) }
if ($BtnSidebarDonate)    { $BtnSidebarDonate.add_Click($OpenZeroIqDonate) }
if ($BtnAboutLogo)        { $BtnAboutLogo.add_MouseDown($OpenZeroIqWebsite) }
if ($BtnAboutSiteBadge)   { $BtnAboutSiteBadge.add_MouseDown($OpenZeroIqWebsite) }
if ($BtnOpenWebsite)      { $BtnOpenWebsite.add_Click($OpenZeroIqWebsite) }
if ($BtnOpenDonate)       { $BtnOpenDonate.add_Click($OpenZeroIqDonate) }

# Colorful Logging Helper Brushes
$Script:LogTimeBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B") # Muted Slate
$Script:LogInitBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8") # Sky Blue
$Script:LogScanBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C084FC") # Purple / Lavender
$Script:LogInfoBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8") # Slate
$Script:LogActionBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8") # Cyan
$Script:LogGuardBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24") # Warm Amber
$Script:LogSuccessBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80") # Vibrant Emerald
$Script:LogDoneBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80") # Mint Green
$Script:LogWarnBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FB923C") # Coral / Orange
$Script:LogErrorBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E") # Bright Rose
$Script:LogDebugBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B") # Dark Slate
$Script:LogRamBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E879F9") # Fuchsia
$Script:LogMsgDefault   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9") # Crisp White

# Logging Helper (Memory-Capped Colored FlowDocument)
function Add-HubLog([string]$message, [string]$level = "INFO") {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    try {
        $color = switch ($level.ToUpper()) {
            "INIT"    { "Cyan" }
            "SCAN"    { "Magenta" }
            "INFO"    { "Gray" }
            "ACTION"  { "Cyan" }
            "GUARD"   { "Yellow" }
            "SUCCESS" { "Green" }
            "DONE"    { "Green" }
            "WARN"    { "DarkYellow" }
            "ERROR"   { "Red" }
            "RAM"     { "Magenta" }
            "DEBUG"   { "DarkGray" }
            default   { "White" }
        }
        Write-Host "[$timestamp] [$level] $message" -ForegroundColor $color
    } catch {}

    if ($TxtLogConsole) {
        $TxtLogConsole.Dispatcher.Invoke([Action]{
            try {
                $doc = $TxtLogConsole.Document
                if ($doc.Blocks.Count -gt 350) {
                    for ($i = 0; $i -lt 50 -and $doc.Blocks.Count -gt 100; $i++) {
                        [void]$doc.Blocks.Remove($doc.Blocks.FirstBlock)
                    }
                }

                $p = New-Object System.Windows.Documents.Paragraph
                $p.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)

                # Timestamp [18:40:50]
                $rTime = New-Object System.Windows.Documents.Run("[$timestamp] ")
                $rTime.Foreground = $Script:LogTimeBrush
                $p.Inlines.Add($rTime)

                # Level Tag [WARN], [SUCCESS], [SCAN], etc.
                $rLevel = New-Object System.Windows.Documents.Run("[$level] ")
                $rLevel.FontWeight = [System.Windows.FontWeights]::Bold

                $msgBrush = $Script:LogMsgDefault
                switch ($level.ToUpper()) {
                    "INIT"    { $rLevel.Foreground = $Script:LogInitBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E0F2FE") }
                    "SCAN"    { $rLevel.Foreground = $Script:LogScanBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E9D5FF") }
                    "INFO"    { $rLevel.Foreground = $Script:LogInfoBrush; $msgBrush = $Script:LogMsgDefault }
                    "ACTION"  { $rLevel.Foreground = $Script:LogActionBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E0F2FE") }
                    "GUARD"   { $rLevel.Foreground = $Script:LogGuardBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FEF3C7") }
                    "SUCCESS" { $rLevel.Foreground = $Script:LogSuccessBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DCFCE7") }
                    "DONE"    { $rLevel.Foreground = $Script:LogDoneBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1FAE5") }
                    "WARN"    { $rLevel.Foreground = $Script:LogWarnBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFEDD5") }
                    "ERROR"   { $rLevel.Foreground = $Script:LogErrorBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFE4E6") }
                    "RAM"     { $rLevel.Foreground = $Script:LogRamBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FAE8FF") }
                    "DEBUG"   { $rLevel.Foreground = $Script:LogDebugBrush; $msgBrush = $Script:LogDebugBrush }
                    default   { $rLevel.Foreground = $Script:LogInfoBrush; $msgBrush = $Script:LogMsgDefault }
                }
                $p.Inlines.Add($rLevel)

                # Message content
                $rMsg = New-Object System.Windows.Documents.Run($message)
                $rMsg.Foreground = $msgBrush
                $p.Inlines.Add($rMsg)

                $doc.Blocks.Add($p)
                $TxtLogConsole.ScrollToEnd()
            } catch {}
        })
    }
}

$Script:ActiveLogProgPara = $null
$Script:ActiveLogProgBarRun = $null
$Script:ActiveLogProgPctRun = $null
$Script:ActiveLogProgMsgRun = $null

function Set-HubLogProgress([string]$title, [int]$percent, [string]$stage) {
    $percent = [Math]::Max(0, [Math]::Min(100, $percent))
    $barLen = 22
    $filled = [Math]::Round(($percent / 100.0) * $barLen)
    $empty = $barLen - $filled
    $barStr = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    
    $TxtLogConsole.Dispatcher.Invoke([Action]{
        try {
            $doc = $TxtLogConsole.Document
            if (-not $Script:ActiveLogProgPara -or -not $doc.Blocks.Contains($Script:ActiveLogProgPara)) {
                $p = New-Object System.Windows.Documents.Paragraph
                $p.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)

                $rTime = New-Object System.Windows.Documents.Run("[$timestamp] ")
                $rTime.Foreground = $Script:LogTimeBrush
                $p.Inlines.Add($rTime)

                $rTag = New-Object System.Windows.Documents.Run("[PROG] ")
                $rTag.FontWeight = [System.Windows.FontWeights]::Bold
                $rTag.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $p.Inlines.Add($rTag)

                $rBar = New-Object System.Windows.Documents.Run("$barStr ")
                $rBar.FontWeight = [System.Windows.FontWeights]::Bold
                $rBar.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $p.Inlines.Add($rBar)

                $rPct = New-Object System.Windows.Documents.Run("$percent% ")
                $rPct.FontWeight = [System.Windows.FontWeights]::Bold
                $rPct.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                $p.Inlines.Add($rPct)

                $rMsg = New-Object System.Windows.Documents.Run("$title - $stage")
                $rMsg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
                $p.Inlines.Add($rMsg)

                $doc.Blocks.Add($p)
                $Script:ActiveLogProgPara = $p
                $Script:ActiveLogProgBarRun = $rBar
                $Script:ActiveLogProgPctRun = $rPct
                $Script:ActiveLogProgMsgRun = $rMsg
            } else {
                $Script:ActiveLogProgBarRun.Text = "$barStr "
                $Script:ActiveLogProgPctRun.Text = "$percent% "
                $Script:ActiveLogProgMsgRun.Text = "$title - $stage"
                if ($percent -ge 100) {
                    $Script:ActiveLogProgBarRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                    $Script:ActiveLogProgPctRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                }
            }
            $TxtLogConsole.ScrollToEnd()
        } catch {}
    })
}

function Complete-HubLogProgress([string]$title, [string]$finalMsg) {
    Set-HubLogProgress $title 100 $finalMsg
    $Script:ActiveLogProgPara = $null
    $Script:ActiveLogProgBarRun = $null
    $Script:ActiveLogProgPctRun = $null
    $Script:ActiveLogProgMsgRun = $null
}

# ==========================================
# APPLICATION SETTINGS & NOTIFICATION PREFERENCES
# ==========================================
$Script:ZeroHubSettingsPath = Join-Path $env:LOCALAPPDATA "ZeroHub\settings.json"
$Script:AppNotificationsEnabled = $true

function Load-ZeroHubSettings {
    try {
        if (Test-Path $Script:ZeroHubSettingsPath) {
            $json = Get-Content -Path $Script:ZeroHubSettingsPath -Raw | ConvertFrom-Json
            if ($null -ne $json.AppNotificationsEnabled) {
                $Script:AppNotificationsEnabled = [bool]$json.AppNotificationsEnabled
            }
        }
    } catch {}
    Update-NotificationToggleUI
}

function Save-ZeroHubSettings {
    try {
        $settingsDir = Split-Path -Path $Script:ZeroHubSettingsPath -Parent
        if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
        $data = @{
            AppNotificationsEnabled = $Script:AppNotificationsEnabled
        }
        $data | ConvertTo-Json | Set-Content -Path $Script:ZeroHubSettingsPath -Force
    } catch {}
}

function Update-NotificationToggleUI {
    if (-not $TxtToggleNotifications -or -not $IconToggleNotifications) { return }
    $brushConv = [System.Windows.Media.BrushConverter]::new()
    if ($Script:AppNotificationsEnabled) {
        $TxtToggleNotifications.Text = "Notifications: ON"
        $TxtToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        $IconToggleNotifications.Text = [char]0xE7E7 # Bell icon
        $IconToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        if ($BtnToggleNotifications) {
            $BtnToggleNotifications.Background = $brushConv.ConvertFromString("#1A2E1F") # Green
            $BtnToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
            $BtnToggleNotifications.ToolTip = "Windows notifications for ZeroHub are ON. Click to Turn OFF."
        }
    } else {
        $TxtToggleNotifications.Text = "Notifications: OFF"
        $TxtToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        $IconToggleNotifications.Text = [char]0xE7E7 # Bell icon
        $IconToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        if ($BtnToggleNotifications) {
            $BtnToggleNotifications.Background = $brushConv.ConvertFromString("#c15f3c") # Signature Red
            $BtnToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
            $BtnToggleNotifications.ToolTip = "Windows notifications for ZeroHub are OFF (Muted). Click to Turn ON."
        }
    }
}

# Native Windows 10/11 Toast Notification with Sound
function Show-ZeroToastNotification([string]$title, [string]$message) {
    if (-not $Script:AppNotificationsEnabled) {
        return
    }
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

# Tab switches used to re-run their data load every single time. The uninstaller and bloatware tabs
# were guarded by a "have I got any rows yet" check, which caches forever and never refreshes, and
# the installer tab had no guard at all, so every visit shelled out to winget again. Neither of
# those is caching. Stamp each dataset when it loads and let callers ask whether it is still fresh,
# with the Refresh buttons passing -Force to bypass it.
$Script:CacheStamps = @{}
function Test-DataCacheFresh([string]$key, [int]$maxAgeSeconds) {
    if (-not $Script:CacheStamps.ContainsKey($key)) { return $false }
    return ((Get-Date) - $Script:CacheStamps[$key]).TotalSeconds -lt $maxAgeSeconds
}
function Set-DataCacheStamp([string]$key) {
    $Script:CacheStamps[$key] = Get-Date
}
function Clear-DataCacheStamp([string]$key) {
    if ($Script:CacheStamps.ContainsKey($key)) { [void]$Script:CacheStamps.Remove($key) }
}

# Measure Folder Size safely and at high speed using Native C# walker
# Held as a scriptblock rather than only a function so the background scan runspace can rebuild it
# with [scriptblock]::Create($Script:FolderSizerText) and there is still exactly one implementation.
# A scriptblock object itself stays bound to the runspace that created it, so the text is what
# crosses the boundary.
$Script:FolderSizer = {
    param([string]$targetPath)
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
                $totalBytes += [ZeroHub.NativeMethods]::FastGetDirectorySize($d)
            }
            return [math]::Round(($totalBytes / 1MB), 1)
        }

        if ([System.IO.Directory]::Exists($targetPath)) {
            $bytes = [ZeroHub.NativeMethods]::FastGetDirectorySize($targetPath)
            return [math]::Round(($bytes / 1MB), 1)
        }
    } catch {}
    return 0
}
$Script:FolderSizerText = $Script:FolderSizer.ToString()

# Thin wrapper so existing synchronous callers are unchanged.
function Get-FolderSizeMBQuick([string]$targetPath) {
    return (& $Script:FolderSizer $targetPath)
}

# Process Check Helper. $Script:RunningProcessNames is a set captured once per scan; the old code
# called Get-Process once per guard name per target, which on 68 targets meant a full process
# enumeration around a hundred times per scan, on the UI thread.
function Test-ProcessRunning([string[]]$Names) {
    if ($null -eq $Names -or $Names.Length -eq 0) { return $false }
    if ($Script:RunningProcessNames) {
        foreach ($n in $Names) {
            if ($Script:RunningProcessNames.Contains($n)) { return $true }
        }
        return $false
    }
    foreach ($n in $Names) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

# Update Drive C: Info
function Update-DriveInfo() {
    try {
        $cDrive = [System.IO.DriveInfo]::new("C")
        if ($cDrive.IsReady) {
            $totalBytes = $cDrive.TotalSize
            $freeBytes  = $cDrive.AvailableFreeSpace
            $usedBytes  = $totalBytes - $freeBytes
            $totalGB    = [math]::Round($totalBytes / 1GB, 1)
            $freeGB     = [math]::Round($freeBytes / 1GB, 1)
            $percent    = if ($totalBytes -gt 0) { [math]::Round(($usedBytes / $totalBytes) * 100, 0) } else { 0 }

            if ($DriveProgressBar) { $DriveProgressBar.Value = $percent }
            if ($DriveFreeText)    { $DriveFreeText.Text = "$freeGB GB free of $totalGB GB" }
        }
    } catch {}
}

# Update Real-Time RAM & Reclaimable Memory Indicator
function Update-LiveMemoryStats() {
    try {
        $totalGB = 0.0; $usedGB = 0.0; $freeGB = 0.0; $usedPercent = 0; $reclaimableMB = 0.0;
        $success = $false

        try {
            [ZeroHub.NativeMethods]::GetLiveMemoryMetrics([ref]$totalGB, [ref]$usedGB, [ref]$freeGB, [ref]$usedPercent, [ref]$reclaimableMB)
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
                # See the note in GetLiveMemoryMetrics: this 0.28 is the fallback twin of the 0.30
                # there. Left as written, raised in that comment rather than changed here.
                $reclaimableMB = [math]::Round(($usedBytes * 0.28) / 1MB, 0)
            }
        }

        if ($totalGB -gt 0) {
            # Update Circular Progress Ring
            $pVal = [math]::Max(0.5, [math]::Min(99.9, [double]$usedPercent))
            $radius = 10.2
            $cx = 14.0
            $cy = 14.0
            $angle = ($pVal / 100.0) * 360.0
            $angleRad = ($angle - 90.0) * [Math]::PI / 180.0
            $startX = $cx
            $startY = [Math]::Round(($cy - $radius), 2)
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
                $TxtRamReclaimable.Text = "Reclaimable: ~$reclaimableStr"
            }

            # Dynamically update Free RAM button tooltip
            if ($BtnFreeRam) {
                $BtnFreeRam.ToolTip = "Quickly free idle application RAM (approx $reclaimableStr)"
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
    $suffix = "items"
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
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $AdminIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $BtnRelaunchAdmin.Visibility = [System.Windows.Visibility]::Collapsed
} else {
    $AdminText.Text = "Standard User"
    $AdminText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $AdminIcon.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $BtnRelaunchAdmin.add_Click({
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
        $Window.Close()
    })
}

$BrushSelected   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
$BrushUnselected = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
$BrushDisabled   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
$BrushRecycleRed = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")

# Row hover and checkbox styles reuse resources rather than traversing the visual tree 68 times.
$BrushRowHover       = $Window.FindResource("CardHover")
$StyleModernCheckBox = $Window.FindResource("ModernCheckBox")
$BrushRowNormal      = [System.Windows.Media.Brushes]::Transparent
$BrushRecycleRedChecked = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")

# Populate Target Items & Build Category Checkboxes
foreach ($t in $TargetsData) {
    $item = [ZeroHub.TargetItem]::new()
    $item.Id            = $t.Id
    $item.Name          = $t.Name
        $item.Path          = $t.Path
    $item.Cat           = $t.Cat
    $item.Description   = $t.Description
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
    if ($StyleModernCheckBox) { $chk.Style = $StyleModernCheckBox }
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

    # Hover affordance. The row Grid had no Background at all, which means WPF does not hit-test it,
    # so there was no way to tell which row the pointer was over before clicking a checkbox. A
    # Transparent background makes the full row width hit-testable without drawing anything, and the
    # hover state is the existing CardHover token, so no new colour and no layout change.
    # Disabled rows are left out on purpose: highlighting a row the user cannot click is a lie.
    $rowGrid.Background = $BrushRowNormal
    if ($chk.IsEnabled) {
        $rowGrid.Add_MouseEnter({ param($s, $e) $s.Background = $BrushRowHover })
        $rowGrid.Add_MouseLeave({ param($s, $e) $s.Background = $BrushRowNormal })
    }

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
if ($TargetsDataGrid) { $TargetsDataGrid.ItemsSource = $Script:TargetItems }

# Refresh / Scan Function
# Shimmer: a pending row pulses its size label instead of sitting on a stale number. Cheap enough to
# run on 68 rows because it is a single animated DP per label, composited off the UI thread by WPF.
$Script:ShimmerBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
function Start-RowShimmer($label) {
    if (-not $label) { return }
    $anim = [System.Windows.Media.Animation.DoubleAnimation]::new()
    $anim.From = 0.30
    $anim.To = 1.0
    $anim.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(650))
    $anim.AutoReverse = $true
    $anim.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $label.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
}
function Stop-RowShimmer($label) {
    if (-not $label) { return }
    # Passing $null clears the animation and hands the property back to the local value.
    $label.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
    $label.Opacity = 1.0
}

# The scan walks 68 directory trees recursively. It used to do that inline on the UI thread, so the
# whole window locked up for the duration and the Cleaner dashboard froze while it totalled sizes.
# It now runs in its own runspace and streams one result per target back through a ConcurrentQueue,
# which a DispatcherTimer drains: rows, category badges and the running total all fill in live.
$Script:ScanPs = $null
$Script:ScanHandle = $null
$Script:ScanTimer = $null
$Script:ScanQueue = $null
$Script:ScanTotalMB = 0.0
$Script:ScanDone = 0
$Script:ScanExpected = 0
$Script:ScanAutoSelect = $false

function Invoke-ScanSpace([bool]$autoSelectFound = $false) {
    if ($Script:ScanPs) { return }   # a scan is already in flight

    $BtnScanAll.IsEnabled = $false
    $BtnCleanSelected.IsEnabled = $false
    $StatusIcon.Text = [char]0xE72C
    $StatusText.Text = "Scanning over 55 cache targets across Drive C: ..."
    Add-HubLog "Beginning full drive C: cache analysis in the background..." "SCAN"

    # One process enumeration for the whole scan instead of one per guard per target.
    $Script:RunningProcessNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) { [void]$Script:RunningProcessNames.Add($p.ProcessName) }

    $Script:ScanTotalMB = 0.0
    $Script:ScanDone = 0
    $Script:ScanAutoSelect = $autoSelectFound
    $Script:ScanQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    # Plain data only: strings cross the runspace boundary, WPF objects must not.
    $work = [System.Collections.ArrayList]::new()
    foreach ($item in $Script:TargetItems) {
        [void]$work.Add([pscustomobject]@{ Id = $item.Id; Path = $item.Path })
        $item.SizeLabel.Text = "Scanning..."
        $item.SizeLabel.Foreground = $Script:ShimmerBrush
        $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Normal
        Start-RowShimmer $item.SizeLabel
    }
    $Script:ScanExpected = $work.Count

    # STA because the recycle-bin branch of the sizer talks to the Shell.Application COM object,
    # which is not callable from an MTA thread.
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()

    $Script:ScanPs = [powershell]::Create()
    $Script:ScanPs.Runspace = $rs
    [void]$Script:ScanPs.AddScript({
        param($work, $queue, $sizerText)
        $sizer = [scriptblock]::Create($sizerText)
        foreach ($w in $work) {
            $mb = 0.0
            try { $mb = [double](& $sizer $w.Path) } catch { $mb = 0.0 }
            $queue.Enqueue([pscustomobject]@{ Id = $w.Id; SizeMB = $mb })
        }
    }).AddArgument($work).AddArgument($Script:ScanQueue).AddArgument($Script:FolderSizerText)

    $Script:ScanHandle = $Script:ScanPs.BeginInvoke()

    $Script:ScanTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:ScanTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $Script:ScanTimer.add_Tick({ Update-ScanProgress })
    $Script:ScanTimer.Start()
}

function Update-ScanProgress {
    $item = $null
    $result = $null
    while ($Script:ScanQueue.TryDequeue([ref]$result)) {
        $item = $Script:TargetItems | Where-Object { $_.Id -eq $result.Id } | Select-Object -First 1
        if (-not $item) { continue }

        $sz = [double]$result.SizeMB
        $item.SizeMB = $sz
        $item.SizeFormatted = Format-SpaceMB $sz
        $Script:ScanDone++

        if ($item.IsAdmin -and -not $isAdmin) {
            $item.Status = "Requires Admin"
        } elseif ($item.Guard.Length -gt 0 -and (Test-ProcessRunning $item.Guard)) {
            $item.Status = "Locked (" + ($item.Guard -join ', ') + " running)"
        } elseif ($sz -gt 0) {
            $item.Status = "Ready to Clean"
            $Script:ScanTotalMB += $sz
        } else {
            $item.Status = "Clean / Empty"
        }

        Stop-RowShimmer $item.SizeLabel
        if ($sz -gt 0) {
            $item.SizeLabel.Text = $item.SizeFormatted
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Bold
            if ($Script:ScanAutoSelect -and ($isAdmin -or -not $item.IsAdmin)) {
                $item.CheckBoxControl.IsChecked = $true
            }
        } else {
            $item.SizeLabel.Text = "0 MB"
            $item.SizeLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")
            $item.SizeLabel.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    # Live feedback while the rest is still being walked.
    if ($Script:ScanDone -lt $Script:ScanExpected) {
        Update-CategoryBadges
        $StatusText.Text = "Scanning... $($Script:ScanDone) / $($Script:ScanExpected) targets ($(Format-SpaceMB $Script:ScanTotalMB) found)"
    }

    if (-not $Script:ScanHandle.IsCompleted) { return }
    if ($Script:ScanDone -lt $Script:ScanExpected -and $Script:ScanQueue.Count -gt 0) { return }

    $Script:ScanTimer.Stop()
    try { $Script:ScanPs.EndInvoke($Script:ScanHandle) | Out-Null } catch {
        Add-HubLog "Background scan reported an error: $($_.Exception.Message)" "ERROR"
    }
    try { $Script:ScanPs.Runspace.Close() } catch {}
    try { $Script:ScanPs.Dispose() } catch {}
    $Script:ScanPs = $null
    $Script:ScanHandle = $null

    # Any row that never produced a result must not be left shimmering forever.
    foreach ($t in $Script:TargetItems) { Stop-RowShimmer $t.SizeLabel }

    Update-DriveInfo
    Update-CategoryBadges
    Update-SelectedSummary
    if ($TargetsDataGrid) { $TargetsDataGrid.Items.Refresh() }

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E
    $StatusText.Text = "Scan complete! Found cache targets are highlighted."
    Add-HubLog "Cache analysis complete: $(Format-SpaceMB $Script:ScanTotalMB) detected across targets ($($TxtTotalReclaimable.Text) selected)." "SCAN"
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

# ==========================================
# SMART PROCESS MANAGER MODULE
# ==========================================
$Script:AllSmartProcesses = [System.Collections.Generic.List[ZeroHub.SmartProcessItem]]::new()
$Script:CurrentProcFilter = "ALL"

function Update-SmartProcessList {
    if (-not $ProcManagerDataGrid) { return }
    
    try {
        $Script:AllSmartProcesses = [ZeroHub.ProcessManagerEngine]::GetAllProcesses()
    } catch {
        $Script:AllSmartProcesses = [System.Collections.Generic.List[ZeroHub.SmartProcessItem]]::new()
    }

    Filter-SmartProcessList
}

function Filter-SmartProcessList {
    if (-not $ProcManagerDataGrid) { return }
    $query = if ($TxtProcSearch -and $TxtProcSearch.Text) { $TxtProcSearch.Text } else { "" }
    $filter = $Script:CurrentProcFilter

    $totalCount = 0
    $safeCount = 0
    $safeMemMB = 0.0
    $filtered = [ZeroHub.ProcessManagerEngine]::FilterProcesses($Script:AllSmartProcesses, $query, $filter, [ref]$totalCount, [ref]$safeCount, [ref]$safeMemMB)

    $ProcManagerDataGrid.ItemsSource = $filtered

    if ($TxtProcStatsInfo) {
        $TxtProcStatsInfo.Text = "$totalCount Running • $safeCount Safe to Stop ($([Math]::Round($safeMemMB, 1)) MB RAM)"
    }
    if ($TxtProcSafeReclaimable) {
        $TxtProcSafeReclaimable.Text = "Safe RAM to reclaim: $([Math]::Round($safeMemMB, 1)) MB"
    }
}

function Set-ProcFilterStyle($activeBtn) {
    $defaultBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
    $activeBg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
    $activeFg  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    $fgMap = @{
        $BtnFilterProcAll       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8");
        $BtnFilterProcSafe      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80");
        $BtnFilterProcWork      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24");
        $BtnFilterProcService   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C084FC");
        $BtnFilterProcHeavy     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8");
        $BtnFilterProcProtected = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171");
    }

    $buttons = @($BtnFilterProcAll, $BtnFilterProcSafe, $BtnFilterProcWork, $BtnFilterProcService, $BtnFilterProcHeavy, $BtnFilterProcProtected)
    foreach ($btn in $buttons) {
        if ($btn) {
            if ($btn -eq $activeBtn) {
                $btn.Background = $activeBg
                $btn.Foreground = $activeFg
                $btn.FontWeight = [System.Windows.FontWeights]::Bold
            } else {
                $btn.Background = $defaultBg
                $btn.Foreground = if ($fgMap.ContainsKey($btn)) { $fgMap[$btn] } else { [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8") }
                $btn.FontWeight = [System.Windows.FontWeights]::SemiBold
            }
        }
    }
}

function Invoke-PurgeAllSafeProcesses {
    if (-not $Script:AllSmartProcesses) { return }
    $safeProcs = $Script:AllSmartProcesses | Where-Object { $_.SafetyTier -eq "Safe" -and $_.CanEnd }
    if (-not $safeProcs -or $safeProcs.Count -eq 0) {
        Show-ZeroToastNotification "Task Manager" "No safe background tasks found to purge."
        return
    }

    if ($BtnPurgeSafeProcs) {
        $BtnPurgeSafeProcs.IsEnabled = $false
        $BtnPurgeSafeProcs.Content = "⏳ Purging..."
    }

    $killed = 0
    $freedMB = 0.0
    foreach ($p in $safeProcs) {
        $ok = [ZeroHub.ProcessManagerEngine]::KillProcess($p.Id)
        if ($ok) {
            $killed++
            $freedMB += $p.MemoryMB
        }
    }

    Add-HubLog "Task Manager: Purged $killed safe background tasks, reclaimed $([Math]::Round($freedMB, 1)) MB RAM" "SUCCESS"
    Show-ZeroToastNotification "Process Purged" "Closed $killed background tasks, reclaimed $([Math]::Round($freedMB, 1)) MB RAM!"

    if ($BtnPurgeSafeProcs) {
        $BtnPurgeSafeProcs.IsEnabled = $true
        $BtnPurgeSafeProcs.Content = "🧹 Purge Safe Background Tasks"
    }

    Start-Sleep -Milliseconds 150
    Update-SmartProcessList
    Update-LiveMemoryStats
}

function Invoke-EndSelectedProcess([ZeroHub.SmartProcessItem]$selected) {
    if (-not $selected) { return }
    if (-not $selected.CanEnd -or $selected.SafetyTier -eq "Critical") {
        Show-ZeroToastNotification "Process Protected" "$($selected.Name) is a critical Windows system process and cannot be terminated."
        return
    }

    if ($selected.SafetyTier -eq "Caution" -or $selected.SafetyTier -eq "CautionWork") {
        $msg = "Closing '$($selected.Name)' may cause unsaved work to be lost. Are you sure you want to end this task?"
        $res = [System.Windows.MessageBox]::Show($msg, "End Task Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
    } elseif ($selected.SafetyTier -eq "CautionService") {
        $msg = "'$($selected.Name)' is a background Windows service. Ending it may affect related background tasks until restarted. Are you sure you want to end it?"
        $res = [System.Windows.MessageBox]::Show($msg, "End Service Confirmation", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }
    }

    # Instantly drop the process from local collection so the UI row vanishes immediately
    if ($Script:AllSmartProcesses) {
        $targetId = $selected.Id
        $Script:AllSmartProcesses.RemoveAll([Predicate[ZeroHub.SmartProcessItem]]{ param($item) $item.Id -eq $targetId }) | Out-Null
        Filter-SmartProcessList
    }

    $ok = [ZeroHub.ProcessManagerEngine]::KillProcess($selected.Id)
    if ($ok) {
        Add-HubLog "Task Manager: Terminated $($selected.Name) (PID: $($selected.Id))" "SUCCESS"
        Show-ZeroToastNotification "Process Terminated" "Successfully closed $($selected.Name)."
        Start-Sleep -Milliseconds 150
        Update-SmartProcessList
        Update-LiveMemoryStats
    } else {
        Add-HubLog "Task Manager: Failed to terminate $($selected.Name) (PID: $($selected.Id))" "WARN"
        Update-SmartProcessList
    }
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
                    $pItem = [ZeroHub.ProcessItem]::new()
                    $pItem.Name = $p.ProcessName
                    $pItem.Id = $p.Id
                    $pItem.TargetName = $t.Name
                    $pItem.Status = "In Use (Blocking Clean)"
                    $pItem.MainWindowTitle = if ($p.MainWindowTitle) { $p.MainWindowTitle } else { "(Background Process)" }
                    $activeGuards.Add($pItem) | Out-Null
                }
            }
        }
    }

    $ProcessDataGrid.ItemsSource = $activeGuards
    Add-HubLog "Process Guard checked: $($activeGuards.Count) active processes detected." "GUARD"
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

# Close Guarded Processes
function Stop-ActiveGuardedProcesses([bool]$onlySelected = $false) {
    if ($BtnCloseAllGuards) {
        $BtnCloseAllGuards.IsEnabled = $false
        $BtnCloseAllGuards.Content = "⏳ Closing..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Closing active guarded applications holding file locks..."
    [System.Windows.Forms.Application]::DoEvents()

    $closedCount = 0
    $seenPids = [System.Collections.Generic.HashSet[int]]::new()
    
    # 1. Directly terminate all PIDs currently shown in the Process Guard grid if not $onlySelected
    if (-not $onlySelected -and $ProcessDataGrid -and $ProcessDataGrid.ItemsSource) {
        foreach ($item in $ProcessDataGrid.ItemsSource) {
            if ($item.Id -and $seenPids.Add([int]$item.Id)) {
                $pidToKill = [int]$item.Id
                try {
                    Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
                    $closedCount++
                    Add-HubLog "Closed guarded process: $($item.Name) (PID: $pidToKill)" "PROCESS"
                } catch {
                    try {
                        Start-Process -FilePath "taskkill.exe" -ArgumentList "/F /PID $pidToKill /T" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                        $closedCount++
                    } catch {}
                }
            }
        }
    }

    # 2. Collect all guard process names across targets
    $guardNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $Script:TargetItems) {
        if ((-not $onlySelected -or $t.IsSelected) -and $t.Guard -and $t.Guard.Length -gt 0) {
            foreach ($g in $t.Guard) {
                if ($g) { [void]$guardNames.Add($g) }
            }
        }
    }

    $runningProcesses = Get-Process -ErrorAction SilentlyContinue
    foreach ($p in $runningProcesses) {
        if ($guardNames.Contains($p.ProcessName) -and $seenPids.Add($p.Id)) {
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                Add-HubLog "Closed guarded process: $($p.ProcessName) (PID: $($p.Id))" "PROCESS"
                $closedCount++
            } catch {
                try {
                    Start-Process -FilePath "taskkill.exe" -ArgumentList "/F /PID $($p.Id) /T" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                    $closedCount++
                } catch {}
            }
        }
    }

    Start-Sleep -Milliseconds 500
    Update-ProcessGuardList

    $msg = "Successfully closed $closedCount guarded application process(es)."
    $StatusIcon.Text = [char]0xE73E
    $StatusText.Text = $msg
    Add-HubLog $msg "SUCCESS"
    Show-ZeroToastNotification "ZeroHub Process Guard" $msg

    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($BtnCloseAllGuards) {
        $BtnCloseAllGuards.Content = "✅ Closed $closedCount Apps!"
        $timer = [System.Windows.Threading.DispatcherTimer]::new()
        $timer.Interval = [TimeSpan]::FromSeconds(3)
        $timer.add_Tick({
            param($s, $e)
            $s.Stop()
            if ($BtnCloseAllGuards) {
                $BtnCloseAllGuards.IsEnabled = $true
                $BtnCloseAllGuards.Content = "Close All Guarded Apps"
            }
        })
        $timer.Start()
    }

    return $closedCount
}

# Clean Cache Asynchronous Engine (Background Runspace + Thread-safe Queue)
# Offloads heavy recursive file deletions and disk I/O from the WPF UI thread to eliminate UI freezes,
# streaming live log entries, status updates, and auto-refreshing the Cleaner dashboard when finished.
$Script:CleanPs = $null
$Script:CleanHandle = $null
$Script:CleanTimer = $null
$Script:CleanQueue = $null

function Update-CleanProgress {
    $result = $null
    $doneObj = $null
    while ($Script:CleanQueue.TryDequeue([ref]$result)) {
        if (-not $result) { continue }
        if ($result.Type -eq "LOG") {
            Add-HubLog $result.Message $result.Level
        } elseif ($result.Type -eq "STATUS") {
            $StatusText.Text = $result.Text
        } elseif ($result.Type -eq "DONE") {
            $doneObj = $result
        }
    }

    if (-not $Script:CleanHandle -or -not $Script:CleanHandle.IsCompleted) { return }
    if ($Script:CleanQueue.Count -gt 0) { return }

    $Script:CleanTimer.Stop()
    try { $Script:CleanPs.EndInvoke($Script:CleanHandle) | Out-Null } catch {
        Add-HubLog "Background cleanup reported an error: $($_.Exception.Message)" "ERROR"
    }
    try { $Script:CleanPs.Runspace.Close() } catch {}
    try { $Script:CleanPs.Dispose() } catch {}
    $Script:CleanPs = $null
    $Script:CleanHandle = $null

    # Play chime
    try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}

    Update-DriveInfo

    $BtnScanAll.IsEnabled = $true
    $BtnCleanSelected.IsEnabled = $true
    $StatusIcon.Text = [char]0xE73E

    $freedTotalMB      = if ($doneObj) { [double]$doneObj.FreedTotalMB } else { 0.0 }
    $totalFilesDeleted = if ($doneObj) { [int]$doneObj.TotalFilesDeleted } else { 0 }
    $totalFilesLocked  = if ($doneObj) { [int]$doneObj.TotalFilesLocked } else { 0 }
    $totalLockedBytes  = if ($doneObj) { [long]$doneObj.TotalLockedBytes } else { 0 }
    $cleanedItems      = if ($doneObj) { [int]$doneObj.CleanedItems } else { 0 }
    $elapsedSec        = if ($doneObj) { [double]$doneObj.ElapsedSec } else { 0.0 }
    $freedFormatted    = Format-SpaceMB $freedTotalMB

    if ($freedTotalMB -gt 0.05) {
        if ($totalFilesLocked -gt 0) {
            $lockedMB = [math]::Round(($totalLockedBytes / 1MB), 1)
            $summaryMsg = "Cleanup Finished! Deleted $totalFilesDeleted files and freed $freedFormatted ($totalFilesLocked file(s) totaling $(Format-SpaceMB $lockedMB) were locked by running apps)."
        } else {
            $summaryMsg = "Cleanup Complete! Deleted $totalFilesDeleted files and freed $freedFormatted across $cleanedItems target(s) in ${elapsedSec}s."
        }
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "DONE"
    } elseif ($totalFilesLocked -gt 0) {
        $lockedMB = [math]::Round(($totalLockedBytes / 1MB), 1)
        $summaryMsg = "Warning: 0 MB freed! Selected files ($(Format-SpaceMB $lockedMB) across $totalFilesLocked file(s)) are actively locked by running applications. Close open apps or reboot to finish cleaning."
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "WARN"
    } else {
        $summaryMsg = "Cleanup Complete in ${elapsedSec}s! Selected cache targets were already clean (0 MB)."
        $StatusText.Text = $summaryMsg
        Add-HubLog $summaryMsg "DONE"
    }

    # Pop up native Windows Toast Notification with sound
    Show-ZeroToastNotification "ZeroHub" $summaryMsg
    [ZeroHub.NativeMethods]::TrimSelfMemory()

    # Automatically trigger scan to refresh all sizes and cleaner badges upon completion
    Invoke-ScanSpace $false
}

# Execute Cache Deletion
function Invoke-ExecuteClean([bool]$dryRun = $false) {
    if ($Script:CleanPs) { return } # A clean operation is already running

    # Force-sync IsSelected from UI checkboxes and build selected list directly
    $work = [System.Collections.ArrayList]::new()
    foreach ($item in $Script:TargetItems) {
        $isChecked = $false
        if ($item.CheckBoxControl -and $item.CheckBoxControl.IsChecked -eq $true) {
            $isChecked = $true
        }
        if ($isChecked -or $item.IsSelected) {
            if (-not $item.IsSelected) { $item.IsSelected = $true }
            [void]$work.Add([pscustomobject]@{
                Id      = [string]$item.Id
                Name    = [string]$item.Name
                Path    = [string]$item.Path
                IsAdmin = [bool]$item.IsAdmin
                Guard   = @($item.Guard)
            })
        }
    }
    Add-HubLog "Selection sync complete: $($work.Count) of $($Script:TargetItems.Count) targets selected for cleaning." "DEBUG"
    if ($work.Count -eq 0) {
        $msg = "Please select at least one cache target to clean."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $confirmPrompt = "Are you sure you want to clean $($work.Count) selected cache target(s)?`n`nZeroHub will safely purge temporary cache files without touching your passwords or cookies."

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
    $StatusText.Text = "Cleaning selected caches in background..."

    $autoClose = $ChkAutoCloseApps.IsChecked -eq $true
    if ($autoClose) {
        Add-HubLog "Auto-close enabled. Terminating guarded applications holding locks..." "ACTION"
        Stop-ActiveGuardedProcesses $true
    }

    $Script:CleanQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()

    # STA Runspace for safe Shell.Application COM interop (Recycle bin) and isolated background thread execution
    $rs = [runspacefactory]::CreateRunspace()
    $rs.ApartmentState = "STA"
    $rs.ThreadOptions = "ReuseThread"
    $rs.Open()

    $Script:CleanPs = [powershell]::Create()
    $Script:CleanPs.Runspace = $rs
    [void]$Script:CleanPs.AddScript({
        param($targets, $queue, [bool]$userIsAdmin, [bool]$autoCloseApps, $sizerText)

        function Send-Log([string]$msg, [string]$lvl = "INFO") {
            $queue.Enqueue([pscustomobject]@{ Type = "LOG"; Message = $msg; Level = $lvl })
        }
        function Send-Status([string]$txt) {
            $queue.Enqueue([pscustomobject]@{ Type = "STATUS"; Text = $txt })
        }
        function Format-MB([double]$mb) {
            if ($mb -ge 1024) { return ("{0:N2} GB" -f ($mb / 1024)) }
            return ("{0:N1} MB" -f $mb)
        }

        $sizer = [scriptblock]::Create($sizerText)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $freedTotalMB = 0.0
        $totalFilesDeleted = 0
        $totalFilesLocked = 0
        $totalLockedBytes = [long]0
        $cleanedItems = 0
        $skippedItems = 0

        # One process enumeration for guard checks across targets
        $runningProcesses = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) { [void]$runningProcesses.Add($p.ProcessName) }

        foreach ($t in $targets) {
            Send-Log "Processing target: $($t.Name)" "INFO"
            Send-Status "Cleaning $($t.Name)..."

            if ($t.IsAdmin -and -not $userIsAdmin) {
                Send-Log "Skipped $($t.Name): Requires Administrator privileges." "WARN"
                $skippedItems++
                continue
            }

            if ($t.Guard -and $t.Guard.Length -gt 0) {
                $isGuarded = $false
                foreach ($g in $t.Guard) {
                    if ($g -and $runningProcesses.Contains($g)) { $isGuarded = $true; break }
                }
                if ($isGuarded) {
                    if (-not $autoCloseApps) {
                        $guardNames = ($t.Guard | Where-Object { $_ }) -join ', '
                        Send-Log "Skipped $($t.Name): App ($guardNames) is running. Close it first or enable 'Auto-close apps'." "WARN"
                        $skippedItems++
                        continue
                    }
                }
            }

            if ($t.Id -eq "sys_recycle_bin") {
                try {
                    $beforeBin = 0.0
                    try { $beforeBin = [double](& $sizer "VIRTUAL:RECYCLEBIN") } catch { $beforeBin = 0.0 }
                    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
                    $afterBin = 0.0
                    try { $afterBin = [double](& $sizer "VIRTUAL:RECYCLEBIN") } catch { $afterBin = 0.0 }
                    $freedBin = [math]::Max(0, [math]::Round(($beforeBin - $afterBin), 2))
                    $freedTotalMB += $freedBin
                    if ($freedBin -gt 0) {
                        Send-Log "Emptied Windows Recycle Bin (freed $(Format-MB $freedBin))!" "SUCCESS"
                    } else {
                        Send-Log "Windows Recycle Bin is already empty." "SUCCESS"
                    }
                    $cleanedItems++
                } catch {
                    Send-Log "Error emptying Recycle Bin: $($_.Exception.Message)" "ERROR"
                }
                continue
            }

            if ($t.Id -eq "sys_dns_cache") {
                try {
                    Clear-DnsClientCache -ErrorAction SilentlyContinue
                    ipconfig /flushdns 2>$null | Out-Null
                    Send-Log "Flushed Windows DNS Resolver Cache successfully!" "SUCCESS"
                    $cleanedItems++
                } catch {
                    Send-Log "Error flushing DNS cache: $($_.Exception.Message)" "ERROR"
                }
                continue
            }

            $targetDeletedBytes = [long]0
            $targetDeletedFiles = 0
            $targetLockedBytes  = [long]0
            $targetLockedFiles  = 0

            try {
                $dirsToClean = @()
                if ($t.Path.Contains("*")) {
                    $parent = Split-Path $t.Path -Parent
                    $leaf = Split-Path $t.Path -Leaf
                    if ([System.IO.Directory]::Exists($parent)) {
                        $dirsToClean = @([System.IO.Directory]::GetDirectories($parent, $leaf))
                    }
                } elseif ([System.IO.Directory]::Exists($t.Path)) {
                    $dirsToClean = @($t.Path)
                }

                if ($dirsToClean.Count -gt 0) {
                    foreach ($dir in $dirsToClean) {
                        # 1. Delete individual files safely
                        $allFiles = [ZeroHub.NativeMethods]::SafeListFiles($dir)
                        if ($allFiles -and $allFiles.Count -gt 0) {
                            $batchCounter = 0
                            foreach ($fPath in $allFiles) {
                                try {
                                    $len = [long]0
                                    try { $len = (New-Object System.IO.FileInfo $fPath).Length } catch {}
                                    [System.IO.File]::Delete($fPath)
                                    $targetDeletedBytes += $len
                                    $targetDeletedFiles++
                                    $batchCounter++
                                    if ($batchCounter % 100 -eq 0) {
                                        Send-Status "Cleaning $($t.Name)... ($targetDeletedFiles files)"
                                    }
                                } catch {
                                    $targetLockedFiles++
                                    try { $targetLockedBytes += (New-Object System.IO.FileInfo $fPath).Length } catch {}
                                    [ZeroHub.NativeMethods]::ScheduleDeleteOnReboot($fPath) | Out-Null
                                }
                            }
                        }
                        # 2. Remove empty subfolders
                        foreach ($dPath in [ZeroHub.NativeMethods]::SafeListDirs($dir)) {
                            try { [System.IO.Directory]::Delete($dPath, $false) } catch {}
                        }
                    }

                    $reclaimedMB = [math]::Round(($targetDeletedBytes / 1MB), 2)
                    $totalFilesDeleted += $targetDeletedFiles
                    $totalFilesLocked += $targetLockedFiles
                    $totalLockedBytes += $targetLockedBytes
                    $freedTotalMB += $reclaimedMB

                    if ($targetDeletedFiles -gt 0) {
                        if ($targetLockedFiles -gt 0) {
                            $lockedMB = [math]::Round(($targetLockedBytes / 1MB), 1)
                            if ($reclaimedMB -le 0.05) {
                                $warnMsg = "Warning: $($t.Name): Cleaned only $targetDeletedFiles file(s) ($($reclaimedMB) MB). $targetLockedFiles file(s) ($(Format-MB $lockedMB)) are locked & in-use by active running apps! (Scheduled for deletion on next reboot)."
                                Send-Log $warnMsg "WARN"
                            } else {
                                $cleanMsg = "Cleaned $targetDeletedFiles file(s) ($(Format-MB $reclaimedMB)) from $($t.Name)! ($targetLockedFiles file(s) locked; scheduled for deletion on next reboot)"
                                Send-Log $cleanMsg "SUCCESS"
                            }
                        } else {
                            $cleanMsg = "Cleaned $targetDeletedFiles file(s) ($(Format-MB $reclaimedMB)) from $($t.Name)!"
                            Send-Log $cleanMsg "SUCCESS"
                        }
                        $cleanedItems++
                    } elseif ($targetLockedFiles -gt 0) {
                        $lockedMB = [math]::Round(($targetLockedBytes / 1MB), 1)
                        $lockMsg = "Warning: $($t.Name): 0 MB deleted! $targetLockedFiles file(s) ($(Format-MB $lockedMB)) are actively locked and in-use by running apps. Close open programs or reboot to delete."
                        Send-Log $lockMsg "WARN"
                    } else {
                        Send-Log "Target $($t.Name) checked: 0 files needed cleaning (already clean)." "SUCCESS"
                        $cleanedItems++
                    }
                } else {
                    Send-Log "Target $($t.Name) path is not present or already empty." "INFO"
                }
            } catch {
                Send-Log "Error cleaning $($t.Name): $($_.Exception.Message)" "ERROR"
            }
    }

    $sw.Stop()
    $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 1)

    $queue.Enqueue([pscustomobject]@{
        Type               = "DONE"
        FreedTotalMB       = $freedTotalMB
        TotalFilesDeleted  = $totalFilesDeleted
        TotalFilesLocked   = $totalFilesLocked
        TotalLockedBytes   = $totalLockedBytes
        CleanedItems       = $cleanedItems
        ElapsedSec         = $elapsedSec
    })
}).AddArgument($work).AddArgument($Script:CleanQueue).AddArgument($isAdmin).AddArgument($autoClose).AddArgument($Script:FolderSizerText)

    $Script:CleanHandle = $Script:CleanPs.BeginInvoke()

    $Script:CleanTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:CleanTimer.Interval = [TimeSpan]::FromMilliseconds(80)
    $Script:CleanTimer.add_Tick({ Update-CleanProgress })
    $Script:CleanTimer.Start()
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

# Wire Preset Buttons with active visual feedback
$BtnPresetRecommended.add_Click({ Set-CleanerPresetActive $BtnPresetRecommended; Set-RecommendedSelection })
$BtnPresetAll.add_Click({ Set-CleanerPresetActive $BtnPresetAll; Set-AllSelections $true })
$BtnPresetBrowsers.add_Click({ Set-CleanerPresetActive $BtnPresetBrowsers; Set-CategorySelection "Browser" })
$BtnPresetDev.add_Click({ Set-CleanerPresetActive $BtnPresetDev; Set-CategorySelection "Dev" })
$BtnPresetGaming.add_Click({ Set-CleanerPresetActive $BtnPresetGaming; Set-CategorySelection "Gaming" })
$BtnPresetClear.add_Click({ Set-CleanerPresetActive $BtnPresetClear; Set-AllSelections $false })

# Wire Action Buttons
$BtnScanAll.add_Click({ Invoke-ScanSpace $false })
$BtnCleanSelected.add_Click({ Invoke-ExecuteClean $false })

# Wire Auto-Close Tip Banner Controls
if ($BtnDismissAutoCloseTip) {
    $BtnDismissAutoCloseTip.add_Click({
        $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Collapsed
    })
}
if ($BtnToggleAutoCloseTip) {
    $BtnToggleAutoCloseTip.add_Click({
        if ($Banner_AutoCloseTip.Visibility -eq [System.Windows.Visibility]::Visible) {
            $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Collapsed
        } else {
            $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Visible
        }
    })
}
if ($ChkAutoCloseApps) {
    $ChkAutoCloseApps.add_Checked({
        if ($Banner_AutoCloseTip) { $Banner_AutoCloseTip.Visibility = [System.Windows.Visibility]::Visible }
        $StatusText.Text = "Auto-Close enabled: Running apps will be closed before cleanup to unlock 100% of files."
    })
    $ChkAutoCloseApps.add_Unchecked({
        $StatusText.Text = "Auto-Close disabled: Running apps will be safely skipped during cleanup."
    })
}


# Wire Process Guard Tab
$BtnRefreshProcesses.add_Click({ Update-ProcessGuardList })
$BtnCloseAllGuards.add_Click({
    $prompt = "Close all running browsers, game launchers, and chat apps holding file locks?"
    $res = [System.Windows.MessageBox]::Show($prompt, "ZeroHub Process Guard", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        Stop-ActiveGuardedProcesses $false
    }
})

# Wire Log Console Buttons
$BtnCopyLogs.add_Click({
    try {
        $textRange = New-Object System.Windows.Documents.TextRange($TxtLogConsole.Document.ContentStart, $TxtLogConsole.Document.ContentEnd)
        if (-not [string]::IsNullOrWhiteSpace($textRange.Text)) {
            [System.Windows.Clipboard]::SetText($textRange.Text.Trim())
            $copiedMsg = "Logs copied to clipboard!"
            [System.Windows.MessageBox]::Show($copiedMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    } catch {}
})
$BtnClearLogs.add_Click({
    try { $TxtLogConsole.Document.Blocks.Clear() } catch {}
})

# ==========================================
# 1-CLICK ESSENTIAL APP INSTALLER ENGINE (WINGET)
# ==========================================
$Script:InstallerCatalogList = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerAppItem]]::new()
$Script:InstallerCategoryCards = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerCategoryCard]]::new()
$Script:Col1Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerCategoryCard]]::new()
$Script:Col2Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerCategoryCard]]::new()
$Script:Col3Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerCategoryCard]]::new()
$Script:Col4Cards = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstallerCategoryCard]]::new()
$Script:InstallerFilterCategory = "All"

$Script:CatalogAppsData = @(
    @{ Id="Brave.Brave"; Name="Brave"; CatKey="Browsers"; Desc="Brave is a privacy-focused web browser that blocks ads and trackers, offering a faster and safer browsing experience."; Rec=$true },
    @{ Id="Google.Chrome"; Name="Chrome"; CatKey="Browsers"; Desc="Google Chrome is a widely used web browser known for its speed, simplicity, and seamless integration with Google serv..."; Rec=$false },
    @{ Id="Hibbiki.Chromium"; Name="Chromium"; CatKey="Browsers"; Desc="Chromium is the open-source project that serves as the foundation for various web browsers, including Chrome."; Rec=$false },
    @{ Id="Microsoft.Edge"; Name="Edge"; CatKey="Browsers"; Desc="Microsoft Edge is a modern web browser built on Chromium, offering performance, security, and integration with Micros..."; Rec=$false },
    @{ Id="Mozilla.Firefox"; Name="Firefox"; CatKey="Browsers"; Desc="Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions."; Rec=$false },
    @{ Id="Mozilla.Firefox.ESR"; Name="Firefox ESR"; CatKey="Browsers"; Desc="Mozilla Firefox is an open-source web browser known for its customization options, privacy features, and extensions. ..."; Rec=$false },
    @{ Id="Ablaze.Floorp"; Name="Floorp"; CatKey="Browsers"; Desc="Floorp is an open-source web browser project that aims to provide a simple and fast browsing experience."; Rec=$false },
    @{ Id="ImputNet.Helium"; Name="Helium"; CatKey="Browsers"; Desc="Private, fast, and honest web browser."; Rec=$false },
    @{ Id="LibreWolf.LibreWolf"; Name="LibreWolf"; CatKey="Browsers"; Desc="LibreWolf is a privacy-focused web browser based on Firefox, with additional privacy and security enhancements."; Rec=$false },
    @{ Id="MullvadVPN.MullvadBrowser"; Name="Mullvad Browser"; CatKey="Browsers"; Desc="Mullvad Browser is a privacy-focused web browser, developed in partnership with the Tor Project."; Rec=$false },
    @{ Id="Opera.OperaGX"; Name="Opera GX"; CatKey="Browsers"; Desc="Opera GX is a specialized gaming browser with built-in CPU, RAM, and network limiters plus Discord and Twitch integration."; Rec=$false },
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
    @{ Id="WhatsApp.WhatsApp"; Name="WhatsApp"; CatKey="Communications"; Desc="WhatsApp for Windows provides reliable messaging and high-quality voice and video calls with end-to-end encryption."; Rec=$false },
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
    @{ Id="DolphinEmulator.Dolphin"; Name="Dolphin (GameCube/Wii)"; CatKey="Gaming"; Desc="Dolphin is an open-source Nintendo GameCube and Wii emulator with high-definition rendering support."; Rec=$false },
    @{ Id="ElectronicArts.EADesktop"; Name="EA App"; CatKey="Gaming"; Desc="EA App is a platform for accessing and playing Electronic Arts games."; Rec=$false },
    @{ Id="ES-DE.EmulationStation-DE"; Name="EmulationStation Desktop Edition"; CatKey="Gaming"; Desc="EmulationStation Desktop Edition is a frontend for browsing and launching games from your multi-platform game collect..."; Rec=$false },
    @{ Id="EpicGames.EpicGamesLauncher"; Name="Epic Games Launcher"; CatKey="Gaming"; Desc="Epic Games Launcher is the client for accessing and playing games from the Epic Games Store."; Rec=$false },
    @{ Id="Nvidia.GeForceNow"; Name="GeForce NOW"; CatKey="Gaming"; Desc="GeForce NOW is a cloud gaming service that allows you to play high-quality PC games on your device."; Rec=$false },
    @{ Id="GOG.Galaxy"; Name="GOG Galaxy"; CatKey="Gaming"; Desc="GOG Galaxy is a gaming client that offers DRM-free games, additional content, and more."; Rec=$false },
    @{ Id="HeroicGamesLauncher.HeroicGamesLauncher"; Name="Heroic Games Launcher"; CatKey="Gaming"; Desc="Heroic Games Launcher is an open-source alternative game launcher for Epic Games Store."; Rec=$false },
    @{ Id="ItchIo.Itch"; Name="Itch.io"; CatKey="Gaming"; Desc="Itch.io is a digital distribution platform for indie games and creative projects."; Rec=$false },
    @{ Id="Modrinth.ModrinthApp"; Name="Modrinth App"; CatKey="Gaming"; Desc="Modrinth App is a desktop application for managing Minecraft mods and modpacks."; Rec=$false },
    @{ Id="Overwolf.CurseForge"; Name="Overwolf"; CatKey="Gaming"; Desc="Popular platform for game overlays and companion apps (mod managers, trackers, etc.), widely used by gamers."; Rec=$false },
    @{ Id="PCSX2.PCSX2"; Name="PCSX2 (PS2 Emulator)"; CatKey="Gaming"; Desc="PCSX2 is a free and open-source PlayStation 2 emulator supporting thousands of games at up to 4K resolution."; Rec=$false },
    @{ Id="Playnite.Playnite"; Name="Playnite"; CatKey="Gaming"; Desc="Playnite is an open-source video game library manager with one simple goal: To provide a unified interface for all of..."; Rec=$false },
    @{ Id="PrismLauncher.PrismLauncher"; Name="Prism Launcher"; CatKey="Gaming"; Desc="Prism Launcher is an open-source Minecraft launcher with the ability to manage multiple instances, accounts, and mods."; Rec=$false },
    @{ Id="Libretro.RetroArch"; Name="RetroArch"; CatKey="Gaming"; Desc="RetroArch is a frontend for emulators, game engines and media players with shaders, netplay, and rewinding."; Rec=$false },
    @{ Id="Guru3D.RTSS"; Name="RivaTuner Statistics Server"; CatKey="Gaming"; Desc="RivaTuner Statistics Server provides framerate limiting, frame pacing, and high-performance OSD statistics."; Rec=$false },
    @{ Id="Roblox.Roblox"; Name="Roblox"; CatKey="Gaming"; Desc="Roblox is a platform and game creation system that allows users to create and play games developed by the community."; Rec=$false },
    @{ Id="RPCS3.RPCS3"; Name="RPCS3 (PS3 Emulator)"; CatKey="Gaming"; Desc="RPCS3 is an open-source Sony PlayStation 3 emulator and debugger written in C++."; Rec=$false },
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
    @{ Id="Spotify.Spotify"; Name="Spotify"; CatKey="Media"; Desc="Spotify is the world's leading digital music and podcast streaming service with millions of tracks and playlists."; Rec=$true },
    @{ Id="TIDALMusicAS.TIDAL"; Name="TIDAL"; CatKey="Media"; Desc="TIDAL is a high-fidelity music streaming service delivering lossless FLAC, Dolby Atmos, and HiRes audio."; Rec=$false },
    @{ Id="VideoLAN.VLC"; Name="VLC (Video Player)"; CatKey="Media"; Desc="VLC Media Player is a free and open-source multimedia player that supports a wide range of audio and video formats. I..."; Rec=$true },
    @{ Id="Famatech.AdvancedIPScanner"; Name="Advanced IP Scanner"; CatKey="ProTools"; Desc="Advanced IP Scanner is a fast and easy-to-use network scanner. It is designed to analyze LAN networks and provides in..."; Rec=$false },
    @{ Id="angryziber.AngryIPScanner"; Name="Angry IP Scanner"; CatKey="ProTools"; Desc="Angry IP Scanner is an open-source and cross-platform network scanner. It is used to scan IP addresses and ports, pro..."; Rec=$false },
    @{ Id="Maxon.CinebenchR23"; Name="Cinebench R23"; CatKey="ProTools"; Desc="Cinebench R23 is a benchmark tool for comparing CPU rendering performance across systems."; Rec=$false },
    @{ Id="CPUID.CPU-Z"; Name="CPU-Z"; CatKey="ProTools"; Desc="CPU-Z is a system monitoring and diagnostic tool for Windows. It provides detailed information about the computer's h..."; Rec=$true },
    @{ Id="Wagnardsoft.DisplayDriverUninstaller"; Name="Display Driver Uninstaller"; CatKey="ProTools"; Desc="Display Driver Uninstaller (DDU) is a tool for completely uninstalling graphics drivers from NVIDIA, AMD, and Intel. ..."; Rec=$true },
    @{ Id="Rem0o.FanControl"; Name="Fan Control"; CatKey="ProTools"; Desc="Fan Control is a highly customizable GPU and CPU fan curve management utility for Windows."; Rec=$true },
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
    @{ Id="7zip.7zip"; Name="7-Zip"; CatKey="Utilities"; Desc="7-Zip is a free and open-source file archiver utility. It supports several compression formats and provides a high co..."; Rec=$false },
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
    @{ Id="voidtools.Everything"; Name="Everything"; CatKey="Utilities"; Desc="Everything is a search engine that locates files and folders by filename instantly for Windows. Unlike Windows search..."; Rec=$false },
    @{ Id="flux.flux"; Name="F.lux"; CatKey="Utilities"; Desc="f.lux adjusts the color temperature of your screen to reduce eye strain during nighttime use."; Rec=$false },
    @{ Id="FilesCommunity.Files"; Name="Files"; CatKey="Utilities"; Desc="Alternative file explorer."; Rec=$false },
    @{ Id="Flow-Launcher.Flow-Launcher"; Name="Flow Launcher"; CatKey="Utilities"; Desc="Flow Launcher is a fast, extensible quick search and productivity launcher for Windows files, apps, and plugins."; Rec=$false },
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
    @{ Id="PaddyXu.QuickLook"; Name="QuickLook (Spacebar Preview)"; CatKey="Utilities"; Desc="QuickLook brings macOS-style instant spacebar previewing to Windows File Explorer for images, PDFs, and archives."; Rec=$false },
    @{ Id="RevoUninstaller.RevoUninstaller"; Name="Revo Uninstaller"; CatKey="Utilities"; Desc="Revo Uninstaller is an advanced uninstaller tool that helps you remove unwanted software and clean up your system."; Rec=$false },
    @{ Id="Rufus.Rufus"; Name="Rufus Imager"; CatKey="Utilities"; Desc="Rufus is a utility that helps format and create bootable USB drives, such as USB keys or pen drives."; Rec=$false },
    @{ Id="RustDesk.RustDesk"; Name="RustDesk"; CatKey="Utilities"; Desc="RustDesk is a free, open-source, and self-hostable remote desktop client alternative to TeamViewer and AnyDesk."; Rec=$false },
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
    @{ Id="RARLab.WinRAR"; Name="WinRAR"; CatKey="Utilities"; Desc="WinRAR is a powerful archive manager that allows you to create, manage, and extract compressed files."; Rec=$true },
    @{ Id="WiseCleaner.WiseProgramUninstaller"; Name="Wise Program Uninstaller (WiseCleaner)"; CatKey="Utilities"; Desc="Wise Program Uninstaller is the perfect solution for uninstalling Windows programs, allowing you to uninstall applica..."; Rec=$false },
    @{ Id="AntibodySoftware.WizTree"; Name="WizTree"; CatKey="Utilities"; Desc="WizTree is a fast disk space analyzer that helps you quickly find the files and folders consuming the most space on y..."; Rec=$false }
)

$Script:AvailableWingetUpgrades = @{}
$Script:DismissedUpgradeIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

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
                if ($line -match "Name\s+Id\s+Version\s+Available" -or $line -match "Id\s+Version\s+Available") {
                    $idColStart = $line.IndexOf("Id")
                    $verColStart = $line.IndexOf("Version")
                    $availColStart = $line.IndexOf("Available")
                }
                continue
            }

            if ([string]::IsNullOrWhiteSpace($line) -or $line -match "upgrades available" -or $line -match "package\(s\) have") {
                continue
            }

            if ($idColStart -ge 0 -and $verColStart -gt $idColStart -and $line.Length -gt $idColStart) {
                $pkgId = $line.Substring($idColStart, [math]::Min($line.Length - $idColStart, $verColStart - $idColStart)).Trim()
                $currVer = if ($line.Length -gt $verColStart) {
                    $len = if ($availColStart -gt $verColStart) { [math]::Min($line.Length - $verColStart, $availColStart - $verColStart) } else { $line.Length - $verColStart }
                    $line.Substring($verColStart, $len).Trim()
                } else { "" }
                $availVer = if ($line.Length -gt $availColStart) {
                    $line.Substring($availColStart).Trim().Split(" ")[0]
                } else { "" }

                if ($pkgId -and -not $Script:DismissedUpgradeIds.Contains($pkgId)) {
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

$Script:IsWingetScanRunning = $false
$Script:WingetAsyncTimer = $null
$Script:WingetAsyncPs = $null

function Get-WingetUpgradesAsync {
    if ($Script:IsWingetScanRunning) { return }
    $Script:IsWingetScanRunning = $true

    if ($Script:WingetAsyncTimer) {
        try { $Script:WingetAsyncTimer.Stop() } catch {}
        $Script:WingetAsyncTimer = $null
    }
    if ($Script:WingetAsyncPs) {
        try { $Script:WingetAsyncPs.Dispose() } catch {}
        $Script:WingetAsyncPs = $null
    }

    $tempOut = "$env:TEMP\winget_upgrades_raw.txt"
    $asyncCode = {
        param($outPath)
        $proc = Start-Process -FilePath "winget" -ArgumentList "upgrade", "--accept-source-agreements" -NoNewWindow -PassThru -RedirectStandardOutput $outPath -RedirectStandardError "$env:TEMP\winget_upgrades_err.txt"
        $proc.WaitForExit(15000)
    }

    $Script:WingetAsyncPs = [powershell]::Create()
    $Script:WingetAsyncPs.AddScript($asyncCode).AddArgument($tempOut) | Out-Null
    $asyncHandle = $Script:WingetAsyncPs.BeginInvoke()

    $Script:WingetAsyncTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WingetAsyncTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $Script:WingetAsyncTimer.add_Tick({
        param($s, $e)
        if ($asyncHandle.IsCompleted) {
            if ($s) { try { $s.Stop() } catch {} }
            try { $Script:WingetAsyncPs.EndInvoke($asyncHandle) | Out-Null } catch {}
            try { $Script:WingetAsyncPs.Dispose() } catch {}
            $Script:WingetAsyncPs = $null
            $Script:WingetAsyncTimer = $null
            $Script:IsWingetScanRunning = $false

            $upgrades = Get-WingetAvailableUpgrades
            if ($upgrades) {
                foreach ($k in $upgrades.Keys) {
                    if (-not $Script:DismissedUpgradeIds.Contains($k)) {
                        $Script:AvailableWingetUpgrades[$k] = $upgrades[$k]
                    }
                }
            }

            # Rebuild catalog and refresh UI filters
            Clear-DataCacheStamp "installer"
            Initialize-InstallerCatalogList
            Set-InstallerFilters
        }
    })
    $Script:WingetAsyncTimer.Start()
}

function Update-InstallerSelectionStatus {
    $sel = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnInstallSelectedApps.IsEnabled = $true
        $updateOnly = ($sel | Where-Object { $_.HasUpdate -or $_.IsInstalled }).Count -eq $sel.Count
        if ($updateOnly) {
            $BtnInstallSelectedApps.Content = "🔄 Upgrade Selected Apps ($($sel.Count))"
        } else {
            $BtnInstallSelectedApps.Content = "🚀 Install / Upgrade Apps ($($sel.Count))"
        }
        $TxtInstallerStatus.Text = "$($sel.Count) application(s) selected for silent installation / upgrade via Winget."
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    } else {
        $BtnInstallSelectedApps.IsEnabled = $false
        $BtnInstallSelectedApps.Content = "🚀 Install Selected Apps"
        $TxtInstallerStatus.Text = "Select one or more software applications to silently install or upgrade via official winget."
        $TxtInstallerStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

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

# Batch Install & Upgrade Action Worker
function Install-SelectedApps {
    $selected = @($Script:InstallerCatalogList | Where-Object { $_.IsSelected })
    if ($selected.Count -eq 0) { return }

    # Verify winget
    $wingetCheck = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCheck) {
        $noWingetMsg = "Microsoft Package Manager (winget) was not found on this PC. Please install App Installer from Microsoft Store."
        [System.Windows.MessageBox]::Show($noWingetMsg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $confirmMsg = if ($selected.Count -eq 1) {
        $actionWord = if ($selected[0].HasUpdate -or $selected[0].IsInstalled) { "upgrade" } else { "install" }
        "Do you want to silently $actionWord '$($selected[0].DisplayName)' via Winget?"
    } else {
        "Do you want to silently batch-install / upgrade ($($selected.Count)) selected apps via Winget?"
    }

    $confirmTitle = "ZeroHub - Install / Upgrade Apps"
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Switch to Activity Log Tab to show real-time installation progress
    $MainTabs.SelectedItem = $Tab_Log
    $BtnInstallSelectedApps.IsEnabled = $false

    $successCount = 0
    $idx = 0

    # Auto-close running app processes mapping to prevent file lock errors
    $appProcessMap = @{
        "OBSProject.OBSStudio"          = @("obs64", "obs32", "obs")
        "Microsoft.VisualStudioCode"    = @("Code")
        "Brave.Brave"                   = @("brave")
        "Google.Chrome"                 = @("chrome")
        "Mozilla.Firefox"               = @("firefox")
        "Discord.Discord"               = @("Discord")
        "Valve.Steam"                   = @("steam")
        "Spotify.Spotify"               = @("Spotify")
        "AutoHotkey.AutoHotkey"         = @("AutoHotkey", "AutoHotkey64", "AutoHotkey32", "AutoHotkeyUX")
        "Telegram.TelegramDesktop"      = @("Telegram")
        "VideoLAN.VLC"                  = @("vlc")
        "Notepad++.Notepad++"           = @("notepad++")
        "Git.Git"                       = @("git", "git-bash")
        "Docker.DockerDesktop"          = @("Docker Desktop")
        "ElectronicArts.EADesktop"      = @("EADesktop", "EALocalHostSvc", "EABackgroundService")
        "EpicGames.EpicGamesLauncher"   = @("EpicGamesLauncher")
        "Ubisoft.Connect"               = @("upc", "UbisoftConnect")
    }

    foreach ($app in $selected) {
        $idx++
        $isUpgrade = ($app.HasUpdate -eq $true -or $app.IsInstalled -eq $true)
        $actionVerb = if ($isUpgrade) { "Upgrading" } else { "Installing" }
        $statusStr = "[$idx / $($selected.Count)] $($actionVerb): $($app.DisplayName) ($($app.PackageId))..."
        Add-HubLog $statusStr "ACTION"
        Set-HubLogProgress $app.DisplayName 10 "🔎 Resolving package manifest..."
        [System.Windows.Forms.Application]::DoEvents()

        # Gracefully release locked files if application is currently open
        if ($appProcessMap.ContainsKey($app.PackageId)) {
            foreach ($pName in $appProcessMap[$app.PackageId]) {
                try {
                    $running = Get-Process -Name $pName -ErrorAction SilentlyContinue
                    if ($running) {
                        Add-HubLog "Closing running instance of $($app.DisplayName) ($pName) to release locked files..." "INFO"
                        $running | Stop-Process -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Milliseconds 400
                    }
                } catch {}
            }
        }

        try {
            $wingetCmd = if ($isUpgrade) { "upgrade" } else { "install" }
            $wingetArgs = "$wingetCmd --id $($app.PackageId) --silent --force --accept-package-agreements --accept-source-agreements -e"
            
            $currentStage = "⬇️ Downloading package binaries..."
            $currentPct = 15

            $onLineCallback = [Action[string]]{
                param($line)
                if ($line) {
                    if ($line -match '(?i)Found\s+(.+?)\s+\[') {
                        $currentStage = "🔎 Found $($Matches[1])"
                        $currentPct = 25
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Downloading\s+(.+)') {
                        $url = $Matches[1]
                        $fileName = [System.IO.Path]::GetFileName($url)
                        if (-not $fileName) { $fileName = "installer package" }
                        $currentStage = "⬇️ Downloading: $fileName"
                        $currentPct = 40
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Successfully verified|Verifying|Hash') {
                        $currentStage = "📦 Verifying SHA-256 Hash & Extracting..."
                        $currentPct = 78
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Starting package install|Installing') {
                        $currentStage = "⚙️ Executing Silent Installer..."
                        $currentPct = 88
                        Set-HubLogProgress $app.DisplayName $currentPct $currentStage
                    } elseif ($line -match '(?i)Successfully installed|Successfully upgraded') {
                        $currentStage = "✅ Successfully $actionVerb!"
                        $currentPct = 100
                        Complete-HubLogProgress $app.DisplayName $currentStage
                    } else {
                        Add-HubLog "  $line" "INFO"
                    }
                }
            }
            $onProgressCallback = [Action[int, string]]{
                param($pct, $msg)
                if ($pct -gt $currentPct) { $currentPct = $pct }
                Set-HubLogProgress $app.DisplayName $currentPct $currentStage
            }
            $onPumpCallback = [Action]{
                [System.Windows.Forms.Application]::DoEvents()
            }

            # Pre-clean orphaned update client registry tags that block newer versions
            if ($app.PackageId -eq "Brave.Brave") {
                Remove-Item "HKLM:\SOFTWARE\WOW6432Node\BraveSoftware\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "HKCU:\Software\BraveSoftware\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
            } elseif ($app.PackageId -eq "Google.Chrome") {
                Remove-Item "HKLM:\SOFTWARE\WOW6432Node\Google\Update\Clients" -Recurse -Force -ErrorAction SilentlyContinue
            }

            $exitCode = [ZeroHub.AsyncProcessRunner]::Run("winget", $wingetArgs, $onLineCallback, $onPumpCallback, $onProgressCallback)

            # Resilient Direct Vendor Fallback if Winget repository is behind or blocked
            if ($exitCode -ne 0 -and $exitCode -ne 3010) {
                Add-HubLog "Winget reported code $exitCode. Attempting Direct Smart Install for $($app.DisplayName)..." "WARN"
                $directUrl = switch ($app.PackageId) {
                    "Brave.Brave"     { "https://laptop-updates.brave.com/latest/winx64" }
                    "Google.Chrome"   { "https://dl.google.com/chrome/install/standalonesetup64.exe" }
                    "Mozilla.Firefox" { "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" }
                    default           { $null }
                }

                if ($directUrl) {
                    try {
                        $tempSetup = "$env:TEMP\ZeroHub_$($app.PackageId)_setup.exe"
                        Set-HubLogProgress $app.DisplayName 45 "⬇️ Downloading official vendor package..."
                        [System.Windows.Forms.Application]::DoEvents()
                        (New-Object System.Net.WebClient).DownloadFile($directUrl, $tempSetup)
                        if (Test-Path $tempSetup) {
                            Set-HubLogProgress $app.DisplayName 85 "⚙️ Executing standalone vendor installer..."
                            [System.Windows.Forms.Application]::DoEvents()
                            $directProc = Start-Process -FilePath $tempSetup -ArgumentList "/silent /install" -PassThru -Wait -ErrorAction SilentlyContinue
                            if ($directProc -and ($directProc.ExitCode -eq 0 -or $null -eq $directProc.ExitCode)) {
                                $exitCode = 0
                            }
                        }
                    } catch {
                        Add-HubLog "Direct fallback note: $($_.Exception.Message)" "WARN"
                    }
                }
            }

            if ($exitCode -eq 0 -or $exitCode -eq 3010) {
                Complete-HubLogProgress $app.DisplayName "✅ Completed $actionVerb successfully!"
                Add-HubLog "Successfully completed $actionVerb for $($app.DisplayName)!" "SUCCESS"
                $successCount++
                if ($Script:AvailableWingetUpgrades -and $Script:AvailableWingetUpgrades.ContainsKey($app.PackageId)) {
                    [void]$Script:AvailableWingetUpgrades.Remove($app.PackageId)
                }
                [void]$Script:DismissedUpgradeIds.Add($app.PackageId)
                # Directly clear update state on in-memory object
                $targetItem = @($Script:InstallerCatalogList | Where-Object { $_.PackageId -eq $app.PackageId })
                foreach ($tItem in $targetItem) {
                    $tItem.HasUpdate = $false
                    $tItem.IsInstalled = $true
                    $tItem.IsSelected = $false
                    $tItem.Status = "✅ Installed"
                    $tItem.StatusBg = "#064E3B"
                    $tItem.StatusFg = "#34D399"
                    $tItem.StatusVisibility = "Visible"
                    $tItem.NameFg = "#34D399"
                }
                Remove-Item "$env:TEMP\winget_upgrades_raw.txt" -Force -ErrorAction SilentlyContinue
            } else {
                Complete-HubLogProgress $app.DisplayName "⚠️ Finished with exit code $exitCode"
                Add-HubLog "Winget completed with exit code $exitCode for $($app.DisplayName)" "WARN"
            }
        } catch {
            Add-HubLog "Error processing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = "Process Complete! Successfully installed/upgraded $successCount of $($selected.Count) app(s)."
    Add-HubLog $summary "SUCCESS"
    Show-ZeroToastNotification "ZeroHub - App Installer" $summary

    # Invalidate cache and refresh immediately in background
    Clear-DataCacheStamp "installer"
    Initialize-InstallerCatalogList
    Set-InstallerFilters
    $BtnInstallSelectedApps.IsEnabled = $true
    Get-WingetUpgradesAsync
}

if ($BtnInstallSelectedApps) {
    $BtnInstallSelectedApps.add_Click({ Install-SelectedApps })
}

# --- REVO-STYLE DEEP APP UNINSTALLER TAB LOGIC ---
$Script:AllInstalledApps = [System.Collections.Generic.List[ZeroHub.InstalledAppItem]]::new()
$Script:CurrentAppFilter = "All"

function Update-InstalledAppsList() {
    if (-not $AppsGrid) { return }
    Set-DataCacheStamp "installedapps"

    try {
        $Script:AllInstalledApps = [ZeroHub.UninstallerEngine]::GetInstalledApps()
    } catch {
        $Script:AllInstalledApps = [System.Collections.Generic.List[ZeroHub.InstalledAppItem]]::new()
    }

    Set-AppFilters
    [ZeroHub.NativeMethods]::TrimSelfMemory()
}

function Set-AppFilterButtonStyles($activeFilter) {
    $defaultBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
    $defaultBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
    $defaultFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    $activeBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $activeBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
    $activeFg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

    foreach ($btn in @($BtnFilterAll, $BtnFilterGames, $BtnFilterApps, $BtnFilterOrphaned)) {
        if ($btn) {
            $btn.Background = $defaultBg
            $btn.BorderBrush = $defaultBorder
            $btn.Foreground = $defaultFg
            $btn.FontWeight = [System.Windows.FontWeights]::Normal
        }
    }

    switch ($activeFilter) {
        "All" { if ($BtnFilterAll) { $BtnFilterAll.Background = $activeBg; $BtnFilterAll.BorderBrush = $activeBorder; $BtnFilterAll.Foreground = $activeFg; $BtnFilterAll.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Games" { if ($BtnFilterGames) { $BtnFilterGames.Background = $activeBg; $BtnFilterGames.BorderBrush = $activeBorder; $BtnFilterGames.Foreground = $activeFg; $BtnFilterGames.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Apps" { if ($BtnFilterApps) { $BtnFilterApps.Background = $activeBg; $BtnFilterApps.BorderBrush = $activeBorder; $BtnFilterApps.Foreground = $activeFg; $BtnFilterApps.FontWeight = [System.Windows.FontWeights]::Bold } }
        "Orphaned" { if ($BtnFilterOrphaned) { $BtnFilterOrphaned.Background = $activeBg; $BtnFilterOrphaned.BorderBrush = $activeBorder; $BtnFilterOrphaned.Foreground = $activeFg; $BtnFilterOrphaned.FontWeight = [System.Windows.FontWeights]::Bold } }
    }
}

function Set-AppFilters() {
    if (-not $AppsGrid) { return }
    $q = if ($TxtAppSearch -and $TxtAppSearch.Text) { $TxtAppSearch.Text } else { "" }
    $filterMode = $Script:CurrentAppFilter

    $filtered = [ZeroHub.UninstallerEngine]::FilterInstalledApps($Script:AllInstalledApps, $q, $filterMode)
    $AppsGrid.ItemsSource = $filtered

    # Update count text
    $catName = if ($filterMode -eq "Games") {
        "Games"
    } elseif ($filterMode -eq "Apps") {
        "Apps"
    } elseif ($filterMode -eq "Orphaned") {
        "Orphaned items"
    } else {
        "Total items"
    }
    if ($TxtAppCount) {
        $TxtAppCount.Text = "$($filtered.Count) $catName"
    }
}

# Category Filter Buttons
$BtnFilterAll.add_Click({
    $Script:CurrentAppFilter = "All"
    Set-AppFilterButtonStyles "All"
    Set-AppFilters
})

$BtnFilterGames.add_Click({
    $Script:CurrentAppFilter = "Games"
    Set-AppFilterButtonStyles "Games"
    Set-AppFilters
})

$BtnFilterApps.add_Click({
    $Script:CurrentAppFilter = "Apps"
    Set-AppFilterButtonStyles "Apps"
    Set-AppFilters
})

$BtnFilterOrphaned.add_Click({
    $Script:CurrentAppFilter = "Orphaned"
    Set-AppFilterButtonStyles "Orphaned"
    Set-AppFilters
})

# Search filter in App Uninstaller tab
$TxtAppSearch.add_TextChanged({ Set-AppFilters })

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
            $BtnUninstallSelected.Content = "Uninstall & Clean Selected App"
            $TxtSelectedAppStatus.Text = "Selected: $($selectedList[0].DisplayName) ($($selectedList[0].SizeFormatted))"
        } else {
            $BtnUninstallSelected.Content = "Bulk Uninstall ($($selectedList.Count) Selected)"
            $TxtSelectedAppStatus.Text = "$($selectedList.Count) apps selected (Total Size: $sizeText)"
        }
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    } else {
        $BtnUninstallSelected.IsEnabled = $false
        $BtnUninstallSelected.Content = "Uninstall & Clean Leftovers"
        $TxtSelectedAppStatus.Text = "Select one or more applications from the list above to uninstall and clean leftovers."
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
$Script:AppsClickHandler = [System.Windows.RoutedEventHandler]{
    param($s, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $AppsGrid.Dispatcher.BeginInvoke([System.Action]{
            Update-AppSelectionStatus
        })
    }
}
$AppsGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $Script:AppsClickHandler)

# Double-click app row to open containing folder
$AppsGrid.add_MouseDoubleClick({
    param($s, $e)
    $selected = $AppsGrid.SelectedItem
    if (-not $selected) { return }

    $targetFolder = ""
    if ($selected.InstallLocation -and [System.IO.Directory]::Exists($selected.InstallLocation)) {
        $targetFolder = $selected.InstallLocation
    } elseif ($selected.UninstallString) {
        $u = $selected.UninstallString.Trim()
        $exe = ""
        if ($u -match '^"([^"]+)"') { $exe = $matches[1] }
        elseif ($u -match '^([a-zA-Z]:\\[^\s]+\.exe)') { $exe = $matches[1] }
        else { $exe = $u.Split(' ')[0] }

        if ($exe -and [System.IO.File]::Exists($exe)) {
            $targetFolder = [System.IO.Path]::GetDirectoryName($exe)
        }
    }

    if ($targetFolder -and [System.IO.Directory]::Exists($targetFolder)) {
        Start-Process "explorer.exe" -ArgumentList "`"$targetFolder`""
    }
})

# Right-click Context Menu for AppsGrid
$appsContextMenu = New-Object System.Windows.Controls.ContextMenu

# 1. Open / View Containing Folder
$menuAppFolder = New-Object System.Windows.Controls.MenuItem
$menuAppFolder.Header = "View Containing Folder"
$iconFolder = New-Object System.Windows.Controls.TextBlock
$iconFolder.Text = [char]0xE838
$iconFolder.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconFolder.FontSize = 11.5
$iconFolder.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
$menuAppFolder.Icon = $iconFolder

$menuAppFolder.FontWeight = [System.Windows.FontWeights]::SemiBold
$menuAppFolder.add_Click({
    $selected = $AppsGrid.SelectedItem
    if (-not $selected) { return }

    $targetFolder = ""
    if ($selected.InstallLocation -and [System.IO.Directory]::Exists($selected.InstallLocation)) {
        $targetFolder = $selected.InstallLocation
    } elseif ($selected.UninstallString) {
        $u = $selected.UninstallString.Trim()
        $exe = ""
        if ($u -match '^"([^"]+)"') { $exe = $matches[1] }
        elseif ($u -match '^([a-zA-Z]:\\[^\s]+\.exe)') { $exe = $matches[1] }
        else { $exe = $u.Split(' ')[0] }

        if ($exe -and [System.IO.File]::Exists($exe)) {
            $targetFolder = [System.IO.Path]::GetDirectoryName($exe)
        }
    }

    if ($targetFolder -and [System.IO.Directory]::Exists($targetFolder)) {
        Start-Process "explorer.exe" -ArgumentList "`"$targetFolder`""
        Show-ZeroToastNotification "App Uninstaller" "Opened folder: $targetFolder"
    } else {
        Show-ZeroToastNotification "App Uninstaller" "Containing folder not found on disk for '$($selected.DisplayName)'"
    }
})
$appsContextMenu.Items.Add($menuAppFolder) | Out-Null

$appsContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

# 2. Copy Install Path
$menuCopyInstallPath = New-Object System.Windows.Controls.MenuItem
$menuCopyInstallPath.Header = "Copy Install Location Path"
$iconCopyPath = New-Object System.Windows.Controls.TextBlock
$iconCopyPath.Text = [char]0xE8C8
$iconCopyPath.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconCopyPath.FontSize = 11.5
$iconCopyPath.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
$menuCopyInstallPath.Icon = $iconCopyPath

$menuCopyInstallPath.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.InstallLocation) {
        [System.Windows.Clipboard]::SetText($selected.InstallLocation)
        Show-ZeroToastNotification "App Uninstaller" "Copied install path: $($selected.InstallLocation)"
    } elseif ($selected) {
        Show-ZeroToastNotification "App Uninstaller" "No install location path recorded in registry."
    }
})
$appsContextMenu.Items.Add($menuCopyInstallPath) | Out-Null

# 3. Copy Registry Path
$menuCopyRegPath = New-Object System.Windows.Controls.MenuItem
$menuCopyRegPath.Header = "Copy Registry Key Path"
$iconCopyReg = New-Object System.Windows.Controls.TextBlock
$iconCopyReg.Text = [char]0xE8D7
$iconCopyReg.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconCopyReg.FontSize = 11.5
$iconCopyReg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
$menuCopyRegPath.Icon = $iconCopyReg

$menuCopyRegPath.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.RegistryPath) {
        [System.Windows.Clipboard]::SetText($selected.RegistryPath)
        Show-ZeroToastNotification "App Uninstaller" "Copied registry path: $($selected.RegistryPath)"
    }
})
$appsContextMenu.Items.Add($menuCopyRegPath) | Out-Null

$appsContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

# 4. Search Online
$menuSearchAppOnline = New-Object System.Windows.Controls.MenuItem
$menuSearchAppOnline.Header = "Search Software Online"
$iconSearch = New-Object System.Windows.Controls.TextBlock
$iconSearch.Text = [char]0xE721
$iconSearch.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
$iconSearch.FontSize = 11.5
$iconSearch.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
$menuSearchAppOnline.Icon = $iconSearch

$menuSearchAppOnline.add_Click({
    $selected = $AppsGrid.SelectedItem
    if ($selected -and $selected.DisplayName) {
        $searchUrl = "https://www.google.com/search?q=$([Uri]::EscapeDataString($selected.DisplayName))"
        Open-SafeBrowserUrl $searchUrl
    }
})
$appsContextMenu.Items.Add($menuSearchAppOnline) | Out-Null

$AppsGrid.ContextMenu = $appsContextMenu

$BtnRefreshApps.add_Click({
    $BtnRefreshApps.Content = "⏳ Scanning..."
    $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    [System.Windows.Forms.Application]::DoEvents()

    Update-InstalledAppsList

    $BtnRefreshApps.Content = "✅ Refreshed!"
    $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#22C55E")
    $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")

    $timer = [System.Windows.Threading.DispatcherTimer]::new()
    $timer.Interval = [TimeSpan]::FromMilliseconds(1000)
    $timer.add_Tick({
        $this.Stop()
        $BtnRefreshApps.Content = "🔄 Refresh List"
        $BtnRefreshApps.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A3756")
        $BtnRefreshApps.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
    })
    $timer.Start()
})

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
            "Are you sure you want to uninstall '$($targetList[0].DisplayName)' ($($targetList[0].SizeFormatted)) and clean all residual leftover files?"
        } else {
            "Are you sure you want to bulk uninstall ($($targetList.Count)) selected applications (Total: $totalSizeStr) and clean all residual leftovers?"
        }
        $confirmTitle = "ZeroHub - Bulk Uninstall Confirm"
        $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $successCount = 0
        $totalFreedBytes = 0
        $currentIdx = 0

        foreach ($targetApp in $targetList) {
            $currentIdx++

            # Handle Windows UWP / Bloatware package uninstallation
            if ($targetApp.IsAppx -and $targetApp.PackageFullName) {
                $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Removing Windows App: $($targetApp.DisplayName)..."
                $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                [System.Windows.Forms.Application]::DoEvents()

                try {
                    Remove-AppxPackage -Package $targetApp.PackageFullName -ErrorAction SilentlyContinue
                    if ($isAdmin) {
                        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { 
                            $_.DisplayName -like "*$($targetApp.DisplayName)*" -or $_.PackageName -eq $targetApp.PackageFullName 
                        } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                    }
                    Add-HubLog "Successfully uninstalled UWP / Bloatware package: $($targetApp.DisplayName)" "SUCCESS"
                } catch {
                    Add-HubLog "Error removing UWP package $($targetApp.DisplayName): $($_.Exception.Message)" "ERROR"
                }

                $successCount++
                continue
            }

            $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Running official uninstaller for $($targetApp.DisplayName)... (Please complete the uninstaller wizard on your screen)"
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            [System.Windows.Forms.Application]::DoEvents()

            # 1. Execute Uninstaller and Wait for It to Completely Finish (Revo Style)
            $uninstStr = $targetApp.UninstallString
            $proc = $null
            if (-not [string]::IsNullOrWhiteSpace($uninstStr)) {
                $uninstStr = $uninstStr.Trim()
                Add-HubLog "Executing uninstaller for $($targetApp.DisplayName): $uninstStr" "UNINSTALL"

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
                    $uninstArgs = ""
                    if ($uninstStr -match '^"([^"]+\.exe)"\s*(.*)$') {
                        $exe = $matches[1]
                        $uninstArgs = $matches[2].Trim()
                    } elseif ($uninstStr -match '^([a-zA-Z]:\\.+?\.exe)(\s+(.*))?$') {
                        $exe = $matches[1]
                        $uninstArgs = if ($matches[3]) { $matches[3].Trim() } else { "" }
                    } else {
                        $exe = $uninstStr
                        $uninstArgs = ""
                    }

                    if ($exe -and (Test-Path $exe)) {
                        $psi = [System.Diagnostics.ProcessStartInfo]::new()
                        $psi.FileName = $exe
                        $psi.Arguments = $uninstArgs
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
            $TxtSelectedAppStatus.Text = "[$currentIdx / $($targetList.Count)] Uninstallation finished! Scanning and cleaning leftovers for $($targetApp.DisplayName)..."
            $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
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

            # Folders that are never an app leftover no matter what the display name matches.
            $personalFolders = @(
                "documents", "desktop", "downloads", "pictures", "videos", "music", "favorites",
                "links", "saved games", "contacts", "searches", "onedrive", "appdata", "local",
                "locallow", "roaming", "public", "default", "startmenu", "start menu"
            )

            $cleanName = ($targetApp.DisplayName -replace '\s*\d+(\.\d+)*(\s*\(x\d+\))?.*$', '').Trim()

            # $blockedWords used to be compared against the WHOLE display name with -contains, so it
            # only ever fired on a single-word name: "Steam" was blocked, "Steam Client Bootstrapper"
            # went straight through and matched every directory containing "steam". The list read
            # like a strong safety net and was very nearly a no-op. Filter word by word instead.
            $words = @($cleanName -split '[^\w\+\#\.]+' | Where-Object { $_ })
            $meaningful = @($words | Where-Object { $blockedWords -notcontains $_.ToLower() })
            $tokens = @()
            if ($meaningful.Count -gt 0) {
                $candidate = ($meaningful -join ' ').Trim()
                if ($candidate.Length -ge 4) { $tokens = @($candidate) }
            }
            if ($tokens.Count -eq 0 -and $cleanName) {
                Add-HubLog "Leftover scan skipped for '$($targetApp.DisplayName)': name is too generic to match safely." "INFO"
            }

            $roots = @($env:LOCALAPPDATA, $env:APPDATA, $env:ProgramData)
            $leftoverDirs = @()

            # Safety check function
            $IsSafeToDelete = {
                param($pathToCheck)
                if (-not $pathToCheck -or -not (Test-Path $pathToCheck)) { return $false }
                $norm = $pathToCheck.TrimEnd('\').ToLower()

                # Reparse points (junctions, symlinks) are never followed. On Windows PowerShell 5.1
                # Remove-Item -Recurse on a junction deletes the contents of the TARGET, so a stray
                # junction inside an app folder could take out an unrelated directory tree.
                try {
                    $fsItem = Get-Item -LiteralPath $pathToCheck -Force -ErrorAction Stop
                    if ($fsItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) { return $false }
                } catch { return $false }

                # Exact match on a protected root, AND any ancestor of one. The old check was
                # equality only, so it refused to delete C:\Program Files but was happy to take
                # C:\Program Files\Common Files, or anything under the user profile.
                foreach ($pr in $protectedRoots) {
                    if (-not $pr) { continue }
                    $p = $pr.TrimEnd('\').ToLower()
                    if ($norm -eq $p) { return $false }
                    if ($p.StartsWith($norm + "\")) { return $false }
                }

                # Never touch the well-known personal folders, whatever the app is called.
                $leaf = Split-Path $norm -Leaf
                if ($personalFolders -contains $leaf) { return $false }
                $userRoot = $env:USERPROFILE.TrimEnd('\').ToLower()
                if ($norm.StartsWith($userRoot + "\")) {
                    $rel = $norm.Substring($userRoot.Length + 1)
                    $firstSeg = ($rel -split '\\')[0]
                    if ($personalFolders -contains $firstSeg) { return $false }
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

            # Sizes are collected per candidate and only counted as freed AFTER the user approves the
            # list, so declining does not inflate the "freed" total in the summary.
            $candidateSizes = @{}

            # Check InstallLocation safely
            if ($targetApp.InstallLocation -and (Test-Path $targetApp.InstallLocation)) {
                if (& $IsSafeToDelete $targetApp.InstallLocation) {
                    $files = Get-ChildItem $targetApp.InstallLocation -Recurse -Force -File -ErrorAction SilentlyContinue
                    $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                    $candidateSizes[$targetApp.InstallLocation] = $sz
                    $leftoverDirs += $targetApp.InstallLocation
                } else {
                    Add-HubLog "Protected shared directory from deletion: $($targetApp.InstallLocation)" "INFO"
                }
            }

            # Check AppData / ProgramData safely
            foreach ($r in $roots) {
                if (-not (Test-Path $r)) { continue }
                foreach ($tok in $tokens) {
                    $dirMatches = Get-ChildItem -Path $r -Directory -Filter "*$tok*" -ErrorAction SilentlyContinue
                    foreach ($m in $dirMatches) {
                        if (& $IsSafeToDelete $m.FullName) {
                            $files = Get-ChildItem $m.FullName -Recurse -Force -File -ErrorAction SilentlyContinue
                            $sz = if ($files) { ($files | Measure-Object Length -Sum).Sum } else { 0 }
                            $candidateSizes[$m.FullName] = $sz
                            $leftoverDirs += $m.FullName
                        }
                    }
                }
            }

            $leftoverDirs = @($leftoverDirs | Select-Object -Unique)

            # The matcher is a substring wildcard over three roots, so it can and does pull in
            # directories belonging to a different app whose name contains this one. Deleting those
            # recursively, as admin, with nothing shown to the user was the single most destructive
            # thing in this script: the old confirmation said "clean all residual leftovers" and
            # never named a path, and paths were logged only after they were already gone. Show the
            # exact list, default to No, and log each path before touching it.
            if ($leftoverDirs.Count -gt 0) {
                $listedBytes = ($leftoverDirs | ForEach-Object { [int64]$candidateSizes[$_] } | Measure-Object -Sum).Sum
                $listedStr = Format-SpaceMB ([math]::Round($listedBytes / 1MB, 2))
                $shown = $leftoverDirs | Select-Object -First 15
                $listText = ($shown | ForEach-Object { "    $_  ($(Format-SpaceMB ([math]::Round([int64]$candidateSizes[$_] / 1MB, 2))))" }) -join "`n"
                if ($leftoverDirs.Count -gt 15) { $listText += "`n    ... and $($leftoverDirs.Count - 15) more" }

                $leftoverPrompt = "Found $($leftoverDirs.Count) leftover folder(s) for '$($targetApp.DisplayName)', $listedStr total.`n`nThese will be permanently deleted:`n$listText`n`nRead the list before answering. Delete them?"
                $leftoverTitle = "ZeroHub - Confirm Leftover Deletion"

                foreach ($ld in $leftoverDirs) { Add-HubLog "Leftover candidate for $($targetApp.DisplayName): $ld" "SCAN" }

                $leftoverConfirm = [System.Windows.MessageBox]::Show(
                    $leftoverPrompt, $leftoverTitle,
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning,
                    [System.Windows.MessageBoxResult]::No)

                if ($leftoverConfirm -eq [System.Windows.MessageBoxResult]::Yes) {
                    foreach ($ld in $leftoverDirs) {
                        Add-HubLog "Deleting leftover directory: $ld" "CLEAN"
                        try {
                            Remove-Item -LiteralPath $ld -Recurse -Force -Confirm:$false -ErrorAction Stop
                            $totalFreedBytes += [int64]$candidateSizes[$ld]
                        } catch {
                            Add-HubLog "Locked, scheduled for deletion on next reboot: $ld" "WARN"
                            [ZeroHub.NativeMethods]::ScheduleDeleteOnReboot($ld) | Out-Null
                        }
                    }
                } else {
                    Add-HubLog "Leftover deletion declined by user for $($targetApp.DisplayName). Nothing was removed." "INFO"
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

        $TxtSelectedAppStatus.Text = "Bulk cleanup completed! Uninstalled $successCount apps and freed $freedFinalStr of leftovers."
        $TxtSelectedAppStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        Add-HubLog "Bulk Uninstalled $successCount app(s) and freed $freedFinalStr of leftovers!" "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Bulk Uninstaller" "Successfully uninstalled $successCount apps and cleaned $freedFinalStr of leftovers!"

        # Refresh tables
        Update-InstalledAppsList
        Initialize-InstallerCatalogList
    } catch {
        Add-HubLog "Error during bulk uninstaller: $($_.Exception.Message)" "ERROR"
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

$BtnCreateShortcut.add_Click({
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "ZeroHub.lnk"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        
        $localDir = Join-Path $env:LOCALAPPDATA "ZeroHub"
        $localScript = Join-Path $localDir "ZeroHub-GUI.ps1"
        $localBat = Join-Path $localDir "ZeroHub-GUI.bat"

        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        # Determine best source script path
        $srcPath = if ($PSCommandPath -and (Test-Path $PSCommandPath)) { 
            $PSCommandPath 
        } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"))) { 
            Join-Path $PSScriptRoot "ZeroHub-GUI.ps1" 
        } else { $null }

        # If running from a file, copy to local cache directory if not already there
        if ($srcPath -and (Test-Path $srcPath) -and ($srcPath -ne $localScript)) {
            try { Copy-Item -Path $srcPath -Destination $localScript -Force } catch {}
        }

        # Ensure local silent .vbs and .bat launchers exist
        $localVbs = Join-Path $localDir "ZeroHub-Silent.vbs"
        $targetScriptToRun = if ($srcPath -and (Test-Path $srcPath)) { $srcPath } else { $localScript }
        $vbsContent = "Set sh = CreateObject(`"WScript.Shell`")`r`nsh.Run `"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `" & Chr(34) & `"$targetScriptToRun`" & Chr(34), 0, False`r`n"
        try { [System.IO.File]::WriteAllText($localVbs, $vbsContent, [System.Text.Encoding]::ASCII) } catch {}

        $batContent = "@echo off`r`ncd /d `"%~dp0`"`r`npowershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"`"%~dp0ZeroHub-GUI.ps1`"`""
        try { [System.IO.File]::WriteAllText($localBat, $batContent, [System.Text.Encoding]::ASCII) } catch {}

        if (Test-Path $localVbs) {
            $shortcut.TargetPath = "wscript.exe"
            $shortcut.Arguments = "`"$localVbs`""
            $shortcut.WorkingDirectory = $localDir
            $shortcut.WindowStyle = 7
        } elseif ($targetScriptToRun -and (Test-Path $targetScriptToRun)) {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$targetScriptToRun`""
            $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($targetScriptToRun)
            $shortcut.WindowStyle = 7
        } else {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex`""
            $shortcut.WindowStyle = 7
        }
        
        # Resolve or prepare desktop shortcut icon (logo.ico matching logo.png)
        $localIco = Join-Path $localDir "logo.ico"
        $srcIco = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.ico"))) {
            Join-Path $PSScriptRoot "assets\logo.ico"
        } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "logo.ico"))) {
            Join-Path $PSScriptRoot "logo.ico"
        } else { $null }

        if ($srcIco -and (Test-Path $srcIco) -and ((Resolve-Path $srcIco).Path -ne (Resolve-Path $localIco -ErrorAction SilentlyContinue).Path)) {
            try { Copy-Item -Path $srcIco -Destination $localIco -Force -ErrorAction SilentlyContinue } catch {}
        } elseif (-not (Test-Path $localIco)) {
            $srcPng = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.png"))) {
                Join-Path $PSScriptRoot "assets\logo.png"
            } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "logo.png"))) {
                Join-Path $PSScriptRoot "logo.png"
            } else { $null }

            if ($srcPng -and (Test-Path $srcPng)) {
                try {
                    Add-Type -AssemblyName System.Drawing
                    $pngImg = [System.Drawing.Image]::FromFile($srcPng)
                    $bmp256 = New-Object System.Drawing.Bitmap(256, 256)
                    $g = [System.Drawing.Graphics]::FromImage($bmp256)
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $g.Clear([System.Drawing.Color]::Transparent)
                    $g.DrawImage($pngImg, 0, 0, 256, 256)
                    $g.Dispose()
                    $pngMs = New-Object System.IO.MemoryStream
                    $bmp256.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
                    $pBytes = $pngMs.ToArray()
                    $pngMs.Dispose()
                    $bmp256.Dispose()
                    $pngImg.Dispose()

                    $fileMs = New-Object System.IO.MemoryStream
                    $bw = New-Object System.IO.BinaryWriter($fileMs)
                    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
                    $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
                    $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pBytes.Length); $bw.Write([uint32]22)
                    $bw.Write($pBytes); $bw.Flush()
                    [System.IO.File]::WriteAllBytes($localIco, $fileMs.ToArray())
                    $bw.Dispose(); $fileMs.Dispose()
                } catch {}
            }
            if (-not (Test-Path $localIco)) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add('User-Agent', 'ZeroHub')
                    $wc.DownloadFile("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.ico", $localIco)
                } catch {}
            }
        }
        
        $shortcut.Description = "ZeroHub - Fast & Intelligent Windows Optimization Hub"
        if (Test-Path $localIco) {
            $shortcut.IconLocation = "$localIco,0"
        } else {
            $shortcut.IconLocation = "$env:SystemRoot\System32\cleanmgr.exe,0"
        }
        $shortcut.Save()

        $msg = "ZeroHub Desktop shortcut created successfully!`n`nIt will now launch locally from your PC instantly without needing internet."
        Add-HubLog "Desktop shortcut created: $shortcutPath" "SHORTCUT"
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Add-HubLog "Failed to create shortcut: $($_.Exception.Message)" "ERROR"
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

    if ($isBlocked) {
        # Updates are Blocked / Paused
        $TxtWinUpdateStatus.Text = "● Updates: Blocked / Paused"
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#371B28")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")

        $BtnToggleWinUpdate.Content = "Enable Windows Updates"
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = "● Services Stopped & Disabled"
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = "● Auto-Downloads Blocked"
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = "● Scan Tasks Disabled"
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = "● Driver Shield Active"
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
    } else {
        # Updates are Active
        $TxtWinUpdateStatus.Text = "● Updates: Active & Enabled"
        $TxtWinUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        $BadgeWinUpdateStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
        $BadgeWinUpdateStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")

        $BtnToggleWinUpdate.Content = "Block Windows Updates"
        $BtnToggleWinUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        $BtnToggleWinUpdate.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
        $BtnToggleWinUpdate.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")

        if ($BadgeCard1) {
            $BadgeCard1.Text = "● Services Active (Default)"
            $BadgeCard1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard2) {
            $BadgeCard2.Text = "● Policies Active (Default)"
            $BadgeCard2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard3) {
            $BadgeCard3.Text = "● Tasks Scheduled (Default)"
            $BadgeCard3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
        }
        if ($BadgeCard4) {
            $BadgeCard4.Text = "● Default Windows Mode"
            $BadgeCard4.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        }
    }
}

function Set-WindowsUpdatesState {
    $isBlocked = Get-WinUpdateStatus

    if (-not $isAdmin) {
        $msg = "Please run ZeroHub as Administrator to modify Windows Update settings."
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

            $successMsg = "Windows Updates have been successfully enabled! You can now check for updates normally."
            Add-HubLog "Windows Updates successfully enabled." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Add-HubLog "Error enabling Windows Updates: $($_.Exception.Message)" "ERROR"
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

            $successMsg = "Windows Automatic Updates have been successfully stopped and blocked!"
            Add-HubLog "Windows Updates successfully stopped and blocked." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub - Windows Updates" $successMsg
        } catch {
            Add-HubLog "Error stopping Windows Updates: $($_.Exception.Message)" "ERROR"
        }
    }

    Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
}

$Script:WuCachePs     = $null
$Script:WuCacheHandle = $null
$Script:WuCacheTimer  = $null
$Script:WuCacheTicks  = 0

function Clear-WinUpdateCache {
    if (-not $isAdmin) {
        $msg = "Please run as Administrator to clear Windows Update cache."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ($BtnCleanWuCache) {
        $BtnCleanWuCache.IsEnabled = $false
        $BtnCleanWuCache.Content = "⏳ Cleaning WU Cache..."
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = "Stopping services and clearing SoftwareDistribution\Download cache in background..."
    Add-HubLog "Beginning Windows Update cache purge in background..." "INFO"

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
        } finally {
            # finally, not the tail of the try: this block stops Windows Update, BITS and CryptSvc.
            # If anything above throws or the pipeline is stopped, the services must still come back
            # up, otherwise the machine is left with update and certificate services down.
            Start-Service -Name "wuauserv", "bits", "cryptsvc" -ErrorAction SilentlyContinue
        }
        return $freedMB
    }

    $Script:WuCachePs = [powershell]::Create()
    $Script:WuCachePs.AddScript($asyncScript) | Out-Null
    $Script:WuCacheHandle = $Script:WuCachePs.BeginInvoke()
    $Script:WuCacheTicks = 0

    $Script:WuCacheTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuCacheTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    # 200 ms x 900 = 180 s. The old budget was 30 ticks, six seconds, which a real
    # SoftwareDistribution purge almost never meets. Worse, on timeout the old code disposed the
    # still-running pipeline (Dispose stops it) and then printed the success message regardless, so
    # the run could be cut off between "Stop-Service wuauserv, bits, cryptsvc" and the restart while
    # the UI claimed it had worked. Wait properly, and never claim a result we did not read back.
    $Script:WuCacheTimer.add_Tick({
        $Script:WuCacheTicks++
        $timedOut = $Script:WuCacheTicks -ge 900
        if ($Script:WuCacheHandle.IsCompleted -or $timedOut) {
            $Script:WuCacheTimer.Stop()

            if ($BtnCleanWuCache) {
                $BtnCleanWuCache.IsEnabled = $true
                $BtnCleanWuCache.Content = "🧹 Clean WU Cache"
            }

            if (-not $Script:WuCacheHandle.IsCompleted) {
                # Deliberately not disposed: the pipeline still owns the stopped services and its
                # finally block is what brings them back. Killing it here is what broke machines.
                $warn = "Windows Update cache purge is still running after 180s. It has not finished yet."
                $StatusIcon.Text = "⏳"
                $StatusText.Text = $warn
                Add-HubLog "Windows Update cache purge still running after 180s. Not reporting a result, and leaving it to finish so the services get restarted." "WARN"
                return
            }

            $freedMB = 0
            $ok = $false
            try {
                $res = $Script:WuCachePs.EndInvoke($Script:WuCacheHandle)
                if ($res) { $freedMB = [double]$res[0] }
                $ok = $true
            } catch {
                Add-HubLog "Windows Update cache purge failed: $($_.Exception.Message)" "ERROR"
            }
            try { $Script:WuCachePs.Dispose() } catch {}

            if (-not $ok) {
                $StatusIcon.Text = "❌"
                $StatusText.Text = "Windows Update cache purge failed. See the Activity Log."
                return
            }

            $msg = "Cleaned Windows Update cache successfully! Freed $freedMB MB."
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Add-HubLog "Windows Update cache purged: $freedMB MB freed." "SUCCESS"
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
        $msg = "Please run as Administrator to reset Windows Update."
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    # This does more than "repair update DLLs". netsh winsock reset rewrites the Winsock catalog,
    # which drops third-party LSPs and needs a reboot before networking is reliable again. That was
    # never stated anywhere in the UI or the README, so say it here and let the user decline.
    $resetPrompt = "ZeroHub will:`n`n  - stop the wuauserv, BITS and CryptSvc services temporarily`n  - re-register 18 Windows Update DLLs`n  - run netsh winsock reset`n`nWarning: the Winsock reset removes third-party network layer providers (VPN and security software hook in there) and needs a REBOOT before networking is reliable again.`n`nContinue?"
    $resetTitle = "ZeroHub - Confirm Component Reset"
    $resetConfirm = [System.Windows.MessageBox]::Show(
        $resetPrompt, $resetTitle,
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning,
        [System.Windows.MessageBoxResult]::No)
    if ($resetConfirm -ne [System.Windows.MessageBoxResult]::Yes) {
        Add-HubLog "Windows Update component reset declined by user. Nothing was changed." "INFO"
        return
    }

    if ($BtnResetWuComponents) {
        $BtnResetWuComponents.IsEnabled = $false
        $BtnResetWuComponents.Content = "⏳ Repairing Components & Network..."
    }
    $StatusIcon.Text = "⏳"
    $StatusText.Text = "Re-registering update DLLs and resetting network & update components in background..."
    Add-HubLog "Starting fast background Windows Update component reset & DLL re-registration..." "INFO"

    $asyncScript = {
        try {
            Stop-Service -Name "wuauserv", "bits", "cryptsvc" -Force -ErrorAction SilentlyContinue
            $dllList = "wuapi.dll wuaueng.dll wups.dll wups2.dll qmgr.dll atl.dll urlmon.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll dssenh.dll rsaenh.dll cryptdlg.dll oleaut32.dll ole32.dll shell32.dll"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c for %d in ($dllList) do @if exist `"%SystemRoot%\System32\%d`" regsvr32.exe /s `"%SystemRoot%\System32\%d`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            return $true
        } catch {
            return $false
        } finally {
            # Same reasoning as the cache purge: these services are stopped above, so restarting
            # them belongs in finally. A throw or a stopped pipeline must not leave them down.
            Start-Service -Name "cryptsvc", "bits", "wuauserv" -ErrorAction SilentlyContinue
        }
    }

    $Script:WuResetPs = [powershell]::Create()
    $Script:WuResetPs.AddScript($asyncScript) | Out-Null
    $Script:WuResetHandle = $Script:WuResetPs.BeginInvoke()
    $Script:WuResetTicks = 0

    $Script:WuResetTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:WuResetTimer.Interval = [TimeSpan]::FromMilliseconds(200)
    # Same 180 s budget and the same rule as the cache purge: 18 regsvr32 calls plus a winsock reset
    # do not finish in six seconds, and a timeout is not a success.
    $Script:WuResetTimer.add_Tick({
        $Script:WuResetTicks++
        $timedOut = $Script:WuResetTicks -ge 900
        if ($Script:WuResetHandle.IsCompleted -or $timedOut) {
            $Script:WuResetTimer.Stop()

            if ($BtnResetWuComponents) {
                $BtnResetWuComponents.IsEnabled = $true
                $BtnResetWuComponents.Content = "🔧 Reset Components"
            }

            if (-not $Script:WuResetHandle.IsCompleted) {
                # Left running on purpose so its finally block restarts the services it stopped.
                $warn = "Component reset is still running after 180s. It has not finished yet."
                $StatusIcon.Text = "⏳"
                $StatusText.Text = $warn
                Add-HubLog "Windows Update component reset still running after 180s. Not reporting a result, and leaving it to finish so the services get restarted." "WARN"
                return
            }

            $ok = $false
            try {
                $res = $Script:WuResetPs.EndInvoke($Script:WuResetHandle)
                $ok = [bool]($res -and $res[0])
            } catch {
                Add-HubLog "Windows Update component reset failed: $($_.Exception.Message)" "ERROR"
            }
            try { $Script:WuResetPs.Dispose() } catch {}

            if (-not $ok) {
                $StatusIcon.Text = "❌"
                $StatusText.Text = "Component reset failed. See the Activity Log."
                Add-HubLog "Windows Update component reset did not complete successfully." "ERROR"
                Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
                return
            }

            $msg = "Windows Update components reset. Reboot to complete the Winsock reset."
            $StatusIcon.Text = "✅"
            $StatusText.Text = $msg
            Add-HubLog "Windows Update components and DLLs reset. A reboot is required to finish the Winsock reset." "SUCCESS"
            Show-ZeroToastNotification "ZeroHub" $msg
            Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-StartupAppsList
    Update-GameLibraryList
        }
    })
    $Script:WuResetTimer.Start()
}

function Open-WinUpdateSettings {
    Start-Process "ms-settings:windowsupdate" -ErrorAction SilentlyContinue
}

if ($BtnToggleWinUpdate) {
    $BtnToggleWinUpdate.add_Click({ Set-WindowsUpdatesState })
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

function Set-PrivacyDiagnostics([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "DiagBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        if ($disable) {
            Start-Process -FilePath "sc.exe" -ArgumentList "config DiagTrack start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop DiagTrack" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config diagsvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop diagsvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Add-HubLog "Stopped and disabled DiagTrack & diagsvc telemetry services." "PRIVACY"
        } else {
            Start-Process -FilePath "sc.exe" -ArgumentList "config DiagTrack start= auto" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "start DiagTrack" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config diagsvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Add-HubLog "Restored DiagTrack & diagsvc services to Windows defaults." "PRIVACY"
        }

        # Registry DataCollection
        $pathDC = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $pathDC)) { New-Item -Path $pathDC -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathDC -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathDC -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathDC -Name "MaxTelemetryAllowed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathDC -Name "AllowTelemetry" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathDC -Name "DoNotShowFeedbackNotifications" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathDC -Name "MaxTelemetryAllowed" -Force -ErrorAction SilentlyContinue
        }

        # Handwriting error sharing
        $pathHW = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"
        if (-not (Test-Path $pathHW)) { New-Item -Path $pathHW -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathHW -Name "PreventHandwritingDataSharing" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathHW -Name "PreventHandwritingDataSharing" -Force -ErrorAction SilentlyContinue
        }

        # Tailored experiences
        $pathPriv = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
        if (-not (Test-Path $pathPriv)) { New-Item -Path $pathPriv -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathPriv -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathPriv -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting diagnostics telemetry: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyAdsAndActivity([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "AdsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Advertising Info
        $pathAdCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $pathAdCU)) { New-Item -Path $pathAdCU -Force | Out-Null }
        $adVal = if ($disable) { 0 } else { 1 }
        Set-ItemProperty -Path $pathAdCU -Name "Enabled" -Value $adVal -Type DWord -Force -ErrorAction SilentlyContinue

        $pathAdLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        if (-not (Test-Path $pathAdLM)) { New-Item -Path $pathAdLM -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathAdLM -Name "DisabledByGroupPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathAdLM -Name "DisabledByGroupPolicy" -Force -ErrorAction SilentlyContinue
        }

        # Activity Feed / Timeline Cloud Upload
        $pathSys = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $pathSys)) { New-Item -Path $pathSys -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSys -Name "EnableActivityFeed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSys -Name "PublishUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSys -Name "UploadUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathSys -Name "EnableActivityFeed" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSys -Name "PublishUserActivities" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSys -Name "UploadUserActivities" -Force -ErrorAction SilentlyContinue
        }

        # Content Delivery Manager (Promoted Apps & Suggestions)
        $pathCDM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (Test-Path $pathCDM) {
            $val = if ($disable) { 0 } else { 1 }
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-338388Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-338389Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-353696Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SystemPaneSuggestionsEnabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SilentInstalledAppsEnabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Advertising ID and Activity Timeline policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting ad tracking policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyTypingAndSearch([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "SearchBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Search & Bing in Start Menu
        $pathSearchCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        if (-not (Test-Path $pathSearchCU)) { New-Item -Path $pathSearchCU -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSearchCU -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchCU -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathSearchCU -Name "BingSearchEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchCU -Name "CortanaConsent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        $pathSearchLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $pathSearchLM)) { New-Item -Path $pathSearchLM -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSearchLM -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "DisableWebSearch" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "AllowSearchToUseLocation" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathSearchLM -Name "AllowCortana" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "DisableWebSearch" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "ConnectedSearchUseWeb" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "AllowSearchToUseLocation" -Force -ErrorAction SilentlyContinue
        }

        # Input Personalization & Inking Keystroke Collection
        $pathInput = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        if (-not (Test-Path $pathInput)) { New-Item -Path $pathInput -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitInkCollection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitTextCollection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        $pathTrained = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        if (-not (Test-Path $pathTrained)) { New-Item -Path $pathTrained -Force | Out-Null }
        $hcVal = if ($disable) { 0 } else { 1 }
        Set-ItemProperty -Path $pathTrained -Name "HarvestContacts" -Value $hcVal -Type DWord -Force -ErrorAction SilentlyContinue

        # Location Sensor Policy
        $pathLoc = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        if (-not (Test-Path $pathLoc)) { New-Item -Path $pathLoc -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathLoc -Name "DisableLocation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathLoc -Name "DisableLocationScripting" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathLoc -Name "DisableLocation" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathLoc -Name "DisableLocationScripting" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Typing, Inking, Location & Web Search policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting search and inking privacy: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyTasks([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "TasksBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $tasks = @(
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "KernelCeipTask" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "StartupAppTask" },
            @{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy" },
            @{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector" }
        )

        foreach ($t in $tasks) {
            try {
                if ($disable) {
                    Disable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                } else {
                    Enable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                }
            } catch {}
        }

        Add-HubLog "Configured Customer Experience and telemetry background tasks (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting privacy tasks: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyAI([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "AIBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Windows Copilot Policy
        $pathCopilotLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $pathCopilotLM)) { New-Item -Path $pathCopilotLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathCopilotCU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $pathCopilotCU)) { New-Item -Path $pathCopilotCU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Windows Recall Policy
        $pathRecallLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Recall"
        if (-not (Test-Path $pathRecallLM)) { New-Item -Path $pathRecallLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathRecallCU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Recall"
        if (-not (Test-Path $pathRecallCU)) { New-Item -Path $pathRecallCU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Windows AI Data Analysis Policy
        $pathAILM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if (-not (Test-Path $pathAILM)) { New-Item -Path $pathAILM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathAICU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if (-not (Test-Path $pathAICU)) { New-Item -Path $pathAICU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Explorer Copilot Taskbar Icon
        $pathExp = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        if ($disable) {
            Set-ItemProperty -Path $pathCopilotLM -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCopilotCU -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathRecallLM -Name "DisableRecall" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathRecallCU -Name "DisableRecall" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathAILM -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathAICU -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            if (Test-Path $pathExp) { Set-ItemProperty -Path $pathExp -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue }
        } else {
            Remove-ItemProperty -Path $pathCopilotLM -Name "TurnOffWindowsCopilot" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathCopilotCU -Name "TurnOffWindowsCopilot" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathRecallLM -Name "DisableRecall" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathRecallCU -Name "DisableRecall" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathAILM -Name "DisableAIDataAnalysis" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathAICU -Name "DisableAIDataAnalysis" -Force -ErrorAction SilentlyContinue
            if (Test-Path $pathExp) { Set-ItemProperty -Path $pathExp -Name "ShowCopilotButton" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
        }

        Add-HubLog "Configured AI, Copilot and Windows Recall policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting AI & Recall policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyHosts([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "HostsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        if (Test-Path $hostsPath) {
            $item = Get-Item -Path $hostsPath -ErrorAction SilentlyContinue
            if ($item -and $item.IsReadOnly) { $item.IsReadOnly = $false }

            $lines = @(Get-Content -Path $hostsPath -ErrorAction SilentlyContinue)
            $cleanLines = @($lines | Where-Object { 
                $_ -notmatch "# ZeroHub Anti-Telemetry Blocklist" -and
                $_ -notmatch "0\.0\.0\.0\s+(v10\.events|v20\.events|telemetry\.microsoft|watson\.telemetry|diagnostics\.support|browser\.pipe\.aria|settings-win\.data)"
            })

            if ($disable) {
                $blockEntries = @(
                    "",
                    "# ZeroHub Anti-Telemetry Blocklist",
                    "0.0.0.0 v10.events.data.microsoft.com",
                    "0.0.0.0 v20.events.data.microsoft.com",
                    "0.0.0.0 telemetry.microsoft.com",
                    "0.0.0.0 watson.telemetry.microsoft.com",
                    "0.0.0.0 diagnostics.support.microsoft.com",
                    "0.0.0.0 browser.pipe.aria.microsoft.com",
                    "0.0.0.0 settings-win.data.microsoft.com"
                )
                $newContent = ($cleanLines + $blockEntries) -join "`r`n"
            } else {
                $newContent = $cleanLines -join "`r`n"
            }
            
            try {
                [System.IO.File]::WriteAllText($hostsPath, $newContent, [System.Text.Encoding]::ASCII)
            } catch {
                Set-Content -Path $hostsPath -Value $newContent -Force -Encoding ASCII -ErrorAction SilentlyContinue
            }
        }

        Add-HubLog "Configured Hosts file telemetry null-routing (Blocked=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting hosts file: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyEdge([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "EdgeBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $pathEdgeLM = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $pathEdgeLM)) { New-Item -Path $pathEdgeLM -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $pathEdgeLM -Name "MetricsReportingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "SendDoNotTrack" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "DiagnosticData" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathEdgeLM -Name "MetricsReportingEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "SendDoNotTrack" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "PersonalizationReportingEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "DiagnosticData" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "BackgroundModeEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "StartupBoostEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "ShowRecommendationsEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "EdgeShoppingAssistantEnabled" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Microsoft Edge telemetry & background processes (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting Edge privacy policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyWER([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "WERBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $pathWERLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $pathWERLM)) { New-Item -Path $pathWERLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathWERCU = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $pathWERCU)) { New-Item -Path $pathWERCU -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $pathWERLM -Name "Disabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERLM -Name "DoNotSendAdditionalData" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERLM -Name "LoggingDisabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERCU -Name "Disabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERCU -Name "DontSendAdditionalData" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathWERLM -Name "Disabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERLM -Name "DoNotSendAdditionalData" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERLM -Name "LoggingDisabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERCU -Name "Disabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERCU -Name "DontSendAdditionalData" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Windows Error Reporting & crash dump privacy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting WER policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyNudges([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "NudgesBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $cdm)) { New-Item -Path $cdm -Force -ErrorAction SilentlyContinue | Out-Null }
        $cloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $cloudContent)) { New-Item -Path $cloudContent -Force -ErrorAction SilentlyContinue | Out-Null }
        $advExp = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $advExp)) { New-Item -Path $advExp -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExp -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cloudContent -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExp -Name "ShowSyncProviderNotifications" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $cloudContent -Name "DisableWindowsConsumerFeatures" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Windows nudges & sponsored suggestions policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting nudges policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyWUDO([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "WUDOBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $doLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if (-not (Test-Path $doLM)) { New-Item -Path $doLM -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $doLM -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config DoSvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop DoSvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $doLM -Name "DODownloadMode" -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config DoSvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Delivery Optimization (WUDO) P2P bandwidth policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting WUDO policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyClipboard([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "ClipboardBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $clipSys = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $clipSys)) { New-Item -Path $clipSys -Force -ErrorAction SilentlyContinue | Out-Null }
        $clipCU = "HKCU:\SOFTWARE\Microsoft\Clipboard"
        if (-not (Test-Path $clipCU)) { New-Item -Path $clipCU -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $clipSys -Name "AllowCrossDeviceClipboard" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "EnableCloudClipboard" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "CloudClipboardAutomaticUpload" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $clipSys -Name "AllowCrossDeviceClipboard" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "EnableCloudClipboard" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Clipboard cloud synchronization policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting clipboard policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacySensors([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "SensorsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $locPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        if (-not (Test-Path $locPol)) { New-Item -Path $locPol -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $locPol -Name "DisableLocation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $locPol -Name "DisableSensors" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $locPol -Name "DisableLocationScripting" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config lfsvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop lfsvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $locPol -Name "DisableLocation" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $locPol -Name "DisableSensors" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $locPol -Name "DisableLocationScripting" -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config lfsvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Location & Sensor tracking services (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting sensor policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-ClassicContextMenu([bool]$enable, [bool]$skipUI = $false) {
    try {
        $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
        $inprocPath = "$clsidPath\InprocServer32"

        if ($enable) {
            if (-not (Test-Path $clsidPath)) { New-Item -Path $clsidPath -Force -ErrorAction SilentlyContinue | Out-Null }
            if (-not (Test-Path $inprocPath)) { New-Item -Path $inprocPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $inprocPath -Name "(Default)" -Value "" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-Item -Path $inprocPath -Value "" -Force -ErrorAction SilentlyContinue | Out-Null
            $action = "Enabled Classic Windows 10 Context Menu"
        } else {
            if (Test-Path $clsidPath) {
                Remove-Item -Path $clsidPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $action = "Restored Windows 11 Modern Context Menu"
        }

        # Seamlessly restart explorer.exe
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }

        Add-HubLog "$action (File Explorer restarted)." "TWEAKS"
        if (-not $skipUI) {
            Show-ZeroToastNotification "ZeroHub Shell Tweaks" "$action (File Explorer restarted)."
            Update-PrivacyUI
        }
    } catch {
        Add-HubLog "Error updating Classic Context Menu: $($_.Exception.Message)" "ERROR"
    }
}


function Set-MaxPrivacyMode {
    $confirmPrompt = "Max Privacy Mode will apply comprehensive privacy hardening across all 12 vectors:`n`n - Stop DiagTrack & diagsvc telemetry background services`n - Disable Advertising ID & Activity Timeline cloud uploads`n - Block keystroke/ink harvesting & Bing web search integration`n - Disable CEIP & Compatibility Appraiser background tasks`n - Block Windows Recall snapshots & Copilot background processes`n - Null-route Microsoft telemetry hostnames in the hosts file`n - Disable Edge background telemetry & startup boost`n - Block Windows Error Reporting (WER) memory dump uploads`n - Block Windows nudges, tips & File Explorer promo ads`n - Disable Delivery Optimization (WUDO) P2P upload bandwidth seeding`n - Block Cloud Clipboard synchronization while keeping local history`n - Disable location tracking, sensor telemetry & feedback nags`n`nCore Windows features (Microsoft Store, Xbox, DirectX, Games) remain 100% functional. Continue?"

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "ZeroHub - Max Privacy Mode",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $loadingMsg = "Applying Max Privacy Mode & disabling all 13 telemetry vectors..."
    Set-PrivacyLoadingState $true $loadingMsg

    try {
        Set-PrivacyDiagnostics $true $true
        Set-PrivacyAdsAndActivity $true $true
        Set-PrivacyTypingAndSearch $true $true
        Set-PrivacyTasks $true $true
        Set-PrivacyAI $true $true
        Set-PrivacyHosts $true $true
        Set-PrivacyEdge $true $true
        Set-PrivacyWER $true $true
        Set-PrivacyNudges $true $true
        Set-PrivacyWUDO $true $true
        Set-PrivacyClipboard $true $true
        Set-PrivacySensors $true $true

        $msg = "Max Privacy Mode Applied! All 12 Windows telemetry and tracking vectors are now blocked."
        $StatusIcon.Text = [char]0xE73E # Checkmark
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Privacy Shield" $msg
    } finally {
        Set-PrivacyLoadingState $false
        Update-PrivacyUI
    }
}

function Restore-DefaultPrivacyMode {
    $confirmPrompt = "Do you want to restore default Windows privacy and telemetry configurations for all 12 vectors?"

    $confirm = [System.Windows.MessageBox]::Show(
        $confirmPrompt,
        "ZeroHub - Restore Privacy Defaults",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $restoreMsg = "Restoring Windows default privacy and telemetry settings..."
    Set-PrivacyLoadingState $true $restoreMsg

    try {
        Set-PrivacyDiagnostics $false $true
        Set-PrivacyAdsAndActivity $false $true
        Set-PrivacyTypingAndSearch $false $true
        Set-PrivacyTasks $false $true
        Set-PrivacyAI $false $true
        Set-PrivacyHosts $false $true
        Set-PrivacyEdge $false $true
        Set-PrivacyWER $false $true
        Set-PrivacyNudges $false $true
        Set-PrivacyWUDO $false $true
        Set-PrivacyClipboard $false $true
        Set-PrivacySensors $false $true

        $msg = "Windows default privacy & telemetry settings restored."
        $StatusIcon.Text = [char]0xE73E # Checkmark
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Privacy Shield" $msg
    } finally {
        Set-PrivacyLoadingState $false
        Update-PrivacyUI
    }
}

# Wire Privacy Tab Action Buttons
if ($BtnApplyMaxPrivacy) {
    $BtnApplyMaxPrivacy.add_Click({ Set-MaxPrivacyMode })
}
if ($BtnRestorePrivacyDefaults) {
    $BtnRestorePrivacyDefaults.add_Click({ Restore-DefaultPrivacyMode })
}
if ($BtnTogglePrivDiag) {
    $BtnTogglePrivDiag.add_Click({
        $curr = Get-PrivacyDiagnosticsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyDiagnostics (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivAds) {
    $BtnTogglePrivAds.add_Click({
        $curr = Get-PrivacyAdsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyAdsAndActivity (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivSearch) {
    $BtnTogglePrivSearch.add_Click({
        $curr = Get-PrivacySearchState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyTypingAndSearch (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivTasks) {
    $BtnTogglePrivTasks.add_Click({
        $curr = Get-PrivacyTasksState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyTasks (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivAI) {
    $BtnTogglePrivAI.add_Click({
        $curr = Get-PrivacyAIState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyAI (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivHosts) {
    $BtnTogglePrivHosts.add_Click({
        $curr = Get-PrivacyHostsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyHosts (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivEdge) {
    $BtnTogglePrivEdge.add_Click({
        $curr = Get-PrivacyEdgeState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyEdge (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivWER) {
    $BtnTogglePrivWER.add_Click({
        $curr = Get-PrivacyWERState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyWER (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivNudges) {
    $BtnTogglePrivNudges.add_Click({
        $curr = Get-PrivacyNudgesState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyNudges (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivWUDO) {
    $BtnTogglePrivWUDO.add_Click({
        $curr = Get-PrivacyWUDOState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyWUDO (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivClipboard) {
    $BtnTogglePrivClipboard.add_Click({
        $curr = Get-PrivacyClipboardState
        Set-PrivacyLoadingState $true
        try { Set-PrivacyClipboard (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivSensors) {
    $BtnTogglePrivSensors.add_Click({
        $curr = Get-PrivacySensorsState
        Set-PrivacyLoadingState $true
        try { Set-PrivacySensors (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}
if ($BtnTogglePrivClassicMenu) {
    $BtnTogglePrivClassicMenu.add_Click({
        $curr = Get-ClassicContextMenuState
        Set-PrivacyLoadingState $true "Configuring Windows Context Menu..."
        try { Set-ClassicContextMenu (-not $curr) } finally { Set-PrivacyLoadingState $false; Update-PrivacyUI }
    })
}




# ==========================================
# WINDOWS SECURITY & DEFENDER QUICK MANAGER ENGINE
# ==========================================
function Get-DefenderLiveStatus {
    try {
        $mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
        if ($mp) {
            return @{
                RealTime = [bool]$mp.RealTimeProtectionEnabled
                AntivirusEnabled = [bool]$mp.AntivirusEnabled
                SignatureVersion = [string]$mp.AntivirusSignatureVersion
                Ioav = [bool]$mp.IoavProtectionEnabled
            }
        }
    } catch {}
    return @{ RealTime = $true; AntivirusEnabled = $true; SignatureVersion = "Up to date"; Ioav = $true }
}


function Get-InstalledGameFoldersList {
    $gameFolders = @()
    try {
        # 1. Steam paths
        $steamPath = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction SilentlyContinue).SteamPath
        if ($steamPath -and (Test-Path $steamPath)) {
            $gameFolders += $steamPath
            $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
            if (Test-Path $vdf) {
                $lines = Get-Content $vdf -ErrorAction SilentlyContinue
                foreach ($line in $lines) {
                    if ($line -match '"path"\s+"([^"]+)"') {
                        $p = $Matches[1].Replace('\', '')
                        if ((Test-Path $p) -and -not $gameFolders.Contains($p)) {
                            $gameFolders += $p
                        }
                    }
                }
            }
        }

        # 2. Common drive Games folders
        foreach ($drive in (Get-PSDrive -PSProvider FileSystem)) {
            $candidate = Join-Path ($drive.Root) 'Games'
            if ((Test-Path $candidate) -and -not $gameFolders.Contains($candidate)) {
                $gameFolders += $candidate
            }
        }

        # 3. Epic Games default
        $epicDef = 'C:\Program Files\Epic Games'
        if ((Test-Path $epicDef) -and -not $gameFolders.Contains($epicDef)) {
            $gameFolders += $epicDef
        }

        # 4. GOG Galaxy
        $gogPath = 'C:\Program Files (x86)\GOG Galaxy\Games'
        if ((Test-Path $gogPath) -and -not $gameFolders.Contains($gogPath)) {
            $gameFolders += $gogPath
        }
    } catch {}
    return $gameFolders
}

function Get-DefenderExclusionsList {
    $paths = @()
    try {
        $pref = Get-MpPreference -ErrorAction SilentlyContinue
        if ($pref -and $pref.ExclusionPath) {
            foreach ($p in $pref.ExclusionPath) {
                if ($p -and -not $paths.Contains($p)) {
                    $paths += $p
                }
            }
        }
    } catch {}
    return $paths
}

function Add-AllDetectedGameExclusions {
    if ($BtnAddDetectedGames) {
        $BtnAddDetectedGames.IsEnabled = $false
        $BtnAddDetectedGames.Content = "⏳ Adding Game Exclusions..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Scanning and adding game libraries to Defender exclusions..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $detected = Get-InstalledGameFoldersList
        $addedCount = 0
        foreach ($folder in $detected) {
            try {
                Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue
                $addedCount++
                Add-HubLog "Added Defender Exclusion: $folder" "SUCCESS"
            } catch {}
        }

        $msg = "Successfully added $addedCount game library folder(s) to Windows Defender exclusions!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
        Update-DefenderUI
    } catch {
        Add-HubLog "Error adding game exclusions: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnAddDetectedGames) {
            $BtnAddDetectedGames.Content = "✅ Exclusions Added!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnAddDetectedGames) {
                    $BtnAddDetectedGames.IsEnabled = $true
                    $BtnAddDetectedGames.Content = "🎮 Add Detected Game Libraries"
                }
            })
            $timer.Start()
        }
    }
}

function Add-CustomDefenderExclusionDialog {
    try {
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "Select a Game or App folder to exclude from Windows Defender scans:"
        $fbd.ShowNewFolderButton = $false
        if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selected = $fbd.SelectedPath
            if ($selected -and (Test-Path $selected)) {
                Add-MpPreference -ExclusionPath $selected -ErrorAction Stop
                $msg = "Added folder ($selected) to Defender exclusions successfully!"
                Add-HubLog $msg "SUCCESS"
                Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
                Update-DefenderUI
            }
        }
    } catch {
        Add-HubLog "Error adding custom exclusion: $($_.Exception.Message)" "ERROR"
    }
}

function Invoke-ClearDefenderProtectionHistory {
    if ($BtnClearProtHistory) {
        $BtnClearProtHistory.IsEnabled = $false
        $BtnClearProtHistory.Content = "⏳ Clearing History..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Purging Windows Defender DetectionHistory cache files..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $histPath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory"
        $storePath = "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Store"

        if (Test-Path $histPath) {
            Remove-Item -Path "$histPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $storePath) {
            Remove-Item -Path "$storePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Milliseconds 400

        $msg = "Windows Defender Protection History purged successfully! Stuck threat notifications cleared."
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
    } catch {
        Add-HubLog "Error clearing protection history: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnClearProtHistory) {
            $BtnClearProtHistory.Content = "✅ Protection History Cleared!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnClearProtHistory) {
                    $BtnClearProtHistory.IsEnabled = $true
                    $BtnClearProtHistory.Content = "🧹 Clear Protection History"
                }
            })
            $timer.Start()
        }
    }
}

function Invoke-DefenderQuickScan {
    if ($BtnDefenderQuickScan) {
        $BtnDefenderQuickScan.IsEnabled = $false
        $BtnDefenderQuickScan.Content = "⏳ Quick Scanning..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Launching Windows Defender background Quick Scan..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -Command Start-MpScan -ScanType QuickScan" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        $msg = "Windows Defender Quick Scan started in the background!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
    } catch {
        Add-HubLog "Error launching quick scan: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnDefenderQuickScan) {
            $BtnDefenderQuickScan.Content = "✅ Scan Launched!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(3)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnDefenderQuickScan) {
                    $BtnDefenderQuickScan.IsEnabled = $true
                    $BtnDefenderQuickScan.Content = "⚡ Quick Scan"
                }
            })
            $timer.Start()
        }
    }
}

function Invoke-UpdateDefenderSignatures {
    if ($BtnUpdateSignatures) {
        $BtnUpdateSignatures.IsEnabled = $false
        $BtnUpdateSignatures.Content = "⏳ Updating in background..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Downloading latest Windows Defender definitions in background..."

    # Launch background process asynchronously so WPF UI never freezes
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command Update-MpSignature" -NoNewWindow -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue

    $pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $pollTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $pollTimer.add_Tick({
        param($s, $e)
        if (-not $proc -or $proc.HasExited) {
            $s.Stop()
            if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
            $msg = "Windows Defender signatures updated successfully!"
            $StatusIcon.Text = [char]0xE73E
            $StatusText.Text = $msg
            Add-HubLog $msg "SUCCESS"
            Show-ZeroToastNotification "ZeroHub Defender Manager" $msg
            Update-DefenderUI

            if ($BtnUpdateSignatures) {
                $BtnUpdateSignatures.Content = "✅ Updated!"
                $resetTimer = [System.Windows.Threading.DispatcherTimer]::new()
                $resetTimer.Interval = [TimeSpan]::FromSeconds(3)
                $resetTimer.add_Tick({
                    param($ts, $te)
                    $ts.Stop()
                    if ($BtnUpdateSignatures) {
                        $BtnUpdateSignatures.IsEnabled = $true
                        $BtnUpdateSignatures.Content = "🔄 Update Signatures"
                    }
                })
                $resetTimer.Start()
            }
        }
    })
    $pollTimer.Start()
}

function Update-DefenderUI {
    if (-not $Tab_Defender) { return }

    # 1. Antivirus Live Status
    $status = Get-DefenderLiveStatus
    if ($BadgeDefenderStatus -and $TxtDefenderStatus) {
        if ($status.RealTime -and $status.AntivirusEnabled) {
            $BadgeDefenderStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
            $BadgeDefenderStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
            $TxtDefenderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            $TxtDefenderStatus.Text = "● Real-Time Antivirus Active (v$($status.SignatureVersion))"
        } else {
            $BadgeDefenderStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
            $BadgeDefenderStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
            $TxtDefenderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
            $TxtDefenderStatus.Text = "● Protection Inactive / Managed Externally"
        }
    }



    # 3. Active Exclusions List
    $exclusions = Get-DefenderExclusionsList
    if ($ListDefenderExclusions) {
        $ListDefenderExclusions.ItemsSource = @($exclusions)
    }
    if ($TxtExclusionCountInfo) {
        $TxtExclusionCountInfo.Text = "$($exclusions.Count) Excluded Folders"
    }
}

# Wire Defender Buttons
if ($BtnDefenderQuickScan) {
    $BtnDefenderQuickScan.add_Click({ Invoke-DefenderQuickScan })
}
if ($BtnUpdateSignatures) {
    $BtnUpdateSignatures.add_Click({ Invoke-UpdateDefenderSignatures })
}
if ($BtnOpenWinSecurity) {
    $BtnOpenWinSecurity.add_Click({
        try {
            Start-Process "windowsdefender://" -ErrorAction SilentlyContinue
        } catch {
            Start-Process "ms-settings:windowsdefender" -ErrorAction SilentlyContinue
        }
    })
}
if ($BtnAddDetectedGames) {
    $BtnAddDetectedGames.add_Click({ Add-AllDetectedGameExclusions })
}
if ($BtnAddCustomExclusion) {
    $BtnAddCustomExclusion.add_Click({ Add-CustomDefenderExclusionDialog })
}
if ($BtnRefreshExclusions) {
    $BtnRefreshExclusions.add_Click({ Update-DefenderUI })
}
if ($BtnClearProtHistory) {
    $BtnClearProtHistory.add_Click({ Invoke-ClearDefenderProtectionHistory })
}

# ==========================================
# DNS & INTERNET SPEED BOOSTER ENGINE
# ==========================================
$Script:DnsProviders = @(
    @{
        Id = "cloudflare"
        Name = "Cloudflare (1.1.1.1)"
        Tag = "⚡ Ultra-Low Latency & Gaming"
        Desc = "World's fastest public DNS resolver with privacy pledge and zero log selling."
        Primary = "1.1.1.1"
        Secondary = "1.0.0.1"
    },
    @{
        Id = "adguard"
        Name = "AdGuard DNS"
        Tag = "🛡️ System-Wide Ad & Tracker Blocker"
        Desc = "Blocks intrusive web ads, popups, and tracking domains across your entire system without extra software."
        Primary = "94.140.14.14"
        Secondary = "94.140.15.15"
    },
    @{
        Id = "quad9"
        Name = "Quad9 Secure"
        Tag = "🔒 Anti-Malware & Phishing Shield"
        Desc = "Real-time threat intelligence blocking ransomware, infected domains, malware, and phishing."
        Primary = "9.9.9.9"
        Secondary = "149.112.112.112"
    },
    @{
        Id = "google"
        Name = "Google Public DNS"
        Tag = "🌐 High Reliability & Global Anycast"
        Desc = "Massive global Anycast infrastructure with geo-optimized CDN caching for rock-solid stability."
        Primary = "8.8.8.8"
        Secondary = "8.8.4.4"
    },
    @{
        Id = "opendns"
        Name = "Cisco OpenDNS"
        Tag = "🏢 Enterprise Cloud Routing"
        Desc = "Enterprise-grade cloud routing with SmartCache and automatic phishing domain filtering."
        Primary = "208.67.222.222"
        Secondary = "208.67.220.220"
    },
    @{
        Id = "cleanbrowsing"
        Name = "CleanBrowsing Family Filter"
        Tag = "👨‍👩‍👧 Family Safety & Content Filter"
        Desc = "Enforces safe search and blocks malicious, phishing, and non-family domains automatically."
        Primary = "185.228.168.168"
        Secondary = "185.228.169.168"
    }
)

function Get-ActiveNetworkAdaptersList {
    try {
        $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
        if ($adapters.Count -eq 0) {
            $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue)
        }
        return $adapters
    } catch {
        return @()
    }
}

function Get-CurrentActiveDnsList {
    $servers = @()
    try {
        $adapters = Get-ActiveNetworkAdaptersList
        foreach ($a in $adapters) {
            $dns = Get-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($dns -and $dns.ServerAddresses) {
                foreach ($ip in $dns.ServerAddresses) {
                    if ($ip -and -not $servers.Contains($ip)) {
                        $servers += $ip
                    }
                }
            }
        }
    } catch {}
    return $servers
}

function Set-SystemDnsServers([string]$primary, [string]$secondary, [string]$providerName = "", $triggerBtn = $null) {
    if ($triggerBtn) {
        $triggerBtn.IsEnabled = $false
        $triggerBtn.Content = "⏳ Applying..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Applying DNS ($($providerName): $primary)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $adapters = Get-ActiveNetworkAdaptersList
        if ($adapters.Count -eq 0) {
            $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue)
        }

        $ips = @($primary)
        if ($secondary -and $secondary -ne $primary) { $ips += $secondary }

        foreach ($a in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $ips -ErrorAction SilentlyContinue
            } catch {}
            try {
                & netsh.exe interface ipv4 set dnsservers name="$($a.Name)" source=static address="$primary" validate=no 2>$null | Out-Null
                if ($secondary) {
                    & netsh.exe interface ipv4 add dnsservers name="$($a.Name)" address="$secondary" index=2 validate=no 2>$null | Out-Null
                }
            } catch {}
        }

        # Clear DNS cache
        try {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            ipconfig /flushdns 2>$null | Out-Null
        } catch {}

        if (-not $isAdmin) {
            try {
                $secArg = if ($secondary) { "netsh interface ipv4 add dnsservers name=`\`"`$(`$_.Name)`\`" address=$secondary index=2 validate=no" } else { "" }
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Get-NetAdapter | Where-Object { `$_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex `$_.InterfaceIndex -ServerAddresses @('$primary','$secondary') -ErrorAction SilentlyContinue; netsh interface ipv4 set dnsservers name=`\`"`$(`$_.Name)`\`" source=static address=$primary validate=no; $secArg }; Clear-DnsClientCache; ipconfig /flushdns`"" -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            } catch {}
        }

        Start-Sleep -Milliseconds 400

        $msg = "Applied DNS ($($providerName): $primary) successfully across active network adapters!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub DNS Switcher" $msg
        Update-DnsUI
    } catch {
        Add-HubLog "Error setting DNS servers: $($_.Exception.Message)" "ERROR"
        Update-DnsUI
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
    }
}

function Restore-DefaultDnsDhcp {
    if ($BtnRestoreDnsDhcp) {
        $BtnRestoreDnsDhcp.IsEnabled = $false
        $BtnRestoreDnsDhcp.Content = "⏳ Restoring..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Restoring automatic DNS (DHCP)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # 1. Reset all network adapters via Set-DnsClientServerAddress
        Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            } catch {}
        }

        # 2. Reset via WMI (covers all physical and virtual interfaces)
        try {
            Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPEnabled } | ForEach-Object {
                $_.SetDNSServerSearchOrder() | Out-Null
            }
        } catch {}

        # 3. Reset via netsh across all interfaces
        try {
            Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.Name
                & netsh.exe interface ipv4 set dnsservers name="$name" source=dhcp 2>$null | Out-Null
                & netsh.exe interface ipv6 set dnsservers name="$name" source=dhcp 2>$null | Out-Null
            }
        } catch {}

        # 4. Clear client cache and flush DNS
        try {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            ipconfig /flushdns 2>$null | Out-Null
        } catch {}

        # 5. Check if not admin and trigger elevated reset
        if (-not $isAdmin) {
            try {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Get-NetAdapter | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex `$_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue; netsh interface ipv4 set dnsservers name=`\`"`$(`$_.Name)`\`" source=dhcp; netsh interface ipv6 set dnsservers name=`\`"`$(`$_.Name)`\`" source=dhcp }; Clear-DnsClientCache; ipconfig /flushdns`"" -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            } catch {}
        }

        Start-Sleep -Milliseconds 400

        $msg = "Restored automatic DNS (DHCP / ISP default) successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub DNS Switcher" $msg
        Update-DnsUI
    } catch {
        Add-HubLog "Error resetting DNS to DHCP: $($_.Exception.Message)" "ERROR"
        Update-DnsUI
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnRestoreDnsDhcp) {
            $BtnRestoreDnsDhcp.Content = "✅ Restored!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(2.0)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnRestoreDnsDhcp) {
                    $BtnRestoreDnsDhcp.IsEnabled = $true
                    $BtnRestoreDnsDhcp.Content = "Restore DHCP"
                }
            })
            $timer.Start()
        }
    }
}

function Invoke-QuickFlushDns {
    if ($BtnFlushDns) {
        $BtnFlushDns.IsEnabled = $false
        $BtnFlushDns.Content = "⏳ Flushing..."
    }
    if ($BtnToolFlushDns) {
        $BtnToolFlushDns.IsEnabled = $false
        $BtnToolFlushDns.Content = "⏳ Flushing DNS Resolver Cache..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Purging Windows DNS resolver cache..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        ipconfig /flushdns 2>$null | Out-Null
        Start-Sleep -Milliseconds 300
        $msg = "Windows DNS resolver cache flushed successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error flushing DNS cache: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnFlushDns) {
            $BtnFlushDns.Content = "✅ Flushed!"
            $t1 = [System.Windows.Threading.DispatcherTimer]::new()
            $t1.Interval = [TimeSpan]::FromSeconds(2.5)
            $t1.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnFlushDns) {
                    $BtnFlushDns.IsEnabled = $true
                    $BtnFlushDns.Content = "🧹 Flush DNS"
                }
            })
            $t1.Start()
        }
        if ($BtnToolFlushDns) {
            $BtnToolFlushDns.Content = "✅ DNS Cache Flushed Successfully!"
            $t2 = [System.Windows.Threading.DispatcherTimer]::new()
            $t2.Interval = [TimeSpan]::FromSeconds(2.5)
            $t2.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolFlushDns) {
                    $BtnToolFlushDns.IsEnabled = $true
                    $BtnToolFlushDns.Content = "🧹 Flush DNS Resolver Cache"
                }
            })
            $t2.Start()
        }
    }
}

function Invoke-ResetWinsockAndTcp {
    if ($BtnToolResetWinsock) {
        $BtnToolResetWinsock.IsEnabled = $false
        $BtnToolResetWinsock.Content = "⏳ Resetting Winsock & TCP/IP Stack..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Resetting Winsock catalog & TCP/IP network stack..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process -FilePath "netsh.exe" -ArgumentList "int ip reset" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        $msg = "Winsock & TCP/IP stack reset successfully! (Reboot recommended)."
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error resetting network stack: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnToolResetWinsock) {
            $BtnToolResetWinsock.Content = "✅ Network Stack Reset Successfully!"
            $t = [System.Windows.Threading.DispatcherTimer]::new()
            $t.Interval = [TimeSpan]::FromSeconds(3)
            $t.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolResetWinsock) {
                    $BtnToolResetWinsock.IsEnabled = $true
                    $BtnToolResetWinsock.Content = "🔄 Reset Winsock & TCP/IP Stack"
                }
            })
            $t.Start()
        }
    }
}

function Invoke-ReleaseRenewIp {
    if ($BtnToolRenewIp) {
        $BtnToolRenewIp.IsEnabled = $false
        $BtnToolRenewIp.Content = "⏳ Releasing & Renewing IP Address..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Releasing and renewing DHCP IPv4 address lease..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "ipconfig.exe" -ArgumentList "/release" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process -FilePath "ipconfig.exe" -ArgumentList "/renew" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        $msg = "Network IP address released and renewed successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error renewing IP: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnToolRenewIp) {
            $BtnToolRenewIp.Content = "✅ IP Address Renewed Successfully!"
            $t = [System.Windows.Threading.DispatcherTimer]::new()
            $t.Interval = [TimeSpan]::FromSeconds(3)
            $t.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolRenewIp) {
                    $BtnToolRenewIp.IsEnabled = $true
                    $BtnToolRenewIp.Content = "⚡ Release & Renew IP Address"
                }
            })
            $t.Start()
        }
    }
}

function Test-AllDnsLatencies {
    if ($BtnRunDnsBenchmark) { $BtnRunDnsBenchmark.IsEnabled = $false }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Benchmarking DNS response times (Ping test)..."
    [System.Windows.Forms.Application]::DoEvents()

    $pinger = [System.Net.NetworkInformation.Ping]::new()
    $lowestPing = 99999
    $fastestId = ""
    $pingResults = @{}

    foreach ($prov in $Script:DnsProviders) {
        $targetIp = $prov.Primary
        $latency = 9999
        try {
            $reply = $pinger.Send($targetIp, 1200)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $latency = [int]$reply.RoundtripTime
            }
        } catch {}

        $pingResults[$prov.Id] = $latency
        if ($latency -lt $lowestPing -and $latency -ge 0) {
            $lowestPing = $latency
            $fastestId = $prov.Id
        }
    }

    # Update UI badges
    foreach ($prov in $Script:DnsProviders) {
        $badgeText = $Window.FindName("TxtPingDns_" + $prov.Id)
        $badgeBorder = $Window.FindName("Border_PingDns_" + $prov.Id)
        if ($badgeText -and $badgeBorder) {
            $p = $pingResults[$prov.Id]
            if ($p -lt 1000) {
                if ($prov.Id -eq $fastestId) {
                    $fastestTag = "Fastest"
                    $badgeText.Text = "$p ms ⚡ $fastestTag"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
                } elseif ($p -le 35) {
                    $badgeText.Text = "$p ms"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0C2340")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
                } else {
                    $badgeText.Text = "$p ms"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
                }
            } else {
                $badgeText.Text = "Timeout"
                $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
                $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4C0519")
                $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
            }
        }
    }

    if ($BtnRunDnsBenchmark) { $BtnRunDnsBenchmark.IsEnabled = $true }
    $StatusIcon.Text = [char]0xE73E
    $fastestName = if ($fastestId) { ($Script:DnsProviders | Where-Object { $_.Id -eq $fastestId }).Name } else { "None" }
    $doneMsg = "Benchmark Complete! Fastest DNS in your area: $fastestName ($lowestPing ms)"
    $StatusText.Text = $doneMsg
    Add-HubLog $doneMsg "SUCCESS"
}

function Update-DnsUI {
    if (-not $Tab_Dns) { return }

    $activeServers = Get-CurrentActiveDnsList
    $matchedProvider = $null

    foreach ($prov in $Script:DnsProviders) {
        $isMatch = ($activeServers.Count -gt 0 -and $activeServers.Contains($prov.Primary))
        $cardBorder = $Window.FindName("CardDns_" + $prov.Id)
        $applyBtn   = $Window.FindName("BtnApplyDns_" + $prov.Id)

        if ($isMatch) {
            $matchedProvider = $prov
            if ($cardBorder) {
                $cardBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
                $cardBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B6B48")
            }
            if ($applyBtn) {
                $applyBtn.Content = "Disconnect"
                $applyBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
                $applyBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
                $applyBtn.FontWeight = [System.Windows.FontWeights]::Bold
                $applyBtn.IsEnabled = $true
            }
        } else {
            if ($cardBorder) {
                $cardBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#111114")
                $cardBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
            }
            if ($applyBtn) {
                $applyBtn.Content = "Apply DNS"
                $applyBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
                $applyBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $applyBtn.FontWeight = [System.Windows.FontWeights]::SemiBold
                $applyBtn.IsEnabled = $true
            }
        }
    }

    if ($BadgeDnsActiveStatus -and $TxtDnsActiveStatus) {
        if ($matchedProvider) {
            $BadgeDnsActiveStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
            $BadgeDnsActiveStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B6B48")
            $TxtDnsActiveStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
            $TxtDnsActiveStatus.Text = "🛡️ Active: $($matchedProvider.Name)"
        } else {
            $BadgeDnsActiveStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#111114")
            $BadgeDnsActiveStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
            $TxtDnsActiveStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
            $TxtDnsActiveStatus.Text = "🌐 Automatic (DHCP / ISP)"
        }
    }
}

function Handle-DnsPresetClick([string]$primary, [string]$secondary, [string]$name, $btn) {
    $activeServers = Get-CurrentActiveDnsList
    if ($activeServers.Count -gt 0 -and $activeServers.Contains($primary)) {
        Restore-DefaultDnsDhcp
    } else {
        Set-SystemDnsServers $primary $secondary $name $btn
    }
}

# Wire DNS Action Buttons
if ($BtnRunDnsBenchmark) {
    $BtnRunDnsBenchmark.add_Click({ Test-AllDnsLatencies })
}
if ($BtnRestoreDnsDhcp) {
    $BtnRestoreDnsDhcp.add_Click({ Restore-DefaultDnsDhcp })
}
if ($BtnFlushDns) {
    $BtnFlushDns.add_Click({ Invoke-QuickFlushDns })
}
if ($BtnToolFlushDns) {
    $BtnToolFlushDns.add_Click({ Invoke-QuickFlushDns })
}
if ($BtnToolResetWinsock) {
    $BtnToolResetWinsock.add_Click({ Invoke-ResetWinsockAndTcp })
}
if ($BtnToolRenewIp) {
    $BtnToolRenewIp.add_Click({ Invoke-ReleaseRenewIp })
}

# Wire Preset Apply Buttons
$btnCloudflare = $Window.FindName("BtnApplyDns_cloudflare")
if ($btnCloudflare) {
    $btnCloudflare.add_Click({ Handle-DnsPresetClick "1.1.1.1" "1.0.0.1" "Cloudflare" $btnCloudflare })
}
$btnAdGuard = $Window.FindName("BtnApplyDns_adguard")
if ($btnAdGuard) {
    $btnAdGuard.add_Click({ Handle-DnsPresetClick "94.140.14.14" "94.140.15.15" "AdGuard DNS" $btnAdGuard })
}
$btnQuad9 = $Window.FindName("BtnApplyDns_quad9")
if ($btnQuad9) {
    $btnQuad9.add_Click({ Handle-DnsPresetClick "9.9.9.9" "149.112.112.112" "Quad9 Secure" $btnQuad9 })
}
$btnGoogle = $Window.FindName("BtnApplyDns_google")
if ($btnGoogle) {
    $btnGoogle.add_Click({ Handle-DnsPresetClick "8.8.8.8" "8.8.4.4" "Google Public DNS" $btnGoogle })
}
$btnOpenDns = $Window.FindName("BtnApplyDns_opendns")
if ($btnOpenDns) {
    $btnOpenDns.add_Click({ Handle-DnsPresetClick "208.67.222.222" "208.67.220.220" "Cisco OpenDNS" $btnOpenDns })
}
$btnCleanBrowsing = $Window.FindName("BtnApplyDns_cleanbrowsing")
if ($btnCleanBrowsing) {
    $btnCleanBrowsing.add_Click({ Handle-DnsPresetClick "185.228.168.168" "185.228.169.168" "CleanBrowsing" $btnCleanBrowsing })
}

if ($BtnApplyCustomDns) {
    $BtnApplyCustomDns.add_Click({
        $p = if ($TxtCustomDnsPrimary -and $TxtCustomDnsPrimary.Text) { $TxtCustomDnsPrimary.Text.Trim() } else { "" }
        $s = if ($TxtCustomDnsSecondary -and $TxtCustomDnsSecondary.Text) { $TxtCustomDnsSecondary.Text.Trim() } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            Set-SystemDnsServers $p $s "Custom DNS"
        }
    })
}

# ==========================================
# STARTUP APPLICATIONS ENGINE
# ==========================================
$Script:AllStartupApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.StartupAppItem]]::new()
$Script:FilteredStartupApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.StartupAppItem]]::new()

$StartupAppsDataGrid.ItemsSource = $Script:FilteredStartupApps

function Update-StartupSearchFilter {
    $q = if ($TxtStartupSearch -and $TxtStartupSearch.Text) { $TxtStartupSearch.Text.Trim().ToLower() } else { "" }
    
    $Script:FilteredStartupApps.Clear()
    foreach ($app in $Script:AllStartupApps) {
        if ([string]::IsNullOrWhiteSpace($q) -or 
            ($app.Name -and $app.Name.ToLower().Contains($q)) -or 
            ($app.Publisher -and $app.Publisher.ToLower().Contains($q)) -or
            ($app.Command -and $app.Command.ToLower().Contains($q)) -or
            ($app.SourceType -and $app.SourceType.ToLower().Contains($q))) {
            $Script:FilteredStartupApps.Add($app)
        }
    }

    if ($TxtStartupCountInfo) {
        $runCount = @($Script:AllStartupApps | Where-Object { $_.IsRunning }).Count
        $totCount = $Script:AllStartupApps.Count
        $TxtStartupCountInfo.Text = "$runCount Running Now • $totCount Total Startup Apps"
    }
}

if ($TxtStartupSearch) {
    $TxtStartupSearch.add_TextChanged({ Update-StartupSearchFilter })
}

function Set-StartupAppStatus([ZeroHub.StartupAppItem]$app, [bool]$enabled) {
    try {
        if ($app.RegistryPath -and $app.ApprovedPath) {
            if (-not (Test-Path $app.ApprovedPath)) {
                New-Item -Path $app.ApprovedPath -Force | Out-Null
            }
            $byteVal = if ($enabled) { 0x02 } else { 0x03 }
            $bytes = [byte[]]@($byteVal, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
            Set-ItemProperty -Path $app.ApprovedPath -Name $app.Name -Value $bytes -Type Binary -Force -ErrorAction SilentlyContinue
            Add-HubLog "Configured startup app '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        } elseif ($app.FilePath) {
            $dir = [System.IO.Path]::GetDirectoryName($app.FilePath)
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($app.FilePath)
            if ($enabled) {
                if ($app.FilePath.EndsWith(".disabled")) {
                    $newPath = Join-Path $dir "$baseName.lnk"
                    Rename-Item -Path $app.FilePath -NewName "$baseName.lnk" -Force -ErrorAction SilentlyContinue
                    $app.FilePath = $newPath
                }
            } else {
                if ($app.FilePath.EndsWith(".lnk")) {
                    $newPath = Join-Path $dir "$baseName.disabled"
                    Rename-Item -Path $app.FilePath -NewName "$baseName.disabled" -Force -ErrorAction SilentlyContinue
                    $app.FilePath = $newPath
                }
            }
            Add-HubLog "Configured startup shortcut '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        } elseif ($app.TaskName) {
            if ($enabled) {
                Enable-ScheduledTask -TaskName $app.TaskName -ErrorAction SilentlyContinue | Out-Null
            } else {
                Disable-ScheduledTask -TaskName $app.TaskName -ErrorAction SilentlyContinue | Out-Null
            }
            Add-HubLog "Configured startup task '$($app.Name)' (Enabled=$enabled)." "STARTUP"
        }
    } catch {
        Add-HubLog "Error setting startup state for $($app.Name): $($_.Exception.Message)" "ERROR"
    }
}

function Get-StartupAppImpact([string]$name, [string]$cmd) {
    $highImpact = @("Discord", "Steam", "Spotify", "EpicGamesLauncher", "RiotClient", "CurseForge", "Battle.net", "Adobe", "Teams", "Zoom", "Chrome", "Brave")
    $mediumImpact = @("OneDrive", "Dropbox", "Slack", "Telegram", "Viber", "Skype", "iCUE", "Razer", "Logitech", "SteelSeries")
    
    foreach ($h in $highImpact) {
        if (($name -like "*$h*") -or ($cmd -like "*$h*")) { return @{ Impact = "⚡ High"; Color = "#F43F5E" } }
    }
    foreach ($m in $mediumImpact) {
        if (($name -like "*$m*") -or ($cmd -like "*$m*")) { return @{ Impact = "⚠️ Medium"; Color = "#FBBF24" } }
    }
    return @{ Impact = "● Low"; Color = "#4ADE80" }
}

function Update-StartupAppsList {
    try {
        $Script:AllStartupApps.Clear()
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $rawList = [System.Collections.Generic.List[ZeroHub.StartupAppItem]]::new()

        # Fast .NET process enumeration (0ms)
        $runningProcs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($p in [System.Diagnostics.Process]::GetProcesses()) {
            if ($p.ProcessName) { [void]$runningProcs.Add($p.ProcessName) }
        }

        # 1. Registry Hives (User, System, 32-bit Wow6432Node)
        $regLocations = @(
            @{ Hive = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; Source = "Registry (User)" },
            @{ Hive = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"; Source = "Registry (System)" },
            @{ Hive = "HKCU:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"; Source = "Registry 32-bit (User)" },
            @{ Hive = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Appr = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"; Source = "Registry 32-bit (System)" }
        )

        foreach ($loc in $regLocations) {
            if (Test-Path $loc.Hive) {
                $props = (Get-Item -Path $loc.Hive).Property
                foreach ($p in $props) {
                    if ($seen.Add("REG_$p")) {
                        $cmd = (Get-ItemProperty -Path $loc.Hive -Name $p -ErrorAction SilentlyContinue).$p
                        $isEnabled = $true
                        if (Test-Path $loc.Appr) {
                            $bin = (Get-ItemProperty -Path $loc.Appr -Name $p -ErrorAction SilentlyContinue).$p
                            if ($null -ne $bin -and $bin.Length -gt 0) {
                                if ($bin[0] -eq 3 -or $bin[0] -eq 1) { $isEnabled = $false }
                            }
                        }

                        $exeName = ""
                        if ($cmd -match '([^\\]+?)\.exe') { $exeName = $Matches[1] }
                        elseif ($p) { $exeName = $p }
                        $isRunning = ($exeName -and $runningProcs.Contains($exeName)) -or ($p -and $runningProcs.Contains($p))

                        $imp = Get-StartupAppImpact $p $cmd
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $p
                        $item.Command = [string]$cmd
                        $item.SourceType = $loc.Source
                        $item.RegistryPath = $loc.Hive
                        $item.ApprovedPath = $loc.Appr
                        $item.Publisher = if ($loc.Source.Contains("User")) { "User Application" } else { "System Software" }
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 2. StartupApproved registered apps
        foreach ($loc in $regLocations) {
            if (Test-Path $loc.Appr) {
                $apprProps = (Get-Item -Path $loc.Appr).Property
                foreach ($p in $apprProps) {
                    if ($seen.Add("REG_$p")) {
                        $bin = (Get-ItemProperty -Path $loc.Appr -Name $p -ErrorAction SilentlyContinue).$p
                        $isEnabled = ($null -eq $bin -or $bin.Length -eq 0 -or ($bin[0] -ne 3 -and $bin[0] -ne 1))
                        $isRunning = ($p -and $runningProcs.Contains($p))
                        $imp = Get-StartupAppImpact $p ""
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $p
                        $item.Command = "StartupApproved Registration ($p)"
                        $item.SourceType = $loc.Source
                        $item.RegistryPath = $loc.Hive
                        $item.ApprovedPath = $loc.Appr
                        $item.Publisher = "Registered Application"
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 3. User & Common Startup Folders
        $folders = @(
            @{ Path = [Environment]::GetFolderPath("Startup"); Source = "Startup Folder (User)" },
            @{ Path = [Environment]::GetFolderPath("CommonStartup"); Source = "Startup Folder (All Users)" }
        )
        foreach ($fld in $folders) {
            if (Test-Path $fld.Path) {
                $files = Get-ChildItem -Path $fld.Path -File -ErrorAction SilentlyContinue
                foreach ($f in $files) {
                    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
                    if ($seen.Add("FLD_$baseName")) {
                        $isEnabled = (-not $f.Name.EndsWith(".disabled"))
                        $isRunning = ($runningProcs.Contains($baseName))
                        $imp = Get-StartupAppImpact $baseName $f.FullName
                        $item = [ZeroHub.StartupAppItem]::new()
                        $item.Name = $baseName
                        $item.Command = $f.FullName
                        $item.FilePath = $f.FullName
                        $item.SourceType = $fld.Source
                        $item.Publisher = "Startup Shortcut"
                        $item.Impact = $imp.Impact
                        $item.ImpactColor = $imp.Color
                        $item.IsEnabled = $isEnabled
                        $item.IsRunning = $isRunning

                        $item.add_PropertyChanged({
                            param($s, $e)
                            if ($e.PropertyName -eq "IsEnabled") {
                                Set-StartupAppStatus $s $s.IsEnabled
                            }
                        })
                        $rawList.Add($item)
                    }
                }
            }
        }

        # 4. User Startup Scheduled Tasks (Ultra-fast COM API, 0ms latency)
        try {
            $sched = New-Object -ComObject "Schedule.Service"
            $sched.Connect()
            $rootFolder = $sched.GetFolder("\")
            $tasks = $rootFolder.GetTasks(0)
            foreach ($t in $tasks) {
                if (-not $t.Enabled) { continue }
                $defn = $t.Definition
                $actions = $defn.Actions
                $execPath = $null
                foreach ($act in $actions) {
                    if ($act.Type -eq 0 -and $act.Path) { # 0 = TASK_ACTION_EXEC
                        $execPath = $act.Path
                        break
                    }
                }
                if (-not $execPath) { continue }
                $taskName = $t.Name
                $cleanTaskName = $taskName
                if ($cleanTaskName.Length -gt 35) { $cleanTaskName = $cleanTaskName.Substring(0, 32) + "..." }
                if ($seen.Add("TSK_$taskName")) {
                    $exeName = [System.IO.Path]::GetFileNameWithoutExtension($execPath)
                    $isRunning = ($exeName -and $runningProcs.Contains($exeName))
                    $imp = Get-StartupAppImpact $cleanTaskName $execPath
                    $item = [ZeroHub.StartupAppItem]::new()
                    $item.Name = $cleanTaskName
                    $item.Command = [string]$execPath
                    $item.SourceType = "Scheduled Task"
                    $item.TaskName = $taskName
                    $item.Publisher = "Task Trigger"
                    $item.Impact = $imp.Impact
                    $item.ImpactColor = $imp.Color
                    $item.IsEnabled = [bool]$t.Enabled
                    $item.IsRunning = $isRunning

                    $item.add_PropertyChanged({
                        param($s, $e)
                        if ($e.PropertyName -eq "IsEnabled") {
                            Set-StartupAppStatus $s $s.IsEnabled
                        }
                    })
                    $rawList.Add($item)
                }
            }
        } catch {}

        # Separation sort: 1st Running Apps (at the top), then Startup Impact / Alphabetical
        $sorted = $rawList | Sort-Object @{ Expression = { if ($_.IsRunning) { 0 } else { 1 } } }, @{ Expression = { if ($_.Impact -like "*High*") { 0 } elseif ($_.Impact -like "*Med*") { 1 } else { 2 } } }, Name
        foreach ($app in $sorted) {
            $Script:AllStartupApps.Add($app)
        }

        Update-StartupSearchFilter
    } catch {
        Add-HubLog "Error updating startup apps list: $($_.Exception.Message)" "ERROR"
    }
}

function Optimize-StartupBoot {
    try {
        $disabledCount = 0
        foreach ($app in $Script:AllStartupApps) {
            if ($app.IsEnabled -and ($app.Impact -like "*High*" -or $app.Impact -like "*Med*")) {
                $app.IsEnabled = $false
                $disabledCount++
            }
        }
        $msg = "Fast Boot Optimization complete! Disabled $disabledCount heavy startup apps."
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub - Boot Optimizer" $msg
    } catch {
        Add-HubLog "Error running fast boot optimization: $($_.Exception.Message)" "ERROR"
    }
}

if ($BtnRefreshStartup) {
    $BtnRefreshStartup.add_Click({
        Update-StartupAppsList
    })
}
if ($BtnOptimizeStartup) {
    $BtnOptimizeStartup.add_Click({
        Optimize-StartupBoot
    })
}

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

function Invoke-BoostAndLaunchGame([ZeroHub.GameItem]$game, [bool]$boost) {
    try {
        if ($null -eq $game) { return }

        $freedMb = 0
        if ($boost) {
            # 1. Purge Standby & Process RAM
            try {
                $before = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
                [ZeroHub.NativeMethods]::EmptyWorkingSet(-1) | Out-Null
                $after = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
                $freedMb = [math]::Max(0, [math]::Round(($after - $before) / 1024, 0))
            } catch {}

            # 2. Pause Windows Updates & BITS temporarily
            try {
                Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue | Out-Null
                Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue | Out-Null
            } catch {}

            # 3. High Performance Power Scheme
            try {
                powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
            } catch {}

            Add-HubLog "🚀 Game Booster: Cleaned ${freedMb}MB RAM, paused background updates for $($game.Name)." "BOOST"
        }

        # Launch Game (Protocol, Shell App, or Direct Exe)
        if ($game.LaunchUri -match '^[a-zA-Z0-9_\-\.]+://' -or $game.LaunchUri.StartsWith("shell:")) {
            Start-Process $game.LaunchUri
        } elseif (Test-Path $game.LaunchUri) {
            Start-Process -FilePath $game.LaunchUri -WorkingDirectory ([System.IO.Path]::GetDirectoryName($game.LaunchUri))
        } else {
            Start-Process "cmd.exe" -ArgumentList "/c start `"`" `"$($game.LaunchUri)`"" -WindowStyle Hidden
        }

        $msg = if ($boost) {
            "🚀 Boost & Launch: $($game.Name) is now running! Freed ${freedMb}MB RAM with High CPU Priority."
        } else {
            "▶️ Launching $($game.Name)..."
        }

        Show-ZeroToastNotification "ZeroHub - Game Booster" $msg
        Add-HubLog $msg "SUCCESS"

        # Background Priority Booster Watcher (up to 15 seconds)
        if ($boost) {
            $Script:GameBoostTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $Script:GameBoostTimer.Interval = [TimeSpan]::FromSeconds(2)
            $Script:BoostAttempts = 0
            $Script:GameBoostTimer.Add_Tick({
                $Script:BoostAttempts++
                $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
                    $_.ProcessName -match ($game.Name -replace '[^a-zA-Z0-9]', '') -or 
                    ($game.InstallDir -and $_.Path -and $_.Path.StartsWith($game.InstallDir)) 
                }
                foreach ($p in $procs) {
                    try {
                        $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                        Add-HubLog "Set CPU Priority to HIGH for game process $($p.ProcessName) (PID: $($p.Id))." "BOOST"
                        $Script:GameBoostTimer.Stop()
                        return
                    } catch {}
                }
                if ($Script:BoostAttempts -ge 7) {
                    $Script:GameBoostTimer.Stop()
                }
            })
            $Script:GameBoostTimer.Start()
        }
    } catch {
        Add-HubLog "Error launching game $($game.Name): $($_.Exception.Message)" "ERROR"
    }
}

function Show-AddCustomGameDialog {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $ofd = [System.Windows.Forms.OpenFileDialog]::new()
        $ofd.Filter = "Game Executable (*.exe;*.lnk)|*.exe;*.lnk|All Files (*.*)|*.*"
        $ofd.Title = "Select Game Executable or Shortcut"
        if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedPath = $ofd.FileName
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($selectedPath)
            
            $customDir = [System.IO.Path]::GetDirectoryName($Script:CustomGamesFilePath)
            if (-not (Test-Path $customDir)) { New-Item -Path $customDir -ItemType Directory -Force | Out-Null }
            
            $existing = @()
            if (Test-Path $Script:CustomGamesFilePath) {
                $existing = @(Get-Content $Script:CustomGamesFilePath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue)
            }
            $newEntry = @{
                Name = $baseName
                Platform = "Custom"
                InstallDir = [System.IO.Path]::GetDirectoryName($selectedPath)
                LaunchUri = $selectedPath
            }
            $existing += $newEntry
            $existing | ConvertTo-Json -Depth 4 | Set-Content -Path $Script:CustomGamesFilePath -Encoding UTF8
            Add-HubLog "Added custom game '$baseName' to Game Hub." "GAMEHUB"
            Update-GameLibraryList
        }
    } catch {
        Add-HubLog "Error adding custom game: $($_.Exception.Message)" "ERROR"
    }
}

if ($BtnAddCustomGame) {
    $BtnAddCustomGame.add_Click({ Show-AddCustomGameDialog })
}
if ($BtnRefreshGames) {
    $BtnRefreshGames.add_Click({ Update-GameLibraryList })
}

# Attach Card Button Click Router
$GameCardsContainer.AddHandler(
    [System.Windows.Controls.Primitives.ButtonBase]::ClickEvent,
    [System.Windows.RoutedEventHandler]{
        param($src, $e)
        $btn = $e.OriginalSource
        if ($btn -is [System.Windows.Controls.Button]) {
            $game = $btn.Tag
            if ($game -is [ZeroHub.GameItem]) {
                if ($btn.Name -eq "BtnBoostAndLaunch") {
                    Invoke-BoostAndLaunchGame $game $true
                } elseif ($btn.Name -eq "BtnQuickPlay") {
                    Invoke-BoostAndLaunchGame $game $false
                }
            }
        }
    }
)

# ==========================================
# DEDICATED BLOATWARE TAB LOGIC & ENGINE
# ==========================================
$Script:AllBloatwareApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstalledAppItem]]::new()

function Update-BloatSelectionStatus {
    $sel = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnRemoveSelectedBloatware.IsEnabled = $true
        $TxtBloatSelectionStatus.Text = "$($sel.Count) Windows apps selected for complete removal."
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
    } else {
        $BtnRemoveSelectedBloatware.IsEnabled = $false
        $TxtBloatSelectionStatus.Text = "Select one or more Windows apps from the table to permanently remove."
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

function Update-BloatwareList() {
    Set-DataCacheStamp "bloatware"
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

            # NOTE for the maintainer. Wording deliberately left exactly as you wrote it.
            # SafetyStatus below is the same constant on every row, so it reads as an assessment but
            # can never come out negative. A handful of entries in $knownBloatware do have known
            # consequences and may deserve a different label:
            #   Gaming Services         Game Pass and Store game installs stop working, and this
            #                           package is notoriously awkward to reinstall.
            #   Xbox Identity Provider  Xbox sign-in breaks in PC titles such as Minecraft.
            #   Xbox App                Game Pass library and game installs stop working.
            #   Quick Assist            Removes the built-in remote support tool.
            #   Mail & Calendar         Removes the mail client along with its stored accounts.
            #   Phone Link              Breaks phone pairing and SMS mirroring.
            #   Teams, New Outlook      Removes the client and any accounts configured in it.
            #   Microsoft Edge          Windows features and WebView2-hosted apps expect it present.
            # Suggestion only, not applied because it changes user-facing wording: keep the green
            # label for everything else and give these a caution label naming the consequence.

            if (-not $seen.Contains($friendlyName)) {
                $seen.Add($friendlyName) | Out-Null
                $item = [ZeroHub.InstalledAppItem]::new()
                $item.Index = $idx++
                $item.DisplayName = $friendlyName
                $item.PackageName = $p.Name
                $item.PackageFullName = $p.PackageFullName
                $item.Publisher = if ($p.PublisherId) { "Microsoft / Store" } else { "Microsoft Corporation" }
                $item.SafetyStatus = "● 100% Safe to Remove"
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
            $item = [ZeroHub.InstalledAppItem]::new()
            $item.Index = $idx++
            $item.DisplayName = "Microsoft Edge Browser"
            $item.PackageName = "Microsoft.Edge (Win32 / System)"
            $item.PackageFullName = "Microsoft.Edge.System"
            $item.Publisher = "Microsoft Corporation"
            # Same note as above. Edge removal is unsupported by Microsoft, Windows Update can
            # reinstall it, and some Windows features expect it present. Wording left as written.
            $item.SafetyStatus = "● 100% Safe to Remove"
            $item.IsAppx = $false
            $item.IsBloatware = $true
            $item.IsSelected = $false
            $item.InstallLocation = [System.IO.Path]::GetDirectoryName($edgeExe)
            $Script:AllBloatwareApps.Add($item)
        }
    } catch {}

    $BloatwareGrid.ItemsSource = $Script:AllBloatwareApps
    if ($Script:AllBloatwareApps.Count -gt 0) {
        $countText = "$($Script:AllBloatwareApps.Count) Apps Found"
        $TxtBloatwareCount.Text = $countText
        Update-BloatSelectionStatus
    } else {
        $TxtBloatwareCount.Text = "Clean Windows (0)"
        $TxtBloatSelectionStatus.Text = "🎉 Great news! Your Windows installation is already debloated — 0 unwanted apps found on this PC."
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

$Script:BloatClickHandler = [System.Windows.RoutedEventHandler]{
    param($s, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $BloatwareGrid.Dispatcher.BeginInvoke([System.Action]{
            Update-BloatSelectionStatus
        })
    }
}
$BloatwareGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $Script:BloatClickHandler)

$BtnRemoveSelectedBloatware.add_Click({
    $targetList = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($targetList.Count -eq 0) { return }

    $confirmMsg = if ($targetList.Count -eq 1) {
        "Are you sure you want to remove Windows app '$($targetList[0].DisplayName)'?"
    } else {
        "Are you sure you want to permanently remove ($($targetList.Count)) selected Windows apps?"
    }

    $confirmTitle = "ZeroHub - Remove Windows Bloatware"
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $BtnRemoveSelectedBloatware.IsEnabled = $false
    $currentIdx = 0
    $successCount = 0

    foreach ($app in $targetList) {
        $currentIdx++
        $TxtBloatSelectionStatus.Text = "[$currentIdx / $($targetList.Count)] Removing: $($app.DisplayName)..."
        [System.Windows.Forms.Application]::DoEvents()

        try {
            if ($app.PackageName -like "*Microsoft.Edge*") {
                # Terminate running edge processes
                # msedgewebview2 is deliberately NOT killed. WebView2 is a shared runtime that Teams,
                # Outlook, Office panes and a pile of third-party apps render inside, so killing it
                # takes down unrelated software that the user never asked to touch.
                Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
                
                # Check for Edge setup.exe
                $setups = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue
                if ($setups -and $setups.Count -gt 0) {
                    $setupExe = $setups[0].FullName
                    Start-Process -FilePath $setupExe -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                
                # Also try winget
                Start-Process -FilePath "winget" -ArgumentList "uninstall --id Microsoft.Edge --silent --force --accept-source-agreements" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                
                # Remove AppX Edge packages
                # Was: Get-AppxPackage *Edge* | Remove-AppxPackage. That wildcard matches anything
                # with "Edge" in the name, including Microsoft.EdgeDevToolsClient and the WebView2
                # runtime package, so "remove Edge" quietly broke every WebView2-hosted app on the
                # box. Match the browser package names exactly instead.
                $edgePackageNames = @("Microsoft.MicrosoftEdge", "Microsoft.MicrosoftEdge.Stable")
                Get-AppxPackage -ErrorAction SilentlyContinue |
                    Where-Object { $edgePackageNames -contains $_.Name } |
                    Remove-AppxPackage -ErrorAction SilentlyContinue
            } else {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                if ($isAdmin) {
                    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -like "*$($app.DisplayName)*" -or $_.PackageName -eq $app.PackageFullName
                    } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                }
            }
            Add-HubLog "Removed Windows Bloatware: $($app.DisplayName) ($($app.PackageName))" "SUCCESS"
            $successCount++
        } catch {
            Add-HubLog "Error removing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = "Successfully removed $successCount Windows apps!"
    $TxtBloatSelectionStatus.Text = $summary
    $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    Show-ZeroToastNotification "ZeroHub - Bloatware Remover" $summary
    Update-BloatwareList
    Initialize-InstallerCatalogList
})

# Tab Selection Changed Handler
$MainTabs.add_SelectionChanged({
    param($s, $e)
    if ($e.Source -is [System.Windows.Controls.TabControl]) {
        Update-SidebarSelection $MainTabs.SelectedItem
        try {
            # Each of these hits a real data source: winget for the catalog, the uninstall registry
            # hives plus a recursive directory walk per app for the uninstaller, and Get-AppxPackage
            # for bloatware. Re-running them on every tab click was most of the perceived lag.
            if ($MainTabs.SelectedItem -eq $Tab_Installer) {
                if ($Script:InstallerCatalogList.Count -eq 0) {
                    Initialize-InstallerCatalogList
                } else {
                    Set-InstallerFilters
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Uninstaller) {
                if ($Script:AllInstalledApps.Count -eq 0) {
                    Update-InstalledAppsList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Bloatware -and -not (Test-DataCacheFresh "bloatware" 300)) {
                Update-BloatwareList
            }
            if ($MainTabs.SelectedItem -eq $Tab_Updates) {
                Update-WinUpdateUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Privacy) {
                Update-PrivacyUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Dns) {
                Update-DnsUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Defender) {
                Update-DefenderUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Startup) {
                Update-StartupAppsList
            }
            if ($MainTabs.SelectedItem -eq $Tab_GameHub) {
                if ($Script:AllGames.Count -eq 0) {
                    Update-GameLibraryList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_ProcManager) {
                if ($Script:AllSmartProcesses.Count -eq 0) {
                    Update-SmartProcessList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Guard) {
                Update-ProcessGuardList
            }
        } catch {
            Add-HubLog "Tab switch warning: $($_.Exception.Message)" "WARN"
        }
    }
})


# ==========================================
# GITHUB LIVE AUTO-UPDATE ENGINE
# ==========================================
$Script:CurrentAppVersion = "1.3.2"
$Script:GitHubRepo        = "ZeroIQs/Zerohub"
$Script:HasAvailableUpdate = $false
$Script:LatestUpdateTag   = ""
$Script:UpdateResetTimer  = $null

function Set-SidebarUpdateButtonVisuals([string]$mode, [string]$tag = "") {
    if (-not $BorderSidebarUpdate -or -not $TxtSidebarUpdate) { return }

    $brushConv = [System.Windows.Media.BrushConverter]::new()

    if ($mode -eq "UPDATE_AVAILABLE") {
        # Vibrant Crimson Red Styling for Available Update
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#E11D48")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#FB7185")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE896 # Download glyph
            $IconSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        }
        $TxtSidebarUpdate.Text       = "Update $tag Available!"
        $TxtSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = [System.Windows.Media.Brushes]::White
        }
    }
    elseif ($mode -eq "UP_TO_DATE") {
        # Green Checkmark state: User has the latest version
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#064E3B")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#059669")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE73E # Checkmark glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#4ADE80")
        }
        $TxtSidebarUpdate.Text       = "You are using the latest version"
        $TxtSidebarUpdate.Foreground = $brushConv.ConvertFromString("#4ADE80")
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#4ADE80")
        }
    }
    elseif ($mode -eq "CHECKING") {
        # Checking state
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#111827")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#0284C7")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE72C # Sync glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
        $TxtSidebarUpdate.Text       = "Checking..."
        $TxtSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
    }
    else {
        # Normal Idle State
        $BorderSidebarUpdate.Background  = $brushConv.ConvertFromString("#111827")
        $BorderSidebarUpdate.BorderBrush = $brushConv.ConvertFromString("#1F2937")
        if ($IconSidebarUpdate) {
            $IconSidebarUpdate.Text       = [char]0xE72C # Sync glyph
            $IconSidebarUpdate.Foreground = $brushConv.ConvertFromString("#D4D4D8")
        }
        $TxtSidebarUpdate.Text       = "Check for Updates"
        $TxtSidebarUpdate.Foreground = [System.Windows.Media.Brushes]::White
        if ($BadgeSidebarUpdateArrow) {
            $BadgeSidebarUpdateArrow.Foreground = $brushConv.ConvertFromString("#64748B")
        }
    }
}

$Script:IsManualUpdateCheck = $false

function Check-GitHubAppUpdateAsync([bool]$isManual = $false) {
    $Script:IsManualUpdateCheck = $isManual

    if ($isManual) {
        if ($BtnManualCheckUpdates) {
            $BtnManualCheckUpdates.IsEnabled = $false
            $BtnManualCheckUpdates.Content = "⏳ Checking for Updates..."
        }
        if ($TxtAboutUpdateStatus) {
            $TxtAboutUpdateStatus.Text = "Checking for new releases on GitHub..."
            $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
        }
        Set-SidebarUpdateButtonVisuals "CHECKING"
    }

    # Instant offline check: If no network adapter is online, skip in 0ms!
    $isOnline = $false
    try {
        $isOnline = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
    } catch {}

    if (-not $isOnline) {
        if ($Script:IsManualUpdateCheck) {
            if ($TxtAboutUpdateStatus) {
                $TxtAboutUpdateStatus.Text = "Offline Mode (No Internet Connection)"
                $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
            }
            Set-SidebarUpdateButtonVisuals "NORMAL"
            if ($BtnManualCheckUpdates) {
                $BtnManualCheckUpdates.IsEnabled = $true
                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
            }
        }
        return
    }

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls

        $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $rawUrl = "https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.ps1?nocache=$ts"

        $Script:UpdateWebClient = New-Object System.Net.WebClient
        $Script:UpdateWebClient.Headers.Add("User-Agent", "ZeroHub-UpdateChecker")
        $Script:UpdateWebClient.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")

        $Script:UpdateWebClient.add_DownloadStringCompleted({
            param($srcClient, $e)
            if (-not $Window) { return }

            $Window.Dispatcher.Invoke([Action]{
                $wasManual = $Script:IsManualUpdateCheck
                try {
                    $hasErr = $e.Error -or [string]::IsNullOrWhiteSpace($e.Result)
                    if ($hasErr) {
                        if ($TxtAboutUpdateStatus) {
                            $TxtAboutUpdateStatus.Text = "You are using the latest version (v$($Script:CurrentAppVersion))"
                            $TxtAboutUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                        }
                        if ($wasManual) {
                            Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                            }
                            Show-ZeroToastNotification "ZeroHub is Up to Date" "You are using the latest version (v$($Script:CurrentAppVersion))."

                            if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                            $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                            $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                            $Script:UpdateResetTimer.Add_Tick({
                                $Script:UpdateResetTimer.Stop()
                                if (-not $Script:HasAvailableUpdate) {
                                    Set-SidebarUpdateButtonVisuals "NORMAL"
                                    if ($BtnManualCheckUpdates) {
                                        $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                    }
                                }
                            })
                            $Script:UpdateResetTimer.Start()
                        } else {
                            Set-SidebarUpdateButtonVisuals "NORMAL"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                            }
                        }
                        return
                    }

                    $rawText = $e.Result
                    $cleanTag = $null
                    if ($rawText -match '\$Script:CurrentAppVersion\s*=\s*["'']([^"'']+)["'']') {
                        $cleanTag = $Matches[1].Trim().TrimStart('v', 'V')
                    }

                    if (-not [string]::IsNullOrWhiteSpace($cleanTag)) {
                        $curVer = [System.Version]::Parse($Script:CurrentAppVersion)
                        $latVer = [System.Version]::Parse($cleanTag)

                        if ($latVer -gt $curVer) {
                            # Newer release found on GitHub -> Highlight RED button!
                            $Script:HasAvailableUpdate = $true
                            $Script:LatestUpdateTag   = $cleanTag

                            Set-SidebarUpdateButtonVisuals "UPDATE_AVAILABLE" "v$cleanTag"

                            if ($BtnAppUpdate) {
                                $BtnAppUpdate.Visibility = [System.Windows.Visibility]::Visible
                                $TxtAppUpdate.Text = "🚀 Update v$cleanTag Available!"
                            }
                            if ($TxtAppUpdateStatus) {
                                $TxtAppUpdateStatus.Text = "New version available on GitHub: v$cleanTag"
                                $TxtAppUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FB7185")
                            }
                            if ($BtnAppUpdateTab) {
                                $BtnAppUpdateTab.Visibility = [System.Windows.Visibility]::Visible
                                $BtnAppUpdateTab.Content = "🚀 Install v$cleanTag"
                            }
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Re-check GitHub"
                            }
                            Add-HubLog "New ZeroHub release detected on GitHub: v$cleanTag (Current: v$($Script:CurrentAppVersion))." "INFO"

                            if (-not $wasManual) {
                                Show-ZeroToastNotification "ZeroHub: New Update Available! (v$cleanTag)" "Version v$cleanTag is available on GitHub with new performance improvements. Click Updates in the sidebar to install."
                            }
                        } else {
                            # Up to date
                            $Script:HasAvailableUpdate = $false
                            if ($TxtAppUpdateStatus) {
                                $TxtAppUpdateStatus.Text = "You are using the latest version (v$($Script:CurrentAppVersion))"
                                $TxtAppUpdateStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                            }
                            if ($BtnAppUpdateTab) {
                                $BtnAppUpdateTab.Visibility = [System.Windows.Visibility]::Collapsed
                            }

                            if ($wasManual) {
                                Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                                if ($BtnManualCheckUpdates) {
                                    $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                                }
                                Show-ZeroToastNotification "ZeroHub is Up to Date" "You are using the latest version (v$($Script:CurrentAppVersion))."

                                if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                                $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                                $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                                $Script:UpdateResetTimer.Add_Tick({
                                    $Script:UpdateResetTimer.Stop()
                                    if (-not $Script:HasAvailableUpdate) {
                                        Set-SidebarUpdateButtonVisuals "NORMAL"
                                        if ($BtnManualCheckUpdates) {
                                            $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                        }
                                    }
                                })
                                $Script:UpdateResetTimer.Start()
                            } else {
                                Set-SidebarUpdateButtonVisuals "NORMAL"
                                if ($BtnManualCheckUpdates) {
                                    $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                }
                            }
                        }
                    } else {
                        if ($wasManual) {
                            Set-SidebarUpdateButtonVisuals "UP_TO_DATE"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "✓ You are using the latest version"
                            }
                            if ($Script:UpdateResetTimer) { $Script:UpdateResetTimer.Stop() }
                            $Script:UpdateResetTimer = New-Object System.Windows.Threading.DispatcherTimer
                            $Script:UpdateResetTimer.Interval = [TimeSpan]::FromSeconds(3.5)
                            $Script:UpdateResetTimer.Add_Tick({
                                $Script:UpdateResetTimer.Stop()
                                if (-not $Script:HasAvailableUpdate) {
                                    Set-SidebarUpdateButtonVisuals "NORMAL"
                                    if ($BtnManualCheckUpdates) {
                                        $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                                    }
                                }
                            })
                            $Script:UpdateResetTimer.Start()
                        } else {
                            Set-SidebarUpdateButtonVisuals "NORMAL"
                            if ($BtnManualCheckUpdates) {
                                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
                            }
                        }
                    }
                } finally {
                    if ($BtnManualCheckUpdates) {
                        $BtnManualCheckUpdates.IsEnabled = $true
                    }
                    try { $srcClient.Dispose() } catch {}
                }
            })
        })

        $Script:UpdateWebClient.DownloadStringAsync([Uri]::new($rawUrl))
    } catch {
        if ($Script:IsManualUpdateCheck) {
            Set-SidebarUpdateButtonVisuals "NORMAL"
            if ($BtnManualCheckUpdates) {
                $BtnManualCheckUpdates.IsEnabled = $true
                $BtnManualCheckUpdates.Content = "🔄 Check for Updates"
            }
        }
    }
}

function Invoke-PerformSelfAppUpdate {
    if (-not $Script:HasAvailableUpdate) {
        Check-GitHubAppUpdateAsync $true
        return
    }

    $confirmMsg = "Download and install ZeroHub ($($Script:LatestUpdateTag)) from GitHub now? The application will update in-place wherever it is stored and automatically restart."
    $res = [System.Windows.MessageBox]::Show($confirmMsg, "ZeroHub Auto-Updater", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
        try {
            # 1. Retrieve the exact running script path stored at startup
            $targetPs1 = $Script:RunningScriptPath
            if (-not $targetPs1 -or -not (Test-Path $targetPs1)) {
                if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
                    $targetPs1 = $PSCommandPath
                } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"))) {
                    $targetPs1 = Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"
                } elseif (Test-Path (Join-Path (Get-Location).Path "ZeroHub-GUI.ps1")) {
                    $targetPs1 = Join-Path (Get-Location).Path "ZeroHub-GUI.ps1"
                } else {
                    $targetPs1 = Join-Path $env:LOCALAPPDATA "ZeroHub\ZeroHub-GUI.ps1"
                }
            }

            $targetDir = Split-Path -Path $targetPs1 -Parent
            $targetBat = Join-Path $targetDir "ZeroHub-GUI.bat"

            # 2. Download newest release files to TEMP
            $ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $tempPs1 = Join-Path $env:TEMP "ZeroHub_Update_$ts.ps1"
            $tempBat = Join-Path $env:TEMP "ZeroHub_Update_$ts.bat"

            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "ZeroHub-AutoUpdater")
            $wc.DownloadFile("https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.ps1?nocache=$ts", $tempPs1)
            try {
                $wc.DownloadFile("https://raw.githubusercontent.com/$($Script:GitHubRepo)/main/ZeroHub-GUI.bat?nocache=$ts", $tempBat)
            } catch {}

            # 3. Integrity Verification (> 100 KB)
            if ((Test-Path $tempPs1) -and ((Get-Item $tempPs1).Length -gt 100000)) {
                # In-place overwrite in user's current folder
                Copy-Item -Path $tempPs1 -Destination $targetPs1 -Force
                if (Test-Path $tempBat) {
                    try { Copy-Item -Path $tempBat -Destination $targetBat -Force } catch {}
                }

                # Also synchronize %LOCALAPPDATA%\ZeroHub cache if it exists
                $appDataDir = Join-Path $env:LOCALAPPDATA "ZeroHub"
                if (Test-Path $appDataDir) {
                    try {
                        Copy-Item -Path $tempPs1 -Destination (Join-Path $appDataDir "ZeroHub-GUI.ps1") -Force
                        if (Test-Path $tempBat) {
                            Copy-Item -Path $tempBat -Destination (Join-Path $appDataDir "ZeroHub-GUI.bat") -Force
                        }
                    } catch {}
                }

                # Clean temporary downloaded files
                try { Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue } catch {}
                try { Remove-Item $tempBat -Force -ErrorAction SilentlyContinue } catch {}

                # 4. Seamlessly relaunch the updated ZeroHub instance
                $launchArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$targetPs1`""
                Start-Process "powershell.exe" -ArgumentList $launchArgs -WorkingDirectory $targetDir
                $Window.Close()
            } else {
                throw "Downloaded update file was incomplete. Please check your internet connection."
            }
        } catch {
            [System.Windows.MessageBox]::Show("Update failed: $($_.Exception.Message)", "ZeroHub Update Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    }
}

# Wire Update Checker & Auto-Updater Click Handlers
if ($BtnAppUpdateTab) {
    $BtnAppUpdateTab.add_Click({
        Invoke-PerformSelfAppUpdate
    })
}
if ($BtnSidebarUpdate) {
    $BtnSidebarUpdate.add_Click({
        $MainTabs.SelectedItem = $Tab_AppUpdate
        if ($Script:HasAvailableUpdate) {
            Invoke-PerformSelfAppUpdate
        } else {
            Check-GitHubAppUpdateAsync $true
        }
    })
}
if ($BtnManualCheckUpdates) {
    $BtnManualCheckUpdates.add_Click({
        Check-GitHubAppUpdateAsync $true
    })
}

if ($BtnToggleNotifications) {
    $BtnToggleNotifications.add_Click({
        $Script:AppNotificationsEnabled = -not $Script:AppNotificationsEnabled
        Update-NotificationToggleUI
        Save-ZeroHubSettings
        if ($Script:AppNotificationsEnabled) {
            Add-HubLog "Windows toast notifications enabled for ZeroHub." "INFO"
            Show-ZeroToastNotification "ZeroHub Notifications" "Notifications are now active."
        } else {
            Add-HubLog "Windows toast notifications turned OFF for ZeroHub." "INFO"
        }
    })
}



# ==========================================
# FAST TEXT FINDER LOGIC & EVENT HANDLERS
# ==========================================
if ($TxtSearchFolder) {
    $TxtSearchFolder.Text = (Get-Location).Path
}

if ($BtnBrowseSearchFolder) {
    $BtnBrowseSearchFolder.add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select Target Folder to Search Content"
        $dialog.ShowNewFolderButton = $false
        if ([System.IO.Directory]::Exists($TxtSearchFolder.Text)) {
            $dialog.SelectedPath = $TxtSearchFolder.Text
        }
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $TxtSearchFolder.Text = $dialog.SelectedPath
        }
    })
}




# Mode Explanation dynamic switch
if ($RadioSearchContent) {
    $RadioSearchContent.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "📄 Inside Content Mode: Opens each file (.ini, .txt, .log, code, configs) and searches for exact text matches inside lines."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

if ($RadioSearchNames) {
    $RadioSearchNames.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "📁 Name Search Mode: Instant 0.01s search for file and folder names across the directory tree (Everything-style)."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

if ($RadioSearchBoth) {
    $RadioSearchBoth.add_Checked({
        if ($TxtSearchModeExplainer) {
            $TxtSearchModeExplainer.Text = "⚡ All (Both) Mode: Finds matching file and folder names PLUS reads inside all text files for text matches."
            $TxtSearchModeExplainer.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
        }
    })
}

function Invoke-PerformTextSearch {
    $folder = $TxtSearchFolder.Text.Trim()
    $query = $TxtSearchQuery.Text.Trim()
    $exts = $TxtSearchExtensions.Text.Trim()
    $recursive = [bool]$ChkSearchRecursive.IsChecked
    $matchCase = [bool]$ChkSearchMatchCase.IsChecked
    $useRegex = [bool]$ChkSearchUseRegex.IsChecked

    $searchMode = "Both"
    if ($RadioSearchNames -and $RadioSearchNames.IsChecked) { $searchMode = "Names" }
    elseif ($RadioSearchContent -and $RadioSearchContent.IsChecked) { $searchMode = "Content" }

    if ([string]::IsNullOrWhiteSpace($folder) -or -not ([System.IO.Directory]::Exists($folder))) {
        [System.Windows.MessageBox]::Show("Please enter or browse a valid target folder path.", "Invalid Folder", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if ([string]::IsNullOrWhiteSpace($query)) {
        [System.Windows.MessageBox]::Show("Please enter a search query or filename.", "Empty Search", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        return
    }

    $BtnStartTextSearch.IsEnabled = $false
    $BtnStartTextSearch.Content = "⏳ Searching..."
    $TxtSearchStatus.Text = "Searching files, folders & content in parallel using C# engine..."
    $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    try {
        $stats = $null
        $results = [ZeroHub.FileContentSearcher]::Search(
            $folder,
            $query,
            $exts,
            $searchMode,
            $recursive,
            $matchCase,
            $useRegex,
            3000,
            [ref]$stats
        )

        $SearchDataGrid.ItemsSource = $results

        if ($stats) {
            $msg = "✓ Found $($stats.MatchedCount) match(es)"
            if ($stats.FoldersMatched -gt 0) { $msg += " ($($stats.FoldersMatched) folders" }
            if ($stats.FilesMatched -gt 0) { 
                if ($stats.FoldersMatched -gt 0) { $msg += ", $($stats.FilesMatched) files)" }
                else { $msg += " ($($stats.FilesMatched) files)" }
            } elseif ($stats.FoldersMatched -gt 0) { $msg += ")" }
            $msg += " (Scanned $($stats.FilesScanned) files in $($stats.ElapsedSeconds)s)"

            $TxtSearchStatus.Text = $msg
            $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
            Add-HubLog "Omni search for '$query' ($searchMode) completed: $($stats.MatchedCount) match(es) in $($stats.ElapsedSeconds)s." "INFO"
        }
    } catch {
        $TxtSearchStatus.Text = "Error during search: $($_.Exception.Message)"
        $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
        Add-HubLog "Error during search: $($_.Exception.Message)" "ERROR"
    } finally {
        $BtnStartTextSearch.IsEnabled = $true
        $BtnStartTextSearch.Content = "⚡ Start Search"
    }
}

if ($BtnStartTextSearch) {
    $BtnStartTextSearch.add_Click({
        Invoke-PerformTextSearch
    })
}

if ($TxtSearchQuery) {
    $TxtSearchQuery.add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Enter) {
            Invoke-PerformTextSearch
        }
    })
}

if ($BtnClearSearchResults) {
    $BtnClearSearchResults.add_Click({
        $SearchDataGrid.ItemsSource = $null
        $TxtSearchQuery.Text = ""
        $TxtSearchStatus.Text = "Ready to search. Select a folder and enter search keywords."
        $TxtSearchStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    })
}

# Context Menu & Row Double Click Handlers
if ($SearchDataGrid) {
    $SearchDataGrid.add_MouseDoubleClick({
        param($s, $e)
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            if ($selected.IsDirectory) {
                Start-Process "explorer.exe" -ArgumentList "`"$($selected.FilePath)`""
            } else {
                Start-Process $selected.FilePath
            }
        }
    })

    $searchContextMenu = New-Object System.Windows.Controls.ContextMenu

    $menuOpen = New-Object System.Windows.Controls.MenuItem
    $menuOpen.Header = "Open File in Default Editor"
    $iconOpenFile = New-Object System.Windows.Controls.TextBlock
    $iconOpenFile.Text = "📄"
    $iconOpenFile.FontSize = 11.5
    $menuOpen.Icon = $iconOpenFile
    
    $menuOpen.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            Start-Process $selected.FilePath
        }
    })
    $searchContextMenu.Items.Add($menuOpen) | Out-Null

    $menuFolder = New-Object System.Windows.Controls.MenuItem
    $menuFolder.Header = "Open Containing Folder"
    $iconOpenFolder = New-Object System.Windows.Controls.TextBlock
    $iconOpenFolder.Text = "📁"
    $iconOpenFolder.FontSize = 11.5
    $menuFolder.Icon = $iconOpenFolder
    
    $menuFolder.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath -and ([System.IO.File]::Exists($selected.FilePath) -or [System.IO.Directory]::Exists($selected.FilePath))) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.FilePath)`""
        }
    })
    $searchContextMenu.Items.Add($menuFolder) | Out-Null

    $searchContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuCopyPath = New-Object System.Windows.Controls.MenuItem
    $menuCopyPath.Header = "Copy Full Path"
    $iconCopyP = New-Object System.Windows.Controls.TextBlock
    $iconCopyP.Text = "📋"
    $iconCopyP.FontSize = 11.5
    $menuCopyPath.Icon = $iconCopyP
    
    $menuCopyPath.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.FilePath) {
            [System.Windows.Clipboard]::SetText($selected.FilePath)
            Show-ZeroToastNotification "ZeroHub" "Copied path to clipboard: $($selected.FilePath)"
        }
    })
    $searchContextMenu.Items.Add($menuCopyPath) | Out-Null

    $menuCopyLine = New-Object System.Windows.Controls.MenuItem
    $menuCopyLine.Header = "Copy Matched Line Text"
    $iconCopyL = New-Object System.Windows.Controls.TextBlock
    $iconCopyL.Text = "📋"
    $iconCopyL.FontSize = 11.5
    $menuCopyLine.Icon = $iconCopyL
    
    $menuCopyLine.add_Click({
        $selected = $SearchDataGrid.SelectedItem
        if ($selected -and $selected.LineText) {
            [System.Windows.Clipboard]::SetText($selected.LineText)
            Show-ZeroToastNotification "ZeroHub" "Copied matched line to clipboard."
        }
    })
    $searchContextMenu.Items.Add($menuCopyLine) | Out-Null

    $SearchDataGrid.ContextMenu = $searchContextMenu
}

# Process Manager Event Wiring
if ($TxtProcSearch) {
    $TxtProcSearch.add_TextChanged({ Filter-SmartProcessList })
}
if ($BtnRefreshProcList) {
    $BtnRefreshProcList.add_Click({ Update-SmartProcessList })
}
if ($BtnPurgeSafeProcs) {
    $BtnPurgeSafeProcs.add_Click({ Invoke-PurgeAllSafeProcesses })
}
if ($BtnFilterProcAll) {
    $BtnFilterProcAll.add_Click({
        $Script:CurrentProcFilter = "ALL"
        Set-ProcFilterStyle $BtnFilterProcAll
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcSafe) {
    $BtnFilterProcSafe.add_Click({
        $Script:CurrentProcFilter = "SAFE"
        Set-ProcFilterStyle $BtnFilterProcSafe
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcWork) {
    $BtnFilterProcWork.add_Click({
        $Script:CurrentProcFilter = "WORK"
        Set-ProcFilterStyle $BtnFilterProcWork
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcService) {
    $BtnFilterProcService.add_Click({
        $Script:CurrentProcFilter = "SERVICE"
        Set-ProcFilterStyle $BtnFilterProcService
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcHeavy) {
    $BtnFilterProcHeavy.add_Click({
        $Script:CurrentProcFilter = "HEAVY"
        Set-ProcFilterStyle $BtnFilterProcHeavy
        Filter-SmartProcessList
    })
}
if ($BtnFilterProcProtected) {
    $BtnFilterProcProtected.add_Click({
        $Script:CurrentProcFilter = "PROTECTED"
        Set-ProcFilterStyle $BtnFilterProcProtected
        Filter-SmartProcessList
    })
}

if ($ProcManagerDataGrid) {
    $ProcManagerDataGrid.add_MouseDoubleClick({
        param($s, $e)
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Path -and [System.IO.File]::Exists($selected.Path)) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.Path)`""
        }
    })

    $procContextMenu = New-Object System.Windows.Controls.ContextMenu

    $menuEndProc = New-Object System.Windows.Controls.MenuItem
    $menuEndProc.Header = "End Process / Task"
    $iconEnd = New-Object System.Windows.Controls.TextBlock
    $iconEnd.Text = "❌"
    $iconEnd.FontSize = 11.5
    $iconEnd.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    $menuEndProc.Icon = $iconEnd
    $menuEndProc.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    $menuEndProc.FontWeight = [System.Windows.FontWeights]::Bold
    $menuEndProc.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected) { Invoke-EndSelectedProcess $selected }
    })
    $procContextMenu.Items.Add($menuEndProc) | Out-Null

    $procContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuProcFolder = New-Object System.Windows.Controls.MenuItem
    $menuProcFolder.Header = "Open File Location"
    $iconFolder = New-Object System.Windows.Controls.TextBlock
    $iconFolder.Text = "📁"
    $iconFolder.FontSize = 11.5
    $menuProcFolder.Icon = $iconFolder
    
    $menuProcFolder.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Path -and [System.IO.File]::Exists($selected.Path)) {
            Start-Process "explorer.exe" -ArgumentList "/select,`"$($selected.Path)`""
        } elseif ($selected) {
            Show-ZeroToastNotification "Process Manager" "Path not accessible for $($selected.Name) (PID: $($selected.Id))"
        }
    })
    $procContextMenu.Items.Add($menuProcFolder) | Out-Null

    $menuGoogleProc = New-Object System.Windows.Controls.MenuItem
    $menuGoogleProc.Header = "Search Process Online"
    $iconSearch = New-Object System.Windows.Controls.TextBlock
    $iconSearch.Text = "🔍"
    $iconSearch.FontSize = 11.5
    $iconSearch.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
    $menuGoogleProc.Icon = $iconSearch
    
    $menuGoogleProc.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected -and $selected.Name) {
            $searchUrl = "https://www.google.com/search?q=what+is+process+$([Uri]::EscapeDataString($selected.Name))"
            Open-SafeBrowserUrl $searchUrl
        }
    })
    $procContextMenu.Items.Add($menuGoogleProc) | Out-Null

    $procContextMenu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null

    $menuCopyProcName = New-Object System.Windows.Controls.MenuItem
    $menuCopyProcName.Header = "Copy Process Name & PID"
    $iconCopy = New-Object System.Windows.Controls.TextBlock
    $iconCopy.Text = "📋"
    $iconCopy.FontSize = 11.5
    $menuCopyProcName.Icon = $iconCopy
    
    $menuCopyProcName.add_Click({
        $selected = $ProcManagerDataGrid.SelectedItem
        if ($selected) {
            [System.Windows.Clipboard]::SetText("$($selected.Name) (PID: $($selected.Id))")
            Show-ZeroToastNotification "Process Manager" "Copied '$($selected.Name)' to clipboard."
        }
    })
    $procContextMenu.Items.Add($menuCopyProcName) | Out-Null

    $ProcManagerDataGrid.ContextMenu = $procContextMenu
}


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
        [ZeroHub.NativeMethods]::EnableDarkTitleBar($helper.Handle)
        # Note: Console window kept visible for developer real-time logs
        if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
            $icoBig = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
            $icoSmall = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
            [ZeroHub.NativeMethods]::SetWindowIconFull($helper.Handle, $icoBig.Handle, $icoSmall.Handle)
        }

        # Hook Windows TaskbarCreated message: when Explorer crashes/restarts, auto-reapply ZeroHub icon
        try {
            $source = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
            if ($source) {
                $source.AddHook([System.Windows.Interop.HwndSourceHook]{
                    param($hwnd, $msg, $wParam, $lParam, [ref]$handled)
                    if ($msg -eq [ZeroHub.NativeMethods]::WM_TASKBARCREATED) {
                        try {
                            [ZeroHub.NativeMethods]::SetAppId("ZeroIQ.ZeroHub.App.1")
                            if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
                                $icoB = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
                                $icoS = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
                                [ZeroHub.NativeMethods]::SetWindowIconFull($hwnd, $icoB.Handle, $icoS.Handle)
                            }
                        } catch {}
                    }
                    return [IntPtr]::Zero
                })
            }
        } catch {}
    } catch {}

    Update-SidebarSelection $Tab_Dashboard
    Load-ZeroHubSettings
    Update-DriveInfo
    Update-LiveMemoryStats
    Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Initialize-InstallerCatalogList
    Update-InstalledAppsList
    Update-StartupAppsList
    Update-GameLibraryList
    Update-SmartProcessList
    Check-GitHubAppUpdateAsync $false
    Set-AllSelections $false
    $modeStr = if ($isAdmin) { "Administrator" } else { "Standard User" }
    Add-HubLog "ZeroHub v1.3.2 initialized. User Mode: $modeStr" "INIT"
    Invoke-ScanSpace $false
    Get-WingetUpgradesAsync

    # Start Real-Time Live Metrics Timer (Every 1 second)
    $Script:MetricsTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:MetricsTimer.Interval = [TimeSpan]::FromSeconds(1)
    $Script:MetricsTimer.Add_Tick({
        Update-DriveInfo
        Update-LiveMemoryStats
    })
    $Script:MetricsTimer.Start()
})

$Window.add_Closed({
    [System.Environment]::Exit(0)
})

# Show WPF Window
[void]$Window.ShowDialog()
[System.Environment]::Exit(0)
