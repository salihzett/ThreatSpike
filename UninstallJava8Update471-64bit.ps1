# --- KONFIGURATION ---
# Wir suchen NUR im nativen 64-Bit Registry-Zweig
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"

Write-Host "Suche nach Java 8 Update 471 (NUR 64-Bit)..." -ForegroundColor Cyan

# Hole alle Programme aus dem 64-Bit Zweig, filtere nach Name
$app = Get-ItemProperty $regPath | Where-Object { 
    $_.DisplayName -like "Java 8 Update 471*64-bit*" 
}

if ($app) {
    Write-Host "Gefunden: $($app.DisplayName)" -ForegroundColor Yellow
    
    # GUID ermitteln
    $guid = $app.PSChildName
    
    if ($guid -match "{.*}") {
        Write-Host "Starte Deinstallation für $guid ..." -ForegroundColor Magenta
        
        # Silent Uninstall NUR für diese GUID
        $proc = Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -PassThru
        
        if ($proc.ExitCode -eq 0) {
            Write-Host "Java (64-Bit) wurde erfolgreich entfernt." -ForegroundColor Green
        } else {
            Write-Host "Fehler beim Entfernen. Exit-Code: $($proc.ExitCode)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Keine 64-Bit Version von Java 8 Update 471 gefunden." -ForegroundColor Gray
    Write-Host "(Die 32-Bit Version wird von diesem Skript ignoriert)." -ForegroundColor Gray
}
