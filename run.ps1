# ZeroCleaner 1-Line Web Runner
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$bytes = (New-Object System.Net.WebClient).DownloadData("https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/ZeroCleaner-GUI.ps1")
$code = [System.Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
Invoke-Expression $code
