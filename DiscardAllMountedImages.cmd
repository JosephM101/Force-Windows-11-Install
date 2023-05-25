@(set "0=%~f0"^)#) & powershell -nop -c iex([io.file]::ReadAllText($env:0)) & exit/b 

$_Script = {
  Write-Host "Dismounting all mounted Windows images..."
  Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\WIMMount\Mounted Images" | Get-ItemProperty | Select -ExpandProperty "Mount Path" | ForEach-Object {Dismount-WindowsImage -Path $_ -Discard}
  Write-Host "Done."
  Pause
} ; start -verb runas powershell -args "-nop -c & {`n`n$($_Script-replace'"','\"')}"