@echo off
setlocal enabledelayedexpansion

:: ==========================
:: 1) Server und Key definieren
:: ==========================
set "RUSTDESK_SERVER=10.134.129.91"
set "RUSTDESK_KEY=0yF7XMN688QNf9SdB8flLa4xOwbNDw2Bwyx51nhEiFE="

:: ==========================
:: 2) RustDesk via Winget installieren, falls nicht vorhanden
:: ==========================
where rustdesk.exe >nul 2>&1
if errorlevel 1 (
    echo RustDesk nicht gefunden. Installiere via Winget...
    winget install --id RustDesk.RustDesk -e --silent
    timeout /t 5 >nul
) else (
    echo RustDesk bereits installiert.
)

:: ==========================
:: 3) TOML-Konfiguration vorbereiten
:: ==========================
set "TOML_CONTENT=rendezvous_server = ''`r`n\
nat_type = 0`r`n\
serial = 0`r`n\
unlock_pin = ''`r`n\
trusted_devices = ''`r`n`r`n\
[options]`r`n\
custom-rendezvous-server = ""%RUSTDESK_SERVER%""`r`n\
key = ""%RUSTDESK_KEY%""`r`n\
approve-mode = ""click""`r`n\
av1-test = ""N"""

:: ==========================
:: 4) Config für alle bestehenden Benutzer schreiben
:: ==========================
echo Schreibe Config fuer bestehende Benutzer...
for /D %%u in (C:\Users\*) do (
    if exist "%%u\AppData\Roaming" (
        set "CONFIG_DIR=%%u\AppData\Roaming\RustDesk\config"
        if not exist "!CONFIG_DIR!" mkdir "!CONFIG_DIR!"
        echo !TOML_CONTENT! > "!CONFIG_DIR!\RustDesk2.toml"
        echo Config geschrieben fuer %%u
    )
)

:: ==========================
:: 5) Config ins Default-Profil für neue Benutzer
:: ==========================
set "DEFAULT_DIR=C:\Users\Default\AppData\Roaming\RustDesk\config"
if not exist "%DEFAULT_DIR%" mkdir "%DEFAULT_DIR%"
echo %TOML_CONTENT% > "%DEFAULT_DIR%\RustDesk2.toml"
echo Config ins Default-Profil geschrieben.

echo Deployment abgeschlossen.
endlocal
exit /b 0
