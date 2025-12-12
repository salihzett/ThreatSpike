# Threatspike CheatSheet
Threatspike provides an option to use Remote Terminal on SYSTEM level. This cheatsheet can help to administrate the devices.

#### Shutdown & Restart
| Command | Description |
| --- | --- |
| `powershell -Command "Get-MpComputerStatus \| Select-Object AntivirusSignatureLastUpdated"` | Check last Defender Signature version |
| `powershell Update-MpSignature` | Update Defender Signature |
| `%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate` | Update Defender Signature (Alternative) |
| `powershell -Command "Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\' \| Select-Object DisplayVersion, CurrentBuild, ReleaseId" ` | Check Windows OS Version|
| `reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Firefox"` | Check Firefox 64bit version |
| `reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Firefox"` | Check Firefox 32bit version |
| `"C:\Program Files\Mozilla Firefox\uninstall\helper.exe" /S"` | Uninstall Firefox |
| `reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "KeePass"` | Check Keepass 32bit version |
| `reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "PDF24"` | Check PDF24 64bit version |
| `reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "PDF24"` | Check PDF24 32bit version |
| `where pdf24.exe` | Where is PDF24 |
| `"C:\Program Files (x86)\KeePass Password Safe 2\unins000.exe" /VERYSILENT /NORESTART` | Uninstall Keepass |
| `reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{695A895D-DD4C-4E12-9A47-EECEC1AEFB28}" /f` | Uninstall Keepass 2.58 |
| `reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{7C096F52-C65F-4B26-9663-FD293907B241}" /f` | Uninstall Keepass 2.60 |
| `winget uninstall --id DominikReichl.KeePass` | Uninstall Keepass via winget |
| `winget list keepass` | List Keepass via winget |
| `powershell -NoProfile -Command "(Get-Item 'C:\Program Files\Adobe\Adobe Illustrator 2025\Support Files\Contents\Windows\Illustrator.exe').VersionInfo.ProductVersion"` | Check Illustrator version |
| `powershell -NoProfile -Command "(Get-Item 'C:\Program Files\Adobe\Adobe InDesign 2025\InDesign.exe').VersionInfo.ProductVersion"` | Check InDesign version |
| `powershell -NoProfile -Command "(Get-Item 'C:\Program Files\Adobe\Adobe Photoshop 2025\Photoshop.exe').VersionInfo.ProductVersion"` | Check Photoshop version |
| `powershell -NoProfile -Command "(Get-Item 'C:\Program Files\Adobe\Acrobat\Acrobat.exe').VersionInfo.ProductVersion"` | Check Acrobat version |
| `C:\AdobeTools\RemoteUpdateManager.exe --action=list` | List available apps with Adobe |
| `C:\AdobeTools\RemoteUpdateManager.exe --action=download` | Download available apps with Adobe |
| `C:\AdobeTools\RemoteUpdateManager.exe --action=install` | Install available apps with Adobe |
| `C:\AdobeTools\AdobeUninstaller.exe --list --format=TABLE` | Options to remove Adobe |
| `wmic product get name,identifyingnumber` | Search msi package |
| `wmic product get name \| findstr /I “PDF”24` | Search PDF24 package |
| `msiexec /x {GUID} /qn` | Uninstall package |
| `C:\Windows\System32>powershell -command "Get-CimInstance Win32_DesktopMonitor \| Select-Object DeviceID, ScreenWidth, ScreenHeight"` | Check Screens |
| `shutdown /s /t 0` | Shutdown |
| `shutdown /r /t 0` | Restart |
| `shutdown /s /t 60` | Shutdown in 60 secs |
| `shutdown /e /t 60 /c "Device will restart in our hour"` | Restart with message |


not tested
```
msg * "Please save you stuff."
shutdown /s /t 60
```
or
```
powershell -command "[System.Windows.MessageBox]::Show('Message')"
shutdown /s /t 60
```

Fix of Defender issue
```
# Reset 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 0 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /f
# Repair
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow
# Register
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
# Restart
shutdown /r /t 0
# Start Defender
sc start WinDefend
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate

```

Rust
```
# Download
curl -L -o "%TEMP%\rustscript.ps1" "https://ra
w.githubusercontent.com/salihzett/ThreatSpike/refs/heads/main/rust1_4_3.ps1"
#Setup
powershell -ExecutionPolicy Bypass -File "%TEMP%\rustscript.ps1"
# Log:
type "C:\Temp\rustdesk_config_update.log"
2025-11-13 09:53:49 - ==== RustDesk Deployment gestartet ====
2025-11-13 09:53:49 - RustDesk nicht gefunden. Installiere via Winget...
2025-11-13 09:53:54 - RustDesk Installation abgeschlossen.
2025-11-13 09:53:54 - Schreibe Config fÃ¼r alle vorhandenen Benutzer...
2025-11-13 09:53:54 - Config geschrieben fÃ¼r Benutzer: Joe
2025-11-13 09:53:54 - Config ins Default-Profil geschrieben fÃ¼r zukÃ¼nftige Benutzer.
2025-11-13 09:53:54 - ==== RustDesk Deployment abgeschlossen ====
#Check config:
type "C:\Users\username\AppData\Roaming\RustDesk\config\RustDesk2.toml"
```

Download CLCL & Set Shortcut
```
powershell -Command "Invoke-WebRequest -Uri 'https://nakka.com/soft/clcl/download/clcl213.zip' -OutFile 'C:\Temp\clcl213.zip'; Expand-Archive -Path 'C:\Temp\clcl213.zip' -DestinationPath 'C:\Program Files\CLCL' -Force"
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\CLCL.lnk'); $Shortcut.TargetPath = 'C:\Program Files\CLCL\clcl.exe'; $Shortcut.Save()"
```

Download CLCL, Set Shortcut and Check if older version exists
```
powershell -Command "if(Test-Path 'C:\Program Files\CLCL'){Remove-Item 'C:\Program Files\CLCL' -Recurse -Force}; Invoke-WebRequest -Uri 'https://nakka.com/soft/clcl/download/clcl213.zip' -OutFile 'C:\Temp\clcl213.zip'; Expand-Archive -Path 'C:\Temp\clcl213.zip' -DestinationPath 'C:\Program Files\CLCL' -Force; $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('C:\Users\Public\Desktop\CLCL.lnk'); $Shortcut.TargetPath = 'C:\Program Files\CLCL\clcl.exe'; $Shortcut.Save()"```
```


Chocolatery Setup, if not working (ex. installs CLCL)
```
PATH=%PATH%;C:\ProgramData\chocolatey\bin
set PATH=%PATH%;C:\ProgramData\chocolatey\bin
choco install clcl.portable -y
```
