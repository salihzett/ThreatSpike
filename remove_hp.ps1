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
                    Write-Host "⚠️ Deinstallationsprozess hängt, wird beendet: $($proc.Id)" -ForegroundColor Red
                    try { Stop-Process -Id $proc.Id -Force } catch {}
                }
            }
        }
    }
}
