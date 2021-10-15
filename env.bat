@echo OFF
powershell Start-Process powershell.exe -verb runAs -ArgumentList '-NoExit', '-Command', 'cd %CD%'