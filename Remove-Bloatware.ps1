<#
.SYNOPSIS
    All-in-One Cleaner v6 (Brute Force Edition):
    - FIX: Kein UAC-Popup mehr (ruft keinen Uninstaller auf).
    - FIX: Löscht OneDrive-Dateien hart von der Platte.
    - FIX: Löscht Einträge aus der "Installierte Apps" Liste via Registry.
    - FIX: Entfernt Clipchamp-Stubs.
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

# ---------------------------------------------------------
# 2. ONEDRIVE "BRUTE FORCE" LÖSCHUNG
# ---------------------------------------------------------
Write-Output "--- [PHASE 1] OneDrive Dateien & Registry löschen ---"

# 1. Prozesse hart beenden
taskkill /f /im OneDrive.exe /T 2>$null
taskkill /f /im "Microsoft OneDrive.exe" /T 2>$null
taskkill /f /im Explorer.exe /T 2>$null # Explorer kurz killen, um File-Locks zu lösen
Start-Sleep -Seconds 2

# 2. DATEIEN LÖSCHEN (Wir fragen nicht mehr den Uninstaller)
Write-Output "Lösche Programm-Dateien..."
$OneDriveFolders = @(
    "C:\Program Files\Microsoft OneDrive",
    "C:\Program Files (x86)\Microsoft OneDrive",
    "C:\ProgramData\Microsoft OneDrive",
    "C:\OneDriveTemp"
)
foreach ($folder in $OneDriveFolders) {
    if (Test-Path $folder) { Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue }
}

# 3. BENUTZER-ORDNER BEREINIGEN (Loop durch C:\Users)
Write-Output "Lösche OneDrive aus Benutzer-Profilen..."
$Users = Get-ChildItem -Path "C:\Users" -Directory
foreach ($User in $Users) {
    # AppData Local löschen
    $LocalOD = "$($User.FullName)\AppData\Local\Microsoft\OneDrive"
    if (Test-Path $LocalOD) {
        Write-Output "   -> Bereinige: $LocalOD"
        Remove-Item -Path $LocalOD -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Startmenü Verknüpfung löschen
    $Shortcut = "$($User.FullName)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    if (Test-Path $Shortcut) { Remove-Item -Path $Shortcut -Force -ErrorAction SilentlyContinue }
}

# 4. REGISTRY CLEANUP (Damit es aus der Liste verschwindet)
Write-Output "Bereinige Registry-Einträge (Liste)..."

# Systemweite Uninstall-Keys suchen und löschen
$UninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($Hive in $UninstallKeys) {
    Get-ChildItem $Hive -ErrorAction SilentlyContinue | ForEach-Object {
        $Name = (Get-ItemProperty -Path $_.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
        if ($Name -like "*OneDrive*") {
            Write-Output "   -> Entferne Registry-Key: $Name"
            Remove-Item -Path $_.PSPath -Recurse -Force
        }
    }
}

# Explorer neu starten
Start-Process "explorer.exe"

# ---------------------------------------------------------
# 3. CLIPCHAMP & BING (Provisioning + Registry Stub Killer)
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Clipchamp & Stubs entfernen ---"

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

# 1. Provisioning entfernen (Das verhindert die Neuinstallation)
foreach ($pattern in $KillPatterns) {
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern -or $_.PackageName -like $pattern } | ForEach-Object {
        Write-Output "Entferne Provisioning: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# 2. Installierte Pakete entfernen
Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*Clipchamp*" -or $_.PublisherId -eq "7m82760505" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

# 3. Clipchamp Registry Stub aus "InboxApps" entfernen (Der 8KB Eintrag)
# Das ist oft der Grund, warum es noch angezeigt wird
$InboxPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications"
if (Test-Path $InboxPath) {
    Get-ChildItem $InboxPath | Where-Object { $_.Name -like "*Clipchamp*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------
# 4. GENERELLE BEREINIGUNG (Appx)
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] Generelle Apps ---"

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
Write-Output "--- [PHASE 4] Assistenten Reste ---"
$Folders = @("C:\Windows10Upgrade", "C:\Windows11InstallationAssistant", "C:\$WINDOWS.~BT")
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Output "Bereinigung v6 komplett."
