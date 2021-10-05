param
(
    [switch]$VerboseOutput = $false,
    #[switch]$CreateESD = $false,
    [switch]$EditMode = $false,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Win10Image,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Win11Image,

    [Parameter(Mandatory=$false,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $DestinationImage
)

process
{
    # Acknowledge obsolete status
    Write-Host "Please acknowledge that this method/tool is now obsolete, and is no longer being maintained. Please use 'Win11-TPM-RegBypass' instead. "
    Write-Host "Read the README.md for more details, or go to https://github.com/JosephM101/Force-Windows-11-Install/blob/main/README.md"
    Write-Host ""

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
    function CleanupScratch {
        Remove-Item -Path "C:\SCRATCH" -Force -Recurse
    }
    
    $DefaultWindowStyle = "Hidden"

    if($VerboseOutput) {
        $DefaultWindowStyle = "Normal"
    }

    $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

    $7ZipExecutable = ".\7z\7z.exe"
    $oscdimgExecutable = ".\oscdimg\oscdimg.exe"
    $ScratchDir = "C:\Scratch"
    $Win10ScratchDir = "C:\Scratch\W10"
    $Win11ScratchDir = "C:\Scratch\W11"
    $DISMExecutable = Join-Path -Path $ScriptDir -ChildPath "DISM\dism.exe"
    $DISMExecutableDir = Join-Path -Path $ScriptDir -ChildPath "DISM"
    Write-Host "Getting information..." -ForegroundColor Yellow
    Write-Host "Checking if specified images exist..." -ForegroundColor Yellow
    $win10exists = Test-Path $Win10Image
    $win11exists = Test-Path $Win11Image
    if(!$win10exists)
    {
        Write-Error -Message "Win10Image: File does not exist" -Category ObjectNotFound
        Exit
    }
    else {
        Write-Host "Windows 10 image exists" -ForegroundColor Green
    }
    if(!$win11exists)
    {
        Write-Error -Message "Win11Image: File does not exist" -Category ObjectNotFound
        Exit
    }
    else {
        Write-Host "Windows 11 image exists" -ForegroundColor Green
    }

    if (!($PSBoundParameters.ContainsKey("DestinationImage")))
    {
        if(!($SkipISO))
        {
            $DestinationImage = Read-Host -Prompt "Specify the path for the final (output) ISO"
        }
    }

    # Write-Host "Running..."
    # CleanupScratch | Out-Null
    mkdir -Path $ScratchDir | Out-Null

    # if($CreateESD) {
    #     #if(!(Test-CommandExists Export-WindowsImage))
    #     # if(!(Test-Path (Join-Path -Path $ScriptDir -ChildPath "DISM\dism.exe")))
    #     # {
    #     #     Write-Host "Error: ESD support requires Windows 10 Deployment and Imaging Tools to be installed. You can download it from this link: https://go.microsoft.com/fwlink/?linkid=2120254" -ForegroundColor Red
    #     #     Write-Host "Note: You only need to check 'Deployment Tools' on the installer." -ForegroundColor Red
    #     #     Exit
    #     # }
    #     if(!(AdminPrivleges))
    #     {
    #         Write-Host "Error: ESD support requires elevated privleges. Run this script in an elevated PowerShell instance." -ForegroundColor Red
    #         Exit
    #     }
    # }

    Function CreateImage {
        Write-Progress -Activity "Creating image..." -Status "75% Complete:" -PercentComplete 75
        $OSCDIMG_ARGS = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$Win10ScratchDir\boot\etfsboot.com#pEF,e,b$Win10ScratchDir\efi\microsoft\boot\efisys.bin $Win10ScratchDir ""$DestinationImage"""
        & $oscdimgExecutable $OSCDIMG_ARGS
        Write-Progress -Activity "Cleaning up..." -Status "100% Complete:" -PercentComplete 100
        CleanupScratch | Out-Null
        Write-Host "Image created." -ForegroundColor Green
        Write-Host $DestinationImage
    }

    Write-Progress -Activity "Extracting images..." -Status "0% Complete:" -PercentComplete 0
    # $Win10_7zArguments = "x ""$Win10Image"" -o$Win10ScratchDir -x!sources/install.wim -y"
    $Win10_7zArguments = "x ""$Win10Image"" -o$Win10ScratchDir -y"
    & $7ZipExecutable $Win10_7zArguments 
    Write-Progress -Activity "Extracting images..." -Status "25% Complete:" -PercentComplete 25
    $Win11_7zArguments = "e ""$Win11Image"" -o$Win11ScratchDir install.wim -r"
    & $7ZipExecutable $Win11_7zArguments
    Write-Progress -Activity "Copying files..." -Status "50% Complete:" -PercentComplete 50
    Remove-Item -Path "$Win10ScratchDir\sources\install.wim"
    # if ($CreateESD)  {
    #     Write-Progress -Activity "Converting install.wim to install.esd (this may take a while)..." -Status "60% Complete:" -PercentComplete 60
    #     # Export-WindowsImage -SourceImagePath "C:\Scratch\W11\install.wim" -SourceName "Windows 11 Pro" -DestinationImagePath "C:\Scratch\W10\sources\install.esd" -CheckIntegrity -CompressionType recovery -Setbootable
    #     $DISM_SourceImage = Join-Path -Path $Win11ScratchDir -ChildPath "install.wim"
    #     $DISM_DestinationImage = Join-Path -Path $Win10ScratchDir -ChildPath "sources/install.esd"
    #     $DISMArgs = "/export-image /SourceImageFile:""$DISM_SourceImage"" /SourceName:""Windows 11 Pro"" /DestinationImageFile:""$DISM_DestinationImage"" /Compress:recovery /CheckIntegrity"
    #     Start-Process -FilePath $DISMExecutable -WorkingDirectory $DISMExecutableDir -ArgumentList $DISMArgs -Wait -WindowStyle $DefaultWindowStyle
    # }
    # else {
    #     Move-Item -Path "$Win11ScratchDir\install.wim" -Destination "$Win10ScratchDir\sources\install.wim"
    # }
    Move-Item -Path "$Win11ScratchDir\install.wim" -Destination "$Win10ScratchDir\sources\install.wim"
    Remove-Item -Path "$Win11ScratchDir"

    Function ReadyContinue {
        $inputF = Read-Host -Prompt "When you're ready, type 'continue' to build the ISO from the modified source"
        if(!($inputF -eq "continue"))
        {
            ReadyContinue
        }
    }

    if($EditMode)
    {
        Write-Host "Images extracted."
        Write-Host "Images can be modified in ""$Win10ScratchDir""."
        ReadyContinue
    }

    CreateImage
    Pause
}