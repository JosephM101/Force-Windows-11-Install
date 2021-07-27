SET /P win11iso=Windows 11 ISO Path: 
SET /P dest_iso=Destination ISO: 

powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -file %~dp0\Win11-TPM-RegBypass.ps1 -Win11Image %win11iso% -DestinationImage %dest_iso%' -verb RunAs}"