# Window Controls & Custom Titlebar Handlers
if ($BtnWindowMinimize) {
    $BtnWindowMinimize.add_Click({
        $Window.WindowState = [System.Windows.WindowState]::Minimized
    })
}
if ($BtnWindowMaximize) {
    $BtnWindowMaximize.add_Click({
        if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
            $Window.WindowState = [System.Windows.WindowState]::Normal
        } else {
            $Window.WindowState = [System.Windows.WindowState]::Maximized
        }
    })
}
if ($BtnWindowClose) {
    $BtnWindowClose.add_Click({
        $Window.Close()
    })
}

$Window.add_StateChanged({
    if ($Window.WindowState -eq [System.Windows.WindowState]::Maximized) {
        if ($TxtWindowMaximizeIcon) { $TxtWindowMaximizeIcon.Text = "❐" }
    } else {
        if ($TxtWindowMaximizeIcon) { $TxtWindowMaximizeIcon.Text = "🗖" }
    }
})

# Window Initialized Event
$Window.add_Loaded({
    try {
        $helper = [System.Windows.Interop.WindowInteropHelper]::new($Window)
        [ZeroHub.NativeMethods]::EnableDarkTitleBar($helper.Handle)
        # Note: Console window kept visible for developer real-time logs
        if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
            $icoBig = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
            $icoSmall = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
            [ZeroHub.NativeMethods]::SetWindowIconFull($helper.Handle, $icoBig.Handle, $icoSmall.Handle)
        }

        # Hook Windows TaskbarCreated message: when Explorer crashes/restarts, auto-reapply ZeroHub icon
        try {
            $source = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
            if ($source) {
                $source.AddHook([System.Windows.Interop.HwndSourceHook]{
                    param($hwnd, $msg, $wParam, $lParam, [ref]$handled)
                    if ($msg -eq [ZeroHub.NativeMethods]::WM_TASKBARCREATED) {
                        try {
                            [ZeroHub.NativeMethods]::SetAppId("ZeroIQ.ZeroHub.App.1")
                            if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
                                $icoB = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
                                $icoS = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
                                [ZeroHub.NativeMethods]::SetWindowIconFull($hwnd, $icoB.Handle, $icoS.Handle)
                            }
                        } catch {}
                    }
                    return [IntPtr]::Zero
                })
            }
        } catch {}
    } catch {}

    Update-SidebarSelection $Tab_Dashboard
    Load-ZeroHubSettings
    Update-DriveInfo
    Update-LiveMemoryStats
    Update-WinUpdateUI
    Update-PrivacyUI
    Update-DnsUI
    Update-DefenderUI
    Update-DriverUpdaterUI
    Initialize-InstallerCatalogList
    Update-InstalledAppsList
    Update-StartupAppsList
    Update-GameLibraryList
    Update-SmartProcessList
    Check-GitHubAppUpdateAsync $false
    Set-AllSelections $false
    $modeStr = if ($isAdmin) { "Administrator" } else { "Standard User" }
    Add-HubLog "ZeroHub v1.3.6 initialized. User Mode: $modeStr" "INIT"
    Invoke-ScanSpace $false
    Get-WingetUpgradesAsync

    # Start Real-Time Live Metrics Timer (Every 1 second)
    $Script:MetricsTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $Script:MetricsTimer.Interval = [TimeSpan]::FromSeconds(1)
    $Script:MetricsTimer.Add_Tick({
        Update-DriveInfo
        Update-LiveMemoryStats
    })
    $Script:MetricsTimer.Start()
})

$Window.add_Closed({
    [System.Environment]::Exit(0)
})

# Show WPF Window
[void]$Window.ShowDialog()
[System.Environment]::Exit(0)
