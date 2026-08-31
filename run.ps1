# ZeroHub GUI Web Bootstrapper
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

$localDir = Join-Path $env:LOCALAPPDATA "ZeroHub"
$localScript = Join-Path $localDir "ZeroHub-GUI.ps1"
$localBat = Join-Path $localDir "ZeroHub-GUI.bat"

if (-not (Test-Path $localDir)) {
    New-Item -ItemType Directory -Path $localDir -Force | Out-Null
}

$ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$downloadUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroHub-GUI.ps1?nocache=$ts"
$scriptText = $null

$isOnline = $false
try {
    $isOnline = [System.Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()
} catch {}

if ($isOnline) {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', 'ZeroHub-Launcher')
        $wc.Headers.Add('Cache-Control', 'no-cache, no-store, must-revalidate')
        $wc.Headers.Add('Pragma', 'no-cache')

        try {
            $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/ZeroIQs/Zerohub/commits/main?t=$ts" -Headers @{ "Cache-Control" = "no-cache"; "User-Agent" = "ZeroHub" } -TimeoutSec 3
            if ($commit -and $commit.sha) {
                $downloadUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/$($commit.sha)/ZeroHub-GUI.ps1"
            }
        } catch {}

        $b = $wc.DownloadData($downloadUrl)
        $scriptText = [System.Text.Encoding]::UTF8.GetString($b).TrimStart([char]0xFEFF)

        # Cache locally with UTF-8 BOM so offline startup works forever
        [System.IO.File]::WriteAllText($localScript, $scriptText, [System.Text.Encoding]::UTF8)

        $batContent = "@echo off`r`ntitle ZeroHub GUI Launcher`r`ncd /d `"%~dp0`"`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0ZeroHub-GUI.ps1`"`r`npause"
        [System.IO.File]::WriteAllText($localBat, $batContent, [System.Text.Encoding]::ASCII)

        try {
            $icoUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.ico"
            $localIco = Join-Path $localDir "logo.ico"
            if (-not (Test-Path $localIco)) {
                $wc.DownloadFile($icoUrl, $localIco)
            }
        } catch {}
    } catch {}
}

# If offline or GitHub request failed, run the cached local copy
if (-not $scriptText -and (Test-Path $localScript)) {
    $scriptText = [System.IO.File]::ReadAllText($localScript, [System.Text.Encoding]::UTF8)
}

if ($scriptText) {
    if (Test-Path $localScript) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$localScript"
    } else {
        Invoke-Expression $scriptText
    }
} else {
    Write-Host "ZeroHub: Unable to connect to GitHub and no local copy found. Please check your internet connection for the first run." -ForegroundColor Red
}