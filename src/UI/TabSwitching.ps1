# Tab Selection Changed Handler
$MainTabs.add_SelectionChanged({
    param($s, $e)
    if ($e.Source -is [System.Windows.Controls.TabControl]) {
        Update-SidebarSelection $MainTabs.SelectedItem
        try {
            # Each of these hits a real data source: winget for the catalog, the uninstall registry
            # hives plus a recursive directory walk per app for the uninstaller, and Get-AppxPackage
            # for bloatware. Re-running them on every tab click was most of the perceived lag.
            if ($MainTabs.SelectedItem -eq $Tab_Installer) {
                if ($Script:InstallerCatalogList.Count -eq 0) {
                    Initialize-InstallerCatalogList
                } else {
                    Set-InstallerFilters
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Uninstaller) {
                if ($Script:AllInstalledApps.Count -eq 0) {
                    Update-InstalledAppsList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Bloatware -and -not (Test-DataCacheFresh "bloatware" 300)) {
                Update-BloatwareList
            }
            if ($MainTabs.SelectedItem -eq $Tab_Updates) {
                Update-WinUpdateUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Privacy) {
                Update-PrivacyUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Dns) {
                Update-DnsUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Defender) {
                Update-DefenderUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_DriverUpdater) {
                Update-DriverUpdaterUI
            }
            if ($MainTabs.SelectedItem -eq $Tab_Startup) {
                Update-StartupAppsList
            }
            if ($MainTabs.SelectedItem -eq $Tab_GameHub) {
                if ($Script:AllGames.Count -eq 0) {
                    Update-GameLibraryList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_ProcManager) {
                if ($Script:AllSmartProcesses.Count -eq 0) {
                    Update-SmartProcessList
                }
            }
            if ($MainTabs.SelectedItem -eq $Tab_Guard) {
                Update-ProcessGuardList
            }
        } catch {
            Add-HubLog "Tab switch warning: $($_.Exception.Message)" "WARN"
        }
    }
})


