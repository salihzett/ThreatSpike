<#
.SYNOPSIS
    All-in-One Cleaner v9.2 (Clipchamp Fix):
    - Reparierte Syntax für IEX-Ausführung.
    - Spezieller "Kill-Switch" für Clipchamp.
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

# Clipchamp hier explizit in die Suchliste
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
Write-Output "--- [PHASE 3] Apps Bereinigung (Bitte warten...) ---"

# --- ZUSATZ: SPEZIALBEHANDLUNG CLIPCHAMP ---
Write-Output "   -> [PRIORITÄT] Suche und vernichte Clipchamp..."
Get-AppxPackage -AllUsers "*Clipchamp*" | ForEach-Object {
    Write-Output "      GEFUNDEN: $($_.Name) - Wird entfernt."
    $_ | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}
Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -like "*Clipchamp*"} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
# -------------------------------------------

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

# Provisioning für andere Apps löschen
foreach ($pattern in $KillPatterns) {
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern } | ForEach-Object {
        Write-Output "   -> Entferne Image-Paket: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
}

# Installierte Apps scannen (Microsoft Filter)
$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

$Total = $Apps.Count
$Count = 0

foreach ($app in $Apps) {
    $Count++
    # Einfacheres Write-Host ohne komplexe Escapes, um IEX-Fehler zu vermeiden
    Write-Host "   -> Prüfe App [$Count / $Total]: $($app.Name)"
    
    $shouldKeep = $false
    # 1. Whitelist Check (Wenn ja -> Behalten)
    foreach ($pattern in ($Whitelist + $SystemCritical)) {
        if ($app.Name -like "*$pattern*") { $shouldKeep = $true; break }
    }
    
    # 2. KillList Check (Wenn ja -> Weg damit, überschreibt Whitelist)
    foreach ($kill in $KillPatterns) {
        if ($app.Name -like $kill) { $shouldKeep = $false }
    }

    # Löschen wenn nicht behalten
    if (-not $shouldKeep) {
        Write-Host "      [LÖSCHE] $($app.Name)..." -ForegroundColor Yellow
        try { 
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop 
        } catch {
            Write-Host "      [FEHLER] Konnte nicht löschen (evtl. System-App)." -ForegroundColor Red
        }
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
$Folders = @("C:\Windows10Upgrade", "C:\Windows11InstallationAssistant", "C:\`$WINDOWS.~BT")
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Output "FERTIG! Bitte Einstellungen schließen und neu prüfen."
