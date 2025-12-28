<#
.SYNOPSIS
    FINAL COMPLETE SCRIPT
    1. Prozesse & Dienste (Hard Kill)
    2. Scheduled Tasks (Updater entfernen)
    3. WMI / Installer DB (Fix für 'wmic' Anzeige)
    4. Uninstall Registry (Verstecken vor Asset-Tools)
    5. Filesystem (Dateien & MSOCache löschen)
    6. Spuren (Firewall, Prefetch, MSI)
    7. Startmenü & Shortcuts
    8. LibreOffice Verknüpfung
#>

# Admin Check
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "BITTE ALS ADMINISTRATOR AUSFÜHREN!"
    Start-Sleep -s 5; Exit
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   OFFICE TOTAL-ENTFERNUNG (FINAL & CLEAN)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# ==========================================
# 1. PROZESSE & DIENSTE (HARD KILL)
# ==========================================
Write-Host "`n[1/8] Beende Prozesse & Dienste..." -ForegroundColor Yellow

$services = @("ClickToRunSvc", "OfficeSvc", "ose", "osppsvc", "dcsvc", "wuauserv") 
foreach ($svc in $services) {
    if (Get-Service $svc) {
        Stop-Service $svc -Force
        if ($svc -ne "wuauserv") { & sc.exe delete $svc | Out-Null } # Dienst löschen
    }
}

$procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "mspub", "visio", "winproj", "lync", "teams", "officeclicktorun", "officec2rclient", "msiexec", "dcsvc", "wsappx")
foreach ($p in $procs) { Get-Process -Name $p | Stop-Process -Force }

# ==========================================
# 2. SCHEDULED TASKS (UPDATER KILLEN)
# ==========================================
Write-Host "[2/8] Lösche geplante Office-Aufgaben (Updater)..." -ForegroundColor Yellow
Get-ScheduledTask | Where-Object { $_.TaskName -match "Office" -or $_.TaskPath -match "Office" } | Unregister-ScheduledTask -Confirm:$false

# ==========================================
# 3. WMI / INSTALLER DB (FIX FÜR DEINEN SCREENSHOT)
# ==========================================
Write-Host "[3/8] Bereinige WMI Datenbank (Fix für 'wmic product get')..." -ForegroundColor Yellow

# A) Generische Suche in der Installer DB
$installerHives = @(
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
)
foreach ($hive in $installerHives) {
    Get-ChildItem -Path $hive | ForEach-Object {
        $prodName = (Get-ItemProperty -Path $_.PSPath -Name "ProductName").ProductName
        if ($prodName -match "Microsoft Office" -or $prodName -match "ProPlus" -or $prodName -match "DCF MUI") {
            Write-Host "  -> WMI-Eintrag entfernt: $prodName" -ForegroundColor Red
            Remove-Item -Path $_.PSPath -Recurse -Force
        }
    }
}

# B) Spezifische GUIDs aus deinem Output
$targetGUIDs = @("{90160000-0090-0407-0000-0000000FF1CE}", "{90160000-0011-0000-0000-0000000FF1CE}")
foreach ($guid in $targetGUIDs) {
    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid"
    if (Test-Path $path) { 
        Write-Host "  -> Spezifische GUID gelöscht: $guid" -ForegroundColor Red
        Remove-Item $path -Recurse -Force 
    }
}

# ==========================================
# 4. REGISTRY CLEANUP (ASSET TOOLS TARNUNG)
# ==========================================
# Das ist der Teil, den du gesucht hast!
Write-Host "[4/8] Entferne Uninstall-Einträge (Verstecken vor Asset-Tools)..." -ForegroundColor Yellow

# Uninstall Keys (Asset Management Tools schauen hier!)
$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($hive in $regKeys) {
    Get-ChildItem $hive | ForEach-Object {
        $name = (Get-ItemProperty $_.PSPath "DisplayName").DisplayName
        if ($name -match "Microsoft Office" -or $name -match "ProPlus" -or $_.PSChildName -match "0FF1CE") {
            Write-Host "  -> Uninstall-Key entfernt: $name" -ForegroundColor Red
            Remove-Item $_.PSPath -Recurse -Force
        }
    }
}

# Config Keys (HKLM & HKCU)
$deepPaths = @("HKLM:\SOFTWARE\Microsoft\Office", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office", "HKLM:\SOFTWARE\Microsoft\ClickToRun", "HKLM:\SOFTWARE\Microsoft\AppVISV", "HKCU:\Software\Microsoft\Office")
foreach ($p in $deepPaths) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }

# ==========================================
# 5. DATEISYSTEM (FILES)
# ==========================================
Write-Host "[5/8] Lösche Dateien (Program Files, MSOCache)..." -ForegroundColor Yellow

$folders = @(
    "C:\Program Files\Microsoft Office", "C:\Program Files (x86)\Microsoft Office",
    "C:\ProgramData\Microsoft\Office", "C:\Program Files\Common Files\Microsoft Shared\ClickToRun",
    "C:\Program Files\Common Files\Microsoft Shared\Office16", "C:\Program Files (x86)\Common Files\Microsoft Shared\Office16",
    "C:\MSOCache" # Wichtig!
)
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $folders += "$($_.FullName)\AppData\Local\Microsoft\Office"
    $folders += "$($_.FullName)\AppData\Roaming\Microsoft\Office"
}

foreach ($f in $folders) {
    if (Test-Path $f) { Remove-Item -Path $f -Recurse -Force; Write-Host "  -> Ordner gelöscht: $f" -ForegroundColor DarkGray }
}

# ==========================================
# 6. SPUREN (FIREWALL, PREFETCH, MSI-FILES)
# ==========================================
Write-Host "[6/8] Bereinige Spuren (Firewall, Prefetch, MSI)..." -ForegroundColor Yellow

Get-NetFirewallRule | Where-Object { $_.DisplayName -match "Microsoft Office" -or $_.DisplayName -match "Outlook" } | Remove-NetFirewallRule
Get-ChildItem "C:\Windows\Prefetch" | Where-Object { $_.Name -match "WINWORD" -or $_.Name -match "EXCEL" -or $_.Name -match "OFFICE" } | Remove-Item -Force

try {
    $installer = New-Object -ComObject WindowsInstaller.Installer
    Get-ChildItem "C:\Windows\Installer\*.msi" | ForEach-Object {
        try {
            $db = $installer.OpenDatabase($_.FullName, 0)
            $view = $db.OpenView("SELECT `Value` FROM `Property` WHERE `Property` = 'ProductName'")
            $view.Execute(); $rec = $view.Fetch()
            if ($rec -and ($rec.StringData(1) -match "Microsoft Office" -or $rec.StringData(1) -match "DCF MUI")) {
                Write-Host "  -> MSI-Datei gelöscht: $($rec.StringData(1))" -ForegroundColor Red
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
# 7. STARTMENÜ & SHORTCUTS
# ==========================================
Write-Host "[7/8] Bereinige Startmenü & Desktop..." -ForegroundColor Yellow
$lnkPaths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs", "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop")
foreach ($p in $lnkPaths) {
    if (Test-Path $p) { Get-ChildItem $p -Recurse -Include *.lnk | Where-Object { $_.Name -match "Word" -or $_.Name -match "Excel" -or $_.Name -match "Office" } | Remove-Item -Force }
}

# ==========================================
# 8. LIBREOFFICE VERKNÜPFUNG
# ==========================================
Write-Host "[8/8] Setze LibreOffice als Standard..." -ForegroundColor Yellow
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
    Stop-Process -Name "explorer" -Force
} else { Write-Host "WARNUNG: LibreOffice nicht gefunden!" -ForegroundColor Red }

Write-Host "`nBITTE NEUSTARTEN!" -ForegroundColor Cyan
