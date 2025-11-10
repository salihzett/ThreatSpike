@echo off
setlocal enabledelayedexpansion

:: Log-Datei
set LOG=%TEMP%\remove_visualcpp.log
echo Starte Deinstallation von Microsoft Visual C++ Redistributables > "%LOG%"
echo ================================ >> "%LOG%"

:: Zähle gefundene Pakete
set COUNT=0

:: Alle MSI-Produkte mit "Microsoft Visual" im Namen
for /f "skip=1 tokens=1,* delims= " %%i in ('wmic product where "Name like '%%Microsoft Visual%%'" get IdentifyingNumber ^| findstr /r /v "^$"') do (
    set /a COUNT+=1
    echo Deinstalliere %%i ...
    echo !DATE! !TIME! - Deinstalliere GUID %%i >> "%LOG%"
    
    :: Deinstallation still, ohne Neustart
    msiexec /x %%i /quiet /norestart

    :: 5 Sekunden warten
    timeout /t 5 /nobreak >nul
)

if %COUNT%==0 (
    echo Keine Microsoft Visual C++ Redistributables gefunden. >> "%LOG%"
) else (
    echo Fertig! %COUNT% Pakete deinstalliert. >> "%LOG%"
)

echo Deinstallation abgeschlossen. Log-Datei: %LOG%
pause
