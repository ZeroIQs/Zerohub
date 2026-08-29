[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('User-Agent', 'ZeroHub-Launcher')
$wc.Headers.Add('Cache-Control', 'no-cache')
$wc.Headers.Add('Pragma', 'no-cache')

# Dynamically resolve latest commit SHA to guarantee instant, cache-free execution
$downloadUrl = "https://raw.githubusercontent.com/itninja04/Zerohub/main/ZeroHub-GUI.ps1"
try {
    $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/itninja04/Zerohub/commits/main" -Headers @{ "Cache-Control" = "no-cache"; "User-Agent" = "ZeroHub" } -TimeoutSec 3
    if ($commit.sha) {
        $downloadUrl = "https://raw.githubusercontent.com/itninja04/Zerohub/$($commit.sha)/ZeroHub-GUI.ps1"
    }
} catch {
    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $downloadUrl = "https://raw.githubusercontent.com/itninja04/Zerohub/main/ZeroHub-GUI.ps1?v=$ts"
}

$b = $wc.DownloadData($downloadUrl)
$s = [System.Text.Encoding]::UTF8.GetString($b).TrimStart([char]0xFEFF)
Invoke-Expression $s