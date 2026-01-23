# ====== KB5073379 Installer Script ======

# TLS 1.2 erzwingen für sichere Downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Funktion: Modul PSWindowsUpdate installieren, falls nicht vorhanden
function Ensure-PSWindowsUpdate {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Output "PSWindowsUpdate Modul wird installiert..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
    } else {
        Write-Output "PSWindowsUpdate Modul ist bereits vorhanden."
    }
}

# PSWindowsUpdate sicher importieren
function Import-PSWindowsUpdateModule {
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
    } catch {
        Write-Error "Fehler beim Importieren des Moduls PSWindowsUpdate: $_"
        exit 1
    }
}

# Prüfen, ob KB bereits installiert ist
function Install-KB {
    param([string]$KBID)

    if (Get-HotFix -Id $KBID -ErrorAction SilentlyContinue) {
        Write-Output "$KBID ist bereits installiert."
    } else {
        Write-Output "Installiere $KBID..."
        Get-WindowsUpdate -KBArticleID $KBID -Install -AcceptAll -IgnoreReboot
        Write-Output "$KBID Installation abgeschlossen."
    }
}

# ====== Hauptteil ======
Ensure-PSWindowsUpdate
Import-PSWindowsUpdateModule
Install-KB -KBID "KB5073379"

Write-Output "Script fertig."
