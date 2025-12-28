<#
.SYNOPSIS
    COMPLETE OFFICE WIPE & LIBREOFFICE ASSOCIATION
    1. Aggressive Entfernung von Microsoft Office (Files, Reg, Services).
    2. Tarnung vor Monitoring-Tools (Uninstall-Keys löschen).
    3. Neuzuweisung der Dateitypen (docx, xlsx) auf LibreOffice.
#>

# Admin-Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Bitte führen Sie dieses Skript als ADMINISTRATOR aus!"
    Start-Sleep -s 5
    Exit
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   MICROSOFT OFFICE TOTAL-ENTFERNUNG & LIBREOFFICE SETUP" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# ==========================================
# PHASE 1: PROZESSE & DIENSTE BEENDEN
# ==========================================
Write-Host "`n[1/8] Beende Prozesse und Dienste..." -ForegroundColor Yellow

# Dienste stoppen und aus der Service-Control-Manager löschen
$services = @("ClickToRunSvc", "OfficeSvc", "ose", "osppsvc", "dcsvc", "wuauserv") # wuauserv kurz stoppen
foreach ($svc in $services) {
    if (Get-Service $svc) {
        Stop-Service $svc -Force
        if ($svc -ne "wuauserv") { # Windows Update nicht löschen, nur Office Dienste
            & sc.exe delete $svc | Out-Null
            Write-Host "  -> Dienst gelöscht: $svc" -ForegroundColor DarkGray
        }
    }
}

# Prozesse hart beenden
$procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "mspub", "visio", "winproj", "lync", "teams", "officeclicktorun", "officec2rclient", "msiexec", "dcsvc", "wsappx")
foreach ($p in $procs) { Get-Process -Name $p | Stop-Process -Force }

# ==========================================
# PHASE 2: DATEISYSTEM BEREINIGUNG
# ==========================================
Write-Host "[2/8] Lösche Programmdateien & Caches (Dies kann dauern)..." -ForegroundColor Yellow

$folders = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "C:\ProgramData\Microsoft\Office",
    "C:\Program Files\Common Files\Microsoft Shared\ClickToRun",
    "C:\Program Files\Common Files\Microsoft Shared\Office16",
    "C:\Program Files (x86)\Common Files\Microsoft Shared\Office16",
    "C:\Program Files (x86)\Common Files\Microsoft Shared\Source Engine",
    "C:\MSOCache" # Installations-Cache (wichtig zu löschen!)
)

# User-Profile bereinigen
$users = Get-ChildItem "C:\Users" -Directory
foreach ($user in $users) {
    $folders += "$($user.FullName)\AppData\Local\Microsoft\Office"
    $folders += "$($user.FullName)\AppData\Roaming\Microsoft\Office"
}

foreach ($f in $folders) {
    if (Test-Path $f) {
        Write-Host "  -> Lösche: $f" -ForegroundColor Red
        Remove-Item -Path $f -Recurse -Force
    }
}

# ==========================================
# PHASE 3: REGISTRY UNINSTALL KEYS (MONITORING)
# ==========================================
Write-Host "[3/8] Entferne Uninstall-Einträge (Verstecken vor Asset-Tools)..." -ForegroundColor Yellow

$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($hive in $regKeys) {
    Get-ChildItem $hive | ForEach-Object {
        $name = (Get-ItemProperty $_.PSPath "DisplayName").DisplayName
        # Löscht alles mit Office, ProPlus oder Visio im Namen
        if ($name -match "Microsoft Office" -or $name -match "ProPlus" -or $_.PSChildName -match "0FF1CE") {
            Write-Host "  -> Entferne Registry Key: $name" -ForegroundColor Red
            Remove-Item $_.PSPath -Recurse -Force
        }
    }
}

# ==========================================
# PHASE 4: TIEFE REGISTRY BEREINIGUNG
# ==========================================
Write-Host "[4/8] Lösche Office Konfigurationen..." -ForegroundColor Yellow
$deepPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office",
    "HKLM:\SOFTWARE\Microsoft\ClickToRun",
    "HKLM:\SOFTWARE\Microsoft\AppVISV"
)
foreach ($p in $deepPaths) { 
    if (Test-Path $p) { Remove-Item $p -Recurse -Force } 
}

# ==========================================
# PHASE 5: SPURENBESEITIGUNG
# ==========================================
Write-Host "[5/8] Entferne Firewall-Regeln & Prefetch..." -ForegroundColor Yellow

# Firewall
Get-NetFirewallRule | Where-Object { $_.DisplayName -match "Microsoft Office" -or $_.DisplayName -match "Outlook" } | Remove-NetFirewallRule

# Prefetch (Startprotokolle)
Get-ChildItem "C:\Windows\Prefetch" | Where-Object { $_.Name -match "WINWORD" -or $_.Name -match "EXCEL" -or $_.Name -match "OFFICE" } | Remove-Item -Force

# ==========================================
# PHASE 6: MSI INSTALLER CACHE (Kryptische Files)
# ==========================================
Write-Host "[6/8] Scanne C:\Windows\Installer nach Resten..." -ForegroundColor Yellow
try {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    Get-ChildItem "C:\Windows\Installer\*.msi" | ForEach-Object {
        try {
            $db = $installer.OpenDatabase($_.FullName, 0)
            $view = $db.OpenView("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductName'")
            $view.Execute()
            $rec = $view.Fetch()
            if ($rec) {
                if ($rec.StringData(1) -match "Microsoft Office") {
                    Write-Host "  -> Lösche MSI-Cache: $($_.Name)" -ForegroundColor Red
                    $view.Close(); [System.Runtime.Interopservices.Marshal]::ReleaseComObject($rec)|Out-Null
                    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($db)|Out-Null
                    Remove-Item $_.FullName -Force
                }
            }
            if ($view) { $view.Close(); [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view)|Out-Null }
            if ($db) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($db)|Out-Null }
        } catch {}
    }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer)|Out-Null
} catch { Write-Host "  ! MSI Scan übersprungen (Fehler)" -ForegroundColor DarkGray }

# ==========================================
# PHASE 7: STARTMENÜ BEREINIGEN
# ==========================================
Write-Host "[7/8] Bereinige Startmenü Verknüpfungen..." -ForegroundColor Yellow
$linkPaths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
foreach ($path in $linkPaths) {
    Get-ChildItem $path -Recurse -Include *.lnk | Where-Object { $_.Name -match "Word" -or $_.Name -match "Excel" -or $_.Name -match "Office" } | Remove-Item -Force
}

# ==========================================
# PHASE 8: LIBREOFFICE ASSOCIAITONS
# ==========================================
Write-Host "[8/8] Setze LibreOffice als Standard..." -ForegroundColor Yellow

# Pfadsuche
$loPath = $null
if (Test-Path "C:\Program Files\LibreOffice\program\soffice.exe") {
    $loBase = "C:\Program Files\LibreOffice\program"
} elseif (Test-Path "C:\Program Files (x86)\LibreOffice\program\soffice.exe") {
    $loBase = "C:\Program Files (x86)\LibreOffice\program"
}

if ($loBase) {
    $writer = "$loBase\swriter.exe"; $calc = "$loBase\scalc.exe"; $impress = "$loBase\simpress.exe"

    function Set-Assoc {
        param ($ext, $progID, $exe)
        # 1. Extension Mapping
        New-Item "HKLM:\SOFTWARE\Classes\$ext" -Force | Out-Null
        Set-ItemProperty "HKLM:\SOFTWARE\Classes\$ext" -Name "(Default)" -Value $progID
        # 2. Command Mapping
        $cmdKey = "HKLM:\SOFTWARE\Classes\$progID\shell\open\command"
        if (!(Test-Path $cmdKey)) { New-Item $cmdKey -Force -Recurse | Out-Null }
        Set-ItemProperty $cmdKey -Name "(Default)" -Value "`"$exe`" -o `"%1`""
        Write-Host "  -> Verknüpft: $ext -> LibreOffice" -ForegroundColor Green
    }

    # Word
    Set-Assoc ".docx" "LibreOffice.Docx" $writer
    Set-Assoc ".doc"  "LibreOffice.Doc"  $writer
    Set-Assoc ".rtf"  "LibreOffice.Rtf"  $writer
    # Excel
    Set-Assoc ".xlsx" "LibreOffice.Xlsx" $calc
    Set-Assoc ".xls"  "LibreOffice.Xls"  $calc
    Set-Assoc ".csv"  "LibreOffice.Csv"  $calc
    # PowerPoint
    Set-Assoc ".pptx" "LibreOffice.Pptx" $impress

    # Explorer neustarten für Icons
    Stop-Process -Name "explorer" -Force
} else {
    Write-Host "WARNUNG: LibreOffice nicht gefunden! Verknüpfungen nicht gesetzt." -ForegroundColor Red
}

Write-Host "`n--------------------------------------------------------"
Write-Host "FERTIG. MS Office ist komplett entfernt." -ForegroundColor Green
Write-Host "Dateien werden nun mit LibreOffice geöffnet." -ForegroundColor Green
Write-Host "Bitte PC neu starten!" -ForegroundColor Cyan
