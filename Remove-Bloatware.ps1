<#
.SYNOPSIS
    All-in-One Cleaner v3:
    - Korrigiert: Clipchamp wird jetzt gefunden (Hersteller-Filter ignoriert).
    - Entfernt: Bloatware, PowerAutomate, Update-Assistenten, Bing, Remotehilfe.
    - Behält: Edge, Fotos, Paint, Rechner, Terminal, Medienwiedergabe.
#>

# ---------------------------------------------------------
# 1. DEFINITIONEN
# ---------------------------------------------------------

# Apps, die sicher bleiben sollen (Whitelist)
$Whitelist = @(
    "Microsoft.MicrosoftEdge",
    "Microsoft.Windows.Photos",
    "Microsoft.Paint",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsTerminal",
    "Microsoft.ZuneVideo",            # Medienwiedergabe (Legacy)
    "Microsoft.ZuneMusic",            # Medienwiedergabe (Legacy)
    "Microsoft.Media.Player",         # Medienwiedergabe (Neu)
    "Microsoft.RemoteDesktop",        # Remote Desktop Client Store App
    "Microsoft.ScreenSketch",         # Snipping Tool
    "Microsoft.WindowsStore",         # Store (Systemkritisch)
    "Microsoft.DesktopAppInstaller",  # Winget (Systemkritisch)
    "Microsoft.SecHealthUI"           # Defender UI (Systemkritisch)
)

# System-Komponenten, die wir keinesfalls anfassen (Verhindert Fehler)
$SystemCritical = @(
    "Microsoft.UI.Xaml",
    "Microsoft.VCLibs",
    "Microsoft.NET.Native",
    "Microsoft.WindowsAppRuntime",
    "Microsoft.Services.Store",
    "Microsoft.VP9VideoExtensions",
    "Microsoft.HEIFImageExtension",
    "Microsoft.WebMediaExtensions",
    "Microsoft.WebpImageExtension",
    "Microsoft.AAD.BrokerPlugin",
    "Microsoft.AccountsControl",
    "Microsoft.AsyncTextService",
    "Microsoft.BioEnrollment",
    "Microsoft.CredDialogHost",
    "Microsoft.ECApp",
    "Microsoft.LockApp",
    "Microsoft.Win32WebViewHost",
    "windows.immersivecontrolpanel",
    "Microsoft.Windows.StartMenuExperienceHost",
    "Microsoft.Windows.ShellExperienceHost",
    "MicrosoftWindows.Client"
)

# ---------------------------------------------------------
# 2. SPEZIAL-LÖSCHUNG: Clipchamp, Bing, Remotehilfe
# ---------------------------------------------------------
# Wir suchen diese Apps unabhängig vom Publisher ("Microsoft" oder "Clipchamp Inc")
Write-Output "--- [PHASE 1] Gezielte Löschung (Clipchamp, Bing, etc.) ---"

$KillPatterns = @("*Clipchamp*", "*PowerAutomate*", "*QuickAssist*", "*Microsoft.Bing*", "*BingWeather*", "*BingNews*")

foreach ($pattern in $KillPatterns) {
    # 1. Installierte Pakete löschen
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pattern -or $_.DisplayName -like $pattern } | ForEach-Object {
        Write-Output "KILLING: $($_.Name) ($($_.Version))"
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
    
    # 2. Aus dem Image entfernen (damit es nicht wiederkommt)
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pattern -or $_.PackageName -like $pattern } | ForEach-Object {
        Write-Output "DEPROVISIONING: $($_.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------
# 3. GENERELLE MICROSOFT BEREINIGUNG
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] Generelle Microsoft-Bloatware Bereinigung ---"

# Hier filtern wir nur nach Microsoft Publisher, um nicht Intel/Nvidia Apps zu löschen
$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

foreach ($app in $Apps) {
    $shouldKeep = $false
    
    # Prüfen ob auf Whitelist oder Systemkritisch
    foreach ($pattern in ($Whitelist + $SystemCritical)) {
        if ($app.Name -like "*$pattern*") {
            $shouldKeep = $true
            break
        }
    }

    # Wenn es Clipchamp/Bing ist, haben wir es oben schon versucht, aber sicher ist sicher: Weg damit.
    foreach ($kill in $KillPatterns) {
        if ($app.Name -like $kill) { $shouldKeep = $false }
    }

    if ($shouldKeep) {
        # Write-Output "SKIPPING: $($app.Name)"
    }
    else {
        Write-Output "REMOVING: $($app.Name) ..."
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
        } catch {
            Write-Warning "   -> Fehler: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------
# 4. KLASSISCHE SOFTWARE (EXE/MSI)
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] EXE/MSI Bereinigung ---"

# Update Assistenten
$UpgradeTools = @(
    "C:\Windows10Upgrade\Windows10UpgraderApp.exe",
    "C:\Windows11InstallationAssistant\Windows11InstallationAssistant.exe"
)
foreach ($tool in $UpgradeTools) {
    if (Test-Path $tool) {
        Write-Output "Deinstalliere Assistent: $tool"
        Start-Process -FilePath $tool -ArgumentList "/ForceUninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
}

# Ordner löschen
$Folders = @("C:\Windows10Upgrade", "C:\Windows11InstallationAssistant", "C:\$WINDOWS.~BT")
foreach ($f in $Folders) {
    if (Test-Path $f) { Remove-Item $f -Recurse -Force -ErrorAction SilentlyContinue }
}

# System-Feature Remotehilfe (Legacy Capability) entfernen
Get-WindowsCapability -Online | Where-Object {$_.Name -like "*QuickAssist*"} | Remove-WindowsCapability -Online -ErrorAction SilentlyContinue

Write-Output "Vorgang beendet."
