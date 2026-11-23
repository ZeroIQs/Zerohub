# Ensure C# Core Types
if (-not ([System.Management.Automation.PSTypeName]'ZeroHub.TargetItem').Type) {
    # No -ReferencedAssemblies here on purpose. PowerShell 7 treats that parameter as the
    # COMPLETE reference set rather than an addition, so naming the four WPF assemblies drops
    # System.Runtime and System.Collections.Concurrent and the compile dies on CS0234 before a
    # single ZeroHub type exists. Passing the loaded assemblies instead fails differently:
    # Stack<T> then demands System.Private.CoreLib, which Add-Type refuses as a reference.
    # The default set is correct on both editions, so the C# below stays free of WPF types
    # (CheckBoxControl and SizeLabel are object; PowerShell late-binds their members anyway).
    # Verified 2026-08-29 compiling clean on pwsh 7.6.5 and Windows PowerShell 5.1.
    Add-Type -TypeDefinition @'
#pragma warning disable 0067, 0649
using System;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace ZeroHub {
#ZH-INCLUDE Core/CSharp/Models.Core.cs
#ZH-INCLUDE Core/CSharp/Models.Features.cs
#ZH-INCLUDE Core/CSharp/FileContentSearcher.cs
#ZH-INCLUDE Core/CSharp/AsyncProcessRunner.cs
#ZH-INCLUDE Core/CSharp/NativeMethods.cs
#ZH-INCLUDE Core/CSharp/ProcessManagerEngine.cs
#ZH-INCLUDE Core/CSharp/UninstallerEngine.cs
}
'@
}

# Add-Type reports a compile failure as a NON-terminating error, so before this guard existed the
# script sailed on and every later call site failed in turn: roughly 2000 "Unable to find type" and
# "property cannot be found" lines that buried the single CS#### line that actually explained it.
# The giveaway was [System.Collections.Generic.List] being reported as missing, which is impossible
# unless the generic argument (a ZeroHub type) never compiled. Stop here instead of cascading.
if (-not ([System.Management.Automation.PSTypeName]'ZeroHub.TargetItem').Type) {
    Write-Host ""
    Write-Host "ZeroHub cannot start: its core C# types failed to compile." -ForegroundColor Red
    Write-Host "The real error is the CS#### compiler message printed above this line." -ForegroundColor Red
    Write-Host "This is NOT a missing-file or permissions problem." -ForegroundColor Red
    Write-Host ""
    Write-Host "Workaround, run it under Windows PowerShell 5.1:" -ForegroundColor Yellow
    if ($PSCommandPath) {
        Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ForegroundColor Yellow
    } else {
        Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex`"" -ForegroundColor Yellow
    }
    Write-Host ""
    exit 1
}

