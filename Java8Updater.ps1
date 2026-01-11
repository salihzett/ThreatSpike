# --- KONFIGURATION ---
$downloadUrl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252627_99a6cb9582554a09bd4ac60f73f9b8e6"
$installerPath = "$env:TEMP\java_installer.exe"
$minVersion = 471 

# --- FUNKTION: ALTE JAVA VERSIONEN (32 & 64 Bit) ENTFERNEN ---
function Uninstall-OldJava {
    Write-Host "Suche nach ALLEN alten Java-Versionen (32-Bit & 64-Bit)..." -ForegroundColor Cyan

    # Wir suchen jetzt in BEIDEN Pfaden:
    # 1. Native 64-Bit Programme
    # 2. 32-Bit Programme auf 64-Bit Windows (WOW6432Node)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    $foundAny = $false

    foreach ($path in $regPaths) {
        # Einträge abrufen, Fehler unterdrücken falls Pfad nicht existiert
        $installedSoftware = Get-ItemProperty $path -ErrorAction SilentlyContinue
        
        # Filter auf "Java 8 Update"
        $javaInstalls = $installedSoftware | Where-Object { $_.DisplayName -like "Java 8 Update *" }

        foreach ($java in $javaInstalls) {
            # Versionsnummer parsen
            if ($java.DisplayName -match "Java 8 Update (\d+)") {
                $versionNumber = [int]$matches[1]

                if ($versionNumber -lt $minVersion) {
                    $foundAny = $true
                    Write-Host "Veraltete Version gefunden: $($java.DisplayName)" -ForegroundColor Yellow
                    Write-Host "   -> Pfad: $($java.PSPath)" -ForegroundColor DarkGray
                    
                    # GUID (Product Code) ermitteln
                    # Manchmal ist PSChildName die GUID, manchmal muss man sie aus dem UninstallString holen
                    $guid = $java.PSChildName
                    
                    # Fallback: Wenn der Key-Name keine GUID ist, versuchen wir sie aus dem UninstallString zu parsen
                    if ($guid -notmatch "{.*}") {
                         if ($java.UninstallString -match "{.*}") {
                            $guid = $matches[0]
                         }
                    }

                    if ($guid -match "{.*}") {
                        Write-Host "   -> Starte Deinstallation für GUID: $guid" -ForegroundColor Magenta
                        
                        # msiexec /x {GUID} /qn /norestart
                        $proc = Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -Wait -PassThru
                        
                        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 1605 -or $proc.ExitCode -eq 3010) {
                            # 0=Erfolg, 1605=War schon weg, 3010=Neustart nötig (aber erfolgreich)
                            Write-Host "   -> Deinstallation erfolgreich." -ForegroundColor Green
                        } else {
                            Write-Host "   -> FEHLER bei Deinstallation (Code $($proc.ExitCode)). Versuche es manuell." -ForegroundColor Red
                        }
                    } else {
                         Write-Host "   -> Konnte keine gültige GUID finden. Überspringe." -ForegroundColor Red
                    }
                }
            }
        }
    }

    if (-not $foundAny) {
        Write-Host "Keine veralteten Versionen unter Update $minVersion gefunden." -ForegroundColor Gray
    }
}

# --- HAUPTABLAUF ---
try {
    # 1. Alte Versionen bereinigen
    Uninstall-OldJava

    Write-Host "------------------------------------------------"
    
    # 2. Download
    Write-Host "Lade NEUES Java herunter..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
    Write-Host "Download abgeschlossen." -ForegroundColor Green

    # 3. Installieren
    Write-Host "Installiere Java (Silent)..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Java Installation erfolgreich."
