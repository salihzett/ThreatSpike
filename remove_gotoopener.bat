@echo off
echo Stoppe GoTo Opener Prozesse...
taskkill /F /IM "GoTo Opener.exe"

echo Loesche Installationsordner...
rmdir /S /Q "C:\Program Files (x86)\GoTo Opener"

echo Loesche Registry-Eintraege...
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{7659273F-0EB6-4ECB-BC7D-5889F3FD3075}" /f
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{C3DCA297-15FC-436B-98BE-BF286913C38B}" /f

echo Fertig.
pause
