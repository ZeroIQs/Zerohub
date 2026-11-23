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

