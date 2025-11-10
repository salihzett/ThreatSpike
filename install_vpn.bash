$Log = "C:\Temp\WG-MVPN-SSL-install.log"
$Installer = "C:\Temp\WG-MVPN-SSL_12_11_4.exe"
$Url = "https://cdn.watchguard.com/SoftwareCenter/Files/MUVPN_SSL/12_11_4/WG-MVPN-SSL_12_11_4.exe"

"$(Get-Date) - Start Download..." | Out-File $Log -Append

try {
    Invoke-WebRequest -Uri $Url -OutFile $Installer -ErrorAction Stop
    "$(Get-Date) - Download done." | Out-File $Log -Append
}
catch {
    "$(Get-Date) - Download error: $_" | Out-File $Log -Append
    exit 1
}

"$(Get-Date) - Start Silent Installation..." | Out-File $Log -Append
try {
    $proc = Start-Process -FilePath $Installer -ArgumentList "/S" -Wait -PassThru
    "$(Get-Date) - Installation done. ExitCode: $($proc.ExitCode)" | Out-File $Log -Append
}
catch {
    "$(Get-Date) - Error during Installation: $_" | Out-File $Log -Append
    exit 1
}

"$(Get-Date) - Delete Installer..." | Out-File $Log -Append
Remove-Item $Installer -Force

"$(Get-Date) - Done." | Out-File $Log -Append
