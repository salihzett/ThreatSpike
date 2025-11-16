# Office 2016 Removal Script – Silent, no reboot, ohne OffScrub

# 1️⃣ Prozesse beenden
$officeProcesses = "winword","excel","powerpnt","onenote","outlook","lync","mspub","visio","infopath"
Get-Process | Where-Object {$officeProcesses -contains $_.Name} | Stop-Process -Force -ErrorAction SilentlyContinue

# 2️⃣ Office Ordner löschen
$officePaths = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "$env:ProgramData\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Office",
    "$env:APPDATA\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Outlook"
)
foreach ($p in $officePaths) {
    Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
}

# 3️⃣ Registry Keys löschen
$registryKeys = @(
    "HKLM:\Software\Microsoft\Office\16.0",
    "HKLM:\Software\WOW6432Node\Microsoft\Office\16.0",
    "HKCU:\Software\Microsoft\Office\16.0"
)
foreach ($k in $registryKeys) {
    Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
}

# 4️⃣ Optional: Verknüpfungen auf Desktop / Startmenu entfernen
$shortcuts = @(
    "$env:PUBLIC\Desktop\*.lnk",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\*.lnk"
)
foreach ($s in $shortcuts) {
    Remove-Item -Path $s -Force -ErrorAction SilentlyContinue
}

Write-Host "Office 2016 wurde vollständig entfernt (silent, ohne OffScrub, ohne Reboot)."
