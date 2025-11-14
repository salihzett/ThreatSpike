# ===============================================
# Adobe RUM Auto-Updater Script (Optimized)
# ===============================================

$SourceZip = "\\Kiber2dc01.adlon.hotel\NETLOGON\KIBER2\AdobeUninstaller.zip"
$TempFolder = "$env:TEMP\AdobeRUM"
$ZipFile = "$TempFolder\RUM.zip"

# Log directory
$LogFolder = "$env:TEMP\Adobe_RUM_Update_Logs"
if (-Not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

$LogFile = Join-Path $LogFolder ("RUM_Update_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File $LogFile -Encoding UTF8 -Append
}

Write-Log "=== Starting Adobe RUM update ==="

# Validate source ZIP exists
if (-not (Test-Path $SourceZip)) {
    Write-Log "ERROR: Source ZIP not found: $SourceZip"
    exit 1
}

Write-Log "Source ZIP found: $SourceZip"

# Clean previous temp folder
if (Test-Path $TempFolder) {
    Remove-Item $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $TempFolder | Out-Null

# Copy ZIP to temp
try {
    Copy-Item $SourceZip $ZipFile -Force
    Write-Log "ZIP copied to $ZipFile"
} catch {
    Write-Log "ERROR copying ZIP: $_"
    exit 1
}

# Extract ZIP
try {
    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive -Path $ZipFile -DestinationPath $TempFolder -Force
        Write-Log "ZIP extracted using Expand-Archive"
    } else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $TempFolder)
        Write-Log "ZIP extracted using ZipFile class"
    }
} catch {
    Write-Log "ERROR extracting ZIP: $_"
    exit 1
}

# Locate RemoteUpdateManager.exe
$RUM = Get-ChildItem -Path $TempFolder -Filter "RemoteUpdateManager.exe" -Recurse | Select-Object -First 1

if (-not $RUM) {
    Write-Log "ERROR: RemoteUpdateManager.exe not found!"
    exit 1
}

Write-Log "Found RUM at: $($RUM.FullName)"

# Run RUM
try {
    Write-Log "Starting Adobe RUM (silent)..."
    $process = Start-Process -FilePath $RUM.FullName -ArgumentList "--silent" -Wait -PassThru
    Write-Log "RUM exit code: $($process.ExitCode)"
} catch {
    Write-Log "ERROR running RUM: $_"
    exit 1
}

Write-Log "Adobe RUM update finished."

# Cleanup optional
try {
    Remove-Item $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Temp folder cleaned."
} catch {
    Write-Log "WARNING: Failed to clean Temp folder."
}

Write-Log "=== Script completed ==="
exit 0
