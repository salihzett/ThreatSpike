@echo off
echo Deinstalliere OneDrive for Business Updates...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-0011-0000-1000-0000000FF1CE}_Office16.PROPLUS_{BEE8A3FB-432A-4F06-8A38-F12ADB043344}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-00BA-0407-1000-0000000FF1CE}_Office16.PROPLUS_{BEE8A3FB-432A-4F06-8A38-F12ADB043344}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-00C1-0000-1000-0000000FF1CE}_Office16.PROPLUS_{BEE8A3FB-432A-4F06-8A38-F12ADB043344}" /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{90160000-00C1-0407-1000-0000000FF1CE}_Office16.PROPLUS_{BEE8A3FB-432A-4F06-8A38-F12ADB043344}" /f
echo Fertig.
