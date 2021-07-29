param
(
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Source,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Destination,

    [switch]
    $InjectVMwareTools = $false,

    [switch]
    $SkipReg = $false
)

process
{
    Import-Module -Name DISM
    $OldLocation = Get-Location

    # The encoded version (Base64) of the registry keys to be applied to the boot.wim file to bypass TPM and Secure Boot checks
    $REGISTRY_KEY_FILE_B64 = "//5XAGkAbgBkAG8AdwBzACAAUgBlAGcAaQBzAHQAcgB5ACAARQBkAGkAdABvAHIAIABWAGUAcgBzAGkAbwBuACAANQAuADAAMAANAAoADQAKAFsASABLAEUAWQBfAEwATwBDAEEATABfAE0AQQBDAEgASQBOAEUAXABTAFkAUwBUAEUATQBcAFMAZQB0AHUAcABcAEwAYQBiAEMAbwBuAGYAaQBnAF0ADQAKACIAQgB5AHAAYQBzAHMAVABQAE0AQwBoAGUAYwBrACIAPQBkAHcAbwByAGQAOgAwADAAMAAwADAAMAAwADEADQAKACIAQgB5AHAAYQBzAHMAUwBlAGMAdQByAGUAQgBvAG8AdABDAGgAZQBjAGsAIgA9AGQAdwBvAHIAZAA6ADAAMAAwADAAMAAwADAAMQANAAoADQAKAA=="
    
    $DefaultWindowStyle = "Normal"
    $ActivityName = "Win11-TPM-Bypass"

    if($VerboseOutput) {
        $DefaultWindowStyle = "Normal"
    }

    $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
    $ScriptExec = $script:MyInvocation.MyCommand.Path

    $7ZipExecutable = Join-Path -Path $ScriptDir -ChildPath "7z\7z.exe"
    $oscdimgExecutable = ".\oscdimg\oscdimg"
    $DISMExecutable = Join-Path -Path $ScriptDir -ChildPath "DISM\dism.exe"
    $DISMExecutableDir = Join-Path -Path $ScriptDir -ChildPath "DISM"

    $ScratchDir = "C:\Scratch"
    $WIMScratchDir = Join-Path -Path $ScratchDir -ChildPath "WIM"
    $Win11ScratchDir = Join-Path -Path $ScratchDir -ChildPath "W-ISO"
    $BootWIMFilePath = Join-Path -Path $Win11ScratchDir -ChildPath "sources\boot.wim"
    $InstallWIMFilePath = Join-Path -Path $Win11ScratchDir -ChildPath "sources\install.wim"
    $InstallWIMMountPath = Join-Path -Path $ScratchDir -ChildPath "INSTALL_WIM"
    $BootWimImageIndex = 2
    $RegkeyPath = Join-Path -Path $ScratchDir -ChildPath "regkey.reg"

    $sb_bypass_keyname = "win11-tpm-sb-bypass"
    $sb_bypass_key = Join-Path -Path $Win11ScratchDir -ChildPath ("\sources\" + $sb_bypass_keyname)

    # Extra Features
    $VMwareToolsISOPath = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "VMware\VMware Workstation\windows.iso"

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

    Function Verify-Switches {
        # VMware Tools Switch
        if($InjectVMwareTools) {
            if (!(Test-Path $VMwareToolsISOPath)) {
                Write-Host "VMware Tools doesn't seem to exist at the path we expected it to be ($VMwareToolsISOPath)." -ForegroundColor Red
                Pause
                Exit
            }
        }
    }

    Function AdminPrivleges {
        return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    Function CleanupScratch {
        if(Test-Path $ScratchDir) {
            # Write-Host "INFO: Deleting old Scratch directory..." -ForegroundColor Yellow
            DISM-DismountAllImages
            Remove-Item -Path $ScratchDir -Force -Recurse
        }
    }
    
    Function CollectGarbage {
        Write-Host "Cleaning up..."
        [gc]::Collect(1000, [System.GCCollectionMode]::Forced , $true) # Clean up
        [gc]::WaitForPendingFinalizers() # Wait for cleanup process to finish
        #Start-Sleep 1
    }    
    
    Function DISM-DismountAllImages {
        Write-Host "Dismounting existing images..."
        Get-WindowsImage -Mounted -ErrorAction Stop | ForEach-Object {
	        Dismount-WindowsImage -Path $_.Path -Discard #-ErrorAction Stop
        }
    }

    Function TerminateS_Premature {
        CollectGarbage
        CleanupScratch | Out-Null
        Write-Host "Process terminated."
        Exit
    }

    # Alert the user if the source image has already been modified by this tool
    Function Alert-ImageModified {
        $inputF = Read-Host -Prompt "Are you sure you want to continue? [y/n]"
        if(($inputF -ne "y") -and ($inputF -ne "n"))
        {
            Write-Host "Invalid input: $inputF" -ForegroundColor Red
            Alert-ImageModified
        }
        else
        {
            if($inputF -eq "n")
            {
                TerminateS_Premature
            }
        }
    }

    # Check to see if the destination image exists before continuing.
    Function Alert-DestinationImageAlreadyExists {
        $inputF = Read-Host -Prompt "The destination image already exists. Do you want to overwrite it? [y/n]"
        if(($inputF -ne "y") -and ($inputF -ne "n"))
        {
            Write-Host "Invalid input: $inputF" -ForegroundColor Red
            Alert-DestinationImageAlreadyExists
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

    Function AnnounceProgress-RunningExtraTasks {
        Write-Progress -Activity $ActivityName -Status "Executing extra tasks..." -PercentComplete 75
    }

    if(Test-Path $Destination)
    {
        Alert-DestinationImageAlreadyExists
    }


    # Features
    Function InjectRegistryKeys {
        # Mount and edit the setup environment's registry
        Write-Progress -Activity $ActivityName -Status "Editing image registry..." -PercentComplete 60
        $REG_System = Join-Path $WIMScratchDir -ChildPath "\Windows\System32\config\system"
        $VirtualRegistryPath_SYSTEM = "HKLM\WinPE_SYSTEM"
        $VirtualRegistryPath_Setup = $VirtualRegistryPath_SYSTEM + "\Setup"
        $VirtualRegistryPath_LabConfig = $VirtualRegistryPath_Setup + "\LabConfig"
        reg unload $VirtualRegistryPath_SYSTEM | Out-Null # Just in case...
        Start-Sleep 1
        reg load $VirtualRegistryPath_SYSTEM $REG_System | Out-Null
        Set-Location -Path Registry::$VirtualRegistryPath_Setup
        New-Item -Name "LabConfig"
        #Start-Sleep 1
        New-ItemProperty -Path "LabConfig" -Name "BypassTPMCheck" -Value 1 -PropertyType DWORD -Force
        #Start-Sleep 1
        New-ItemProperty -Path "LabConfig" -Name "BypassSecureBootCheck" -Value 1 -PropertyType DWORD -Force
        #Start-Sleep 1
        New-ItemProperty -Path "LabConfig" -Name "BypassRAMCheck" -Value 1 -PropertyType DWORD -Force
        #Start-Sleep 1
        Set-Location -Path $ScriptDir
        CollectGarbage
        Start-Sleep 1
        reg unload $VirtualRegistryPath_SYSTEM
        # Start-Sleep 1
        Write-Host "boot.wim patched" -ForegroundColor Green
    }

    Function InjectVMwareTools {
        # Scratch directory for VMware Tools
        $VMwareToolsScratchDir = Join-Path -Path $ScratchDir -ChildPath "vmwaretools"

        AnnounceProgress-RunningExtraTasks
        Write-Host "Preparing to inject VMware Tools into install.wim..."
        mkdir $InstallWIMMountPath # Make our mount directory for install.wim...
        mkdir $VMwareToolsScratchDir #... and our temporary directory for VMware Tools
        # Get information about install.wim, such as if it has more than one edition.
        Write-Host "Getting install.wim info..."
        $WIMEditions = Get-WindowsImage -ImagePath $InstallWIMFilePath
        $WIMCountStr = $WIMEditions.Count.ToString()

        # Prepare everything we need in the VMware Tools scratch directory.
        # Extract the VMware Tools ISO
        $VMwareTempFolderName = "vmwaretools"
        $MountDir_Setup = Join-Path -Path $VMwareToolsScratchDir -ChildPath "Windows\Setup\Scripts"
        $SetupCompleteCMD = Join-Path -Path $MountDir_Setup -ChildPath "SetupComplete.cmd"
        # Define the contents of our SetupComplete.cmd file
        $SetupCompleteCMDContents = 
@"
C:\$VMwareTempFolderName\setup64.exe /S /v "/qn REBOOT=R ADDLOCAL=ALL"
rmdir C:\$VMwareTempFolderName /s /q
rmdir C:\Windows\Setup\Scripts /s /q
"@
        mkdir $MountDir_Setup
        & $7ZipExecutable x $VMwareToolsISOPath ("-o" + (Join-Path -Path $VMwareToolsScratchDir -ChildPath $VMwareTempFolderName)) | Out-Null
        # Generate SetupComplete.cmd file

        # Write SetupComplete.cmd contents to file
        $stream = [System.IO.StreamWriter] $SetupCompleteCMD
        $stream.Write(($SetupCompleteCMDContents -join "`r`n"))
        $stream.close()

        if($WIMEditions.Count -gt 1) {
            # If install.wim has more than one edition, give the user the option to choose one or all.
            $EditionList = @("0: Modify all editions")
            Write-Host "The install.wim image contains multiple editions. Enter the index number of the edition(s) you want to use (editions not selected will not exist in the new image), or type 0 to modify all (not recommended)" -ForegroundColor Yellow
            Write-Host ""
            # Sift through editions
            foreach ($WIMedition in $WIMEditions) {
                $EditionList += ($WIMedition.ImageIndex.ToString() + ": " + $WIMedition.ImageName)
            }
            # Print editions from $EditionList
            $EditionList | ForEach-Object {"$PSItem"}

            $SelectMulti = @()

            Write-Host ""
            # Request choice from user
            # do 
            # {
            #     $SelectedIndex = try {(Read-Host "Enter choice [0-$WIMCountStr], 'M' to select multiple")}
            #     catch {}
            #     #$SelectedIndex = try {[int]::Parse($value)} catch {$SelectedIndex = 1}
            #     [string]$option = $SelectedIndex
            # } while (-not ($option -contains "M") -or -not ($SelectedIndex -ge 0 -and $SelectedIndex -le ($WIMEditions.Count)))
            # 
            # if($option -contains "M")
            # {
            #     do 
            #     {
            #         try {[ValidatePattern('^[0-9,]+$')]$Multi_Options = (Read-Host "Choose editions, followed by commas (ex. 1,3,6)")}
            #         catch {}
            #     } until ($?)
            # 
            #     $SelectMulti = foreach($indexEntry in ($Multi_Options -Split ",")) {
            #         try {
            #             [int]::Parse($indexEntry)
            #         }
            #         catch{}
            #     }
            # }

            do 
            {
                try {[ValidatePattern('^[0-9,]+$')]$Multi_Options = (Read-Host "Enter choice(s) [0-$WIMCountStr]. For multiple selections, separate choices with commas (ex. 1,3,6)")}
                catch {}
            } while (-not ($Multi_Options -ge 0 -and $Multi_Options -le ($WIMEditions.Count))) # until ($?)

            $Selection = foreach($indexEntry in ($Multi_Options -Split ",")) {
                try {
                    [int]::Parse($indexEntry)
                }
                catch{}
            }

            if(($Selection.Count -gt 1) -and ($Selection.Contains(0))) { # If we selected individuals, we're of course not doing them all. Find if a 0 exists, and remove it if the length of the list is larger than 1
                $Selection = $Selection | ? { $_ -ne 0 }
            }

            $Selection = $Selection | select -uniq # Remove duplicates from the array

            # Print the selection
            Write-Host "Selected:"
            $Selection | ForEach-Object { $WIMEditions[$PSItem - 1].ImageName }

            if($Selection[0] -eq 0)
            {
                Write-Host "Processing all"
                #foreach ($edition in $WIMEditions)
                #{
                #    $PercentageComplete = GetPercentageFromRange $edition.ImageIndex 0 $WIMEditions.Count
                #    Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $edition.ImageName + " (" + $edition.ImageIndex.ToString() + "/" + $WIMEditions.Count.ToString() + ")") -PercentComplete $PercentageComplete
                #    Sub_InjectVMwareTools $InstallWIMFilePath $InstallWIMMountPath $edition.ImageIndex $VMwareToolsScratchDir 
                #}
                #CleanWIM $InstallWIMFilePath $SelectedIndex
            }
            else
            {
                $EditionsToProcess = foreach ($edition in $WIMEditions)
                {
                    if ($Selection -contains $edition.ImageIndex)
                    {
                        $edition
                    }
                }
                $EditionsToProcess
                Write-Host ""
                $CurrentIndex = 0
                foreach ($edition in $EditionsToProcess)
                {
                    $CurrentIndex++
                    $PercentageComplete = GetPercentageFromRange ($CurrentIndex - 1) 0 $EditionsToProcess.Count
                    Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $edition.ImageName + " (" + $CurrentIndex.ToString() + "/" + $EditionsToProcess.Count.ToString() + ")") -PercentComplete $PercentageComplete
                    Sub_InjectVMwareTools $InstallWIMFilePath $InstallWIMMountPath $edition.ImageIndex $VMwareToolsScratchDir
                    Start-Sleep 1
                }
                CleanWIM $InstallWIMFilePath $EditionsToProcess
            }
        }
        else { # There's only one edition in the WIM file.
            Write-Progress -Activity "Modifying install.wim" -Status ("Modifying " + $WIMEditions[0].ImageName + " (" + $WIMEditions[0].ImageIndex.ToString() + "/" + $WIMEditions.Count.ToString() + ")") -PercentComplete 0
            Sub_InjectVMwareTools $InstallWIMFilePath $InstallWIMMountPath $WIMEditions[0].ImageIndex $VMwareToolsScratchDir
        }
    }

    Function Sub_InjectVMwareTools ([string] $WIMFilePath, [string] $MountPath, [uint32] $WIMIndex, [string] $VMwareToolsSource) {
        Mount-WindowsImage -ImagePath $WIMFilePath -Index $WIMIndex -Path $MountPath
        Copy-Item ($VMwareToolsSource + "\*") ($MountPath + "\") -Recurse -Force # | Out-Null
        Dismount-WindowsImage -Path $MountPath -Save
    }

    Function CleanWIM ([string] $WIMFilePath, $KeepEditions) {
        $OLD = $WIMFilePath + ".old"
        Move-Item $WIMFilePath $OLD -Force
        foreach ($edition in $KeepEditions)
        {
            Export-WindowsImage -SourceImagePath $OLD -SourceIndex $edition.ImageIndex -DestinationImagePath $WIMFilePath -CompressionType Max
        }
        Remove-Item $OLD -Force
    }


    # Start main script

    Write-Host "Checking for administrative privleges..."
    if(!(AdminPrivleges)) {
        # powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -file $ScriptExec -Win11Image $Source -DestinationImage $Destination' -verb RunAs}"
        Write-Host "This script requires administrative privleges to run." -ForegroundColor Red
        Exit
    }

    Set-Location -Path $ScriptDir # In case we aren't positioned here already. It's a good idea for the PowerShell instance to be in the same directory as the commands we will be referencing.
    Write-Host "Getting information..." -ForegroundColor Yellow
    Write-Host "Checking if image exists..." -ForegroundColor Yellow
    $image_exists = Test-Path $Source
    if(!$image_exists)
    {
        Write-Error -Message "Source: File does not exist" -Category ObjectNotFound
        Exit
    }
    else {
        Write-Host "Windows 11 image exists" -ForegroundColor Green
    }
    CleanupScratch # Just in case anything was left over from any previous runs as a result of an error
    mkdir -Path $ScratchDir
    # Check for evidence that the image was previously modified. If there is any, warn the user.
    & $7ZipExecutable e $Source ("-o" + $ScratchDir) $sb_bypass_keyname -r | Out-Null
    if(Test-Path (Join-Path -Path $ScratchDir -ChildPath $sb_bypass_keyname))
    {
        Write-Host "Looks like you've already used this tool on this ISO. Continuing is not recommended as it hasn't been tested."
        Alert-ImageModified
    }    
    Write-Progress -Activity "$ActivityName" -Status "Extracting image" -PercentComplete 0
    # Extract source ISO to scratch directory
    & $7ZipExecutable x $Source ("-o" + $Win11ScratchDir) | Out-Null
    Write-Progress -Activity "$ActivityName" -Status "Mounting boot.wim" -PercentComplete 50
    # Make directory for DISM mount
    mkdir -Path $WIMScratchDir

    if(-not $SkipReg)
    {
        # Mount boot.wim for editing
        Mount-WindowsImage -ImagePath $BootWIMFilePath -Index $BootWimImageIndex -Path $WIMScratchDir
        # Add our registry keys
        InjectRegistryKeys
        # Unmount WIM; save changes
        Write-Progress -Activity $ActivityName -Status "Dismounting boot.wim; saving changes..." -PercentComplete 70
        Dismount-WindowsImage -Path $WIMScratchDir -Save
    }

    if($InjectVMwareTools) {
        InjectVMwareTools
    }

    # "Leave our mark" (in other words, modify the contents of the final image in some sort of way to make it easily identifiable if a given ISO has already been modified by this tool.)
    # In this case, let's copy the registry keys we used to the "sources" directory under the name defined in $sb_bypass_key
    [byte[]]$REGKEY_BYTES = [convert]::FromBase64String($REGISTRY_KEY_FILE_B64)
    [System.IO.File]::WriteAllBytes($sb_bypass_key, $REGKEY_BYTES)
    Write-Progress -Activity $ActivityName -Status "Creating ISO" -PercentComplete 80
    $OSCDIMG_ARGS = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$Win11ScratchDir\boot\etfsboot.com#pEF,e,b$Win11ScratchDir\efi\microsoft\boot\efisys.bin $Win11ScratchDir ""$Destination"""
    Start-Process -FilePath $oscdimgExecutable -WorkingDirectory $ScriptDir -ArgumentList $OSCDIMG_ARGS -Wait -WindowStyle $DefaultWindowStyle
    Write-Progress -Activity $ActivityName -Status "Cleaning up" -PercentComplete 100
    CleanupScratch | Out-Null
    Write-Host "Image created." -ForegroundColor Green
    Write-Host $Destination
    Pause
    Set-Location -Path $OldLocation
}