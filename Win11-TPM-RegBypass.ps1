# Ascii graphics generated using https://patorjk.com/software/taag/
<# 
__        __  _           _   _     _____   ____    __  __     ____                                     
\ \      / / (_)  _ __   / | / |   |_   _| |  _ \  |  \/  |   | __ )   _   _   _ __    __ _   ___   ___ 
 \ \ /\ / /  | | | '_ \  | | | |     | |   | |_) | | |\/| |   |  _ \  | | | | | '_ \  / _` | / __| / __|
  \ V  V /   | | | | | | | | | |     | |   |  __/  | |  | |   | |_) | | |_| | | |_) || (_| | \__ \ \__ \
   \_/\_/    |_| |_| |_| |_| |_|     |_|   |_|     |_|  |_|   |____/   \__, | | .__/  \__,_| |___/ |___/
                                                                       |___/  |_|                       
#>

<# 
This script/project was made possible by the following software and projects:

- AveYo's Skip_TPM_Check_on_Dynamic_Update.cmd script (https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd)
- 7-Zip (https://www.7-zip.org)
#>

[CmdletBinding(DefaultParametersetName='Main')] 
param
(
    [Parameter(ParameterSetName='Extra2',Mandatory=$false)][switch] 
    $UndoPrepareUpgrade = $false,

    [Parameter(ParameterSetName='Extra',Mandatory=$false)][switch] 
    $PrepareUpgrade = $false,

    # Allow parameter to be passed even if -PrepareUpgrade was passed, but don't make it mandatory.
    [Parameter(Position=0,ParameterSetName='Extra',ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Parameter(Position=0,ParameterSetName='Main',Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()] 
    [string]
    $Source,

    # Allow parameter to be passed even if -PrepareUpgrade was passed, but don't make it mandatory.
    [Parameter(Position=1,ParameterSetName='Extra',ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Parameter(Position=1,ParameterSetName='Main',Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()] 
    [string]
    $Destination,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $InjectVMwareTools = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $InjectPostPatch = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $GuiSelectMode = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [string]
    $SetTargetInsiderLevel,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $HideTimestamps = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $VerboseMode = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $SkipReg = $false,

    [Parameter(ParameterSetName='Extra')]
    [Parameter(ParameterSetName="Main")]
    [switch]
    $UseNewPatch = $false
)

process
{
    $version = 1.3
    $version_s = "$version"

    # The first thing we should do is check if this script is running on anything but Windows, and terminate with a message if that's the case.
    if($IsWindows -eq $false) { Write-Host "This script will only work on Windows systems." -ForegroundColor Red ; Exit }

    Function MakeDirectory ($path) {
        if($VerboseMode) {
            mkdir $path
        } else {
            (mkdir $path) > $null
        }
    }

    Function FormatTimespan {
        $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
        return $totalTime
    }

    Function PrintTimespan ($strPrefix, $inputTimespan) {
        if($HideTimestamps -eq $false) {
            $strOutput = ""
            $strOutput += $strPrefix
            $strOutput += FormatTimespan $inputTimespan
            Write-Host $strOutput -ForegroundColor Green
        }
    }

    $OldLocation = Get-Location
    
    $DefaultWindowStyle = "Normal"
    $ActivityName = "Win11-TPM-Bypass"

    # if($VerboseMode) {
    #     $DefaultWindowStyle = "Normal"
    # }

    # Declarations
    
    $Is64BitSystem = [Environment]::Is64BitOperatingSystem

    $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    #$ScriptExec = $script:MyInvocation.MyCommand.Path
    $7ZipExecutable = Join-Path -Path $ScriptDir -ChildPath "7z\7z.exe"
    $oscdimgExecutable = ".\oscdimg\oscdimg"
    $oscdimgExecutableFull = Join-Path -Path $ScriptDir -ChildPath "oscdimg\oscdimg.exe"
    $ScratchDir = "C:\Scratch"
    $WIMScratchDir = Join-Path -Path $ScratchDir -ChildPath "WIM"
    $Win11ScratchDir = Join-Path -Path $ScratchDir -ChildPath "W-ISO"
    $BootWIMFilePath = Join-Path -Path $Win11ScratchDir -ChildPath "sources\boot.wim"
    $InstallWIMFilePath = Join-Path -Path $Win11ScratchDir -ChildPath "sources\install.wim"
    $InstallWIMMountPath = Join-Path -Path $ScratchDir -ChildPath "INSTALL_WIM"

    # Installation part of boot.wim is located at WIM index 2.
    $BootWimImageIndex = 2
    
    $sb_bypass_keyname = "win11-tpm-sb-bypass"
    $sb_bypass_key = Join-Path -Path $Win11ScratchDir -ChildPath ("\sources\" + $sb_bypass_keyname)
    $PostSetupScriptsPath = "Windows\Setup\Scripts"

    # Do not use
    $PostPatchCMDFilename = "SkipTPM.cmd"

    $SkipTPMCheckOnDynamicUpdate_Filename = "Skip_TPM_Check_on_Dynamic_Update.cmd"
    $PostPatchPS1Filename = "SkipTPM.ps1"
    $Temp_PostSetupOperations = Join-Path -Path $ScratchDir -ChildPath "PostSetup"
    $Temp_PostSetupOperations_ScriptDirectory = Join-Path -Path $Temp_PostSetupOperations -ChildPath $PostSetupScriptsPath
    $VMwareTempFolderName = "vmwaretools"
    $VMwareToolsScratchDir = Join-Path -Path $Temp_PostSetupOperations -ChildPath "vmwaretools"
    #$MountDir_Setup = Join-Path -Path $VMwareToolsScratchDir -ChildPath $PostSetupScriptsPath
    $VMwareToolsISOPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "VMware\VMware Workstation\windows.iso"
    $32Bit_System_Error_Message = "ERROR: This device does not support Windows 11, as it is a 32-bit device. Windows 11 will only run on 64-bit devices."

    $PostPatch_WMISubscriptionName = 'Skip TPM Check on Dynamic Update'

    Function GetPercentageFromRange ($value, $minV, $maxV) {
        $percentage = ($value - $minV) / ($maxV - $minV)
        return [int] ($percentage * 100)
    }

    Function Test-CommandExists {
        Param ($command)
        $oldPreference = $ErrorActionPreference
        $ErrorActionPreference = 'stop'
        try {if(Get-Command $command){return $true}}
        Catch {return $false}
        Finally {$ErrorActionPreference=$oldPreference}
    }

    Function VerifySwitches {
        # VMware Tools Switch
        if($InjectVMwareTools) {
            if (!(Test-Path $VMwareToolsISOPath)) {
                Write-Host "VMware Tools doesn't seem to exist at the path we expected it to be ($VMwareToolsISOPath)." -ForegroundColor Red
                Pause
                Exit
            }
        }
    }

    Function HasAdminPrivileges {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    Function CleanupScratch {
        if(Test-Path $ScratchDir) {
            # Write-Host "INFO: Deleting old Scratch directory..." -ForegroundColor Yellow
            DISM_DismountAllImages
            Remove-Item -Path $ScratchDir -Force -Recurse
        }
    }
    
    Function CollectGarbage {
        Write-Host "Cleaning up..."
        [gc]::Collect(1000, [System.GCCollectionMode]::Forced , $true) # Clean up
        [gc]::WaitForPendingFinalizers() # Wait for cleanup process to finish
        #Start-Sleep 1
    }    
    
    Function DISM_DismountAllImages {
        Write-Host "Dismounting all mounted Windows images..."
        #Get-WindowsImage -Mounted -ErrorAction Stop | ForEach-Object {
	    #    Dismount-WindowsImage -Path $_.Path -Discard #-ErrorAction Stop
        #}
        Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\WIMMount\Mounted Images" | Get-ItemProperty | Select-Object -ExpandProperty "Mount Path" | ForEach-Object {Dismount-WindowsImage -Path $_ -Discard}
    }

    Function TerminateS_Premature {
        CollectGarbage
        CleanupScratch | Out-Null
        Write-Host "Process terminated."
        Exit
    }

    # Alert the user if the source image has already been modified by this tool
    Function Alert_ImageModified {
        # $inputF = Read-Host -Prompt "Are you sure you want to continue? [y/n]"
        $inputF = Read-Host -Prompt "Continue anyway? [y/n]"
        if(($inputF -ne "y") -and ($inputF -ne "n"))
        {
            Write-Host "Invalid input: $inputF" -ForegroundColor Red
            Alert_ImageModified
        }
        else
        {
            if($inputF -eq "n")
            {
                TerminateS_Premature
            }
        }
    }

    Function AskQuestion {
        param (
            $question
        )

        $inputF = Read-Host -Prompt "$question [y/n]"
        if(($inputF -ne "y") -and ($inputF -ne "n"))
        {
            Write-Host "Invalid input: $inputF" -ForegroundColor Red
            return AskQuestion $question $defaultAnswer
        }
        else
        {
            if($inputF -eq "n")
            {
                return $false
            }
        }
        return $true
    }

    # Check to see if the destination image exists before continuing.
    Function Alert_DestinationImageAlreadyExists {
        $inputF = Read-Host -Prompt "The destination image already exists. Do you want to overwrite it? [y/n]"
        if(($inputF -ne "y") -and ($inputF -ne "n"))
        {
            Write-Host "Invalid input: $inputF" -ForegroundColor Red
            Alert_DestinationImageAlreadyExists
        }
        else
        {
            if($inputF -eq "n")
            {
                TerminateS_Premature
            }
            if($inputF -eq "y")
            {
                Remove-Item -Path $Destination -Force
            }
        }
    }

    Function AnnounceProgress_RunningExtraTasks {
        Write-Progress -Activity $ActivityName -Status "Executing extra tasks..." -PercentComplete 75
    }

    # Features

    Function InjectRegistryKeys {
        # Mount and edit the setup environment's registry
        Write-Progress -Activity $ActivityName -Status "Editing image registry..." -PercentComplete 60
        $REG_System = Join-Path $WIMScratchDir -ChildPath "\Windows\System32\config\system"
        $VirtualRegistryPath_SYSTEM = "HKLM\WinPE_SYSTEM"
        $VirtualRegistryPath_Setup = $VirtualRegistryPath_SYSTEM + "\Setup"
        # $VirtualRegistryPath_LabConfig = $VirtualRegistryPath_Setup + "\LabConfig"
        reg unload $VirtualRegistryPath_SYSTEM | Out-Null # Just in case...
        Start-Sleep 1
        reg load $VirtualRegistryPath_SYSTEM $REG_System | Out-Null

        Set-Location -Path Registry::$VirtualRegistryPath_Setup
       
        New-Item -Name "LabConfig"
        New-ItemProperty -Path "LabConfig" -Name "BypassTPMCheck" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path "LabConfig" -Name "BypassSecureBootCheck" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path "LabConfig" -Name "BypassRAMCheck" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path "LabConfig" -Name "BypassStorageCheck" -Value 1 -PropertyType DWORD -Force
        New-ItemProperty -Path "LabConfig" -Name "BypassCPUCheck" -Value 1 -PropertyType DWORD -Force

        Set-Location -Path $ScriptDir
        CollectGarbage
        Start-Sleep 1
        reg unload $VirtualRegistryPath_SYSTEM
        # Start-Sleep 1
    }

    
    # Create the directory structure that will be replicated on the installation images
    Function GeneratePostSetupFileStructure {
        MakeDirectory $Temp_PostSetupOperations
        MakeDirectory $Temp_PostSetupOperations_ScriptDirectory
        
        # Generate SetupComplete.cmd file
        $SetupCompleteCMD = Join-Path -Path $Temp_PostSetupOperations_ScriptDirectory -ChildPath "SetupComplete.cmd"

        if ($InjectVMwareTools) { 
            # Add commands to SetupComplete.cmd file to make the VMware Tools installer run durig the post-setup process

            $VMwareInstall = 
@"
C:\$VMwareTempFolderName\setup64.exe /S /v "/qn REBOOT=R ADDLOCAL=ALL"
rmdir C:\$VMwareTempFolderName /s /q
"@
            # Copy the contents of the installer to the root of the structure; folder name defined by $VMwareTempFolderName
            
            # Make our temporary directory for VMware Tools
            MakeDirectory $VMwareToolsScratchDir # C:/Scratch/PostSetup/vmware

            # Extract the VMware Tools ISO to that directory
            & $7ZipExecutable x $VMwareToolsISOPath ("-o" + ($VMwareToolsScratchDir)) | Out-Null
        }

        if ($InjectPostPatch) { $PatchInject =
@"
:: cmd /c start /wait C:\$PostSetupScriptsPath\$PostPatchCMDFilename
powershell.exe -executionpolicy Bypass -file "C:\$PostSetupScriptsPath\$PostPatchPS1Filename"
"@ }


        # Finally, combine all of the SetupComplete commands into a single string to be written to the file.
        $SetupCompleteCMDContents = 
@"
$PatchInject
$VMwareInstall
:: Registry patches
reg add HKEY_CURRENT_USER\Control Panel\UnsupportedHardwareNotificationCache
reg add HKEY_CURRENT_USER\Control Panel\UnsupportedHardwareNotificationCache\SV2 /v 0 /t REG_DWORD /d 0 /f
rmdir C:\Windows\Setup\Scripts /s /q
"@

        # Write SetupComplete.cmd contents to file in scratch directory
        $stream = [System.IO.StreamWriter] $SetupCompleteCMD
        $stream.Write(($SetupCompleteCMDContents -join "`r`n"))
        $stream.close()

        if ($InjectPostPatch) {

#             $PS1_Contents_v2 = @'
# $N = 'Skip TPM Check on Dynamic Update'
# $0 = Set-ItemProperty 'HKLM:\SYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 1 -type dword -force -ea 0
# $C = "cmd /q $N /d/x/r>nul (erase /f/s/q %systemdrive%\`$windows.~bt\appraiserres.dll"
# $C+= '&md 11&cd 11&ren vd.exe vdsldr.exe&robocopy "../" "./" "vdsldr.exe"&ren vdsldr.exe vd.exe&start vd -Embedding)&rem;'
# $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
# $0 = New-Item $K -force -ea 0
# Set-ItemProperty $K 'Debugger' $C -force
# '@

#             $PS1_Contents_v4 = @'
# $N = "Skip TPM Check on Dynamic Update"; $X = @("' $N (c) AveYo 2021 : v4 IFEO-based with no flashing cmd window") 
# $X+= 'C = "cmd /q AveYo /d/x/r pushd %systemdrive%\\$windows.~bt\\Sources\\Panther && mkdir Appraiser_Data.ini\\AveYo&"'
# $X+= 'M = "pushd %allusersprofile%& ren vd.exe vdsldr.exe &robocopy ""%systemroot%/system32/"" ""./"" ""vdsldr.exe""&"'
# $X+= 'D = "ren vdsldr.exe vd.exe& start vd.exe -Embedding" : CreateObject("WScript.Shell").Run C & M & D, 0, False'    
# $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
# $P = [Environment]::GetFolderPath('CommonApplicationData'); $F = join-path $P '11tpm.vbs'; $V = "wscript $F //B //T:5"
# new-item $K -force -ea 0 >''; set-itemproperty $K 'Debugger' $V -force -ea 0; [io.file]::WriteAllText($F, $X-join"`r`n")
# rmdir $([Environment]::SystemDirectory[0]+':\\$Windows.~BT\\Sources\\Panther') -rec -force -ea 0
# '@

            $PS1_Contents_v5 = @'
$N = "Skip TPM Check on Dynamic Update"; $X = @("' $N (c) AveYo 2021 : v4 IFEO-based with no flashing cmd window") 
$X+= 'C = "cmd /q AveYo /d/x/r pushd %systemdrive%\\$windows.~bt\\Sources\\Panther && mkdir Appraiser_Data.ini\\AveYo&"'
$X+= 'M = "pushd %allusersprofile%& ren vd.exe vdsldr.exe &robocopy ""%systemroot%/system32/"" ""./"" ""vdsldr.exe""&"'
$X+= 'D = "ren vdsldr.exe vd.exe& start vd.exe -Embedding" : CreateObject("WScript.Shell").Run C & M & D, 0, False'    
$K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
$P = [Environment]::GetFolderPath('CommonApplicationData'); $F = join-path $P '11tpm.vbs'; $V = "wscript $F //B //T:5" 
if (test-path $K) {
  remove-item $K -force -ea 0 >''; del $F -force -ea 0; del (join-path $P 'vd.exe') -force -ea 0
  write-host -fore 0xf -back 0xd "`n $N v4 [REMOVED] run again to install "
} else {
  new-item $K -force -ea 0 >''; set-itemproperty $K 'Debugger' $V -force -ea 0; [io.file]::WriteAllText($F, $X-join"`r`n")
  write-host -fore 0xf -back 0x2 "`n $N v4 [INSTALLED] run again to remove "
} ;  rmdir $([Environment]::SystemDirectory[0]+':\\$Windows.~BT\\Sources\\Panther') -rec -force -ea 0; timeout /t 5
'@

# ---------------------------------------------------------------------------------------
# Generate the script
# ---------------------------------------------------------------------------------------

            $PS1_Fallback = $PS1_Contents_v5
            $PS1ScriptContents = ""

            if ($UseNewPatch) {
                try {
                    # Get CMD contents from online file: https://github.com/AveYo/MediaCreationTool.bat/raw/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd
                    $CMD_Contents = [System.Net.WebClient]::DownloadString('https://raw.githubusercontent.com/AveYo/MediaCreationTool.bat/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd')

                    # Create a new cmd file in scratch directory, and write the contents to it.
                    $cmdFilepath = Join-Path -Path $Temp_PostSetupOperations_ScriptDirectory -ChildPath $SkipTPMCheckOnDynamicUpdate_Filename
                    [System.IO.File]::WriteAllText($cmdFilepath, $CMD_Contents)

                    # Set the contents of the PS1 script to execute the cmd file, which will be in the same directory.
                    $PS1ScriptContents = "Invoke-Item -Path $SkipTPMCheckOnDynamicUpdate_Filename"
                    
                }
                catch {
                    $PS1ScriptContents = ($PS1_Fallback -join "`r`n")
                }
            }
            else {
                $PS1ScriptContents = ($PS1_Fallback -join "`r`n")
            }

            $ps1Filepath = Join-Path -Path $Temp_PostSetupOperations_ScriptDirectory -ChildPath $PostPatchPS1Filename
            [System.IO.File]::WriteAllText($ps1Filepath, $PS1ScriptContents)
        }
    }

    <#
    .DESCRIPTION
    Shortcut method for function InjectExtraPatches that copies the generated patch folder and files to the specified mounted image.
    #>
    Function CopyPostSetupFiles ([string] $WIMFilePath, [string] $MountPath, [uint32] $WIMIndex) {
        $StartTime = $(get-date)

        Mount-WindowsImage -ImagePath $WIMFilePath -Index $WIMIndex -Path $MountPath
        Get-ChildItem $Temp_PostSetupOperations | Copy-Item -Destination $MountPath -Recurse -Force
        Dismount-WindowsImage -Path $MountPath -Save

        # Print time elapsed
        $elapsedTime = $(get-date) - $StartTime
        # Write-Host "Modifying edition index $WIMIndex took $(FormatTimespan $elapsedTime)" -ErrorAction SilentlyContinue -ForegroundColor Green
        PrintTimespan "Modifying edition index $WIMIndex took " $elapsedTime
    }

    <#
    .DESCRIPTION
    InjectExtraPatches injects patches into the install.wim image as per the user's request. If the image contains more than one edition, the user will be asked if they want to modify one or all. Some of these patches include VMware Tools, and patches that allow future in-place upgrades.
    #>
    Function InjectExtraPatches {
        AnnounceProgress_RunningExtraTasks
        Write-Host "Preparing to modify install.wim..."
        MakeDirectory $InstallWIMMountPath # Make our mount directory for install.wim...

        GeneratePostSetupFileStructure

        # Get information and list of its editions from install.wim
        Write-Host "Getting install.wim info..."
        $WIMEditions = Get-WindowsImage -ImagePath $InstallWIMFilePath

        # If there is more than one edition in the install.wim image, ask the user which edition(s) they want to modify
        if ($WIMEditions.Count -gt 1) {
            # install.wim has more than one edition. Give the user the option to select editions to modify.
	    
	        # Create an empty list
	        $EditionList = @()
	    
            Write-Host "The install.wim image contains multiple editions. Select the editions you want to modify (editions not selected will be excluded from the new image)." -ForegroundColor Yellow
            Write-Host ""
	    
            # Go through and log editions
            foreach ($WIMedition in $WIMEditions) {
                $EditionList += ($WIMedition.ImageIndex.ToString() + ": " + $WIMedition.ImageName)
            }

            # Ask user to select what editions to modify
            $ModifyAll = $false

            # Get number of editions
            $WIMEditionsCount = 1..$WIMEditions.Count
            $options = New-Object System.Collections.Generic.HashSet[int]

            if ($GuiSelectMode) {
                $selected = $EditionList | Out-GridView -Title "Select editions to modify. Leave none selected to modify all." -OutputMode Multiple

                if($selected.Count -eq 0) {
                    #Write-Host "Modifying all..."
                    $ModifyAll = $true
                } else {
                    #Write-Host "Selected: $selected"
                }

                $Selection = foreach($item in $selected) {
                    try {
                        #[int]::Parse($item)
			            ($EditionList.indexOf($item) + 1)
                        #Write-Host $item
                    }
                    catch{}
                }
            } else {
                # Print editions from $EditionList
                $EditionList | ForEach-Object {"$PSItem"}

                Write-Host "" # Write empty line
                Write-Host "Enter a selection from 1 to $($WIMEditionsCount.Count), and press Enter to select that edition. When you're done, press Enter again to confirm your choices. If nothing is selected, all editions will be modified."
                do {
                    $userInput = Read-Host "($options)"
                    if ($userInput -eq "") {
                        continue
                    }
                    if ($userInput -notin $WIMEditionsCount) {
                        Write-Host "Invalid value entered." -ForegroundColor Red
                        continue
                    }
                    elseif ($userInput -in $options) {
                        do {
                            $inputF = Read-Host -Prompt "$userInput is already selected. Do you want to deselect it? [y/n]"
                            } while ($userInput -notcontains $inputF)
                        
                        if($inputF -eq "y") {
                            $options.Remove($userInput) | Out-Null
                        }
                        continue
                    }
                    else {
                        $options.Add($userInput) | Out-Null
                    }
                } while ($userInput -ne "")

                if ($options.Count -eq 0) {
                    #Write-Host "Modifying all..."
                    $ModifyAll = $true
                }
                else {
                    Write-Host ""
                    Write-Host "Options selected: $options"
                }

                $Selection = foreach($indexEntry in $options) {
                    try {
                        [int]::Parse($indexEntry)
                        #Write-Host $indexEntry
                    }
                    catch{}
                }
            }

            # Write-Host $Selection
            # $Selection = foreach($indexEntry in ($Multi_Options -Split ",")) {

            if(($Selection.Count -gt 1) -and ($Selection.Contains(0))) { # If individual editions were selected, check to see if a 0 exists, and remove it if the length of the list is larger than 1.
                $Selection = $Selection | Where-Object { $_ -ne 0 }
            }

            $Selection = $Selection | Select-Object -uniq # Remove duplicates from the array; not really necessary considering that the above selection method prevents that. We'll just keep it here for good measure.

            $Selection | ForEach-Object { $WIMEditions[$PSItem - 1].ImageName }

            # Get current time
            $TotalStartTime = $(get-date)

            if ($ModifyAll) {
                Write-Host "Processing all"
                foreach ($edition in $WIMEditions) {
                    $PercentageComplete = GetPercentageFromRange $edition.ImageIndex 0 $WIMEditions.Count
                    Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $edition.ImageName + " (" + $edition.ImageIndex.ToString() + "/" + $WIMEditions.Count.ToString() + ")") -PercentComplete $PercentageComplete
                    CopyPostSetupFiles $InstallWIMFilePath $InstallWIMMountPath $edition.ImageIndex
                }
                CleanWIM $InstallWIMFilePath $SelectedIndex
            }
            else {
                $EditionsToProcess = foreach ($edition in $WIMEditions) {
                    if ($Selection -contains $edition.ImageIndex) {
                        $edition
                    }
                }
                $EditionsToProcess
                Write-Host ""
                $CurrentIndex = 0
                foreach ($edition in $EditionsToProcess) {
                    $CurrentIndex++
                    $PercentageComplete = GetPercentageFromRange ($CurrentIndex - 1) 0 $EditionsToProcess.Count
                    Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $edition.ImageName + " (" + $CurrentIndex.ToString() + "/" + $EditionsToProcess.Count.ToString() + ")") -PercentComplete $PercentageComplete
                    CopyPostSetupFiles $InstallWIMFilePath $InstallWIMMountPath $edition.ImageIndex
                    Start-Sleep 1
                }
                CleanWIM $InstallWIMFilePath $EditionsToProcess
            }

            # Print time elapsed
            $TotalElapsedTime = $(get-date) - $TotalStartTime
            # Write-Host "Done. Took $(FormatTimespan $TotalElapsedTime)" -ErrorAction SilentlyContinue -ForegroundColor Green
            PrintTimespan "Process complete. Took " $TotalElapsedTime
        }
        else { # There's only one edition in the WIM file.
            Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $WIMEditions[0].ImageName + " (" + $WIMEditions[0].ImageIndex.ToString() + "/" + $WIMEditions.Count.ToString() + ")") -PercentComplete 0
            CopyPostSetupFiles $InstallWIMFilePath $InstallWIMMountPath $WIMEditions[0].ImageIndex
        }
    }

    # Function Sub_InjectVMwareTools ([string] $WIMFilePath, [string] $MountPath, [uint32] $WIMIndex, [string] $VMwareToolsSource) {
    #     # Scratch directory for VMware Tools
    # 
    #     # Prepare everything we need in the VMware Tools scratch directory.
    #     MakeDirectory $VMwareToolsScratchDir #... and our temporary directory for VMware Tools
    # 
    #     # Extract the VMware Tools ISO
    # 
    #     MakeDirectory $MountDir_Setup
    #     & $7ZipExecutable x $VMwareToolsISOPath ("-o" + (Join-Path -Path $VMwareToolsScratchDir -ChildPath $VMwareTempFolderName)) | Out-Null
    #     Copy-Item ($VMwareToolsSource + "\*") ($MountPath + "\") -Recurse -Force # | Out-Null
    # }
    # 
    # Function Sub_InjectPostPatch ([string] $WIMFilePath, [string] $MountPath, [uint32] $WIMIndex) {
    #     
    # }

    
    Function CleanWIM ([string] $WIMFilePath, $KeepEditions) {
        $OLD = $WIMFilePath + ".old"
        Move-Item $WIMFilePath $OLD -Force
        foreach ($edition in $KeepEditions)
        {
            Export-WindowsImage -SourceImagePath $OLD -SourceIndex $edition.ImageIndex -DestinationImagePath $WIMFilePath -CompressionType Max
        }
        Remove-Item $OLD -Force
    }

    # Quick verbose function that checks whether a file exists or not.
    Function CheckExists ($FilePath, $ItemName, $Description) {
        Write-Host "Checking if $ItemName exists..." -ForegroundColor Yellow -NoNewline
        $file_exists = Test-Path $FilePath
        if (!$file_exists)
        {
            Write-Host " no" -ForegroundColor Red
            Write-Host "$($ItemName): $Description does not exist" -ForegroundColor Red
            Exit
        }
        else {
            Write-Host " yes" -ForegroundColor Green
        }
    }

    # Make changes to the local system to allow in-place upgrades.
    Function PrepareSystemForUpgrade {
        if ($PrepareUpgrade) {
            if ($Is64BitSystem) {
                Write-Host "Preparing system for in-place upgrades..." -ForegroundColor Yellow -NoNewline

                Write-Host "WARNING: This operation has not yet been updated for newer Windows builds." -ForegroundColor Yellow -NoNewline
                if (AskQuestion "Are you sure you want to continue?")
                {
                    $N = "Skip TPM Check on Dynamic Update"; $X = @("' $N (c) AveYo 2021 : v4 IFEO-based with no flashing cmd window") 
                    $X+= 'C = "cmd /q AveYo /d/x/r pushd %systemdrive%\\$windows.~bt\\Sources\\Panther && mkdir Appraiser_Data.ini\\AveYo&"'
                    $X+= 'M = "pushd %allusersprofile%& ren vd.exe vdsldr.exe &robocopy ""%systemroot%/system32/"" ""./"" ""vdsldr.exe""&"'
                    $X+= 'D = "ren vdsldr.exe vd.exe& start vd.exe -Embedding" : CreateObject("WScript.Shell").Run C & M & D, 0, False'    
                    $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
                    $P = [Environment]::GetFolderPath('CommonApplicationData'); $F = join-path $P '11tpm.vbs'; $V = "wscript $F //B //T:5"
                    New-Item $K -force -ea 0 >''; set-itemproperty $K 'Debugger' $V -force -ea 0; [io.file]::WriteAllText($F, $X-join"`r`n")
                    Remove-Item $([Environment]::SystemDirectory[0]+':\\$Windows.~BT\\Sources\\Panther') -rec -force -ea 0

                    Write-Host " done" -ForegroundColor Green
                    Write-Host "System patched." -ForegroundColor Green
                    # Write-Host "You can now try upgrading, but you may need to reboot your system for the changes to take effect."
                }
                else {
                    Write-Host "Exiting..." -ForegroundColor Red
                }
            } else {
                Write-Host $32Bit_System_Error_Message -ForegroundColor Red
            }
        }
    }

    Function Undo_PrepareSystemForUpgrade {
        if ($Is64BitSystem) {
            Write-Host "Operation: Undo changes made by -PrepareUpgrade" -NoNewline
            Write-Host "Undoing system changes..." -NoNewline

            $N = $PostPatch_WMISubscriptionName
            $null = Set-ItemProperty 'HKLM:\SYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 0 -type dword -force -ea 0
            $B = Get-WmiObject -Class __FilterToConsumerBinding -Namespace 'root\subscription' -Filter "Filter = ""__eventfilter.name='$N'""" -ea 0
            $C = Get-WmiObject -Class CommandLineEventConsumer -Namespace 'root\subscription' -Filter "Name='$N'" -ea 0
            $F = Get-WmiObject -Class __EventFilter -NameSpace 'root\subscription' -Filter "Name='$N'" -ea 0
            if ($B) { 
                $B | Remove-WMIObject 
            }
            if ($C) { 
                $C | Remove-WMIObject 
            } 
            if ($F) { 
                $F | Remove-WMIObject 
            }
            $K = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\vdsldr.exe'
            if (test-path $K) {
                Remove-Item $K -force -ea 0
            }

            Write-Host " done" -ForegroundColor Green
            Write-Host "Modifications that were made to your PC by the -PrepareUpgrade flag have been reverted. You may need to reboot for the changes to take effect." -ForegroundColor Yellow
        } else {
            Write-Host $32Bit_System_Error_Message -ForegroundColor Red
            Write-Host "Nothing to undo."
        }
    }

#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#
#  ______                    _   _     _                ____             _              _    _               
# |  ____|                  | | | |   (_)              |  _ \           (_)            | |  | |              
# | |____   _____ _ __ _   _| |_| |__  _ _ __   __ _   | |_) | ___  __ _ _ _ __  ___   | |__| | ___ _ __ ___ 
# |  __\ \ / / _ \ '__| | | | __| '_ \| | '_ \ / _` |  |  _ < / _ \/ _` | | '_ \/ __|  |  __  |/ _ \ '__/ _ \
# | |___\ V /  __/ |  | |_| | |_| | | | | | | | (_| |  | |_) |  __/ (_| | | | | \__ \  | |  | |  __/ | |  __/
# |______\_/ \___|_|   \__, |\__|_| |_|_|_| |_|\__, |  |____/ \___|\__, |_|_| |_|___/  |_|  |_|\___|_|  \___|
#                       __/ |                   __/ |               __/ |                                    
#                      |___/                   |___/               |___/                                     
#
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------

    Write-Host "Windows 11 Compatibility Check Bypass Tool $version_s"
    Write-Host "If you run into any issues, please don't hesitate to open an issue on the GitHub repository." -ForegroundColor Yellow

    Write-Host "Checking for administrative privileges..."
    if(!(HasAdminPrivileges)) {
        # powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -file $ScriptExec -Win11Image $Source -DestinationImage $Destination' -verb RunAs}"
        Write-Host "This script requires administrative privileges to run." -ForegroundColor Red
        Exit
    }

    if($UndoPrepareUpgrade) {
        # Undo any changes made by -PrepareUpgrade
        Undo_PrepareSystemForUpgrade
        Exit
    }

    if($PrepareUpgrade) {
        if([string]::IsNullOrEmpty($Source) -or [string]::IsNullOrEmpty(($Destination))) {
            Write-Host "Prepare system for upgrade"
            PrepareSystemForUpgrade
            Exit
        }
    }

    # Import DISM module
    $DISMModule_ErrorMessage = "Could not import DISM module. It may not be installed."
    try {
        Import-Module -Name DISM -ErrorAction SilentlyContinue -ErrorVariable dismError
        if ($dismError) {
            # Something bad happened. Likely the module doesn't exist.
            Write-Host $DISMModule_ErrorMessage -ForegroundColor Red
            Exit
        }
    }
    catch {
        Write-Host $DISMModule_ErrorMessage -ForegroundColor Red
        Exit
    }
    
    Set-Location -Path $ScriptDir # In case we aren't at the repository directory already. It's a good idea for the PowerShell instance to be in the same directory as the commands and files we will be referencing.
    
    Write-Host "Getting required information..." -ForegroundColor Yellow

    if (Test-Path $Destination)
    {
        Alert_DestinationImageAlreadyExists
    }

    # Check to see if we have (and can access) everything we need
    CheckExists $7ZipExecutable "7z" "Tool executable"
    CheckExists $oscdimgExecutableFull "oscdimg" "Tool executable"
    CheckExists $Source "ISO image" "File"

    CleanupScratch # Just in case anything was left over from any previous runs as a result of an error
    MakeDirectory -Path $ScratchDir

    # Check for evidence that the image was previously modified. If there is any, give the user the option to either continue or stop.
    & $7ZipExecutable e $Source ("-o" + $ScratchDir) $sb_bypass_keyname -r | Out-Null
    if (Test-Path (Join-Path -Path $ScratchDir -ChildPath $sb_bypass_keyname))
    {
        Write-Host "Looks like this ISO has already been modified by this tool. Continuing with it is not recommended as it may have undesirable results."
        Alert_ImageModified
    }
    Write-Progress -Activity "$ActivityName" -Status "Extracting image" -PercentComplete 0
    # Extract ISO contents to scratch directory
    & $7ZipExecutable x $Source ("-o" + $Win11ScratchDir) | Out-Null
    Write-Progress -Activity "$ActivityName" -Status "Mounting boot.wim" -PercentComplete 50

    # Make directory to mount WIM images to
    MakeDirectory -Path $WIMScratchDir

    if (-not $SkipReg) # If we're not skipping the boot.wim registry modifications, then...
    {
        # Get the current time
        $StartTime = $(get-date)

        # Mount boot.wim for editing
        Mount-WindowsImage -ImagePath $BootWIMFilePath -Index $BootWimImageIndex -Path $WIMScratchDir

        # Add the registry keys
        InjectRegistryKeys

        # Unmount WIM; save changes
        Write-Progress -Activity $ActivityName -Status "Dismounting boot.wim; saving changes..." -PercentComplete 60
        Dismount-WindowsImage -Path $WIMScratchDir -Save

        # Print time elapsed
        $elapsedTime = $(get-date) - $StartTime
        PrintTimespan "boot.wim patched. Took " $elapsedTime
    }

    # Check if the user asked to modify install.wim
    if ($InjectVMwareTools -or $InjectPostPatch) {
        # Start the InjectExtraPatches routine
        InjectExtraPatches
    }

    # "Leave our mark" 
    # In other words, modify the contents of the final image in some sort of way to make it easily identifiable if a given ISO has already been modified by this tool. That way, we can warn the user if they try to use the same image again.
    # In this case, let's copy the registry keys we used to the "sources" directory under the name defined in $sb_bypass_key
    [byte[]]$REGKEY_BYTES = [convert]::FromBase64String($REGISTRY_KEY_FILE_B64)
    [System.IO.File]::WriteAllBytes($sb_bypass_key, $REGKEY_BYTES)

    ## Start creating the ISO image using OSCDIMG

    # Get the current time
    $StartTime = $(get-date)

    # Update the status
    Write-Progress -Activity $ActivityName -Status "Creating ISO" -PercentComplete 95

    # We need to provide arguments for OSCDIMG so that it generates our new installation image, and does it correctly
    # For more information, visit https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options
    $OSCDIMG_ARGS = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$Win11ScratchDir\boot\etfsboot.com#pEF,e,b$Win11ScratchDir\efi\microsoft\boot\efisys.bin $Win11ScratchDir ""$Destination"""

    # Run OSCDIMG with the arguments we've built
    Start-Process -FilePath $oscdimgExecutable -WorkingDirectory $ScriptDir -ArgumentList $OSCDIMG_ARGS -Wait -WindowStyle $DefaultWindowStyle
    
    # Print time elapsed (ISO creation)
    $elapsedTime = $(get-date) - $StartTime    
    PrintTimespan "OSCDIMG finished. Took " $elapsedTime
    
    # Delete any leftovers
    Write-Progress -Activity $ActivityName -Status "Cleaning up" -PercentComplete 100
    CleanupScratch | Out-Null

    Write-Host "Image created." -ForegroundColor Green
    Write-Host $Destination

    PrepareSystemForUpgrade

    Pause

    Set-Location -Path $OldLocation
}
