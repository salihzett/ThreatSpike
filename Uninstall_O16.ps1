<#
.SYNOPSIS
    FINAL ULTIMATE CLEANER (NO WMIC DEPENDENCY) - COMBINED
    Dieses Skript entfernt Office (ProPlus/2016/365) sowie alle zugehörigen Lizenzschlüssel vollständig.
    Es repariert die Registry-Datenbank, damit Inventarisierungs-Tools nichts mehr finden.
#>

# 0. ADMINISTRATOR CHECK
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ACHTUNG: Bitte Rechtsklick -> 'Mit PowerShell als Administrator ausführen'!"
    Start-Sleep -s 5
    Exit
}

$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   OFFICE TOTAL-ENTFERNUNG & LIZENZ-CLEANUP (FINAL VERSION)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# ==========================================
# 1. PROZESSE & DIENSTE (HARD KILL)
# ==========================================
Write-Host "`n[1/9] Beende Prozesse & Dienste..." -ForegroundColor Yellow

$services = @("ClickToRunSvc", "OfficeSvc", "ose", "osppsvc", "dcsvc") 
foreach ($svc in $services) {
    if (Get-Service $svc) {
        Stop-Service $svc -Force
        & sc.exe delete $svc | Out-Null # Dienst aus Windows entfernen
        Write-Host "  -> Dienst gelöscht: $svc" -ForegroundColor DarkGray
    }
}

$procs = @("winword", "excel", "powerpnt", "outlook", "onenote", "msaccess", "mspub", "visio", "winproj", "lync", "teams", "officeclicktorun", "officec2rclient", "msiexec", "dcsvc", "wsappx")
foreach ($p in $procs) { Get-Process -Name $p | Stop-Process -Force }

# ==========================================
# 2. LIZENZSCHLÜSSEL ENTFERNEN
# ==========================================
Write-Host "`n[2/9] Suche nach ALLEN Office-Lizenzen..." -ForegroundColor Yellow

$alleLizenzen = Get-CimInstance SoftwareLicensingProduct | Where-Object {$_.Name -like "*Office*" -and $_.PartialProductKey}

if ($alleLizenzen) {
    $anzahl = $alleLizenzen.Count
    Write-Host "  -> $anzahl Lizenz(en) gefunden. Beginne Löschvorgang..." -ForegroundColor Cyan

    foreach ($lizenz in $alleLizenzen) {
        $key = $lizenz.PartialProductKey
        Write-Host "  -> Entferne Schlüssel: $key ... " -NoNewline
        
        try {
            $lizenz | Invoke-CimMethod -MethodName UninstallProductKey | Out-Null
            Write-Host "[OK]" -ForegroundColor Green
        }
        catch {
            Write-Host "[FEHLER]" -ForegroundColor Red
            Write-Host $_.Exception.Message
        }
    }
    Write-Host "  -> Lizenz-Bereinigung abgeschlossen." -ForegroundColor Green
}
else {
    Write-Host "  -> Keine Office-Lizenzen gefunden. Dieser Bereich ist sauber." -ForegroundColor Green
}

# ==========================================
# 3. SCHEDULED TASKS (UPDATER KILLEN)
# ==========================================
Write-Host "`n[3/9] Lösche geplante Office-Aufgaben (Updater)..." -ForegroundColor Yellow
Get-ScheduledTask | Where-Object { $_.TaskName -match "Office" -or $_.TaskPath -match "Office" } | Unregister-ScheduledTask -Confirm:$false

# ==========================================
# 4. WMI / INSTALLER DATENBANK BEREINIGEN
# ==========================================
Write-Host "`n[4/9] Bereinige interne Installations-Datenbank..." -ForegroundColor Yellow

$targetGUIDs = @(
    "{90160000-0090-0407-0000-0000000FF1CE}", # DCF MUI
    "{90160000-0011-0000-0000-0000000FF1CE}"  # Pro Plus 2016
)

foreach ($guid in $targetGUIDs) {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$guid"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Write-Host "  -> TARGET GUID GEFUNDEN & GELÖSCHT: $guid" -ForegroundColor Red
            Remove-Item $p -Recurse -Force
        }
    }
}

$installerHives = @(
    "HKLM:\SOFTWARE\Classes\Installer\Products",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products"
)
foreach ($hive in $installerHives) {
    Get-ChildItem -Path $hive | ForEach-Object {
        $prodName = (Get-ItemProperty -Path $_.PSPath -Name "ProductName").ProductName
        if ($prodName -match "Microsoft Office" -or $prodName -match "ProPlus" -or $prodName -match "DCF MUI") {
            Write-Host "  -> Verwaisten Installer-Key entfernt: $prodName" -ForegroundColor Magenta
            Remove-Item -Path $_.PSPath -Recurse -Force
        }
    }
}

# ==========================================
# 5. REGISTRY CLEANUP (ASSET TOOLS TARNUNG)
# ==========================================
Write-Host "`n[5/9] Entferne Einträge aus 'Programme und Features'..." -ForegroundColor Yellow

$regKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($hive in $regKeys) {
    Get-ChildItem $hive | ForEach-Object {
        $name = (Get-ItemProperty $_.PSPath "DisplayName").DisplayName
        if ($name -match "Microsoft Office" -or $name -match "ProPlus" -or $_.PSChildName -match "0FF1CE") {
            Write-Host "  -> Eintrag entfernt: $name" -ForegroundColor Red
            Remove-Item $_.PSPath -Recurse -Force
        }
    }
}

$deepPaths = @("HKLM:\SOFTWARE\Microsoft\Office", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office", "HKLM:\SOFTWARE\Microsoft\ClickToRun", "HKLM:\SOFTWARE\Microsoft\AppVISV", "HKCU:\Software\Microsoft\Office")
foreach ($p in $deepPaths) { if (Test-Path $p) { Remove-Item $p -Recurse -Force } }

# ==========================================
# 6. DATEISYSTEM (FILES)
# ==========================================
Write-Host "`n[6/9] Lösche Dateien (Program Files, MSOCache)..." -ForegroundColor Yellow

$folders = @(
    "C:\Program Files\Microsoft Office", "C:\Program Files (x86)\Microsoft Office",
    "C:\ProgramData\Microsoft\Office", "C:\Program Files\Common Files\Microsoft Shared\ClickToRun",
    "C:\Program Files\Common Files\Microsoft Shared\Office16", "C:\Program Files (x86)\Common Files\Microsoft Shared\Office16",
    "C:\MSOCache" 
)
Get-ChildItem "C:\Users" -Directory | ForEach-Object {
    $folders += "$($_.FullName)\AppData\Local\Microsoft\Office"
    $folders += "$($_.FullName)\AppData\Roaming\Microsoft\Office"
}

foreach ($f in $folders) {
    if (Test-Path $f) { Remove-Item -Path $f -Recurse -Force; Write-Host "  -> Ordner gelöscht: $f" -ForegroundColor DarkGray }
}

# ==========================================
# 7. SPUREN (FIREWALL, PREFETCH, MSI-FILES)
# ==========================================
Write-Host "`n[7/9] Bereinige Spuren (Firewall, Prefetch, MSI)..." -ForegroundColor Yellow

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
# 8. STARTMENÜ & SHORTCUTS
# ==========================================
Write-Host "`n[8/9] Bereinige Startmenü & Desktop..." -ForegroundColor Yellow
$lnkPaths = @("C:\ProgramData\Microsoft\Windows\Start Menu\Programs", "$env:APPDATA\Microsoft\Windows\Start Menu\Programs", "$env:PUBLIC\Desktop", "$env:USERPROFILE\Desktop")
foreach ($p in $lnkPaths) {
    if (Test-Path $p) { Get-ChildItem $p -Recurse -Include *.lnk | Where-Object { $_.Name -match "Word" -or $_.Name -match "Excel" -or $_.Name -match "Office" } | Remove-Item -Force }
}

# ==========================================
# 9. ABSCHLUSSPRÜFUNG (POWERSHELL STATT WMIC)
# ==========================================
Write-Host "`n[9/9] Abschlussprüfung (PowerShell Check)..." -ForegroundColor Yellow

$check = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -match "Microsoft Office" -or $_.Name -match "ProPlus" }

if ($check) {
    Write-Host "WARNUNG: Es wurden noch Reste in der Datenbank gefunden:" -ForegroundColor Red
    $check | Select-Object Name, IdentifyingNumber
} else {
    Write-Host "ERFOLG: Keine Office-Produkte mehr gefunden." -ForegroundColor Green
    Write-Host "Das System ist sauber." -ForegroundColor Green
}

Write-Host "`nBITTE NEUSTARTEN!" -ForegroundColor Cyan
Start-Sleep -Seconds 5
