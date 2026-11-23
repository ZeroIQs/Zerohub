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
if ($BtnOpenWebsite)      { $BtnOpenWebsite.add_Click($OpenZeroIqWebsite) }
if ($BtnOpenDonate)       { $BtnOpenDonate.add_Click($OpenZeroIqDonate) }

