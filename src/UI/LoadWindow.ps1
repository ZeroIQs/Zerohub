# Build XAML UI definition with high-contrast crisp white typography, Segoe MDL2 Assets, and Iraqi Flag Language Switcher
[xml]$xaml = @'
#ZH-INCLUDE UI/MainWindow.xaml
'@

# Read and Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [System.Windows.Markup.XamlReader]::Load($reader)

# Resolve App Icon & Bind Immediately to Window & Win32 Class
$Script:AppIconPath = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.ico"))) {
    $Script:AppIconPath = Join-Path $PSScriptRoot "assets\logo.ico"
} elseif (Test-Path "$env:LOCALAPPDATA\ZeroHub\logo.ico") {
    $Script:AppIconPath = "$env:LOCALAPPDATA\ZeroHub\logo.ico"
} else {
    try {
        $zeroDir = "$env:LOCALAPPDATA\ZeroHub"
        if (-not (Test-Path $zeroDir)) { New-Item -Path $zeroDir -ItemType Directory -Force | Out-Null }
        $Script:AppIconPath = "$zeroDir\logo.ico"
        (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.ico", $Script:AppIconPath)
    } catch {}
}

if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
    try {
        $decoder = [System.Windows.Media.Imaging.IconBitmapDecoder]::new(
            [Uri]::new($Script:AppIconPath, [UriKind]::Absolute),
            [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        )
        if ($decoder.Frames.Count -gt 0) {
            $Window.Icon = $decoder.Frames[0]
        } else {
            $Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($Script:AppIconPath, [UriKind]::Absolute))
        }
    } catch {
        try { $Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($Script:AppIconPath, [UriKind]::Absolute)) } catch {}
    }
}

$Window.add_SourceInitialized({
    try {
        $helper = [System.Windows.Interop.WindowInteropHelper]::new($Window)
        $hwnd = $helper.Handle
        [ZeroHub.NativeMethods]::EnableDarkTitleBar($hwnd)
        if ($Script:AppIconPath -and (Test-Path $Script:AppIconPath)) {
            $icoBig = [System.Drawing.Icon]::new($Script:AppIconPath, 32, 32)
            $icoSmall = [System.Drawing.Icon]::new($Script:AppIconPath, 16, 16)
            [ZeroHub.NativeMethods]::SetWindowIconFull($hwnd, $icoBig.Handle, $icoSmall.Handle)
        }
    } catch {}
})

