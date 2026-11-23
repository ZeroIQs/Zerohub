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

