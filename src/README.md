# ZeroHub source

`ZeroHub-GUI.ps1` in the repo root is a build output. Edit the files here, then run:

```powershell
.\build.ps1          # rebuild ZeroHub-GUI.ps1
.\build.ps1 -Check   # exit 1 if ZeroHub-GUI.ps1 is out of date with src/
```

It stays one file on purpose: `run.ps1`, `ZeroHub-GUI.bat` and the in-app updater all download or launch that single script.

## How the build works

- `build-order.txt` lists the top-level files in load order. Order matters, since later files use variables and functions defined earlier.
- A line `#ZH-INCLUDE <path>` is replaced with the contents of that file. It is used to keep the C# types (`Core/CSharp/*.cs`) and the window markup (`UI/MainWindow.xaml`) as real files while they still end up inside their here-strings.
- Output is UTF-8 with BOM and LF line endings. CR characters in source files are dropped, so CRLF editors are fine.
- The build parses the result and refuses to write it if there are parse errors.

## Layout

| Folder | Contents |
|---|---|
| `App/` | startup, admin elevation, window lifecycle |
| `Core/` | C# types compiled with Add-Type |
| `UI/` | XAML window, control mapping, language, navigation, tab switching |
| `Shared/` | logging, settings, toast notifications, helpers |
| `Cleaner/` | targets, scan, clean, presets |
| `Processes/` | smart process manager and process guard |
| `Installer/`, `Uninstaller/`, `Bloatware/` | app management tabs |
| `WindowsUpdate/`, `Privacy/`, `Defender/`, `Drivers/`, `Network/`, `Startup/`, `Games/`, `Search/` | one folder per tab |
| `Updater/` | GitHub self-update |
