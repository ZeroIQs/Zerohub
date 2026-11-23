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

