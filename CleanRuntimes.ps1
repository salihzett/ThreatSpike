# CleanRuntimes.ps1
Write-Host "Starting radical cleanup of all Microsoft Runtimes..." -ForegroundColor Yellow

# These keywords cover all C++, J#, VSTO, and .NET Runtimes from the system
$keywords = @(
    "*Visual C++*",
    "*Visual Studio 2010*Tools*",
    "*Visual J#*",
    "*Windows Desktop Runtime*"
)

# Search in both 64-bit and 32-bit registry hives
$registryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
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
        
        # Handle MSI packages (e.g., older 2005/2008 versions)
        if ($app.UninstallString -match "msiexec") {
            # Extract the GUID (PSChildName) and run silent uninstall
            $arguments = "/x $($app.PSChildName) /qn /norestart"
            Start-Process "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow
        } 
        # Handle EXE packages (e.g., newer 2015-2022 and .NET versions)
        else {
            $uninstallCmd = ""
            if ($app.QuietUninstallString) {
                # Use the official silent uninstall string if provided by the vendor
                $uninstallCmd = $app.QuietUninstallString
            } elseif ($app.UninstallString) {
                # Fallback: append standard silent flags to the regular uninstall string
                $uninstallCmd = "$($app.UninstallString) /quiet /norestart /uninstall"
            }
            
            if ($uninstallCmd) {
                # Run via cmd.exe to handle unquoted paths with spaces safely
                Start-Process "cmd.exe" -ArgumentList "/c `"$uninstallCmd`"" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "Cleanup successfully completed!" -ForegroundColor Green
