<#
.SYNOPSIS
    All-in-One Cleaner v8 (Safe Mode):
    - FIX: Tötet NICHT mehr den Explorer (verhindert Einfrieren).
    - Entfernt: OneDrive Dateien, Registry-Einträge, Clipchamp, Bing.
    - Behält: Whitelist.
#>

# ---------------------------------------------------------
# 1. KONFIGURATION
# ---------------------------------------------------------

$Whitelist = @(
    "Microsoft.MicrosoftEdge",
    "Microsoft.Windows.Photos",
    "Microsoft.Paint",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsTerminal",
    "Microsoft.Media.Player",
    "Microsoft.RemoteDesktop",
    "Microsoft.ScreenSketch",
    "Microsoft.WindowsStore",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.SecHealthUI"
)

$SystemCritical = @(
    "Microsoft.UI.Xaml", "Microsoft.VCLibs", "Microsoft.NET.Native",
    "Microsoft.WindowsAppRuntime", "Microsoft.Services.Store",
    "Microsoft.VP9VideoExtensions", "Microsoft.HEIFImageExtension",
    "Microsoft.WebMediaExtensions", "Microsoft.WebpImageExtension",
    "Microsoft.AAD.BrokerPlugin", "Microsoft.AccountsControl",
    "Microsoft.AsyncTextService", "Microsoft.BioEnrollment",
    "Microsoft.CredDialogHost", "Microsoft.ECApp", "Microsoft.LockApp",
    "Microsoft.Win32WebViewHost", "windows.immersivecontrolpanel",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.ShellExperienceHost", "MicrosoftWindows.Client"
)

# Suchbegriffe für Geister-Einträge
$GhostTargets = @("*OneDrive*", "*Clipchamp*")

# ---------------------------------------------------------
# 2. DATEIEN LÖSCHEN (Safe Mode)
# ---------------------------------------------------------
Write-Output "--- [PHASE 1] OneDrive Bereinigung ---"

# Nur OneDrive beenden, NICHT Explorer
taskkill /f /im OneDrive.exe /T 2>$null
taskkill /f /im "Microsoft OneDrive.exe" /T 2>$null
Start-Sleep -Seconds 2

# System-Ordner löschen
Write-Output "Lösche Programm-Ordner..."
$Folders = @(
    "C:\Program Files\Microsoft OneDrive",
    "C:\Program Files (x86)\Microsoft OneDrive",
    "C:\ProgramData\Microsoft OneDrive",
    "C:\OneDriveTemp"
)
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

# Benutzer-Ordner löschen
Write-Output "Lösche User-Daten (AppData)..."
$Users = Get-ChildItem -Path "C:\Users" -Directory
foreach ($User in $Users) {
    $LocalOD = "$($User.FullName)\AppData\Local\Microsoft\OneDrive"
    if (Test-Path $LocalOD) { Remove-Item -Path $LocalOD -Recurse -Force -ErrorAction SilentlyContinue }
    
    $Shortcut = "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    if (Test-Path $Shortcut) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------
# 3. REGISTRY CLEANER (Listen-Bereinigung)
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Registry Geister-Einträge entfernen ---"

function Remove-RegEntry {
    param ($RootPath)
    if (-not (Test-Path $RootPath)) { return }
    
    Get-ChildItem $RootPath -ErrorAction SilentlyContinue | ForEach-Object {
        $KeyPath = $_.PSPath
        $DisplayName = $null
        try { $DisplayName = (Get-ItemProperty -Path $KeyPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName } catch {}

        foreach ($target in $GhostTargets) {
            if ($DisplayName -like $target) {
                Write-Output "   [REGISTRY] Entferne: '$DisplayName' aus $RootPath"
                Remove-Item -Path $KeyPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# A. Systemweite Uninstall-Listen
$SystemHives = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($hive in $SystemHives) { Remove-RegEntry -RootPath $hive }

# B. Benutzer-spezifische Uninstall-Listen (HKU Scan)
Write-Output "Scanne Benutzer-Profile in Registry..."
$UserSIDs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Select-Object -ExpandProperty PSChildName

foreach ($sid in $UserSIDs) {
    if ($sid -like "S-1-5-21*") { 
        $UserUninstallPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        Remove-RegEntry -RootPath $UserUninstallPath
    }
}

# C. Clipchamp Inbox Stub
$InboxPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications"
if (Test-Path $InboxPath) {
    Get-ChildItem $InboxPath | Where-Object { $_.Name -like "*Clipchamp*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------
# 4. APPX / STORE BEREINIGUNG
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] Store Apps Bereinigung ---"

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

foreach ($pattern in $KillPatterns) {
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

foreach ($app in $Apps) {
    $shouldKeep = $false
    foreach ($pattern in ($Whitelist + $SystemCritical)) {
        if ($app.Name -like "*$pattern*") { $shouldKeep = $true; break }
    }
    foreach ($kill in $KillPatterns) {
        if ($app.Name -like $kill) { $shouldKeep = $false }
    }

    if (-not $shouldKeep) {
        try { Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop } catch {}
    }
}

# ---------------------------------------------------------
# 5. ASSISTENTEN
# ---------------------------------------------------------
Write-Output "--- [PHASE 4] Assistenten ---"
$UpgradeTools = @("C:\Windows10Upgrade\Windows10UpgraderApp.exe", "C:\Windows11InstallationAssistant\Windows11InstallationAssistant.exe")
foreach ($tool in $UpgradeTools) {
    if (Test-Path $tool) { Start-Process -FilePath $tool -ArgumentList "/ForceUninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue }
}
$Folders = @("C:\Windows10Upgrade", "C:\Windows11InstallationAssistant", "C:\$WINDOWS.~BT")
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Output "Vorgang abgeschlossen."
