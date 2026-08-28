[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    $b = (New-Object System.Net.WebClient).DownloadData('https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroHub-GUI.ps1')
} catch {
    $b = (New-Object System.Net.WebClient).DownloadData('https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/ZeroCleaner-GUI.ps1')
}
$s = [System.Text.Encoding]::UTF8.GetString($b).TrimStart([char]0xFEFF)
Invoke-Expression $s