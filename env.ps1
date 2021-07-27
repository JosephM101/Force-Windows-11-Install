$PSScriptRootd = Get-Location
$rpf = '\"' + $PSScriptRootd + '\"'
Start-Process powershell.exe -verb runAs -ArgumentList "-NoExit -Command (Set-Location $rpf)"
Exit