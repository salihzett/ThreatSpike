$KBNumber = "KB5015878"
$DownloadUrl = "https://www.catalog.update.microsoft.com/Search.aspx?q=$KBNumber"

# Download the update
Invoke-WebRequest -Uri $DownloadUrl -OutFile "$env:TEMP\$KBNumber.msu"

# Install the update
Start-Process -FilePath "C:\Windows\System32\wusa.exe" -ArgumentList "/quiet", "/norestart", "$env:TEMP\$KBNumber.msu" -Wait
