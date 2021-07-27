param
(
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Win11Image,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $DestinationImage
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
    $WIMScratchDir = "C:\Scratch\WIM"
    $Win11ScratchDir = "C:\Scratch\W-IMG"
    $BootWIMFilePath = Join-Path -Path $Win11ScratchDir -ChildPath "sources\boot.wim"
    $WimImageIndex = 2
    $RegkeyPath = Join-Path -Path $ScratchDir -ChildPath "regkey.reg"

    $sb_bypass_keyname = "win11-tpm-sb-bypass"
    $sb_bypass_key = Join-Path -Path $Win11ScratchDir -ChildPath ("\sources\" + $sb_bypass_keyname)

    Function Test-CommandExists {
        Param ($command)
        $oldPreference = $ErrorActionPreference
        $ErrorActionPreference = 'stop'
        try {if(Get-Command $command){return $true}}
        Catch {return $false}
        Finally {$ErrorActionPreference=$oldPreference}
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
                Remove-Item -Path $DestinationImage -Force
            }
        }
    }

    if(Test-Path $DestinationImage)
    {
        Alert-DestinationImageAlreadyExists
    }


    Write-Host "Checking for administrative privleges..."
    if(!(AdminPrivleges)) {
        powershell -noprofile -command "&{ start-process powershell -ArgumentList '-noprofile -file $ScriptExec -Win11Image $Win11Image -DestinationImage $DestinationImage' -verb RunAs}"
        Write-Host "This script requires administrative privleges to run." -ForegroundColor Red
        Exit
    }

    Set-Location -Path $ScriptDir

    Write-Host "Getting information..." -ForegroundColor Yellow
    Write-Host "Checking if image exists..." -ForegroundColor Yellow
    $win11exists = Test-Path $Win11Image
    if(!$win11exists)
    {
        Write-Error -Message "Win11Image: File does not exist" -Category ObjectNotFound
        Exit
    }
    else {
        Write-Host "Windows 11 image exists" -ForegroundColor Green
    }
    
    CleanupScratch
    mkdir -Path $ScratchDir

    # Check for evidence that the image was previously modified.
    & $7ZipExecutable e $Win11Image ("-o" + $ScratchDir) $sb_bypass_keyname -r | Out-Null
    if(Test-Path (Join-Path -Path $ScratchDir -ChildPath $sb_bypass_keyname))
    {
        Write-Host "Looks like you've already used this tool on this ISO. Continuing is not recommended as it hasn't been tested."
        Alert-ImageModified
    }
    
    Write-Progress -Activity "$ActivityName" -Status "Extracting image" -PercentComplete 0
    # Extract source ISO to scratch directory
    & $7ZipExecutable x $Win11Image ("-o" + $Win11ScratchDir) | Out-Null
    Write-Progress -Activity "$ActivityName" -Status "Mounting boot.wim" -PercentComplete 50
    # Make directory for DISM mount
    mkdir -Path $WIMScratchDir

    # Mount boot.wim for editing
    Mount-WindowsImage -ImagePath $BootWIMFilePath -Index $WimImageIndex -Path $WIMScratchDir

    $REG_System = Join-Path $WIMScratchDir -ChildPath "\Windows\System32\config\system"
    
    # Mount and edit the setup environment's registry
    Write-Progress -Activity $ActivityName -Status "Editing image registry..." -PercentComplete 60
    $VirtualRegistryPath_SYSTEM = "HKLM\WinPE_SYSTEM"
    $VirtualRegistryPath_Setup = $VirtualRegistryPath_SYSTEM + "\Setup"
    $VirtualRegistryPath_LabConfig = $VirtualRegistryPath_Setup + "\LabConfig"
    reg unload $VirtualRegistryPath_SYSTEM | Out-Null # Just in case...
    Start-Sleep 1
    reg load $VirtualRegistryPath_SYSTEM $REG_System | Out-Null
    Set-Location -Path Registry::$VirtualRegistryPath_Setup
    New-Item -Name "LabConfig"
    Start-Sleep 1
    New-ItemProperty -Path "LabConfig" -Name "BypassTPMCheck" -Value 1 -PropertyType DWORD -Force
    Start-Sleep 1
    New-ItemProperty -Path "LabConfig" -Name "BypassSecureBootCheck" -Value 1 -PropertyType DWORD -Force
    Start-Sleep 1
    New-ItemProperty -Path "LabConfig" -Name "BypassRAMCheck" -Value 1 -PropertyType DWORD -Force
    Start-Sleep 1
    Set-Location -Path $ScriptDir
    CollectGarbage
    Start-Sleep 2
    reg unload $VirtualRegistryPath_SYSTEM

    Start-Sleep 1

    # Unmount WIM; save changes
    Write-Progress -Activity $ActivityName -Status "Dismounting boot.wim; saving changes..." -PercentComplete 70
    Dismount-WindowsImage -Path $WIMScratchDir -Save

    # "Leave our mark" (in other words, modify the contents of the final image in some sort of way to make it easily identifiable if a given ISO has already been modified by this tool.)
    # In this case, let's copy the registry keys we used to the "sources" directory under the name defined in $sb_bypass_key
    [byte[]]$REGKEY_BYTES = [convert]::FromBase64String($REGISTRY_KEY_FILE_B64)
    [System.IO.File]::WriteAllBytes($sb_bypass_key, $REGKEY_BYTES)

    Write-Progress -Activity $ActivityName -Status "Creating ISO" -PercentComplete 80
    $OSCDIMG_ARGS = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$Win11ScratchDir\boot\etfsboot.com#pEF,e,b$Win11ScratchDir\efi\microsoft\boot\efisys.bin $Win11ScratchDir ""$DestinationImage"""
    Start-Process -FilePath $oscdimgExecutable -WorkingDirectory $ScriptDir -ArgumentList $OSCDIMG_ARGS -Wait -WindowStyle $DefaultWindowStyle
    Write-Progress -Activity $ActivityName -Status "Cleaning up" -PercentComplete 100

    CleanupScratch | Out-Null

    Write-Host "Image created." -ForegroundColor Green
    Write-Host $DestinationImage

    Pause

    Set-Location -Path $OldLocation
}