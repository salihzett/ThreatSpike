# -------------------------------
# System Overview for HPE ProLiant DL20 Gen10 Plus
# -------------------------------

# System & Mainboard
$system = Get-CimInstance Win32_ComputerSystem
$baseboard = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS

Write-Host "=============================="
Write-Host "Overview"
Write-Host "=============================="
Write-Host "Manufactur: $($system.Manufacturer)"
Write-Host "Model: $($system.Model)"
Write-Host "Baseboard: $($baseboard.Product)"
Write-Host "Serial Number: $($baseboard.SerialNumber)"
Write-Host "BIOS-Version: $($bios.SMBIOSBIOSVersion) vom $($bios.ReleaseDate)"
Write-Host ""

# Prozessor
$cpu = Get-CimInstance Win32_Processor
Write-Host "=============================="
Write-Host "Prozessor(en)"
Write-Host "=============================="
foreach ($c in $cpu) {
    Write-Host "Name: $($c.Name)"
    Write-Host "Cores: $($c.NumberOfCores) | Logische Prozessoren: $($c.NumberOfLogicalProcessors)"
    Write-Host "Max Clock Speed: $($c.MaxClockSpeed) MHz"
    Write-Host ""
}

# RAM
$ramArray = Get-CimInstance Win32_PhysicalMemoryArray
$ramModules = Get-CimInstance Win32_PhysicalMemory

Write-Host "=============================="
Write-Host "RAM"
Write-Host "=============================="
Write-Host "Installed Sum Capacity: $([math]::Round((($ramModules | Measure-Object Capacity -Sum).Sum / 1GB),2)) GB"
Write-Host "Max Capacity: $([math]::Round(($ramArray.MaxCapacity / 1MB),2)) GB"
Write-Host "RAM-Slots: $($ramArray.MemoryDevices)"
Write-Host "Available Slots: $($ramModules.Count)"
Write-Host ""

$ramModules | Select-Object BankLabel, Manufacturer,
  @{Name='Capacity(GB)';Expression={[math]::Round($_.Capacity / 1GB,2)}},
  @{Name='Typ';Expression={
    switch ($_.SMBIOSMemoryType) {
      20 {'DDR'}
      21 {'DDR2'}
      24 {'DDR3'}
      26 {'DDR4'}
      27 {'DDR5'}
      default {"unknown ($($_.SMBIOSMemoryType))"}
    }
  }},
  Speed | Format-Table -AutoSize

Write-Host ""

# Hard Drive
$disks = Get-CimInstance Win32_DiskDrive
Write-Host "=============================="
Write-Host "Hard Drive"
Write-Host "=============================="
foreach ($d in $disks) {
    Write-Host "Name: $($d.Model)"
    Write-Host "Disk: $([math]::Round($d.Size/1GB,2)) GB"
    Write-Host "Interface: $($d.InterfaceType)"
    Write-Host "Partitions: $($d.Partitions)"
    Write-Host "S/N: $($d.SerialNumber)"
    Write-Host "-------------------------"
}

# Optional: Controller/RAID-Infos (if available)
$storageControllers = Get-CimInstance Win32_SCSIController
Write-Host "=============================="
Write-Host "Storage-Controller / RAID"
Write-Host "=============================="
foreach ($s in $storageControllers) {
    Write-Host "Name: $($s.Name) | Hersteller: $($s.Manufacturer) | Status: $($s.Status)"
}
