function Update-DnsUI {
    if (-not $Tab_Dns) { return }

    $activeServers = Get-CurrentActiveDnsList
    $matchedProvider = $null

    foreach ($prov in $Script:DnsProviders) {
        $isMatch = ($activeServers.Count -gt 0 -and $activeServers.Contains($prov.Primary))
        $cardBorder = $Window.FindName("CardDns_" + $prov.Id)
        $applyBtn   = $Window.FindName("BtnApplyDns_" + $prov.Id)

        if ($isMatch) {
            $matchedProvider = $prov
            if ($cardBorder) {
                $cardBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
                $cardBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B6B48")
            }
            if ($applyBtn) {
                $applyBtn.Content = "Disconnect"
                $applyBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
                $applyBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
                $applyBtn.FontWeight = [System.Windows.FontWeights]::Bold
                $applyBtn.IsEnabled = $true
            }
        } else {
            if ($cardBorder) {
                $cardBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#111114")
                $cardBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
            }
            if ($applyBtn) {
                $applyBtn.Content = "Apply DNS"
                $applyBtn.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
                $applyBtn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $applyBtn.FontWeight = [System.Windows.FontWeights]::SemiBold
                $applyBtn.IsEnabled = $true
            }
        }
    }

    if ($BadgeDnsActiveStatus -and $TxtDnsActiveStatus) {
        if ($matchedProvider) {
            $BadgeDnsActiveStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1A2E1F")
            $BadgeDnsActiveStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B6B48")
            $TxtDnsActiveStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
            $TxtDnsActiveStatus.Text = "🛡️ Active: $($matchedProvider.Name)"
        } else {
            $BadgeDnsActiveStatus.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#111114")
            $BadgeDnsActiveStatus.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
            $TxtDnsActiveStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
            $TxtDnsActiveStatus.Text = "🌐 Automatic (DHCP / ISP)"
        }
    }
}

function Handle-DnsPresetClick([string]$primary, [string]$secondary, [string]$name, $btn) {
    $activeServers = Get-CurrentActiveDnsList
    if ($activeServers.Count -gt 0 -and $activeServers.Contains($primary)) {
        Restore-DefaultDnsDhcp
    } else {
        Set-SystemDnsServers $primary $secondary $name $btn
    }
}

# Wire DNS Action Buttons
if ($BtnRunDnsBenchmark) {
    $BtnRunDnsBenchmark.add_Click({ Test-AllDnsLatencies })
}
if ($BtnRestoreDnsDhcp) {
    $BtnRestoreDnsDhcp.add_Click({ Restore-DefaultDnsDhcp })
}
if ($BtnFlushDns) {
    $BtnFlushDns.add_Click({ Invoke-QuickFlushDns })
}
if ($BtnToolFlushDns) {
    $BtnToolFlushDns.add_Click({ Invoke-QuickFlushDns })
}
if ($BtnToolResetWinsock) {
    $BtnToolResetWinsock.add_Click({ Invoke-ResetWinsockAndTcp })
}
if ($BtnToolRenewIp) {
    $BtnToolRenewIp.add_Click({ Invoke-ReleaseRenewIp })
}

# Wire Preset Apply Buttons
$btnCloudflare = $Window.FindName("BtnApplyDns_cloudflare")
if ($btnCloudflare) {
    $btnCloudflare.add_Click({ Handle-DnsPresetClick "1.1.1.1" "1.0.0.1" "Cloudflare" $btnCloudflare })
}
$btnAdGuard = $Window.FindName("BtnApplyDns_adguard")
if ($btnAdGuard) {
    $btnAdGuard.add_Click({ Handle-DnsPresetClick "94.140.14.14" "94.140.15.15" "AdGuard DNS" $btnAdGuard })
}
$btnQuad9 = $Window.FindName("BtnApplyDns_quad9")
if ($btnQuad9) {
    $btnQuad9.add_Click({ Handle-DnsPresetClick "9.9.9.9" "149.112.112.112" "Quad9 Secure" $btnQuad9 })
}
$btnGoogle = $Window.FindName("BtnApplyDns_google")
if ($btnGoogle) {
    $btnGoogle.add_Click({ Handle-DnsPresetClick "8.8.8.8" "8.8.4.4" "Google Public DNS" $btnGoogle })
}
$btnOpenDns = $Window.FindName("BtnApplyDns_opendns")
if ($btnOpenDns) {
    $btnOpenDns.add_Click({ Handle-DnsPresetClick "208.67.222.222" "208.67.220.220" "Cisco OpenDNS" $btnOpenDns })
}
$btnCleanBrowsing = $Window.FindName("BtnApplyDns_cleanbrowsing")
if ($btnCleanBrowsing) {
    $btnCleanBrowsing.add_Click({ Handle-DnsPresetClick "185.228.168.168" "185.228.169.168" "CleanBrowsing" $btnCleanBrowsing })
}

if ($BtnApplyCustomDns) {
    $BtnApplyCustomDns.add_Click({
        $p = if ($TxtCustomDnsPrimary -and $TxtCustomDnsPrimary.Text) { $TxtCustomDnsPrimary.Text.Trim() } else { "" }
        $s = if ($TxtCustomDnsSecondary -and $TxtCustomDnsSecondary.Text) { $TxtCustomDnsSecondary.Text.Trim() } else { "" }
        if (-not [string]::IsNullOrWhiteSpace($p)) {
            Set-SystemDnsServers $p $s "Custom DNS"
        }
    })
}

