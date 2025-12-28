<#
.SYNOPSIS
    ULTIMATE OFFICE REMOVER & LIBREOFFICE SETUP
    - Entfernt Office Dateien (ProPlus, Standard, 2016, 365)
    - Bereinigt WMI / Installer Database (gegen "wmic product get" Leichen)
    - Löscht Registry Spuren (Uninstall Keys)
    - Setzt LibreOffice als Standard
#>

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ACHTUNG: Bitte als ADMINISTRATOR ausführen!"
    Start-Sleep -s 5; Exit
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   ULTIMATE OFFICE CLEANER & LIBREOFFICE ASSIGNMENT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ==========================================
# PHASE 1: PROZESSE & DIENSTE KILLEN
# ==========================================
Write-Host "`n[1/8] Beende Prozesse und lösche Dienste..." -ForegroundColor Yellow

# Dienste hart löschen (sc delete)
$services = @("ClickToRunSvc", "OfficeSvc", "ose", "osppsvc", "dcsvc")
foreach ($svc in $services) {
    if (Get-Service $svc) {
        Stop-Service $svc -Force
        & sc.exe delete $svc | Out-Null
        Write-Host "  -> Dienst gelöscht: $svc" -ForegroundColor DarkGray
    }
}

# Prozesse beenden
$procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "mspub", "visio", "winproj", "lync", "teams", "officeclicktorun", "officec2rclient", "msiexec")
foreach ($p in $procs) { Get-Process -Name $p | Stop-Process -Force }

# ==========================================
# PHASE 2: DATEISYSTEM BEREINIGUNG
# ==========================================
Write-Host "[2/8] Lösche Dateisystem (Program Files, AppData, MSOCache)..." -ForegroundColor Yellow

$folders = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "C:\ProgramData\Microsoft\Office",
    "C:\Program Files\Common Files\Microsoft Shared\ClickToRun",
    "C:\Program Files\Common Files\Microsoft Shared\Office16",
    "C:\Program Files (x86)\Common Files\Microsoft Shared\Office16",
    "C:\MSOCache" # Installations-Cache
)
# User AppData hinzufügen
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $folders += "$($_.FullName)\AppData\Local\Microsoft\Office"
    $folders += "$($_.FullName)\AppData\Roaming\Microsoft\Office"
}

foreach ($f in $folders) {
    if (Test-Path $f) {
        Remove-Item -Path $f -Recurse -Force
        Write-Host "  -> Gelöscht: $f" -ForegroundColor DarkGray
    }
}

# ==========================================
# PHASE 3: UNINSTALL KEYS (Standard Registry)
# ==========================================
Write-Host "[3/8] Bereinige Standard 'Programme und Features' Liste..." -ForegroundColor Yellow
$uninstallHives = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($hive in $uninstallHives) {
    Get-ChildItem $hive | ForEach-Object {
        $name = (Get-ItemProperty $_.PSPath "DisplayName").DisplayName
        if ($name -match "Microsoft Office" -or $name -match "ProPlus" -or $_.PSChildName -match "0FF1CE") {
            Write-Host "  -> Entferne Key: $name" -ForegroundColor Red
            Remove-Item $_.PSPath -Recurse -Force
        }
    }
}

# ==========================================
# PHASE 4: WMI / INSTALLER DATENBANK (Der wichtige Teil!)
# ==========================================
Write-Host "[4/8] Bereinige WMI Installer Datenbank (Fix für WMIC)..." -ForegroundColor Yellow

# Hier verstecken sich die Einträge, die "wmic product get" anzeigt
$installerHives = @(
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
)

foreach ($hive in $installerHives) {
    $keys = Get-ChildItem -Path $hive
    foreach ($key in $keys) {
        $prodName = (Get-ItemProperty -Path $key.PSPath -Name "ProductName").ProductName
        
        # Filter: Office, ProPlus, DCF MUI
        if ($prodName -match "Microsoft Office" -or $prodName -match "ProPlus" -or $prodName -match "DCF MUI") {
            Write-Host "  -> WMI-Eintrag entfernt: $prodName" -ForegroundColor Magenta
            Remove-Item -Path $key.PSPath -Recurse -Force
        }
    }
}

# ==========================================
# PHASE 5: TIEFENREINIGUNG (Configs & Spuren)
# ==========================================
Write-Host "[5/8] Lösche Configs, Firewall-Regeln & MSI-Dateien..." -ForegroundColor Yellow

# Registry Configs
$deepPaths = @("HKLM:\SOFTWARE\Microsoft\Office", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office", "HKLM:\SOFTWARE\Microsoft\ClickToRun")
foreach ($p in $deepPaths) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }

# Firewall
Get-NetFirewallRule | Where-Object { $_.DisplayName -match "Microsoft Office" -or $_.DisplayName -match "Outlook" } | Remove-NetFirewallRule

# MSI Cache Dateien (in C:\Windows\Installer)
try {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    Get-ChildItem "C:\Windows\Installer\*.msi" | ForEach-Object {
        try {
            $db = $installer.OpenDatabase($_.FullName, 0)
            $view = $db.OpenView("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductName'")
            $view.Execute(); $rec = $view.Fetch()
            if ($rec -and ($rec.StringData(1) -match "Microsoft Office" -or $rec.StringData(1) -match "DCF MUI")) {
                Write-Host "  -> MSI-Cache gelöscht: $($rec.StringData(1))" -ForegroundColor Red
                $view.Close(); [System.Runtime.Interopservices.Marshal]::ReleaseComObject($rec)|Out-Null
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($db)|Out-Null
                Remove-Item $_.FullName -Force
            } else {
                if ($view) { $view.Close(); [System.Runtime.Interopservices.Marshal]::ReleaseComObject($view)|Out-Null }
                if ($db) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($db)|Out-Null }
            }
        } catch {}
    }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer)|Out-Null
} catch {}

# ==========================================
# PHASE 6: SHORTCUTS
# ==========================================
Write-Host "[6/8] Bereinige Startmenü..." -ForegroundColor Yellow
$lnkPaths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs")
foreach ($p in $lnkPaths) {
    Get-ChildItem $p -Recurse -Include *.lnk | Where-Object { $_.Name -match "Word" -or $_.Name -match "Excel" -or $_.Name -match "Office" } | Remove-Item -Force
}

# ==========================================
# PHASE 7: LIBREOFFICE ASSIGNMENT
# ==========================================
Write-Host "[7/8] Setze LibreOffice als Standard..." -ForegroundColor Yellow
$loBase = $null
if (Test-Path "C:\Program Files\LibreOffice\program\soffice.exe") { $loBase = "C:\Program Files\LibreOffice\program" }
elseif (Test-Path "C:\Program Files (x86)\LibreOffice\program\soffice.exe") { $loBase = "C:\Program Files (x86)\LibreOffice\program" }

if ($loBase) {
    $wr = "$loBase\swriter.exe"; $ca = "$loBase\scalc.exe"; $im = "$loBase\simpress.exe"
    
    function Set-LO ($ext, $pid, $exe) {
        New-Item "HKLM:\SOFTWARE\Classes\$ext" -Force | Out-Null
        Set-ItemProperty "HKLM:\SOFTWARE\Classes\$ext" -Name "(Default)" -Value $pid
        $cmd = "HKLM:\SOFTWARE\Classes\$pid\shell\open\command"
        if (!(Test-Path $cmd)) { New-Item $cmd -Force -Recurse | Out-Null }
        Set-ItemProperty $cmd -Name "(Default)" -Value "`"$exe`" -o `"%1`""
        Write-Host "  -> Verknüpft: $ext" -ForegroundColor Green
    }
    
    Set-LO ".docx" "LibreOffice.Docx" $wr; Set-LO ".doc" "LibreOffice.Doc" $wr
    Set-LO ".xlsx" "LibreOffice.Xlsx" $ca; Set-LO ".xls" "LibreOffice.Xls" $ca
    Set-LO ".pptx" "LibreOffice.Pptx" $im
    Stop-Process -Name "explorer" -Force # Refresh Icons
} else {
    Write-Host "WARNUNG: LibreOffice nicht gefunden." -ForegroundColor Red
}

# ==========================================
# PHASE 8: FINAL CHECK
# ==========================================
Write-Host "`n[8/8] Abschlussprüfung (WMIC Check)..." -ForegroundColor Yellow
$wmiCheck = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -match "Microsoft Office" -or $_.Name -match "ProPlus" }

if ($wmiCheck) {
    Write-Host "ACHTUNG: Es wurden noch Reste gefunden:" -ForegroundColor Red
    $wmiCheck | Select-Object Name, IdentifyingNumber
} else {
    Write-Host "ERFOLG: Keine Office-Produkte mehr in WMI/Registry gefunden." -ForegroundColor Green
    Write-Host "Das System ist sauber." -ForegroundColor Green
}

Write-Host "`nBITTE NEUSTARTEN!" -ForegroundColor Cyan
