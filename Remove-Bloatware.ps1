<#
.SYNOPSIS
    Entfernt Microsoft Bloatware inkl. Power Automate, schützt Systemkerne.
    Läuft im System-Context.
#>

# 1. Whitelist: Diese Apps behalten wir (deine Liste)
$Whitelist = @(
    "Microsoft.MicrosoftEdge",        # Edge
    "Microsoft.Windows.Photos",       # Fotoanzeige
    "Microsoft.Paint",                # Paint
    "Microsoft.WindowsCalculator",    # Rechner
    "Microsoft.WindowsTerminal",      # Terminal
    "Microsoft.ZuneVideo",            # Medienwiedergabe (alt)
    "Microsoft.ZuneMusic",            # Medienwiedergabe (alt)
    "Microsoft.Media.Player",         # Medienwiedergabe (neu)
    "Microsoft.RemoteDesktop",        # Remote Desktop
    "Microsoft.ScreenSketch"          # Snipping Tool (optional, oft gewünscht)
)

# 2. System-Frameworks (WICHTIG: Nicht löschen, sonst Fehler im Log)
# Hier fügen wir auch Runtimes hinzu, die im Fehlerlog Probleme machten.
$SystemCritical = @(
    "Microsoft.WindowsStore",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.SecHealthUI",          # Defender Interface
    "Microsoft.UI.Xaml",              # GUI Framework
    "Microsoft.VCLibs",               # C++ Runtimes
    "Microsoft.NET.Native",           # .NET Runtimes
    "Microsoft.WindowsAppRuntime",    # Verursachte Fehler 0x80073CF3
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
    "Microsoft.Windows.StartMenuExperienceHost", # Verursachte Fehler
    "Microsoft.Windows.ContentDeliveryManager",  # Verursachte Fehler
    "MicrosoftWindows.Client"                    # Kern-Systemkomponenten
)

Write-Output "--- Starte optimierte Bereinigung ---"

# Wir holen alle Microsoft Apps, filtern aber sofort die "Nicht entfernbaren" System-Apps heraus
$Apps = Get-AppxPackage -AllUsers | Where-Object { 
    $_.Publisher -like "*Microsoft*" -and 
    $_.NonRemovable -eq $false -and 
    $_.SignatureKind -ne "System"
}

foreach ($app in $Apps) {
    $shouldKeep = $false
    
    # Prüfen auf Whitelist & Systemkritisch
    foreach ($pattern in ($Whitelist + $SystemCritical)) {
        if ($app.Name -like "*$pattern*") {
            $shouldKeep = $true
            break
        }
    }

    if ($shouldKeep) {
        # Optional: Kommentar entfernen, wenn du sehen willst, was behalten wird
        # Write-Output "SKIPPING: $($app.Name)"
    }
    else {
        Write-Output "REMOVING: $($app.Name) ..."
        
        # PowerAutomate Check: Manchmal heißt es "Flow" oder "PowerAutomateDesktop"
        
        try {
            # 1. Entfernen (Versuch)
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
            Write-Output "   [OK] AppxPackage entfernt."
        }
        catch {
            # Fehler ignorieren, wenn App gerade offen ist oder vom System gesperrt
            Write-Warning "   [!] Konnte App nicht entfernen: $($_.Exception.Message)"
        }

        # 2. Provisioning entfernen
        try {
            $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Name }
            if ($prov) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop
                Write-Output "   [OK] Provisioning entfernt."
            }
        }
        catch {
             Write-Warning "   [!] Provisioning Fehler: $($_.Exception.Message)"
        }
    }
}

Write-Output "--- Fertig ---"
