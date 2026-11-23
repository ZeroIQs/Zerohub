# Bilingual Dictionaries
# Interface Language Setup (English)
function Set-HubLanguage([string]$lang = "EN") {
        

    if ($TxtAppSubtitle) { $TxtAppSubtitle.Text = "Tired of Windows? Switch to Linux :D" }
    $TxtDriveLabel.Text        = $t.DriveLabel
    $BtnRelaunchAdmin.Content  = $t.ElevateBtn
    $AdminText.Text            = if ($isAdmin) { $t.Administrator } else { $t.StandardUser }

    if ($NavCat_Clean)         { $NavCat_Clean.Text         = $t.NavCat_Clean }
    if ($NavCat_Tools)         { $NavCat_Tools.Text         = $t.NavCat_Tools }
    if ($TxtNav_Dashboard)     { $TxtNav_Dashboard.Text     = $t.Nav_Dashboard }
    if ($TxtNav_Installer)     { $TxtNav_Installer.Text     = $t.Nav_Installer }
    if ($TxtNav_Uninstaller)   { $TxtNav_Uninstaller.Text   = $t.Nav_Uninstaller }
    if ($TxtNav_Bloatware)     { $TxtNav_Bloatware.Text     = $t.Nav_Bloatware }
    if ($TxtNav_Updates)       { $TxtNav_Updates.Text       = $t.Nav_Updates }
    if ($TxtNav_Privacy)       { $TxtNav_Privacy.Text       = $t.Nav_Privacy }
    if ($TxtNav_Dns)           { $TxtNav_Dns.Text           = $t.Nav_Dns }
    if ($TxtHeaderTabDns)      { $TxtHeaderTabDns.Text      = $t.TabDns }
    if ($TxtDnsHeroTitle)      { $TxtDnsHeroTitle.Text      = $t.DnsHeroTitle }
    if ($TxtDnsHeroSubtitle)   { $TxtDnsHeroSubtitle.Text   = $t.DnsHeroSubtitle }
    if ($BtnRunDnsBenchmark)   { $BtnRunDnsBenchmark.Content = $t.BtnRunDnsBenchmark }
    if ($BtnRestoreDnsDhcp)    { $BtnRestoreDnsDhcp.Content = $t.BtnRestoreDnsDhcp }
    if ($BtnFlushDns)          { $BtnFlushDns.Content       = $t.BtnFlushDns }
    if ($TxtCustomDnsTitle)    { $TxtCustomDnsTitle.Text    = $t.CustomDnsTitle }
    if ($TxtCustomDnsDesc)     { $TxtCustomDnsDesc.Text     = $t.CustomDnsDesc }
    if ($BtnApplyCustomDns)    { $BtnApplyCustomDns.Content = $t.BtnApplyCustomDns }
    if ($TxtNetToolsTitle)     { $TxtNetToolsTitle.Text     = $t.NetToolsTitle }
    if ($TxtNetToolsDesc)      { $TxtNetToolsDesc.Text      = $t.NetToolsDesc }
    if ($BtnToolFlushDns)      { $BtnToolFlushDns.Content   = $t.BtnToolFlushDns }
    if ($BtnToolResetWinsock)  { $BtnToolResetWinsock.Content = $t.BtnToolResetWinsock }
    if ($BtnToolRenewIp)       { $BtnToolRenewIp.Content    = $t.BtnToolRenewIp }
    if ($TxtDnsNoticeTitle)    { $TxtDnsNoticeTitle.Text    = $t.DnsNoticeTitle }
    if ($TxtDnsNoticeDesc)     { $TxtDnsNoticeDesc.Text     = $t.DnsNoticeDesc }
    if ($TxtNav_Startup)       { $TxtNav_Startup.Text       = $t.Nav_Startup }
    if ($TxtNav_GameHub)       { $TxtNav_GameHub.Text       = $t.Nav_GameHub }
    
    if ($TxtNav_Defender)      { $TxtNav_Defender.Text      = $t.Nav_Defender }
    if ($TxtNav_Guard)         { $TxtNav_Guard.Text         = $t.Nav_Guard }
    if ($TxtNav_ProcManager)   { $TxtNav_ProcManager.Text   = "Task Manager" }
    if ($TxtNav_Log)           { $TxtNav_Log.Text           = $t.Nav_Log }
    if ($TxtNav_About)         { $TxtNav_About.Text         = $t.Nav_About }

    $Tab_Dashboard.Header      = $t.TabDashboard
    if ($Tab_Installer)        { $Tab_Installer.Header = "📥 " + $t.TabInstaller }
    $Tab_Uninstaller.Header    = $t.TabUninstaller
    if ($Tab_Startup)          { $Tab_Startup.Header = "🚀 " + $t.TabStartup }
    if ($TxtHeaderTabStartup)  { $TxtHeaderTabStartup.Text = $t.TabStartup }
    if ($Tab_GameHub)          { $Tab_GameHub.Header = "🎮 " + $t.TabGameHub }
    if ($TxtHeaderTabGameHub)  { $TxtHeaderTabGameHub.Text = $t.TabGameHub }
    
    if ($Tab_Defender)         { $Tab_Defender.Header = "🛡️ " + $t.TabDefender }
    if ($Tab_ProcManager)      { $Tab_ProcManager.Header = "⚡ Task Manager" }
    $Tab_Guard.Header          = $t.TabGuard
    $Tab_Log.Header            = $t.TabLog
    $Tab_About.Header          = $t.TabAbout

    $TxtPresetsLabel.Text      = $t.PresetsLabel
    $BtnPresetRecommended.Content = $t.BtnRec
    $BtnPresetAll.Content      = $t.BtnAll
    $BtnPresetBrowsers.Content = $t.BtnBrowsers
    $BtnPresetDev.Content      = $t.BtnDev
    $BtnPresetGaming.Content   = $t.BtnGaming
    $BtnPresetClear.Content    = $t.BtnClear

    $ChkAutoCloseApps.Content  = $t.AutoCloseApps
    $BtnScanAll.Content        = $t.ScanSpace
    $BtnCleanSelected.Content  = $t.CleanSelected

    $TxtTitle_GPU.Text         = $t.Title_GPU
    $TxtSub_GPU.Text           = $t.Sub_GPU
    $TxtTitle_Browser.Text     = $t.Title_Browser
    $TxtSub_Browser.Text       = $t.Sub_Browser
    $TxtTitle_Dev.Text         = $t.Title_Dev
    $TxtSub_Dev.Text           = $t.Sub_Dev
    $TxtTitle_Gaming.Text      = $t.Title_Gaming
    $TxtSub_Gaming.Text        = $t.Sub_Gaming
    $TxtTitle_Social.Text      = $t.Title_Social
    $TxtSub_Social.Text        = $t.Sub_Social
    $TxtTitle_System.Text      = $t.Title_System
    $TxtSub_System.Text        = $t.Sub_System

    $TxtFilterLabel.Text       = $t.FilterLabel
    $BtnTableRefresh.Content   = $t.RescanTable
    $BtnSelectFoundOnly.Content= $t.SelectFound

    $TxtGuardTitle.Text        = $t.GuardTitle
    $BtnRefreshProcesses.Content = $t.CheckProcesses
    $BtnCloseAllGuards.Content = $t.CloseGuards

    $TxtLogTitle.Text          = $t.LogTitle
    $BtnCopyLogs.Content       = $t.CopyLogs
    $BtnClearLogs.Content      = $t.ClearConsole

    $TxtSelectedLabel.Text     = $t.SelectedLabel
    $TxtReclaimableLabel.Text  = $t.ReclaimableLabel

    foreach ($item in $Script:TargetItems) {
        $item.CheckBoxControl.Content = $item.Name
        $item.CheckBoxControl.ToolTip = $item.Description
    }

    Update-ProcessGuardList
    if ($Script:InstallerCatalogList.Count -gt 0) { Initialize-InstallerCatalogList }
    if ($Script:AllInstalledApps.Count -gt 0) { Set-AppFilters; Update-AppSelectionStatus }
    Update-DriveInfo
}


