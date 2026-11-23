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

