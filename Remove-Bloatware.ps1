<#
.SYNOPSIS
    All-in-One Cleaner v4:
    - NEU: Aggressive OneDrive Deinstallation (Win32 & Store).
    - NEU: Verbesserte Clipchamp Entfernung.
    - Behält: Whitelist (Edge, Paint, etc.).
#>

# ---------------------------------------------------------
# 1. KONFIGURATION & WHITELIST
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

# System-Komponenten (Schutz)
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
# 2. ONEDRIVE ENTFERNEN (Win32 & Store)
# ---------------------------------------------------------
Write-Output "--- [PHASE 1] Entferne OneDrive ---"

# Prozess beenden
taskkill /f /im OneDrive.exe /T -ErrorAction SilentlyContinue

# Deinstallations-Routine finden und ausführen
$OneDriveSetups = @(
    "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe",
    "$env:SYSTEMROOT\System32\OneDriveSetup.exe",
    "$env:LOCALAPPDATA\Microsoft\OneDrive\Update\OneDriveSetup.exe",
    "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe"
)

$foundUninstaller = $false
foreach ($setup in $OneDriveSetups) {
    if (Test-Path $setup) {
        Write-Output "Uninstaller gefunden: $setup"
        Start-Process -FilePath $setup -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        $foundUninstaller = $true
    }
}

# Wartezeit für Deinstallation
if ($foundUninstaller) { Start-Sleep -Seconds 5 }

# Reste aufräumen (Ordner & Registry)
Write-Output "Bereinige OneDrive Reste..."
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue

# Entfernt OneDrive aus dem Datei-Explorer (Registry)
$RegKey = "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $RegKey) { Remove-Item -Path $RegKey -Recurse -Force -ErrorAction SilentlyContinue }
$RegKey64 = "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
if (Test-Path $RegKey64) { Remove-Item -Path $RegKey64 -Recurse -Force -ErrorAction SilentlyContinue }

# ---------------------------------------------------------
# 3. CLIPCHAMP, BING & REMOTEHILFE (Aggressiv)
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Entferne Clipchamp, Bing, Remotehilfe ---"

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

foreach ($pattern in $KillPatterns) {
    # Appx Packages (Installierte Apps)
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern -or $_.DisplayName -like $pattern } | ForEach-Object {
        Write-Output "Entferne Appx: $($_.Name)"
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
    
    # Provisioned Packages (System-Image)
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern -or $_.PackageName -like $pattern } | ForEach-Object {
        Write-Output "Entferne Provisioned: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------
# 4. GENERELLE BEREINIGUNG (Appx)
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] Generelle Bloatware Bereinigung ---"

$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

foreach ($app in $Apps) {
    $shouldKeep = $false
    
    # Whitelist Check
    foreach ($pattern in ($Whitelist + $SystemCritical)) {
        if ($app.Name -like "*$pattern*") { $shouldKeep = $true; break }
    }

    # Kill-Pattern Override (falls Clipchamp doch noch dabei ist)
    foreach ($kill in $KillPatterns) {
        if ($app.Name -like $kill) { $shouldKeep = $false }
    }

    if (-not $shouldKeep) {
        Write-Output "Entferne: $($app.Name)"
        try { Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop } catch {}
    }
}

# ---------------------------------------------------------
# 5. KLASSISCHE UPDATE ASSISTENTEN
# ---------------------------------------------------------
Write-Output "--- [PHASE 4] Assistenten & Abschluss ---"

$UpgradeTools = @("C:\Windows10Upgrade\Windows10UpgraderApp.exe", "C:\Windows11InstallationAssistant\Windows11InstallationAssistant.exe")
foreach ($tool in $UpgradeTools) {
    if (Test-Path $tool) {
        Start-Process -FilePath $tool -ArgumentList "/ForceUninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
}

$Folders = @("C:\Windows10Upgrade", "C:\Windows11InstallationAssistant", "C:\$WINDOWS.~BT")
foreach ($f in $Folders) { if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue } }

Write-Output "Bereinigung v4 abgeschlossen."
