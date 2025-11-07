# 1️⃣ HP-Tasks deaktivieren
Write-Host "`n-- Entferne HP Aufgaben (Task Scheduler) --" -ForegroundColor Cyan
$hpTasks = Get-ScheduledTask | Where-Object {$_.TaskName -match '(?i)HP|Bromium|Wolf'}
foreach ($t in $hpTasks) {
    Write-Host "→ Deaktiviere Aufgabe: $($t.TaskName)" -ForegroundColor Yellow
    try { Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue } catch {}
}

# 2️⃣ HP-Dienste stoppen & deaktivieren
Write-Host "`n-- Stoppe & deaktiviere HP Dienste --" -ForegroundColor Cyan
Get-Service | Where-Object {$_.DisplayName -match '(?i)HP|Bromium|Wolf'} | ForEach-Object {
    Write-Host "→ Stoppe: $($_.Name)" -ForegroundColor Yellow
    Stop-Service $_.Name -Force -ErrorAction SilentlyContinue
    Set-Service $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
}

# 3️⃣ HP & Bromium Programme entfernen
Write-Host "`n-- Entferne HP/Bromium Programme --" -ForegroundColor Cyan
$progs = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
    Get-ItemProperty | Where-Object {
        $_.Publisher -match '(?i)HP|Bromium' -or $_.DisplayName -match '(?i)HP|Bromium|Wolf'
    }

foreach ($p in $progs) {
    Write-Host "→ Deinstalliere: $($p.DisplayName)" -ForegroundColor Yellow
    $cmd = $p.UninstallString
    if ($cmd -match 'msiexec\.exe') {
        Start-Process msiexec.exe -ArgumentList "/x $($cmd -replace '.*({.*}).*','$1') /qn /norestart" -Wait
    } else {
        Start-Process "cmd.exe" -ArgumentList "/c", "$cmd /quiet /norestart" -Wait
    }
}

# 4️⃣ HP Appx entfernen
Get-AppxPackage -AllUsers | Where-Object { $_.Name -match '(?i)HP|Wolf|Bromium' } | ForEach-Object {
    Remove-AppxPackage $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
}

# 5️⃣ Provisionierte Appx entfernen
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match '(?i)HP|Wolf|Bromium' } | ForEach-Object {
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

# 6️⃣ Reste löschen
Write-Host "`n-- Lösche verbleibende HP-Ordner --" -ForegroundColor Cyan
$paths = @(
    "C:\Program Files\HP",
    "C:\Program Files (x86)\HP",
    "C:\ProgramData\HP",
    "$env:LOCALAPPDATA\HP",
    "$env:APPDATA\HP"
)
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "→ Entferne Ordner: $p" -ForegroundColor Yellow
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`✅ HP Software entfernt. Neustart empfohlen." -ForegroundColor Green
Pause


