# Silent Office 2016 Removal Script (no reboot, no user interaction)

$tool = "$env:TEMP\SetupProd_OffScrub.exe"

# 1. Download Microsoft OffScrub Tool
Invoke-WebRequest -Uri "https://aka.ms/SaRA-OfficeUninstallFromPC" -OutFile $tool -UseBasicParsing

# 2. Silent uninstall of Office 2016 (O16)
Start-Process -FilePath $tool -ArgumentList "/quiet /product O16" -Wait

# OPTIONAL: All Office versions, uncomment if needed
# Start-Process -FilePath $tool -ArgumentList "/quiet /product ALL" -Wait

# 3. Kill remaining Office processes
Get-Process | Where-Object {$_.Name -match "office|winword|excel|powerpnt|onenote|outlook"} | Stop-Process -Force -ErrorAction SilentlyContinue

# 4. Remove leftover directories
$paths = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "$env:ProgramData\Microsoft\Office",
    "$env:AppData\Microsoft\Office",
    "$env:LocalAppData\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Outlook"
)

foreach ($p in $paths) {
    Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Remove Office 2016 registry keys
$regKeys = @(
    "HKLM:\Software\Microsoft\Office\16.0",
    "HKLM:\Software\WOW6432Node\Microsoft\Office\16.0",
    "HKCU:\Software\Microsoft\Office\16.0"
)

foreach ($key in $regKeys) {
    Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue
}

# 6. Finished (no reboot required)
Write-Host "Office 2016 wurde vollständig entfernt (silent, no reboot)."
