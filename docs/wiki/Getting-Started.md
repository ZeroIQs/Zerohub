# 🚀 Getting Started with ZeroHub

This guide covers everything you need to know to launch, configure, and run ZeroHub on your PC.

---

## 💻 System Requirements

* **Operating System**: Windows 10 (64-bit) or Windows 11 (64-bit).
* **PowerShell Version**: PowerShell 5.1 (Built-in to Windows) or PowerShell 7+ (Core).
* **Privileges**: Administrator privileges recommended for system-level tweaks, cache deletion, and Windows Defender exclusions.
* **Internet Connection**: Required for 1-Click App Installer and Live GitHub Auto-Updates.

---

## ⚡ Launch Methods

### Method 1: Instant Web Launch (Recommended)
Open **PowerShell as Administrator** and paste:

```powershell
irm https://raw.githubusercontent.com/ZeroIQs/Zerohub/main/run.ps1 | iex
```

*This downloads and runs the latest official version in memory without needing manual installation.*

---

### Method 2: Local Portable Execution
1. Clone or download the repository from [GitHub](https://github.com/ZeroIQs/Zerohub).
2. Right-click **`ZeroHub-GUI.bat`** and choose **"Run as Administrator"**.
3. ZeroHub will launch instantly with the dark fluent UI.

---

## 🛡️ Administrator Rights & Elevation

Certain modules in ZeroHub require elevated administrative permissions:
* **Deep Cleaner**: Unlocks locked system temp files, delivery optimization, and Windows Update cache.
* **Defender Quick Manager**: Adding folder exclusions requires Windows Security Admin access.
* **Privacy & Telemetry**: Modifying system-wide telemetry policies in `HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection`.

If ZeroHub is started without admin rights, a prominent **"Elevate"** badge appears in the top header, allowing 1-click relaunch as Administrator.

---

## 🌐 Language Selection (Bilingual Interface)

ZeroHub features a built-in 1-click **English ↔ العربية** toggle in the top-right header:
* Switches all UI modules, buttons, status tooltips, and explanations instantly.
* Preserves your language preference across restarts.
