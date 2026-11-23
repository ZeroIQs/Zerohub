# ==========================================
# DEDICATED BLOATWARE TAB LOGIC & ENGINE
# ==========================================
$Script:AllBloatwareApps = [System.Collections.ObjectModel.ObservableCollection[ZeroHub.InstalledAppItem]]::new()

function Update-BloatSelectionStatus {
    $sel = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($sel.Count -gt 0) {
        $BtnRemoveSelectedBloatware.IsEnabled = $true
        $TxtBloatSelectionStatus.Text = "$($sel.Count) Windows apps selected for complete removal."
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E")
    } else {
        $BtnRemoveSelectedBloatware.IsEnabled = $false
        $TxtBloatSelectionStatus.Text = "Select one or more Windows apps from the table to permanently remove."
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
    }
}

function Update-BloatwareList() {
    Set-DataCacheStamp "bloatware"
    $Script:AllBloatwareApps.Clear()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $knownBloatware = @{
        "Microsoft.MicrosoftEdge"                       = "Microsoft Edge"
        "Microsoft.MicrosoftEdge.Stable"                = "Microsoft Edge Browser"
        "Microsoft.MicrosoftEdgeDevToolsClient"         = "Microsoft Edge DevTools"
        "MicrosoftEdge"                                 = "Microsoft Edge"
        "Microsoft.549981C3F5F10"                      = "Cortana"
        "Microsoft.Copilot"                             = "Microsoft Copilot"
        "Microsoft.BingNews"                            = "Microsoft News (MSN)"
        "Microsoft.BingWeather"                         = "Bing Weather"
        "Microsoft.BingFinance"                         = "Bing Finance / Money"
        "Microsoft.BingSports"                          = "Bing Sports"
        "Microsoft.BingSearch"                          = "Bing Search Experience"
        "Microsoft.MicrosoftSolitaireCollection"        = "Solitaire & Casual Games"
        "Microsoft.ZuneMusic"                           = "Groove Music / Windows Media Player"
        "Microsoft.ZuneVideo"                           = "Movies & TV (Films & TV)"
        "Microsoft.WindowsFeedbackHub"                  = "Feedback Hub"
        "Microsoft.GetHelp"                             = "Get Help"
        "Microsoft.Getstarted"                          = "Tips (Get Started)"
        "Microsoft.YourPhone"                           = "Phone Link (Your Phone)"
        "Microsoft.WindowsMaps"                         = "Windows Maps"
        "Microsoft.WindowsSoundRecorder"                = "Voice Recorder / Sound Recorder"
        "Microsoft.People"                              = "Microsoft People"
        "Microsoft.Microsoft3DViewer"                   = "3D Viewer"
        "Microsoft.3DBuilder"                           = "3D Builder"
        "Microsoft.Paint3D"                             = "Paint 3D"
        "Microsoft.MixedReality.Portal"                 = "Mixed Reality Portal"
        "Microsoft.WindowsAlarms"                       = "Clock & Alarms"
        "Clipchamp"                                     = "Clipchamp Video Editor"
        "Microsoft.Clipchamp.Clipchamp"                 = "Clipchamp Video Editor"
        "Microsoft.WindowsCommunicationsApps"           = "Mail & Calendar"
        "Microsoft.Todos"                               = "Microsoft To Do"
        "Microsoft.PowerAutomateDesktop"                = "Power Automate"
        "Microsoft.GamingApp"                           = "Xbox App"
        "Microsoft.XboxGamingOverlay"                   = "Xbox Game Bar"
        "Microsoft.XboxIdentityProvider"                = "Xbox Identity Provider"
        "Microsoft.XboxSpeechToTextOverlay"             = "Xbox Speech Overlay"
        "Microsoft.Xbox.TCUI"                           = "Xbox TCUI"
        "Microsoft.MicrosoftOfficeHub"                  = "Microsoft 365 / Office Hub"
        "Microsoft.OutlookForWindows"                   = "New Outlook for Windows"
        "Microsoft.SkypeApp"                            = "Skype"
        "MicrosoftTeams"                                = "Microsoft Teams (Chat)"
        "Microsoft.Teams"                               = "Microsoft Teams (Chat)"
        "Microsoft.Wallet"                              = "Microsoft Pay / Wallet"
        "Microsoft.WindowsReadingList"                  = "Reading List"
        "Microsoft.OneConnect"                          = "Mobile Plans"
        "Microsoft.QuickAssist"                         = "Quick Assist"
        "Microsoft.Family"                              = "Microsoft Family Safety"
        "Microsoft.Windows.DevHome"                     = "Windows Dev Home"
        "Microsoft.GamingServices"                      = "Gaming Services (Xbox Background)"
        "SpotifyAB.SpotifyMusic"                        = "Spotify (UWP)"
        "Disney"                                        = "Disney+"
        "Disney.37853FC22B2CE"                          = "Disney+"
        "ByteDancePte.Ltd.TikTok"                       = "TikTok"
        "TikTok"                                        = "TikTok"
        "Amazon.AmazonPrimeVideo"                       = "Amazon Prime Video"
        "Amazon"                                        = "Amazon Prime Video"
        "Facebook.Facebook"                             = "Facebook"
        "Facebook.Instagram"                            = "Instagram"
        "Netflix"                                       = "Netflix"
        "King.com.CandyCrushSaga"                       = "Candy Crush Saga"
        "King.com.CandyCrushSodaSaga"                   = "Candy Crush Soda Saga"
        "King.com.BubbleWitch3Saga"                     = "Bubble Witch 3 Saga"
        "AdobeSystemsIncorporated.AdobePhotoshopExpress"  = "Photoshop Express"
        "Duolingo-LearnLanguagesforFree"                = "Duolingo"
        "Fitbit.FitbitCoach"                            = "Fitbit Coach"
        "McAfee"                                        = "McAfee Security (UWP)"
    }

    try {
        $packages = Get-AppxPackage -ErrorAction SilentlyContinue
        $idx = 1
        foreach ($p in $packages) {
            if ($p.IsFramework -or $p.NonRemovable -or $p.Name -like "*SecHealthUI*" -or $p.Name -like "*Windows.UI.*" -or $p.Name -like "*LanguageExperiencePack*" -or $p.Name -like "*DesktopAppInstaller*" -or $p.Name -like "*StorePurchaseApp*" -or $p.Name -like "*WindowsStore*") {
                continue
            }

            $friendlyName = $null
            foreach ($k in $knownBloatware.Keys) {
                if ($p.Name -like "*$k*") {
                    $friendlyName = $knownBloatware[$k]
                    break
                }
            }

            if (-not $friendlyName) { continue }

            # NOTE for the maintainer. Wording deliberately left exactly as you wrote it.
            # SafetyStatus below is the same constant on every row, so it reads as an assessment but
            # can never come out negative. A handful of entries in $knownBloatware do have known
            # consequences and may deserve a different label:
            #   Gaming Services         Game Pass and Store game installs stop working, and this
            #                           package is notoriously awkward to reinstall.
            #   Xbox Identity Provider  Xbox sign-in breaks in PC titles such as Minecraft.
            #   Xbox App                Game Pass library and game installs stop working.
            #   Quick Assist            Removes the built-in remote support tool.
            #   Mail & Calendar         Removes the mail client along with its stored accounts.
            #   Phone Link              Breaks phone pairing and SMS mirroring.
            #   Teams, New Outlook      Removes the client and any accounts configured in it.
            #   Microsoft Edge          Windows features and WebView2-hosted apps expect it present.
            # Suggestion only, not applied because it changes user-facing wording: keep the green
            # label for everything else and give these a caution label naming the consequence.

            if (-not $seen.Contains($friendlyName)) {
                $seen.Add($friendlyName) | Out-Null
                $item = [ZeroHub.InstalledAppItem]::new()
                $item.Index = $idx++
                $item.DisplayName = $friendlyName
                $item.PackageName = $p.Name
                $item.PackageFullName = $p.PackageFullName
                $item.Publisher = if ($p.PublisherId) { "Microsoft / Store" } else { "Microsoft Corporation" }
                $item.SafetyStatus = "● 100% Safe to Remove"
                $item.IsAppx = $true
                $item.IsBloatware = $true
                $item.IsSelected = $false
                $Script:AllBloatwareApps.Add($item)
            }
        }

        # Check Win32 Edge if installed
        $edgePaths = @(
            "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
            "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
        )
        $hasEdge = $false
        $edgeExe = $null
        foreach ($ep in $edgePaths) {
            if (Test-Path $ep) {
                $hasEdge = $true
                $edgeExe = $ep
                break
            }
        }
        if ($hasEdge -and -not $seen.Contains("Microsoft Edge Browser") -and -not $seen.Contains("Microsoft Edge")) {
            $seen.Add("Microsoft Edge Browser") | Out-Null
            $item = [ZeroHub.InstalledAppItem]::new()
            $item.Index = $idx++
            $item.DisplayName = "Microsoft Edge Browser"
            $item.PackageName = "Microsoft.Edge (Win32 / System)"
            $item.PackageFullName = "Microsoft.Edge.System"
            $item.Publisher = "Microsoft Corporation"
            # Same note as above. Edge removal is unsupported by Microsoft, Windows Update can
            # reinstall it, and some Windows features expect it present. Wording left as written.
            $item.SafetyStatus = "● 100% Safe to Remove"
            $item.IsAppx = $false
            $item.IsBloatware = $true
            $item.IsSelected = $false
            $item.InstallLocation = [System.IO.Path]::GetDirectoryName($edgeExe)
            $Script:AllBloatwareApps.Add($item)
        }
    } catch {}

    $BloatwareGrid.ItemsSource = $Script:AllBloatwareApps
    if ($Script:AllBloatwareApps.Count -gt 0) {
        $countText = "$($Script:AllBloatwareApps.Count) Apps Found"
        $TxtBloatwareCount.Text = $countText
        Update-BloatSelectionStatus
    } else {
        $TxtBloatwareCount.Text = "Clean Windows (0)"
        $TxtBloatSelectionStatus.Text = "🎉 Great news! Your Windows installation is already debloated — 0 unwanted apps found on this PC."
        $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    }
}

$BtnSelectAllBloat.add_Click({
    foreach ($app in $Script:AllBloatwareApps) {
        $app.IsSelected = $true
    }
    $BloatwareGrid.Items.Refresh()
    Update-BloatSelectionStatus
})

$BtnDeselectAllBloat.add_Click({
    foreach ($app in $Script:AllBloatwareApps) {
        $app.IsSelected = $false
    }
    $BloatwareGrid.Items.Refresh()
    Update-BloatSelectionStatus
})

$BtnRefreshBloat.add_Click({
    Update-BloatwareList
})

$BloatwareGrid.add_SelectionChanged({ Update-BloatSelectionStatus })

$Script:BloatClickHandler = [System.Windows.RoutedEventHandler]{
    param($s, $e)
    if ($e.OriginalSource -is [System.Windows.Controls.CheckBox]) {
        $BloatwareGrid.Dispatcher.BeginInvoke([System.Action]{
            Update-BloatSelectionStatus
        })
    }
}
$BloatwareGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $Script:BloatClickHandler)

$BtnRemoveSelectedBloatware.add_Click({
    $targetList = @($Script:AllBloatwareApps | Where-Object { $_.IsSelected })
    if ($targetList.Count -eq 0) { return }

    $confirmMsg = if ($targetList.Count -eq 1) {
        "Are you sure you want to remove Windows app '$($targetList[0].DisplayName)'?"
    } else {
        "Are you sure you want to permanently remove ($($targetList.Count)) selected Windows apps?"
    }

    $confirmTitle = "ZeroHub - Remove Windows Bloatware"
    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, $confirmTitle, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $BtnRemoveSelectedBloatware.IsEnabled = $false
    $currentIdx = 0
    $successCount = 0

    foreach ($app in $targetList) {
        $currentIdx++
        $TxtBloatSelectionStatus.Text = "[$currentIdx / $($targetList.Count)] Removing: $($app.DisplayName)..."
        [System.Windows.Forms.Application]::DoEvents()

        try {
            if ($app.PackageName -like "*Microsoft.Edge*") {
                # Terminate running edge processes
                # msedgewebview2 is deliberately NOT killed. WebView2 is a shared runtime that Teams,
                # Outlook, Office panes and a pile of third-party apps render inside, so killing it
                # takes down unrelated software that the user never asked to touch.
                Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
                
                # Check for Edge setup.exe
                $setups = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue
                if ($setups -and $setups.Count -gt 0) {
                    $setupExe = $setups[0].FullName
                    Start-Process -FilePath $setupExe -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                
                # Also try winget
                Start-Process -FilePath "winget" -ArgumentList "uninstall --id Microsoft.Edge --silent --force --accept-source-agreements" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                
                # Remove AppX Edge packages
                # Was: Get-AppxPackage *Edge* | Remove-AppxPackage. That wildcard matches anything
                # with "Edge" in the name, including Microsoft.EdgeDevToolsClient and the WebView2
                # runtime package, so "remove Edge" quietly broke every WebView2-hosted app on the
                # box. Match the browser package names exactly instead.
                $edgePackageNames = @("Microsoft.MicrosoftEdge", "Microsoft.MicrosoftEdge.Stable")
                Get-AppxPackage -ErrorAction SilentlyContinue |
                    Where-Object { $edgePackageNames -contains $_.Name } |
                    Remove-AppxPackage -ErrorAction SilentlyContinue
            } else {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                if ($isAdmin) {
                    Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {
                        $_.DisplayName -like "*$($app.DisplayName)*" -or $_.PackageName -eq $app.PackageFullName
                    } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                }
            }
            Add-HubLog "Removed Windows Bloatware: $($app.DisplayName) ($($app.PackageName))" "SUCCESS"
            $successCount++
        } catch {
            Add-HubLog "Error removing $($app.DisplayName): $($_.Exception.Message)" "ERROR"
        }
    }

    $summary = "Successfully removed $successCount Windows apps!"
    $TxtBloatSelectionStatus.Text = $summary
    $TxtBloatSelectionStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
    Show-ZeroToastNotification "ZeroHub - Bloatware Remover" $summary
    Update-BloatwareList
    Initialize-InstallerCatalogList
})

