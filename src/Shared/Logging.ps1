# Colorful Logging Helper Brushes
$Script:LogTimeBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B") # Muted Slate
$Script:LogInitBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8") # Sky Blue
$Script:LogScanBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#C084FC") # Purple / Lavender
$Script:LogInfoBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8") # Slate
$Script:LogActionBrush  = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8") # Cyan
$Script:LogGuardBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24") # Warm Amber
$Script:LogSuccessBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80") # Vibrant Emerald
$Script:LogDoneBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80") # Mint Green
$Script:LogWarnBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FB923C") # Coral / Orange
$Script:LogErrorBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F43F5E") # Bright Rose
$Script:LogDebugBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B") # Dark Slate
$Script:LogRamBrush     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E879F9") # Fuchsia
$Script:LogMsgDefault   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9") # Crisp White

# Logging Helper (Memory-Capped Colored FlowDocument)
function Add-HubLog([string]$message, [string]$level = "INFO") {
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    try {
        $color = switch ($level.ToUpper()) {
            "INIT"    { "Cyan" }
            "SCAN"    { "Magenta" }
            "INFO"    { "Gray" }
            "ACTION"  { "Cyan" }
            "GUARD"   { "Yellow" }
            "SUCCESS" { "Green" }
            "DONE"    { "Green" }
            "WARN"    { "DarkYellow" }
            "ERROR"   { "Red" }
            "RAM"     { "Magenta" }
            "DEBUG"   { "DarkGray" }
            default   { "White" }
        }
        Write-Host "[$timestamp] [$level] $message" -ForegroundColor $color
    } catch {}

    if ($TxtLogConsole) {
        $TxtLogConsole.Dispatcher.Invoke([Action]{
            try {
                $doc = $TxtLogConsole.Document
                if ($doc.Blocks.Count -gt 350) {
                    for ($i = 0; $i -lt 50 -and $doc.Blocks.Count -gt 100; $i++) {
                        [void]$doc.Blocks.Remove($doc.Blocks.FirstBlock)
                    }
                }

                $p = New-Object System.Windows.Documents.Paragraph
                $p.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)

                # Timestamp [18:40:50]
                $rTime = New-Object System.Windows.Documents.Run("[$timestamp] ")
                $rTime.Foreground = $Script:LogTimeBrush
                $p.Inlines.Add($rTime)

                # Level Tag [WARN], [SUCCESS], [SCAN], etc.
                $rLevel = New-Object System.Windows.Documents.Run("[$level] ")
                $rLevel.FontWeight = [System.Windows.FontWeights]::Bold

                $msgBrush = $Script:LogMsgDefault
                switch ($level.ToUpper()) {
                    "INIT"    { $rLevel.Foreground = $Script:LogInitBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E0F2FE") }
                    "SCAN"    { $rLevel.Foreground = $Script:LogScanBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E9D5FF") }
                    "INFO"    { $rLevel.Foreground = $Script:LogInfoBrush; $msgBrush = $Script:LogMsgDefault }
                    "ACTION"  { $rLevel.Foreground = $Script:LogActionBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E0F2FE") }
                    "GUARD"   { $rLevel.Foreground = $Script:LogGuardBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FEF3C7") }
                    "SUCCESS" { $rLevel.Foreground = $Script:LogSuccessBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DCFCE7") }
                    "DONE"    { $rLevel.Foreground = $Script:LogDoneBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D1FAE5") }
                    "WARN"    { $rLevel.Foreground = $Script:LogWarnBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFEDD5") }
                    "ERROR"   { $rLevel.Foreground = $Script:LogErrorBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFE4E6") }
                    "RAM"     { $rLevel.Foreground = $Script:LogRamBrush; $msgBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FAE8FF") }
                    "DEBUG"   { $rLevel.Foreground = $Script:LogDebugBrush; $msgBrush = $Script:LogDebugBrush }
                    default   { $rLevel.Foreground = $Script:LogInfoBrush; $msgBrush = $Script:LogMsgDefault }
                }
                $p.Inlines.Add($rLevel)

                # Message content
                $rMsg = New-Object System.Windows.Documents.Run($message)
                $rMsg.Foreground = $msgBrush
                $p.Inlines.Add($rMsg)

                $doc.Blocks.Add($p)
                $TxtLogConsole.ScrollToEnd()
            } catch {}
        })
    }
}

$Script:ActiveLogProgPara = $null
$Script:ActiveLogProgBarRun = $null
$Script:ActiveLogProgPctRun = $null
$Script:ActiveLogProgMsgRun = $null

function Set-HubLogProgress([string]$title, [int]$percent, [string]$stage) {
    $percent = [Math]::Max(0, [Math]::Min(100, $percent))
    $barLen = 22
    $filled = [Math]::Round(($percent / 100.0) * $barLen)
    $empty = $barLen - $filled
    $barStr = "[" + ("█" * $filled) + ("░" * $empty) + "]"
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    
    $TxtLogConsole.Dispatcher.Invoke([Action]{
        try {
            $doc = $TxtLogConsole.Document
            if (-not $Script:ActiveLogProgPara -or -not $doc.Blocks.Contains($Script:ActiveLogProgPara)) {
                $p = New-Object System.Windows.Documents.Paragraph
                $p.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)

                $rTime = New-Object System.Windows.Documents.Run("[$timestamp] ")
                $rTime.Foreground = $Script:LogTimeBrush
                $p.Inlines.Add($rTime)

                $rTag = New-Object System.Windows.Documents.Run("[PROG] ")
                $rTag.FontWeight = [System.Windows.FontWeights]::Bold
                $rTag.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $p.Inlines.Add($rTag)

                $rBar = New-Object System.Windows.Documents.Run("$barStr ")
                $rBar.FontWeight = [System.Windows.FontWeights]::Bold
                $rBar.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D4D4D8")
                $p.Inlines.Add($rBar)

                $rPct = New-Object System.Windows.Documents.Run("$percent% ")
                $rPct.FontWeight = [System.Windows.FontWeights]::Bold
                $rPct.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FBBF24")
                $p.Inlines.Add($rPct)

                $rMsg = New-Object System.Windows.Documents.Run("$title - $stage")
                $rMsg.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F1F5F9")
                $p.Inlines.Add($rMsg)

                $doc.Blocks.Add($p)
                $Script:ActiveLogProgPara = $p
                $Script:ActiveLogProgBarRun = $rBar
                $Script:ActiveLogProgPctRun = $rPct
                $Script:ActiveLogProgMsgRun = $rMsg
            } else {
                $Script:ActiveLogProgBarRun.Text = "$barStr "
                $Script:ActiveLogProgPctRun.Text = "$percent% "
                $Script:ActiveLogProgMsgRun.Text = "$title - $stage"
                if ($percent -ge 100) {
                    $Script:ActiveLogProgBarRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                    $Script:ActiveLogProgPctRun.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4ADE80")
                }
            }
            $TxtLogConsole.ScrollToEnd()
        } catch {}
    })
}

function Complete-HubLogProgress([string]$title, [string]$finalMsg) {
    Set-HubLogProgress $title 100 $finalMsg
    $Script:ActiveLogProgPara = $null
    $Script:ActiveLogProgBarRun = $null
    $Script:ActiveLogProgPctRun = $null
    $Script:ActiveLogProgMsgRun = $null
}

