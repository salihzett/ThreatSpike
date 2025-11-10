# =======================
# HP / Bromium Programme (MSI / EXE) robust mit 3 Minuten Timeout + Fallback
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
            $success = $false

            # --- MSI-GUID Deinstallation ---
            if ($cmd -match 'msiexec\.exe' -and $cmd -match '{[0-9A-F-]+}') {
                $guid = $Matches[0]
                Start-Process msiexec.exe -ArgumentList "/x $guid /qn /norestart" -Wait
                $success = $true
            } elseif ($cmd) {
                # --- EXE Deinstallation mit 3 Minuten Timeout ---
                try {
                    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd" -PassThru
                    $ok = $proc | Wait-Process -Timeout 180   # 3 Minuten
                    if (-not $ok) {
                        Write-Host "⚠️ Deinstallationsprozess hängt, wird beendet: $($proc.Id)" -ForegroundColor Red
                        try { Stop-Process -Id $proc.Id -Force } catch {}
                    } else {
                        $success = $true
                    }
                } catch {
                    Write-Host "❌ Fehler beim Starten von Uninstaller: $_" -ForegroundColor Red
                }
            }

            # --- Fallback: Win32_Product / MSI GUID ---
            if (-not $success) {
                try {
                    $prod = Get-CimInstance -ClassName Win32_Product -Filter "Name LIKE '%$($p.DisplayName)%'" -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($prod) {
                        Write-Host "ℹ️ Fallback über Win32_Product: $($prod.Name)" -ForegroundColor Cyan
                        Start-Process msiexec.exe -ArgumentList "/x $($prod.IdentifyingNumber) /qn /norestart" -Wait
                    } else {
                        Write-Host "ℹ️ Kein Eintrag in Win32_Product gefunden." -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "❌ Fehler beim Fallback über Win32_Product: $_" -ForegroundColor Red
                }
            }
        }
    }
}
