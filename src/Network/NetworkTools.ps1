function Invoke-QuickFlushDns {
    if ($BtnFlushDns) {
        $BtnFlushDns.IsEnabled = $false
        $BtnFlushDns.Content = "⏳ Flushing..."
    }
    if ($BtnToolFlushDns) {
        $BtnToolFlushDns.IsEnabled = $false
        $BtnToolFlushDns.Content = "⏳ Flushing DNS Resolver Cache..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Purging Windows DNS resolver cache..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        ipconfig /flushdns 2>$null | Out-Null
        Start-Sleep -Milliseconds 300
        $msg = "Windows DNS resolver cache flushed successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error flushing DNS cache: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnFlushDns) {
            $BtnFlushDns.Content = "✅ Flushed!"
            $t1 = [System.Windows.Threading.DispatcherTimer]::new()
            $t1.Interval = [TimeSpan]::FromSeconds(2.5)
            $t1.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnFlushDns) {
                    $BtnFlushDns.IsEnabled = $true
                    $BtnFlushDns.Content = "🧹 Flush DNS"
                }
            })
            $t1.Start()
        }
        if ($BtnToolFlushDns) {
            $BtnToolFlushDns.Content = "✅ DNS Cache Flushed Successfully!"
            $t2 = [System.Windows.Threading.DispatcherTimer]::new()
            $t2.Interval = [TimeSpan]::FromSeconds(2.5)
            $t2.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolFlushDns) {
                    $BtnToolFlushDns.IsEnabled = $true
                    $BtnToolFlushDns.Content = "🧹 Flush DNS Resolver Cache"
                }
            })
            $t2.Start()
        }
    }
}

function Invoke-ResetWinsockAndTcp {
    if ($BtnToolResetWinsock) {
        $BtnToolResetWinsock.IsEnabled = $false
        $BtnToolResetWinsock.Content = "⏳ Resetting Winsock & TCP/IP Stack..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Resetting Winsock catalog & TCP/IP network stack..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process -FilePath "netsh.exe" -ArgumentList "int ip reset" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        $msg = "Winsock & TCP/IP stack reset successfully! (Reboot recommended)."
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error resetting network stack: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnToolResetWinsock) {
            $BtnToolResetWinsock.Content = "✅ Network Stack Reset Successfully!"
            $t = [System.Windows.Threading.DispatcherTimer]::new()
            $t.Interval = [TimeSpan]::FromSeconds(3)
            $t.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolResetWinsock) {
                    $BtnToolResetWinsock.IsEnabled = $true
                    $BtnToolResetWinsock.Content = "🔄 Reset Winsock & TCP/IP Stack"
                }
            })
            $t.Start()
        }
    }
}

function Invoke-ReleaseRenewIp {
    if ($BtnToolRenewIp) {
        $BtnToolRenewIp.IsEnabled = $false
        $BtnToolRenewIp.Content = "⏳ Releasing & Renewing IP Address..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Releasing and renewing DHCP IPv4 address lease..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        Start-Process -FilePath "ipconfig.exe" -ArgumentList "/release" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process -FilePath "ipconfig.exe" -ArgumentList "/renew" -NoNewWindow -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        $msg = "Network IP address released and renewed successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub Network" $msg
    } catch {
        Add-HubLog "Error renewing IP: $($_.Exception.Message)" "ERROR"
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnToolRenewIp) {
            $BtnToolRenewIp.Content = "✅ IP Address Renewed Successfully!"
            $t = [System.Windows.Threading.DispatcherTimer]::new()
            $t.Interval = [TimeSpan]::FromSeconds(3)
            $t.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnToolRenewIp) {
                    $BtnToolRenewIp.IsEnabled = $true
                    $BtnToolRenewIp.Content = "⚡ Release & Renew IP Address"
                }
            })
            $t.Start()
        }
    }
}

function Test-AllDnsLatencies {
    if ($BtnRunDnsBenchmark) { $BtnRunDnsBenchmark.IsEnabled = $false }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Benchmarking DNS response times (Ping test)..."
    [System.Windows.Forms.Application]::DoEvents()

    $pinger = [System.Net.NetworkInformation.Ping]::new()
    $lowestPing = 99999
    $fastestId = ""
    $pingResults = @{}

    foreach ($prov in $Script:DnsProviders) {
        $targetIp = $prov.Primary
        $latency = 9999
        try {
            $reply = $pinger.Send($targetIp, 1200)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $latency = [int]$reply.RoundtripTime
            }
        } catch {}

        $pingResults[$prov.Id] = $latency
        if ($latency -lt $lowestPing -and $latency -ge 0) {
            $lowestPing = $latency
            $fastestId = $prov.Id
        }
    }

    # Update UI badges
    foreach ($prov in $Script:DnsProviders) {
        $badgeText = $Window.FindName("TxtPingDns_" + $prov.Id)
        $badgeBorder = $Window.FindName("Border_PingDns_" + $prov.Id)
        if ($badgeText -and $badgeBorder) {
            $p = $pingResults[$prov.Id]
            if ($p -lt 1000) {
                if ($prov.Id -eq $fastestId) {
                    $fastestTag = "Fastest"
                    $badgeText.Text = "$p ms ⚡ $fastestTag"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#059669")
                } elseif ($p -le 35) {
                    $badgeText.Text = "$p ms"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0C2340")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
                } else {
                    $badgeText.Text = "$p ms"
                    $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                    $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#451A03")
                    $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
                }
            } else {
                $badgeText.Text = "Timeout"
                $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#c15f3c")
                $badgeBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4C0519")
                $badgeBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
            }
        }
    }

    if ($BtnRunDnsBenchmark) { $BtnRunDnsBenchmark.IsEnabled = $true }
    $StatusIcon.Text = [char]0xE73E
    $fastestName = if ($fastestId) { ($Script:DnsProviders | Where-Object { $_.Id -eq $fastestId }).Name } else { "None" }
    $doneMsg = "Benchmark Complete! Fastest DNS in your area: $fastestName ($lowestPing ms)"
    $StatusText.Text = $doneMsg
    Add-HubLog $doneMsg "SUCCESS"
}

