function Set-PrivacyHosts([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "HostsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        if (Test-Path $hostsPath) {
            $item = Get-Item -Path $hostsPath -ErrorAction SilentlyContinue
            if ($item -and $item.IsReadOnly) { $item.IsReadOnly = $false }

            $lines = @(Get-Content -Path $hostsPath -ErrorAction SilentlyContinue)
            $cleanLines = @($lines | Where-Object { 
                $_ -notmatch "# ZeroHub Anti-Telemetry Blocklist" -and
                $_ -notmatch "0\.0\.0\.0\s+(v10\.events|v20\.events|telemetry\.microsoft|watson\.telemetry|diagnostics\.support|browser\.pipe\.aria|settings-win\.data)"
            })

            if ($disable) {
                $blockEntries = @(
                    "",
                    "# ZeroHub Anti-Telemetry Blocklist",
                    "0.0.0.0 v10.events.data.microsoft.com",
                    "0.0.0.0 v20.events.data.microsoft.com",
                    "0.0.0.0 telemetry.microsoft.com",
                    "0.0.0.0 watson.telemetry.microsoft.com",
                    "0.0.0.0 diagnostics.support.microsoft.com",
                    "0.0.0.0 browser.pipe.aria.microsoft.com",
                    "0.0.0.0 settings-win.data.microsoft.com"
                )
                $newContent = ($cleanLines + $blockEntries) -join "`r`n"
            } else {
                $newContent = $cleanLines -join "`r`n"
            }
            
            try {
                [System.IO.File]::WriteAllText($hostsPath, $newContent, [System.Text.Encoding]::ASCII)
            } catch {
                Set-Content -Path $hostsPath -Value $newContent -Force -Encoding ASCII -ErrorAction SilentlyContinue
            }
        }

        Add-HubLog "Configured Hosts file telemetry null-routing (Blocked=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting hosts file: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyEdge([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "EdgeBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $pathEdgeLM = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        if (-not (Test-Path $pathEdgeLM)) { New-Item -Path $pathEdgeLM -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $pathEdgeLM -Name "MetricsReportingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "SendDoNotTrack" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "DiagnosticData" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathEdgeLM -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathEdgeLM -Name "MetricsReportingEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "SendDoNotTrack" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "PersonalizationReportingEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "DiagnosticData" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "BackgroundModeEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "StartupBoostEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "ShowRecommendationsEnabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathEdgeLM -Name "EdgeShoppingAssistantEnabled" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Microsoft Edge telemetry & background processes (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting Edge privacy policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyWER([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "WERBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $pathWERLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $pathWERLM)) { New-Item -Path $pathWERLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathWERCU = "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $pathWERCU)) { New-Item -Path $pathWERCU -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $pathWERLM -Name "Disabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERLM -Name "DoNotSendAdditionalData" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERLM -Name "LoggingDisabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERCU -Name "Disabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathWERCU -Name "DontSendAdditionalData" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathWERLM -Name "Disabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERLM -Name "DoNotSendAdditionalData" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERLM -Name "LoggingDisabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERCU -Name "Disabled" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathWERCU -Name "DontSendAdditionalData" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Windows Error Reporting & crash dump privacy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting WER policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyNudges([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "NudgesBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $cdm = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (-not (Test-Path $cdm)) { New-Item -Path $cdm -Force -ErrorAction SilentlyContinue | Out-Null }
        $cloudContent = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $cloudContent)) { New-Item -Path $cloudContent -Force -ErrorAction SilentlyContinue | Out-Null }
        $advExp = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if (-not (Test-Path $advExp)) { New-Item -Path $advExp -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-353694Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-353696Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExp -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cloudContent -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $cdm -Name "SystemPaneSuggestionsEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338388Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $cdm -Name "SubscribedContent-338389Enabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $advExp -Name "ShowSyncProviderNotifications" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $cloudContent -Name "DisableWindowsConsumerFeatures" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Windows nudges & sponsored suggestions policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting nudges policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyWUDO([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "WUDOBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $doLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
        if (-not (Test-Path $doLM)) { New-Item -Path $doLM -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $doLM -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config DoSvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop DoSvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $doLM -Name "DODownloadMode" -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config DoSvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Delivery Optimization (WUDO) P2P bandwidth policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting WUDO policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyClipboard([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "ClipboardBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $clipSys = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $clipSys)) { New-Item -Path $clipSys -Force -ErrorAction SilentlyContinue | Out-Null }
        $clipCU = "HKCU:\SOFTWARE\Microsoft\Clipboard"
        if (-not (Test-Path $clipCU)) { New-Item -Path $clipCU -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $clipSys -Name "AllowCrossDeviceClipboard" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "EnableCloudClipboard" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "CloudClipboardAutomaticUpload" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $clipSys -Name "AllowCrossDeviceClipboard" -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $clipCU -Name "EnableCloudClipboard" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Clipboard cloud synchronization policy (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting clipboard policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacySensors([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "SensorsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $locPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        if (-not (Test-Path $locPol)) { New-Item -Path $locPol -Force -ErrorAction SilentlyContinue | Out-Null }

        if ($disable) {
            Set-ItemProperty -Path $locPol -Name "DisableLocation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $locPol -Name "DisableSensors" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $locPol -Name "DisableLocationScripting" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config lfsvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop lfsvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $locPol -Name "DisableLocation" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $locPol -Name "DisableSensors" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $locPol -Name "DisableLocationScripting" -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config lfsvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Location & Sensor tracking services (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting sensor policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-ClassicContextMenu([bool]$enable, [bool]$skipUI = $false) {
    try {
        $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
        $inprocPath = "$clsidPath\InprocServer32"

        if ($enable) {
            if (-not (Test-Path $clsidPath)) { New-Item -Path $clsidPath -Force -ErrorAction SilentlyContinue | Out-Null }
            if (-not (Test-Path $inprocPath)) { New-Item -Path $inprocPath -Force -ErrorAction SilentlyContinue | Out-Null }
            Set-ItemProperty -Path $inprocPath -Name "(Default)" -Value "" -Force -ErrorAction SilentlyContinue | Out-Null
            Set-Item -Path $inprocPath -Value "" -Force -ErrorAction SilentlyContinue | Out-Null
            $action = "Enabled Classic Windows 10 Context Menu"
        } else {
            if (Test-Path $clsidPath) {
                Remove-Item -Path $clsidPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            $action = "Restored Windows 11 Modern Context Menu"
        }

        # Seamlessly restart explorer.exe
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
            Start-Process explorer.exe
        }

        Add-HubLog "$action (File Explorer restarted)." "TWEAKS"
        if (-not $skipUI) {
            Show-ZeroToastNotification "ZeroHub Shell Tweaks" "$action (File Explorer restarted)."
            Update-PrivacyUI
        }
    } catch {
        Add-HubLog "Error updating Classic Context Menu: $($_.Exception.Message)" "ERROR"
    }
}


