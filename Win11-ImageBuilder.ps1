param
(
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Win10Image,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $Win11Image,

    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]
    $DestinationImage,

    [switch]$VerboseOutput = $false
)

process
{
    function CleanupScratch {
        Remove-Item -Path "C:\SCRATCH" -Force -Recurse
    }
    
    $DefaultWindowStyle = "Hidden"

    if($VerboseOutput) {
        $DefaultWindowStyle = "Normal"
    }

    $ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

    $7ZipExecutable = ".\7z"
    $oscdimgExecutable = ".\oscdimg"
    $ScratchDir = "C:\Scratch"
    $Win10ScratchDir = "C:\Scratch\W10"
    $Win11ScratchDir = "C:\Scratch\W11"
    Write-Host "Getting information..." -ForegroundColor Yellow
    Write-Host "Checking if specified paths exist..." -ForegroundColor Yellow
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

    # Write-Host "Running..."
    # CleanupScratch | Out-Null
    mkdir -Path $ScratchDir | Out-Null

    Write-Progress -Activity "Extracting images..." -Status "0% Complete:" -PercentComplete 0
    $Win10_7zArguments = "x ""$Win10Image"" -o$Win10ScratchDir -y"
    Start-Process -FilePath $7ZipExecutable -WorkingDirectory $ScriptDir -ArgumentList $Win10_7zArguments -Wait -WindowStyle $DefaultWindowStyle
    Write-Progress -Activity "Extracting images..." -Status "25% Complete:" -PercentComplete 25
    $Win11_7zArguments = "e ""$Win11Image"" -o$Win11ScratchDir install.wim -r"
    Start-Process -FilePath $7ZipExecutable -WorkingDirectory $ScriptDir -ArgumentList $Win11_7zArguments -Wait -WindowStyle $DefaultWindowStyle
    Write-Progress -Activity "Copying files..." -Status "50% Complete:" -PercentComplete 50
    Remove-Item -Path "$Win10ScratchDir\sources\install.wim"
    Move-Item -Path "$Win11ScratchDir\install.wim" -Destination "$Win10ScratchDir\sources\install.wim"
    Write-Progress -Activity "Creating image..." -Status "75% Complete:" -PercentComplete 75
    $OSCDIMG_ARGS = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b$Win10ScratchDir\boot\etfsboot.com#pEF,e,b$Win10ScratchDir\efi\microsoft\boot\efisys.bin $Win10ScratchDir ""$DestinationImage"""
    Start-Process -FilePath $oscdimgExecutable -WorkingDirectory $ScriptDir -ArgumentList $OSCDIMG_ARGS -Wait -WindowStyle $DefaultWindowStyle
    Write-Progress -Activity "Cleaning up..." -Status "100% Complete:" -PercentComplete 100

    CleanupScratch | Out-Null

    Write-Host "Image created." -ForegroundColor Green
    Write-Host $DestinationImage
    Pause
}