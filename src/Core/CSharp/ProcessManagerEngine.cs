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

