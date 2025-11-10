$Log = "C:\Temp\WG-MVPN-SSL-install.log"
$Installer = "C:\Temp\WG-MVPN-SSL_12_11_4.exe"
$Url = "https://cdn.watchguard.com/SoftwareCenter/Files/MUVPN_SSL/12_11_4/WG-MVPN-SSL_12_11_4.exe"

"$(Get-Date) - Starte Download..." | Out-File $Log -Append

try {
    Invoke-WebRequest -Uri $Url -OutFile $Installer -ErrorAction Stop
    "$(Get-Date) - Download erfolgreich." | Out-File $Log -Append
}
catch {
    "$(Get-Date) - Download fehlgeschlagen: $_" | Out-File $Log -Append
    exit 1
}

"$(Get-Date) - Starte Silent Installation..." | Out-File $Log -Append
try {
    $proc = Start-Process -FilePath $Installer -ArgumentList "/S" -Wait -PassThru
    "$(Get-Date) - Installation beendet. ExitCode: $($proc.ExitCode)" | Out-File $Log -Append
}
catch {
    "$(Get-Date) - Fehler bei Installation: $_" | Out-File $Log -Append
    exit 1
}

"$(Get-Date) - Lösche Installer..." | Out-File $Log -Append
Remove-Item $Installer -Force

"$(Get-Date) - Fertig." | Out-File $Log -Append
