<#
.SYNOPSIS
    Bereinigt "tote" Office-2016-Updates, die nach der Deinstallation von Office
    weiterhin in Windows Update angeboten werden bzw. bei x % haengenbleiben.

.DESCRIPTION
    Ursache: Office 2016 (MSI) registriert sich als eigenstaendiges Produkt beim
    Windows-Installer und bei der Microsoft-Update-Erkennung. Wird Office nicht
    sauber deinstalliert (oder nur der Ordner/Verknuepfungen entfernt), bleiben
    die Produkt-Registrierungen bestehen. Windows Update erkennt das Produkt
    weiter, bietet Patches an, die Installation scheitert aber, weil die Dateien
    fehlen -> Downloads bleiben bei 14 % / 40 % / 66 % stehen.

    Das Skript arbeitet in 5 Phasen:
      1. Diagnose   - findet Office-16.0-Reste (nur lesen)
      2. Registry   - entfernt verwaiste Produkt-Registrierungen (mit Backup)
      3. Cache      - setzt SoftwareDistribution + catroot2 zurueck
      4. Ausblenden - versteckt verbliebene Office-Updates ueber die WU-API
      5. Neustart   - Dienste starten, Neuerkennung anstossen

.PARAMETER Mode
    Diagnose  = nur analysieren, nichts aendern (Standard)
    Fix       = bereinigen

.EXAMPLE
    .\Cleanup-DeadOffice2016Updates.ps1
    .\Cleanup-DeadOffice2016Updates.ps1 -Mode Fix

.NOTES
    Als Administrator ausfuehren. Danach Neustart empfohlen.
#>

[CmdletBinding()]
param(
    [ValidateSet('Diagnose','Fix')]
    [string]$Mode = 'Diagnose'
)

$ErrorActionPreference = 'Continue'
$Backup = "C:\Temp\OfficeCleanup_$(Get-Date -f yyyyMMdd_HHmmss)"

function Write-Step($t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Warn2($t){ Write-Host "  [!]    $t" -ForegroundColor Yellow }

# --- Adminrechte pruefen -----------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw "Bitte PowerShell als Administrator starten." }

Write-Host "Modus: $Mode" -ForegroundColor Magenta

# =============================================================================
# PHASE 1 - DIAGNOSE
# =============================================================================
Write-Step "Phase 1: Diagnose - Office-2016-Reste suchen"

# 1a) Noch registrierte MSI-Produkte (Office 2016 = ProductCode {90160000-....})
$msiProducts = @()
$uninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($p in $uninstallPaths) {
    $msiProducts += Get-ItemProperty $p -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like '{90160000-*' -or $_.DisplayName -match 'Office.*2016|Office 16' } |
        Select-Object PSChildName, DisplayName, DisplayVersion
}
if ($msiProducts) {
    Write-Warn2 "Registrierte Office-Produkte gefunden:"
    $msiProducts | Format-Table -AutoSize | Out-String | Write-Host
} else { Write-Ok "Keine Office-2016-Produkte in der Uninstall-Registry." }

# 1b) Office-Konfigurationsschluessel
$officeKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Office\16.0',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0',
    'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun'
) | Where-Object { Test-Path $_ }
if ($officeKeys) { $officeKeys | ForEach-Object { Write-Warn2 "Vorhanden: $_" } }
else { Write-Ok "Keine Office-16.0-Konfigurationsschluessel." }

# 1c) Verwaiste Windows-Installer-Produkte (gepackte GUIDs beginnen mit '00006190')
$installerProducts = Get-ChildItem 'HKLM:\SOFTWARE\Classes\Installer\Products' -ErrorAction SilentlyContinue |
    ForEach-Object {
        $pn = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).ProductName
        if ($pn -match 'Office|Word|Excel|PowerPoint|Outlook|Access|Publisher|OneNote|Visio|Project|Proof' -and
            $_.PSChildName -like '00006190*') {
            [pscustomobject]@{ Key = $_.PSChildName; ProductName = $pn; Path = $_.PSPath }
        }
    }
if ($installerProducts) {
    Write-Warn2 "Verwaiste Installer-Produkt-Registrierungen (Ursache der Phantom-Updates):"
    $installerProducts | Format-Table Key, ProductName -AutoSize | Out-String | Write-Host
} else { Write-Ok "Keine verwaisten Installer-Produkte." }

# 1d) Ist der Client WSUS-/Intune-verwaltet?
$wu = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
if (Test-Path $wu) {
    $srv = (Get-ItemProperty $wu -ErrorAction SilentlyContinue).WUServer
    if ($srv) { Write-Warn2 "Client ist WSUS-verwaltet ($srv). Ausblenden greift ggf. nicht - Updates muessen serverseitig abgelehnt werden." }
}
if (Get-Service -Name IntuneManagementExtension -ErrorAction SilentlyContinue) {
    Write-Warn2 "Intune Management Extension vorhanden - Zuweisungen koennen Updates zurueckholen."
}

# 1e) Aktuell angebotene Office-Updates auflisten
$pattern = 'Office 2016|Word 2016|Excel 2016|PowerPoint 2016|Outlook 2016|Access 2016|Publisher 2016|OneNote 2016|Skype for Business 2016|Visio 2016|Project 2016'
try {
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $found    = $searcher.Search("IsInstalled=0 and IsHidden=0").Updates |
                Where-Object { $_.Title -match $pattern }
    if ($found) {
        Write-Warn2 "Angebotene Office-2016-Updates:"
        $found | ForEach-Object { Write-Host "         - $($_.Title)" }
    } else { Write-Ok "Aktuell keine offenen Office-2016-Updates in der WU-Queue." }
} catch { Write-Warn2 "WU-Abfrage fehlgeschlagen: $($_.Exception.Message)" }

if ($Mode -eq 'Diagnose') {
    Write-Host "`nDiagnose beendet. Zum Bereinigen erneut mit '-Mode Fix' starten." -ForegroundColor Magenta
    return
}

# =============================================================================
# PHASE 2 - REGISTRY-RESTE ENTFERNEN (mit Backup)
# =============================================================================
Write-Step "Phase 2: Verwaiste Produkt-Registrierungen entfernen"
New-Item -ItemType Directory -Path $Backup -Force | Out-Null
Write-Host "  Backup nach: $Backup"

# 2a) Falls noch echte MSI-Produkte registriert sind: sauber deinstallieren
foreach ($prod in $msiProducts) {
    if ($prod.PSChildName -like '{90160000-*') {
        Write-Host "  msiexec /x $($prod.PSChildName) wird ausgefuehrt..."
        Start-Process msiexec.exe -ArgumentList "/x $($prod.PSChildName) /qn /norestart" -Wait -ErrorAction SilentlyContinue
    }
}

# 2b) Verwaiste Installer-Produkte + Uninstall-Keys entfernen
foreach ($ip in $installerProducts) {
    $regPath = $ip.Path -replace 'Microsoft\.PowerShell\.Core\\Registry::', ''
    & reg.exe export $regPath "$Backup\Product_$($ip.Key).reg" /y | Out-Null
    Remove-Item -Path $ip.Path -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "Entfernt: $($ip.ProductName)"
}

foreach ($u in $uninstallPaths) {
    Get-ChildItem ($u -replace '\\\*$','') -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like '{90160000-*' } |
        ForEach-Object {
            & reg.exe export ($_.Name) "$Backup\Uninstall_$($_.PSChildName).reg" /y | Out-Null
            Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Ok "Uninstall-Key entfernt: $($_.PSChildName)"
        }
}

# 2c) Office-16.0-Konfigurationsschluessel
foreach ($k in $officeKeys) {
    & reg.exe export ($k -replace 'HKLM:','HKLM') "$Backup\$(($k -split '\\')[-2])_$(($k -split '\\')[-1]).reg" /y | Out-Null
    Remove-Item $k -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "Entfernt: $k"
}

# 2d) Microsoft-Update-Opt-in fuer Office-Erkennung zuruecksetzen
$svcMgr = New-Object -ComObject Microsoft.Update.ServiceManager
$msUpdate = $svcMgr.Services | Where-Object { $_.ServiceID -eq '7971f918-a847-4430-9279-4a52d1efe18d' }
if ($msUpdate) { Write-Warn2 "Microsoft Update (Office-Erkennung) ist aktiv - Eintrag bleibt bestehen, wird aber nach der Bereinigung nichts mehr finden." }

# =============================================================================
# PHASE 3 - UPDATE-CACHE ZURUECKSETZEN
# =============================================================================
Write-Step "Phase 3: SoftwareDistribution und catroot2 zuruecksetzen"
$services = 'wuauserv','bits','cryptsvc','msiserver','usosvc'
foreach ($s in $services) { Stop-Service $s -Force -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 3

$stamp = Get-Date -f yyyyMMddHHmmss
foreach ($item in @("$env:SystemRoot\SoftwareDistribution", "$env:SystemRoot\System32\catroot2")) {
    if (Test-Path $item) {
        Rename-Item $item "$item.bak_$stamp" -Force -ErrorAction SilentlyContinue
        if ($?) { Write-Ok "Umbenannt: $item -> $item.bak_$stamp" }
        else    { Write-Warn2 "Konnte $item nicht umbenennen - loesche nur Inhalt." 
                  Remove-Item "$item\Download\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# BITS-Jobs verwerfen (die haengenden 14-%-Downloads)
& bitsadmin.exe /reset /allusers 2>&1 | Out-Null
Write-Ok "Haengende BITS-Downloads verworfen."

foreach ($s in $services) { Start-Service $s -ErrorAction SilentlyContinue }
Start-Sleep -Seconds 5

# =============================================================================
# PHASE 4 - VERBLIEBENE OFFICE-UPDATES AUSBLENDEN
# =============================================================================
Write-Step "Phase 4: Verbliebene Office-2016-Updates ausblenden"
try {
    $session  = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result   = $searcher.Search("IsInstalled=0 and IsHidden=0")
    $hidden = 0
    foreach ($upd in $result.Updates) {
        if ($upd.Title -match $pattern) {
            try { $upd.IsHidden = $true; $hidden++; Write-Ok "Ausgeblendet: $($upd.Title)" }
            catch { Write-Warn2 "Konnte nicht ausblenden: $($upd.Title)" }
        }
    }
    if ($hidden -eq 0) { Write-Ok "Nichts mehr auszublenden." }
} catch { Write-Warn2 "WU-API-Fehler: $($_.Exception.Message)" }

# =============================================================================
# PHASE 5 - NEUERKENNUNG
# =============================================================================
Write-Step "Phase 5: Neuerkennung anstossen"
& "$env:SystemRoot\System32\UsoClient.exe" StartScan 2>&1 | Out-Null
& "$env:SystemRoot\System32\wuauclt.exe" /resetauthorization /detectnow 2>&1 | Out-Null
Write-Ok "Scan angestossen."

Write-Host "`nFertig. Bitte den Rechner NEU STARTEN und danach Windows Update erneut oeffnen." -ForegroundColor Magenta
Write-Host "Backups der geloeschten Registry-Zweige: $Backup" -ForegroundColor Magenta
Write-Host "Die Ordner *.bak_$stamp koennen nach erfolgreicher Pruefung geloescht werden." -ForegroundColor DarkGray
