<p align="center">
  <a href="https://zeroiq.site/" target="_blank">
    <img src="assets/logo.png" alt="ZeroHub Logo" width="200" height="200">
  </a>
</p>

<h1 align="center">ZeroHub</h1>

<p align="center">
  <strong>Fast, Safe & Intelligent All-in-One Windows Optimization Hub</strong><br>
  <em>Silent App Installs • Deep Cache Cleaning • Windows Debloat • Deep Uninstaller • Live RAM Flush • Windows Update Control</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D4.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Engine-C%23%20Async%20Native-4ADE80.svg" alt="Engine">
  <img src="https://img.shields.io/badge/Security-100%25%20Login%20Safe-38BDF8.svg" alt="Safety">
</p>

## 🚀 Quick Launch (1-Line Command)

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/itninja04/Zerohub/main/run.ps1 | iex
```

*Or simply double-click **`ZeroHub-GUI.bat`** in the repository.*

## 📸 Screenshots

<p align="center">
  <img src="assets/screenshot_cleaner.png" alt="ZeroHub Cleaner Dashboard" width="100%">
</p>

<p align="center">
  <img src="assets/screenshot_installer.png" alt="ZeroHub App Installer" width="100%">
</p>

<p align="center">
  <img src="assets/screenshot_about.png" alt="ZeroHub Power Modules" width="100%">
</p>

---

## 🌟 What ZeroHub Does

| Module | What It Does |
| :--- | :--- |
| 📦 **App Manager & Updater** | Checkbox front end over Winget for 226 curated packages, plus live upgrade detection (`Current → Available`). ZeroHub distributes no software of its own. Every install comes from the Winget repository. |
| 🧹 **Deep Cache Cleaner** | Cleans 68 targets (GPU shaders, dev tools, game launchers, browsers, and Windows temp). |
| 🗑️ **Bloatware & Edge Remover** | Removes pre-installed Windows junk (Cortana, Copilot, Bing News, Xbox overlays) and Microsoft Edge. Each entry states what breaks if it is not safe to remove. |
| ⚡ **Deep App Uninstaller** | Runs the app's own uninstaller, then offers to remove leftover folders and the orphaned registry key. Leftovers are always listed for approval before anything is deleted. |
| 🚀 **Live RAM Optimizer** | Real-time RAM meter and 1-click `EmptyWorkingSet` trim across running processes, without closing apps. |
| 🛡️ **Windows Updates Controller** | Block forced background updates and restarts, purge the update cache, and re-register the update DLLs. |

---

## 🔒 Safety & Performance

- 🛡️ **Login safe cleaning**: the 68 cache targets are cache and temp directories only. Cookie, login and bookmark databases sit outside every path in the list, and the cleaner deletes the contents of a target rather than the target itself.
- ⚡ **Off the UI thread**: the cache scan and the installed-app scan run in their own runspaces and stream results back, so the window stays responsive while they work. Tab data is cached for 5 minutes rather than re-queried on every click.
- 🧨 **Nothing destructive without a list**: leftover folder deletion shows the exact paths and sizes and defaults to No. The Windows Update component reset states up front that it runs `netsh winsock reset`, which drops third-party network layer providers and needs a reboot.
- 🎨 **Modern Fluent UI**: dark frameless titlebar (`WindowChrome`), live drive meter, and 1-click **English / العربية** switching.

### Known limits

- Removing **Xbox / Gaming Services** breaks Game Pass installs and is awkward to undo. Removing **Edge** is unsupported by Microsoft and Windows Update may reinstall it.
- Blocking Windows Update stops security patches until you toggle it back on.
- The app self-elevates. Under the `irm | iex` launcher there is no integrity check on the downloaded script, so run it from a commit you have read if that matters to you.

---

## 🙏 Credits

The Winget application catalog and its category layout are derived from
[Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil) (MIT).

---

## 👨‍💻 Author & Contact

Original ZeroHub by **Amir Ali** ([@sytus](https://t.me/sytus), [zeroiq.site](https://zeroiq.site/), [@lnetl](https://instagram.com/lnetl)).

This fork is maintained by [@itninja04](https://github.com/itninja04).
- **License:** [MIT License](LICENSE)


