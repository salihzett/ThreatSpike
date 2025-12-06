# UpgradeTo25H2-Auto.ps1
# check if 24h2, search for download and install the package

Write-Host "`n=== Windows 11 25H2 Auto-Upgrade Tool ===`n"

# 1. Prüfen ob 24H2
$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\"
if ($os.DisplayVersion -ne "24H2") {
    Write-Warning "System is not 24H2 — Upgrade via Enablement-Package NOT recommanded."
    exit 1
}

Write-Host "✔ Windows 11 24H2 found."

# 2. Mögliche URLs definieren (x64 / ARM64)
$urls = @(
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/fa84cc49-18b2-4c26-b389-90c96e6ae0d2/public/windows11.0-kb5054156-x64_a0c1638cbcf4cf33dbe9a5bef69db374b4786974.msu",
    "https://catalog.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/78b265e5-83a8-4e0a-9060-efbe0bac5bde/public/windows11.0-kb5054156-arm64_3d5c91aaeb08a87e0717f263ad4a61186746e465.msu"
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

#Write-Host "`n✅ Installation abgeschlossen — Neustart notwendig."
#Restart-Computer -Force
