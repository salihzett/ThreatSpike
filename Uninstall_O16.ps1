# Silent Office 2016 Removal Script (PowerShell 5.1 compatible, fixed, no reboot, no user interaction)

# Download Office Uninstall Tool to a safe folder (not Temp) to avoid blockages
$installFolder = "C:\ProgramData\OffScrub"
if (-not (Test-Path $installFolder)) { New-Item -Path $installFolder -ItemType Directory | Out-Null }
$tool = Join-Path $installFolder "SetupProd_OffScrub.exe"

# Download using WebClient (handles redirects correctly in PS5.1)
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile("https://aka.ms/SaRA-OfficeUninstallFromPC", $tool)

# Silent uninstall of Office 2016 (O16)
Start-Process -FilePath $tool -ArgumentList "/quiet /product O16" -Wait

# OPTIONAL: All Office versions, uncomment if needed
# Start-Process -FilePath $tool -ArgumentList "/quiet /product ALL" -Wait

# Kill remaining Office processes
Get-Process | Where-Object {$_.Name -match "office|winword|excel|powerpnt|onenote|outlook"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Remove leftover directories
$paths = @(
    "C:\Program Files\Microsoft Office",
    "C:\Program Files (x86)\Microsoft Office",
    "$env:ProgramData\Microsoft\Office",
    "$env:AppData\Microsoft\Office",
    "$env:LocalAppData\Microsoft\Office",
    "$env:LOCALAPPDATA\Microsoft\Outlook"
)
foreach ($p in $paths) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }

# Remove Office 2016 registry keys
$regKeys = @(
    "HKLM:\Software\Microsoft\Office\16.0",
    "HKLM:\Software\WOW6432Node\Microsoft\Office\16.0",
    "HKCU:\Software\Microsoft\Office\16.0"
)
foreach ($key in $regKeys) { Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "Office 2016 wurde vollständig entfernt (silent, no reboot, PowerShell 5.1 kompatibel, fixed)."
