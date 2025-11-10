@echo off
set LOGFILE=uninstall.log

echo ============================ >> %LOGFILE%
echo Deinstallation gestartet am %date% %time% >> %LOGFILE%
echo ============================ >> %LOGFILE%

echo Starte Deinstallation...

echo Entferne ICS...
echo Entferne ICS... >> %LOGFILE%
msiexec /x {9881592F-ADE0-430D-8E1E-31F363C1BA28} /qn /L*V %LOGFILE%

echo Entferne HP PC Hardware Diagnostics UEFI...
echo Entferne HP PC Hardware Diagnostics UEFI... >> %LOGFILE%
msiexec /x {924D3ABC-FC75-4042-9DDB-FB846A45848D} /qn /L*V %LOGFILE%

echo Entferne HP Smart Camera (64bit)...
echo Entferne HP Smart Camera (64bit)... >> %LOGFILE%
msiexec /x {C0D3AE68-3407-4449-8CEC-6846700F2913} /qn /L*V %LOGFILE%

echo Entferne HP Wolf Security - Console...
echo Entferne HP Wolf Security - Console... >> %LOGFILE%
msiexec /x {49BDEA48-2A7C-4626-A17D-F5E92D4B2030} /qn /L*V %LOGFILE%

echo Entferne HP Notifications...
echo Entferne HP Notifications... >> %LOGFILE%
msiexec /x {84937F28-9CB4-49E7-A2CF-E32D97E6DAE6} /qn /L*V %LOGFILE%

echo Entferne HP Sure Run Module...
echo Entferne HP Sure Run Module... >> %LOGFILE%
msiexec /x {75B0993A-9D9F-4F9F-A7F5-B0F3AC4C6FE1} /qn /L*V %LOGFILE%

echo Entferne HP System Default Settings...
echo Entferne HP System Default Settings... >> %LOGFILE%
msiexec /x {142F2395-3FCA-46F9-8867-A1968186E087} /qn /L*V %LOGFILE%
msiexec /x {D530265D-C486-4A7F-8FC0-79CE82BB5F6B} /qn /L*V %LOGFILE%

echo Entferne 64 Bit HP CIO Components Installer...
echo Entferne 64 Bit HP CIO Components Installer... >> %LOGFILE%
msiexec /x {50229C72-539F-4E65-BEB5-F0491C5074B7} /qn /L*V %LOGFILE%

echo Entferne HP Sure Recover...
echo Entferne HP Sure Recover... >> %LOGFILE%
msiexec /x {9E05E83B-8C88-46DA-B484-3BF4652884DF} /qn /L*V %LOGFILE%

echo Entferne HP Security Update Service...
echo Entferne HP Security Update Service... >> %LOGFILE%
msiexec /x {ECBD9C21-3CC3-41C2-BA81-FE17685C0205} /qn /L*V %LOGFILE%
msiexec /x {3E6A2F91-E0BA-47AC-8101-132B3A6BCB28} /qn /L*V %LOGFILE%

echo Entferne HP Wolf Security - Console...
echo Entferne HP Wolf Security - Console... >> %LOGFILE%
msiexec /x {63795A78-D0E3-4046-ABA9-168B34986B7A} /qn /L*V %LOGFILE%

echo Entferne HP Wolf Security Application Support (Chrome Versionen)...
echo Entferne HP Wolf Security Application Support (Chrome Versionen)... >> %LOGFILE%

msiexec /x {387845A8-02D1-4A17-A609-4CDD3A25C284} /qn /L*V %LOGFILE%
msiexec /x {FE4C68CA-7616-4209-A797-A19A77F3AD30} /qn /L*V %LOGFILE%
msiexec /x {68E3C76B-6FC8-4993-A424-A92FD5A5F3FB} /qn /L*V %LOGFILE%
msiexec /x {567C0987-AC45-4E4C-ADDF-C8A611C15DA1} /qn /L*V %LOGFILE%
msiexec /x {ECE0A1EF-4AF5-469E-9CB8-29FCFAE6BA1D} /qn /L*V %LOGFILE%
msiexec /x {B05FF260-E8D9-437D-9C02-04A23AC5E8F9} /qn /L*V %LOGFILE%
msiexec /x {3A6B2680-2A97-4DB1-BB67-4AA89E86F18D} /qn /L*V %LOGFILE%
msiexec /x {1DE23EA0-7E93-4166-AADE-55B9F23B7D43} /qn /L*V %LOGFILE%
msiexec /x {1CAA9714-DDCF-4D91-B1E6-D7E98628883F} /qn /L*V %LOGFILE%
msiexec /x {AF1426F4-B847-4EF0-B8E0-B37B49FE93C2} /qn /L*V %LOGFILE%
msiexec /x {BF150435-22FF-4CC9-A0F0-5F562AC6991D} /qn /L*V %LOGFILE%

echo Entferne HP Wolf Security Application Support for Windows...
echo Entferne HP Wolf Security Application Support for Windows... >> %LOGFILE%
msiexec /x {A34EDE79-0A76-409F-B258-FF5D1CAE6B8F} /qn /L*V %LOGFILE%

echo ============================ >> %LOGFILE%
echo Deinstallation beendet am %date% %time% >> %LOGFILE%
echo ============================ >> %LOGFILE%

echo Fertig!
pause
exit /b
