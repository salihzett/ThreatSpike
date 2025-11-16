<#
.SYNOPSIS
Vollständige Deinstallation von Office 2016 (32/64-bit) ohne OffScrub
.SILENT
Keine Benutzerinteraktion, kein Neustart
#>

Write-Host "Starte vollständige Office 2016 Deinstallation..."

# 1️⃣ Office Prozesse beenden
$officeProcesses = "winword","excel","powerpnt","onenote","outlook","lync","mspub","visio","infopath"
foreach ($p in $officeProcesses) {
    Get-Process -Name $p -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# 2️⃣ MSI-Komponenten deinstallieren
$officeMSI = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Office 16*"}
foreach ($app in $officeMSI) {
    Write-Host "Deinstalliere $($app.Name)..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $($app.IdentifyingNumber) /qn /norestart" -Wait
}

# 3️⃣ Ordner löschen
$paths = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "$env:ProgramData\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Office",
    "$env:APPDATA\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Outlook"
)
foreach ($p in $paths) {
    Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
}

# 4️⃣ Registry löschen
$registryKeys = @(
    "HKLM:\Software\Microsoft\Office\16.0",
    "HKLM:\Software\WOW6432Node\Microsoft\Office\16.0",
    "HKCU:\Software\Microsoft\Office\16.0"
)
foreach ($k in $registryKeys) {
    Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
}

# 5️⃣ Desktop / Startmenü-Verknüpfungen
$shortcuts = @(
    "$env:PUBLIC\Desktop\*.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\*.lnk"
)
foreach ($s in $shortcuts) {
    Remove-Item -Path $s -Force -ErrorAction SilentlyContinue
}

Write-Host "Office 2016 wurde vollständig entfernt (silent, kein Reboot, ohne OffScrub)."
