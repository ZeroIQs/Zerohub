[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent', 'ZeroHub-Launcher')
$wc.Headers.Add('Cache-Control', 'no-cache, no-store, must-revalidate')
$wc.Headers.Add('Pragma', 'no-cache')

# Dynamically resolve latest commit SHA or use millisecond timestamp to bypass all CDN caching
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$downloadUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroHub-GUI.ps1?t=$ts"

try {
    $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/ZeroIQs/Zerohub/commits/main?t=$ts" -Headers @{ "Cache-Control" = "no-cache"; "User-Agent" = "ZeroHub" } -TimeoutSec 3
    if ($commit.sha) {
        $downloadUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/$($commit.sha)/ZeroHub-GUI.ps1"
    }
} catch {
    # Fallback to timestamped direct raw URL
    $downloadUrl = "https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroHub-GUI.ps1?nocache=$ts"
}

$b = $wc.DownloadData($downloadUrl)
$s = [System.Text.Encoding]::UTF8.GetString($b).TrimStart([char]0xFEFF)
Invoke-Expression $s