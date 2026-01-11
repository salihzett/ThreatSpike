# --- KONFIGURATION ---
$downloadUrl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=252627_99a6cb9582554a09bd4ac60f73f9b8e6"
$installerPath = "$env:TEMP\java_installer.exe"
$minVersion = 471 

# Liste bekannter hartnäckiger GUIDs (Hier deine genannte ID)
$targetGuids = @(
    "{77924AE4-039E-4CA4-87B4-2F32180421F0}" # Java 8 Update 421 (User/Auto-Update)
)

# --- SCHRITT 0: JAVA PROZESSE BEENDEN ---
Write-Host "Beende laufende Java-Prozesse, um Sperren zu lösen..." -ForegroundColor Yellow
Stop-Process -Name "java","javaw","jp2launcher","jqs","jusched" -Force -ErrorAction SilentlyContinue

# --- SCHRITT 1: GEZIELTE DEINSTALLATION BEKANNTER GUIDS ---
Write-Host "Führe gezielten Schlag gegen bekannte GUIDs aus..." -ForegroundColor Cyan
foreach ($id in $targetGuids) {
    Write-Host " -> Versuche harte Deinstallation von $id" -ForegroundColor Magenta
    $proc = Start-Process "msiexec.exe" -ArgumentList "/x $id /qn /norestart" -Wait -PassThru
    Write-Host "    Exit Code: $($proc.ExitCode)" -ForegroundColor Gray
}

# --- SCHRITT 2: WMI TIEFENSUCHE (LANGSAM ABER GRÜNDLICH) ---
Write-Host "Suche via WMI nach verbliebenen Java-Versionen (Das kann 1-2 Minuten dauern)..." -ForegroundColor Cyan

# Win32_Product fragt direkt die Installer-Datenbank ab (nicht nur die Registry)
$javaProducts = Get-WmiObject -Class Win32_Product | Where-Object { 
    $_.Name -like "Java 8 Update *" 
}

foreach ($app in $javaProducts) {
    if ($app.Name -match "Java 8 Update (\d+)") {
        $ver = [int]$matches[1]
        
        if ($ver -lt $minVersion) {
            Write-Host "GEFUNDEN via WMI: $($app.Name) (Version $ver)" -ForegroundColor Yellow
            Write-Host " -> Deinstalliere..." -ForegroundColor Magenta
            
            # Die Uninstall() Methode von WMI aufrufen
            try {
                $app.Uninstall() | Out-Null
                Write-Host " -> WMI Deinstallation angestoßen." -ForegroundColor Green
            } catch {
                Write-Host " -> WMI Fehler. Versuche Fallback auf msiexec..." -ForegroundColor Red
                # Fallback falls WMI-Methode klemmt
                Start-Process "msiexec.exe" -ArgumentList "/x $($app.IdentifyingNumber) /qn /norestart" -Wait
            }
        }
    }
}

# --- SCHRITT 3: DOWNLOAD & INSTALLATION ---
Write-Host "------------------------------------------------"
Write-Host "Lade NEUES Java herunter..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
    Write-Host "Download fertig. Installiere..." -ForegroundColor Cyan
    
    $process = Start-Process -FilePath $installerPath -ArgumentList "/s" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Java Installation erfolgreich." -ForegroundColor Green
    } else {
        Write-Host "Installation Exit-Code: $($process.ExitCode)" -ForegroundColor Red
    }
} catch {
    Write-Error "Download/Install Fehler: $_"
} finally {
    if (Test-Path $installerPath) { Remove-Item -Path $installerPath -Force }
}
