# ===============================
# Adobe RUM Auto-Update Script
# ===============================

$SourceZip = "\\Kiber2dc01.adlon.hotel\NETLOGON\KIBER2\AdobeUninstaller.zip"
$TempFolder = "$env:TEMP\AdobeRUM"
$ZipFile = "$TempFolder\RUM.zip"

# Log-Ordner
$LogFolder = "$env:TEMP\Adobe_RUM_Update_Logs"
if (-Not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}
$LogFile = Join-Path $LogFolder ("RUM_Update_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

Write-Output "[$(Get-Date -Format G)] Starting Adobe RUM update..." | Out-File $LogFile -Append

# Clean TEMP folder
if (Test-Path $TempFolder) {
    Remove-Item $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $TempFolder | Out-Null

# Download ZIP
try {
    Copy-Item $SourceZip $ZipFile -Force
    Write-Output "[$(Get-Date -Format G)] RUM.zip copied successfully." | Out-File $LogFile -Append
} catch {
    Write-Output "[$(Get-Date -Format G)] ERROR copying ZIP: $_" | Out-File $LogFile -Append
    exit 1
}

# Unzip
try {
    Expand-Archive -Path $ZipFile -DestinationPath $TempFolder -Force
    Write-Output "[$(Get-Date -Format G)] RUM.zip extracted." | Out-File $LogFile -Append
} catch {
    Write-Output "[$(Get-Date -Format G)] ERROR extracting ZIP: $_" | Out-File $LogFile -Append
    exit 1
}

# Suche RUM.exe
$RUM = Get-ChildItem -Path $TempFolder -Filter "RemoteUpdateManager.exe" -Recurse | Select-Object -First 1

if (-not $RUM) {
    Write-Output "[$(Get-Date -Format G)] ERROR: RemoteUpdateManager.exe not found!" | Out-File $LogFile -Append
    exit 1
} else {
    Write-Output "[$(Get-Date -Format G)] RUM found at: $($RUM.FullName)" | Out-File $LogFile -Append
}

# Run Adobe Updates
try {
    Start-Process -FilePath $RUM.FullName -ArgumentList "--silent" -Wait
    Write-Output "[$(Get-Date -Format G)] Adobe RUM update completed." | Out-File $LogFile -Append
} catch {
    Write-Output "[$(Get-Date -Format G)] ERROR running RUM: $_" | Out-File $LogFile -Append
}

Write-Output "[$(Get-Date -Format G)] Script finished." | Out-File $LogFile -Append
