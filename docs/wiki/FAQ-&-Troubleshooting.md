# ❓ FAQ & Troubleshooting

Common questions and answers regarding ZeroHub usage, safety, and performance.

---

## ❓ Frequently Asked Questions

### Q1: Is ZeroHub safe to use on my main PC?
**Yes, 100%.** ZeroHub is open-source under the **GNU General Public License v3 (GPLv3)**. All code is public and readable. It does not contain telemetry, tracking, miners, or third-party ads.

---

### Q2: Will running the Cleaner log me out of Discord, Steam, or Chrome?
**No.** ZeroHub has an isolated cleaning engine that specifically excludes browser cookies, login sessions, active tokens, and passwords. You will stay logged into all your accounts.

---

### Q3: Does ZeroHub work with Anti-Cheats (Vanguard, Easy Anti-Cheat, BattlEye)?
**Yes.** ZeroHub does not modify protected kernel files or inject code into games. It only manages standard Windows directories, shader caches, and folder exclusions, making it 100% safe for competitive online games.

---

### Q4: Why does ZeroHub require Administrator privileges?
Admin rights are required to:
* Clean system-level temporary files (`C:\Windows\Temp`).
* Add game folder exclusions to Windows Defender.
* Block background Windows telemetry services.
* Uninstall desktop applications and delete leftover registry entries.

---

### Q5: How do Live Auto-Updates work?
When ZeroHub starts, it connects via TLS 1.2 to your official repository on GitHub (`ZeroIQs/Zerohub`). If a newer version is found, a **Crimson Red `⤓ Update Available! ➔`** button appears in the sidebar. Clicking it automatically downloads and relaunches the newest version.

---

## 🔧 Troubleshooting

### "Script Execution Disabled on this System"
If Windows blocks script execution, open PowerShell as Administrator and run:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### "Winget not found in App Manager"
The 1-Click App Manager uses Microsoft Winget. If your Windows 10 installation lacks Winget, update the **"App Installer"** from the Microsoft Store or install it via the official Microsoft Winget GitHub repository.

---

## 💬 Community & Support
* **Website:** [zeroiq.site](https://zeroiq.site/)
* **Telegram:** [@sytus](https://t.me/sytus)
* **GitHub Issues:** [ZeroIQs/Zerohub/issues](https://github.com/ZeroIQs/Zerohub/issues)
