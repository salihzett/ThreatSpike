# CleanRuntimes.ps1
Write-Host "Starting aggressive Ghost-Cleanup of Microsoft Runtimes..." -ForegroundColor Yellow

$keywords = @(
    "*Visual C++*",
    "*Visual Studio*",
    "*Visual J#*",
    "*Windows Desktop Runtime*"
)

$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedApps = Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -ne $null }

foreach ($app in $installedApps) {
    $match = $false
    foreach ($keyword in $keywords) {
        if ($app.DisplayName -like $keyword) {
            $match = $true
            break
        }
    }
    
    if ($match) {
        Write-Host "Removing/Wiping: $($app.DisplayName)" -ForegroundColor Cyan
        
        # 1. Try standard uninstall silently in the background (ignoring errors if it fails)
        if ($app.UninstallString -match "msiexec") {
            if ($app.UninstallString -match "\{[-a-zA-Z0-9]+\}") {
                $guid = $matches[0]
                $arguments = "/x $guid /qn /norestart"
            } else {
                $arguments = "/x $($app.PSChildName) /qn /norestart"
            }
            Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow -ErrorAction SilentlyContinue
        } 
        
        # 2. BRUTE FORCE: Delete the registry key so the "Ghost" vanishes from the system completely
        try {
            Remove-Item -Path $app.PSPath -Recurse -Force -ErrorAction Stop
            Write-Host " -> Ghost entry successfully wiped from Registry." -ForegroundColor DarkGray
        } catch {
            Write-Host " -> Could not wipe registry key (maybe requires TrustedInstaller)." -ForegroundColor Red
        }
    }
}

Write-Host "Cleanup successfully completed! Ghosts removed." -ForegroundColor Green
