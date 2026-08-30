# 📦 App Manager & Deep Uninstaller Guide

ZeroHub provides complete control over your installed desktop software, silent bulk installations, version updates, and residual file scrubbing.

---

## 📦 1-Click App Manager & Updater

The App Manager interfaces directly with Microsoft's official **Winget Package Manager API** to provide silent, background application deployment without bloatware, toolbars, or manual installer clicking.

### Key Capabilities:
* **100+ Top Software Packages**: Organized across 8 curated categories (Web Browsers, Dev Tools, Gaming Launchers, Media & Creative, System Utilities, Documents, Hardware Monitoring, and Microsoft Runtimes).
* **Live Update Recognizer**: Scans your PC on tab launch and detects available upgrades (`Current Version → Available Version`), highlighting pending updates with a dedicated badge (`[⚡ Update available]`).
* **Silent Multi-App Installation**: Select multiple applications and click **"Install Selected Apps"** to install everything concurrently in the background.

---

## 🗑️ Deep App Uninstaller

When standard Windows uninstallers run, they often leave behind hundreds of megabytes of junk in `AppData`, `ProgramData`, and orphaned registry keys in `HKCU`/`HKLM`.

### How Deep Uninstaller Works:
1. **Enumerates All Installed Software**: Lists 32-bit and 64-bit desktop programs from Windows Registry with exact installation sizes and publishers.
2. **Executes Official Silent Uninstall**: Calls the official uninstaller with silent switches (`/silent`, `/qn`, `/quiet`, `/VERYSILENT`).
3. **Automatic Leftover Scrubber**:
   * Scans `%APPDATA%`, `%LOCALAPPDATA%`, `%PROGRAMDATA%`, and `C:\Program Files` for residual developer folders matching the uninstalled software name.
   * Scans Windows Registry for dead registry subkeys and wipes them completely.
4. **Summary & Freed Space**: Reports exact reclaimed disk space upon completion.

---

## 🚀 Windows Bloatware Remover

1-Click removal of pre-installed Microsoft junk apps that consume RAM and background CPU cycles:
* **Cortana, Copilot, Bing News, Bing Weather, Microsoft News, Xbox Game Overlay, Feedback Hub, Tips, Solitaire Collection, Get Help, Windows Maps, Zune Video, Phone Link, Microsoft Edge (Optional)**.
* Cleans AppX provisioned packages to prevent Windows from reinstalling them on new user profile creation.
