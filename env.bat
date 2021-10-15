::env.bat
:: Start a new instance of PowerShell requesting admin access, and set it to the directory of the repository (aka. the current directory)
@echo OFF

:: ----Breakdown----
:: -verb runAs: request admin privileges
:: -NoExit: prevent PowerShell instance from exiting after command is finished; this is important.
:: -'cd %CD%: the command to run; sets the current path of the PowerShell instance to the current directory
powershell Start-Process powershell.exe -verb runAs -ArgumentList '-NoExit', '-Command', 'cd %CD%'