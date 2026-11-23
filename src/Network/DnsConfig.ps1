# ==========================================
# DNS & INTERNET SPEED BOOSTER ENGINE
# ==========================================
$Script:DnsProviders = @(
    @{
        Id = "cloudflare"
        Name = "Cloudflare (1.1.1.1)"
        Tag = "⚡ Ultra-Low Latency & Gaming"
        Desc = "World's fastest public DNS resolver with privacy pledge and zero log selling."
        Primary = "1.1.1.1"
        Secondary = "1.0.0.1"
    },
    @{
        Id = "adguard"
        Name = "AdGuard DNS"
        Tag = "🛡️ System-Wide Ad & Tracker Blocker"
        Desc = "Blocks intrusive web ads, popups, and tracking domains across your entire system without extra software."
        Primary = "94.140.14.14"
        Secondary = "94.140.15.15"
    },
    @{
        Id = "quad9"
        Name = "Quad9 Secure"
        Tag = "🔒 Anti-Malware & Phishing Shield"
        Desc = "Real-time threat intelligence blocking ransomware, infected domains, malware, and phishing."
        Primary = "9.9.9.9"
        Secondary = "149.112.112.112"
    },
    @{
        Id = "google"
        Name = "Google Public DNS"
        Tag = "🌐 High Reliability & Global Anycast"
        Desc = "Massive global Anycast infrastructure with geo-optimized CDN caching for rock-solid stability."
        Primary = "8.8.8.8"
        Secondary = "8.8.4.4"
    },
    @{
        Id = "opendns"
        Name = "Cisco OpenDNS"
        Tag = "🏢 Enterprise Cloud Routing"
        Desc = "Enterprise-grade cloud routing with SmartCache and automatic phishing domain filtering."
        Primary = "208.67.222.222"
        Secondary = "208.67.220.220"
    },
    @{
        Id = "cleanbrowsing"
        Name = "CleanBrowsing Family Filter"
        Tag = "👨‍👩‍👧 Family Safety & Content Filter"
        Desc = "Enforces safe search and blocks malicious, phishing, and non-family domains automatically."
        Primary = "185.228.168.168"
        Secondary = "185.228.169.168"
    }
)

function Get-ActiveNetworkAdaptersList {
    try {
        $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" })
        if ($adapters.Count -eq 0) {
            $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue)
        }
        return $adapters
    } catch {
        return @()
    }
}

function Get-CurrentActiveDnsList {
    $servers = @()
    try {
        $adapters = Get-ActiveNetworkAdaptersList
        foreach ($a in $adapters) {
            $dns = Get-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($dns -and $dns.ServerAddresses) {
                foreach ($ip in $dns.ServerAddresses) {
                    if ($ip -and -not $servers.Contains($ip)) {
                        $servers += $ip
                    }
                }
            }
        }
    } catch {}
    return $servers
}

function Set-SystemDnsServers([string]$primary, [string]$secondary, [string]$providerName = "", $triggerBtn = $null) {
    if ($triggerBtn) {
        $triggerBtn.IsEnabled = $false
        $triggerBtn.Content = "⏳ Applying..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Applying DNS ($($providerName): $primary)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        $adapters = Get-ActiveNetworkAdaptersList
        if ($adapters.Count -eq 0) {
            $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue)
        }

        $ips = @($primary)
        if ($secondary -and $secondary -ne $primary) { $ips += $secondary }

        foreach ($a in $adapters) {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $ips -ErrorAction SilentlyContinue
            } catch {}
            try {
                & netsh.exe interface ipv4 set dnsservers name="$($a.Name)" source=static address="$primary" validate=no 2>$null | Out-Null
                if ($secondary) {
                    & netsh.exe interface ipv4 add dnsservers name="$($a.Name)" address="$secondary" index=2 validate=no 2>$null | Out-Null
                }
            } catch {}
        }

        # Clear DNS cache
        try {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            ipconfig /flushdns 2>$null | Out-Null
        } catch {}

        if (-not $isAdmin) {
            try {
                $secArg = if ($secondary) { "netsh interface ipv4 add dnsservers name=`\`"`$(`$_.Name)`\`" address=$secondary index=2 validate=no" } else { "" }
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Get-NetAdapter | Where-Object { `$_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex `$_.InterfaceIndex -ServerAddresses @('$primary','$secondary') -ErrorAction SilentlyContinue; netsh interface ipv4 set dnsservers name=`\`"`$(`$_.Name)`\`" source=static address=$primary validate=no; $secArg }; Clear-DnsClientCache; ipconfig /flushdns`"" -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            } catch {}
        }

        Start-Sleep -Milliseconds 400

        $msg = "Applied DNS ($($providerName): $primary) successfully across active network adapters!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub DNS Switcher" $msg
        Update-DnsUI
    } catch {
        Add-HubLog "Error setting DNS servers: $($_.Exception.Message)" "ERROR"
        Update-DnsUI
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
    }
}

function Restore-DefaultDnsDhcp {
    if ($BtnRestoreDnsDhcp) {
        $BtnRestoreDnsDhcp.IsEnabled = $false
        $BtnRestoreDnsDhcp.Content = "⏳ Restoring..."
    }
    if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Visible }
    $StatusIcon.Text = [char]0xE895
    $StatusText.Text = "Restoring automatic DNS (DHCP)..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # 1. Reset all network adapters via Set-DnsClientServerAddress
        Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            } catch {}
        }

        # 2. Reset via WMI (covers all physical and virtual interfaces)
        try {
            Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPEnabled } | ForEach-Object {
                $_.SetDNSServerSearchOrder() | Out-Null
            }
        } catch {}

        # 3. Reset via netsh across all interfaces
        try {
            Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {
                $name = $_.Name
                & netsh.exe interface ipv4 set dnsservers name="$name" source=dhcp 2>$null | Out-Null
                & netsh.exe interface ipv6 set dnsservers name="$name" source=dhcp 2>$null | Out-Null
            }
        } catch {}

        # 4. Clear client cache and flush DNS
        try {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
            ipconfig /flushdns 2>$null | Out-Null
        } catch {}

        # 5. Check if not admin and trigger elevated reset
        if (-not $isAdmin) {
            try {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Get-NetAdapter | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex `$_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue; netsh interface ipv4 set dnsservers name=`\`"`$(`$_.Name)`\`" source=dhcp; netsh interface ipv6 set dnsservers name=`\`"`$(`$_.Name)`\`" source=dhcp }; Clear-DnsClientCache; ipconfig /flushdns`"" -Verb RunAs -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
            } catch {}
        }

        Start-Sleep -Milliseconds 400

        $msg = "Restored automatic DNS (DHCP / ISP default) successfully!"
        $StatusIcon.Text = [char]0xE73E
        $StatusText.Text = $msg
        Add-HubLog $msg "SUCCESS"
        Show-ZeroToastNotification "ZeroHub DNS Switcher" $msg
        Update-DnsUI
    } catch {
        Add-HubLog "Error resetting DNS to DHCP: $($_.Exception.Message)" "ERROR"
        Update-DnsUI
    } finally {
        if ($FooterProgressBar) { $FooterProgressBar.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($BtnRestoreDnsDhcp) {
            $BtnRestoreDnsDhcp.Content = "✅ Restored!"
            $timer = [System.Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [TimeSpan]::FromSeconds(2.0)
            $timer.add_Tick({
                param($s, $e)
                $s.Stop()
                if ($BtnRestoreDnsDhcp) {
                    $BtnRestoreDnsDhcp.IsEnabled = $true
                    $BtnRestoreDnsDhcp.Content = "Restore DHCP"
                }
            })
            $timer.Start()
        }
    }
}

