# UpgradeTo26H2-Auto.ps1
# Check if system is ready for upgrade, download and install the package

Write-Host "`n=== Windows 11 26H2 Auto-Upgrade Tool ===`n"

# 1. Prüfen ob die korrekte Basis-Version (z.B. 25H2) installiert ist
$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
if ($os.DisplayVersion -ne "25H2") {
    Write-Warning "System ist nicht 25H2 - Upgrade via Enablement-Package wird abgebrochen."
    exit 1
}

Write-Host "[OK] Windows 11 25H2 gefunden."

# 2. Mögliche URLs definieren (x64 / ARM64) 
# HINWEIS: KB-Nummern prüfen und durch die korrekten 26H2-Links ersetzen!
$urls = @(
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/94520a88-858f-4832-a57d-7211f6d84a4e/public/Windows11.0-KB5121794-x64_5e20a3cce48d6611b16bdec42b07167f5456586a.msu",
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/9d8dc3d0-9cbf-4eb1-9411-722e3e6a19b3/public/Windows11.0-KB5121794-arm64_77a76caf2d362bb293a4d18058388f2717365abe.msu"
)

# 3. Prüfen & Download
$downloaded = $false
foreach ($url in $urls) {
    Write-Host "Prüfe URL: $url"
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            Write-Host "[OK] Paket gefunden. Download startet..."
            $out = "$env:TEMP\$(Split-Path $url -Leaf)"
            Invoke-WebRequest -Uri $url -OutFile $out -ErrorAction Stop
            $downloaded = $true
            break
        } else {
            Write-Host "[X] Kein Zugriff (HTTP $($resp.StatusCode))"
        }
    } catch {
        Write-Warning "[!] Fehler beim Zugriff auf die URL: $($_.Exception.Message)"
    }
}

if (-not $downloaded) {
    Write-Warning "Kein passendes Enablement-Package gefunden. Skript wird beendet."
    exit 1
}

# 4. Installation mit Exit-Code-Prüfung
Write-Host "[*] Starte Installation..."
$process = Start-Process "wusa.exe" -ArgumentList "`"$out`" /quiet /norestart" -Wait -PassThru

# Exit Code 0 = Erfolgreich, 3010 = Erfolgreich, aber Neustart erforderlich
if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
    Write-Host "`n[OK] Installation abgeschlossen (Exit Code: $($process.ExitCode)). Neustart erforderlich."
    # Restart-Computer -Force
} else {
    Write-Warning "`n[X] Installation fehlgeschlagen! wusa.exe meldet Exit Code: $($process.ExitCode)"
}
