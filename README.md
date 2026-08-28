# ZeroCleaner 🚀

> **Fast, Safe, and Intelligent Cache Cleaner for Windows Drive C:**  
> Clean 55+ verified cache targets across browsers, games, developer tools, creative suites, and GPU shaders — without losing your saved logins, cookies, or active sessions.

**Developed by Amir Ali** ([@sytus](https://t.me/sytus)) · **Instagram:** [@lnetl](https://instagram.com/lnetl)

---

## 🌟 Key Features

- 🖥️ **Modern Desktop GUI (Chris Titus Tech WinUtil Style):** Native Windows WPF XAML desktop app featuring deep dark mode, category cards, Drive C: storage visualizer, live console, and target inspector.
- 🛡️ **100% Safe Account & Login Protection:** Cleans purely temporary scratch & render caches without touching saved browser logins, cookies, passwords, or account credentials.
- ⚡ **55+ Integrated Cache Targets:** Reclaims tens of gigabytes of wasted storage across browsers, game launchers, dev tools, creative apps, and GPU drivers.
- 🎨 **Dynamic High-Contrast UI:** Crisp `#FFFFFF` text that turns to `#DA7756` coral orange upon selection.
- 🔒 **Active Application Guard:** Detects running processes (Discord, Steam, Chrome, VS Code, Battle.net, Riot) to safely skip locked files or optionally close them for 100% deep clean.
- 🎯 **One-Click Presets:** Recommended (100% login safe), All, Browsers, Dev Caches, Gaming, or Custom selection.
- 📊 **Target Inspector & Search:** Filter and inspect all cache locations, sizes, and file locks in real-time.
- 🔑 **Admin Elevation Support:** Optional system-level cleanup for Windows Update leftovers, Delivery Optimization caches, and crash memory dumps.

---

## 📦 Cache Targets Covered (55+)

| Category | Supported Applications & Caches |
| :--- | :--- |
| **🎮 GPU Shaders** | NVIDIA DXCache & GLCache, AMD DxCache & GLCache, Intel GPU Shader Cache, DirectX D3D Shader Cache |
| **💻 Dev Caches** | `npm`, `pip`, `Yarn`, `pnpm`, `NuGet` (.NET/C#), `Gradle` (Java/Android), `Maven`, `Android SDK build-cache`, `Go` build cache, `Cargo` (Rust) registry cache, `VS Code` cached data, `JetBrains` IDE caches |
| **🌐 Browsers** | Google Chrome, Microsoft Edge, Brave, Arc Browser, Mozilla Firefox, Opera, Opera GX, Vivaldi, Chromium (HTML, Code, and GPU caches) |
| **🕹️ Gaming** | Steam WebCache, Epic Games Launcher, Blizzard Battle.net, Riot Games / VALORANT / LoL, GOG Galaxy, Roblox, EA Desktop, Ubisoft Connect |
| **🎬 Creative & Chat** | DaVinci Resolve render cache, Blender render cache, OBS Studio browser source cache, VLC media art cache, Telegram media cache, Discord (Stable, Canary, PTB), Slack, Microsoft Teams, Notion, Figma, Obsidian, Postman, Spotify audio storage, Adobe Media Cache |
| **💻 System & Temp** | Windows User Temp (`%TEMP%`), Cryptnet SSL URL Cache, Windows Update leftovers, Delivery Optimization, WER crash logs, Windows BSOD crash dumps (`MEMORY.DMP`), NVIDIA App driver artifacts |

---

## 🚀 How to Run

### ⚡ Method 1: Instant 1-Line Web Launch (Recommended)
Open PowerShell as Administrator and run:
```powershell
irm https://raw.githubusercontent.com/ZeroIQs/ZeroCleaner/main/run.ps1 | iex
```

### 📦 Method 2: Local Batch Launch
- Double-click **`ZeroCleaner-GUI.bat`** (it automatically prompts for Administrator elevation to unlock all system caches, or run `powershell -ExecutionPolicy Bypass -File .\ZeroCleaner-GUI.ps1`).

---

## 🎛️ GUI Dashboard Overview

- **Cleaner Dashboard:** Select presets (`Recommended`, `Browsers`, `Dev Caches`, `Gaming`, `Select All`) or toggle individual checkboxes with real-time size labels.
- **Drive C: Meter:** Live progress bar showing used and free disk space.
- **Simulate (Dry Run):** Test how much space can be freed without deleting anything.
- **Target Inspector:** Search and filter targets by name, category, or path.
- **Process Guard:** View running apps holding cache locks and close them with one click.
- **Activity Log:** Real-time log stream with instant clipboard copying.

---

## 🔒 Safety Guarantees

1. **No Password / Cookie Reset:** ZeroCleaner targets temporary cache folders (`Cache`, `Code Cache`, `DXCache`, `htmlcache`) and NEVER deletes profile databases (`Web Data`, `Login Data`, `Cookies`, `Local Storage/leveldb`).
2. **Guarded Processes:** If an app is running (e.g., Discord or Firefox), ZeroCleaner prompts you before attempting to close it or skips locked files safely.

---

© 2026 **Amir Ali** (`@sytus`) · [Telegram](https://t.me/sytus) · [Instagram](https://instagram.com/lnetl)
