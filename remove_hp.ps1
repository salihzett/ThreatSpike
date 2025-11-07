<#
.SYNOPSIS
  Entfernt alle HP- und Bromium-Komponenten vollständig:
  - HP UWP / Appx Pakete
  - HP Win32-Programme
  - HP Wolf Security & Bromium
  - HP Security Update Service
  - HP-bezogene Dienste, Tasks und Ordner
#>

# =======================
# Admincheck
# =======================
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)) {
    Write-Host "Dieses Skript erfordert Administratorrechte. Bitte als Administrator ausführen!" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "`n===============================" -ForegroundColor Cyan
Write-Host " Entferne HP & Bromium Software vollständig"
Write-Host "===============================" -ForegroundColor Cyan

# =======================
# (1) HP Tasks deaktivieren
# =======================
Write-Host "`n-- (1/6) HP & Bromium Aufgaben deaktivieren --" -ForegroundColor Cyan
Get-ScheduledTask | Where-Object {
    $_.TaskName -match '(?i)HP|Bromium|Wolf'
} | ForEach-Object {
    Write-Host "→ Deaktiviere Aufgabe: $($_.TaskName)" -ForegroundColor Yellow
    try { Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue } catch {}
}

# =======================
# (2) HP Dienste stoppen & deaktivieren
# =======================
Write-Host "`n-- (2/6) Stoppe & deaktiviere HP/Bromium Dienste --" -ForegroundColor Cyan
Get-Service | Where-Object {
    $_.DisplayName -match '(?i)HP|Wolf|Bromium|Security'
} | ForEach-Object {
    Write-Host "→ Stoppe: $($_.Name)" -ForegroundColor Yellow
    try {
        Stop-Service $_.Name -Force -ErrorAction SilentlyContinue
        Set-Service $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}

# =======================
# (3) HP Appx / UWP Pakete
# =======================
Write-Host "`n-- (3/6) Entferne HP Appx/UWP Pakete --" -ForegroundColor Cyan
Get-AppxPackage -AllUsers | Where-Object {
    $_.Name -match '(?i)HP|Wolf|Bromium|Security'
} | ForEach-Object {
    Write-Host "→ Entferne Appx: $($_.Name)" -ForegroundColor Yellow
    Remove-AppxPackage $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
}

Write-Host "`n-- Deprovisioniere HP Appx --" -ForegroundColor Cyan
Get-AppxProvisionedPackage -Online | Where-Object {
    $_.DisplayName -match '(?i)HP|Wolf|Bromium|Security'
} | ForEach-Object {
    Write-Host "→ Entferne ProvisionedPackage: $($_.DisplayName)" -ForegroundColor Yellow
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

# =======================
# (4) HP / Bromium Programme (MSI / EXE) robust
# =======================
Write-Host "`n-- (4/6) Entferne klassische Programme (MSI/EXE) --" -ForegroundColor Cyan

$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

foreach ($root in $uninstallRoots) {
    Get-ChildItem $root | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -match '(?i)HP|Wolf|Bromium|Security Update') {
            Write-Host "→ Deinstalliere: $($p.DisplayName)" -ForegroundColor Yellow
            $cmd = $p.UninstallString
            if ($cmd -match 'msiexec\.exe' -and $cmd -match '{[0-9A-F-]+}') {
                $guid = $Matches[0]
                Start-Process msiexec.exe -ArgumentList "/x $guid /qn /norestart" -Wait
            } elseif ($cmd) {
                # Timeout: 7 Minuten
                $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -PassThru
                $ok = $proc | Wait-Process -Timeout 420   # 7 Minuten
                if (-not $ok) {
                    Write-Host "Deinstallationsprozess hängt, wird beendet: $($proc.Id)" -ForegroundColor Red
                    try { Stop-Process -Id $proc.Id -Force } catch {}
                }
            }
        }
    }
}


# =======================
# (5) Reste löschen
# =======================
Write-Host "`n-- (5/6) Lösche verbleibende HP/Bromium Ordner --" -ForegroundColor Cyan
$paths = @(
    "C:\Program Files\HP",
    "C:\Program Files (x86)\HP",
    "C:\Program Files\HP Wolf Security",
    "C:\Program Files (x86)\HP Wolf Security",
    "C:\Program Files\Bromium",
    "C:\Program Files (x86)\Bromium",
    "C:\ProgramData\HP",
    "C:\ProgramData\HP Wolf Security",
    "C:\ProgramData\Bromium",
    "$env:LOCALAPPDATA\HP",
    "$env:APPDATA\HP"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "→ Entferne Ordner: $p" -ForegroundColor Yellow
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# =======================
# (6) Registryreste entfernen
# =======================
Write-Host "`n-- (6/6) Bereinige Registry --" -ForegroundColor Cyan
$regPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\HP Secure Update Service",
    "HKLM:\SYSTEM\CurrentControlSet\Services\Bromium",
    "HKLM:\SYSTEM\CurrentControlSet\Services\HPWolf",
    "HKLM:\SYSTEM\CurrentControlSet\Services\HPWolfSecurity",
    "HKLM:\SYSTEM\CurrentControlSet\Services\HPAppHelperCap"
)
foreach ($r in $regPaths) {
    if (Test-Path $r) {
        Write-Host "→ Entferne Schlüssel: $r" -ForegroundColor Yellow
        Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`✅ Fertig! Neustart empfohlen, um gesperrte Dateien zu löschen." -ForegroundColor Green
Pause

