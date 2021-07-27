@ECHO off
setlocal EnableDelayedExpansion
TITLE Simple WIM2ESD / ESD2WIM Converter - By Joel Didier (Studisys)

:: Set DISM Directory
CD /d "%~dp0"
IF EXIST "%CD%\DISM\dism.exe" SET DISM_PATH="%CD%\DISM"

GOTO AdminRightsRoutine



:AdminRightsRoutine
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
	>NUL 2>&1 "%SYSTEMROOT%\SysWOW64\caCLS.exe" "%SYSTEMROOT%\SysWOW64\config\system"
		) ELSE (
	>NUL 2>&1 "%SYSTEMROOT%\system32\caCLS.exe" "%SYSTEMROOT%\system32\config\system"
		)

IF '%ERRORLEVEL%' NEQ '0' (
GOTO GetAdminRights
) ELSE ( GOTO GetAdminRightsSuccess )


:GetAdminRights
CLS
COLOR 17
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                   Administrator Rights Required
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO.  You did not execute the script as Administrator.
ECHO.  Administrator rights are required.
ECHO.  You will now be prompted for Administrator rights.
ECHO.  If you do not grant Administrator rights, this script will not run.
ECHO.
PAUSE
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\GetAdminRights.vbs"
SET params = %*:"=""
ECHO UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\GetAdminRights.vbs"
"%temp%\GetAdminRights.vbs"
DEL "%temp%\GetAdminRights.vbs"
EXIT /B


:GetAdminRightsSuccess
pushd "%CD%"
CD /D "%~dp0"
GOTO Home


:Home
CLS
COLOR 17
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                   	     Welcome
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO.  Welcome to the Simple WIM2ESD / ESD2WIM Converter (version 0.5.0-beta)
ECHO.
ECHO.  This tool allows to quickly convert a WIM Image to an ESD Image, and vice-versa.
ECHO.
ECHO.  Please read the full documentation on :
ECHO.  https://github.com/Studisys/Simple-WIM2ESD---ESD2WIM-Converter/
ECHO.
ECHO.
PAUSE
CALL :CheckVariables


:CheckVariables
CALL :CONVERSIONTYPE
CALL :SRCPATHSET
CALL :DSTPATHSET
CALL :COMPRESSTYPESET
GOTO IndexExport



:CONVERSIONTYPE
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                         Program Parameters
ECHO.                                                  Conversion Type
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO.  What type of conversion do you want ?
ECHO.
ECHO.  [1] WIM --^> ESD
ECHO.  [2] ESD --^> WIM
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c 12qs /n /m "  Your choice :  "
IF %ERRORLEVEL%==1 CALL :WIMESDPRESET
IF %ERRORLEVEL%==2 CALL :ESDWIMPRESET
IF %ERRORLEVEL%==3 EXIT
IF %ERRORLEVEL%==4 GOTO AdminRightsRoutine
GOTO SETVAR

:WIMESDPRESET
SET SRCtype=WIM
SET DSTtype=ESD
SET SRC_PATH=install.wim
SET DST_PATH=install.esd
SET COMPRESS_TYPE=Recovery
GOTO :eof

:ESDWIMPRESET
SET SRCtype=ESD
SET DSTtype=WIM
SET SRC_PATH=install.esd
SET DST_PATH=install.wim
SET COMPRESS_TYPE=Recovery
GOTO :eof

:SETVAR
CALL :SRCPATH
GOTO IndexExport


:SRCPATH
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                Path to Source Image
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO.  Current Path to the source Image is : %SRC_PATH%
ECHO.  Do you wish to change it ?
ECHO.
ECHO. 	[Y] Yes
ECHO.	[N] No
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c ynqs /n /m "Your choice :  "
IF %ERRORLEVEL%==1 CALL :SRCPATHSET
IF %ERRORLEVEL%==2 GOTO DSTPATH
IF %ERRORLEVEL%==3 EXIT
IF %ERRORLEVEL%==4 GOTO AdminRightsRoutine
GOTO DSTPATH


:SRCPATHSET
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                Path to Source Image
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO. Please enter the path to the source image.
ECHO. (Do not include quotes "")
ECHO.
SET /P c=	 Path : 
SET SRC_PATH=%c%
GOTO :eof

:DSTPATH
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                             Path to Destination Image
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO. Current Path to the destination Image is : %DST_PATH%
ECHO. Do you wish to change it ?
ECHO.
ECHO. 	[Y] Yes
ECHO. 	[N] No
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c ynqs /n /m "Your choice :  "
IF %ERRORLEVEL%==1 CALL :DSTPATHSET
IF %ERRORLEVEL%==2 GOTO COMPRESSTYPE
IF %ERRORLEVEL%==3 EXIT
IF %ERRORLEVEL%==4 GOTO AdminRightsRoutine
GOTO COMPRESSTYPE

:DSTPATHSET
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                             Path to Destination Image
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO. Please enter the path to the destination image.
ECHO. (Do not include quotes "")
ECHO.
SET /P c=	 Path : 
SET DST_PATH=%c%
GOTO :eof

:COMPRESSTYPE
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                   Compress Type
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO. Current Compression Type is : %COMPRESS_TYPE%
ECHO. Do you wish to change it ?
ECHO.
ECHO.	[Y] Yes
ECHO. 	[N] No
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c ynqs /n /m "Your choice :  "
IF %ERRORLEVEL%==1 CALL :COMPRESSTYPESET
IF %ERRORLEVEL%==2 GOTO IndexAnalyzer
IF %ERRORLEVEL%==3 EXIT
IF %ERRORLEVEL%==4 GOTO AdminRightsRoutine
GOTO IndexAnalyzer


:COMPRESSTYPESET
CLS
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                   Compress Type
ECHO.                           ================================================================
ECHO.
ECHO.
ECHO. Please enter the compression type.
ECHO.
ECHO. Available Compression Types :
ECHO.
ECHO. [1] None :  No Compression (Fastest) [Destination Image bigger than Source Image]
ECHO.
ECHO. [2] Fast :  Low Compression (Fast) [Destination Image 'may' be bigger than Source Image]
ECHO.
ECHO. [3] Maximum :  Very High Compression (Slow) [Destination Image WAY smaller than Source Image]
ECHO.
ECHO. [4] Recovery :  Insane Compression (Slowest) [Destination Image WAY smaller than Source Image]
ECHO.
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c 1234qs /n /m "Your choice :  "
IF %ERRORLEVEL%==1 (
SET COMPRESS_TYPE=None
)
IF %ERRORLEVEL%==2 (
SET COMPRESS_TYPE=Fast
)
IF %ERRORLEVEL%==3 (
SET COMPRESS_TYPE=Maximum
)
IF %ERRORLEVEL%==4 (
SET COMPRESS_TYPE=Recovery
)
IF %ERRORLEVEL%==5 EXIT
IF %ERRORLEVEL%==6 GOTO AdminRightsRoutine
GOTO IndexAnalyzer


:IndexAnalyzer
CLS
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                 Analyzing %SRCtype% . . .
ECHO.                           ================================================================
ECHO.
setlocal EnableDelayedExpansion
SET /A count=0
FOR /F "tokens=2 delims=: " %%i IN ('DISM /Get-WimInfo /WimFile:"%SRC_PATH%" ^| findstr "Index"') DO SET images=%%i
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
FOR /L %%i in (1, 1, %images%) DO CALL :IndexCounter %%i
ECHO.         The %SRCtype% Image contains the following %images% indexes :
ECHO. 
FOR /L %%i in (1, 1, %images%) DO (
ECHO.  [%%i] !name%%i!
)
ECHO.
ECHO.                           ================================================================
ECHO.
ECHO.         What do you want to do ?
ECHO.
ECHO.  [1] Export a single Index
ECHO.  [2] Export all Indexes
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c 12qs /n /m "Your choice :  "
IF %ERRORLEVEL%==1 GOTO ExportSingleIndex
IF %ERRORLEVEL%==2 GOTO ExportAllIndex
IF %ERRORLEVEL%==3 EXIT
IF %ERRORLEVEL%==4 GOTO AdminRightsRoutine


:IndexCounter
SET /A count+=1
FOR /f "tokens=1* delims=: " %%i IN ('DISM /Get-WimInfo /wimfile:"%SRC_PATH%" /index:%1 ^| find /i "Name"') DO SET name%count%=%%j
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
GOTO :eof


:DEL_DST_PATH
IF EXIST %DST_PATH% (
	DEL /F %DST_PATH%
)
GOTO :eof

:ExportSingleIndex
CLS
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                                                Export Single Index
ECHO.                           ================================================================
ECHO.
ECHO.     Please enter the Index number you want to export.
ECHO.
ECHO.     Here are the Indexes :
ECHO.
FOR /L %%i IN (1, 1, %images%) DO (
ECHO.  [%%i] !name%%i!
)
ECHO.
ECHO.
SET /P INDEXCHOICE= Your choice :  
CLS
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                           ================================================================
ECHO.
ECHO.     This will export Index %INDEXCHOICE% to the destination %DSTtype% Image.
ECHO.
ECHO.     PLEASE NOTE : 
ECHO.     This operation may take a few minutes to complete depending on your PC Hardware.
ECHO.     This operation will use a lot of CPU and Memory ressources.
ECHO.     Your system may be hotter or may seem unresponsive while processing your request.
ECHO.     Please do not interfer with the process before it has ended.
ECHO.
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.                                              Export Single Index
ECHO.                                               Exporting Index %INDEXCHOICE% . . .
ECHO.                           ================================================================
ECHO.
ECHO.
CALL :DEL_DST_PATH
"%DISM_PATH%"\DISM /Export-Image /SourceImageFile:"%SRC_PATH%" /Sourceindex:%INDEXCHOICE% /DestinationImageFile:"%DST_PATH%" /compress:%COMPRESS_TYPE% /CheckIntegrity
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
GOTO SUCCESS




:ExportAllIndex
CLS
TITLE Simple WIM2ESD / ESD2WIM Converter - %SRCtype%2%DSTtype% - Exporting Index 1 / %images% . . . 
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                           ================================================================
ECHO.
ECHO.     This will export all indexes to the destination %DSTtype% Image.
ECHO.
ECHO.     PLEASE NOTE : 
ECHO.     This operation may take a few minutes to complete depending on your PC Hardware.
ECHO.     This operation will use a lot of CPU and Memory ressources.
ECHO.     Your system may be hotter or may seem unresponsive while processing your request.
ECHO.     Please do not interfer with the process before it has ended.
ECHO.
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.                                               Exporting All Indexes
ECHO.                                             Exporting Index 1 of %images% . . .
ECHO.                           ================================================================
ECHO.
ECHO.
CALL :DEL_DST_PATH
"%DISM_PATH%"\DISM /Export-Image /SourceImageFile:"%SRC_PATH%" /Sourceindex:1 /DestinationImageFile:"%DST_PATH%" /compress:%COMPRESS_TYPE% /CheckIntegrity
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
FOR /L %%i IN (2, 1, %images%) DO (
CLS
TITLE %SRCtype%2%DSTtype% - Exporting Index %%i / %images% . . .
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.			                            %SRCtype% --^> %DSTtype%
ECHO.                           ================================================================
ECHO.
ECHO.     This will export all indexes to the destination %DSTtype% Image.
ECHO.
ECHO.     PLEASE NOTE : 
ECHO.     This operation may take a few minutes to complete depending on your PC Hardware.
ECHO.     This operation will use a lot of CPU and Memory ressources.
ECHO.     Your system may be hotter or may seem unresponsive while processing your request.
ECHO.     Please do not interfer with the process before it has ended.
ECHO.
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.                                               Exporting All Indexes . . .
ECHO.                                             Exporting Index %%i of %images% . . .
ECHO.                           ================================================================
ECHO.
ECHO.
"%DISM_PATH%"\DISM /Export-Image /SourceImageFile:"%SRC_PATH%" /SourceIndex:%%i /DestinationImageFile:"%DST_PATH%" /Compress:%COMPRESS_TYPE% /CheckIntegrity
)
IF %ERRORLEVEL% NEQ 0 GOTO ERROR
GOTO SUCCESS



:SUCCESS
CLS
COLOR 17
ECHO.
ECHO.                           ================================================================
ECHO.                                          Simple WIM2ESD / ESD2WIM Converter
ECHO.                                                      Success
ECHO.                           ================================================================
ECHO.
ECHO. Successfully performed requested tasks.
ECHO.
ECHO. Thanks for using my script.
ECHO. GitHub Page : https://github.com/Studisys/Simple-WIM2ESD---ESD2WIM-Converter/
ECHO. Version : 0.5.0-beta
ECHO. Author : Joel Didier (Studisys)
ECHO. Twitter : https://twitter.com/Studisys
ECHO. Email : studisys@protonmail.com
ECHO. 
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c qs /n /m ""
IF %ERRORLEVEL%==1 EXIT
IF %ERRORLEVEL%==2 GOTO AdminRightsRoutine
EXIT

:ERROR
COLOR 17
ECHO.
ECHO.                           ================================================================
ECHO.                                              Simple WIM2ESD Converter
ECHO.                                                       Error
ECHO.                           ================================================================
ECHO.
ECHO. Something wrong occured . . .
ECHO.
ECHO. Currently, there is no log, except the one generated from DISM.
ECHO. This script will generate a complete log in the future.
ECHO. Please send me the error given by DISM and the log located in :
ECHO. C:\WINDOWS\Logs\DISM\dism.log
ECHO.
ECHO.
ECHO. Thanks in advance.
ECHO.
ECHO. GitHub Page : https://github.com/Studisys/Simple-WIM2ESD---ESD2WIM-Converter/
ECHO.
ECHO. Author : Joel Didier (Studisys)
ECHO. Twitter : https://twitter.com/Studisys
ECHO. Email : studisys@protonmail.com
ECHO.
ECHO.                           ================================================================
ECHO.                                        Press 'Q' to exit, 'S' to start over
ECHO.                           ================================================================
ECHO.
CHOICE /c qs /n /m ""
IF %ERRORLEVEL%==1 EXIT
IF %ERRORLEVEL%==2 GOTO AdminRightsRoutine
EXIT