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

