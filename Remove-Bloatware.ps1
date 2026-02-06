<#
.SYNOPSIS
    All-in-One Cleaner v5:
    - NEU: OneDrive "Nuclear"-Option (Löscht Dateien in C:\Users\*\AppData).
    - Behält: Whitelist, System-Schutz, entfernt Clipchamp/Bing.
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
# 2. ONEDRIVE ZERSTÖREN (Nuclear Option)
# ---------------------------------------------------------
Write-Output "--- [PHASE 1] OneDrive Manuelle Entfernung ---"

# 1. Prozess töten
Write-Output "Beende OneDrive Prozesse..."
taskkill /f /im OneDrive.exe /T 2>$null
taskkill /f /im "Microsoft OneDrive.exe" /T 2>$null
Start-Sleep -Seconds 2

# 2. Versuch der offiziellen Deinstallation (System-Level)
$Uninstalls = @(
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe",
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "C:\Program Files\Microsoft OneDrive\OneDriveSetup.exe",
    "C:\Program Files (x86)\Microsoft OneDrive\OneDriveSetup.exe"
)
foreach ($exe in $Uninstalls) {
    if (Test-Path $exe) {
        Write-Output "Führe Uninstaller aus: $exe"
        Start-Process -FilePath $exe -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
}

# 3. MANUELLE BEREINIGUNG (Dateisystem)
Write-Output "Lösche OneDrive Ordner (System & User)..."

# A. System-Ordner
Remove-Item -Path "C:\ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Program Files (x86)\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue

# B. Benutzer-Ordner (Loop durch C:\Users)
# Da wir SYSTEM sind, müssen wir in jeden User-Ordner schauen
$Users = Get-ChildItem -Path "C:\Users" -Directory
foreach ($User in $Users) {
    $OneDrivePath = "$($User.FullName)\AppData\Local\Microsoft\OneDrive"
    if (Test-Path $OneDrivePath) {
        Write-Output "   -> Lösche bei User $($User.Name)..."
        Remove-Item -Path $OneDrivePath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 4. REGISTRY BEREINIGUNG (Explorer Integration entfernen)
Write-Output "Bereinige Registry..."
$RegKeys = @(
    "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
    "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
)
foreach ($Key in $RegKeys) {
    if (Test-Path $Key) { Remove-Item -Path $Key -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------
# 3. CLIPCHAMP, BING & REMOTEHILFE
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Apps Entfernen (Clipchamp/Bing) ---"

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

foreach ($pattern in $KillPatterns) {
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern -or $_.DisplayName -like $pattern } | ForEach-Object {
        Write-Output "Entferne Appx: $($_.Name)"
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern -or $_.PackageName -like $pattern } | ForEach-Object {
        Write-Output "Entferne Provisioned: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------
# 4. GENERELLE BEREINIGUNG
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] Generelle Bereinigung ---"

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

Write-Output "Bereinigung v5 komplett."
