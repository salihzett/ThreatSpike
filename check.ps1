# -------------------------------
# Systemübersicht für Gerät
# -------------------------------

# System & Mainboard
$system = Get-CimInstance Win32_ComputerSystem
$baseboard = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS

Write-Host "=============================="
Write-Host "Systemübersicht"
Write-Host "=============================="
Write-Host "Hersteller: $($system.Manufacturer)"
Write-Host "Modell: $($system.Model)"
Write-Host "Basisplatine: $($baseboard.Product)"
Write-Host "Seriennummer: $($baseboard.SerialNumber)"
Write-Host "BIOS-Version: $($bios.SMBIOSBIOSVersion) vom $($bios.ReleaseDate)"
Write-Host ""

# Prozessor(en)
$cpu = Get-CimInstance Win32_Processor
Write-Host "=============================="
Write-Host "Prozessor(en)"
Write-Host "=============================="
foreach ($c in $cpu) {
    Write-Host "Name: $($c.Name)"
    Write-Host "Cores: $($c.NumberOfCores) | Logische Prozessoren: $($c.NumberOfLogicalProcessors)"
    Write-Host "Max Takt: $($c.MaxClockSpeed) MHz"
    Write-Host ""
}

# RAM
$ramArray = Get-CimInstance Win32_PhysicalMemoryArray
$ramModules = Get-CimInstance Win32_PhysicalMemory

Write-Host "=============================="
Write-Host "RAM"
Write-Host "=============================="
Write-Host "Installierte Gesamtkapazität: $([math]::Round((($ramModules | Measure-Object Capacity -Sum).Sum / 1GB),2)) GB"
Write-Host "Maximal unterstützt: $([math]::Round(($ramArray.MaxCapacity / 1MB),2)) GB"
Write-Host "RAM-Steckplätze: $($ramArray.MemoryDevices)"
Write-Host "Belegte Slots: $($ramModules.Count)"
Write-Host ""

$ramModules | Select-Object BankLabel, Manufacturer,
  @{Name='Kapazität(GB)';Expression={[math]::Round($_.Capacity / 1GB,2)}},
  @{Name='Typ';Expression={
    switch ($_.SMBIOSMemoryType) {
      20 {'DDR'}
      21 {'DDR2'}
      24 {'DDR3'}
      26 {'DDR4'}
      27 {'DDR5'}
      default {"Unbekannt ($($_.SMBIOSMemoryType))"}
    }
  }},
  Speed | Format-Table -AutoSize

Write-Host ""

# Festplatten
$disks = Get-CimInstance Win32_DiskDrive
Write-Host "=============================="
Write-Host "Festplatten"
Write-Host "=============================="
foreach ($d in $disks) {
    Write-Host "Name: $($d.Model)"
    Write-Host "Kapazität: $([math]::Round($d.Size/1GB,2)) GB"
    Write-Host "Interface: $($d.InterfaceType)"
    Write-Host "Partitionsanzahl: $($d.Partitions)"
    Write-Host "S/N: $($d.SerialNumber)"
    Write-Host "-------------------------"
}

# Optional: Controller/RAID-Infos (falls vorhanden)
$storageControllers = Get-CimInstance Win32_SCSIController
Write-Host "=============================="
Write-Host "Storage-Controller / RAID"
Write-Host "=============================="
foreach ($s in $storageControllers) {
    Write-Host "Name: $($s.Name) | Hersteller: $($s.Manufacturer) | Status: $($s.Status)"
}
