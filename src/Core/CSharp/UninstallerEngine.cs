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
