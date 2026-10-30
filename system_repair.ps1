<#
================================================================================
  GENERATIVE AI - Advanced Windows Diagnostic & Recovery Toolkit
  Platform: Windows 10 & Windows 11
  Description: PowerShell-driven system repair, update cache purge, BCD manager,
               and automated support bundle log collector.
================================================================================
#>

# --- 1. ELEVATION CHECK ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n [ERROR] 'GENERATIVE AI' requires Administrator privileges." -ForegroundColor Red
    Write-Host " Please restart PowerShell as Administrator and rerun this script.`n" -ForegroundColor Yellow
    Pause
    Exit
}

# --- 2. INITIALIZATION & LOGGING ---
$Host.UI.RawUI.WindowTitle = "GENERATIVE AI - Recovery Toolkit"
$LogDir = "$env:USERPROFILE\Desktop\GENERATIVE_AI_Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$LogFile = "$LogDir\GenerativeAI_Run_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMsg = "[$TimeStamp] $Message"
    Write-Host $FormattedMsg -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $FormattedMsg
}

# --- 3. CORE FUNCTION DEFINITIONS ---

function Run-SFCAndDISM {
    Clear-Host
    Write-Log "--- Starting System File & Image Repair ---" "Cyan"
    Write-Log "Running SFC (System File Checker)..." "Yellow"
    sfc /scannow | Out-Host

    Write-Log "Running DISM Component Store Scan & Cleanup..." "Yellow"
    dism /Online /Cleanup-Image /ScanHealth | Out-Host
    dism /Online /Cleanup-Image /RestoreHealth | Out-Host
    Write-Log "SFC and DISM operations complete." "Green"
    Pause
}

function Run-DiskCheck {
    Clear-Host
    Write-Log "--- Checking System Drive Health ---" "Cyan"
    Write-Log "Running CHKDSK on C: drive (Read-Only Mode)..." "Yellow"
    chkdsk C: | Out-Host
    Write-Log "Disk scan complete. If errors were found, schedule a repair reboot using 'chkdsk C: /f'." "Green"
    Pause
}

function Reset-WindowsUpdateCache {
    Clear-Host
    Write-Log "--- Resetting Windows Update Cache ---" "Cyan"
    
    $Services = @("wuauserv", "bits", "cryptsvc", "msiserver")
    foreach ($svc in $Services) {
        Write-Log "Stopping service: $svc..." "Yellow"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Purging SoftwareDistribution and Catroot2 folders..." "Yellow"
    if (Test-Path "$env:windir\SoftwareDistribution") {
        Remove-Item -Path "$env:windir\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path "$env:windir\System32\catroot2") {
        Remove-Item -Path "$env:windir\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($svc in $Services) {
        Write-Log "Starting service: $svc..." "Yellow"
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }
    Write-Log "Windows Update cache successfully reset." "Green"
    Pause
}

function Set-SafeModeBoot {
    Clear-Host
    Write-Log "--- Toggle Safe Mode Boot (BCD) ---" "Cyan"
    Write-Host "1. Enable Safe Mode on Next Reboot"
    Write-Host "2. Disable Safe Mode (Return to Normal Boot)"
    Write-Host "3. Cancel"
    $Choice = Read-Host "`nSelect an option [1-3]"

    switch ($Choice) {
        "1" {
            bcdedit /set {default} safeboot minimal | Out-Host
            Write-Log "Safe Mode configured for next boot." "Green"
        }
        "2" {
            bcdedit /deletevalue {default} safeboot | Out-Host
            Write-Log "Safe Mode disabled. Normal boot restored." "Green"
        }
        Default { Write-Log "Operation canceled." "Yellow" }
    }
    Pause
}

function Reset-NetworkStack {
    Clear-Host
    Write-Log "--- Resetting Network Stack & Winsock ---" "Cyan"
    
    Write-Log "Flushing DNS cache..." "Yellow"
    ipconfig /flushdns | Out-Host

    Write-Log "Resetting Winsock and IP configurations..." "Yellow"
    netsh winsock reset | Out-Host
    netsh int ip reset | Out-Host

    Write-Log "Network stack reset completed. A system restart is recommended." "Green"
    Pause
}

function Remove-RecentWindowsUpdates {
    Clear-Host
    Write-Log "--- List & Remove Recent Windows Updates ---" "Cyan"
    Write-Log "Querying installed package updates via DISM..." "Yellow"
    
    Get-WindowsPackage -Online | Where-Object { $_.PackageState -eq "Installed" } | Select-Object -Property PackageName, InstallTime | Format-Table -AutoSize
    
    $PackageName = Read-Host "`nEnter the exact PackageName to remove (or leave blank to cancel)"
    if (-not [string]::IsNullOrWhiteSpace($PackageName)) {
        Write-Log "Attempting removal of $PackageName..." "Yellow"
        dism /Online /Remove-Package /PackageName:$PackageName | Out-Host
    } else {
        Write-Log "Package removal canceled." "Yellow"
    }
    Pause
}

function Export-SupportBundle {
    Clear-Host
    Write-Log "--- Generating Support Bundle ZIP ---" "Cyan"
    
    $TempZipDir = "$env:TEMP\GenerativeAI_Bundle"
    if (Test-Path $TempZipDir) { Remove-Item -Path $TempZipDir -Recurse -Force }
    New-Item -ItemType Directory -Path $TempZipDir | Out-Null

    Write-Log "Collecting CBS and DISM logs..." "Yellow"
    if (Test-Path "$env:windir\Logs\CBS\CBS.log") { Copy-Item "$env:windir\Logs\CBS\CBS.log" -Destination $TempZipDir }
    if (Test-Path "$env:windir\Logs\DISM\dism.log") { Copy-Item "$env:windir\Logs\DISM\dism.log" -Destination $TempZipDir }

    Write-Log "Collecting Minidump crash files..." "Yellow"
    if (Test-Path "$env:windir\Minidump") { Copy-Item "$env:windir\Minidump\*" -Destination $TempZipDir -Recurse }

    Write-Log "Generating System Information summary..." "Yellow"
    Get-ComputerInfo | Out-File -FilePath "$TempZipDir\SystemInfo.txt"

    $ZipPath = "$LogDir\SupportBundle_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    Compress-Archive -Path "$TempZipDir\*" -DestinationPath $ZipPath -Force

    Remove-Item -Path $TempZipDir -Recurse -Force
    Write-Log "Support bundle successfully created at: $ZipPath" "Green"
    Pause
}

function Create-RestorePoint {
    Clear-Host
    Write-Log "--- Creating System Restore Point ---" "Cyan"
    try {
        Checkpoint-Computer -Description "GenerativeAI_Manual_RestorePoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Log "System Restore Point created successfully." "Green"
    } catch {
        Write-Log "Failed to create Restore Point: $_" "Red"
    }
    Pause
}

# --- 4. MAIN MENU LOOP ---
do {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "                         GENERATIVE AI RECOVERY TOOLKIT                   " -ForegroundColor White
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  [1]  Run SFC File Checker & DISM Image Repair"
    Write-Host "  [2]  Scan System Drive Health (CHKDSK)"
    Write-Host "  [3]  Reset Windows Update Cache (Fix Update Stalls)"
    Write-Host "  [4]  Toggle Safe Mode Boot (BCD)"
    Write-Host "  [5]  Reset Network Stack & Winsock Catalog"
    Write-Host "  [6]  List & Rollback Recent Windows Updates"
    Write-Host "  [7]  Export Full Diagnostic Support Bundle (ZIP)"
    Write-Host "  [8]  Create System Restore Point"
    Write-Host "  [9]  Restart Computer"
    Write-Host "  [10] Exit"
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $Selection = Read-Host "Select an option [1-10]"

    switch ($Selection) {
        "1"  { Run-SFCAndDISM }
        "2"  { Run-DiskCheck }
        "3"  { Reset-WindowsUpdateCache }
        "4"  { Set-SafeModeBoot }
        "5"  { Reset-NetworkStack }
        "6"  { Remove-RecentWindowsUpdates }
        "7"  { Export-SupportBundle }
        "8"  { Create-RestorePoint }
        "9"  { Restart-Computer -Confirm }
        "10" { Write-Host "`nExiting GENERATIVE AI. Goodbye!" -ForegroundColor Green; Exit }
        Default { Write-Host "`nInvalid choice. Press Enter to retry..." -ForegroundColor Red; Pause }
    }
} while ($true)