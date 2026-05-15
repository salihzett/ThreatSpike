# CleanRuntimes.ps1
Write-Host "Initiating Deep Registry Purge (Bypassing blocked msiexec)..." -ForegroundColor Yellow

$keywords = @(
    "*Visual C++*",
    "*Visual Studio*",
    "*Visual J#*",
    "*Windows Desktop Runtime*"
)

# Wir müssen den versteckten MSI-Cache (Classes\Installer\Products) scannen
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Classes\Installer\Products\*"
)

$installedApps = Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue

foreach ($app in $installedApps) {
    # MSI Pakete nutzen 'ProductName', normale Setup.exe nutzen 'DisplayName'
    $appName = $app.DisplayName
    if (-not $appName) { $appName = $app.ProductName }
    
    $match = $false
    if ($appName) {
        foreach ($keyword in $keywords) {
            if ($appName -like $keyword) {
                $match = $true
                break
            }
        }
    }
    
    if ($match) {
        Write-Host "Wiping Registry Entry: $appName" -ForegroundColor Cyan
        try {
            # Löscht den Schlüssel mit purer Gewalt aus der Registry
            Remove-Item -Path $app.PSPath -Recurse -Force -ErrorAction Stop
            Write-Host " -> DELETED." -ForegroundColor Green
        } catch {
            Write-Host " -> Access Denied. Key requires TrustedInstaller permissions." -ForegroundColor Red
        }
    }
}

Write-Host "Purge complete. Please close and reopen the 'Add/Remove Programs' window!" -ForegroundColor Yellow
