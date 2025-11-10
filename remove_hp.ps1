# remove_hp_fix.ps1
$LogFile = "$env:TEMP\remove_hp.log"
"Starte Deinstallation von HP Software - Log: $LogFile" | Out-File $LogFile

# Liste aller installierten Programme
$Programs = Get-WmiObject Win32_Product | Where-Object { $_.Name -match '(?i)HP|Wolf|Bromium|HP Security Update' }

if ($Programs.Count -eq 0) {
    "Keine HP/Wolf/Bromium-Produkte gefunden." | Out-File $LogFile -Append
} else {
    foreach ($p in $Programs) {
        "Deinstalliere $($p.Name)..." | Tee-Object -FilePath $LogFile -Append
        try {
            $p.Uninstall()
            Start-Sleep -Seconds 5
            "Erfolgreich deinstalliert: $($p.Name)" | Tee-Object -FilePath $LogFile -Append
        } catch {
            "Fehler beim Deinstallieren: $($p.Name) - $_" | Tee-Object -FilePath $LogFile -Append
        }
    }
}

"Deinstallation abgeschlossen." | Out-File $LogFile -Append
Write-Host "Fertig! Log-Datei: $LogFile"
