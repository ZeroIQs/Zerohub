function Set-PrivacyDiagnostics([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "DiagBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        if ($disable) {
            Start-Process -FilePath "sc.exe" -ArgumentList "config DiagTrack start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop DiagTrack" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config diagsvc start= disabled" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "stop diagsvc" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Add-HubLog "Stopped and disabled DiagTrack & diagsvc telemetry services." "PRIVACY"
        } else {
            Start-Process -FilePath "sc.exe" -ArgumentList "config DiagTrack start= auto" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "start DiagTrack" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Start-Process -FilePath "sc.exe" -ArgumentList "config diagsvc start= demand" -NoNewWindow -WindowStyle Hidden -ErrorAction SilentlyContinue
            Add-HubLog "Restored DiagTrack & diagsvc services to Windows defaults." "PRIVACY"
        }

        # Registry DataCollection
        $pathDC = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $pathDC)) { New-Item -Path $pathDC -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathDC -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathDC -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathDC -Name "MaxTelemetryAllowed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathDC -Name "AllowTelemetry" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathDC -Name "DoNotShowFeedbackNotifications" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathDC -Name "MaxTelemetryAllowed" -Force -ErrorAction SilentlyContinue
        }

        # Handwriting error sharing
        $pathHW = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports"
        if (-not (Test-Path $pathHW)) { New-Item -Path $pathHW -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathHW -Name "PreventHandwritingDataSharing" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathHW -Name "PreventHandwritingDataSharing" -Force -ErrorAction SilentlyContinue
        }

        # Tailored experiences
        $pathPriv = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
        if (-not (Test-Path $pathPriv)) { New-Item -Path $pathPriv -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathPriv -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathPriv -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting diagnostics telemetry: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyAdsAndActivity([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "AdsBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Advertising Info
        $pathAdCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $pathAdCU)) { New-Item -Path $pathAdCU -Force | Out-Null }
        $adVal = if ($disable) { 0 } else { 1 }
        Set-ItemProperty -Path $pathAdCU -Name "Enabled" -Value $adVal -Type DWord -Force -ErrorAction SilentlyContinue

        $pathAdLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
        if (-not (Test-Path $pathAdLM)) { New-Item -Path $pathAdLM -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathAdLM -Name "DisabledByGroupPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathAdLM -Name "DisabledByGroupPolicy" -Force -ErrorAction SilentlyContinue
        }

        # Activity Feed / Timeline Cloud Upload
        $pathSys = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $pathSys)) { New-Item -Path $pathSys -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSys -Name "EnableActivityFeed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSys -Name "PublishUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSys -Name "UploadUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathSys -Name "EnableActivityFeed" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSys -Name "PublishUserActivities" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSys -Name "UploadUserActivities" -Force -ErrorAction SilentlyContinue
        }

        # Content Delivery Manager (Promoted Apps & Suggestions)
        $pathCDM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        if (Test-Path $pathCDM) {
            $val = if ($disable) { 0 } else { 1 }
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-338388Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-338389Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SubscribedContent-353696Enabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SystemPaneSuggestionsEnabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCDM -Name "SilentInstalledAppsEnabled" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Advertising ID and Activity Timeline policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting ad tracking policies: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyTypingAndSearch([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "SearchBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Search & Bing in Start Menu
        $pathSearchCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        if (-not (Test-Path $pathSearchCU)) { New-Item -Path $pathSearchCU -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSearchCU -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchCU -Name "CortanaConsent" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathSearchCU -Name "BingSearchEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchCU -Name "CortanaConsent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        $pathSearchLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $pathSearchLM)) { New-Item -Path $pathSearchLM -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathSearchLM -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "DisableWebSearch" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathSearchLM -Name "AllowSearchToUseLocation" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathSearchLM -Name "AllowCortana" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "DisableWebSearch" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "ConnectedSearchUseWeb" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathSearchLM -Name "AllowSearchToUseLocation" -Force -ErrorAction SilentlyContinue
        }

        # Input Personalization & Inking Keystroke Collection
        $pathInput = "HKCU:\SOFTWARE\Microsoft\InputPersonalization"
        if (-not (Test-Path $pathInput)) { New-Item -Path $pathInput -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitInkCollection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathInput -Name "RestrictImplicitTextCollection" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }

        $pathTrained = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
        if (-not (Test-Path $pathTrained)) { New-Item -Path $pathTrained -Force | Out-Null }
        $hcVal = if ($disable) { 0 } else { 1 }
        Set-ItemProperty -Path $pathTrained -Name "HarvestContacts" -Value $hcVal -Type DWord -Force -ErrorAction SilentlyContinue

        # Location Sensor Policy
        $pathLoc = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
        if (-not (Test-Path $pathLoc)) { New-Item -Path $pathLoc -Force | Out-Null }
        if ($disable) {
            Set-ItemProperty -Path $pathLoc -Name "DisableLocation" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathLoc -Name "DisableLocationScripting" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $pathLoc -Name "DisableLocation" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathLoc -Name "DisableLocationScripting" -Force -ErrorAction SilentlyContinue
        }

        Add-HubLog "Configured Typing, Inking, Location & Web Search policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting search and inking privacy: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyTasks([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "TasksBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        $tasks = @(
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator" },
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip" },
            @{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "KernelCeipTask" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater" },
            @{ Path = "\Microsoft\Windows\Application Experience\"; Name = "StartupAppTask" },
            @{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy" },
            @{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector" }
        )

        foreach ($t in $tasks) {
            try {
                if ($disable) {
                    Disable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                } else {
                    Enable-ScheduledTask -TaskPath $t.Path -TaskName $t.Name -ErrorAction SilentlyContinue | Out-Null
                }
            } catch {}
        }

        Add-HubLog "Configured Customer Experience and telemetry background tasks (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting privacy tasks: $($_.Exception.Message)" "ERROR"
    }
}

function Set-PrivacyAI([bool]$disable, [bool]$skipUI = $false) {
    try {
        $zhPath = "HKCU:\SOFTWARE\ZeroHub\Privacy"
        if (-not (Test-Path $zhPath)) { New-Item -Path $zhPath -Force -ErrorAction SilentlyContinue | Out-Null }
        $flag = if ($disable) { 1 } else { 0 }
        Set-ItemProperty -Path $zhPath -Name "AIBlocked" -Value $flag -Type DWord -Force -ErrorAction SilentlyContinue

        # Windows Copilot Policy
        $pathCopilotLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $pathCopilotLM)) { New-Item -Path $pathCopilotLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathCopilotCU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $pathCopilotCU)) { New-Item -Path $pathCopilotCU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Windows Recall Policy
        $pathRecallLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Recall"
        if (-not (Test-Path $pathRecallLM)) { New-Item -Path $pathRecallLM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathRecallCU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Recall"
        if (-not (Test-Path $pathRecallCU)) { New-Item -Path $pathRecallCU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Windows AI Data Analysis Policy
        $pathAILM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if (-not (Test-Path $pathAILM)) { New-Item -Path $pathAILM -Force -ErrorAction SilentlyContinue | Out-Null }
        $pathAICU = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
        if (-not (Test-Path $pathAICU)) { New-Item -Path $pathAICU -Force -ErrorAction SilentlyContinue | Out-Null }

        # Explorer Copilot Taskbar Icon
        $pathExp = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

        if ($disable) {
            Set-ItemProperty -Path $pathCopilotLM -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathCopilotCU -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathRecallLM -Name "DisableRecall" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathRecallCU -Name "DisableRecall" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathAILM -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $pathAICU -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            if (Test-Path $pathExp) { Set-ItemProperty -Path $pathExp -Name "ShowCopilotButton" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue }
        } else {
            Remove-ItemProperty -Path $pathCopilotLM -Name "TurnOffWindowsCopilot" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathCopilotCU -Name "TurnOffWindowsCopilot" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathRecallLM -Name "DisableRecall" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathRecallCU -Name "DisableRecall" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathAILM -Name "DisableAIDataAnalysis" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $pathAICU -Name "DisableAIDataAnalysis" -Force -ErrorAction SilentlyContinue
            if (Test-Path $pathExp) { Set-ItemProperty -Path $pathExp -Name "ShowCopilotButton" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }
        }

        Add-HubLog "Configured AI, Copilot and Windows Recall policies (Disabled=$disable)." "PRIVACY"
        if (-not $skipUI) { Update-PrivacyUI }
    } catch {
        Add-HubLog "Error adjusting AI & Recall policies: $($_.Exception.Message)" "ERROR"
    }
}

