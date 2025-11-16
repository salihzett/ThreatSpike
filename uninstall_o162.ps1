# ---------------------------
# uninstall_o162_custom.ps1
# Vollständige Deinstallation von Office 2016, LibreOffice bleibt verschont
# ---------------------------

Write-Host "Starte vollständige Office 2016 Deinstallation..."

# Alle Office-Produkte auflisten, LibreOffice ausschließen
$officeProducts = Get-WmiObject -Class Win32_Product | Where-Object {
    $_.Name -like "*Office*" -and $_.Name -notlike "*LibreOffice*"
}

# Deinstallation
foreach ($product in $officeProducts) {
    Write-Host "Deinstalliere:" $product.Name
    $product.Uninstall() | Out-Null
}

Write-Host "Fertig. Verbleibende Office-Produkte:"
# Übersicht nach der Deinstallation
Get-WmiObject -Class Win32_Product | Where-Object {
    $_.Name -like "*Office*" -and $_.Name -notlike "*LibreOffice*"
} | Select-Object Name, Version, Vendor
