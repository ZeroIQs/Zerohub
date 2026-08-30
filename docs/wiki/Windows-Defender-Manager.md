# 🛡️ Windows Defender & Security Quick Manager Guide

Windows Defender (Microsoft Defender Antivirus) constantly scans games and large assets in the background, which can cause micro-stutters, delayed game loading, and false positive warnings on legitimate games.

ZeroHub's Defender Quick Manager provides safe, 1-click tools to streamline antivirus performance without disabling core real-time protection.

---

## 🎮 1-Click Game Folder Exclusions Manager

### Why Exclude Game Folders?
When a game launches or loads a new map, it reads tens of thousands of texture files, audio banks, and executable scripts. If Defender scans every file during gameplay, it consumes CPU cycles and causes frame drops.

### How ZeroHub Handles Game Exclusions:
1. **Automatic Multi-Drive Detection**:
   * Scans all connected local drives (`C:`, `D:`, `E:`, `F:`, etc.) for installed game libraries:
     * Steam (`steamapps\common`)
     * Epic Games
     * EA Games / Origin
     * Ubisoft Game Launcher
     * GOG Galaxy Games
     * Riot Games (`VALORANT`, `League of Legends`)
     * XboxGames
     * Repack Directories (`Games`, `FitGirl Games`, `DODI-Repacks`)
2. **1-Click Add**: Adds all detected game folders directly to Windows Defender's native exclusion list via `Add-MpPreference -ExclusionPath`.
3. **Custom Folder Browser**: Allows selecting custom emulator, modding, or game directories with a native Windows folder picker.
4. **Active Exclusions Viewer**: Displays all currently excluded directories in a clean, scrollable list with 1-click removal.

---

## 🧹 Clear Defender Protection History (Stuck Threats Fixer)

### The "Stuck Threat" Problem:
Windows Defender often shows notifications for threats that have already been deleted or quarantined days or weeks ago because the internal `DetectionHistory` database files become corrupted.

### The Fix:
* Clicking **"🧹 Purge Protection History"** safely deletes the corrupted cache files inside:
  `C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service\DetectionHistory` and `Store`.
* Restarts the Defender service to instantly clear ghost notification badges from Windows Security.

---

## ⚡ Additional Quick Tools

* **⚡ 1-Click Quick Scan**: Launches a background antivirus scan without navigating through Windows Settings.
* **🔄 Asynchronous Signature Updates**: Force-downloads the latest virus definitions (`Update-MpSignature`) in a non-blocking background thread.
* **🛡️ Open Windows Security**: 1-Click direct launcher for the official Windows Security app.
