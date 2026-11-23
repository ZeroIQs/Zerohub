$BtnCreateShortcut.add_Click({
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "ZeroHub.lnk"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        
        $localDir = Join-Path $env:LOCALAPPDATA "ZeroHub"
        $localScript = Join-Path $localDir "ZeroHub-GUI.ps1"
        $localBat = Join-Path $localDir "ZeroHub-GUI.bat"

        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        # Determine best source script path
        $srcPath = if ($PSCommandPath -and (Test-Path $PSCommandPath)) { 
            $PSCommandPath 
        } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "ZeroHub-GUI.ps1"))) { 
            Join-Path $PSScriptRoot "ZeroHub-GUI.ps1" 
        } else { $null }

        # If running from a file, copy to local cache directory if not already there
        if ($srcPath -and (Test-Path $srcPath) -and ($srcPath -ne $localScript)) {
            try { Copy-Item -Path $srcPath -Destination $localScript -Force } catch {}
        }

        # Ensure local silent .vbs and .bat launchers exist
        $localVbs = Join-Path $localDir "ZeroHub-Silent.vbs"
        $targetScriptToRun = if ($srcPath -and (Test-Path $srcPath)) { $srcPath } else { $localScript }
        $vbsContent = "Set sh = CreateObject(`"WScript.Shell`")`r`nsh.Run `"powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `" & Chr(34) & `"$targetScriptToRun`" & Chr(34), 0, False`r`n"
        try { [System.IO.File]::WriteAllText($localVbs, $vbsContent, [System.Text.Encoding]::ASCII) } catch {}

        $batContent = "@echo off`r`ncd /d `"%~dp0`"`r`npowershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"`"%~dp0ZeroHub-GUI.ps1`"`""
        try { [System.IO.File]::WriteAllText($localBat, $batContent, [System.Text.Encoding]::ASCII) } catch {}

        if (Test-Path $localVbs) {
            $shortcut.TargetPath = "wscript.exe"
            $shortcut.Arguments = "`"$localVbs`""
            $shortcut.WorkingDirectory = $localDir
            $shortcut.WindowStyle = 7
        } elseif ($targetScriptToRun -and (Test-Path $targetScriptToRun)) {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$targetScriptToRun`""
            $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($targetScriptToRun)
            $shortcut.WindowStyle = 7
        } else {
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex`""
            $shortcut.WindowStyle = 7
        }
        
        # Resolve or prepare desktop shortcut icon (logo.ico matching logo.png)
        $localIco = Join-Path $localDir "logo.ico"
        $srcIco = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.ico"))) {
            Join-Path $PSScriptRoot "assets\logo.ico"
        } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "logo.ico"))) {
            Join-Path $PSScriptRoot "logo.ico"
        } else { $null }

        if ($srcIco -and (Test-Path $srcIco) -and ((Resolve-Path $srcIco).Path -ne (Resolve-Path $localIco -ErrorAction SilentlyContinue).Path)) {
            try { Copy-Item -Path $srcIco -Destination $localIco -Force -ErrorAction SilentlyContinue } catch {}
        } elseif (-not (Test-Path $localIco)) {
            $srcPng = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "assets\logo.png"))) {
                Join-Path $PSScriptRoot "assets\logo.png"
            } elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot "logo.png"))) {
                Join-Path $PSScriptRoot "logo.png"
            } else { $null }

            if ($srcPng -and (Test-Path $srcPng)) {
                try {
                    Add-Type -AssemblyName System.Drawing
                    $pngImg = [System.Drawing.Image]::FromFile($srcPng)
                    $bmp256 = New-Object System.Drawing.Bitmap(256, 256)
                    $g = [System.Drawing.Graphics]::FromImage($bmp256)
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $g.Clear([System.Drawing.Color]::Transparent)
                    $g.DrawImage($pngImg, 0, 0, 256, 256)
                    $g.Dispose()
                    $pngMs = New-Object System.IO.MemoryStream
                    $bmp256.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
                    $pBytes = $pngMs.ToArray()
                    $pngMs.Dispose()
                    $bmp256.Dispose()
                    $pngImg.Dispose()

                    $fileMs = New-Object System.IO.MemoryStream
                    $bw = New-Object System.IO.BinaryWriter($fileMs)
                    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
                    $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
                    $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$pBytes.Length); $bw.Write([uint32]22)
                    $bw.Write($pBytes); $bw.Flush()
                    [System.IO.File]::WriteAllBytes($localIco, $fileMs.ToArray())
                    $bw.Dispose(); $fileMs.Dispose()
                } catch {}
            }
            if (-not (Test-Path $localIco)) {
                try {
                    $wc = New-Object System.Net.WebClient
                    $wc.Headers.Add('User-Agent', 'ZeroHub')
                    $wc.DownloadFile("https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/assets/logo.ico", $localIco)
                } catch {}
            }
        }
        
        $shortcut.Description = "ZeroHub - Fast & Intelligent Windows Optimization Hub"
        if (Test-Path $localIco) {
            $shortcut.IconLocation = "$localIco,0"
        } else {
            $shortcut.IconLocation = "$env:SystemRoot\System32\cleanmgr.exe,0"
        }
        $shortcut.Save()

        $msg = "ZeroHub Desktop shortcut created successfully!`n`nIt will now launch locally from your PC instantly without needing internet."
        Add-HubLog "Desktop shortcut created: $shortcutPath" "SHORTCUT"
        [System.Windows.MessageBox]::Show($msg, "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        Add-HubLog "Failed to create shortcut: $($_.Exception.Message)" "ERROR"
        [System.Windows.MessageBox]::Show("Failed to create shortcut: $($_.Exception.Message)", "ZeroHub", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

