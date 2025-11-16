Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Office 16*"} | ForEach-Object {
    Write-Host "Deinstalliere $($_.Name)"
    msiexec.exe /x $_.IdentifyingNumber /qn /norestart
}
