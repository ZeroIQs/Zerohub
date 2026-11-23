# Update Active Sidebar Highlight
function Update-SidebarSelection {
    param($selectedTab)
    if (-not $selectedTab -and $MainTabs) {
        $selectedTab = $MainTabs.SelectedItem
    }
    if (-not $selectedTab) { return }

    $activeBg       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#23232A")
    $activeBorder   = [System.Windows.Media.Brushes]::Transparent
    $activeFg       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FDFBF7")
    $inactiveBg     = [System.Windows.Media.Brushes]::Transparent
    $inactiveBorder = [System.Windows.Media.Brushes]::Transparent
    $inactiveFg     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")

    $list = @(
        @{ Tab = $Tab_Dashboard;   Border = $Border_Nav_Dashboard;   Text = $TxtNav_Dashboard;   Icon = $Icon_Nav_Dashboard },
        @{ Tab = $Tab_Installer;   Border = $Border_Nav_Installer;   Text = $TxtNav_Installer;   Icon = $Icon_Nav_Installer },
        @{ Tab = $Tab_Uninstaller; Border = $Border_Nav_Uninstaller; Text = $TxtNav_Uninstaller; Icon = $Icon_Nav_Uninstaller },
        @{ Tab = $Tab_Bloatware;   Border = $Border_Nav_Bloatware;   Text = $TxtNav_Bloatware;   Icon = $Icon_Nav_Bloatware },
        @{ Tab = $Tab_Updates;     Border = $Border_Nav_Updates;     Text = $TxtNav_Updates;     Icon = $Icon_Nav_Updates },
        @{ Tab = $Tab_Privacy;     Border = $Border_Nav_Privacy;     Text = $TxtNav_Privacy;     Icon = $Icon_Nav_Privacy },
        @{ Tab = $Tab_Dns;         Border = $Border_Nav_Dns;         Text = $TxtNav_Dns;         Icon = $Icon_Nav_Dns },
        @{ Tab = $Tab_Startup;     Border = $Border_Nav_Startup;     Text = $TxtNav_Startup;     Icon = $Icon_Nav_Startup },
        @{ Tab = $Tab_GameHub;     Border = $Border_Nav_GameHub;     Text = $TxtNav_GameHub;     Icon = $Icon_Nav_GameHub },
        
        @{ Tab = $Tab_Defender;      Border = $Border_Nav_Defender;      Text = $TxtNav_Defender;      Icon = $Icon_Nav_Defender },
        @{ Tab = $Tab_DriverUpdater; Border = $Border_Nav_DriverUpdater; Text = $TxtNav_DriverUpdater; Icon = $Icon_Nav_DriverUpdater },
        @{ Tab = $Tab_TextFinder;    Border = $Border_Nav_TextFinder;    Text = $TxtNav_TextFinder;    Icon = $Icon_Nav_TextFinder },
        @{ Tab = $Tab_ProcManager; Border = $Border_Nav_ProcManager; Text = $TxtNav_ProcManager; Icon = $Icon_Nav_ProcManager },
        @{ Tab = $Tab_Guard;       Border = $Border_Nav_Guard;       Text = $TxtNav_Guard;       Icon = $Icon_Nav_Guard },
        @{ Tab = $Tab_Log;         Border = $Border_Nav_Log;         Text = $TxtNav_Log;         Icon = $Icon_Nav_Log },
        @{ Tab = $Tab_AppUpdate;   Border = $Border_Nav_AppUpdate;   Text = $TxtNav_AppUpdate;   Icon = $Icon_Nav_AppUpdate },
        @{ Tab = $Tab_About;       Border = $Border_Nav_About;       Text = $TxtNav_About;       Icon = $Icon_Nav_About }
    )

    foreach ($entry in $list) {
        if ($entry.Border -and $entry.Text) {
            if ($entry.Tab -eq $selectedTab) {
                $entry.Border.Background = $activeBg
                $entry.Border.BorderBrush = $activeBorder
                $entry.Border.BorderThickness = [System.Windows.Thickness]::new(0)
                $entry.Text.Foreground = $activeFg
                $entry.Text.FontWeight = [System.Windows.FontWeights]::SemiBold
                if ($entry.Icon) { $entry.Icon.Foreground = $activeFg }
            } else {
                $entry.Border.Background = $inactiveBg
                $entry.Border.BorderBrush = $inactiveBorder
                $entry.Border.BorderThickness = [System.Windows.Thickness]::new(0)
                $entry.Text.Foreground = $inactiveFg
                $entry.Text.FontWeight = [System.Windows.FontWeights]::SemiBold
                if ($entry.Icon) { $entry.Icon.Foreground = $inactiveFg }
            }
        }
    }

    if ($PanelCleanerFooterMetrics) {
        if ($selectedTab -eq $Tab_Dashboard) {
            $PanelCleanerFooterMetrics.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $PanelCleanerFooterMetrics.Visibility = [System.Windows.Visibility]::Collapsed
        }
    }
}

# Wire Sidebar Navigation Buttons
if ($Nav_Dashboard)   { $Nav_Dashboard.add_Click({   $MainTabs.SelectedItem = $Tab_Dashboard }) }
if ($Nav_Installer)   { $Nav_Installer.add_Click({   $MainTabs.SelectedItem = $Tab_Installer }) }
if ($Nav_Uninstaller) { $Nav_Uninstaller.add_Click({ $MainTabs.SelectedItem = $Tab_Uninstaller }) }
if ($Nav_Bloatware)   { $Nav_Bloatware.add_Click({   $MainTabs.SelectedItem = $Tab_Bloatware }) }
if ($Nav_Updates)     { $Nav_Updates.add_Click({     $MainTabs.SelectedItem = $Tab_Updates }) }
if ($Nav_Privacy)     { $Nav_Privacy.add_Click({     $MainTabs.SelectedItem = $Tab_Privacy }) }
if ($Nav_Dns)         { $Nav_Dns.add_Click({         $MainTabs.SelectedItem = $Tab_Dns }) }
if ($Nav_Startup)     { $Nav_Startup.add_Click({     $MainTabs.SelectedItem = $Tab_Startup }) }
if ($Nav_GameHub)     { $Nav_GameHub.add_Click({     $MainTabs.SelectedItem = $Tab_GameHub }) }

if ($Nav_Defender)      { $Nav_Defender.add_Click({      $MainTabs.SelectedItem = $Tab_Defender }) }
if ($Nav_DriverUpdater) { $Nav_DriverUpdater.add_Click({ $MainTabs.SelectedItem = $Tab_DriverUpdater }) }
if ($Nav_TextFinder)    { $Nav_TextFinder.add_Click({    $MainTabs.SelectedItem = $Tab_TextFinder }) }
if ($Nav_ProcManager) { $Nav_ProcManager.add_Click({  $MainTabs.SelectedItem = $Tab_ProcManager }) }
if ($Nav_Guard)       { $Nav_Guard.add_Click({       $MainTabs.SelectedItem = $Tab_Guard }) }
if ($Nav_Log)         { $Nav_Log.add_Click({         $MainTabs.SelectedItem = $Tab_Log }) }
if ($Nav_AppUpdate)   { $Nav_AppUpdate.add_Click({   $MainTabs.SelectedItem = $Tab_AppUpdate }) }
if ($Nav_About)       { $Nav_About.add_Click({       $MainTabs.SelectedItem = $Tab_About }) }

# Load Application Logo (Header & About Page)
$Script:LogoImageSource = $null
$localLogoPath = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.png"))) {
    $localLogoPath = Join-Path $PSScriptRoot "assets\logo.png"
}
if ($localLogoPath) {
    try {
        $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bi.BeginInit()
        $bi.UriSource = [Uri]::new($localLogoPath, [UriKind]::Absolute)
        $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bi.EndInit()
        $bi.Freeze()
        $Script:LogoImageSource = $bi
    } catch {}
}
if (-not $Script:LogoImageSource) {
    try {
        $bi = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bi.BeginInit()
        $bi.UriSource = [Uri]::new("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.png", [UriKind]::Absolute)
        $bi.EndInit()
        $Script:LogoImageSource = $bi
    } catch {}
}
if ($Script:LogoImageSource) {
    if ($ImgHeaderLogo) { $ImgHeaderLogo.Source = $Script:LogoImageSource }
    if ($ImgAboutLogo)  { $ImgAboutLogo.Source = $Script:LogoImageSource }
    if (-not $Window.Icon) { try { $Window.Icon = $Script:LogoImageSource } catch {} }
}

