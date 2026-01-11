# --- KONFIGURATION ---
$downloadUrl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252627_99a6cb9582554a09bd4ac60f73f9b8e6"
$installerPath = "$env:TEMP\java_installer.exe"
$minVersion = 471 # Alle Versionen unter "Java 8 Update 471" werden gelöscht

# --- FUNKTION: ALTE JAVA VERSIONEN ENTFERNEN ---
function Uninstall-OldJava {
    Write-Host "Suche nach alten Java-Versionen (älter als Update $minVersion)..." -ForegroundColor Cyan

    # Pfad zur Registry für 64-Bit Software Deinstallationen
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    
    # Hole alle installierten Programme, filtere nach Java 8
    $installedJava = Get-ItemProperty $regPath | Where-Object { 
        $_.DisplayName -like "Java 8 Update *" 
    }

    foreach ($java in $installedJava) {
        # Extrahiere die Update-Nummer aus dem Namen (z.B. aus "Java 8 Update 211" -> "211")
        if ($java.DisplayName -match "Java 8 Update (\d+)") {
            $versionNumber = [int]$matches[1]

            # Prüfen ob Version veraltet ist
            if ($versionNumber -lt $minVersion) {
                Write-Host "Veraltete Version gefunden: $($java.DisplayName)" -ForegroundColor Yellow
                
                # Uninstall String vorbereiten (msiexec /x {GUID} /qn)
                # Wir nutzen hier direkt den UninstallString oder bauen ihn via PSChildName (was die GUID ist)
                $guid = $java.PSChildName
                
                if ($guid -match "{.*}") {
                    Write-Host "Deinstalliere $($java.DisplayName) ($guid)..." -ForegroundColor Magenta
                    
                    # Silent Uninstall Befehl
                    $proc = Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -PassThru
                    
                    if ($proc.ExitCode -eq 0) {
                        Write-Host "Deinstallation erfolgreich." -ForegroundColor Green
                    } else {
                        Write-Host "Deinstallation beendet mit Code $($proc.ExitCode)." -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "Version $($java.DisplayName) ist aktuell genug (behalten)." -ForegroundColor Gray
            }
        }
    }
}

try {
    # 1. Bereinigung starten
    Uninstall-OldJava

    Write-Host "------------------------------------------------"
    
    # 2. Neuer Download
    Write-Host "Lade neue Java Version herunter..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
    Write-Host "Download abgeschlossen." -ForegroundColor Green

    # 3. Installation
    Write-Host "Installiere neue Java Version..." -ForegroundColor Cyan
    # /s = Silent Installation
    $process = Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Java Installation erfolgreich abgeschlossen." -ForegroundColor Green
    } else {
        Write-Host "Installation fehlgeschlagen. Exit-Code: $($process.ExitCode)" -ForegroundColor Red
    }

} catch {
    Write-Error "Ein kritischer Fehler ist aufgetreten: $_"
} finally {
    # 4. Aufräumen
    if (Test-Path $installerPath) {
        Remove-Item -Path $installerPath -Force
    }
}
