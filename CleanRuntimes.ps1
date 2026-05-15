# CleanRuntimes.ps1
Write-Host "Starting radical cleanup of all Microsoft Runtimes..." -ForegroundColor Yellow

# Broader keywords to catch EVERYTHING Visual Studio related, plus C++, J# and .NET
$keywords = @(
    "*Visual C++*",
    "*Visual Studio*",
    "*Visual J#*",
    "*Windows Desktop Runtime*"
)

# Search in 64-bit, 32-bit, AND Current User registry hives
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Fetch all installed applications
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
        Write-Host "Removing: $($app.DisplayName)" -ForegroundColor Cyan
        
        # Handle MSI packages (especially stubborn 2005/2008 versions)
        if ($app.UninstallString -match "msiexec") {
            # Extract the actual GUID from the UninstallString using Regex for accuracy
            if ($app.UninstallString -match "\{[-a-zA-Z0-9]+\}") {
                $guid = $matches[0]
                $arguments = "/x $guid /qn /norestart"
            } else {
                $arguments = "/x $($app.PSChildName) /qn /norestart"
            }
            Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow
        } 
        # Handle EXE packages (newer Runtimes and Installers)
        else {
            $uninstallCmd = ""
            if ($app.QuietUninstallString) {
                $uninstallCmd = $app.QuietUninstallString
            } elseif ($app.UninstallString) {
                # Some uninstall strings have quotes, we strip them and build a clean command
                $cleanString = $app.UninstallString -replace '"', ''
                $uninstallCmd = "`"$cleanString`" /quiet /norestart /uninstall"
            }
            
            if ($uninstallCmd) {
                Start-Process "cmd.exe" -ArgumentList "/c $uninstallCmd" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "Cleanup successfully completed!" -ForegroundColor Green
