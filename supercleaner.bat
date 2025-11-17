@echo off
:: ==========================
:: DEBLOAT SCRIPT FÜR ALLE BENUTZER
:: ==========================

:: Schleife über alle Benutzerprofile
for /D %%u in (C:\Users\*) do (
    set "user=%%u"
    echo =============================
    echo Bearbeite Benutzer: %%u
    echo =============================

    :: -------- OneDrive entfernen --------
    if exist "%%u\OneDrive" (
        echo -- Verschiebe OneDrive Dateien
        robocopy "%%u\OneDrive" "%%u" /mov /e /xj /ndl /nfl /njh /njs /nc /ns /np
        echo -- Entferne OneDrive Reste
        rd "%%u\OneDrive" /Q /S
        rd "%%u\AppData\Local\OneDrive" /Q /S
        rd "%%u\AppData\Local\Microsoft\OneDrive" /Q /S
    )

    :: -------- Apps entfernen --------
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *XboxApp* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *MicrosoftTeams* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *ZuneMusic* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *ZuneVideo* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *SkypeApp* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *WindowsAlarms* | Remove-AppxPackage"
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -User '%%u' *Microsoft.GetHelp* | Remove-AppxPackage"

    :: -------- Widgets / Telemetrie deaktivieren --------
    reg load HKU\TempUser "%%u\NTUSER.DAT"
    reg add "HKU\TempUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
    reg unload HKU\TempUser

    :: -------- Edge entfernen (Chromium, optional) --------
    if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
        echo -- Entferne Edge
        rd "C:\Program Files (x86)\Microsoft\Edge" /Q /S
    )

)

:: -------- Global: Store & Telemetrie entfernen --------
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers *Microsoft.WindowsStore* | Remove-AppxPackage"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers *WindowsFeedbackHub* | Remove-AppxPackage"

:: Optional: Autostart ausklammern (falls benötigt)
:: echo -- Autostart Skript (ausgeklammert)
:: copy "C:\Pfad\zum\Script.bat" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"

echo =============================
echo Fertig! Alle Benutzer bearbeitet.
echo =============================
pause
