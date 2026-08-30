# 🔒 Privacy & Anti-Telemetry Hardener Guide

ZeroHub provides an enterprise-grade 12-vector telemetry and privacy hardening module to prevent Windows from collecting, indexing, and transmitting your background usage data to remote servers.

---

## 🛡️ The 12 Privacy Protection Vectors

### 1. 📊 Diagnostics & Diagnostic Telemetry
* **What it does**: Disables `DiagTrack` (Connected User Experiences and Telemetry) and `dmwappushservice` services. Sets Group Policy `AllowTelemetry = 0` (Security/Off level).

### 2. 🎯 Advertising ID & User Timeline
* **What it does**: Disables the unique Windows per-user Advertising ID, stops Windows Timeline activity uploads to the cloud, and blocks cross-app advertising tracking.

### 3. ✍️ Inking, Typing & Speech Tracking
* **What it does**: Disables keystroke, handwriting, and voice telemetry sent to Microsoft for "personalization and dictionary improvements".

### 4. ⏰ Scheduled Telemetry Tasks
* **What it does**: Disables hidden Windows Task Scheduler triggers under `Microsoft\Windows\Customer Experience Improvement Program (CEIP)` and `Application Experience` (`ProgramDataUpdater`, `Compatibility Appraiser`).

### 5. 🤖 AI & Windows Recall Shield
* **What it does**: Disables Windows 11 AI Recall continuous screen snapshot indexing, Copilot background Edge WebView2 telemetry hooks, and AI feedback uploaders.

### 6. 🌐 Telemetry Hosts Null-Router
* **What it does**: Appends known Microsoft telemetry collection endpoints (`v10.events.data.microsoft.com`, `telemetry.microsoft.com`, `watson.telemetry.microsoft.com`) to `0.0.0.0` in the Windows `hosts` file (`C:\Windows\System32\drivers\etc\hosts`).

### 7. 🌍 Microsoft Edge Telemetry & Shopping Trackers
* **What it does**: Blocks Edge background startup boost, shopping assistant price trackers, and diagnostic reporting to Microsoft servers.

### 8. ⚠️ Error Reporting & Crash Dump Privacy
* **What it does**: Disables Windows Error Reporting (WER) from automatically uploading full system memory dumps (which can contain sensitive private data) over the internet.

### 9. 🚫 Windows Nudges & In-OS Ads
* **What it does**: Disables full-screen "Finish setting up your PC" OOBE nags, File Explorer promotional OneDrive banners, lock screen tips/ads, and Start menu suggested apps.

### 10. ⚡ Delivery Optimization P2P Seeding (WUDO)
* **What it does**: Stops Windows from using your home internet bandwidth to upload Windows Updates to random external computers across the internet.

### 11. 📋 Cloud Clipboard & Keystroke Sync
* **What it does**: Keeps Windows Clipboard history strictly local on your PC, blocking clipboard content from synchronizing across cloud devices.

### 12. 📍 Location Tracking & Feedback Nags
* **What it does**: Disables persistent background geolocation polling and sets Windows feedback frequency to "Never".

---

## ⚡ 1-Click Operations

* **🛡️ Apply Max Privacy Mode**: Activates all 12 protection vectors simultaneously with full verification.
* **🔄 Restore Windows Defaults**: Safely reverts all telemetry policies and services back to stock Windows defaults if ever needed.
