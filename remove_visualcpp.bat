@echo off
echo Lösche Visual C++...

wmic product where "IdentifyingNumber='{1D8E6291-B0D5-35EC-8441-6616F567A0F7}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{ad8a2fa1-06e7-4b0d-927d-6e54b3d31028}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{8122DAB1-ED4D-3676-BB0A-CA368196543E}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{7D0B74C2-C3F8-4AF1-940F-CD79AB4B2DCE}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{53CF6934-A98D-3D84-9146-FC4EDF3D5641}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{0FA68574-690B-4B00-89AA-B28946231449}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{9BE518E6-ECC6-35A9-88E4-87755C07200F}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{EEA66967-97E2-4561-A999-5C22E3CDE428}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{37B8F9C7-03FB-3253-8781-2517C99D7C00}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{010792BA-551A-3AC0-A7EF-0FAB4156C382}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{B175520C-86A2-35A7-8619-86DC379688B9}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{710f4c1c-cc18-4c49-8cbf-51240c89a1a2}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{CF2BEA3C-26EA-32F8-AA9B-331F7E34BA97}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{D401961D-3A20-3AC7-943B-6139D5BD490A}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{2BC3BD4D-FABA-4394-93C7-9AC82A263FE2}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{BD95A8CD-1D9F-35AD-981A-3E7925026EBB}'" call uninstall /nointeractive
wmic product where "IdentifyingNumber='{B0A5A6EE-F8BA-48B1-BB32-BAC17E96C2B4}'" call uninstall /nointeractive

echo Fertig.
