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

