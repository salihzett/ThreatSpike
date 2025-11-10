@echo off
setlocal enabledelayedexpansion

set LOG=%TEMP%\remove_visualcpp.log
echo Starte Deinstallation >> "%LOG%"
echo ===================== >> "%LOG%"

for /f "skip=1 tokens=1" %%i in ('wmic product where "Name like '%%Microsoft Visual%%'" get IdentifyingNumber ^| findstr /r /v "^$"') do (
    rem Prüfen, ob msiexec die GUID wirklich findet
    msiexec /x %%i /quiet /norestart >nul 2>&1
    if errorlevel 1 (
        echo GUID %%i konnte nicht deinstalliert werden oder existiert nicht >> "%LOG%"
    ) else (
        echo GUID %%i erfolgreich deinstalliert >> "%LOG%"
        timeout /t 5 /nobreak >nul
    )
)

echo Fertig! Log: %LOG%
pause
