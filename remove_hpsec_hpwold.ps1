Write-Host "`n=== Entferne HP Security Update Service & HP Wolf Security Console ===" -ForegroundColor Cyan

# 1️⃣ Dienste stoppen und deaktivieren
$services = Get-Service | Where-Object { $_.Name -match '(?i)HP.*Security|Bromium|Wolf' }
foreach ($svc in $services) {
    Write-Host "→ Stoppe & deaktiviere Dienst: $($svc.Name)" -ForegroundColor Yellow
    try {
        Stop-Service $svc.Name -Force -ErrorAction SilentlyContinue
        Set-Service $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
    } catch {}
}

# 2️⃣ Alle Wolf / Bromium / HP Security MSI-Pakete finden und deinstallieren
$keys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
foreach ($key in $keys) {
    Get-ChildItem $key | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        if ($p.DisplayName -match '(?i)HP Wolf|Security Update|Bromium') {
            Write-Host "→ Deinstalliere: $($p.DisplayName)" -ForegroundColor Yellow
            if ($p.UninstallString -match 'msiexec\.exe' -and $p.UninstallString -match '{[0-9A-F-]+}') {
                $guid = $Matches[0]
                Start-Process msiexec.exe -ArgumentList "/x $guid /qn /norestart" -Wait
            } elseif ($p.UninstallString) {
                Start-Process "cmd.exe" -ArgumentList "/c", "$($p.UninstallString) /quiet /norestart" -Wait
            }
        }
    }
}

# 3️⃣ Eventuelle Appx-Pakete entfernen (Wolf Security App)
Get-AppxPackage -AllUsers | Where-Object { $_.Name -match '(?i)HPWolf|Security' } | ForEach-Object {
    Write-Host "→ Entferne Appx: $($_.Name)" -ForegroundColor Yellow
    Remove-AppxPackage $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
}

# 4️⃣ Überreste löschen
$paths = @(
    "C:\Program Files\HP Wolf Security",
    "C:\Program Files (x86)\HP Wolf Security",
    "C:\Program Files\Bromium",
    "C:\Program Files (x86)\Bromium",
    "C:\ProgramData\HP Wolf Security",
    "C:\ProgramData\Bromium"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "→ Entferne Ordner: $p" -ForegroundColor Yellow
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 5️⃣ Registry-Reste löschen (optional, fortgeschritten)
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HP Secure Update Service" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Bromium" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ HP Wolf Security & HP Security Update Service entfernt. Neustart erforderlich!" -ForegroundColor Green
Pause


