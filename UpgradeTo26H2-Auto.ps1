# UpgradeTo26H2-Auto.ps1
# check if 24h2, search for download and install the package

Write-Host "`n=== Windows 11 26H2 Auto-Upgrade Tool ===`n"

# 1. Prüfen ob 24H2
$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
if ($os.DisplayVersion -ne "25H2") {
    Write-Warning "System is not 25H2 — Upgrade via Enablement-Package NOT recommanded."
    exit 1
}

Write-Host "✔ Windows 11 25H2 found."

# 2. Mögliche URLs definieren (x64 / ARM64)
$urls = @(
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/94520a88-858f-4832-a57d-7211f6d84a4e/public/Windows11.0-KB5121794-x64_5e20a3cce48d6611b16bdec42b07167f5456586a.msu",
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/9d8dc3d0-9cbf-4eb1-9411-722e3e6a19b3/public/Windows11.0-KB5121794-arm64_77a76caf2d362bb293a4d18058388f2717365abe.msu"
)

# 3. Prüfen & Download
$downloaded = $false
foreach ($url in $urls) {
    Write-Host "Check URL: $url"
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) {
            Write-Host "✔ Paket Found. Download..."
            $out = "$env:TEMP\$(Split-Path $url -Leaf)"
            Invoke-WebRequest -Uri $url -OutFile $out
            $downloaded = $true
            break
        } else {
            Write-Host "✖ No Access (HTTP $($resp.StatusCode))"
        }
    } catch {
        Write-Host "✖ Error in Access: $_"
    }
}

if (-not $downloaded) {
    Write-Warning "No Enablement-Package Found. Exit Script."
    exit 1
}

# 4. Installation
Write-Host "🚀 Start Installation..."
Start-Process "wusa.exe" -ArgumentList "`"$out`" /quiet /norestart" -Wait

#Write-Host "`n✅ Installation done — Restart required."
#Restart-Computer -Force
