# Speicherort für Download
$Installer = "C:\Temp\WG-MVPN-SSL_12_11_4.exe"

# URL
$Url = "https://cdn.watchguard.com/SoftwareCenter/Files/MUVPN_SSL/12_11_4/WG-MVPN-SSL_12_11_4.exe"

# Download
Invoke-WebRequest -Uri $Url -OutFile $Installer

# Installation (silent mode)
Start-Process -FilePath $Installer -ArgumentList "/S" -Wait

# Datei löschen
Remove-Item $Installer -Force
