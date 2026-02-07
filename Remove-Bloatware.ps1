<#
.SYNOPSIS
    All-in-One Cleaner v9.1 (Clipchamp Fix):
    - Zeigt LIVE an, welche App gerade geprüft wird.
    - Spezieller "Kill-Switch" für Clipchamp hinzugefügt.
    - OneDrive & Registry Fix inklusive.
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

# Hier explizit Clipchamp als Ziel definiert
$GhostTargets = @("*OneDrive*", "*Clipchamp*")

# ---------------------------------------------------------
# 2. DATEIEN LÖSCHEN
# ---------------------------------------------------------
Write-Output "--- [PHASE 1] OneDrive Dateien ---"

taskkill /f /im OneDrive.exe /T 2>$null
taskkill /f /im "Microsoft OneDrive.exe" /T 2>$null
Start-Sleep -Seconds 1

$Folders = @(
    "C:\Program Files\Microsoft OneDrive",
    "C:\Program Files (x86)\Microsoft OneDrive",
    "C:\ProgramData\Microsoft OneDrive",
    "C:\OneDriveTemp"
)
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

$Users = Get-ChildItem -Path "C:\Users" -Directory
foreach ($User in $Users) {
    $LocalOD = "$($User.FullName)\AppData\Local\Microsoft\OneDrive"
    if (Test-Path $LocalOD) { Remove-Item -Path $LocalOD -Recurse -Force -ErrorAction SilentlyContinue }
    $Shortcut = "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    if (Test-Path $Shortcut) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------
# 3. REGISTRY CLEANER
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Registry Cleaner ---"

function Remove-RegEntry {
    param ($RootPath)
    if (-not (Test-Path $RootPath)) { return }
    
    Get-ChildItem $RootPath -ErrorAction SilentlyContinue | ForEach-Object {
        $KeyPath = $_.PSPath
        $DisplayName = $null
        try { $DisplayName = (Get-ItemProperty -Path $KeyPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName } catch {}

        foreach ($target in $GhostTargets) {
            if ($DisplayName -like $target) {
                Write-Output "   [REGISTRY] Entferne: '$DisplayName'"
                Remove-Item -Path $KeyPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

$SystemHives = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($hive in $SystemHives) { Remove-RegEntry -RootPath $hive }

Write-Output "   -> Scanne Benutzer-Profile..."
$UserSIDs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" | Select-Object -ExpandProperty PSChildName
foreach ($sid in $UserSIDs) {
    if ($sid -like "S-1-5-21*") { 
        $UserUninstallPath = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        Remove-RegEntry -RootPath $UserUninstallPath
    }
}

$InboxPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications"
if (Test-Path $InboxPath) {
    Get-ChildItem $InboxPath | Where-Object { $_.Name -like "*Clipchamp*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------
# 4. APPX / STORE BEREINIGUNG
# ---------------------------------------------------------
Write-Output "---
