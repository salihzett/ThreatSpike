# --- Entfernen mit Timeout & Fallback ---
function Uninstall-WithTimeout {
    param(
        [Parameter(Mandatory=$true)] [string] $DisplayName,
        [int] $TimeoutSeconds = 300,                 # Timeout in Sekunden
        [string] $LogFile = "$env:TEMP\uninstall_log.txt"
    )

    Add-Content -Path $LogFile -Value "=== Uninstall-WithTimeout for '$DisplayName' started: $(Get-Date) ==="

    # 1) Suche UninstallString in Registry (32/64-bit)
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $uninstallEntry = $null
    foreach ($k in $keys) {
        $uninstallEntry = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.DisplayName -like "*$DisplayName*" } |
            Select-Object -First 1
        if ($uninstallEntry) { break }
    }

    if (-not $uninstallEntry) {
        Add-Content $LogFile "INFO: Kein Uninstall-Eintrag für '$DisplayName' in Registry gefunden."
    } else {
        Add-Content $LogFile "Found registry entry: DisplayName='$($uninstallEntry.DisplayName)'. UninstallString='$($uninstallEntry.UninstallString)'."
    }

    # Hilfsfunktion: starte Kommando als Prozess und warte mit Timeout
    function Start-And-Wait {
        param($exe, $args)
        try {
            $startInfo = @{
                FilePath = $exe
                ArgumentList = $args
                WorkingDirectory = [IO.Path]::GetDirectoryName($exe)
                PassThru = $true
            }
            $proc = Start-Process @startInfo
        } catch {
            Add-Content $LogFile "ERROR: Start-Process fehlgeschlagen: $_"
            return @{ Success = $false; Proc = $null }
        }

        # Warte mit Timeout
        $ok = $proc | Wait-Process -Timeout $TimeoutSeconds
        if (-not $ok) {
            Add-Content $LogFile "WARN: Prozess hat Timeout ($TimeoutSeconds s) erreicht. Versuche zu beenden (Id $($proc.Id))."
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Add-Content $LogFile "INFO: Prozess $($proc.Id) beendet."
            } catch {
                Add-Content $LogFile "ERROR: Prozess konnte nicht beendet werden: $_"
            }
            return @{ Success = $false; Proc = $proc }
        } else {
            Add-Content $LogFile "INFO: Prozess beendet innerhalb Timeout (Id $($proc.Id)). ExitCode: $($proc.ExitCode)"
            return @{ Success = $true; Proc = $proc; ExitCode = $proc.ExitCode }
        }
    }

    # 2) Wenn UninstallString existiert, parse sie
    if ($uninstallEntry -and $uninstallEntry.UninstallString) {
        $cmd = $uninstallEntry.UninstallString.Trim()
        # Manchmal ist der String in Form: "C:\path\uninstall.exe" /arg
        if ($cmd -match '^\s*"(.*?)"\s*(.*)$') {
            $exe = $matches[1]; $args = $matches[2]
        } elseif ($cmd -match '^\s*(\S+)\s*(.*)$') {
            $exe = $matches[1]; $args = $matches[2]
        } else {
            $exe = $cmd; $args = ''
        }

        Add-Content $LogFile "INFO: Starte Uninstaller: $exe $args"
        $result = Start-And-Wait -exe $exe -args $args
        if ($result.Success) {
            Add-Content $LogFile "SUCCESS: Deinstallation via UninstallString erfolgreich."
            return $true
        } else {
            Add-Content $LogFile "WARN: Deinstallation via UninstallString schlug fehl/timeout."
            # continue to fallback
        }
    }

    # 3) Fallback: versuche msiexec, falls ein ProductCode vorhanden ist
    if ($uninstallEntry -and $uninstallEntry.PSObject.Properties.Name -contains 'QuietUninstallString') {
        $msiCmd = $uninstallEntry.QuietUninstallString
        Add-Content $LogFile "INFO: Found QuietUninstallString: $msiCmd"
    }

    # Suche ProductCode via Win32_Product (nur wenn nötig; langsam)
    try {
        $prod = Get-CimInstance -ClassName Win32_Product -Filter "Name LIKE '%$DisplayName%'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($prod) {
            Add-Content $LogFile "INFO: Win32_Product gefunden: Name='$($prod.Name)', IdentifyingNumber='$($prod.IdentifyingNumber)'. Versuche msiexec /x."
            $exe = "$env:windir\system32\msiexec.exe"
            $args = "/x $($prod.IdentifyingNumber) /qn /norestart"
            $result = Start-And-Wait -exe $exe -args $args
            if ($result.Success) {
                Add-Content $LogFile "SUCCESS: MSI-Deinstallation erfolgreich."
                return $true
            } else {
                Add-Content $LogFile "WARN: MSI-Deinstallation schlug fehl/timeout."
            }
        } else {
            Add-Content $LogFile "INFO: Kein Eintrag in Win32_Product gefunden (oder Abfrage schlug fehl)."
        }
    } catch {
        Add-Content $LogFile "ERROR: Fehler beim Abfragen von Win32_Product: $_"
    }

    # 4) Letzte Option: Beende eventuell laufende HP-Prozesse, markiere als fehlgeschlagen
    # Beispiel: Prozesse, die oft hängen könnten (anpassen falls nötig)
    $possibleProcs = @('HPConnOptimizer','HPConnectionOptimizer','HpClientServices','HPCONFIG') 
    foreach ($p in $possibleProcs) {
        Get-Process -Name $p -ErrorAction SilentlyContinue | ForEach-Object {
            Add-Content $LogFile "INFO: Stoppe Prozess $($_.Name) (Id $($_.Id))."
            try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; Add-Content $LogFile "INFO: Prozess gestoppt." } catch { Add-Content $LogFile "WARN: Konnte Prozess nicht stoppen: $_" }
        }
    }

    Add-Content $LogFile "ERROR: Deinstallation von '$DisplayName' nicht erfolgreich. Ende: $(Get-Date)"
    return $false
}

# --- Beispiel-Aufruf für HP Connection Optimizer ---
Uninstall-WithTimeout -DisplayName 'HP Connection Optimizer' -TimeoutSeconds 420
