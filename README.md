# GENERATIVE AI — Advanced Windows Repair & Recovery Toolkit

**GENERATIVE AI** is a lightweight, PowerShell-driven diagnostic and system repair script designed for **Windows 10 and Windows 11**. It consolidates core Windows servicing commands, system file diagnostics, boot configuration settings, update cache resets, and log aggregation into a single, user-friendly interactive menu.

---

## 🚀 Features

* **System File & Image Repair:** Runs `sfc /scannow` and `DISM` component store cleanup to fix corrupted operating system files.
* **Disk Diagnostics:** Performs drive checks (`chkdsk`) to monitor hard drive and SSD integrity.
* **Windows Update Cache Reset:** Halts update services, purges corrupted `SoftwareDistribution` and `Catroot2` folders, and restarts services to fix stuck update cycles.
* **Safe Mode Toggle:** Effortlessly configures Boot Configuration Data (BCD) to boot directly into Safe Mode on the next restart.
* **Network Stack Reset:** Resets Winsock, IP stack configurations, and flushes DNS caches to restore connectivity.
* **Recent Package Rollback:** Lists installed Windows update packages and provides an interface to cleanly remove problematic updates.
* **Support Bundle Collector:** Automatically collects CBS logs, DISM logs, crash minidumps, and system info into a single, timestamped ZIP archive on your desktop.
* **System Restore Points:** Creates immediate checkpoints prior to applying major system changes.

---

## 📋 Requirements

* **OS:** Windows 10 or Windows 11
* **Privileges:** Administrator access (Elevated Command Prompt or PowerShell)
* **Execution Policy:** PowerShell Script Execution enabled (or bypassed via launcher)

---

## 🛠️ How to Save & Run

### Method 1: Running via PowerShell Directly
1. Copy the script content into a text file and save it as **`GENERATIVE_AI.ps1`**.
2. Right-click **`GENERATIVE_AI.ps1`** and select **Run with PowerShell**.
3. If prompted for administrative privileges, accept the UAC prompt.

### Method 2: Bypassing PowerShell Execution Policy
If Windows prevents script execution due to execution policy restrictions, open Command Prompt as Administrator and run:

```cmd
powershell -ExecutionPolicy Bypass -File "C:\Path\To\GENERATIVE_AI.ps1"
```

---

## 📂 Menu Overview

```text
==========================================================================
                         GENERATIVE AI RECOVERY TOOLKIT                   
==========================================================================
  [1]  Run SFC File Checker & DISM Image Repair
  [2]  Scan System Drive Health (CHKDSK)
  [3]  Reset Windows Update Cache (Fix Update Stalls)
  [4]  Toggle Safe Mode Boot (BCD)
  [5]  Reset Network Stack & Winsock Catalog
  [6]  List & Rollback Recent Windows Updates
  [7]  Export Full Diagnostic Support Bundle (ZIP)
  [8]  Create System Restore Point
  [9]  Restart Computer
  [10] Exit
==========================================================================
```

---

## ⚠️ Important Safety Instructions

1. **Backup Data First:** Always back up vital files before running disk repair operations or removing system packages.
2. **Hardware Issues:** `CHKDSK` repairs file-system-level errors, but cannot fix physical drive degradation. If your drive is making unusual noises or producing read errors, back up immediately.
3. **Admin Rights:** This toolkit modifies system settings and services. It **must** be run as Administrator to function correctly.

---

## 📜 Output & Logs

All operation logs and exported support bundles are automatically organized and saved to your desktop:
```text
C:\Users\<YourUsername>\Desktop\GENERATIVE_AI_Logs\
```