@echo OFF
:: Start a new instance of PowerShell requesting admin access, and set it to the directory of the repository (aka. the current directory)
powershell Start-Process powershell.exe -verb runAs -ArgumentList '-NoExit', '-Command', 'cd %CD%'
