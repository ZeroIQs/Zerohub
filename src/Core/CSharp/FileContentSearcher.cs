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

