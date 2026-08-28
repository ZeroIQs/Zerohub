[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient
$wc.Headers.Add('Cache-Control', 'no-cache')
$wc.Headers.Add('Pragma', 'no-cache')
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$b = $wc.DownloadData("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroHub-GUI.ps1?v=$ts")
$s = [System.Text.Encoding]::UTF8.GetString($b).TrimStart([char]0xFEFF)
Invoke-Expression $s