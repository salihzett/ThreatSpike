# URL der Java-Installationsdatei (vom Benutzer bereitgestellt)
$url = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252627_99a6cb9582554a09bd4ac60f73f9b8e6"

# Speicherort für den Download (Temporärer Ordner)
$installerPath = "$env:TEMP\java_installer.exe"

try {
    # 1. Herunterladen
    Write-Host "Lade Java Installer herunter..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $installerPath
    Write-Host "Download abgeschlossen." -ForegroundColor Green

    # 2. Silent Installation
    # Das Argument "/s" steht bei Oracle Java Installern für "Silent"
    Write-Host "Starte die Silent-Installation..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait -PassThru
    
    # Überprüfung des Exit-Codes (0 bedeutet meist Erfolg)
    if ($process.ExitCode -eq 0) {
        Write-Host "Java wurde erfolgreich installiert." -ForegroundColor Green
    } else {
        Write-Host "Installation beendet mit Exit-Code: $($process.ExitCode)" -ForegroundColor Yellow
    }

} catch {
    Write-Error "Ein Fehler ist aufgetreten: $_"
} finally {
    # 3. Aufräumen (Löschen der Installationsdatei)
    if (Test-Path $installerPath) {
        Write-Host "Lösche temporäre Installationsdatei..." -ForegroundColor Gray
        Remove-Item -Path $installerPath -Force
    }
}
