Write-Host "Suche nach ALLEN Office-Lizenzen..." -ForegroundColor Cyan

# 1. Alle Lizenzen abrufen, die "Office" im Namen haben und einen Key besitzen
$alleLizenzen = Get-CimInstance SoftwareLicensingProduct | Where-Object {$_.Name -like "*Office*" -and $_.PartialProductKey}

if ($alleLizenzen) {
    $anzahl = $alleLizenzen.Count
    Write-Host "$anzahl Lizenz(en) gefunden. Beginne Löschvorgang..." -ForegroundColor Yellow

    # 2. Schleife durch jeden gefundenen Schlüssel
    foreach ($lizenz in $alleLizenzen) {
        $key = $lizenz.PartialProductKey
        Write-Host "Entferne Schlüssel: $key ... " -NoNewline
        
        try {
            # 3. Der Befehl zum Löschen
            $lizenz | Invoke-CimMethod -MethodName UninstallProductKey | Out-Null
            Write-Host "[OK]" -ForegroundColor Green
        }
        catch {
            Write-Host "[FEHLER]" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
    Write-Host "`nBereinigung abgeschlossen." -ForegroundColor Green
}
else {
    Write-Host "Keine Office-Lizenzen gefunden. Das System ist sauber." -ForegroundColor Green
}

# Kurze Pause, damit man das Ergebnis lesen kann
Start-Sleep -Seconds 3
