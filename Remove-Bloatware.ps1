<#
.SYNOPSIS
    Entfernt Standard-Windows-Apps im System-Kontext, basierend auf einer Whitelist.
.DESCRIPTION
    Entfernt AppxPackages und ProvisionedAppxPackages.
    Ignoriert System-Frameworks und benutzerdefinierte Whitelist.
    Sicher für Ausführung via Remote-Shell / SYSTEM.
#>

# 1. DEFINITION: Apps, die behalten werden sollen (Deine Whitelist)
# Wir nutzen Regex-Pattern, um Variationen der Namen abzudecken.
$Whitelist = @(
    "Microsoft.MicrosoftEdge",        # Edge (Legacy/Stable)
    "Microsoft.Windows.Photos",       # Windows-Fotoanzeige (Modern)
    "Microsoft.Paint",                # Paint
    "Microsoft.WindowsCalculator",    # Rechner
    "Microsoft.WindowsTerminal",      # Terminal
    "Microsoft.ZuneVideo",            # Medienwiedergabe (Legacy Name)
    "Microsoft.ZuneMusic",            # Medienwiedergabe (Legacy Name)
    "Microsoft.Media.Player",         # Medienwiedergabe (Neuer Name)
    "Microsoft.RemoteDesktop",        # Remote Desktop App (Store Version)
    "Microsoft.ScreenSketch"          # Oft nützlich (Ausschneiden & Skizzieren) - optional, hier aber sicherheitshalber geprüft
)

# 2. DEFINITION: System-Kritische Komponenten (NICHT LÖSCHEN!)
# Löscht man diese, wird das Windows-Image beschädigt oder der Store geht nicht mehr.
$SystemFrameworks = @(
    "Microsoft.WindowsStore",
    "Microsoft.DesktopAppInstaller",  # Winget
    "Microsoft.Windows.Apprep.ChxApp", # SmartScreen
    "Microsoft.SecHealthUI",          # Windows Defender UI
    "Microsoft.AAD.BrokerPlugin",     # Auth
    "Microsoft.AccountsControl",      # Auth
    "Microsoft.AsyncTextService",
    "Microsoft.BioEnrollment",        # Hello
    "Microsoft.CredDialogHost",
    "Microsoft.ECApp",
    "Microsoft.LockApp",
    "Microsoft.Win32WebViewHost",
    "windows.immersivecontrolpanel",  # Settings App
    "Microsoft.UI.Xaml",              # GUI Framework
    "Microsoft.VCLibs",               # C++ Runtimes
    "Microsoft.NET.Native",           # .NET Runtimes
    "Microsoft.Services.Store.Engagement",
    "Microsoft.VP9VideoExtensions",   # Nötig für Fotos/Video
    "Microsoft.HEIFImageExtension",   # Nötig für Fotos
    "Microsoft.WebMediaExtensions",   # Nötig für Edge/Video
    "Microsoft.WebpImageExtension"    # Nötig für Fotos
)

# Kombinierte "Keep"-Liste
$KeepPatterns = $Whitelist + $SystemFrameworks

Write-Output "Starte Bereinigung im System-Kontext..."

# Holen aller installierten Pakete, die von Microsoft stammen
$Apps = Get-AppxPackage -AllUsers | Where-Object { $_.Publisher -like "*Microsoft*" }

foreach ($app in $Apps) {
    $shouldKeep = $false
    
    # Prüfen, ob App in der Keep-Liste ist
    foreach ($pattern in $KeepPatterns) {
        if ($app.Name -like "*$pattern*") {
            $shouldKeep = $true
            break
        }
    }

    if ($shouldKeep) {
        Write-Output "SKIPPING: $($app.Name) (Auf Whitelist oder System-Kritisch)"
    }
    else {
        Write-Output "REMOVING: $($app.Name)..."
        
        # 1. Entfernen für alle aktuellen Nutzer
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
            Write-Output "   -> AppxPackage entfernt."
        }
        catch {
            Write-Output "   -> Fehler beim Entfernen des AppxPackage: $($_.Exception.Message)"
        }

        # 2. Entfernen aus dem Provisioning (damit es nicht bei neuen Usern kommt)
        # Wir suchen den passenden Provisioned Namen basierend auf dem Appx Namen
        try {
            $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Name }
            if ($provisioned) {
                Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction Stop
                Write-Output "   -> Provisioned Package entfernt."
            }
        }
        catch {
            Write-Output "   -> Fehler beim Entfernen des ProvisionedPackage: $($_.Exception.Message)"
        }
    }
}

Write-Output "Bereinigung abgeschlossen."
