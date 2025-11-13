# ==== RustDesk Deployment Script (kostenlos, PowerShell) ====
$ErrorActionPreference = 'SilentlyContinue'
$logFile = "C:\Temp\rustdesk_config_update.log"

# ==== Server-Parameter ====
$Server = '10.134.129.91'
$Key    = '0yF7XMN688QNf9SdB8flLa4xOwbNDw2Bwyx51nhEiFE='

# ==== TOML-Inhalt ====
$toml = @"
rendezvous_server = ''
nat_type = 0
serial = 0
unlock_pin = ''
trusted_devices = ''

[options]
custom-rendezvous-server = "$Server"
key = "$Key"
approve-mode = "click"
av1-test = "N"
"@

# ==== Logging-Funktion ====
function Write-Log {
    param([string]$message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts - $message" | Out-File -Append -FilePath $logFile
}

Write-Log "==== RustDesk Deployment gestartet ===="

# ==== 1) RustDesk via Winget installieren, falls nicht vorhanden ====
if (-not (Get-Command "rustdesk.exe" -ErrorAction SilentlyContinue)) {
    Write-Log "RustDesk nicht gefunden. Installiere via Winget..."
    winget install --id RustDesk.RustDesk -e --silent
    Start-Sleep -Seconds 5
    Write-Log "RustDesk Installation abgeschlossen."
} else {
    Write-Log "RustDesk bereits installiert."
}

# ==== 2) Konfiguration für alle vorhandenen Benutzer schreiben ====
Write-Log "Schreibe Config für alle vorhandenen Benutzer..."
foreach ($userDir in Get-ChildItem 'C:\Users' -Directory) {
    if (Test-Path "$($userDir.FullName)\AppData\Roaming") {
        $configPath = "$($userDir.FullName)\AppData\Roaming\RustDesk\config\RustDesk2.toml"
        $configDir = Split-Path $configPath
        if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
        Set-Content -Path $configPath -Value $toml -Encoding UTF8
        Write-Log "Config geschrieben für Benutzer: $($userDir.Name)"
    }
}

# ==== 3) Konfiguration ins Default-Profil für neue Benutzer ====
$defaultProfile = 'C:\Users\Default\AppData\Roaming\RustDesk\config\RustDesk2.toml'
$defaultDir = Split-Path $defaultProfile
if (-not (Test-Path $defaultDir)) { New-Item -ItemType Directory -Path $defaultDir -Force | Out-Null }
Set-Content -Path $defaultProfile -Value $toml -Encoding UTF8
Write-Log "Config ins Default-Profil geschrieben für zukünftige Benutzer."

Write-Log "==== RustDesk Deployment abgeschlossen ===="
Write-Output "RustDesk Deployment und Konfiguration abgeschlossen. Log: $logFile"
