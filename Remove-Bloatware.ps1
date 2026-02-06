<#
.SYNOPSIS
    All-in-One Cleaner v2: Entfernt Bloatware, Clipchamp, PowerAutomate, Update-Assistenten.
    NEU: Entfernt explizit Remotehilfe (Schnellhilfe) & Bing.
    Schützt Systemkomponenten & Whitelist.
#>

# ---------------------------------------------------------
# 1. KONFIGURATION
# ---------------------------------------------------------

# Deine Whitelist (Apps, die bleiben sollen)
$Whitelist = @(
    "Microsoft.MicrosoftEdge",        # Edge Browser
    "Microsoft.Windows.Photos",       # Fotos
    "Microsoft.Paint",                # Paint
    "Microsoft.WindowsCalculator",    # Rechner
    "Microsoft.WindowsTerminal",      # Terminal
    "Microsoft.ZuneVideo",            # Medienwiedergabe (alt)
    "Microsoft.ZuneMusic",            # Medienwiedergabe (alt)
    "Microsoft.Media.Player",         # Medienwiedergabe (neu)
    "Microsoft.RemoteDesktop",        # Remote Desktop Client (Nicht Remotehilfe!)
    "Microsoft.ScreenSketch"          # Snipping Tool
)

# System-Kritische Komponenten (Schutz vor Bootloops/Fehlern)
$SystemCritical = @(
    "Microsoft.WindowsStore",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.SecHealthUI",
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

# Apps, die ZWINGEND weg müssen (Override für Systemschutz)
$ForceRemoveKeywords = @(
    "Clipchamp", 
    "PowerAutomate", 
    "QuickAssist",      # Das ist die "Remotehilfe/Schnellhilfe" App
    "Microsoft.Bing",   # Bing Suche / News / Weather
    "BingWeather",
    "BingNews"
)

Write-Output "--- [PHASE 1] Apps & Store Bereinigung ---"

# Alle Microsoft Apps holen
$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

foreach ($app in $Apps) {
    $shouldKeep = $false
    $forceDelete = $false
    
    # 1. Check: Muss es zwingend weg?
    foreach ($keyword in $ForceRemoveKeywords) {
        if ($app.Name -like "*$keyword*") {
            $forceDelete = $true
            break
        }
    }

    # 2. Check: Ist es auf der Whitelist (nur wenn kein ForceDelete)?
    if (-not $forceDelete) {
        foreach ($pattern in ($Whitelist + $SystemCritical)) {
            if ($app.Name -like "*$pattern*") {
                $shouldKeep = $true
                break
            }
        }
    }

    if ($shouldKeep) {
        # Write-Output "SKIPPING: $($app.Name)" 
    }
    else {
        Write-Output "REMOVING Appx: $($app.Name) ..."
        
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
        } catch {
            Write-Warning "   -> Fehler beim Entfernen: $($_.Exception.Message)"
        }

        try {
            $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Name }
            if ($prov) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop
                Write-Output "   -> Provisioning entfernt."
            }
        } catch {
             Write-Warning "   -> Provisioning Fehler: $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------
# 2. SYSTEM-FEATURES (Capabilities)
# ---------------------------------------------------------
Write-Output "--- [PHASE 2] System-Features Bereinigung ---"

# Entfernt die alte "Remotehilfe" Systemkomponente, falls vorhanden
try {
    $qaCapability = Get-WindowsCapability -Online | Where-Object { $_.Name -like "*App.Support.QuickAssist*" -and $_.State -eq "Installed" }
    if ($qaCapability) {
        Write-Output "Entferne Legacy Remotehilfe (Capability)..."
        Remove-WindowsCapability -Online -Name $qaCapability.Name -ErrorAction SilentlyContinue
    }
} catch {}

# ---------------------------------------------------------
# 3. KLASSISCHE SOFTWARE (Exe/MSI)
# ---------------------------------------------------------
Write-Output "--- [PHASE 3] Update-Assistenten & MSI ---"

# Tools
$UpgradeTools = @(
    "C:\Windows10Upgrade\Windows10UpgraderApp.exe",
    "C:\Windows11InstallationAssistant\Windows11InstallationAssistant.exe"
)

foreach ($tool in $UpgradeTools) {
    if (Test-Path $tool) {
        Write-Output "Deinstalliere Tool: $tool"
        Start-Process -FilePath $tool -ArgumentList "/ForceUninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
    }
}

# Ordner
$FoldersToRemove = @(
    "C:\Windows10Upgrade",
    "C:\Windows11InstallationAssistant",
    "C:\$WINDOWS.~BT"
)
foreach ($folder in $FoldersToRemove) {
    if (Test-Path $folder) {
        Write-Output "Lösche Ordner: $folder"
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# MSI Pakete via PackageManagement
$BloatPackages = @("*Power Automate*", "*Clipchamp*", "*Update Assistant*", "*Installation Assistant*")
Get-Package -Name $BloatPackages -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Output "Deinstalliere Paket: $($_.Name)"
    Uninstall-Package -InputObject $_ -Force -ErrorAction SilentlyContinue
}

# Tasks bereinigen
Get-ScheduledTask | Where-Object { $_.TaskName -like "*UpdateAssistant*" } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

Write-Output "Bereinigung komplett."
