# ==========================================
# APPLICATION SETTINGS & NOTIFICATION PREFERENCES
# ==========================================
$Script:ZeroHubSettingsPath = Join-Path $env:LOCALAPPDATA "ZeroHub\settings.json"
$Script:AppNotificationsEnabled = $true

function Load-ZeroHubSettings {
    try {
        if (Test-Path $Script:ZeroHubSettingsPath) {
            $json = Get-Content -Path $Script:ZeroHubSettingsPath -Raw | ConvertFrom-Json
            if ($null -ne $json.AppNotificationsEnabled) {
                $Script:AppNotificationsEnabled = [bool]$json.AppNotificationsEnabled
            }
        }
    } catch {}
    Update-NotificationToggleUI
}

function Save-ZeroHubSettings {
    try {
        $settingsDir = Split-Path -Path $Script:ZeroHubSettingsPath -Parent
        if (-not (Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
        $data = @{
            AppNotificationsEnabled = $Script:AppNotificationsEnabled
        }
        $data | ConvertTo-Json | Set-Content -Path $Script:ZeroHubSettingsPath -Force
    } catch {}
}

function Update-NotificationToggleUI {
    if (-not $TxtToggleNotifications -or -not $IconToggleNotifications) { return }
    $brushConv = [System.Windows.Media.BrushConverter]::new()
    if ($Script:AppNotificationsEnabled) {
        $TxtToggleNotifications.Text = "Notifications: ON"
        $TxtToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        $IconToggleNotifications.Text = [char]0xE7E7 # Bell icon
        $IconToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        if ($BtnToggleNotifications) {
            $BtnToggleNotifications.Background = $brushConv.ConvertFromString("#1A2E1F") # Green
            $BtnToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
            $BtnToggleNotifications.ToolTip = "Windows notifications for ZeroHub are ON. Click to Turn OFF."
        }
    } else {
        $TxtToggleNotifications.Text = "Notifications: OFF"
        $TxtToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        $IconToggleNotifications.Text = [char]0xE7E7 # Bell icon
        $IconToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
        if ($BtnToggleNotifications) {
            $BtnToggleNotifications.Background = $brushConv.ConvertFromString("#c15f3c") # Signature Red
            $BtnToggleNotifications.Foreground = [System.Windows.Media.Brushes]::White
            $BtnToggleNotifications.ToolTip = "Windows notifications for ZeroHub are OFF (Muted). Click to Turn ON."
        }
    }
}

# Native Windows 10/11 Toast Notification with Sound
function Show-ZeroToastNotification([string]$title, [string]$message) {
    if (-not $Script:AppNotificationsEnabled) {
        return
    }
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

        $escapedTitle = [System.Security.SecurityElement]::Escape($title)
        $escapedMessage = [System.Security.SecurityElement]::Escape($message)

        $template = @"
<toast duration="short">
    <visual>
        <binding template="ToastGeneric">
            <text>$escapedTitle</text>
            <text>$escapedMessage</text>
        </binding>
    </visual>
    <audio src="ms-winsoundevent:Notification.Default" />
</toast>
"@
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($template)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)

        $appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
        try {
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
        } catch {
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("ZeroHub").Show($toast)
        }
    } catch {
        try { [System.Media.SystemSounds]::Asterisk.Play() } catch {}
    }
}

